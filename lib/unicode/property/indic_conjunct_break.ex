defmodule Unicode.IndicConjunctBreak do
  @moduledoc """
  Functions to introspect the Unicode Indic conjunct break property for binaries (Strings) and codepoints.

  The primary API is `indic_conjunct_break/1` which returns the Indic conjunct break property for a codepoint or the list of Indic conjunct break properties for a string.

  The functions `fetch/1`, `get/1` and `count/1` provide introspection of the codepoint ranges associated with a given Indic conjunct break property. `indic_conjunct_break/0`, `known_indic_conjunct_breaks/0` and `aliases/0` return the underlying property data.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @indic_conjunct_breaks Utils.derived_properties()
                         |> Map.fetch!(:incb)
                         |> Enum.map(fn {from, to, [value | _category_and_name]} ->
                           value =
                             value
                             |> String.downcase()
                             |> String.to_atom()

                           {value, {from, to}}
                         end)
                         |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
                         |> Enum.map(fn {value, range} -> {value, Enum.sort(range)} end)
                         |> Map.new()

  @indic_conjunct_break_table Unicode.RangeSearch.new_value_table(@indic_conjunct_breaks)

  @doc """
  Returns the map of Unicode Indic conjunct breaks.

  ### Returns

  * A map with the Indic conjunct break name as the key and a list of codepoint ranges as 2-tuples as the value.

  ### Examples

      iex> Unicode.IndicConjunctBreak.indic_conjunct_break() |> Map.keys() |> Enum.sort()
      [:consonant, :extend, :linker]

  """

  def indic_conjunct_break do
    @indic_conjunct_breaks
  end

  @doc """
  Returns a list of known Unicode Indic conjunct break names.

  This function does not return the names of any Indic conjunct break aliases.

  ### Returns

  * A list of Indic conjunct break names as atoms.

  ### Examples

      iex> Unicode.IndicConjunctBreak.known_indic_conjunct_breaks() |> Enum.sort()
      [:consonant, :extend, :linker]

  """
  @known_indic_conjunct_breaks Map.keys(@indic_conjunct_breaks)
  def known_indic_conjunct_breaks do
    @known_indic_conjunct_breaks
  end

  @indic_conjunct_break_alias @indic_conjunct_breaks
                              |> Enum.map(fn {value, _} ->
                                {value |> Atom.to_string() |> String.downcase(), value}
                              end)
                              |> Map.new()

  @doc """
  Returns a map of aliases for Unicode Indic conjunct breaks.

  An alias is an alternative name for referring to an Indic conjunct break. Aliases are resolved by the `fetch/1` and `get/1` functions.

  ### Returns

  * A map with the alias as a string key and the Indic conjunct break name as an atom value.

  ### Examples

      iex> Unicode.IndicConjunctBreak.aliases() |> Map.get("linker")
      :linker

  """
  @impl Unicode.Property.Behaviour
  def aliases do
    @indic_conjunct_break_alias
  end

  @doc """
  Returns the Unicode codepoint ranges for a given Indic conjunct break.

  Aliases are resolved by this function.

  ### Arguments

  * `indic_conjunct_break` is any Indic conjunct break name as an atom, or a string alias for an Indic conjunct break.

  ### Returns

  * `{:ok, range_list}` where `range_list` is a list of codepoint ranges as 2-tuples.

  * `:error` if the Indic conjunct break name is not known.

  ### Examples

      iex> {:ok, ranges} = Unicode.IndicConjunctBreak.fetch(:linker)
      iex> Enum.take(ranges, 2)
      [{2381, 2381}, {2509, 2509}]

      iex> Unicode.IndicConjunctBreak.fetch(:invalid)
      :error

  """
  @impl Unicode.Property.Behaviour
  def fetch(indic_conjunct_break) when is_atom(indic_conjunct_break) do
    Map.fetch(indic_conjunct_break(), indic_conjunct_break)
  end

  def fetch(indic_conjunct_break) do
    indic_conjunct_break =
      Utils.downcase_and_remove_whitespace(indic_conjunct_break)

    indic_conjunct_break =
      Map.get(aliases(), indic_conjunct_break, indic_conjunct_break)
      |> Utils.maybe_atomize()

    Map.fetch(indic_conjunct_break(), indic_conjunct_break)
  end

  @doc """
  Returns the Unicode codepoint ranges for a given Indic conjunct break.

  Aliases are resolved by this function.

  ### Arguments

  * `indic_conjunct_break` is any Indic conjunct break name as an atom, or a string alias for an Indic conjunct break.

  ### Returns

  * `range_list` which is a list of codepoint ranges as 2-tuples.

  * `nil` if the Indic conjunct break name is not known.

  ### Examples

      iex> Unicode.IndicConjunctBreak.get(:linker) |> Enum.take(2)
      [{2381, 2381}, {2509, 2509}]

      iex> Unicode.IndicConjunctBreak.get(:invalid)
      nil

  """
  @impl Unicode.Property.Behaviour
  def get(indic_conjunct_break) do
    case fetch(indic_conjunct_break) do
      {:ok, indic_conjunct_break} -> indic_conjunct_break
      _ -> nil
    end
  end

  @doc """
  Returns the count of the number of characters for a given Indic conjunct break.

  ### Arguments

  * `indic_conjunct_break` is any Indic conjunct break name as an atom, or a string alias for an Indic conjunct break.

  ### Returns

  * The number of codepoints that have the given Indic conjunct break.

  * `:error` if the Indic conjunct break name is not known.

  ### Examples

      iex> Unicode.IndicConjunctBreak.count(:linker)
      20

  """
  @impl Unicode.Property.Behaviour
  def count(indic_conjunct_break) do
    with {:ok, indic_conjunct_break} <- fetch(indic_conjunct_break) do
      Enum.reduce(indic_conjunct_break, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the Indic conjunct break name(s) for the given binary or codepoint.

  ### Arguments

  * `codepoint_or_string` is either an integer codepoint or a string.

  ### Returns

  * In the case of a codepoint, a single Indic conjunct break name as an atom. Codepoints with no explicit Indic conjunct break property default to `:none`.

  * In the case of a string, a list of the distinct Indic conjunct break names represented by the codepoints in the string.

  ### Examples

      iex> Unicode.IndicConjunctBreak.indic_conjunct_break(0x094D)
      :linker

      iex> Unicode.IndicConjunctBreak.indic_conjunct_break(?A)
      :none

  """
  def indic_conjunct_break(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&indic_conjunct_break/1)
    |> Enum.uniq()
  end

  def indic_conjunct_break(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    Unicode.RangeSearch.find(@indic_conjunct_break_table, codepoint, :none)
  end
end
