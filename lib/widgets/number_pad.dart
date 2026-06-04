import 'package:flutter/material.dart';

import '../app/game_controller.dart';
import '../app/strings.dart';

/// Bottom input pad: 1..9 buttons + Erase + Pencil toggle + Auto-notes.
class NumberPad extends StatelessWidget {
  final GameController controller;
  const NumberPad({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row of 1..9
            LayoutBuilder(
              builder: (context, c) {
                final width = (c.maxWidth - 8 * 4) / 9;
                return Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: [
                    for (var d = 1; d <= 9; d++)
                      SizedBox(
                        width: width.clamp(34, 56),
                        height: 52,
                        child: FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => controller.enterDigit(d),
                          child: Text(
                            '$d',
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            // Action row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionButton(
                  icon: controller.pencilMode
                      ? Icons.edit
                      : Icons.edit_outlined,
                  label: s.pencil,
                  selected: controller.pencilMode,
                  onTap: controller.togglePencilMode,
                ),
                _ActionButton(
                  icon: Icons.backspace_outlined,
                  label: s.erase,
                  onTap: controller.eraseSelected,
                ),
                _ActionButton(
                  icon: Icons.auto_awesome_outlined,
                  label: s.autofillNotes,
                  onTap: controller.autofillNotes,
                ),
                _ActionButton(
                  icon: Icons.undo,
                  label: s.undo,
                  onTap: controller.undo,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
