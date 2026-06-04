import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Result of detecting the 10×10 grid lines in a cropped sudoku image.
class GridLines {
  /// Ten Y-coordinates of horizontal grid lines, sorted ascending.
  /// Index 0 is the top of row 0; index 9 is the bottom of row 8.
  final List<double> rowYs;

  /// Ten X-coordinates of vertical grid lines, sorted ascending.
  final List<double> colXs;

  /// Dimensions of the image the coordinates were detected against (after
  /// any internal downscaling).
  final int imageWidth;
  final int imageHeight;

  GridLines({
    required this.rowYs,
    required this.colXs,
    required this.imageWidth,
    required this.imageHeight,
  });

  /// Cell (row, col) bounding rectangle: (left, top, right, bottom).
  (double, double, double, double) cellBounds(int row, int col) {
    return (colXs[col], rowYs[row], colXs[col + 1], rowYs[row + 1]);
  }

  /// Center of cell (row, col).
  (double, double) cellCenter(int row, int col) {
    final (l, t, r, b) = cellBounds(row, col);
    return ((l + r) / 2, (t + b) / 2);
  }

  /// Assign a point (px, py) to the cell it falls inside.
  /// Returns (row, col) clamped to 0..8.
  (int, int) cellOf(double px, double py) {
    var col = 0;
    for (var i = 0; i < 9; i++) {
      if (px >= colXs[i] && px < colXs[i + 1]) {
        col = i;
        break;
      }
      if (px >= colXs[i + 1]) col = i + 1;
    }
    var row = 0;
    for (var i = 0; i < 9; i++) {
      if (py >= rowYs[i] && py < rowYs[i + 1]) {
        row = i;
        break;
      }
      if (py >= rowYs[i + 1]) row = i + 1;
    }
    return (row.clamp(0, 8), col.clamp(0, 8));
  }
}

/// Detects the 10 horizontal and 10 vertical lines of a sudoku grid by
/// projecting dark pixels along each axis and finding the 10 strongest
/// peaks. Assumes the image is roughly axis-aligned and cropped tight to
/// (or just around) the grid — both of which the scan flow enforces.
class GridDetector {
  /// Pre-decoded grayscale image used by the most recent [detect] call.
  /// Exposed so the OCR step can reuse the same downscaled bytes instead
  /// of re-decoding the file.
  img.Image? lastImage;

  /// Raw darkness projections from the most recent detect() call.
  /// Exposed for diagnostic dumps.
  List<int>? lastRowDarkness;
  List<int>? lastColDarkness;
  // (start, pitch) chosen by the brute-force search. Diagnostic.
  (int, double)? lastBestRow;
  (int, double)? lastBestCol;

