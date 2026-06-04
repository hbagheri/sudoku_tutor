import '../board.dart';
import '../hint.dart';
import 'technique.dart';

/// Pointing Pair / Pointing Triple (a.k.a. Locked Candidates Type 1).
///
/// Within a 3x3 box, if every candidate cell for a digit lies inside a single
/// row (or column), the digit must be placed inside that row (or column)
/// *within this box*. Therefore the digit can be eliminated from the other
/// cells of that row/column that lie *outside* the box.
class Pointing extends Technique {
  @override
  String get id => 'pointing';
  @override
  String get nameEn => 'Pointing Pair/Triple';
  @override
  String get nameFa => 'زوج/سه‌تایی اشاره‌گر';
  @override
  int get difficulty => 3;

  EliminationHint? _scanBox(Board board, int boxIndex) {
    final boxCells = board.box(boxIndex).toList();
    for (var digit = 1; digit <= 9; digit++) {
      // Skip if digit is already placed in the box.
      if (boxCells.any((c) => c.value == digit)) continue;

      final candidateCells = boxCells
          .where((c) => c.value == null && c.candidates.contains(digit))
          .toList();
      if (candidateCells.length < 2) continue;

      final rows = candidateCells.map((c) => c.row).toSet();
      final cols = candidateCells.map((c) => c.col).toSet();

      // All candidates share one row → eliminate digit from rest of row.
      if (rows.length == 1) {
        final row = rows.first;
        final eliminations = <Elimination>[];
        for (final cell in board.row(row)) {
          if (cell.box == boxIndex) continue;
          if (cell.value == null && cell.candidates.contains(digit)) {
            eliminations.add(
              Elimination(row: cell.row, col: cell.col, values: {digit}),
            );
          }
        }
        if (eliminations.isNotEmpty) {
          return _buildHint(
            digit: digit,
            evidence: candidateCells,
            eliminations: eliminations,
            boxIndex: boxIndex,
            alignedUnit: UnitRef(UnitType.row, row),
          );
        }
      }

      // All candidates share one column → eliminate from rest of column.
      if (cols.length == 1) {
        final col = cols.first;
        final eliminations = <Elimination>[];
        for (final cell in board.col(col)) {
          if (cell.box == boxIndex) continue;
          if (cell.value == null && cell.candidates.contains(digit)) {
            eliminations.add(
              Elimination(row: cell.row, col: cell.col, values: {digit}),
            );
          }
        }
        if (eliminations.isNotEmpty) {
          return _buildHint(
            digit: digit,
            evidence: candidateCells,
            eliminations: eliminations,
            boxIndex: boxIndex,
            alignedUnit: UnitRef(UnitType.col, col),
          );
        }
      }
    }
    return null;
  }

  EliminationHint _buildHint({
    required int digit,
    required List<Cell> evidence,
    required List<Elimination> eliminations,
    required int boxIndex,
    required UnitRef alignedUnit,
  }) {
    final unitEn = alignedUnit.type == UnitType.row ? 'row' : 'column';
    final unitFa = alignedUnit.type == UnitType.row ? 'سطر' : 'ستون';
    return EliminationHint(
      eliminations: eliminations,
      techniqueId: id,
      techniqueNameEn: nameEn,
      techniqueNameFa: nameFa,
      difficulty: difficulty,
      summaryEn: 'In box ${boxIndex + 1}, digit $digit can only go in '
          '$unitEn ${alignedUnit.index + 1} — remove it elsewhere in '
          'that $unitEn.',
      summaryFa: 'در مربع ${boxIndex + 1}، عدد $digit فقط می‌تواند در '
          '$unitFa ${alignedUnit.index + 1} قرار بگیرد — از بقیه‌ی '
          'این $unitFa حذف می‌شود.',
      explanationEn:
          'Inside box ${boxIndex + 1}, every cell that can still take $digit '
          'lies in $unitEn ${alignedUnit.index + 1}. So whichever cell of '
          'the box ends up holding $digit, it will be in that $unitEn. '
          'That means $digit cannot appear anywhere else in $unitEn '
          '${alignedUnit.index + 1}, so we can erase $digit from the '
          'candidates of the other cells of the $unitEn.',
      explanationFa:
          'در مربع ${boxIndex + 1}، تمام خانه‌هایی که هنوز می‌توانند عدد '
          '$digit را داشته باشند، در $unitFa ${alignedUnit.index + 1} قرار '
          'دارند. پس هر خانه‌ای از این مربع که در نهایت $digit بگیرد، در '
          'همین $unitFa خواهد بود. در نتیجه $digit در جای دیگری از '
          '$unitFa ${alignedUnit.index + 1} نمی‌تواند ظاهر شود و از فهرست '
          'اعداد ممکن آن خانه‌ها حذف می‌شود.',
      highlights: [
        for (final c in evidence)
          CellHighlight(
            row: c.row,
            col: c.col,
            candidates: {digit},
            role: HighlightRole.evidence,
          ),
        for (final e in eliminations)
          CellHighlight(
            row: e.row,
            col: e.col,
            candidates: e.values,
            role: HighlightRole.eliminated,
          ),
      ],
      involvedUnits: [UnitRef(UnitType.box, boxIndex), alignedUnit],
    );
  }

  @override
  Hint? findOne(Board board) {
    for (var b = 0; b < boardSize; b++) {
      final h = _scanBox(board, b);
      if (h != null) return h;
    }
    return null;
  }

  @override
  Iterable<Hint> findAll(Board board) sync* {
    for (var b = 0; b < boardSize; b++) {
      final h = _scanBox(board, b);
      if (h != null) yield h;
    }
  }
}
