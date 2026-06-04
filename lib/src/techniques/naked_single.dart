import '../board.dart';
import '../hint.dart';
import 'technique.dart';

/// Naked Single: a cell that has exactly one candidate digit must contain
/// that digit. The simplest technique.
class NakedSingle extends Technique {
  @override
  String get id => 'naked_single';
  @override
  String get nameEn => 'Naked Single';
  @override
  String get nameFa => 'تک‌تنها';
  @override
  int get difficulty => 1;

  PlaceHint _build(Cell cell, int value) {
    return PlaceHint(
      row: cell.row,
      col: cell.col,
      value: value,
      techniqueId: id,
      techniqueNameEn: nameEn,
      techniqueNameFa: nameFa,
      difficulty: difficulty,
      summaryEn: 'Cell (R${cell.row + 1},C${cell.col + 1}) has only one '
          'possible digit: $value.',
      summaryFa:
          'خانه (س${cell.row + 1},ت${cell.col + 1}) فقط یک عدد ممکن دارد: $value.',
      explanationEn:
          'A Naked Single is a cell whose pencil-marks have been reduced '
          'to a single digit. Because every empty cell must hold one of '
          'the digits 1–9, and all other digits already appear in this '
          'cell\'s row, column, or box, only $value can go here.',
      explanationFa:
          'تک‌تنها به خانه‌ای می‌گویند که فهرست اعداد ممکنش به یک عدد رسیده. '
          'چون هر خانه‌ی خالی باید یکی از اعداد ۱ تا ۹ را داشته باشد و بقیه‌ی '
          'اعداد قبلاً در سطر، ستون یا مربع‌ این خانه وجود دارند، فقط $value '
          'می‌تواند اینجا قرار بگیرد.',
      highlights: [
        CellHighlight(
          row: cell.row,
          col: cell.col,
          candidates: {value},
          role: HighlightRole.target,
        ),
      ],
    );
  }

  @override
  Hint? findOne(Board board) {
    for (final cell in board.allCells) {
      if (cell.value == null && cell.candidates.length == 1) {
        return _build(cell, cell.candidates.first);
      }
    }
    return null;
  }

  @override
  Iterable<Hint> findAll(Board board) sync* {
    for (final cell in board.allCells) {
      if (cell.value == null && cell.candidates.length == 1) {
        yield _build(cell, cell.candidates.first);
      }
    }
  }
}
