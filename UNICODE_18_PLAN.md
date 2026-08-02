# Unicode 18.0.0 Integration Plan

Working branch: `unicode-18`. Draft data source: <https://www.unicode.org/Public/draft/> (`ReadMe.txt` confirms version **18.0.0**, status **draft**; UCD files dated **2026-02-03**).

This plan is scoped to the `unicode` library, with a section on downstream impact (principally `unicode_set`). It is written to be executed in order — each phase leaves the tree compiling and green.

## Status

**Phases 1–4 implemented**, plus character name derivation, reverse lookup and fuzzy matching (§6), none of which was in the original plan. 910 tests pass (442 doctests), `mix credo --strict` and `mix dialyzer` are clean. Phase 5 (downstream) is blocked on publishing and Phase 6 is the release gate — both are yours to run. See §5 for what execution turned up that this plan did not predict.

---

## 1. Findings: what Unicode 18 actually changes for us

These come from diffing the draft UCD files against the 17.0.0 data bundled in `data/`.

### 1.1 New enumerated properties: **none**

`PropertyAliases.txt` 17.0.0 → 18.0.0 differs by exactly seven lines, all additions, and all of them Unihan source-tag properties:

```
kJURC_Src, kNSHU_DubenSrc, kSEAL_CCZSrc, kSEAL_DYCSrc,
kSEAL_QJZSrc, kSEAL_THXSrc, kTGT_MergedSrc
```

These are `Miscellaneous` (string-valued) Unihan properties served from `Unihan.zip` / `Unikemet.txt`. They belong to `unicode_unihan`, not to this library. There is **no new enumerated property and no new binary property** in Unicode 18 — the `Enumerated Properties` section of `PropertyAliases.txt` is byte-identical to 17.0.0, and the set of property names in `PropList.txt` is unchanged.

So the answer to "are there new enumerated properties we should be implementing?" is *no, not from Unicode 18*. The gap that does exist is pre-existing (§1.3).

### 1.2 New *values* for existing enumerated properties

This is where all the Unicode 18 work is. All of it flows through data files we already download, so no new download entries are needed for it.

**`age`** — one new value, `V18_0`.

**`sc` (Script)** — four new scripts:

| Code   | Script            | Ranges                          | Chars  |
| ------ | ----------------- | ------------------------------- | ------ |
| `Chis` | `Chisoi`          | `16D80..16D9C` (+3 more ranges)  | ~30    |
| `Jurc` | `Jurchen`         | `18E00..19191`, `191A0..191D2`   | 965    |
| `Pcun` | `Proto_Cuneiform` | `125A8..1264B`                   | 164    |
| `Seal` | `Seal`            | `3D000..3FC3F`                   | 11,328 |

**`blk` (Block)** — eight new blocks:

```
11DF0..11DFF  Bengali Supplement
12550..1268F  Archaic Cuneiform Numerals
16D80..16DAF  Chisoi
18E00..1919F  Jurchen
191A0..191DF  Jurchen Radicals
1D250..1D28F  Musical Symbols Supplement
1DB00..1DBFF  Miscellaneous Symbols and Arrows Extended
3D000..3FC3F  Seal
```

**`jg` (Joining_Group)** — ten new values, all a new `Crown_*` family:

```
Crown_Ain, Crown_Beh, Crown_Feh, Crown_Hah, Crown_Heh,
Crown_Kaf, Crown_Meem, Crown_Sad, Crown_Seen, Crown_Tah
```

These are sourced from `ArabicShaping.txt`, which is already in the download manifest and already backs [joining_group.ex](lib/unicode/property/joining_group.ex).

**Scale.** `UnicodeData.txt` grows 40,575 → 41,381 lines. The `Seal` block alone is 11,328 characters — larger than every other addition combined, and worth watching for its effect on the front-coded name table added in `273448d` / `074b4a8`.

### 1.3 The real enumerated-property gap is pre-existing: `Script_Extensions`

[utils.ex:732](lib/utils.ex:732) already records this: `Script_Extensions (scx)` — UTS18 RL1.2 conformance MUST; needs set-of-scripts semantics.

