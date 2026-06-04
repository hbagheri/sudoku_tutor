import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_tutor/sudoku_engine.dart';

void main() {
  group('Solver', () {
    test('solves an easy puzzle with basic techniques', () {
      // A canonical easy puzzle that should be fully solvable using only
      // naked + hidden singles.
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
      final result = Solver().solve(b);
      expect(result.solved, isTrue, reason: result.toString());
      expect(b.isSolved(), isTrue);
      expect(b.isValid(), isTrue);
    });

    test('nextHint returns a hint when one is available', () {
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
      final h = Solver().nextHint(b);
      expect(h, isNotNull);
    });

    test('countSolutions returns 1 for a uniquely-solvable puzzle', () {
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
      expect(countSolutions(b, limit: 2), 1);
    });

    test('countSolutions detects ambiguity', () {
      // Nearly-empty board has many solutions.
      final b = Board.empty();
      expect(countSolutions(b, limit: 2), 2);
    });
  });
}
