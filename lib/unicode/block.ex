defmodule Unicode.Block do
  @moduledoc """
  Functions to introspect the Unicode block property for binaries (Strings) and codepoints.

  The primary API is `block/1` which returns the block of a codepoint, or the list of blocks of a string.

  The functions `fetch/1`, `get/1` and `count/1` provide introspection of the codepoint ranges belonging to a block. `blocks/0`, `known_blocks/0` and `aliases/0` return the underlying block data.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @blocks Utils.blocks()
          |> Utils.remove_annotations()

  @block_table Unicode.RangeSearch.new_value_table(@blocks)

  @doc """
  Returns the map of Unicode blocks.

  ### Returns

  * A map where the block name is the key and a list of codepoint ranges as 2-tuples is the value.

  ### Examples

      iex> Unicode.Block.blocks() |> Map.get(:basic_latin)
      [{0, 127}]

  """
  def blocks do
    @blocks
  end

  @doc """
  Returns a list of known Unicode block names.

  This function does not return the names of any block aliases.

  ### Returns

  * A list of atom block names.

  ### Examples

      iex> :basic_latin in Unicode.Block.known_blocks()
      true

  """
  @known_blocks Map.keys(@blocks)
  def known_blocks do
    @known_blocks
  end

  # The PropertyValueAliases short/long names do not always normalise to the
  # same string as the Blocks.txt-derived key (e.g. `:latin_1_supplement`
  # normalises to "latin1supplement", which no PropertyValueAliases entry
  # produces). Merge a self-alias `normalise(key) => key` for every block so the
  # canonical block name always resolves regardless of digits, spaces, hyphens
  # or underscores.
  @block_canonical_alias Map.new(
                           Map.keys(@blocks),
                           &{Utils.downcase_and_remove_whitespace(&1), &1}
                         )

  @block_alias Utils.property_value_alias()
               |> Map.get("blk")
               |> Utils.invert_map()
               |> Utils.atomize_values()
               |> Utils.downcase_keys_and_remove_whitespace()
               |> Utils.add_canonical_alias()
               |> Map.merge(@block_canonical_alias)

  @doc """
  Returns a map of aliases for Unicode blocks.

  An alias is an alternative name for referring to a block. Aliases are resolved by the `fetch/1` and `get/1` functions.

  ### Returns

  * A map where the alias string is the key and the block name is the value.

  ### Examples

      iex> Unicode.Block.aliases() |> Map.get("ascii")
      :basic_latin

  """
  @impl Unicode.Property.Behaviour
  def aliases do
    @block_alias
  end

  @doc """
  Returns the Unicode codepoint ranges for a given block.

  Aliases are resolved by this function.

  ### Arguments

  * `block` is any block name or alias, as an atom or string.

  ### Returns

  * `{:ok, range_list}` where `range_list` is a list of codepoint ranges as 2-tuples.

  * `:error` if the block is not known.

  ### Examples

      iex> Unicode.Block.fetch(:basic_latin)
      {:ok, [{0, 127}]}

      iex> Unicode.Block.fetch(:invalid)
      :error

  """
  @impl Unicode.Property.Behaviour
  def fetch(block) when is_atom(block) do
    Map.fetch(blocks(), block)
  end

  def fetch(block) do
    block = Utils.downcase_and_remove_whitespace(block)
    block = Map.get(aliases(), block, block)
    Map.fetch(blocks(), block)
  end

  @doc """
  Returns the Unicode codepoint ranges for a given block.

  Aliases are resolved by this function.

  ### Arguments

  * `block` is any block name or alias, as an atom or string.

  ### Returns

  * A list of codepoint ranges as 2-tuples.

  * `nil` if the block is not known.

  ### Examples

      iex> Unicode.Block.get(:basic_latin)
      [{0, 127}]

      iex> Unicode.Block.get(:invalid)
      nil

  """
  @impl Unicode.Property.Behaviour
  def get(block) do
    case fetch(block) do
      {:ok, block} -> block
      _ -> nil
    end
  end

  @doc """
  Returns the count of characters in a given block.

  Aliases are resolved by this function.

  ### Arguments

  * `block` is any block name or alias, as an atom or string.

  ### Returns

  * A non-negative integer count of the codepoints in the block.

  * `:error` if the block is not known.

  ### Examples

      iex> Unicode.Block.count(:old_north_arabian)
      32

  """
  @impl Unicode.Property.Behaviour
  def count(block) do
    with {:ok, block} <- fetch(block) do
      Enum.reduce(block, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the block name(s) for the given binary or codepoint.

  ### Arguments

  * `string_or_codepoint` is either a binary (String) or a codepoint in the range `0..0x10FFFF`.

  ### Returns

  * For a codepoint, a single block name is returned.

  * For a binary, a list of the distinct block names of the codepoints in the binary is returned.

  ### Examples

      iex> Unicode.Block.block(?A)
      :basic_latin

      iex> Unicode.Block.block("abc")
      [:basic_latin]

  """
  def block(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&block/1)
    |> Enum.uniq()
  end

  def block(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    Unicode.RangeSearch.find(@block_table, codepoint, :no_block)
  end

  @doc """
  Returns a list of tuples representing the assigned ranges of all Unicode codepoints.

  ### Returns

  * A list of codepoint ranges as 2-tuples.

  ### Examples

      iex> Unicode.Block.assigned() |> hd()
      {0, 12255}

  """
  @assigned @blocks
            |> Map.values()
            |> Enum.map(&hd/1)
            |> Enum.sort()
            |> Unicode.compact_ranges()

  def assigned do
    @assigned
  end
end
