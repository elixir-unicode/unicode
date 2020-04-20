defmodule Unicode.DerivedCategory.Printable do
  @moduledoc false

  # iex> {:ok, list, _, _, _, _} = Unicode.Set.parse "[[\u0020-\u007e][\u0100-\u01FF][\u00A0..\uD7FF][\uE000-\uFFFD][\u{10000}-\u{10FFFF}]\n\r\t\v\b\f\e\d\a]"
  # iex> Unicode.Set.Operation.expand list

  @printable [
    {7, 13},
    {27, 27},
    {32, 127},
    {160, 160},
    {256, 511},
    {55295, 55295},
    {57344, 65533},
    {65536, 1114111}
  ]

  @doc false
  def printable do
    @printable
  end
end