defmodule Unicode.RangeSearch do
  @moduledoc """
  Builds compact search tables from codepoint ranges and performs binary search over them.

  The Unicode property modules build their search tables at compile time from the range data returned by functions such as `Unicode.GeneralCategory.categories/0`. The tables are stored as module attributes so they are embedded in the compiled module as literals and shared, not copied, at runtime.

  Two table shapes are supported:

  * A *value table*, built with `new_value_table/1` from a map of `value => ranges`, returns the value associated with the range containing a codepoint via `find/3`.

  * A *membership table*, built with `new_membership_table/1` from a list of ranges, answers whether a codepoint is within any range via `member?/2`.

  Binary search over these tables replaces the very large generated guard clauses previously used for codepoint lookup, reducing compile time by an order of magnitude and lookup time by approximately 10x.

  """

  @typedoc "A tuple of range starts, range ends and the value for each range."
  @type value_table :: {tuple(), tuple(), tuple()}

  @typedoc "A tuple of range starts and range ends."
  @type membership_table :: {tuple(), tuple()}

  @typedoc "A codepoint range expressed as an inclusive 2-tuple."
  @type range :: {non_neg_integer(), non_neg_integer()}

  @doc """
  Builds a value table from a map of values to codepoint ranges.

  ### Arguments

  * `range_map` is a map with any term as the key and a list of 2-tuple codepoint ranges as the value.

  ### Returns

  * A `t:value_table/0` suitable for use with `find/3`.

  Ranges whose bounds are not integers (for example, multi-codepoint emoji sequence ranges) are ignored. Raises `ArgumentError` if ranges associated with different values overlap, since the table cannot then return a single value for a codepoint.

  ### Examples

      iex> table = Unicode.RangeSearch.new_value_table(%{lower: [{?a, ?z}], upper: [{?A, ?Z}]})
      iex> Unicode.RangeSearch.find(table, ?q, :none)
      :lower
      iex> Unicode.RangeSearch.find(table, ?5, :none)
      :none

  """
  @spec new_value_table(%{any() => [range(), ...]}) :: value_table()
  def new_value_table(range_map) do
    entries =
      range_map
      |> Enum.flat_map(fn {value, ranges} ->
        for {first, last} <- ranges, is_integer(first) and is_integer(last) do
          {first, last, value}
        end
      end)
      |> Enum.sort()

    validate_disjoint!(entries)

    {
      entries |> Enum.map(&elem(&1, 0)) |> List.to_tuple(),
      entries |> Enum.map(&elem(&1, 1)) |> List.to_tuple(),
      entries |> Enum.map(&elem(&1, 2)) |> List.to_tuple()
    }
  end

  @doc """
  Builds a membership table from a list of codepoint ranges.

  ### Arguments

  * `ranges` is a list of 2-tuple codepoint ranges.

  ### Returns

  * A `t:membership_table/0` suitable for use with `member?/2`.

  Ranges whose bounds are not integers (for example, multi-codepoint emoji sequence ranges) are ignored. Overlapping and adjacent ranges are merged.

  ### Examples

      iex> table = Unicode.RangeSearch.new_membership_table([{?a, ?z}, {?0, ?9}])
      iex> Unicode.RangeSearch.member?(table, ?x)
      true
      iex> Unicode.RangeSearch.member?(table, ?!)
      false

  """
  @spec new_membership_table([range(), ...]) :: membership_table()
  def new_membership_table(ranges) do
    merged =
      ranges
      |> Enum.filter(fn {first, last} -> is_integer(first) and is_integer(last) end)
      |> Enum.sort()
      |> merge_ranges()

    {
      merged |> Enum.map(&elem(&1, 0)) |> List.to_tuple(),
      merged |> Enum.map(&elem(&1, 1)) |> List.to_tuple()
    }
  end

  @doc """
  Returns the value for the range containing a codepoint.

  ### Arguments

  * `value_table` is a table built with `new_value_table/1`.

  * `codepoint` is an integer codepoint.

  * `default` is the term returned when no range contains `codepoint`.

  ### Returns

  * The value associated with the range containing `codepoint`, or `default`.

  ### Examples

      iex> table = Unicode.RangeSearch.new_value_table(%{lower: [{?a, ?z}], upper: [{?A, ?Z}]})
      iex> Unicode.RangeSearch.find(table, ?A, :none)
      :upper

  """
  @spec find(value_table(), integer(), any()) :: any()
  def find({starts, ends, values}, codepoint, default) when is_integer(codepoint) do
    case search(starts, ends, codepoint, 1, tuple_size(starts)) do
      nil -> default
      index -> elem(values, index - 1)
    end
  end

  @doc """
  Returns whether any range in a membership table contains a codepoint.

  ### Arguments

  * `membership_table` is a table built with `new_membership_table/1`.

  * `codepoint` is an integer codepoint.

  ### Returns

  * `true` if a range contains `codepoint`, otherwise `false`.

  ### Examples

      iex> table = Unicode.RangeSearch.new_membership_table([{?0, ?9}])
      iex> Unicode.RangeSearch.member?(table, ?7)
      true

  """
  @spec member?(membership_table(), integer()) :: boolean()
  def member?({starts, ends}, codepoint) when is_integer(codepoint) do
    search(starts, ends, codepoint, 1, tuple_size(starts)) != nil
  end

  defp validate_disjoint!(entries) do
    Enum.reduce(entries, -1, fn {first, last, value}, previous_last ->
      if first <= previous_last do
        raise ArgumentError,
              "overlapping ranges cannot form a value table: " <>
                "range #{inspect({first, last})} for #{inspect(value)} " <>
                "overlaps a range ending at #{previous_last}"
      end

      last
    end)
  end

  defp search(_starts, _ends, _codepoint, low, high) when low > high do
    nil
  end

  defp search(starts, ends, codepoint, low, high) do
    middle = div(low + high, 2)

    cond do
      codepoint < elem(starts, middle - 1) -> search(starts, ends, codepoint, low, middle - 1)
      codepoint > elem(ends, middle - 1) -> search(starts, ends, codepoint, middle + 1, high)
      true -> middle
    end
  end

  defp merge_ranges([]) do
    []
  end

  defp merge_ranges([{first, last}, {next_first, next_last} | rest])
       when next_first <= last + 1 do
    merge_ranges([{first, max(last, next_last)} | rest])
  end

  defp merge_ranges([range | rest]) do
    [range | merge_ranges(rest)]
  end
end
