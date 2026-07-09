defmodule Unicode.JoiningGroup do
  @moduledoc """
  Functions to introspect the Unicode `Joining_Group` property for binaries (Strings) and codepoints.

  The `Joining_Group` property groups Arabic and Syriac letters that share the same shaping behaviour, for example `:beh`, `:alaph` or `:teh_marbuta`. Codepoints that are not cursively joined have the value `:no_joining_group`.

  The primary API is `joining_group/1` which returns the joining group of a codepoint, or the list of joining groups of a string. This complements `Unicode.JoiningType`.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @joining_groups Utils.joining_groups()

  @joining_group_table Unicode.RangeSearch.new_value_table(@joining_groups)

  @doc """
  Returns the map of Unicode joining groups.

  ### Returns

  * A map where the joining group is the key and a list of codepoint ranges as 2-tuples is the value.

  ### Examples

      iex> :beh in Map.keys(Unicode.JoiningGroup.joining_groups())
      true

  """
  def joining_groups do
    @joining_groups
  end

  @doc """
  Returns a list of known Unicode joining group names.

  ### Returns

  * A list of atom joining group names.

  ### Examples

      iex> :alaph in Unicode.JoiningGroup.known_joining_groups()
      true

  """
  @known_joining_groups Map.keys(@joining_groups)
  def known_joining_groups do
    @known_joining_groups
  end

  @doc """
  Returns a map of aliases for Unicode joining groups.

  ### Returns

  * A map where the alias string is the key and the joining group is the value.

  ### Examples

      iex> Unicode.JoiningGroup.aliases() |> Map.get("beh")
      :beh

  """
  @joining_group_aliases Utils.value_aliases("jg", @known_joining_groups)
                         |> Utils.add_canonical_alias()

  @impl Unicode.Property.Behaviour
  def aliases do
    @joining_group_aliases
  end

  @doc """
  Returns the Unicode codepoint ranges for a given joining group.

  Aliases are resolved by this function.

  ### Arguments

  * `joining_group` is any joining group name or alias, as an atom or string.

  ### Returns

  * `{:ok, range_list}` where `range_list` is a list of codepoint ranges as 2-tuples.

  * `:error` if the joining group is not known.

  ### Examples

      iex> Unicode.JoiningGroup.fetch(:beh) |> elem(0)
      :ok

      iex> Unicode.JoiningGroup.fetch(:invalid)
      :error

  """
  @impl Unicode.Property.Behaviour
  def fetch(joining_group) when is_atom(joining_group) do
    Map.fetch(joining_groups(), joining_group)
  end

  def fetch(joining_group) do
    joining_group = Utils.downcase_and_remove_whitespace(joining_group)
    joining_group = Map.get(aliases(), joining_group, joining_group) |> Utils.maybe_atomize()
    Map.fetch(joining_groups(), joining_group)
  end

  @doc """
  Returns the Unicode codepoint ranges for a given joining group.

  Aliases are resolved by this function.

  ### Arguments

  * `joining_group` is any joining group name or alias, as an atom or string.

  ### Returns

  * A list of codepoint ranges as 2-tuples.

  * `nil` if the joining group is not known.

  ### Examples

      iex> Unicode.JoiningGroup.get(:invalid)
      nil

  """
  @impl Unicode.Property.Behaviour
  def get(joining_group) do
    case fetch(joining_group) do
      {:ok, range_list} -> range_list
      _ -> nil
    end
  end

  @doc """
  Returns the count of the codepoints in a given joining group.

  Aliases are resolved by this function.

  ### Arguments

  * `joining_group` is any joining group name or alias, as an atom or string.

  ### Returns

  * A non-negative integer count of the codepoints in the joining group.

  * `:error` if the joining group is not known.

  ### Examples

      iex> is_integer(Unicode.JoiningGroup.count(:beh))
      true

  """
  @impl Unicode.Property.Behaviour
  def count(joining_group) do
    with {:ok, range_list} <- fetch(joining_group) do
      Enum.reduce(range_list, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the joining group of the given binary or codepoint.

  ### Arguments

  * `string_or_codepoint` is either a binary (String) or a codepoint in the range `0..0x10FFFF`.

  ### Returns

  * For a codepoint, a single joining group atom is returned. Codepoints that are not cursively joined return `:no_joining_group`.

  * For a binary, a list of the distinct joining groups of the codepoints in the binary is returned.

  ### Examples

      iex> Unicode.JoiningGroup.joining_group(0x0628)
      :beh

      iex> Unicode.JoiningGroup.joining_group(?A)
      :no_joining_group

  """
  def joining_group(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&joining_group/1)
    |> Enum.uniq()
  end

  def joining_group(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    Unicode.RangeSearch.find(@joining_group_table, codepoint, :no_joining_group)
  end
end
