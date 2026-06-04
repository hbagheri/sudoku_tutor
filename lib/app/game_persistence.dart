import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../sudoku_engine.dart';

/// Versioned, serializable snapshot of an in-progress game. Saved between
/// app launches so the player can pick up where they left off.
class SavedGame {
  static const int currentVersion = 1;

  final Difficulty difficulty;
  final String solutionCompact; // 81-char board (all digits)
  final String givensCompact;   // 81-char board ('0' for non-given cells)
  final String valuesCompact;   // 81-char board (current placed values)
  final List<List<int>> candidates; // 81 entries, each a sorted digit list
  final int mistakes;
  final int elapsedSeconds;
  final bool autoNotes;
  final DateTime savedAt;

  const SavedGame({
    required this.difficulty,
    required this.solutionCompact,
    required this.givensCompact,
    required this.valuesCompact,
    required this.candidates,
    required this.mistakes,
    required this.elapsedSeconds,
    required this.autoNotes,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'v': currentVersion,
        'diff': difficulty.name,
        'solution': solutionCompact,
        'givens': givensCompact,
        'values': valuesCompact,
        'cands': candidates,
        'mistakes': mistakes,
        'elapsedSec': elapsedSeconds,
        'autoNotes': autoNotes,
        'savedAt': savedAt.millisecondsSinceEpoch,
      };

  static SavedGame? fromJson(Map<String, dynamic> json) {
    final v = json['v'];
    if (v != currentVersion) return null;
    try {
      final diff = Difficulty.values.firstWhere(
        (d) => d.name == json['diff'],
        orElse: () => Difficulty.medium,
      );
      final rawCands = json['cands'] as List;
      final cands = [
        for (final entry in rawCands)
          [for (final n in (entry as List)) (n as num).toInt()],
      ];
      return SavedGame(
        difficulty: diff,
        solutionCompact: json['solution'] as String,
        givensCompact: json['givens'] as String,
        valuesCompact: json['values'] as String,
        candidates: cands,
        mistakes: (json['mistakes'] as num).toInt(),
        elapsedSeconds: (json['elapsedSec'] as num).toInt(),
        autoNotes: json['autoNotes'] as bool? ?? false,
        savedAt: DateTime.fromMillisecondsSinceEpoch(
          (json['savedAt'] as num).toInt(),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Loads, saves, and clears the single "current game" slot in
/// `shared_preferences`. There is one slot — starting a new game overwrites
/// the previous one, and solving a puzzle clears it.
class GamePersistence {
  static const _kCurrentGame = 'currentGame';

  Future<void> save(SavedGame game) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrentGame, jsonEncode(game.toJson()));
  }

  Future<SavedGame?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCurrentGame);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return SavedGame.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<bool> has() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_kCurrentGame);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCurrentGame);
  }
}
