defmodule Cldr.Unicode.Script do
  @moduledoc false

  alias Cldr.Unicode.Utils

  @scripts Utils.scripts()
  |> Utils.remove_annotations

  def scripts do
    @scripts
  end

  @known_scripts Map.keys(@scripts)
  def known_scripts do
    @known_scripts
  end

  def count(script) do
    scripts()
    |> Map.get(script)
    |> Enum.reduce(0, fn {from, to}, acc -> acc + to - from + 1 end)
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
