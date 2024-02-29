defmodule Unicode.IndicConjunctBreak do
  @moduledoc """
  Property manager for the Unicode Indic Conjunction Break
  property.

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
  |> Enum.group_by(&elem(&1, 0), &(elem(&1, 1)))
  |> Enum.map(fn {value, range} -> {value, Enum.sort(range)} end)
  |> Map.new()

  @doc """
  Returns the map of Unicode
  Indic Conjunction Breaks..

  """

  def indic_conjunct_break do
    @indic_conjunct_breaks
  end

  @doc """
  Returns a list of known Unicode
  indic_conjunct_break names.

  This function does not return the
  names of any indic_conjunct_break aliases.

  """
  @known_indic_conjunct_breaks Map.keys(@indic_conjunct_breaks)
  def known_indic_conjunct_breaks do
    @known_indic_conjunct_breaks
  end

  @indic_conjunct_break_alias @indic_conjunct_breaks
  |> Enum.map(fn {value, _} -> {value |> Atom.to_string |> String.downcase(), value} end)
  |> Map.new()

  @doc """
  Returns a map of aliases for
  Unicode indic_conjunct_breaks.

  An alias is an alternative name
  for referring to a indic_conjunct_break. Aliases
  are resolved by the `fetch/1` and
  `get/1` functions.

  """
  @impl Unicode.Property.Behaviour
  def aliases do
    @indic_conjunct_break_alias
  end

  @doc """
  Returns the Unicode ranges for
  a given indic_conjunct_break as a list of
  ranges as 2-tuples.

  Aliases are resolved by this function.

  Returns either `{:ok, range_list}` or
  `:error`.

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
  Returns the Unicode ranges for
  a given indic_conjunct_break as a list of
  ranges as 2-tuples.

  Aliases are resolved by this function.

  Returns either `range_list` or
  `nil`.

  """
  @impl Unicode.Property.Behaviour
  def get(indic_conjunct_break) do
    case fetch(indic_conjunct_break) do
      {:ok, indic_conjunct_break} -> indic_conjunct_break
      _ -> nil
    end
  end

  @doc """
  Returns the count of the number of characters
  for a given indic_conjunct_break.

  ## Example

      iex> Unicode.Script.count("mongolian")
      168

  """
  @impl Unicode.Property.Behaviour
  def count(indic_conjunct_break) do
    with {:ok, indic_conjunct_break} <- fetch(indic_conjunct_break) do
      Enum.reduce(indic_conjunct_break, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the indic_conjunct_break name(s) for the
  given binary or codepoint.

  In the case of a codepoint, a single
  indic_conjunct_break name is returned.

  For a binary a list of distinct indic_conjunct_break
  names represented by the graphemes in
  the binary is returned.

  """
  def indic_conjunct_break(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&indic_conjunct_break/1)
    |> Enum.uniq()
  end

  for {indic_conjunct_break, ranges} <- @indic_conjunct_breaks do
    def indic_conjunct_break(codepoint) when unquote(Utils.ranges_to_guard_clause(ranges)) do
      unquote(indic_conjunct_break)
    end
  end

  def indic_conjunct_break(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    :none
  end
end
