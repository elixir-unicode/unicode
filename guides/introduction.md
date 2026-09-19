# Introduction

This library makes the Unicode Character Database available as Elixir data: the properties of a codepoint, the codepoints that have a property, and character names in both directions. The database is compiled into the library, so a lookup is a function call — there is no data to load at runtime and no external dependency.

This guide covers the shape of the API and the questions it answers. The README has installation instructions and a summary of the function list.

## Codepoints and strings

Every lookup accepts either a codepoint or a string. Given a codepoint it returns one value; given a string it returns the distinct values of the codepoints in it, which is usually what you want when asking what a piece of text is made of.

```elixir
iex> Unicode.script(?ä)
:latin

iex> Unicode.script("Ελληνικά")
[:greek]

iex> Unicode.block("äA")
[:latin_1_supplement, :basic_latin]
```

## Three ways in

The same data is reachable three ways, and which one to use depends on whether the property is known when you write the code.

**The `Unicode` module** is the convenient way in when you know the property you want. It delegates to the module that owns the property, so `Unicode.script/1` and `Unicode.Script.script/1` are the same function.

```elixir
iex> Unicode.category(?A)
:Lu

iex> Unicode.block(?ä)
:latin_1_supplement

iex> Unicode.age(?A)
:"1.1"

iex> Unicode.numeric_value(?7)
7
```

**A property module** adds introspection of the property itself: which values exist, which codepoints have a value, and how many there are. Every enumerated property module offers the same five functions, so knowing one module is knowing all of them.

```elixir
iex> Unicode.Script.script(0x30FB)
:common

iex> Unicode.Script.count(:tirhuta)
82

iex> Unicode.Script.get(:tirhuta)
[{70784, 70855}, {70864, 70873}]

iex> length(Unicode.Script.known_scripts())
178
```

Codepoint sets are returned as a list of inclusive `{first, last}` ranges rather than a list of codepoints, which is how the database itself is organised and what makes the tables small enough to compile in.

**`Unicode.property_servers/0`** maps every property name and alias to the module that serves it, which is how a property named at runtime — from configuration, a query, or a set expression — is resolved. The keys are normalized the same way property names are matched, so any spelling of a name finds its module.

```elixir
iex> Unicode.property_servers() |> Map.get("sc")
Unicode.Script

iex> Unicode.property_servers() |> Map.get("jt")
Unicode.JoiningType
```

## Naming a property value

Property and value names can be spelled any way the database spells them. Matching ignores case, whitespace, `-` and `_`, and both the short and long forms of a name resolve, so `latn`, `Latin` and `:latin` are one script.

```elixir
iex> Unicode.Script.fetch("latn") == Unicode.Script.fetch(:latin)
true
```

Every codepoint has a value for every property, including the codepoints a data file does not mention: the database declares a default for those, and the default is a value like any other. Unassigned codepoints have a script of `Unknown`, and most characters have a joining type of `Non_Joining` even though `DerivedJoiningType.txt` lists only the ones that join.

```elixir
iex> Unicode.JoiningType.joining_type(?A)
:u

iex> Unicode.JoiningType.fetch("Non_Joining") |> elem(0)
:ok
```

## Boolean properties

Properties that a codepoint either has or does not have are answered by `Unicode.properties/1`, which lists them, and by a predicate for each one.

```elixir
iex> Unicode.properties(?+)
[:grapheme_base, :math, :pattern_syntax]

iex> Unicode.alphabetic?("abc")
true

iex> Unicode.emoji?("🧐")
true

iex> Unicode.Property.bidi_mirrored?(?()
true
```

The common ones — `Unicode.alphabetic?/1`, `Unicode.alphanumeric?/1`, `Unicode.digits?/1`, `Unicode.numeric?/1`, `Unicode.emoji?/1`, `Unicode.math?/1`, `Unicode.cased?/1`, `Unicode.lowercase?/1` and `Unicode.uppercase?/1` — have a function on `Unicode` itself. Any other binary property is reachable as `Unicode.Property.<name>?/1`.

## Character names

Names resolve in both directions. `to_codepoint/2` matches loosely, in the same way `\N{...}` does in a regular expression, and `to_name/1` returns the `Name` property.

```elixir
iex> Unicode.CharacterName.to_codepoint("BULLET")
{:ok, 8226}

iex> Unicode.CharacterName.to_name(0x2022)
{:ok, "BULLET"}
```

