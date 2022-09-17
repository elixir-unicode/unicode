defmodule Unicode.Utils do
  @moduledoc false

  @doc """
  Returns a map of the Unicode codepoints with the `script` name
  as the key and a list of codepoint ranges as the values.
  """
  @scripts_path Path.join(Unicode.data_dir(), "scripts.txt")
  @external_resource @scripts_path
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
  @external_resource @blocks_path
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
  @external_resource @combining_class_path
  def combining_classes do
    parse_file(@combining_class_path)
    |> Enum.map(fn {k, v} -> {String.to_integer(k), v} end)
    |> Map.new()
  end

  @doc """
  Returns a map of the Unicode codepoints with the `category` name
  as the key and a list of codepoint ranges as the values.
  """
  @categories_path Path.join(Unicode.data_dir(), "categories.txt")
  @external_resource @categories_path
  def categories do
    parse_file(@categories_path)
    |> atomize_keys()
  end

  @doc """
  Returns a map of the Unicode codepoints with the `derived property` name
  as the key and a list of codepoint ranges as the values.
  """
  @derived_properties_path Path.join(Unicode.data_dir(), "derived_properties.txt")
  @external_resource @derived_properties_path
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
  @external_resource @properties_path
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
  @external_resource @emoji_path
  def emoji do
    parse_file(@emoji_path)
    |> downcase_keys
    |> atomize_keys()
  end

  @doc """
  Returns a map of the Unicode codepoints with the emoji sequence name
  as the key and a list of codepoint ranges as the values.
  """
  @emoji_sequences_path Path.join(Unicode.data_dir(), "emoji_sequences.txt")
  @external_resource @emoji_sequences_path
  def emoji_sequences do
    parse_file(@emoji_sequences_path)
    |> downcase_keys
    |> atomize_keys()
  end

  @doc """
  Returns a map of the Unicode codepoints with the `grapheme_break` name
  as the key and a list of codepoint ranges as the values.
  """
  @grapheme_breaks_path Path.join(Unicode.data_dir(), "grapheme_break.txt")
  @external_resource @grapheme_breaks_path
  def grapheme_breaks do
    parse_file(@grapheme_breaks_path)
    |> downcase_keys()
    |> atomize_keys()
  end

  @doc """
  Returns a map of the Unicode codepoints with the `line_break` name
  as the key and a list of codepoint ranges as the values.
  """
  @line_breaks_path Path.join(Unicode.data_dir(), "line_break.txt")
  @external_resource @line_breaks_path
  def line_breaks do
    parse_file(@line_breaks_path)
    |> downcase_keys()
    |> atomize_keys()
  end

  @doc """
  Returns a map of the Unicode codepoints with the `word_break` name
  as the key and a list of codepoint ranges as the values.
  """
  @word_breaks_path Path.join(Unicode.data_dir(), "word_break.txt")
  @external_resource @word_breaks_path
  def word_breaks do
    parse_file(@word_breaks_path)
    |> downcase_keys()
    |> atomize_keys()
  end

  @doc """
  Returns a map of the Unicode codepoints from SpecialCasing.txt
  as the key and a list of codepoint ranges as the values.
  """
  @case_folding_path Path.join(Unicode.data_dir(), "case_folding.txt")
  @external_resource @case_folding_path
  def case_folding do
    parse_alias_file(@case_folding_path)
    |> Enum.map(fn
      [from, status, to, _] -> [encode(status), extract(from), extract(to)]
    end)
    |> Enum.sort_by(&hd/1)
    |> Enum.reverse
  end

  defp encode("c"), do: :common
  defp encode("t"), do: :turkic
  defp encode("f"), do: :full
  defp encode("s"), do: :simple

  @doc """
  Returns a map of the Unicode codepoints from SpecialCasing.txt
  as the key and a list of codepoint ranges as the values.
  """
  @special_casing_path Path.join(Unicode.data_dir(), "special_casing.txt")
  @external_resource @special_casing_path
  def special_casing do
    parse_alias_file(@special_casing_path)
    |> Enum.map(fn row ->
      Enum.map(row, &extract/1)
      |> Enum.reverse
      |> tl
      |> Enum.reverse
    end)
    |> Enum.group_by(&hd/1)
  end

  defp extract(string) do
    string
    |> String.split(" ")
    |> Enum.map(&to_integer/1)
    |> return_list_or_integer
  rescue ArgumentError ->
    string
  end

  def return_list_or_integer([integer]), do: integer
  def return_list_or_integer(list), do: list

  def to_integer(""), do: nil
  def to_integer(string), do: String.to_integer(string, 16)

  @doc """
  Returns a map of the Unicode codepoints with the `sentence_break` name
  as the key and a list of codepoint ranges as the values.
  """
  @sentence_breaks_path Path.join(Unicode.data_dir(), "sentence_break.txt")
  @external_resource @sentence_breaks_path
  def sentence_breaks do
    parse_file(@sentence_breaks_path)
    |> downcase_keys()
    |> atomize_keys()
  end

  @doc """
  Returns a map of the Unicode codepoints with the `east_asian_width` name
  as the key and a list of codepoint ranges as the values.
  """
  @east_asian_width_path Path.join(Unicode.data_dir(), "east_asian_width.txt")
  @external_resource @east_asian_width_path
  def east_asian_width do
    parse_file(@east_asian_width_path)
    |> downcase_keys()
    |> atomize_keys()
  end

  @doc """
  Returns a map of the Unicode codepoints with the `sentence_break` name
  as the key and a list of codepoint ranges as the values.
  """
  @indic_syllabic_category_path Path.join(Unicode.data_dir(), "indic_syllabic_category.txt")
  @external_resource @indic_syllabic_category_path
  def indic_syllabic_categories do
    parse_file(@indic_syllabic_category_path)
    |> downcase_keys()
    |> atomize_keys()
  end

  @doc """
  Returns a map of the property value aliases.
  """
  @property_alias_path Path.join(Unicode.data_dir(), "property_alias.txt")
  @external_resource @property_alias_path
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
  Returns a mapping of property names and
  aliases to the module that serves that
  property

  """
  def property_servers do
    property_alias()
    |> atomize_values
    |> add_canonical_alias()
    |> Enum.map(fn {k, v} ->
      {k, Module.concat(Unicode, Macro.camelize(Atom.to_string(v)))}
    end)
    |> Enum.filter(fn {_k, v} -> ensure_compiled?(v) end)
    |> Map.new()
  end

  @doc """
  Returns a map of the property value aliases.
  """
  @property_value_alias_path Path.join(Unicode.data_dir(), "property_value_alias.txt")
  @external_resource @property_value_alias_path
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
    |> Map.new
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
    |> Map.new()
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

  @doc """
  Takes a list of codepoints and collapses them into
  a list of tuple ranges

  """
  def list_to_ranges(list) do
    list
    |> Enum.sort
    |> Enum.reduce([], fn
      codepoint, [] ->
        [{codepoint, codepoint}]
      codepoint, [{start, finish} | rest] when codepoint == finish + 1 ->
        [{start, finish + 1} | rest]
      codepoint, acc ->
        [{codepoint, codepoint} | acc]
    end)
    |> Enum.reverse
  end

  @doc """
  Takes a list of tuple ranges and compacts
  adjacent ranges

  """
  def compact_ranges([]) do
    []
  end

  def compact_ranges([{first, last}, {next, final} | rest]) when next >= first  and final <= last do
    compact_ranges([{first, last} | rest])
  end

  def compact_ranges([{first, last}, {first, last} | rest]) do
    compact_ranges([{first, last} | rest])
  end

  def compact_ranges([{first, last}, {next, final} | rest])
      when next >= first and next <= last and final >= last do
    compact_ranges([{first, final} | rest])
  end

  def compact_ranges([{first, last}, {next, final} | rest]) when next == last + 1 do
    compact_ranges([{first, final} | rest])
  end

  def compact_ranges([entry | rest]) do
    [entry | compact_ranges(rest)]
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
  def maybe_atomize(key) do
    String.to_existing_atom(key)
  rescue _e in ArgumentError ->
    key
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

  defp ensure_compiled?(module) do
    case Code.ensure_compiled(module) do
      {:module, _} -> true
      {:error, _} -> false
    end
  end
end
