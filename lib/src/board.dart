/// Core data model for a 9x9 Sudoku board.
///
/// Coordinates: row and col are 0..8. Row 0 is the top, col 0 is the left.
/// Box index `box = (row ~/ 3) * 3 + (col ~/ 3)` — 0 top-left, 8 bottom-right.
library;

/// Conventional values used across the engine.
const int boardSize = 9;
const int boxSize = 3;

/// All valid digits for a Sudoku cell.
const Set<int> allDigits = {1, 2, 3, 4, 5, 6, 7, 8, 9};

/// A single 9x9 grid cell.
class Cell {
  final int row;
  final int col;

  /// The placed digit (1..9), or null if empty.
  int? value;

  /// Pencil marks — candidate digits the user (or solver) considers possible.
  Set<int> candidates;

  /// True if this cell was part of the original puzzle (a clue).
  /// Used by the UI to render differently and to forbid editing.
  bool isGiven;

  Cell({
    required this.row,
    required this.col,
    this.value,
    Set<int>? candidates,
    this.isGiven = false,
  }) : candidates = candidates ?? <int>{};

  /// 3x3 box index, 0..8.
  int get box => (row ~/ boxSize) * boxSize + (col ~/ boxSize);

  bool get isEmpty => value == null;
  bool get isFilled => value != null;

  Cell copy() => Cell(
        row: row,
        col: col,
        value: value,
        candidates: {...candidates},
        isGiven: isGiven,
      );

  @override
  String toString() =>
      'Cell(r$row,c$col,v=${value ?? "_"},cands=$candidates)';
}

/// A full 9x9 Sudoku board.
class Board {
  /// Cells in row-major order. Always 9 rows x 9 cols.
  final List<List<Cell>> cells;

  Board._(this.cells);

  /// Builds an empty board (no values, no candidates).
  factory Board.empty() {
    final rows = List.generate(boardSize, (r) {
      return List.generate(boardSize, (c) => Cell(row: r, col: c));
    });
    return Board._(rows);
  }

  /// Builds a board from an 81-character string.
  /// '0' or '.' represent empty cells; '1'..'9' are placed values.
  /// Whitespace is ignored. All placed values become "givens".
  factory Board.fromString(String s) {
    final compact = s.replaceAll(RegExp(r'\s'), '');
    if (compact.length != 81) {
      throw ArgumentError(
        'Expected 81 characters of board data, got ${compact.length}',
      );
    }
    final board = Board.empty();
    for (var i = 0; i < 81; i++) {
      final ch = compact[i];
      final r = i ~/ boardSize;
      final c = i % boardSize;
      if (ch == '.' || ch == '0') continue;
      final digit = int.tryParse(ch);
      if (digit == null || digit < 1 || digit > 9) {
        throw ArgumentError('Invalid char "$ch" at index $i');
      }
      board.cells[r][c] = Cell(
        row: r,
        col: c,
        value: digit,
        isGiven: true,
      );
    }
    return board;
  }

  /// Deep copy of this board.
  Board copy() {
    final rows = List.generate(boardSize, (r) {
      return List.generate(boardSize, (c) => cells[r][c].copy());
    });
    return Board._(rows);
  }

  Cell at(int row, int col) => cells[row][col];

  Iterable<Cell> get allCells sync* {
    for (var r = 0; r < boardSize; r++) {
      for (var c = 0; c < boardSize; c++) {
        yield cells[r][c];
      }
    }
  }

  Iterable<Cell> row(int r) => cells[r];

  Iterable<Cell> col(int c) sync* {
    for (var r = 0; r < boardSize; r++) {
      yield cells[r][c];
    }
  }

  Iterable<Cell> box(int b) sync* {
    final br = (b ~/ boxSize) * boxSize;
    final bc = (b % boxSize) * boxSize;
    for (var r = br; r < br + boxSize; r++) {
      for (var c = bc; c < bc + boxSize; c++) {
        yield cells[r][c];
      }
    }
  }

  /// The 20 cells that share a row, column, or box with `cell` (excluding it).
  Iterable<Cell> peers(Cell cell) sync* {
    final seen = <Cell>{cell};
    for (final c in row(cell.row)) {
      if (seen.add(c)) yield c;
    }
    for (final c in col(cell.col)) {
      if (seen.add(c)) yield c;
    }
    for (final c in box(cell.box)) {
      if (seen.add(c)) yield c;
    }
  }

  /// All 27 "units" (9 rows + 9 columns + 9 boxes), each as a list of 9 cells.
  Iterable<List<Cell>> get units sync* {
    for (var i = 0; i < boardSize; i++) {
      yield row(i).toList();
    }
    for (var i = 0; i < boardSize; i++) {
      yield col(i).toList();
    }
    for (var i = 0; i < boardSize; i++) {
      yield box(i).toList();
    }
  }

  /// True if the board has no constraint violations (duplicates in any unit).
  /// An incomplete board can still be valid.
  bool isValid() {
    for (final unit in units) {
      final seen = <int>{};
      for (final cell in unit) {
        final v = cell.value;
        if (v == null) continue;
        if (!seen.add(v)) return false;
      }
    }
    return true;
  }

  bool isSolved() {
    for (final cell in allCells) {
      if (cell.value == null) return false;
    }
    return isValid();
  }

  /// Returns the values currently placed in `unit`, ignoring empty cells.
  Set<int> placedIn(Iterable<Cell> unit) {
    final s = <int>{};
    for (final c in unit) {
      final v = c.value;
      if (v != null) s.add(v);
    }
    return s;
  }

  /// Returns the digits that would not violate row/column/box constraints
  /// if placed in (row, col). Does not consult `cell.candidates`.
  Set<int> legalDigitsAt(int row, int col) {
    final cell = cells[row][col];
    if (cell.value != null) return <int>{};
    final blocked = <int>{};
    blocked.addAll(placedIn(this.row(row)));
    blocked.addAll(placedIn(this.col(col)));
    blocked.addAll(placedIn(box(cell.box)));
    return allDigits.difference(blocked);
  }

  /// Fills every empty cell's `candidates` set with all digits that are legal
  /// based on currently placed values. Existing candidates are overwritten.
  void recomputeAllCandidates() {
    for (final cell in allCells) {
      if (cell.value == null) {
        cell.candidates = legalDigitsAt(cell.row, cell.col);
      } else {
        cell.candidates.clear();
      }
    }
  }

  /// 81-char representation: digits or '0' for empty. Useful for tests and
  /// persistence.
  String toCompactString() {
    final buf = StringBuffer();
    for (final cell in allCells) {
      buf.write(cell.value ?? '0');
    }
    return buf.toString();
  }

  /// Human-readable grid with box dividers — useful in tests/debugging.
  String toPrettyString() {
    final buf = StringBuffer();
    for (var r = 0; r < boardSize; r++) {
      if (r > 0 && r % boxSize == 0) buf.writeln('------+-------+------');
      for (var c = 0; c < boardSize; c++) {
        if (c > 0 && c % boxSize == 0) buf.write(' |');
        buf.write(' ${cells[r][c].value ?? '.'}');
      }
      buf.writeln();
    }
    return buf.toString();
  }
}
