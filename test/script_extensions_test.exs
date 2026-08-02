defmodule Unicode.ScriptExtensions.Test do
  use ExUnit.Case, async: true

  describe "codepoint lookup" do
    test "a codepoint with no explicit assignment takes its Script value" do
      # The great majority of codepoints are absent from ScriptExtensions.txt and default to `sc`.
      assert Unicode.ScriptExtensions.script_extensions(?A) == [:latin]
      assert Unicode.Script.script(?A) == :latin
    end

    test "a codepoint shared between scripts returns the whole set" do
      assert Unicode.ScriptExtensions.script_extensions(0x02C7) == [:bopomofo, :latin]
    end

    test "ARABIC TATWEEL returns every script it is used with" do
      scripts = Unicode.ScriptExtensions.script_extensions(0x0640)

      assert :arabic in scripts
      assert :syriac in scripts
      assert :mandaic in scripts
      assert length(scripts) > 5
    end

    test "an explicitly listed codepoint drops its Script value when absent from the set" do
      # U+00B7 MIDDLE DOT has sc=Common, but Common is not in its scx set. This is the case a naive
      # merge of Scripts.txt and ScriptExtensions.txt gets wrong.
      assert Unicode.Script.script(0x00B7) == :common
      refute :common in Unicode.ScriptExtensions.script_extensions(0x00B7)
      assert :greek in Unicode.ScriptExtensions.script_extensions(0x00B7)
    end

    test "an unassigned codepoint returns unknown" do
      assert Unicode.ScriptExtensions.script_extensions(0x0378) == [:unknown]
    end

    test "a string returns the union of its codepoints' sets" do
      assert Unicode.ScriptExtensions.script_extensions("Aά") == [:greek, :latin]
    end

    test "results are sorted and deduplicated" do
      scripts = Unicode.ScriptExtensions.script_extensions("AAAά")

      assert scripts == Enum.sort(scripts)
      assert scripts == Enum.uniq(scripts)
    end

    test "raises on an out of range codepoint" do
      assert_raise FunctionClauseError, fn ->
        Unicode.ScriptExtensions.script_extensions(0x110000)
      end
    end
  end

  describe "range introspection" do
    test "fetch/1 resolves atoms, names and short codes" do
      assert {:ok, ranges} = Unicode.ScriptExtensions.fetch(:latin)
      assert Unicode.ScriptExtensions.fetch("latin") == {:ok, ranges}
      assert Unicode.ScriptExtensions.fetch("latn") == {:ok, ranges}
    end

    test "fetch/1 returns :error for an unknown script" do
      assert Unicode.ScriptExtensions.fetch(:invalid) == :error
      assert Unicode.ScriptExtensions.fetch("not a script") == :error
    end

    test "get/1 returns ranges or nil" do
      assert is_list(Unicode.ScriptExtensions.get(:latin))
      assert Unicode.ScriptExtensions.get(:invalid) == nil
    end

    test "the scx range list is a superset of the sc range list" do
      # Every script gains the shared characters that name it, so scx is never smaller than sc.
      for script <- [:latin, :greek, :arabic, :han] do
        assert Unicode.ScriptExtensions.count(script) >= Unicode.Script.count(script)
      end
    end

    test "Common is smaller under scx than under sc" do
      # The shared characters listed in ScriptExtensions.txt are removed from Common.
      assert Unicode.ScriptExtensions.count(:common) < Unicode.Script.count(:common)
    end

    test "known_script_extensions/0 covers every known script" do
      assert Enum.sort(Unicode.ScriptExtensions.known_script_extensions()) ==
               Enum.sort(Unicode.Script.known_scripts())
    end

    test "aliases/0 maps short codes to canonical script names" do
      aliases = Unicode.ScriptExtensions.aliases()

      assert Map.get(aliases, "latn") == :latin
      assert Map.get(aliases, "copt") == :coptic
      assert Map.get(aliases, "coptic") == :coptic
    end

    test "the ISO 15924 alias Qaac does not become a script of its own" do
      # `Copt` shares its PropertyValueAliases line with both `Coptic` and the alias `Qaac`.
      # Inverting that many-to-one map elects an arbitrary name, which filed the Coptic codepoints
      # under a spurious `:qaac` key. Coptic must own them.
      refute :qaac in Unicode.ScriptExtensions.known_script_extensions()
      assert :coptic in Unicode.ScriptExtensions.known_script_extensions()
      assert 0x00B7 in (Unicode.ScriptExtensions.get(:coptic) |> ranges_to_codepoints())
    end

    defp ranges_to_codepoints(ranges) do
      Enum.flat_map(ranges, fn {first, last} -> Enum.to_list(first..last) end)
    end
  end

  describe "property resolution" do
    test "scx resolves through the generic property API" do
      assert Unicode.fetch_property("scx") == {:ok, Unicode.ScriptExtensions}
    end
  end

  describe "internal consistency" do
    test "the set-keyed form partitions the codepoints it covers" do
      # `Unicode.RangeSearch.new_value_table/1` raises when ranges for different values overlap, so
      # building the table at compile time already proves disjointness. Assert it explicitly too,
      # since it is the invariant that makes a single lookup return a complete answer.
      ranges =
        Unicode.Utils.script_extension_sets()
        |> Map.values()
        |> Enum.concat()
        |> Enum.sort()

      Enum.reduce(ranges, -1, fn {first, last}, previous_last ->
        assert first > previous_last
        last
      end)
    end

    test "every script in the inverted form appears in the set-keyed form" do
      from_sets =
        Unicode.Utils.script_extension_sets()
        |> Map.keys()
        |> Enum.concat()
        |> Enum.uniq()
        |> Enum.sort()

      assert from_sets == Enum.sort(Unicode.ScriptExtensions.known_script_extensions())
    end
  end
end
