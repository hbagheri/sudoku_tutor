import 'package:flutter/material.dart';

import '../sudoku_engine.dart';

/// One 9x9 grid cell. Shows either a placed value or its pencil-marks
/// (3x3 mini-grid). Tap notifies the parent.
class CellView extends StatelessWidget {
  final Cell cell;
  final bool isSelected;
  final bool isPeer;
  final bool hasSameValueAsSelected;
  final bool isError;
  final HighlightRole? hintRole;
  final Set<int> hintCandidates;
  final VoidCallback onTap;

  const CellView({
    required this.cell,
    required this.isSelected,
    required this.isPeer,
    required this.hasSameValueAsSelected,
    required this.isError,
    required this.onTap,
    this.hintRole,
    this.hintCandidates = const <int>{},
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Color bg;
    if (hintRole == HighlightRole.target) {
      bg = scheme.primaryContainer;
    } else if (hintRole == HighlightRole.evidence) {
      bg = scheme.tertiaryContainer.withValues(alpha: 0.6);
    } else if (hintRole == HighlightRole.eliminated) {
      bg = scheme.errorContainer.withValues(alpha: 0.4);
    } else if (isSelected) {
      bg = scheme.secondaryContainer;
    } else if (hasSameValueAsSelected) {
      bg = scheme.surfaceContainerHighest;
    } else if (isPeer) {
      bg = scheme.surfaceContainerLow;
    } else {
      bg = scheme.surface;
    }

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        child: cell.value != null
            ? _ValueText(
                value: cell.value!,
                isGiven: cell.isGiven,
                isError: isError,
              )
            : _PencilMarks(
                candidates: cell.candidates,
                eliminated: hintRole == HighlightRole.eliminated
                    ? hintCandidates
                    : const <int>{},
                emphasized: hintRole == HighlightRole.evidence
                    ? hintCandidates
                    : const <int>{},
              ),
      ),
    );
  }
}

class _ValueText extends StatelessWidget {
  final int value;
  final bool isGiven;
  final bool isError;

  const _ValueText({
    required this.value,
    required this.isGiven,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = isError
        ? scheme.error
        : isGiven
            ? scheme.onSurface
            : scheme.primary;
    return Center(
      child: Text(
        '$value',
        style: theme.textTheme.headlineSmall?.copyWith(
          color: color,
          fontWeight: isGiven ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _PencilMarks extends StatelessWidget {
  final Set<int> candidates;
  final Set<int> eliminated;
  final Set<int> emphasized;

  const _PencilMarks({
    required this.candidates,
    required this.eliminated,
    required this.emphasized,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final base = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurface.withValues(alpha: 0.65),
      fontSize: 9,
    );

    return Padding(
      padding: const EdgeInsets.all(1.5),
      child: Column(
        children: [
          for (var r = 0; r < 3; r++)
            Expanded(
              child: Row(
                children: [
                  for (var c = 0; c < 3; c++)
                    Expanded(
                      child: Center(
                        child: _pencilChar(
                          digit: r * 3 + c + 1,
                          baseStyle: base,
                          scheme: scheme,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _pencilChar({
    required int digit,
    required TextStyle? baseStyle,
    required ColorScheme scheme,
  }) {
    if (!candidates.contains(digit)) return const SizedBox.shrink();
    final isElim = eliminated.contains(digit);
    final isEmp = emphasized.contains(digit);
    final style = baseStyle?.copyWith(
      color: isElim ? scheme.error : (isEmp ? scheme.primary : null),
      decoration: isElim ? TextDecoration.lineThrough : null,
      fontWeight: isEmp ? FontWeight.w700 : null,
    );
    return Text('$digit', style: style);
  }
}
