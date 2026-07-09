defmodule Unicode.HangulSyllableType do
  @moduledoc """
  Functions to introspect the Unicode `Hangul_Syllable_Type` property for binaries (Strings) and codepoints.

  The `Hangul_Syllable_Type` property classifies Hangul jamo and precomposed syllables. The values are `:l` (Leading_Jamo), `:v` (Vowel_Jamo), `:t` (Trailing_Jamo), `:lv` (LV_Syllable) and `:lvt` (LVT_Syllable). Codepoints that are not Hangul have the value `:na` (Not_Applicable).

  The primary API is `hangul_syllable_type/1` which returns the type of a codepoint, or the list of types of a string.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @hangul_syllable_types Utils.hangul_syllable_types()
                         |> Utils.remove_annotations()

  @hangul_syllable_type_table Unicode.RangeSearch.new_value_table(@hangul_syllable_types)

  @doc """
  Returns the map of Unicode hangul syllable types.

  ### Returns

  * A map where the hangul syllable type is the key and a list of codepoint ranges as 2-tuples is the value.

  ### Examples

      iex> :lv in Map.keys(Unicode.HangulSyllableType.hangul_syllable_types())
      true

  """
  def hangul_syllable_types do
    @hangul_syllable_types
  end

  @doc """
  Returns a list of known Unicode hangul syllable type names.

  ### Returns

  * A list of atom hangul syllable type names.

  ### Examples

      iex> :lvt in Unicode.HangulSyllableType.known_hangul_syllable_types()
      true

  """
  @known_hangul_syllable_types Map.keys(@hangul_syllable_types)
  def known_hangul_syllable_types do
    @known_hangul_syllable_types
  end

  @doc """
  Returns a map of aliases for Unicode hangul syllable types.

  ### Returns

  * A map where the alias string is the key and the hangul syllable type is the value.

  ### Examples

      iex> Unicode.HangulSyllableType.aliases() |> Map.get("leadingjamo")
      :l

  """
  @hangul_syllable_type_aliases Utils.value_aliases("hst", @known_hangul_syllable_types)
                                |> Utils.add_canonical_alias()

  @impl Unicode.Property.Behaviour
  def aliases do
    @hangul_syllable_type_aliases
  end

  @doc """
  Returns the Unicode codepoint ranges for a given hangul syllable type.

  Aliases are resolved by this function.

  ### Arguments

  * `hangul_syllable_type` is any type name or alias, as an atom or string.

  ### Returns

  * `{:ok, range_list}` where `range_list` is a list of codepoint ranges as 2-tuples.

  * `:error` if the hangul syllable type is not known.

  ### Examples

      iex> Unicode.HangulSyllableType.fetch(:lv) |> elem(0)
      :ok

      iex> Unicode.HangulSyllableType.fetch(:invalid)
      :error

  """
  @impl Unicode.Property.Behaviour
  def fetch(hangul_syllable_type) when is_atom(hangul_syllable_type) do
    Map.fetch(hangul_syllable_types(), hangul_syllable_type)
  end

  def fetch(hangul_syllable_type) do
    hangul_syllable_type = Utils.downcase_and_remove_whitespace(hangul_syllable_type)

    hangul_syllable_type =
      Map.get(aliases(), hangul_syllable_type, hangul_syllable_type) |> Utils.maybe_atomize()

    Map.fetch(hangul_syllable_types(), hangul_syllable_type)
  end

  @doc """
  Returns the Unicode codepoint ranges for a given hangul syllable type.

  Aliases are resolved by this function.

  ### Arguments

  * `hangul_syllable_type` is any type name or alias, as an atom or string.

  ### Returns

  * A list of codepoint ranges as 2-tuples.

  * `nil` if the hangul syllable type is not known.

  ### Examples

      iex> Unicode.HangulSyllableType.get(:invalid)
      nil

  """
  @impl Unicode.Property.Behaviour
  def get(hangul_syllable_type) do
    case fetch(hangul_syllable_type) do
      {:ok, range_list} -> range_list
      _ -> nil
    end
  end

  @doc """
  Returns the count of the codepoints with a given hangul syllable type.

  Aliases are resolved by this function.

  ### Arguments

  * `hangul_syllable_type` is any type name or alias, as an atom or string.

  ### Returns

  * A non-negative integer count of the codepoints with the hangul syllable type.

  * `:error` if the hangul syllable type is not known.

  ### Examples

      iex> Unicode.HangulSyllableType.count(:lv)
      399

  """
  @impl Unicode.Property.Behaviour
  def count(hangul_syllable_type) do
    with {:ok, range_list} <- fetch(hangul_syllable_type) do
      Enum.reduce(range_list, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the hangul syllable type of the given binary or codepoint.

  ### Arguments

  * `string_or_codepoint` is either a binary (String) or a codepoint in the range `0..0x10FFFF`.

  ### Returns

  * For a codepoint, a single type atom is returned. Non-Hangul codepoints return `:na`.

  * For a binary, a list of the distinct types of the codepoints in the binary is returned.

  ### Examples

      iex> Unicode.HangulSyllableType.hangul_syllable_type(0xAC00)
      :lv

      iex> Unicode.HangulSyllableType.hangul_syllable_type(?A)
      :na

  """
  def hangul_syllable_type(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&hangul_syllable_type/1)
    |> Enum.uniq()
  end

  def hangul_syllable_type(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    Unicode.RangeSearch.find(@hangul_syllable_type_table, codepoint, :na)
  end
end
