defmodule Unicode.Validation.UTF32 do
  @moduledoc false

  @replacement_character :unicode.characters_to_binary("�", :utf8, :utf32)

  def replace_invalid(<<>>, _), do: <<>>

  def replace_invalid(bytes, replacement) when is_binary(bytes) and is_binary(replacement) do
    do_replace(bytes, replacement, <<>>)
  end

  # good sequence
  defp do_replace(<<_::utf32, rest::binary>>, rep, acc) do
    do_replace(rest, rep, acc)
  end

  # illegal sequence
  defp do_replace(<<_::binary-size(4), rest::binary>>, rep, acc) do
    do_replace(rest, rep, <<acc::bits, rep::bits>>)
  end
end
