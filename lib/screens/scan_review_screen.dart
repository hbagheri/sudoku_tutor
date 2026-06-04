import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../app/grid_detector.dart';
import '../app/ocr_service.dart';
import '../app/settings.dart';
import '../app/strings.dart';
import 'custom_puzzle_screen.dart';

/// Walks the user through what the scanner saw on their photo, stage by
/// stage: horizontal grid lines → vertical grid lines → recognised
/// digits. Once OCR is done, the user can tap any cell on the photo to
/// add a missed digit or fix a misread one, then confirm.
class ScanReviewScreen extends StatefulWidget {
  final AppSettings settings;
  final String imagePath;
  const ScanReviewScreen({
    required this.settings,
    required this.imagePath,
    super.key,
  });

  @override
  State<ScanReviewScreen> createState() => _ScanReviewScreenState();
}

enum _Stage { loading, horizontalLines, verticalLines, digits, done, failed }

class _ScanReviewScreenState extends State<ScanReviewScreen> {
  final _detector = GridDetector();
  final _ocr = OcrService();

  _Stage _stage = _Stage.loading;
  GridLines? _grid;
  String? _failureReason;

  /// Mutable 81-cell grid. Seeded from OCR, then edited by the user.
  /// We replace the whole list on every edit so the CustomPaint's
  /// shouldRepaint can use reference equality to know when to redraw.
  List<int> _values = List<int>.filled(81, 0);

  int? _selRow;
  int? _selCol;

