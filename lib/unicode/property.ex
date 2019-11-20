defmodule Unicode.Property do
  @moduledoc false

  alias Unicode.Utils
  alias Unicode.Emoji
  alias Unicode.Category

  @type string_or_binary :: String.t() | non_neg_integer

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

  def properties do
    @properties
  end

  @known_properties Map.keys(@properties) ++ Emoji.known_emoji_categories()
  def known_properties do
    @known_properties
  end

  def count(property) do
    properties()
    |> Map.get(property)
    |> Enum.reduce(0, fn {from, to}, acc -> acc + to - from + 1 end)
  end

  @spec properties(string_or_binary) :: [atom, ...] | [[atom, ...], ...]
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

  def properties(codepoint) when is_integer(codepoint) do
    [numeric(codepoint), Emoji.emoji(codepoint) | unquote(@properties_code)]
    |> Enum.reject(&is_nil/1)
  end

  def numeric(codepoint_or_binary) do
    if numeric?(codepoint_or_binary), do: :numeric, else: nil
  end

  def alphanumeric(codepoint_or_binary) do
    if alphanumeric?(codepoint_or_binary), do: :alphanumeric, else: nil
  end

  def extended_numeric(codepoint_or_binary) do
    if extended_numeric?(codepoint_or_binary), do: :extended_numeric, else: nil
  end

  @numeric_ranges Category.categories()[:Nd]

  def numeric?(codepoint)
      when unquote(Utils.ranges_to_guard_clause(@numeric_ranges)),
      do: true

  def numeric?(string) when is_binary(string) do
    string_has_property?(string, &numeric?/1)
  end

  def numeric?(_), do: false

  @extended_numeric_ranges @numeric_ranges ++
                             Category.categories()[:Nl] ++ Category.categories()[:No]

  def extended_numeric?(codepoint_or_binary)

  def extended_numeric?(codepoint)
      when unquote(Utils.ranges_to_guard_clause(@extended_numeric_ranges)),
      do: true

  def extended_numeric?(string) when is_binary(string) do
    string_has_property?(string, &extended_numeric?/1)
  end

  def extended_numeric?(_), do: false

  def alphanumeric?(codepoint_or_binary)

  def alphanumeric?(codepoint) when is_integer(codepoint) do
    alphabetic?(codepoint) or numeric?(codepoint)
  end

  def alphanumeric?(string) when is_binary(string) do
    string_has_property?(string, &alphanumeric?/1)
  end

  def alphanumeric?(_), do: false

  def emoji?(codepoint_or_binary)

  def emoji?(codepoint) when is_integer(codepoint) do
    ignorable?(codepoint) ||
      Emoji.emoji(codepoint) in Emoji.known_emoji_categories()
  end

  def emoji?(string) when is_binary(string) do
    string_has_property?(string, &emoji?/1)
  end

  def emoji?(_), do: false

  def ignorable?(codepoint) do
    properties = properties(codepoint)
    :case_ignorable in properties || :default_ignorable_code_point in properties
  end

  def math(codepoint_or_binary)
  def alphabetic(codepoint_or_binary)
  def lowercase(codepoint_or_binary)
  def uppercase(codepoint_or_binary)
  def case_ignorable(codepoint_or_binary)
  def cased(codepoint_or_binary)

  def math?(codepoint_or_binary)
  def alphabetic?(codepoint_or_binary)
  def lowercase?(codepoint_or_binary)
  def uppercase?(codepoint_or_binary)
  def case_ignorable?(codepoint_or_binary)
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
