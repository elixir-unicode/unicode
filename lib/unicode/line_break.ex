defmodule Unicode.LineBreak do
  @moduledoc """
  Functions to introspect Unicode
  line breaks for binaries
  (Strings) and codepoints.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @line_breaks Utils.line_breaks()
               |> Utils.remove_annotations()

  @doc """
  Returns the map of Unicode
  line breaks.

  The line break name is the map
  key and a list of codepoint
  ranges as tuples as the value.

  """

  def line_breaks do
    @line_breaks
  end

  @doc """
  Returns a list of known Unicode
  line break names.

  This function does not return the
  names of any line break aliases.

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
  Returns a map of aliases for
  Unicode line breaks.

  An alias is an alternative name
  for referring to a line break. Aliases
  are resolved by the `fetch/1` and
  `get/1` functions.

  """
  @impl Unicode.Property.Behaviour
  def aliases do
    @line_break_alias
  end

  @doc """
  Returns the Unicode ranges for
  a given line break as a list of
  ranges as 2-tuples.

  Aliases are resolved by this function.

  Returns either `{:ok, range_list}` or
  `:error`.

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
  Returns the Unicode ranges for
  a given line break as a list of
  ranges as 2-tuples.

  Aliases are resolved by this function.

  Returns either `range_list` or
  `nil`.

  """
  @impl Unicode.Property.Behaviour
  def get(line_break) do
    case fetch(line_break) do
      {:ok, line_break} -> line_break
      _ -> nil
    end
  end

  @doc """
  Returns the count of the number of characters
  for a given line_break.

  ## Example

      iex> Unicode.LineBreak.count(:al)
      22043

  """
  @impl Unicode.Property.Behaviour
  def count(line_break) do
    with {:ok, line_break} <- fetch(line_break) do
      Enum.reduce(line_break, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the line break name(s) for the
  given binary or codepoint.

  In the case of a codepoint, a single
  line_break name is returned.

  For a binary a list of distinct line break
  names represented by the lines in
  the binary is returned.

  """
  def line_break(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&line_break/1)
    |> Enum.uniq()
  end

  for {line_break, ranges} <- @line_breaks do
    def line_break(codepoint) when unquote(Utils.ranges_to_guard_clause(ranges)) do
      unquote(line_break)
    end
  end

  def line_break(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    :xx
  end
end