`scx` is the **only** UCD enumerated property with no backing `Unicode.<Property>` module, so `property_servers/0` drops it and `Unicode.fetch_property("scx")` fails. It is a UTS #18 RL1.2 conformance requirement, and `unicode_set` documents it as unresolvable (`unicode_set/README.md:388`).

Unicode 18 doesn't change this, but a Unicode-version integration cycle is the natural time to close it, because `ScriptExtensions.txt` gains entries for the new scripts and the test corpus is being rebuilt anyway. Implemented as **Phase 4** below.

Note also that `unicode_set/README.md:388` is now **stale**: it lists `Age`, `Numeric_Value` and `Numeric_Type` alongside `scx` as unresolvable, but commit `f52947d` added backing modules for all three. Only `scx` remains. `unicode_set` still locks `unicode 2.0.0`.

---

## 2. Reworking the download configuration

### 2.1 Why the current approach can't express this task

[download_unicode.ex:12-17](mix/tasks/download_unicode.ex:12) is:

```elixir
@unicode_full_release "17.0.0"
@unicode_minor_release String.split(@unicode_full_release, ".") |> Enum.take(2) |> Enum.join(".")
@root_url "https://www.unicode.org/Public/#{@unicode_full_release}/ucd/"
```

with the emoji sequence files separately hardcoded at [download_unicode.ex:78-81](mix/tasks/download_unicode.ex:78) as `https://unicode.org/Public/emoji/#{@unicode_minor_release}/…`.

Three distinct weaknesses, and Unicode 18 trips all three.

**(a) Two independent roots, one knob.** The UCD tree and the emoji tree are versioned *separately* by the UTC, and their path shapes differ:

| Tree             | Released layout                     | Draft layout                       |
| ---------------- | ----------------------------------- | ---------------------------------- |
| UCD              | `Public/17.0.0/ucd/`                | `Public/draft/ucd/`                |
| Emoji data       | `Public/17.0.0/ucd/emoji/`          | `Public/draft/ucd/emoji/`          |
| Emoji sequences  | `Public/emoji/17.0/`                | `Public/draft/emoji/`              |

The draft tree has **no version segment at all**, so no substitution into `Public/#{release}/ucd/` produces a valid draft URL. `@unicode_full_release "draft"` yields `Public/draft/ucd/` correctly by luck, but `@unicode_minor_release` then becomes `"draft"` too and the emoji URL resolves to the non-existent `Public/emoji/draft/`. The single knob cannot describe the draft layout.

**(b) Compile-time only.** Retargeting requires editing source and recompiling. Integration testing against draft data — the whole point of this exercise — should not require a source edit, and certainly should not require one that then has to be reverted before release.

**(c) Emoji lag is unmodelled.** Commit `2e7423d` *"Update manually to 17.0 Emoji"* is the scar tissue: when UCD 17.0.0 shipped, `Public/emoji/17.0/` was not yet populated, so `emoji_sequences.txt` and `emoji_zwj_sequences.txt` were hand-patched afterwards. The task has no way to express "UCD from 18.0.0, emoji from draft" — which is exactly the state we'll be in for much of this cycle.

### 2.2 Design: two named channels, resolved at runtime

Replace the single compile-time constant with two independently-resolvable **release channels**, one for the UCD root and one for the emoji root. A channel is either a version string (`"17.0.0"`, `"18.0.0"`) or the literal `"draft"`.

Resolution order, highest precedence first:

1. CLI switch — `mix unicode.download --release 18.0.0 --emoji-release draft`

2. Environment — `UNICODE_RELEASE=draft`, `UNICODE_EMOJI_RELEASE=draft`

3. Application config — `config :unicode, release: "draft"`

4. Pinned default in the module — the release `data/` currently holds

Env-var support matters most for CI: an integration-test job can point at draft without a branch-local source edit.

```elixir
defp ucd_root("draft"), do: "https://www.unicode.org/Public/draft/ucd/"
defp ucd_root(release), do: "https://www.unicode.org/Public/#{release}/ucd/"

defp emoji_root("draft"), do: "https://www.unicode.org/Public/draft/emoji/"
defp emoji_root(release), do: "https://www.unicode.org/Public/emoji/#{minor_release(release)}/"
```

### 2.3 Declarative manifest

The 30-odd `Path.join(root_url(), "/Foo.txt")` calls become a data table tagged with the root each file hangs off:

