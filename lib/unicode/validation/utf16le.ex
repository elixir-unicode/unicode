defmodule Unicode.Validation.UTF16LE do
  @moduledoc false

  @replacement_character :unicode.characters_to_binary("�", :utf8, {:utf16, :little})

  def replace_invalid(bytes, replacement \\ @replacement_character)

  def replace_invalid(<<>>, _), do: <<>>

  def replace_invalid(bytes, replacement) when is_binary(bytes) and is_binary(replacement) do
    do_replace(bytes, replacement, <<>>)
  end

  # good sequence
  defp do_replace(<<_::utf16-little, rest::bits>>, rep, acc) do
    do_replace(rest, rep, acc)
  end

  # illegal sequence
  defp do_replace(<<_::bytes-size(2), rest::bits>>, rep, acc) do
    do_replace(rest, rep, <<acc::bits, rep::bits>>)
  end
end
