defmodule Unicode.Validation.UTF16LE do
  @moduledoc false

  def replace_invalid(bytes, replacement \\ "�")
      when is_binary(bytes) and is_binary(replacement) do
    do_replace(bytes, Unicode.Validation.encode_replacement(replacement, {:utf16, :little}), <<>>)
  end

  defp do_replace(<<>>, _replacement, acc) do
    acc
  end

  defp do_replace(<<codepoint::utf16-little, rest::bits>>, replacement, acc) do
    do_replace(rest, replacement, <<acc::bits, codepoint::utf16-little>>)
  end

  defp do_replace(<<_::bytes-size(2), rest::bits>>, replacement, acc) do
    do_replace(rest, replacement, <<acc::bits, replacement::bits>>)
  end

  defp do_replace(_truncated, replacement, acc) do
    <<acc::bits, replacement::bits>>
  end
end
