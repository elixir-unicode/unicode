defmodule Unicode.CharacterName do
  @moduledoc """
  Resolves Unicode character names to their codepoint.

  Names are taken from the `Name` field of the Unicode Character Database
  (`UnicodeData.txt`) and matched loosely: case, whitespace, `_` and `-` are
  ignored (as in `\\N{...}` name lookups). Codepoints whose name is a bracketed
  label such as `<control>`, or an algorithmically-named range (CJK ideographs,
  Hangul syllables), are not included.

  The names are stored as a single sorted binary blob plus a fixed-width offset
  index, and looked up with a binary search, so the table is compact (roughly
  1.2MB) and no large map is materialised.

  """

  alias Unicode.Utils

  # `@table` is only used to define the two binaries below, so it is not itself
  # embedded in the compiled module. `@name_blob` and `@offsets` are the only
  # literals that end up in the BEAM.
  @table Utils.character_name_table()
  @name_blob elem(@table, 0)
  @offsets elem(@table, 1)

  # Each `@offsets` record is 6 bytes; the last is a sentinel, so the number of
  # names is `byte_size(@offsets) / 6 - 1`.
  @count div(byte_size(@offsets), 6) - 1

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
    search(Utils.downcase_and_remove_whitespace(name), 0, @count - 1)
  end

  @doc """
  Returns the number of names in the table.

  """
  @spec count() :: non_neg_integer()
  def count, do: @count

  defp search(_name, low, high) when low > high do
    :error
  end

  defp search(name, low, high) do
    middle = div(low + high, 2)
    {middle_name, codepoint} = entry(middle)

    cond do
      name == middle_name -> {:ok, codepoint}
      name < middle_name -> search(name, low, middle - 1)
      true -> search(name, middle + 1, high)
    end
  end

  defp entry(index) do
    <<offset::24, codepoint::24>> = binary_part(@offsets, index * 6, 6)
    <<next_offset::24, _::24>> = binary_part(@offsets, (index + 1) * 6, 6)
    {binary_part(@name_blob, offset, next_offset - offset), codepoint}
  end
end
