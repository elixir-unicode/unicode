defmodule Unicode.CharacterName.Alias.Test do
  @moduledoc """
  Covers the `Name_Alias` property from `NameAliases.txt`.

  Aliases are the only names the control characters have, since their `Name` property is empty, and
  they carry the corrections for the names that were published with an error. `to_codepoint/1`
  resolves them after the `Name` property and the derivation rules, so a name always wins over an
  alias spelled the same way.
  """

  use ExUnit.Case, async: true

  alias Unicode.CharacterName

  describe "to_codepoint/1 with aliases" do
    test "resolves each of the five alias types" do
      # control, abbreviation, correction, alternate and figment respectively.
      assert CharacterName.to_codepoint("NULL") == {:ok, 0x0000}
      assert CharacterName.to_codepoint("LF") == {:ok, 0x000A}
      assert CharacterName.to_codepoint("LATIN CAPITAL LETTER GHA") == {:ok, 0x01A2}
      assert CharacterName.to_codepoint("BYTE ORDER MARK") == {:ok, 0xFEFF}
      assert CharacterName.to_codepoint("HIGH OCTET PRESET") == {:ok, 0x0081}
    end

    test "matches aliases as loosely as names" do
      for spelling <- ["BYTE ORDER MARK", "byte order mark", "Byte_Order_Mark", "byte-order-mark"] do
        assert CharacterName.to_codepoint(spelling) == {:ok, 0xFEFF}
      end
    end

    test "every alias in the data resolves to the codepoint it names" do
      failures =
        for {codepoint, aliases} <- Unicode.Utils.name_aliases(),
            {_type, name} <- aliases,
            CharacterName.to_codepoint(name) != {:ok, codepoint},
            do: {name, codepoint, CharacterName.to_codepoint(name)}

      assert failures == []
    end

    test "a Name is preferred over an alias with the same spelling" do
      # U+1F514 is named BELL; U+0007 is aliased ALERT and BEL, so nothing is shadowed today. The
      # assertion pins the precedence that decides the answer if a release ever introduces a clash.
      assert CharacterName.to_codepoint("BELL") == {:ok, 0x1F514}
      assert CharacterName.to_codepoint("ALERT") == {:ok, 0x0007}

      shadowed =
        for {codepoint, aliases} <- Unicode.Utils.name_aliases(),
            {_type, name} <- aliases,
            {:ok, resolved} = CharacterName.to_codepoint(name),
            resolved != codepoint,
            do: {name, codepoint, resolved}

      assert shadowed == []
    end

    test "an unknown name is still unknown" do
      assert CharacterName.to_codepoint("NOT AN ALIAS") == :error
    end
  end

  describe "aliases/1" do
    test "returns the aliases of a codepoint with their types, in file order" do
      assert CharacterName.aliases(0x0000) == [control: "NULL", abbreviation: "NUL"]

      assert CharacterName.aliases(0xFEFF) == [
               alternate: "BYTE ORDER MARK",
               abbreviation: "BOM",
               abbreviation: "ZWNBSP"
             ]
    end

    test "returns a correction for a character whose published name has an error" do
      assert CharacterName.aliases(0x01A2) == [correction: "LATIN CAPITAL LETTER GHA"]
      assert CharacterName.to_name(0x01A2) == {:ok, "LATIN CAPITAL LETTER OI"}
    end

    test "returns an empty list for a codepoint with no aliases" do
      assert CharacterName.aliases(?A) == []
      assert CharacterName.aliases(0x10FFFF) == []
    end

    test "every alias type in the data is one of the five UAX #44 types" do
      types =
        Unicode.Utils.name_aliases()
        |> Map.values()
        |> Enum.concat()
        |> Enum.map(&elem(&1, 0))
        |> Enum.uniq()
        |> Enum.sort()

      assert types == [:abbreviation, :alternate, :control, :correction, :figment]
    end

    test "raises on an out of range codepoint" do
      assert_raise FunctionClauseError, fn -> CharacterName.aliases(0x110000) end
    end
  end
end
