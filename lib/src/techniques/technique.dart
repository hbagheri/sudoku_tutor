import '../board.dart';
import '../hint.dart';

/// A solving technique. Implementations look for one pattern (e.g. naked
/// single, X-Wing) on the board and emit hints.
///
/// Techniques must be pure: they do not mutate the board. Callers apply the
/// returned hints with [applyHint] to advance the solution.
abstract class Technique {
  /// Stable id used to tag hints, e.g. `"naked_single"`.
  String get id;
  String get nameEn;
  String get nameFa;

  /// Ordinal difficulty 1..14. Lower = applied first by the solver.
  int get difficulty;

  /// Find at most one hint produced by this technique on the given board.
  /// Returns null if no instance of this pattern is present.
  ///
  /// Returning at most one keeps the teaching loop snappy: each call shows
  /// the user a single deduction step.
  Hint? findOne(Board board);

  /// Find *all* instances. Useful for batched auto-solve.
  Iterable<Hint> findAll(Board board);
}
