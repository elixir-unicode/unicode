defmodule Unicode.GraphemeClusterBreak do
  @moduledoc """
  Functions to introspect Unicode
  grapheme cluster breaks for binaries
  (Strings) and codepoints.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @grapheme_breaks Utils.grapheme_breaks()
                   |> Utils.remove_annotations()

  @doc """
  Returns the map of Unicode
  grapheme cluster breaks.

  The grapheme cluster break name is the map
  key and a list of codepoint
  ranges as tuples as the value.

  """

  def grapheme_breaks do
    @grapheme_breaks
  end

  @doc """
  Returns a list of known Unicode
  grapheme cluster break names.

  This function does not return the
  names of any grapheme cluster break aliases.

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
  Returns a map of aliases for
  Unicode grapheme cluster breaks.

  An alias is an alternative name
  for referring to a grapheme cluster break. Aliases
  are resolved by the `fetch/1` and
  `get/1` functions.

  """
  @impl Unicode.Property.Behaviour
  def aliases do
    @grapheme_break_alias
  end

  @doc """
  Returns the Unicode ranges for
  a given grapheme cluster break as a list of
  ranges as 2-tuples.

  Aliases are resolved by this function.

  Returns either `{:ok, range_list}` or
  `:error`.

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
  Returns the Unicode ranges for
  a given grapheme cluster break as a list of
  ranges as 2-tuples.

  Aliases are resolved by this function.

  Returns either `range_list` or
  `nil`.

  """
  @impl Unicode.Property.Behaviour
  def get(grapheme_break) do
    case fetch(grapheme_break) do
      {:ok, grapheme_break} -> grapheme_break
      _ -> nil
    end
  end

  @doc """
  Returns the count of the number of characters
  for a given grapheme cluster break.

  ## Example

      iex> Unicode.GraphemeClusterBreak.count(:prepend)
      26

  """
  @impl Unicode.Property.Behaviour
  def count(grapheme_break) do
    with {:ok, grapheme_break} <- fetch(grapheme_break) do
      Enum.reduce(grapheme_break, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the grapheme cluster break name(s) for the
  given binary or codepoint.

  In the case of a codepoint, a single
  grapheme cluster break name is returned.

  For a binary a list of distinct grapheme cluster break
  names represented by the graphemes in
  the binary is returned.

  """
  def grapheme_break(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&grapheme_break/1)
    |> Enum.uniq()
  end

  for {grapheme_break, ranges} <- @grapheme_breaks do
    def grapheme_break(codepoint) when unquote(Utils.ranges_to_guard_clause(ranges)) do
      unquote(grapheme_break)
    end
  end

  def grapheme_break(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    :other
  end
end
