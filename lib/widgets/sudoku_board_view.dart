import 'package:flutter/material.dart';

import '../app/game_controller.dart';
import '../sudoku_engine.dart';
import 'cell_view.dart';

/// Renders the 9x9 Sudoku grid. Listens to a [GameController] and rebuilds
/// when the board or selection changes.
class SudokuBoardView extends StatelessWidget {
  final GameController controller;
  const SudokuBoardView({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final selectedCell = controller.selectedCell;
        final hint = controller.activeHint;
        final hintMap = _buildHintMap(hint);

        return AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outline, width: 2),
            ),
            child: Column(
              children: [
                for (var bandRow = 0; bandRow < 3; bandRow++)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: bandRow < 2
                              ? BorderSide(color: scheme.outline, width: 2)
                              : BorderSide.none,
                        ),
                      ),
                      child: Column(
                        children: [
                          for (var rOff = 0; rOff < 3; rOff++)
                            Expanded(
                              child: _buildRow(
                                row: bandRow * 3 + rOff,
                                selectedCell: selectedCell,
                                hintMap: hintMap,
                                scheme: scheme,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRow({
    required int row,
    required Cell? selectedCell,
    required Map<_RC, _HintInfo> hintMap,
    required ColorScheme scheme,
  }) {
    return Row(
      children: [
        for (var bandCol = 0; bandCol < 3; bandCol++)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: bandCol < 2
                      ? BorderSide(color: scheme.outline, width: 2)
                      : BorderSide.none,
                ),
              ),
              child: Row(
                children: [
                  for (var cOff = 0; cOff < 3; cOff++)
                    Expanded(
                      child: _cell(
                        row: row,
                        col: bandCol * 3 + cOff,
                        selectedCell: selectedCell,
                        hintMap: hintMap,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _cell({
    required int row,
    required int col,
    required Cell? selectedCell,
    required Map<_RC, _HintInfo> hintMap,
  }) {
    final cell = controller.board.at(row, col);
    final isSelected =
        selectedCell != null && selectedCell.row == row && selectedCell.col == col;
    final isPeer = selectedCell != null &&
        !isSelected &&
        (selectedCell.row == row ||
            selectedCell.col == col ||
            selectedCell.box == cell.box);
    final sameValue = selectedCell != null &&
        selectedCell.value != null &&
        cell.value == selectedCell.value;
    final isError = _isError(cell);
    final hintInfo = hintMap[_RC(row, col)];

    return CellView(
      cell: cell,
      isSelected: isSelected,
      isPeer: isPeer,
      hasSameValueAsSelected: sameValue && !isSelected,
      isError: isError,
      hintRole: hintInfo?.role,
      hintCandidates: hintInfo?.candidates ?? const <int>{},
      onTap: () => controller.selectCell(row, col),
    );
  }

  bool _isError(Cell cell) {
    final v = cell.value;
    if (v == null) return false;
    final expected = controller.solution.at(cell.row, cell.col).value;
    return expected != null && v != expected;
  }

  Map<_RC, _HintInfo> _buildHintMap(Hint? hint) {
    if (hint == null) return const {};
    final map = <_RC, _HintInfo>{};
    for (final hl in hint.highlights) {
      map[_RC(hl.row, hl.col)] = _HintInfo(hl.role, hl.candidates);
    }
    return map;
  }
}

class _RC {
  final int r;
  final int c;
  const _RC(this.r, this.c);
  @override
  int get hashCode => Object.hash(r, c);
  @override
  bool operator ==(Object other) =>
      other is _RC && other.r == r && other.c == c;
}

class _HintInfo {
  final HighlightRole role;
  final Set<int> candidates;
  const _HintInfo(this.role, this.candidates);
}
