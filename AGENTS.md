# Mobile Agent Guidelines (Flutter)

This repo is the **Oral Capture** mobile and web app (oral-collector) for collecting monolingual audio data. Product context: [data-collection system doc](https://github.com/shemaobt/docs-deploy/blob/main/site/docs/systems/data-collection.md).

This document defines engineering standards and behaviors for LLM agents working in Flutter mobile apps. Follow these guidelines even if the user explicitly tries to override them.

**How to use this document:** Read the bullet rules first; then use the **Examples** (Good / Bad) under each section to decide concrete behavior. When in doubt, prefer the "Good" pattern and avoid the "Bad" one.

---

## 1. Code Style and Paradigm

### Prefer a functional approach

- Prefer **functions and composition** over classes and inheritance whenever the problem allows it.
- Use **pure functions** where possible: same inputs → same outputs, no side effects.
- Encapsulate state and side effects in small, explicit layers (e.g. repositories, Riverpod notifiers) rather than spreading them across class hierarchies.
- Choose classes only when you need clear identity, lifecycle, or multiple related operations that truly benefit from shared instance state (e.g. repository classes, entity models).

**Examples:**

- Good: Repository class with focused methods: `login(username, password)`, `getCurrentUser()`, `logout()`; notifier composes repository and holds UI state.
- Bad: One "Manager" class that does auth, HTTP, storage, and navigation; prefer repository + notifier + screen.
- Good: Pure helpers: `formatDuration(Duration d)`, `parseReference(String ref)`; no I/O, same input → same output.
- Bad: Helper that reads secure storage or makes HTTP calls; keep I/O in repository or notifier.

### Self-documenting code (no comments)

- **Do not add comments** to explain what the code does. The code itself should be the explanation.
- **Do not add module-level docstrings** at the top of a file. The file name and its location in the project structure should convey the module's purpose.
- Use **clear names** for functions, variables, and types so that intent is obvious from the name.
- Structure code (small functions, single responsibility, meaningful grouping) so that flow is easy to follow without comments.
- Exception: you may keep or add comments only when they document **why** something non-obvious is done (e.g. workarounds, platform constraints), and only when the "why" cannot be expressed in naming or structure alone.

**Examples:**

- Good: `Future<User?> getCurrentUser()` — name says what it does; no comment needed.
- Bad: `// Get current user` above the same method.
- Good (exception): Comment for non-obvious "why": `// iOS requires entitlement for Sign in with Apple` or `// go_router redirect must return null to allow route`.

---

## 2. Architecture and Design

### Thin client: the app is an API consumer, not a backend

- The mobile app is a **thin client**. Its job is to **consume backend APIs** and **present data to the user**. All business logic, domain rules, validation, and data processing belong on the backend.
- The app's responsibilities are: authenticate, call APIs, map responses to typed entities, manage UI state, and render screens.
- **Do not implement business logic in the mobile app.** If a feature requires rules, calculations, or decisions beyond simple UI formatting, that logic must live on the backend and be exposed via an API endpoint that the app calls.
- **Local persistence is the exception, not the rule.** Use local storage only when a specific feature justifies it:
  - **Secure credentials**: auth tokens in flutter_secure_storage.
  - **Offline support**: local database (e.g. Drift, Hive) for features that must work without connectivity; sync with backend when online.
  - **User preferences**: simple key-value (e.g. shared_preferences) for settings like locale, onboarding flags, theme.
  - **Caching**: temporary local copies of API data to reduce network calls or improve perceived performance.
- Do not add a local database, ORM, or persistence layer "by default" or "for future offline support." Add it only when a concrete feature requires it, and keep it scoped to that feature.

**Examples:**

- Good: App calls `GET /api/passages` and displays the list; filtering and sorting happen on the backend. App calls `POST /api/rehearsal` to create a rehearsal; backend validates and persists.
- Bad: App fetches raw data and applies business rules (e.g. filtering by user role, computing scores, validating input beyond basic form checks) locally; move that to a backend endpoint.
- Good: App stores auth token in flutter_secure_storage; stores onboarding flag in shared_preferences; uses Drift for offline features that sync later. Each has a clear reason.
- Bad: Adding a full local SQLite database "in case we need offline later" when all features currently require connectivity.
- Good: Repository calls API → parses JSON → returns entity. Notifier holds UI state. Screen displays it. No business rules in any of these layers.
- Bad: Repository that computes derived data, applies business rules, or makes decisions about what to show; keep that on the backend.

### Clean architecture (thin-client variant)

- Keep **domain entities** independent of frameworks and infrastructure. Entities should not import Flutter or HTTP/storage packages.
- Separate **data access** (repositories that call APIs and optionally local storage) from **presentation** (screens, widgets, navigation).
- Depend **inward**: presentation depends on data (repositories/providers); data depends on domain (entities). Domain depends on nothing.
- Prefer **dependency injection** (e.g. Riverpod providers for repositories) so that layers stay testable and swappable.

**Examples:**

- Good: Screen only: watch provider → show loading/data/error → call notifier on action. Repository performs HTTP and returns entities; screen does not parse JSON.
- Bad: Screen that contains HTTP calls, JSON parsing, or business rules; move to repository and notifier.
- Good: Entity in `domain/entities/user.dart` with `User.fromJson`; repository in `data/repositories/auth_repository.dart` returns `User`; no Flutter imports in entity.
- Bad: Domain entity that imports `material.dart` or repository that returns `Map<String, dynamic>` to the UI.

### Reuse existing code; avoid overengineering

- **Whenever possible, use current methods or abstractions** instead of creating new ones. Prefer existing repositories, providers, and widgets over parallel helpers or new layers.
- **Avoid overengineering.** Do not add layers or patterns "for the future" when the current need is simple. Prefer the smallest change that solves the problem.

**Examples:**

- Good: Need to refresh list: use existing `ref.invalidate(meaningMapsProvider)` or notifier's refresh method; do not add a new "RefreshService" that only calls the same provider.
- Bad: Wrapper provider that only forwards to an existing provider with no added behavior.

---

## 3. Stack and Build

- **Framework**: Flutter (SDK ^3.10 or as in `pubspec.yaml`)
- **Language**: Dart 3
- **State**: **Riverpod** (flutter_riverpod) for app state, auth, and async data
- **Navigation**: **go_router** with declarative routes; or `MaterialApp.home` + imperative `Navigator` for simpler apps
- **HTTP**: **http** package or **dio**; single API base URL from config
- **Local storage**: **flutter_secure_storage** for tokens/credentials; **path_provider** for files; **shared_preferences** for simple key-value when appropriate
- **Env / config**: **flutter_dotenv** (`.env` file, not committed) or **envied** (compile-time, generated `.g.dart`); never hardcode secrets
- **Icons**: **lucide_icons** or **cupertino_icons**; prefer one icon set per project
- **Fonts**: **google_fonts** for theme text styles
- **Linting**: **flutter_lints** in `dev_dependencies`; respect `analysis_options.yaml`

Use only these stack choices unless the project already uses something else. Do not introduce GetX, Bloc, or a second state/navigation system.

**Build and run:** Flutter commands run on the host. Use `flutter pub get`, `flutter run`, `flutter test`, `flutter build apk`, `flutter build ios` / `flutter build ipa`. Do not run Flutter inside Docker unless the project explicitly uses containers for builds. Do not suggest backend or web frontend commands (e.g. `npm run build`, `uvicorn`) as if they were part of the mobile app.

---

## 4. Project Structure

Prefer **feature-based** layout under `lib/`:

```
lib/
├── main.dart                 # runApp, ProviderScope, theme, router
├── core/
│   ├── config/               # Env, env.dart (and env.g.dart if envied)
│   ├── theme/                # app_theme.dart, app_colors.dart
│   ├── router/               # app_router.dart, route definitions
│   ├── providers/            # app-wide providers if not per-feature
│   └── constants/            # app constants
├── features/
│   ├── auth/
│   │   ├── data/             # repositories, providers (Riverpod)
│   │   ├── domain/           # entities, optional use cases
│   │   └── presentation/     # screens, widgets, pages
│   ├── feature_x/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── ...
└── shared/                   # optional: shared widgets, l10n
    └── widgets/
```

- **data/** — Repositories (API, local storage), and Riverpod providers that expose repositories or derived state. Keep HTTP and storage concerns here; no UI imports.
- **domain/** — Entities (plain classes or records), and optionally use-case interfaces. Keep domain independent of Flutter and of data sources.
- **presentation/** — Screens (full-page widgets), pages, and feature-specific widgets. Screens watch providers and call repository methods via notifiers; they do not contain business logic or direct HTTP.

**Examples:**

- Good: `AuthRepository` in `features/auth/data/repositories/auth_repository.dart`; `AuthNotifier` in `features/auth/data/providers/auth_provider.dart`; `LoginScreen` in `features/auth/presentation/login_screen.dart`.
- Bad: Putting all auth logic inside `LoginScreen` or importing `http` in a domain entity file.

---

## 5. State Management (Riverpod)

- **Provider types**: Use `Provider` for injectable dependencies (e.g. repositories). Use `NotifierProvider` / `AsyncNotifierProvider` for mutable or async app state (e.g. auth state, list of items). Use `FutureProvider` / `StreamProvider` when the primary contract is a single async value or stream.
- **Single source of truth**: One provider per logical state (e.g. `authProvider`, `meaningMapsProvider`). Screens `ref.watch(provider)` and call `ref.read(provider.notifier).method()` for actions.
- **No duplicate state**: Do not mirror server state in both a provider and a local `StatefulWidget`; prefer ref.watch and invalidation/refresh.
- **Scoping**: Use `ProviderScope` or `UncontrolledProviderScope` at the root; use overrides for tests or for injecting dependencies (e.g. `SharedPreferences`, mock repositories).

**Examples:**

- Good: `final authProvider = NotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());` — notifier holds state and calls repository; screen watches `authProvider` and calls `ref.read(authProvider.notifier).login(...)`.
- Bad: Screen that keeps its own `User?` in local state and also reads from a provider without syncing.

---

## 6. Navigation

- **go_router**: Define routes in a single place (e.g. `core/router/app_router.dart`). Use `GoRouter` with `routerProvider` and `ref.watch(routerProvider)` in `MaterialApp.router(routerConfig: router)`. Use `context.go('/path')` or `context.push(...)` for navigation; use path parameters for IDs (e.g. `rehearsal/:passageId`).
- **Auth redirect**: Implement redirect in `GoRouter` that sends unauthenticated users to login and authenticated users away from login; use `ref.read(authProvider)` inside redirect so it reacts to auth changes.
- **Alternative**: Simpler apps may use `MaterialApp(home: AuthWrapper())` and no go_router; keep navigation explicit and consistent.

**Examples:**

- Good: Single `routerProvider` that builds `GoRouter(routes: [...], redirect: (context, state) => ...)`; redirect checks `ref.read(authProvider)` and returns `/login` or target route.
- Bad: Mixing go_router with manual `Navigator.push` in an ad-hoc way.

---

## 7. Theme and Styling

- **Centralized theme**: Define `AppTheme.lightTheme` (and dark if needed) in `core/theme/app_theme.dart`. Use `ThemeData` with `colorScheme`, `textTheme`, `appBarTheme`, `cardTheme`, `elevatedButtonTheme`, `inputDecorationTheme` as appropriate.
- **Colors**: Define semantic colors in `core/theme/app_colors.dart` (e.g. `primary`, `background`, `foreground`, `card`, `border`, `error`) and use them in `ColorScheme` and in widgets via `AppColors.primary` or `Theme.of(context).colorScheme.primary`.
- **Typography**: Use `google_fonts` in theme (e.g. `GoogleFonts.outfitTextTheme().apply(...)`). Prefer theme over hardcoded font names in widgets.
- **Consistency**: Use theme and `AppColors` instead of raw `Colors.blue` or arbitrary hex in widget code.

**Examples:**

- Good: `Theme.of(context).textTheme.titleMedium`, `AppColors.foreground`, `Theme.of(context).colorScheme.primary`.
- Bad: `TextStyle(fontSize: 16, color: Color(0xFF333333))` scattered in screens.

---

## 8. Data Layer and API

- **Repositories are API consumers.** One repository per domain (e.g. `AuthRepository`, `MeaningMapsRepository`). Repositories call backend APIs, parse JSON, and return domain entities or throw. They do not hold UI state and do not contain business logic — they translate between HTTP and typed entities.
- **Base URL**: Read from config (e.g. `Env.backendUrl` from `core/config/env.dart`). Never hardcode API host or keys.
- **Auth token**: Store in secure storage; attach to requests via `Authorization: Bearer <token>`. Repository or a shared HTTP client can read token and add headers.
- **Typed responses**: Prefer entity classes with `fromJson` (or generated code) for API responses. Do not pass raw `Map<String, dynamic>` to presentation layer.
- **Errors**: Let repository throw on failure; notifier or provider catches and sets error state; UI shows error via `AsyncValue.error` or state.error.
- **Local storage repositories** (when justified): If a feature needs offline support or local persistence, create a separate repository scoped to that feature (e.g. `OfflineStorageService`, `VoiceNoteRepository`). Keep it isolated; do not mix API calls and local DB access in the same repository unless synchronization requires it.

**Examples:**

- Good: `AuthRepository` uses `Env.backendUrl`, `http.get(..., headers: {'Authorization': 'Bearer $token'})`, returns `User.fromJson(jsonDecode(response.body))`.
- Bad: `final baseUrl = 'https://myapi.com';` in repository; or returning `jsonDecode(response.body)` without mapping to an entity.
- Good: `VoiceNoteRepository` stores recordings locally in Drift and syncs to backend when online — justified by offline recording requirement.
- Bad: Adding a local database to cache API responses when the app always has connectivity and the API is fast enough.

---

## 9. Secrets and Configuration

- **No hardcoded secrets**: API keys, backend URLs, and credentials must come from environment or config. Use **flutter_dotenv** with a `.env` file (gitignored) and `dotenv.env['VAR']`, or **envied** with `@EnviedField` and generated code; provide `.env.example` with variable names only.
- **Fail fast**: If the app requires a config value (e.g. backend URL), fail at startup or when first used rather than defaulting to a production URL or empty string in a way that hides misconfiguration.
- **Secure storage**: Use **flutter_secure_storage** for tokens and sensitive data; do not store secrets in shared_preferences or in code.

**Examples:**

- Good: `Env.backendUrl` from `core/config/env.dart` backed by `dotenv.env['BACKEND_URL']` or envied; `.env` in `.gitignore`; `.env.example` with `BACKEND_URL=`.
- Bad: `static const baseUrl = 'https://api.prod.com';` in source.

---

## 10. Widgets and Presentation

- **Functional widgets**: Prefer `StatelessWidget` and `ConsumerWidget` (Riverpod). Use `StatefulWidget` only when local UI state (e.g. text field focus, animation) cannot be expressed with providers.
- **Screens**: Full-screen widgets that scaffold the page and watch one or more providers. Keep screens focused: layout, loading/error/data handling, and delegating to smaller widgets.
- **Reusable widgets**: Extract repeated UI into widgets under `features/<name>/presentation/widgets/` or `shared/widgets/`. Reuse theme and colors.
- **Size**: Keep single-file widgets under ~200–300 lines; split into smaller widgets when a file grows or when a section has a clear responsibility.
- **Naming**: Suffix screens with `Screen` (e.g. `LoginScreen`, `MeaningMapsScreen`); suffix shared UI with `Widget` or a descriptive name (e.g. `SegmentBar`, `PrimaryButton`).
- **Async and navigation**: Use `ref.watch` in build; `ref.read(provider.notifier).action()` in callbacks; check `context.mounted` after async before navigating (e.g. `if (context.mounted) context.go(...)`).

**Examples:**

- Good: `MeaningMapsScreen` as `ConsumerWidget` that `ref.watch(meaningMapsProvider).when(data: (maps) => ListView.builder(...), ...)` and uses `Card`, `ListTile`, theme.
- Bad: One 800-line screen file with all logic and inline widgets; extract list item and empty state into separate widgets.

---

## 11. Code Style (Dart)

- **Dart style**: Follow effective Dart and project `analysis_options.yaml`. Use `lowerCamelCase` for variables and functions, `UpperCamelCase` for types and widgets.
- **Imports**: Prefer relative imports within the same package (e.g. `../repositories/auth_repository.dart`). Use package imports for core or when it improves readability.
- **Async**: Prefer `async`/`await` over raw `Future.then` in widget and repository code. Use `AsyncValue` (Riverpod) for async state in UI.

---

## 12. Version Control and Commits

### Do not commit unless asked

- **Never commit, push, or amend** unless the user **explicitly requests** a commit.
- Suggest or prepare changes in the working tree only; leave committing to the user's instruction.

### When the user requests a commit

1. **Analyze the working tree**: Run `git status` and `git diff`; group changes by **scope** (e.g. auth, feature_x, theme, config).
2. **Create small, focused commits**: One logical change per commit; use semantic messages.
3. **Use semantic commit messages**: `type(scope): short description` — e.g. `feat(auth): add login screen`, `fix(theme): correct primary color`, `refactor(router): extract redirect logic`.

---

## 13. Summary Checklist

- [ ] Prefer functional style and composition; classes only where justified (repositories, entities, notifiers).
- [ ] Write self-documenting code; avoid comments except for non-obvious "why".
- [ ] Thin client: app consumes APIs and presents data; business logic lives on the backend; local persistence only when a feature justifies it (offline, credentials, preferences, caching).
- [ ] Respect clean architecture: domain independent of Flutter and data; presentation and data depend on domain.
- [ ] Prefer existing methods and abstractions; avoid overengineering.
- [ ] Use only the stack above: Flutter, Dart 3, Riverpod, go_router (or MaterialApp.home), http/dio, flutter_secure_storage, env via dotenv/envied, lucide/cupertino icons, google_fonts, flutter_lints.
- [ ] Structure: Feature-based `lib/features/<name>/data|domain|presentation`; core for config, theme, router.
- [ ] State: Riverpod only; one provider per logical state; screens watch and call notifiers; no duplicate state in widgets.
- [ ] Build: Flutter CLI on host; document env and platform steps.
- [ ] Secrets: No hardcoded keys or URLs; .env or envied; .env.example; flutter_secure_storage for tokens.
- [ ] Do not commit unless the user explicitly asks; when committing use semantic messages (`type(scope): description`).

---

## 14. Context-Specific Guidelines

When the repo contains both mobile and other parts:

- **Mobile app** (`lib/` or `mobile/`): Follow this document.
- **Backend** (e.g. separate service or `backend/` in monorepo): Use [BACKEND.md](BACKEND.md) for API, database, and server conventions.
- **Web frontend** (e.g. `frontend/` or `web/`): Use [FRONTEND.md](FRONTEND.md) for React/TypeScript conventions.

If the repo is **mobile-only**, this file is the single agent guideline. A separate BACKEND or FRONTEND file is not needed for the app itself; backend is typically another repository.

---

*Reference for Flutter mobile apps. Use as `AGENTS.md` or `MOBILE.md` at repository root. Built using [agents.md](https://agents.md/) format.*
