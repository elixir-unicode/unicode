defmodule Unicode.Validation.UTF32LE do
  @moduledoc false

  def replace_invalid(bytes, replacement \\ "�")
      when is_binary(bytes) and is_binary(replacement) do
    do_replace(bytes, Unicode.Validation.encode_replacement(replacement, {:utf32, :little}), <<>>)
  end

  defp do_replace(<<>>, _replacement, acc) do
    acc
  end

  defp do_replace(<<codepoint::utf32-little, rest::bits>>, replacement, acc) do
    do_replace(rest, replacement, <<acc::bits, codepoint::utf32-little>>)
  end

  defp do_replace(<<_::bytes-size(4), rest::bits>>, replacement, acc) do
    do_replace(rest, replacement, <<acc::bits, replacement::bits>>)
  end

  defp do_replace(_truncated, replacement, acc) do
    <<acc::bits, replacement::bits>>
  end
end
