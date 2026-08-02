defmodule Unicode.LinkBracket do
  @moduledoc """
  Functions to introspect the `Link_Bracket` property.

  `Link_Bracket` maps a closing bracket to the opening bracket it pairs with, as defined by [UTS #58](https://www.unicode.org/reports/tr58/). The link termination algorithm uses it to decide whether a closing bracket encountered inside a candidate link matches the innermost unclosed opening bracket — if it does the bracket is part of the link, and if it does not the link ends before it.

  This is a codepoint-valued mapping rather than a set of ranges, so it does not implement `Unicode.Property.Behaviour`. It is also distinct from the UCD's `Bidi_Paired_Bracket`: the two overlap but are scoped to different problems and are not interchangeable.

  """

  alias Unicode.Utils

  @link_brackets Utils.link_brackets()

  @doc """
  Returns the map of closing codepoints to their opening codepoints.

  ### Returns

  * A map with the closing codepoint as the key and the opening codepoint as the value.

  ### Examples

      iex> Unicode.LinkBracket.brackets() |> Map.get(?\\))
      40

  """
  def brackets do
    @link_brackets
  end

  @doc """
  Returns the number of bracket pairs.

  ### Returns

  * A non-negative integer count.

  ### Examples

      iex> Unicode.LinkBracket.count()
      65

  """
  @count map_size(@link_brackets)
  def count do
    @count
  end

  @doc """
  Returns the opening bracket paired with a closing bracket.

  ### Arguments

  * `codepoint` is a codepoint in the range `0..0x10FFFF`.

  ### Returns

  * `{:ok, opening_codepoint}` if the codepoint is a closing bracket, or

  * `:error` if it is not.

  ### Examples

      iex> Unicode.LinkBracket.fetch(?\\))
      {:ok, 40}

      iex> Unicode.LinkBracket.fetch(?a)
      :error

  """
  def fetch(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    Map.fetch(@link_brackets, codepoint)
  end

  @doc """
  Returns the opening bracket paired with a closing bracket.

  ### Arguments

  * `codepoint` is a codepoint in the range `0..0x10FFFF`.

  ### Returns

  * The opening codepoint if the codepoint is a closing bracket, or

  * `nil` if it is not.

  ### Examples

      iex> Unicode.LinkBracket.get(?\\])
      91

      iex> Unicode.LinkBracket.get(?a)
      nil

  """
  def get(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    Map.get(@link_brackets, codepoint)
  end

  @doc """
  Returns whether a closing bracket pairs with a given opening bracket.

  ### Arguments

  * `closing` is a codepoint in the range `0..0x10FFFF`.

  * `opening` is a codepoint in the range `0..0x10FFFF`.

  ### Returns

  * `true` if `closing` is a closing bracket whose pair is `opening`, otherwise `false`.

  ### Examples

      iex> Unicode.LinkBracket.pair?(?\\), ?\\()
      true

      iex> Unicode.LinkBracket.pair?(?\\), ?\\[)
      false

  """
  def pair?(closing, opening)
      when is_integer(closing) and closing in 0..0x10FFFF and
             is_integer(opening) and opening in 0..0x10FFFF do
    Map.get(@link_brackets, closing) == opening
  end
end
