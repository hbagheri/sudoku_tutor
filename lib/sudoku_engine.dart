/// Public API of the Sudoku solving + teaching engine.
///
/// The engine is plain Dart (no Flutter dependency) so it can be unit-tested
/// with `dart test` and reused across UIs.
library;

export 'src/board.dart';
export 'src/generator.dart';
export 'src/hint.dart';
export 'src/solver.dart';
export 'src/techniques/box_line.dart';
export 'src/techniques/hidden_single.dart';
export 'src/techniques/hidden_subset.dart';
export 'src/techniques/naked_single.dart';
export 'src/techniques/naked_subset.dart';
export 'src/techniques/pointing.dart';
export 'src/techniques/technique.dart';
export 'src/techniques/swordfish.dart';
export 'src/techniques/unique_rectangle.dart';
export 'src/techniques/x_wing.dart';
export 'src/techniques/y_wing.dart';
