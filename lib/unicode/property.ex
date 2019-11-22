defmodule Unicode.Property do
  @moduledoc """
  Functions to introspect Unicode properties for binaries
  (Strings) and codepoints.

  """
  @type string_or_codepoint :: String.t() | non_neg_integer

  alias Unicode.Utils
  alias Unicode.Emoji
  alias Unicode.Category

  @selected_properties [
    :math,
    :alphabetic,
    :lowercase,
    :uppercase,
    :case_ignorable,
    :cased,
    :default_ignorable_code_point
  ]

  @properties Utils.properties()
              |> Utils.remove_annotations()

  @doc """
  Returns the map of Unicode
  properties.

  The property name is the map
  key and a list of codepoint
  ranges as tuples as the value.

  """
  def properties do
    @properties
  end

  @doc """
  Returns a list of known Unicode
  property names.

  This function does not return the
  names of any property aliases.

  """
  @known_properties Map.keys(@properties) ++ Emoji.known_emoji_categories()
  def known_properties do
    @known_properties
  end

  @doc """
  Returns the count of the number of characters
  for a given property.

  ## Example

      iex> Unicode.Property.count(:lowercase)
      2340

  """
  def count(property) do
    properties()
    |> Map.get(property)
    |> Enum.reduce(0, fn {from, to}, acc -> acc + to - from + 1 end)
  end

  @spec properties(string_or_codepoint) :: [atom, ...] | [[atom, ...], ...]
  def properties(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&properties/1)
    |> Enum.uniq()
  end

  @properties_code @selected_properties
                   |> Enum.map(fn fun ->
                     quote do
                       unquote(fun)(var!(codepoint))
                     end
                   end)

  @doc """
  Returns the property name(s) for the
  given binary or codepoint.

  In the case of a codepoint, a single
  list of properties for that codepoint name is returned.

  For a binary a list of list for each
  codepoint in the binary is returned.

  """
  def properties(codepoint) when is_integer(codepoint) do
    [numeric(codepoint), Emoji.emoji(codepoint) | unquote(@properties_code)]
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Returns `:numeric` or `nil` based upon
  whether the given codepoint or binary
  is all numeric characters.

  This is useful when the desired result is
  `truthy` or `falsy`

  ## Example

      iex> Unicode.Property.numeric "123"
      :numeric
      iex> Unicode.Property.numeric "123a"
      nil

  """
  def numeric(codepoint_or_binary) do
    if numeric?(codepoint_or_binary), do: :numeric, else: nil
  end

  @doc """
  Returns `:alphanumeric` or `nil` based upon
  whether the given codepoint or binary
  is all alphanumeric characters.

  This is useful when the desired result is
  `truthy` or `falsy`

  ## Example

      iex> Unicode.Property.alphanumeric "123abc"
      :alphanumeric
      iex> Unicode.Property.alphanumeric "???"
      nil

  """
  def alphanumeric(codepoint_or_binary) do
    if alphanumeric?(codepoint_or_binary), do: :alphanumeric, else: nil
  end

  @doc """
  Returns `:extended_numeric` or `nil` based upon
  whether the given codepoint or binary
  is all alphanumeric characters.

  Extended numberic includes fractions, superscripts,
  subscripts and other characters in the category `No`.

  This is useful when the desired result is
  `truthy` or `falsy`

  ## Example

      iex> Unicode.Property.extended_numeric "123"
      :extended_numeric
      iex> Unicode.Property.extended_numeric "⅔"
      :extended_numeric
      iex> Unicode.Property.extended_numeric "-123"
      nil

  """
  def extended_numeric(codepoint_or_binary) do
    if extended_numeric?(codepoint_or_binary), do: :extended_numeric, else: nil
  end

  @numeric_ranges Category.categories()[:Nd]

  @doc """
  Returns a boolean based upon
  whether the given codepoint or binary
  is all numeric characters.

  ## Example

      iex> Unicode.Property.numeric? "123"
      true
      iex> Unicode.Property.numeric? "123a"
      false

  """
  def numeric?(codepoint)
      when unquote(Utils.ranges_to_guard_clause(@numeric_ranges)),
      do: true

  def numeric?(string) when is_binary(string) do
    string_has_property?(string, &numeric?/1)
  end

  def numeric?(_), do: false

  @extended_numeric_ranges @numeric_ranges ++
                             Category.categories()[:Nl] ++ Category.categories()[:No]

  @doc """
  Returns a boolean based upon
  whether the given codepoint or binary
  is all numberic characters.

  ## Example

     iex> Unicode.Property.extended_numeric? "123"
     true
     iex> Unicode.Property.extended_numeric? "⅔"
     true

  """
  def extended_numeric?(codepoint_or_binary)

  def extended_numeric?(codepoint)
      when unquote(Utils.ranges_to_guard_clause(@extended_numeric_ranges)),
      do: true

  def extended_numeric?(string) when is_binary(string) do
    string_has_property?(string, &extended_numeric?/1)
  end

  def extended_numeric?(_), do: false

  @doc """
  Returns a boolean based upon
  whether the given codepoint or binary
  is all alphanumeric characters.

  ## Example

      iex> Unicode.Property.alphanumeric? "123abc"
      true
      iex> Unicode.Property.alphanumeric? "⅔"
      false

  """
  def alphanumeric?(codepoint_or_binary)

  def alphanumeric?(codepoint) when is_integer(codepoint) do
    alphabetic?(codepoint) or numeric?(codepoint)
  end

  def alphanumeric?(string) when is_binary(string) do
    string_has_property?(string, &alphanumeric?/1)
  end

  def alphanumeric?(_), do: false

  @doc """
  Returns a boolean based upon
  whether the given codepoint or binary
  is all emoji characters.

  Note that some characters are unexpectedly
  emoji because they are part of a multicodepoint
  combination. For example, the numbers `0` through
  `9` are emoji because they form part of the `keycap`
  emoji codepoints.

  ## Example

      iex> Unicode.Property.emoji? "🔥"
      true
      iex> Unicode.Property.emoji? "1"
      true
      iex> Unicode.Property.emoji? "abc"
      false

  """
  def emoji?(codepoint_or_binary)

  def emoji?(codepoint) when is_integer(codepoint) do
    ignorable?(codepoint) ||
      Emoji.emoji(codepoint) in Emoji.known_emoji_categories()
  end

  def emoji?(string) when is_binary(string) do
    string_has_property?(string, &emoji?/1)
  end

  def emoji?(_), do: false

  defp ignorable?(codepoint) do
    properties = properties(codepoint)
    :case_ignorable in properties || :default_ignorable_code_point in properties
  end

  @doc """
  Returns `:math` or `nil` based upon
  whether the given codepoint or binary
  is all math characters.

  This is useful when the desired result is
  `truthy` or `falsy`

  ## Example

      iex> Unicode.Property.math "+<>=^"
      :math
      iex> Unicode.Property.math "*/"
      nil

  """
  def math(codepoint_or_binary)

  @doc """
  Returns `:alphabetic` or `nil` based upon
  whether the given codepoint or binary
  is all alphabetic characters.

  This is useful when the desired result is
  `truthy` or `falsy`

  ## Example

      iex> Unicode.Property.alphabetic "abc"
      :alphabetic
      iex> Unicode.Property.alphabetic "123"
      nil

  """
  def alphabetic(codepoint_or_binary)

  @doc """
  Returns `:lowercase` or `nil` based upon
  whether the given codepoint or binary
  is all lowercase characters.

  This is useful when the desired result is
  `truthy` or `falsy`

  ## Example

      iex> Unicode.Property.lowercase "abc"
      :lowercase
      iex> Unicode.Property.lowercase "ABC"
      nil

  """
  def lowercase(codepoint_or_binary)

  @doc """
  Returns `:uppercase` or `nil` based upon
  whether the given codepoint or binary
  is all uppercase characters.

  This is useful when the desired result is
  `truthy` or `falsy`

  ## Example

      iex> Unicode.Property.uppercase "ABC"
      :uppercase
      iex> Unicode.Property.uppercase "abc"
      nil

  """
  def uppercase(codepoint_or_binary)

  @doc """
  Returns `:case_ignorable` or `nil` based upon
  whether the given codepoint or binary
  is all case ignorable characters.

  This is useful when the desired result is
  `truthy` or `falsy`

  ## Example

      iex> Unicode.Property.case_ignorable ".:^"
      :case_ignorable
      iex> Unicode.Property.case_ignorable "123abc"
      nil

  """
  def case_ignorable(codepoint_or_binary)

  @doc """
  Returns `:cased` or `nil` based upon
  whether the given codepoint or binary
  is all cased characters.

  This is useful when the desired result is
  `truthy` or `falsy`

  ## Example

      iex> Unicode.Property.cased "abc"
      :cased
      iex> Unicode.Property.cased "123"
      nil

  """
  def cased(codepoint_or_binary)

  @doc """
  Returns a boolean based upon
  whether the given codepoint or binary
  is all math characters.

  ## Example

      iex> Unicode.Property.math? "+<>^"
      true
      iex> Unicode.Property.math? "abc"
      false

  """
  def math?(codepoint_or_binary)

  @doc """
  Returns a boolean based upon
  whether the given codepoint or binary
  is all alphabetic characters.

  ## Example

      iex> Unicode.Property.alphabetic? "abc"
      true
      iex> Unicode.Property.alphabetic? "123"
      false

  """
  def alphabetic?(codepoint_or_binary)

  @doc """
  Returns a boolean based upon
  whether the given codepoint or binary
  is all lowercase characters.

  ## Example

      iex> Unicode.Property.lowercase? "abc"
      true
      iex> Unicode.Property.lowercase? "ABC"
      false

  """
  def lowercase?(codepoint_or_binary)

  @doc """
  Returns a boolean based upon
  whether the given codepoint or binary
  is all uppercase characters.

  ## Example

      iex> Unicode.Property.uppercase? "ABC"
      true
      iex> Unicode.Property.uppercase? "abc"
      false

  """
  def uppercase?(codepoint_or_binary)

  @doc """
  Returns a boolean based upon
  whether the given codepoint or binary
  is all case ignorable characters.

  ## Example

      iex> Unicode.Property.case_ignorable? ".:^"
      true
      iex> Unicode.Property.case_ignorable? "123abc"
      false

  """
  def case_ignorable?(codepoint_or_binary)

  @doc """
  Returns a boolean based upon
  whether the given codepoint or binary
  is all cased characters.

  ## Example

      iex> Unicode.Property.cased? "abc"
      true
      iex> Unicode.Property.cased? "123"
      false

  """
  def cased?(codepoint_or_binary)

  for {property, ranges} <- @properties,
      property in @selected_properties do
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
      string_has_property?(string, &unquote(boolean_function)(&1))
    end

    def unquote(property)(codepoint) do
      if unquote(boolean_function)(codepoint), do: unquote(property), else: nil
    end
  end

  @doc false
  def string_has_property?(string, function) do
    case String.next_codepoint(string) do
      nil ->
        false

      {<<codepoint::utf8>>, ""} ->
        function.(codepoint)

      {<<codepoint::utf8>>, rest} ->
        function.(codepoint) && function.(rest)
    end
  end
end
