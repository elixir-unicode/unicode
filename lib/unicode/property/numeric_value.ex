defmodule Unicode.NumericValue do
  @moduledoc """
  Functions to introspect the Unicode `Numeric_Value` property for binaries (Strings) and codepoints.

  The `Numeric_Value` property is the numeric value a codepoint represents. Whole numbers are returned as integers and fractions as a `{numerator, denominator}` tuple. Codepoints with no numeric value return `nil`.

  The primary API is `numeric_value/1` which returns the numeric value of a codepoint, or the list of numeric values of a string. See `Unicode.NumericType` for the associated numeric type.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @typedoc "A Unicode numeric value: an integer, a `{numerator, denominator}` fraction, or `nil`."
  @type value :: integer() | {integer(), integer()} | nil

  @numeric_values Utils.numeric_values()

  @numeric_value_table Unicode.RangeSearch.new_value_table(@numeric_values)

  @doc """
  Returns the map of Unicode numeric values.

  ### Returns

  * A map where the numeric value (an integer or `{numerator, denominator}` tuple) is the key and a list of codepoint ranges as 2-tuples is the value.

  ### Examples

      iex> Unicode.NumericValue.numeric_values() |> Map.get(7) |> Enum.any?(fn {first, last} -> ?7 in first..last end)
      true

  """
  def numeric_values do
    @numeric_values
  end

  @doc """
  Returns a list of known Unicode numeric values.

  ### Returns

  * A list of integers and `{numerator, denominator}` tuples.

  ### Examples

      iex> 7 in Unicode.NumericValue.known_numeric_values()
      true

      iex> {1, 2} in Unicode.NumericValue.known_numeric_values()
      true

  """
  @known_numeric_values Map.keys(@numeric_values)
  def known_numeric_values do
    @known_numeric_values
  end

  @doc """
  Returns an empty map.

  The `Numeric_Value` property has no value aliases; this function exists to satisfy the `Unicode.Property.Behaviour`.

  ### Returns

  * An empty map.

  ### Examples

      iex> Unicode.NumericValue.aliases()
      %{}

  """
  @impl Unicode.Property.Behaviour
  def aliases do
    %{}
  end

  @doc """
  Returns the Unicode codepoint ranges having a given numeric value.

  ### Arguments

  * `value` is an integer or `{numerator, denominator}` tuple.

  ### Returns

  * `{:ok, range_list}` where `range_list` is a list of codepoint ranges as 2-tuples.

  * `:error` if no codepoint has the value.

  ### Examples

      iex> Unicode.NumericValue.fetch(7) |> elem(0)
      :ok

      iex> Unicode.NumericValue.fetch(:invalid)
      :error

  """
  @impl Unicode.Property.Behaviour
  def fetch(value) do
    Map.fetch(numeric_values(), value)
  end

  @doc """
  Returns the Unicode codepoint ranges having a given numeric value.

  ### Arguments

  * `value` is an integer or `{numerator, denominator}` tuple.

  ### Returns

  * A list of codepoint ranges as 2-tuples.

  * `nil` if no codepoint has the value.

  ### Examples

      iex> Unicode.NumericValue.get(:invalid)
      nil

  """
  @impl Unicode.Property.Behaviour
  def get(value) do
    case fetch(value) do
      {:ok, range_list} -> range_list
      _ -> nil
    end
  end

  @doc """
  Returns the count of the codepoints having a given numeric value.

  ### Arguments

  * `value` is an integer or `{numerator, denominator}` tuple.

  ### Returns

  * A non-negative integer count of the codepoints with the value.

  * `:error` if no codepoint has the value.

  ### Examples

      iex> Unicode.NumericValue.count(7) > 0
      true

  """
  @impl Unicode.Property.Behaviour
  def count(value) do
    with {:ok, range_list} <- fetch(value) do
      Enum.reduce(range_list, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the numeric value of the given binary or codepoint.

  ### Arguments

  * `string_or_codepoint` is either a binary (String) or a codepoint in the range `0..0x10FFFF`.

  ### Returns

  * For a codepoint, the numeric value as an integer, a `{numerator, denominator}` tuple, or `nil` if the codepoint has no numeric value.

  * For a binary, a list of the distinct numeric values of the codepoints in the binary is returned.

  ### Examples

      iex> Unicode.NumericValue.numeric_value(?7)
      7

      iex> Unicode.NumericValue.numeric_value(?½)
      {1, 2}

      iex> Unicode.NumericValue.numeric_value(?A)
      nil

  """
  @spec numeric_value(String.t()) :: [value(), ...]
  def numeric_value(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&numeric_value/1)
    |> Enum.uniq()
  end

  @spec numeric_value(Unicode.codepoint()) :: value()
  def numeric_value(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    Unicode.RangeSearch.find(@numeric_value_table, codepoint, nil)
  end
end
