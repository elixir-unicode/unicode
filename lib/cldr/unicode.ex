defmodule Cldr.Unicode do
  @moduledoc """
  Functions to introspect the Unicode character database and
  to provide fast codepoint lookups.
  """

  alias Cldr.Unicode

  @type codepoint :: non_neg_integer
  @type codepoint_or_string :: codepoint | String.t

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
    {12, 1, 0}
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
  classes used in various regular expression engine.  The
  full list of categories is:

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

      iex> Cldr.Unicode.category ?ä
      :Ll

      iex> Cldr.Unicode.category ?A
      :Lu

      iex> Cldr.Unicode.category ?🧐
      :So

      iex> Cldr.Unicode.category ?+
      :Sm

      iex> Cldr.Unicode.category ?1
      :Nd

      iex> Cldr.Unicode.category "äA"
      [:Ll, :Lu]

  """
  @spec category(codepoint_or_string) :: atom | [atom, ...]
  defdelegate category(codepoint_or_string), to: Unicode.Category

  @spec category(codepoint_or_string) :: atom | [atom, ...]
  defdelegate class(codepoint_or_string), to: Unicode.Category, as: :category

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

      iex> Cldr.Unicode.script ?ä
      "latin"

      iex> Cldr.Unicode.script ?خ
      "arabic"

      iex> Cldr.Unicode.script ?अ
      "devanagari"

      iex> Cldr.Unicode.script ?א
      "hebrew"

      iex> Cldr.Unicode.script ?Ж
      "cyrillic"

      iex> Cldr.Unicode.script ?δ
      "greek"

      iex> Cldr.Unicode.script ?ก
      "thai"

      iex> Cldr.Unicode.script ?ယ
      "myanmar"

  """
  @spec script(codepoint_or_string) :: String.t | [String.t, ...]
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

      iex> Cldr.Unicode.block ?ä
      :latin_1_supplement

      iex> Cldr.Unicode.block ?A
      :basic_latin

      iex> Cldr.Unicode.block "äA"
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

      iex> Cldr.Unicode.properties 0x1bf0
      [:alphabetic, :case_ignorable]

      iex> Cldr.Unicode.properties ?A
      [:alphabetic, :uppercase, :cased]

      iex> Cldr.Unicode.properties ?+
      [:math]

      iex> Cldr.Unicode.properties "a1+"
      [[:alphabetic, :lowercase, :cased], [:numeric, :emoji], [:math]]

  """
  @spec properties(codepoint_or_string) :: [atom, ...] | [[atom, ...], ...]
  defdelegate properties(codepoint_or_string), to: Unicode.Property

  @doc """
  Returns `true` if a single Unicode codepoint (or all characters in the
  given string) adhere to the Derived Core Property `Alphabetic`
  otherwise returns `false`.

  These are all characters that are usually used as representations
  of letters/syllabes/ in words/sentences.

  ## Arguments

  * `codepoint_or_string` is a single integer codepoint
    or a `String.t`.

  ## Returns

  * `true` or `false`

  For the string-version, the result will be true only if _all_
  codepoints in the string adhere to the property.

  ## Examples

      iex> Cldr.Unicode.alphabetic?(?a)
      true

      iex> Cldr.Unicode.alphabetic?("A")
      true

      iex> Cldr.Unicode.alphabetic?("Elixir")
      true

      iex> Cldr.Unicode.alphabetic?("الإكسير")
      true

      iex> Cldr.Unicode.alphabetic?("foo, bar") # comma and whitespace
      false

      iex> Cldr.Unicode.alphabetic?("42")
      false

      iex> Cldr.Unicode.alphabetic?("龍王")
      true

      iex> Cldr.Unicode.alphabetic?("∑") # Summation, \u2211
      false

      iex> Cldr.Unicode.alphabetic?("Σ") # Greek capital letter sigma, \u03a3
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

      iex> Cldr.Unicode.alphanumeric? "1234"
      true

      iex> Cldr.Unicode.alphanumeric? "KeyserSöze1995"
      true

      iex> Cldr.Unicode.alphanumeric? "3段"
      true

      iex> Cldr.Unicode.alphanumeric? "dragon@example.com"
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

      iex> Cldr.Unicode.numeric?("65535")
      true

      iex> Cldr.Unicode.numeric?("42")
      true

      iex> Cldr.Unicode.numeric?("lapis philosophorum")
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

      iex> Cldr.Unicode.emoji? "🧐🤓🤩🤩️🤯"
      true

  """
  @spec emoji?(codepoint_or_string) :: boolean
  defdelegate emoji?(codepoint_or_string), to: Unicode.Property

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

      iex> Cldr.Unicode.math?(?=)
      true

      iex> Cldr.Unicode.math?("=")
      true

      iex> Cldr.Unicode.math?("1+1=2") # Digits do not have the `:math` property.
      false

      iex> Cldr.Unicode.math?("परिस")
      false

      iex> Cldr.Unicode.math?("∑") # Summation, \\u2211
      true

      iex> Cldr.Unicode.math?("Σ") # Greek capital letter sigma, \\u03a3
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

      iex> Cldr.Unicode.cased? ?ယ
      false

      iex> Cldr.Unicode.cased? ?A
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

      iex> Cldr.Unicode.lowercase?(?a)
      true

      iex> Cldr.Unicode.lowercase?("A")
      false

      iex> Cldr.Unicode.lowercase?("Elixir")
      false

      iex> Cldr.Unicode.lowercase?("léon")
      true

      iex> Cldr.Unicode.lowercase?("foo, bar")
      false

      iex> Cldr.Unicode.lowercase?("42")
      false

      iex> Cldr.Unicode.lowercase?("Σ")
      false

      iex> Cldr.Unicode.lowercase?("σ")
      true

  """
  @spec lowercase?(codepoint_or_string) :: boolean
  defdelegate lowercase?(codepoint_or_string), to: Unicode.Property

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

      iex> Cldr.Unicode.uppercase?(?a)
      false

      iex> Cldr.Unicode.uppercase?("A")
      true

      iex> Cldr.Unicode.uppercase?("Elixir")
      false

      iex> Cldr.Unicode.uppercase?("CAMEMBERT")
      true

      iex> Cldr.Unicode.uppercase?("foo, bar")
      false

      iex> Cldr.Unicode.uppercase?("42")
      false

      iex> Cldr.Unicode.uppercase?("Σ")
      true

      iex> Cldr.Unicode.uppercase?("σ")
      false

  """
  @spec uppercase?(codepoint_or_string) :: boolean
  defdelegate uppercase?(codepoint_or_string), to: Unicode.Property


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

      iex> Cldr.Unicode.unaccent("Et Ça sera sa moitié.")
      "Et Ca sera sa moitie."

  """
  def unaccent(string) do
    string
    |> normalize_nfd
    |> String.to_charlist
    |> remove_diacritical_marks([:combining_diacritical_marks])
    |> List.to_string
  end

  defp remove_diacritical_marks(charlist, blocks) do
    Enum.reduce(charlist, [], fn char, acc ->
      if Cldr.Unicode.Block.block(char) in blocks do
        acc
      else
        [char | acc]
      end
    end)
    |> Enum.reverse
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
