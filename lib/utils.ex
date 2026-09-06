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
  Returns a map of the Unicode codepoints with the `script` name as the key and a list of codepoint
  ranges as the values, for the `Script_Extensions` property.

  `Script_Extensions` is set-valued: each codepoint maps to a *set* of scripts, not one. That shape
  does not fit the `%{value => ranges}` form the property modules use, so the mapping is inverted
  here — a codepoint appears under every script in its set. That is also the form the queries
  actually asked take (`\\p{scx=Latin}` means "is Latin in this codepoint's scx set?").

  Two details of UAX #24 are easy to get wrong and are handled here:

  * Codepoints absent from `ScriptExtensions.txt` take their `Script` value as their
    `Script_Extensions` value. The file lists only the exceptions, so the great majority of
    codepoints get their value from `scripts/0`.

  * For a codepoint that *is* listed, the listed set replaces its `Script` value rather than adding
    to it. U+00B7 MIDDLE DOT has `sc=Common` but `Common` is not in its `scx` set, so it must be
    removed from the `:common` entry. Hence the range subtraction rather than a plain merge.

  """
  @script_extensions_path Path.join(Unicode.data_dir(), "script_extensions.txt")
  @external_resource @script_extensions_path
  def script_extensions do
    script_extension_sets()
    |> Enum.flat_map(fn {scripts, ranges} -> Enum.map(scripts, &{&1, ranges}) end)
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Map.new(fn {script, ranges} -> {script, ranges |> Enum.concat() |> merge_ranges()} end)
  end

  @doc """
  Returns a map of the `Script_Extensions` property keyed by the *set* of scripts, with a list of
  codepoint ranges as the values.

  This is the form the file itself takes, and unlike `script_extensions/0` its ranges are disjoint —
  each codepoint has exactly one `Script_Extensions` set. That makes it directly usable as a
  `Unicode.RangeSearch` value table, where one lookup returns the whole set.

  """
  def script_extension_sets do
    explicit = explicit_script_extension_sets()
    listed = explicit |> Map.values() |> Enum.concat() |> merge_ranges()

    scripts()
    |> remove_annotations()
    |> Enum.map(fn {script, ranges} -> {[script], subtract_ranges(ranges, listed)} end)
    |> Enum.reject(fn {_scripts, ranges} -> ranges == [] end)
    |> Map.new()
    |> Map.merge(explicit, fn _scripts, default, explicit ->
      merge_ranges(default ++ explicit)
    end)
  end

  # `%{"Bopo Latn" => ranges}` from the file becomes `%{[:bopomofo, :latin] => ranges}`. Grouped
  # rather than mapped because two different orderings of the same set are distinct keys in the
  # file but the same key here.
  defp explicit_script_extension_sets do
    code_to_name = script_code_to_name()

    @script_extensions_path
    |> parse_file()
    |> Enum.map(fn {codes, ranges} ->
      scripts =
        codes
        |> String.split(" ", trim: true)
        |> Enum.map(&script_from_code(&1, code_to_name))
        |> Enum.sort()

      {scripts, Enum.map(ranges, fn {start, finish, _tail} -> {start, finish} end)}
    end)
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Map.new(fn {scripts, ranges} -> {scripts, ranges |> Enum.concat() |> merge_ranges()} end)
  end

  # `ScriptExtensions.txt` uses short script codes (`Latn`), not the full names (`Latin`) that key
  # the script map, so codes are expanded through the `sc` value aliases.
  #
  # `value_aliases/2` rather than inverting the alias map: the alias map is many-to-one, so
  # inverting it silently drops entries and can elect a non-canonical name. `Copt`, for instance,
  # shares a line with both `Coptic` and the ISO 15924 alias `Qaac`, and inversion picked `:qaac`.
  defp script_code_to_name do
    "sc"
    |> value_aliases(Map.keys(scripts()))
    |> add_canonical_alias()
  end

  defp script_from_code(code, code_to_name) do
    normalized = downcase_and_remove_whitespace(code)
    Map.get(code_to_name, normalized, maybe_atomize(normalized))
  end

  # Sorts and coalesces a range list, joining ranges that touch or overlap.
  defp merge_ranges(ranges) do
    ranges
    |> Enum.sort()
    |> Enum.reduce([], fn
      {start, finish}, [{previous_start, previous_finish} | rest]
      when start <= previous_finish + 1 ->
        [{previous_start, max(previous_finish, finish)} | rest]

      range, acc ->
        [range | acc]
    end)
    |> Enum.reverse()
  end

  defp subtract_ranges(ranges, subtrahend) do
    Enum.flat_map(ranges, fn range ->
      Enum.reduce(subtrahend, [range], fn {sub_start, sub_finish}, remaining ->
        Enum.flat_map(remaining, &subtract_range(&1, sub_start, sub_finish))
      end)
    end)
  end

  defp subtract_range({start, finish}, sub_start, sub_finish)
       when sub_finish < start or sub_start > finish do
    [{start, finish}]
  end

  defp subtract_range({start, finish}, sub_start, sub_finish) do
    left = if start < sub_start, do: [{start, sub_start - 1}], else: []
    right = if finish > sub_finish, do: [{sub_finish + 1, finish}], else: []
    left ++ right
  end

  @doc """
  Returns a map of the `Link_Term` property with the value name as the key and a list of codepoint
  ranges as the values.

  `Link_Term` drives the link termination algorithm of
  [UTS #58](https://www.unicode.org/reports/tr58/). Codepoints absent from the file take the
  default value `:hard`, which is most of them — the file lists only the characters that can appear
  inside a link or bracket it.

  """
  @link_term_path Path.join(Unicode.data_dir(), "link_term.txt")
  @external_resource @link_term_path
  def link_terms do
    parse_file(@link_term_path)
    |> downcase_keys()
    |> atomize_keys()
  end

  @doc """
  Returns the codepoint ranges of the `Link_Email` property.

  `Link_Email` is a binary property listing the characters valid in the local part of an email
  address, per [UTS #58](https://www.unicode.org/reports/tr58/). The file carries no value field —
  a codepoint is either listed or it is not — so this returns a plain range list rather than the
  `%{value => ranges}` map the enumerated properties use.

  """
  @link_email_path Path.join(Unicode.data_dir(), "link_email.txt")
  @external_resource @link_email_path
  def link_emails do
    @link_email_path
    |> File.stream!()
    |> Enum.flat_map(fn
      <<"#", _rest::bitstring>> -> []
      <<"\n", _rest::bitstring>> -> []
      line -> [codepoint_range(line)]
    end)
    |> merge_ranges()
  end

  @doc """
  Returns the `Link_Bracket` property as a map of closing codepoint to opening codepoint.

  Unlike the other link properties this is a codepoint-valued mapping rather than a set of ranges,
  so it does not fit `Unicode.Property.Behaviour`. It is used by the
  [UTS #58](https://www.unicode.org/reports/tr58/) termination algorithm to decide whether a
  closing bracket matches the innermost open one.

  """
  @link_bracket_path Path.join(Unicode.data_dir(), "link_bracket.txt")
  @external_resource @link_bracket_path
  def link_brackets do
    @link_bracket_path
    |> File.stream!()
    |> Enum.flat_map(fn
      <<"#", _rest::bitstring>> -> []
      <<"\n", _rest::bitstring>> -> []
      line -> [bracket_pair(line)]
    end)
    |> Map.new()
  end

  defp bracket_pair(line) do
    [close, open] =
      line
      |> String.split("#")
      |> hd()
      |> String.split(";")
      |> Enum.map(&(String.trim(&1) |> String.to_integer(16)))

    {close, open}
  end

  # The first field of a line, as an inclusive `{first, last}` tuple. A single codepoint gives a
  # range of one.
  defp codepoint_range(line) do
    case line |> String.split("#") |> hd() |> String.trim() |> String.split("..") do
      [single] -> {String.to_integer(single, 16), String.to_integer(single, 16)}
      [first, last] -> {String.to_integer(first, 16), String.to_integer(last, 16)}
    end
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
  Returns a map of the Unicode codepoints with the `bidi_class` name
  as the key and a list of codepoint ranges as the values.

  """
  @bidi_class_path Path.join(Unicode.data_dir(), "bidi_class.txt")
  @external_resource @bidi_class_path
  def bidi_classes do
    parse_file(@bidi_class_path)
    |> downcase_keys()
    |> atomize_keys()
  end

  @doc """
  Returns a map of the Unicode codepoints with the `joining_type` name
  as the key and a list of codepoint ranges as the values.

  """
  @joining_type_path Path.join(Unicode.data_dir(), "joining_type.txt")
  @external_resource @joining_type_path
  def joining_types do
    parse_file(@joining_type_path)
    |> downcase_keys()
    |> atomize_keys()
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
      |> Map.new()

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
  def casing_sorter({{language_1, _}, _}, {{language_2, _context}, _}),
    do: language_1 < language_2

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
  Returns a map of the Unicode codepoints with the `indic_positional_category`
  name as the key and a list of codepoint ranges as the values.
  """
  @indic_positional_category_path Path.join(Unicode.data_dir(), "indic_positional_category.txt")
  @external_resource @indic_positional_category_path
  def indic_positional_categories do
    parse_file(@indic_positional_category_path)
    |> downcase_keys()
    |> atomize_keys()
  end

  @doc """
  Returns a map of the Unicode codepoints with the `age` (the version in which
  the codepoint was first assigned) as the key and a list of codepoint ranges as
  the values.
  """
  @derived_age_path Path.join(Unicode.data_dir(), "derived_age.txt")
  @external_resource @derived_age_path
  def ages do
    parse_file(@derived_age_path)
    |> atomize_keys()
  end

  @doc """
  Returns a map of the Unicode codepoints with the `numeric_type` name as the
  key and a list of codepoint ranges as the values.
  """
  @numeric_type_path Path.join(Unicode.data_dir(), "numeric_type.txt")
  @external_resource @numeric_type_path
  def numeric_types do
    parse_file(@numeric_type_path)
    |> downcase_keys()
    |> atomize_keys()
  end

  @doc """
  Returns a map of the Unicode codepoints with the `decomposition_type` name as
  the key and a list of codepoint ranges as the values.
  """
  @decomposition_type_path Path.join(Unicode.data_dir(), "decomposition_type.txt")
  @external_resource @decomposition_type_path
  def decomposition_types do
    parse_file(@decomposition_type_path)
    |> downcase_keys()
    |> atomize_keys()
  end

  @doc """
  Returns a map of the Unicode codepoints with the `hangul_syllable_type` name
  as the key and a list of codepoint ranges as the values.
  """
  @hangul_syllable_type_path Path.join(Unicode.data_dir(), "hangul_syllable_type.txt")
  @external_resource @hangul_syllable_type_path
  def hangul_syllable_types do
    parse_file(@hangul_syllable_type_path)
    |> downcase_keys()
    |> atomize_keys()
  end

  @doc """
  Returns a map of the Unicode codepoints with the `vertical_orientation` name
  as the key and a list of codepoint ranges as the values.
  """
  @vertical_orientation_path Path.join(Unicode.data_dir(), "vertical_orientation.txt")
  @external_resource @vertical_orientation_path
  def vertical_orientations do
    parse_file(@vertical_orientation_path)
    |> downcase_keys()
    |> atomize_keys()
  end

  @doc """
  Returns a map of the Unicode codepoints with the `joining_group` name as the
  key and a list of codepoint ranges as the values.

  The data is derived from `ArabicShaping.txt`, taking the fourth (joining group)
  field of each entry.
  """
  @arabic_shaping_path Path.join(Unicode.data_dir(), "arabic_shaping.txt")
  @external_resource @arabic_shaping_path
  def joining_groups do
    @arabic_shaping_path
    |> File.stream!()
    |> Enum.reduce(%{}, fn line, map ->
      case String.trim(line) do
        "#" <> _rest ->
          map

        "" ->
          map

        data ->
          [codepoint, _name, _joining_type, joining_group] =
            data |> String.split(";") |> Enum.map(&String.trim/1)

          codepoint = String.to_integer(codepoint, 16)
          group = joining_group |> String.downcase() |> String.to_atom()
          Map.update(map, group, [{codepoint, codepoint}], &[{codepoint, codepoint} | &1])
      end
    end)
    |> Enum.map(fn {group, ranges} -> {group, ranges |> Enum.reverse() |> compact_ranges()} end)
    |> Map.new()
  end

  @doc """
  Returns a map of the Unicode codepoints with the `numeric_value` as the key and
  a list of codepoint ranges as the values.

  The value is an integer for whole numbers or a `{numerator, denominator}` tuple
  for fractions. The data is derived from the fourth (exact value) field of
  `DerivedNumericValues.txt`.
  """
  @numeric_values_path Path.join(Unicode.data_dir(), "numeric_values.txt")
  @external_resource @numeric_values_path
  def numeric_values do
    @numeric_values_path
    |> File.stream!()
    |> Enum.reduce(%{}, fn line, map ->
      case String.trim(line) do
        "#" <> _rest ->
          map

        "" ->
          map

        data ->
          [range, _representation, _blank, value] =
            data
            |> String.replace(~r/ *#.*/, "")
            |> String.split(";")
            |> Enum.map(&String.trim/1)

          [first, last] = extract_codepoint_range(String.split(range, ".."))
          value = parse_numeric_value(value)
          Map.update(map, value, [{first, last}], &[{first, last} | &1])
      end
    end)
    |> Enum.map(fn {value, ranges} -> {value, ranges |> Enum.reverse() |> compact_ranges()} end)
    |> Map.new()
  end

  defp parse_numeric_value(value) do
    case String.split(value, "/") do
      [numerator, denominator] ->
        {String.to_integer(numerator), String.to_integer(denominator)}

      [integer] ->
        String.to_integer(integer)
    end
  end

  @doc """
  Returns a map of the Unicode codepoints with the `bidi_paired_bracket_type`
  name (`:open` or `:close`) as the key and a list of codepoint ranges as the
  values.

  The data is derived from `BidiBrackets.txt`.
  """
  @bidi_brackets_path Path.join(Unicode.data_dir(), "bidi_brackets.txt")
  @external_resource @bidi_brackets_path
  def bidi_paired_bracket_types do
    @bidi_brackets_path
    |> File.stream!()
    |> Enum.flat_map(&parse_bidi_bracket_line/1)
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Map.new(fn {type, ranges} -> {type, compact_ranges(Enum.sort(ranges))} end)
  end

  defp parse_bidi_bracket_line(line) do
    case strip_comment(line) do
      "" ->
        []

      data ->
        [codepoint, _paired, type] = data |> String.split(";") |> Enum.map(&String.trim/1)
        codepoint = String.to_integer(codepoint, 16)
        [{bracket_type(type), {codepoint, codepoint}}]
    end
  end

  defp bracket_type("o"), do: :open
  defp bracket_type("c"), do: :close

  @doc """
  Returns a map of the four normalization `Quick_Check` properties.

  The result is keyed by property name (`:nfc_qc`, `:nfd_qc`, `:nfkc_qc` and
  `:nfkd_qc`); each value is a map from the quick check value (`:no` or `:maybe`)
  to a list of codepoint ranges. Codepoints not listed have the default value
  `:yes`. The data is derived from `DerivedNormalizationProps.txt`.
  """
  @normalization_props_path Path.join(Unicode.data_dir(), "normalization_props.txt")
  @external_resource @normalization_props_path
  def quick_check_properties do
    @normalization_props_path
    |> File.stream!()
    |> Enum.flat_map(&parse_quick_check_line/1)
    |> Enum.group_by(fn {property, _value, _range} -> property end, fn {_property, value, range} ->
      {value, range}
    end)
    |> Map.new(fn {property, pairs} -> {property, group_quick_check_ranges(pairs)} end)
  end

  defp parse_quick_check_line(line) do
    with data when data != "" <- strip_comment(line),
         [range, property, value] <- data |> String.split(";") |> Enum.map(&String.trim/1),
         true <- String.ends_with?(property, "_QC") do
      property = property |> String.downcase() |> String.to_atom()
      [first, last] = extract_codepoint_range(String.split(range, ".."))
      [{property, quick_check_value(value), {first, last}}]
    else
      _other -> []
    end
  end

  defp quick_check_value("M"), do: :maybe
  defp quick_check_value(_no), do: :no

  defp group_quick_check_ranges(pairs) do
    pairs
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Map.new(fn {value, ranges} -> {value, compact_ranges(Enum.sort(ranges))} end)
  end

  @doc """
  Returns a map with the single key `:bidi_mirrored` and a list of codepoint
  ranges as its value.

  A codepoint is `Bidi_Mirrored` when the tenth field of its `UnicodeData.txt`
  entry is `Y`. The shape matches the boolean property maps so it can be merged
  into `Unicode.Property`.
  """
  def bidi_mirrored do
    ranges =
      @unicode_data_path
      |> parse_unicode_data()
      |> Enum.flat_map(fn {codepoint, fields} ->
        if Enum.at(fields, 8) == "Y" do
          point = String.to_integer(codepoint, 16)
          [{point, point}]
        else
          []
        end
      end)
      |> Enum.sort()
      |> compact_ranges()

    %{bidi_mirrored: ranges}
  end

  defp strip_comment(line) do
    case String.trim(line) do
      "#" <> _rest -> ""
      trimmed -> trimmed |> String.replace(~r/ *#.*/, "") |> String.trim()
    end
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

  # `Link_Term` is defined by UTS #58 rather than the UCD, so it is absent from `PropertyAliases`
  # and has to be wired explicitly. Only this one of the three link properties is served here:
  # `Link_Email` is binary and `Link_Bracket` maps codepoints to codepoints, so neither has the
  # `fetch(value)` semantics that `Unicode.fetch_property/1` callers rely on.
  @link_term_server %{
    "linkterm" => Unicode.LinkTerm,
    "link_term" => Unicode.LinkTerm
  }

  # The `Name` property is served by `Unicode.CharacterName`, whose module name
  # does not follow the `Unicode.<CamelCasedProperty>` convention, so it is wired
  # explicitly rather than derived from the property alias.
  @character_name_server %{
    "name" => Unicode.CharacterName,
    "na" => Unicode.CharacterName
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
      # Normalize the alias key the same way `Unicode.fetch_property/1` normalizes
      # its lookup, so aliases containing underscores (for example `nfc_qc`) are
      # reachable and not just their whitespace-stripped canonical form.
      {downcase_and_remove_whitespace(k),
       Module.concat(Unicode, Macro.camelize(Atom.to_string(v)))}
    end)
    # A property with no backing `Unicode.<CamelCasedProperty>` module is dropped by
    # `ensure_compiled?/1` below and cannot be resolved via `Unicode.fetch_property/1`. Every UCD
    # enumerated property now has one — `Script_Extensions` was the last gap and is served by
    # `Unicode.ScriptExtensions` — so adding a module is all that a future property requires.
    # `test/property_modules_test.exs` asserts the set is complete, so a new enumerated property
    # in a future Unicode release fails a test rather than going unnoticed.
    |> Enum.filter(fn {_k, v} -> ensure_compiled?(v) end)
    |> Map.new()
    |> Map.merge(@indic_conjunct_break_server)
    |> Map.merge(@link_term_server)
    |> Map.merge(@character_name_server)
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

  # Number of names per front-coded block. Every `@name_block_size`-th name is
  # stored in full (a "restart point") and is what the binary search compares
  # against; the rest are prefix-compressed relative to the previous name.
  @name_block_size 16

  @doc """
  Returns the number of character names per front-coded block.

  Exposed so that `Unicode.CharacterName` can walk the blob without duplicating the constant.

  """
  def name_block_size, do: @name_block_size

  @doc """
  Returns the front-coded character-name table as `{blob, restarts, codepoint_index, count}`.

  Each name is stored **once**, in normalized form, and both lookup directions use it. Storing the
  original name as well would double the largest structure in this library; instead the original is
  reconstructed. That is possible because UAX #44 restricts the `Name` property to the characters
  `A-Z`, `0-9`, space and hyphen — there is no lower case anywhere in the data — so upper-casing the
  normalized name and reinserting the separators recovers it exactly. Recording where the separators
  go costs about 3 bytes per name, against roughly 26 for a second copy.

  Keeping the searchable form normalized also means `to_codepoint/1` compares whole binaries, as it
  always has. Storing original names instead and normalizing candidates during the search was
  measured at roughly four times slower.

  Entries are sorted by normalized name, then by codepoint, and written into `blob` using
  block-based front coding: names are grouped into blocks of #{@name_block_size}, the first name of
  each block is stored in full, and every following name is stored as the length of the prefix it
  shares with the previous name plus the remaining suffix. `blob` records are:

    * restart (first in a block): `<<name_length, name, codepoint::24, separators>>`
    * other: `<<shared_prefix_length, suffix_length, suffix, codepoint::24, separators>>`

  where `separators` is `<<count, entries::binary-size(count)>>` and each entry is
  `<<position::7, hyphen?::1>>`, giving the index in the *original* name at which a space or hyphen
  appears. Front coding roughly halves the names because sorted Unicode names share long prefixes
  (`LATIN SMALL LETTER ...`).

  The remaining elements are:

    * `restarts` — a `<<blob_offset::32>>` entry per block, so a by-name lookup can binary-search
      the restart names and then scan-decode within a single block.

    * `codepoint_index` — a `<<codepoint::24, block::16, index_in_block::8>>` entry per name, sorted
      by codepoint, so a by-codepoint lookup can binary-search it and decode forward from that
      block's restart.

    * `count` — the number of names.

  Entries whose name field is a bracketed label (`<control>`, `<CJK Ideograph, First>` and similar
  algorithmically-named ranges) are omitted, since those are not usable character names. The
  algorithmic ranges are handled by `character_name_ranges/0` and `jamo_short_names/0` instead.

  Names are **not** de-duplicated. Six pairs differ only by a hyphen that normalization removes
  (`TIBETAN LETTER -A` and `TIBETAN LETTER A`, for example), and dropping either would leave its
  codepoint with no name in the reverse direction. A by-name lookup of a colliding name resolves to
  the lower codepoint.

  """
  def character_name_table do
    entries =
      @unicode_data_path
      |> parse_unicode_data()
      |> Enum.flat_map(fn
        {_codepoint, ["<" <> _label | _rest]} ->
          []

        {codepoint, [name | _rest]} ->
          [
            {downcase_and_remove_whitespace(name), String.to_integer(codepoint, 16),
             separators(name)}
          ]
      end)
      |> Enum.sort()

    {blob_iodata, restart_iodata, index_iodata, _previous, _offset, count} =
      Enum.reduce(entries, {[], [], [], "", 0, 0}, fn
        {name, codepoint, separators}, {blob, restarts, index, _previous, offset, position}
        when rem(position, @name_block_size) == 0 ->
          record = <<byte_size(name)::8, name::binary, codepoint::24, separators::binary>>

          {[blob, record], [restarts, <<offset::32>>], [index, index_entry(codepoint, position)],
           name, offset + byte_size(record), position + 1}

        {name, codepoint, separators}, {blob, restarts, index, previous, offset, position} ->
          shared = common_prefix_length(previous, name)
          suffix = binary_part(name, shared, byte_size(name) - shared)

          record =
            <<shared::8, byte_size(suffix)::8, suffix::binary, codepoint::24, separators::binary>>

          {[blob, record], restarts, [index, index_entry(codepoint, position)], name,
           offset + byte_size(record), position + 1}
      end)

    codepoint_index = index_iodata |> IO.iodata_to_binary() |> sort_codepoint_index()

    {IO.iodata_to_binary(blob_iodata), IO.iodata_to_binary(restart_iodata), codepoint_index,
     count}
  end

  # Where the separators sit in the original name. Position is an index into that name, which
  # UAX #44 caps well below the 127 a 7 bit field allows.
  defp separators(name) do
    positions =
      name
      |> String.to_charlist()
      |> Enum.with_index()
      |> Enum.filter(fn {character, _index} -> character in ~c" -_" end)
      |> Enum.map(fn
        {?-, index} -> <<index::7, 1::1>>
        {_space, index} -> <<index::7, 0::1>>
      end)

    IO.iodata_to_binary([<<length(positions)::8>>, positions])
  end

  @doc """
  Rebuilds an original character name from its normalized form and separator descriptor.

  The inverse of the encoding described in `character_name_table/0`. Since the `Name` property has
  no lower case anywhere, upper-casing the normalized name and reinserting the separators at the
  recorded positions recovers the original exactly.

  """
  def restore_character_name(normalized, separators) do
    restore_character_name(String.upcase(normalized), separators, 0, [])
  end

  defp restore_character_name(name, <<>>, _index, acc) do
    IO.iodata_to_binary([acc, name])
  end

  defp restore_character_name(name, <<position::7, hyphen?::1, rest::binary>>, index, acc) do
    take = position - index
    <<preceding::binary-size(^take), remaining::binary>> = name
    separator = if hyphen? == 1, do: "-", else: " "

    restore_character_name(remaining, rest, position + 1, [acc, preceding, separator])
  end

  # `block` is 16 bits, which covers 65,536 blocks or a little over a million names — more than the
  # Unicode codespace. Assert rather than silently truncating if that ever stops being true.
  defp index_entry(codepoint, position) do
    block = div(position, @name_block_size)

    if block > 0xFFFF do
      raise "character name table has too many blocks (#{block}) for a 16 bit block index"
    end

    <<codepoint::24, block::16, rem(position, @name_block_size)::8>>
  end

  # The blob is in name order; this index must be in codepoint order to be binary-searchable.
  # Sorting the fixed-width entries as binaries sorts by codepoint, since each entry leads with it
  # as a big-endian 24 bit field.
  defp sort_codepoint_index(index) do
    for(<<entry::binary-size(6) <- index>>, do: entry)
    |> Enum.sort()
    |> IO.iodata_to_binary()
  end

  @doc """
  Returns the codepoint ranges whose character names are derived by rule rather than listed.

  `UnicodeData.txt` records these as `<..., First>`/`<..., Last>` pairs with no per-character name,
  so they are absent from `character_name_table/0`. Each entry is `{first, last, name_prefix}`,
  where the name of a codepoint in the range is the prefix followed by its hexadecimal value — this
  is rule NR2 of [UAX #44](https://www.unicode.org/reports/tr44/#Name).

  Ranges with no character name at all (surrogates and private use) are excluded, as are the Hangul
  syllables, whose names are built from jamo short names under rule NR1 instead. See
  `jamo_short_names/0`.

  """
  def character_name_ranges do
    @unicode_data_path
    |> parse_unicode_data()
    |> Enum.flat_map(fn
      {codepoint, ["<" <> label | _rest]} ->
        case String.split(label, ", ") do
          [name, boundary] when boundary in ["First>", "Last>"] ->
            [{name, boundary, String.to_integer(codepoint, 16)}]

          _other ->
            []
        end

      _other ->
        []
    end)
    |> Enum.group_by(&elem(&1, 0))
    |> Enum.flat_map(fn {label, boundaries} -> name_range(label, boundaries) end)
    |> Enum.sort()
  end

  defp name_range(label, boundaries) do
    with true <- derives_name?(label),
         [{_label, _first, first}, {_label2, _last, last}] <-
           Enum.sort_by(boundaries, &elem(&1, 2)) do
      [{first, last, name_prefix(label)}]
    else
      _other -> []
    end
  end

  # Surrogates and private use characters have no name, so nothing can be derived for them. Hangul
  # syllables do have derivable names but follow rule NR1, which is not a prefix plus a codepoint.
  defp derives_name?(label) do
    not (String.contains?(label, "Surrogate") or String.contains?(label, "Private Use") or
           label == "Hangul Syllable")
  end

  # Upcasing the label is the correct derivation for most ranges — `Seal Character` gives
  # `SEAL CHARACTER-`, matching UAX #44 — so a range added by a future Unicode release is handled
  # without change. CJK and Tangut are the two documented exceptions: every CJK extension shares
  # the single `CJK UNIFIED IDEOGRAPH-` prefix, and the Tangut supplement shares `TANGUT IDEOGRAPH-`.
  defp name_prefix("CJK Ideograph" <> _extension), do: "CJK UNIFIED IDEOGRAPH-"
  defp name_prefix("Tangut Ideograph" <> _supplement), do: "TANGUT IDEOGRAPH-"
  defp name_prefix(label), do: String.upcase(label) <> "-"

  @doc """
  Returns the Hangul jamo short names as `{leading, vowel, trailing}` tuples.

  A Hangul syllable name is `HANGUL SYLLABLE` followed by the short names of its leading consonant,
  vowel and optional trailing consonant, which is rule NR1 of
  [UAX #44](https://www.unicode.org/reports/tr44/#Name). The names are returned as the data file
  gives them, in upper case, and the trailing tuple carries an empty name at index 0 for syllables
  with no trailing consonant, so each tuple can be indexed directly by the jamo index computed in
  [UAX #15](https://www.unicode.org/reports/tr15/).

  """
  @jamo_path Path.join(Unicode.data_dir(), "jamo.txt")
  @external_resource @jamo_path
  def jamo_short_names do
    names =
      @jamo_path
      |> File.stream!()
      |> Enum.flat_map(fn
        <<"#", _rest::bitstring>> ->
          []

        <<"\n", _rest::bitstring>> ->
          []

        line ->
          [codepoint, short_name] =
            line |> String.split("#") |> hd() |> String.split(";") |> Enum.map(&String.trim/1)

          [{String.to_integer(codepoint, 16), short_name}]
      end)
      |> Map.new()

    leading = for codepoint <- 0x1100..0x1112, do: Map.fetch!(names, codepoint)
    vowel = for codepoint <- 0x1161..0x1175, do: Map.fetch!(names, codepoint)
    trailing = for codepoint <- 0x11A8..0x11C2, do: Map.fetch!(names, codepoint)

    {List.to_tuple(leading), List.to_tuple(vowel), List.to_tuple(["" | trailing])}
  end

  defp common_prefix_length(first, second), do: common_prefix_length(first, second, 0)

  defp common_prefix_length(<<char, first::binary>>, <<char, second::binary>>, length),
    do: common_prefix_length(first, second, length + 1)

  defp common_prefix_length(_first, _second, length), do: length

  @doc false
  def parse_file(path) do
    Enum.reduce(File.stream!(path), %{}, &parse_line/2)
    |> Enum.map(fn {key, ranges} ->
      {key, Enum.reverse(ranges)}
    end)
    |> Map.new()
  end

  defp parse_line(<<"#", _rest::bitstring>>, map) do
    map
  end

  defp parse_line(<<"\n", _rest::bitstring>>, map) do
    map
  end

  defp parse_line(data, map) do
    [range, script | tail] =
      data
      |> String.split(~r/[;#]/)
      |> Enum.map(&String.trim/1)

    [start, finish] =
      range
      |> String.split("..")
      |> extract_codepoint_range()

    Map.update(map, script, [{start, finish, tail}], &add_range(&1, start, finish, tail))
  end

  # Merges a new range into the accumulated (reversed) range list for one
  # property value. A new integer range adjacent to the most recent one is
  # coalesced with it, otherwise the new range is prepended.
  defp add_range([{first, last, text} | rest], start, finish, tail)
       when is_integer(first) and is_integer(last) and start == last + 1 do
    [{first, finish, tail ++ text} | rest]
  end

  defp add_range(ranges, start, finish, tail) do
    [{start, finish, tail} | ranges]
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

  @doc """
  Builds the value-alias map for an enumerated property.

  `category` is the lowercased property-value-alias category code (for example
  `"nt"` for Numeric_Type). `known_values` is the list of canonical value atoms
  actually present in the property data (the keys of the value-table map).

  Every alias token on the same `PropertyValueAliases` line as a known value is
  mapped, in normalized (downcased, whitespace/`_`/`-` removed) form, to that
  known value. Lines whose values are not present in the data (for example a
  default value that never appears explicitly) are skipped.

  A line may carry more than two names — `sc ; Copt ; Coptic ; Qaac` gives the
  short code, the canonical name and an ISO 15924 alias — so the tokens are
  regrouped by their short code and the whole group is resolved together. This
  is what makes every spelling reach the one name that is actually present in
  the data. Inverting the alias map instead loses entries, because it is
  many-to-one, and elects whichever name it happens to see last.

  """
  def value_aliases(category, known_values) do
    known = MapSet.new(known_values)

    property_value_alias()
    |> Map.get(category, %{})
    |> Enum.group_by(fn {_alias, code} -> code end, fn {alias, _code} -> alias end)
    |> Enum.reduce(%{}, fn {code, aliases}, resolved ->
      resolve_alias_group([code | aliases], known, resolved)
    end)
  end

  defp resolve_alias_group(tokens, known, resolved) do
    case Enum.find_value(tokens, &known_value(&1, known)) do
      nil ->
        resolved

      canonical ->
        Enum.reduce(tokens, resolved, fn token, resolved ->
          Map.put(resolved, downcase_and_remove_whitespace(token), canonical)
        end)
    end
  end

  defp known_value(token, known) do
    value = maybe_atomize(token)
    if MapSet.member?(known, value), do: value
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
  # Builds a guard expression that is true when the guard variable
  # `codepoint` falls within any of the given ranges. The expression is a
  # *balanced* binary tree of `or` clauses so its nesting depth is O(log n)
  # rather than O(n). A deep, right-nested linear chain is pathologically
  # slow for the BEAM to compile as a `defguard` (roughly 3x here) and, past
  # a few hundred ranges, can exceed the compiler's stack-slot limit; the
  # balanced tree keeps the nesting shallow.
  def ranges_to_guard_clause(ranges) do
    ranges_to_guard_clause(ranges, quote(do: var!(codepoint)))
  end

  @doc false
  # As `ranges_to_guard_clause/1` but tests the given `variable` AST
  # rather than the hygienic `codepoint` variable. Used by macros that
  # must substitute the caller's own expression into the guard.
  def ranges_to_guard_clause(ranges, variable) do
    ranges
    |> Enum.sort()
    |> balanced_guard_clause(variable)
  end

  defp balanced_guard_clause([{first, first}], variable) do
    quote do
      unquote(variable) == unquote(first)
    end
  end

  defp balanced_guard_clause([{first, last}], variable) do
    quote do
      unquote(variable) in unquote(first)..unquote(last)
    end
  end

  defp balanced_guard_clause(ranges, variable) do
    {left, right} = Enum.split(ranges, div(length(ranges), 2))

    quote do
      unquote(balanced_guard_clause(left, variable)) or
        unquote(balanced_guard_clause(right, variable))
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

  # The last codepoint of the Unicode codespace, used as the upper bound
  # when complementing a range list.
  @codespace_last 0x10FFFF

  @doc """
  Returns the union of one or more lists of codepoint ranges as a single
  sorted, compacted range list.

  """
  def union_ranges(range_lists) do
    range_lists
    |> List.flatten()
    |> Enum.sort()
    |> compact_ranges()
  end

  @doc """
  Returns the complement of a list of codepoint ranges over the Unicode
  codespace `0..0x10FFFF` — that is, every codepoint that is not covered
  by the given ranges.

  """
  def complement_ranges(ranges) do
    {gaps, next} =
      ranges
      |> Enum.sort()
      |> Enum.reduce({[], 0}, fn {first, last}, {gaps, next} ->
        gaps = if first > next, do: [{next, first - 1} | gaps], else: gaps
        {gaps, max(next, last + 1)}
      end)

    gaps = if next <= @codespace_last, do: [{next, @codespace_last} | gaps], else: gaps
    Enum.reverse(gaps)
  end

  @doc """
  Returns the difference of two lists of codepoint ranges — the codepoints
  in `ranges` that are not in `subtract`.

  """
  def difference_ranges(ranges, subtract) do
    complement_ranges(union_ranges([complement_ranges(ranges), subtract]))
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

  @doc """
  Adds the property value that a UCD data file declares as the default for
  every codepoint it does not list explicitly.

  Several UCD files carry an `@missing` annotation such as
  `# @missing: 0000..10FFFF; Other`, meaning that any codepoint absent from
  the file has that value. Because the value never appears as a data row it
  is otherwise absent from the parsed map, so `\p{Word_Break=Other}` and
  friends cannot be resolved.

  ### Arguments

  * `map` is a map of property value to a list of codepoint ranges as
    2-tuples. Annotations must already be removed.

  * `default_value` is the atom naming the value the `@missing` annotation
    declares.

  ### Returns

  * `map` with `default_value` added, holding every codepoint not assigned
    to some other value.

  """
  def add_default_value(map, default_value) do
    assigned = map |> Map.values() |> union_ranges()
    unassigned = difference_ranges([{0x0, 0x10FFFF}], assigned)

    # The value may already be present. `Line_Break` lists some XX ranges
    # explicitly even though XX is also its `@missing` default, so the two sets
    # have to be merged; replacing would silently drop the explicit ranges.
    Map.update(map, default_value, unassigned, fn existing ->
      union_ranges([existing, unassigned])
    end)
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
  def ranges_to_codepoints(ranges) when is_list(ranges) do
    Enum.reduce(ranges, [], fn
      {first, first}, acc ->
        [first | acc]

      {first, last}, acc ->
        Enum.to_list(last..first//-1) ++ acc
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
