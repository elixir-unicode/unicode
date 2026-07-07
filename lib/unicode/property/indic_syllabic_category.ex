defmodule Unicode.IndicSyllabicCategory do
  @moduledoc """
  Functions to introspect the Unicode Indic syllabic category property for binaries (Strings) and codepoints.

  The primary API is `indic_syllabic_category/1` which returns the Indic syllabic category for a codepoint or the list of Indic syllabic categories for a string.

  The functions `fetch/1`, `get/1` and `count/1` provide introspection of the codepoint ranges associated with a given Indic syllabic category. `indic_syllabic_categories/0`, `known_indic_syllabic_categories/0` and `aliases/0` return the underlying property data.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @indic_syllabic_categories Utils.indic_syllabic_categories()
                             |> Utils.remove_annotations()

  @indic_syllabic_category_table Unicode.RangeSearch.new_value_table(@indic_syllabic_categories)

  @doc """
  Returns the map of Unicode Indic syllabic categories.

  ### Returns

  * A map with the Indic syllabic category name as the key and a list of codepoint ranges as 2-tuples as the value.

  ### Examples

      iex> Unicode.IndicSyllabicCategory.indic_syllabic_categories() |> Map.get(:virama) |> Enum.take(2)
      [{2381, 2381}, {2509, 2509}]

  """

  def indic_syllabic_categories do
    @indic_syllabic_categories
  end

  @doc """
  Returns a list of known Unicode Indic syllabic category names.

  This function does not return the names of any Indic syllabic category aliases.

  ### Returns

  * A list of Indic syllabic category names as atoms.

  ### Examples

      iex> Unicode.IndicSyllabicCategory.known_indic_syllabic_categories() |> Enum.sort() |> Enum.take(3)
      [:avagraha, :bindu, :brahmi_joining_number]

  """
  @known_indic_syllabic_categories Map.keys(@indic_syllabic_categories)
  def known_indic_syllabic_categories do
    @known_indic_syllabic_categories
  end

  @indic_syllabic_category_alias Utils.property_value_alias()
                                 |> Map.get("insc")
                                 |> Utils.atomize_values()
                                 |> Utils.downcase_keys_and_remove_whitespace()
                                 |> Utils.add_canonical_alias()

  @doc """
  Returns a map of aliases for Unicode Indic syllabic categories.

  An alias is an alternative name for referring to an Indic syllabic category. Aliases are resolved by the `fetch/1` and `get/1` functions.

  ### Returns

  * A map with the alias as a string key and the Indic syllabic category name as an atom value.

  ### Examples

      iex> Unicode.IndicSyllabicCategory.aliases() |> Map.get("virama")
      :virama

  """
  @impl Unicode.Property.Behaviour
  def aliases do
    @indic_syllabic_category_alias
  end

  @doc """
  Returns the Unicode codepoint ranges for a given Indic syllabic category.

  Aliases are resolved by this function.

  ### Arguments

  * `indic_syllabic_category` is any Indic syllabic category name as an atom, or a string alias for an Indic syllabic category.

  ### Returns

  * `{:ok, range_list}` where `range_list` is a list of codepoint ranges as 2-tuples.

  * `:error` if the Indic syllabic category name is not known.

  ### Examples

      iex> {:ok, ranges} = Unicode.IndicSyllabicCategory.fetch(:virama)
      iex> Enum.take(ranges, 2)
      [{2381, 2381}, {2509, 2509}]

      iex> Unicode.IndicSyllabicCategory.fetch(:invalid)
      :error

  """
  @impl Unicode.Property.Behaviour
  def fetch(indic_syllabic_category) when is_atom(indic_syllabic_category) do
    Map.fetch(indic_syllabic_categories(), indic_syllabic_category)
  end

  def fetch(indic_syllabic_category) do
    indic_syllabic_category = Utils.downcase_and_remove_whitespace(indic_syllabic_category)
    indic_syllabic_category = Map.get(aliases(), indic_syllabic_category, indic_syllabic_category)
    Map.fetch(indic_syllabic_categories(), indic_syllabic_category)
  end

  @doc """
  Returns the Unicode codepoint ranges for a given Indic syllabic category.

  Aliases are resolved by this function.

  ### Arguments

  * `indic_syllabic_category` is any Indic syllabic category name as an atom, or a string alias for an Indic syllabic category.

  ### Returns

  * `range_list` which is a list of codepoint ranges as 2-tuples.

  * `nil` if the Indic syllabic category name is not known.

  ### Examples

      iex> Unicode.IndicSyllabicCategory.get(:virama) |> Enum.take(2)
      [{2381, 2381}, {2509, 2509}]

      iex> Unicode.IndicSyllabicCategory.get(:invalid)
      nil

  """
  @impl Unicode.Property.Behaviour
  def get(indic_syllabic_category) do
    case fetch(indic_syllabic_category) do
      {:ok, indic_syllabic_category} -> indic_syllabic_category
      _ -> nil
    end
  end

  @doc """
  Returns the count of the number of characters for a given Indic syllabic category.

  ### Arguments

  * `indic_syllabic_category` is any Indic syllabic category name as an atom, or a string alias for an Indic syllabic category.

  ### Returns

  * The number of codepoints that have the given Indic syllabic category.

  * `:error` if the Indic syllabic category name is not known.

  ### Examples

      iex> Unicode.IndicSyllabicCategory.count(:bindu)
      99

  """
  @impl Unicode.Property.Behaviour
  def count(indic_syllabic_category) do
    with {:ok, indic_syllabic_category} <- fetch(indic_syllabic_category) do
      Enum.reduce(indic_syllabic_category, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the Indic syllabic category name(s) for the given binary or codepoint.

  ### Arguments

  * `codepoint_or_string` is either an integer codepoint or a string.

  ### Returns

  * In the case of a codepoint, a single Indic syllabic category name as an atom. Codepoints with no explicit Indic syllabic category default to `:other`.

  * In the case of a string, a list of the distinct Indic syllabic category names represented by the codepoints in the string.

  ### Examples

      iex> Unicode.IndicSyllabicCategory.indic_syllabic_category(0x094D)
      :virama

      iex> Unicode.IndicSyllabicCategory.indic_syllabic_category(?A)
      :other

  """
  def indic_syllabic_category(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&indic_syllabic_category/1)
    |> Enum.uniq()
  end

  def indic_syllabic_category(codepoint)
      when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    Unicode.RangeSearch.find(@indic_syllabic_category_table, codepoint, :other)
  end
end
