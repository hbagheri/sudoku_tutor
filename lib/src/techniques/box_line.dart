import '../board.dart';
import '../hint.dart';
import 'technique.dart';

/// Box-Line Reduction (a.k.a. Locked Candidates Type 2).
///
/// Within a single row (or column), if every candidate cell for a digit lies
/// inside one 3x3 box, the digit must be placed in that box *within this
/// row/column*. Therefore the digit can be eliminated from the other cells
/// of that box.
class BoxLine extends Technique {
  @override
  String get id => 'box_line';
  @override
  String get nameEn => 'Box-Line Reduction';
  @override
  String get nameFa => 'کاهش مربع-خط';
  @override
  int get difficulty => 4;

  EliminationHint? _scanLine(
    Board board,
    List<Cell> line,
    UnitType type,
    int index,
  ) {
    for (var digit = 1; digit <= 9; digit++) {
      if (line.any((c) => c.value == digit)) continue;

      final candidates = line
          .where((c) => c.value == null && c.candidates.contains(digit))
          .toList();
      if (candidates.length < 2) continue;

      final boxes = candidates.map((c) => c.box).toSet();
      if (boxes.length != 1) continue;
      final boxIndex = boxes.first;

      final eliminations = <Elimination>[];
      for (final cell in board.box(boxIndex)) {
        // Skip cells that are part of the originating line.
        final inLine = switch (type) {
          UnitType.row => cell.row == index,
          UnitType.col => cell.col == index,
          UnitType.box => false,
        };
        if (inLine) continue;
        if (cell.value == null && cell.candidates.contains(digit)) {
          eliminations.add(
            Elimination(row: cell.row, col: cell.col, values: {digit}),
          );
        }
      }
      if (eliminations.isNotEmpty) {
        return _buildHint(
          digit: digit,
          evidence: candidates,
          eliminations: eliminations,
          lineType: type,
          lineIndex: index,
          boxIndex: boxIndex,
        );
      }
    }
    return null;
  }

  EliminationHint _buildHint({
    required int digit,
    required List<Cell> evidence,
    required List<Elimination> eliminations,
    required UnitType lineType,
    required int lineIndex,
    required int boxIndex,
  }) {
    final lineEn = lineType == UnitType.row ? 'row' : 'column';
    final lineFa = lineType == UnitType.row ? 'سطر' : 'ستون';
    return EliminationHint(
      eliminations: eliminations,
      techniqueId: id,
      techniqueNameEn: nameEn,
      techniqueNameFa: nameFa,
      difficulty: difficulty,
      summaryEn: 'In $lineEn ${lineIndex + 1}, digit $digit fits only inside '
          'box ${boxIndex + 1} — remove it elsewhere in that box.',
      summaryFa: 'در $lineFa ${lineIndex + 1}، عدد $digit فقط در مربع '
          '${boxIndex + 1} جا می‌شود — از بقیه‌ی این مربع حذف می‌شود.',
      explanationEn:
          'Every cell of $lineEn ${lineIndex + 1} that can still take $digit '
          'sits inside box ${boxIndex + 1}. So whichever cell of the $lineEn '
          'ends up holding $digit, it will be in box ${boxIndex + 1}. That '
          'means $digit cannot appear anywhere else in that box, so we can '
          'erase $digit from the candidates of the other cells of the box.',
      explanationFa:
          'تمام خانه‌های $lineFa ${lineIndex + 1} که هنوز می‌توانند عدد '
          '$digit را داشته باشند، درون مربع ${boxIndex + 1} هستند. پس هر '
          'خانه‌ای از این $lineFa که در نهایت $digit بگیرد، در همین مربع '
          'خواهد بود. در نتیجه $digit در جای دیگری از این مربع نمی‌تواند '
          'ظاهر شود و از فهرست اعداد ممکن آن خانه‌ها حذف می‌شود.',
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
      involvedUnits: [
        UnitRef(lineType, lineIndex),
        UnitRef(UnitType.box, boxIndex),
      ],
    );
  }

  @override
  Hint? findOne(Board board) {
    for (var i = 0; i < boardSize; i++) {
      final h = _scanLine(board, board.row(i).toList(), UnitType.row, i);
      if (h != null) return h;
    }
    for (var i = 0; i < boardSize; i++) {
      final h = _scanLine(board, board.col(i).toList(), UnitType.col, i);
      if (h != null) return h;
    }
    return null;
  }

  @override
  Iterable<Hint> findAll(Board board) sync* {
    for (var i = 0; i < boardSize; i++) {
      final h = _scanLine(board, board.row(i).toList(), UnitType.row, i);
      if (h != null) yield h;
    }
    for (var i = 0; i < boardSize; i++) {
      final h = _scanLine(board, board.col(i).toList(), UnitType.col, i);
      if (h != null) yield h;
    }
  }
}
