defmodule Unicode.Category.QuoteMarks do
  @moduledoc """
  Functions to return codepoints that form quotation marks. These
  marks are taken from the [Wikipedia definition](https://en.wikipedia.org/wiki/Quotation_mark)
  which is more expansive than the Unicode categories [Pi](https://www.compart.com/en/unicode/category/Pi)
  and [Pf](https://www.compart.com/en/unicode/category/Pf).

  The full list of codepoints considered to be quote marks is tabled here.

  ## Unicode code point table

  These are codepoints noted in the Unicode character data base with the flag
  `quotation mark = yes`. These are equivalent to the unicode sets `Pi` and `Pf`.

  | Glyph | Code | Unicode name | HTML | Comments |
  | ----- | ---- | ------------ | ---- | -------- |
  | \u0022 | U+0022 | Quotation mark | &amp;quot; | Typewriter ("programmer's") quote, ambidextrous. Also known as "double quote".
  | \u0027 | U+0027 | Apostrophe | &amp;#39; | Typewriter ("programmer's") straight single quote, ambidextrous
  | \u00AB | U+00AB | Left-pointing double angle quotation mark | &amp;laquo; | Double angle quote
  | \u00BB | U+00BB | Right-pointing double angle quotation mark | &amp;raquo; | Double angle quote, right
  | \u2018 | U+2018 | Left single quotation mark | &amp;lsquo; | Single curved quote, left. Also known as ''inverted [[comma]]'' or ''turned comma''
  | \u2019 | U+2019 | Right single quotation mark | &amp;rsquo; | Single curved quote, right
  | \u201A | U+201A | Single low-9 quotation mark | &amp;sbquo; | Low single curved quote, left
  | \u201B | U+201B | Single high-reversed-9 quotation mark | &amp;#8219; | also called ''single reversed comma'', ''quotation mark''
  | \u201C | U+201C | Left double quotation mark | &amp;ldquo; | Double curved quote, left
  | \u201D | U+201D | Right double quotation mark | &amp;rdquo; | Double curved quote, right
  | \u201E | U+201E | Double low-9 quotation mark | &amp;bdquo; | Low double curved quote, left
  | \u201F | U+201F | Double high-reversed-9 quotation mark | &amp;#8223; | also called ''double reversed comma'', ''quotation mark''
  | \u2039 | U+2039 | Single left-pointing angle quotation mark | &amp;lsaquo; | Single angle quote, left
  | \u203A | U+203A | Single right-pointing angle quotation mark | &amp;rsaquo; | Single angle quote, right
  | \u2E42 | U+2E42 | Double low-reversed-9 quotation mark | &amp;#11842; | also called ''double low reversed comma'', ''quotation mark''

  ### Quotation marks in dingbats

  | Glyph | Code | Unicode name | HTML | Comments |
  | ----- | ---- | ------------ | ---- | -------- |
  | \u275B  | U+275B  | Heavy single turned comma quotation mark ornament | &amp;#10075; | <code>Quotation Mark=No</code>
  | \u275C  | U+275C  | Heavy single comma quotation mark ornament | &amp;#10076; | <code>Quotation Mark=No</code>
  | \u275D  | U+275D  | Heavy double turned comma quotation mark ornament | &amp;#10077; | <code>Quotation Mark=No</code>
  | \u275E  | U+275E  | Heavy double comma quotation mark ornament | &amp;#10078; | <code>Quotation Mark=No</code>
  | \u{1F676} | U+1F676 | SANS-SERIF HEAVY DOUBLE TURNED COMMA QUOTATION MARK ORNAMENT | &amp;#128630; | <code>Quotation Mark=No</code>
  | \u{1F677} | U+1F677 | SANS-SERIF HEAVY DOUBLE COMMA QUOTATION MARK ORNAMENT | &amp;#128631; | <code>Quotation Mark=No</code>
  | \u{1F678} | U+1F678 | SANS-SERIF HEAVY LOW DOUBLE COMMA QUOTATION MARK ORNAMENT | &amp;#128632; | <code>Quotation Mark=No</code>

  ### Quotation marks in Braille Patterns

  | Glyph | Code | Unicode name | HTML | Comments |
  | ----- | ---- | ------------ | ---- | -------- |
  | \u2826 | U+2826 | Braille pattern dots-236 | &amp;#10292; | Braille double closing quotation mark; <code>Quotation Mark=No</code>
  | \u2834 | U+2834 | Braille pattern dots-356 | &amp;#10278; | Braille double opening quotation mark; <code>Quotation Mark=No</code>

  ### Quotation marks in Chinese, Japanese, and Korean

  | Glyph | Code | Unicode name | HTML | Comments |
  | ----- | ---- | ------------ | ---- | -------- |
  | \u300C | U+300C | Left corner bracket | &amp;#12300; | CJK
  | \u300D | U+300D | Right corner bracket | &amp;#12301; | CJK
  | \u300E | U+300E | Left white corner bracket | &amp;#12302; | CJK
  | \u300F | U+300F | Right white corner bracket | &amp;#12303; | CJK
  | \u301D | U+301D | REVERSED DOUBLE PRIME QUOTATION MARK | &amp;#12317; | CJK
  | \u301E | U+301E | DOUBLE PRIME QUOTATION MARK | &amp;#12318; | CJK
  | \u301F | U+301F | LOW DOUBLE PRIME QUOTATION MARK | &amp;#12319; | CJK

  ### Alternate encodings

  | Glyph | Code | Unicode name | HTML | Comments |
  | ----- | ---- | ------------ | ---- | -------- |
  | \uFE41 | U+FE41 | PRESENTATION FORM FOR VERTICAL LEFT CORNER BRACKET | &amp;#65089; | CJK Compatibility, preferred use: U+300C
  | \uFE42 | U+FE42 | PRESENTATION FORM FOR VERTICAL RIGHT CORNER BRACKET | &amp;#65090; | CJK Compatibility, preferred use: U+300D
  | \uFE43 | U+FE43 | PRESENTATION FORM FOR VERTICAL LEFT WHITE CORNER BRACKET | &amp;#65091; | CJK Compatibility, preferred use: U+300E
  | \uFE44 | U+FE44 | PRESENTATION FORM FOR VERTICAL RIGHT WHITE CORNER BRACKET | &amp;#65092; | CJK Compatibility, preferred use: U+300F
  | \uFF02 | U+FF02 | FULLWIDTH QUOTATION MARK | &amp;#65282; | Halfwidth and Fullwidth Forms, corresponds with U+0022
  | \uFF07 | U+FF07 | FULLWIDTH apostrophe | &amp;#65287; | Halfwidth and Fullwidth Forms, corresponds with U+0027
  | \uFF62 | U+FF62 | HALFWIDTH LEFT CORNER BRACKET | &amp;#65378; | Halfwidth and Fullwidth Forms, corresponds with U+300C
  | \uFF63 | U+FF63 | HALFWIDTH right CORNER BRACKET | &amp;#65379; | Halfwidth and Fullwidth Forms, corresponds with U+300D
  """

  @doc """
  Return a list of codepoints representing quote marks
  typically used on the left (for LTR languages)
  """
  def quote_marks_left do
    [
      0x00AB,
      0x2018,
      0x201A,
      0x201C,
      0x201E,
      0x2039,
      0x2826,
      0x300C,
      0x300E,
      0xFE41,
      0xFE43,
      0xFF62,
      0x1F676,
      0x275D,
      0x275B
    ]
  end

  @doc """
  Return a list of codepoints representing quote marks
  typically used on the right (for LTR languages)
  """
  def quote_marks_right do
    [
      0x00BB,
      0x2019,
      0x201B,
      0x201D,
      0x203A,
      0x2834,
      0x300D,
      0x300F,
      0xFE42,
      0xFE44,
      0xFF63,
      0x1F677,
      0x275C,
      0x275E
    ]
  end

  @doc """
  Return a list of codepoints representing quote marks
  typically used on the left or right (for LTR languages)
  """
  def quote_marks_ambidextrous do
    [0x0022, 0x0027, 0x201F, 0x2E42, 0x301D, 0x301E, 0x301F, 0xFF02, 0xFF07, 0x1F678]
  end

  @doc """
  Return a list of codepoints representing quote marks
  typically used in Braille
  """
  def quote_marks_braille do
    [0x2826, 0x2834]
  end

  @doc """
  Return a list of codepoints representing quote marks
  understood to be single marks
  """
  def quote_marks_single do
    [
      0x0027,
      0x2018,
      0x2019,
      0x201A,
      0x201B,
      0x2039,
      0x203A,
      0x275B,
      0x275C,
      0x300C,
      0x300D,
      0x300E,
      0x300F,
      0xFE41,
      0xFE42,
      0xFE43,
      0xFE44,
      0xFF07,
      0xFF62,
      0xFF63
    ]
  end

  @doc """
  Return a list of codepoints representing quote marks
  understood to be double marks
  """
  def quote_marks_double do
    [
      0x0022,
      0x00AB,
      0x00BB,
      0x201C,
      0x201D,
      0x201E,
      0x201F,
      0x2E42,
      0x275D,
      0x275E,
      0x1F676,
      0x1F677,
      0x1F678,
      0x2826,
      0x2834,
      0x301D,
      0x301E,
      0x301F,
      0xFF02
    ]
  end

  @doc """
  Return a list of codepoints representing all
  quote marks.
  """
  def all_quote_marks do
    [
      quote_marks_left(),
      quote_marks_right(),
      quote_marks_ambidextrous(),
      quote_marks_single(),
      quote_marks_double()
    ]
    |> List.flatten()
    |> Enum.uniq()
  end
end
