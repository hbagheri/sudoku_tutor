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
/// Each entry sets up a minimal board state, runs the technique on it, and
/// captures the resulting hint. Techniques that don't have a hand-crafted
/// example here fall back to a text-only entry in the UI.
List<TechniqueExample> buildTechniqueExamples() {
  final list = <TechniqueExample>[];

  // ---- Naked Single ----
  {
    final b = Board.empty();
    for (var c = 1; c <= 8; c++) {
      b.at(0, c).value = c + 1;
    }
    b.recomputeAllCandidates();
    final t = NakedSingle();
    final h = t.findOne(b);
    if (h != null) list.add(TechniqueExample(technique: t, board: b, hint: h));
  }

  // ---- Hidden Single ----
  {
    final b = Board.empty();
    b.at(1, 3).value = 5;
    b.at(2, 7).value = 5;
    b.at(5, 1).value = 5;
    b.at(6, 2).value = 5;
    b.recomputeAllCandidates();
    final t = HiddenSingle();
    final h = t.findOne(b);
    if (h != null) list.add(TechniqueExample(technique: t, board: b, hint: h));
  }

  // ---- Pointing ----
  {
    final b = Board.empty();
    b.at(1, 0).value = 1;
    b.at(1, 1).value = 2;
    b.at(1, 2).value = 3;
    b.at(2, 0).value = 4;
    b.at(2, 1).value = 5;
    b.at(2, 2).value = 6;
    b.recomputeAllCandidates();
    final t = Pointing();
    final h = t.findOne(b);
    if (h != null) list.add(TechniqueExample(technique: t, board: b, hint: h));
  }

  // ---- Box-Line Reduction ----
  {
    final b = Board.empty();
    b.at(0, 3).value = 1;
    b.at(0, 4).value = 2;
    b.at(0, 5).value = 3;
    b.at(0, 6).value = 4;
    b.at(0, 7).value = 5;
    b.at(0, 8).value = 6;
    b.recomputeAllCandidates();
    final t = BoxLine();
    final h = t.findOne(b);
    if (h != null) list.add(TechniqueExample(technique: t, board: b, hint: h));
  }

  // ---- Naked Pair ----
  {
    final b = Board.empty();
    // Row 0 cols 2..6 filled with 3..7; (1,1)=8 and (2,2)=9 lock 8 and 9 out
    // of (0,0) and (0,1) via box 0. Those two cells end up sharing exactly
    // {1, 2}, and the technique strips 1, 2 from (0,7) and (0,8).
    b.at(0, 2).value = 3;
    b.at(0, 3).value = 4;
    b.at(0, 4).value = 5;
    b.at(0, 5).value = 6;
    b.at(0, 6).value = 7;
    b.at(1, 1).value = 8;
    b.at(2, 2).value = 9;
    b.recomputeAllCandidates();
    final t = NakedPair();
    final h = t.findOne(b);
    if (h != null) list.add(TechniqueExample(technique: t, board: b, hint: h));
  }

  // ---- Hidden Pair ----
  {
    final b = Board.empty();
    // Box 0 receives no 1s or 2s, but every box-0 cell *except* (0,0) and
    // (0,1) gets 1 or 2 blocked from its row or column. The result: in box
    // 0, digits 1 and 2 can only live in those two cells, so any other
    // candidates currently in them can be eliminated.
    b.at(1, 5).value = 1;
    b.at(1, 6).value = 2;
    b.at(2, 4).value = 2;
    b.at(2, 8).value = 1;
    b.at(3, 2).value = 1;
    b.at(4, 2).value = 2;
    b.recomputeAllCandidates();
    final t = HiddenPair();
    final h = t.findOne(b);
    if (h != null) list.add(TechniqueExample(technique: t, board: b, hint: h));
  }

  // Triples, Quads, and X-Wing need denser board states to demonstrate;
  // they are documented textually in `allTechniques` for now and surface
  // their full explanation when the user hits them in a real game.

  return list;
}

/// The full list of techniques, in difficulty order, with display metadata.
/// Includes techniques that don't yet have a visual example.
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
