defmodule Unicode.Category do
  @moduledoc """
  Functions to introspect Unicode
  general categories for binaries
  (Strings) and codepoints.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.Utils

  @categories Utils.categories()
              |> Utils.remove_annotations()

  @super_categories @categories
                    |> Map.keys()
                    |> Enum.map(&to_string/1)
                    |> Enum.group_by(&String.slice(&1, 0, 1))
                    |> Enum.map(fn {k, v} ->
                      {String.to_atom(k),
                       Enum.flat_map(v, &Map.get(@categories, String.to_atom(&1))) |> Enum.sort()}
                    end)
                    |> Map.new()

  @all_categories Map.merge(@categories, @super_categories)

  @doc """
  Returns the map of Unicode
  character categories.

  The category name is the map
  key and a list of codepoint
  ranges as tuples as the value.

  """
  def categories do
    @all_categories
  end

  @doc """
  Returns a list of known Unicode
  category names.

  This function does not return the
  names of any category aliases.

  """
  @known_categories Map.keys(@all_categories)
  def known_categories do
    @known_categories
  end

  @category_alias Utils.property_value_alias()
  |> Map.get("gc")
  |> Enum.flat_map(fn
    [code, alias1] ->
      [{String.downcase(alias1), String.to_atom(code)},
      {String.downcase(code), String.to_atom(code)}]
    [code, alias1, alias2] ->
      [{String.downcase(alias1), String.to_atom(code)},
      {String.downcase(alias2), String.to_atom(code)},
      {String.downcase(code), String.to_atom(code)}]
  end)
  |> Map.new

  @doc """
  Returns a map of aliases for
  Unicode categories.

  An alias is an alternative name
  for referring to a category. Aliases
  are resolved by the `fetch/1` and
  `get/1` functions.

  """
  @impl Unicode.Property.Behaviour
  def aliases do
    @category_alias
  end

  @doc """
  Returns the Unicode ranges for
  a given category as a list of
  ranges as 2-tuples.

  Aliases are resolved by this function.

  Returns either `{:ok, range_list}` or
  `:error`.

  """
  @impl Unicode.Property.Behaviour
  def fetch(category) do
    category = Map.get(aliases(), category, category)
    Map.fetch(categories(), category)
  end

  @doc """
  Returns the Unicode ranges for
  a given category as a list of
  ranges as 2-tuples.

  Aliases are resolved by this function.

  Returns either `range_list` or
  `nil`.

  """
  @impl Unicode.Property.Behaviour
  def get(category) do
    case fetch(category) do
      {:ok, category} -> category
      _ -> nil
    end
  end

  @doc """
  Return the count of characters in a given
  category.

  ## Example

      iex> Unicode.Category.count(:Ll)
      2151

      iex> Unicode.Category.count(:Nd)
      630

  """
  @impl Unicode.Property.Behaviour
  def count(category) do
    with {:ok, category} <- fetch(category) do
      Enum.reduce(category, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the category name(s) for the
  given binary or codepoint.

  In the case of a codepoint, a single
  category name is returned.

  For a binary a list of distinct category
  names represented by the graphemes in
  the binary is returned.

  """
  def category(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&category/1)
    |> Enum.uniq()
  end

  for {category, ranges} <- @categories do
    def category(codepoint) when unquote(Utils.ranges_to_guard_clause(ranges)) do
      unquote(category)
    end
  end

  def category(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    :Cn
  end
end
