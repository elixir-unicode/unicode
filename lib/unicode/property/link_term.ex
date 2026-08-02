defmodule Unicode.LinkTerm do
  @moduledoc """
  Functions to introspect the `Link_Term` property for binaries (Strings) and codepoints.

  `Link_Term` drives the link termination algorithm of [UTS #58](https://www.unicode.org/reports/tr58/), which decides where a URL or email address appearing in flowing text ends. The values are:

  * `:include` — the character belongs inside the link.

  * `:hard` — the character terminates the link immediately. This is the default, so any codepoint not listed in the data terminates a link.

  * `:soft` — the character terminates the link only when what follows is a run of soft characters and then a hard character or the end of the text. This is what lets `See example.com.` drop the sentence-final full stop while `example.com/a.b` keeps its inner one.

  * `:open` and `:close` — bracket characters, paired through `Unicode.LinkBracket`. A closing bracket is included when it matches the innermost open bracket and terminates the link otherwise.

  The primary API is `link_term/1` which returns the value for a codepoint, or the list of values for a string.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @link_terms Utils.link_terms()
              |> Utils.remove_annotations()

  @link_term_table Unicode.RangeSearch.new_value_table(@link_terms)

  @doc """
  Returns the map of `Link_Term` values.

  ### Returns

  * A map where the value name is the key and a list of codepoint ranges as 2-tuples is the value.

  ### Examples

      iex> :soft in Map.keys(Unicode.LinkTerm.link_terms())
      true

  """
  def link_terms do
    @link_terms
  end

  @doc """
  Returns a list of known `Link_Term` values.

  Note that `:hard` is the default value and is therefore not listed in the data, so it does not appear here even though `link_term/1` returns it.

  ### Returns

  * A list of atom value names.

  ### Examples

      iex> :include in Unicode.LinkTerm.known_link_terms()
      true

  """
  @known_link_terms Map.keys(@link_terms)
  def known_link_terms do
    @known_link_terms
  end

  @doc """
  Returns a map of aliases for `Link_Term` values.

  `Link_Term` is defined by UTS #58 rather than the UCD, so it has no entry in
  `PropertyValueAliases.txt` and the only aliases are the value names themselves.

  ### Returns

  * A map where the alias string is the key and the value name is the value.

  ### Examples

      iex> Unicode.LinkTerm.aliases() |> Map.get("soft")
      :soft

  """
  @link_term_aliases Map.new(@known_link_terms, fn value ->
                       {Utils.downcase_and_remove_whitespace(Atom.to_string(value)), value}
                     end)

  @impl Unicode.Property.Behaviour
  def aliases do
    @link_term_aliases
  end

  @doc """
  Returns the Unicode codepoint ranges for a given `Link_Term` value.

  ### Arguments

  * `link_term` is any `Link_Term` value name, as an atom or string.

  ### Returns

  * `{:ok, range_list}` where `range_list` is a list of codepoint ranges as 2-tuples.

  * `:error` if the value is not known.

  ### Examples

      iex> Unicode.LinkTerm.fetch(:open) |> elem(0)
      :ok

      iex> Unicode.LinkTerm.fetch(:invalid)
      :error

  """
  @impl Unicode.Property.Behaviour
  def fetch(link_term) when is_atom(link_term) do
    Map.fetch(link_terms(), link_term)
  end

  def fetch(link_term) do
    link_term = Utils.downcase_and_remove_whitespace(link_term)
    link_term = Map.get(aliases(), link_term, link_term) |> Utils.maybe_atomize()

    Map.fetch(link_terms(), link_term)
  end

  @doc """
  Returns the Unicode codepoint ranges for a given `Link_Term` value.

  ### Arguments

  * `link_term` is any `Link_Term` value name, as an atom or string.

  ### Returns

  * A list of codepoint ranges as 2-tuples.

  * `nil` if the value is not known.

  ### Examples

      iex> Unicode.LinkTerm.get(:invalid)
      nil

  """
  @impl Unicode.Property.Behaviour
  def get(link_term) do
    case fetch(link_term) do
      {:ok, range_list} -> range_list
      _ -> nil
    end
  end

  @doc """
  Returns the count of codepoints with a given `Link_Term` value.

  ### Arguments

  * `link_term` is any `Link_Term` value name, as an atom or string.

  ### Returns

  * A non-negative integer count of the codepoints with that value.

  * `:error` if the value is not known.

  ### Examples

      iex> Unicode.LinkTerm.count(:open)
      65

  """
  @impl Unicode.Property.Behaviour
  def count(link_term) do
    with {:ok, range_list} <- fetch(link_term) do
      Enum.reduce(range_list, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the `Link_Term` value of the given binary or codepoint.

  ### Arguments

  * `string_or_codepoint` is either a binary (String) or a codepoint in the range `0..0x10FFFF`.

  ### Returns

  * For a codepoint, a single value atom. Codepoints not listed in the data return `:hard`, the
    UTS #58 default.

  * For a binary, a list of the distinct values of the codepoints in the binary.

  ### Examples

      iex> Unicode.LinkTerm.link_term(?a)
      :include

      iex> Unicode.LinkTerm.link_term(?.)
      :soft

      iex> Unicode.LinkTerm.link_term(?\\s)
      :hard

      iex> Unicode.LinkTerm.link_term(?\\()
      :open

  """
  def link_term(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&link_term/1)
    |> Enum.uniq()
  end

  def link_term(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    Unicode.RangeSearch.find(@link_term_table, codepoint, :hard)
  end
end
