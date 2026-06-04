import '../sudoku_engine.dart';

/// One self-contained worked example: a board, the hint that fires on it,
/// and the technique metadata for display.
class TechniqueExample {
  final Technique technique;
  final Board board;
  final Hint hint;

  TechniqueExample({
    required this.technique,
    required this.board,
    required this.hint,
  });
}

/// Build the curated list of examples shown in the tutorial screen.
///
/// All 14 boards below were captured by walking a single Legendary-difficulty
/// puzzle (seed 1 from `tool/extract_examples.dart`) and recording the first
/// state at which each technique naturally fires. That keeps the examples
/// honest — they are positions the solver itself actually reaches — and
/// removes the need to hand-craft contrived boards.
List<TechniqueExample> buildTechniqueExamples() {
  final list = <TechniqueExample>[];

  // ---- naked_single (seed=1, step=3) ----
  {
    final b = _restore(
      '060000040018700006200000039800005900006090300390007080080024007634000890050000000',
      _cands1Step3,
    );
    _capture(list, 'naked_single', b);
  }

  // ---- hidden_single (seed=1, step=0) ----
  {
    final b = _restore(_givens1Step0, _cands1Step0);
    _capture(list, 'hidden_single', b);
  }

  // ---- pointing (seed=1, step=0) ----
  {
    final b = _restore(_givens1Step0, _cands1Step0);
    _capture(list, 'pointing', b);
  }

  // ---- box_line (seed=1, step=0) ----
  {
    final b = _restore(_givens1Step0, _cands1Step0);
    _capture(list, 'box_line', b);
  }

  // ---- naked_pair (seed=1, step=0) ----
  {
    final b = _restore(_givens1Step0, _cands1Step0);
    _capture(list, 'naked_pair', b);
  }

  // ---- hidden_pair (seed=1, step=0) ----
  {
    final b = _restore(_givens1Step0, _cands1Step0);
    _capture(list, 'hidden_pair', b);
  }

  // ---- naked_triple (seed=1, step=0) ----
  {
    final b = _restore(_givens1Step0, _cands1Step0);
    _capture(list, 'naked_triple', b);
  }

  // ---- hidden_triple (seed=1, step=0) ----
  {
    final b = _restore(_givens1Step0, _cands1Step0);
    _capture(list, 'hidden_triple', b);
  }

  // ---- naked_quad (seed=1, step=0) ----
  {
    final b = _restore(_givens1Step0, _cands1Step0);
    _capture(list, 'naked_quad', b);
  }

  // ---- hidden_quad (seed=1, step=3) ----
  {
    final b = _restore(
      '060000040018700006200000039800005900006090300390007080080024007634000890050000000',
      _cands1Step3,
    );
    _capture(list, 'hidden_quad', b);
  }

  // ---- swordfish (seed=1, step=0) ----
  {
    final b = _restore(_givens1Step0, _cands1Step0);
    _capture(list, 'swordfish', b);
  }

  // ---- x_wing (seed=1, step=10) ----
  {
    final b = _restore(
      '060000040018703006200000039800035900006090300390007080080324007634571892050000000',
      _cands1Step10,
    );
    _capture(list, 'x_wing', b);
  }

  // ---- y_wing (seed=1, step=17) ----
  {
    final b = _restore(
      '563000040918703006207000039800035900006090300390007080189324007634571892750000000',
      _cands1Step17,
    );
    _capture(list, 'y_wing', b);
  }

  // ---- unique_rectangle (seed=1, step=27) ----
  {
    final b = _restore(
      '563010048918703006247000039801035904406090305395007081189324007634571892752000000',
      _cands1Step27,
    );
    _capture(list, 'unique_rectangle', b);
  }

  return list;
}

void _capture(List<TechniqueExample> list, String id, Board b) {
  final t = _techniqueById(id);
  if (t == null) return;
  final h = t.findOne(b);
  if (h == null) return;
  list.add(TechniqueExample(technique: t, board: b, hint: h));
}

Technique? _techniqueById(String id) {
  for (final t in Solver().techniques) {
    if (t.id == id) return t;
  }
  return null;
}

/// Build a Board from an 81-character compact value string (0 for empty)
/// plus a list of 81 candidate digit lists (one per cell).
Board _restore(String values, List<List<int>> candidates) {
  assert(values.length == 81);
  assert(candidates.length == 81);
  final b = Board.empty();
  for (var i = 0; i < 81; i++) {
    final r = i ~/ 9;
    final c = i % 9;
    final cell = b.at(r, c);
    final v = int.tryParse(values[i]) ?? 0;
    if (v != 0) {
      cell.value = v;
      cell.isGiven = true;
    } else {
      cell.candidates = candidates[i].toSet();
    }
  }
  return b;
}

