import 'package:flutter/material.dart';

import '../app/game_controller.dart';
import '../app/settings.dart';
import '../app/strings.dart';
import '../sudoku_engine.dart';
import 'game_screen.dart';
import 'tutorial_screen.dart';

class HomeScreen extends StatelessWidget {
  final AppSettings settings;
  const HomeScreen({required this.settings, super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.appTitle),
        actions: [
          PopupMenuButton<AppLocale>(
            tooltip: s.language,
            icon: const Icon(Icons.language),
            initialValue: settings.locale,
            onSelected: settings.setLocale,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: AppLocale.fa,
                child: Text(s.persian),
              ),
              PopupMenuItem(
                value: AppLocale.en,
                child: Text(s.english),
              ),
            ],
          ),
          PopupMenuButton<ThemeMode>(
            tooltip: s.theme,
            icon: const Icon(Icons.brightness_6_outlined),
            initialValue: settings.themeMode,
            onSelected: settings.setThemeMode,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: ThemeMode.system,
                child: Text(s.themeSystem),
              ),
              PopupMenuItem(
                value: ThemeMode.light,
                child: Text(s.themeLight),
              ),
              PopupMenuItem(
                value: ThemeMode.dark,
                child: Text(s.themeDark),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.grid_on,
                    size: 96,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(s.appTitle, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 32),
                  Text(s.pickDifficulty, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ..._buildDifficultyButtons(context, s),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const TutorialScreen(),
                        ));
                      },
                      icon: const Icon(Icons.school_outlined),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(s.tutorial),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDifficultyButtons(BuildContext context, Strings s) {
    final levels = <(Difficulty, String)>[
      (Difficulty.easy, s.easy),
      (Difficulty.medium, s.medium),
      (Difficulty.hard, s.hard),
      (Difficulty.expert, s.expert),
      (Difficulty.master, s.master),
      (Difficulty.legendary, s.legendary),
    ];
    return [
      for (final (level, label) in levels) ...[
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: () => _startGame(context, level),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(label),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    ];
  }

  void _startGame(BuildContext context, Difficulty diff) {
    // Generate off the build phase. Generation can take a fraction of a
    // second for harder levels — show a quick spinner.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    Future.microtask(() {
      try {
        final controller = GameController.newGame(
          diff,
          autoNotes: settings.autoNotes,
        );
        if (!context.mounted) return;
        Navigator.of(context).pop(); // close spinner
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => GameScreen(controller: controller, settings: settings),
        ));
      } catch (e) {
        if (!context.mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    });
  }
}
