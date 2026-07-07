defmodule Unicode.Property do
  @moduledoc """
  Functions to introspect Unicode properties for binaries
  (Strings) and codepoints.

  The functions in this module only represent boolean
  properties. That is, properties that are either true
  or false - or in several cases represented as "has property"
  or "does not have property".

  """
  @behaviour Unicode.Property.Behaviour

  @type string_or_codepoint :: String.t() | non_neg_integer

  alias Unicode.{Emoji, GeneralCategory, Utils}

  @derived_properties Utils.derived_properties()
                      |> Utils.remove_annotations()

  @properties Utils.properties()
              |> Utils.remove_annotations()

  @all_and_derived_properties @properties
                              |> Map.merge(@derived_properties)

  @all_properties @all_and_derived_properties
                  |> Map.merge(Emoji.emoji())

  @doc """
  Returns the map of Unicode
  properties.

  The property name is the map
  key and a list of codepoint
  ranges as tuples as the value.

  ### Returns

  * A map of property names to a list of codepoint ranges.

  ### Examples

      iex> Unicode.Property.properties() |> Map.get(:alphabetic) |> Enum.take(2)
      [{65, 90}, {97, 122}]

  """
  def properties do
    @all_properties
  end

  @doc """
  Returns a list of known Unicode
  property names.

  This function does not return the
  names of any property aliases.

  ### Returns

  * A list of atom property names.

  ### Examples

      iex> :alphabetic in Unicode.Property.known_properties()
      true

  """
  @known_properties Map.keys(@all_properties)

  def known_properties do
    @known_properties
  end

  @doc """
  Returns a map of aliases for
  Unicode properties.

  An alias is an alternative name
  for referring to a property. Aliases
  are resolved by the `fetch/1` and
  `get/1` functions.

  ### Returns

  * A map of property aliases to property names.

  ### Examples

      iex> Unicode.Property.aliases() |> Map.get("alpha")
      :alphabetic

  """
  @property_alias Utils.property_alias()
                  |> Utils.atomize_values()
                  |> Utils.add_canonical_alias()

  @impl Unicode.Property.Behaviour
  def aliases do
    @property_alias
  end

  @doc """
  Returns a map of properties to the module
  that serves that property.

  ### Returns

  * A map of property names to the module that serves that property.

  ### Examples

      iex> Unicode.Property.servers() |> Map.get("script")
      Unicode.Script

  """
  @servers Utils.property_servers()
  def servers do
    @servers
  end

  @doc """
  Returns the Unicode ranges for
  a given property as a list of
  ranges as 2-tuples.

  Aliases are resolved by this function.

  ### Arguments

  * `property` is a property name as a string or atom.

  ### Returns

  * `{:ok, range_list}` or

  * `:error` if the property is not known.

  ### Examples

      iex> {:ok, ranges} = Unicode.Property.fetch(:alphabetic)
      iex> Enum.take(ranges, 2)
      [{65, 90}, {97, 122}]

      iex> Unicode.Property.fetch(:not_a_property)
      :error

  """
  @impl Unicode.Property.Behaviour
  def fetch(property) when is_atom(property) do
    Map.fetch(properties(), property)
  end

  def fetch(property) do
    property = Utils.downcase_and_remove_whitespace(property)
    property = Map.get(aliases(), property, property) |> Utils.maybe_atomize()
    Map.fetch(properties(), property)
  end

  @doc """
  Returns the Unicode ranges for
  a given property as a list of
  ranges as 2-tuples.

  Aliases are resolved by this function.

  ### Arguments

  * `property` is a property name as a string or atom.

  ### Returns

  * `range_list` or

  * `nil` if the property is not known.

  ### Examples

      iex> Unicode.Property.get(:alphabetic) |> Enum.take(2)
      [{65, 90}, {97, 122}]

      iex> Unicode.Property.get(:not_a_property)
      nil

  """
  @impl Unicode.Property.Behaviour
  def get(property) do
    case fetch(property) do
      {:ok, property} -> property
      _ -> nil
    end
  end

  @doc """
  Returns the count of the number of characters
  for a given property.

  ### Arguments

  * `property` is a property name as an atom.

  ### Returns

  * The number of codepoints that have the given property.

  ### Examples

      iex> Unicode.Property.count(:lowercase)
      2595

  """
  @impl Unicode.Property.Behaviour
  def count(property) do
    properties()
    |> Map.get(property)
    |> Enum.reduce(0, fn {from, to}, acc -> acc + to - from + 1 end)
  end

  @doc """
  Returns `:numeric` or `nil` based upon
  whether the given codepoint or binary
  is all numeric characters.

  This is useful when the desired result is
  `truthy` or `falsy`.

  ### Arguments

  * `codepoint_or_binary` is a single integer codepoint or a `t:String.t/0`.

  ### Returns

  * `:numeric` or

  * `nil`.

  ### Examples

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
  `truthy` or `falsy`.

  ### Arguments

  * `codepoint_or_binary` is a single integer codepoint or a `t:String.t/0`.

  ### Returns

  * `:alphanumeric` or

  * `nil`.

  ### Examples

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
  is all extended numeric characters.

  Extended numeric includes fractions, superscripts,
  subscripts and other characters in the category `No`.

  This is useful when the desired result is
  `truthy` or `falsy`.

  ### Arguments

  * `codepoint_or_binary` is a single integer codepoint or a `t:String.t/0`.

  ### Returns

  * `:extended_numeric` or

  * `nil`.

  ### Examples

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

  @numeric_ranges GeneralCategory.get(:Nd)
  @numeric_table Unicode.RangeSearch.new_membership_table(@numeric_ranges)

  @doc """
  Returns a boolean based upon
  whether the given codepoint or binary
  is all numeric characters.

  ### Arguments

  * `codepoint_or_binary` is a single integer codepoint or a `t:String.t/0`.

  ### Returns

  * `true` or `false`. For a string, the result is `true` only if all codepoints in the string are numeric.

  ### Examples

      iex> Unicode.Property.numeric? "123"
      true

      iex> Unicode.Property.numeric? "123a"
      false

  """
  def numeric?(codepoint) when is_integer(codepoint) do
    Unicode.RangeSearch.member?(@numeric_table, codepoint)
  end

  def numeric?(string) when is_binary(string) do
    string_has_property?(string, &numeric?/1)
  end

  def numeric?(_), do: false

  @extended_numeric_ranges @numeric_ranges ++ GeneralCategory.get(:Nl) ++ GeneralCategory.get(:No)
  @extended_numeric_table Unicode.RangeSearch.new_membership_table(@extended_numeric_ranges)

  @doc """
  Returns a boolean based upon
  whether the given codepoint or binary
  is all extended numeric characters.

  Extended numeric includes fractions, superscripts,
  subscripts and other characters in the category `No`.

  ### Arguments

  * `codepoint_or_binary` is a single integer codepoint or a `t:String.t/0`.

  ### Returns

  * `true` or `false`. For a string, the result is `true` only if all codepoints in the string are extended numeric.

  ### Examples

      iex> Unicode.Property.extended_numeric? "123"
      true

      iex> Unicode.Property.extended_numeric? "⅔"
      true

  """
  def extended_numeric?(codepoint_or_binary)

  def extended_numeric?(codepoint) when is_integer(codepoint) do
    Unicode.RangeSearch.member?(@extended_numeric_table, codepoint)
  end

  def extended_numeric?(string) when is_binary(string) do
    string_has_property?(string, &extended_numeric?/1)
  end

  def extended_numeric?(_), do: false

  @doc """
  Returns a boolean based upon
  whether the given codepoint or binary
  is all alphanumeric characters.

  ### Arguments

  * `codepoint_or_binary` is a single integer codepoint or a `t:String.t/0`.

  ### Returns

  * `true` or `false`. For a string, the result is `true` only if all codepoints in the string are alphanumeric.

  ### Examples

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

  @property_names Map.keys(@all_properties)

  @properties_code @property_names
                   |> Enum.map(fn fun ->
                     quote do
                       unquote(fun)(var!(codepoint))
                     end
                   end)

  for {property, ranges} <- @all_properties,
      property in @property_names do
    boolean_function = String.to_atom("#{property}?")
    membership_table = ranges |> Unicode.RangeSearch.new_membership_table() |> Macro.escape()

    @doc """
    Returns a boolean indicating if the
    codepoint or string has the property
    `#{inspect(property)}`.

    ### Arguments

    * `codepoint_or_string` is a single integer codepoint or a `t:String.t/0`.

    ### Returns

    * `true` or `false`. For a string, the result is `true` only if all codepoints in the string have the `#{inspect(property)}` property.

    """
    def unquote(boolean_function)(codepoint)
        when is_integer(codepoint) and codepoint in 0..0x10FFFF do
      Unicode.RangeSearch.member?(unquote(membership_table), codepoint)
    end

    def unquote(boolean_function)(string) when is_binary(string) do
      string_has_property?(string, &unquote(boolean_function)(&1))
    end

    @doc """
    Returns `#{inspect(property)}` or `nil` indicating
    if the codepoint or string has the property
    `#{inspect(property)}`.

    ### Arguments

    * `codepoint_or_string` is a single integer codepoint or a `t:String.t/0`.

    ### Returns

    * `#{inspect(property)}` or `nil`. For a string, the result is `#{inspect(property)}` only if all codepoints in the string have the `#{inspect(property)}` property.

    """
    def unquote(property)(codepoint) do
      if unquote(boolean_function)(codepoint), do: unquote(property), else: nil
    end
  end

  @doc """
  Returns the property name(s) for the
  given binary or codepoint.

  ### Arguments

  * `codepoint` is a single integer codepoint or a `t:String.t/0`.

  ### Returns

  * In the case of a codepoint, a single list of the properties of that codepoint.

  * In the case of a binary, a list of property lists, one for each codepoint in the binary.

  ### Examples

      iex> Unicode.Property.properties(?A)
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

  """
  def properties(codepoint) when is_integer(codepoint) do
    unquote(@properties_code)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort()
  end

  @spec properties(string_or_codepoint) :: [atom, ...] | [[atom, ...], ...]
  def properties(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&properties/1)
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