  int? _srcWidth;
  int? _srcHeight;

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    _ocr.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    try {
      final intrinsic = await _readIntrinsicSize(widget.imagePath);
      if (!mounted) return;
      _srcWidth = intrinsic.$1;
      _srcHeight = intrinsic.$2;

      final grid = await _detector.detect(widget.imagePath);
      if (!mounted) return;
      if (grid == null) {
        setState(() {
          _stage = _Stage.failed;
          _failureReason = context.strings.gridDetectionFailed;
        });
        return;
      }
      _grid = grid;

      setState(() => _stage = _Stage.horizontalLines);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      setState(() => _stage = _Stage.verticalLines);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      final ocr = await _ocr.recognizeWithGrid(
        imagePath: widget.imagePath,
        grid: grid,
        sourceImageWidth: _srcWidth!,
        sourceImageHeight: _srcHeight!,
      );
      if (!mounted) return;
      // Seed the editable grid from OCR.
      _values = List<int>.from(ocr.values);

      setState(() => _stage = _Stage.digits);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _stage = _Stage.done);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.failed;
        _failureReason = e.toString();
      });
    }
  }

  Future<(int, int)> _readIntrinsicSize(String path) async {
    final completer = Completer<(int, int)>();
    final stream = Image.file(File(path)).image.resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      stream.removeListener(listener);
      completer.complete((info.image.width, info.image.height));
    }, onError: (e, _) {
      stream.removeListener(listener);
      completer.completeError(e);
    });
    stream.addListener(listener);
    return completer.future;
  }

  void _tapAt(Offset localPos, Size widgetSize) {
    final grid = _grid;
    if (grid == null) return;
    if (_stage != _Stage.done && _stage != _Stage.digits) return;
    final gx = localPos.dx / widgetSize.width * grid.imageWidth;
    final gy = localPos.dy / widgetSize.height * grid.imageHeight;
    final (r, c) = grid.cellOf(gx, gy);
    setState(() {
      _selRow = r;
      _selCol = c;
    });
  }

  void _setDigit(int d) {
    final r = _selRow;
    final c = _selCol;
    if (r == null || c == null) return;
    setState(() {
      _values = List<int>.from(_values)..[r * 9 + c] = d;
    });
  }

  void _erase() {
    final r = _selRow;
    final c = _selCol;
    if (r == null || c == null) return;
    setState(() {
      _values = List<int>.from(_values)..[r * 9 + c] = 0;
    });
  }

  void _confirm() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => CustomPuzzleScreen(
        settings: widget.settings,
        initialValues: List<int>.from(_values),
      ),
    ));
  }

  int get _clueCount => _values.where((v) => v != 0).length;

  String _stageLabel(Strings s) {
    switch (_stage) {
      case _Stage.loading:
        return s.recognizing;
      case _Stage.horizontalLines:
        return s.detectingHorizontalLines;
      case _Stage.verticalLines:
        return s.detectingVerticalLines;
      case _Stage.digits:
      case _Stage.done:
        return s.recognizingDigits;
      case _Stage.failed:
        return _failureReason ?? s.ocrFailed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final theme = Theme.of(context);
    final aspect = (_srcWidth != null && _srcHeight != null)
        ? _srcWidth! / _srcHeight!
        : 1.0;

    return Scaffold(
      appBar: AppBar(title: Text(s.scanPuzzle)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (_stage != _Stage.done && _stage != _Stage.failed)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (_stage == _Stage.done)
                    Icon(Icons.check_circle,
                        color: theme.colorScheme.primary, size: 18)
                  else
                    Icon(Icons.error_outline,
                        color: theme.colorScheme.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _stage == _Stage.done
                          ? '$_clueCount ${s.cluesFound} · ${s.tapCellToEdit}'
                          : _stageLabel(s),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: AspectRatio(
                    aspectRatio: aspect,
                    child: LayoutBuilder(builder: (context, constraints) {
                      final size =
                          Size(constraints.maxWidth, constraints.maxHeight);
                      return GestureDetector(
                        onTapDown: (details) =>
                            _tapAt(details.localPosition, size),
                        behavior: HitTestBehavior.opaque,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(widget.imagePath),
                              fit: BoxFit.contain,
                            ),
                            if (_grid != null)
                              CustomPaint(
                                painter: _GridOverlayPainter(
                                  grid: _grid!,
                                  stage: _stage,
                                  values: _values,
                                  selectedRow: _selRow,
                                  selectedCol: _selCol,
                                  outlineColor: theme.colorScheme.primary,
                                  accentColor: theme.colorScheme.tertiary,
                                  digitColor: theme.colorScheme.onPrimary,
                                  digitBgColor: theme.colorScheme.primary,
                                  selectionColor:
                                      theme.colorScheme.secondary,
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
            if (_stage == _Stage.done) ...[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: _Pad(
                  enabled: _selRow != null,
                  onDigit: _setDigit,
                  onErase: _erase,
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => Navigator.of(context).pop(),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(s.retake),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check),
                      onPressed: _stage == _Stage.done ? _confirm : null,
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(s.useThis),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pad extends StatelessWidget {
  final bool enabled;
  final void Function(int) onDigit;
  final VoidCallback onErase;
  const _Pad({
    required this.enabled,
    required this.onDigit,
    required this.onErase,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        for (var d = 1; d <= 9; d++)
          SizedBox(
            width: 42,
            height: 44,
            child: FilledButton.tonal(
              style: FilledButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: enabled ? () => onDigit(d) : null,
              child: Text(
                '$d',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        SizedBox(
          width: 50,
          height: 44,
          child: IconButton.filledTonal(
            onPressed: enabled ? onErase : null,
            icon: const Icon(Icons.backspace_outlined),
          ),
        ),
      ],
    );
  }
}

class _GridOverlayPainter extends CustomPainter {
  final GridLines grid;
  final _Stage stage;
  final List<int> values;
  final int? selectedRow;
  final int? selectedCol;
  final Color outlineColor;
  final Color accentColor;
  final Color digitColor;
  final Color digitBgColor;
  final Color selectionColor;

  _GridOverlayPainter({
    required this.grid,
    required this.stage,
    required this.values,
    required this.selectedRow,
    required this.selectedCol,
    required this.outlineColor,
    required this.accentColor,
    required this.digitColor,
    required this.digitBgColor,
    required this.selectionColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / grid.imageWidth;
    final sy = size.height / grid.imageHeight;

    final linePaint = Paint()
      ..color = outlineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final accentPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final showH = stage != _Stage.loading && stage != _Stage.failed;
    final showV = stage == _Stage.verticalLines ||
        stage == _Stage.digits ||
        stage == _Stage.done;
    final showDigits = stage == _Stage.digits || stage == _Stage.done;

    // Highlight the selected cell first so lines and digits draw on top.
    if (selectedRow != null && selectedCol != null && showDigits) {
      final r = selectedRow!;
      final c = selectedCol!;
      final (l, t, ri, b) = grid.cellBounds(r, c);
      final rect = Rect.fromLTRB(l * sx, t * sy, ri * sx, b * sy);
      final fill = Paint()
        ..color = selectionColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;
      final stroke = Paint()
        ..color = selectionColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawRect(rect, fill);
      canvas.drawRect(rect, stroke);
    }

    if (showH) {
      for (var i = 0; i < grid.rowYs.length; i++) {
        final y = grid.rowYs[i] * sy;
        final isBox = i % 3 == 0;
        canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          isBox ? accentPaint : linePaint,
        );
      }
    }
    if (showV) {
      for (var i = 0; i < grid.colXs.length; i++) {
        final x = grid.colXs[i] * sx;
        final isBox = i % 3 == 0;
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height),
          isBox ? accentPaint : linePaint,
        );
      }
    }
    if (showDigits) {
      final cellW = (grid.imageWidth / 9.0) * sx;
      final fontSize = cellW * 0.55;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          final v = values[r * 9 + c];
          if (v == 0) continue;
          final (cx, cy) = grid.cellCenter(r, c);
          final tp = TextPainter(
            text: TextSpan(
              text: '$v',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: digitColor,
                backgroundColor: digitBgColor.withValues(alpha: 0.85),
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          tp.layout();
          tp.paint(
            canvas,
            Offset(cx * sx - tp.width / 2, cy * sy - tp.height / 2),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridOverlayPainter old) {
    return old.stage != stage ||
        old.grid != grid ||
        old.values != values ||
        old.selectedRow != selectedRow ||
        old.selectedCol != selectedCol;
  }
}
