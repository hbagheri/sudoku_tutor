import 'package:flutter/material.dart';

import '../app/strings.dart';
import '../data/tutorial_examples.dart';
import '../widgets/static_board_view.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final examples = buildTechniqueExamples();
    final byId = {for (final e in examples) e.technique.id: e};

    return Scaffold(
      appBar: AppBar(title: Text(s.tutorial)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(s.tutorialIntro, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            for (final info in allTechniques) ...[
              _TechniqueCard(
                info: info,
                example: byId[info.id],
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _TechniqueCard extends StatefulWidget {
  final TechniqueInfo info;
  final TechniqueExample? example;

  const _TechniqueCard({required this.info, this.example});

  @override
  State<_TechniqueCard> createState() => _TechniqueCardState();
}

class _TechniqueCardState extends State<_TechniqueCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final isFa = s.isFa;
    final theme = Theme.of(context);
    final name = isFa ? widget.info.nameFa : widget.info.nameEn;
    final summary = isFa ? widget.info.summaryFa : widget.info.summaryEn;
    final example = widget.example;

    String? exampleSummary;
    String? exampleExplanation;
    if (example != null) {
      exampleSummary = isFa ? example.hint.summaryFa : example.hint.summaryEn;
      exampleExplanation =
          isFa ? example.hint.explanationFa : example.hint.explanationEn;
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _DifficultyChip(level: widget.info.difficulty),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          summary,
                          maxLines: _expanded ? null : 2,
                          overflow: _expanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded && example != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      s.example,
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                  Center(
                    child: StaticBoardView(
                      board: example.board,
                      hint: example.hint,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (exampleSummary != null)
                    Text(
                      exampleSummary,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  const SizedBox(height: 8),
                  if (exampleExplanation != null)
                    Text(
                      exampleExplanation,
                      style: theme.textTheme.bodyMedium,
                    ),
                ],
              ),
            )
          else if (_expanded && example == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    isFa
                        ? 'مثال تصویری برای این تکنیک به‌زودی اضافه می‌شود. '
                          'فعلاً وقتی این تکنیک در یک پازل واقعی فعال شد، '
                          'دقیقاً همین توضیح در نوار راهنمای بالا نشان '
                          'داده می‌شود.'
                        : 'A visual example for this technique is coming '
                          'soon. For now, when it fires inside a real game, '
                          'the same explanation appears in the hint bar at '
                          'the top.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final int level;
  const _DifficultyChip({required this.level});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (level) {
      1 => Colors.green,
      2 => Colors.lightGreen,
      3 => Colors.lime,
      4 => Colors.amber,
      5 => Colors.orange,
      6 => Colors.deepOrange,
      7 => Colors.red,
      _ => Colors.purple,
    };
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        '$level',
        style: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
