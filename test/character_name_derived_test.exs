defmodule Unicode.CharacterName.Derived.Test do
  @moduledoc """
  Covers the character names derived by rule rather than listed in `UnicodeData.txt`.

  These are the `<..., First>`/`<..., Last>` ranges (rule NR2 of UAX #44) and the Hangul syllables
  (rule NR1). Together they account for more characters than the entire listed name table, so they
  are computed on demand rather than stored.
  """

  use ExUnit.Case, async: true

  describe "NR2 ranged names" do
    test "the first and last codepoint of every range resolves" do
      # Driven off the data rather than a fixed list, so a range added by a future Unicode release
      # is covered without editing this test.
      for {first, last, prefix} <- Unicode.Utils.character_name_ranges() do
        first_name = prefix <> Integer.to_string(first, 16)
        last_name = prefix <> Integer.to_string(last, 16)

        assert Unicode.CharacterName.to_codepoint(first_name) == {:ok, first}
        assert Unicode.CharacterName.to_codepoint(last_name) == {:ok, last}
      end
    end

    test "well known ideograph names resolve" do
      assert Unicode.CharacterName.to_codepoint("CJK UNIFIED IDEOGRAPH-4E00") == {:ok, 0x4E00}
      assert Unicode.CharacterName.to_codepoint("CJK UNIFIED IDEOGRAPH-20000") == {:ok, 0x20000}
      assert Unicode.CharacterName.to_codepoint("TANGUT IDEOGRAPH-17000") == {:ok, 0x17000}
    end

    test "names are matched loosely, as listed names are" do
      assert Unicode.CharacterName.to_codepoint("cjk unified ideograph 4e00") == {:ok, 0x4E00}
      assert Unicode.CharacterName.to_codepoint("CjkUnifiedIdeograph-4E00") == {:ok, 0x4E00}
    end

    test "a codepoint outside the range does not resolve" do
      # The prefix alone is not sufficient — without the bounds check this would resolve to an
      # unassigned codepoint.
      assert Unicode.CharacterName.to_codepoint("CJK UNIFIED IDEOGRAPH-FFFFFF") == :error
      assert Unicode.CharacterName.to_codepoint("SEAL CHARACTER-1") == :error
    end

    test "a malformed suffix does not resolve" do
      assert Unicode.CharacterName.to_codepoint("SEAL CHARACTER-ZZZZ") == :error
      assert Unicode.CharacterName.to_codepoint("SEAL CHARACTER-3D000X") == :error
      assert Unicode.CharacterName.to_codepoint("SEAL CHARACTER-") == :error
    end

    test "ranges with no character name are excluded" do
      # Surrogates and private use characters have no name, so nothing should be derivable for them
      # even though they appear as ranges in UnicodeData.txt.
      labels = Enum.map(Unicode.Utils.character_name_ranges(), &elem(&1, 2))

      refute Enum.any?(labels, &String.contains?(&1, "SURROGATE"))
      refute Enum.any?(labels, &String.contains?(&1, "PRIVATE USE"))
      assert Unicode.CharacterName.to_codepoint("PRIVATE USE-E000") == :error
      assert Unicode.CharacterName.to_codepoint("LOW SURROGATE-DC00") == :error
    end
  end

  describe "NR1 Hangul syllable names" do
    test "every Hangul syllable name resolves to its codepoint" do
      # Exhaustive rather than sampled: the jamo short names are not prefix-free and two of them are
      # empty (CHOSEONG IEUNG, and the absent trailing consonant), so the decomposition needs
      # backtracking. A sampled test would not have caught the 588 syllables a greedy match missed.
      {leading, vowel, trailing} = Unicode.Utils.jamo_short_names()

      failures =
        for leading_index <- 0..(tuple_size(leading) - 1),
            vowel_index <- 0..(tuple_size(vowel) - 1),
            trailing_index <- 0..(tuple_size(trailing) - 1) do
          codepoint =
            0xAC00 +
              (leading_index * tuple_size(vowel) + vowel_index) * tuple_size(trailing) +
              trailing_index

          name =
            "HANGUL SYLLABLE " <>
              elem(leading, leading_index) <>
              elem(vowel, vowel_index) <> elem(trailing, trailing_index)

          {name, codepoint}
        end
        |> Enum.reject(fn {name, codepoint} ->
          Unicode.CharacterName.to_codepoint(name) == {:ok, codepoint}
        end)

      assert failures == []
    end

    test "the syllable count matches the Hangul block" do
      {leading, vowel, trailing} = Unicode.Utils.jamo_short_names()

      assert tuple_size(leading) * tuple_size(vowel) * tuple_size(trailing) == 11_172
      assert Unicode.CharacterName.to_codepoint("HANGUL SYLLABLE GA") == {:ok, 0xAC00}
      assert Unicode.CharacterName.to_codepoint("HANGUL SYLLABLE HIH") == {:ok, 0xD7A3}
    end

    test "a syllable with no leading consonant resolves" do
      # CHOSEONG IEUNG has an empty short name, so the name begins directly with the vowel.
      assert Unicode.CharacterName.to_codepoint("HANGUL SYLLABLE A") == {:ok, 0xC544}
      assert Unicode.CharacterName.to_codepoint("HANGUL SYLLABLE EU") == {:ok, 0xC73C}
    end

    test "an invalid jamo sequence does not resolve" do
      assert Unicode.CharacterName.to_codepoint("HANGUL SYLLABLE XX") == :error
      assert Unicode.CharacterName.to_codepoint("HANGUL SYLLABLE GAX") == :error
      assert Unicode.CharacterName.to_codepoint("HANGUL SYLLABLE G") == :error
    end
  end

  describe "listed names are unaffected" do
    test "the common path still resolves from the name table" do
      assert Unicode.CharacterName.to_codepoint("LATIN SMALL LETTER A") == {:ok, ?a}
      assert Unicode.CharacterName.to_codepoint("bullet") == {:ok, 8226}
      assert Unicode.CharacterName.to_codepoint("Not A Real Name") == :error
    end

    test "individually listed algorithmic-looking names still resolve from the table" do
      # Nushu and Khitan have per-character rows in UnicodeData.txt despite their names looking
      # derived, so they must continue to come from the table.
      assert Unicode.CharacterName.to_codepoint("NUSHU CHARACTER-1B170") == {:ok, 0x1B170}

      assert Unicode.CharacterName.to_codepoint("KHITAN SMALL SCRIPT CHARACTER-18B00") ==
               {:ok, 0x18B00}
    end
  end
end
