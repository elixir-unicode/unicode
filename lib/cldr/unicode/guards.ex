defmodule Cldr.Unicode.Guards do
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
  alias Cldr.Unicode

  categories = Unicode.Utils.categories

  is_upper =
    categories
    |> Map.get(:Lu)
    |> Unicode.Utils.ranges_to_guard_clause

  is_lower =
    categories
    |> Map.get(:Ll)
    |> Unicode.Utils.ranges_to_guard_clause

  is_currency_symbol =
    categories
    |> Map.get(:Sc)
    |> Unicode.Utils.ranges_to_guard_clause

  is_digit =
    categories
    |> Map.get(:Nd)
    |> Unicode.Utils.ranges_to_guard_clause

  @doc """
  Guards whether a UTF8 codepoint is an upper case
  character.
  """
  defguard is_upper(codepoint) when is_integer(codepoint) and unquote(is_upper)

  @doc """
  Guards whether a UTF8 codepoint is an lower case
  character.
  """
  defguard is_lower(codepoint) when is_integer(codepoint) and unquote(is_lower)

  @doc """
  Guards whether a UTF8 codepoint is an digit
  character.
  """
  defguard is_digit(codepoint) when is_integer(codepoint) and unquote(is_digit)

  @doc """
  Guards whether a UTF8 codepoint is an currency symbol
  character.
  """
  defguard is_currency_symbol(codepoint) when is_integer(codepoint) and unquote(is_currency_symbol)

end