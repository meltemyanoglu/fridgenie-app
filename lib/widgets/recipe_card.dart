import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../data/models/recipe.dart';
import '../data/services/ai_service.dart';
import 'match_badge.dart';

/// Headline recipe card. Used in horizontal carousels and full lists.
class RecipeCard extends StatelessWidget {
  final RankedRecipe ranked;
  final VoidCallback? onTap;
  final bool wide;

  const RecipeCard({
    super.key,
    required this.ranked,
    this.onTap,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = ranked.recipe;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, 8),
              blurRadius: 22,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero gradient with emoji
              Container(
                height: wide ? 130 : 110,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: r.gradientColors,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -12,
                      top: -8,
                      child: Text(
                        r.emoji,
                        style: const TextStyle(fontSize: 110),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      top: 14,
                      child: MatchBadge(percent: ranked.matchPercent, dark: true),
                    ),
                    Positioned(
                      left: 14,
                      bottom: 14,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusPill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined,
                                size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              '${r.cookMinutes} min',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          r.category.emoji,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          r.category.label,
                          style: TextStyle(
                            color: r.category.color,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const Spacer(),
                        _DifficultyDots(level: r.difficulty.value),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      r.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.tagline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _NutritionPill(
                          label: '${r.nutrition.calories} cal',
                          color: AppColors.primarySurface,
                          fg: AppColors.primaryDark,
                        ),
                        const SizedBox(width: 6),
                        _NutritionPill(
                          label: '${r.nutrition.proteinG}g protein',
                          color: AppColors.citrusSurface,
                          fg: AppColors.citrusDeep,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyDots extends StatelessWidget {
  final int level;
  const _DifficultyDots({required this.level});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final filled = i < level;
        return Padding(
          padding: const EdgeInsets.only(left: 3),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: filled ? AppColors.primary : AppColors.outline,
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}

class _NutritionPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color fg;
  const _NutritionPill({required this.label, required this.color, required this.fg});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Compact horizontal recipe row for list views.
class RecipeListTile extends StatelessWidget {
  final RankedRecipe ranked;
  final VoidCallback? onTap;
  const RecipeListTile({super.key, required this.ranked, this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = ranked.recipe;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              offset: const Offset(0, 6),
              blurRadius: 14,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: r.gradientColors,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              alignment: Alignment.center,
              child: Text(r.emoji, style: const TextStyle(fontSize: 36)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${r.cookMinutes} min · ${r.category.label}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            MatchBadge(percent: ranked.matchPercent),
          ],
        ),
      ),
    );
  }
}
