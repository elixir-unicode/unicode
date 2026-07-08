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
  doctest Unicode.RangeSearch
  doctest Unicode.Category.QuoteMarks
  doctest Unicode.Guards
end
