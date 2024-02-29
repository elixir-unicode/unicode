defmodule Unicode.WordBreak do
  @moduledoc """
  Functions to introspect Unicode word breaks for
  string and codepoints.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @word_breaks Utils.word_breaks()
               |> Utils.remove_annotations()

  @doc """
  Returns the map of Unicode
  word breaks.

  The word break name is the map
  key and a list of codepoint
  ranges as tuples as the value.

  """

  def word_breaks do
    @word_breaks
  end

  @doc """
  Returns a list of known Unicode
  word break names.

  This function does not return the
  names of any word break aliases.

  """
  @known_word_breaks Map.keys(@word_breaks)
  def known_word_breaks do
    @known_word_breaks
  end

  @word_break_alias Utils.property_value_alias()
                    |> Map.get("wb")
                    |> Utils.invert_map()
                    |> Utils.atomize_values()
                    |> Utils.downcase_keys_and_remove_whitespace()
                    |> Utils.add_canonical_alias()

  @doc """
  Returns a map of aliases for
  Unicode word breaks.

  An alias is an alternative name
  for referring to a word break. Aliases
  are resolved by the `fetch/1` and
  `get/1` functions.

  """
  @impl Unicode.Property.Behaviour
  def aliases do
    @word_break_alias
  end

  @doc """
  Returns the Unicode ranges for
  a given word break as a list of
  ranges as 2-tuples.

  Aliases are resolved by this function.

  Returns either `{:ok, range_list}` or
  `:error`.

  """
  @impl Unicode.Property.Behaviour
  def fetch(word_break) when is_atom(word_break) do
    Map.fetch(word_breaks(), word_break)
  end

  def fetch(word_break) do
    word_break = Utils.downcase_and_remove_whitespace(word_break)
    word_break = Map.get(aliases(), word_break, word_break)
    Map.fetch(word_breaks(), word_break)
  end

  @doc """
  Returns the Unicode ranges for
  a given word break as a list of
  ranges as 2-tuples.

  Aliases are resolved by this function.

  Returns either `range_list` or
  `nil`.

  """
  @impl Unicode.Property.Behaviour
  def get(word_break) do
    case fetch(word_break) do
      {:ok, word_break} -> word_break
      _ -> nil
    end
  end

  @doc """
  Returns the count of the number of characters
  for a given word_break.

  ## Example

      iex> Unicode.WordBreak.count(:al)
      21400

  """
  @impl Unicode.Property.Behaviour
  def count(word_break) do
    with {:ok, word_break} <- fetch(word_break) do
      Enum.reduce(word_break, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the word break name(s) for the
  given binary or codepoint.

  In the case of a codepoint, a single
  word_break name is returned.

  For a binary a list of distinct word break
  names represented by the lines in
  the binary is returned.

  A value of `:xx` indicates there is no word
  break property for a codepoint.

  """
  def word_break(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&word_break/1)
  end

  for {word_break, ranges} <- @word_breaks do
    def word_break(codepoint) when unquote(Utils.ranges_to_guard_clause(ranges)) do
      unquote(word_break)
    end
  end

  def word_break(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    :xx
  end
end
