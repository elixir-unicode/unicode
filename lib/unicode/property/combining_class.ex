defmodule Unicode.CanonicalCombiningClass do
  @moduledoc """
  Functions to introspect the Unicode canonical combining class property for binaries (Strings) and codepoints.

  The primary API is `combining_class/1` which returns the canonical combining class of a codepoint, or the list of canonical combining classes of a string.

  The functions `fetch/1`, `get/1` and `count/1` provide introspection of the codepoint ranges belonging to a combining class. `combining_classes/0`, `known_combining_classes/0` and `aliases/0` return the underlying combining class data.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @combining_classes Utils.combining_classes()
                     |> Utils.remove_annotations()

  @combining_class_table Unicode.RangeSearch.new_value_table(@combining_classes)

  @doc """
  Returns the map of Unicode canonical combining classes.

  ### Returns

  * A map where the combining class number is the key and a list of codepoint ranges as 2-tuples is the value.

  ### Examples

      iex> Unicode.CanonicalCombiningClass.combining_classes() |> Map.get(214)
      [{7630, 7630}]

  """
  def combining_classes do
    @combining_classes
  end

  @doc """
  Returns a list of known Unicode canonical combining class numbers.

  This function does not return the names of any class aliases.

  ### Returns

  * A list of integer combining class numbers.

  ### Examples

      iex> 230 in Unicode.CanonicalCombiningClass.known_combining_classes()
      true

  """
  @known_combining_classes Map.keys(@combining_classes)
  def known_combining_classes do
    @known_combining_classes
  end

  @combining_class_alias Utils.property_value_alias()
                         |> Map.get("ccc")
                         |> Enum.map(fn {k, v} -> {k, String.to_integer(v)} end)
                         |> Map.new()
                         |> Utils.downcase_keys_and_remove_whitespace()
                         |> Utils.add_canonical_alias()

  @doc """
  Returns a map of aliases for Unicode canonical combining classes.

  An alias is an alternative name for referring to a class. Aliases are resolved by the `fetch/1` and `get/1` functions.

  ### Returns

  * A map where the alias string is the key and the combining class number is the value.

  ### Examples

      iex> Unicode.CanonicalCombiningClass.aliases() |> Map.get("above")
      230

  """
  @impl Unicode.Property.Behaviour
  def aliases do
    @combining_class_alias
  end

  @doc """
  Returns the Unicode codepoint ranges for a given canonical combining class.

  Aliases are resolved by this function.

  ### Arguments

  * `combining_class` is any combining class number, or a class alias as a string.

  ### Returns

  * `{:ok, range_list}` where `range_list` is a list of codepoint ranges as 2-tuples.

  * `:error` if the combining class is not known.

  ### Examples

      iex> Unicode.CanonicalCombiningClass.fetch(214)
      {:ok, [{7630, 7630}]}

      iex> Unicode.CanonicalCombiningClass.fetch(999)
      :error

  """
  @impl Unicode.Property.Behaviour
  def fetch(combining_class) when is_integer(combining_class) do
    Map.fetch(combining_classes(), combining_class)
  end

  def fetch(combining_class) when is_binary(combining_class) do
    combining_class = Utils.downcase_and_remove_whitespace(combining_class)
    combining_class = Map.get(aliases(), combining_class, combining_class)
    Map.fetch(combining_classes(), combining_class)
  end

  @doc """
  Returns the Unicode codepoint ranges for a given canonical combining class.

  Aliases are resolved by this function.

  ### Arguments

  * `combining_class` is any combining class number, or a class alias as a string.

  ### Returns

  * A list of codepoint ranges as 2-tuples.

  * `nil` if the combining class is not known.

  ### Examples

      iex> Unicode.CanonicalCombiningClass.get(214)
      [{7630, 7630}]

      iex> Unicode.CanonicalCombiningClass.get(999)
      nil

  """
  @impl Unicode.Property.Behaviour
  def get(combining_class) do
    case fetch(combining_class) do
      {:ok, combining_class} -> combining_class
      _ -> nil
    end
  end

  @doc """
  Returns the count of characters in a given canonical combining class.

  Aliases are resolved by this function.

  ### Arguments

  * `class` is any combining class number, or a class alias as a string.

  ### Returns

  * A non-negative integer count of the codepoints in the combining class.

  * `:error` if the combining class is not known.

  ### Examples

      iex> Unicode.CanonicalCombiningClass.count(230)
      546

  """
  @impl Unicode.Property.Behaviour
  def count(class) do
    with {:ok, class} <- fetch(class) do
      Enum.reduce(class, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the canonical combining class(es) for the given binary or codepoint.

  ### Arguments

  * `string_or_codepoint` is either a binary (String) or a codepoint in the range `0..0x10FFFF`.

  ### Returns

  * For a codepoint, a single combining class number is returned.

  * For a binary, a list of the distinct combining class numbers of the codepoints in the binary is returned.

  ### Examples

      iex> Unicode.CanonicalCombiningClass.combining_class(0x0301)
      230

      iex> Unicode.CanonicalCombiningClass.combining_class("abc")
      [0]

  """
  def combining_class(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&combining_class/1)
    |> Enum.uniq()
  end

  def combining_class(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    Unicode.RangeSearch.find(@combining_class_table, codepoint, 0)
  end
end
