defmodule Unicode do
  @moduledoc """
  Functions to introspect the Unicode character database and
  to provide fast codepoint lookups for scripts, blocks,
  categories and properties.

  """
  alias Unicode.Utils

  @typedoc "A codepoint is an integer representing a Unicode character"
  @type codepoint :: non_neg_integer

  @typedoc "A codepoint or a string"
  @type codepoint_or_string :: codepoint | String.t()

  @typedoc "Unicode UTF encodings"
  @type encoding :: :utf8 | :utf16 | :utf16be | :utf16le | :utf32 | :utf32be | :utf32le

  @typedoc "The valid scripts as of Unicode 15"
  @type script ::
    :tangsa | :runic | :greek | :myanmar | :cherokee | :palmyrene | :elymaic | :latin,
    :kannada | :deseret | :old_hungarian | :psalter_pahlavi | :tagbanwa | :wancho,
    :khmer | :bengali | :soyombo | :chakma | :inscriptional_pahlavi | :carian,
    :tai_viet | :georgian | :oriya | :meroitic_cursive | :meroitic_hieroglyphs,
    :braille | :nandinagari | :vai | :adlam | :mahajani | :tirhuta | :mro,
    :zanabazar_square | :cuneiform | :vithkuqi | :newa | :yezidi | :osage | :linear_a,
    :hiragana | :mende_kikakui | :cyrillic | :hatran | :anatolian_hieroglyphs | :limbu,
    :balinese | :ethiopic | :new_tai_lue | :dives_akuru | :old_uyghur | :saurashtra,
    :linear_b | :mandaic | :tibetan | :caucasian_albanian | :avestan | :tangut,
    :siddham | :duployan | :kawi | :common | :thai | :shavian | :tamil | :old_persian,
    :nag_mundari | :ol_chiki | :samaritan | :tagalog | :grantha | :gujarati | :ugaritic,
    :khitan_small_script | :nyiakeng_puachue_hmong | :buhid | :syriac | :old_sogdian,
    :khudawadi | :lepcha | :lycian | :phags_pa | :bopomofo | :old_permic | :phoenician,
    :katakana | :dogra | :javanese | :glagolitic | :tai_le | :old_turkic,
    :old_south_arabian | :takri | :inscriptional_parthian | :signwriting | :osmanya,
    :syloti_nagri | :sogdian | :egyptian_hieroglyphs | :gunjala_gondi | :sora_sompeng,
    :arabic | :modi | :inherited | :chorasmian | :manichaean | :medefaidrin,
    :imperial_aramaic | :nko | :cypriot | :bamum | :han | :masaram_gondi | :ahom,
    :hanifi_rohingya | :coptic | :lao | :cham | :malayalam | :lisu | :yi | :old_italic,
    :gothic | :cypro_minoan | :pau_cin_hau | :canadian_aboriginal | :mongolian,
    :sharada | :tai_tham | :hanunoo | :old_north_arabian | :lydian | :rejang,
    :warang_citi | :kharoshthi | :brahmi | :sinhala | :batak | :telugu | :gurmukhi,
    :kayah_li | :marchen | :pahawh_hmong | :armenian | :bassa_vah | :multani,
    :nabataean | :toto | :hangul | :devanagari | :khojki | :kaithi | :thaana | :nushu,
    :sundanese | :bhaiksuki | :ogham | :makasar | :elbasan | :miao | :meetei_mayek,
    :hebrew | :buginese | :tifinagh

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
  Ensures that a binary is valid UTF encoded.

  The string is validated by replacing any invalid UTF
  bytes or incomplete sequences with a replacement string.

  ### Arguments

  * `binary` is any sequence of bytes.

  * `encoding` is any UTF encoding being one of
    `:utf8`, `:utf16`, `:utf16be`, `:utf16le`, `:utf32`, `:utf32be` or
    `:utf32le`. The default is `:utf8`.

  * `replacement` is any string that will be used to replace
    invalid UTF-8 bytes or incomplete sequences. The default
    is `"�"`.

  ### Returns

  * A valid UTF binary that may or may not include
    replacements for invalid UTF. If `encoding` is `:utf8`
    then the return type is a `t:String.t/0`.

  ### Example

      iex> Unicode.replace_invalid(<<"foo", 0b11111111, "bar">>, :utf8)
      "foo�bar"

  """
  @doc since: "1.18.0"
  @spec replace_invalid(binary :: binary(), encoding :: encoding(), replacement :: String.t()) :: binary()
  defdelegate replace_invalid(string, encoding \\ :utf8, replacement \\ "�"), to: Unicode.Validation

  @doc """
  Returns a map of aliases mapping
  property names to a module that
  serves that property.

  """
  def property_servers do
    Unicode.Property.servers()
  end

  @doc false
  def fetch_property(property) when is_binary(property) do
    Map.fetch(property_servers(), Utils.downcase_and_remove_whitespace(property))
  end

  @doc false
  def get_property(property) when is_binary(property) do
    Map.get(property_servers(), Utils.downcase_and_remove_whitespace(property))
  end

  @doc """
  Returns the Unicode category for a codepoint or a list of
  categories for a string.

  ## Argument

  * `codepoint_or_string` is a single integer codepoint
    or a `t:String.t/0`.

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
    or a `t:String.t/0`.

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
    or a `t:String.t/0`.

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
    or a `t:String.t/0`.

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
    or a `t:String.t/0`.

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
    or a `t:String.t/0`.

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
    or a `t:String.t/0`.

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
    or a `t:String.t/0`.

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
    or a `t:String.t/0`.

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
    or a `t:String.t/0`.

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
    or a `t:String.t/0`.

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
    or a `t:String.t/0`.

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
    or a `t:String.t/0`.

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

  * `string` is any `t:String.t/0`

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

  @doc """
  Returns the first index and grapheme count of each
  script detected in a string.

  ## Arguments

  * `string` is any `t:String.t/0`.

  ## Returns

  * A map where the key is a `t:script/0` and the value
    is a tuple where the first element is the index in the
    string where that script first appeared and the second
    element is the number of graphemes in that script.

  ## Examples

      iex> Unicode.script_statistic "Tokyo is the capital of 日本"
      %{common: {5, 5}, han: {24, 2}, latin: {0, 19}}

      iex> Unicode.script_statistic "おはよう"
      %{hiragana: {0, 4}}

  """
  @doc since: "1.16.0"

  @spec script_statistic(String.t()) :: %{script() => {non_neg_integer, pos_integer}}
  def script_statistic(string) when is_binary(string) do
    string
    |> String.graphemes()
    |> Enum.reduce({0, Map.new()}, fn grapheme, {index, map} ->
      [script] = Unicode.script(grapheme)
      map = Map.update(map, script, {index, 1}, fn {loc, count} -> {loc, count + 1} end)
      {index + 1, map}
    end)
    |> elem(1)
  end

  @doc """
  Returns a keyword list of scripts in descending dominance
  order for a given string.

  Dominance is determined by (in order of priority):

  * Index of the first occurrence of the script
  * Count of the number of graphemes in the script
  * Lexical ordering of the script name (used as a final means
    to ensure returning a deterministic result).

  ## Arguments

  * `string` is any `t:String.t/0`.

  ## Returns

  * A keyword list where the key is a `t:script/0` and the value
    is a tuple where the first element is the index in the
    string where that script first appeared and the second
    element is the number of graphemes in that script. The list
    is ordered by descending dominance.

  ## Example

      iex> Unicode.script_dominance "Tokyo is the capital of 日本"
      [latin: {0, 19}, common: {5, 5}, han: {24, 2}]

      iex> Unicode.script_dominance "おはよう"
      [hiragana: {0, 4}]

  """
  @doc since: "1.16.0"

  @spec script_dominance(String.t()) :: [{script(), {non_neg_integer, pos_integer}}]
  def script_dominance(string) do
    string
    |> script_statistic()
    |> Enum.sort(fn
      {script_1, {index_1, count_1}}, {script_2, {index_1, count_1}} ->
        to_string(script_1) < to_string(script_2)

      {_script_1, {index_1, count_1}}, {_script_2, {index_1, count_2}} ->
        count_1 < count_2

      {_script_1, {index_1, _count_1}}, {_script_2, {index_2, _count_2}} ->
        index_1 < index_2
    end)
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
