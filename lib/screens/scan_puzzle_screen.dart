import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/ocr_service.dart';
import '../app/settings.dart';
import '../app/strings.dart';
import 'custom_puzzle_screen.dart';

/// Lets the user pick a photo (or open the camera) and runs ML Kit on it
/// to recognise the Sudoku digits, then hands the result off to the
/// CustomPuzzleScreen — pre-filled — so they can fix any misreads.
class ScanPuzzleScreen extends StatefulWidget {
  final AppSettings settings;
  const ScanPuzzleScreen({required this.settings, super.key});

  @override
  State<ScanPuzzleScreen> createState() => _ScanPuzzleScreenState();
}

class _ScanPuzzleScreenState extends State<ScanPuzzleScreen> {
  final _picker = ImagePicker();
  final _ocr = OcrService();
  bool _busy = false;
  String? _busyLabel;
  String? _errorText;
  File? _previewImage;

  @override
  void dispose() {
    _ocr.dispose();
    super.dispose();
  }

  Future<void> _pick({required ImageSource source}) async {
    setState(() {
      _busy = true;
      _busyLabel = context.strings.recognizing;
      _errorText = null;
    });
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 92,
      );
      if (picked == null) {
        if (!mounted) return;
        setState(() => _busy = false);
        return;
      }
      if (!mounted) return;
      setState(() => _previewImage = File(picked.path));
      final result = await _ocr.recognizeSudoku(picked.path);
      if (!mounted) return;
      if (!result.success) {
        setState(() {
          _busy = false;
          _errorText =
              '${context.strings.ocrFailed}: ${result.failureReason}';
        });
        return;
      }
      final values = result.values!;
      // Always send the user to the custom puzzle screen so they can verify
      // and patch anything that came out wrong.
      await Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => CustomPuzzleScreen(
          settings: widget.settings,
          initialValues: values,
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorText = '${context.strings.ocrFailed}: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.scanPuzzle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.document_scanner_outlined,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.scanIntro,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (_previewImage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _previewImage!,
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  if (_busy)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 8),
                          if (_busyLabel != null) Text(_busyLabel!),
                        ],
                      ),
                    )
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.camera_alt_outlined),
                        onPressed: () => _pick(source: ImageSource.camera),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(s.takePhoto),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.photo_library_outlined),
                        onPressed: () => _pick(source: ImageSource.gallery),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(s.pickFromGallery),
                        ),
                      ),
                    ),
                  ],
                  if (_errorText != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorText!,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    s.reviewBeforeStart,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
