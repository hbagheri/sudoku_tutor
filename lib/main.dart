import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/settings.dart';
import 'app/strings.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();
  runApp(SudokuTutorApp(settings: settings));
}

class SudokuTutorApp extends StatelessWidget {
  final AppSettings settings;
  const SudokuTutorApp({required this.settings, super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        final lightScheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF3D5AFE),
        );
        final darkScheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF3D5AFE),
          brightness: Brightness.dark,
        );
        return StringsScope(
          locale: settings.locale,
          child: MaterialApp(
            title: 'Sudoku Tutor',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: lightScheme,
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: darkScheme,
              useMaterial3: true,
            ),
            themeMode: settings.themeMode,
            locale: settings.locale.flutterLocale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('fa')],
            builder: (context, child) {
              return Directionality(
                textDirection: settings.locale.textDirection,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: HomeScreen(settings: settings),
          ),
        );
      },
    );
  }
}
