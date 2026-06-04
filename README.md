# Sudoku Tutor · معلم سودوکو

An educational Sudoku game that **teaches you the solving techniques** —
one logical step at a time — instead of just handing you the answer.

Built with **Flutter** for Android and Linux desktop. Bilingual interface
(English / Persian), light and dark themes, fully offline.

## Why it exists

Most Sudoku apps give you a "hint" button that just fills in the next cell.
Sudoku Tutor never does that. Every hint is tagged with the *technique* it
came from — Naked Single, Hidden Single, Pointing Pair, Box-Line Reduction,
Naked / Hidden Pair · Triple · Quad, X-Wing — and explains, in plain
language, why this digit must go here. By the time you've solved a
Master-level puzzle, you've actually internalized the techniques.

## Features

- **Six difficulty levels** — Easy through Legendary, each defined by the
  hardest solving technique required.
- **Step-by-step teaching mode** — request a hint or auto-solve one step
  at a time; the explanation pane tells you what technique was applied.
- **Pencil marks** — fill in possibilities manually, or let the app keep
  them in sync after every move (toggleable).
- **Bilingual UI** — English and Persian (RTL).
- **Light / dark / system themes**.
- **Generator** — every puzzle is freshly built and verified to have a
  unique solution.
- **Undo, erase, mistakes counter, timer**.

## Tech stack

- **Flutter 3.44+** (Material 3, Dart 3.12+)
- Pure-Dart sudoku engine in `lib/src/` — no Flutter dependency, fully
  unit-testable.
- `shared_preferences` for settings persistence.
- Android (min API 24+) and Linux desktop targets configured. iOS and
  Windows targets are not enabled but could be added in a few minutes.

## Project layout

```
lib/
  sudoku_engine.dart       ← public engine API (Board, Hint, Solver, Generator)
  src/
    board.dart             ← 9x9 model
    hint.dart              ← Hint sealed class hierarchy
    generator.dart         ← Difficulty-aware puzzle generator
    solver.dart            ← Technique orchestrator + brute-force validator
    techniques/            ← One file per technique
      naked_single.dart
      hidden_single.dart
      pointing.dart
      box_line.dart
      naked_subset.dart    ← Pair, Triple, Quad
      hidden_subset.dart   ← Pair, Triple, Quad
      x_wing.dart
  app/
    settings.dart          ← Persisted user settings
    game_controller.dart   ← In-game state (ChangeNotifier)
    strings.dart           ← FA / EN string bundles
  screens/                 ← HomeScreen, GameScreen
  widgets/                 ← SudokuBoardView, NumberPad, TechniqueBar...
test/                      ← 29 unit tests covering board, techniques,
                              solver, and generator
```

## Building from source

```bash
# Install Flutter SDK (3.44+ stable) and add it to PATH.
# https://docs.flutter.dev/get-started/install/linux

git clone git@github.com:hbagheri/sudoku_tutor.git
cd sudoku_tutor
flutter pub get

# Run all tests
flutter test

# Run on Linux desktop
flutter run -d linux

# Build Android APK
flutter build apk --release

# Build Android App Bundle (for Play Store)
flutter build appbundle --release
```

### Android signing for release

For release builds you'll need a keystore. The repo ships with a template
at `android/key.properties.template` — copy it to `android/key.properties`
and fill in your own paths and passwords (this file is gitignored).

```bash
keytool -genkey -v -keystore ~/sudoku_upload.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias upload
cp android/key.properties.template android/key.properties
$EDITOR android/key.properties
```

## Roadmap

- More advanced techniques: Y-Wing (XY-Wing), Swordfish, Unique Rectangle,
  Simple Coloring, XY-Chain, Forcing Chain.
- Save / continue a game across sessions.
- Statistics screen (best times, completion rate per difficulty).
- AdMob integration (rewarded hints) for the Play Store build.
- iOS / Windows / Web targets.
- F-Droid metadata.

## Privacy

See [PRIVACY_POLICY.md](PRIVACY_POLICY.md). The short version: nothing
leaves your device. Advertising, when enabled, follows AdMob's standard
data handling.

## License

MIT — see [LICENSE](LICENSE).

## Credits

Built by **Hassan Bagheri** (`hbagheri@glenar.com`) with a lot of help
from Claude (Anthropic).
