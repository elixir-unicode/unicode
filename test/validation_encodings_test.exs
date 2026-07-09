defmodule Unicode.Validation.Encodings.Test do
  use ExUnit.Case, async: true

  # `Unicode.replace_invalid/3` delegates :utf8 to `String.replace_invalid/2`
  # on Elixir 1.16 and later, so these tests exercise the library's own
  # validation implementations directly through `Unicode.Validation`.

  describe "Unicode.Validation.replace_invalid/3 with :utf8" do
    test "returns a valid string unchanged" do
      assert Unicode.Validation.replace_invalid("déjà vu", :utf8) == "déjà vu"
    end

    test "replaces an invalid byte" do
      assert Unicode.Validation.replace_invalid(<<"foo", 0xFF, "bar">>, :utf8) == "foo�bar"
    end

    test "replaces a truncated sequence at end of input" do
      truncated = binary_slice(<<"é">>, 0, 1)
      assert Unicode.Validation.replace_invalid(<<"abc", truncated::binary>>, :utf8) == "abc�"
    end

    test "replaces surrogate codepoints encoded as utf-8" do
      surrogate = <<0xED, 0xA0, 0x80>>
      assert Unicode.Validation.replace_invalid(surrogate, :utf8) == "���"
    end

    test "replaces overlong encodings" do
      overlong_slash = <<0xC0, 0xAF>>
      assert Unicode.Validation.replace_invalid(overlong_slash, :utf8) == "��"
    end

    test "uses a custom replacement" do
      assert Unicode.Validation.replace_invalid(<<"a", 0xFF, "b">>, :utf8, "?") == "a?b"
    end

    test "empty binary returns empty string" do
      assert Unicode.Validation.replace_invalid(<<>>, :utf8) == ""
    end
  end

  describe "Unicode.Validation.replace_invalid/3 with :utf16" do
    test "returns a valid utf16 binary unchanged" do
      valid = :unicode.characters_to_binary("hello", :utf8, :utf16)
      assert Unicode.Validation.replace_invalid(valid, :utf16) == valid
    end

    test ":utf16be is an alias for :utf16" do
      valid = :unicode.characters_to_binary("hello", :utf8, :utf16)

      assert Unicode.Validation.replace_invalid(valid, :utf16be) ==
               Unicode.Validation.replace_invalid(valid, :utf16)
    end

    test "replaces an unpaired high surrogate" do
      unpaired = <<0xD8, 0x00>>
      replacement = :unicode.characters_to_binary("�", :utf8, :utf16)

      assert Unicode.Validation.replace_invalid(unpaired, :utf16) == replacement
    end

    test "valid utf16le binary is unchanged" do
      valid = :unicode.characters_to_binary("hello", :utf8, {:utf16, :little})
      assert Unicode.Validation.replace_invalid(valid, :utf16le) == valid
    end
  end

  describe "Unicode.Validation.replace_invalid/3 with :utf32" do
    test "returns a valid utf32 binary unchanged" do
      valid = :unicode.characters_to_binary("hello", :utf8, :utf32)
      assert Unicode.Validation.replace_invalid(valid, :utf32) == valid
    end

    test ":utf32be is an alias for :utf32" do
      valid = :unicode.characters_to_binary("hello", :utf8, :utf32)

      assert Unicode.Validation.replace_invalid(valid, :utf32be) ==
               Unicode.Validation.replace_invalid(valid, :utf32)
    end

    test "replaces an out of range codepoint" do
      invalid = <<0x00, 0x11, 0x00, 0x00>>
      replacement = :unicode.characters_to_binary("�", :utf8, :utf32)

      assert Unicode.Validation.replace_invalid(invalid, :utf32) == replacement
    end

    test "valid utf32le binary is unchanged" do
      valid = :unicode.characters_to_binary("hello", :utf8, {:utf32, :little})
      assert Unicode.Validation.replace_invalid(valid, :utf32le) == valid
    end
  end

  describe "Unicode.replace_invalid/3 dispatch" do
    test "dispatches :utf16 and :utf32 to the library implementation" do
      valid16 = :unicode.characters_to_binary("ok", :utf8, :utf16)
      valid32 = :unicode.characters_to_binary("ok", :utf8, :utf32)

      assert Unicode.replace_invalid(valid16, :utf16) == valid16
      assert Unicode.replace_invalid(valid32, :utf32) == valid32
    end

    test "raises for an unknown encoding" do
      encoding = String.to_atom("latin1")

      assert_raise FunctionClauseError, fn ->
        Unicode.replace_invalid("abc", encoding)
      end
    end
  end

  describe "trailing truncated code units" do
    test "utf16 input with a trailing odd byte is replaced" do
      valid = :unicode.characters_to_binary("a", :utf8, :utf16)
      replacement = :unicode.characters_to_binary("�", :utf8, :utf16)

      assert Unicode.Validation.UTF16.replace_invalid(<<valid::binary, 0x00>>) ==
               <<valid::binary, replacement::binary>>
    end

    test "utf16le input with a trailing odd byte is replaced" do
      valid = :unicode.characters_to_binary("a", :utf8, {:utf16, :little})
      replacement = :unicode.characters_to_binary("�", :utf8, {:utf16, :little})

      assert Unicode.Validation.UTF16LE.replace_invalid(<<valid::binary, 0x00>>) ==
               <<valid::binary, replacement::binary>>
    end

    test "utf32 input with trailing bytes is replaced" do
      valid = :unicode.characters_to_binary("a", :utf8, :utf32)
      replacement = :unicode.characters_to_binary("�", :utf8, :utf32)

      assert Unicode.Validation.UTF32.replace_invalid(<<valid::binary, 0x00, 0x00>>) ==
               <<valid::binary, replacement::binary>>
    end

    test "utf32le input with trailing bytes is replaced" do
      valid = :unicode.characters_to_binary("a", :utf8, {:utf32, :little})
      replacement = :unicode.characters_to_binary("�", :utf8, {:utf32, :little})

      assert Unicode.Validation.UTF32LE.replace_invalid(<<valid::binary, 0x00, 0x00>>) ==
               <<valid::binary, replacement::binary>>
    end

    test "custom replacements are transcoded to the target encoding" do
      question16 = :unicode.characters_to_binary("?", :utf8, :utf16)

      assert Unicode.Validation.UTF16.replace_invalid(<<0xD8, 0x00>>, "?") == question16
      assert Unicode.Validation.replace_invalid(<<0xD8, 0x00>>, :utf16, "?") == question16
    end

    test "an invalid replacement string raises ArgumentError" do
      assert_raise ArgumentError, ~r/replacement/, fn ->
        Unicode.Validation.replace_invalid(<<0xD8, 0x00>>, :utf16, <<0xFF>>)
      end
    end
  end

  describe "Unicode.Validation.UTF8.replace_invalid/2" do
    test "handles ascii fast path" do
      assert Unicode.Validation.UTF8.replace_invalid("plain ascii text") ==
               "plain ascii text"
    end

    test "handles mixed valid and invalid sequences" do
      input = <<"café", 0xC0, " au lait", 0xFF>>
      assert Unicode.Validation.UTF8.replace_invalid(input) == "café� au lait�"
    end

    test "handles every truncation of a four byte sequence" do
      four_bytes = <<"𝄞">>

      for keep <- 1..3 do
        truncated = binary_slice(four_bytes, 0, keep)
        result = Unicode.Validation.UTF8.replace_invalid(truncated)
        assert result == "�"
      end
    end

    test "replaces a three byte sequence truncated mid-stream" do
      # 0xE0 0xA0 are the first two bytes of a three byte sequence; the
      # following "X" is not a continuation byte so the sequence is invalid.
      assert Unicode.Validation.UTF8.replace_invalid(<<0xE0, 0xA0, "X">>) == "�X"
    end

    test "replaces a four byte sequence truncated after two bytes mid-stream" do
      assert Unicode.Validation.UTF8.replace_invalid(<<0xF0, 0x90, "X">>) == "�X"
    end

    test "replaces a four byte sequence truncated after three bytes mid-stream" do
      assert Unicode.Validation.UTF8.replace_invalid(<<0xF0, 0x90, 0x80, "X">>) == "�X"
    end
  end

  describe "invalid full code units in little-endian encodings" do
    test "utf16le replaces an unpaired surrogate code unit" do
      # High surrogate U+D800 encoded little-endian; not a valid scalar value.
      unpaired = <<0x00, 0xD8>>
      replacement = :unicode.characters_to_binary("�", :utf8, {:utf16, :little})

      assert Unicode.Validation.UTF16LE.replace_invalid(unpaired) == replacement
    end

    test "utf16le replaces an invalid code unit but keeps a following valid one" do
      unpaired = <<0x00, 0xD8>>
      valid = :unicode.characters_to_binary("a", :utf8, {:utf16, :little})
      replacement = :unicode.characters_to_binary("�", :utf8, {:utf16, :little})

      assert Unicode.Validation.UTF16LE.replace_invalid(<<unpaired::binary, valid::binary>>) ==
               <<replacement::binary, valid::binary>>
    end

    test "utf32le replaces an out of range code unit" do
      # U+110000 (out of range) encoded little-endian.
      invalid = <<0x00, 0x00, 0x11, 0x00>>
      replacement = :unicode.characters_to_binary("�", :utf8, {:utf32, :little})

      assert Unicode.Validation.UTF32LE.replace_invalid(invalid) == replacement
    end
  end
end
