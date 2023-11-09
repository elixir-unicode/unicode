defmodule Unicode.Validation.UTF8 do
  @moduledoc false

  defguardp is_truncated_ii_of_iii(i, ii) when
    Bitwise.bor(Bitwise.bsl(i, 6), ii) in 32..863
    or
    Bitwise.bor(Bitwise.bsl(i, 6), ii) in 896..1023

  defguardp is_truncated_ii_of_iv(i, ii) when
    Bitwise.bor(Bitwise.bsl(i, 6), ii) in 16..271

  defguardp is_truncated_iii_of_iv(i, ii, iii) when
    Bitwise.bor(Bitwise.bor(Bitwise.bsl(i, 12), Bitwise.bsl(ii, 6)), iii) in 1024..17407

  defguardp is_ascii(codepoint) when codepoint in 0..127

  defguardp is_next_sequence(next) when Bitwise.bsr(next, 6) !== 0b10

  def replace_invalid(bytes, replacement \\ "�")
     when is_binary(bytes) and is_binary(replacement) do
    do_replace(bytes, replacement, <<>>)
  end

  # ASCII (for better average speed)
  defp do_replace(<<ascii::8, next::8, _::bytes>> = rest, rep, acc)
     when is_ascii(ascii) and is_next_sequence(next) do
    <<_::8, rest::bytes>> = rest
    do_replace(rest, rep, acc <> <<ascii::8>>)
  end

  # UTF-8 (valid)
  defp do_replace(<<grapheme::utf8, rest::bytes>>, rep, acc) do
    do_replace(rest, rep, acc <> <<grapheme::utf8>>)
  end

  # 2/3 truncated sequence
  defp do_replace(<<0b1110::4, i::4, 0b10::2, ii::6>>, rep, acc)
     when is_truncated_ii_of_iii(i, ii) do
    acc <> rep
  end

  defp do_replace(<<0b1110::4, i::4, 0b10::2, ii::6, next::8, _::bytes>> = rest, rep, acc)
     when is_truncated_ii_of_iii(i, ii) and is_next_sequence(next) do
    <<_::16, rest::bytes>> = rest
    do_replace(rest, rep, acc <> rep)
  end

  # 2/4
  defp do_replace(<<0b11110::5, i::3, 0b10::2, ii::6>>, rep, acc)
     when is_truncated_ii_of_iv(i, ii) do
    acc <> rep
  end

  defp do_replace(<<0b11110::5, i::3, 0b10::2, ii::6, next::8, _::bytes>> = rest, rep, acc)
     when is_truncated_ii_of_iv(i, ii) and is_next_sequence(next) do
    <<_::16, rest::bytes>> = rest
    do_replace(rest, rep, acc <> rep)
  end

  # 3/4
  defp do_replace(<<0b11110::5, i::3, 0b10::2, ii::6, 0b10::2, iii::6>>, rep, acc)
     when is_truncated_iii_of_iv(i, ii, iii) do
    acc <> rep
  end

  defp do_replace(<<0b11110::5, i::3, 0b10::2, ii::6, 0b10::2, iii::6, next::8, _::bytes>> = rest, rep, acc)
     when is_truncated_iii_of_iv(i, ii, iii) and is_next_sequence(next) do
    <<_::24, rest::bytes>> = rest
    do_replace(rest, rep, acc <> rep)
  end

  # Everything else
  defp do_replace(<<_, rest::bytes>>, rep, acc), do: do_replace(rest, rep, acc <> rep)

  # Final
  defp do_replace(<<>>, _, acc), do: acc
end
