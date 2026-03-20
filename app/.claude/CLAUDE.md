# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the app
flutter run

# Build
flutter build apk --release
flutter build ipa --release

# Analyze & lint
flutter analyze

# Format
dart format lib/

# Tests (minimal — only a template widget test exists)
flutter test
flutter test test/widget_test.dart
```

## Environment

- Dart SDK: `^3.10.8`
- Flutter: stable channel
- Lint rules: `package:flutter_lints/flutter.yaml` (see `analysis_options.yaml`)
- Target platforms: Android + iOS

## Architecture

**Majske igre** is a dark-themed Flutter event app for a Slovenian student festival. It shows sport events, concerts, and culture events with a calendar and detail screens.

### Layer structure

```
lib/
├── bloc/           # App-wide state (DataCubit, EventNotificationsCubit)
├── data/           # Models + repositories (manual fromJson, no codegen)
├── screens/        # Feature screens, each with optional part files for tabs
├── widgets/        # Reusable UI components (cards, buttons, headers)
├── extensions/     # DateTime, String, Map extensions
├── services/       # NotificationService (FCM + local notifications)
├── styles/         # MIColors (primary, sport, concert, culture accent colors)
├── env.dart        # Environment constants (baseUrl, notificationApi)
├── app_navigator.dart  # Global navigatorKey
└── firebase_options.dart  # Generated Firebase config (do not edit)
```

### Routing

Navigation uses named `MaterialApp.routes` with string keys:

```dart
routes: {
  '/': (_) => const HomeScreen(),
  'home': (_) => const HomeScreen(),
  'contact': (_) => const ContactScreen(),
  'about': (_) => const AboutScreen(),
  'info-point': (_) => const InfoPointScreen(),
  'settings': (_) => const SettingsScreen(),
  'settings/notifications': (_) => const SettingsNotificationScreen(),
}
```

A global `navigatorKey` lives in `app_navigator.dart`. Navigate with `Navigator.of(context).pushNamed('route')`. When adding new screens, register them in `MaterialApp.routes` in `main.dart`.

### State management

- `DataCubit` (singleton, provided at app root via `MultiBlocProvider`) is the single source of truth for all event data. It exposes `sportEvents`, `concerts`, `cultureEvents` (draft-filtered), plus `sportFallbackImageUrl` / `cultureFallbackImageUrl` computed getters.
- `EventNotificationsCubit` manages notification subscriptions persisted via `NotificationRepository`.
- `EventNotificationUICubit` is a screen-scoped cubit for notification toggle UI state, created per detail screen via `BlocProvider`.
- Repositories are provided via `MultiRepositoryProvider` at app root: `OrganizerRepository`, `EventDescriptionRepository`, `EventRepository`, `NotificationRepository`.
- Prefer `Cubit` over full `Bloc`. Prefer `StatelessWidget` + bloc over `StatefulWidget`.
- New data requirements should be added to `DataCubit`/`DataState` — do not create new standalone cubits for event data.

### Screen patterns

- Screens with tabs use `part` / `part of` to split tab widgets into `widgets/_tab_name.widget.dart` files — they share the parent screen's imports.
  Example: `lib/screens/sport/sport_screen.dart` uses `part 'widgets/_sport_tab.widget.dart'`.
  When creating new tab files, they must be `part` files — not standalone widgets with their own imports.
- Detail screens (sport, culture, concert) read `DataCubit` via `context.read<DataCubit>().state` for fallback images — no parameter passing.
- `CultureEventDayCard` reads `DataCubit` internally for its fallback image, so call sites stay clean.
- App uses a `_StartupOverlay` (StatefulWidget with Stack) in `main.dart` that shows `StartupLoadingScreen` on top of all routes until startup completes.

### Date/time handling

Backend sends Java `LocalDateTime` serialized with a trailing `Z` (e.g. `2025-05-07T17:00:00.000Z`). Parse with `.toLocal()` to convert to device timezone:
```dart
DateTime.parse(json['date'] as String).toLocal()
```
Never compare `DateTime.now().toUtc()` against event times — always compare local-to-local.

### Image fallback pattern

When an event has no image, screens fall back to a category cover image. The logic lives in `DataState` getters (`sportFallbackImageUrl`, `cultureFallbackImageUrl`) — priority: `eventDescription.sportCover/cultureCover` → first valid event image → hardcoded URL (`_lastResortFallbackImage`). URL validation checks for non-null, non-empty, and not ending in `'null'`.

Use `cached_network_image` for network images. Always provide `errorWidget` and a loading `placeholder`.

### Error handling in DataCubit

`DataCubit.loadData()` uses `Future.wait` with `eagerError: false` and individual `.catchError` per repository call, so partial failures still load available data. On total failure, it emits `DataState.empty(dataLoaded: true)`. The `dataLoaded` flag signals to UI that loading is complete (even if data is empty). Follow this same pattern when adding new data loading.

## Coding conventions

### Style rules

- JSON serialization is manual (`fromJson` methods), no code generation — do not introduce `json_serializable`, `freezed`, or `build_runner`.
- `dart_util_box` provides helpers like `whereToList`, `mapToList`, `startOfDay`.
- `remixicon` package is used for icons throughout (e.g. `RemixIcons.map_pin_2_line`).
- `ScreenUtil` design size is 375×812; use `.w`, `.h`, `.sp` — avoid hard-coded pixel values.
- Locale is `sl_SI` (Slovenian); date formats use `intl`'s `DateFormat` with that locale.
- Font: `GoogleFonts.nunitoTextTheme` applied globally with white body/display colors.
- Theme: dark only (`Brightness.dark`), `ColorScheme.fromSeed` with `MIColors.primary` as seed. No light theme.
- No trailing comments in code.
- One class per file. Closely related classes can be linked via `part` / `part of`.
- If a method/function body is a single expression, use arrow syntax (`=>`).
- Line length: 80 characters or fewer.
- Naming: `PascalCase` for classes, `camelCase` for members/variables/functions/enums, `snake_case` for files.
- File naming uses dot notation: `event.repository.dart`, `data.bloc.dart`, `sport_event.model.dart`.
- Keep functions short with a single purpose (aim for under 20 lines).
- Avoid magic numbers — use named constants.
- Avoid abbreviations — use meaningful, descriptive names.

### Import ordering

1. `dart:` imports
2. `package:flutter/` imports
3. Third-party package imports (alphabetical)
4. Project-relative imports (`package:majske_igre/`)

### Null safety

- Write soundly null-safe code. Avoid `!` unless the value is guaranteed to be non-null.
- Use pattern matching and records where they simplify null checks or type narrowing.

### Error handling

- Use `try-catch` blocks with specific exception types, not bare `catch` (except for top-level catch-all like in `main()`).
- For data loading, prefer `.catchError` with fallback values so partial failures don't block the whole app.
- Use `developer.log` from `dart:developer` for structured logging — never use bare `print`.

### Async patterns

- Use `Future` + `async`/`await` for single async operations.
- Use `Future.wait` for parallel loading (as in `DataCubit.loadData()`).
- Use `Stream` + `StreamBuilder` for sequences of async events.
- Use `compute()` for expensive work (e.g. large JSON parsing) to avoid blocking the UI thread.

### Widget conventions

- Prefer `StatelessWidget` + `BlocBuilder`/`BlocListener` over `StatefulWidget`.
- Prefer composition over inheritance — compose smaller widgets instead of deep nesting.
- Use `const` constructors wherever possible to reduce rebuilds.
- Break large `build()` methods into smaller, private `Widget` classes (not helper methods returning widgets).
- Use `ListView.builder` or `SliverList` for long/dynamic lists.
- Avoid `Positioned` when possible; prefer layout widgets like `Align`,
  `Padding`, `SizedBox`, `Row`, and `Column` first.
- Avoid expensive operations (network calls, heavy computation) inside `build()`.

### Documentation

- Add `///` doc comments to all public APIs.
- First sentence should be a concise summary ending with a period.
- Comment *why*, not *what* — code should be self-explanatory.
- No useless documentation that just restates the class/method name.