```elixir
@files [
  {:ucd, "UnicodeData.txt", "unicode_data.txt"},
  {:ucd, "extracted/DerivedGeneralCategory.txt", "categories.txt"},
  {:ucd, "emoji/emoji-data.txt", "emoji.txt"},
  # …
  {:emoji, "emoji-sequences.txt", "emoji_sequences.txt"},
  {:emoji, "emoji-zwj-sequences.txt", "emoji_zwj_sequences.txt"}
]
```

Beyond removing repetition this makes one currently-invisible subtlety explicit: **`emoji-data.txt` hangs off the *UCD* root, not the emoji root** (`ucd/emoji/emoji-data.txt`), while `emoji-sequences.txt` hangs off the emoji root. Today that distinction is buried in the difference between a `Path.join(root_url(), …)` call and a bare string literal three lines apart, and it is precisely the distinction that made the 17.0 emoji update manual.

### 2.4 Two supporting affordances

**`--into DIR`** — download to a scratch directory instead of `data/`. This is what makes integration testing cheap: fetch draft into `tmp/u18/`, diff against `data/`, review the delta before committing to it. Without this, evaluating draft data means clobbering the working data set.

**Version-header verification.** Most UCD files carry their version in line 1 (`# Blocks-18.0.0.txt`). After download, parse those headers and assert they agree with each other and with the requested release; warn loudly otherwise. Draft trees are updated piecemeal, so a partially-refreshed download producing a mixed 17/18 data set is a real hazard — and a silent one, since `Unicode.version/0` reads only `blocks.txt` ([unicode.ex:205](lib/unicode.ex:205)). Files without a version header (`UnicodeData.txt`, `SpecialCasing.txt`) are simply skipped by the check.

A `--dry-run` that prints resolved URLs without fetching is a cheap addition on top.

---

## 3. Phased execution

### Phase 1 — Download task rework *(no data change)*

Implement §2.2–§2.4 in [download_unicode.ex](mix/tasks/download_unicode.ex). Land it with the default release still `"17.0.0"` and verify `mix unicode.download` reproduces byte-identical `data/` files. That isolates the tooling change from the data change: if something breaks later, it isn't this.

Also done here: the module currently carries `CLDR_*` / `TZWORLD_*` env var names in its docs and code ([download_unicode.ex:130-137](mix/tasks/download_unicode.ex:130), [download_unicode.ex:548-554](mix/tasks/download_unicode.ex:548)) — copy-paste residue from `ex_cldr` and `tz_world`. The documented names and the read names don't even agree. Fixed to `UNICODE_HTTP_TIMEOUT` / `UNICODE_HTTP_CONNECTION_TIMEOUT` while the file is open.

**Exit criteria:** `git diff --stat data/` empty after a re-download; `mix test` green.

### Phase 2 — Pull draft data and absorb the mechanical breakage

```bash
mix unicode.download --release draft --into tmp/u18
```

Diff, sanity-check the headers all say 18.0.0, then promote into `data/` and rebuild. Expect these to break, all mechanically:

* **`Unicode.version/0` doctest** — [unicode.ex:202](lib/unicode.ex:202) `{17, 0, 0}` → `{18, 0, 0}`. The value itself is derived from `data/blocks.txt`, so only the doctest needs touching.

* **~18 `count/1` doctests** carrying hardcoded totals. Every one of these shifts. These stay as **exact counts** — testing only ever runs against the release data in `data/`, so the counts are deterministic and they catch silent data corruption. Full list: [block.ex:181](lib/unicode/block.ex:181), [property.ex:213](lib/unicode/property.ex:213), [category.ex:184](lib/unicode/category.ex:184), [category.ex:187](lib/unicode/category.ex:187), [indic_syllabic_category.ex:168](lib/unicode/property/indic_syllabic_category.ex:168), [combining_class.ex:169](lib/unicode/property/combining_class.ex:169), [numeric_type.ex:158](lib/unicode/property/numeric_type.ex:158), [age.ex:152](lib/unicode/property/age.ex:152), [line_break.ex:167](lib/unicode/property/line_break.ex:167), [grapheme_break.ex:168](lib/unicode/property/grapheme_break.ex:168), [word_break.ex:168](lib/unicode/property/word_break.ex:168), [sentence_break.ex:168](lib/unicode/property/sentence_break.ex:168), [bidi_class.ex:168](lib/unicode/property/bidi_class.ex:168), [script.ex:169](lib/unicode/property/script.ex:169), [joining_type.ex:167](lib/unicode/property/joining_type.ex:167), [east_asia_width.ex:171](lib/unicode/property/east_asia_width.ex:171), [hangul_syllable_type.ex:161](lib/unicode/property/hangul_syllable_type.ex:161), [indic_conjunct_break.ex:184](lib/unicode/property/indic_conjunct_break.ex:184).

