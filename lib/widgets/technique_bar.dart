import 'package:flutter/material.dart';

import '../app/game_controller.dart';
import '../app/strings.dart';

/// Persistent top bar that names the technique behind the current hint.
/// Tapping expands into a teaching panel with the full explanation.
class TechniqueBar extends StatefulWidget {
  final GameController controller;
  const TechniqueBar({required this.controller, super.key});

  @override
  State<TechniqueBar> createState() => _TechniqueBarState();
}

class _TechniqueBarState extends State<TechniqueBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final isFa = s.isFa;
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final hint = widget.controller.activeHint;
        if (hint == null) return const SizedBox.shrink();
        final name = isFa ? hint.techniqueNameFa : hint.techniqueNameEn;
        final summary = isFa ? hint.summaryFa : hint.summaryEn;
        final explanation = isFa ? hint.explanationFa : hint.explanationEn;
        return Material(
          color: theme.colorScheme.tertiaryContainer,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 18, color: theme.colorScheme.onTertiaryContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$name — $summary',
                          maxLines: _expanded ? null : 1,
                          overflow: _expanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ],
                  ),
                  if (_expanded) ...[
                    const SizedBox(height: 8),
                    Text(
                      explanation,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        FilledButton.tonal(
                          onPressed: widget.controller.applyActiveHint,
                          child: Text(isFa ? 'اعمال' : 'Apply'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
