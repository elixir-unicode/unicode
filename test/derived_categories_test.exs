defmodule Unicode.DerivedCategories.Test do
  use ExUnit.Case, async: true

  describe "Unicode.Category.QuoteMarks" do
    test "quote mark lists contain the expected codepoints" do
      assert ?" in Unicode.Category.QuoteMarks.all_quote_marks()
      assert ?' in Unicode.Category.QuoteMarks.quote_marks_single()
      assert ?" in Unicode.Category.QuoteMarks.quote_marks_double()
      assert 0x00AB in Unicode.Category.QuoteMarks.quote_marks_left()
      assert 0x00BB in Unicode.Category.QuoteMarks.quote_marks_right()
      assert ?" in Unicode.Category.QuoteMarks.quote_marks_ambidextrous()
      assert is_list(Unicode.Category.QuoteMarks.quote_marks_braille())
    end
  end

  describe "computed derived categories" do
    defp count(ranges), do: Enum.reduce(ranges, 0, fn {a, b}, acc -> acc + b - a + 1 end)

    defp member?(ranges, codepoint), do: Enum.any?(ranges, fn {a, b} -> codepoint in a..b end)

    test "assigned is the complement of the unassigned category" do
      assigned = Unicode.GeneralCategory.get(:Assigned)
      unassigned = Unicode.GeneralCategory.get(:Cn)

      # Every assigned codepoint is a member of exactly one concrete category.
      assert member?(assigned, ?A)
      refute member?(unassigned, ?A)
      # Assigned and unassigned partition the whole codespace.
      assert count(assigned) + count(unassigned) == 0x10FFFF + 1
    end

    test "graph excludes whitespace, control and surrogate characters" do
      graph = Unicode.GeneralCategory.get(:Graph)

      assert member?(graph, ?A)
      refute member?(graph, 0x0000)
      refute member?(graph, ?\s)
      # Newly-assigned BMP characters are included (regression guard for the
      # previously-stale static table).
      assert member?(graph, 0x0870)
    end

    test "visible is identical to graph" do
      assert Unicode.GeneralCategory.get(:Visible) == Unicode.GeneralCategory.get(:Graph)
    end

    test "printable matches String.printable?/1" do
      printable = Unicode.GeneralCategory.get(:Printable)

      for codepoint <- [?A, ?\n, 0xA0, 0x0627, 0x4E00, 0xAC00, 0x1F600] do
        assert member?(printable, codepoint) == String.printable?(<<codepoint::utf8>>),
               "printable mismatch for #{inspect(codepoint)}"
      end

      refute member?(printable, 0x0000)
    end
  end

  describe "fallback UTF-8 validator agrees with the standard library" do
    alias Unicode.Validation.UTF8.Test.Helpers

    test "on random mixtures of valid and invalid sequences" do
      for _iteration <- 1..500 do
        {bytes, _expected} = Helpers.random_sequences(8)

        assert Unicode.Validation.UTF8.replace_invalid(bytes) ==
                 String.replace_invalid(bytes)
      end
    end

    test "on random valid strings" do
      for _iteration <- 1..200 do
        bytes = Helpers.random_valid_sequences(16)

        assert Unicode.Validation.UTF8.replace_invalid(bytes) == bytes
      end
    end
  end
end