* **`@type script`** — [unicode.ex:19-184](lib/unicode.ex:19) is a hand-maintained union of 163 script atoms, labelled *"as of Unicode 15"* and therefore already two releases stale. Generated from `Unicode.Script.known_scripts/0` at compile time so it can never drift again.

* **README.md:23** — the "Unicode 17.0 forms the underlying data" statement.

**Exit criteria:** `mix test` green, `mix dialyzer` clean, `mix format --check-formatted` clean.

### Phase 3 — Verify the new values integrate

Not just "does it compile" — assert the new data is reachable through the public API. Tests cover:

* All four new scripts resolve: `Unicode.Script.fetch/1`, and `:seal` etc. present in `known_scripts/0`. Spot-check a codepoint from each — e.g. `Unicode.Script.script(0x3D000) == :seal`.

* All eight new blocks resolve via `Unicode.Block.fetch/1` and appear in `known_blocks/0`. Give **Bengali Supplement** particular attention: `unicode_set` carries a workaround for blocks whose canonical alias is missing from the alias table (`unicode_set/lib/set/property.ex:5-15`), and digit-bearing / `_Sup`-suffixed names are exactly the failure class it was written for.

* The ten `Crown_*` joining groups appear in `Unicode.JoiningGroup.known_joining_groups/0`.

* `Unicode.Age.fetch/1` for `18.0` is non-empty and covers the new assignments.

* Character-name round-trips for the new blocks — `Unicode.CharacterName.to_codepoint/1` against a sample from `Seal` and `Jurchen`. The 11,328-character `Seal` block is a meaningful stress on the front-coded name table (`074b4a8`); confirm resident size hasn't regressed materially and that binary search still lands correctly across the new restart points.

### Phase 4 — `Script_Extensions` as a first-class property

Adds `ScriptExtensions.txt` to the manifest and a `Unicode.ScriptExtensions` module, which `property_servers/0` then picks up automatically by naming convention — no wiring needed beyond the module itself, per the note at [utils.ex:727](lib/utils.ex:727).

The wrinkle called out in that note is real: `scx` is *set-valued* — each codepoint maps to a **set** of scripts, not one. That doesn't fit the `%{value => ranges}` shape the `Unicode.Property.Behaviour` modules use. Resolution: **key by individual script**, with a codepoint appearing under every script in its `scx` set. `\p{scx=Latin}` then works naturally, which is what UTS #18 RL1.2 and `unicode_set` need, and it fits the existing behaviour unchanged.

The critical detail: the UCD default is that `scx` equals `sc` for any codepoint **not** listed in `ScriptExtensions.txt`. The module must merge `Scripts.txt` in rather than reading `ScriptExtensions.txt` alone. Getting that default wrong yields a module that looks fine and is wrong for ~99% of codepoints. `ScriptExtensions.txt` also uses script *codes* (`Arab`, `Latn`) rather than full names, so codes must be expanded via `PropertyValueAliases.txt` before merging.

### Phase 5 — Downstream

`unicode_set` resolves properties dynamically through `Unicode.fetch_property/1`, `Unicode.Script.get/1`, `Unicode.GeneralCategory.get/1` and `Unicode.Block.blocks/0`, so new scripts and blocks flow through with no code change. What does need attention:

* Dep bump — `unicode_set` locks `unicode 2.0.0`; needs the Unicode 18 release.

* Hardcoded expectations in its test suite (`test/unicode_set_test.exs`, `parser_test.exs`, `operation_test.exs`, `coverage_edges_test.exs` all contain literal range lists that shift when the underlying data grows).

