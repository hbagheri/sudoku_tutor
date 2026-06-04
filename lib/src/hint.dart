import 'board.dart';

/// A reference to a cell + an optional set of candidates within that cell.
/// Used to tell the UI which cells to highlight and (optionally) which digit
/// chips inside the cell to emphasize.
class CellHighlight {
  final int row;
  final int col;
  final Set<int> candidates;
  final HighlightRole role;

  const CellHighlight({
    required this.row,
    required this.col,
    this.candidates = const <int>{},
    this.role = HighlightRole.evidence,
  });

  @override
  String toString() => 'CellHighlight(r$row,c$col,role=$role,cands=$candidates)';
}

/// The semantic role of a highlight, used by the UI to pick a color.
enum HighlightRole {
  /// The cell where the action ultimately takes place.
  target,

  /// Cells whose placed values or candidates form the reasoning.
  evidence,

  /// Cells affected by an elimination (where a candidate gets removed).
  eliminated,
}

/// Identifies a unit (row/column/box) used in the reasoning, so the UI can
/// outline it. Type is one of the three; index is 0..8.
class UnitRef {
  final UnitType type;
  final int index;
  const UnitRef(this.type, this.index);

  @override
  String toString() => '${type.name}$index';
}

enum UnitType { row, col, box }

/// A single solver action together with the explanation needed to teach it.
///
/// Sealed: every hint is either a `PlaceHint` (assigns a digit) or an
/// `EliminationHint` (removes one or more candidates).
sealed class Hint {
  /// Stable id of the technique that produced this hint, e.g. `"naked_single"`.
  final String techniqueId;

  /// English display name of the technique.
  final String techniqueNameEn;

  /// Persian display name.
  final String techniqueNameFa;

  /// 1..14 — used both for sorting and for UI color/badge.
  final int difficulty;

  /// One-line summary suitable for the always-visible hint bar.
  /// EN.
  final String summaryEn;

  /// One-line summary, Persian.
  final String summaryFa;

  /// Multi-paragraph explanation shown when the user expands the hint bar.
  final String explanationEn;
  final String explanationFa;

  /// Cells the UI should highlight, with roles.
  final List<CellHighlight> highlights;

  /// Units (rows/cols/boxes) the UI should outline as part of the reasoning.
  final List<UnitRef> involvedUnits;

  const Hint({
    required this.techniqueId,
    required this.techniqueNameEn,
    required this.techniqueNameFa,
    required this.difficulty,
    required this.summaryEn,
    required this.summaryFa,
    required this.explanationEn,
    required this.explanationFa,
    required this.highlights,
    this.involvedUnits = const [],
  });
}

/// A "place this digit here" hint.
class PlaceHint extends Hint {
  final int row;
  final int col;
  final int value;

  const PlaceHint({
    required this.row,
    required this.col,
    required this.value,
    required super.techniqueId,
    required super.techniqueNameEn,
    required super.techniqueNameFa,
    required super.difficulty,
    required super.summaryEn,
    required super.summaryFa,
    required super.explanationEn,
    required super.explanationFa,
    required super.highlights,
    super.involvedUnits,
  });

  @override
  String toString() =>
      'PlaceHint($techniqueId: r$row,c$col=$value)';
}

/// "Remove these candidates from these cells" hint.
class EliminationHint extends Hint {
  /// Cells (row, col) and the set of digits to remove from their candidates.
  final List<Elimination> eliminations;

  const EliminationHint({
    required this.eliminations,
    required super.techniqueId,
    required super.techniqueNameEn,
    required super.techniqueNameFa,
    required super.difficulty,
    required super.summaryEn,
    required super.summaryFa,
    required super.explanationEn,
    required super.explanationFa,
    required super.highlights,
    super.involvedUnits,
  });

  @override
  String toString() =>
      'EliminationHint($techniqueId: $eliminations)';
}

class Elimination {
  final int row;
  final int col;
  final Set<int> values;
  const Elimination({
    required this.row,
    required this.col,
    required this.values,
  });

  @override
  String toString() => 'r$row,c$col-$values';
}

/// Apply a hint to a board, mutating it in place.
///
/// For a `PlaceHint`, places the value and removes it from peers' candidates.
/// For an `EliminationHint`, just removes the listed candidates.
void applyHint(Board board, Hint hint) {
  switch (hint) {
    case PlaceHint(:final row, :final col, :final value):
      final cell = board.at(row, col);
      cell.value = value;
      cell.candidates.clear();
      for (final peer in board.peers(cell)) {
        peer.candidates.remove(value);
      }
    case EliminationHint(:final eliminations):
      for (final e in eliminations) {
        board.at(e.row, e.col).candidates.removeAll(e.values);
      }
  }
}
