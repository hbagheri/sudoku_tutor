import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../app/settings.dart';
import '../app/strings.dart';
import 'scan_review_screen.dart';

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
  bool _busy = false;
  String? _busyLabel;
  String? _errorText;
  File? _previewImage;

  Future<void> _pick({required ImageSource source}) async {
    setState(() {
      _busy = true;
      _busyLabel = context.strings.recognizing;
      _errorText = null;
    });
    try {
      final picked = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
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
      final s = context.strings;
      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: s.cropPuzzle,
            // Don't lock — many phones photograph a sudoku at an angle, and
            // a fixed square forces the user to drag the photo behind a
            // stationary frame instead of just framing the grid.
            lockAspectRatio: false,
            initAspectRatio: CropAspectRatioPreset.square,
            hideBottomControls: false,
          ),
        ],
      );
      if (cropped == null) {
        if (!mounted) return;
        setState(() => _busy = false);
        return;
      }
      if (!mounted) return;
      setState(() {
        _previewImage = File(cropped.path);
        _busy = false;
      });
      // Hand off to the review screen, which walks the user through grid
      // detection and OCR stage-by-stage and lets them confirm.
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ScanReviewScreen(
          settings: widget.settings,
          imagePath: cropped.path,
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
