defmodule Unicode.LinkEmail do
  @moduledoc """
  Functions to introspect the `Link_Email` property for binaries (Strings) and codepoints.

  `Link_Email` is the set of characters valid in the local part of an email address — the portion before the `@` — as defined by [UTS #58](https://www.unicode.org/reports/tr58/).

  Unlike the enumerated properties this is binary: a codepoint is either in the set or it is not. It therefore does not implement `Unicode.Property.Behaviour`, which assumes a map of values to ranges, and the primary API is the predicate `link_email?/1`.

  """

  alias Unicode.Utils

  @link_emails Utils.link_emails()

  @link_email_table Unicode.RangeSearch.new_membership_table(@link_emails)

  @doc """
  Returns the codepoint ranges of the `Link_Email` property.

  ### Returns

  * A list of codepoint ranges as 2-tuples.

  ### Examples

      iex> Unicode.LinkEmail.ranges() |> is_list()
      true

  """
  def ranges do
    @link_emails
  end

  @doc """
  Returns the count of codepoints valid in an email local part.

  ### Returns

  * A non-negative integer count.

  ### Examples

      iex> Unicode.LinkEmail.count() > 100_000
      true

  """
  @count Enum.reduce(@link_emails, 0, fn {from, to}, acc -> acc + to - from + 1 end)
  def count do
    @count
  end

  @doc """
  Returns whether a codepoint or every codepoint of a string is valid in an email local part.

  ### Arguments

  * `string_or_codepoint` is either a binary (String) or a codepoint in the range `0..0x10FFFF`.

  ### Returns

  * For a codepoint, `true` or `false`.

  * For a binary, `true` only when *every* codepoint is valid, so the result can be used directly
    to validate a candidate local part. An empty string returns `true`, since it has no invalid
    codepoint; callers needing a non-empty local part should check that separately.

  ### Examples

      iex> Unicode.LinkEmail.link_email?(?a)
      true

      iex> Unicode.LinkEmail.link_email?(?@)
      false

      iex> Unicode.LinkEmail.link_email?("first.last")
      true

      iex> Unicode.LinkEmail.link_email?("has space")
      false

  """
  def link_email?(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.all?(&link_email?/1)
  end

  def link_email?(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    Unicode.RangeSearch.member?(@link_email_table, codepoint)
  end
end
