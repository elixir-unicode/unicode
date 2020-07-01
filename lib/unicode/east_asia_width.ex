defmodule Unicode.EastAsianWidth do
  @moduledoc """
  Functions to introspect Unicode
  east asian width categories for binaries
  (Strings) and codepoints.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @east_asian_width_categories Utils.east_asian_width()
                             |> Utils.remove_annotations()

  @doc """
  Returns the map of Unicode
  east asian width categorys.

  The east asian width category name is the map
  key and a list of codepoint
  ranges as tuples as the value.

  """

  def east_asian_width_categories do
    @east_asian_width_categories
  end

  @doc """
  Returns a list of known Unicode
  east asian width category names.

  This function does not return the
  names of any east asian width category aliases.

  """
  @known_east_asian_width_categories Map.keys(@east_asian_width_categories)
  def known_east_asian_width_categories do
    @known_east_asian_width_categories
  end

  @east_asian_width_alias Utils.property_value_alias()
                                 |> Map.get("ea")
                                 |> Utils.atomize_values()
                                 |> Utils.downcase_keys_and_remove_whitespace()
                                 |> Utils.add_canonical_alias()

  @doc """
  Returns a map of aliases for
  Unicode east asian width categorys.

  An alias is an alternative name
  for referring to a east asian width category. Aliases
  are resolved by the `fetch/1` and
  `get/1` functions.

  """
  @impl Unicode.Property.Behaviour
  def aliases do
    @east_asian_width_alias
  end

  @doc """
  Returns the Unicode ranges for
  a given east asian width category as a list of
  ranges as 2-tuples.

  Aliases are resolved by this function.

  Returns either `{:ok, range_list}` or
  `:error`.

  """
  @impl Unicode.Property.Behaviour
  def fetch(east_asian_width_category) when is_atom(east_asian_width_category) do
    Map.fetch(east_asian_width_categories(), east_asian_width_category)
  end

  def fetch(east_asian_width_category) do
    east_asian_width_category = Utils.downcase_and_remove_whitespace(east_asian_width_category)
    east_asian_width_category = Map.get(aliases(), east_asian_width_category, east_asian_width_category)
    Map.fetch(east_asian_width_categories(), east_asian_width_category)
  end

  @doc """
  Returns the Unicode ranges for
  a given east asian width category as a list of
  ranges as 2-tuples.

  Aliases are resolved by this function.

  Returns either `range_list` or
  `nil`.

  """
  @impl Unicode.Property.Behaviour
  def get(east_asian_width_category) do
    case fetch(east_asian_width_category) do
      {:ok, east_asian_width_category} -> east_asian_width_category
      _ -> nil
    end
  end

  @doc """
  Returns the count of the number of characters
  for a given east asian width category.

  ## Example

      iex> Unicode.IndicSyllabicCategory.count(:bindu)
      91

  """
  @impl Unicode.Property.Behaviour
  def count(east_asian_width_category) do
    with {:ok, east_asian_width_category} <- fetch(east_asian_width_category) do
      Enum.reduce(east_asian_width_category, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the east asian width category name(s) for the
  given binary or codepoint.

  In the case of a codepoint, a single
  east asian width category name is returned.

  For a binary a list of distinct east asian width category
  names represented by the lines in
  the binary is returned.

  """
  def east_asian_width_category(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&east_asian_width_category/1)
    |> Enum.uniq()
  end

  for {east_asian_width_category, ranges} <- @east_asian_width_categories do
    def east_asian_width_category(codepoint) when unquote(Utils.ranges_to_guard_clause(ranges)) do
      unquote(east_asian_width_category)
    end
  end

  def east_asian_width_category(codepoint)
      when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    :other
  end
end
