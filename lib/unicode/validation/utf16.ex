defmodule UniRecover.UTF16 do
  @moduledoc false

  @dialyzer :no_improper_lists

  def replace_invalid(bytes, endianness, replacement \\ "�")

  def replace_invalid(<<>>, _, _), do: ""

  def replace_invalid(bytes, :be, replacement) when is_binary(bytes) and is_binary(replacement) do
    replacement = :unicode.characters_to_binary(replacement, :utf8, :utf16)

    find_bad_sequences_be(bytes)
    |> replace_bad_sequences(bytes, replacement)
  end

  def replace_invalid(bytes, :le, replacement) when is_binary(bytes) and is_binary(replacement) do
    replacement = :unicode.characters_to_binary(replacement, :utf8, {:utf16, :little})

    find_bad_sequences_le(bytes)
    |> replace_bad_sequences(bytes, replacement)
  end

  defp find_bad_sequences_be(bytes, acc \\ [])

  # good sequence
  defp find_bad_sequences_be(<<_::utf16, rest::binary>>, acc) do
    find_bad_sequences_be(rest, acc)
  end

  # illegal sequence
  defp find_bad_sequences_be(<<_::binary-size(2), rest::binary>>, acc) do
    find_bad_sequences_be(rest, [byte_size(rest) | acc])
  end

  # 0-1 bytes left (trailing incomplete code points will be ignored)
  defp find_bad_sequences_be(_, acc), do: Enum.reverse(acc)

  defp find_bad_sequences_le(bytes, acc \\ [])

  defp find_bad_sequences_le(<<_::utf16-little, rest::binary>>, acc),
    do: find_bad_sequences_le(rest, acc)

  defp find_bad_sequences_le(<<_::binary-size(2), rest::binary>>, acc),
    do: find_bad_sequences_le(rest, [byte_size(rest) | acc])

  defp find_bad_sequences_le(_, acc), do: Enum.reverse(acc)

  ## 0-1 bad sequences -> short circuit

  # none
  defp replace_bad_sequences([], og, _), do: og

  # leading
  defp replace_bad_sequences([offset], og, rep) when offset+2 === byte_size(og) do
    rep <> binary_slice(og, -(offset + 1)..-1//1)
  end

  # trailing
  defp replace_bad_sequences([0], og, rep) do
    binary_slice(og, -byte_size(og)..-3//1) <> rep
  end

  # middle
  defp replace_bad_sequences([offset], og, rep) do
    binary_slice(og, -byte_size(og)..-(offset + 3)//1) <> rep <> binary_slice(og, -offset..-1//1)
  end

  ## 2+ bad sequences -> recursive

  # og begins with a bad sequence -> start with empty acc
  defp replace_bad_sequences([offset | _rest] = bad_offsets, og, rep) when offset + 2 === byte_size(og) do
    do_replace_bad_sequences([], bad_offsets, og, rep)
  end

  # -> start with slice from start
  defp replace_bad_sequences([offset | _rest] = bad_offsets, og, rep) do
    [binary_slice(og, -byte_size(og)..-(offset+3)//1)]
    |> do_replace_bad_sequences(bad_offsets, og, rep)
  end

  ## loop

  # og ends with a bad sequence -> skip slice and convert
  defp do_replace_bad_sequences(acc, [0], _s, rep) do
    [acc | rep]
    |> IO.iodata_to_binary()
  end

  # last bad sequence -> slice and convert
  defp do_replace_bad_sequences(acc, [offset], og, rep) do
    [[acc | rep] | binary_slice(og, -offset..-1//1)]
    |> IO.iodata_to_binary()
  end

  # adjacent bad sequences -> don't take a slice between them
  defp do_replace_bad_sequences(acc, [offset_i | [offset_ii | _] = rest], og, rep) when offset_i + 3 === offset_ii do
    [acc | rep]
    |> do_replace_bad_sequences(rest, og, rep)
  end

  # -> take a slice between bad sequences
  defp do_replace_bad_sequences(acc, [offset_i | [offset_ii | _] = rest], og, rep) do
    [[acc | rep] | binary_slice(og, -(offset_i+1)..-(offset_ii+3)//1)]
    |> do_replace_bad_sequences(rest, og, rep)
  end
end
