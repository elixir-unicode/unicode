defmodule Unicode.NfcQuickCheck do
  @moduledoc """
  Functions to introspect the Unicode `NFC_Quick_Check` property for binaries (Strings) and codepoints.

  The `NFC_Quick_Check` property is used by the quick check algorithm of [UAX #15](https://www.unicode.org/reports/tr15/) to determine whether a string is already in Normalization Form C. The values are `:no` and `:maybe`; codepoints that are always allowed in NFC have the default value `:yes`.

  The primary API is `nfc_quick_check/1` which returns the value of a codepoint, or the list of values of a string.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @nfc_quick_check Utils.quick_check_properties() |> Map.fetch!(:nfc_qc)

  @nfc_quick_check_table Unicode.RangeSearch.new_value_table(@nfc_quick_check)

  @doc """
  Returns the map of `NFC_Quick_Check` values to codepoint ranges.

  ### Returns

  * A map where the quick check value (`:no` or `:maybe`) is the key and a list of codepoint ranges as 2-tuples is the value.

  ### Examples

      iex> Unicode.NfcQuickCheck.nfc_quick_check() |> Map.keys() |> Enum.sort()
      [:maybe, :no]

  """
  def nfc_quick_check do
    @nfc_quick_check
  end

  @doc """
  Returns a list of known `NFC_Quick_Check` values.

  ### Returns

  * A list of atom values.

  ### Examples

      iex> :maybe in Unicode.NfcQuickCheck.known_nfc_quick_check()
      true

  """
  @known_nfc_quick_check Map.keys(@nfc_quick_check)
  def known_nfc_quick_check do
    @known_nfc_quick_check
  end

  @doc """
  Returns a map of aliases for `NFC_Quick_Check` values.

  ### Returns

  * A map where the alias string is the key and the value is the atom value.

  ### Examples

      iex> Unicode.NfcQuickCheck.aliases() |> Map.get("n")
      :no

  """
  @nfc_quick_check_aliases Utils.value_aliases("nfc_qc", @known_nfc_quick_check)
                           |> Utils.add_canonical_alias()

  @impl Unicode.Property.Behaviour
  def aliases do
    @nfc_quick_check_aliases
  end

  @doc """
  Returns the codepoint ranges for a given `NFC_Quick_Check` value.

  Aliases are resolved by this function.

  ### Arguments

  * `value` is any value name or alias, as an atom or string.

  ### Returns

  * `{:ok, range_list}` where `range_list` is a list of codepoint ranges as 2-tuples.

  * `:error` if the value is not known.

  ### Examples

      iex> Unicode.NfcQuickCheck.fetch(:no) |> elem(0)
      :ok

      iex> Unicode.NfcQuickCheck.fetch(:invalid)
      :error

  """
  @impl Unicode.Property.Behaviour
  def fetch(value) when is_atom(value) do
    Map.fetch(nfc_quick_check(), value)
  end

  def fetch(value) do
    value = Utils.downcase_and_remove_whitespace(value)
    value = Map.get(aliases(), value, value) |> Utils.maybe_atomize()
    Map.fetch(nfc_quick_check(), value)
  end

  @doc """
  Returns the codepoint ranges for a given `NFC_Quick_Check` value.

  Aliases are resolved by this function.

  ### Arguments

  * `value` is any value name or alias, as an atom or string.

  ### Returns

  * A list of codepoint ranges as 2-tuples.

  * `nil` if the value is not known.

  ### Examples

      iex> Unicode.NfcQuickCheck.get(:invalid)
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
  Returns the count of the codepoints with a given `NFC_Quick_Check` value.

  Aliases are resolved by this function.

  ### Arguments

  * `value` is any value name or alias, as an atom or string.

  ### Returns

  * A non-negative integer count of the codepoints with the value.

  * `:error` if the value is not known.

  ### Examples

      iex> is_integer(Unicode.NfcQuickCheck.count(:no))
      true

  """
  @impl Unicode.Property.Behaviour
  def count(value) do
    with {:ok, range_list} <- fetch(value) do
      Enum.reduce(range_list, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the `NFC_Quick_Check` value of the given binary or codepoint.

  ### Arguments

  * `string_or_codepoint` is either a binary (String) or a codepoint in the range `0..0x10FFFF`.

  ### Returns

  * For a codepoint, `:no`, `:maybe` or the default `:yes`.

  * For a binary, a list of the distinct values of the codepoints in the binary is returned.

  ### Examples

      iex> Unicode.NfcQuickCheck.nfc_quick_check(?A)
      :yes

      iex> Unicode.NfcQuickCheck.nfc_quick_check(0x0300)
      :maybe

  """
  def nfc_quick_check(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&nfc_quick_check/1)
    |> Enum.uniq()
  end

  def nfc_quick_check(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    Unicode.RangeSearch.find(@nfc_quick_check_table, codepoint, :yes)
  end
end
