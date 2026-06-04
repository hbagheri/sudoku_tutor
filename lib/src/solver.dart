import 'board.dart';
import 'hint.dart';
import 'techniques/box_line.dart';
import 'techniques/hidden_single.dart';
import 'techniques/hidden_subset.dart';
import 'techniques/naked_single.dart';
import 'techniques/naked_subset.dart';
import 'techniques/pointing.dart';
import 'techniques/technique.dart';
import 'techniques/swordfish.dart';
import 'techniques/unique_rectangle.dart';
import 'techniques/x_wing.dart';
import 'techniques/y_wing.dart';

/// Coordinates a list of techniques, ordered by difficulty, to solve or
/// hint a board.
class Solver {
  /// Techniques in ascending difficulty order. The solver tries the easiest
  /// first, so the user is taught the simplest applicable trick at each step.
  final List<Technique> techniques;

  Solver({List<Technique>? techniques})
      : techniques = techniques ??
            [
              NakedSingle(),
              HiddenSingle(),
              Pointing(),
              BoxLine(),
              NakedPair(),
              HiddenPair(),
              NakedTriple(),
              HiddenTriple(),
              XWing(),
              NakedQuad(),
              HiddenQuad(),
              YWing(),
              Swordfish(),
              UniqueRectangle(),
            ];

  /// Return EVERY hint that any of the configured techniques can produce
  /// on the *current* board state. Useful for building tutorial galleries
  /// or "show me all available moves" UIs.
  ///
  /// Does not mutate the board (techniques run independently on the same
  /// candidate state). The implicit step-0 candidate fill applies here as
  /// well — if the board has no pencil-marks at all yet, they are filled
  /// before the scan so the techniques have something to work with.
  List<Hint> findAllHints(Board board) {
    var anyCandidates = false;
    for (final cell in board.allCells) {
      if (cell.value == null && cell.candidates.isNotEmpty) {
        anyCandidates = true;
        break;
      }
    }
    if (!anyCandidates) {
      board.recomputeAllCandidates();
    }
    final hints = <Hint>[];
    for (final t in techniques) {
      hints.addAll(t.findAll(board));
    }
    return hints;
  }

  /// Returns the easiest hint available, or null if no technique applies.
  ///
  /// By default, the board's existing candidate state is respected — so
  /// candidate eliminations performed by previous techniques are not undone
  /// between consecutive hint requests. As an implicit "step 0", if every
  /// empty cell has no candidates at all (e.g. a fresh game where the user
  /// has not pressed "auto-fill notes"), candidates are filled in once so
  /// the techniques have something to work with.
  ///
  /// Pass `recomputeCandidates: true` to force a full recompute, e.g. after
  /// manual edits that may have left candidates in an inconsistent state.
  Hint? nextHint(Board board, {bool recomputeCandidates = false}) {
    if (recomputeCandidates) {
      board.recomputeAllCandidates();
    } else {
      var anyCandidates = false;
      for (final cell in board.allCells) {
        if (cell.value == null && cell.candidates.isNotEmpty) {
          anyCandidates = true;
          break;
        }
      }
      if (!anyCandidates) {
        board.recomputeAllCandidates();
      }
    }
    for (final t in techniques) {
      final h = t.findOne(board);
      if (h != null) return h;
    }
    return null;
  }

  /// Try to solve the board using only the configured techniques (no
  /// brute force). Mutates the board. Returns the result.
  SolveResult solve(Board board) {
    board.recomputeAllCandidates();
    final stepsByTechnique = <String, int>{};
    var maxDifficulty = 0;
    var steps = 0;

    while (!board.isSolved()) {
      Hint? hint;
      for (final t in techniques) {
        hint = t.findOne(board);
        if (hint != null) break;
      }
      if (hint == null) {
        return SolveResult(
          solved: false,
          steps: steps,
          stepsByTechnique: stepsByTechnique,
          maxDifficulty: maxDifficulty,
        );
      }
      applyHint(board, hint);
      steps++;
      stepsByTechnique.update(
        hint.techniqueId,
        (v) => v + 1,
        ifAbsent: () => 1,
      );
      if (hint.difficulty > maxDifficulty) maxDifficulty = hint.difficulty;
    }
    return SolveResult(
      solved: true,
      steps: steps,
      stepsByTechnique: stepsByTechnique,
      maxDifficulty: maxDifficulty,
    );
  }
}

class SolveResult {
  final bool solved;
  final int steps;
  final Map<String, int> stepsByTechnique;

  /// Highest difficulty of any technique used during the solve.
  /// Useful as a "puzzle rating".
  final int maxDifficulty;

  const SolveResult({
    required this.solved,
    required this.steps,
    required this.stepsByTechnique,
    required this.maxDifficulty,
  });

  @override
  String toString() => 'SolveResult(solved=$solved, steps=$steps, '
      'maxDifficulty=$maxDifficulty, by=$stepsByTechnique)';
}

/// Brute-force backtracking solver. Used internally by the puzzle generator
/// to verify uniqueness; not surfaced to the user as a "technique".
///
/// Returns the number of solutions found, capped at [limit]. The first
/// solution (if any) is written into [solutionOut].
int countSolutions(Board board, {int limit = 2, Board? solutionOut}) {
  final work = board.copy();
  var count = 0;
  bool recurse() {
    Cell? target;
    for (final c in work.allCells) {
      if (c.value == null) {
        target = c;
        break;
      }
    }
    if (target == null) {
      count++;
      if (count == 1 && solutionOut != null) {
        for (var r = 0; r < boardSize; r++) {
          for (var c = 0; c < boardSize; c++) {
            solutionOut.cells[r][c].value = work.cells[r][c].value;
          }
        }
      }
      return count >= limit;
    }
    final legal = work.legalDigitsAt(target.row, target.col);
    for (final d in legal) {
      target.value = d;
      if (recurse()) return true;
    }
    target.value = null;
    return false;
  }

  recurse();
  return count;
}
