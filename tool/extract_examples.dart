// Walk through Legendary-difficulty puzzles, finding the first naturally
// occurring board state for each technique. Prints Dart source that can
// be pasted into lib/data/tutorial_examples.dart as the worked examples.
//
// Run:  dart run tool/extract_examples.dart

import 'dart:math';

import 'package:sudoku_tutor/sudoku_engine.dart';

void main(List<String> args) {
  final captured = <String, _Captured>{};
  // Try several seeds — one puzzle rarely exercises every advanced
  // technique on its own.
  for (final seed in [1, 7, 13, 42, 99, 100, 314, 271]) {
    if (captured.length >= 14) break;
    print('--- seed $seed ---');
    final gen = PuzzleGenerator(random: Random(seed));
    final puzzle = gen.generate(Difficulty.legendary);
    final board = puzzle.initial.copy();
    final solver = Solver();
    var step = 0;
    while (!board.isSolved() && step < 200) {
      final hints = solver.findAllHints(board);
      if (hints.isEmpty) {
        print('  stuck at step $step');
        break;
      }
      for (final h in hints) {
        if (!captured.containsKey(h.techniqueId)) {
          captured[h.techniqueId] = _Captured(
            seed: seed,
            step: step,
            board: board.copy(),
            hint: h,
          );
          print(
            '  step $step  +  ${h.techniqueNameEn} (${h.techniqueId})',
          );
        }
      }
      applyHint(board, hints.first);
      step++;
    }
  }

  print('\n==== captured ${captured.length} of 14 techniques ====');
  for (final entry in captured.entries) {
    final c = entry.value;
    print(' ${entry.key}  '
        '(seed=${c.seed} step=${c.step}, ${c.hint.techniqueNameEn})');
  }
  print('\n==== missing ====');
  final missingIds = <String>{
    'naked_single',
    'hidden_single',
    'pointing',
    'box_line',
    'naked_pair',
    'naked_triple',
    'naked_quad',
    'hidden_pair',
    'hidden_triple',
    'hidden_quad',
    'x_wing',
    'y_wing',
    'swordfish',
    'unique_rectangle',
  }..removeAll(captured.keys);
  for (final id in missingIds) {
    print('  $id');
  }

  print('\n==== Dart source for tutorial_examples.dart ====');
  for (final entry in captured.entries) {
    final c = entry.value;
    print(_emitEntry(entry.key, c));
  }
}

String _emitEntry(String id, _Captured c) {
  final board = c.board;
  final values = StringBuffer();
  for (final cell in board.allCells) {
    values.write(cell.value ?? 0);
  }
  // Candidates per cell.
  final cands = <String>[];
  for (final cell in board.allCells) {
    final sorted = cell.candidates.toList()..sort();
    cands.add('[${sorted.join(",")}]');
  }
  return '''
  // ---- $id (seed=${c.seed}, step=${c.step}) ----
  {
    final b = _restore(
      "${values.toString()}",
      [${cands.join(",")}],
    );
    final t = _techniqueById('$id');
    if (t != null) {
      final h = t.findOne(b);
      if (h != null) list.add(TechniqueExample(technique: t, board: b, hint: h));
    }
  }
''';
}

class _Captured {
  final int seed;
  final int step;
  final Board board;
  final Hint hint;
  const _Captured({
    required this.seed,
    required this.step,
    required this.board,
    required this.hint,
  });
}
