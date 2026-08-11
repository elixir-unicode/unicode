defmodule Unicode.Unicode18.Test do
  @moduledoc """
  Verifies that the values introduced by Unicode 18.0 are reachable through the public API.

  Unicode 18 adds no new properties — only new values for existing enumerated properties — so these
  tests assert that scripts, blocks, joining groups and ages new in this release resolve, rather
  than testing any new API surface.
  """

  use ExUnit.Case, async: true

  # {script, a codepoint within it}
  #
  # Chisoi was in the alpha data but was removed during the beta review, which is exactly the change
  # the beta period allows — the repertoire is closed to *additions* once beta opens, but characters
  # new in the version may still be withdrawn.
  @new_scripts [
    {:jurchen, 0x18E00},
    {:proto_cuneiform, 0x125A8},
    {:seal, 0x3D000}
  ]

  # {block, first codepoint of the block}
  @new_blocks [
    {:bengali_supplement, 0x11DF0},
    {:archaic_cuneiform_numerals, 0x12550},
    {:jurchen, 0x18E00},
    {:jurchen_radicals, 0x191A0},
    {:musical_symbols_supplement, 0x1D250},
    {:miscellaneous_symbols_and_arrows_extended, 0x1DB00},
    {:seal, 0x3D000}
  ]

  @new_joining_groups [
    :"crown ain",
    :"crown beh",
    :"crown feh",
    :"crown hah",
    :"crown heh",
    :"crown kaf",
    :"crown meem",
    :"crown sad",
    :"crown seen",
    :"crown tah"
  ]

  # {name, codepoint} for characters explicitly named in the blocks new in this release.
  @new_character_names [
    {"BENGALI SIGN COMBINING ANUSVARA ABOVE", 0x11DF0},
    {"CUNEIFORM NUMERIC SIGN ONE N01", 0x12550},
    {"JURCHEN RADICAL-01", 0x191A0},
    {"MUSICAL SYMBOL COMBINING FLAG-6", 0x1D250},
    {"LEIBNIZIAN EQUALS SIGN", 0x1DB00}
  ]

  describe "Unicode version" do
    test "the bundled data is Unicode 18" do
      assert {18, 0, 0} = Unicode.version()
    end
  end

  describe "new scripts" do
    for {script, codepoint} <- @new_scripts do
      test "#{script} is a known script" do
        assert unquote(script) in Unicode.Script.known_scripts()
      end

      test "#{script} resolves a representative codepoint" do
        assert Unicode.Script.script(unquote(codepoint)) == unquote(script)
      end

      test "#{script} has a non-empty range list" do
        assert {:ok, ranges} = Unicode.Script.fetch(unquote(script))
        assert Unicode.Script.count(unquote(script)) > 0
        assert is_list(ranges)
      end
    end

    test "Seal is the largest addition in this release" do
      assert Unicode.Script.count(:seal) == 11_328
    end
  end

  describe "new blocks" do
    for {block, codepoint} <- @new_blocks do
      test "#{block} is a known block" do
        assert unquote(block) in Unicode.Block.known_blocks()
      end

      test "#{block} contains its first codepoint" do
        assert Unicode.Block.block(unquote(codepoint)) == unquote(block)
      end
    end

    test "Bengali Supplement resolves by its display name" do
      # `_Sup`-suffixed and digit-bearing block names have historically been the ones that fail
      # alias resolution, so the string form is asserted as well as the atom form.
      assert Unicode.Block.fetch("Bengali Supplement") == Unicode.Block.fetch(:bengali_supplement)
    end
  end

  describe "new joining groups" do
    test "the Crown_* joining groups are known" do
      known = Unicode.JoiningGroup.known_joining_groups()

      for joining_group <- @new_joining_groups do
        assert joining_group in known
      end
    end
  end

  describe "new age" do
    test "18.0 is a known age with assigned codepoints" do
      assert {:ok, ranges} = Unicode.Age.fetch(:"18.0")
      assert is_list(ranges)
      assert Unicode.Age.count(:"18.0") > 0
    end

    test "codepoints new in this release report age 18.0" do
      assert Unicode.Age.age(0x3D000) == :"18.0"
      assert Unicode.Age.age(0x18E00) == :"18.0"
    end
  end

  describe "character names in the new blocks" do
    test "names in the new blocks resolve to their codepoints" do
      # The name table is front-coded with periodic restart points, so a release adding this many
      # names exercises the binary search across newly shifted restart boundaries.
      for {name, codepoint} <- @new_character_names do
        assert Unicode.CharacterName.to_codepoint(name) == {:ok, codepoint}
      end
    end

    test "the name table grew with the new assignments" do
      assert Unicode.CharacterName.count() > 41_000
    end

    test "the new algorithmically named ranges resolve" do
      # `Seal` and `Jurchen` are range entries in `UnicodeData.txt` (`<Seal Character, First>`) with
      # no per-character name, so they are absent from the name table and resolved by rule instead.
      assert Unicode.CharacterName.to_codepoint("SEAL CHARACTER-3D000") == {:ok, 0x3D000}
      assert Unicode.CharacterName.to_codepoint("SEAL CHARACTER-3FC3F") == {:ok, 0x3FC3F}
      assert Unicode.CharacterName.to_codepoint("JURCHEN CHARACTER-18E00") == {:ok, 0x18E00}
      assert Unicode.CharacterName.to_codepoint("JURCHEN CHARACTER-19191") == {:ok, 0x19191}
    end
  end
end
