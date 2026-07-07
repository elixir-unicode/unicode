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

  describe "static derived category tables" do
    test "assigned excludes unassigned codepoints" do
      ranges = Unicode.DerivedCategory.Assigned.assigned()

      assert Enum.any?(ranges, fn {first, last} -> ?A in first..last end)
    end

    test "graph excludes control characters" do
      ranges = Unicode.DerivedCategory.Graph.graph()

      assert Enum.any?(ranges, fn {first, last} -> ?A in first..last end)
      refute Enum.any?(ranges, fn {first, last} -> 0x0000 in first..last end)
    end

    test "printable matches Elixir's definition" do
      ranges = Unicode.DerivedCategory.Printable.printable()

      assert Enum.any?(ranges, fn {first, last} -> ?A in first..last end)
      assert Enum.any?(ranges, fn {first, last} -> ?\n in first..last end)
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
