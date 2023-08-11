defmodule Unicode.Utils.Test do
  use ExUnit.Case

  test "compact tuple ranges" do
    list = [
      {32, 32},
      {33, 35},
      {36, 36},
      {37, 39},
      {40, 40},
      {41, 41},
      {42, 42},
      {43, 43},
      {44, 44},
      {45, 45},
      {46, 47},
      {48, 57}
    ]

    assert Unicode.Utils.compact_ranges(list) == [{32, 57}]

    assert Unicode.Utils.compact_ranges([{1, 2}, {3, 4}, {6, 7}, {9, 10}]) ==
             [{1, 4}, {6, 7}, {9, 10}]

    assert Unicode.Utils.compact_ranges([{1, 2}, {3, 4}, {6, 7}, {9, 10}, {11, 20}]) ==
             [{1, 4}, {6, 7}, {9, 20}]
  end
end
