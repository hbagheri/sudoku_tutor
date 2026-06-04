import 'package:flutter/widgets.dart';

/// Minimal i18n: two locales (English, Persian) and a static lookup of
/// hand-written strings. No code generation. Add a getter per string.

enum AppLocale { en, fa }

extension AppLocaleExt on AppLocale {
  String get code => switch (this) {
        AppLocale.en => 'en',
        AppLocale.fa => 'fa',
      };

  TextDirection get textDirection => switch (this) {
        AppLocale.en => TextDirection.ltr,
        AppLocale.fa => TextDirection.rtl,
      };

  Locale get flutterLocale => Locale(code);

  static AppLocale fromCode(String code) =>
      code == 'fa' ? AppLocale.fa : AppLocale.en;
}

class Strings {
  final AppLocale locale;
  const Strings(this.locale);

  bool get isFa => locale == AppLocale.fa;

  String get appTitle => isFa ? 'معلم سودوکو' : 'Sudoku Tutor';

  String get newGame => isFa ? 'بازی جدید' : 'New Game';
  String get continueGame => isFa ? 'ادامه بازی' : 'Continue';
  String get discardSavedGame => isFa ? 'صرف نظر و شروع جدید' : 'Discard';
  String get settings => isFa ? 'تنظیمات' : 'Settings';
  String get stats => isFa ? 'آمار' : 'Stats';

  String get easy => isFa ? 'آسان' : 'Easy';
  String get medium => isFa ? 'متوسط' : 'Medium';
  String get hard => isFa ? 'سخت' : 'Hard';
  String get expert => isFa ? 'خبره' : 'Expert';
  String get master => isFa ? 'استاد' : 'Master';
  String get legendary => isFa ? 'افسانه‌ای' : 'Legendary';

  String get language => isFa ? 'زبان' : 'Language';
  String get persian => isFa ? 'فارسی' : 'Persian';
  String get english => isFa ? 'انگلیسی' : 'English';
  String get theme => isFa ? 'تم' : 'Theme';
  String get themeLight => isFa ? 'روشن' : 'Light';
  String get themeDark => isFa ? 'تاریک' : 'Dark';
  String get themeSystem => isFa ? 'سیستم' : 'System';

  String get erase => isFa ? 'پاک‌کن' : 'Erase';
  String get pencil => isFa ? 'یادداشت' : 'Notes';
  String get hint => isFa ? 'راهنما' : 'Hint';
  String get autofillNotes =>
      isFa ? 'نوشتن اعداد ممکن' : 'Mark possibilities';
  String get autoNotes =>
      isFa ? 'یادداشت خودکار' : 'Auto notes';
  String get showNotes =>
      isFa ? 'نمایش اعداد ممکن' : 'Show possibilities';
  String get check => isFa ? 'بررسی' : 'Check';
  String get undo => isFa ? 'برگشت' : 'Undo';

  String get nextStep => isFa ? 'گام بعدی' : 'Next step';
  String get autoSolve => isFa ? 'حل خودکار' : 'Auto-solve';
  String get tapForExplanation =>
      isFa ? 'برای توضیح کلیک کنید' : 'Tap for explanation';

  String get mistakes => isFa ? 'اشتباه' : 'Mistakes';
  String get timer => isFa ? 'زمان' : 'Time';
  String get difficulty => isFa ? 'سختی' : 'Difficulty';

