import 'package:flutter/material.dart';

import '../app/game_controller.dart';
import '../app/settings.dart';
import '../app/stats.dart';
import '../app/strings.dart';
import '../widgets/number_pad.dart';
import '../widgets/sudoku_board_view.dart';
import '../widgets/technique_bar.dart';

class GameScreen extends StatefulWidget {
  final GameController controller;
  final AppSettings settings;
  const GameScreen({
    required this.controller,
    required this.settings,
    super.key,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _solvedDialogShown = false;
  final _statsRepo = StatsRepository();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (!_solvedDialogShown && widget.controller.isSolved) {
      _solvedDialogShown = true;
      // Defer to the next frame so we don't try to show a dialog while
      // mid-build.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _statsRepo.recordCompletion(
          difficulty: widget.controller.difficulty,
          seconds: widget.controller.elapsed.inSeconds,
          mistakes: widget.controller.mistakes,
        );
        if (!mounted) return;
        _showSolvedDialog();
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    widget.controller.dispose();
    super.dispose();
  }

  void _showSolvedDialog() {
    final s = context.strings;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        final c = widget.controller;
        return AlertDialog(
          icon: Icon(Icons.emoji_events,
              size: 56, color: theme.colorScheme.primary),
          title: Text(s.congrats, textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.solvedMessage, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              _ResultRow(label: s.difficulty, value: _difficultyLabel(s, c)),
              _ResultRow(label: s.timer, value: _fmtDuration(c.elapsed)),
              _ResultRow(label: s.mistakes, value: '${c.mistakes}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                Navigator.of(context).pop();
              },
              child: Text(s.backToMenu),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                _restartSameDifficulty();
              },
              child: Text(s.playAgain),
            ),
          ],
        );
      },
    );
  }

  void _restartSameDifficulty() {
    // Pop the existing game screen and push a fresh one with the same
    // difficulty. The home screen briefly shows, but never gets focus.
    final diff = widget.controller.difficulty;
    final autoNotes = widget.controller.autoNotes;
    final persistence = widget.controller.persistence;
    final fresh = GameController.newGame(
      diff,
      autoNotes: autoNotes,
      persistence: persistence,
    );
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => GameScreen(
        controller: fresh,
        settings: widget.settings,
      ),
    ));
  }

  String _difficultyLabel(Strings s, GameController c) {
    return switch (c.difficulty.name) {
      'easy' => s.easy,
      'medium' => s.medium,
      'hard' => s.hard,
      'expert' => s.expert,
      'master' => s.master,
      'legendary' => s.legendary,
      'custom' => s.custom,
      _ => c.difficulty.name,
    };
  }

  String _fmtDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.appTitle),
        actions: [
          AnimatedBuilder(
            animation: widget.controller,
            builder: (context, _) {
              final on = widget.controller.autoNotes;
              return IconButton(
                tooltip: s.showNotes,
                onPressed: () async {
                  widget.controller.setAutoNotes(!on);
                  await widget.settings.setAutoNotes(!on);
                },
                icon: Icon(
                  on ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                ),
              );
            },
          ),
          IconButton(
            tooltip: s.hint,
            onPressed: () {
              final found = widget.controller.requestHint();
              if (!found) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.noHintsLeft)),
                );
              }
            },
            icon: const Icon(Icons.lightbulb_outline),
          ),
          IconButton(
            tooltip: s.nextStep,
            onPressed: () {
              if (!widget.controller.takeOneStep()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.noHintsLeft)),
                );
              }
            },
            icon: const Icon(Icons.skip_next),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            return Column(
              children: [
                _StatsBar(controller: widget.controller),
                TechniqueBar(controller: widget.controller),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: SudokuBoardView(controller: widget.controller),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: NumberPad(controller: widget.controller),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  final GameController controller;
  const _StatsBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: theme.colorScheme.surfaceContainerLow,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _Stat(label: s.difficulty, value: _difficultyLabel(s, controller)),
          _Stat(label: s.mistakes, value: '${controller.mistakes}'),
          _Stat(label: s.timer, value: _fmtDuration(controller.elapsed)),
        ],
      ),
    );
  }

  String _difficultyLabel(Strings s, GameController c) {
    return switch (c.difficulty.name) {
      'easy' => s.easy,
      'medium' => s.medium,
      'hard' => s.hard,
      'expert' => s.expert,
      'master' => s.master,
      'legendary' => s.legendary,
      'custom' => s.custom,
      _ => c.difficulty.name,
    };
  }

  String _fmtDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        Text(value, style: theme.textTheme.titleMedium),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
