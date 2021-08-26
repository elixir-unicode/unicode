defmodule Unicode.SentenceBreak do
  @moduledoc """
  Functions to introspect Unicode
  sentence breaks for binaries
  (Strings) and codepoints.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @sentence_breaks Utils.sentence_breaks()
                   |> Utils.remove_annotations()

  @doc """
  Returns the map of Unicode
  sentence breaks.

  The sentence break name is the map
  key and a list of codepoint
  ranges as tuples as the value.

  """

  def sentence_breaks do
    @sentence_breaks
  end

  @doc """
  Returns a list of known Unicode
  sentence break names.

  This function does not return the
  names of any sentence break aliases.

  """
  @known_sentence_breaks Map.keys(@sentence_breaks)
  def known_sentence_breaks do
    @known_sentence_breaks
  end

  @sentence_break_alias Utils.property_value_alias()
                        |> Map.get("sb")
                        |> Utils.invert_map
                        |> Utils.atomize_values()
                        |> Utils.downcase_keys_and_remove_whitespace()
                        |> Utils.add_canonical_alias()

  @doc """
  Returns a map of aliases for
  Unicode sentence breaks.

  An alias is an alternative name
  for referring to a sentence break. Aliases
  are resolved by the `fetch/1` and
  `get/1` functions.

  """
  @impl Unicode.Property.Behaviour
  def aliases do
    @sentence_break_alias
  end

  @doc """
  Returns the Unicode ranges for
  a given sentence break as a list of
  ranges as 2-tuples.

  Aliases are resolved by this function.

  Returns either `{:ok, range_list}` or
  `:error`.

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
  Returns the Unicode ranges for
  a given sentence break as a list of
  ranges as 2-tuples.

  Aliases are resolved by this function.

  Returns either `range_list` or
  `nil`.

  """
  @impl Unicode.Property.Behaviour
  def get(sentence_break) do
    case fetch(sentence_break) do
      {:ok, sentence_break} -> sentence_break
      _ -> nil
    end
  end

  @doc """
  Returns the count of the number of characters
  for a given sentence break.

  ## Example

      iex> Unicode.SentenceBreak.count(:extend)
      2508

  """
  @impl Unicode.Property.Behaviour
  def count(sentence_break) do
    with {:ok, sentence_break} <- fetch(sentence_break) do
      Enum.reduce(sentence_break, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the sentence break name(s) for the
  given binary or codepoint.

  In the case of a codepoint, a single
  sentence break name is returned.

  For a binary a list of distinct sentence break
  names represented by the graphemes in
  the binary is returned.

  """
  def sentence_break(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&sentence_break/1)
    |> Enum.uniq()
  end

  for {sentence_break, ranges} <- @sentence_breaks do
    def sentence_break(codepoint) when unquote(Utils.ranges_to_guard_clause(ranges)) do
      unquote(sentence_break)
    end
  end

  def sentence_break(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    :other
  end
end
