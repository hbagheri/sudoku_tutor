import 'dart:math' as math;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Recognizes digits from a Sudoku photograph by running ML Kit on the
/// whole image and clustering the result into a 9×9 grid.
///
/// We do NOT try to crop/deskew the grid first — for typical newspaper
/// or magazine photos the digits are already legible, and ML Kit returns
/// a bounding box for each. Once we have the boxes, we cluster their
/// centroids into 9 rows and 9 columns based on horizontal and vertical
/// position.
class OcrService {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  Future<OcrResult> recognizeSudoku(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final result = await _recognizer.processImage(input);
    final digits = _collectDigitElements(result);
    if (digits.length < 17) {
      // 17 is the theoretical minimum number of clues for a unique Sudoku.
      return OcrResult.failure(
        reason: 'Not enough digits detected (got ${digits.length})',
        rawDigits: digits.length,
      );
    }
    return _clusterIntoGrid(digits);
  }

  /// Turn ML Kit's nested Text / Block / Line / Element structure into a
  /// flat list of single-digit elements with their centers.
  List<_Digit> _collectDigitElements(RecognizedText text) {
    final out = <_Digit>[];
    for (final block in text.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          final raw = element.text.trim();
          if (raw.isEmpty) continue;
          // ML Kit sometimes joins adjacent digits into a single element
          // (e.g. "73" for two adjacent givens). Split per-character.
          for (var i = 0; i < raw.length; i++) {
            final ch = raw[i];
            final d = int.tryParse(ch);
            if (d == null || d < 1 || d > 9) continue;
            final box = element.boundingBox;
            // Approximate the per-character bounding box by slicing along
            // the element's width.
            final slice = box.width / raw.length;
            final left = box.left + slice * i;
            final right = left + slice;
            out.add(_Digit(
              value: d,
              cx: (left + right) / 2,
              cy: (box.top + box.bottom) / 2,
            ));
          }
        }
      }
    }
    return out;
  }

  /// Sort the digits' centers into 9 rows and 9 columns, then place each
  /// digit at its (row, col) coordinate. Returns 81-cell array of digits
  /// (0 for empty cells).
  OcrResult _clusterIntoGrid(List<_Digit> digits) {
    final rowBands = _kmeansLike(digits.map((d) => d.cy).toList());
    final colBands = _kmeansLike(digits.map((d) => d.cx).toList());
    if (rowBands.length != 9 || colBands.length != 9) {
      return OcrResult.failure(
        reason: 'Grid clustering failed '
            '(${rowBands.length} rows, ${colBands.length} cols)',
        rawDigits: digits.length,
      );
    }

    final cells = List<int>.filled(81, 0);
    for (final d in digits) {
      final r = _closestIndex(rowBands, d.cy);
      final c = _closestIndex(colBands, d.cx);
      final idx = r * 9 + c;
      if (cells[idx] == 0) {
        cells[idx] = d.value;
      }
    }

    final placed = cells.where((v) => v != 0).length;
    if (placed < 17) {
      return OcrResult.failure(
        reason: 'Only $placed cells were resolved',
        rawDigits: digits.length,
      );
    }

    return OcrResult.success(values: cells, rawDigits: digits.length);
  }

  /// Simple 1D clustering: sort the values, then greedily merge adjacent
  /// ones whose gap is smaller than `medianGap × 0.5`. Returns the
  /// cluster centers in increasing order.
  ///
  /// This is a far simpler-than-k-means approach that works well for
  /// Sudoku layouts where row/column centers are roughly uniformly spaced.
  List<double> _kmeansLike(List<double> raw) {
    if (raw.isEmpty) return [];
    final sorted = [...raw]..sort();
    // Gather initial micro-clusters by tight merging.
    final clusters = <List<double>>[[sorted.first]];
    for (var i = 1; i < sorted.length; i++) {
      final last = clusters.last.last;
      // Use a small gap (~6 px) for the first pass.
      if (sorted[i] - last < 12) {
        clusters.last.add(sorted[i]);
      } else {
        clusters.add([sorted[i]]);
      }
    }
    if (clusters.length < 9) return clusters.map(_avg).toList();

    // We want exactly 9 clusters. If we have more, merge the closest pair
    // repeatedly until we're at 9.
    final centers = clusters.map(_avg).toList();
    final counts = clusters.map((c) => c.length).toList();
    while (centers.length > 9) {
      var bestI = 0;
      var bestGap = double.infinity;
      for (var i = 0; i < centers.length - 1; i++) {
        final gap = centers[i + 1] - centers[i];
        if (gap < bestGap) {
          bestGap = gap;
          bestI = i;
        }
      }
      // Merge bestI and bestI+1 (weighted).
      final cA = centers[bestI];
      final cB = centers[bestI + 1];
      final nA = counts[bestI];
      final nB = counts[bestI + 1];
      final merged = (cA * nA + cB * nB) / (nA + nB);
      centers[bestI] = merged;
      counts[bestI] = nA + nB;
      centers.removeAt(bestI + 1);
      counts.removeAt(bestI + 1);
    }
    return centers;
  }

  double _avg(List<double> xs) =>
      xs.fold(0.0, (a, b) => a + b) / xs.length;

  int _closestIndex(List<double> centers, double value) {
    var best = 0;
    var bestD = double.infinity;
    for (var i = 0; i < centers.length; i++) {
      final d = (centers[i] - value).abs();
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  /// Free native resources held by the ML Kit recognizer.
  Future<void> dispose() async {
    await _recognizer.close();
  }
}

class _Digit {
  final int value;
  final double cx;
  final double cy;
  const _Digit({required this.value, required this.cx, required this.cy});
}

/// Result of running OCR on a Sudoku image.
class OcrResult {
  final bool success;
  final String? failureReason;
  final List<int>? values;
  final int rawDigits;

  const OcrResult._({
    required this.success,
    this.failureReason,
    this.values,
    required this.rawDigits,
  });

  factory OcrResult.success({
    required List<int> values,
    required int rawDigits,
  }) {
    assert(values.length == 81);
    return OcrResult._(success: true, values: values, rawDigits: rawDigits);
  }

  factory OcrResult.failure({
    required String reason,
    required int rawDigits,
  }) =>
      OcrResult._(success: false, failureReason: reason, rawDigits: rawDigits);

  int get clueCount =>
      values?.where((v) => v != 0).length ?? 0;
}

// Unused right now, but kept handy for diagnostic dumps.
// ignore: unused_element
double _hypot(double a, double b) => math.sqrt(a * a + b * b);
