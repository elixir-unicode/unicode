defmodule Unicode.Emoji do
  @moduledoc false

  alias Unicode.{Utils, Property}

  @emoji Utils.emoji()
         |> Utils.remove_reserved_codepoints()
         |> Utils.remove_annotations()

  def emoji do
    @emoji
  end

  @known_emoji_categories Map.keys(@emoji)
  def known_emoji_categories do
    @known_emoji_categories
  end

  def count(emoji_category) do
    emoji()
    |> Map.get(emoji_category)
    |> Enum.reduce(0, fn {from, to}, acc -> acc + to - from + 1 end)
  end

  for {emoji_category, ranges} <- @emoji,
      range <- ranges do
    case range do
      {first, first} when is_integer(first) ->
        def emoji(unquote(first)), do: unquote(emoji_category)

      {first, last} when is_integer(first) and is_integer(last) ->
        def emoji(codepoint) when codepoint in unquote(first)..unquote(last),
          do: unquote(emoji_category)

      {first, first} when is_list(first) ->
        def emoji(unquote(first)), do: unquote(emoji_category)
    end
  end

  def emoji(string) when is_binary(string) do
    string
    |> String.graphemes()
    |> Enum.map(&String.to_charlist/1)
    |> Enum.map(&emoji/1)
  end

  def emoji(_codepoint) do
    nil
  end

  @doc """
  Returns a boolean based upon
  whether the given codepoint or binary
  is all emoji characters.

  Note that some characters are unexpectedly
  emoji because they are part of a multicodepoint
  combination. For example, the numbers `0` through
  `9` are emoji because they form part of the `keycap`
  emoji codepoints.

  ## Example

      iex> Unicode.Emoji.emoji? "🔥"
      true
      iex> Unicode.Emoji.emoji? "1"
      true
      iex> Unicode.Emoji.emoji? "abc"
      false

  """
  def emoji?(codepoint_or_binary)

  def emoji?(codepoint) when is_integer(codepoint) do
    ignorable?(codepoint) ||
      emoji(codepoint) in known_emoji_categories()
  end

  def emoji?(string) when is_binary(string) do
    Property.string_has_property?(string, &emoji?/1)
  end

  def emoji?(_), do: false

  defp ignorable?(codepoint) do
    properties = Property.properties(codepoint)
    :case_ignorable in properties || :default_ignorable_codepoint in properties
  end
end
