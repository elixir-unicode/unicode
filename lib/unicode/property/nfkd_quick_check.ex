defmodule Unicode.NfkdQuickCheck do
  @moduledoc """
  Functions to introspect the Unicode `NFKD_Quick_Check` property for binaries (Strings) and codepoints.

  The `NFKD_Quick_Check` property is used by the quick check algorithm of [UAX #15](https://www.unicode.org/reports/tr15/) to determine whether a string is already in Normalization Form KD. The value is `:no`; codepoints that are always allowed in NFKD have the default value `:yes`.

  The primary API is `nfkd_quick_check/1` which returns the value of a codepoint, or the list of values of a string.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @nfkd_quick_check Utils.quick_check_properties() |> Map.fetch!(:nfkd_qc)

  @nfkd_quick_check_table Unicode.RangeSearch.new_value_table(@nfkd_quick_check)

  @doc """
  Returns the map of `NFKD_Quick_Check` values to codepoint ranges.

  ### Returns

  * A map where the quick check value (`:no`) is the key and a list of codepoint ranges as 2-tuples is the value.

  ### Examples

      iex> Unicode.NfkdQuickCheck.nfkd_quick_check() |> Map.keys() |> Enum.sort()
      [:no]

  """
  def nfkd_quick_check do
    @nfkd_quick_check
  end

  @doc """
  Returns a list of known `NFKD_Quick_Check` values.

  ### Returns

  * A list of atom values.

  ### Examples

      iex> :no in Unicode.NfkdQuickCheck.known_nfkd_quick_check()
      true

  """
  @known_nfkd_quick_check Map.keys(@nfkd_quick_check)
  def known_nfkd_quick_check do
    @known_nfkd_quick_check
  end

  @doc """
  Returns a map of aliases for `NFKD_Quick_Check` values.

  ### Returns

  * A map where the alias string is the key and the value is the atom value.

  ### Examples

      iex> Unicode.NfkdQuickCheck.aliases() |> Map.get("n")
      :no

  """
  @nfkd_quick_check_aliases Utils.value_aliases("nfkd_qc", @known_nfkd_quick_check)
                            |> Utils.add_canonical_alias()

  @impl Unicode.Property.Behaviour
  def aliases do
    @nfkd_quick_check_aliases
  end

  @doc """
  Returns the codepoint ranges for a given `NFKD_Quick_Check` value.

  Aliases are resolved by this function.

  ### Arguments

  * `value` is any value name or alias, as an atom or string.

  ### Returns

  * `{:ok, range_list}` where `range_list` is a list of codepoint ranges as 2-tuples.

  * `:error` if the value is not known.

  ### Examples

      iex> Unicode.NfkdQuickCheck.fetch(:no) |> elem(0)
      :ok

      iex> Unicode.NfkdQuickCheck.fetch(:invalid)
      :error

  """
  @impl Unicode.Property.Behaviour
  def fetch(value) when is_atom(value) do
    Map.fetch(nfkd_quick_check(), value)
  end

  def fetch(value) do
    value = Utils.downcase_and_remove_whitespace(value)
    value = Map.get(aliases(), value, value) |> Utils.maybe_atomize()
    Map.fetch(nfkd_quick_check(), value)
  end

  @doc """
  Returns the codepoint ranges for a given `NFKD_Quick_Check` value.

  Aliases are resolved by this function.

  ### Arguments

  * `value` is any value name or alias, as an atom or string.

  ### Returns

  * A list of codepoint ranges as 2-tuples.

  * `nil` if the value is not known.

  ### Examples

      iex> Unicode.NfkdQuickCheck.get(:invalid)
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
  Returns the count of the codepoints with a given `NFKD_Quick_Check` value.

  Aliases are resolved by this function.

  ### Arguments

  * `value` is any value name or alias, as an atom or string.

  ### Returns

  * A non-negative integer count of the codepoints with the value.

  * `:error` if the value is not known.

  ### Examples

      iex> is_integer(Unicode.NfkdQuickCheck.count(:no))
      true

  """
  @impl Unicode.Property.Behaviour
  def count(value) do
    with {:ok, range_list} <- fetch(value) do
      Enum.reduce(range_list, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the `NFKD_Quick_Check` value of the given binary or codepoint.

  ### Arguments

  * `string_or_codepoint` is either a binary (String) or a codepoint in the range `0..0x10FFFF`.

  ### Returns

  * For a codepoint, `:no` or the default `:yes`.

  * For a binary, a list of the distinct values of the codepoints in the binary is returned.

  ### Examples

      iex> Unicode.NfkdQuickCheck.nfkd_quick_check(?A)
      :yes

      iex> Unicode.NfkdQuickCheck.nfkd_quick_check(0x00C0)
      :no

  """
  def nfkd_quick_check(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&nfkd_quick_check/1)
    |> Enum.uniq()
  end

  def nfkd_quick_check(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    Unicode.RangeSearch.find(@nfkd_quick_check_table, codepoint, :yes)
  end
end
