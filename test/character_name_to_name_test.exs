defmodule Unicode.CharacterName.ToName.Test do
  @moduledoc """
  Covers `Unicode.CharacterName.to_name/1`.

  Listed names are decoded from the same front-coded blob that `to_codepoint/1` searches, reached
  through a codepoint index. Derived names are computed from the UAX #44 rules and are not stored.
  """

  use ExUnit.Case, async: true

  alias Unicode.CharacterName

  describe "derived names, which are computed rather than stored" do
    test "NR2 ranged names resolve" do
      assert CharacterName.to_name(0x4E00) == {:ok, "CJK UNIFIED IDEOGRAPH-4E00"}
      assert CharacterName.to_name(0x17000) == {:ok, "TANGUT IDEOGRAPH-17000"}
      assert CharacterName.to_name(0x3D000) == {:ok, "SEAL CHARACTER-3D000"}
      assert CharacterName.to_name(0x18E00) == {:ok, "JURCHEN CHARACTER-18E00"}
    end

    test "NR1 Hangul syllable names resolve" do
      assert CharacterName.to_name(0xAC00) == {:ok, "HANGUL SYLLABLE GA"}
      assert CharacterName.to_name(0xD7A3) == {:ok, "HANGUL SYLLABLE HIH"}
      # CHOSEONG IEUNG contributes no letters to the name.
      assert CharacterName.to_name(0xC544) == {:ok, "HANGUL SYLLABLE A"}
    end

    test "every Hangul syllable round-trips through to_codepoint/1" do
      failures =
        Enum.reject(0xAC00..0xD7A3, fn codepoint ->
          {:ok, name} = CharacterName.to_name(codepoint)
          CharacterName.to_codepoint(name) == {:ok, codepoint}
        end)

      assert failures == []
    end

    test "the boundaries of every NR2 range round-trip" do
      for {first, last, _prefix} <- Unicode.Utils.character_name_ranges(),
          codepoint <- [first, last] do
        assert {:ok, name} = CharacterName.to_name(codepoint)
        assert CharacterName.to_codepoint(name) == {:ok, codepoint}
      end
    end

    test "codepoints with no name return :error" do
      # Control characters, surrogates, private use and unassigned codepoints have an empty Name.
      assert CharacterName.to_name(0x0000) == :error
      assert CharacterName.to_name(0xD800) == :error
      assert CharacterName.to_name(0xE000) == :error
      assert CharacterName.to_name(0x0378) == :error
    end

    test "raises on an out of range codepoint" do
      assert_raise FunctionClauseError, fn -> CharacterName.to_name(0x110000) end
    end
  end

  describe "listed names" do
    test "well known names resolve" do
      assert CharacterName.to_name(?A) == {:ok, "LATIN CAPITAL LETTER A"}
      assert CharacterName.to_name(?a) == {:ok, "LATIN SMALL LETTER A"}
      assert CharacterName.to_name(0x2603) == {:ok, "SNOWMAN"}
      assert CharacterName.to_name(0x1F600) == {:ok, "GRINNING FACE"}
    end

    test "names are returned in their original form, not normalized" do
      # The to_codepoint/1 table stores `latincapitallettera`; this must not leak through here.
      assert {:ok, name} = CharacterName.to_name(?A)
      assert name == String.upcase(name)
      assert String.contains?(name, " ")
    end

    test "every listed name matches UnicodeData.txt exactly" do
      # Exhaustive: the table is front-coded, so a decoding error would corrupt a whole block of
      # names rather than one, and spot checks would likely land outside it.
      mismatches =
        Unicode.Utils.unicode()
        |> Enum.flat_map(fn
          {_codepoint, ["<" <> _label | _rest]} -> []
          {codepoint, [name | _rest]} -> [{String.to_integer(codepoint, 16), name}]
        end)
        |> Enum.reject(fn {codepoint, name} ->
          CharacterName.to_name(codepoint) == {:ok, name}
        end)

      assert mismatches == []
    end

    test "names in the blocks new in Unicode 18 resolve" do
      assert CharacterName.to_name(0x11DF0) == {:ok, "BENGALI SIGN COMBINING ANUSVARA ABOVE"}
      assert CharacterName.to_name(0x16D80) == {:ok, "CHISOI LETTER A"}
      assert CharacterName.to_name(0x1DB00) == {:ok, "LEIBNIZIAN EQUALS SIGN"}
    end
  end

  describe "loose matching is lossy in one direction only" do
    test "names differing only by a non-medial hyphen collide under to_codepoint/1" do
      # UAX #44 rule UAX44-LM2 ignores only *medial* hyphens, but this library removes all of them,
      # so `TIBETAN LETTER -A` and `TIBETAN LETTER A` normalize identically and only the first is
      # reachable by name. `to_name/1` is unaffected and returns each codepoint's own name.
      assert CharacterName.to_name(0x0F60) == {:ok, "TIBETAN LETTER -A"}
      assert CharacterName.to_name(0x0F68) == {:ok, "TIBETAN LETTER A"}

      assert CharacterName.to_codepoint("TIBETAN LETTER -A") ==
               CharacterName.to_codepoint("TIBETAN LETTER A")
    end
  end
end
