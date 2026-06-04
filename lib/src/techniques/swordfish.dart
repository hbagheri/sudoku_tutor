import '../board.dart';
import '../hint.dart';
import 'technique.dart';

/// Swordfish — a 3×3 generalisation of X-Wing.
///
/// For a digit D, find 3 rows where every candidate cell for D sits inside
/// the SAME 3 columns. Each row may have 2 or 3 candidate cells (no more,
/// no less than 2 *distinct* columns used). Because D needs to appear once
/// per row and uses only 3 columns to do so, those columns lock D into a
/// 3×3 sub-grid — and D can be eliminated from those columns in every
/// other row. The column-flavored swordfish works the same way with rows
/// and columns swapped.
class Swordfish extends Technique {
  @override
  String get id => 'swordfish';
  @override
  String get nameEn => 'Swordfish';
  @override
  String get nameFa => 'سوردفیش';
  @override
  int get difficulty => 11;

  EliminationHint? _scanRows(Board board) {
    for (var d = 1; d <= 9; d++) {
      // Collect rows where D has 2 or 3 candidate columns.
      final rowCols = <int, Set<int>>{};
      for (var r = 0; r < boardSize; r++) {
        final cols = <int>{};
        for (var c = 0; c < boardSize; c++) {
          final cell = board.at(r, c);
          if (cell.value == null && cell.candidates.contains(d)) {
            cols.add(c);
          }
        }
        if (cols.length == 2 || cols.length == 3) rowCols[r] = cols;
      }
      final eligibleRows = rowCols.keys.toList();
      if (eligibleRows.length < 3) continue;

      // Try every combination of 3 rows.
      for (var i = 0; i < eligibleRows.length - 2; i++) {
        for (var j = i + 1; j < eligibleRows.length - 1; j++) {
          for (var k = j + 1; k < eligibleRows.length; k++) {
            final ra = eligibleRows[i];
            final rb = eligibleRows[j];
            final rc = eligibleRows[k];
            final unionCols = <int>{
              ...rowCols[ra]!,
              ...rowCols[rb]!,
              ...rowCols[rc]!,
            };
            if (unionCols.length != 3) continue;

            // Found a Swordfish. Eliminate D from those columns in other rows.
            final eliminations = <Elimination>[];
            for (final col in unionCols) {
              for (var r = 0; r < boardSize; r++) {
                if (r == ra || r == rb || r == rc) continue;
                final cell = board.at(r, col);
                if (cell.value == null && cell.candidates.contains(d)) {
                  eliminations.add(
                    Elimination(row: r, col: col, values: {d}),
                  );
                }
              }
            }
            if (eliminations.isEmpty) continue;

            final evidence = <Cell>[
              for (final r in [ra, rb, rc])
                for (final c in rowCols[r]!) board.at(r, c),
            ];
            return _buildHint(
              digit: d,
              evidence: evidence,
              eliminations: eliminations,
              base: UnitType.row,
              baseIndices: [ra, rb, rc],
              crossIndices: unionCols.toList()..sort(),
            );
          }
        }
      }
    }
    return null;
  }

  EliminationHint? _scanCols(Board board) {
    for (var d = 1; d <= 9; d++) {
      final colRows = <int, Set<int>>{};
      for (var c = 0; c < boardSize; c++) {
        final rows = <int>{};
        for (var r = 0; r < boardSize; r++) {
          final cell = board.at(r, c);
          if (cell.value == null && cell.candidates.contains(d)) {
            rows.add(r);
          }
        }
        if (rows.length == 2 || rows.length == 3) colRows[c] = rows;
      }
      final eligibleCols = colRows.keys.toList();
      if (eligibleCols.length < 3) continue;

      for (var i = 0; i < eligibleCols.length - 2; i++) {
        for (var j = i + 1; j < eligibleCols.length - 1; j++) {
          for (var k = j + 1; k < eligibleCols.length; k++) {
            final ca = eligibleCols[i];
            final cb = eligibleCols[j];
            final cc = eligibleCols[k];
            final unionRows = <int>{
              ...colRows[ca]!,
              ...colRows[cb]!,
              ...colRows[cc]!,
            };
            if (unionRows.length != 3) continue;

            final eliminations = <Elimination>[];
            for (final row in unionRows) {
              for (var c = 0; c < boardSize; c++) {
                if (c == ca || c == cb || c == cc) continue;
                final cell = board.at(row, c);
                if (cell.value == null && cell.candidates.contains(d)) {
                  eliminations.add(
                    Elimination(row: row, col: c, values: {d}),
                  );
                }
              }
            }
            if (eliminations.isEmpty) continue;

            final evidence = <Cell>[
              for (final c in [ca, cb, cc])
                for (final r in colRows[c]!) board.at(r, c),
            ];
            return _buildHint(
              digit: d,
              evidence: evidence,
              eliminations: eliminations,
              base: UnitType.col,
              baseIndices: [ca, cb, cc],
              crossIndices: unionRows.toList()..sort(),
            );
          }
        }
      }
    }
    return null;
  }

  EliminationHint _buildHint({
    required int digit,
    required List<Cell> evidence,
    required List<Elimination> eliminations,
    required UnitType base,
    required List<int> baseIndices,
    required List<int> crossIndices,
  }) {
    final baseEn = base == UnitType.row ? 'rows' : 'columns';
    final baseFa = base == UnitType.row ? 'سطرها' : 'ستون‌ها';
    final crossEn = base == UnitType.row ? 'columns' : 'rows';
    final crossFa = base == UnitType.row ? 'ستون‌ها' : 'سطرها';
    final basesStr = baseIndices.map((i) => i + 1).join(', ');
    final crossesStr = crossIndices.map((i) => i + 1).join(', ');

    return EliminationHint(
      eliminations: eliminations,
      techniqueId: id,
      techniqueNameEn: nameEn,
      techniqueNameFa: nameFa,
      difficulty: difficulty,
      summaryEn: 'Swordfish on digit $digit: $baseEn $basesStr share '
          '$crossEn $crossesStr — $digit removed from those $crossEn '
          'elsewhere.',
      summaryFa: 'سوردفیش روی عدد $digit: $baseFa $basesStr همگی در '
          '$crossFa $crossesStr قرار دارند — $digit از باقی این '
          '$crossFa حذف می‌شود.',
      explanationEn:
          'Across $baseEn $basesStr, the candidate cells for $digit all '
          'lie within three $crossEn ($crossesStr). Since each of the three '
          '$baseEn must contain $digit exactly once, and the only places '
          'available are those three $crossEn, those three $crossEn must '
          'host $digit between them — once each. So $digit cannot appear '
          'in any other row of those $crossEn, and we can remove it from '
          'the candidates of every other cell in $crossEn $crossesStr.',
      explanationFa:
          'در $baseFa $basesStr، خانه‌های نامزد عدد $digit همگی در سه '
          '$crossFa ($crossesStr) قرار گرفته‌اند. چون هر یک از این سه '
          '$baseFa باید $digit را داشته باشد و جای ممکن فقط در همین سه '
          '$crossFa است، این عدد در همان سه $crossFa توزیع می‌شود — هر '
          'یک بار. بنابراین $digit در هیچ ردیف دیگر از این $crossFa '
          'نمی‌تواند باشد و از فهرست اعداد ممکن آن خانه‌ها حذف می‌شود.',
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
        for (final i in baseIndices) UnitRef(base, i),
        for (final i in crossIndices)
          UnitRef(base == UnitType.row ? UnitType.col : UnitType.row, i),
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
