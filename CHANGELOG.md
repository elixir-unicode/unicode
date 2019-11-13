# Changelog for Cldr Unicode v0.7.1

This is the changelog for Cldr v0.7.1 released on _____, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_unicode/tags)

### Bug Fixes

* Fixes `count/1` for blocks, scripts and categories

* Replace deprecated `String.normalize/2` with `:unicode.characters_to_nfd_binary/` for OTP release 20 and later.

# Changelog for Cldr Unicode v0.7.0

This is the changelog for Cldr v0.7.0 released on November 12th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_unicode/tags)

### Enhancements

* Add `is_whitespace/1` guard generator

# Changelog for Cldr Unicode v0.6.0

This is the changelog for Cldr v0.6.0 released on October 22nd, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_unicode/tags)

### Enhancements

* Update to Emoji 12.1

# Changelog for Cldr Unicode v0.5.0

This is the changelog for Cldr v0.5.0 released on May 12th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_unicode/tags)

### Enhancements

* Update to Unicode 12.1

# Changelog for Cldr Unicode v0.4.0

This is the changelog for Cldr v0.4.0 released on April 30th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_unicode/tags)

### Enhancements

* Adds `Cldr.Unicode.unaccent/1`

### Breaking Changes

* Block names are now atoms instead of strings

# Changelog for Cldr Unicode v0.3.0

This is the changelog for Cldr v0.3.0 released on March 28th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_unicode/tags)

### Enhancements

* Updated to Unicode version 12

# Changelog for Cldr Unicode v0.2.0

This is the changelog for Cldr v0.2.0 released on February 24th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_unicode/tags)

### Enhancements

* Moves the public API to the `Cldr.Unicode` module.

* Updates and adds documentation to all public functions.

* Removes the text annotations from the compiled functions which materially reduces the size of the beam files.

# Changelog for Cldr Unicode v0.1.0

This is the changelog for Cldr v0.1.0 released on February 23rd, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_unicode/tags)

### Enhancements

* Initial release
