import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_tutor/sudoku_engine.dart';

void main() {
  group('YWing', () {
    test('eliminates C from a cell that sees both wings', () {
      // Pivot at (0,0) with candidates {1,2}. Wings at (0,3) shares 1 with
      // the pivot and carries {1,3}, and at (3,0) shares 2 with the pivot
      // and carries {2,3}. The only cell that sees BOTH wings (apart from
      // the pivot itself) is (3,3) — it must lose 3 from its candidates.
      //
      // We set candidate sets directly to keep the test minimal — the
      // technique works off whatever pencil-marks the board carries.
      final b = Board.empty();
      b.at(0, 0).candidates = {1, 2};
      b.at(0, 3).candidates = {1, 3};
      b.at(3, 0).candidates = {2, 3};
      b.at(3, 3).candidates = {3, 4, 5};

      final hint = YWing().findOne(b);
      expect(hint, isA<EliminationHint>());
      final eh = hint as EliminationHint;
      expect(eh.eliminations, hasLength(1));
      expect(eh.eliminations.first.row, 3);
      expect(eh.eliminations.first.col, 3);
      expect(eh.eliminations.first.values, {3});
    });

    test('returns null when no Y-Wing pattern is present', () {
      final b = Board.empty();
      // A single bivalue cell with no matching wings.
      b.at(0, 0).candidates = {1, 2};
      expect(YWing().findOne(b), isNull);
    });
  });
}
