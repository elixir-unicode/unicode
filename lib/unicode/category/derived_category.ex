defmodule Unicode.GeneralCategory.Derived do
  @moduledoc """
  For certain operations and transformations
  (especially in [Unicode Sets](http://unicode.org/reports/tr35/#Unicode_Sets))
  there is an expectation that certain derived
  general categories exist even though they are not
  defined in the unicode character database.

  These categories are:

  * `:any` which is the full unicode character
    range `0x0..0x10ffff`

  * `:assigned` which is the set of codepoints
    that are assigned and is therefore
    equivalent to `[:any]-[:Cn]`. It is computed
    directly from the general category data.

  * `:ascii` which is the range for the US ASCII
    character set of `0x0..0x7f`

  In addition there are derived categories
  not part of the Unicode specification that
  support additional use cases. These include:

  * Categories related to
    recognising quotation marks. See the
    module `Unicode.Category.QuoteMarks`.

  * `:printable` which implements the same
    semantics as `String.printable?/1`. This is
    a very broad definition of printable characters.

  * `:graph` which includes characters from the
    `[^\\p{White_Space}\\p{gc=Control}\\p{gc=Surrogate}\\p{gc=Unassigned}]`
    set defined by [Unicode Regular Expressions](http://unicode.org/reports/tr18/).
    It is computed directly from the general category and
    `White_Space` property data.

  """

  alias Unicode.Category.QuoteMarks
  alias Unicode.Utils

  @ascii_category [{0x0, 0x7F}]

  # The concrete general categories, read directly from the character
  # database. `GeneralCategory` cannot be used here because it depends on
  # this module, so the derived categories are computed from `Utils` data.
  @categories Utils.categories() |> Utils.remove_annotations()
  @white_space Utils.properties() |> Utils.remove_annotations() |> Map.fetch!(:white_space)

  # Assigned is every codepoint that has a general category other than
  # `Cn` (Unassigned), i.e. the complement of `Cn`.
  @assigned Utils.complement_ranges(Map.fetch!(@categories, :Cn))

  # Graph is the assigned characters that are not whitespace, control or
  # surrogate, matching the Unicode TR18 definition.
  @graph Utils.difference_ranges(
           @assigned,
           Utils.union_ranges([
             @white_space,
             Map.fetch!(@categories, :Cc),
             Map.fetch!(@categories, :Cs)
           ])
         )

  @derived_categories %{
    Ascii: @ascii_category,
    Any: Unicode.all(),
    Assigned: @assigned,
    QuoteMark: QuoteMarks.all_quote_marks() |> Utils.list_to_ranges(),
    QuoteMarkLeft: QuoteMarks.quote_marks_left() |> Utils.list_to_ranges(),
    QuoteMarkRight: QuoteMarks.quote_marks_right() |> Utils.list_to_ranges(),
    QuoteMarkAmbidextrous: QuoteMarks.quote_marks_ambidextrous() |> Utils.list_to_ranges(),
    QuoteMarkSingle: QuoteMarks.quote_marks_single() |> Utils.list_to_ranges(),
    QuoteMarkDouble: QuoteMarks.quote_marks_double() |> Utils.list_to_ranges(),
    Printable: Unicode.DerivedCategory.Printable.printable(),
    Graph: @graph,
    Visible: @graph
  }

  @derived_aliases %{
    "any" => :Any,
    "assigned" => :Assigned,
    "ascii" => :Ascii,
    "quotemark" => :QuoteMark,
    "quotemarkleft" => :QuoteMarkLeft,
    "quotemarkright" => :QuoteMarkRight,
    "quotemarkambidextrous" => :QuoteMarkAmbidextrous,
    "quotemarksingle" => :QuoteMarkSingle,
    "quotemarkdouble" => :QuoteMarkDouble,
    "printable" => :Printable,
    "visible" => :Graph,
    "graph" => :Graph
  }

  @doc """
  Returns a map of the derived
  General Categories
  """
  @spec categories :: map()
  def categories do
    @derived_categories
  end

  @doc """
  Returns a map of the aliases
  for the derived General Categories
  """
  @spec aliases :: map()
  def aliases do
    @derived_aliases
  end
end
