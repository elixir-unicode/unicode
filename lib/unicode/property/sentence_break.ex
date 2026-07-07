defmodule Unicode.SentenceBreak do
  @moduledoc """
  Functions to introspect the Unicode sentence break property for binaries (Strings) and codepoints.

  The primary API is `sentence_break/1` which returns the sentence break property for a codepoint or the list of sentence break properties for a string.

  The functions `fetch/1`, `get/1` and `count/1` provide introspection of the codepoint ranges associated with a given sentence break property. `sentence_breaks/0`, `known_sentence_breaks/0` and `aliases/0` return the underlying property data.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @sentence_breaks Utils.sentence_breaks()
                   |> Utils.remove_annotations()

  @sentence_break_table Unicode.RangeSearch.new_value_table(@sentence_breaks)

  @doc """
  Returns the map of Unicode sentence breaks.

  ### Returns

  * A map with the sentence break name as the key and a list of codepoint ranges as 2-tuples as the value.

  ### Examples

      iex> Unicode.SentenceBreak.sentence_breaks() |> Map.get(:cr)
      [{13, 13}]

  """

  def sentence_breaks do
    @sentence_breaks
  end

  @doc """
  Returns a list of known Unicode sentence break names.

  This function does not return the names of any sentence break aliases.

  ### Returns

  * A list of sentence break names as atoms.

  ### Examples

      iex> Unicode.SentenceBreak.known_sentence_breaks() |> Enum.sort() |> Enum.take(3)
      [:aterm, :close, :cr]

  """
  @known_sentence_breaks Map.keys(@sentence_breaks)
  def known_sentence_breaks do
    @known_sentence_breaks
  end

  @sentence_break_alias Utils.property_value_alias()
                        |> Map.get("sb")
                        |> Utils.invert_map()
                        |> Utils.atomize_values()
                        |> Utils.downcase_keys_and_remove_whitespace()
                        |> Utils.add_canonical_alias()

  @doc """
  Returns a map of aliases for Unicode sentence breaks.

  An alias is an alternative name for referring to a sentence break. Aliases are resolved by the `fetch/1` and `get/1` functions.

  ### Returns

  * A map with the alias as a string key and the sentence break name as an atom value.

  ### Examples

      iex> Unicode.SentenceBreak.aliases() |> Map.get("up")
      :upper

  """
  @impl Unicode.Property.Behaviour
  def aliases do
    @sentence_break_alias
  end

  @doc """
  Returns the Unicode codepoint ranges for a given sentence break.

  Aliases are resolved by this function.

  ### Arguments

  * `sentence_break` is any sentence break name as an atom, or a string alias for a sentence break.

  ### Returns

  * `{:ok, range_list}` where `range_list` is a list of codepoint ranges as 2-tuples.

  * `:error` if the sentence break name is not known.

  ### Examples

      iex> Unicode.SentenceBreak.fetch(:cr)
      {:ok, [{13, 13}]}

      iex> Unicode.SentenceBreak.fetch(:invalid)
      :error

  """
  @impl Unicode.Property.Behaviour
  def fetch(sentence_break) when is_atom(sentence_break) do
    Map.fetch(sentence_breaks(), sentence_break)
  end

  def fetch(sentence_break) do
    sentence_break = Utils.downcase_and_remove_whitespace(sentence_break)
    sentence_break = Map.get(aliases(), sentence_break, sentence_break)
    Map.fetch(sentence_breaks(), sentence_break)
  end

  @doc """
  Returns the Unicode codepoint ranges for a given sentence break.

  Aliases are resolved by this function.

  ### Arguments

  * `sentence_break` is any sentence break name as an atom, or a string alias for a sentence break.

  ### Returns

  * `range_list` which is a list of codepoint ranges as 2-tuples.

  * `nil` if the sentence break name is not known.

  ### Examples

      iex> Unicode.SentenceBreak.get(:cr)
      [{13, 13}]

      iex> Unicode.SentenceBreak.get(:invalid)
      nil

  """
  @impl Unicode.Property.Behaviour
  def get(sentence_break) do
    case fetch(sentence_break) do
      {:ok, sentence_break} -> sentence_break
      _ -> nil
    end
  end

  @doc """
  Returns the count of the number of characters for a given sentence break.

  ### Arguments

  * `sentence_break` is any sentence break name as an atom, or a string alias for a sentence break.

  ### Returns

  * The number of codepoints that have the given sentence break.

  * `:error` if the sentence break name is not known.

  ### Examples

      iex> Unicode.SentenceBreak.count(:extend)
      2643

  """
  @impl Unicode.Property.Behaviour
  def count(sentence_break) do
    with {:ok, sentence_break} <- fetch(sentence_break) do
      Enum.reduce(sentence_break, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the sentence break name(s) for the given binary or codepoint.

  ### Arguments

  * `codepoint_or_string` is either an integer codepoint or a string.

  ### Returns

  * In the case of a codepoint, a single sentence break name as an atom. Codepoints with no explicit sentence break property default to `:other`.

  * In the case of a string, a list of the distinct sentence break names represented by the codepoints in the string.

  ### Examples

      iex> Unicode.SentenceBreak.sentence_break(?A)
      :upper

      iex> Unicode.SentenceBreak.sentence_break("Aa")
      [:upper, :lower]

  """
  def sentence_break(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&sentence_break/1)
    |> Enum.uniq()
  end

  def sentence_break(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    Unicode.RangeSearch.find(@sentence_break_table, codepoint, :other)
  end
end
