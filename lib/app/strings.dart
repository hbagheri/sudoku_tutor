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
