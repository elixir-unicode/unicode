defmodule Unicode.DecompositionType do
  @moduledoc """
  Functions to introspect the Unicode `Decomposition_Type` property for binaries (Strings) and codepoints.

  The `Decomposition_Type` property classifies the kind of decomposition mapping a codepoint has, for example `:canonical`, `:compat`, `:font`, `:circle` or `:nobreak`. Codepoints with no decomposition mapping have the value `:none`.

  The primary API is `decomposition_type/1` which returns the decomposition type of a codepoint, or the list of decomposition types of a string.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @decomposition_types Utils.decomposition_types()
                       |> Utils.remove_annotations()

  @decomposition_type_table Unicode.RangeSearch.new_value_table(@decomposition_types)

  @doc """
  Returns the map of Unicode decomposition types.

  ### Returns

  * A map where the decomposition type is the key and a list of codepoint ranges as 2-tuples is the value.

  ### Examples

      iex> :canonical in Map.keys(Unicode.DecompositionType.decomposition_types())
      true

  """
  def decomposition_types do
    @decomposition_types
  end

  @doc """
  Returns a list of known Unicode decomposition type names.

  ### Returns

  * A list of atom decomposition type names.

  ### Examples

      iex> :compat in Unicode.DecompositionType.known_decomposition_types()
      true

  """
  @known_decomposition_types Map.keys(@decomposition_types)
  def known_decomposition_types do
    @known_decomposition_types
  end

  @doc """
  Returns a map of aliases for Unicode decomposition types.

  ### Returns

  * A map where the alias string is the key and the decomposition type is the value.

  ### Examples

      iex> Unicode.DecompositionType.aliases() |> Map.get("can")
      :canonical

  """
  @decomposition_type_aliases Utils.value_aliases("dt", @known_decomposition_types)
                              |> Utils.add_canonical_alias()

  @impl Unicode.Property.Behaviour
  def aliases do
    @decomposition_type_aliases
  end

  @doc """
  Returns the Unicode codepoint ranges for a given decomposition type.

  Aliases are resolved by this function.

  ### Arguments

  * `decomposition_type` is any decomposition type name or alias, as an atom or string.

  ### Returns

  * `{:ok, range_list}` where `range_list` is a list of codepoint ranges as 2-tuples.

  * `:error` if the decomposition type is not known.

  ### Examples

      iex> Unicode.DecompositionType.fetch(:canonical) |> elem(0)
      :ok

      iex> Unicode.DecompositionType.fetch(:invalid)
      :error

  """
  @impl Unicode.Property.Behaviour
  def fetch(decomposition_type) when is_atom(decomposition_type) do
    Map.fetch(decomposition_types(), decomposition_type)
  end

  def fetch(decomposition_type) do
    decomposition_type = Utils.downcase_and_remove_whitespace(decomposition_type)

    decomposition_type =
      Map.get(aliases(), decomposition_type, decomposition_type) |> Utils.maybe_atomize()

    Map.fetch(decomposition_types(), decomposition_type)
  end

  @doc """
  Returns the Unicode codepoint ranges for a given decomposition type.

  Aliases are resolved by this function.

  ### Arguments

  * `decomposition_type` is any decomposition type name or alias, as an atom or string.

  ### Returns

  * A list of codepoint ranges as 2-tuples.

  * `nil` if the decomposition type is not known.

  ### Examples

      iex> Unicode.DecompositionType.get(:invalid)
      nil

  """
  @impl Unicode.Property.Behaviour
  def get(decomposition_type) do
    case fetch(decomposition_type) do
      {:ok, range_list} -> range_list
      _ -> nil
    end
  end

  @doc """
  Returns the count of the codepoints with a given decomposition type.

  Aliases are resolved by this function.

  ### Arguments

  * `decomposition_type` is any decomposition type name or alias, as an atom or string.

  ### Returns

  * A non-negative integer count of the codepoints with the decomposition type.

  * `:error` if the decomposition type is not known.

  ### Examples

      iex> is_integer(Unicode.DecompositionType.count(:canonical))
      true

  """
  @impl Unicode.Property.Behaviour
  def count(decomposition_type) do
    with {:ok, range_list} <- fetch(decomposition_type) do
      Enum.reduce(range_list, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the decomposition type of the given binary or codepoint.

  ### Arguments

  * `string_or_codepoint` is either a binary (String) or a codepoint in the range `0..0x10FFFF`.

  ### Returns

  * For a codepoint, a single decomposition type atom is returned. Codepoints with no decomposition mapping return `:none`.

  * For a binary, a list of the distinct decomposition types of the codepoints in the binary is returned.

  ### Examples

      iex> Unicode.DecompositionType.decomposition_type(0x00A0)
      :nobreak

      iex> Unicode.DecompositionType.decomposition_type(?A)
      :none

  """
  def decomposition_type(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&decomposition_type/1)
    |> Enum.uniq()
  end

  def decomposition_type(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    Unicode.RangeSearch.find(@decomposition_type_table, codepoint, :none)
  end
end
