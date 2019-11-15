defmodule Unicode.CombiningClass do
  @moduledoc false

  alias Unicode.Utils

  @combining_classes Utils.combining_classes()
                     |> Utils.remove_annotations()

  def combining_classes do
    @combining_classes
  end

  @known_combining_classes Map.keys(@combining_classes)
  def known_combining_classes do
    @known_combining_classes
  end

  def count(class) when is_integer(class) and class in @known_combining_classes do
    combining_classes()
    |> Map.get(class)
    |> Enum.reduce(0, fn {from, to}, acc -> acc + to - from + 1 end)
  end

  def count(class) when is_integer(class) do
    0
  end

  def combining_class(string) when is_binary(string) do
    string
    |> String.codepoints()
    |> Enum.flat_map(&Utils.binary_to_codepoints/1)
    |> Enum.map(&combining_class/1)
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
