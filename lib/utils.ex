defmodule Unicode.Utils do
  @moduledoc false

  @doc """
  Returns a map of the Unicode codepoints with the `script` name
  as the key and a list of codepoint ranges as the values.

  """
  @unicode_data_path Path.join(Unicode.data_dir(), "unicode_data.txt")
  @external_resource @unicode_data_path
  def unicode do
    parse_unicode_data(@unicode_data_path)
  end

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
      [from, status, to, _] -> [encode(status), String.to_integer(from, 16), extract(to)]
    end)
    |> Enum.sort_by(&hd/1)
    |> Enum.reverse()
  end

  defp encode("c"), do: :common
  defp encode("t"), do: :turkic
  defp encode("f"), do: :full
  defp encode("s"), do: :simple

  @doc """
  Returns a list of maps containing the default casing data
  (upper, lower and title) for codepoints that
  have multiple cases.

  Additional casing data is returned by `Unicode.Utils.special_casing/0`.

  """
  def default_casing do
    unicode()
    |> Enum.map(fn {codepoint, parsed} ->
      {codepoint, Enum.drop(parsed, 11) |> Enum.map(&String.trim/1)}
    end)
    |> Enum.reject(fn {_codepoint, [upper, lower, title]} ->
      Enum.all?([upper, lower, title], &(&1 == ""))
    end)
    |> Enum.reduce(%{}, fn {codepoint, [upper, lower, title]}, acc ->
      codepoint = codepoint_from(codepoint)
      context = nil

      Map.put(acc, codepoint, %{
        {:any, context} => %{
          upper: extract(upper),
          lower: extract(lower),
          title: extract(title),
          type: :default
        }
      })
    end)
  end

  @doc """
  Returns a list of the Unicode codepoints from SpecialCasing.txt
  and the special casing rules that should be applied based upon
  language and surrounding context.

  """
  @special_casing_path Path.join(Unicode.data_dir(), "special_casing.txt")
  @external_resource @special_casing_path
  def special_casing do
    parse_alias_file(@special_casing_path)
    |> Enum.reduce(Map.new(), fn
      [codepoint, lower, title, upper, context, ""], acc ->
        [language, context] = parse(context)
        codepoint = codepoint_from(codepoint)

        casing = %{
          upper: extract(upper),
          title: extract(title),
          lower: extract(lower),
          type: :special
        }

        update_casing(acc, codepoint, {language, context}, casing)

      [codepoint, lower, title, upper, ""], acc ->
        codepoint = codepoint_from(codepoint)
        context = nil

        casing = %{
          upper: extract(upper),
          title: extract(title),
          lower: extract(lower),
          type: :special
        }

        update_casing(acc, codepoint, {:any, context}, casing)
    end)
  end

  defp update_casing(acc, codepoint, language_context, casing) do
    {_, acc} =
      Map.get_and_update(acc, codepoint, fn
        nil -> {nil, %{language_context => casing}}
        existing -> {existing, Map.put(existing, language_context, casing)}
      end)

    acc
  end

  defp extract(string) do
    string
    |> String.split(" ")
    |> Enum.map(&to_integer/1)
    |> return_list_or_nil
  end

  defp return_list_or_nil([nil]), do: nil
  defp return_list_or_nil(other), do: other

  defp to_integer(""), do: nil
  defp to_integer(string), do: String.to_integer(string, 16)

  @doc false
  def parse(rule) do
    rule
    |> String.split(" ")
    |> case do
      [language, context] -> [String.to_atom(language), context]
      [<<_::utf8, _::utf8>> = language] -> [String.to_atom(language), nil]
      [rule] -> [:any, rule]
    end
  end

  @doc """
  Returns the merged data from default casing and
  special casing.

  """
  def casing do
    special_casing_map = special_casing()

    # Merge special casing into default casing
    first_phase_merge =
      Enum.map(default_casing(), fn {codepoint, default_casing} ->
        special_casing = Map.get(special_casing_map, codepoint, %{})
        merged_casing = Map.merge(default_casing, special_casing)
        {codepoint, merged_casing}
      end)
      |> Map.new

    # Merge special casing that does not already exist in
    # default casing
    Enum.reduce(special_casing_map, first_phase_merge, fn {codepoint, casing}, acc ->
      case Map.get(acc, codepoint) do
        nil -> Map.put(acc, codepoint, casing)
        _other -> acc
      end
    end)
  end

  @doc """
  Present casing in an order that is appropriate
  for generating functions to process casing.

  """
  def casing_in_order do
    casing()
    |> Enum.sort()
    |> Enum.map(fn {codepoint, casing} ->
      casing
      |> Enum.sort(&casing_sorter/2)
      |> Enum.map(fn {{language, context}, casing} ->
        casing
        |> Map.put(:language, language)
        |> Map.put(:context, context)
        |> Map.put(:codepoint, codepoint)
      end)
    end)
    |> List.flatten()
  end

  # :any language is the last rule.
  def casing_sorter({{:any, nil}, _}, _b), do: false
  def casing_sorter(_a, {{:any, nil}, _}), do: true

  # A language with a context comes before language with no context
  def casing_sorter({{language, nil}, _}, {{language, _context}, _}), do: false
  def casing_sorter({{language, _context}, _}, {{language, nil}, _}), do: true

  # A language with a context comes before language with no context
  def casing_sorter({{language_1, _}, _}, {{language_2, _context}, _}), do: language_1 < language_2

  @doc """
  Returns the list of locales that are referenced in
  SpecialCasing.txt.

  """
  def known_casing_locales do
    special_casing()
    |> Enum.flat_map(fn {_codepoint, mappings} -> Map.keys(mappings) end)
    |> Enum.map(&elem(&1, 0))
    |> Enum.uniq()
    |> List.delete(:any)
  end

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

  @indic_conjunct_break_server %{
    "incb" => Unicode.IndicConjunctBreak,
    "indicconjunctbreak" => Unicode.IndicConjunctBreak
  }
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
    |> Map.merge(@indic_conjunct_break_server)
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
  def parse_unicode_data(path) do
    Enum.reduce(File.stream!(path), %{}, fn line, map ->
      case line do
        <<"#", _rest::bitstring>> ->
          map

        <<"\n", _rest::bitstring>> ->
          map

        data ->
          [codepoint | rest] = String.split(data, ";")
          Map.put(map, codepoint, rest)
      end
    end)
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
    |> Map.new()
  end

  # Range
  defp extract_codepoint_range([first, last]) do
    [codepoint_from(first), codepoint_from(last)]
  end

  defp extract_codepoint_range([codepoint]) do
    cp = codepoint_from(codepoint)
    [cp, cp]
  end

  defp codepoint_from("") do
    nil
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
    |> Enum.sort()
    |> Enum.reduce([], fn
      codepoint, [] ->
        [{codepoint, codepoint}]

      codepoint, [{start, finish} | rest] when codepoint == finish + 1 ->
        [{start, finish + 1} | rest]

      codepoint, acc ->
        [{codepoint, codepoint} | acc]
    end)
    |> Enum.reverse()
  end

  @doc """
  Takes a list of tuple ranges and compacts
  adjacent ranges

  """
  def compact_ranges([]) do
    []
  end

  def compact_ranges([{first, last}, {next, final} | rest])
      when next >= first and final <= last do
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
  rescue
    _e in ArgumentError ->
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