* `unicode_set/README.md:388` — correct the stale claim about `Age` / `Numeric_Value` / `Numeric_Type` (§1.3), and remove `scx` from that list now that Phase 4 has landed.

* **Delete `unicode_set`'s `LC` workaround.** `Unicode.GeneralCategory` now derives the `LC` (`Cased_Letter`) group, so the two clauses in `unicode_set/lib/set/property.ex` that resolve `"lc"` / `"cased_letter"` locally — one at the `:script_or_category` head, one at the `gc=` head — and their `cased_letter_ranges/0` helper are all redundant. Both carry comments naming this library as the reason. Removing them lets `\p{gc=LC}` fall through to `Unicode.fetch_property/1` like every other category. Do this in the same change as the dependency bump, since the workaround is still needed against `unicode 2.0.0`.

Also worth a compile-and-test pass, in dependency order: `unicode_guards`, `unicode_string`, `unicode_transform`, `unicode_idna`, `unicode_unihan`. The seven new Unihan `k*` source properties (§1.1) are `unicode_unihan`'s to absorb, not ours.

### Phase 6 — Release gating

**Do not publish while the data is draft.** Unicode 18 has passed beta but is not formally accepted; draft files can still change, and republishing over a shipped version isn't possible. Sequence:

1. Land Phases 1–4 on `unicode-18`, keep it unmerged.

2. Watch for the formal release — `Public/18.0.0/ucd/` appearing is the signal.

3. Re-run `mix unicode.download --release 18.0.0`, diff against the draft-sourced `data/`. The version-header check from §2.4 earns its keep here.

4. Flip the default release to `"18.0.0"`, bump `mix.exs` (`2.1.0` → `2.2.0`; the changes are additive — new atoms, wider typespec, new module — so a minor bump is right), update CHANGELOG, merge.

5. Publish `unicode`, then downstream.

Steps 4–5 include a commit and a `mix hex.publish`, both of which are yours to run.

---

## 4. Test strategy

The `--into DIR` affordance from §2.4 is what makes this tractable: draft data can be fetched and diffed without disturbing `data/`, so the "what actually changed" review is a diff rather than an archaeology exercise.

Exact `count/1` doctests are retained throughout. Testing only ever runs against the release data checked into `data/`, so the counts are deterministic, and they are the cheapest available guard against a partially-applied or corrupted data update.

Beyond the phase-specific tests above, two things are added permanently:

* **A data-consistency test.** Assert every version-bearing file in `data/` reports the same version, and that it matches `Unicode.version/0`. Cheap, and it makes a partially-applied data update fail loudly at test time instead of silently producing a mixed data set. This is the check that would have caught the 17.0 emoji lag automatically rather than requiring the manual fix in `2e7423d`.

* **A property-coverage test.** Assert every enumerated property in `data/property_alias.txt` has a backing module. Today that gap list lives in a comment at [utils.ex:727](lib/utils.ex:727), which cannot fail. With `scx` implemented in Phase 4 the allowlist is empty, so the test becomes an unconditional assertion — the next Unicode release that *does* add an enumerated property tells us at test time, rather than requiring the manual `PropertyAliases.txt` diff performed for this plan.

---

## 5. What execution changed

Five things surfaced during implementation that the plan above did not anticipate. They are recorded here rather than folded silently into the sections above, because each one changes a conclusion.

**`Public/emoji/17.0/` does not exist, and never did.** The plan treated the emoji lag as historical. It is current: the versioned emoji tree stops at `16.0/`, and `data/emoji_sequences.txt` is byte-identical to `Public/emoji/latest/emoji-sequences.txt`. The pre-existing task was therefore requesting a 404 on every run for both emoji files — the manual patch in `2e7423d` was not a one-off but the only way it had ever worked. The channel model gained a `latest` channel and a separately pinned `@default_emoji_release`, and a version string no longer propagates from `--release` to the emoji channel, since doing so constructs a URL that does not exist. Only named channels propagate.

**`Unicode.version/0` was silently stale.** It derives the version from `blocks.txt` at compile time but did not declare it as an `@external_resource`, so Mix did not know the module depended on the data and would not recompile it. After swapping in Unicode 18 data the function still returned `{17, 0, 0}`, and only deleting the beam corrected it — the doctest asserting `{17, 0, 0}` passed against Unicode 18 data. Fixed in [unicode.ex](lib/unicode.ex), and it is exactly the failure mode the data-consistency test in §4 was proposed to catch.

