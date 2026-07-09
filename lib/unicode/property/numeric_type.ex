defmodule Unicode.NumericType do
  @moduledoc """
  Functions to introspect the Unicode `Numeric_Type` property for binaries (Strings) and codepoints.

  The `Numeric_Type` property classifies how a codepoint represents a number. The values are `:decimal`, `:digit` and `:numeric`; codepoints that are not numeric have the value `:none`.

  The primary API is `numeric_type/1` which returns the numeric type of a codepoint, or the list of numeric types of a string. See `Unicode.NumericValue` for the associated numeric values.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @numeric_types Utils.numeric_types()
                 |> Utils.remove_annotations()

  @numeric_type_table Unicode.RangeSearch.new_value_table(@numeric_types)

  @doc """
  Returns the map of Unicode numeric types.

  ### Returns

  * A map where the numeric type is the key and a list of codepoint ranges as 2-tuples is the value.

  ### Examples

      iex> Unicode.NumericType.numeric_types() |> Map.keys() |> Enum.sort()
      [:decimal, :digit, :numeric]

  """
  def numeric_types do
    @numeric_types
  end

  @doc """
  Returns a list of known Unicode numeric type names.

  ### Returns

  * A list of atom numeric type names.

  ### Examples

      iex> :decimal in Unicode.NumericType.known_numeric_types()
      true

  """
  @known_numeric_types Map.keys(@numeric_types)
  def known_numeric_types do
    @known_numeric_types
  end

  @doc """
  Returns a map of aliases for Unicode numeric types.

  ### Returns

  * A map where the alias string is the key and the numeric type is the value.

  ### Examples

      iex> Unicode.NumericType.aliases() |> Map.get("de")
      :decimal

  """
  @numeric_type_aliases Utils.value_aliases("nt", @known_numeric_types)
                        |> Utils.add_canonical_alias()

  @impl Unicode.Property.Behaviour
  def aliases do
    @numeric_type_aliases
  end

  @doc """
  Returns the Unicode codepoint ranges for a given numeric type.

  Aliases are resolved by this function.

  ### Arguments

  * `numeric_type` is any numeric type name or alias, as an atom or string.

  ### Returns

  * `{:ok, range_list}` where `range_list` is a list of codepoint ranges as 2-tuples.

  * `:error` if the numeric type is not known.

  ### Examples

      iex> Unicode.NumericType.fetch(:decimal) |> elem(0)
      :ok

      iex> Unicode.NumericType.fetch(:invalid)
      :error

  """
  @impl Unicode.Property.Behaviour
  def fetch(numeric_type) when is_atom(numeric_type) do
    Map.fetch(numeric_types(), numeric_type)
  end

  def fetch(numeric_type) do
    numeric_type = Utils.downcase_and_remove_whitespace(numeric_type)
    numeric_type = Map.get(aliases(), numeric_type, numeric_type) |> Utils.maybe_atomize()
    Map.fetch(numeric_types(), numeric_type)
  end

  @doc """
  Returns the Unicode codepoint ranges for a given numeric type.

  Aliases are resolved by this function.

  ### Arguments

  * `numeric_type` is any numeric type name or alias, as an atom or string.

  ### Returns

  * A list of codepoint ranges as 2-tuples.

  * `nil` if the numeric type is not known.

  ### Examples

      iex> Unicode.NumericType.get(:invalid)
      nil

  """
  @impl Unicode.Property.Behaviour
  def get(numeric_type) do
    case fetch(numeric_type) do
      {:ok, range_list} -> range_list
      _ -> nil
    end
  end

  @doc """
  Returns the count of the codepoints with a given numeric type.

  Aliases are resolved by this function.

  ### Arguments

  * `numeric_type` is any numeric type name or alias, as an atom or string.

  ### Returns

  * A non-negative integer count of the codepoints with the numeric type.

  * `:error` if the numeric type is not known.

  ### Examples

      iex> Unicode.NumericType.count(:decimal)
      770

  """
  @impl Unicode.Property.Behaviour
  def count(numeric_type) do
    with {:ok, range_list} <- fetch(numeric_type) do
      Enum.reduce(range_list, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the numeric type of the given binary or codepoint.

  ### Arguments

  * `string_or_codepoint` is either a binary (String) or a codepoint in the range `0..0x10FFFF`.

  ### Returns

  * For a codepoint, a single numeric type atom is returned. Non-numeric codepoints return `:none`.

  * For a binary, a list of the distinct numeric types of the codepoints in the binary is returned.

  ### Examples

      iex> Unicode.NumericType.numeric_type(?1)
      :decimal

      iex> Unicode.NumericType.numeric_type(?A)
      :none

      iex> Unicode.NumericType.numeric_type(?½)
      :numeric

  """
  def numeric_type(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&numeric_type/1)
    |> Enum.uniq()
  end

  def numeric_type(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    Unicode.RangeSearch.find(@numeric_type_table, codepoint, :none)
  end
end
