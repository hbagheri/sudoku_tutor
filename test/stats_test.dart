import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_tutor/app/stats.dart';
import 'package:sudoku_tutor/sudoku_engine.dart';

void main() {
  group('DifficultyStats.record', () {
    test('updates count, total, best on first completion', () {
      const start = DifficultyStats();
      final next = start.record(seconds: 120, mistakes: 2);
      expect(next.completed, 1);
      expect(next.totalSeconds, 120);
      expect(next.bestSeconds, 120);
      expect(next.totalMistakes, 2);
    });

    test('best time only goes down', () {
      const a = DifficultyStats(
        completed: 1,
        bestSeconds: 100,
        totalSeconds: 100,
      );
      final b = a.record(seconds: 200, mistakes: 0);
      expect(b.bestSeconds, 100, reason: '200 > 100 should not become best');
      final c = b.record(seconds: 50, mistakes: 0);
      expect(c.bestSeconds, 50);
    });
  });

  group('GameStats roll-up', () {
    test('totals sum across difficulties', () {
      final stats = GameStats({
        Difficulty.easy: const DifficultyStats(
          completed: 2,
          totalSeconds: 100,
          totalMistakes: 1,
        ),
        Difficulty.hard: const DifficultyStats(
          completed: 1,
          totalSeconds: 300,
          totalMistakes: 5,
        ),
      });
      expect(stats.totalCompleted, 3);
      expect(stats.totalSeconds, 400);
      expect(stats.totalMistakes, 6);
    });

    test('statsFor missing difficulty returns empty', () {
      final stats = GameStats.empty();
      expect(stats.statsFor(Difficulty.easy).completed, 0);
    });
  });

  group('GameStats JSON', () {
    test('round-trips', () {
      final stats = GameStats({
        Difficulty.medium: const DifficultyStats(
          completed: 5,
          bestSeconds: 60,
          totalSeconds: 600,
          totalMistakes: 3,
        ),
      });
      final json = stats.toJson();
      final restored = GameStats.fromJson(json);
      expect(restored.statsFor(Difficulty.medium).completed, 5);
      expect(restored.statsFor(Difficulty.medium).bestSeconds, 60);
      expect(restored.statsFor(Difficulty.medium).totalSeconds, 600);
      expect(restored.statsFor(Difficulty.medium).totalMistakes, 3);
    });
  });
}
