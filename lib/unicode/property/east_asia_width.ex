defmodule Unicode.EastAsianWidth do
  @moduledoc """
  Functions to introspect the Unicode east asian width property for binaries (Strings) and codepoints.

  The primary API is `east_asian_width_category/1` which returns the east asian width category of a codepoint, or the list of east asian width categories of a string.

  The functions `fetch/1`, `get/1` and `count/1` provide introspection of the codepoint ranges belonging to an east asian width category. `east_asian_width_categories/0`, `known_east_asian_width_categories/0` and `aliases/0` return the underlying east asian width data.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @east_asian_width_categories Utils.east_asian_width()
                               |> Utils.remove_annotations()

  @east_asian_width_table Unicode.RangeSearch.new_value_table(@east_asian_width_categories)

  @doc """
  Returns the map of Unicode east asian width categories.

  ### Returns

  * A map where the east asian width category name is the key and a list of codepoint ranges as 2-tuples is the value.

  ### Examples

      iex> Unicode.EastAsianWidth.east_asian_width_categories() |> Map.get(:f)
      [{12288, 12288}, {65281, 65376}, {65504, 65510}]

  """
  def east_asian_width_categories do
    @east_asian_width_categories
  end

  @doc """
  Returns a list of known Unicode east asian width category names.

  This function does not return the names of any east asian width category aliases.

  ### Returns

  * A list of atom east asian width category names.

  ### Examples

      iex> :na in Unicode.EastAsianWidth.known_east_asian_width_categories()
      true

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
  Returns a map of aliases for Unicode east asian width categories.

  An alias is an alternative name for referring to an east asian width category. Aliases are resolved by the `fetch/1` and `get/1` functions.

  ### Returns

  * A map where the alias string is the key and the east asian width category name is the value.

  ### Examples

      iex> Unicode.EastAsianWidth.aliases() |> Map.get("fullwidth")
      :f

  """
  @impl Unicode.Property.Behaviour
  def aliases do
    @east_asian_width_alias
  end

  @doc """
  Returns the Unicode codepoint ranges for a given east asian width category.

  Aliases are resolved by this function.

  ### Arguments

  * `east_asian_width_category` is any east asian width category name or alias, as an atom or string.

  ### Returns

  * `{:ok, range_list}` where `range_list` is a list of codepoint ranges as 2-tuples.

  * `:error` if the east asian width category is not known.

  ### Examples

      iex> Unicode.EastAsianWidth.fetch(:f)
      {:ok, [{12288, 12288}, {65281, 65376}, {65504, 65510}]}

      iex> Unicode.EastAsianWidth.fetch(:invalid)
      :error

  """
  @impl Unicode.Property.Behaviour
  def fetch(east_asian_width_category) when is_atom(east_asian_width_category) do
    Map.fetch(east_asian_width_categories(), east_asian_width_category)
  end

  def fetch(east_asian_width_category) do
    east_asian_width_category = Utils.downcase_and_remove_whitespace(east_asian_width_category)

    east_asian_width_category =
      Map.get(aliases(), east_asian_width_category, east_asian_width_category)

    Map.fetch(east_asian_width_categories(), east_asian_width_category)
  end

  @doc """
  Returns the Unicode codepoint ranges for a given east asian width category.

  Aliases are resolved by this function.

  ### Arguments

  * `east_asian_width_category` is any east asian width category name or alias, as an atom or string.

  ### Returns

  * A list of codepoint ranges as 2-tuples.

  * `nil` if the east asian width category is not known.

  ### Examples

      iex> Unicode.EastAsianWidth.get(:f)
      [{12288, 12288}, {65281, 65376}, {65504, 65510}]

      iex> Unicode.EastAsianWidth.get(:invalid)
      nil

  """
  @impl Unicode.Property.Behaviour
  def get(east_asian_width_category) do
    case fetch(east_asian_width_category) do
      {:ok, east_asian_width_category} -> east_asian_width_category
      _ -> nil
    end
  end

  @doc """
  Returns the count of characters in a given east asian width category.

  Aliases are resolved by this function.

  ### Arguments

  * `east_asian_width_category` is any east asian width category name or alias, as an atom or string.

  ### Returns

  * A non-negative integer count of the codepoints in the east asian width category.

  * `:error` if the east asian width category is not known.

  ### Examples

      iex> Unicode.EastAsianWidth.count(:f)
      104

  """
  @impl Unicode.Property.Behaviour
  def count(east_asian_width_category) do
    with {:ok, east_asian_width_category} <- fetch(east_asian_width_category) do
      Enum.reduce(east_asian_width_category, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the east asian width category name(s) for the given binary or codepoint.

  ### Arguments

  * `string_or_codepoint` is either a binary (String) or a codepoint in the range `0..0x10FFFF`.

  ### Returns

  * For a codepoint, a single east asian width category name is returned.

  * For a binary, a list of the distinct east asian width category names of the codepoints in the binary is returned.

  ### Examples

      iex> Unicode.EastAsianWidth.east_asian_width_category(0xFF01)
      :f

      iex> Unicode.EastAsianWidth.east_asian_width_category("abc")
      [:na]

  """
  def east_asian_width_category(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&east_asian_width_category/1)
    |> Enum.uniq()
  end

  def east_asian_width_category(codepoint)
      when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    Unicode.RangeSearch.find(@east_asian_width_table, codepoint, :other)
  end
end
