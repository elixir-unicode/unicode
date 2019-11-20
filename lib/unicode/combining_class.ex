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

  @combining_class_alias Utils.property_value_alias()
  |> Map.get("ccc")
  |> Enum.flat_map(fn [code, alias1, alias2] ->
      [{String.downcase(alias1), String.to_integer(code)},
      {String.downcase(alias2), String.to_integer(code)},
      {String.downcase(code), String.to_integer(code)}]
  end)
  |> Map.new

  def aliases do
    @combining_class_alias
  end

  def fetch(combining_class) do
    combining_class = Map.get(aliases(), combining_class, combining_class)
    Map.fetch(combining_classes(), combining_class)
  end

  def get(combining_class) do
    case fetch(combining_class) do
      {:ok, combining_class} -> combining_class
      _ -> nil
    end
  end

  def count(class) do
    with {:ok, class} <- fetch(class) do
      Enum.reduce(class, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

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
