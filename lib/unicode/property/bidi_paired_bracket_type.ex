defmodule Unicode.BidiPairedBracketType do
  @moduledoc """
  Functions to introspect the Unicode `Bidi_Paired_Bracket_Type` property for binaries (Strings) and codepoints.

  The `Bidi_Paired_Bracket_Type` property identifies the bracket pairs used by the bidirectional algorithm (see [UAX #9](https://www.unicode.org/reports/tr9/)). The values are `:open` and `:close`; all other codepoints have the value `:none`.

  The primary API is `bidi_paired_bracket_type/1` which returns the type of a codepoint, or the list of types of a string.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @bidi_paired_bracket_types Utils.bidi_paired_bracket_types()

  @bidi_paired_bracket_type_table Unicode.RangeSearch.new_value_table(@bidi_paired_bracket_types)

  @doc """
  Returns the map of Unicode bidi paired bracket types.

  ### Returns

  * A map where the type (`:open` or `:close`) is the key and a list of codepoint ranges as 2-tuples is the value.

  ### Examples

      iex> Unicode.BidiPairedBracketType.bidi_paired_bracket_types() |> Map.keys() |> Enum.sort()
      [:close, :open]

  """
  def bidi_paired_bracket_types do
    @bidi_paired_bracket_types
  end

  @doc """
  Returns a list of known Unicode bidi paired bracket type names.

  ### Returns

  * A list of atom type names.

  ### Examples

      iex> :open in Unicode.BidiPairedBracketType.known_bidi_paired_bracket_types()
      true

  """
  @known_bidi_paired_bracket_types Map.keys(@bidi_paired_bracket_types)
  def known_bidi_paired_bracket_types do
    @known_bidi_paired_bracket_types
  end

  @doc """
  Returns a map of aliases for Unicode bidi paired bracket types.

  ### Returns

  * A map where the alias string is the key and the type is the value.

  ### Examples

      iex> Unicode.BidiPairedBracketType.aliases() |> Map.get("o")
      :open

  """
  @bidi_paired_bracket_type_aliases Utils.value_aliases("bpt", @known_bidi_paired_bracket_types)
                                    |> Utils.add_canonical_alias()

  @impl Unicode.Property.Behaviour
  def aliases do
    @bidi_paired_bracket_type_aliases
  end

  @doc """
  Returns the Unicode codepoint ranges for a given bidi paired bracket type.

  Aliases are resolved by this function.

  ### Arguments

  * `type` is any type name or alias, as an atom or string.

  ### Returns

  * `{:ok, range_list}` where `range_list` is a list of codepoint ranges as 2-tuples.

  * `:error` if the type is not known.

  ### Examples

      iex> Unicode.BidiPairedBracketType.fetch(:open) |> elem(0)
      :ok

      iex> Unicode.BidiPairedBracketType.fetch(:invalid)
      :error

  """
  @impl Unicode.Property.Behaviour
  def fetch(type) when is_atom(type) do
    Map.fetch(bidi_paired_bracket_types(), type)
  end

  def fetch(type) do
    type = Utils.downcase_and_remove_whitespace(type)
    type = Map.get(aliases(), type, type) |> Utils.maybe_atomize()
    Map.fetch(bidi_paired_bracket_types(), type)
  end

  @doc """
  Returns the Unicode codepoint ranges for a given bidi paired bracket type.

  Aliases are resolved by this function.

  ### Arguments

  * `type` is any type name or alias, as an atom or string.

  ### Returns

  * A list of codepoint ranges as 2-tuples.

  * `nil` if the type is not known.

  ### Examples

      iex> Unicode.BidiPairedBracketType.get(:invalid)
      nil

  """
  @impl Unicode.Property.Behaviour
  def get(type) do
    case fetch(type) do
      {:ok, range_list} -> range_list
      _ -> nil
    end
  end

  @doc """
  Returns the count of the codepoints with a given bidi paired bracket type.

  Aliases are resolved by this function.

  ### Arguments

  * `type` is any type name or alias, as an atom or string.

  ### Returns

  * A non-negative integer count of the codepoints with the type.

  * `:error` if the type is not known.

  ### Examples

      iex> is_integer(Unicode.BidiPairedBracketType.count(:open))
      true

  """
  @impl Unicode.Property.Behaviour
  def count(type) do
    with {:ok, range_list} <- fetch(type) do
      Enum.reduce(range_list, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the bidi paired bracket type of the given binary or codepoint.

  ### Arguments

  * `string_or_codepoint` is either a binary (String) or a codepoint in the range `0..0x10FFFF`.

  ### Returns

  * For a codepoint, a single type atom is returned. Codepoints that are not brackets return `:none`.

  * For a binary, a list of the distinct types of the codepoints in the binary is returned.

  ### Examples

      iex> Unicode.BidiPairedBracketType.bidi_paired_bracket_type(?\\()
      :open

      iex> Unicode.BidiPairedBracketType.bidi_paired_bracket_type(?\\))
      :close

      iex> Unicode.BidiPairedBracketType.bidi_paired_bracket_type(?A)
      :none

  """
  def bidi_paired_bracket_type(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&bidi_paired_bracket_type/1)
    |> Enum.uniq()
  end

  def bidi_paired_bracket_type(codepoint)
      when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    Unicode.RangeSearch.find(@bidi_paired_bracket_type_table, codepoint, :none)
  end
end
