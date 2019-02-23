defmodule Cldr.Unicode.Emoji do
  @moduledoc """
  Functions for identifying emoji which
  fall into the following categories:

  | Category	            |
  | ----------------------|
  | :emoji	              |
  | :emoji_component      |
  | :emoji_modifier	      |
  | :emoji_modifier_base	|
  | :emoji_presentation   |
  | :extended_pictograph	|

  """
  alias Cldr.Unicode.Utils

  @emoji Utils.emoji()
  |> Utils.remove_reserved_codepoints
  |> Utils.remove_annotations

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
end
