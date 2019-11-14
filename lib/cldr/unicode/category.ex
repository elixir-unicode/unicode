defmodule Unicode.Category do
  @moduledoc false

  alias Unicode.Utils

  @categories Utils.categories()
  |> Utils.remove_annotations

  def categories do
    @categories
  end

  @known_categories Map.keys(@categories)
  def known_categories do
    @known_categories
  end

  @doc """
  Return the count of characters in a given
  category.

  ## Example

      iex> Unicode.Category.count(:Ll)
      2151

      iex> Unicode.Category.count(:Nd)
      630

  """
  def count(category) do
    categories()
    |> Map.get(category)
    |> Enum.reduce(0, fn {from, to}, acc -> acc + to - from + 1 end)
  end

  def category(string) when is_binary(string) do
    string
    |> String.codepoints()
    |> Enum.flat_map(&Utils.binary_to_codepoints/1)
    |> Enum.map(&category/1)
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
