# Changelog for Unicode v1.1.0

This is the changelog for Unicode v1.1.0 released on ______, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/unicode/tags)

### Breaking Changes

* Removed `Unicode.Guards` from this library and moved them to the [unicode_set](https://hex.pm/packages/unicode_set) package.

### Enhancements

* `Unicode.Category.categories/0` now returns the super categories as well as the subcategories. These super categories are computed at compile time by consolidating the relevant subcategories. `Unicode.Category.category/1` will only return one category, and it will be the subcategory as it consistent with earlier releases.

* Add `Unicode.ranges/0` that returns all Unicode codepoints as a list of 2-tuples representing the disjoint ranges of valid codepoints. The list is in sorted order.

* Add `aliases/0` for `Unicode.Category`, `Unicode.Script`, `Unicode.Block`, and `Unicode.CombiningClass` which returns the alias map for the relevant module.

* Add `fetch/1` and `get/1` for `Unicode.Category`, `Unicode.Script`, `Unicode.Block`, and `Unicode.CombiningClass`. These functions leverage Unicode property value aliases for retrieving codepoints.

* Add `Unicode.fetch_property/1` and `Unicode.get_property/1` that return the module responsible for handling a given Unicode property.

* Add `Unicode.compact_ranges/1` that given a list of 2-tuple ranges will compact them into as small a list of contiguous blocks as possible

# Changelog for Unicode v1.0.0

This is the changelog for Unicode v1.0.0 released on November 14th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/unicode/tags)

### Breaking Changes

* Rename the module prefix to `Unicode` since this package is not linked in any way to the `Cldr` family. The hex package is renamed to `ex_unicode`.

# Changelog for Cldr Unicode v0.7.1

This is the changelog for Unicode v0.7.1 released on November 12th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_unicode/tags)

### Bug Fixes

* Fixes `count/1` for blocks, scripts and categories

* Replace deprecated `String.normalize/2` with `:unicode.characters_to_nfd_binary/` for OTP release 20 and later.

# Changelog for Cldr Unicode v0.7.0

This is the changelog for Unicode v0.7.0 released on November 12th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_unicode/tags)

### Enhancements

* Add `is_whitespace/1` guard generator

# Changelog for Cldr Unicode v0.6.0

This is the changelog for Unicode v0.6.0 released on October 22nd, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_unicode/tags)

### Enhancements

* Update to Emoji 12.1

# Changelog for Cldr Unicode v0.5.0

This is the changelog for Unicode v0.5.0 released on May 12th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_unicode/tags)

### Enhancements

* Update to Unicode 12.1

# Changelog for Cldr Unicode v0.4.0

This is the changelog for Unicode v0.4.0 released on April 30th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_unicode/tags)

### Enhancements

* Adds `Cldr.Unicode.unaccent/1`

### Breaking Changes

* Block names are now atoms instead of strings

# Changelog for Cldr Unicode v0.3.0

This is the changelog for Unicode v0.3.0 released on March 28th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_unicode/tags)

### Enhancements

* Updated to Unicode version 12

# Changelog for Cldr Unicode v0.2.0

This is the changelog for Unicode v0.2.0 released on February 24th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_unicode/tags)

### Enhancements

* Moves the public API to the `Cldr.Unicode` module.

* Updates and adds documentation to all public functions.

* Removes the text annotations from the compiled functions which materially reduces the size of the beam files.

# Changelog for Cldr Unicode v0.1.0

This is the changelog for Unicode v0.1.0 released on February 23rd, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_unicode/tags)

### Enhancements

* Initial release
