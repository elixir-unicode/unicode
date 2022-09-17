# Changelog

## Unicode v1.13.1

This is the changelog for Unicode v1.13.1 released on September 16th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-unicode/unicode/tags)

### Bug Fixes

* When looking up scripts, general categories and properties we indirect through an alias table. But not all entries have alias so in the case alias lookup fails we still need to lookup using the original key.

## Unicode v1.13.0

This is the changelog for Unicode v1.13.0 released on September 15th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-unicode/unicode/tags)

### Enhancements

* Change the application name to `:unicode` (in collaboration with @Qqwy). The old name `ex_unicode` will be retired.

## Unicode v1.12.0

This is the changelog for Unicode v1.12.0 released on September 14th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-unicode/unicode/tags)

### Enhancements

* Update to use [Unicode 14](https://unicode.org/versions/Unicode14.0.0) release data.

## Unicode v1.12.0-rc.0

This is the changelog for Unicode v1.12.0-rc.0 released on August 27th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-unicode/unicode/tags)

### Enhancements

* Updates to Unicode 14 preview data.

## Unicode v1.11.2

This is the changelog for Unicode v1.11.2 released on May 25th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-unicode/unicode/tags)

### Bug fixes

* Make `ex_doc` and `benchee` optional. Thanks to @fireproofsocks.

## Unicode v1.11.1

This is the changelog for Unicode v1.11.1 released on January 5th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-unicode/unicode/tags)

### Bug fixes

* Restrict `ex_doc` to only `:dev` and `:release`. Closes #3. Thanks to @manuelmontenegro.

* Fix spec for `Unicode.all/0` so dialyzer is happy

## Unicode v1.11.0

This is the changelog for Unicode v1.11.0 released on October 8th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-unicode/unicode/tags)

### Bug fixes

* Rename the derived category `:visible` to `:graph` and change the definition to that in [Unicode Regular Expressions](http://unicode.org/reports/tr18/). Deprecate the derived category `:visible`.

## Unicode v1.10.0

This is the changelog for Unicode v1.10.0 released on October 5th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-unicode/unicode/tags)

### Bug fixes

* Revert "Change the definition of the derived property `All` to be the disjoint set of unicode ranges, not the closed set." since `All` in the ICU means the full range of codepoints, assigned or otherwise.

* Add `:inets` and `:public_key` to `:extra_applicatons` to avoid warnings on Elixir 1.11.

### Enhancements

* Add `Unicode.assigned/0` to return the list of codepoint ranges that are assigned within Unicode

* Rename `Unicode.ranges/0` to `Unicode.all/0` to better reflect the intent. `Unicode.ranges/0` is deprecated.


## Unicode v1.9.0

This is the changelog for Unicode v1.9.0 released on October 4th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-unicode/unicode/tags)

### Enhancements

* Change the definition of the derived property `All` to be the disjoint set of unicode ranges, not the closed set.

## Unicode v1.8.0

This is the changelog for Unicode v1.8.0 released on July 12th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-unicode/unicode/tags)

### Enhancements

* Add the east asian width property to `Unicode.Property.fetch/2` API

* Add the word break property to `Unicode.Property.fetch/2` API

## Unicode v1.7.0

This is the changelog for Unicode v1.7.0 released on June 22nd, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-unicode/unicode/tags)

### Enhancements

* Add the emoji properties to `Uniccode.Property.fetch/2` API

* Add certificate verification to download process

## Unicode v1.6.0

This is the changelog for Unicode v1.6.0 released on May 17th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-unicode/unicode/tags)

### Enhancements

* Add `Unicode.Utils.case_folding/0`

* Add `Unicode.Utils.special_casing/0`

## Unicode v1.5.0

This is the changelog for Unicode v1.5.0 released on March 14th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-unicode/unicode/tags)

### Enhancements

* Add derived categories `:printable:` and `:visible:`. `:printable:` implements the same semnantics `String.printable?/1`. `:visible:` combines the categories `[[:L:][:N:][:M:][:P:][:S:][:Zs:]]`.

## Unicode v1.4.1

This is the changelog for Unicode v1.4.1 released on March 11th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-unicode/unicode/tags)

### Bug Fixes

* Regenerate the assigned ranges for Unicode 13

## Unicode v1.4.0

This is the changelog for Unicode v1.4.0 released on March 11th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-unicode/unicode/tags)

### Enhancements

#### Updates Unicode to version 13.0.