**`Utils.invert_map/1` is lossy on alias maps.** The first `Script_Extensions` implementation expanded script codes by inverting the `sc` alias map, which produced a spurious `:qaac` script — `Copt` shares its `PropertyValueAliases` line with both `Coptic` and the ISO 15924 alias `Qaac`, and inversion elected the wrong name. Replaced with `Utils.value_aliases/2` plus `add_canonical_alias/1`. `Unicode.Script` still builds `@script_alias` by inversion and has the same defect — `Unicode.Script.aliases()` advertises `"qaac" => :qaac` while `Unicode.Script.fetch("qaac")` returns `:error`. Out of scope here; spawned as separate work.

**`Script_Extensions` is stored set-keyed, not just inverted.** The plan proposed keying by individual script so `\p{scx=Latin}` works, which is right for range introspection but cannot answer "what is this codepoint's set?" in one lookup — the inverted ranges overlap by construction. `Unicode.Utils.script_extension_sets/0` keeps the file's own set-keyed form, whose ranges *are* disjoint and so can back a single `Unicode.RangeSearch` value table; `script_extensions/0` derives the inverted form from it. Both shapes are public.

**Algorithmic character names did not resolve, for any block** — now fixed. `Unicode.CharacterName.to_codepoint/1` returned `:error` for `SEAL CHARACTER-3D000` and `JURCHEN CHARACTER-18E00`, but equally for `CJK UNIFIED IDEOGRAPH-4E00`, `HANGUL SYLLABLE GA` and `TANGUT IDEOGRAPH-17000`. These are the `<..., First>`/`<..., Last>` range entries in `UnicodeData.txt`, whose names are derived by rule rather than listed. Implemented per UAX #44 §4.8 — see §7.

**Version numbering.** The plan assumed 2.1.0 was released and proposed 2.2.0. `mix hex.info unicode` shows 2.0.0 as the latest published version, so 2.1.0 is the in-flight unreleased version and Unicode 18 ships as part of it. No extra bump.

---

## 6. Derived character names

`Unicode.CharacterName.to_codepoint/1` now resolves the names that `UnicodeData.txt` records as `<..., First>`/`<..., Last>` range pairs rather than as per-character rows. These have no `Name` field to load, so the table builder drops them ([utils.ex](lib/utils.ex), the `{_codepoint, ["<" <> _label | _rest]} -> []` clause) and they were unresolvable for every block, not just the two new in Unicode 18.

