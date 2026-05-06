import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/ingredient.dart';
import '../../data/services/ingredient_recognizer.dart';
import '../../providers/fridge_provider.dart';
import '../../widgets/animated_blob.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/ingredient_chip.dart';
import '../../widgets/primary_button.dart';

/// AI fridge scan. Capture (or pick) a real photo, send it through an
/// [IngredientRecognizer], and let the user confirm what gets added to
/// inventory. Falls back to a mock recognizer when no API key is configured.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

enum _ScanPhase { idle, hasPhoto, scanning, results, error }

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  final ImagePicker _picker = ImagePicker();

  Uint8List? _photoBytes;
  String? _photoPath; // for preview when we have a File path
  List<Ingredient> _detected = [];
  final Set<String> _accepted = {};
  String? _errorMessage;

  _ScanPhase _phase = _ScanPhase.idle;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Image acquisition ────────────────────────────────────────────────────

  Future<void> _pickFrom(ImageSource source) async {
    if (_phase == _ScanPhase.scanning) return;

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        // Compress to keep upload small + within Vision API limits.
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 88,
      );
      if (picked == null) return; // user cancelled

      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      setState(() {
        _photoBytes = bytes;
        _photoPath = picked.path;
        _detected = [];
        _accepted.clear();
        _errorMessage = null;
        _phase = _ScanPhase.hasPhoto;
      });

      // Auto-run scan as soon as the photo is captured.
      await _runScan();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not open the camera/library: $e';
        _phase = _ScanPhase.error;
      });
    }
  }

  // ── AI detection ─────────────────────────────────────────────────────────

  Future<void> _runScan() async {
    if (_photoBytes == null) return;
    if (_phase == _ScanPhase.scanning) return;

    setState(() {
      _phase = _ScanPhase.scanning;
      _errorMessage = null;
      _detected = [];
      _accepted.clear();
    });

    final recognizer = context.read<IngredientRecognizer>();
    final fridge = context.read<FridgeProvider>();

    try {
      final result = await recognizer.detect(
        imageBytes: _photoBytes,
        excludeIds: fridge.inventoryIds,
      );

      if (!mounted) return;

      setState(() {
        _detected = result;
        _accepted
          ..clear()
          ..addAll(result.map((e) => e.id));
        _phase = result.isEmpty ? _ScanPhase.error : _ScanPhase.results;
        if (result.isEmpty) {
          _errorMessage =
              'I couldn\'t spot anything in that photo. Try better light or a closer shot.';
        }
      });
    } on RecognizerException catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _ScanPhase.error;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _ScanPhase.error;
        _errorMessage = 'Something went wrong: $e';
      });
    }
  }

  // ── User actions ─────────────────────────────────────────────────────────

  void _toggleAccept(String id) {
    setState(() {
      if (_accepted.contains(id)) {
        _accepted.remove(id);
      } else {
        _accepted.add(id);
      }
    });
  }

  void _confirm() {
    if (_accepted.isEmpty) return;
    final addedCount = _accepted.length;
    context.read<FridgeProvider>().addManyToInventory(_accepted);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Added $addedCount ${addedCount == 1 ? "item" : "items"} to your fridge',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop();
  }

  void _retake() {
    setState(() {
      _photoBytes = null;
      _photoPath = null;
      _detected = [];
      _accepted.clear();
      _errorMessage = null;
      _phase = _ScanPhase.idle;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final recognizer = context.read<IngredientRecognizer>();
    final hasResults = _phase == _ScanPhase.results && _detected.isNotEmpty;
    final hasPhoto = _photoBytes != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('AI fridge scan'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: recognizer.isReal
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    recognizer.isReal
                        ? Icons.bolt_rounded
                        : Icons.science_rounded,
                    size: 13,
                    color: recognizer.isReal
                        ? AppColors.primaryDark
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    recognizer.isReal ? 'AI Vision' : 'Demo',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: recognizer.isReal
                          ? AppColors.primaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned(
            top: -100,
            right: -80,
            child: AnimatedBlob(
              size: 280,
              colors: [AppColors.primarySurface, AppColors.background],
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageHPadding,
                      AppSpacing.lg,
                      AppSpacing.pageHPadding,
                      AppSpacing.lg,
                    ),
                    children: [
                      Text(
                        hasPhoto
                            ? 'Here\'s your fridge.\nLet me see what\'s inside.'
                            : 'Snap your fridge.\nI\'ll spot what\'s inside.',
                        style: context.text.displaySmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        recognizer.isReal
                            ? 'Powered by GPT-4 Vision.'
                            : 'Demo mode — set OPENAI_API_KEY to enable real AI.',
                        style: context.text.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // ── Viewport: photo if we have one, else placeholder
                      AspectRatio(
                        aspectRatio: 1.1,
                        child: AnimatedBuilder(
                          animation: _ctrl,
                          builder: (_, __) => _ScanViewport(
                            phase: _phase,
                            photoBytes: _photoBytes,
                            photoPath: _photoPath,
                            progress: _ctrl.value,
                            statusText: _statusLine(recognizer.isReal),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // ── Source picker (only before a photo is taken)
                      if (!hasPhoto && _phase != _ScanPhase.scanning) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _SourceCard(
                                icon: Icons.camera_alt_rounded,
                                label: 'Take photo',
                                subtitle: 'Open camera',
                                onTap: () => _pickFrom(ImageSource.camera),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SourceCard(
                                icon: Icons.photo_library_rounded,
                                label: 'From library',
                                subtitle: 'Pick a saved photo',
                                onTap: () => _pickFrom(ImageSource.gallery),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // ── Error banner
                      if (_phase == _ScanPhase.error &&
                          _errorMessage != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.tomatoSurface,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            border:
                                Border.all(color: AppColors.tomato.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: AppColors.tomato, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── Detected items
                      if (hasResults)
                        GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Detected items',
                                      style: context.text.titleLarge,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _retake,
                                    icon: const Icon(Icons.refresh_rounded,
                                        size: 18),
                                    label: const Text('Retake'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap any item to toggle whether it goes into your fridge.',
                                style: context.text.bodyMedium,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _detected
                                    .map(
                                      (ing) => IngredientChip(
                                        ingredient: ing,
                                        selected: _accepted.contains(ing.id),
                                        onTap: () => _toggleAccept(ing.id),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Bottom CTA, contextual
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageHPadding,
                    8,
                    AppSpacing.pageHPadding,
                    AppSpacing.lg,
                  ),
                  child: _bottomCta(hasResults: hasResults, hasPhoto: hasPhoto),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLine(bool real) {
    switch (_phase) {
      case _ScanPhase.idle:
        return 'Ready when you are';
      case _ScanPhase.hasPhoto:
        return 'Photo loaded — preparing scan…';
      case _ScanPhase.scanning:
        return real ? 'AI is looking…' : 'Genie is scanning…';
      case _ScanPhase.results:
        return 'Detected ${_detected.length} items';
      case _ScanPhase.error:
        return 'Something went wrong';
    }
  }

  Widget _bottomCta({required bool hasResults, required bool hasPhoto}) {
    if (hasResults) {
      return PrimaryButton(
        label: _accepted.isEmpty
            ? 'Pick at least one item'
            : 'Add ${_accepted.length} to fridge',
        icon: Icons.check_rounded,
        onPressed: _accepted.isEmpty ? null : _confirm,
      );
    }

    if (_phase == _ScanPhase.scanning) {
      return const PrimaryButton(
        label: 'Scanning…',
        icon: Icons.center_focus_strong_rounded,
        loading: true,
      );
    }

    if (_phase == _ScanPhase.error && hasPhoto) {
      return PrimaryButton(
        label: 'Try again',
        icon: Icons.refresh_rounded,
        onPressed: _runScan,
      );
    }

    if (hasPhoto) {
      return PrimaryButton(
        label: 'Run scan',
        icon: Icons.center_focus_strong_rounded,
        onPressed: _runScan,
      );
    }

    return PrimaryButton(
      label: 'Take a photo',
      icon: Icons.camera_alt_rounded,
      onPressed: () => _pickFrom(ImageSource.camera),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Viewport: shows camera placeholder, photo preview, scan animation, etc.
// ─────────────────────────────────────────────────────────────────────────────

class _ScanViewport extends StatelessWidget {
  final _ScanPhase phase;
  final Uint8List? photoBytes;
  final String? photoPath;
  final double progress;
  final String statusText;

  const _ScanViewport({
    required this.phase,
    required this.photoBytes,
    required this.photoPath,
    required this.progress,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    final scanning = phase == _ScanPhase.scanning;

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.calmGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.outline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Photo preview (if we have one) — fills viewport.
            if (photoBytes != null)
              _PhotoPreview(bytes: photoBytes!, path: photoPath)
            else
              const Center(
                child: Text('🧊', style: TextStyle(fontSize: 88)),
              ),

            // 2. Dim overlay while scanning so the line stands out.
            if (scanning)
              Container(color: Colors.black.withValues(alpha: 0.18)),

            // 3. Scan line animation.
            if (scanning)
              LayoutBuilder(
                builder: (ctx, c) => Stack(
                  children: [
                    Positioned(
                      left: 16,
                      right: 16,
                      top: 24 + (progress * (c.maxHeight - 64)),
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: AppColors.leafGradient,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 4. Status pill.
            Positioned(
              bottom: 14,
              left: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    Icon(
                      phase == _ScanPhase.error
                          ? Icons.error_outline_rounded
                          : Icons.bolt_rounded,
                      size: 16,
                      color: phase == _ScanPhase.error
                          ? AppColors.tomato
                          : AppColors.primaryDark,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: phase == _ScanPhase.error
                              ? AppColors.tomato
                              : AppColors.primaryDark,
                        ),
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
  }
}

class _PhotoPreview extends StatelessWidget {
  final Uint8List bytes;
  final String? path;

  const _PhotoPreview({required this.bytes, required this.path});

  @override
  Widget build(BuildContext context) {
    // Prefer Image.file when we have a path (cheaper, decoded once); fall back
    // to the in-memory bytes otherwise.
    if (path != null) {
      final file = File(path!);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }
    return Image.memory(bytes, fit: BoxFit.cover);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Source picker card (camera / library)
// ─────────────────────────────────────────────────────────────────────────────

class _SourceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SourceCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.leafGradient,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
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
