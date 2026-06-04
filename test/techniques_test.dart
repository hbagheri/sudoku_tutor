import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_tutor/sudoku_engine.dart';

void main() {
  group('NakedSingle', () {
    test('finds a cell with one candidate', () {
      final b = Board.empty();
      // Force (0,0)=1 by filling the rest of row 0 with 2..9.
      for (var c = 1; c <= 8; c++) {
        b.at(0, c).value = c + 1;
      }
      b.recomputeAllCandidates();

      final hint = NakedSingle().findOne(b);
      expect(hint, isA<PlaceHint>());
      final ph = hint as PlaceHint;
      expect(ph.row, 0);
      expect(ph.col, 0);
      expect(ph.value, 1);
    });

    test('returns null when no single is present', () {
      final b = Board.empty();
      b.recomputeAllCandidates();
      expect(NakedSingle().findOne(b), isNull);
    });
  });

  group('HiddenSingle', () {
    test('finds digit with one home in a row', () {
      // Row 0 missing only 1 — also a naked single, but HiddenSingle should
      // still detect it on its row scan.
      final b = Board.empty();
      for (var c = 1; c <= 8; c++) {
        b.at(0, c).value = c + 1;
      }
      b.recomputeAllCandidates();

      final hint = HiddenSingle().findOne(b);
      expect(hint, isA<PlaceHint>());
      final ph = hint as PlaceHint;
      expect(ph.value, 1);
      expect(ph.row, 0);
      expect(ph.col, 0);
    });

    test('finds hidden single inside a box', () {
      // Set up so 5 can only land in (0,0) of box 0. Block (0,1), (0,2) via
      // distant column 5s; block (1,*) and (2,*) of box 0 via row 5s — taking
      // care to keep all placements in distinct rows, columns, and boxes.
      final b = Board.empty();
      b.at(1, 3).value = 5; // row 1, col 3, box 1
      b.at(2, 7).value = 5; // row 2, col 7, box 2
      b.at(5, 1).value = 5; // row 5, col 1, box 3
      b.at(6, 2).value = 5; // row 6, col 2, box 6
      expect(b.isValid(), isTrue, reason: 'test setup must be valid');
      b.recomputeAllCandidates();

      // Sanity: in box 0, only (0,0) carries 5.
      final fives = b
          .box(0)
          .where((c) => c.value == null && c.candidates.contains(5))
          .toList();
      expect(fives.length, 1);
      expect(fives.first.row, 0);
      expect(fives.first.col, 0);

      final hint = HiddenSingle().findOne(b);
      expect(hint, isA<PlaceHint>());
      final ph = hint as PlaceHint;
      expect(ph.value, 5);
      expect(ph.row, 0);
      expect(ph.col, 0);
    });
  });

  group('Pointing', () {
    test('eliminates from rest of row when box-candidates align', () {
      // Fill rows 1 and 2 of box 0 with values 1..6 — then 7, 8, 9 can only
      // appear in row 0 of box 0, but those digits are still candidates in
      // row 0 outside box 0 (the rest of the board is empty).
      final b = Board.empty();
      b.at(1, 0).value = 1;
      b.at(1, 1).value = 2;
      b.at(1, 2).value = 3;
      b.at(2, 0).value = 4;
      b.at(2, 1).value = 5;
      b.at(2, 2).value = 6;
      expect(b.isValid(), isTrue);
      b.recomputeAllCandidates();

      // Sanity: in box 0, digit 7's candidates all live in row 0.
      final sevens = b
          .box(0)
          .where((c) => c.value == null && c.candidates.contains(7))
          .toList();
      expect(sevens.length, 3);
      expect(sevens.every((c) => c.row == 0), isTrue);

      final hint = Pointing().findOne(b);
      expect(hint, isA<EliminationHint>());
      final eh = hint as EliminationHint;
      // Every elimination should be in row 0 outside box 0.
      for (final e in eh.eliminations) {
        expect(e.row, 0);
        expect(e.col, greaterThanOrEqualTo(3));
      }
      expect(eh.eliminations, isNotEmpty);
    });
  });

  group('BoxLine', () {
    test('eliminates from rest of box when row-candidates align', () {
      // Fill row 0 cols 3..8 with values 1..6 — then digits 7, 8, 9 can only
      // be placed inside box 0 within row 0, so they should be removed from
      // the other cells of box 0 (rows 1 and 2 of cols 0..2).
      final b = Board.empty();
      b.at(0, 3).value = 1;
      b.at(0, 4).value = 2;
      b.at(0, 5).value = 3;
      b.at(0, 6).value = 4;
      b.at(0, 7).value = 5;
      b.at(0, 8).value = 6;
      expect(b.isValid(), isTrue);
      b.recomputeAllCandidates();

      // Sanity: in row 0, digit 7's candidates all live in box 0.
      final sevens = b
          .row(0)
          .where((c) => c.value == null && c.candidates.contains(7))
          .toList();
      expect(sevens.length, 3);
      expect(sevens.every((c) => c.box == 0), isTrue);

      final hint = BoxLine().findOne(b);
      expect(hint, isA<EliminationHint>());
      final eh = hint as EliminationHint;
      for (final e in eh.eliminations) {
        expect(b.at(e.row, e.col).box, 0);
        expect(e.row, isNot(0));
      }
      expect(eh.eliminations, isNotEmpty);
    });
  });
}
