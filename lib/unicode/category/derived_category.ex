defmodule Unicode.GeneralCategory.Derived do
  @moduledoc """
  For certain operations and transformations
  (especially in [Unicode Sets](http://unicode.org/reports/tr35/#Unicode_Sets)) there is an
  expectation that certain derived general
  categories exists even though they are not
  defined in the unicode character database.

  These categories are:

  * `:any` which is the full unicode character
    range `0x0..0x10ffff`

  * `:assigned` which is the set of codepoints
    that are assigned and which is therefore
    equivalent to `:any` - `:Cn`. In fact that is
    exactly how it is calculated using `unicode_set`
    and the results are statically copied here so
    that there is no mutual dependency.

  * `:ascii` which is the range for the US ASCII
    character set of `0x0..0x7f`

  In addition there are derived categories
  not part of the Unicode specification that
  support additional use cases. These include:

  * Categories related to
  recognising quotation marks. See the
  module `Unicode.Category.QuoteMarks`.

  * `:printable:` which implements the same
  semantics as `String.printable?/1`

  * `:visible:` which includes characters from the
  `[[:L:][:N:][:M:][:P:][:S:][:Zs:]]` set

  """

  alias Unicode.Category.QuoteMarks
  alias Unicode.Utils

  @any_category Unicode.Block.ranges()
  @ascii_category [{0x0, 0x7F}]

  @derived_categories %{
    Ascii: @ascii_category,
    Any: @any_category,
    Assigned: Unicode.DerivedCategory.Assigned.assigned(),
    QuoteMark: QuoteMarks.all_quote_marks() |> Utils.list_to_ranges(),
    QuoteMarkLeft: QuoteMarks.quote_marks_left() |> Utils.list_to_ranges(),
    QuoteMarkRight: QuoteMarks.quote_marks_right() |> Utils.list_to_ranges(),
    QuoteMarkAmbidextrous: QuoteMarks.quote_marks_ambidextrous() |> Utils.list_to_ranges(),
    QuoteMarkSingle: QuoteMarks.quote_marks_single() |> Utils.list_to_ranges(),
    QuoteMarkDouble: QuoteMarks.quote_marks_double() |> Utils.list_to_ranges(),
    Printable: Unicode.DerivedCategory.Printable.printable(),
    Visible: Unicode.DerivedCategory.Visible.visible()
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
    "visible" => :Visible
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
