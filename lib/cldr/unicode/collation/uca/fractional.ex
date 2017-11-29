defmodule Cldr.Collations.Uca.Fractional do
  @fractional_uca_path "./data/FractionalUCA.txt"
  def parse do
    stream = File.stream!(@fractional_uca_path)
    Enum.reduce stream, %{line: 1, radicals: 0}, fn line, map ->
      parse_line(line, map) |> Map.put(:line, map[:line] + 1)
    end
  end

  defp parse_line("[UCA version = " <> _rest, map) do
    map
  end

  defp parse_line("#" <> _rest, map) do
    map
  end

  defp parse_line("[Unified_Ideograph" <> _rest, map) do
    map
  end

  defp parse_line("[radical " <> rest, map) do
    case String.split(rest, ":") do
      [_, codepoints] ->
        count =
          codepoints
          |> String.trim_trailing("]")
          |> String.codepoints
          |> Enum.count
        Map.put(map, :radicals, Map.get(map, :radicals) + count)
      [_] ->
        IO.puts "Number of radicals: #{inspect Map.get(map, :radicals)}"
        map
    end
  end

  defp parse_line("\n", map) do
    map
  end

  defp parse_line("[top_byte" <> _rest, map) do
    map
  end

  defp parse_line("[first" <> _rest, map) do
    map
  end

  defp parse_line("[last" <> _rest, map) do
    map
  end

  defp parse_line("[reorderingTokens" <> _rest, map) do
    map
  end

  defp parse_line("[categories" <> _rest, map) do
    map
  end

  defp parse_line("[fixed" <> _rest, map) do
    map
  end

  defp parse_line("[variable" <> _rest, map) do
    map
  end

  defp parse_line(line, map) do
    [codepoints, rest] = String.split(line, ";")

    codepoints
    |> String.split(" ")
    |> parse_line(rest, map)
  end

  # Single codepoint
  defp parse_line([string], rest, map) do
    codepoint = string_to_codepoint(string)
    collation_elements =
      rest
      |> trim_line
      |> extract_collation_elements(map)
    Map.put(map, codepoint, collation_elements)
  end

  defp parse_line(["FDD1", _b], _rest, map) do
    map
  end

  defp parse_line([_a, _b], _rest, map) do
    map
  end

  defp parse_line([_a, "|", _c], _rest, map) do
    map
  end

  defp parse_line([_a, _b, _c], _rest, map) do
    map
  end

  defp parse_line(other, rest, map) do
    IO.puts "Other: #{inspect other}; rest: #{rest}"
    map
  end

  defp trim_line(rest) do
    Regex.replace(~r/\w*#.*/, rest, "")
  end

  defp extract_collation_elements(string, map) do
    Regex.scan(~r/\[(.+?)\]+/, string, capture: :all_but_first)
    |> List.flatten
    |> Enum.map(&String.replace(&1, " ", ""))
    |> Enum.map(&String.split(&1, ","))
    |> Enum.map(&substitute_collation_elements(&1, map))
    |> Enum.map(&convert_to_integer/1)
  end

  defp substitute_collation_elements(["U+" <> _codepoint, _tertiary], map) do
    map
  end

  defp substitute_collation_elements(["U+" <> _codepoint, _secondary, _tertiary], map) do
    map
  end

  defp substitute_collation_elements(other, _map) do
    other
  end

  defp string_to_codepoint(string) when is_binary(string) do
    << String.to_integer(string, 16) :: utf8 >>
  end

  defp convert_to_integer(list) do
    Enum.map list, fn
      "" -> 0
      e -> String.to_integer(e, 16)
    end
  end
end