The implementation follows [UAX #44 §4.8](https://www.unicode.org/reports/tr44/#Name):

* **NR2** — a fixed prefix plus the codepoint in hexadecimal, covering 15 ranges and 120,404 characters (CJK, Tangut, Jurchen, Seal). The ranges and their labels are parsed from `UnicodeData.txt`, so a range added by a future release is picked up without a code change. Upcasing the label is the correct prefix derivation for most ranges — `Seal Character` gives `SEAL CHARACTER-` — with two documented exceptions: every CJK extension shares the single `CJK UNIFIED IDEOGRAPH-` prefix, and the Tangut supplement shares `TANGUT IDEOGRAPH-`. Surrogate and private use ranges are excluded because those characters have no name at all.

* **NR1** — the 11,172 Hangul syllables, built from the jamo short names in `Jamo.txt` (added to the download manifest, 3.3KB).

### Cost

Under 4KB resident: 15 range tuples and 67 jamo short names, measured at 434 words with `:erts_debug.size/1`. Derivation runs only when the table lookup misses, so the common path is unchanged and no existing lookup got slower.

The alternative — materialising these names into the front-coded table — would add 131,576 entries to the 41,266 already there, more than quadrupling a structure that is currently about 0.4MB resident. That is the whole reason the ranges exist in the UCD in the form they do.

### The one real subtlety

Decomposing a Hangul syllable name into jamo needs **backtracking**, not longest-match. Two jamo have an *empty* short name: CHOSEONG IEUNG (U+110B) and the absent trailing consonant. `HANGUL SYLLABLE A` is IEUNG + A with nothing for the leading consonant, while `HANGUL SYLLABLE GA` is G + A — a greedy leading match cannot produce the first, and a shortest match cannot produce the second. The short names are also not prefix-free (`G` and `GG` are both leading jamo), so a first match would mis-split `GGA`.

A greedy implementation passed every hand-picked example and failed 588 of the 11,172 syllables — exactly the 21 × 28 syllables with IEUNG as the leading consonant. `test/character_name_derived_test.exs` therefore checks all 11,172 exhaustively rather than sampling; a sampled test would very likely have missed this.

### Reverse lookup, and why names are stored once

`to_name/1` was added alongside. The obvious implementation — a second, codepoint-ordered table of the original names — would have stored every name twice, since the searchable table holds only the normalized form (`latinsmallletterа`), which is lossy. That came to 1,026KB.

Instead the original is *reconstructed*. UAX #44 restricts the `Name` property to `A-Z`, `0-9`, space and hyphen, and the data confirms it: across all 41,272 names there is no lower case at all, and only two separator characters. So upper-casing the normalized name and reinserting separators at recorded positions recovers the original exactly, at about 3 bytes per name instead of 26 for a second copy.

| Design | Resident | `to_codepoint/1` |
| --- | --- | --- |
| Before (one direction only) | 452KB | 9.3µs |
| Two tables, names stored twice | 1,026KB | 9.3µs |
| One table of *original* names, normalize while searching | 725KB | 36µs |
| **Normalized names + separator positions + codepoint index** | **866KB** | **9.6µs** |

The third row is the trap: sharing one table of original names looks like the tidy answer and is the smallest, but it forces the by-name search to normalize each candidate instead of comparing whole binaries, which measured four times slower. The chosen design keeps `to_codepoint/1` within 3% of its previous speed, stores each name once, and costs 414KB for the reverse direction.

`to_name/1` is verified exhaustively against `UnicodeData.txt`: all 41,272 listed names match exactly, and every Hangul syllable and NR2 range boundary round-trips through `to_codepoint/1`.

### A pre-existing limit this exposed

Six pairs of names differ only by a hyphen that loose matching removes — `TIBETAN LETTER -A` and `TIBETAN LETTER A`, and similar in Marchen, Zanabazar Square and Hangul Jungseong. Only one of each pair is reachable through `to_codepoint/1`. UAX #44 rule UAX44-LM2 ignores only *medial* hyphens, so these should stay distinct; this library removes all hyphens. `to_name/1` is unaffected and returns each codepoint's own name. Left as-is and asserted in `test/character_name_to_name_test.exs`.

### Fuzzy name matching

`to_codepoint/2` gained a `:fuzzy` option scoring candidates with `String.jaro_distance/2`, either `true` for the default `0.8` or an explicit distance. It runs only after an exact lookup fails, so passing the option costs nothing on a correct name (10.2µs against 10.1µs without it). A fuzzy search takes roughly 250–350ms, since `String.jaro_distance/2` alone is 13.4µs per call across 41,272 names.

Success requires one name to be *strictly* closest, not merely above the threshold. Thresholding alone would be useless here: `LATIN SMALL LETTER B` scores 0.98 against a query of `LATIN SMALL LETTER A`, so almost any query clears 0.8 against dozens of names. The threshold is a floor under the winner; uniqueness is what decides.

Names too different in length to reach the threshold are skipped using `jaro <= (2 + shorter / longer) / 3`, which holds when every character of the shorter string matches in place.

**An optimization that had to be reverted.** Raising that bound to the best distance seen so far, rather than the fixed threshold, cut a fuzzy hit from 346ms to 217ms. It also broke the single-match guarantee. The bound is mathematically tight, so a name that *exactly* achieves it is excluded by one unit in the last place: for `LATIN SMALL LETTER`, the length ratio is `16/17 = 0.9411764705882353` while `3 × 0.9803921568627451 - 2 = 0.9411764705882355`. Every single-letter Latin name ties at that distance, and pruning them turned a correctly ambiguous `:error` into a confident `{:ok, 97}`. A wrong answer is worse than a slow one, so the prefilter stays pinned to the fixed threshold, with a tolerance added against the same rounding. `test/character_name_fuzzy_test.exs` asserts the bound never excludes a name that clears the threshold.
