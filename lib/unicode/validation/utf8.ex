defmodule Unicode.Validation.UTF8 do
  @moduledoc false

  import Bitwise

  defguardp is_truncated_ii_of_iii(i, ii) when
    (896 <= ((i <<< 6) ||| ii) and ((i <<< 6) ||| ii) <= 1023)
    or
    (32 <= ((i <<< 6) ||| ii) and ((i <<< 6) ||| ii) <= 863)

  defguardp is_truncated_ii_of_iv(i, ii) when
    (16 <= ((i <<< 6) ||| ii)) and (((i <<< 6) ||| ii) <= 271)

  defguardp is_truncated_iii_of_iv(i, ii, iii) when
    (1024 <= (((i <<< 12) ||| (ii <<< 6)) ||| iii))
    and ((((i <<< 12) ||| (ii <<< 6)) ||| iii) <= 17407)

  defguardp is_ascii(codepoint) when codepoint in 0..127

  defguardp is_next_sequence(next) when (next >>> 6) !== 0b10

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
