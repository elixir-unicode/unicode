defmodule Unicode.VerticalOrientation do
  @moduledoc """
  Functions to introspect the Unicode `Vertical_Orientation` property for binaries (Strings) and codepoints.

  The `Vertical_Orientation` property describes how a codepoint is oriented when laid out in vertical text (see [UAX #50](https://www.unicode.org/reports/tr50/)). The values are `:u` (Upright), `:r` (Rotated), `:tu` (Transformed_Upright) and `:tr` (Transformed_Rotated). Codepoints without an explicit assignment default to `:r`.

  The primary API is `vertical_orientation/1` which returns the orientation of a codepoint, or the list of orientations of a string.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @vertical_orientations Utils.vertical_orientations()
                         |> Utils.remove_annotations()

  @vertical_orientation_table Unicode.RangeSearch.new_value_table(@vertical_orientations)

  @doc """
  Returns the map of Unicode vertical orientations.

  ### Returns

  * A map where the vertical orientation is the key and a list of codepoint ranges as 2-tuples is the value.

  ### Examples

      iex> :u in Map.keys(Unicode.VerticalOrientation.vertical_orientations())
      true

  """
  def vertical_orientations do
    @vertical_orientations
  end

  @doc """
  Returns a list of known Unicode vertical orientation names.

  ### Returns

  * A list of atom vertical orientation names.

  ### Examples

      iex> :tu in Unicode.VerticalOrientation.known_vertical_orientations()
      true

  """
  @known_vertical_orientations Map.keys(@vertical_orientations)
  def known_vertical_orientations do
    @known_vertical_orientations
  end

  @doc """
  Returns a map of aliases for Unicode vertical orientations.

  ### Returns

  * A map where the alias string is the key and the vertical orientation is the value.

  ### Examples

      iex> Unicode.VerticalOrientation.aliases() |> Map.get("upright")
      :u

  """
  @vertical_orientation_aliases Utils.value_aliases("vo", @known_vertical_orientations)
                                |> Utils.add_canonical_alias()

  @impl Unicode.Property.Behaviour
  def aliases do
    @vertical_orientation_aliases
  end

  @doc """
  Returns the Unicode codepoint ranges for a given vertical orientation.

  Aliases are resolved by this function.

  ### Arguments

  * `vertical_orientation` is any orientation name or alias, as an atom or string.

  ### Returns

  * `{:ok, range_list}` where `range_list` is a list of codepoint ranges as 2-tuples.

  * `:error` if the vertical orientation is not known.

  ### Examples

      iex> Unicode.VerticalOrientation.fetch(:u) |> elem(0)
      :ok

      iex> Unicode.VerticalOrientation.fetch(:invalid)
      :error

  """
  @impl Unicode.Property.Behaviour
  def fetch(vertical_orientation) when is_atom(vertical_orientation) do
    Map.fetch(vertical_orientations(), vertical_orientation)
  end

  def fetch(vertical_orientation) do
    vertical_orientation = Utils.downcase_and_remove_whitespace(vertical_orientation)

    vertical_orientation =
      Map.get(aliases(), vertical_orientation, vertical_orientation) |> Utils.maybe_atomize()

    Map.fetch(vertical_orientations(), vertical_orientation)
  end

  @doc """
  Returns the Unicode codepoint ranges for a given vertical orientation.

  Aliases are resolved by this function.

  ### Arguments

  * `vertical_orientation` is any orientation name or alias, as an atom or string.

  ### Returns

  * A list of codepoint ranges as 2-tuples.

  * `nil` if the vertical orientation is not known.

  ### Examples

      iex> Unicode.VerticalOrientation.get(:invalid)
      nil

  """
  @impl Unicode.Property.Behaviour
  def get(vertical_orientation) do
    case fetch(vertical_orientation) do
      {:ok, range_list} -> range_list
      _ -> nil
    end
  end

  @doc """
  Returns the count of the codepoints with a given vertical orientation.

  Aliases are resolved by this function.

  ### Arguments

  * `vertical_orientation` is any orientation name or alias, as an atom or string.

  ### Returns

  * A non-negative integer count of the codepoints with the vertical orientation.

  * `:error` if the vertical orientation is not known.

  ### Examples

      iex> is_integer(Unicode.VerticalOrientation.count(:u))
      true

  """
  @impl Unicode.Property.Behaviour
  def count(vertical_orientation) do
    with {:ok, range_list} <- fetch(vertical_orientation) do
      Enum.reduce(range_list, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the vertical orientation of the given binary or codepoint.

  ### Arguments

  * `string_or_codepoint` is either a binary (String) or a codepoint in the range `0..0x10FFFF`.

  ### Returns

  * For a codepoint, a single orientation atom is returned. Codepoints without an explicit assignment return `:r`.

  * For a binary, a list of the distinct orientations of the codepoints in the binary is returned.

  ### Examples

      iex> Unicode.VerticalOrientation.vertical_orientation(?A)
      :r

      iex> Unicode.VerticalOrientation.vertical_orientation(0x3042)
      :u

  """
  def vertical_orientation(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&vertical_orientation/1)
    |> Enum.uniq()
  end

  def vertical_orientation(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    Unicode.RangeSearch.find(@vertical_orientation_table, codepoint, :r)
  end
end
