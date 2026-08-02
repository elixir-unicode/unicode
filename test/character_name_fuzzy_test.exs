defmodule Unicode.CharacterName.Fuzzy.Test do
  @moduledoc """
  Covers the `:fuzzy` option of `Unicode.CharacterName.to_codepoint/2`.

  A fuzzy search scans every name, so these tests are deliberately few. The property that matters is
  that a match is returned only when it is unambiguous.
  """

  use ExUnit.Case, async: true

  alias Unicode.CharacterName

  describe "resolving a misspelled name" do
    test "a single character typo resolves" do
      assert CharacterName.to_codepoint("LATIN SMALL LETER A", fuzzy: true) == {:ok, ?a}
      assert CharacterName.to_codepoint("GRINING FACE", fuzzy: true) == {:ok, 0x1F600}
      assert CharacterName.to_codepoint("SNOWMAM", fuzzy: true) == {:ok, 0x2603}
    end

    test "an explicit threshold is honoured" do
      assert CharacterName.to_codepoint("GRINING FACE", fuzzy: 0.9) == {:ok, 0x1F600}

      # The same query cannot clear a threshold set above its actual distance.
      assert CharacterName.to_codepoint("GRINING FACE", fuzzy: 0.999) == :error
    end

    test "a threshold of 1.0 admits only an exact normalized match" do
      assert CharacterName.to_codepoint("LATIN SMALL LETTER A", fuzzy: 1.0) == {:ok, ?a}
      assert CharacterName.to_codepoint("LATIN SMALL LETER A", fuzzy: 1.0) == :error
    end
  end

  describe "ambiguity is refused" do
    test "a query equidistant from several names returns :error" do
      # `LATIN SMALL LETTER` is exactly as close to `LATIN SMALL LETTER A` as to every other
      # single-letter Latin name, so there is no single answer to give.
      assert CharacterName.to_codepoint("LATIN SMALL LETTER", fuzzy: true) == :error
      assert CharacterName.to_codepoint("TIBETAN LETTER", fuzzy: true) == :error
    end

    test "a query close to nothing returns :error" do
      assert CharacterName.to_codepoint("XXXXXXXXXXXXXXXX", fuzzy: true) == :error
      assert CharacterName.to_codepoint("", fuzzy: true) == :error
    end
  end

  describe "the option itself" do
    test "fuzzy matching is off by default" do
      assert CharacterName.to_codepoint("LATIN SMALL LETER A") == :error
      assert CharacterName.to_codepoint("LATIN SMALL LETER A", []) == :error
      assert CharacterName.to_codepoint("LATIN SMALL LETER A", fuzzy: false) == :error
    end

    test "an exact match never triggers a fuzzy scan" do
      # Not a timing assertion, but the exact result must win regardless of the threshold given.
      assert CharacterName.to_codepoint("LATIN SMALL LETTER A", fuzzy: 0.1) == {:ok, ?a}
    end

    test "a derived name still resolves exactly when fuzzy is enabled" do
      assert CharacterName.to_codepoint("CJK UNIFIED IDEOGRAPH-4E00", fuzzy: true) ==
               {:ok, 0x4E00}
    end

    test "derived names are not fuzzy matched" do
      # A near miss on the hexadecimal part names a different character, so approximating it would
      # be actively wrong rather than merely unhelpful.
      assert CharacterName.to_codepoint("CJK UNIFIED IDEOGRAPH-4E0", fuzzy: true) == :error
    end

    test "a malformed option returns :error rather than raising" do
      for fuzzy <- ["banana", 42, -0.5, 1.5, nil, :yes] do
        assert CharacterName.to_codepoint("LATIN SMALL LETER A", fuzzy: fuzzy) == :error
      end
    end
  end

  describe "the length prefilter is sound" do
    @threshold 0.8

    test "no name that clears the threshold can be excluded by the length bound" do
      # Fuzzy search skips names whose lengths are too far apart to reach the threshold, using the
      # bound `jaro <= (2 + shorter / longer) / 3`. If that bound were ever wrong — or too tight
      # against floating point rounding — a real match would be pruned and the search would return
      # the wrong answer, or a spurious one where a tie was discarded.
      names =
        Unicode.Utils.unicode()
        |> Enum.flat_map(fn
          {_codepoint, ["<" <> _label | _rest]} -> []
          {_codepoint, [name | _rest]} -> [Unicode.Utils.downcase_and_remove_whitespace(name)]
        end)

      for query <- ["latinsmallletter", "grinningface"] do
        violations =
          Enum.filter(names, fn name ->
            shorter = min(byte_size(query), byte_size(name))
            longer = max(byte_size(query), byte_size(name))

            String.jaro_distance(query, name) >= @threshold and
              shorter / longer < 3 * @threshold - 2 - 1.0e-9
          end)

        assert violations == []
      end
    end
  end
end
