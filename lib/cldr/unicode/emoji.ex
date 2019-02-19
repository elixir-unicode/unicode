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

  def emoji(string) when is_binary(string) do
    string
    |> String.codepoints()
    |> Enum.flat_map(&Utils.binary_to_codepoints/1)
    |> Enum.map(&emoji/1)
  end

  for {emoji_category, ranges} <- @emoji do
    def emoji(codepoint) when unquote(Utils.ranges_to_guard_clause(ranges)) do
      unquote(emoji_category)
    end
  end

  def emoji(_codepoint) do
    nil
  end
end
