import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../sudoku_engine.dart';

/// Per-difficulty aggregate stats: completion count, best time, total time,
/// and total mistakes across all sessions.
class DifficultyStats {
  final int completed;
  final int bestSeconds; // 0 if no completion yet
  final int totalSeconds;
  final int totalMistakes;

  const DifficultyStats({
    this.completed = 0,
    this.bestSeconds = 0,
    this.totalSeconds = 0,
    this.totalMistakes = 0,
  });

  DifficultyStats record({required int seconds, required int mistakes}) {
    final newCount = completed + 1;
    final newBest = (bestSeconds == 0 || seconds < bestSeconds)
        ? seconds
        : bestSeconds;
    return DifficultyStats(
      completed: newCount,
      bestSeconds: newBest,
      totalSeconds: totalSeconds + seconds,
      totalMistakes: totalMistakes + mistakes,
    );
  }

  Map<String, dynamic> toJson() => {
        'completed': completed,
        'best': bestSeconds,
        'total': totalSeconds,
        'mistakes': totalMistakes,
      };

  factory DifficultyStats.fromJson(Map<String, dynamic> j) => DifficultyStats(
        completed: (j['completed'] as num?)?.toInt() ?? 0,
        bestSeconds: (j['best'] as num?)?.toInt() ?? 0,
        totalSeconds: (j['total'] as num?)?.toInt() ?? 0,
        totalMistakes: (j['mistakes'] as num?)?.toInt() ?? 0,
      );
}

/// All-time stats, keyed by difficulty.
class GameStats {
  final Map<Difficulty, DifficultyStats> byDifficulty;

  const GameStats(this.byDifficulty);

  DifficultyStats statsFor(Difficulty d) =>
      byDifficulty[d] ?? const DifficultyStats();

  int get totalCompleted =>
      byDifficulty.values.fold(0, (sum, s) => sum + s.completed);

  int get totalSeconds =>
      byDifficulty.values.fold(0, (sum, s) => sum + s.totalSeconds);

  int get totalMistakes =>
      byDifficulty.values.fold(0, (sum, s) => sum + s.totalMistakes);

  Map<String, dynamic> toJson() => {
        for (final entry in byDifficulty.entries)
          entry.key.name: entry.value.toJson(),
      };

  factory GameStats.fromJson(Map<String, dynamic> j) {
    final map = <Difficulty, DifficultyStats>{};
    for (final d in Difficulty.values) {
      final entry = j[d.name];
      if (entry is Map<String, dynamic>) {
        map[d] = DifficultyStats.fromJson(entry);
      }
    }
    return GameStats(map);
  }

  factory GameStats.empty() => const GameStats({});
}

/// Reads and writes the all-time `GameStats` to `shared_preferences`.
class StatsRepository {
  static const _kStats = 'gameStats';

  Future<GameStats> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kStats);
    if (raw == null) return GameStats.empty();
    try {
      return GameStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return GameStats.empty();
    }
  }

  /// Append the result of a solved puzzle to the persisted stats.
  Future<GameStats> recordCompletion({
    required Difficulty difficulty,
    required int seconds,
    required int mistakes,
  }) async {
    final stats = await load();
    final updatedEntry = stats
        .statsFor(difficulty)
        .record(seconds: seconds, mistakes: mistakes);
    final next = Map<Difficulty, DifficultyStats>.from(stats.byDifficulty);
    next[difficulty] = updatedEntry;
    final updated = GameStats(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kStats, jsonEncode(updated.toJson()));
    return updated;
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kStats);
  }
}
