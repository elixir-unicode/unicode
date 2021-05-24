defmodule Unicode do
  @moduledoc """
  Functions to introspect the Unicode character database and
  to provide fast codepoint lookups for scripts, blocks,
  categories and properties.

  """
  alias Unicode.Utils

  @type codepoint :: non_neg_integer
  @type codepoint_or_string :: codepoint | String.t()

  @doc false
  @data_dir Path.join(__DIR__, "../data") |> Path.expand()
  def data_dir do
    @data_dir
  end

  @doc """
  Returns the version of Unicode in use.

  """
  @version File.read!("data/blocks.txt")
           |> String.split("\n")
           |> Enum.at(0)
           |> String.replace("# Blocks-", "")
           |> String.replace(".txt", "")
           |> String.split(".")
           |> Enum.map(&String.to_integer/1)
           |> List.to_tuple()

  def version do
    @version
  end

  @doc """
  Returns a map of aliases mapping
  property names to a module that
  serves that property

  """
  def property_servers do
    Unicode.Property.servers()
  end

  def fetch_property(property) when is_binary(property) do
    Map.fetch(property_servers(), Utils.downcase_and_remove_whitespace(property))
  end

  def get_property(property) when is_binary(property) do
    Map.get(property_servers(), Utils.downcase_and_remove_whitespace(property))
  end

  @doc """
  Returns the Unicode category for a codepoint or a list of
  categories for a string.

  ## Argument

  * `codepoint_or_string` is a single integer codepoint
    or a `String.t`.

  ## Returns

  * in the case of a single codepoint, an atom representing
    one of the categories listed below

  * in the case of a string, a list representing the
    category for each codepoint in the string

  ## Notes

  THese categories match the names of the Unicode character
  classes used in various regular expression engines and in
  Unicode Sets.  The full list of categories is:

  | Category	| Matches	                |
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

  Note too that the group level categories like `:L`,
  `:M`, `:S` and so on are not assigned to any codepoint.
  They can only be identified by combining the results
  for each of the subsidiary categories.

  ## Examples

      iex> Unicode.category ?ä
      :Ll

      iex> Unicode.category ?A
      :Lu

      iex> Unicode.category ?🧐
      :So

      iex> Unicode.category ?+
      :Sm

      iex> Unicode.category ?1
      :Nd

      iex> Unicode.category "äA"
      [:Ll, :Lu]

  """
  @spec category(codepoint_or_string) :: atom | [atom, ...]
  defdelegate category(codepoint_or_string), to: Unicode.GeneralCategory

  @doc """
  Returns the script name of a codepoint
  or the list of block names for each codepoint
  in a string.

  ## Arguments

  * `codepoint_or_string` is a single integer codepoint
    or a `String.t`.

  ## Returns

  * in the case of a single codepoint, a string
    script name

  * in the case of a string, a list of string
    script names for each codepoint in the
  ` codepoint_or_string`

  ## Exmaples

      iex> Unicode.script ?ä
      :latin

      iex> Unicode.script ?خ
      :arabic

      iex> Unicode.script ?अ
      :devanagari

      iex> Unicode.script ?א
      :hebrew

      iex> Unicode.script ?Ж
      :cyrillic

      iex> Unicode.script ?δ
      :greek

      iex> Unicode.script ?ก
      :thai

      iex> Unicode.script ?ယ
      :myanmar

  """
  @spec script(codepoint_or_string) :: String.t() | [String.t(), ...]
  defdelegate script(codepoint_or_string), to: Unicode.Script

  @doc """
  Returns the block name of a codepoint
  or the list of block names for each codepoint
  in a string.

  ## Arguments

  * `codepoint_or_string` is a single integer codepoint
    or a `String.t`.

  ## Returns

  * in the case of a single codepoint, an atom
    block name

  * in the case of a string, a list of atom
    block names for each codepoint in the
   `codepoint_or_string`

  ## Exmaples

      iex> Unicode.block ?ä
      :latin_1_supplement

      iex> Unicode.block ?A
      :basic_latin

      iex> Unicode.block "äA"
      [:latin_1_supplement, :basic_latin]

  """
  @spec block(codepoint_or_string) :: atom | [atom, ...]
  defdelegate block(codepoint_or_string), to: Unicode.Block

  @doc """
  Returns the list of properties of each codepoint
  in a given string or the list of properties for a
  given string.

  ## Arguments

  * `codepoint_or_string` is a single integer codepoint
    or a `String.t`.

  ## Returns

  * in the case of a single codepoint, an atom
    list of properties

  * in the case of a string, a list of atom
    lisr for each codepoint in the
  ` codepoint_or_string`

  ## Exmaples

      iex> Unicode.properties 0x1bf0
      [
        :alphabetic,
        :case_ignorable,
        :grapheme_extend,
        :id_continue,
        :other_alphabetic,
        :xid_continue
      ]

      iex> Unicode.properties ?A
      [
        :alphabetic,
        :ascii_hex_digit,
        :cased,
        :changes_when_casefolded,
        :changes_when_casemapped,
        :changes_when_lowercased,
        :grapheme_base,
        :hex_digit,
        :id_continue,
        :id_start,
        :uppercase,
        :xid_continue,
        :xid_start
      ]

      iex> Unicode.properties ?+
      [:grapheme_base, :math, :pattern_syntax]

      iex> Unicode.properties "a1+"
      [
        [
          :alphabetic,
          :ascii_hex_digit,
          :cased,
          :changes_when_casemapped,
          :changes_when_titlecased,
          :changes_when_uppercased,
          :grapheme_base,
          :hex_digit,
          :id_continue,
          :id_start,
          :lowercase,
          :xid_continue,
          :xid_start
        ],
        [
          :ascii_hex_digit,
          :emoji,
          :emoji_component,
          :grapheme_base,
          :hex_digit,
          :id_continue,
          :xid_continue
        ],
        [
          :grapheme_base,
          :math,
          :pattern_syntax
        ]
      ]

  """
  @spec properties(codepoint_or_string) :: [atom, ...] | [[atom, ...], ...]
  defdelegate properties(codepoint_or_string), to: Unicode.Property

  @doc """
  Returns `true` if a single Unicode codepoint (or all characters in the
  given string) adhere to the Derived Core Property `Alphabetic`
  otherwise returns `false`.

  These are all characters that are usually used as representations
  of letters/syllabes in words/sentences.

  ## Arguments

  * `codepoint_or_string` is a single integer codepoint
    or a `String.t`.

  ## Returns

  * `true` or `false`

  For the string-version, the result will be true only if _all_
  codepoints in the string adhere to the property.

  ## Examples

      iex> Unicode.alphabetic?(?a)
      true

      iex> Unicode.alphabetic?("A")
      true

      iex> Unicode.alphabetic?("Elixir")
      true

      iex> Unicode.alphabetic?("الإكسير")
      true

      # comma and whitespace
      iex> Unicode.alphabetic?("foo, bar")
      false

      iex> Unicode.alphabetic?("42")
      false

      iex> Unicode.alphabetic?("龍王")
      true

      # Summation, \u2211
      iex> Unicode.alphabetic?("∑")
      false

      # Greek capital letter sigma, \u03a3
      iex> Unicode.alphabetic?("Σ")
      true

  """
  @spec alphabetic?(codepoint_or_string) :: boolean
  defdelegate alphabetic?(codepoint_or_string), to: Unicode.Property

  @doc """
  Returns `true` if a single Unicode codepoint (or all characters
  in the given string) are either `alphabetic?/1` or
  `numeric?/1` otherwise returns `false`.

  ## Arguments

  * `codepoint_or_string` is a single integer codepoint
    or a `String.t`.

  ## Returns

  * `true` or `false`

  For the string-version, the result will be true only if _all_
  codepoints in the string adhere to the property.

  ### Examples

      iex> Unicode.alphanumeric? "1234"
      true

      iex> Unicode.alphanumeric? "KeyserSöze1995"
      true

      iex> Unicode.alphanumeric? "3段"
      true

      iex> Unicode.alphanumeric? "dragon@example.com"
      false

  """
  @spec alphanumeric?(codepoint_or_string) :: boolean
  defdelegate alphanumeric?(codepoint_or_string), to: Unicode.Property

  @doc """
  Returns `true` if a single Unicode codepoint (or all characters
  in the given string) adhere to Unicode category `:Nd`
  otherwise returns `false`.

  This group of characters represents the decimal digits zero
  through nine (0..9) and the equivalents in non-Latin scripts.

  ## Arguments

  * `codepoint_or_string` is a single integer codepoint
    or a `String.t`.

  ## Returns

  * `true` or `false`

  For the string-version, the result will be true only if _all_
  codepoints in the string adhere to the property.

  For the string-version, the result will be true only if _all_
  codepoints in the string adhere to the property.

  ## Examples

  """
  @spec digits?(codepoint_or_string) :: boolean
  defdelegate digits?(codepoint_or_string), to: Unicode.Property, as: :numeric?

  @doc """
  Returns `true` if a single Unicode codepoint (or all characters
  in the given string) adhere to Unicode categories `:Nd`,
  `:Nl` and `:No` otherwise returns `false`.

  This group of characters represents the decimal digits zero
  through nine (0..9) and the equivalents in non-Latin scripts.

  ## Arguments

  * `codepoint_or_string` is a single integer codepoint
    or a `String.t`.

  ## Returns

  * `true` or `false`

  For the string-version, the result will be true only if _all_
  codepoints in the string adhere to the property.

  ## Examples

      iex> Unicode.numeric?("65535")
      true

      iex> Unicode.numeric?("42")
      true

      iex> Unicode.numeric?("lapis philosophorum")
      false

  """
  @spec numeric?(codepoint_or_string) :: boolean
  defdelegate numeric?(codepoint_or_string), to: Unicode.Property, as: :extended_numeric?

  @doc """
  Returns `true` if a single Unicode codepoint (or all characters
  in the given string) are `emoji` otherwise returns `false`.

  ## Arguments

  * `codepoint_or_string` is a single integer codepoint
    or a `String.t`.

  ## Returns

  * `true` or `false`

  For the string-version, the result will be true only if _all_
  codepoints in the string adhere to the property.

  ### Examples

      iex> Unicode.emoji? "🧐🤓🤩🤩️🤯"
      true

  """
  @spec emoji?(codepoint_or_string) :: boolean
  defdelegate emoji?(codepoint_or_string), to: Unicode.Emoji

  @doc """
  Returns `true` if a single Unicode codepoint (or all characters
  in the given string) the category `:Sm` otherwise returns `false`.

  These are all characters whose primary usage is in mathematical
  concepts (and not in alphabets). Notice that the numerical digits
  are not part of this group.

  ## Arguments

  * `codepoint_or_string` is a single integer codepoint
    or a `String.t`.

  ## Returns

  * `true` or `false`

  For the string-version, the result will be true only if _all_
  codepoints in the string adhere to the property.

  ## Examples

      iex> Unicode.math?(?=)
      true

      iex> Unicode.math?("=")
      true

      iex> Unicode.math?("1+1=2") # Digits do not have the `:math` property.
      false

      iex> Unicode.math?("परिस")
      false

      iex> Unicode.math?("∑") # Summation, \\u2211
      true

      iex> Unicode.math?("Σ") # Greek capital letter sigma, \\u03a3
      false

  """
  @spec math?(codepoint_or_string) :: boolean
  defdelegate math?(codepoint_or_string), to: Unicode.Property

  @doc """
  Returns either `true` if the codepoint has the `:cased` property
  or `false`.

  The `:cased` property means that this character has at least
  an upper and lower representation and possibly a titlecase
  representation too.

  ## Arguments

  * `codepoint_or_string` is a single integer codepoint
    or a `String.t`.

  ## Returns

  * `true` or `false`

  For the string-version, the result will be true only if _all_
  codepoints in the string adhere to the property.

  ## Examples

      iex> Unicode.cased? ?ယ
      false

      iex> Unicode.cased? ?A
      true

  """
  @spec cased?(codepoint_or_string) :: boolean
  defdelegate cased?(codepoint_or_string), to: Unicode.Property

  @doc """
  Returns `true` if a single Unicode codepoint (or all characters
  in the given string) the category `:Ll` otherwise returns `false`.

  Notice that there are many languages that do not have a distinction
  between cases. Their characters are not included in this group.

  ## Arguments

  * `codepoint_or_string` is a single integer codepoint
    or a `String.t`.

  ## Returns

  * `true` or `false`

  For the string-version, the result will be true only if _all_
  codepoints in the string adhere to the property.

  ## Examples

      iex> Unicode.lowercase?(?a)
      true

      iex> Unicode.lowercase?("A")
      false

      iex> Unicode.lowercase?("Elixir")
      false

      iex> Unicode.lowercase?("léon")
      true

      iex> Unicode.lowercase?("foo, bar")
      false

      iex> Unicode.lowercase?("42")
      false

      iex> Unicode.lowercase?("Σ")
      false

      iex> Unicode.lowercase?("σ")
      true

  """
  @spec lowercase?(codepoint_or_string) :: boolean
  defdelegate lowercase?(codepoint_or_string), to: Unicode.Property
  defdelegate downcase?(codepoint_or_string), to: Unicode.Property, as: :lowercase?

  @doc """
  Returns `true` if a single Unicode codepoint (or all characters
  in the given string) the category `:Lu` otherwise returns `false`.

  Notice that there are many languages that do not have a distinction
  between cases. Their characters are not included in this group.

  ## Arguments

  * `codepoint_or_string` is a single integer codepoint
    or a `String.t`.

  ## Returns

  * `true` or `false`

  For the string-version, the result will be true only if _all_
  codepoints in the string adhere to the property.
  ## Examples

      iex> Unicode.uppercase?(?a)
      false

      iex> Unicode.uppercase?("A")
      true

      iex> Unicode.uppercase?("Elixir")
      false

      iex> Unicode.uppercase?("CAMEMBERT")
      true

      iex> Unicode.uppercase?("foo, bar")
      false

      iex> Unicode.uppercase?("42")
      false

      iex> Unicode.uppercase?("Σ")
      true

      iex> Unicode.uppercase?("σ")
      false

  """
  @spec uppercase?(codepoint_or_string) :: boolean
  defdelegate uppercase?(codepoint_or_string), to: Unicode.Property
  defdelegate upcase?(codepoint_or_string), to: Unicode.Property, as: :uppercase?

  @doc """
  Returns a list of tuples representing the
  assigned ranges of Unicode code points.

  This information is derived from the block
  ranges as defined by `Unicode.Block.blocks/0`.

  """
  @spec assigned :: [{pos_integer, pos_integer}]
  defdelegate assigned, to: Unicode.Block, as: :assigned

  @deprecated "Use Unicode.assigned/0"
  def ranges do
    assigned()
  end

  @doc """
  Returns a list of tuples representing the
  full range of Unicode code points.

  """
  @all [{0x0, 0x10FFFF}]

  @spec all :: [{0x0, 0x10FFFF}]
  def all do
    @all
  end

  @doc """
  Removes accents (diacritical marks) from
  a string.

  ## Arguments

  * `string` is any `String.t`

  ## Returns

  * A string with all diacritical marks
    removed

  ## Notes

  The string is first normalised to `:nfd` form
  and then all characters in the block
  `:comnbining_diacritical_marks` is removed
  from the string

  ## Example

      iex> Unicode.unaccent("Et Ça sera sa moitié.")
      "Et Ca sera sa moitie."

  """
  def unaccent(string) do
    string
    |> normalize_nfd
    |> String.to_charlist()
    |> remove_diacritical_marks([:combining_diacritical_marks])
    |> List.to_string()
  end

  defp remove_diacritical_marks(charlist, blocks) do
    Enum.reduce(charlist, [], fn char, acc ->
      if Unicode.Block.block(char) in blocks do
        acc
      else
        [char | acc]
      end
    end)
    |> Enum.reverse()
  end

  @doc false
  def compact_ranges([{as, ae}, {bs, be} | rest]) when ae >= bs - 1 and as <= be do
    compact_ranges([{as, be} | rest])
  end

  def compact_ranges([{as, ae}, {_bs, be} | rest]) when ae >= be do
    compact_ranges([{as, ae} | rest])
  end

  def compact_ranges([first]) do
    [first]
  end

  def compact_ranges([first | rest]) do
    [first | compact_ranges(rest)]
  end

  # OTP 20 introduced the `:unicode: module
  # but we also want to support earlier
  # versions

  @doc false
  if Code.ensure_loaded?(:unicode) do
    def normalize_nfd(string) do
      :unicode.characters_to_nfd_binary(string)
    end
  else
    def normalize_nfd(string) do
      String.normalize(string, :nfd)
    end
  end
end
