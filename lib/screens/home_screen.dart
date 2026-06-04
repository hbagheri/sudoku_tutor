import 'package:flutter/material.dart';

import '../app/game_controller.dart';
import '../app/game_persistence.dart';
import '../app/settings.dart';
import '../app/strings.dart';
import '../sudoku_engine.dart';
import 'game_screen.dart';
import 'tutorial_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppSettings settings;
  const HomeScreen({required this.settings, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _persistence = GamePersistence();
  SavedGame? _saved;
  bool _checkingSaved = true;

  @override
  void initState() {
    super.initState();
    _refreshSaved();
  }

  Future<void> _refreshSaved() async {
    final saved = await _persistence.load();
    if (!mounted) return;
    setState(() {
      _saved = saved;
      _checkingSaved = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final settings = widget.settings;
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.grid_on,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(s.appTitle, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 24),
                  if (_saved != null) ...[
                    _ContinueCard(
                      saved: _saved!,
                      onContinue: _continueSaved,
                      onDiscard: _discardSaved,
                    ),
                    const SizedBox(height: 16),
                  ],
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
                  if (_checkingSaved)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: SizedBox(
                        height: 2,
                        child: LinearProgressIndicator(),
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
          autoNotes: widget.settings.autoNotes,
          persistence: _persistence,
        );
        if (!context.mounted) return;
        Navigator.of(context).pop(); // close spinner
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => GameScreen(
            controller: controller,
            settings: widget.settings,
          ),
        )).then((_) => _refreshSaved());
      } catch (e) {
        if (!context.mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    });
  }

  void _continueSaved() {
    final saved = _saved;
    if (saved == null) return;
    final controller = GameController.fromSaved(saved, persistence: _persistence);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GameScreen(
        controller: controller,
        settings: widget.settings,
      ),
    )).then((_) => _refreshSaved());
  }

  Future<void> _discardSaved() async {
    await _persistence.clear();
    if (!mounted) return;
    setState(() => _saved = null);
  }
}

class _ContinueCard extends StatelessWidget {
  final SavedGame saved;
  final VoidCallback onContinue;
  final VoidCallback onDiscard;

  const _ContinueCard({
    required this.saved,
    required this.onContinue,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final theme = Theme.of(context);
    final diffLabel = switch (saved.difficulty.name) {
      'easy' => s.easy,
      'medium' => s.medium,
      'hard' => s.hard,
      'expert' => s.expert,
      'master' => s.master,
      'legendary' => s.legendary,
      _ => saved.difficulty.name,
    };
    final m = (saved.elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final sec = (saved.elapsedSeconds % 60).toString().padLeft(2, '0');

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.play_arrow,
                    color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.continueGame,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$diffLabel · $m:$sec',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: s.discardSavedGame,
                  icon: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  onPressed: onDiscard,
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: onContinue,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(s.continueGame),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
