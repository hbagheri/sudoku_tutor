import 'dart:async';

import 'package:flutter/material.dart';

import '../app/game_controller.dart';
import '../app/game_persistence.dart';
import '../app/settings.dart';
import '../app/strings.dart';
import '../sudoku_engine.dart';
import 'game_screen.dart';

/// Lets the user type a Sudoku puzzle digit-by-digit. On a valid, uniquely
/// solvable board the "Start playing" action becomes available and hands
/// the puzzle off to a normal [GameScreen].
class CustomPuzzleScreen extends StatefulWidget {
  final AppSettings settings;

  /// Optional 81-cell digit array (0 = empty). Used to seed the grid from
  /// OCR. The user can still edit before tapping "Start playing".
  final List<int>? initialValues;

  const CustomPuzzleScreen({
    required this.settings,
    this.initialValues,
    super.key,
  });

  @override
  State<CustomPuzzleScreen> createState() => _CustomPuzzleScreenState();
}

class _CustomPuzzleScreenState extends State<CustomPuzzleScreen> {
  late Board _board;
  int? _selRow;
  int? _selCol;

  _Validation _status = _Validation.empty();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _board = Board.empty();
    final seed = widget.initialValues;
    if (seed != null && seed.length == 81) {
      for (var i = 0; i < 81; i++) {
        if (seed[i] != 0) {
          _board.at(i ~/ 9, i % 9).value = seed[i];
        }
      }
      _scheduleValidate();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _select(int r, int c) {
    setState(() {
      _selRow = r;
      _selCol = c;
    });
  }

  void _setDigit(int d) {
    final r = _selRow;
    final c = _selCol;
    if (r == null || c == null) return;
    setState(() {
      _board.at(r, c).value = d;
    });
    _scheduleValidate();
  }

  void _erase() {
    final r = _selRow;
    final c = _selCol;
    if (r == null || c == null) return;
    setState(() {
      _board.at(r, c).value = null;
    });
    _scheduleValidate();
  }

  void _clearAll() {
    setState(() {
      _board = Board.empty();
      _selRow = null;
      _selCol = null;
      _status = _Validation.empty();
    });
  }

  void _scheduleValidate() {
    _debounce?.cancel();
    setState(() => _status = _Validation.checking());
    _debounce = Timer(const Duration(milliseconds: 250), _validate);
  }

  void _validate() {
    final clues = _countClues();
    if (clues == 0) {
      setState(() => _status = _Validation.empty());
      return;
    }
    if (!_board.isValid()) {
      setState(() => _status = _Validation.invalid());
      return;
    }
    // Heavy: count solutions (up to 2). For sparse boards this can take a
    // moment, but it's run on the UI thread with a 250ms debounce so it
    // stays interactive.
    final solution = Board.empty();
    final count = countSolutions(_board, limit: 2, solutionOut: solution);
    setState(() {
      if (count == 0) {
        _status = _Validation.noSolution();
      } else if (count > 1) {
        _status = _Validation.multipleSolutions();
      } else {
        _status = _Validation.valid(solution: solution, clueCount: clues);
      }
    });
  }

  int _countClues() {
    var n = 0;
    for (final cell in _board.allCells) {
      if (cell.value != null) n++;
    }
    return n;
  }

  void _startPlaying() {
    final solution = _status.solution;
    if (solution == null) return;
    // Build a puzzle: mark every placed cell as a given, candidates start
    // empty (the GameController fills them if autoNotes is on).
    final initial = _board.copy();
    for (final cell in initial.allCells) {
      cell.isGiven = cell.value != null;
      cell.candidates.clear();
    }
    final puzzle = Puzzle(
      initial: initial,
      solution: solution,
      difficulty: Difficulty.custom,
      maxDifficultyUsed: 0,
    );
    final controller = GameController.fromPuzzle(
      puzzle,
      autoNotes: widget.settings.autoNotes,
      persistence: GamePersistence(),
    );
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => GameScreen(
        controller: controller,
        settings: widget.settings,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.enterCustomPuzzle),
        actions: [
          IconButton(
            tooltip: s.clearAll,
            onPressed: _clearAll,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    s.customPuzzleIntro,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _Grid(
                        board: _board,
                        selRow: _selRow,
                        selCol: _selCol,
                        onTap: _select,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _StatusBar(status: _status),
                  const SizedBox(height: 8),
                  _Pad(
                    onDigit: _setDigit,
                    onErase: _erase,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: _status.canStart ? _startPlaying : null,
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(s.startPlaying),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  final Board board;
  final int? selRow;
  final int? selCol;
  final void Function(int r, int c) onTap;
  const _Grid({
    required this.board,
    required this.selRow,
    required this.selCol,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration:
          BoxDecoration(border: Border.all(color: scheme.outline, width: 2)),
      child: Column(
        children: [
          for (var br = 0; br < 3; br++)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: br < 2
                        ? BorderSide(color: scheme.outline, width: 2)
                        : BorderSide.none,
                  ),
                ),
                child: Column(
                  children: [
                    for (var ro = 0; ro < 3; ro++)
                      Expanded(
                        child: Row(
                          children: [
                            for (var bc = 0; bc < 3; bc++)
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: bc < 2
                                          ? BorderSide(
                                              color: scheme.outline, width: 2)
                                          : BorderSide.none,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      for (var co = 0; co < 3; co++)
                                        Expanded(
                                          child: _Cell(
                                            row: br * 3 + ro,
                                            col: bc * 3 + co,
                                            value: board
                                                .at(br * 3 + ro, bc * 3 + co)
                                                .value,
                                            isSelected: br * 3 + ro == selRow &&
                                                bc * 3 + co == selCol,
                                            onTap: () => onTap(
                                              br * 3 + ro,
                                              bc * 3 + co,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final int row;
  final int col;
  final int? value;
  final bool isSelected;
  final VoidCallback onTap;
  const _Cell({
    required this.row,
    required this.col,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? scheme.secondaryContainer : scheme.surface,
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        child: Center(
          child: value == null
              ? const SizedBox.shrink()
              : Text(
                  '$value',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
        ),
      ),
    );
  }
}

class _Pad extends StatelessWidget {
  final void Function(int) onDigit;
  final VoidCallback onErase;
  const _Pad({required this.onDigit, required this.onErase});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        for (var d = 1; d <= 9; d++)
          SizedBox(
            width: 44,
            height: 48,
            child: FilledButton.tonal(
              style: FilledButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () => onDigit(d),
              child: Text(
                '$d',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
        SizedBox(
          width: 52,
          height: 48,
          child: IconButton.filledTonal(
            onPressed: onErase,
            icon: const Icon(Icons.backspace_outlined),
          ),
        ),
      ],
    );
  }
}

class _StatusBar extends StatelessWidget {
  final _Validation status;
  const _StatusBar({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final theme = Theme.of(context);
    final (text, color, icon) = switch (status.state) {
      _ValState.empty => (s.statusEmpty, theme.colorScheme.onSurfaceVariant,
          Icons.info_outline),
      _ValState.checking => (s.checking, theme.colorScheme.onSurfaceVariant,
          Icons.hourglass_top_outlined),
      _ValState.invalid => (s.statusInvalid, theme.colorScheme.error,
          Icons.error_outline),
      _ValState.noSolution => (s.statusNoSolution, theme.colorScheme.error,
          Icons.error_outline),
      _ValState.multipleSolutions => (
          s.statusMultipleSolutions,
          theme.colorScheme.tertiary,
          Icons.warning_amber_outlined,
        ),
      _ValState.valid => (
          '${s.statusValid} · ${status.clueCount} ${s.clues}',
          theme.colorScheme.primary,
          Icons.check_circle_outline,
        ),
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

enum _ValState {
  empty,
  checking,
  invalid,
  noSolution,
  multipleSolutions,
  valid,
}

class _Validation {
  final _ValState state;
  final Board? solution;
  final int clueCount;

  const _Validation._(this.state, this.solution, this.clueCount);
  factory _Validation.empty() => const _Validation._(_ValState.empty, null, 0);
  factory _Validation.checking() =>
      const _Validation._(_ValState.checking, null, 0);
  factory _Validation.invalid() =>
      const _Validation._(_ValState.invalid, null, 0);
  factory _Validation.noSolution() =>
      const _Validation._(_ValState.noSolution, null, 0);
  factory _Validation.multipleSolutions() =>
      const _Validation._(_ValState.multipleSolutions, null, 0);
  factory _Validation.valid({
    required Board solution,
    required int clueCount,
  }) =>
      _Validation._(_ValState.valid, solution, clueCount);

  bool get canStart => state == _ValState.valid && solution != null;
}
