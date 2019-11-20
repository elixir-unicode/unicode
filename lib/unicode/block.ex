defmodule Unicode.Block do
  @moduledoc false

  alias Unicode.Utils

  @blocks Utils.blocks()
          |> Utils.remove_annotations()

  def blocks do
    @blocks
  end

  @known_blocks Map.keys(@blocks)
  def known_blocks do
    @known_blocks
  end

  @block_alias Utils.property_value_alias()
  |> Map.get("blk")
  |> Enum.flat_map(fn
    [code, alias1] ->
      [{String.downcase(alias1), String.to_atom(code)},
      {String.downcase(code), String.to_atom(code)}]
    [code, alias1, alias2] ->
      [{String.downcase(alias1), String.to_atom(code)},
      {String.downcase(alias2), String.to_atom(code)},
      {String.downcase(code), String.to_atom(code)}]
  end)
  |> Map.new

  def aliases do
    @block_alias
  end

  def fetch(block) do
    block = Map.get(aliases(), block, block)
    Map.fetch(blocks(), block)
  end

  def get(block) do
    case fetch(block) do
      {:ok, block} -> block
      _ -> nil
    end
  end

  @doc """
  Returns the count of the number of characters
  for a given block.

  ## Example

      iex> Unicode.Block.count(:old_north_arabian)
      32

  """
  def count(block) do
    with {:ok, block} <- fetch(block) do
      Enum.reduce(block, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
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

  @doc """
  Returns a list of tuples representing the
  valid ranges of Unicode code points.

  This information is derived from the block
  ranges as defined by `Unicode.Block.blocks/0`.

  """
  @ranges @blocks
          |> Map.values()
          |> Enum.map(&hd/1)
          |> Enum.sort()

  def ranges do
    @ranges
  end
end