// ============================================================================
// Captured board candidate states from `tool/extract_examples.dart` (seed=1).
// Each entry is a list of 81 digit lists — empty for placed cells.
// ============================================================================

const String _givens1Step0 =
    '060000040018700006200000039800005000006090300390007080000024007604000890050000000';

const List<List<int>> _cands1Step0 = [
  [5,7,9],[],[3,5,7,9],[1,2,3,5,8,9],[1,3,5,8],[1,2,3,8,9],[1,2,5,7],[],[1,2,5,8],
  [4,5,9],[],[],[],[3,4,5],[2,3,9],[2,5],[2,5],[],
  [],[4,7],[5,7],[1,4,5,6,8],[1,4,5,6,8],[1,6,8],[1,5,7],[],[],
  [],[2,4,7],[1,2,7],[1,2,3,4,6],[1,3,4,6],[],[1,2,4,6,7,9],[1,2,6,7],[1,2,4],
  [1,4,5,7],[2,4,7],[],[1,2,4,8],[],[1,2,8],[],[1,2,5,7],[1,2,4,5],
  [],[],[1,2,5],[1,2,4,6],[1,4,6],[],[1,2,4,5,6],[],[1,2,4,5],
  [1,9],[3,8],[1,3,9],[1,3,5,6,8,9],[],[],[1,5,6],[1,5,6],[],
  [],[2,3,7],[],[1,3,5],[1,3,5,7],[1,3],[],[],[1,2,3,5],
  [1,7,9],[],[1,2,3,7,9],[1,3,6,8,9],[1,3,6,7,8],[1,3,6,8,9],[1,2,4,6],[1,2,6],[1,2,3,4],
];

const List<List<int>> _cands1Step3 = [
  [5,7,9],[],[3,5,7,9],[1,2,3,5,8,9],[1,3,5,8],[1,2,3,8,9],[1,2,5,7],[],[1,2,5,8],
  [4,5,9],[],[],[],[3,4,5],[2,3,9],[2,5],[2,5],[],
  [],[4,7],[5,7],[1,4,5,6,8],[1,4,5,6,8],[1,6,8],[1,5,7],[],[],
  [],[2,4,7],[1,2,7],[1,2,3,4,6],[1,3,4,6],[],[],[1,2,6,7],[1,2,4],
  [1,4,5,7],[2,4,7],[],[1,2,4,8],[],[1,2,8],[],[1,2,5,7],[1,2,4,5],
  [],[],[1,2,5],[1,2,4,6],[1,4,6],[],[1,2,4,5,6],[],[1,2,4,5],
  [1,9],[],[1,9],[1,3,5,6,9],[],[],[1,5,6],[1,5,6],[],
  [],[],[],[1,5],[1,5,7],[1],[],[],[1,2,5],
  [1,7,9],[],[1,2,7,9],[1,3,6,8,9],[1,3,6,7,8],[1,3,6,8,9],[1,2,4,6],[1,2,6],[1,2,3,4],
];

const List<List<int>> _cands1Step10 = [
  [5,7,9],[],[3,5,7,9],[1,2,8,9],[1,5,8],[2,8,9],[1,2,5,7],[],[1,5,8],
  [4,5,9],[],[],[],[4,5],[],[2,5],[2,5],[],
  [],[4,7],[5,7],[1,4,6,8],[1,4,5,6,8],[6,8],[1,5,7],[],[],
  [],[2,4,7],[1,2,7],[1,2,4,6],[],[],[],[1,2,6,7],[1,4],
  [1,4,5,7],[2,4,7],[],[1,2,4,8],[],[2,8],[],[1,2,5,7],[1,4,5],
  [],[],[1,2,5],[1,2,4,6],[1,4,6],[],[1,2,4,5,6],[],[1,4,5],
  [1,9],[],[1,9],[],[],[],[1,5,6],[1,5,6],[],
  [],[],[],[],[],[],[],[],[],
  [1,7,9],[],[1,2,7,9],[6,8,9],[6,8],[6,8,9],[1,4,6],[1,6],[1,3,4],
];

