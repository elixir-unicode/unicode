defmodule Unicode.Script do
  @moduledoc false

  alias Unicode.Utils

  @scripts Utils.scripts()
           |> Utils.remove_annotations()

  def scripts do
    @scripts
  end

  @known_scripts Map.keys(@scripts)

  def known_scripts do
    @known_scripts
  end

  @script_alias Utils.property_value_alias()
  |> Map.get("sc")
  |> Enum.flat_map(fn
      [alias1, code] ->
        [{String.downcase(alias1), String.downcase(code)}]
      [alias1, code, alias2] ->
        [{String.downcase(alias1), String.downcase(code)},
         {String.downcase(alias2), String.downcase(code)}]
  end)
  |> Map.new

  def aliases do
    @script_alias
  end

  def fetch(script) do
    script = Map.get(aliases(), script, script)
    Map.fetch(scripts(), script)
  end

  def get(script) do
    case fetch(script) do
      {:ok, script} -> script
      _ -> nil
    end
  end

  @doc """
  Returns the count of the number of characters
  for a given script.

  ## Example

      iex> Unicode.Script.count("mongolian")
      167

  """
  def count(script) do
    with {:ok, script} <- fetch(script) do
      Enum.reduce(script, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  def script(string) when is_binary(string) do
    string
    |> String.codepoints()
    |> Enum.flat_map(&Utils.binary_to_codepoints/1)
    |> Enum.map(&script/1)
  end

  for {script, ranges} <- @scripts do
    def script(codepoint) when unquote(Utils.ranges_to_guard_clause(ranges)) do
      unquote(script)
    end
  end

  def script(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    nil
  end
end
