defmodule Unicode.PropertyValues.Test do
  use ExUnit.Case, async: true

  # Every value `PropertyValueAliases.txt` declares for a property this library implements should
  # resolve, whichever spelling is used. That includes the values a data file supplies only through
  # an `@missing` annotation: `\p{jt=U}`, `\p{bpt=None}` and `\p{sc=Unknown}` name values that no
  # data row carries, and which are therefore easy to leave out of the parsed map.
  #
  # These values are declared for stability but no codepoint carries them in this release, so they
  # have no ranges to return. `E_Base` and its companions were withdrawn in Unicode 11, `CCC133` is
  # reserved and unused, and `Katakana_Or_Hiragana` is a script alias that is never assigned.
  @no_codepoints_in_this_release [
    {"ccc", "atbl"},
    {"ccc", "attached_below_left"},
    {"ccc", "ccc133"},
    {"gcb", "e_base"},
    {"gcb", "e_base_gaz"},
    {"gcb", "e_modifier"},
    {"gcb", "glue_after_zwj"},
    {"sc", "katakana_or_hiragana"},
    {"wb", "e_base"},
    {"wb", "e_base_gaz"},
    {"wb", "e_modifier"},
    {"wb", "glue_after_zwj"}
  ]

  # {module, the function returning its known values}. Each of these properties has a default value,
  # so between them its values account for every codepoint, assigned or not.
  @covering_modules [
    {Unicode.Age, :known_ages},
    {Unicode.BidiClass, :known_bidi_classes},
    {Unicode.BidiPairedBracketType, :known_bidi_paired_bracket_types},
    {Unicode.Block, :known_blocks},
    {Unicode.CanonicalCombiningClass, :known_combining_classes},
    {Unicode.DecompositionType, :known_decomposition_types},
    {Unicode.EastAsianWidth, :known_east_asian_width_categories},
    {Unicode.GeneralCategory, :known_categories},
    {Unicode.GraphemeClusterBreak, :known_grapheme_breaks},
    {Unicode.HangulSyllableType, :known_hangul_syllable_types},
    {Unicode.IndicConjunctBreak, :known_indic_conjunct_breaks},
    {Unicode.IndicPositionalCategory, :known_indic_positional_categories},
    {Unicode.IndicSyllabicCategory, :known_indic_syllabic_categories},
    {Unicode.JoiningGroup, :known_joining_groups},
    {Unicode.JoiningType, :known_joining_types},
    {Unicode.LineBreak, :known_line_breaks},
    {Unicode.NfcQuickCheck, :known_nfc_quick_check},
    {Unicode.NfdQuickCheck, :known_nfd_quick_check},
    {Unicode.NfkcQuickCheck, :known_nfkc_quick_check},
    {Unicode.NfkdQuickCheck, :known_nfkd_quick_check},
    {Unicode.NumericType, :known_numeric_types},
    {Unicode.Script, :known_scripts},
    {Unicode.ScriptExtensions, :known_script_extensions},
    {Unicode.SentenceBreak, :known_sentence_breaks},
    {Unicode.VerticalOrientation, :known_vertical_orientations},
    {Unicode.WordBreak, :known_word_breaks}
  ]

  describe "property values" do
    test "every value in PropertyValueAliases resolves" do
      # `Unicode.Emoji` and friends serve a property without implementing `fetch/1`, so they are
      # not part of this check.
      modules =
        for {category, _aliases} <- Unicode.Utils.property_value_alias(),
            {:ok, module} <- [Unicode.fetch_property(category)],
            match?({:module, _}, Code.ensure_loaded(module)),
            function_exported?(module, :fetch, 1),
            into: %{},
            do: {category, module}

      unresolvable =
        for {category, aliases} <- Unicode.Utils.property_value_alias(),
            module = modules[category],
            {alias_name, _code} <- aliases,
            module.fetch(alias_name) == :error,
            do: {category, alias_name}

      assert Enum.sort(unresolvable) == Enum.sort(@no_codepoints_in_this_release)
    end

    test "a property's values account for every codepoint" do
      for {module, known_values} <- @covering_modules do
        covered =
          module
          |> apply(known_values, [])
          |> Enum.flat_map(&(module.get(&1) || []))
          |> Unicode.Utils.union_ranges()
          |> Enum.reduce(0, fn {first, last}, count -> count + last - first + 1 end)

        assert covered == 0x110000,
               "#{inspect(module)} assigns a value to #{covered} of the 1,114,112 codepoints"
      end
    end
  end
end