const List<List<int>> _cands1Step17 = [
  [],[],[],[1,2,8,9],[1,8],[2,8,9],[1,2,7],[],[1,8],
  [],[],[],[],[4,5],[],[2,5],[2,5],[],
  [],[4],[],[1,4,6,8],[1,4,5,6,8],[6,8],[1,5],[],[],
  [],[2,4,7],[1,2],[1,2,4,6],[],[],[],[1,2,6,7],[1,4],
  [4],[2,4,7],[],[1,2,4,8],[],[2,8],[],[1,2,5,7],[1,4,5],
  [],[],[1,2,5],[1,2,4,6],[1,4,6],[],[1,2,4,5,6],[],[1,4,5],
  [],[],[],[],[],[],[5,6],[5,6],[],
  [],[],[],[],[],[],[],[],[],
  [],[],[2],[6,8,9],[6,8],[6,8,9],[1,4,6],[1,6],[1,3,4],
];

const List<List<int>> _cands1Step27 = [
  [],[],[],[2,9],[],[2,9],[2,7],[],[],
  [],[],[],[],[4,5],[],[2,5],[2,5],[],
  [],[],[],[6,8],[5,6,8],[6,8],[1,5],[],[],
  [],[2,7],[],[2,6],[],[],[],[2,6,7],[],
  [],[2,7],[],[1,2,8],[],[2,8],[],[2,7],[],
  [],[],[],[2,4,6],[4,6],[],[2,6],[],[],
  [],[],[],[],[],[],[5,6],[5,6],[],
  [],[],[],[],[],[],[],[],[],
  [],[],[],[6,8,9],[6,8],[6,8,9],[1,4,6],[1,6],[3],
];

