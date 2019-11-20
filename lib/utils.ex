defmodule Unicode.Utils do
  @moduledoc false

  @doc """
  Returns a map of the Unicode codepoints with the `script` name
  as the key and a list of codepoint ranges as the values.
  """
  @scripts_path Path.join(Unicode.data_dir(), "scripts.txt")
  def scripts do
    parse_file(@scripts_path)
  end

  @doc """
  Returns a map of the Unicode codepoints with the `block` name
  as the key and a list of codepoint ranges as the values.
  """
  @blocks_path Path.join(Unicode.data_dir(), "blocks.txt")
  def blocks do
    parse_file(@blocks_path)
    |> Enum.map(fn {k, v} ->
      new_key =
        k
        |> String.replace(" ", "_")
        |> String.replace("-", "_")
        |> String.to_atom()

      {new_key, v}
    end)
    |> Map.new()
  end

  @doc """
  Returns a map of the Unicode codepoints with the `combining_class` number
  as the key and a list of codepoint ranges as the values.
  """
  @combining_class_path Path.join(Unicode.data_dir(), "combining_class.txt")
  def combining_classes do
    parse_file(@combining_class_path)
    |> Enum.map(fn {k, v} -> {String.to_integer(k), v} end)
    |> Enum.into(%{})
  end

  @doc """
  Returns a map of the Unicode codepoints with the `category` name
  as the key and a list of codepoint ranges as the values.
  """
  @categories_path Path.join(Unicode.data_dir(), "categories.txt")
  def categories do
    parse_file(@categories_path)
    |> Enum.map(fn {k, v} -> {titlecase(k), v} end)
    |> atomize_keys
  end

  @test_path Path.join(Unicode.data_dir(), "test.txt")
  def test do
    parse_file(@test_path)
    |> Enum.map(fn {k, v} -> {titlecase(k), v} end)
    |> atomize_keys
  end

  @doc """
  Returns a map of the Unicode codepoints with the emoji type name
  as the key and a list of codepoint ranges as the values.
  """
  @emoji_path Path.join(Unicode.data_dir(), "emoji.txt")
  def emoji do
    parse_file(@emoji_path)
    |> Enum.map(fn {k, v} -> {String.downcase(k), v} end)
    |> atomize_keys
  end

  @doc """
  Returns a map of the property value aliases.
  """
  @property_value_alias_path Path.join(Unicode.data_dir(), "property_value_alias.txt")
  def property_value_alias do
    Enum.reduce(File.stream!(@property_value_alias_path), [], fn line, acc ->
      case line do
        <<"#", _rest::bitstring>> ->
          acc

        <<"\n", _rest::bitstring>> ->
          acc

      data ->
        [data
        |> String.replace(~r/ *#.*/, "")
        |> String.split(";")
        |> Enum.map(&String.trim/1) | acc]
      end
    end)
    |> Enum.group_by(&hd/1, &tl/1)
  end

  @doc """
  Returns a map of the Unicode codepoints with the `property` name
  as the key and a list of codepoint ranges as the values.
  """
  @properties_path Path.join(Unicode.data_dir(), "properties.txt")
  def properties do
    parse_file(@properties_path)
    |> atomize_keys
  end

  @doc false
  def parse_file(path) do
    Enum.reduce(File.stream!(path), %{}, fn line, map ->
      case line do
        <<"#", _rest::bitstring>> ->
          map

        <<"\n", _rest::bitstring>> ->
          map

        data ->
          [range, script | tail] =
            data
            |> String.split(~r/[;#]/)
            |> Enum.map(&String.trim/1)

          [start, finish] =
            range
            |> String.split("..")
            |> extract_codepoint_range

          range =
            case Map.get(map, script) do
              nil ->
                [{start, finish, tail}]

              [{first, last, text}] when is_integer(first) and is_integer(last) ->
                if start == last + 1 do
                  [{first, finish, tail ++ text}]
                else
                  [{start, finish, tail}, {first, last, text}]
                end

              [{first, last, text} | rest] when is_integer(first) and is_integer(last) ->
                if start == last + 1 do
                  [{first, finish, tail ++ text} | rest]
                else
                  [{start, finish, tail}, {first, last, text} | rest]
                end

              [{first, last, text} | rest] when is_list(first) and is_list(last) ->
                [{start, finish, tail}, {first, last, text} | rest]
            end

          Map.put(map, script, range)
      end
    end)
    |> Enum.map(fn {key, ranges} ->
      {String.downcase(key), Enum.reverse(ranges)}
    end)
    |> Enum.into(%{})
  end

  # Range
  defp extract_codepoint_range([first, last]) do
    [codepoint_from(first), codepoint_from(last)]
  end

  defp extract_codepoint_range([codepoint]) do
    cp = codepoint_from(codepoint)
    [cp, cp]
  end

  defp codepoint_from(codepoint) do
    case String.split(codepoint, " ") do
      [codepoint] ->
        String.to_integer(codepoint, 16)

      codepoints ->
        Enum.map(codepoints, &String.to_integer(&1, 16))
    end
  end

  @doc """
  For a given list of bytes (each in the range 0x00..0xff) return
  the equivalent codepoint.
  """
  def bytes_to_codepoint(byte_list) when is_list(byte_list) do
    <<byte_list
      |> :binary.list_to_bin()
      |> :binary.decode_unsigned()::utf8>>
  end

  @doc """
  Append a codepoint to a list of codepoints
  """
  def append_codepoint(binary, codepoint) when is_integer(codepoint) do
    <<binary::binary, codepoint::utf8>>
  end

  @doc """
  For a given character in binary format, return the
  integer codepoint.
  """
  def binary_to_codepoints(string) when is_binary(string) do
    String.to_charlist(string)
  end

  @doc """
  For a given character in binary format, return the
  integer codepoint.
  """
  def integer_to_codepoint(integer) when is_integer(integer) and integer >= 0 do
    <<codepoint::utf8>> = integer
    codepoint
  end

  @doc false
  def ranges_to_guard_clause([{first, first}]) do
    quote do
      var!(codepoint) == unquote(first)
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

  @doc false
  defp titlecase(string) do
    String.capitalize(string)
  end

  @doc false
  def atomize_keys(map) do
    Enum.map(map, fn {k, v} -> {String.to_atom(k), v} end)
    |> Enum.into(%{})
  end

  @doc false
  def remove_annotations(data) do
    data
    |> Enum.map(fn {k, v} ->
      {k, Enum.map(v, fn {s, f, _} -> {s, f} end)}
    end)
    |> Map.new()
  end

  @doc false
  @reserved "<reserved"
  def remove_reserved_codepoints(data) do
    data
    |> Enum.map(fn {k, v} ->
      filtered_list =
        Enum.reject(v, fn {_, _, notes} ->
          Enum.any?(notes, fn note ->
            String.contains?(note, @reserved)
          end)
        end)

      {k, filtered_list}
    end)
    |> Map.new()
  end

  @doc false
  def ranges_to_codepoints(ranges) when is_list(ranges) do
    Enum.reduce(ranges, [], fn
      {first, first}, acc ->
        [first | acc]

      {first, last}, acc ->
        Enum.map(last..first, & &1) ++ acc
    end)
  end
end
