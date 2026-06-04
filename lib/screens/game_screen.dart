import 'package:flutter/material.dart';

import '../app/game_controller.dart';
import '../app/settings.dart';
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
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
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
