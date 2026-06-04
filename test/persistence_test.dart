import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_tutor/app/game_persistence.dart';
import 'package:sudoku_tutor/sudoku_engine.dart';

void main() {
  group('SavedGame', () {
    test('round-trips through JSON', () {
      final original = SavedGame(
        difficulty: Difficulty.medium,
        solutionCompact: '5' * 81,
        givensCompact: '1' + '0' * 80,
        valuesCompact: '17' + '0' * 79,
        candidates: [
          for (var i = 0; i < 81; i++)
            if (i == 5) [1, 2, 3] else <int>[]
        ],
        mistakes: 3,
        elapsedSeconds: 123,
        autoNotes: true,
        savedAt: DateTime.fromMillisecondsSinceEpoch(1_700_000_000_000),
      );
      final json = jsonEncode(original.toJson());
      final restored = SavedGame.fromJson(jsonDecode(json));
      expect(restored, isNotNull);
      expect(restored!.difficulty, Difficulty.medium);
      expect(restored.solutionCompact, original.solutionCompact);
      expect(restored.givensCompact, original.givensCompact);
      expect(restored.valuesCompact, original.valuesCompact);
      expect(restored.mistakes, 3);
      expect(restored.elapsedSeconds, 123);
      expect(restored.autoNotes, isTrue);
      expect(restored.candidates[5], [1, 2, 3]);
      expect(restored.candidates[0], isEmpty);
    });

    test('rejects a payload from a future version', () {
      final json = '{"v": 999, "diff": "easy"}';
      final restored = SavedGame.fromJson(jsonDecode(json));
      expect(restored, isNull);
    });

    test('returns null on malformed payload', () {
      final json = '{"v": 1, "diff": "easy"}'; // missing required fields
      final restored = SavedGame.fromJson(jsonDecode(json));
      expect(restored, isNull);
    });
  });
}