Names that follow a rule rather than being listed — CJK and Tangut ideographs, Hangul syllables, and the Seal and Jurchen characters, more than 131,000 of them — are computed instead of stored, and resolve the same way.

```elixir
iex> Unicode.CharacterName.to_name(0x4E00)
{:ok, "CJK UNIFIED IDEOGRAPH-4E00"}

iex> Unicode.CharacterName.to_codepoint("HANGUL SYLLABLE GA")
{:ok, 44032}
```

A character's name can never change once published, so the characters that need another name have an alias: the control characters, which have no `Name` at all, and the characters whose published name contains an error. `aliases/1` returns them with their types.

```elixir
iex> Unicode.CharacterName.to_codepoint("NULL")
{:ok, 0}

iex> Unicode.CharacterName.aliases(0x0000)
[control: "NULL", abbreviation: "NUL"]
```

When a name might be misspelled, `:fuzzy` resolves it by `String.jaro_distance/2`. It answers only when one name is strictly closer than all others, so an ambiguous query returns `:error` rather than guessing.

```elixir
iex> Unicode.CharacterName.to_codepoint("GRINING FACE", fuzzy: 0.9)
{:ok, 128512}
```

## Scripts and script extensions

A character has one `Script`, but many characters are used with several scripts, and for those the single value is `Common` or `Inherited` — which is rarely the answer you want when deciding whether a string belongs to one writing system. `Script_Extensions` gives the set of scripts a character is actually used with.

```elixir
iex> Unicode.Script.script(0x30FB)
:common

iex> Unicode.ScriptExtensions.script_extensions(0x30FB)
[:bopomofo, :han, :hangul, :hiragana, :katakana, :yi]

iex> Unicode.ScriptExtensions.script_extensions(?A)
[:latin]
```

## Guards

`Unicode.Guards` provides guards for the common character classes, so a codepoint can be classified in a function head rather than in the body.

```elixir
iex> import Unicode.Guards
iex> match?(codepoint when is_upper(codepoint), ?A)
true
```

```elixir
defmodule Classify do
  import Unicode.Guards

  def type(codepoint) when is_upper(codepoint), do: :upper
  def type(codepoint) when is_lower(codepoint), do: :lower
  def type(codepoint) when is_digit(codepoint), do: :digit
  def type(codepoint) when is_whitespace(codepoint), do: :whitespace
  def type(_codepoint), do: :other
end
```

The full set is `is_upper/1`, `is_lower/1`, `is_digit/1`, `is_whitespace/1`, `is_blank/1`, `is_separator/1`, `is_graph/1`, `is_print/1`, `is_printable/1`, `is_currency_symbol/1` and the quote mark guards `is_quote_mark/1`, `is_quote_mark_left/1`, `is_quote_mark_right/1`, `is_quote_mark_single/1`, `is_quote_mark_double/1` and `is_quote_mark_ambidextrous/1`.

## Working with text

Two functions operate on strings rather than answering questions about them. `Unicode.unaccent/1` strips diacritical marks, which is useful for building a sort or search key, and `Unicode.replace_invalid/3` replaces malformed byte sequences so that text from an untrusted source can be handled without crashing.

```elixir
iex> Unicode.unaccent("Étude")
"Etude"

iex> Unicode.replace_invalid(<<0xFF, "abc">>) == "�abc"
true
```

## Which version of Unicode

The version reported is the version of the data compiled into the library, which is not the library's own version number.

```elixir
iex> Unicode.version()
{18, 0, 0}
```

The database files live in the `data` directory of the package and are refreshed with `mix unicode.download`, which fetches them from unicode.org and checks that every file reports the same version.

## Beyond this library

This library answers questions about individual codepoints. Three libraries build on it for questions about text:

* [unicode_set](https://github.com/elixir-unicode/unicode_set) parses and matches [Unicode sets](http://unicode.org/reports/tr35/#Unicode_Sets), the `[\p{Lu}\p{Nd}]` expressions used throughout the standard.

* [unicode_string](https://github.com/elixir-unicode/unicode_string) splits text into graphemes, words, sentences and lines by the [Unicode segmentation](https://unicode.org/reports/tr29/) algorithms, and implements case mapping.

* [unicode_transform](https://github.com/elixir-unicode/unicode_transform) implements the [Unicode transform](https://unicode.org/reports/tr35/tr35-general.html#Transforms) specification.
