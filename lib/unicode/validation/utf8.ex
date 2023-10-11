defmodule Unicode.Validation.UTF8 do
  @moduledoc false

  def replace_invalid(bytes, replacement \\ "�") when is_binary(bytes) and is_binary(replacement) do
    do_replace(bytes, replacement, <<>>)
  end

  # match ascii characters first for speed
  defp do_replace(<<ascii::8, n_lead::2, n_rest::6, rest::bytes>>, rep, acc) when ascii in 0..127 and n_lead != 0b10 do
    do_replace(rest, rep, <<acc::bits, ascii::8, n_lead::2, n_rest::6>>)
  end

  defp do_replace(<<grapheme::utf8, rest::bytes>>, rep, acc) do
    do_replace(rest, rep, <<acc::bits, grapheme::utf8>>)
  end

  # 2/3-byte truncated
  defp do_replace(<<0b1110::4, i::4, 0b10::2, ii::6>>, rep, acc) do
    <<acc::bits, ii_of_iii(<<i::4, ii::6>>, rep)::bits>>
  end

  defp do_replace(<<0b1110::4, i::4, 0b10::2, ii::6, n_lead::2, n_rest::6, rest::bytes>>, rep, acc) when n_lead != 0b10 do
    do_replace(<<n_lead::2, n_rest::6, rest::bytes>>, rep, <<acc::bits, ii_of_iii(<<i::4, ii::6>>, rep)::bits>>)
  end

  # 2/4-byte truncated
  defp do_replace(<<0b11110::5, i::3, 0b10::2, ii::6>>, rep, acc) do
    <<acc::bits, ii_of_iiii(<<i::4, ii::6>>, rep)::bits>>
  end

  defp do_replace(<<0b11110::5, i::3, 0b10::2, ii::6, n_lead::2, n_rest::6, rest::bytes>>, rep, acc) when n_lead != 0b10 do
    do_replace(<<n_lead::2, n_rest::6, rest::bytes>>, rep, <<acc::bits, ii_of_iiii(<<i::4, ii::6>>, rep)::bits>>
    )
  end

  # 3/4-byte truncated
  defp do_replace(<<0b11110::5, i::3, 0b10::2, ii::6, 0b10::2, iii::6>>, rep, acc) do
    <<acc::bits, iii_of__iiii(<<i::3, ii::6, iii::6>>, rep)::bits>>
  end

  defp do_replace(<<0b11110::5, i::3, 0b10::2, ii::6, 0b10::2, iii::6, n_lead::2, n_rest::6, rest::bytes>>, rep, acc) when n_lead != 0b10 do
    do_replace(<<n_lead::2, n_rest::6, rest::bytes>>, rep, <<acc::bits, iii_of__iiii(<<i::3, ii::6, iii::6>>, rep)::bits>>)
  end

  defp do_replace(<<_, rest::bytes>>, rep, acc), do: do_replace(rest, rep, <<acc::bits, rep::bytes>>)
  defp do_replace(<<>>, _, acc), do: acc

  defp ii_of_iii(tcp, rep) when tcp >= 32 and tcp <= 863, do: rep
  defp ii_of_iii(tcp, rep) when tcp >= 896 and tcp <= 1023, do: rep
  defp ii_of_iii(_, rep), do: rep <> rep

  defp ii_of_iiii(tcp, rep) when tcp >= 16 and tcp <= 271, do: rep
  defp ii_of_iiii(_, rep), do: rep <> rep

  defp iii_of__iiii(tcp, rep) when tcp >= 1024 and tcp <= 17407, do: rep
  defp iii_of__iiii(_, rep), do: rep <> rep <> rep
end
