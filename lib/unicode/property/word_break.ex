defmodule Unicode.WordBreak do
  @moduledoc """
  Functions to introspect the Unicode word break property for binaries (Strings) and codepoints.

  The primary API is `word_break/1` which returns the word break property for a codepoint or the list of word break properties for a string.

  The functions `fetch/1`, `get/1` and `count/1` provide introspection of the codepoint ranges associated with a given word break property. `word_breaks/0`, `known_word_breaks/0` and `aliases/0` return the underlying property data.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @word_breaks Utils.word_breaks()
               |> Utils.remove_annotations()

  @word_break_table Unicode.RangeSearch.new_value_table(@word_breaks)

  @doc """
  Returns the map of Unicode word breaks.

  ### Returns

  * A map with the word break name as the key and a list of codepoint ranges as 2-tuples as the value.

  ### Examples

      iex> Unicode.WordBreak.word_breaks() |> Map.get(:zwj)
      [{8205, 8205}]

  """

  def word_breaks do
    @word_breaks
  end

  @doc """
  Returns a list of known Unicode word break names.

  This function does not return the names of any word break aliases.

  ### Returns

  * A list of word break names as atoms.

  ### Examples

      iex> Unicode.WordBreak.known_word_breaks() |> Enum.sort() |> Enum.take(3)
      [:aletter, :cr, :double_quote]

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
  Returns a map of aliases for Unicode word breaks.

  An alias is an alternative name for referring to a word break. Aliases are resolved by the `fetch/1` and `get/1` functions.

  ### Returns

  * A map with the alias as a string key and the word break name as an atom value.

  ### Examples

      iex> Unicode.WordBreak.aliases() |> Map.get("le")
      :aletter

  """
  @impl Unicode.Property.Behaviour
  def aliases do
    @word_break_alias
  end

  @doc """
  Returns the Unicode codepoint ranges for a given word break.

  Aliases are resolved by this function.

  ### Arguments

  * `word_break` is any word break name as an atom, or a string alias for a word break.

  ### Returns

  * `{:ok, range_list}` where `range_list` is a list of codepoint ranges as 2-tuples.

  * `:error` if the word break name is not known.

  ### Examples

      iex> Unicode.WordBreak.fetch(:zwj)
      {:ok, [{8205, 8205}]}

      iex> Unicode.WordBreak.fetch(:invalid)
      :error

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
  Returns the Unicode codepoint ranges for a given word break.

  Aliases are resolved by this function.

  ### Arguments

  * `word_break` is any word break name as an atom, or a string alias for a word break.

  ### Returns

  * `range_list` which is a list of codepoint ranges as 2-tuples.

  * `nil` if the word break name is not known.

  ### Examples

      iex> Unicode.WordBreak.get(:zwj)
      [{8205, 8205}]

      iex> Unicode.WordBreak.get(:invalid)
      nil

  """
  @impl Unicode.Property.Behaviour
  def get(word_break) do
    case fetch(word_break) do
      {:ok, word_break} -> word_break
      _ -> nil
    end
  end

  @doc """
  Returns the count of the number of characters for a given word break.

  ### Arguments

  * `word_break` is any word break name as an atom, or a string alias for a word break.

  ### Returns

  * The number of codepoints that have the given word break.

  * `:error` if the word break name is not known.

  ### Examples

      iex> Unicode.WordBreak.count(:aletter)
      33973

  """
  @impl Unicode.Property.Behaviour
  def count(word_break) do
    with {:ok, word_break} <- fetch(word_break) do
      Enum.reduce(word_break, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the word break name(s) for the given binary or codepoint.

  ### Arguments

  * `codepoint_or_string` is either an integer codepoint or a string.

  ### Returns

  * In the case of a codepoint, a single word break name as an atom. Codepoints with no explicit word break property default to `:xx`.

  * In the case of a string, a list of the word break names for each codepoint in the string, in order. One entry is returned for each codepoint.

  ### Examples

      iex> Unicode.WordBreak.word_break(0x200D)
      :zwj

      iex> Unicode.WordBreak.word_break("A")
      [:aletter]

  """
  def word_break(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&word_break/1)
  end

  def word_break(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    Unicode.RangeSearch.find(@word_break_table, codepoint, :xx)
  end
end
