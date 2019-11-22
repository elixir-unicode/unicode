# Unicode

Functions to return information about Unicode codepoints.

Elixir string are UTF8-encoded [Unicode](https://unicode.org) binaries. This is a flexible and complete encoding scheme for the worlds many scripts, characters and emjois. However since its a variable lenght encoding (using between one and four bytes for UTF8) it is harder to use high-performance byte-oriented functions to decompose strings.

Since checking strings and codepoints for certain attributes - like whether they are upper case, or symbols, or whitespace - is a common occurrence, a performant approach to such detection is useful.

It is tempting to assume the use of [US ASCII](https://en.wikipedia.org/wiki/ASCII) encoding and checking only for characters in that range. For example it is very common to see code in Elixir checking `codepoint in ?a..?z` to check for lowercase alphabetic characters. When the underlying programming language has no canonical form for a string beyond bytes this may be considered acceptable - the programmer is defining the script domain as he or she sees fit.

However Elixir string are declared to be [UTF8 encoded Unicode string](https://unicode.org/faq/utf_bom.html#utf8-1) it seems appropriate to make it easier to determins the characteristics of codepoints (and strings) using this standard.

The Elixir standard library does not provide introspection beyond that required to support casing (String.downcase/1, String.upcase/1, String.capitalize/1).  This library aims to *fill in the blanks* a little bit.

## Additional Unicode libraries

[ex_unicode](https://hex.pm/packages/ex_unicode) provides basic introspection into Unicode codepoints and strings.  Additional libraries (either releases or in development) buil upon this library):

* [unicode_set](https://github.com/elixir-unicode/unicode_set) implements functions to parse and match on [unicode sets](http://unicode.org/reports/tr35/#Unicode_Sets)

* [unicode_guards](https://github.com/elixir-unicode/unicode_guards) is a simple library implementing common function guards using `unicode_set` and `ex_unicode`

* [unicode_string](https://github.com/elixir-unicode/unicode_string) is a library to implement efficient string splitting and replacing based upon unicode sets

* [unicode_transform](https://github.com/elixir-unicode/unicode_transform) implements the [Unicode transform](https://unicode.org/reports/tr35/tr35-general.html#Transforms) specification.

## Unicode Functions

The following is a partial list of functions included in the library. See the documentation for the relevant module for further information:

### Codepoint ranges

These functions return the codepoints as list of 2-tuples for the given property:

* `Unicode.Block.blocks/0`
* `Unicode.Script.scripts/0`
* `Unicode.Category.categories/0`
* `Unicode.CombiningClass.combining_classes/0`

### Basic introspection of codepoints and string

The following functions return the block, script and category for codepoints and strings:

* `Unicode.script/1`
```
iex> Unicode.script ?ä
"latin"

iex> Unicode.script ?خ
"arabic"

iex> Unicode.script ?अ
"devanagari"
```

* `Unicode.block/1`
```
iex> Unicode.block ?ä
:latin_1_supplement

iex> Unicode.block ?A
:basic_latin

iex> Unicode.block "äA"
[:latin_1_supplement, :basic_latin]
```

* `Unicode.category/1`

```
iex> Unicode.category ?ä
:Ll
iex> Unicode.category ?A
:Lu
iex> Unicode.category ?🧐
:So
```

* `Unicode.properties/1`
```
iex> Unicode.properties 0x1bf0
[:alphabetic, :case_ignorable]

iex> Unicode.properties ?A
[:alphabetic, :uppercase, :cased]

iex> Unicode.properties ?+
[:math]

iex> Unicode.properties "a1+"
[[:alphabetic, :lowercase, :cased], [:numeric, :emoji], [:math]]
```

### Character classes

These functions help filter codepoints and strings based upon their properties. They return a boolean result.

* Unicode.alphabetic?/1
* Unicode.alphanumeric?/1
* Unicode.digits?/1
* Unicode.numeric?/1
* Unicode.emoji?/1
* Unicode.math?/1
* Unicode.cased?/1
* Unicode.lowercase?/1
* Unicode.uppercase?/1'
'
### Transformations

The function `Unicode.unaccent/1` attempts to transform a Unicode string into a subset of the Latin-1 alphabet by removing diacritical marks from text. It is not a full transformation (which will be available in the upcoming `unicode_transform` library.)

## Recognition

The information functions are heavily inspired by [@qqwy's elixir-unicode package](https://github.com/Qqwy/elixir-unicode) and compatibility with some of the api is represented by including some of the doctests from that package.

## Installation

The package can be installed by adding `ex_unicode` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_unicode, "~> 1.0"}
  ]
end
```

The docs can be found at [https://hexdocs.pm/ex_unicode](https://hexdocs.pm/ex_unicode).
