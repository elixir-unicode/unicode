defmodule Unicode.CharacterName do
  @moduledoc """
  Resolves Unicode character names to their codepoint.

  Names are taken from the `Name` field of the Unicode Character Database
  (`UnicodeData.txt`) and matched loosely: case, whitespace, `_` and `-` are
  ignored (as in `\\N{...}` name lookups). Codepoints whose name is a bracketed
  label such as `<control>`, or an algorithmically-named range (CJK ideographs,
  Hangul syllables), are not included.

  The names are prefix-compressed (front-coded) into a single sorted binary blob
  with block restart points, and looked up with a binary search over the restart
  names followed by a scan-decode within one block. This keeps the table compact
  (about 0.4MB resident at runtime, versus roughly 1.2MB uncompressed) without
  materialising a large map.

  """

  alias Unicode.Utils

  # Bind the table to compile-time local variables rather than an intermediate
  # module attribute, so only `@blob`/`@restarts` (each referenced once in the
  # functions below) end up in the compiled module, not a duplicate tuple.
  {blob, restarts, count} = Utils.character_name_table()
  @blob blob
  @restarts restarts
  @count count
  @block_count div(byte_size(restarts), 4)

  @doc """
  Returns the codepoint for a Unicode character name.

  ### Arguments

  * `name` is a Unicode character name as a string, matched loosely.

  ### Returns

  * `{:ok, codepoint}` or

  * `:error` if the name is not known.

  ### Examples

      iex> Unicode.CharacterName.to_codepoint("LATIN SMALL LETTER A")
      {:ok, 97}

      iex> Unicode.CharacterName.to_codepoint("bullet")
      {:ok, 8226}

      iex> Unicode.CharacterName.to_codepoint("Not A Real Name")
      :error

  """
  @spec to_codepoint(String.t()) :: {:ok, pos_integer()} | :error
  def to_codepoint(name) when is_binary(name) do
    normalized = Utils.downcase_and_remove_whitespace(name)
    block = find_block(normalized, 0, @block_count - 1)
    scan_block(normalized, block)
  end

  @doc """
  Returns the number of names in the table.

  """
  @spec count() :: non_neg_integer()
  def count, do: @count

  # Binary search for the last block whose first (restart) name is `<=` the
  # query. The upper-biased midpoint guarantees termination.
  defp find_block(_name, low, low), do: low

  defp find_block(name, low, high) do
    middle = div(low + high + 1, 2)

    if block_first_name(middle) <= name do
      find_block(name, middle, high)
    else
      find_block(name, low, middle - 1)
    end
  end

  defp restart_offset(block) do
    <<offset::32>> = binary_part(@restarts, block * 4, 4)
    offset
  end

  defp block_first_name(block) do
    offset = restart_offset(block)
    <<name_length>> = binary_part(@blob, offset, 1)
    binary_part(@blob, offset + 1, name_length)
  end

  # Decode the block's restart name in full, then scan its front-coded entries.
  defp scan_block(query, block) do
    offset = restart_offset(block)

    block_end =
      if block + 1 < @block_count, do: restart_offset(block + 1), else: byte_size(@blob)

    <<name_length, name::binary-size(name_length), codepoint::24, rest::binary>> =
      binary_part(@blob, offset, block_end - offset)

    scan(query, name, codepoint, rest)
  end

  defp scan(query, name, codepoint, rest) do
    cond do
      query == name ->
        {:ok, codepoint}

      # Names are sorted, so once we pass the query it cannot be present.
      query < name ->
        :error

      rest == <<>> ->
        :error

      true ->
        <<shared, suffix_length, suffix::binary-size(suffix_length), codepoint::24,
          next_rest::binary>> = rest

        next_name = binary_part(name, 0, shared) <> suffix
        scan(query, next_name, codepoint, next_rest)
    end
  end
end
