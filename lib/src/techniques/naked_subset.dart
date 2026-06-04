import '../board.dart';
import '../hint.dart';
import 'technique.dart';

/// Naked Subset — generalized Naked Pair / Triple / Quad.
///
/// If `size` cells in a unit (row/col/box) collectively contain exactly
/// `size` distinct candidate digits, those digits must occupy precisely
/// those cells. Any other cell in the unit can have those digits removed
/// from its candidates.
abstract class _NakedSubset extends Technique {
  int get size;

  EliminationHint? _scanUnit(
    List<Cell> unit,
    UnitType type,
    int index,
  ) {
    final empties = unit.where((c) => c.value == null).toList();
    if (empties.length <= size) return null;

    // Generate all combinations of `size` empty cells.
    final hint = _findInCombos(empties, type, index);
    return hint;
  }

  EliminationHint? _findInCombos(
    List<Cell> empties,
    UnitType type,
    int index,
  ) {
    final n = empties.length;
    final combo = List<int>.filled(size, 0);
    final result = _Box<EliminationHint?>(null);

    bool recurse(int start, int depth) {
      if (depth == size) {
        final cells = [for (var i = 0; i < size; i++) empties[combo[i]]];
        final union = <int>{};
        for (final c in cells) {
          union.addAll(c.candidates);
        }
        if (union.length != size) return false;

        // Found a naked subset. Try to eliminate `union` from peers in unit.
        final eliminations = <Elimination>[];
        for (final cell in empties) {
          if (cells.contains(cell)) continue;
          final overlap = cell.candidates.intersection(union);
          if (overlap.isNotEmpty) {
            eliminations.add(Elimination(
              row: cell.row,
              col: cell.col,
              values: overlap,
            ));
          }
        }
        if (eliminations.isEmpty) return false;

        result.value = _buildHint(
          subsetCells: cells,
          digits: union,
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
    final cellsText = subsetCells
        .map((c) => '(R${c.row + 1},C${c.col + 1})')
        .join(', ');
    final digitsText = digits.toList()
      ..sort();

    return EliminationHint(
      eliminations: eliminations,
      techniqueId: id,
      techniqueNameEn: nameEn,
      techniqueNameFa: nameFa,
      difficulty: difficulty,
      summaryEn: '$nameEn in $unitEn ${unitIndex + 1}: '
          'cells $cellsText share exactly digits ${digitsText.join(",")}.',
      summaryFa: '$nameFa در $unitFa ${unitIndex + 1}: '
          'خانه‌های مذکور دقیقاً اعداد ${digitsText.join("،")} را به اشتراک '
          'گذاشته‌اند.',
      explanationEn:
          'Across $unitEn ${unitIndex + 1}, $size cells together hold only '
          '$size distinct candidate digits (${digitsText.join(", ")}). '
          'Because each of those digits has to be placed in the $unitEn, '
          'and there are exactly as many digits as cells available to host '
          'them, the digits must occupy those cells in some order. No other '
          'cell in the $unitEn can take any of those digits.',
      explanationFa:
          'در $unitFa ${unitIndex + 1}، $size خانه روی هم فقط $size عدد '
          'مختلف (${digitsText.join("، ")}) را به عنوان گزینه دارند. چون این '
          'اعداد همگی باید در $unitFa قرار بگیرند و دقیقاً به همان تعداد خانه '
          'برایشان جای ممکن داریم، این اعداد به ترتیبی در همین خانه‌ها قرار '
          'می‌گیرند. پس هیچ خانه‌ی دیگری از $unitFa نمی‌تواند این اعداد را '
          'داشته باشد.',
      highlights: [
        for (final c in subsetCells)
          CellHighlight(
            row: c.row,
            col: c.col,
            candidates: c.candidates,
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

/// Tiny mutable container — Dart doesn't have ref parameters.
class _Box<T> {
  T value;
  _Box(this.value);
}

class NakedPair extends _NakedSubset {
  @override
  int get size => 2;
  @override
  String get id => 'naked_pair';
  @override
  String get nameEn => 'Naked Pair';
  @override
  String get nameFa => 'زوج برهنه';
  @override
  int get difficulty => 5;
}

class NakedTriple extends _NakedSubset {
  @override
  int get size => 3;
  @override
  String get id => 'naked_triple';
  @override
  String get nameEn => 'Naked Triple';
  @override
  String get nameFa => 'سه‌تایی برهنه';
  @override
  int get difficulty => 6;
}

class NakedQuad extends _NakedSubset {
  @override
  int get size => 4;
  @override
  String get id => 'naked_quad';
  @override
  String get nameEn => 'Naked Quad';
  @override
  String get nameFa => 'چهارتایی برهنه';
  @override
  int get difficulty => 7;
}
