# Noridoc: Content L10n

Path: @/lib/core/l10n

### Overview

- Turns **taxonomy text that arrives from the server** — genre, subcategory and
  register names and descriptions — into text in the reader's language. This is
  the only i18n logic the app has; everything else is a plain
  `AppLocalizations` getter.
- [content_l10n.dart](content_l10n.dart) is the whole folder: a handful of
  top-level `localized*` functions over private lookup maps keyed by the English
  string the server sends.
- The generated `AppLocalizations` classes and the `.arb` sources live in
  [/lib/l10n](/lib/l10n), not here. This folder consumes them.

### How it fits into the larger codebase

- Every screen that renders a taxonomy label calls into here:
  the genre/subcategory pickers and dialogs, the filter bar and filter sheet,
  the recording card, list and detail screens, and the home and admin genre
  cards. They all receive the raw name from
  [/lib/features/genre](/lib/features/genre) (`GET /api/oc/genres`) or from a
  recording row, and pass it through a `localized*` function on the way to a
  `Text`.
- The functions are pure: `AppLocalizations` in, `String` out. No provider, no
  context, no I/O — which is why they are unit-testable without pumping a widget.
- Nothing here is ever sent back to the server. The API speaks in ids
  (`genre_id`, `subcategory_id`, `register_id`); the translated name is
  presentation only. Sending a `localized*` result to the API would corrupt the
  record.

### Core Implementation

- The lookup maps are keyed by the **English name** the server holds for each
  taxonomy row, because that is what the API returns. A miss falls through to
  `_slugToTitleCase` (which turns `oral-discourse` into `Oral Discourse`) and,
  failing that, returns the server's string unchanged. A category the app has
  never heard of therefore still renders — untranslated, but readable.
- `localizedGenreName` and `localizedSubcategoryName` are the exceptions to
  name-keying: each also takes the row's **id**, and resolves the `unclassified`
  sentinel from it before consulting the maps.

### Things to Know

- **`unclassified` is a real taxonomy row, not a client-side state.** One
  migration on the server seeds *two* of them — a genre and a subcategory, both
  `id: 'unclassified'`, `name: 'Unclassified'`, `sort_order: 9999` — and the
  taxonomy endpoints return them alongside the real rows, so they appear at the
  end of every category list in the UI. Both names reached the reader in English
  until ENG-9. The ids collide only by coincidence: they are different columns,
  and `kUnclassifiedGenreId` / `kUnclassifiedSubcategoryId` are deliberately
  separate constants.
- It is resolved **by id, never by name**. The name is the server's to change —
  a rename to "Uncategorized" would silently reintroduce the bug if the match
  were on the string. The id is the stable half of the contract and already has
  a constant, `kUnclassifiedGenreId` in
  [/lib/features/recording/domain/entities/classification.dart](/lib/features/recording/domain/entities/classification.dart).
  The translation reuses the existing `recording_unclassified` key rather than
  adding a genre-specific one.
- The `id` argument is **required** for exactly that reason: an optional one
  would let a new call site silently fall back to the English name. If you add a
  caller, the compiler will make you supply the id.
- `l10n.yaml` sets `nullable-getter: false`, so every `AppLocalizations` getter
  returns a non-null `String` in every locale — a locale missing a key falls back
  to the English template at generation time. Callers never have to guard.
- The **descriptions** are not fixed. The seeded genre carries
  `'Recordings pending classification'`, and `localizedGenreDescription` still
  resolves by name only, so that sentence still reaches the reader in English
  wherever a genre description is rendered (the admin genre list, and the home
  hero card if the sentinel is ever the first genre). Closing that needs a new
  `.arb` key — there is no existing string to reuse — which is why ENG-9 left it
  alone.

Created and maintained by Nori.
