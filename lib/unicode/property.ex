defmodule Unicode.Property do
  @moduledoc """
  Functions to introspect Unicode properties for binaries
  (Strings) and codepoints.

  """
  @behaviour Unicode.Property.Behaviour

  @type string_or_codepoint :: String.t() | non_neg_integer

  alias Unicode.{Utils, GeneralCategory, Emoji}

  @derived_properties Utils.derived_properties()
                      |> Utils.remove_annotations()

  @properties Utils.properties()
              |> Utils.remove_annotations()

  @all_properties @derived_properties
  |> Map.merge(@properties)
  |> Map.merge(Emoji.emoji())

  @doc """
  Returns the map of Unicode
  properties.

  The property name is the map
  key and a list of codepoint
  ranges as tuples as the value.

  """
  def properties do
    @all_properties
  end

  @doc """
  Returns a list of known Unicode
  property names.

  This function does not return the
  names of any property aliases.

  """
  @known_properties Map.keys(@all_properties)

  def known_properties do
    @known_properties
  end

  @doc """
  Returns a map of aliases for
  Unicode blocks.

  An alias is an alternative name
  for referring to a block. Aliases
  are resolved by the `fetch/1` and
  `get/1` functions.

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

  """
  @servers Utils.property_servers()
  def servers do
    @servers
  end

  @doc """
  Returns the Unicode ranges for
  a given block as a list of
  ranges as 2-tuples.

  Aliases are resolved by this function.

  Returns either `{:ok, range_list}` or
  `:error`.

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
  a given block as a list of
  ranges as 2-tuples.

  Aliases are resolved by this function.

  Returns either `range_list` or
  `nil`.

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

  ## Example

      iex> Unicode.Property.count(:lowercase)
      2471

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

  @numeric_ranges GeneralCategory.get(:Nd)

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

  @extended_numeric_ranges @numeric_ranges ++ GeneralCategory.get(:Nl) ++ GeneralCategory.get(:No)

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

    @doc """
    Returns a boolean indicating if the
    codepoint or string has the property
    `#{inspect(property)}`.

    For string parameters, all codepoints in
    the string must have the `#{inspect(property)}`
    property in order for the result to be `true`.

    """
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

    @doc """
    Returns `#{inspect(property)}` or `nil` indicating
    if the codepoint or string has the property
    `#{inspect(property)}`.

    For string parameters, all codepoints in
    the string must have the `#{inspect(property)}`
    property in order for the result to `#{inspect(property)}`.

    """
    def unquote(property)(codepoint) do
      if unquote(boolean_function)(codepoint), do: unquote(property), else: nil
    end
  end

  @doc """
  Returns the property name(s) for the
  given binary or codepoint.

  In the case of a codepoint, a single
  list of properties for that codepoint name is returned.

  For a binary a list of list for each
  codepoint in the binary is returned.

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
    |> Enum.uniq()
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