## Key dependencies

| Package | Purpose |
|---------|---------|
| `flutter_bloc` | Cubit/Bloc state management |
| `flutter_screenutil` | Responsive sizing (375×812 design) |
| `google_fonts` | Nunito font |
| `dio` | HTTP client |
| `cached_network_image` | Image caching with placeholders |
| `flutter_map` | Map display |
| `calendar_view` | Calendar widget |
| `remixicon` | Icon set |
| `dart_util_box` | Collection/date utilities |
| `flutter_svg` | SVG rendering |
| `markdown_widget` | Markdown rendering |
| `flutter_html` | HTML content rendering |
| `firebase_core` + `firebase_messaging` | Push notifications |
| `flutter_local_notifications` | Local notification scheduling |
| `intl` | Slovenian date/number formatting |
| `shared_preferences` | Local key-value persistence |

## Things to avoid

- Do not create `StatefulWidget` when a `Cubit` would work.
- Do not add new standalone cubits for event data — extend `DataCubit`/`DataState` instead.
- Do not introduce code generation packages (`build_runner`, `json_serializable`, `freezed`).
- Do not use `print` for logging — use `developer.log`.
- Do not use `!` null assertion without a clear guarantee.
- Do not hard-code pixel values — use `ScreenUtil` (`.w`, `.h`, `.sp`).
- Do not add routes outside of `MaterialApp.routes` in `main.dart`.
- Do not modify `firebase_options.dart` — it is generated.
- Do not add a light theme — this app is dark-only.