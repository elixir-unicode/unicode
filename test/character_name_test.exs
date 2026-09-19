defmodule Unicode.CharacterName.Test do
  use ExUnit.Case, async: true
  doctest Unicode.CharacterName

  alias Unicode.CharacterName

  test "resolves character names loosely (case/whitespace/_/- insensitive)" do
    assert CharacterName.to_codepoint("LATIN SMALL LETTER A") == {:ok, ?a}
    assert CharacterName.to_codepoint("latin small letter a") == {:ok, ?a}
    assert CharacterName.to_codepoint("latin_small_letter_a") == {:ok, ?a}
    assert CharacterName.to_codepoint("LatinSmallLetterA") == {:ok, ?a}
  end

  test "resolves a range of names across the codespace" do
    assert CharacterName.to_codepoint("BULLET") == {:ok, 0x2022}
    assert CharacterName.to_codepoint("GREEK SMALL LETTER ALPHA") == {:ok, 0x03B1}
    assert CharacterName.to_codepoint("RIGHTWARDS ARROW") == {:ok, 0x2192}
    assert CharacterName.to_codepoint("SNOWMAN") == {:ok, 0x2603}
  end

  test "returns :error for an unknown name" do
    assert CharacterName.to_codepoint("Not A Real Name") == :error
  end

  test "resolves a control character through its Name_Alias" do
    # Control characters have no formal Name property, only Name_Alias. See
    # character_name_alias_test.exs for the alias types and their precedence.
    assert CharacterName.to_codepoint("NULL") == {:ok, 0x0000}
  end

  test "resolves algorithmically derived names" do
    # These are absent from the name table — they are `<..., First>`/`<..., Last>` ranges in
    # UnicodeData.txt — and are derived by rule instead. See character_name_derived_test.exs.
    assert CharacterName.to_codepoint("CJK UNIFIED IDEOGRAPH-4E00") == {:ok, 0x4E00}
    assert CharacterName.to_codepoint("HANGUL SYLLABLE GA") == {:ok, 0xAC00}
  end

  test "the table is non-trivial in size" do
    assert CharacterName.count() > 30_000
  end
end
