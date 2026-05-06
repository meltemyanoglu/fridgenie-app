import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/ingredient.dart';
import '../../data/services/ai_service.dart';
import '../../providers/fridge_provider.dart';
import '../../widgets/animated_blob.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/ingredient_chip.dart';
import '../../widgets/primary_button.dart';

/// Mock AI photo scan. We don't actually open the camera; instead we show a
/// satisfying loading state, "detect" a handful of fresh ingredients (items
/// not already in the user's fridge are preferred), and let the user confirm
/// what should be added.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  final _ai = AIService();
  late final AnimationController _ctrl;

  bool _scanning = false;
  List<Ingredient> _detected = [];
  final Set<String> _accepted = {};

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

  Future<void> _runScan() async {
    // Guard against double-tap while a scan is already in flight.
    if (_scanning) return;

    setState(() {
      _scanning = true;
      _detected = [];
      _accepted.clear();
    });

    // Pass the user's current inventory so we prefer items they don't have.
    final fridge = context.read<FridgeProvider>();
    final result = await _ai.scanFridgePhoto(excludeIds: fridge.inventoryIds);

    if (!mounted) return;

    setState(() {
      _scanning = false;
      _detected = result;
      _accepted
        ..clear()
        ..addAll(result.map((e) => e.id));
    });
  }

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

    // Friendly confirmation so it's obvious the action took effect.
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

  @override
  Widget build(BuildContext context) {
    final hasResults = _detected.isNotEmpty;

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
                // ── Scrollable content area
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
                        'Snap your fridge.\nI\'ll spot what\'s inside.',
                        style: context.text.displaySmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Mock scan for now — wire a real camera later.',
                        style: context.text.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // ── Camera viewport (animated)
                      AspectRatio(
                        aspectRatio: 1.1,
                        child: AnimatedBuilder(
                          animation: _ctrl,
                          builder: (_, __) => _ScanViewport(
                            scanning: _scanning,
                            progress: _ctrl.value,
                            statusText: _scanning
                                ? 'Genie is scanning…'
                                : (hasResults
                                    ? 'Detected ${_detected.length} items'
                                    : 'Ready when you are'),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

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
                                    onPressed: _scanning ? null : _runScan,
                                    icon: const Icon(Icons.refresh_rounded,
                                        size: 18),
                                    label: const Text('Scan again'),
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

                // ── Fixed CTA at the bottom
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageHPadding,
                    8,
                    AppSpacing.pageHPadding,
                    AppSpacing.lg,
                  ),
                  child: hasResults
                      ? PrimaryButton(
                          label: _accepted.isEmpty
                              ? 'Pick at least one item'
                              : 'Add ${_accepted.length} to fridge',
                          icon: Icons.check_rounded,
                          onPressed: _accepted.isEmpty ? null : _confirm,
                        )
                      : PrimaryButton(
                          label: _scanning ? 'Scanning…' : 'Run scan',
                          icon: Icons.center_focus_strong_rounded,
                          loading: _scanning,
                          onPressed: _scanning ? null : _runScan,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanViewport extends StatelessWidget {
  final bool scanning;
  final double progress; // 0..1
  final String statusText;

  const _ScanViewport({
    required this.scanning,
    required this.progress,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.calmGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.outline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Stack(
          children: [
            const Center(
              child: Text('🧊', style: TextStyle(fontSize: 88)),
            ),
            if (scanning)
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (ctx, c) {
                    return Stack(
                      children: [
                        Positioned(
                          left: 16,
                          right: 16,
                          // Bounce the line within the viewport.
                          top: 24 + (progress * (c.maxHeight - 64)),
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: AppColors.leafGradient,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.4),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
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
                    const Icon(Icons.bolt_rounded,
                        size: 16, color: AppColors.primaryDark),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        statusText,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.primaryDark,
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
