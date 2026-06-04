import 'package:flutter/material.dart';

import '../sudoku_engine.dart';
import 'cell_view.dart';

/// A read-only 9×9 board renderer. Same look as `SudokuBoardView` but takes
/// a [Board] + optional [Hint] directly, with no GameController, so it can
/// be used in the tutorial / examples screen.
class StaticBoardView extends StatelessWidget {
  final Board board;
  final Hint? hint;
  final double maxWidth;

  const StaticBoardView({
    required this.board,
    this.hint,
    this.maxWidth = 360,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hintMap = <_RC, _HintInfo>{};
    if (hint != null) {
      for (final hl in hint!.highlights) {
        hintMap[_RC(hl.row, hl.col)] = _HintInfo(hl.role, hl.candidates);
      }
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: AspectRatio(
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
                            child: _row(
                              row: bandRow * 3 + rOff,
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
      ),
    );
  }

  Widget _row({
    required int row,
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
                      child: _cell(row, bandCol * 3 + cOff, hintMap),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _cell(int row, int col, Map<_RC, _HintInfo> hintMap) {
    final cell = board.at(row, col);
    final info = hintMap[_RC(row, col)];
    return CellView(
      cell: cell,
      isSelected: false,
      isPeer: false,
      hasSameValueAsSelected: false,
      isError: false,
      hintRole: info?.role,
      hintCandidates: info?.candidates ?? const <int>{},
      onTap: () {},
    );
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
