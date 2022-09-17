defmodule Unicode.Script do
  @moduledoc """
  Functions to introspect Unicode
  scripts for binaries
  (Strings) and codepoints.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @scripts Utils.scripts()
           |> Utils.remove_annotations()

  @doc """
  Returns the map of Unicode
  scripts.

  The script name is the map
  key and a list of codepoint
  ranges as tuples as the value.

  """

  def scripts do
    @scripts
  end

  @doc """
  Returns a list of known Unicode
  script names.

  This function does not return the
  names of any script aliases.

  """
  @known_scripts Map.keys(@scripts)
  def known_scripts do
    @known_scripts
  end

  @script_alias Utils.property_value_alias()
                |> Map.get("sc")
                |> Utils.invert_map()
                |> Utils.atomize_values()
                |> Utils.downcase_keys_and_remove_whitespace()
                |> Utils.add_canonical_alias()

  @doc """
  Returns a map of aliases for
  Unicode scripts.

  An alias is an alternative name
  for referring to a script. Aliases
  are resolved by the `fetch/1` and
  `get/1` functions.

  """
  @impl Unicode.Property.Behaviour
  def aliases do
    @script_alias
  end

  @doc """
  Returns the Unicode ranges for
  a given script as a list of
  ranges as 2-tuples.

  Aliases are resolved by this function.

  Returns either `{:ok, range_list}` or
  `:error`.

  """
  @impl Unicode.Property.Behaviour
  def fetch(script) when is_atom(script) do
    Map.fetch(scripts(), script)
  end

  def fetch(script) do
    script = Utils.downcase_and_remove_whitespace(script)
    script = Map.get(aliases(), script, script) |> Utils.maybe_atomize()
    Map.fetch(scripts(), script)
  end

  @doc """
  Returns the Unicode ranges for
  a given script as a list of
  ranges as 2-tuples.

  Aliases are resolved by this function.

  Returns either `range_list` or
  `nil`.

  """
  @impl Unicode.Property.Behaviour
  def get(script) do
    case fetch(script) do
      {:ok, script} -> script
      _ -> nil
    end
  end

  @doc """
  Returns the count of the number of characters
  for a given script.

  ## Example

      iex> Unicode.Script.count("mongolian")
      168

  """
  @impl Unicode.Property.Behaviour
  def count(script) do
    with {:ok, script} <- fetch(script) do
      Enum.reduce(script, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the script name(s) for the
  given binary or codepoint.

  In the case of a codepoint, a single
  script name is returned.

  For a binary a list of distinct script
  names represented by the graphemes in
  the binary is returned.

  """
  def script(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&script/1)
    |> Enum.uniq()
  end

  for {script, ranges} <- @scripts do
    def script(codepoint) when unquote(Utils.ranges_to_guard_clause(ranges)) do
      unquote(script)
    end
  end

  def script(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    :unknown
  end
end
