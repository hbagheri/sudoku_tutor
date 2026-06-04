import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'grid_detector.dart';

/// Recognizes digits from a Sudoku photograph using ML Kit.
///
/// Two modes:
///  * [recognizeSudoku] — runs OCR on the whole image and clusters the
///    detected digits into a 9×9 grid using their bounding-box extent.
///    Used when grid-line detection didn't work.
///  * [recognizeWithGrid] — uses pre-detected [GridLines] to assign each
///    detected digit to the cell it physically falls inside, which is
///    far more robust than clustering on sparse rows.
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

  /// Runs OCR on [imagePath] and uses [grid] to place each digit into the
  /// cell whose bounds enclose the digit's centroid. [grid] must be
  /// detected against a downscaled copy of the same image (the same one
  /// [GridDetector] worked on); we rescale OCR centroids to match.
  ///
  /// Returns the recognised digits as a list of detections so the preview
  /// screen can draw them at their true positions.
  Future<GridOcrResult> recognizeWithGrid({
    required String imagePath,
    required GridLines grid,
    required int sourceImageWidth,
    required int sourceImageHeight,
  }) async {
    final input = InputImage.fromFilePath(imagePath);
    final result = await _recognizer.processImage(input);
    final digits = _collectDigitElements(result);

    // ML Kit's coordinates are in the source image's resolution. Convert
    // them to the grid's downscaled coordinate space.
    final sx = grid.imageWidth / sourceImageWidth;
    final sy = grid.imageHeight / sourceImageHeight;

    final cells = List<int>.filled(81, 0);
    final placed = <PlacedDigit>[];
    for (final d in digits) {
      final px = d.cx * sx;
      final py = d.cy * sy;
      final (r, c) = grid.cellOf(px, py);
      final idx = r * 9 + c;
      if (cells[idx] == 0) {
        cells[idx] = d.value;
        placed.add(PlacedDigit(row: r, col: c, value: d.value, cx: px, cy: py));
      }
    }
    return GridOcrResult(
      values: cells,
      rawDigits: digits.length,
      placedDigits: placed,
    );
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

  /// Place each detected digit at its (row, col) using the bounding box of
  /// all digits as the grid extent. This is robust to:
  ///   * the user leaving padding around the grid when cropping, and
  ///   * sparse rows/columns (a tight pitch derived from real digits
  ///     beats greedy clustering that can collapse sparse outer rows
  ///     into their neighbours).
  ///
  /// The only assumption is that at least one digit appears in the top
  /// row, the bottom row, the leftmost column, and the rightmost column
  /// — which is almost always true for printed sudoku (puzzles typically
  /// have 25–30 clues spread across the whole grid).
  OcrResult _clusterIntoGrid(List<_Digit> digits) {
    if (digits.length < 17) {
      return OcrResult.failure(
        reason: 'Not enough digits (${digits.length})',
        rawDigits: digits.length,
      );
    }
    var minX = digits.first.cx, maxX = digits.first.cx;
    var minY = digits.first.cy, maxY = digits.first.cy;
    for (final d in digits) {
      if (d.cx < minX) minX = d.cx;
      if (d.cx > maxX) maxX = d.cx;
      if (d.cy < minY) minY = d.cy;
      if (d.cy > maxY) maxY = d.cy;
    }
    // 9 rows → 8 pitches between row centres (and same for cols).
    final pitchY = (maxY - minY) / 8.0;
    final pitchX = (maxX - minX) / 8.0;
    if (pitchY <= 0 || pitchX <= 0) {
      return OcrResult.failure(
        reason: 'Digits not spread across the grid',
        rawDigits: digits.length,
      );
    }

    final cells = List<int>.filled(81, 0);
    for (final d in digits) {
      final r = ((d.cy - minY) / pitchY).round().clamp(0, 8);
      final c = ((d.cx - minX) / pitchX).round().clamp(0, 8);
      final idx = r * 9 + c;
      // Keep the first reading per cell — duplicates here usually mean
      // ML Kit returned the same digit twice with slightly shifted boxes.
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

/// A single digit detection with its position in grid-coordinate space
/// (matching [GridLines.imageWidth]/[GridLines.imageHeight]).
class PlacedDigit {
  final int row;
  final int col;
  final int value;
  final double cx;
  final double cy;
  const PlacedDigit({
    required this.row,
    required this.col,
    required this.value,
    required this.cx,
    required this.cy,
  });
}

/// Result of OCR + grid-aware cell assignment.
class GridOcrResult {
  /// 81 digits (0 = empty cell), row-major.
  final List<int> values;

  /// How many raw digit elements ML Kit produced (diagnostic).
  final int rawDigits;

  /// Where each retained digit was placed, in grid-coordinate space.
  /// Used by the preview screen to draw markers on top of the photo.
  final List<PlacedDigit> placedDigits;

  const GridOcrResult({
    required this.values,
    required this.rawDigits,
    required this.placedDigits,
  });

  int get clueCount => values.where((v) => v != 0).length;
}
