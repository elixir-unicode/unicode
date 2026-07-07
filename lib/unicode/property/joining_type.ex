defmodule Unicode.JoiningType do
  @moduledoc """
  Functions to introspect the Unicode joining type property for binaries (Strings) and codepoints.

  The primary API is `joining_type/1` which returns the joining type for a codepoint or the list of joining types for a string.

  The functions `fetch/1`, `get/1` and `count/1` provide introspection of the codepoint ranges associated with a given joining type. `joining_types/0`, `known_joining_types/0` and `aliases/0` return the underlying property data.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @joining_types Utils.joining_types()
                 |> Utils.remove_annotations()

  @joining_type_table Unicode.RangeSearch.new_value_table(@joining_types)

  @doc """
  Returns the map of Unicode joining types.

  ### Returns

  * A map with the joining type name as the key and a list of codepoint ranges as 2-tuples as the value.

  ### Examples

      iex> Unicode.JoiningType.joining_types() |> Map.get(:c)
      [{1600, 1600}, {2042, 2042}, {2179, 2181}, {6154, 6154}, {8205, 8205}]

  """

  def joining_types do
    @joining_types
  end

  @doc """
  Returns a list of known Unicode joining type names.

  This function does not return the names of any joining type aliases.

  ### Returns

  * A list of joining type names as atoms.

  ### Examples

      iex> Unicode.JoiningType.known_joining_types() |> Enum.sort()
      [:c, :d, :l, :r, :t]

  """
  @known_joining_types Map.keys(@joining_types)
  def known_joining_types do
    @known_joining_types
  end

  @joining_type_alias Utils.property_value_alias()
                      |> Map.get("jt")
                      |> Utils.atomize_values()
                      |> Utils.downcase_keys_and_remove_whitespace()
                      |> Utils.add_canonical_alias()

  @doc """
  Returns a map of aliases for Unicode joining types.

  An alias is an alternative name for referring to a joining type. Aliases are resolved by the `fetch/1` and `get/1` functions.

  ### Returns

  * A map with the alias as a string key and the joining type name as an atom value.

  ### Examples

      iex> Unicode.JoiningType.aliases() |> Map.get("dualjoining")
      :d

  """
  @impl Unicode.Property.Behaviour
  def aliases do
    @joining_type_alias
  end

  @doc """
  Returns the Unicode codepoint ranges for a given joining type.

  Aliases are resolved by this function.

  ### Arguments

  * `joining_type` is any joining type name as an atom, or a string alias for a joining type.

  ### Returns

  * `{:ok, range_list}` where `range_list` is a list of codepoint ranges as 2-tuples.

  * `:error` if the joining type name is not known.

  ### Examples

      iex> Unicode.JoiningType.fetch(:c)
      {:ok, [{1600, 1600}, {2042, 2042}, {2179, 2181}, {6154, 6154}, {8205, 8205}]}

      iex> Unicode.JoiningType.fetch(:invalid)
      :error

  """
  @impl Unicode.Property.Behaviour
  def fetch(joining_type) when is_atom(joining_type) do
    Map.fetch(joining_types(), joining_type)
  end

  def fetch(joining_type) do
    joining_type = Utils.downcase_and_remove_whitespace(joining_type)
    joining_type = Map.get(aliases(), joining_type, joining_type)
    Map.fetch(joining_types(), joining_type)
  end

  @doc """
  Returns the Unicode codepoint ranges for a given joining type.

  Aliases are resolved by this function.

  ### Arguments

  * `joining_type` is any joining type name as an atom, or a string alias for a joining type.

  ### Returns

  * `range_list` which is a list of codepoint ranges as 2-tuples.

  * `nil` if the joining type name is not known.

  ### Examples

      iex> Unicode.JoiningType.get(:c)
      [{1600, 1600}, {2042, 2042}, {2179, 2181}, {6154, 6154}, {8205, 8205}]

      iex> Unicode.JoiningType.get(:invalid)
      nil

  """
  @impl Unicode.Property.Behaviour
  def get(joining_type) do
    case fetch(joining_type) do
      {:ok, joining_type} -> joining_type
      _ -> nil
    end
  end

  @doc """
  Returns the count of the number of characters for a given joining type.

  ### Arguments

  * `joining_type` is any joining type name as an atom, or a string alias for a joining type.

  ### Returns

  * The number of codepoints that have the given joining type.

  * `:error` if the joining type name is not known.

  ### Examples

      iex> Unicode.JoiningType.count(:d)
      615

  """
  @impl Unicode.Property.Behaviour
  def count(joining_type) do
    with {:ok, joining_type} <- fetch(joining_type) do
      Enum.reduce(joining_type, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the joining type name(s) for the given binary or codepoint.

  ### Arguments

  * `codepoint_or_string` is either an integer codepoint or a string.

  ### Returns

  * In the case of a codepoint, a single joining type name as an atom. Codepoints with no explicit `Joining_Type` assignment default to `:u` (Non_Joining).

  * In the case of a string, a list of the distinct joining type names represented by the codepoints in the string.

  ### Examples

      iex> Unicode.JoiningType.joining_type(?A)
      :u

      iex> Unicode.JoiningType.joining_type(0x0628)
      :d

  """
  def joining_type(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&joining_type/1)
    |> Enum.uniq()
  end

  def joining_type(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    Unicode.RangeSearch.find(@joining_type_table, codepoint, :u)
  end
end