  String get solved => isFa ? 'حل شد!' : 'Solved!';
  String get noHintsLeft => isFa ? 'تکنیکی پیدا نشد' : 'No technique applies';
  String get pickDifficulty =>
      isFa ? 'یک سطح را انتخاب کنید' : 'Pick a difficulty';
  String get congrats => isFa ? 'آفرین!' : 'Well done!';
  String get solvedMessage => isFa
      ? 'پازل را حل کردی. آماده‌ی پازل بعدی هستی؟'
      : 'Puzzle solved. Ready for the next one?';
  String get playAgain => isFa ? 'بازی دوباره' : 'Play again';
  String get backToMenu => isFa ? 'بازگشت به منو' : 'Back to menu';
  String get statsCompleted => isFa ? 'حل‌شده' : 'Completed';
  String get statsBestTime => isFa ? 'بهترین زمان' : 'Best time';
  String get statsTotalTime => isFa ? 'مجموع زمان' : 'Total time';
  String get statsTotalMistakes => isFa ? 'مجموع اشتباهات' : 'Total mistakes';
  String get statsAvgTime => isFa ? 'میانگین زمان' : 'Avg time';
  String get statsEmpty => isFa
      ? 'هنوز پازلی حل نکرده‌اید. یک بازی شروع کنید!'
      : 'No puzzles solved yet. Start a game!';
  String get statsReset => isFa ? 'پاک کردن آمار' : 'Reset stats';
  String get statsResetConfirm => isFa
      ? 'مطمئنید؟ همه‌ی آمار از بین می‌رود.'
      : 'Are you sure? All stats will be cleared.';
  String get cancel => isFa ? 'انصراف' : 'Cancel';
  String get yes => isFa ? 'بله' : 'Yes';

  // ---- Custom puzzle ----
  String get custom => isFa ? 'سفارشی' : 'Custom';
  String get enterCustomPuzzle =>
      isFa ? 'وارد کردن پازل دستی' : 'Enter a custom puzzle';
  String get customPuzzleIntro => isFa
      ? 'یک پازل از روزنامه یا مجله را خانه به خانه وارد کنید. وقتی '
        'پازل معتبر شد، دکمه‌ی «شروع بازی» فعال می‌شود.'
      : 'Tap a cell and type the digit shown in the magazine or newspaper. '
        'When the puzzle is valid, "Start playing" lights up.';
  String get clues => isFa ? 'سرنخ' : 'clues';
  String get startPlaying => isFa ? 'شروع بازی' : 'Start playing';
  String get clearAll => isFa ? 'پاک کردن همه' : 'Clear all';
  String get statusEmpty => isFa ? 'هنوز سرنخی وارد نکرده‌اید' : 'No clues yet';
  String get statusInvalid =>
      isFa ? 'تکراری در سطر، ستون یا مربع' : 'Duplicate in a row/column/box';
  String get statusNoSolution =>
      isFa ? 'این پازل جواب ندارد' : 'No solution exists';
  String get statusMultipleSolutions =>
      isFa ? 'چند جواب دارد — سرنخ بیشتری اضافه کنید' : 'Multiple solutions — add more clues';
  String get statusValid => isFa ? 'پازل معتبر است' : 'Puzzle is valid';
  String get checking => isFa ? 'در حال بررسی…' : 'Checking…';
  String get tutorial => isFa ? 'آموزش تکنیک‌ها' : 'Learn techniques';
  String get tutorialIntro => isFa
      ? 'هر تکنیک یک «قلق» منطقی برای پیشروی در پازل است. اینجا با مثال '
        'تصویری توضیح داده می‌شوند. به ترتیب از ساده به پیچیده.'
      : 'Each technique is a logical pattern that lets you advance. Tap to '
        'expand and see a worked example. Ordered from easy to hard.';
  String get example => isFa ? 'مثال' : 'Example';
}

/// Access the active [Strings] from a [BuildContext]. The current [AppLocale]
/// lives in [StringsScope] above us in the widget tree.
extension StringsCtx on BuildContext {
  Strings get strings {
    final scope = dependOnInheritedWidgetOfExactType<StringsScope>();
    return Strings(scope?.locale ?? AppLocale.en);
  }

  AppLocale get appLocale =>
      dependOnInheritedWidgetOfExactType<StringsScope>()?.locale ??
      AppLocale.en;
}

class StringsScope extends InheritedWidget {
  final AppLocale locale;
  const StringsScope({
    required this.locale,
    required super.child,
    super.key,
  });

  @override
  bool updateShouldNotify(StringsScope old) => old.locale != locale;
}
