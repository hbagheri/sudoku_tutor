import '../board.dart';
import '../hint.dart';
import 'technique.dart';

/// Unique Rectangle (Type 1).
///
/// Sudoku puzzles by definition have a single solution. A "deadly pattern"
/// — four cells forming a rectangle, all with the same two candidates
/// {A, B}, sitting in just two 3×3 boxes — would allow two solutions
/// (swap A and B at the four corners). Therefore the pattern cannot exist
/// in a real puzzle.
///
/// Type 1: three of the rectangle's corners are bivalue {A, B}, the fourth
/// cell has {A, B} plus at least one extra digit. The extra digit must be
/// the answer at that corner — otherwise the deadly pattern would form.
/// So A and B can be removed from the candidate set of that fourth cell.
class UniqueRectangle extends Technique {
  @override
  String get id => 'unique_rectangle';
  @override
  String get nameEn => 'Unique Rectangle';
  @override
  String get nameFa => 'مستطیل یکتا';
  @override
  int get difficulty => 12;

  @override
  Hint? findOne(Board board) {
    // Indices of every bivalue cell grouped by their {A, B} pair.
    final byPair = <String, List<Cell>>{};
    for (final cell in board.allCells) {
      if (cell.value != null) continue;
      if (cell.candidates.length != 2) continue;
      final sorted = cell.candidates.toList()..sort();
      byPair.putIfAbsent(sorted.join(','), () => []).add(cell);
    }

    for (final entry in byPair.entries) {
      final cells = entry.value;
      if (cells.length < 3) continue;
      final ab = entry.key.split(',').map(int.parse).toList();
      final a = ab[0];
      final b = ab[1];

      // Pick any 3 bivalue cells that form three corners of a rectangle and
      // whose missing 4th corner contains {a, b} plus extras.
      for (var i = 0; i < cells.length; i++) {
        for (var j = i + 1; j < cells.length; j++) {
          for (var k = j + 1; k < cells.length; k++) {
            final result = _checkTriple(board, cells[i], cells[j], cells[k],
                a: a, b: b);
            if (result != null) return result;
          }
        }
      }
    }
    return null;
  }

  /// Given three bivalue cells with candidates {a, b}, see if they form
  /// three corners of a row/col-aligned rectangle whose 4th cell carries
  /// {a, b} as a strict subset of its candidates and lies in one of two
  /// boxes shared with the trio.
  EliminationHint? _checkTriple(
    Board board,
    Cell p,
    Cell q,
    Cell r, {
    required int a,
    required int b,
  }) {
    // Try every ordering and compute the missing 4th corner from any two
    // diagonal corners. Simplest: collect rows and columns among the three,
    // figure out the rectangle if exactly 2 unique rows and 2 unique cols.
    final rows = {p.row, q.row, r.row};
    final cols = {p.col, q.col, r.col};
    if (rows.length != 2 || cols.length != 2) return null;

    // The 4th corner is the (row, col) pair not used by any of the trio.
    final rowList = rows.toList();
    final colList = cols.toList();
    final usedCorners = <String>{
      '${p.row},${p.col}',
      '${q.row},${q.col}',
      '${r.row},${r.col}',
    };
    int? r4;
    int? c4;
    for (final rr in rowList) {
      for (final cc in colList) {
        if (!usedCorners.contains('$rr,$cc')) {
          r4 = rr;
          c4 = cc;
        }
      }
    }
    if (r4 == null || c4 == null) return null;

    final fourth = board.at(r4, c4);
    if (fourth.value != null) return null;
    // The 4th cell must contain {a, b} and at least one extra candidate.
    if (!fourth.candidates.contains(a) || !fourth.candidates.contains(b)) {
      return null;
    }
    if (fourth.candidates.length < 3) return null;

    // The four corners must occupy exactly two boxes.
    final boxes = <int>{
      p.box,
      q.box,
      r.box,
      fourth.box,
    };
    if (boxes.length != 2) return null;

    final extras = fourth.candidates.difference({a, b});

    return EliminationHint(
      eliminations: [
        Elimination(row: r4, col: c4, values: {a, b}),
      ],
      techniqueId: id,
      techniqueNameEn: nameEn,
      techniqueNameFa: nameFa,
      difficulty: difficulty,
      summaryEn: 'Unique Rectangle on {$a,$b} at (R${p.row + 1}C${p.col + 1}, '
          'R${q.row + 1}C${q.col + 1}, R${r.row + 1}C${r.col + 1}, '
          'R${r4 + 1}C${c4 + 1}) — strip {$a,$b} from the corner with extras.',
      summaryFa: 'مستطیل یکتا روی {$a،$b}: $a و $b از خانه‌ی چهارم با '
          'گزینه‌های اضافی (${extras.toList()..sort()}) حذف می‌شوند.',
      explanationEn:
          'These four cells form a rectangle inside two 3×3 boxes. Three '
          'of them already only contain {$a, $b}. If the fourth corner '
          'also resolved to $a or $b, the four corners would carry exactly '
          '{$a, $b} — and we could swap $a/$b across the rectangle to get '
          'a second valid solution. Real puzzles have a unique solution, '
          'so the fourth corner must take one of its other candidates. '
          'We can erase $a and $b from its pencil-marks.',
      explanationFa:
          'این چهار خانه یک مستطیل تشکیل می‌دهند که در دو مربع ۳×۳ قرار '
          'دارد. سه تا از آن‌ها فقط {$a، $b} را دارند. اگر گوشه‌ی چهارم '
          'هم $a یا $b شود، چهار گوشه ترکیب {$a، $b} می‌گیرند و می‌توان '
          '$a و $b را در همان مستطیل جابه‌جا کرد — یعنی دو جواب معتبر! '
          'چون پازل سودوکو فقط یک جواب دارد، خانه‌ی چهارم باید یکی از '
          'گزینه‌های دیگرش را بگیرد و $a و $b از آن حذف می‌شوند.',
      highlights: [
        CellHighlight(
          row: p.row,
          col: p.col,
          candidates: {a, b},
          role: HighlightRole.evidence,
        ),
        CellHighlight(
          row: q.row,
          col: q.col,
          candidates: {a, b},
          role: HighlightRole.evidence,
        ),
        CellHighlight(
          row: r.row,
          col: r.col,
          candidates: {a, b},
          role: HighlightRole.evidence,
        ),
        CellHighlight(
          row: r4,
          col: c4,
          candidates: {a, b},
          role: HighlightRole.eliminated,
        ),
      ],
    );
  }

  @override
  Iterable<Hint> findAll(Board board) sync* {
    final h = findOne(board);
    if (h != null) yield h;
  }
}
