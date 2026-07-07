defmodule Unicode.UtilsMore.Test do
  use ExUnit.Case, async: true

  alias Unicode.Utils

  describe "data file parsing" do
    test "unicode/0 parses the unicode data file" do
      unicode = Utils.unicode()

      assert is_map(unicode)
      assert Map.has_key?(unicode, "0041")
    end

    test "scripts/0, blocks/0 and categories/0 return annotated range maps" do
      assert {_first, _last, _annotation} = Utils.scripts() |> Map.fetch!(:latin) |> hd()
      assert {_first, _last, _annotation} = Utils.blocks() |> Map.fetch!(:basic_latin) |> hd()
      assert {_first, _last, _annotation} = Utils.categories() |> Map.fetch!(:Lu) |> hd()
    end

    test "remove_annotations/1 strips annotations" do
      assert {_first, _last} =
               Utils.scripts() |> Utils.remove_annotations() |> Map.fetch!(:latin) |> hd()
    end

    test "property files parse to maps" do
      assert is_map(Utils.derived_properties())
      assert is_map(Utils.properties())
      assert is_map(Utils.emoji())
      assert is_map(Utils.emoji_sequences())
      assert is_map(Utils.combining_classes())
      assert is_map(Utils.bidi_classes())
      assert is_map(Utils.joining_types())
      assert is_map(Utils.grapheme_breaks())
      assert is_map(Utils.line_breaks())
      assert is_map(Utils.word_breaks())
      assert is_map(Utils.sentence_breaks())
      assert is_map(Utils.east_asian_width())
      assert is_map(Utils.indic_syllabic_categories())
    end

    test "property_alias/0 and property_value_alias/0 parse to maps" do
      assert Utils.property_alias()["sc"] == "script"
      assert is_map(Utils.property_value_alias()["gc"])
    end

    test "property_servers/0 maps aliases to modules" do
      servers = Utils.property_servers()

      assert servers["sc"] == Unicode.Script
      assert servers["incb"] == Unicode.IndicConjunctBreak
    end
  end

  describe "casing data" do
    test "case_folding/0 returns folding entries" do
      assert [[status, from, to] | _rest] = Utils.case_folding()
      assert status in [:common, :turkic, :full, :simple]
      assert is_integer(from)
      assert is_list(to) or is_integer(to)
    end

    test "default_casing/0 includes cased characters" do
      casing = Utils.default_casing()

      assert %{{:any, nil} => %{upper: _, lower: lower, title: _, type: :default}} =
               Map.fetch!(casing, ?A)

      assert lower == [?a]
    end

    test "special_casing/0 includes language sensitive mappings" do
      special = Utils.special_casing()

      # The Turkish dotless i is the canonical special casing example.
      assert Map.has_key?(special, ?i)
    end

    test "casing/0 merges default and special casing" do
      casing = Utils.casing()

      assert Map.has_key?(casing, ?A)
      assert Map.has_key?(casing, ?i)
    end

    test "casing_in_order/0 sorts languages before the :any fallback" do
      in_order = Utils.casing_in_order()

      i_rules = Enum.filter(in_order, &(&1.codepoint == ?i))
      assert List.last(i_rules).language == :any
    end

    test "known_casing_locales/0 returns the locales in SpecialCasing.txt" do
      locales = Utils.known_casing_locales()

      assert :tr in locales
      assert :az in locales
      assert :lt in locales
      refute :any in locales
    end
  end

  describe "range manipulation" do
    test "list_to_ranges/1 collapses codepoint lists" do
      assert Utils.list_to_ranges([1, 2, 3, 5, 7, 8]) == [{1, 3}, {5, 5}, {7, 8}]
      assert Utils.list_to_ranges([]) == []
    end

    test "ranges_to_codepoints/1 expands ranges" do
      codepoints = Utils.ranges_to_codepoints([{1, 3}, {5, 5}])

      assert Enum.sort(codepoints) == [1, 2, 3, 5]
    end

    test "ranges_to_guard_clause/1 builds a guard AST" do
      assert {:==, _, _} = Utils.ranges_to_guard_clause([{5, 5}])
      assert {:or, _, _} = Utils.ranges_to_guard_clause([{1, 3}, {5, 5}])
    end
  end

  describe "map and string helpers" do
    test "downcase_and_remove_whitespace/1 for strings, atoms and integers" do
      assert Utils.downcase_and_remove_whitespace("Basic Latin") == "basiclatin"
      assert Utils.downcase_and_remove_whitespace("Left_To-Right") == "lefttoright"
      assert Utils.downcase_and_remove_whitespace(:Lu) == "lu"
      assert Utils.downcase_and_remove_whitespace(230) == "230"
    end

    test "key and value transforms" do
      assert Utils.capitalize_keys(%{"lu" => 1}) == %{"Lu" => 1}
      assert Utils.downcase_keys(%{"LU" => 1}) == %{"lu" => 1}
      assert Utils.atomize_keys(%{"basic latin" => 1}) == %{basic_latin: 1}
      assert Utils.capitalize_values(%{k: "lu"}) == %{k: "Lu"}
      assert Utils.atomize_values(%{k: "lu"}) == %{k: :lu}
      assert Utils.invert_map(%{a: 1}) == %{1 => :a}
    end

    test "add_canonical_alias/1 adds string keys for atom values" do
      aliased = Utils.add_canonical_alias(%{"uppercaseletter" => :Lu})

      assert aliased["lu"] == :Lu
      assert aliased["uppercaseletter"] == :Lu
    end

    test "maybe_atomize/1 only converts existing atoms" do
      assert Utils.maybe_atomize("latin") == :latin
      assert Utils.maybe_atomize("no such atom hopefully") == "no such atom hopefully"
    end

    test "conform_key/1 replaces spaces and dashes" do
      assert Utils.conform_key("a b-c") == "a_b_c"
    end
  end
end
