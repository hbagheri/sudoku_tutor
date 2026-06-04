// Diagnostic: draw the detected grid on the test image and write it to
// /tmp/sudoku_test/visualized.png so we can eyeball the alignment.
// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:sudoku_tutor/app/grid_detector.dart';

void main() {
  test('visualize detected grid', () async {
    const inPath = '/tmp/sudoku_test/new_puzzle.jpg';
    const outPath = '/tmp/sudoku_test/visualized.png';
    if (!File(inPath).existsSync()) {
      print('Skipping: no test image at $inPath');
      return;
    }
    final detector = GridDetector();
    final grid = await detector.detect(inPath);
    if (grid == null) {
      print('FAILED: no grid detected');
      return;
    }
    // Re-decode at full size for the visualization.
    final base = detector.lastImage!;
    // Draw lines: red for inner, green for 3-box boundaries.
    final red = img.ColorRgb8(255, 0, 0);
    final green = img.ColorRgb8(0, 200, 0);
    final blue = img.ColorRgb8(0, 100, 255);

    for (var i = 0; i < grid.rowYs.length; i++) {
      final y = grid.rowYs[i].round();
      final color = i % 3 == 0 ? green : red;
      img.drawLine(base,
          x1: 0, y1: y, x2: base.width - 1, y2: y, color: color, thickness: 2);
    }
    for (var i = 0; i < grid.colXs.length; i++) {
      final x = grid.colXs[i].round();
      final color = i % 3 == 0 ? green : red;
      img.drawLine(base,
          x1: x, y1: 0, x2: x, y2: base.height - 1, color: color, thickness: 2);
    }
    // Mark cell centers with small blue circles.
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final (cx, cy) = grid.cellCenter(r, c);
        img.drawCircle(base,
            x: cx.round(),
            y: cy.round(),
            radius: 3,
            color: blue);
      }
    }
    File(outPath).writeAsBytesSync(img.encodePng(base));
    print('Wrote $outPath');
  });
}
