defmodule Unicode.GraphemeClusterBreak do
  @moduledoc """
  Functions to introspect the Unicode grapheme cluster break property for binaries (Strings) and codepoints.

  The primary API is `grapheme_break/1` which returns the grapheme cluster break property for a codepoint or the list of grapheme cluster break properties for a string.

  The functions `fetch/1`, `get/1` and `count/1` provide introspection of the codepoint ranges associated with a given grapheme cluster break property. `grapheme_breaks/0`, `known_grapheme_breaks/0` and `aliases/0` return the underlying property data.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @grapheme_breaks Utils.grapheme_breaks()
                   |> Utils.remove_annotations()

  @grapheme_break_table Unicode.RangeSearch.new_value_table(@grapheme_breaks)

  @doc """
  Returns the map of Unicode grapheme cluster breaks.

  ### Returns

  * A map with the grapheme cluster break name as the key and a list of codepoint ranges as 2-tuples as the value.

  ### Examples

      iex> Unicode.GraphemeClusterBreak.grapheme_breaks() |> Map.get(:zwj)
      [{8205, 8205}]

  """

  def grapheme_breaks do
    @grapheme_breaks
  end

  @doc """
  Returns a list of known Unicode grapheme cluster break names.

  This function does not return the names of any grapheme cluster break aliases.

  ### Returns

  * A list of grapheme cluster break names as atoms.

  ### Examples

      iex> Unicode.GraphemeClusterBreak.known_grapheme_breaks() |> Enum.sort() |> Enum.take(3)
      [:control, :cr, :extend]

  """
  @known_grapheme_breaks Map.keys(@grapheme_breaks)
  def known_grapheme_breaks do
    @known_grapheme_breaks
  end

  @grapheme_break_alias Utils.property_value_alias()
                        |> Map.get("gcb")
                        |> Utils.invert_map()
                        |> Utils.atomize_values()
                        |> Utils.downcase_keys_and_remove_whitespace()
                        |> Utils.add_canonical_alias()

  @doc """
  Returns a map of aliases for Unicode grapheme cluster breaks.

  An alias is an alternative name for referring to a grapheme cluster break. Aliases are resolved by the `fetch/1` and `get/1` functions.

  ### Returns

  * A map with the alias as a string key and the grapheme cluster break name as an atom value.

  ### Examples

      iex> Unicode.GraphemeClusterBreak.aliases() |> Map.get("zwj")
      :zwj

  """
  @impl Unicode.Property.Behaviour
  def aliases do
    @grapheme_break_alias
  end

  @doc """
  Returns the Unicode codepoint ranges for a given grapheme cluster break.

  Aliases are resolved by this function.

  ### Arguments

  * `grapheme_break` is any grapheme cluster break name as an atom, or a string alias for a grapheme cluster break.

  ### Returns

  * `{:ok, range_list}` where `range_list` is a list of codepoint ranges as 2-tuples.

  * `:error` if the grapheme cluster break name is not known.

  ### Examples

      iex> Unicode.GraphemeClusterBreak.fetch(:zwj)
      {:ok, [{8205, 8205}]}

      iex> Unicode.GraphemeClusterBreak.fetch(:invalid)
      :error

  """
  @impl Unicode.Property.Behaviour
  def fetch(grapheme_break) when is_atom(grapheme_break) do
    Map.fetch(grapheme_breaks(), grapheme_break)
  end

  def fetch(grapheme_break) do
    grapheme_break = Utils.downcase_and_remove_whitespace(grapheme_break)
    grapheme_break = Map.get(aliases(), grapheme_break, grapheme_break)
    Map.fetch(grapheme_breaks(), grapheme_break)
  end

  @doc """
  Returns the Unicode codepoint ranges for a given grapheme cluster break.

  Aliases are resolved by this function.

  ### Arguments

  * `grapheme_break` is any grapheme cluster break name as an atom, or a string alias for a grapheme cluster break.

  ### Returns

  * `range_list` which is a list of codepoint ranges as 2-tuples.

  * `nil` if the grapheme cluster break name is not known.

  ### Examples

      iex> Unicode.GraphemeClusterBreak.get(:zwj)
      [{8205, 8205}]

      iex> Unicode.GraphemeClusterBreak.get(:invalid)
      nil

  """
  @impl Unicode.Property.Behaviour
  def get(grapheme_break) do
    case fetch(grapheme_break) do
      {:ok, grapheme_break} -> grapheme_break
      _ -> nil
    end
  end

  @doc """
  Returns the count of the number of characters for a given grapheme cluster break.

  ### Arguments

  * `grapheme_break` is any grapheme cluster break name as an atom, or a string alias for a grapheme cluster break.

  ### Returns

  * The number of codepoints that have the given grapheme cluster break.

  * `:error` if the grapheme cluster break name is not known.

  ### Examples

      iex> Unicode.GraphemeClusterBreak.count(:prepend)
      27

  """
  @impl Unicode.Property.Behaviour
  def count(grapheme_break) do
    with {:ok, grapheme_break} <- fetch(grapheme_break) do
      Enum.reduce(grapheme_break, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the grapheme cluster break name(s) for the given binary or codepoint.

  ### Arguments

  * `codepoint_or_string` is either an integer codepoint or a string.

  ### Returns

  * In the case of a codepoint, a single grapheme cluster break name as an atom. Codepoints with no explicit grapheme cluster break property default to `:other`.

  * In the case of a string, a list of the distinct grapheme cluster break names represented by the codepoints in the string.

  ### Examples

      iex> Unicode.GraphemeClusterBreak.grapheme_break(0x200D)
      :zwj

      iex> Unicode.GraphemeClusterBreak.grapheme_break("A")
      [:other]

  """
  def grapheme_break(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&grapheme_break/1)
    |> Enum.uniq()
  end

  def grapheme_break(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    Unicode.RangeSearch.find(@grapheme_break_table, codepoint, :other)
  end
end
