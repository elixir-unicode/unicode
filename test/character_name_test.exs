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

  test "returns :error for unknown names and for algorithmic / control names" do
    assert CharacterName.to_codepoint("Not A Real Name") == :error
    # Control characters have no formal Name property (only Name_Alias, which is
    # not loaded), and CJK ideographs are algorithmic, so both are absent.
    assert CharacterName.to_codepoint("NULL") == :error
    assert CharacterName.to_codepoint("CJK UNIFIED IDEOGRAPH-4E00") == :error
  end

  test "the table is non-trivial in size" do
    assert CharacterName.count() > 30_000
  end
end
