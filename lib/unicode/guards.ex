defmodule Unicode.Guards do
  @moduledoc """
  Defines a set of guards that can be used with
  Elixir functions.

  Each guard operates on a UTF8 codepoint since
  the permitted operators in a guard clause
  are restricted to simple comparisons that do
  not include string comparators.

  The data that underpins these guards is generated
  from the Unicode character database and therefore
  includes a broad range of scripts well beyond
  the basic ASCII definitions.

  """

  categories =
    Unicode.Utils.categories()
    |> Enum.map(fn {k, v} ->
      {k, Enum.map(v, fn {s, f, _} -> {s, f} end)}
    end)
    |> Map.new()

  is_upper =
    categories
    |> Map.get(:Lu)
    |> Unicode.Utils.ranges_to_guard_clause()

  is_lower =
    categories
    |> Map.get(:Ll)
    |> Unicode.Utils.ranges_to_guard_clause()

  is_currency_symbol =
    categories
    |> Map.get(:Sc)
    |> Unicode.Utils.ranges_to_guard_clause()

  is_digit =
    categories
    |> Map.get(:Nd)
    |> Unicode.Utils.ranges_to_guard_clause()

  is_whitespace =
    categories
    |> Map.get(:Zs)
    |> Unicode.Utils.ranges_to_guard_clause()

  @doc """
  Guards whether a UTF8 codepoint is an upper case
  character.

  The match is for any UTF8 character that is defined
  in Unicode to be an upper case character in any
  script.

  """
  defguard is_upper(codepoint) when is_integer(codepoint) and unquote(is_upper)

  @doc """
  Guards whether a UTF8 codepoint is a lower case
  character.

  The match is for any UTF8 character that is defined
  in Unicode to be an lower case character in any
  script.

  """
  defguard is_lower(codepoint) when is_integer(codepoint) and unquote(is_lower)

  @doc """
  Guards whether a UTF8 codepoint is a digit
  character.

  This guard will match any digit character from any
  Unicode script, not only the ASCII decimal digits.

  """
  defguard is_digit(codepoint) when is_integer(codepoint) and unquote(is_digit)

  @doc """
  Guards whether a UTF8 codepoint is a currency symbol
  character.

  """
  defguard is_currency_symbol(codepoint)
           when is_integer(codepoint) and unquote(is_currency_symbol)

  @doc """
  Guards whether a UTF8 codepoint is a whitespace symbol
  character.

  """
  defguard is_whitespace(codepoint) when is_integer(codepoint) and unquote(is_whitespace)
end
