defmodule Unicode.Guards.Test do
  use ExUnit.Case, async: true

  import Unicode.Guards

  # Each guard is exercised through exactly one function clause so that the
  # (potentially large) guard expression is compiled once. Membership is then
  # asserted against many codepoints at runtime, which is cheap. This matters
  # for the graphic-set guards (`is_graph`, `is_print`, `is_visible`) whose
  # ~680-range guard is expanded at each call site.

  defp upper?(codepoint) when is_upper(codepoint), do: true
  defp upper?(_), do: false

  defp lower?(codepoint) when is_lower(codepoint), do: true
  defp lower?(_), do: false

  defp digit?(codepoint) when is_digit(codepoint), do: true
  defp digit?(_), do: false

  defp currency?(codepoint) when is_currency_symbol(codepoint), do: true
  defp currency?(_), do: false

  defp whitespace?(codepoint) when is_whitespace(codepoint), do: true
  defp whitespace?(_), do: false

  defp separator?(codepoint) when is_separator(codepoint), do: true
  defp separator?(_), do: false

  defp blank?(codepoint) when is_blank(codepoint), do: true
  defp blank?(_), do: false

  defp quote_mark?(codepoint) when is_quote_mark(codepoint), do: true
  defp quote_mark?(_), do: false

  defp printable?(codepoint) when is_printable(codepoint), do: true
  defp printable?(_), do: false

  defp graph?(codepoint) when is_graph(codepoint), do: true
  defp graph?(_), do: false

  defp print?(codepoint) when is_print(codepoint), do: true
  defp print?(_), do: false

  defp visible?(codepoint) when is_visible(codepoint), do: true
  defp visible?(_), do: false

  describe "letter guards" do
    test "is_upper matches upper case letters across scripts" do
      assert upper?(?A)
      assert upper?(?Ω)
      refute upper?(?a)
      refute upper?(?5)
    end

    test "is_lower matches lower case letters across scripts" do
      assert lower?(?a)
      assert lower?(?ω)
      refute lower?(?A)
    end
  end

  describe "digit and symbol guards" do
    test "is_digit matches decimal digits across scripts" do
      assert digit?(?0)
      assert digit?(?9)
      # Arabic-Indic digit zero
      assert digit?(0x0660)
      refute digit?(?a)
    end

    test "is_currency_symbol matches currency symbols" do
      assert currency?(?$)
      assert currency?(0x00A3)
      refute currency?(?A)
    end
  end

  describe "whitespace, separator and blank guards" do
    test "is_whitespace matches Zs plus 0x09..0x0d" do
      assert whitespace?(?\s)
      assert whitespace?(?\t)
      assert whitespace?(?\n)
      assert whitespace?(0x00A0)
      refute whitespace?(?A)
    end

    test "is_separator matches only Zs" do
      assert separator?(?\s)
      assert separator?(0x00A0)
      refute separator?(?\t)
    end

    test "is_blank matches Zs plus tab" do
      assert blank?(?\t)
      assert blank?(?\s)
      refute blank?(?\n)
    end
  end

  describe "quotation mark guards" do
    test "is_quote_mark matches quotation marks" do
      assert quote_mark?(?")
      assert quote_mark?(?')
      refute quote_mark?(?A)
    end
  end

  describe "graphic and printing guards" do
    test "is_printable matches printable characters" do
      assert printable?(?A)
      assert printable?(?\n)
      assert printable?(0x0627)
      refute printable?(0x0000)
    end

    test "is_graph matches visible graphic characters" do
      assert graph?(?A)
      assert graph?(?~)
      assert graph?(0x4E00)
      refute graph?(?\s)
      refute graph?(0x0000)
    end

    test "is_print matches graphic characters and spaces" do
      assert print?(?A)
      assert print?(?\s)
      assert print?(0x00A0)
      refute print?(0x0000)
    end

    test "is_visible matches the graphic set" do
      assert visible?(?A)
      refute visible?(?\s)
    end
  end

  describe "guard composition and non-integer input" do
    # Small-set guards are real defguards, so they compose in another guard.
    # (Composing the large letter guards would exceed the BEAM guard limit.)
    defguardp is_space_or_digit(codepoint)
              when is_digit(codepoint) or is_whitespace(codepoint)

    test "small defguards compose inside another defguard" do
      assert match?(codepoint when is_space_or_digit(codepoint), ?5)
      assert match?(codepoint when is_space_or_digit(codepoint), ?\s)
      refute match?(codepoint when is_space_or_digit(codepoint), ?A)
    end

    test "guards reject non-integer input via is_integer/1" do
      refute upper?("A")
      refute digit?(:not_a_codepoint)
      refute graph?(nil)
    end
  end
end
