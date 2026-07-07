defmodule Unicode.GeneralCategory do
  @moduledoc """
  Functions to introspect the Unicode general category property for binaries (Strings) and codepoints.

  The primary API is `category/1` which returns the general category of a codepoint, or the list of general categories of a string.

  The functions `fetch/1`, `get/1` and `count/1` provide introspection of the codepoint ranges belonging to a category. `categories/0`, `known_categories/0` and `aliases/0` return the underlying category data.

  """

  @behaviour Unicode.Property.Behaviour

  alias Unicode.GeneralCategory.Derived
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
                  |> Map.merge(Derived.categories())

  @category_table Unicode.RangeSearch.new_value_table(@categories)

  @doc """
  Returns the map of Unicode character categories.

  ### Returns

  * A map where the category name is the key and a list of codepoint ranges as 2-tuples is the value.

  ### Examples

      iex> Unicode.GeneralCategory.categories() |> Map.get(:Zl)
      [{8232, 8232}]

  """
  def categories do
    @all_categories
  end

  @doc """
  Returns a list of known Unicode category names.

  This function does not return the names of any category aliases.

  ### Returns

  * A list of atom category names.

  ### Examples

      iex> :Lu in Unicode.GeneralCategory.known_categories()
      true

  """
  @known_categories Map.keys(@all_categories)
  def known_categories do
    @known_categories
  end

  @category_alias Utils.property_value_alias()
                  |> Map.get("gc")
                  |> Utils.capitalize_values()
                  |> Utils.atomize_values()
                  |> Utils.downcase_keys_and_remove_whitespace()
                  |> Utils.add_canonical_alias()
                  |> Map.merge(Derived.aliases())

  @doc """
  Returns a map of aliases for Unicode categories.

  An alias is an alternative name for referring to a category. Aliases are resolved by the `fetch/1` and `get/1` functions.

  ### Returns

  * A map where the alias string is the key and the category name is the value.

  ### Examples

      iex> Unicode.GeneralCategory.aliases() |> Map.get("lowercaseletter")
      :Ll

  """
  @impl Unicode.Property.Behaviour
  def aliases do
    @category_alias
  end

  @doc """
  Returns the Unicode codepoint ranges for a given category.

  Aliases are resolved by this function.

  ### Arguments

  * `category` is any category name or alias, as an atom or string.

  ### Returns

  * `{:ok, range_list}` where `range_list` is a list of codepoint ranges as 2-tuples.

  * `:error` if the category is not known.

  ### Examples

      iex> Unicode.GeneralCategory.fetch(:Zl)
      {:ok, [{8232, 8232}]}

      iex> Unicode.GeneralCategory.fetch(:invalid)
      :error

  """
  @impl Unicode.Property.Behaviour
  def fetch(category) when is_atom(category) do
    Map.fetch(categories(), category)
  end

  def fetch(category) do
    category = Utils.downcase_and_remove_whitespace(category)
    category = Map.get(aliases(), category, category) |> Utils.maybe_atomize()
    Map.fetch(categories(), category)
  end

  @doc """
  Returns the Unicode codepoint ranges for a given category.

  Aliases are resolved by this function.

  ### Arguments

  * `category` is any category name or alias, as an atom or string.

  ### Returns

  * A list of codepoint ranges as 2-tuples.

  * `nil` if the category is not known.

  ### Examples

      iex> Unicode.GeneralCategory.get(:Zl)
      [{8232, 8232}]

      iex> Unicode.GeneralCategory.get(:invalid)
      nil

  """
  @impl Unicode.Property.Behaviour
  def get(category) do
    case fetch(category) do
      {:ok, category} -> category
      _ -> nil
    end
  end

  @doc """
  Returns the count of characters in a given category.

  Aliases are resolved by this function.

  ### Arguments

  * `category` is any category name or alias, as an atom or string.

  ### Returns

  * A non-negative integer count of the codepoints in the category.

  * `:error` if the category is not known.

  ### Examples

      iex> Unicode.GeneralCategory.count(:Ll)
      2283

      iex> Unicode.GeneralCategory.count(:Nd)
      770

  """
  @impl Unicode.Property.Behaviour
  def count(category) do
    with {:ok, category} <- fetch(category) do
      Enum.reduce(category, 0, fn {from, to}, acc -> acc + to - from + 1 end)
    end
  end

  @doc """
  Returns the category name(s) for the given binary or codepoint.

  Only concrete general categories are considered. Derived categories (`:all`, `:ascii`, `:assigned` and so on) are not considered.

  ### Arguments

  * `string_or_codepoint` is either a binary (String) or a codepoint in the range `0..0x10FFFF`.

  ### Returns

  * For a codepoint, a single category name is returned.

  * For a binary, a list of the distinct category names of the codepoints in the binary is returned.

  ### Examples

      iex> Unicode.GeneralCategory.category(?A)
      :Lu

      iex> Unicode.GeneralCategory.category("abc")
      [:Ll]

  """
  def category(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> Enum.map(&category/1)
    |> Enum.uniq()
  end

  def category(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    Unicode.RangeSearch.find(@category_table, codepoint, :Cn)
  end
end
