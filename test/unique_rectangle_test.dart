import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_tutor/sudoku_engine.dart';

void main() {
  group('UniqueRectangle Type 1', () {
    test('strips {A,B} from the corner that has extras', () {
      // Rectangle corners at (0,0), (0,3), (1,0), (1,3) — rows 0..1 share
      // band 0, cols 0 and 3 cross stacks 0 and 1, so the four corners
      // occupy exactly two boxes (0 and 1). Three corners are {1,2}; the
      // fourth ((1,3)) carries {1,2,7}. UR-1 forces (1,3) to be 7 and
      // strips 1 and 2 from its candidates.
      final b = Board.empty();
      b.at(0, 0).candidates = {1, 2};
      b.at(0, 3).candidates = {1, 2};
      b.at(1, 0).candidates = {1, 2};
      b.at(1, 3).candidates = {1, 2, 7};

      final hint = UniqueRectangle().findOne(b);
      expect(hint, isA<EliminationHint>());
      final eh = hint as EliminationHint;
      expect(eh.eliminations, hasLength(1));
      final e = eh.eliminations.first;
      expect(e.row, 1);
      expect(e.col, 3);
      expect(e.values, {1, 2});
    });

    test('does not fire when corners span four boxes', () {
      // Corners at (0,0), (0,5), (4,0), (4,5) — rows in different bands
      // and cols in different stacks → four distinct boxes. UR cannot
      // apply: the deadly pattern would be in 4 different boxes, but the
      // ambiguity argument only works when the rectangle is in 2 boxes.
      final b = Board.empty();
      b.at(0, 0).candidates = {1, 2};
      b.at(0, 5).candidates = {1, 2};
      b.at(4, 0).candidates = {1, 2};
      b.at(4, 5).candidates = {1, 2, 7};
      expect(UniqueRectangle().findOne(b), isNull);
    });

    test('does not fire when fourth corner is also bivalue', () {
      final b = Board.empty();
      b.at(0, 0).candidates = {1, 2};
      b.at(0, 3).candidates = {1, 2};
      b.at(1, 0).candidates = {1, 2};
      b.at(1, 3).candidates = {1, 2};
      expect(UniqueRectangle().findOne(b), isNull,
          reason: 'a true deadly pattern is not a valid puzzle state');
    });
  });
}
