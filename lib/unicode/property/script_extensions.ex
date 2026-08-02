defmodule Unicode.ScriptExtensions do
  @moduledoc """
  Functions to introspect the Unicode `Script_Extensions` property for binaries (Strings) and codepoints.

  The `Script_Extensions` property (`scx`) records the scripts a codepoint is commonly used with, which for shared characters is more than one (see [UAX #24](https://www.unicode.org/reports/tr24/)). U+0640 ARABIC TATWEEL, for example, has `Script` value `:common` but is used with Arabic, Syriac, Mandaic and others; its `Script_Extensions` value names each of them. Matching on `Script_Extensions` rather than `Script` is required for [UTS #18](https://www.unicode.org/reports/tr18/) RL1.2 conformance.

  The property is set-valued: each codepoint maps to a *set* of scripts. This module inverts that mapping so a codepoint appears under every script in its set, which is both the shape the other property modules use and the form queries actually take — `script_extensions(:latin)` answers "which codepoints have Latin in their set?".

  Two consequences of UAX #24 are worth knowing:

  * A codepoint absent from the `Script_Extensions` data takes its `Script` value, so this module returns a superset of `Unicode.Script` for most scripts rather than only the explicitly listed characters.

  * For a codepoint that *is* listed, the listed set replaces its `Script` value. U+00B7 MIDDLE DOT has `Script` value `:common`, but `:common` is not in its `Script_Extensions` set, so it is absent from `script_extensions(:common)`.

  The primary API is `script_extensions/1` which returns the scripts of a codepoint, or of a string.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @script_extensions Utils.script_extensions()

  @doc """
  Returns the map of Unicode script extensions.

  ### Returns

  * A map where the script name is the key and a list of codepoint ranges as 2-tuples is the value.

  ### Examples

      iex> Unicode.ScriptExtensions.script_extensions() |> Map.fetch!(:latin) |> is_list()
      true

  """
  def script_extensions do
    @script_extensions
  end

  @doc """
  Returns a list of known Unicode script names for the `Script_Extensions` property.

  ### Returns

  * A list of atom script names.

  ### Examples

      iex> :latin in Unicode.ScriptExtensions.known_script_extensions()
      true

  """
  @known_script_extensions Map.keys(@script_extensions)
  def known_script_extensions do
    @known_script_extensions
  end

  @doc """
  Returns a map of aliases for Unicode script extensions.

  The `Script_Extensions` property takes `Script` property values, so the `Script` aliases apply
  here unchanged — `"latn"` and `"latin"` both resolve to `:latin`.

  ### Returns

  * A map where the alias string is the key and the script name is the value.

  ### Examples

      iex> Unicode.ScriptExtensions.aliases() |> Map.get("latn")
      :latin

  """
  @script_extension_aliases Utils.value_aliases("sc", @known_script_extensions)
                            |> Utils.add_canonical_alias()

  @impl Unicode.Property.Behaviour
  def aliases do
    @script_extension_aliases
  end

  @doc """
  Returns the Unicode codepoint ranges for a given script extension.

  Aliases are resolved by this function.

  ### Arguments

  * `script` is any script name or alias, as an atom or string.

  ### Returns

  * `{:ok, range_list}` where `range_list` is a list of codepoint ranges as 2-tuples.

  * `:error` if the script is not known.

  ### Examples

      iex> Unicode.ScriptExtensions.fetch(:latin) |> elem(0)
      :ok

      iex> Unicode.ScriptExtensions.fetch(:invalid)
      :error

  """
  @impl Unicode.Property.Behaviour
  def fetch(script) when is_atom(script) do
    Map.fetch(script_extensions(), script)
  end

  def fetch(script) do
    script = Utils.downcase_and_remove_whitespace(script)
    script = Map.get(aliases(), script, script) |> Utils.maybe_atomize()

    Map.fetch(script_extensions(), script)
  end

  @doc """
  Returns the Unicode codepoint ranges for a given script extension.

  Aliases are resolved by this function.

  ### Arguments

  * `script` is any script name or alias, as an atom or string.

  ### Returns

  * A list of codepoint ranges as 2-tuples.

  * `nil` if the script is not known.

  ### Examples

      iex> Unicode.ScriptExtensions.get("latn") |> is_list()
      true

      iex> Unicode.ScriptExtensions.get(:invalid)
      nil

  """
  @impl Unicode.Property.Behaviour
  def get(script) do
    case fetch(script) do
      {:ok, range_list} -> range_list
      _ -> nil
    end
  end

  @doc """
  Returns the count of the codepoints having a given script in their `Script_Extensions` set.

  Aliases are resolved by this function.

  ### Arguments

  * `script` is any script name or alias, as an atom or string.

  ### Returns

  * A non-negative integer count of the codepoints with the script extension.

  * `:error` if the script is not known.

  ### Examples

      iex> Unicode.ScriptExtensions.count(:latin)
      1720

      iex> Unicode.ScriptExtensions.count(:bopomofo)
      122

  """
  @impl Unicode.Property.Behaviour
  def count(script) do
    with {:ok, range_list} <- fetch(script) do
      Enum.reduce(range_list, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  # Keyed by the whole script *set* rather than by individual script. Those ranges are disjoint —
  # each codepoint has exactly one set — so a single binary search returns the complete answer,
  # where the inverted `@script_extensions` map would need one lookup per script.
  @script_extension_table Unicode.RangeSearch.new_value_table(Utils.script_extension_sets())

  @doc """
  Returns the `Script_Extensions` set of the given binary or codepoint.

  ### Arguments

  * `string_or_codepoint` is either a binary (String) or a codepoint in the range `0..0x10FFFF`.

  ### Returns

  * For a codepoint, the list of script name atoms in its `Script_Extensions` set, sorted. An
    unassigned codepoint returns `[:unknown]`.

  * For a binary, the sorted union of the sets of the codepoints in the binary.

  ### Examples

      iex> Unicode.ScriptExtensions.script_extensions(?A)
      [:latin]

      iex> Unicode.ScriptExtensions.script_extensions(0x02C7)
      [:bopomofo, :latin]

      iex> Unicode.ScriptExtensions.script_extensions("Aά")
      [:greek, :latin]

  """
  def script_extensions(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.flat_map(&script_extensions/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def script_extensions(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    Unicode.RangeSearch.find(@script_extension_table, codepoint, [:unknown])
  end
end
