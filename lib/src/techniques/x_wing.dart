import '../board.dart';
import '../hint.dart';
import 'technique.dart';

/// X-Wing.
///
/// For a digit D, find 2 rows where D has exactly 2 candidate cells, and
/// where those cells share the same 2 columns. Then D must be in either the
/// `\` or `/` diagonal of that 2×2 — so D can be eliminated from those 2
/// columns in every other row. The column-flavored version works the same
/// way with rows and columns swapped.
class XWing extends Technique {
  @override
  String get id => 'x_wing';
  @override
  String get nameEn => 'X-Wing';
  @override
  String get nameFa => 'ایکس-وینگ';
  @override
  int get difficulty => 9;

  EliminationHint? _scanRows(Board board) {
    for (var d = 1; d <= 9; d++) {
      // For each row, find columns where d is a candidate. Only keep rows
      // with exactly 2 such columns.
      final rowSpots = <int, List<int>>{};
      for (var r = 0; r < boardSize; r++) {
        final cols = <int>[];
        for (var c = 0; c < boardSize; c++) {
          final cell = board.at(r, c);
          if (cell.value == null && cell.candidates.contains(d)) {
            cols.add(c);
          }
        }
        if (cols.length == 2) rowSpots[r] = cols;
      }
      final rows = rowSpots.keys.toList();
      for (var i = 0; i < rows.length; i++) {
        for (var j = i + 1; j < rows.length; j++) {
          final ra = rows[i];
          final rb = rows[j];
          final a = rowSpots[ra]!;
          final b = rowSpots[rb]!;
          if (a[0] == b[0] && a[1] == b[1]) {
            final eliminations = <Elimination>[];
            for (final col in a) {
              for (var r = 0; r < boardSize; r++) {
                if (r == ra || r == rb) continue;
                final cell = board.at(r, col);
                if (cell.value == null && cell.candidates.contains(d)) {
                  eliminations.add(
                    Elimination(row: r, col: col, values: {d}),
                  );
                }
              }
            }
            if (eliminations.isNotEmpty) {
              return _buildHint(
                digit: d,
                rows: [ra, rb],
                cols: a,
                eliminations: eliminations,
                base: UnitType.row,
                evidenceCells: [
                  board.at(ra, a[0]),
                  board.at(ra, a[1]),
                  board.at(rb, a[0]),
                  board.at(rb, a[1]),
                ],
              );
            }
          }
        }
      }
    }
    return null;
  }

  EliminationHint? _scanCols(Board board) {
    for (var d = 1; d <= 9; d++) {
      final colSpots = <int, List<int>>{};
      for (var c = 0; c < boardSize; c++) {
        final rows = <int>[];
        for (var r = 0; r < boardSize; r++) {
          final cell = board.at(r, c);
          if (cell.value == null && cell.candidates.contains(d)) {
            rows.add(r);
          }
        }
        if (rows.length == 2) colSpots[c] = rows;
      }
      final cols = colSpots.keys.toList();
      for (var i = 0; i < cols.length; i++) {
        for (var j = i + 1; j < cols.length; j++) {
          final ca = cols[i];
          final cb = cols[j];
          final a = colSpots[ca]!;
          final b = colSpots[cb]!;
          if (a[0] == b[0] && a[1] == b[1]) {
            final eliminations = <Elimination>[];
            for (final row in a) {
              for (var c = 0; c < boardSize; c++) {
                if (c == ca || c == cb) continue;
                final cell = board.at(row, c);
                if (cell.value == null && cell.candidates.contains(d)) {
                  eliminations.add(
                    Elimination(row: row, col: c, values: {d}),
                  );
                }
              }
            }
            if (eliminations.isNotEmpty) {
              return _buildHint(
                digit: d,
                rows: a,
                cols: [ca, cb],
                eliminations: eliminations,
                base: UnitType.col,
                evidenceCells: [
                  board.at(a[0], ca),
                  board.at(a[1], ca),
                  board.at(a[0], cb),
                  board.at(a[1], cb),
                ],
              );
            }
          }
        }
      }
    }
    return null;
  }

  EliminationHint _buildHint({
    required int digit,
    required List<int> rows,
    required List<int> cols,
    required List<Elimination> eliminations,
    required UnitType base,
    required List<Cell> evidenceCells,
  }) {
    final rowsText = rows.map((r) => r + 1).join(' & ');
    final colsText = cols.map((c) => c + 1).join(' & ');
    final baseEn = base == UnitType.row ? 'rows' : 'columns';
    final baseFa = base == UnitType.row ? 'سطرها' : 'ستون‌ها';
    final crossEn = base == UnitType.row ? 'columns' : 'rows';
    final crossFa = base == UnitType.row ? 'ستون‌ها' : 'سطرها';

    return EliminationHint(
      eliminations: eliminations,
      techniqueId: id,
      techniqueNameEn: nameEn,
      techniqueNameFa: nameFa,
      difficulty: difficulty,
      summaryEn: 'X-Wing on digit $digit in $baseEn $rowsText / $colsText.',
      summaryFa: 'ایکس-وینگ روی عدد $digit در $baseFa $rowsText / $colsText.',
      explanationEn:
          'In $baseEn $rowsText, digit $digit has exactly the same two '
          '$crossEn ($colsText) as its only candidate cells. So $digit must '
          'occupy one of those $crossEn in each $baseEn — forming a 2×2 '
          'rectangle of corners with $digit landing on one of its diagonals. '
          'Either way, no other cell in $crossEn $colsText can hold $digit, '
          'so we can erase $digit from those columns/rows in the other '
          '$baseEn.',
      explanationFa:
          'در $baseFa $rowsText، عدد $digit دقیقاً در همان دو $crossFa '
          '($colsText) به عنوان گزینه باقی مانده. پس $digit در هر کدام از '
          'این $baseFa باید در یکی از این $crossFa باشد — یعنی یک مستطیل '
          '۲×۲ تشکیل می‌شود که $digit در یکی از قطرهایش قرار می‌گیرد. در '
          'هر حال، هیچ خانه‌ی دیگری در $crossFa $colsText نمی‌تواند '
          '$digit باشد و این عدد از $baseFa دیگر در همان $crossFa حذف '
          'می‌شود.',
      highlights: [
        for (final c in evidenceCells)
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
        for (final r in rows) UnitRef(UnitType.row, r),
        for (final c in cols) UnitRef(UnitType.col, c),
      ],
    );
  }

  @override
  Hint? findOne(Board board) {
    return _scanRows(board) ?? _scanCols(board);
  }

  @override
  Iterable<Hint> findAll(Board board) sync* {
    final r = _scanRows(board);
    if (r != null) yield r;
    final c = _scanCols(board);
    if (c != null) yield c;
  }
}
