defmodule Unicode.IndicSyllabicCategory do
  @moduledoc """
  Functions to introspect Unicode
  indic syllabic categories for binaries
  (Strings) and codepoints.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @indic_syllabic_categories Utils.indic_syllabic_categories()
                             |> Utils.remove_annotations()

  @doc """
  Returns the map of Unicode
  indic syllabic categorys.

  The indic syllabic category name is the map
  key and a list of codepoint
  ranges as tuples as the value.

  """

  def indic_syllabic_categories do
    @indic_syllabic_categories
  end

  @doc """
  Returns a list of known Unicode
  indic syllabic category names.

  This function does not return the
  names of any indic syllabic category aliases.

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
  Returns a map of aliases for
  Unicode indic syllabic categorys.

  An alias is an alternative name
  for referring to a indic syllabic category. Aliases
  are resolved by the `fetch/1` and
  `get/1` functions.

  """
  @impl Unicode.Property.Behaviour
  def aliases do
    @indic_syllabic_category_alias
  end

  @doc """
  Returns the Unicode ranges for
  a given indic syllabic category as a list of
  ranges as 2-tuples.

  Aliases are resolved by this function.

  Returns either `{:ok, range_list}` or
  `:error`.

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
  Returns the Unicode ranges for
  a given indic syllabic category as a list of
  ranges as 2-tuples.

  Aliases are resolved by this function.

  Returns either `range_list` or
  `nil`.

  """
  @impl Unicode.Property.Behaviour
  def get(indic_syllabic_category) do
    case fetch(indic_syllabic_category) do
      {:ok, indic_syllabic_category} -> indic_syllabic_category
      _ -> nil
    end
  end

  @doc """
  Returns the count of the number of characters
  for a given indic syllabic category.

  ## Example

      iex> Unicode.IndicSyllabicCategory.count(:bindu)
      91

  """
  @impl Unicode.Property.Behaviour
  def count(indic_syllabic_category) do
    with {:ok, indic_syllabic_category} <- fetch(indic_syllabic_category) do
      Enum.reduce(indic_syllabic_category, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the indic syllabic category name(s) for the
  given binary or codepoint.

  In the case of a codepoint, a single
  indic syllabic category name is returned.

  For a binary a list of distinct indic syllabic category
  names represented by the lines in
  the binary is returned.

  """
  def indic_syllabic_category(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&indic_syllabic_category/1)
    |> Enum.uniq()
  end

  for {indic_syllabic_category, ranges} <- @indic_syllabic_categories do
    def indic_syllabic_category(codepoint) when unquote(Utils.ranges_to_guard_clause(ranges)) do
      unquote(indic_syllabic_category)
    end
  end

  def indic_syllabic_category(codepoint)
      when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    :other
  end
end
