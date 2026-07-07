defmodule Unicode.Api.Test do
  use ExUnit.Case, async: true

  describe "version and data" do
    test "version/0 returns a three element tuple" do
      assert {major, _minor, _patch} = Unicode.version()
      assert major >= 17
    end

    test "data_dir/0 points at the packaged data directory" do
      assert File.exists?(Path.join(Unicode.data_dir(), "blocks.txt"))
    end

    test "all/0 covers the full codepoint range" do
      assert Unicode.all() == [{0x0, 0x10FFFF}]
    end

    test "assigned/0 and deprecated ranges/0 return the same list" do
      # `apply/3` avoids the compile-time deprecation warning for `ranges/0`.
      # credo:disable-for-next-line Credo.Check.Refactor.Apply
      assert Unicode.assigned() == apply(Unicode, :ranges, [])
      assert is_list(Unicode.assigned())
    end
  end

  describe "property servers" do
    test "property_servers/0 maps names to modules" do
      servers = Unicode.property_servers()

      assert servers["script"] == Unicode.Script
      assert servers["incb"] == Unicode.IndicConjunctBreak
    end

    test "fetch_property/1 resolves known properties" do
      assert Unicode.fetch_property("script") == {:ok, Unicode.Script}
      assert Unicode.fetch_property("Script") == {:ok, Unicode.Script}
      assert Unicode.fetch_property("no such property") == :error
    end

    test "get_property/1 resolves known properties or nil" do
      assert Unicode.get_property("block") == Unicode.Block
      assert Unicode.get_property("no such property") == nil
    end
  end

  describe "string introspection" do
    test "unaccent/1 removes diacritics" do
      assert Unicode.unaccent("Et Ça sera sa moitié") == "Et Ca sera sa moitie"
    end

    test "script_statistic/1 counts graphemes per script" do
      assert Unicode.script_statistic("おはよう") == %{hiragana: {0, 4}}
    end

    test "script_dominance/1 orders scripts" do
      assert [latin: {0, _}, common: _, han: _] =
               Unicode.script_dominance("Tokyo is the capital of 日本")
    end

    test "script_dominance/1 breaks ties deterministically" do
      assert [_first, _second] = Unicode.script_dominance("a日")
    end
  end

  describe "compact_ranges/1" do
    test "merges overlapping and adjacent ranges" do
      assert Unicode.compact_ranges([{1, 5}, {6, 10}]) == [{1, 10}]
      assert Unicode.compact_ranges([{1, 10}, {2, 5}]) == [{1, 10}]
      assert Unicode.compact_ranges([{1, 2}, {5, 6}]) == [{1, 2}, {5, 6}]
      assert Unicode.compact_ranges([{1, 2}]) == [{1, 2}]
    end

    test "drops a subsequent range that ends before the current one" do
      assert Unicode.compact_ranges([{5, 10}, {1, 3}]) == [{5, 10}]
    end
  end

  describe "Unicode.Property" do
    test "truthy property functions return the property name or nil" do
      assert Unicode.Property.numeric("123") == :numeric
      assert Unicode.Property.numeric("12a") == nil
      assert Unicode.Property.alphanumeric("abc123") == :alphanumeric
      assert Unicode.Property.alphanumeric("???") == nil
      assert Unicode.Property.extended_numeric("⅔") == :extended_numeric
      assert Unicode.Property.extended_numeric("abc") == nil
    end

    test "delegated aliases digits?, downcase? and upcase?" do
      assert Unicode.digits?("123")
      refute Unicode.digits?("12a")
      assert Unicode.downcase?("abc")
      refute Unicode.downcase?("aBc")
      assert Unicode.upcase?("ABC")
      refute Unicode.upcase?("AbC")
    end

    test "boolean property functions accept codepoints and strings" do
      assert Unicode.Property.alphabetic?(?A)
      refute Unicode.Property.alphabetic?(?!)
      assert Unicode.Property.alphabetic?("abc")
      refute Unicode.Property.alphabetic?("ab!")
      refute Unicode.Property.alphabetic?("")
    end

    test "generated truthy functions return the property name or nil" do
      assert Unicode.Property.alphabetic(?A) == :alphabetic
      assert Unicode.Property.alphabetic(?!) == nil
    end

    test "numeric?/1 and extended_numeric?/1 handle non-character input" do
      refute Unicode.Property.numeric?(:not_a_codepoint)
      refute Unicode.Property.extended_numeric?(:not_a_codepoint)
      refute Unicode.Property.alphanumeric?(:not_a_codepoint)
    end

    test "properties/1 returns properties for codepoints and strings" do
      assert :alphabetic in Unicode.Property.properties(?A)
      assert [[_ | _], [_ | _]] = Unicode.Property.properties("ab")
    end

    test "fetch/1 and get/1 resolve property names and aliases" do
      assert {:ok, ranges} = Unicode.Property.fetch("alphabetic")
      assert is_list(ranges)
      assert Unicode.Property.fetch(:alphabetic) == {:ok, ranges}
      assert Unicode.Property.get(:alphabetic) == ranges
      assert Unicode.Property.fetch("no such property") == :error
      assert Unicode.Property.get("no such property") == nil
    end

    test "count/1 returns the number of codepoints with a property" do
      assert Unicode.Property.count(:alphabetic) > 100_000
    end

    test "servers/0 and aliases/0 return maps" do
      assert is_map(Unicode.Property.servers())
      assert is_map(Unicode.Property.aliases())
    end

    test "known_properties/0 includes standard and emoji properties" do
      known = Unicode.Property.known_properties()

      assert :alphabetic in known
      assert :emoji in known
      assert :extended_pictographic in known
    end
  end

  describe "Unicode.Emoji" do
    test "emoji?/1 for codepoints and strings" do
      assert Unicode.Emoji.emoji?("🔥")
      assert Unicode.Emoji.emoji?(?1)
      refute Unicode.Emoji.emoji?("abc")
      refute Unicode.Emoji.emoji?(:not_a_codepoint)
    end

    test "emoji/1 returns the emoji category of a codepoint" do
      assert Unicode.Emoji.emoji(?1) == :emoji
      assert Unicode.Emoji.emoji(?#) == :emoji
      assert Unicode.Emoji.emoji(?a) == nil
    end

    test "emoji/1 returns a category per grapheme for a string" do
      assert Unicode.Emoji.emoji("1a") == [:emoji, nil]
      assert [category] = Unicode.Emoji.emoji("🔥")
      assert category in Unicode.Emoji.known_emoji_categories()
    end

    test "known_emoji_categories/0 and count/1" do
      assert :emoji in Unicode.Emoji.known_emoji_categories()
      assert Unicode.Emoji.count(:emoji) > 0
    end
  end

  describe "Unicode.RangeSearch" do
    test "new_value_table/1 rejects overlapping ranges across values" do
      assert_raise ArgumentError, ~r/overlapping ranges/, fn ->
        Unicode.RangeSearch.new_value_table(%{a: [{1, 10}], b: [{5, 20}]})
      end
    end

    test "new_value_table/1 ignores non-integer ranges" do
      table = Unicode.RangeSearch.new_value_table(%{a: [{1, 2}, {[1, 2], [1, 2]}]})

      assert Unicode.RangeSearch.find(table, 1, nil) == :a
      assert Unicode.RangeSearch.find(table, 3, nil) == nil
    end

    test "new_membership_table/1 merges overlapping ranges" do
      table = Unicode.RangeSearch.new_membership_table([{1, 10}, {5, 20}, {21, 30}])

      assert Unicode.RangeSearch.member?(table, 15)
      assert Unicode.RangeSearch.member?(table, 30)
      refute Unicode.RangeSearch.member?(table, 31)
    end

    test "empty tables return defaults" do
      value_table = Unicode.RangeSearch.new_value_table(%{})
      membership_table = Unicode.RangeSearch.new_membership_table([])

      assert Unicode.RangeSearch.find(value_table, 1, :default) == :default
      refute Unicode.RangeSearch.member?(membership_table, 1)
    end
  end
end
