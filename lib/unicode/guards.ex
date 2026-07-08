defmodule Unicode.Guards do
  @moduledoc """
  Defines a set of guards that can be used with
  Elixir functions to test whether a codepoint is
  a member of a Unicode set.

  Each guard operates on a single integer codepoint
  since the operators permitted in a guard clause are
  restricted to simple comparisons that do not include
  string comparators.

  The data that underpins these guards is generated
  from the Unicode character database and therefore
  includes a broad range of scripts well beyond the
  basic ASCII definitions.

  ### Usage

  Import or require the module and use the guards in a
  function clause `when` expression:

      defmodule MyModule do
        import Unicode.Guards

        def character_type(codepoint) when is_upper(codepoint), do: :upper
        def character_type(codepoint) when is_lower(codepoint), do: :lower
        def character_type(codepoint) when is_digit(codepoint), do: :digit
        def character_type(_codepoint), do: :other
      end

  ### Guards and macros

  Most guards are defined with `defguard/1`, so they compile once in this
  module, are cheap at every call site, and can be composed inside other
  guards. Their guard expression is built as a balanced tree of comparisons
  to keep the compiled guard within the BEAM's limits even for the large
  letter sets (`is_upper/1`, `is_lower/1`).

  The three graphic-set guards (`is_graph/1`, `is_print/1`, `is_visible/1`)
  each cover ~740 ranges, which exceeds the limit for a compiled `defguard`,
  so they are defined as macros expanded at each call site. Prefer using
  each in a single function clause.

  """

  alias Unicode.GeneralCategory
  alias Unicode.Utils

  # Whitespace as used by `is_whitespace/1` is the `Zs` category plus
  # the range 0x09..0x0d (tab, newline, vertical tab, form feed, carriage
  # return).
  @whitespace Utils.compact_ranges(Enum.sort([{0x09, 0x0D} | GeneralCategory.get(:Zs)]))

  # Blank is the `Zs` category plus the tab character, matching the POSIX
  # `[:blank:]` class.
  @blank Utils.compact_ranges(Enum.sort([{0x09, 0x09} | GeneralCategory.get(:Zs)]))

  # Ranges for the graphic sets used by `is_graph/1`, `is_print/1` and
  # `is_visible/1`.
  @graph GeneralCategory.get(:Graph)

  # Print is the graphic characters together with the space separators,
  # matching the POSIX `[:print:]` class (graph ∪ blank, less controls;
  # graph already excludes controls and the only control in blank is the
  # tab, so this reduces to graph ∪ Zs).
  @print Utils.compact_ranges(Enum.sort(GeneralCategory.get(:Graph) ++ GeneralCategory.get(:Zs)))

  # Each guard is a `defguard`, compiled once here rather than at each call
  # site. Each entry is {guard_name, codepoint_ranges, doc_or_false}. The
  # large sets (Lu, Ll, Graph, Print) rely on the balanced guard tree built
  # by `Unicode.Utils.ranges_to_guard_clause/1` to stay within the BEAM's
  # guard limits.
  @guards [
    {:is_upper, GeneralCategory.get(:Lu),
     """
     Guards whether a codepoint is an upper case character.

     Matches any codepoint that Unicode defines as an upper case letter
     (general category `Lu`) in any script.

     ### Examples

         iex> import Unicode.Guards
         iex> match?(codepoint when is_upper(codepoint), ?A)
         true
         iex> match?(codepoint when is_upper(codepoint), ?a)
         false

     """},
    {:is_lower, GeneralCategory.get(:Ll),
     """
     Guards whether a codepoint is a lower case character.

     Matches any codepoint that Unicode defines as a lower case letter
     (general category `Ll`) in any script.

     ### Examples

         iex> import Unicode.Guards
         iex> match?(codepoint when is_lower(codepoint), ?a)
         true
         iex> match?(codepoint when is_lower(codepoint), ?A)
         false

     """},
    {:is_digit, GeneralCategory.get(:Nd),
     """
     Guards whether a codepoint is a decimal digit character.

     Matches any decimal digit (general category `Nd`) from any
     Unicode script, not only the ASCII digits.

     ### Examples

         iex> import Unicode.Guards
         iex> match?(codepoint when is_digit(codepoint), ?5)
         true
         iex> match?(codepoint when is_digit(codepoint), ?x)
         false

     """},
    {:is_currency_symbol, GeneralCategory.get(:Sc),
     """
     Guards whether a codepoint is a currency symbol character.

     Matches any currency symbol (general category `Sc`).

     ### Examples

         iex> import Unicode.Guards
         iex> match?(codepoint when is_currency_symbol(codepoint), ?$)
         true

     """},
    {:is_whitespace, @whitespace,
     """
     Guards whether a codepoint is a whitespace character.

     Matches the Unicode `Zs` category plus the range 0x09..0x0d
     which includes tab, newline and carriage return.

     ### Examples

         iex> import Unicode.Guards
         iex> match?(codepoint when is_whitespace(codepoint), ?\\s)
         true
         iex> match?(codepoint when is_whitespace(codepoint), ?\\t)
         true

     """},
    {:is_separator, GeneralCategory.get(:Zs),
     """
     Guards whether a codepoint is a space separator character.

     Matches the Unicode `Zs` category.

     ### Examples

         iex> import Unicode.Guards
         iex> match?(codepoint when is_separator(codepoint), ?\\s)
         true

     """},
    {:is_blank, @blank,
     """
     Guards whether a codepoint is a blank character.

     Matches the space separators (`Zs`) together with the tab
     character, matching the POSIX `[:blank:]` class.

     ### Examples

         iex> import Unicode.Guards
         iex> match?(codepoint when is_blank(codepoint), ?\\t)
         true

     """},
    {:is_printable, GeneralCategory.get(:Printable),
     """
     Guards whether a codepoint is printable.

     Uses the same definition of printable as `String.printable?/1`.

     ### Examples

         iex> import Unicode.Guards
         iex> match?(codepoint when is_printable(codepoint), ?A)
         true

     """},
    {:is_quote_mark, GeneralCategory.get(:QuoteMark),
     """
     Guards whether a codepoint is a quotation mark.

     See also `Unicode.Category.QuoteMarks`.

     ### Examples

         iex> import Unicode.Guards
         iex> match?(codepoint when is_quote_mark(codepoint), ?")
         true

     """},
    {:is_quote_mark_left, GeneralCategory.get(:QuoteMarkLeft),
     """
     Guards whether a codepoint is a left quotation mark.

     See also `Unicode.Category.QuoteMarks`.

     ### Examples

         iex> import Unicode.Guards
         iex> match?(codepoint when is_quote_mark_left(codepoint), 0x00AB)
         true

     """},
    {:is_quote_mark_right, GeneralCategory.get(:QuoteMarkRight),
     """
     Guards whether a codepoint is a right quotation mark.

     See also `Unicode.Category.QuoteMarks`.

     ### Examples

         iex> import Unicode.Guards
         iex> match?(codepoint when is_quote_mark_right(codepoint), 0x00BB)
         true

     """},
    {:is_quote_mark_ambidextrous, GeneralCategory.get(:QuoteMarkAmbidextrous),
     """
     Guards whether a codepoint is a quotation mark that may be used
     as either a left or right mark.

     See also `Unicode.Category.QuoteMarks`.

     ### Examples

         iex> import Unicode.Guards
         iex> match?(codepoint when is_quote_mark_ambidextrous(codepoint), ?")
         true

     """},
    {:is_quote_mark_single, GeneralCategory.get(:QuoteMarkSingle),
     """
     Guards whether a codepoint is a single quotation mark.

     See also `Unicode.Category.QuoteMarks`.

     ### Examples

         iex> import Unicode.Guards
         iex> match?(codepoint when is_quote_mark_single(codepoint), ?')
         true

     """},
    {:is_quote_mark_double, GeneralCategory.get(:QuoteMarkDouble),
     """
     Guards whether a codepoint is a double quotation mark.

     See also `Unicode.Category.QuoteMarks`.

     ### Examples

         iex> import Unicode.Guards
         iex> match?(codepoint when is_quote_mark_double(codepoint), ?")
         true

     """}
  ]

  for {guard_name, ranges, doc} <- @guards do
    @doc doc
    defguard unquote(guard_name)(codepoint)
             when is_integer(codepoint) and
                    unquote(Utils.ranges_to_guard_clause(ranges))
  end

  # `is_graph/1`, `is_print/1` and `is_visible/1` each cover ~740-range
  # sets. A `defguard` over a set that large exceeds the BEAM's guard
  # stack-slot limit, so these are defined as macros whose guard expression
  # is expanded (and compiled) at each call site. Prefer using each in a
  # single function clause, since every `when` use recompiles the guard.

  @doc """
  Guards whether a codepoint is a graphic character.

  Graphic characters are those that are non-space, non-control,
  non-surrogate and assigned, as modelled by the `:Graph` derived
  general category.

  ### Examples

      iex> import Unicode.Guards
      iex> match?(codepoint when is_graph(codepoint), ?A)
      true
      iex> match?(codepoint when is_graph(codepoint), ?\\s)
      false

  """
  defmacro is_graph(codepoint) do
    guard = Utils.ranges_to_guard_clause(@graph, codepoint)

    quote generated: true do
      is_integer(unquote(codepoint)) and unquote(guard)
    end
  end

  @doc """
  Guards whether a codepoint is a printing character.

  Matches the combination of the graphic characters and the space
  separators, matching the POSIX `[:print:]` class.

  ### Examples

      iex> import Unicode.Guards
      iex> match?(codepoint when is_print(codepoint), ?A)
      true
      iex> match?(codepoint when is_print(codepoint), ?\\s)
      true

  """
  defmacro is_print(codepoint) do
    guard = Utils.ranges_to_guard_clause(@print, codepoint)

    quote generated: true do
      is_integer(unquote(codepoint)) and unquote(guard)
    end
  end

  @doc false
  # Retained for compatibility with `unicode_guards`; `is_graph/1` is the
  # preferred name. Uses the same `:Graph` derived category.
  defmacro is_visible(codepoint) do
    guard = Utils.ranges_to_guard_clause(@graph, codepoint)

    quote generated: true do
      is_integer(unquote(codepoint)) and unquote(guard)
    end
  end
end
