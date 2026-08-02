defmodule Unicode.CharacterName do
  @moduledoc """
  Resolves Unicode character names to their codepoint, and back again.

  Names are taken from the `Name` field of the Unicode Character Database
  (`UnicodeData.txt`). `to_codepoint/1` matches them loosely: case, whitespace,
  `_` and `-` are ignored (as in `\\N{...}` name lookups). Codepoints whose name
  is a bracketed label such as `<control>` have no `Name` property and are not
  resolvable in either direction.

  The names are prefix-compressed (front-coded) into a single sorted binary blob
  with block restart points, and looked up with a binary search over the restart
  names followed by a scan-decode within one block. This keeps the table compact
  without materialising a large map.

  `to_name/1` is the reverse lookup. Each name is stored **once**, in normalized
  form: rather than keeping a second copy of the original, the original is
  reconstructed by upper-casing and reinserting separators recorded at about 3
  bytes per name. That is exact because the `Name` property contains no lower
  case. Reverse lookup therefore costs a codepoint index and those separators,
  not a second name table, and leaves `to_codepoint/1` comparing whole binaries
  as before.

  ### Derived names

  CJK ideographs, Tangut ideographs, Hangul syllables and the Seal and Jurchen
  characters are recorded in `UnicodeData.txt` as `<..., First>`/`<..., Last>`
  range pairs with no per-character name, and their names are instead derived by
  the rules in [UAX #44](https://www.unicode.org/reports/tr44/#Name). These
  resolve, but are not part of the name table: they are computed from 15 range
  tuples and the Hangul jamo short names, under 4KB in total. Materialising them
  would add more than 131,000 names — over three times the size of the whole
  listed table — for characters whose names follow a rule.

  Derivation is attempted only when the table lookup misses, so it costs nothing
  on the common path.

  """

  alias Unicode.Utils

  # Bind the table to compile-time local variables rather than an intermediate
  # module attribute, so only the individual binaries (each referenced once in the
  # functions below) end up in the compiled module, not a duplicate tuple.
  {blob, restarts, codepoint_index, count} = Utils.character_name_table()
  @blob blob
  @restarts restarts
  @codepoint_index codepoint_index
  @count count
  @block_count div(byte_size(restarts), 4)
  @index_entry_size 6

  @name_block_size Utils.name_block_size()

  # Jaro distance used when `fuzzy: true` is given without an explicit threshold.
  @default_jaro_distance 0.8

  @doc """
  Returns the codepoint for a Unicode character name.

  ### Arguments

  * `name` is a Unicode character name as a string, matched loosely.

  * `options` is a keyword list of options.

  ### Options

  * `:fuzzy` enables approximate matching when the name is not found exactly. The value is either
    `true`, meaning use the default Jaro distance of `#{@default_jaro_distance}`, or a number
    between `0.0` and `1.0` giving the minimum distance to accept. The default is `false`, meaning
    exact matching only.

  ### Returns

  * `{:ok, codepoint}` or

  * `:error` if the name is not known, if a fuzzy search found no single best match, or if the
    `:fuzzy` option is not one of the forms above.

  ### Fuzzy matching

  A fuzzy search succeeds only when it resolves to one name: the closest name by
  `String.jaro_distance/2` must be at least as close as the threshold *and* strictly closer than
  every other name. A tie is treated as unresolved and returns `:error`, so an ambiguous query
  never silently picks one of several candidates.

  Because the threshold is a floor rather than a filter, it does not need to exclude the many names
  that are similar to any given query — of the roughly forty thousand names, `LATIN SMALL LETTER B`
  is close to `LATIN SMALL LETTER A` but is not the closest.

  Matching is against the listed names only; algorithmically derived names such as
  `CJK UNIFIED IDEOGRAPH-4E00` are not fuzzy-matched, since a near miss on the hexadecimal part
  would name a different character.

  Fuzzy matching scans every name and is several thousand times slower than an exact lookup. It is
  only attempted after an exact lookup has failed, so supplying the option costs nothing when the
  name is correct.

  ### Examples

      iex> Unicode.CharacterName.to_codepoint("LATIN SMALL LETTER A")
      {:ok, 97}

      iex> Unicode.CharacterName.to_codepoint("bullet")
      {:ok, 8226}

      iex> Unicode.CharacterName.to_codepoint("Not A Real Name")
      :error

      iex> Unicode.CharacterName.to_codepoint("LATIN SMALL LETER A", fuzzy: true)
      {:ok, 97}

      iex> Unicode.CharacterName.to_codepoint("GRINING FACE", fuzzy: 0.9)
      {:ok, 128512}

      iex> Unicode.CharacterName.to_codepoint("LATIN SMALL LETER A")
      :error

  """
  @spec to_codepoint(String.t(), Keyword.t()) :: {:ok, pos_integer()} | :error
  def to_codepoint(name, options \\ []) when is_binary(name) and is_list(options) do
    normalized = Utils.downcase_and_remove_whitespace(name)
    block = find_block(normalized, 0, @block_count - 1)

    with :error <- scan_block(normalized, block),
         :error <- derived_codepoint(normalized) do
      fuzzy_codepoint(normalized, jaro_distance(options))
    end
  end

  defp jaro_distance(options) do
    case Keyword.get(options, :fuzzy, false) do
      true -> @default_jaro_distance
      distance when is_number(distance) and distance >= 0 and distance <= 1 -> distance
      _other -> nil
    end
  end

  @doc """
  Returns the number of names in the table.

  """
  @spec count() :: non_neg_integer()
  def count, do: @count

  @doc """
  Returns the Unicode character name for a codepoint.

  ### Arguments

  * `codepoint` is a codepoint in the range `0..0x10FFFF`.

  ### Returns

  * `{:ok, name}` where `name` is the `Name` property of the codepoint, or

  * `:error` if the codepoint has no name. That includes control characters, surrogates, private
    use characters and unassigned codepoints, whose `Name` property is empty.

  ### Notes

  Reverse lookup shares the name table with `to_codepoint/1` rather than keeping its own copy of
  every name. It adds a 6 byte per name codepoint index and about 3 bytes per name of separator
  positions. Names that follow a derivation rule are computed instead of stored and cost nothing.

  Where two names differ only by a hyphen that loose matching removes, both resolve here to their
  own name even though only one of them is reachable through `to_codepoint/1`.

  ### Examples

      iex> Unicode.CharacterName.to_name(0x4E00)
      {:ok, "CJK UNIFIED IDEOGRAPH-4E00"}

      iex> Unicode.CharacterName.to_name(0xAC00)
      {:ok, "HANGUL SYLLABLE GA"}

      iex> Unicode.CharacterName.to_name(0x0000)
      :error

  """
  @doc since: "2.1.0"
  @spec to_name(non_neg_integer()) :: {:ok, String.t()} | :error
  def to_name(codepoint) when is_integer(codepoint) and codepoint in 0..0x10FFFF do
    case derived_name(codepoint) do
      {:ok, name} -> {:ok, name}
      :error -> listed_name(codepoint)
    end
  end

  # Binary search for the last block whose first (restart) name is `<=` the
  # query. The upper-biased midpoint guarantees termination.
  defp find_block(_name, low, low), do: low

  defp find_block(name, low, high) do
    middle = div(low + high + 1, 2)

    if block_first_name(middle) <= name do
      find_block(name, middle, high)
    else
      find_block(name, low, middle - 1)
    end
  end

  defp restart_offset(block) do
    <<offset::32>> = binary_part(@restarts, block * 4, 4)
    offset
  end

  defp block_first_name(block) do
    offset = restart_offset(block)
    <<name_length>> = binary_part(@blob, offset, 1)
    binary_part(@blob, offset + 1, name_length)
  end

  # Decode the block's restart name in full, then scan its front-coded entries.
  defp scan_block(query, block) do
    offset = restart_offset(block)

    block_end =
      if block + 1 < @block_count, do: restart_offset(block + 1), else: byte_size(@blob)

    <<name_length, name::binary-size(name_length), codepoint::24, separator_count,
      _separators::binary-size(separator_count), rest::binary>> =
      binary_part(@blob, offset, block_end - offset)

    scan(query, name, codepoint, rest)
  end

  defp scan(query, name, codepoint, rest) do
    cond do
      query == name ->
        {:ok, codepoint}

      # Names are sorted, so once we pass the query it cannot be present.
      query < name ->
        :error

      rest == <<>> ->
        :error

      true ->
        <<shared, suffix_length, suffix::binary-size(suffix_length), codepoint::24,
          separator_count, _separators::binary-size(separator_count), next_rest::binary>> = rest

        next_name = binary_part(name, 0, shared) <> suffix
        scan(query, next_name, codepoint, next_rest)
    end
  end

  # A fuzzy search succeeds only on a unique closest name, so the whole table is scanned and the
  # best and runner-up tracked. `nil` threshold means the option was absent or malformed.
  defp fuzzy_codepoint(_query, nil), do: :error

  defp fuzzy_codepoint(query, threshold) do
    case reduce_names({-1.0, nil, false}, &closest(query, threshold, &1, &2, &3)) do
      {_distance, codepoint, true} when codepoint != nil -> {:ok, codepoint}
      _ambiguous_or_absent -> :error
    end
  end

  defp closest(query, threshold, name, codepoint, {best, best_codepoint, _unique?} = accumulator) do
    # Deliberately pruned against the fixed threshold, not the best distance seen so far. Raising
    # the bar as the scan proceeds is roughly a third faster, but the bound is mathematically tight,
    # so a name that *exactly* achieves it is excluded by a one-ULP rounding difference. That silently
    # discards ties — `LATIN SMALL LETTER` is equidistant from every single-letter Latin name, and
    # pruning turned an ambiguous query into a confident wrong answer. Correctness of the
    # single-match guarantee is worth more here than the time.
    if plausible?(query, name, threshold) do
      distance = String.jaro_distance(query, name)

      cond do
        distance < threshold -> accumulator
        distance > best -> {distance, codepoint, true}
        distance == best -> {best, best_codepoint, false}
        true -> accumulator
      end
    else
      accumulator
    end
  end

  # Jaro distance is at most `(2 + shorter / longer) / 3`, reached when every character of the
  # shorter string matches in place. Names whose lengths are too far apart therefore cannot clear
  # the threshold, and comparing two lengths is far cheaper than scoring them. The tolerance keeps
  # a name that lands exactly on the bound from being excluded by floating point rounding.
  @bound_tolerance 1.0e-9

  defp plausible?(query, name, threshold) do
    shorter = min(byte_size(query), byte_size(name))
    longer = max(byte_size(query), byte_size(name))

    longer > 0 and shorter / longer >= 3 * threshold - 2 - @bound_tolerance
  end

  # Walks every name in the blob, front-decoding as it goes. Only fuzzy matching needs this; both
  # exact lookups reach their name through an index instead.
  defp reduce_names(accumulator, fun), do: reduce_names(@blob, 0, "", accumulator, fun)

  defp reduce_names(<<>>, _position, _previous, accumulator, _fun), do: accumulator

  defp reduce_names(blob, position, _previous, accumulator, fun)
       when rem(position, @name_block_size) == 0 do
    <<name_length, name::binary-size(name_length), codepoint::24, separator_count,
      _separators::binary-size(separator_count), rest::binary>> = blob

    reduce_names(rest, position + 1, name, fun.(name, codepoint, accumulator), fun)
  end

  defp reduce_names(blob, position, previous, accumulator, fun) do
    <<shared, suffix_length, suffix::binary-size(suffix_length), codepoint::24, separator_count,
      _separators::binary-size(separator_count), rest::binary>> = blob

    name = binary_part(previous, 0, shared) <> suffix
    reduce_names(rest, position + 1, name, fun.(name, codepoint, accumulator), fun)
  end

  # Names derived by rule rather than listed. These cost 15 range tuples and 67 jamo short names —
  # under 2KB — because the names are computed on demand rather than stored: the CJK, Tangut and
  # Seal ranges alone would add more than 130,000 entries to the table if they were materialised.
  # Only reached when the table lookup misses, so it costs nothing on the common path.
  @name_ranges Utils.character_name_ranges()
               |> Enum.map(fn {first, last, prefix} ->
                 {Utils.downcase_and_remove_whitespace(prefix), prefix, first, last}
               end)

  {leading, vowel, trailing} = Utils.jamo_short_names()

  downcase = fn names ->
    names |> Tuple.to_list() |> Enum.map(&String.downcase/1) |> List.to_tuple()
  end

  @jamo_leading downcase.(leading)
  @jamo_vowel downcase.(vowel)
  @jamo_trailing downcase.(trailing)

  @jamo_leading_name leading
  @jamo_vowel_name vowel
  @jamo_trailing_name trailing

  @hangul_first 0xAC00
  @hangul_last 0xD7A3
  @hangul_vowel_count tuple_size(vowel)
  @hangul_trailing_count tuple_size(trailing)

  defp derived_codepoint("hangulsyllable" <> jamo), do: hangul_codepoint(jamo)
  defp derived_codepoint(name), do: ranged_codepoint(name, @name_ranges)

  # UAX #44 rule NR2: the name is a fixed prefix followed by the codepoint in hexadecimal. The
  # range check matters — without it `CJK UNIFIED IDEOGRAPH-FFFFFF` would resolve to an unassigned
  # codepoint.
  defp ranged_codepoint(_name, []), do: :error

  defp ranged_codepoint(name, [{prefix, _display_prefix, first, last} | rest]) do
    with true <- String.starts_with?(name, prefix),
         suffix = binary_part(name, byte_size(prefix), byte_size(name) - byte_size(prefix)),
         {codepoint, ""} <- Integer.parse(suffix, 16),
         true <- codepoint >= first and codepoint <= last do
      {:ok, codepoint}
    else
      _other -> ranged_codepoint(name, rest)
    end
  end

  # UAX #44 rule NR1: the jamo short names of the leading consonant, vowel and optional trailing
  # consonant, concatenated.
  #
  # This backtracks rather than taking the longest match at each position, because two jamo have an
  # *empty* short name — CHOSEONG IEUNG and the absent trailing consonant — and the names are not
  # prefix-free. `HANGUL SYLLABLE A` is IEUNG + A with nothing for the leading consonant, while
  # `HANGUL SYLLABLE GA` is G + A; a greedy leading match cannot produce the first and a shortest
  # match cannot produce the second. The search space is a handful of candidates per position.
  defp hangul_codepoint(jamo) do
    Enum.find_value(jamo_candidates(@jamo_leading, jamo), :error, &hangul_from_leading/1)
  end

  defp hangul_from_leading({leading, after_leading}) do
    Enum.find_value(jamo_candidates(@jamo_vowel, after_leading), false, fn {vowel, after_vowel} ->
      hangul_from_vowel(leading, vowel, after_vowel)
    end)
  end

  defp hangul_from_vowel(leading, vowel, after_vowel) do
    case trailing_index(after_vowel) do
      {:ok, trailing} ->
        {:ok,
         @hangul_first + (leading * @hangul_vowel_count + vowel) * @hangul_trailing_count +
           trailing}

      :error ->
        false
    end
  end

  defp trailing_index(string) do
    case Enum.find(jamo_candidates(@jamo_trailing, string), &(elem(&1, 1) == "")) do
      {index, ""} -> {:ok, index}
      nil -> :error
    end
  end

  # The reverse of the two derivation rules. Free — the range tuples and jamo names are already
  # present for `to_codepoint/1` — so these resolve whether or not the name table is compiled in.
  defp derived_name(codepoint) when codepoint in @hangul_first..@hangul_last do
    index = codepoint - @hangul_first
    trailing = rem(index, @hangul_trailing_count)
    vowel = div(rem(index, @hangul_vowel_count * @hangul_trailing_count), @hangul_trailing_count)
    leading = div(index, @hangul_vowel_count * @hangul_trailing_count)

    {:ok,
     "HANGUL SYLLABLE " <>
       elem(@jamo_leading_name, leading) <>
       elem(@jamo_vowel_name, vowel) <> elem(@jamo_trailing_name, trailing)}
  end

  defp derived_name(codepoint), do: ranged_name(codepoint, @name_ranges)

  defp ranged_name(_codepoint, []), do: :error

  defp ranged_name(codepoint, [{_prefix, display_prefix, first, last} | _rest])
       when codepoint >= first and codepoint <= last do
    {:ok, display_prefix <> Integer.to_string(codepoint, 16)}
  end

  defp ranged_name(codepoint, [_range | rest]), do: ranged_name(codepoint, rest)

  # Reverse lookup binary-searches the codepoint index, which yields the name's block and position
  # within it, then decodes forward from that block's restart. The names themselves come from the
  # same blob `to_codepoint/1` uses — 6 bytes of index per name rather than a second copy.
  defp listed_name(codepoint) do
    case find_index_entry(codepoint, 0, div(byte_size(@codepoint_index), @index_entry_size) - 1) do
      {:ok, block, position} -> {:ok, decode_name(block, position)}
      :error -> :error
    end
  end

  defp find_index_entry(_codepoint, low, high) when low > high, do: :error

  defp find_index_entry(codepoint, low, high) do
    middle = div(low + high, 2)

    <<found::24, block::16, position::8>> =
      binary_part(@codepoint_index, middle * @index_entry_size, @index_entry_size)

    cond do
      found == codepoint -> {:ok, block, position}
      found < codepoint -> find_index_entry(codepoint, middle + 1, high)
      true -> find_index_entry(codepoint, low, middle - 1)
    end
  end

  # Decode `position` entries forward from the block restart. Bounded by the block size, so at most
  # 15 front-coded steps.
  defp decode_name(block, position) do
    offset = restart_offset(block)

    <<name_length, name::binary-size(name_length), _codepoint::24, separator_count,
      separators::binary-size(separator_count), rest::binary>> =
      binary_part(@blob, offset, byte_size(@blob) - offset)

    decode_name(name, separators, rest, position)
  end

  defp decode_name(name, separators, _rest, 0) do
    Utils.restore_character_name(name, separators)
  end

  defp decode_name(name, _separators, rest, remaining) do
    <<shared, suffix_length, suffix::binary-size(suffix_length), _codepoint::24, separator_count,
      separators::binary-size(separator_count), next_rest::binary>> = rest

    decode_name(binary_part(name, 0, shared) <> suffix, separators, next_rest, remaining - 1)
  end

  # Every jamo whose short name prefixes the string, longest first. The empty short name matches
  # anything and so always sorts last, making it the fallback rather than the first choice.
  defp jamo_candidates(names, string) do
    0..(tuple_size(names) - 1)
    |> Enum.filter(&String.starts_with?(string, elem(names, &1)))
    |> Enum.sort_by(&(-byte_size(elem(names, &1))))
    |> Enum.map(fn index ->
      name = elem(names, index)
      {index, binary_part(string, byte_size(name), byte_size(string) - byte_size(name))}
    end)
  end
end
