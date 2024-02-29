defmodule Unicode.Property.Test do
  use ExUnit.Case, async: true

  test "Emojis have all their properties" do
    assert Unicode.properties(128721) ==
      [:emoji, :emoji_presentation, :extended_pictographic, :grapheme_base]

    assert Unicode.properties("🛑") ==
      [[:emoji, :emoji_presentation, :extended_pictographic, :grapheme_base]]
  end

end