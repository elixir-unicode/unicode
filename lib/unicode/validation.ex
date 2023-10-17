defmodule Unicode.Validation do
  @moduledoc false

  @doc """
  Substitutes all illegal sequences in the provided data with the Unicode
  [replacement character](https://en.wikipedia.org/wiki/Specials_(Unicode_block)#Replacement_character).

  """
  @spec replace_invalid(binary, Unicode.encoding(), String.t()) :: binary()
  def replace_invalid(bytes, encoding \\ :utf8, replacement \\ "�")

  def replace_invalid(bytes, :utf8, replacement) when is_binary(bytes) and is_binary(replacement) do
    Unicode.Validation.UTF8.replace_invalid(bytes, replacement)
  end

  def replace_invalid(bytes, :utf16, replacement) when is_binary(bytes) and is_binary(replacement) do
    Unicode.Validation.UTF16.replace_invalid(bytes, replacement)
  end

  def replace_invalid(bytes, :utf16be, replacement) when is_binary(bytes) and is_binary(replacement) do
    Unicode.Validation.UTF16.replace_invalid(bytes, replacement)
  end

  def replace_invalid(bytes, :utf16le, replacement) when is_binary(bytes) and is_binary(replacement) do
    Unicode.Validation.UTF16LE.replace_invalid(bytes, replacement)
  end

  def replace_invalid(bytes, :utf32, replacement) when is_binary(bytes) and is_binary(replacement) do
    Unicode.Validation.UTF16.replace_invalid(bytes, replacement)
  end

  def replace_invalid(bytes, :utf32be, replacement) when is_binary(bytes) and is_binary(replacement) do
    Unicode.Validation.UTF32.replace_invalid(bytes, replacement)
  end

  def replace_invalid(bytes, :utf32le, replacement) when is_binary(bytes) and is_binary(replacement) do
    Unicode.Validation.UTF32LE.replace_invalid(bytes, replacement)
  end
end