  Future<GridLines?> detect(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    var image = img.decodeImage(bytes);
    if (image == null) return null;

    // Downscale so projection is cheap. 720px is plenty for grid-line
    // detection — digits will still be ~70px which ML Kit reads fine.
    const maxDim = 720;
    final big = math.max(image.width, image.height);
    if (big > maxDim) {
      final scale = maxDim / big;
      image = img.copyResize(
        image,
        width: (image.width * scale).round(),
        height: (image.height * scale).round(),
      );
    }
    lastImage = image;

    final w = image.width;
    final h = image.height;
    final lum = Uint8List(w * h);
    var i = 0;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final p = image.getPixel(x, y);
        final r = p.r.toInt();
        final g = p.g.toInt();
        final b = p.b.toInt();
        lum[i++] = ((r * 299 + g * 587 + b * 114) ~/ 1000).clamp(0, 255);
      }
    }

    // Count "non-white" pixels per row / per column using a generous
    // threshold (200/255). A grid line row hits almost every pixel
    // (~width); a digit row only hits the few pixels covered by the
    // strokes (~5 digits × ~15 px = ~75). The wide margin between those
    // two regimes is what makes line detection robust even when the
    // grid is pale gray and the digits are jet-black ink — both pass
    // the threshold, but the line's per-row count dwarfs the digit
    // row's. Integral-darkness projection was tried first but proved
    // brittle because the bottom half of a typical puzzle has more
    // digits, biasing it toward digit rows over grid-line rows.
    const inkThreshold = 200;
    final rowDark = List<int>.filled(h, 0);
    final colDark = List<int>.filled(w, 0);
    var k = 0;
    for (var y = 0; y < h; y++) {
      var rowCount = 0;
      for (var x = 0; x < w; x++) {
        if (lum[k++] < inkThreshold) {
          rowCount++;
          colDark[x]++;
        }
      }
      rowDark[y] = rowCount;
    }

    lastRowDarkness = rowDark;
    lastColDarkness = colDark;

    final rowPeaks = _findGridLines(rowDark, length: h, debugLabel: 'row');
    final colPeaks = _findGridLines(colDark, length: w, debugLabel: 'col');

    if (rowPeaks.length != 10 || colPeaks.length != 10) {
      return null;
    }

    return GridLines(
      rowYs: rowPeaks.map((p) => p.toDouble()).toList(),
      colXs: colPeaks.map((p) => p.toDouble()).toList(),
      imageWidth: w,
      imageHeight: h,
    );
  }

  /// Pick the 10 grid-line positions from a 1-D darkness projection.
  ///
  /// We don't rely on independent peak picking — too brittle when some
  /// lines are pale and some box-boundary lines saturate the projection.
  /// Instead, we brute-force search over (start, pitch) for the
  /// arrangement of 10 evenly-spaced lines whose total projection
  /// response is maximised. This bakes the prior knowledge "lines are
  /// uniformly spaced" into the detector, and a couple of strong inner
  /// peaks are enough to lock the rest of the grid in place.
  ///
  /// After finding the best (start, pitch), each individual line is
  /// snapped to the nearest local maximum within ±pitch/6 to absorb any
  /// small mis-alignment from perspective.
  List<int> _findGridLines(List<int> projection,
      {required int length, String debugLabel = ''}) {
    final smooth = _smooth(projection, window: 5);
    // Grid pitch (distance between consecutive lines) is length/9 for a
    // tight crop, but could be a bit smaller if there's padding, or a bit
    // larger if the crop chopped slightly into the grid. Search a wide
    // range so we don't miss the optimum.
    final minPitch = length / 11.0;
    final maxPitch = length / 7.5;
    // The first line can start anywhere from the very top to ~25% in.
    final maxStart = (length * 0.25).round();

    var bestSum = -1;
    var bestStart = 0;
    var bestPitch = length / 9.0;

    for (var start = 0; start <= maxStart; start += 2) {
      for (var pitchTimes2 = (minPitch * 2).round();
          pitchTimes2 <= (maxPitch * 2).round();
          pitchTimes2++) {
        final pitch = pitchTimes2 / 2.0;
        if ((start + 9 * pitch).round() >= length) break;
        var sum = 0;
        for (var i = 0; i <= 9; i++) {
          final pos = (start + i * pitch).round();
          if (pos >= smooth.length) break;
          sum += smooth[pos];
        }
        if (sum > bestSum) {
          bestSum = sum;
          bestStart = start;
          bestPitch = pitch;
        }
      }
    }

    if (debugLabel == 'row') lastBestRow = (bestStart, bestPitch);
    if (debugLabel == 'col') lastBestCol = (bestStart, bestPitch);

    // Trust the uniform spacing the brute-force just found. Per-line
    // refinement was tried first but consistently dragged outer lines
    // into nearby digit-dense rows when the projection had a strong
    // digit-row spike near the predicted grid-line position. A small
    // refinement (±2px) is fine to absorb sub-pixel quantisation,
    // anything larger amplifies the noise.
    const refineRadius = 2;
    final lines = <int>[];
    for (var i = 0; i <= 9; i++) {
      final predicted = (bestStart + i * bestPitch).round().clamp(0, smooth.length - 1);
      var bestI = predicted;
      var bestV = smooth[predicted];
      for (var d = -refineRadius; d <= refineRadius; d++) {
        final pos = predicted + d;
        if (pos < 0 || pos >= smooth.length) continue;
        if (smooth[pos] > bestV) {
          bestV = smooth[pos];
          bestI = pos;
        }
      }
      lines.add(bestI);
    }
    return lines;
  }

  List<int> _smooth(List<int> data, {required int window}) {
    final out = List<int>.filled(data.length, 0);
    final half = window ~/ 2;
    for (var i = 0; i < data.length; i++) {
      var s = 0;
      var n = 0;
      for (var j = i - half; j <= i + half; j++) {
        if (j >= 0 && j < data.length) {
          s += data[j];
          n++;
        }
      }
      out[i] = s ~/ n;
    }
    return out;
  }
}
