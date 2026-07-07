defmodule Unicode.BidiClass do
  @moduledoc """
  Functions to introspect the Unicode bidirectional (bidi) class property for binaries (Strings) and codepoints.

  The primary API is `bidi_class/1` which returns the bidi class of a codepoint, or the list of bidi classes of a string.

  The functions `fetch/1`, `get/1` and `count/1` provide introspection of the codepoint ranges belonging to a bidi class. `bidi_classes/0`, `known_bidi_classes/0` and `aliases/0` return the underlying bidi class data.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @bidi_classes Utils.bidi_classes()
                |> Utils.remove_annotations()

  @bidi_class_table Unicode.RangeSearch.new_value_table(@bidi_classes)

  @doc """
  Returns the map of Unicode bidi classes.

  ### Returns

  * A map where the bidi class name is the key and a list of codepoint ranges as 2-tuples is the value.

  ### Examples

      iex> Unicode.BidiClass.bidi_classes() |> Map.get(:lre)
      [{8234, 8234}]

  """
  def bidi_classes do
    @bidi_classes
  end

  @doc """
  Returns a list of known Unicode bidi class names.

  This function does not return the names of any class aliases.

  ### Returns

  * A list of atom bidi class names.

  ### Examples

      iex> :l in Unicode.BidiClass.known_bidi_classes()
      true

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
  Returns a map of aliases for Unicode bidi classes.

  An alias is an alternative name for referring to a bidi class. Aliases are resolved by the `fetch/1` and `get/1` functions.

  ### Returns

  * A map where the alias string is the key and the bidi class name is the value.

  ### Examples

      iex> Unicode.BidiClass.aliases() |> Map.get("arabicletter")
      :al

  """
  @impl Unicode.Property.Behaviour
  def aliases do
    @bidi_class_alias
  end

  @doc """
  Returns the Unicode codepoint ranges for a given bidi class.

  Aliases are resolved by this function.

  ### Arguments

  * `bidi_class` is any bidi class name or alias, as an atom or string.

  ### Returns

  * `{:ok, range_list}` where `range_list` is a list of codepoint ranges as 2-tuples.

  * `:error` if the bidi class is not known.

  ### Examples

      iex> Unicode.BidiClass.fetch(:lre)
      {:ok, [{8234, 8234}]}

      iex> Unicode.BidiClass.fetch(:invalid)
      :error

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
  Returns the Unicode codepoint ranges for a given bidi class.

  Aliases are resolved by this function.

  ### Arguments

  * `bidi_class` is any bidi class name or alias, as an atom or string.

  ### Returns

  * A list of codepoint ranges as 2-tuples.

  * `nil` if the bidi class is not known.

  ### Examples

      iex> Unicode.BidiClass.get(:lre)
      [{8234, 8234}]

      iex> Unicode.BidiClass.get(:invalid)
      nil

  """
  @impl Unicode.Property.Behaviour
  def get(bidi_class) do
    case fetch(bidi_class) do
      {:ok, bidi_class} -> bidi_class
      _ -> nil
    end
  end

  @doc """
  Returns the count of characters in a given bidi class.

  Aliases are resolved by this function.

  ### Arguments

  * `bidi_class` is any bidi class name or alias, as an atom or string.

  ### Returns

  * A non-negative integer count of the codepoints in the bidi class.

  * `:error` if the bidi class is not known.

  ### Examples

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
  Returns the bidi class name(s) for the given binary or codepoint.

  ### Arguments

  * `string_or_codepoint` is either a binary (String) or a codepoint in the range `0..0x10FFFF`.

  ### Returns

  * For a codepoint, a single bidi class name is returned.

  * For a binary, a list of the distinct bidi class names of the codepoints in the binary is returned.

  ### Examples

      iex> Unicode.BidiClass.bidi_class(?A)
      :l

      iex> Unicode.BidiClass.bidi_class(0x05D0)
      :r

      iex> Unicode.BidiClass.bidi_class(0x0627)
      :al

      iex> Unicode.BidiClass.bidi_class("abc")
      [:l]

  """
  def bidi_class(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&bidi_class/1)
    |> Enum.uniq()
  end

  def bidi_class(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    Unicode.RangeSearch.find(@bidi_class_table, codepoint, :l)
  end
end
