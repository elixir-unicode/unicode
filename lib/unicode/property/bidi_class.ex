defmodule Unicode.BidiClass do
  @moduledoc """
  Functions to introspect Unicode
  bidi classes for binaries
  (Strings) and codepoints.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @bidi_classes Utils.bidi_classes()
                |> Utils.remove_annotations()

  @doc """
  Returns the map of Unicode
  bidi classes.

  The bidi class name is the map
  key and a list of codepoint
  ranges as tuples as the value.

  """

  def bidi_classes do
    @bidi_classes
  end

  @doc """
  Returns a list of known Unicode
  bidi class names.

  This function does not return the
  names of any class aliases.

  """
  @known_bidi_classes Map.keys(@bidi_classes)
  def known_bidi_classes do
    @known_bidi_classes
  end

  @bidi_class_alias Utils.property_value_alias()
                    |> Map.get("bc")
                    |> Utils.atomize_values()
                    |> Utils.downcase_keys_and_remove_whitespace()
                    |> Utils.add_canonical_alias()

  @doc """
  Returns a map of aliases for
  Unicode bidi classes.

  An alias is an alternative name
  for referring to a bidi class. Aliases
  are resolved by the `fetch/1` and
  `get/1` functions.

  """
  @impl Unicode.Property.Behaviour
  def aliases do
    @bidi_class_alias
  end

  @doc """
  Returns the Unicode ranges for
  a given bidi class as a list of
  ranges as 2-tuples.

  Aliases are resolved by this function.

  Returns either `{:ok, range_list}` or
  `:error`.

  """
  @impl Unicode.Property.Behaviour
  def fetch(bidi_class) when is_atom(bidi_class) do
    Map.fetch(bidi_classes(), bidi_class)
  end

  def fetch(bidi_class) do
    bidi_class = Utils.downcase_and_remove_whitespace(bidi_class)
    bidi_class = Map.get(aliases(), bidi_class, bidi_class)
    Map.fetch(bidi_classes(), bidi_class)
  end

  @doc """
  Returns the Unicode ranges for
  a given bidi class as a list of
  ranges as 2-tuples.

  Aliases are resolved by this function.

  Returns either `range_list` or
  `nil`.

  """
  @impl Unicode.Property.Behaviour
  def get(bidi_class) do
    case fetch(bidi_class) do
      {:ok, bidi_class} -> bidi_class
      _ -> nil
    end
  end

  @doc """
  Returns the count of the number of characters
  for a given bidi class.

  ## Example

      iex> Unicode.BidiClass.count(:al)
      1478

  """
  @impl Unicode.Property.Behaviour
  def count(bidi_class) do
    with {:ok, bidi_class} <- fetch(bidi_class) do
      Enum.reduce(bidi_class, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the bidi class name(s) for the
  given binary or codepoint.

  In the case of a codepoint, a single
  bidi class name is returned.

  For a binary a list of distinct bidi class
  names represented by the codepoints in
  the binary is returned.

  ## Examples

      iex> Unicode.BidiClass.bidi_class ?A
      :l

      iex> Unicode.BidiClass.bidi_class ?0
      :en

      iex> Unicode.BidiClass.bidi_class 0x05D0
      :r

      iex> Unicode.BidiClass.bidi_class 0x0627
      :al

  """
  def bidi_class(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&bidi_class/1)
    |> Enum.uniq()
  end

  for {bidi_class, ranges} <- @bidi_classes do
    def bidi_class(codepoint) when unquote(Utils.ranges_to_guard_clause(ranges)) do
      unquote(bidi_class)
    end
  end

  def bidi_class(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    :l
  end
end
