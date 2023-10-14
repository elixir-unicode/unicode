defmodule Unicode.Validation.UTF8.Test.Helpers do
  @moduledoc """
  A set of functions that return 2-value tuples of bytes and their correct utf-8 interpretation.
  """

  @surrogates 0xD800..0xDFFF
  @last_valid 0x1000FF
  @unallocated (@last_valid + 1)..((2 ** 21)-1)

  @singles 0..127
  @doubles 128..0x07FF
  @triples 0x0800..0xFFFF
  @quads 0x10000..@last_valid

  @doc """
  Returns the provided utf-8 sequence as a truncated by "n" sequence.
  """
  def truncated(<<_::utf8>> = str, to_trunc \\ 1) when to_trunc > 0 and byte_size(str) - to_trunc > 0 do
    {binary_slice(str, 0, byte_size(str) - to_trunc), "�"}
  end

  @doc """
  Returns the provided utf-8 sequence as an overlong by "n" sequence.
  """
  def overlong(<<codepoint::utf8>> = str, extra_bytes \\ 1) when extra_bytes > 0 and (byte_size(str) + extra_bytes) in 2..6 do
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

  @doc """
  Returns n random surrogate codepoints encoded as utf-8.
  """
  def random_surrogates(n) when is_integer(n) and n > 0 do
    {make_random_surrogates(n), String.duplicate("�", n)}
  end

  defp make_random_surrogates(n, acc \\ <<>>)

  defp make_random_surrogates(0, acc), do: acc

  defp make_random_surrogates(n, acc) do
    <<i::4, ii::6, iii::6>> = <<Enum.random(@surrogates)::16>>
    bytes = <<0b1110::4, i::4, 0b10::2, ii::6, 0b10::2, iii::6>>

    make_random_surrogates(n-1, <<acc::bits, bytes::bytes>>)
  end

  def random_valid_sequence(), do: <<random_valid_codepoint()::utf8>>

  def random_valid_sequence(1), do: <<Enum.random(@singles)::utf8>>

  def random_valid_sequence(2), do: <<Enum.random(@doubles)::utf8>>

  def random_valid_sequence(3) do
    case Enum.random(@triples) do
      c when c in @surrogates -> random_valid_sequence(3)
      c -> <<c::utf8>>
    end
  end

  def random_valid_sequence(4), do: <<Enum.random(@quads)::utf8>>

  @doc """
  Return a string of n random valid codepoints encoded as utf-8.
  """
  def random_valid_sequences(n, acc \\ <<>>)

  def random_valid_sequences(0, acc), do: acc

  def random_valid_sequences(n, acc) when n > 0 do
    random_valid_sequences(n-1, <<acc::bits, random_valid_codepoint()::utf8>>)
  end

  # doing it "this way" for a more even sampling even though embarassingly inefficient.
  defp random_valid_codepoint() do
    case Enum.random(0..@last_valid) do
      c when c in @surrogates -> random_valid_codepoint()
      c -> c
    end
  end

  @doc """
  Returns unallocated codepoints as their would-be utf-8 sequences.
  """
  def random_undefined_codepoint() do
    <<i::3, ii::6, iii::6, iv::6>> = <<Enum.random(@unallocated)::21>>

    <<0b11110::5, i::3, 0b10::2, ii::6, 0b10::2, iii::6, 0b10::2, iv::6>>
  end
end
