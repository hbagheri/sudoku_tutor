import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_tutor/sudoku_engine.dart';

void main() {
  group('Board.fromString', () {
    test('parses 81 chars with dots', () {
      final b = Board.fromString(
        '53..7....'
        '6..195...'
        '.98....6.'
        '8...6...3'
        '4..8.3..1'
        '7...2...6'
        '.6....28.'
        '...419..5'
        '....8..79',
      );
      expect(b.at(0, 0).value, 5);
      expect(b.at(0, 0).isGiven, isTrue);
      expect(b.at(0, 2).value, isNull);
      expect(b.isValid(), isTrue);
      expect(b.isSolved(), isFalse);
    });

    test('rejects wrong length', () {
      expect(
        () => Board.fromString('123'),
        throwsArgumentError,
      );
    });

    test('rejects invalid char', () {
      expect(
        () => Board.fromString('X' * 81),
        throwsArgumentError,
      );
    });
  });

  group('Board topology', () {
    test('box index', () {
      final b = Board.empty();
      expect(b.at(0, 0).box, 0);
      expect(b.at(2, 2).box, 0);
      expect(b.at(0, 3).box, 1);
      expect(b.at(4, 4).box, 4);
      expect(b.at(8, 8).box, 8);
    });

    test('peers count', () {
      final b = Board.empty();
      expect(b.peers(b.at(4, 4)).length, 20);
      expect(b.peers(b.at(0, 0)).length, 20);
    });

    test('row/col/box yield 9 cells', () {
      final b = Board.empty();
      expect(b.row(3).length, 9);
      expect(b.col(7).length, 9);
      expect(b.box(5).length, 9);
    });
  });

  group('Validation', () {
    test('detects row duplicate', () {
      final b = Board.empty();
      b.at(0, 0).value = 5;
      b.at(0, 8).value = 5;
      expect(b.isValid(), isFalse);
    });

    test('detects box duplicate', () {
      final b = Board.empty();
      b.at(3, 3).value = 7;
      b.at(5, 5).value = 7;
      expect(b.isValid(), isFalse);
    });

    test('empty board is valid', () {
      expect(Board.empty().isValid(), isTrue);
    });
  });

  group('Candidates', () {
    test('legalDigitsAt excludes peers values', () {
      final b = Board.empty();
      b.at(0, 0).value = 1;
      b.at(1, 1).value = 2;
      b.at(0, 4).value = 3;
      final legal = b.legalDigitsAt(0, 1);
      expect(legal.contains(1), isFalse, reason: 'in row');
      expect(legal.contains(2), isFalse, reason: 'in box');
      expect(legal.contains(3), isFalse, reason: 'in row');
      expect(legal.contains(4), isTrue);
    });

    test('recomputeAllCandidates fills empties', () {
      final b = Board.fromString(
        '53..7....'
        '6..195...'
        '.98....6.'
        '8...6...3'
        '4..8.3..1'
        '7...2...6'
        '.6....28.'
        '...419..5'
        '....8..79',
      );
      b.recomputeAllCandidates();
      expect(b.at(0, 0).candidates, isEmpty,
          reason: 'placed cell has no candidates');
      expect(b.at(0, 2).candidates, isNotEmpty);
    });
  });
}
