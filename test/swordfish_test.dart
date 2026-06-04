import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_tutor/sudoku_engine.dart';

void main() {
  group('Swordfish', () {
    test('eliminates digit from other rows when columns are locked', () {
      // For digit 7: in rows 0, 4, and 8, 7 is a candidate only in columns
      // 1, 5, and 7 (the unique triple here). Each of those rows must
      // place 7 inside one of those three columns, so in every OTHER row
      // 7 can be removed from cols 1/5/7. We seed an elimination target
      // at (3,5).
      final b = Board.empty();
      b.at(0, 1).candidates = {7, 9};
      b.at(0, 5).candidates = {7, 9};
      b.at(4, 1).candidates = {7, 9};
      b.at(4, 7).candidates = {7, 9};
      b.at(8, 5).candidates = {7, 9};
      b.at(8, 7).candidates = {7, 9};
      // Elimination target — not part of any Swordfish row.
      b.at(3, 5).candidates = {7, 2};

      final hint = Swordfish().findOne(b);
      expect(hint, isA<EliminationHint>());
      final eh = hint as EliminationHint;
      for (final e in eh.eliminations) {
        expect(e.row, isNot(0));
        expect(e.row, isNot(4));
        expect(e.row, isNot(8));
        expect({1, 5, 7}, contains(e.col));
        expect(e.values, {7});
      }
      expect(eh.eliminations, hasLength(1));
      expect(eh.eliminations.first.row, 3);
      expect(eh.eliminations.first.col, 5);
    });

    test('returns null when no triple of rows aligns to 3 columns', () {
      final b = Board.empty();
      b.at(0, 0).candidates = {5, 1};
      b.at(0, 4).candidates = {5, 1};
      expect(Swordfish().findOne(b), isNull);
    });
  });
}
