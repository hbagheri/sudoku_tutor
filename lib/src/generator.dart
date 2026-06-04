import 'dart:math';

import 'board.dart';
import 'solver.dart';

/// User-facing difficulty levels. Each maps to:
///   • a maximum technique difficulty the puzzle requires, and
///   • a target range for the number of remaining clues.
///
/// The generator stops removing clues once *either* bound is hit.
enum Difficulty {
  easy,
  medium,
  hard,
  expert,
  master,
  legendary,
}

class DifficultySpec {
  final int maxTechniqueDifficulty;
  final int minClues;
  final int targetMaxClues;
  const DifficultySpec({
    required this.maxTechniqueDifficulty,
    required this.minClues,
    required this.targetMaxClues,
  });
}

const Map<Difficulty, DifficultySpec> kDifficultySpecs = {
  Difficulty.easy: DifficultySpec(
    maxTechniqueDifficulty: 1, // Naked Single only.
    minClues: 38,
    targetMaxClues: 50,
  ),
  Difficulty.medium: DifficultySpec(
    maxTechniqueDifficulty: 2, // + Hidden Single.
    minClues: 32,
    targetMaxClues: 38,
  ),
  Difficulty.hard: DifficultySpec(
    maxTechniqueDifficulty: 4, // + Pointing, Box-Line.
    minClues: 28,
    targetMaxClues: 32,
  ),
  Difficulty.expert: DifficultySpec(
    maxTechniqueDifficulty: 6, // + Naked/Hidden Pair.
    minClues: 25,
    targetMaxClues: 28,
  ),
  Difficulty.master: DifficultySpec(
    maxTechniqueDifficulty: 8, // + Triples / Quads.
    minClues: 23,
    targetMaxClues: 26,
  ),
  Difficulty.legendary: DifficultySpec(
    maxTechniqueDifficulty: 9, // + X-Wing.
    minClues: 22,
    targetMaxClues: 25,
  ),
};

/// A puzzle ready to be played, plus its unique solution.
class Puzzle {
  /// The board the user starts with — only givens are placed.
  final Board initial;

  /// The completed, fully-solved board for this puzzle.
  final Board solution;

  /// The difficulty bucket the puzzle was generated for.
  final Difficulty difficulty;

  /// The highest technique difficulty actually used to solve it.
  final int maxDifficultyUsed;

  const Puzzle({
    required this.initial,
    required this.solution,
    required this.difficulty,
    required this.maxDifficultyUsed,
  });

  int get clueCount {
    var n = 0;
    for (final c in initial.allCells) {
      if (c.value != null) n++;
    }
    return n;
  }
}

/// Builds randomised, uniquely-solvable Sudoku puzzles.
///
/// The generator works in two passes:
///   1. Build a complete, valid, randomly-shuffled solved board.
///   2. Carve out cells one at a time, keeping the puzzle uniquely solvable
///      and within the technique budget for the requested difficulty.
class PuzzleGenerator {
  final Random _random;

  PuzzleGenerator({Random? random}) : _random = random ?? Random();

  Puzzle generate(Difficulty difficulty) {
    final spec = kDifficultySpecs[difficulty]!;
    final solution = _generateSolved();
    final puzzle = solution.copy();
    // Mark every clue as given (we'll un-give as we erase).
    for (final cell in puzzle.allCells) {
      cell.isGiven = true;
    }

    // Try cells in random order. Use a "rollback" approach: if removing a
    // cell breaks uniqueness or pushes difficulty above target, put it back.
    final positions = [
      for (var r = 0; r < boardSize; r++)
        for (var c = 0; c < boardSize; c++) [r, c]
    ]..shuffle(_random);

    var maxDiffUsed = 0;
    for (final pos in positions) {
      final cell = puzzle.at(pos[0], pos[1]);
      if (cell.value == null) continue;

      final saved = cell.value;
      cell.value = null;
      cell.isGiven = false;

      // Uniqueness check first — it's cheap-ish.
      if (countSolutions(puzzle, limit: 2) != 1) {
        cell.value = saved;
        cell.isGiven = true;
        continue;
      }

      // Difficulty check.
      final probe = puzzle.copy();
      final result = Solver().solve(probe);
      if (!result.solved ||
          result.maxDifficulty > spec.maxTechniqueDifficulty) {
        cell.value = saved;
        cell.isGiven = true;
        continue;
      }
      maxDiffUsed = result.maxDifficulty;

      // Stop if we've hit the lower clue threshold.
      if (_clues(puzzle) <= spec.minClues) break;
    }

    return Puzzle(
      initial: puzzle,
      solution: solution,
      difficulty: difficulty,
      maxDifficultyUsed: maxDiffUsed,
    );
  }

  int _clues(Board b) {
    var n = 0;
    for (final c in b.allCells) {
      if (c.value != null) n++;
    }
    return n;
  }

  /// Build a complete valid solved board.
  Board _generateSolved() {
    final b = Board.empty();
    // Pre-fill the three diagonal boxes — they are mutually independent
    // (share no row or column), so a random permutation each gives a fast
    // valid head start.
    for (final boxIndex in [0, 4, 8]) {
      final digits = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle(_random);
      final cells = b.box(boxIndex).toList();
      for (var i = 0; i < 9; i++) {
        cells[i].value = digits[i];
      }
    }
    // Backtrack-fill the rest with randomised digit ordering for variety.
    if (!_backtrackFill(b)) {
      throw StateError('Failed to generate a solved board');
    }
    return b;
  }

  bool _backtrackFill(Board b) {
    for (var r = 0; r < boardSize; r++) {
      for (var c = 0; c < boardSize; c++) {
        if (b.at(r, c).value != null) continue;
        final digits = b.legalDigitsAt(r, c).toList()..shuffle(_random);
        for (final d in digits) {
          b.at(r, c).value = d;
          if (_backtrackFill(b)) return true;
          b.at(r, c).value = null;
        }
        return false;
      }
    }
    return true;
  }
}
