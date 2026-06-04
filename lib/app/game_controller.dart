import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../sudoku_engine.dart';

/// Central state for the currently-active game. Holds the board, the
/// selected cell, undo history, the solver's current "teaching" hint, and
/// the timer.
class GameController extends ChangeNotifier {
  late Board _board;
  Board get board => _board;

  late Board _solution;
  Board get solution => _solution;

  late Difficulty _difficulty;
  Difficulty get difficulty => _difficulty;

  int? _selectedRow;
  int? _selectedCol;
  int? get selectedRow => _selectedRow;
  int? get selectedCol => _selectedCol;
  Cell? get selectedCell => _selectedRow == null || _selectedCol == null
      ? null
      : _board.at(_selectedRow!, _selectedCol!);

  bool _pencilMode = false;
  bool get pencilMode => _pencilMode;

  int _mistakes = 0;
  int get mistakes => _mistakes;

  Hint? _activeHint;
  Hint? get activeHint => _activeHint;

  Duration _elapsed = Duration.zero;
  Duration get elapsed => _elapsed;
  Timer? _timer;

  final List<_Snapshot> _undoStack = [];

  final Solver _solver = Solver();

  /// When true, peers' candidate sets are kept in sync after every placement,
  /// and the board starts with all legal candidates filled in. When false,
  /// the user manages pencil marks entirely on their own.
  bool autoNotes;

  GameController.fromPuzzle(Puzzle puzzle, {this.autoNotes = true}) {
    _board = puzzle.initial.copy();
    _solution = puzzle.solution.copy();
    _difficulty = puzzle.difficulty;
    if (autoNotes) {
      _board.recomputeAllCandidates();
    }
    _startTimer();
  }

  /// Synchronous helper that creates a brand new game.
  factory GameController.newGame(
    Difficulty difficulty, {
    Random? random,
    bool autoNotes = true,
  }) {
    final puzzle = PuzzleGenerator(random: random).generate(difficulty);
    return GameController.fromPuzzle(puzzle, autoNotes: autoNotes);
  }

  /// Flip the auto-notes flag. When turning on, also recompute candidates so
  /// the user immediately sees them. When turning off, leave existing pencil
  /// marks alone — they are now the user's to manage.
  void setAutoNotes(bool v) {
    if (autoNotes == v) return;
    autoNotes = v;
    if (v) _board.recomputeAllCandidates();
    notifyListeners();
  }

  // ------ Selection ------

  void selectCell(int row, int col) {
    _selectedRow = row;
    _selectedCol = col;
    notifyListeners();
  }

  void togglePencilMode() {
    _pencilMode = !_pencilMode;
    notifyListeners();
  }

  // ------ Input ------

  /// Place [digit] in the selected cell. If [pencilMode], toggle it as a
  /// pencil mark instead. Givens cannot be changed.
  void enterDigit(int digit) {
    final cell = selectedCell;
    if (cell == null || cell.isGiven) return;

    _pushSnapshot();

    if (_pencilMode) {
      if (cell.value != null) return;
      if (cell.candidates.contains(digit)) {
        cell.candidates.remove(digit);
      } else {
        cell.candidates.add(digit);
      }
    } else {
      // Placing a real value.
      final expected = _solution.at(cell.row, cell.col).value;
      if (expected != null && digit != expected) {
        _mistakes++;
      }
      cell.value = digit;
      cell.candidates.clear();
      if (autoNotes) {
        _propagatePeerCandidates(cell, digit);
      }
    }
    _activeHint = null;
    notifyListeners();
  }

  /// Clear the value or all pencil marks of the selected cell (if not a given).
  void eraseSelected() {
    final cell = selectedCell;
    if (cell == null || cell.isGiven) return;
    _pushSnapshot();
    cell.value = null;
    cell.candidates.clear();
    _activeHint = null;
    notifyListeners();
  }

  /// Fill every empty cell's candidate set with its legal digits.
  void autofillNotes() {
    _pushSnapshot();
    _board.recomputeAllCandidates();
    notifyListeners();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    final snap = _undoStack.removeLast();
    snap.applyTo(_board);
    _activeHint = null;
    notifyListeners();
  }

  // ------ Teaching ------

  /// Find the next solver step but do not apply it. Sets [activeHint] so
  /// the UI can highlight the cells involved.
  bool requestHint() {
    _activeHint = _solver.nextHint(_board);
    notifyListeners();
    return _activeHint != null;
  }

  /// Apply [activeHint] to the board (place a value or eliminate candidates),
  /// then clear the hint.
  void applyActiveHint() {
    final hint = _activeHint;
    if (hint == null) return;
    _pushSnapshot();
    applyHint(_board, hint);
    _activeHint = null;
    notifyListeners();
  }

  /// One-shot: find the next hint and apply it immediately. Returns true if a
  /// step was made.
  bool takeOneStep() {
    final hint = _solver.nextHint(_board);
    if (hint == null) return false;
    _pushSnapshot();
    applyHint(_board, hint);
    _activeHint = hint;
    notifyListeners();
    return true;
  }

  // ------ Lifecycle ------

  bool get isSolved => _board.isSolved();

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isSolved) {
        _timer?.cancel();
        return;
      }
      _elapsed += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ------ Internal ------

  void _propagatePeerCandidates(Cell cell, int digit) {
    for (final peer in _board.peers(cell)) {
      peer.candidates.remove(digit);
    }
  }

  void _pushSnapshot() {
    if (_undoStack.length > 100) {
      _undoStack.removeAt(0);
    }
    _undoStack.add(_Snapshot.of(_board));
  }
}

/// A lightweight snapshot of the editable parts of the board for undo.
class _Snapshot {
  final List<int?> values;
  final List<Set<int>> candidates;

  _Snapshot(this.values, this.candidates);

  factory _Snapshot.of(Board b) {
    return _Snapshot(
      [for (final c in b.allCells) c.value],
      [for (final c in b.allCells) {...c.candidates}],
    );
  }

  void applyTo(Board b) {
    var i = 0;
    for (final c in b.allCells) {
      c.value = values[i];
      c.candidates = {...candidates[i]};
      i++;
    }
  }
}
