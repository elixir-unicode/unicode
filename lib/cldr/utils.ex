defmodule Cldr.Unicode.Utils do

  def bytes_to_codepoint(byte_list) when is_list(byte_list) do
    << (byte_list
        |> :binary.list_to_bin
        |> :binary.decode_unsigned)
    :: utf8 >>
  end

  def append_codepoint(binary, codepoint) when is_integer(codepoint) do
    << binary :: binary, codepoint :: utf8 >>
  end

  def codepoint_to_integer(chars) when is_binary(chars) do
    {grapheme, _rest} = String.next_grapheme(chars)
    <<codepoint :: utf8 >> = grapheme
    codepoint
  end

  def integer_to_codepoint(integer) do
    << codepoint :: utf8 >> = integer
    codepoint
  end

  @scripts_path Path.join(Cldr.Unicode.data_dir, "scripts.txt")
  def scripts do
    parse_file(@scripts_path)
  end

  @blocks_path Path.join(Cldr.Unicode.data_dir, "blocks.txt")
  def blocks do
    parse_file(@blocks_path)
  end

  @categories_path Path.join(Cldr.Unicode.data_dir, "categories.txt")
  def categories do
    parse_file(@categories_path)
    |> Enum.map(fn {k, v} -> {titlecase(k), v} end)
    |> Enum.into(%{})
  end

  @properties_path Path.join(Cldr.Unicode.data_dir, "properties.txt")
  def properties do
    parse_file(@properties_path)
  end

  def parse_file(path) do
    Enum.reduce(File.stream!(path), %{}, fn line, map ->
      case line do
        <<"#", _rest :: bitstring>> ->
          map
        <<"\n", _rest :: bitstring>> ->
          map
        range ->
          [range, script | _] = String.split(range, ~r/[;#]/) |> Enum.map(&String.trim/1)
          [start, finish] = extract_codepoint_range(range)
          range = case Map.get(map, script) do
            nil ->
              [{start, finish}]
            [{first, last}] ->
              if start == last + 1 do
                [{first, finish}]
              else
                [{start, finish}, {first, last}]
              end
            [{first, last} | rest] ->
              if start == last + 1 do
                [{first, finish} | rest]
              else
                [{start, finish}, {first, last} | rest]
              end
          end
          Map.put(map, script, range)
      end
    end)
    |> Enum.map(fn {key, ranges} ->
         {String.to_atom(String.downcase(key)), Enum.reverse(ranges)}
       end)
    |> Enum.into(%{})
  end

  defp extract_codepoint_range(range) do
    case String.split(range, "..") do
      [first, last] -> [String.to_integer(first, 16), String.to_integer(last,  16)]
      [first] ->       [String.to_integer(first, 16), String.to_integer(first,  16)]
    end
  end

  def ranges_to_guard_clause([{first, last}]) do
    quote do
      var!(codepoint) in unquote(first)..unquote(last)
    end
  end

  def ranges_to_guard_clause([{first, first} | rest]) do
    quote do
      var!(codepoint) == unquote(first) or unquote(ranges_to_guard_clause(rest))
    end
  end

  def ranges_to_guard_clause([{first, last} | rest]) do
    quote do
      var!(codepoint) in unquote(first)..unquote(last) or unquote(ranges_to_guard_clause(rest))
    end
  end

  defp titlecase(atom) do
    atom
    |> Atom.to_string
    |> String.capitalize
    |> String.to_atom
  end
end