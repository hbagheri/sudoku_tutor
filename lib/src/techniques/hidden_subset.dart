import '../board.dart';
import '../hint.dart';
import 'technique.dart';

/// Hidden Subset — generalized Hidden Pair / Triple / Quad.
///
/// If `size` digits in a unit can only appear in the same `size` cells
/// (across all unit cells), those `size` digits occupy those cells in some
/// order. Any other candidates in those cells can be eliminated.
abstract class _HiddenSubset extends Technique {
  int get size;

  EliminationHint? _scanUnit(
    List<Cell> unit,
    UnitType type,
    int index,
  ) {
    // For each digit, find which cells could hold it.
    final cellsForDigit = <int, Set<int>>{};
    for (var d = 1; d <= 9; d++) {
      cellsForDigit[d] = <int>{};
    }
    for (var i = 0; i < unit.length; i++) {
      final cell = unit[i];
      if (cell.value != null) continue;
      for (final d in cell.candidates) {
        cellsForDigit[d]!.add(i);
      }
    }
    // Remove digits already placed in the unit (no candidate cells).
    final missingDigits = <int>[];
    for (var d = 1; d <= 9; d++) {
      // d is "missing" if no cell in unit holds d as value.
      final placed = unit.any((c) => c.value == d);
      if (!placed) missingDigits.add(d);
    }

    // Try every combo of `size` digits from missing ones.
    final combo = List<int>.filled(size, 0);
    final n = missingDigits.length;
    if (n < size) return null;
    final result = _Box<EliminationHint?>(null);

    bool recurse(int start, int depth) {
      if (depth == size) {
        // Union of cells where these digits can appear.
        final digits = [for (var i = 0; i < size; i++) missingDigits[combo[i]]];
        final unionCells = <int>{};
        for (final d in digits) {
          unionCells.addAll(cellsForDigit[d]!);
        }
        if (unionCells.length != size) return false;
        if (unionCells.any((i) => cellsForDigit[digits[0]] == null)) {
          return false;
        }
        // Hidden subset found: digits {digits} live in cells {unionCells}.
        // Eliminate any *other* candidates from those cells.
        final eliminations = <Elimination>[];
        for (final i in unionCells) {
          final cell = unit[i];
          final extras = cell.candidates.difference(digits.toSet());
          if (extras.isNotEmpty) {
            eliminations.add(
              Elimination(row: cell.row, col: cell.col, values: extras),
            );
          }
        }
        if (eliminations.isEmpty) return false;

        result.value = _buildHint(
          subsetCells: [for (final i in unionCells) unit[i]],
          digits: digits.toSet(),
          eliminations: eliminations,
          unitType: type,
          unitIndex: index,
        );
        return true;
      }
      for (var i = start; i < n; i++) {
        combo[depth] = i;
        if (recurse(i + 1, depth + 1)) return true;
      }
      return false;
    }

    recurse(0, 0);
    return result.value;
  }

  EliminationHint _buildHint({
    required List<Cell> subsetCells,
    required Set<int> digits,
    required List<Elimination> eliminations,
    required UnitType unitType,
    required int unitIndex,
  }) {
    final unitEn = switch (unitType) {
      UnitType.row => 'row',
      UnitType.col => 'column',
      UnitType.box => 'box',
    };
    final unitFa = switch (unitType) {
      UnitType.row => 'سطر',
      UnitType.col => 'ستون',
      UnitType.box => 'مربع',
    };
    final digitsList = digits.toList()..sort();
    final cellsText = subsetCells
        .map((c) => '(R${c.row + 1},C${c.col + 1})')
        .join(', ');

    return EliminationHint(
      eliminations: eliminations,
      techniqueId: id,
      techniqueNameEn: nameEn,
      techniqueNameFa: nameFa,
      difficulty: difficulty,
      summaryEn: '$nameEn in $unitEn ${unitIndex + 1}: digits '
          '${digitsList.join(",")} can only live in $cellsText.',
      summaryFa: '$nameFa در $unitFa ${unitIndex + 1}: اعداد '
          '${digitsList.join("،")} فقط می‌توانند در همان خانه‌ها قرار بگیرند.',
      explanationEn:
          'In $unitEn ${unitIndex + 1}, the digits ${digitsList.join(", ")} '
          'collectively have only $size cells where they can still go. With '
          '$size digits to place in $size cells, those cells must end up '
          'holding exactly those digits. Therefore, any other candidates '
          'currently shown in those cells can be removed.',
      explanationFa:
          'در $unitFa ${unitIndex + 1}، اعداد ${digitsList.join("، ")} روی '
          'هم فقط $size خانه برای قرار گرفتن دارند. وقتی $size عدد و $size '
          'خانه داریم، این اعداد باید دقیقاً همین خانه‌ها را پر کنند. پس هر '
          'گزینه‌ی دیگری که در فهرست اعداد این خانه‌ها هست، می‌تواند حذف '
          'شود.',
      highlights: [
        for (final c in subsetCells)
          CellHighlight(
            row: c.row,
            col: c.col,
            candidates: digits,
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
      involvedUnits: [UnitRef(unitType, unitIndex)],
    );
  }

  @override
  Hint? findOne(Board board) {
    for (var i = 0; i < boardSize; i++) {
      final h = _scanUnit(board.row(i).toList(), UnitType.row, i);
      if (h != null) return h;
    }
    for (var i = 0; i < boardSize; i++) {
      final h = _scanUnit(board.col(i).toList(), UnitType.col, i);
      if (h != null) return h;
    }
    for (var i = 0; i < boardSize; i++) {
      final h = _scanUnit(board.box(i).toList(), UnitType.box, i);
      if (h != null) return h;
    }
    return null;
  }

  @override
  Iterable<Hint> findAll(Board board) sync* {
    for (var i = 0; i < boardSize; i++) {
      final h = _scanUnit(board.row(i).toList(), UnitType.row, i);
      if (h != null) yield h;
    }
    for (var i = 0; i < boardSize; i++) {
      final h = _scanUnit(board.col(i).toList(), UnitType.col, i);
      if (h != null) yield h;
    }
    for (var i = 0; i < boardSize; i++) {
      final h = _scanUnit(board.box(i).toList(), UnitType.box, i);
      if (h != null) yield h;
    }
  }
}

class _Box<T> {
  T value;
  _Box(this.value);
}

class HiddenPair extends _HiddenSubset {
  @override
  int get size => 2;
  @override
  String get id => 'hidden_pair';
  @override
  String get nameEn => 'Hidden Pair';
  @override
  String get nameFa => 'زوج پنهان';
  @override
  int get difficulty => 6;
}

class HiddenTriple extends _HiddenSubset {
  @override
  int get size => 3;
  @override
  String get id => 'hidden_triple';
  @override
  String get nameEn => 'Hidden Triple';
  @override
  String get nameFa => 'سه‌تایی پنهان';
  @override
  int get difficulty => 7;
}

class HiddenQuad extends _HiddenSubset {
  @override
  int get size => 4;
  @override
  String get id => 'hidden_quad';
  @override
  String get nameEn => 'Hidden Quad';
  @override
  String get nameFa => 'چهارتایی پنهان';
  @override
  int get difficulty => 8;
}
