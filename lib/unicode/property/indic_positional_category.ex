defmodule Unicode.IndicPositionalCategory do
  @moduledoc """
  Functions to introspect the Unicode `Indic_Positional_Category` property for binaries (Strings) and codepoints.

  The `Indic_Positional_Category` property describes the visual position of a dependent character relative to its base, for example `:top`, `:bottom`, `:left`, `:right` or `:top_and_bottom`. Codepoints to which it does not apply have the value `:na` (Not_Applicable).

  The primary API is `indic_positional_category/1` which returns the category of a codepoint, or the list of categories of a string.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @indic_positional_categories Utils.indic_positional_categories()
                               |> Utils.remove_annotations()

  @indic_positional_category_table Unicode.RangeSearch.new_value_table(
                                     @indic_positional_categories
                                   )

  @doc """
  Returns the map of Unicode indic positional categories.

  ### Returns

  * A map where the indic positional category is the key and a list of codepoint ranges as 2-tuples is the value.

  ### Examples

      iex> :top in Map.keys(Unicode.IndicPositionalCategory.indic_positional_categories())
      true

  """
  def indic_positional_categories do
    @indic_positional_categories
  end

  @doc """
  Returns a list of known Unicode indic positional category names.

  ### Returns

  * A list of atom indic positional category names.

  ### Examples

      iex> :bottom in Unicode.IndicPositionalCategory.known_indic_positional_categories()
      true

  """
  @known_indic_positional_categories Map.keys(@indic_positional_categories)
  def known_indic_positional_categories do
    @known_indic_positional_categories
  end

  @doc """
  Returns a map of aliases for Unicode indic positional categories.

  ### Returns

  * A map where the alias string is the key and the indic positional category is the value.

  ### Examples

      iex> Unicode.IndicPositionalCategory.aliases() |> Map.get("top")
      :top

  """
  @indic_positional_category_aliases Utils.value_aliases(
                                       "inpc",
                                       @known_indic_positional_categories
                                     )
                                     |> Utils.add_canonical_alias()

  @impl Unicode.Property.Behaviour
  def aliases do
    @indic_positional_category_aliases
  end

  @doc """
  Returns the Unicode codepoint ranges for a given indic positional category.

  Aliases are resolved by this function.

  ### Arguments

  * `indic_positional_category` is any category name or alias, as an atom or string.

  ### Returns

  * `{:ok, range_list}` where `range_list` is a list of codepoint ranges as 2-tuples.

  * `:error` if the indic positional category is not known.

  ### Examples

      iex> Unicode.IndicPositionalCategory.fetch(:top) |> elem(0)
      :ok

      iex> Unicode.IndicPositionalCategory.fetch(:invalid)
      :error

  """
  @impl Unicode.Property.Behaviour
  def fetch(indic_positional_category) when is_atom(indic_positional_category) do
    Map.fetch(indic_positional_categories(), indic_positional_category)
  end

  def fetch(indic_positional_category) do
    indic_positional_category = Utils.downcase_and_remove_whitespace(indic_positional_category)

    indic_positional_category =
      Map.get(aliases(), indic_positional_category, indic_positional_category)
      |> Utils.maybe_atomize()

    Map.fetch(indic_positional_categories(), indic_positional_category)
  end

  @doc """
  Returns the Unicode codepoint ranges for a given indic positional category.

  Aliases are resolved by this function.

  ### Arguments

  * `indic_positional_category` is any category name or alias, as an atom or string.

  ### Returns

  * A list of codepoint ranges as 2-tuples.

  * `nil` if the indic positional category is not known.

  ### Examples

      iex> Unicode.IndicPositionalCategory.get(:invalid)
      nil

  """
  @impl Unicode.Property.Behaviour
  def get(indic_positional_category) do
    case fetch(indic_positional_category) do
      {:ok, range_list} -> range_list
      _ -> nil
    end
  end

  @doc """
  Returns the count of the codepoints with a given indic positional category.

  Aliases are resolved by this function.

  ### Arguments

  * `indic_positional_category` is any category name or alias, as an atom or string.

  ### Returns

  * A non-negative integer count of the codepoints with the indic positional category.

  * `:error` if the indic positional category is not known.

  ### Examples

      iex> is_integer(Unicode.IndicPositionalCategory.count(:top))
      true

  """
  @impl Unicode.Property.Behaviour
  def count(indic_positional_category) do
    with {:ok, range_list} <- fetch(indic_positional_category) do
      Enum.reduce(range_list, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the indic positional category of the given binary or codepoint.

  ### Arguments

  * `string_or_codepoint` is either a binary (String) or a codepoint in the range `0..0x10FFFF`.

  ### Returns

  * For a codepoint, a single category atom is returned. Codepoints to which the property does not apply return `:na`.

  * For a binary, a list of the distinct categories of the codepoints in the binary is returned.

  ### Examples

      iex> Unicode.IndicPositionalCategory.indic_positional_category(0x0903)
      :right

      iex> Unicode.IndicPositionalCategory.indic_positional_category(?A)
      :na

  """
  def indic_positional_category(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&indic_positional_category/1)
    |> Enum.uniq()
  end

  def indic_positional_category(codepoint)
      when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    Unicode.RangeSearch.find(@indic_positional_category_table, codepoint, :na)
  end
end
