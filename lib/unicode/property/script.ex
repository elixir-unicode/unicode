defmodule Unicode.Script do
  @moduledoc """
  Functions to introspect the Unicode script property for binaries (Strings) and codepoints.

  The primary API is `script/1` which returns the script of a codepoint, or the list of scripts of a string.

  The functions `fetch/1`, `get/1` and `count/1` provide introspection of the codepoint ranges belonging to a script. `scripts/0`, `known_scripts/0` and `aliases/0` return the underlying script data.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @scripts Utils.scripts()
           |> Utils.remove_annotations()

  @script_table Unicode.RangeSearch.new_value_table(@scripts)

  @doc """
  Returns the map of Unicode scripts.

  ### Returns

  * A map where the script name is the key and a list of codepoint ranges as 2-tuples is the value.

  ### Examples

      iex> Unicode.Script.scripts() |> Map.get(:ogham)
      [{5760, 5788}]

  """
  def scripts do
    @scripts
  end

  @doc """
  Returns a list of known Unicode script names.

  This function does not return the names of any script aliases.

  ### Returns

  * A list of atom script names.

  ### Examples

      iex> :latin in Unicode.Script.known_scripts()
      true

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
  Returns a map of aliases for Unicode scripts.

  An alias is an alternative name for referring to a script. Aliases are resolved by the `fetch/1` and `get/1` functions.

  ### Returns

  * A map where the alias string is the key and the script name is the value.

  ### Examples

      iex> Unicode.Script.aliases() |> Map.get("ogam")
      :ogham

  """
  @impl Unicode.Property.Behaviour
  def aliases do
    @script_alias
  end

  @doc """
  Returns the Unicode codepoint ranges for a given script.

  Aliases are resolved by this function.

  ### Arguments

  * `script` is any script name or alias, as an atom or string.

  ### Returns

  * `{:ok, range_list}` where `range_list` is a list of codepoint ranges as 2-tuples.

  * `:error` if the script is not known.

  ### Examples

      iex> Unicode.Script.fetch(:ogham)
      {:ok, [{5760, 5788}]}

      iex> Unicode.Script.fetch(:invalid)
      :error

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
  Returns the Unicode codepoint ranges for a given script.

  Aliases are resolved by this function.

  ### Arguments

  * `script` is any script name or alias, as an atom or string.

  ### Returns

  * A list of codepoint ranges as 2-tuples.

  * `nil` if the script is not known.

  ### Examples

      iex> Unicode.Script.get(:ogham)
      [{5760, 5788}]

      iex> Unicode.Script.get(:invalid)
      nil

  """
  @impl Unicode.Property.Behaviour
  def get(script) do
    case fetch(script) do
      {:ok, script} -> script
      _ -> nil
    end
  end

  @doc """
  Returns the count of characters in a given script.

  Aliases are resolved by this function.

  ### Arguments

  * `script` is any script name or alias, as an atom or string.

  ### Returns

  * A non-negative integer count of the codepoints in the script.

  * `:error` if the script is not known.

  ### Examples

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
  Returns the script name(s) for the given binary or codepoint.

  ### Arguments

  * `string_or_codepoint` is either a binary (String) or a codepoint in the range `0..0x10FFFF`.

  ### Returns

  * For a codepoint, a single script name is returned.

  * For a binary, a list of the distinct script names of the codepoints in the binary is returned.

  ### Examples

      iex> Unicode.Script.script(?A)
      :latin

      iex> Unicode.Script.script("abc")
      [:latin]

  """
  def script(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&script/1)
    |> Enum.uniq()
  end

  def script(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    Unicode.RangeSearch.find(@script_table, codepoint, :unknown)
  end
end
