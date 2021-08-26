defmodule Unicode.CanonicalCombiningClass do
  @moduledoc """
  Functions to introspect Unicode
  canonical combining classes for binaries
  (Strings) and codepoints.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @combining_classes Utils.combining_classes()
                     |> Utils.remove_annotations()

  @doc """
  Returns the map of Unicode
  canonical combining classes..

  The class name is the map
  key and a list of codepoint
  ranges as tuples as the value.

  """

  def combining_classes do
    @combining_classes
  end

  @doc """
  Returns a list of known Unicode
  canonical combining class names.

  This function does not return the
  names of any class aliases.

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
  Returns a map of aliases for
  Unicode canonical combining classes..

  An alias is an alternative name
  for referring to a class. Aliases
  are resolved by the `fetch/1` and
  `get/1` functions.

  """
  @impl Unicode.Property.Behaviour
  def aliases do
    @combining_class_alias
  end

  @doc """
  Returns the Unicode ranges for
  a given canonical combining class
   as a list of ranges as 2-tuples.

  Aliases are resolved by this function.

  Returns either `{:ok, range_list}` or
  `:error`.

  """
  @impl Unicode.Property.Behaviour
  def fetch(combining_class) when is_atom(combining_class) do
    Map.fetch(combining_classes(), combining_class)
  end

  def fetch(combining_class) when is_binary(combining_class) do
    combining_class = Utils.downcase_and_remove_whitespace(combining_class)
    combining_class = Map.get(aliases(), combining_class, combining_class)
    Map.fetch(combining_classes(), combining_class)
  end

  def fetch(combining_class) when is_integer(combining_class) do
    Map.fetch(combining_classes(), combining_class)
  end

  @doc """
  Returns the Unicode ranges for
  a given canonical combining class
   as a list of ranges as 2-tuples.

  Aliases are resolved by this function.

  Returns either `range_list` or
  `nil`.

  """
  @impl Unicode.Property.Behaviour
  def get(combining_class) do
    case fetch(combining_class) do
      {:ok, combining_class} -> combining_class
      _ -> nil
    end
  end

  @doc """
  Returns the count of the number of characters
  for a given canonical combining class.

  ## Example

      iex> Unicode.CanonicalCombiningClass.count(230)
      508

  """
  @impl Unicode.Property.Behaviour
  def count(class) do
    with {:ok, class} <- fetch(class) do
      Enum.reduce(class, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the canonical combining class
   name(s) for the given binary or codepoint.

  In the case of a codepoint, a single
  class name is returned.

  For a binary a list of distinct class
  names represented by the graphemes in
  the binary is returned.

  """
  def combining_class(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&combining_class/1)
    |> Enum.uniq()
  end

  for {combining_class, ranges} <- @combining_classes do
    def combining_class(codepoint) when unquote(Utils.ranges_to_guard_clause(ranges)) do
      unquote(combining_class)
    end
  end

  def combining_class(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    0
  end
end
