defmodule Unicode.LineBreak do
  @moduledoc """
  Functions to introspect the Unicode line break property for binaries (Strings) and codepoints.

  The primary API is `line_break/1` which returns the line break property for a codepoint or the list of line break properties for a string.

  The functions `fetch/1`, `get/1` and `count/1` provide introspection of the codepoint ranges associated with a given line break property. `line_breaks/0`, `known_line_breaks/0` and `aliases/0` return the underlying property data.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @line_breaks Utils.line_breaks()
               |> Utils.remove_annotations()

  @line_break_table Unicode.RangeSearch.new_value_table(@line_breaks)

  @doc """
  Returns the map of Unicode line breaks.

  ### Returns

  * A map with the line break name as the key and a list of codepoint ranges as 2-tuples as the value.

  ### Examples

      iex> Unicode.LineBreak.line_breaks() |> Map.get(:lf)
      [{10, 10}]

  """

  def line_breaks do
    @line_breaks
  end

  @doc """
  Returns a list of known Unicode line break names.

  This function does not return the names of any line break aliases.

  ### Returns

  * A list of line break names as atoms.

  ### Examples

      iex> Unicode.LineBreak.known_line_breaks() |> Enum.sort() |> Enum.take(3)
      [:ai, :ak, :al]

  """
  @known_line_breaks Map.keys(@line_breaks)
  def known_line_breaks do
    @known_line_breaks
  end

  @line_break_alias Utils.property_value_alias()
                    |> Map.get("lb")
                    |> Utils.atomize_values()
                    |> Utils.downcase_keys_and_remove_whitespace()
                    |> Utils.add_canonical_alias()

  @doc """
  Returns a map of aliases for Unicode line breaks.

  An alias is an alternative name for referring to a line break. Aliases are resolved by the `fetch/1` and `get/1` functions.

  ### Returns

  * A map with the alias as a string key and the line break name as an atom value.

  ### Examples

      iex> Unicode.LineBreak.aliases() |> Map.get("linefeed")
      :lf

  """
  @impl Unicode.Property.Behaviour
  def aliases do
    @line_break_alias
  end

  @doc """
  Returns the Unicode codepoint ranges for a given line break.

  Aliases are resolved by this function.

  ### Arguments

  * `line_break` is any line break name as an atom, or a string alias for a line break.

  ### Returns

  * `{:ok, range_list}` where `range_list` is a list of codepoint ranges as 2-tuples.

  * `:error` if the line break name is not known.

  ### Examples

      iex> Unicode.LineBreak.fetch(:lf)
      {:ok, [{10, 10}]}

      iex> Unicode.LineBreak.fetch(:invalid)
      :error

  """
  @impl Unicode.Property.Behaviour
  def fetch(line_break) when is_atom(line_break) do
    Map.fetch(line_breaks(), line_break)
  end

  def fetch(line_break) do
    line_break = Utils.downcase_and_remove_whitespace(line_break)
    line_break = Map.get(aliases(), line_break, line_break)
    Map.fetch(line_breaks(), line_break)
  end

  @doc """
  Returns the Unicode codepoint ranges for a given line break.

  Aliases are resolved by this function.

  ### Arguments

  * `line_break` is any line break name as an atom, or a string alias for a line break.

  ### Returns

  * `range_list` which is a list of codepoint ranges as 2-tuples.

  * `nil` if the line break name is not known.

  ### Examples

      iex> Unicode.LineBreak.get(:lf)
      [{10, 10}]

      iex> Unicode.LineBreak.get(:invalid)
      nil

  """
  @impl Unicode.Property.Behaviour
  def get(line_break) do
    case fetch(line_break) do
      {:ok, line_break} -> line_break
      _ -> nil
    end
  end

  @doc """
  Returns the count of the number of characters for a given line break.

  ### Arguments

  * `line_break` is any line break name as an atom, or a string alias for a line break.

  ### Returns

  * The number of codepoints that have the given line break.

  * `:error` if the line break name is not known.

  ### Examples

      iex> Unicode.LineBreak.count(:al)
      26954

  """
  @impl Unicode.Property.Behaviour
  def count(line_break) do
    with {:ok, line_break} <- fetch(line_break) do
      Enum.reduce(line_break, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the line break name(s) for the given binary or codepoint.

  ### Arguments

  * `codepoint_or_string` is either an integer codepoint or a string.

  ### Returns

  * In the case of a codepoint, a single line break name as an atom. Codepoints with no explicit line break property default to `:xx`.

  * In the case of a string, a list of the distinct line break names represented by the codepoints in the string.

  ### Examples

      iex> Unicode.LineBreak.line_break(?\\n)
      :lf

      iex> Unicode.LineBreak.line_break("a b")
      [:al, :sp]

  """
  def line_break(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&line_break/1)
    |> Enum.uniq()
  end

  def line_break(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    Unicode.RangeSearch.find(@line_break_table, codepoint, :xx)
  end
end
