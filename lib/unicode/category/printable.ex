defmodule Unicode.DerivedCategory.Printable do
  @moduledoc false

  # The definition of `printable` matches `String.printable?/1`. A more
  # Unicode-relevant version would be the derived category `:Graphic:`
  # (available here as `:Graph`).
  #
  # The set is the printable ASCII range plus the whitespace and escape
  # control characters Elixir treats as printable, together with the
  # assignable BMP and supplementary ranges:
  #
  # * `0x07..0x0D` (\a \b \t \n \v \f \r) and `0x1B` (\e)
  # * `0x20..0x7F` (printable ASCII plus \d)
  # * `0xA0..0xD7FF` (BMP up to the surrogate area)
  # * `0xE000..0xFFFD` (BMP after the surrogate area)
  # * `0x10000..0x10FFFF` (supplementary planes)

  @printable [
    {0x07, 0x0D},
    {0x1B, 0x1B},
    {0x20, 0x7F},
    {0xA0, 0xD7FF},
    {0xE000, 0xFFFD},
    {0x10000, 0x10FFFF}
  ]

  @doc false
  def printable do
    @printable
  end
end
