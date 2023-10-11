defmodule Unicode.Validation do
  @moduledoc """
  See `Unicode.Validation.replace_invalid/3` for documentation.
  """

  @doc """
  Substitutes all illegal sequences in the provided data with the Unicode [replacement character](https://en.wikipedia.org/wiki/Specials_(Unicode_block)#Replacement_character).
  """
  @spec replace_invalid(binary, (:utf8 | :utf16 | :utf16be | :utf16le | :utf32 | :utf32be | :utf32le), String.t) :: binary
  def replace_invalid(bytes, encoding \\ :utf8, replacement \\ "�")

  def replace_invalid(bytes, :utf8, rep) when is_binary(bytes) and is_binary(rep) do
    Unicode.Validation.UTF8.replace_invalid(bytes, rep)
  end

  def replace_invalid(bytes, :utf16, rep) when is_binary(bytes) and is_binary(rep) do
    Unicode.Validation.UTF16.replace_invalid(bytes, rep)
  end

  def replace_invalid(bytes, :utf16be, rep) when is_binary(bytes) and is_binary(rep) do
    Unicode.Validation.UTF16.replace_invalid(bytes, rep)
  end

  def replace_invalid(bytes, :utf16le, rep) when is_binary(bytes) and is_binary(rep) do
    Unicode.Validation.UTF16LE.replace_invalid(bytes, rep)
  end

  def replace_invalid(bytes, :utf32, rep) when is_binary(bytes) and is_binary(rep) do
    Unicode.Validation.UTF16.replace_invalid(bytes, rep)
  end

  def replace_invalid(bytes, :utf32be, rep) when is_binary(bytes) and is_binary(rep) do
    Unicode.Validation.UTF32.replace_invalid(bytes, rep)
  end

  def replace_invalid(bytes, :utf32le, rep) when is_binary(bytes) and is_binary(rep) do
    Unicode.Validation.UTF32LE.replace_invalid(bytes, rep)
  end
end
