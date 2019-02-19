defmodule Cldr.Unicode do
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
end
