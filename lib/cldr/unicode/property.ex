defmodule Cldr.Unicode.Property do
  @moduledoc """
  Unicode defines a set of [character properties](https://www.unicode.org/Public/UCD/latest/ucd/DerivedCoreProperties.txt) which the functions in this module will return for a given codepoint.  The properties supported by this module are a subset of the full set of properties.  They are:

  * `:math`
  * `:alphabetic`
  * `:lowercase`
  * `:uppercase`
  * `:case_ignorable`
  * `:cased`

  In addition three additional properties are derived from the [Unicode codepoint category data](https://www.unicode.org/Public/UCD/latest/ucd/extracted/DerivedGeneralCategory.txt). These are:

  * `:numeric`
  * `:extended_numeric`
  * `:alphanumeric`

  """
  alias Cldr.Unicode.Utils
  alias Cldr.Unicode.Category

  @type string_or_binary :: String.t | non_neg_integer

  @selected_properties [:math, :alphabetic, :lowercase, :uppercase,
                        :case_ignorable, :cased, :default_ignorable_code_point]

  @doc """
  Returns the map of Unicode properties and the list
  of codepoint ranges that below to a property.
  """
  @properties Utils.properties
  def properties do
    @properties
  end

  @doc """
  Returns a list of the known property typrs.

  ## Example

    iex> Cldr.Unicode.Property.known_properties
    [:alphabetic, :case_ignorable, :cased, :changes_when_casefolded,
     :changes_when_casemapped, :changes_when_lowercased, :changes_when_titlecased,
     :changes_when_uppercased, :default_ignorable_code_point, :grapheme_base,
     :grapheme_extend, :grapheme_link, :id_continue, :id_start, :lowercase, :math,
     :uppercase, :xid_continue, :xid_start]

  """
  @known_properties Map.keys(@properties)
  def known_properties do
    @known_properties
  end

  @doc """
  Returns the count of the number of codepoints for
  a given category

  ## Example

      iex> Cldr.Unicode.Property.count :alphabetic
      126629

  """
  def count(property) do
    properties()
    |> Map.get(property)
    |> Enum.reduce(0, fn {from, to}, acc -> acc + to - from + 1 end)
  end

  @doc """
  Returns the list of properties of each codepoint
  in a given string or the list of properties for a
  given codepoint.

  ## Arguments

  * `codepoint_or_binary` is either an integer codepoint
    or a string

  ## Exmaples

      iex> Cldr.Unicode.Property.properties 0x1bf0
      [:alphabetic, :case_ignorable]

      iex> Cldr.Unicode.Property.properties ?A
      [:alphabetic, :uppercase, :cased]

      iex> Cldr.Unicode.Property.properties ?+
      [:math]

      iex> Cldr.Unicode.Property.properties "a1+"
      [[:alphabetic, :lowercase, :cased], [:numeric], [:math]]

  """
  @spec properties(string_or_binary) :: [atom, ...] | [[atom, ...], ...]
  def properties(string) when is_binary(string) do
    string
    |> String.codepoints
    |> Enum.flat_map(&Utils.binary_to_codepoints/1)
    |> Enum.map(&properties/1)
  end

  @properties_code @selected_properties
  |> Enum.map(fn fun -> quote do unquote(fun)(var!(codepoint)) end end)

  def properties(codepoint) when is_integer(codepoint) do
    [numeric(codepoint) | unquote(@properties_code)]
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Returns either `:math` or nil for a given codepoint or string
  """
  def math(codepoint_or_binary)

  @doc """
  Returns either `:alphabetic` or nil for a given codepoint or string
  """
  def alphabetic(codepoint_or_binary)

  @doc """
  Returns either `:lowercase` or nil for a given codepoint or string
  """
  def lowercase(codepoint_or_binary)

  @doc """
  Returns either `:uppercase` or nil for a given codepoint or string
  """
  def uppercase(codepoint_or_binary)

  @doc """
  Returns either `:case_ignorable` or nil for a given codepoint or string
  """
  def case_ignorable(codepoint_or_binary)

  @doc """
  Returns either `:cased` or nil for a given codepoint or string
  """
  def cased(codepoint_or_binary)

  @doc """
  Returns either `:numeric` or nil for a given codepoint or string
  """
  def numeric(codepoint_or_binary) do
    if numeric?(codepoint_or_binary), do: :numeric, else: nil
  end

  @doc """
  Returns either `:alphanumeric` or nil for a given codepoint or string
  """
  def alphanumeric(codepoint_or_binary) do
    if alphanumeric?(codepoint_or_binary), do: :alphanumeric, else: nil
  end

  @doc """
  Returns either `:extended_numeric` or nil for a given codepoint
  """
  def extended_numeric(codepoint_or_binary) do
    if extended_numeric?(codepoint_or_binary), do: :extended_numeric, else: nil
  end

  @doc """
  Returns `true` if a single Unicode codepoint (or all characters
  in the given binary string) adhere to the Derived Core Property `Math`
  otherwise returns `false`.

  These are all characters whose primary usage is in mathematical
  concepts (and not in alphabets). Notice that the numerical digits
  are not part of this group.

  The function takes a unicode codepoint or a string as input.

  For the string-version, the result will be true only if _all_
  codepoints in the string adhere to the property.

  ## Examples

      iex> Cldr.Unicode.Property.math?(?=)
      true

      iex> Cldr.Unicode.Property.math?("=")
      true

      iex> Cldr.Unicode.Property.math?("1+1=2") # Digits do not have the `:math` property.
      false

      iex> Cldr.Unicode.Property.math?("परिस")
      false

      iex> Cldr.Unicode.Property.math?("∑") # Summation, \\u2211
      true

      iex> Cldr.Unicode.Property.math?("Σ") # Greek capital letter sigma, \\u03a3
      false

  """
  def math?(codepoint_or_binary)

  @doc """
  Returns `true` if a single Unicode codepoint (or all characters in the
  given binary string) adhere to the Derived Core Property `Alphabetic`
  otherwise returns `false`.

  These are all characters that are usually used as representations
  of letters/syllabes/ in words/sentences.

  The function takes a unicode codepoint or a string as input.

  For the string-version, the result will be true only if _all_
  codepoints in the string adhere to the property.

  ## Examples

      iex> Cldr.Unicode.Property.alphabetic?(?a)
      true

      iex> Cldr.Unicode.Property.alphabetic?("A")
      true

      iex> Cldr.Unicode.Property.alphabetic?("Elixir")
      true

      iex> Cldr.Unicode.Property.alphabetic?("الإكسير")
      true

      iex> Cldr.Unicode.Property.alphabetic?("foo, bar") # comma and whitespace
      false

      iex> Cldr.Unicode.Property.alphabetic?("42")
      false

      iex> Cldr.Unicode.Property.alphabetic?("龍王")
      true

      iex> Cldr.Unicode.Property.alphabetic?("∑") # Summation, \u2211
      false

      iex> Cldr.Unicode.Property.alphabetic?("Σ") # Greek capital letter sigma, \u03a3
      true

  """
  def alphabetic?(codepoint_or_binary)

  @doc """
  Returns `true` if a single Unicode codepoint (or all characters
  in the given binary string) adhere to the Derived Core Property
  `Lowercase` otherwise returns `false`.

  Notice that there are many languages that do not have a distinction
  between cases. Their characters are not included in this group.

  The function takes a unicode codepoint or a string as input.

  For the string-version, the result will be true only if _all_
  codepoints in the string adhere to the property.

  ## Examples

      iex> Cldr.Unicode.Property.lowercase?(?a)
      true

      iex> Cldr.Unicode.Property.lowercase?("A")
      false

      iex> Cldr.Unicode.Property.lowercase?("Elixir")
      false

      iex> Cldr.Unicode.Property.lowercase?("léon")
      true

      iex> Cldr.Unicode.Property.lowercase?("foo, bar")
      false

      iex> Cldr.Unicode.Property.lowercase?("42")
      false

      iex> Cldr.Unicode.Property.lowercase?("Σ")
      false

      iex> Cldr.Unicode.Property.lowercase?("σ")
      true

  """
  def lowercase?(codepoint_or_binary)

  @doc """
  Returns `true` if a single Unicode codepoint (or all characters
  in the given binary string) adhere to the Derived Core Property
  `Uppercase` otherwise returns `false`.

  Notice that there are many languages that do not have a distinction
  between cases. Their characters are not included in this group.

  The function takes a unicode codepoint or a string as input.

  For the string-version, the result will be true only if _all_
  codepoints in the string adhere to the property.

  ## Examples

      iex> Cldr.Unicode.Property.uppercase?(?a)
      false

      iex> Cldr.Unicode.Property.uppercase?("A")
      true

      iex> Cldr.Unicode.Property.uppercase?("Elixir")
      false

      iex> Cldr.Unicode.Property.uppercase?("CAMEMBERT")
      true

      iex> Cldr.Unicode.Property.uppercase?("foo, bar")
      false

      iex> Cldr.Unicode.Property.uppercase?("42")
      false

      iex> Cldr.Unicode.Property.uppercase?("Σ")
      true

      iex> Cldr.Unicode.Property.uppercase?("σ")
      false

  """
  def uppercase?(codepoint_or_binary)

  @doc """
  Returns either `true` if the codepoint has the `:case_ignorable` property
  or `false`.
  """
  def case_ignorable?(codepoint_or_binary)

  @doc """
  Returns either `true` if the codepoint has the `:cased` property
  or `false`.
  """
  def cased?(codepoint_or_binary)

  @doc """
  Returns `true` if a single Unicode codepoint (or all characters
  in the given binary string) adhere to Unicode category `:Nd`
  otherwise returns `false`.

  This group of characters represents the decimal digits zero
  through nine (0..9) and the equivalents in non-Latin scripts.

  The function takes a unicode codepoint or a string as input.

  For the string-version, the result will be true only if _all_
  codepoints in the string adhere to the property.

  ## Examples

  """
  def numeric?(codepoint_or_binary)

  @numeric_ranges Category.categories[:Nd]

  def numeric?(codepoint)
    when unquote(Utils.ranges_to_guard_clause(@numeric_ranges)), do: true

  def numeric?(string) when is_binary(string) do
    string_has_property?(string, &numeric?/1)
  end

  def numeric?(_), do: false

  @doc """
  Returns `true` if a single Unicode codepoint (or all characters
  in the given binary string) adhere to Unicode categories `:Nd`,
  `:Nl` and `:No` otherwise returns `false`.

  This group of characters represents the decimal digits zero
  through nine (0..9) and the equivalents in non-Latin scripts.

  The function takes a unicode codepoint or a string as input.

  For the string-version, the result will be true only if _all_
  codepoints in the string adhere to the property.

  ## Examples

      iex> Cldr.Unicode.Property.extended_numeric?("65535")
      true

      iex> Cldr.Unicode.Property.extended_numeric?("42")
      true

      iex> Cldr.Unicode.Property.extended_numeric?("lapis philosophorum")
      false

  """
  @extended_numeric_ranges @numeric_ranges ++
      Category.categories[:Nl] ++ Category.categories[:No]

  def extended_numeric?(codepoint_or_binary)

  def extended_numeric?(codepoint)
    when unquote(Utils.ranges_to_guard_clause(@extended_numeric_ranges)), do: true

  def extended_numeric?(string) when is_binary(string) do
    string_has_property?(string, &extended_numeric?/1)
  end

  def extended_numeric?(_), do: false

  @doc """
  Returns `true` if a single Unicode codepoint (or all characters
  in the given binary string) are either `alphabetic?/1` or
  `numeric?/1 otherwise returns `false`.

  The function takes a unicode codepoint or a string as input.

  For the string-version, the result will be true only if _all_
  codepoints in the string adhere to the property.

  ### Examples

      iex> Cldr.Unicode.Property.alphanumeric? "1234"
      true

      iex> Cldr.Unicode.Property.alphanumeric? "KeyserSöze1995"
      true

      iex> Cldr.Unicode.Property.alphanumeric? "3段"
      true

      iex> Cldr.Unicode.Property.alphanumeric? "dragon@example.com"
      false

  """
  def alphanumeric?(codepoint_or_binary)

  def alphanumeric?(codepoint) when is_integer(codepoint)do
    alphabetic?(codepoint) or numeric?(codepoint)
  end

  def alphanumeric?(string) when is_binary(string) do
    string_has_property?(string, &alphanumeric?/1)
  end

  def alphanumeric?(_), do: false

  defdelegate ignorable?(codepoint), to: __MODULE__, as: :default_ignorable_code_point?
  defdelegate ignorable(codepoint), to: __MODULE__, as: :default_ignorable_code_point

  for \
    {property, ranges} <- @properties,
    property in @selected_properties
  do
    boolean_function = String.to_atom("#{property}?")

    def unquote(boolean_function)(codepoint)
    when is_integer(codepoint) and unquote(Utils.ranges_to_guard_clause(ranges)) do
      true
    end

    def unquote(boolean_function)(codepoint)
    when is_integer(codepoint) and codepoint in 0..0x10FFFF do
      false
    end

    def unquote(boolean_function)(string) when is_binary(string) do
      string_has_property?(string, &(unquote(boolean_function)(&1)))
    end

    def unquote(property)(codepoint) do
      if unquote(boolean_function)(codepoint), do: unquote(property), else: nil
    end
  end

  @doc false
  def string_has_property?(string, function) do
    case String.next_codepoint(string) do
      nil -> false
      {<< codepoint :: utf8 >>, ""} ->
        function.(codepoint)
      {<< codepoint :: utf8 >>, rest} ->
        function.(codepoint) && function.(rest)
    end
  end
end