As of March 2020, Unicode has introduced [Unicode 13.0](http://blog.unicode.org/2020/03/announcing-unicode-standard-version-130.html) and this data now forms the basis of `ex_unicode` version 1.40. Version 13 of Unicode adds 5,390 characters, for a total of 143,859 characters. These additions include four new scripts, for a total of 154 scripts, as well as 55 new emoji characters.

#### Adds derived categories for various quotation marks.

Although the unicode character database has a flag to indicate if a given codepoint is a quotation mark, the list does not include CJK quotation marks, dingbats or alternative encodings. Some additional derived categories are therefore added that are taken from [Wikipedia](https://en.wikipedia.org/wiki/Quotation_mark). The added dervived categories are:

  * QuoteMark - all quote marks
  * QuoteMarkLeft - all quote marks used on the left
  * QuoteMarkRight - quote marks used on the right
  * QuoteMarkAmbidextrous - quote marks used either left or right
  * QuoteMarkSingle - single quote marks
  * QuoteMarkDouble - double quote marks

These additional derived categories can be used in [Unicode Sets](https://hex.pm/packages/unicode_sets), for example:

```
iex> Unicode.Set.match? ?', "[[:quote_mark:]]"
true
iex> Unicode.Set.match? ?', "[[:quote_mark_left:]]"
false
iex> Unicode.Set.match? ?', "[[:quote_mark_ambidextrous:]]"
true
````

## Unicode v1.3.1

This is the changelog for Unicode v1.3.1 released on January 8th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-unicode/unicode/tags)

### Bug Fixes

* Remove call to `Code.ensure_compiled?/1` which is deprecated in Elixir 1.10.0.

* Fix the ranges for the General Category `:assigned`.

## Unicode v1.3.0

This is the changelog for Unicode v1.3.0 released on December 3rd, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-unicode/unicode/tags)

### Breaking Changes

* Changed two module names: `Unicode.Category` becomes `Unicode.GeneralCategory` and `Unicode.CombiningClass` becomes `Unicode.CanonicalCombiningClass`. These names map directly to the Unicode standard names. It also means all property module names can be derived from the Unicode property name which is what the new `Unicode.servers/0` function does.

### Enhancements

* Add property modules for line break, sentence break, grapheme cluster break and indic syllabic category. These properties are used by the CLDR and Unicode segmentation rules.

* Add `Unicode.servers/0` that maps property names and aliases to a module name that serves that property.

### Bug fixes

* Fixes `Unicode.aliases/0` to correctly use the aliases in `data/property_alias.txt`

## Unicode v1.2.0

This is the changelog for Unicode v1.2.0 released on November 27th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-unicode/unicode/tags)

### Breaking Changes

* Script names are now atoms instead of strings to be consistent with other properties

### Enhancements

* Add `aliases/0`, `fetch/1` and `get/1` to `Unicode.Property`

* Added additional properties to `Unicode.Property`. The set now includes those from the UCD files `DerivedCoreProperties.txt` and `PropList.txt`.

## Unicode v1.1.0

This is the changelog for Unicode v1.1.0 released on November 23rd, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-unicode/unicode/tags)

### Breaking Changes

* Removed `Unicode.Guards` from this library and moved them to the [unicode_set](https://hex.pm/packages/unicode_guards) package.

### Enhancements

* `Unicode.Category.categories/0` now returns the super categories as well as the subcategories. These super categories are computed at compile time by consolidating the relevant subcategories. `Unicode.Category.category/1` will only return one category, and it will be the subcategory as it consistent with earlier releases.

* Add `Unicode.ranges/0` that returns all Unicode codepoints as a list of 2-tuples representing the disjoint ranges of valid codepoints. The list is in sorted order.

* Add `aliases/0` for `Unicode.Category`, `Unicode.Script`, `Unicode.Block`, and `Unicode.CombiningClass` which returns the alias map for the relevant module.

* Add `fetch/1` and `get/1` for `Unicode.Category`, `Unicode.Script`, `Unicode.Block`, and `Unicode.CombiningClass`. These functions leverage Unicode property value aliases for retrieving codepoints.

* Add `Unicode.fetch_property/1` and `Unicode.get_property/1` that return the module responsible for handling a given Unicode property.

* Add `Unicode.compact_ranges/1` that given a list of 2-tuple ranges will compact them into as small a list of contiguous blocks as possible

* Documented all public functions

## Unicode v1.0.0

This is the changelog for Unicode v1.0.0 released on November 14th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-unicode/unicode/tags)

### Breaking Changes

* Rename the module prefix to `Unicode` since this package is not linked in any way to the `Cldr` family. The hex package is renamed to `ex_unicode`.

## Cldr Unicode v0.7.1

This is the changelog for Unicode v0.7.1 released on November 12th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_unicode/tags)

### Bug Fixes

* Fixes `count/1` for blocks, scripts and categories

* Replace deprecated `String.normalize/2` with `:unicode.characters_to_nfd_binary/` for OTP release 20 and later.

## Cldr Unicode v0.7.0

This is the changelog for Unicode v0.7.0 released on November 12th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_unicode/tags)

### Enhancements

* Add `is_whitespace/1` guard generator

## Cldr Unicode v0.6.0

This is the changelog for Unicode v0.6.0 released on October 22nd, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_unicode/tags)

### Enhancements

* Update to Emoji 12.1

## Cldr Unicode v0.5.0

This is the changelog for Unicode v0.5.0 released on May 12th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_unicode/tags)

### Enhancements

* Update to Unicode 12.1

## Cldr Unicode v0.4.0

This is the changelog for Unicode v0.4.0 released on April 30th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_unicode/tags)

### Enhancements

* Adds `Cldr.Unicode.unaccent/1`

### Breaking Changes

* Block names are now atoms instead of strings

## Cldr Unicode v0.3.0

This is the changelog for Unicode v0.3.0 released on March 28th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_unicode/tags)

### Enhancements

* Updated to Unicode version 12

## Cldr Unicode v0.2.0

This is the changelog for Unicode v0.2.0 released on February 24th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_unicode/tags)

### Enhancements

* Moves the public API to the `Cldr.Unicode` module.

* Updates and adds documentation to all public functions.

* Removes the text annotations from the compiled functions which materially reduces the size of the beam files.

## Cldr Unicode v0.1.0

This is the changelog for Unicode v0.1.0 released on February 23rd, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_unicode/tags)

### Enhancements

* Initial release
