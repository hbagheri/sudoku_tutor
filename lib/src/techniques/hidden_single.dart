import '../board.dart';
import '../hint.dart';
import 'technique.dart';

/// Hidden Single: within a unit (row, column, or box), a digit can legally
/// go in only one cell. That cell must contain the digit even if other
/// candidates remain in its pencil-marks.
class HiddenSingle extends Technique {
  @override
  String get id => 'hidden_single';
  @override
  String get nameEn => 'Hidden Single';
  @override
  String get nameFa => 'تک‌پنهان';
  @override
  int get difficulty => 2;

  PlaceHint _build({
    required Cell cell,
    required int value,
    required UnitType unitType,
    required int unitIndex,
  }) {
    final unitNameEn = switch (unitType) {
      UnitType.row => 'row',
      UnitType.col => 'column',
      UnitType.box => 'box',
    };
    final unitNameFa = switch (unitType) {
      UnitType.row => 'سطر',
      UnitType.col => 'ستون',
      UnitType.box => 'مربع',
    };
    return PlaceHint(
      row: cell.row,
      col: cell.col,
      value: value,
      techniqueId: id,
      techniqueNameEn: nameEn,
      techniqueNameFa: nameFa,
      difficulty: difficulty,
      summaryEn: 'Digit $value can only go in (R${cell.row + 1},'
          'C${cell.col + 1}) within $unitNameEn ${unitIndex + 1}.',
      summaryFa: 'عدد $value در $unitNameFa ${unitIndex + 1} فقط می‌تواند '
          'در خانه‌ی (س${cell.row + 1},ت${cell.col + 1}) قرار بگیرد.',
      explanationEn:
          'A Hidden Single appears when, looking at a whole $unitNameEn, '
          'a particular digit ($value) has just one cell where it is '
          'still a legal candidate. The cell may also carry other '
          'candidates, but those can be ignored: this is the only place '
          'in the $unitNameEn that $value can go, so it must be placed here.',
      explanationFa:
          'تک‌پنهان وقتی پیش می‌آید که با نگاه به کل $unitNameFa، یک عدد '
          'معین ($value) فقط در یک خانه به عنوان گزینه‌ی مجاز باقی مانده. '
          'ممکن است این خانه چند عدد دیگر هم در فهرست اعدادش داشته باشد، '
          'اما اهمیت ندارد: چون $value فقط همین یک جا را در $unitNameFa دارد، '
          'باید همین‌جا قرار بگیرد.',
      highlights: [
        CellHighlight(
          row: cell.row,
          col: cell.col,
          candidates: {value},
          role: HighlightRole.target,
        ),
      ],
      involvedUnits: [UnitRef(unitType, unitIndex)],
    );
  }

  /// Scan one unit looking for digits with exactly one legal cell.
  Iterable<Hint> _scanUnit(
    List<Cell> unit,
    UnitType type,
    int index,
  ) sync* {
    for (var digit = 1; digit <= 9; digit++) {
      Cell? found;
      var count = 0;
      var alreadyPlaced = false;
      for (final cell in unit) {
        if (cell.value == digit) {
          alreadyPlaced = true;
          break;
        }
        if (cell.value == null && cell.candidates.contains(digit)) {
          found = cell;
          count++;
          if (count > 1) break;
        }
      }
      if (alreadyPlaced) continue;
      if (count == 1 && found != null) {
        // Skip if this is also a naked single — caller can decide priority,
        // but we still report it as Hidden Single when the unit is the
        // distinguishing reason.
        yield _build(
          cell: found,
          value: digit,
          unitType: type,
          unitIndex: index,
        );
      }
    }
  }

  @override
  Hint? findOne(Board board) {
    for (var i = 0; i < boardSize; i++) {
      final rowHints = _scanUnit(board.row(i).toList(), UnitType.row, i);
      for (final h in rowHints) {
        return h;
      }
    }
    for (var i = 0; i < boardSize; i++) {
      final colHints = _scanUnit(board.col(i).toList(), UnitType.col, i);
      for (final h in colHints) {
        return h;
      }
    }
    for (var i = 0; i < boardSize; i++) {
      final boxHints = _scanUnit(board.box(i).toList(), UnitType.box, i);
      for (final h in boxHints) {
        return h;
      }
    }
    return null;
  }

  @override
  Iterable<Hint> findAll(Board board) sync* {
    for (var i = 0; i < boardSize; i++) {
      yield* _scanUnit(board.row(i).toList(), UnitType.row, i);
    }
    for (var i = 0; i < boardSize; i++) {
      yield* _scanUnit(board.col(i).toList(), UnitType.col, i);
    }
    for (var i = 0; i < boardSize; i++) {
      yield* _scanUnit(board.box(i).toList(), UnitType.box, i);
    }
  }
}
