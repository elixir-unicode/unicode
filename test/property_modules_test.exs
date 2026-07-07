defmodule Unicode.PropertyModules.Test do
  use ExUnit.Case, async: true

  # One entry per property module implementing Unicode.Property.Behaviour:
  # {module, lookup_function, codepoint, expected_value, default_codepoint, default_value}
  #
  # `codepoint` is a spot-check with a well-known property value;
  # `default_codepoint` is expected to take the module's default value.
  @property_modules [
    {Unicode.GeneralCategory, :category, ?A, :Lu, 0x10FFFF, :Cn},
    {Unicode.Script, :script, ?A, :latin, 0x10FFFF, :unknown},
    {Unicode.Block, :block, ?A, :basic_latin, 0x2FE0, :no_block},
    {Unicode.CanonicalCombiningClass, :combining_class, 0x0301, 230, ?A, 0},
    {Unicode.BidiClass, :bidi_class, 0x05D0, :r, ?A, :l},
    {Unicode.EastAsianWidth, :east_asian_width_category, 0xFF01, :f, ?A, :na},
    {Unicode.GraphemeClusterBreak, :grapheme_break, 0x200D, :zwj, ?A, :other},
    {Unicode.IndicConjunctBreak, :indic_conjunct_break, 0x094D, :linker, ?A, :none},
    {Unicode.IndicSyllabicCategory, :indic_syllabic_category, 0x094D, :virama, ?A, :other},
    {Unicode.JoiningType, :joining_type, 0x0628, :d, 0x0640, :c},
    {Unicode.LineBreak, :line_break, ?\n, :lf, ?A, :al},
    {Unicode.SentenceBreak, :sentence_break, ?A, :upper, ?\n, :lf},
    {Unicode.WordBreak, :word_break, ?A, :aletter, ?\n, :lf}
  ]

  for {module, lookup_function, codepoint, expected, default_codepoint, default_value} <-
        @property_modules do
    describe "#{inspect(module)}" do
      test "codepoint lookup returns the expected value" do
        assert unquote(module).unquote(lookup_function)(unquote(codepoint)) ==
                 unquote(expected)
      end

      test "codepoint lookup returns the default value" do
        assert unquote(module).unquote(lookup_function)(unquote(default_codepoint)) ==
                 unquote(default_value)
      end

      test "string lookup returns a list including the expected value" do
        string = <<unquote(codepoint)::utf8>>

        assert unquote(expected) in unquote(module).unquote(lookup_function)(string)
      end

      test "codepoint lookup raises on an out of range codepoint" do
        assert_raise FunctionClauseError, fn ->
          unquote(module).unquote(lookup_function)(0x110000)
        end
      end

      test "fetch/1 with a known value returns ranges" do
        assert {:ok, ranges} = unquote(module).fetch(unquote(expected))
        assert is_list(ranges)
        assert Enum.any?(ranges, fn {first, last} -> unquote(codepoint) in first..last end)
      end

      test "fetch/1 with an unknown value returns :error" do
        assert unquote(module).fetch("not a property value") == :error
      end

      test "get/1 returns ranges for a known value and nil otherwise" do
        assert is_list(unquote(module).get(unquote(expected)))
        assert unquote(module).get("not a property value") == nil
      end

      test "count/1 returns a positive integer" do
        assert unquote(module).count(unquote(expected)) > 0
      end

      test "aliases/0 returns a map" do
        assert is_map(unquote(module).aliases())
      end
    end
  end

  describe "fetch/1 alias resolution" do
    test "general category aliases resolve" do
      assert Unicode.GeneralCategory.fetch("uppercase letter") ==
               Unicode.GeneralCategory.fetch(:Lu)

      assert Unicode.GeneralCategory.fetch("Lu") == Unicode.GeneralCategory.fetch(:Lu)
    end

    test "script aliases resolve" do
      assert Unicode.Script.fetch("latn") == Unicode.Script.fetch(:latin)
    end

    test "block fetch resolves names with whitespace" do
      assert Unicode.Block.fetch("Basic Latin") == Unicode.Block.fetch(:basic_latin)
    end

    test "combining class fetches by integer" do
      assert {:ok, _ranges} = Unicode.CanonicalCombiningClass.fetch(230)
    end
  end

  describe "known values" do
    test "each property module returns its known values" do
      assert :Lu in Unicode.GeneralCategory.known_categories()
      assert :latin in Unicode.Script.known_scripts()
      assert :basic_latin in Unicode.Block.known_blocks()
      assert 230 in Unicode.CanonicalCombiningClass.known_combining_classes()
      assert :r in Unicode.BidiClass.known_bidi_classes()
      assert :f in Unicode.EastAsianWidth.known_east_asian_width_categories()
      assert :zwj in Unicode.GraphemeClusterBreak.known_grapheme_breaks()
      assert :linker in Unicode.IndicConjunctBreak.known_indic_conjunct_breaks()
      assert :virama in Unicode.IndicSyllabicCategory.known_indic_syllabic_categories()
      assert :d in Unicode.JoiningType.known_joining_types()
      assert :lf in Unicode.LineBreak.known_line_breaks()
      assert :upper in Unicode.SentenceBreak.known_sentence_breaks()
      assert :aletter in Unicode.WordBreak.known_word_breaks()
    end

    test "each property module returns its ranges map" do
      assert is_map(Unicode.GeneralCategory.categories())
      assert is_map(Unicode.Script.scripts())
      assert is_map(Unicode.Block.blocks())
      assert is_map(Unicode.CanonicalCombiningClass.combining_classes())
      assert is_map(Unicode.BidiClass.bidi_classes())
      assert is_map(Unicode.EastAsianWidth.east_asian_width_categories())
      assert is_map(Unicode.GraphemeClusterBreak.grapheme_breaks())
      assert is_map(Unicode.IndicConjunctBreak.indic_conjunct_break())
      assert is_map(Unicode.IndicSyllabicCategory.indic_syllabic_categories())
      assert is_map(Unicode.JoiningType.joining_types())
      assert is_map(Unicode.LineBreak.line_breaks())
      assert is_map(Unicode.SentenceBreak.sentence_breaks())
      assert is_map(Unicode.WordBreak.word_breaks())
    end
  end

  describe "derived categories" do
    test "derived categories include :Any, :Ascii and :Assigned" do
      derived = Unicode.GeneralCategory.Derived.categories()

      assert Map.has_key?(derived, :Any)
      assert Map.has_key?(derived, :Ascii)
      assert Map.has_key?(derived, :Assigned)
    end

    test "derived aliases are a map" do
      assert is_map(Unicode.GeneralCategory.Derived.aliases())
    end

    test "derived categories are resolvable through GeneralCategory" do
      assert {:ok, [{0, 127}]} = Unicode.GeneralCategory.fetch(:Ascii)
      assert {:ok, [{0, 0x10FFFF}]} = Unicode.GeneralCategory.fetch(:Any)
    end

    test "super categories combine their sub categories" do
      assert {:ok, letters} = Unicode.GeneralCategory.fetch(:L)
      assert Enum.any?(letters, fn {first, last} -> ?A in first..last end)
      assert Enum.any?(letters, fn {first, last} -> ?a in first..last end)
    end
  end

  describe "block assigned ranges" do
    test "assigned/0 returns compacted block ranges" do
      assigned = Unicode.Block.assigned()

      assert is_list(assigned)
      assert Enum.any?(assigned, fn {first, last} -> ?A in first..last end)
    end
  end
end
