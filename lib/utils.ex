defmodule Unicode.Utils do
  @moduledoc false

  @doc """
  Returns a map of the Unicode codepoints with the `script` name
  as the key and a list of codepoint ranges as the values.
  """
  @scripts_path Path.join(Unicode.data_dir(), "scripts.txt")
  def scripts do
    parse_file(@scripts_path)
    |> downcase_keys()
    |> atomize_keys()
  end

  @doc """
  Returns a map of the Unicode codepoints with the `block` name
  as the key and a list of codepoint ranges as the values.
  """
  @blocks_path Path.join(Unicode.data_dir(), "blocks.txt")
  def blocks do
    parse_file(@blocks_path)
    |> downcase_keys
    |> atomize_keys()
  end

  @doc """
  Returns a map of the Unicode codepoints with the `combining_class` number
  as the key and a list of codepoint ranges as the values.
  """
  @combining_class_path Path.join(Unicode.data_dir(), "combining_class.txt")
  def combining_classes do
    parse_file(@combining_class_path)
    |> Enum.map(fn {k, v} -> {String.to_integer(k), v} end)
    |> Map.new
  end

  @doc """
  Returns a map of the Unicode codepoints with the `category` name
  as the key and a list of codepoint ranges as the values.
  """
  @categories_path Path.join(Unicode.data_dir(), "categories.txt")
  def categories do
    parse_file(@categories_path)
    |> atomize_keys()
  end

  @doc """
  Returns a map of the Unicode codepoints with the `derived property` name
  as the key and a list of codepoint ranges as the values.
  """
  @derived_properties_path Path.join(Unicode.data_dir(), "derived_properties.txt")
  def derived_properties do
    parse_file(@derived_properties_path)
    |> downcase_keys
    |> atomize_keys()
  end

  @doc """
  Returns a map of the Unicode codepoints with the `property` name
  as the key and a list of codepoint ranges as the values.
  """
  @properties_path Path.join(Unicode.data_dir(), "properties.txt")
  def properties do
    parse_file(@properties_path)
    |> downcase_keys()
    |> atomize_keys()
  end

  @doc """
  Returns a map of the Unicode codepoints with the emoji type name
  as the key and a list of codepoint ranges as the values.
  """
  @emoji_path Path.join(Unicode.data_dir(), "emoji.txt")
  def emoji do
    parse_file(@emoji_path)
    |> downcase_keys
    |> atomize_keys()
  end

  @doc """
  Returns a map of the property value aliases.
  """
  @property_alias_path Path.join(Unicode.data_dir(), "property_alias.txt")
  def property_alias do
    parse_alias_file(@property_alias_path)
    |> Enum.flat_map(fn
      [alias1, code] ->
        [{alias1, code}]

      [alias1, code, alias2] ->
        [{alias1, code}, {alias2, code}]

      [alias1, code, alias2, alias3] ->
        [{alias1, code}, {alias2, code}, {alias3, code}]

      [_alias1, _code, _alias2, _alias3, _alias4] ->
        []
    end)
    |> Map.new()
  end

  @doc """
  Returns a map of the property value aliases.
  """
  @property_value_alias_path Path.join(Unicode.data_dir(), "property_value_alias.txt")
  def property_value_alias do
    parse_alias_file(@property_value_alias_path)
    |> Enum.group_by(&hd/1, &tl/1)
    |> Enum.map(fn {category, aliases} -> {category, map_from_aliases(aliases)} end)
    |> Map.new()
  end

  defp map_from_aliases(aliases) do
    Enum.flat_map(aliases, fn
      [code, alias1] ->
        [{alias1, code}]

      [code, alias1, alias2] ->
        [{alias1, code}, {alias2, code}]

      [code, alias1, alias2, alias3] ->
        [{alias1, code}, {alias2, code}, {alias3, code}]
    end)
    |> Map.new()
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
      {key, Enum.reverse(ranges)}
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

  @doc false
  def parse_alias_file(path) do
    Enum.reduce(File.stream!(path), [], fn line, acc ->
      case line do
        <<"#", _rest::bitstring>> ->
          acc

        <<"\n", _rest::bitstring>> ->
          acc

        data ->
          [
            data
            |> String.replace(~r/ *#.*/, "")
            |> String.split(";")
            |> Enum.map(fn n -> String.trim(n) |> String.downcase() end)
            | acc
          ]
      end
    end)
  end

  # Take the atom values of the map
  # and add a string version as an alias
  def add_canonical_alias(map) do
    map
    |> Enum.map(fn {_k, v} -> {downcase_and_remove_whitespace(v), v} end)
    |> Map.new
    |> Map.merge(map)
  end

  def downcase_keys_and_remove_whitespace(map) when is_map(map) do
    Enum.map(map, fn {k, v} -> {downcase_and_remove_whitespace(k), v} end)
    |> Map.new()
  end

  @match [" ", "-", "_"]
  def downcase_and_remove_whitespace(string) when is_binary(string) do
    string
    |> String.trim()
    |> String.downcase()
    |> String.replace(@match, "")
  end

  def downcase_and_remove_whitespace(atom) when is_atom(atom) do
    atom
    |> Atom.to_string()
    |> downcase_and_remove_whitespace()
  end

  def downcase_and_remove_whitespace(integer) when is_integer(integer) do
    integer
    |> Integer.to_string()
  end

  def conform_key(string) do
    string
    |> String.replace(" ", "_")
    |> String.replace("-", "_")
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
  def capitalize_keys(map) do
    Enum.map(map, fn {k, v} -> {String.capitalize(k), v} end)
    |> Map.new()
  end

  @doc false
  def downcase_keys(map) do
    Enum.map(map, fn {k, v} -> {String.downcase(k), v} end)
    |> Map.new()
  end

  @doc false
  def atomize_keys(map) do
    Enum.map(map, fn {k, v} -> {String.to_atom(conform_key(k)), v} end)
    |> Map.new()
  end

  @doc false
  def capitalize_values(map) do
    Enum.map(map, fn {k, v} -> {k, String.capitalize(v)} end)
    |> Map.new()
  end

  def atomize_values(map) do
    Enum.map(map, fn {k, v} -> {k, String.to_atom(conform_key(v))} end)
    |> Map.new()
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

  @doc false
  def invert_map(map) do
    Enum.map(map, fn {k, v} -> {v, k} end)
    |> Map.new()
  end
end
