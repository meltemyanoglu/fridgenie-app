import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/extensions.dart';
import '../../providers/recipe_provider.dart';
import '../../routes.dart';
import '../../widgets/animated_blob.dart';
import '../../widgets/match_badge.dart';
import '../../widgets/primary_button.dart';

class SurpriseScreen extends StatefulWidget {
  const SurpriseScreen({super.key});

  @override
  State<SurpriseScreen> createState() => _SurpriseScreenState();
}

class _SurpriseScreenState extends State<SurpriseScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;
  bool _rolling = false;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _roll());
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  Future<void> _roll() async {
    setState(() => _rolling = true);
    _spin.repeat();
    await context.read<RecipeProvider>().rollSurprise();
    if (!mounted) return;
    _spin.stop();
    setState(() => _rolling = false);
  }

  @override
  Widget build(BuildContext context) {
    final surprise = context.watch<RecipeProvider>().surprise;
    return Scaffold(
      appBar: AppBar(title: const Text('Surprise Me, Chef')),
      body: Stack(
        children: [
          const Positioned(
            top: -120,
            right: -80,
            child: AnimatedBlob(
              size: 320,
              colors: [AppColors.citrusSurface, AppColors.background],
            ),
          ),
          const Positioned(
            bottom: -120,
            left: -100,
            child: AnimatedBlob(
              size: 320,
              colors: [AppColors.primarySurface, AppColors.background],
              duration: Duration(seconds: 12),
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
                    'Today\'s wildcard.',
                    style: AppTypography.wordmark.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Genie rolls the dice — sometimes the best dinner is the one you didn\'t plan.',
                    style: context.text.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Expanded(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _spin,
                        builder: (_, __) {
                          return Transform.rotate(
                            angle: _spin.value * 6.28,
                            child: _RollingDie(
                              emoji: _rolling
                                  ? '🎲'
                                  : (surprise?.recipe.emoji ?? '🎲'),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (surprise != null && !_rolling) ...[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXl),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              MatchBadge(
                                  percent: surprise.matchPercent),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.citrusSurface,
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusPill),
                                ),
                                child: Text(
                                  '${surprise.recipe.cookMinutes} min',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.citrusDeep,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(surprise.recipe.title,
                              style: context.text.headlineMedium),
                          const SizedBox(height: 4),
                          Text(
                            surprise.aiReason,
                            style: context.text.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: 'Roll again',
                          icon: Icons.casino_rounded,
                          color: AppColors.surface,
                          foreground: AppColors.textPrimary,
                          onPressed: _rolling ? null : _roll,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Cook this',
                          icon: Icons.restaurant_menu_rounded,
                          onPressed: surprise == null || _rolling
                              ? null
                              : () => Navigator.of(context).pushReplacementNamed(
                                    AppRoutes.recipeDetail,
                                    arguments: surprise,
                                  ),
                        ),
                      ),
                    ],
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

class _RollingDie extends StatelessWidget {
  final String emoji;
  const _RollingDie({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppColors.sunsetGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.tomato.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 110)),
    );
  }
}
