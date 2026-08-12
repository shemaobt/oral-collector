# Noridoc: l10n

Path: @/lib/l10n

### Overview

- Holds one ARB catalogue per shipped language and the `AppLocalizations` classes `flutter gen-l10n` generates from them. Both the `.arb` sources and the generated `.dart` output are committed.
- `app_en.arb` is the template: it is the only file that carries `@key` metadata (placeholder types and the description a translator reads), and it is the file every other catalogue is measured against.
- **The rule: a key added here is added to every supported language in the same PR.** `test/l10n/arb_completeness_test.dart` fails otherwise, per language, naming the keys.

### How it fits into the larger codebase

- The set of languages is owned by `supportedLocales` in `@/lib/core/l10n/supported_locales.dart`, not by this folder. A locale listed there with no `app_<code>.arb` beside it fails the completeness test; the two lists are meant to be read as one.
- `@/lib/core/l10n/locale_provider.dart` chooses the active locale; `@/lib/core/l10n/content_l10n.dart` is a separate concern (server-sent content), not part of this catalogue.
- Widgets read strings through `AppLocalizations.of(context)`. Tests load a specific language directly with `AppLocalizations.delegate.load(const Locale('fr'))`, which is how the three files under `@/test/l10n` assert on what a reader in each language actually sees.

### Core Implementation

- `l10n.yaml` at the repository root configures the generation: `arb-dir: lib/l10n`, template `app_en.arb`, output `app_localizations.dart`, `nullable-getter: false`.
- Run `fvm flutter gen-l10n` after editing any `.arb` and commit the regenerated `app_localizations*.dart` alongside it.
- Plural and placeholder syntax is ICU and is **code, not prose**: `{count}` and the branch names have to survive translation intact. A malformed branch fails at generation; a missing branch fails at nothing, and simply renders the wrong sentence.
- Translated catalogues carry the message keys only. Placeholder types come from the template's `@key` metadata, so a plural key needs no `@key` block outside `app_en.arb`.

### Things to Know

- **A missing key is silent.** `gen-l10n` fills it with the English template text and generates a getter that compiles and returns something plausible, so nothing at runtime distinguishes "translated" from "fell back". `l10n.yaml` sets no `untranslated-messages-file`, so no report is written either — the count `gen-l10n` prints to stdout is the only hint, and nothing reads stdout.
- That silence is how two debts reached `dev` before ENG-410: a change edited `app_en.arb` and `app_pt.arb`, wrote the gap down in a feature doc, and shipped. Fourteen keys were English in nine languages. The completeness test is the failure that was missing; keep it without exceptions, because an allowlist restores exactly the silence it replaced.
- The test also rejects a key that exists in a translation but not in the template, which is how an orphan left behind by a rename gets noticed.
- **Rewritten copy is the case no test catches.** If a behaviour changes and the English sentence is rewritten, every other language still has a well-formed translation of the old, now-false sentence — complete, and wrong. ENG-407 changed clearing the cache from "deletes all local recordings" to "deletes the local copies the server already has"; nine languages went on promising the first for a release. When you rewrite a string because behaviour moved, rewrite all eleven.
- Arabic distinguishes six plural categories (`zero`, `one`, `two`, `few`, `many`, `other`); copying the English `=1`/`other` structure into it is wrong for most counts. Languages without number inflection (zh, ko, id, tpi) are fine with `other` alone, but the ICU still has to be well formed.

Created and maintained by Nori.
