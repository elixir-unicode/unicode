defmodule Cldr.Unicode.Category do
  @moduledoc """
  | Property	| Matches	                |
  | --------- | ----------------------- |
  | :C	      | Other	                  |
  | :Cc	      | Control	                |
  | :Cf	      | Format	                |
  | :Cn	      | Unassigned	            |
  | :Co	      | Private use	            |
  | :Cs	      | Surrogate	              |
  | :L	      | Letter	                |
  | :Ll	      | Lower case letter	      |
  | :Lm	      | Modifier letter	        |
  | :Lo	      | Other letter	          |
  | :Lt	      | Title case letter	      |
  | :Lu	      | Upper case letter	      |
  | :M	      | Mark	                  |
  | :Mc	      | Spacing mark	          |
  | :Me	      | Enclosing mark	        |
  | :Mn	      | Non-spacing mark	      |
  | :N	      | Number	                |
  | :Nd	      | Decimal number	        |
  | :Nl	      | Letter number	          |
  | :No	      | Other number	          |
  | :P	      | Punctuation	            |
  | :Pc	      | Connector punctuation	  |
  | :Pd	      | Dash punctuation	      |
  | :Pe	      | Close punctuation	      |
  | :Pf	      | Final punctuation	      |
  | :Pi	      | Initial punctuation	    |
  | :Po	      | Other punctuation	      |
  | :Ps	      | Open punctuation	      |
  | :S	      | Symbol	                |
  | :Sc	      | Currency symbol	        |
  | :Sk	      | Modifier symbol	        |
  | :Sm	      | Mathematical symbol	    |
  | :So	      | Other symbol	          |
  | :Z	      | Separator	              |
  | :Zl	      | Line separator	        |
  | :Zp	      | Paragraph separator	    |
  | :Zs	      | Space separator	        |

  Note: `:L` includes the following properties: `:Ll`, `:Lm`, `:Lo`, `:Lt` and `:Lu`.

  """
  alias Cldr.Unicode.Utils

  @categories Utils.categories
  def categories do
    @categories
  end

  @known_categories Map.keys(@categories)
  def known_categorys do
    @known_categories
  end

  def count(category) do
    categories()
    |> Map.get(category)
    |> Enum.reduce(0, fn {from, to}, acc -> acc + to - from + 1 end)
  end

  def category(string) when is_binary(string) do
    string
    |> String.codepoints
    |> Enum.map(&Utils.codepoint_to_integer/1)
    |> Enum.map(&category/1)
  end

  for {category, ranges} <- @categories do
    def category(codepoint) when unquote(Utils.ranges_to_guard_clause(ranges)) do
      unquote(category)
    end
  end

  def category(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    :Cn
  end

end