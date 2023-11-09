defmodule Unicode.Validation.UTF8 do
  @moduledoc false

  import Bitwise

  def replace_invalid(bytes, replacement \\ "�") when is_binary(bytes) and is_binary(replacement) do
    do_replace(bytes, replacement, <<>>)
  end

  # ASCII (for better average speed)
  defp do_replace(<<ascii::8, next::8, _::bytes>> = rest, rep, acc) when ascii in 0..127 and (next >>> 6) !== 0b10 do
    <<_::8, rest::bytes>> = rest
    do_replace(rest, rep, acc <> <<ascii::8>>)
  end

  # UTF-8 (valid)
  defp do_replace(<<grapheme::utf8, rest::bytes>>, rep, acc) do
    do_replace(rest, rep, acc <> <<grapheme::utf8>>)
  end

  # 2/3 truncated sequence

  defp do_replace(<<0b1110::4, i::4, 0b10::2, ii::6>>, rep, acc) do
    acc <> ii_of_iii(<<i::4, ii::6>>, rep)
  end

  defp do_replace(<<0b1110::4, i::4, 0b10::2, ii::6, next::8, _::bytes>> = rest, rep, acc) when (next >>> 6) !== 0b10 do
    <<_::16, rest::bytes>> = rest
    do_replace(rest, rep, acc <> ii_of_iii(<<i::4, ii::6>>, rep))
  end

  # 2/4

  defp do_replace(<<0b11110::5, i::3, 0b10::2, ii::6>>, rep, acc) do
    acc <> ii_of_iv(<<i::3, ii::6>>, rep)
  end

  defp do_replace(<<0b11110::5, i::3, 0b10::2, ii::6, next::8, _::bytes>> = rest, rep, acc) when (next >>> 6) !== 0b10 do
    <<_::16, rest::bytes>> = rest
    do_replace(rest, rep, acc <> ii_of_iv(<<i::3, ii::6>>, rep))
  end

  # 3/4

  defp do_replace(<<0b11110::5, i::3, 0b10::2, ii::6, 0b10::2, iii::6>>, rep, acc) do
    acc <> iii_of_iv(<<i::3, ii::6, iii::6>>, rep)
  end

  defp do_replace(<<0b11110::5, i::3, 0b10::2, ii::6, 0b10::2, iii::6, next::8, _::bytes>> = rest, rep, acc) when (next >>> 6) !== 0b10 do
    <<_::24, rest::bytes>> = rest
    do_replace(rest, rep, acc <> iii_of_iv(<<i::3, ii::6, iii::6>>, rep))
  end

  # Everything else

  defp do_replace(<<_, rest::bytes>>, rep, acc), do: do_replace(rest, rep, acc <> rep)

  # Final

  defp do_replace(<<>>, _, acc), do: acc

  # bounds-checking truncated code points for overlong encodings

  defp ii_of_iii(<<tcp::10>>, rep) when tcp >= 32 and tcp <= 863, do: rep
  defp ii_of_iii(<<tcp::10>>, rep) when tcp >= 896 and tcp <= 1023, do: rep
  defp ii_of_iii(_, rep), do: rep <> rep

  defp ii_of_iv(<<tcp::9>>, rep) when tcp >= 16 and tcp <= 271, do: rep
  defp ii_of_iv(_, rep), do: rep <> rep

  defp iii_of_iv(<<tcp::15>>, rep) when tcp >= 1024 and tcp <= 17407, do: rep
  defp iii_of_iv(_, rep), do: rep <> rep <> rep
end
