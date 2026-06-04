// One-off diagnostic: run GridDetector on a real photo pulled from the
// device and dump what it found. Run with:
//   flutter test test/grid_detector_real_image_test.dart
//
// The image path is hard-coded to a /tmp file we pull via adb. The test
// skips itself if the file doesn't exist (so CI doesn't fail on it).
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_tutor/app/grid_detector.dart';

void main() {
  test('detect on real cropped image', () async {
    const path = '/tmp/sudoku_test/new_puzzle.jpg';
    if (!File(path).existsSync()) {
      print('Skipping: no test image at $path');
      return;
    }
    final detector = GridDetector();
    final grid = await detector.detect(path);
    final img = detector.lastImage;
    print('Image size: ${img?.width}x${img?.height}');
    // Dump top-30 row-darkness peaks (index, darkness).
    final rows = detector.lastRowDarkness!;
    final indexed = List.generate(rows.length, (i) => (i, rows[i]));
    indexed.sort((a, b) => b.$2.compareTo(a.$2));
    print('Top 30 row-darkness peaks:');
    for (final (i, v) in indexed.take(30)) {
      print('  row $i: $v');
    }
    final cols = detector.lastColDarkness!;
    final cIndexed = List.generate(cols.length, (i) => (i, cols[i]));
    cIndexed.sort((a, b) => b.$2.compareTo(a.$2));
    print('Top 30 col-darkness peaks:');
    for (final (i, v) in cIndexed.take(30)) {
      print('  col $i: $v');
    }
    if (grid == null) {
      print('FAILED: grid not detected');
    } else {
      print('bestRow (start, pitch): ${detector.lastBestRow}');
      print('bestCol (start, pitch): ${detector.lastBestCol}');
      print('Detected rowYs: ${grid.rowYs.map((v) => v.toInt()).toList()}');
      print('Detected colXs: ${grid.colXs.map((v) => v.toInt()).toList()}');
      // Test cellOf mapping for a few known digit positions.
      // For this puzzle, image is 720x676. Cell pitch ~73 means cell (r,c)
      // center is at (colXs[c]+pitch/2, rowYs[r]+pitch/2).
      // Just sanity-check round-trip.
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          final (cx, cy) = grid.cellCenter(r, c);
          final (rr, cc) = grid.cellOf(cx, cy);
          if (rr != r || cc != c) {
            print('  round-trip fail at ($r,$c): got ($rr,$cc)');
          }
        }
      }
      print('Round-trip OK');
      // Expected pitch for 9 cells across height h: each spacing = (h-?)/9
      if (grid.rowYs.length == 10) {
        final pitches = <int>[];
        for (var i = 1; i < 10; i++) {
          pitches.add((grid.rowYs[i] - grid.rowYs[i - 1]).round());
        }
        print('Row pitches: $pitches');
      }
      if (grid.colXs.length == 10) {
        final pitches = <int>[];
        for (var i = 1; i < 10; i++) {
          pitches.add((grid.colXs[i] - grid.colXs[i - 1]).round());
        }
        print('Col pitches: $pitches');
      }
    }
  });
}
