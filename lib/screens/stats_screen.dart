import 'package:flutter/material.dart';

import '../app/stats.dart';
import '../app/strings.dart';
import '../sudoku_engine.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _repo = StatsRepository();
  GameStats? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _repo.load();
    if (!mounted) return;
    setState(() => _stats = s);
  }

  Future<void> _reset() async {
    final s = context.strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(s.statsResetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s.yes),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _repo.reset();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final theme = Theme.of(context);
    final stats = _stats;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.stats),
        actions: [
          if (stats != null && stats.totalCompleted > 0)
            IconButton(
              tooltip: s.statsReset,
              onPressed: _reset,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: stats == null
          ? const Center(child: CircularProgressIndicator())
          : stats.totalCompleted == 0
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      s.statsEmpty,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _OverallCard(stats: stats),
                    const SizedBox(height: 16),
                    for (final d in Difficulty.values)
                      if (stats.statsFor(d).completed > 0) ...[
                        _DifficultyCard(
                          difficulty: d,
                          stats: stats.statsFor(d),
                        ),
                        const SizedBox(height: 8),
                      ],
                  ],
                ),
    );
  }
}

class _OverallCard extends StatelessWidget {
  final GameStats stats;
  const _OverallCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatRow(
              label: s.statsCompleted,
              value: '${stats.totalCompleted}',
              onContainer: true,
            ),
            const SizedBox(height: 6),
            _StatRow(
              label: s.statsTotalTime,
              value: _fmtSecondsLong(stats.totalSeconds),
              onContainer: true,
            ),
            const SizedBox(height: 6),
            _StatRow(
              label: s.statsTotalMistakes,
              value: '${stats.totalMistakes}',
              onContainer: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final Difficulty difficulty;
  final DifficultyStats stats;
  const _DifficultyCard({required this.difficulty, required this.stats});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final theme = Theme.of(context);
    final label = switch (difficulty.name) {
      'easy' => s.easy,
      'medium' => s.medium,
      'hard' => s.hard,
      'expert' => s.expert,
      'master' => s.master,
      'legendary' => s.legendary,
      _ => difficulty.name,
    };
    final avg = stats.completed > 0
        ? stats.totalSeconds ~/ stats.completed
        : 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            _StatRow(label: s.statsCompleted, value: '${stats.completed}'),
            const SizedBox(height: 4),
            _StatRow(
              label: s.statsBestTime,
              value: _fmtSecondsShort(stats.bestSeconds),
            ),
            const SizedBox(height: 4),
            _StatRow(
              label: s.statsAvgTime,
              value: _fmtSecondsShort(avg),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool onContainer;
  const _StatRow({
    required this.label,
    required this.value,
    this.onContainer = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = onContainer
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: color)),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

String _fmtSecondsShort(int seconds) {
  if (seconds <= 0) return '—';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

String _fmtSecondsLong(int seconds) {
  if (seconds <= 0) return '—';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  if (h > 0) return '${h}h ${m}m ${s}s';
  return '${m}m ${s}s';
}