/// The full list of techniques, in difficulty order, with display metadata.
const List<TechniqueInfo> allTechniques = [
  TechniqueInfo(
    id: 'naked_single',
    nameEn: 'Naked Single',
    nameFa: 'تک‌تنها',
    difficulty: 1,
    summaryEn: 'A cell whose pencil-marks have shrunk to a single digit must '
        'hold that digit.',
    summaryFa: 'خانه‌ای که اعداد ممکنش به یک عدد رسیده، باید همان عدد را '
        'بپذیرد.',
  ),
  TechniqueInfo(
    id: 'hidden_single',
    nameEn: 'Hidden Single',
    nameFa: 'تک‌پنهان',
    difficulty: 2,
    summaryEn: 'Within a row, column, or box, a digit may have only one cell '
        'left where it can legally go.',
    summaryFa: 'در یک سطر، ستون یا مربع، یک عدد ممکن است فقط یک خانه برای '
        'قرار گرفتن داشته باشد.',
  ),
  TechniqueInfo(
    id: 'pointing',
    nameEn: 'Pointing Pair / Triple',
    nameFa: 'زوج/سه‌تایی اشاره‌گر',
    difficulty: 3,
    summaryEn: 'If every candidate cell for a digit in a 3×3 box sits in '
        'one row (or column), the digit can be eliminated from the rest '
        'of that row/column.',
    summaryFa: 'اگر همه‌ی خانه‌های یک مربع که می‌توانند یک عدد را داشته '
        'باشند، در یک سطر (یا ستون) قرار گیرند، آن عدد از باقی آن سطر/ستون '
        'حذف می‌شود.',
  ),
  TechniqueInfo(
    id: 'box_line',
    nameEn: 'Box-Line Reduction',
    nameFa: 'کاهش مربع-خط',
    difficulty: 4,
    summaryEn: 'Mirror of Pointing: if every candidate cell for a digit in '
        'a row/column lives inside one box, the digit goes from the rest '
        'of that box.',
    summaryFa: 'برعکس «اشاره‌گر»: اگر همه‌ی خانه‌های یک سطر/ستون که می‌توانند '
        'یک عدد را داشته باشند، در یک مربع باشند، آن عدد از باقی آن مربع '
        'حذف می‌شود.',
  ),
  TechniqueInfo(
    id: 'naked_pair',
    nameEn: 'Naked Pair',
    nameFa: 'زوج برهنه',
    difficulty: 5,
    summaryEn: 'Two cells in a unit share exactly the same two candidate '
        'digits → those two digits are reserved for those two cells.',
    summaryFa: 'دو خانه از یک واحد دقیقاً دو عدد ممکن یکسان دارند → آن دو '
        'عدد فقط برای آن دو خانه می‌مانند.',
  ),
  TechniqueInfo(
    id: 'hidden_pair',
    nameEn: 'Hidden Pair',
    nameFa: 'زوج پنهان',
    difficulty: 6,
    summaryEn: 'Two digits in a unit can only go in the same two cells — '
        'those cells contain only those digits.',
    summaryFa: 'دو عدد در یک واحد فقط می‌توانند در همان دو خانه قرار گیرند — '
        'آن خانه‌ها فقط همان دو عدد را دارند.',
  ),
  TechniqueInfo(
    id: 'naked_triple',
    nameEn: 'Naked Triple',
    nameFa: 'سه‌تایی برهنه',
    difficulty: 6,
    summaryEn: 'Three cells in a unit share at most three candidate digits '
        'between them → those digits are reserved for those cells.',
    summaryFa: 'سه خانه از یک واحد روی هم حداکثر سه عدد ممکن دارند → آن '
        'اعداد برای آن خانه‌ها رزرو شده‌اند.',
  ),
  TechniqueInfo(
    id: 'hidden_triple',
    nameEn: 'Hidden Triple',
    nameFa: 'سه‌تایی پنهان',
    difficulty: 7,
    summaryEn: 'Three digits in a unit are confined to the same three cells.',
    summaryFa: 'سه عدد در یک واحد محدود به همان سه خانه هستند.',
  ),
  TechniqueInfo(
    id: 'naked_quad',
    nameEn: 'Naked Quad',
    nameFa: 'چهارتایی برهنه',
    difficulty: 7,
    summaryEn: 'Four cells share at most four candidate digits.',
    summaryFa: 'چهار خانه روی هم حداکثر چهار عدد ممکن دارند.',
  ),
  TechniqueInfo(
    id: 'hidden_quad',
    nameEn: 'Hidden Quad',
    nameFa: 'چهارتایی پنهان',
    difficulty: 8,
    summaryEn: 'Four digits in a unit are confined to the same four cells.',
    summaryFa: 'چهار عدد در یک واحد محدود به همان چهار خانه هستند.',
  ),
  TechniqueInfo(
    id: 'x_wing',
    nameEn: 'X-Wing',
    nameFa: 'ایکس-وینگ',
    difficulty: 9,
    summaryEn: 'Two rows where a digit has exactly two candidate columns each, '
        'sharing the same column pair, force a 2×2 lock — the digit can be '
        'eliminated from those columns elsewhere.',
    summaryFa: 'دو سطر که هر کدام برای یک عدد دقیقاً دو ستون به عنوان '
        'گزینه دارند و آن دو ستون یکی هستند، یک قفل ۲×۲ می‌سازند — آن عدد '
        'از باقی آن ستون‌ها حذف می‌شود.',
  ),
  TechniqueInfo(
    id: 'y_wing',
    nameEn: 'Y-Wing',
    nameFa: 'وای-وینگ',
    difficulty: 10,
    summaryEn: 'A bivalue pivot {A,B} and two bivalue wings {A,C} and {B,C} '
        'that the pivot sees — any cell that sees both wings cannot be C.',
    summaryFa: 'یک محور دومقداری {A,B} با دو بازوی دومقداری {A,C} و {B,C} '
        'که محور هر دو را می‌بیند — هر خانه‌ای که هر دو بازو را می‌بیند '
        'نمی‌تواند C باشد.',
  ),
  TechniqueInfo(
    id: 'swordfish',
    nameEn: 'Swordfish',
    nameFa: 'سوردفیش',
    difficulty: 11,
    summaryEn: 'Like X-Wing but on 3 rows whose candidate columns all lie '
        'within the same 3 columns — those columns lock the digit, so it '
        'can be removed from those columns in every other row.',
    summaryFa: 'مانند ایکس-وینگ، ولی روی ۳ سطر که ستون‌های نامزدشان همگی '
        'در همان ۳ ستون قرار دارند — این ۳ ستون قفل می‌شوند و آن عدد از '
        'باقی سطرها در آن ستون‌ها حذف می‌شود.',
  ),
  TechniqueInfo(
    id: 'unique_rectangle',
    nameEn: 'Unique Rectangle',
    nameFa: 'مستطیل یکتا',
    difficulty: 12,
    summaryEn: 'Sudoku has a unique solution, so a "deadly rectangle" of '
        'four corners in two boxes carrying only {A,B} is impossible. If '
        'three corners look like that, the fourth must use its extras.',
    summaryFa: 'سودوکو یک جواب یکتا دارد، پس «مستطیل مرگبار» چهار گوشه '
        'با {A،B} در دو مربع ممکن نیست. اگر سه گوشه چنین باشند، گوشه‌ی '
        'چهارم باید گزینه‌های اضافی‌اش را بگیرد.',
  ),
];

/// Lightweight metadata for techniques that don't (yet) carry a worked
/// example.
class TechniqueInfo {
  final String id;
  final String nameEn;
  final String nameFa;
  final int difficulty;
  final String summaryEn;
  final String summaryFa;

  const TechniqueInfo({
    required this.id,
    required this.nameEn,
    required this.nameFa,
    required this.difficulty,
    required this.summaryEn,
    required this.summaryFa,
  });
}
