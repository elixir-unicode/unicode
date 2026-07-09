defmodule Unicode.Age do
  @moduledoc """
  Functions to introspect the Unicode `Age` property for binaries (Strings) and codepoints.

  The `Age` property records the version of Unicode in which a codepoint was first assigned. The value is an atom formed from the version number, for example `:"1.1"` or `:"15.0"`.

  The primary API is `age/1` which returns the age of a codepoint, or the list of ages of a string. The functions `fetch/1`, `get/1` and `count/1` provide introspection of the codepoint ranges belonging to a given age.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @ages Utils.ages()
        |> Utils.remove_annotations()

  @age_table Unicode.RangeSearch.new_value_table(@ages)

  @doc """
  Returns the map of Unicode ages.

  ### Returns

  * A map where the age (as an atom version number) is the key and a list of codepoint ranges as 2-tuples is the value.

  ### Examples

      iex> Unicode.Age.ages() |> Map.get(:"1.1") |> hd()
      {0, 501}

  """
  def ages do
    @ages
  end

  @doc """
  Returns a list of known Unicode ages.

  ### Returns

  * A list of atom version numbers.

  ### Examples

      iex> :"1.1" in Unicode.Age.known_ages()
      true

  """
  @known_ages Map.keys(@ages)
  def known_ages do
    @known_ages
  end

  @doc """
  Returns a map of aliases for Unicode ages.

  The `Age` property has no value aliases, so this returns an empty map. It exists to satisfy the `Unicode.Property.Behaviour`.

  ### Returns

  * An empty map.

  ### Examples

      iex> Unicode.Age.aliases()
      %{}

  """
  @impl Unicode.Property.Behaviour
  def aliases do
    %{}
  end

  @doc """
  Returns the Unicode codepoint ranges for a given age.

  ### Arguments

  * `age` is any known age, as an atom or string.

  ### Returns

  * `{:ok, range_list}` where `range_list` is a list of codepoint ranges as 2-tuples.

  * `:error` if the age is not known.

  ### Examples

      iex> Unicode.Age.fetch(:"1.1") |> elem(0)
      :ok

      iex> Unicode.Age.fetch(:invalid)
      :error

  """
  @impl Unicode.Property.Behaviour
  def fetch(age) when is_atom(age) do
    Map.fetch(ages(), age)
  end

  def fetch(age) do
    Map.fetch(ages(), Utils.maybe_atomize(age))
  end

  @doc """
  Returns the Unicode codepoint ranges for a given age.

  ### Arguments

  * `age` is any known age, as an atom or string.

  ### Returns

  * A list of codepoint ranges as 2-tuples.

  * `nil` if the age is not known.

  ### Examples

      iex> Unicode.Age.get(:"1.1") |> hd()
      {0, 501}

      iex> Unicode.Age.get(:invalid)
      nil

  """
  @impl Unicode.Property.Behaviour
  def get(age) do
    case fetch(age) do
      {:ok, range_list} -> range_list
      _ -> nil
    end
  end

  @doc """
  Returns the count of the codepoints assigned in a given age.

  ### Arguments

  * `age` is any known age, as an atom or string.

  ### Returns

  * A non-negative integer count of the codepoints in the age.

  * `:error` if the age is not known.

  ### Examples

      iex> Unicode.Age.count(:"1.1")
      33979

  """
  @impl Unicode.Property.Behaviour
  def count(age) do
    with {:ok, range_list} <- fetch(age) do
      Enum.reduce(range_list, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the age of the given binary or codepoint.

  ### Arguments

  * `string_or_codepoint` is either a binary (String) or a codepoint in the range `0..0x10FFFF`.

  ### Returns

  * For a codepoint, a single age atom is returned. Unassigned codepoints return `:unassigned`.

  * For a binary, a list of the distinct ages of the codepoints in the binary is returned.

  ### Examples

      iex> Unicode.Age.age(?A)
      :"1.1"

      iex> Unicode.Age.age(0x0378)
      :unassigned

  """
  def age(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&age/1)
    |> Enum.uniq()
  end

  def age(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    Unicode.RangeSearch.find(@age_table, codepoint, :unassigned)
  end
end
