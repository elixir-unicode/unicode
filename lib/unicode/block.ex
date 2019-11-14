defmodule Cldr.Unicode.Block do
  @moduledoc false
  alias Cldr.Unicode.Utils

  @blocks Utils.blocks()
  |> Utils.remove_annotations

  def blocks do
    @blocks
  end

  @known_blocks Map.keys(@blocks)
  def known_blocks do
    @known_blocks
  end

  @doc """
  Returns the count of the number of characters
  for a given block.

  ## Example

      iex> Cldr.Unicode.Block.count(:old_north_arabian)
      32

  """
  def count(block) do
    blocks()
    |> Map.get(block)
    |> Enum.reduce(0, fn {from, to}, acc -> acc + to - from + 1 end)
  end

  def block(string) when is_binary(string) do
    string
    |> String.codepoints()
    |> Enum.flat_map(&Utils.binary_to_codepoints/1)
    |> Enum.map(&block/1)
    |> Enum.uniq()
  end

  for {block, ranges} <- @blocks do
    def block(codepoint) when unquote(Utils.ranges_to_guard_clause(ranges)) do
      unquote(block)
    end
  end

  def block(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    nil
  end
end