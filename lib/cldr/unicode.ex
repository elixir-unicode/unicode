defmodule Cldr.Unicode do
  alias Cldr.Unicode

  @doc false
  @data_dir Path.join(__DIR__, "/../../data") |> Path.expand()
  def data_dir do
    @data_dir
  end

  @doc """
  Returns the version of Unicode in
  `Cldr.Unicode`.

  """
  def version do
    {12, 0, 0}
  end

  defdelegate category(codepoint_or_string), to: Unicode.Category, as: :category
  defdelegate script(codepoint_or_string), to: Unicode.Script, as: :script
  defdelegate block(codepoint_or_string), to: Unicode.Block, as: :block
  defdelegate properties(codepoint_or_string), to: Unicode.Property, as: :properties

  defdelegate alphabetic?(codepoint_or_string), to: Unicode.Property
  defdelegate alphanumeric?(codepoint_or_string), to: Unicode.Property
  defdelegate numeric?(codepoint_or_string), to: Unicode.Property

  defdelegate emoji?(codepoint_or_string), to: Unicode.Property
  defdelegate math?(codepoint_or_string), to: Unicode.Property

  defdelegate cased?(codepoint_or_string), to: Unicode.Property
  defdelegate lowercase?(codepoint_or_string), to: Unicode.Property
  defdelegate uppercase?(codepoint_or_string), to: Unicode.Property
end
