defmodule Unicode.Test do
  use ExUnit.Case

  doctest Unicode
  doctest Unicode.Property
  doctest Unicode.GeneralCategory
  doctest Unicode.Script
  doctest Unicode.Block
  doctest Unicode.Emoji
  doctest Unicode.CanonicalCombiningClass

  doctest Unicode.GraphemeClusterBreak
  doctest Unicode.LineBreak
  doctest Unicode.SentenceBreak
  doctest Unicode.WordBreak
  doctest Unicode.IndicConjunctBreak
  doctest Unicode.IndicSyllabicCategory
  doctest Unicode.BidiClass
  doctest Unicode.EastAsianWidth
  doctest Unicode.JoiningType
  doctest Unicode.Age
  doctest Unicode.NumericType
  doctest Unicode.DecompositionType
  doctest Unicode.HangulSyllableType
  doctest Unicode.IndicPositionalCategory
  doctest Unicode.VerticalOrientation
  doctest Unicode.JoiningGroup
  doctest Unicode.BidiPairedBracketType
  doctest Unicode.NumericValue
  doctest Unicode.NfcQuickCheck
  doctest Unicode.NfdQuickCheck
  doctest Unicode.NfkcQuickCheck
  doctest Unicode.NfkdQuickCheck
  doctest Unicode.RangeSearch
  doctest Unicode.Category.QuoteMarks
  doctest Unicode.Guards
end
