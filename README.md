# Mil ke Khelo — Flutter app

A Flutter port of the Mil ke Khelo web games: **Snakes & Ladders**, **Memory
Grid**, **First**, and **Thank You** — one home screen, four self-contained
games.

## Getting started

This code was written by hand in a sandboxed environment with no access to
the Flutter SDK or pub.dev, so it has **not** been run through `flutter pub
get`, `flutter analyze`, or a real build yet. A careful manual review of
every file (imports, constructor signatures, enum exhaustiveness, null
safety) found no issues, but you should treat the first build on your own
machine as the real verification step. If `flutter analyze` turns up
anything, it'll almost certainly be something small — happy to fix it fast.

1. Make sure you have the Flutter SDK installed (`flutter --version`).
2. From this folder, generate the native Android/iOS platform folders (they
   aren't included yet, since scaffolding them requires the Flutter SDK):
   ```
   flutter create . --project-name milkekhelo --org com.kapsgrafix
   ```
   This adds `android/` and `ios/` folders around the existing `lib/` and
   `pubspec.yaml` without touching them.
3. Install dependencies:
   ```
   flutter pub get
   ```
4. Run it:
   ```
   flutter run
   ```

Fonts ('Baloo 2', 'Montserrat', 'Nunito Sans') are pulled in at runtime via
the `google_fonts` package, so the very first launch needs internet access
to fetch and cache them. If you'd rather ship fully offline from the first
launch, download the three font families' `.ttf` files, drop them in an
`assets/fonts/` folder, register them in `pubspec.yaml`, and swap
`lib/core/theme/app_text_styles.dart` to use `TextStyle(fontFamily: ...)`
instead of the `GoogleFonts.*` helpers.

## Architecture — why a change to one game never touches another

```
lib/
  main.dart                      — app entry, just hands off to HomeScreen
  core/                          — the ONLY things shared across games
    theme/                       — shared colors + font helpers
    localization/app_language.dart — the EN/HI toggle, shared app-wide
    widgets/                     — GameHeader, PressableCard, StrokedText
  home/
    home_screen.dart             — the 2x2 launcher grid, one card per game
  games/
    snakes_and_ladders/          — board, dice, timer, snakes/ladders data,
                                    translations — all self-contained
    memory_grid/                 — level picker, solo + duel gameplay,
                                    confetti, translations — self-contained
    first/                       — 51-card icebreaker deck + screen
    thank_you/                   — 51-card gratitude deck + screen
```

Each `games/<name>/` folder owns everything specific to that game: its
colors, its copy (English + Hindi), its game logic, its screens. The only
things a game imports from outside its own folder are the shared `core/`
widgets (header, the bouncy card look, stroked text) and the shared
language toggle. That means:

- Asking for a Snakes & Ladders tweak only touches files under
  `games/snakes_and_ladders/`.
- Adding a fifth game later means adding a new `games/<name>/` folder and
  one new card + route in `home/home_screen.dart` — nothing about the
  existing four games changes.

## What's a placeholder vs. faithfully ported

- **Game logic, rules, timing, and all English/Hindi copy** (including all
  102 First + Thank You cards) were extracted directly from the original
  web app's source and ported as exactly as Flutter allows — dice rolls,
  snake/ladder mappings, scoring, Memory Grid's reveal timings and
  solo/duel rules, the exact card text, etc.
- **Visual assets**: the original web app used hand-made PNGs (game-card
  thumbnails, the Snakes & Ladders board art, the wordmark logo). Those
  files weren't available for this port, so they're replaced with emoji +
  procedurally-drawn placeholders (the board is drawn in code from the
  same snake/ladder data, not a static image). Swap in real artwork
  whenever you have it — the code has a comment at each spot pointing to
  where an `Image` widget would replace the placeholder.
- **Minor gameplay quirks not carried over** (called out in code comments
  where relevant): Thank You's swipe-only-advances-forward behavior (both
  games now support swiping either direction, which is simpler and more
  consistent); the original's occasional English-only gaps in the Memory
  Grid how-to-play text were filled in with Hindi translations instead of
  left blank.

## Known follow-ups worth doing before a store release

- Add real app icons, splash screen, and store metadata (`flutter create`
  gives you the placeholders to replace).
- Consider bundling fonts locally (see above) instead of fetching them at
  runtime.
- Add sound effects/haptics if you want them — the original web app has
  none, so none were added here either.
