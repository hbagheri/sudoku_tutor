import '../board.dart';
import '../hint.dart';
import 'technique.dart';

/// Y-Wing (a.k.a. XY-Wing).
///
/// Pick a "pivot" cell with exactly two candidates {A, B}. Find two "wing"
/// cells, each also bivalue, such that:
///   • wing₁ is a peer of the pivot and has candidates {A, C},
///   • wing₂ is a peer of the pivot and has candidates {B, C},
///   • the third digit C is the same in both wings.
///
/// Then exactly one of the wings ends up holding C: if the pivot resolves
/// to A, wing₂ must be C; if it resolves to B, wing₁ must be C. So *any*
/// cell that is a common peer of both wings (and is not the pivot or a
/// wing) cannot also hold C — we can eliminate C from its candidates.
class YWing extends Technique {
  @override
  String get id => 'y_wing';
  @override
  String get nameEn => 'Y-Wing';
  @override
  String get nameFa => 'وای-وینگ';
  @override
  int get difficulty => 10;

  @override
  Hint? findOne(Board board) {
    final bivalue = [
      for (final c in board.allCells)
        if (c.value == null && c.candidates.length == 2) c,
    ];
    for (final pivot in bivalue) {
      final p = pivot.candidates.toList();
      final a = p[0];
      final b = p[1];
      // Look for wings among peers of the pivot.
      final peers = board.peers(pivot).toList();
      final aWings = <Cell>[];
      final bWings = <Cell>[];
      for (final cell in peers) {
        if (cell.value != null || cell.candidates.length != 2) continue;
        final cands = cell.candidates;
        if (cands.contains(a) && !cands.contains(b)) {
          aWings.add(cell);
        } else if (cands.contains(b) && !cands.contains(a)) {
          bWings.add(cell);
        }
      }
      for (final w1 in aWings) {
        for (final w2 in bWings) {
          if (identical(w1, w2)) continue;
          // The "other" digit of each wing.
          final c1 = w1.candidates.firstWhere((d) => d != a);
          final c2 = w2.candidates.firstWhere((d) => d != b);
          if (c1 != c2) continue;
          final c = c1;
          // Find common peers of both wings (excluding pivot and wings).
          final w1Peers = board.peers(w1).toSet();
          final w2Peers = board.peers(w2).toSet();
          final commonPeers = w1Peers.intersection(w2Peers)
            ..remove(pivot)
            ..remove(w1)
            ..remove(w2);
          final eliminations = <Elimination>[];
          for (final cell in commonPeers) {
            if (cell.value == null && cell.candidates.contains(c)) {
              eliminations.add(
                Elimination(row: cell.row, col: cell.col, values: {c}),
              );
            }
          }
          if (eliminations.isEmpty) continue;
          return _buildHint(
            pivot: pivot,
            wing1: w1,
            wing2: w2,
            a: a,
            b: b,
            c: c,
            eliminations: eliminations,
          );
        }
      }
    }
    return null;
  }

  EliminationHint _buildHint({
    required Cell pivot,
    required Cell wing1,
    required Cell wing2,
    required int a,
    required int b,
    required int c,
    required List<Elimination> eliminations,
  }) {
    final pivotRef = '(R${pivot.row + 1},C${pivot.col + 1})';
    final w1Ref = '(R${wing1.row + 1},C${wing1.col + 1})';
    final w2Ref = '(R${wing2.row + 1},C${wing2.col + 1})';
    return EliminationHint(
      eliminations: eliminations,
      techniqueId: id,
      techniqueNameEn: nameEn,
      techniqueNameFa: nameFa,
      difficulty: difficulty,
      summaryEn: 'Y-Wing: pivot $pivotRef={$a,$b}, wings $w1Ref={$a,$c} and '
          '$w2Ref={$b,$c} — $c is removed from cells seeing both wings.',
      summaryFa:
          'وای-وینگ: محور $pivotRef={$a،$b}، بازوها $w1Ref={$a،$c} و '
          '$w2Ref={$b،$c} — $c از خانه‌هایی که هر دو بازو را می‌بینند حذف '
          'می‌شود.',
      explanationEn:
          'The pivot has candidates {$a, $b}. One wing shares $a with the '
          'pivot and otherwise carries $c; the other wing shares $b with '
          'the pivot and also carries $c. Whichever digit the pivot ends up '
          'taking, the wing on the opposite side must take $c. That means '
          'any empty cell that sees BOTH wings (i.e. shares a row, column, '
          'or box with each of them) cannot also be $c, so we can erase '
          '$c from its candidates.',
      explanationFa:
          'خانه‌ی محور دو گزینه‌ی {$a، $b} دارد. یکی از بازوها $a را با '
          'محور به اشتراک گذاشته و در کنارش $c دارد؛ بازوی دیگر $b را به '
          'اشتراک گذاشته و کنارش هم $c دارد. هر کدام از $a و $b که در '
          'محور قرار بگیرد، بازوی دیگر مجبور است $c شود. پس هر خانه‌ی '
          'خالی که هم به بازوی اول دیده می‌شود و هم به بازوی دوم '
          '(در سطر، ستون یا مربع مشترک)، نمی‌تواند $c باشد و این عدد از '
          'لیست اعداد ممکنش حذف می‌شود.',
      highlights: [
        CellHighlight(
          row: pivot.row,
          col: pivot.col,
          candidates: {a, b},
          role: HighlightRole.evidence,
        ),
        CellHighlight(
          row: wing1.row,
          col: wing1.col,
          candidates: {a, c},
          role: HighlightRole.evidence,
        ),
        CellHighlight(
          row: wing2.row,
          col: wing2.col,
          candidates: {b, c},
          role: HighlightRole.evidence,
        ),
        for (final e in eliminations)
          CellHighlight(
            row: e.row,
            col: e.col,
            candidates: e.values,
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
