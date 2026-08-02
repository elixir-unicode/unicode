defmodule Unicode.LinkProperties.Test do
  @moduledoc """
  Covers the three UTS #58 link properties.

  These are not UCD properties — they ship in their own `linkification/` tree and are absent from
  `PropertyAliases.txt` — so they are wired explicitly rather than derived, and the property
  coverage test in `property_modules_test.exs` neither covers nor constrains them.
  """

  use ExUnit.Case, async: true

  describe "Link_Term" do
    test "the documented values are present" do
      assert Enum.sort(Unicode.LinkTerm.known_link_terms()) == [:close, :include, :open, :soft]
    end

    test "representative codepoints take their documented value" do
      assert Unicode.LinkTerm.link_term(?a) == :include
      assert Unicode.LinkTerm.link_term(?/) == :include
      assert Unicode.LinkTerm.link_term(?.) == :soft
      assert Unicode.LinkTerm.link_term(?!) == :soft
      assert Unicode.LinkTerm.link_term(?() == :open
      assert Unicode.LinkTerm.link_term(?)) == :close
    end

    test "unlisted codepoints default to hard" do
      # `Hard` is the `@missing` value, so it is absent from the data entirely and must come from
      # the lookup default rather than a range.
      assert Unicode.LinkTerm.link_term(?\s) == :hard
      assert Unicode.LinkTerm.link_term(?\n) == :hard
      assert Unicode.LinkTerm.link_term(0x0378) == :hard
      refute :hard in Unicode.LinkTerm.known_link_terms()
    end

    test "fetch, get and count behave like the other property modules" do
      assert {:ok, ranges} = Unicode.LinkTerm.fetch(:open)
      assert Unicode.LinkTerm.fetch("open") == {:ok, ranges}
      assert is_list(Unicode.LinkTerm.get(:open))
      assert Unicode.LinkTerm.get(:invalid) == nil
      assert Unicode.LinkTerm.fetch(:invalid) == :error
      assert Unicode.LinkTerm.count(:open) > 0
    end

    test "open and close have the same number of codepoints as there are bracket pairs" do
      # Every closing bracket pairs with exactly one opening bracket, so the three must agree.
      assert Unicode.LinkTerm.count(:open) == Unicode.LinkTerm.count(:close)
      assert Unicode.LinkTerm.count(:close) == Unicode.LinkBracket.count()
    end

    test "a string returns the distinct values of its codepoints" do
      assert Unicode.LinkTerm.link_term("a.") == [:include, :soft]
    end

    test "raises on an out of range codepoint" do
      assert_raise FunctionClauseError, fn -> Unicode.LinkTerm.link_term(0x110000) end
    end

    test "resolves through the generic property API" do
      assert Unicode.fetch_property("link_term") == {:ok, Unicode.LinkTerm}
      assert Unicode.fetch_property("linkterm") == {:ok, Unicode.LinkTerm}
    end

    test "the binary and codepoint-valued link properties are not wired as value servers" do
      # `Unicode.fetch_property/1` callers invoke `module.fetch(value)`. `Link_Email` has no values
      # and `Link_Bracket.fetch/1` takes a codepoint, so serving them here would hand callers a
      # module whose `fetch/1` means something else entirely.
      assert Unicode.fetch_property("link_email") == :error
      assert Unicode.fetch_property("link_bracket") == :error
    end
  end

  describe "Link_Email" do
    test "recognises valid local part characters" do
      assert Unicode.LinkEmail.link_email?(?a)
      assert Unicode.LinkEmail.link_email?(?0)
      assert Unicode.LinkEmail.link_email?(?.)
      assert Unicode.LinkEmail.link_email?(?+)
    end

    test "rejects characters that cannot appear in a local part" do
      assert Unicode.LinkEmail.link_email?(?@) == false
      assert Unicode.LinkEmail.link_email?(?\s) == false
      assert Unicode.LinkEmail.link_email?(?\n) == false
    end

    test "a string is valid only when every codepoint is" do
      assert Unicode.LinkEmail.link_email?("first.last")
      assert Unicode.LinkEmail.link_email?("user+tag")
      assert Unicode.LinkEmail.link_email?("has space") == false
      assert Unicode.LinkEmail.link_email?("user@host") == false
    end

    test "includes non-ASCII, since UTS #58 covers internationalised addresses" do
      assert Unicode.LinkEmail.link_email?(?é)
      assert Unicode.LinkEmail.link_email?("张伟")
    end

    test "count and ranges agree" do
      total = Enum.reduce(Unicode.LinkEmail.ranges(), 0, fn {f, t}, acc -> acc + t - f + 1 end)
      assert Unicode.LinkEmail.count() == total
    end

    test "ranges are sorted and non-overlapping" do
      Enum.reduce(Unicode.LinkEmail.ranges(), -1, fn {first, last}, previous ->
        assert first > previous
        assert last >= first
        last
      end)
    end

    test "raises on an out of range codepoint" do
      assert_raise FunctionClauseError, fn -> Unicode.LinkEmail.link_email?(0x110000) end
    end
  end

  describe "Link_Bracket" do
    test "maps closing brackets to their opening bracket" do
      assert Unicode.LinkBracket.get(?)) == ?(
      assert Unicode.LinkBracket.get(?]) == ?[
      assert Unicode.LinkBracket.get(?}) == ?{
      assert Unicode.LinkBracket.get(?>) == ?<
    end

    test "returns nothing for a non-closing character" do
      assert Unicode.LinkBracket.get(?a) == nil
      assert Unicode.LinkBracket.get(?() == nil
      assert Unicode.LinkBracket.fetch(?a) == :error
    end

    test "pair?/2 checks a specific pairing" do
      assert Unicode.LinkBracket.pair?(?), ?()
      refute Unicode.LinkBracket.pair?(?), ?[)
      refute Unicode.LinkBracket.pair?(?a, ?()
    end

    test "every key is Link_Term=Close and every value is Link_Term=Open" do
      # The two properties must agree, or the termination algorithm would push a bracket it can
      # never match, or match one it never pushed.
      for {closing, opening} <- Unicode.LinkBracket.brackets() do
        assert Unicode.LinkTerm.link_term(closing) == :close
        assert Unicode.LinkTerm.link_term(opening) == :open
      end
    end

    test "covers non-ASCII brackets, which ASCII-only handling does not" do
      # 61 of the 65 pairs are outside ASCII — the whole point of using the property rather than a
      # hardcoded `()[]{}<>` set.
      assert Unicode.LinkBracket.get(0x2046) == 0x2045
      assert Unicode.LinkBracket.get(0x207E) == 0x207D

      non_ascii = Enum.count(Unicode.LinkBracket.brackets(), fn {closing, _} -> closing > 127 end)

      assert non_ascii == 61
      assert Unicode.LinkBracket.count() == 65
    end

    test "raises on an out of range codepoint" do
      assert_raise FunctionClauseError, fn -> Unicode.LinkBracket.get(0x110000) end
    end
  end
end
