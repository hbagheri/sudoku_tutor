import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_tutor/sudoku_engine.dart';

void main() {
  group('PuzzleGenerator', () {
    test('produces a valid, solved board internally', () {
      final gen = PuzzleGenerator(random: Random(42));
      final puzzle = gen.generate(Difficulty.easy);
      expect(puzzle.solution.isSolved(), isTrue);
      expect(puzzle.solution.isValid(), isTrue);
    });

    test('initial board is valid and incomplete', () {
      final gen = PuzzleGenerator(random: Random(42));
      final puzzle = gen.generate(Difficulty.easy);
      expect(puzzle.initial.isValid(), isTrue);
      expect(puzzle.initial.isSolved(), isFalse);
    });

    test('puzzle has a unique solution', () {
      final gen = PuzzleGenerator(random: Random(42));
      final puzzle = gen.generate(Difficulty.easy);
      expect(countSolutions(puzzle.initial, limit: 2), 1);
    });

    test('puzzle solution matches generator solution', () {
      final gen = PuzzleGenerator(random: Random(42));
      final puzzle = gen.generate(Difficulty.easy);
      final work = puzzle.initial.copy();
      final result = Solver().solve(work);
      expect(result.solved, isTrue);
      expect(work.toCompactString(), puzzle.solution.toCompactString());
    });

    test('easy puzzle requires only naked singles', () {
      final gen = PuzzleGenerator(random: Random(42));
      final puzzle = gen.generate(Difficulty.easy);
      expect(puzzle.maxDifficultyUsed, lessThanOrEqualTo(1));
    });

    test('medium puzzle uses at most hidden singles', () {
      final gen = PuzzleGenerator(random: Random(7));
      final puzzle = gen.generate(Difficulty.medium);
      expect(puzzle.maxDifficultyUsed, lessThanOrEqualTo(2));
    });

    test('hard puzzle uses at most box-line', () {
      final gen = PuzzleGenerator(random: Random(13));
      final puzzle = gen.generate(Difficulty.hard);
      expect(puzzle.maxDifficultyUsed, lessThanOrEqualTo(4));
    });

    test('non-empty givens are marked as given', () {
      final gen = PuzzleGenerator(random: Random(42));
      final puzzle = gen.generate(Difficulty.easy);
      for (final cell in puzzle.initial.allCells) {
        if (cell.value != null) {
          expect(cell.isGiven, isTrue);
        } else {
          expect(cell.isGiven, isFalse);
        }
      }
    });
  });
}
