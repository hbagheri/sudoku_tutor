import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'strings.dart';

/// User-configurable, persisted app settings: language + theme mode.
class AppSettings extends ChangeNotifier {
  static const _kLocale = 'locale';
  static const _kThemeMode = 'themeMode';
  static const _kAutoNotes = 'autoNotes';

  final SharedPreferences _prefs;

  AppLocale _locale;
  ThemeMode _themeMode;
  bool _autoNotes;

  AppSettings._(this._prefs, this._locale, this._themeMode, this._autoNotes);

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final locale = AppLocaleExt.fromCode(
      prefs.getString(_kLocale) ?? AppLocale.en.code,
    );
    final mode = _themeModeFromString(prefs.getString(_kThemeMode));
    final autoNotes = prefs.getBool(_kAutoNotes) ?? false;
    return AppSettings._(prefs, locale, mode, autoNotes);
  }

  AppLocale get locale => _locale;
  ThemeMode get themeMode => _themeMode;

  /// When true, the app auto-fills pencil marks at game start and removes
  /// the placed digit from peers' candidates after every move. When false,
  /// the user manages pencil marks manually.
  bool get autoNotes => _autoNotes;

  Future<void> setLocale(AppLocale next) async {
    if (_locale == next) return;
    _locale = next;
    await _prefs.setString(_kLocale, next.code);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _prefs.setString(_kThemeMode, mode.name);
    notifyListeners();
  }

  Future<void> setAutoNotes(bool v) async {
    if (_autoNotes == v) return;
    _autoNotes = v;
    await _prefs.setBool(_kAutoNotes, v);
    notifyListeners();
  }

  static ThemeMode _themeModeFromString(String? raw) {
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}
