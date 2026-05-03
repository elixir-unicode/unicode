defmodule Unicode.JoiningType do
  @moduledoc """
  Functions to introspect Unicode
  joining types for binaries
  (Strings) and codepoints.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @joining_types Utils.joining_types()
                 |> Utils.remove_annotations()

  @doc """
  Returns the map of Unicode
  joining types.

  The joining type name is the map
  key and a list of codepoint
  ranges as tuples as the value.

  """

  def joining_types do
    @joining_types
  end

  @doc """
  Returns a list of known Unicode
  joining type names.

  This function does not return the
  names of any type aliases.

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
  Returns a map of aliases for
  Unicode joining types.

  An alias is an alternative name
  for referring to a joining type. Aliases
  are resolved by the `fetch/1` and
  `get/1` functions.

  """
  @impl Unicode.Property.Behaviour
  def aliases do
    @joining_type_alias
  end

  @doc """
  Returns the Unicode ranges for
  a given joining type as a list of
  ranges as 2-tuples.

  Aliases are resolved by this function.

  Returns either `{:ok, range_list}` or
  `:error`.

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
  Returns the Unicode ranges for
  a given joining type as a list of
  ranges as 2-tuples.

  Aliases are resolved by this function.

  Returns either `range_list` or
  `nil`.

  """
  @impl Unicode.Property.Behaviour
  def get(joining_type) do
    case fetch(joining_type) do
      {:ok, joining_type} -> joining_type
      _ -> nil
    end
  end

  @doc """
  Returns the count of the number of characters
  for a given joining type.

  ## Example

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
  Returns the joining type name(s) for the
  given binary or codepoint.

  In the case of a codepoint, a single
  joining type name is returned. Code points
  with no explicit `Joining_Type` assignment
  default to `:u` (Non_Joining).

  For a binary a list of distinct joining
  type names represented by the codepoints
  in the binary is returned.

  ## Examples

      iex> Unicode.JoiningType.joining_type ?A
      :u

      iex> Unicode.JoiningType.joining_type 0x0640
      :c

      iex> Unicode.JoiningType.joining_type 0x0628
      :d

      iex> Unicode.JoiningType.joining_type 0x200D
      :c

  """
  def joining_type(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&joining_type/1)
    |> Enum.uniq()
  end

  for {joining_type, ranges} <- @joining_types do
    def joining_type(codepoint) when unquote(Utils.ranges_to_guard_clause(ranges)) do
      unquote(joining_type)
    end
  end

  def joining_type(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    :u
  end
end
