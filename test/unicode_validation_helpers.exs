defmodule Unicode.Validation.UTF8.Test.Helpers do
  @moduledoc """
  A set of functions that return 2-value tuples of bytes and their correct utf-8 interpretation.
  """
  @surrogates 0xD800..0xDFFF

  def truncated(<<_::utf8>> = str, to_trunc \\ 1) when to_trunc >= 1 and byte_size(str) - to_trunc >= 1 do
    {binary_slice(str, 0, byte_size(str) - to_trunc), "�"}
  end

  def overlong(<<codepoint::utf8>> = str, extra_bytes \\ 1) when extra_bytes >= 1 and (byte_size(str) + extra_bytes) in 2..6 do
    case byte_size(str) + extra_bytes do
      2 ->
        <<i::5, ii::6>> = <<codepoint::11>>
        {<<0b110::3, i::5, 0b10::2, ii::6>>, "��"}

      3 ->
        <<i::4, ii::6, iii::6>> = <<codepoint::16>>
        {<<0b1110::4, i::4, 0b10::2, ii::6, 0b10::2, iii::6>>, "���"}

      4 ->
        <<i::3, ii::6, iii::6, iv::6>> = <<codepoint::21>>
        {<<0b11110::5, i::3, 0b10::2, ii::6, 0b10::2, iii::6, 0b10::2, iv::6>>, "����"}

      5 ->
        <<i::2, ii::6, iii::6, iv::6, v::6>> = <<codepoint::26>>
        {<<0b111110::6, i::2, 0b10::2, ii::6, 0b10::2, iii::6, 0b10::2, iv::6, 0b10::2, v::6>>, "�����"}

      6 ->
        <<i::1, ii::6, iii::6, iv::6, v::6, vi::6>> = <<codepoint::31>>
        {<<0b1111110::7, i::1, 0b10::2, ii::6, 0b10::2, iii::6, 0b10::2, iv::6, 0b10::2, v::6, 0b10::2, vi::6>>, "������"}
    end
  end

  def random_surrogates(length) when is_integer(length) and length >= 1 do
    {make_random_surrogates(length), String.duplicate("�", length)}
  end

  def make_random_surrogates(0, acc), do: acc

  def make_random_surrogates(n, acc \\ <<>>) do
    <<i::4, ii::6, iii::6>> = <<Enum.random(@surrogates)::16>>
    bytes = <<0b1110::4, i::4, 0b10::2, ii::6, 0b10::2, iii::6>>

    make_random_surrogates(n-1, <<acc::bits, bytes::bytes>>)
  end

  # Todo: Have this return binaries instead of lists of strings

  def random_valid_sequences(count \\ 1) do
    bytes = Enum.map(0..count, fn _ -> random_valid_character() end)
    {bytes, bytes}
  end

  defp random_valid_character() do
    <<([0..0xD7FF, 0xDC00..0x1000FF] |> Enum.random() |> Enum.random())::utf8>>
  end
end
