defmodule Unicode.GeneralCategory do
  @moduledoc """
  Functions to introspect Unicode
  general categories for binaries
  (Strings) and codepoints.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  # These categories are derived but expected to exist.
  # assigned is any - Cn
  @derived_categories %{
    ascii: [{0x0, 0x7f}]
    assigned: [{0, 887}, {890, 2159}, {2208, 2228}, {2230, 12255}, {12272, 12283}, {12288, 66047}, {66176, 66204}, {66208, 66527}, {66560, 66717}, {66720, 66927}, {67072, 67382}, {67392, 67455}, {67584, 67589}, {67592, 67759}, {67808, 67826}, {67828, 67903}, {67968, 68023}, {68028, 68255}, {68288, 68326}, {68331, 68527}, {68736, 68786}, {68800, 68927}, {69376, 69415}, {69424, 69487}, {69600, 69622}, {69632, 70223}, {70272, 70278}, {70280, 70527}, {70656, 70745}, {70747, 70879}, {71040, 71093}, {71096, 71375}, {71424, 71450}, {71453, 71487}, {71840, 71922}, {71935, 71935}, {72096, 72103}, {72106, 72367}, {72704, 72712}, {72714, 72895}, {72960, 72966}, {72968, 73135}, {73664, 73713}, {73727, 75087}, {77824, 78894}, {78896, 78911}, {92160, 92728}, {92736, 92783}, {92880, 92909}, {92912, 93071}, {93952, 94026}, {94031, 94111}, {94176, 94179}, {94208, 101119}, {110592, 110878}, {110928, 111359}, {113664, 113770}, {113776, 113839}, {118784, 119029}, {119040, 119375}, {119520, 119539}, {119552, 119679}, {119808, 119892}, {119894, 121519}, {122880, 122886}, {122888, 122927}, {123136, 123180}, {123184, 123215}, {123584, 123641}, {123647, 123647}, {124928, 125124}, {125127, 125151}, {125184, 125259}, {125264, 125279}, {126065, 126143}, {126209, 126287}, {126464, 126467}, {126469, 126719}, {126976, 127019}, {127024, 129791}, {173824, 177972}, {177984, 191471}, {917505, 917631}, {917760, 917999}, {983040, 1048573}, {1048576, 1114111}]
    any: [{0x0, 0x10ffff}]
  }

  @categories Utils.categories()
              |> Utils.remove_annotations()

  @super_categories @categories
                    |> Map.keys()
                    |> Enum.map(&to_string/1)
                    |> Enum.group_by(&String.slice(&1, 0, 1))
                    |> Enum.map(fn {k, v} ->
                      {String.to_atom(k),
                       Enum.flat_map(v, &Map.get(@categories, String.to_atom(&1))) |> Enum.sort()}
                    end)
                    |> Map.new()

  @all_categories Map.merge(@categories, @super_categories)
    |> Map.merge(@derived_categories)

  @doc """
  Returns the map of Unicode
  character categories.

  The category name is the map
  key and a list of codepoint
  ranges as tuples as the value.

  """
  def categories do
    @all_categories
  end

  @doc """
  Returns a list of known Unicode
  category names.

  This function does not return the
  names of any category aliases.

  """
  @known_categories Map.keys(@all_categories)
  def known_categories do
    @known_categories
  end

  @category_alias Utils.property_value_alias()
                  |> Map.get("gc")
                  |> Utils.capitalize_values()
                  |> Utils.atomize_values()
                  |> Utils.downcase_keys_and_remove_whitespace()
                  |> Utils.add_canonical_alias()

  @doc """
  Returns a map of aliases for
  Unicode categories.

  An alias is an alternative name
  for referring to a category. Aliases
  are resolved by the `fetch/1` and
  `get/1` functions.

  """
  @impl Unicode.Property.Behaviour
  def aliases do
    @category_alias
  end

  @doc """
  Returns the Unicode ranges for
  a given category as a list of
  ranges as 2-tuples.

  Aliases are resolved by this function.

  Returns either `{:ok, range_list}` or
  `:error`.

  """
  @impl Unicode.Property.Behaviour
  def fetch(:any) do
    [{0x0, 0x10ffff}]
  end

  def fetch(:assigned) do

  end

  def fetch(:ascii) do
    [{0x0, 0x7f}]
  end

  def fetch(category) when is_atom(category) do
    Map.fetch(categories(), category)
  end

  def fetch(category) do
    category = Utils.downcase_and_remove_whitespace(category)
    category = Map.get(aliases(), category, category)
    Map.fetch(categories(), category)
  end

  @doc """
  Returns the Unicode ranges for
  a given category as a list of
  ranges as 2-tuples.

  Aliases are resolved by this function.

  Returns either `range_list` or
  `nil`.

  """
  @impl Unicode.Property.Behaviour
  def get(category) do
    case fetch(category) do
      {:ok, category} -> category
      _ -> nil
    end
  end

  @doc """
  Return the count of characters in a given
  category.

  ## Example

      iex> Unicode.GeneralCategory.count(:Ll)
      2151

      iex> Unicode.GeneralCategory.count(:Nd)
      630

  """
  @impl Unicode.Property.Behaviour
  def count(category) do
    with {:ok, category} <- fetch(category) do
      Enum.reduce(category, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the category name(s) for the
  given binary or codepoint.

  In the case of a codepoint, a single
  category name is returned.

  For a binary a list of distinct category
  names represented by the graphemes in
  the binary is returned.

  """
  def category(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&category/1)
    |> Enum.uniq()
  end

  for {category, ranges} <- @categories do
    def category(codepoint) when unquote(Utils.ranges_to_guard_clause(ranges)) do
      unquote(category)
    end
  end

  def category(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    :Cn
  end
end
