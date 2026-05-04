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

/// Mock AI photo scan. We don't actually open the camera; instead we
/// show a satisfying loading state and then a sheet of "detected" items
/// that the user can confirm or remove before adding to inventory.
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
    setState(() {
      _scanning = true;
      _detected = [];
      _accepted.clear();
    });
    final result = await _ai.scanFridgePhoto();
    if (!mounted) return;
    setState(() {
      _scanning = false;
      _detected = result;
      _accepted.addAll(result.map((e) => e.id));
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
    context.read<FridgeProvider>().addManyToInventory(_accepted);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageHPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Snap your fridge.\nI\'ll spot what\'s inside.',
                    style: context.text.displaySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'For now I\'ll simulate a scan — wire a real camera later.',
                    style: context.text.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AspectRatio(
                    aspectRatio: 1.1,
                    child: AnimatedBuilder(
                      animation: _ctrl,
                      builder: (_, __) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.calmGradient,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusXl),
                            border: Border.all(color: AppColors.outline),
                          ),
                          child: Stack(
                            children: [
                              const Center(
                                child: Text('🧊',
                                    style: TextStyle(fontSize: 88)),
                              ),
                              if (_scanning)
                                Positioned(
                                  left: 16,
                                  right: 16,
                                  top: 40 + (_ctrl.value * 220),
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      gradient: AppColors.leafGradient,
                                      borderRadius:
                                          BorderRadius.circular(8),
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
                              Positioned(
                                bottom: 14,
                                left: 14,
                                right: 14,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.bolt_rounded,
                                          size: 16,
                                          color: AppColors.primaryDark),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _scanning
                                              ? 'Genie is scanning…'
                                              : (_detected.isEmpty
                                                  ? 'Ready when you are'
                                                  : 'Detected ${_detected.length} items'),
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
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (_detected.isNotEmpty)
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Detected items',
                                style: context.text.titleLarge),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to confirm what should be added.',
                              style: context.text.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _detected
                                      .map((ing) => IngredientChip(
                                            ingredient: ing,
                                            selected:
                                                _accepted.contains(ing.id),
                                            onTap: () =>
                                                _toggleAccept(ing.id),
                                          ))
                                      .toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  if (_detected.isEmpty)
                    PrimaryButton(
                      label: _scanning ? 'Scanning…' : 'Run scan',
                      icon: Icons.center_focus_strong_rounded,
                      loading: _scanning,
                      onPressed: _scanning ? null : _runScan,
                    )
                  else
                    PrimaryButton(
                      label: 'Add ${_accepted.length} to fridge',
                      icon: Icons.check_rounded,
                      onPressed: _accepted.isEmpty ? null : _confirm,
                    ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
