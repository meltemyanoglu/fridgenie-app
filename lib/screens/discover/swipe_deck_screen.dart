import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../../data/mock/mock_recipes.dart';
import '../../data/models/recipe.dart';
import '../../data/services/ai_service.dart';
import '../../providers/recipe_provider.dart';
import '../../routes.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/match_badge.dart';
import '../../widgets/primary_button.dart';

/// Tinder-style recipe discovery deck.
class SwipeDeckScreen extends StatefulWidget {
  const SwipeDeckScreen({super.key});

  @override
  State<SwipeDeckScreen> createState() => _SwipeDeckScreenState();
}

class _SwipeDeckScreenState extends State<SwipeDeckScreen>
    with SingleTickerProviderStateMixin {
  Offset _drag = Offset.zero;
  bool _animatingOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final list = List<Recipe>.from(MockRecipes.all)..shuffle();
      context.read<RecipeProvider>().seedSwipeDeck(list);
    });
  }

  void _swipe({required bool liked}) {
    setState(() {
      _animatingOut = true;
      _drag = Offset(liked ? 600 : -600, 60);
    });
    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      context.read<RecipeProvider>().swipe(liked: liked);
      setState(() {
        _drag = Offset.zero;
        _animatingOut = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final recipes = context.watch<RecipeProvider>();
    final deck = recipes.swipeDeck;

    return Scaffold(
      appBar: AppBar(title: const Text('Swipe to discover')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageHPadding),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Swipe right to save, left to skip.',
                style: context.text.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: deck.isEmpty
                    ? EmptyState(
                        emoji: '✨',
                        title: 'You\'ve seen them all',
                        subtitle:
                            'Saved ${recipes.liked.length} recipes — find them in your favorites.',
                        actionLabel: 'Reshuffle',
                        onAction: () {
                          final list = List<Recipe>.from(MockRecipes.all)
                            ..shuffle();
                          context
                              .read<RecipeProvider>()
                              .seedSwipeDeck(list);
                        },
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          if (deck.length > 1)
                            _DeckCard(
                              recipe: deck[1],
                              scale: 0.94,
                              opacity: 0.7,
                            ),
                          GestureDetector(
                            onPanUpdate: _animatingOut
                                ? null
                                : (d) => setState(
                                    () => _drag += d.delta),
                            onPanEnd: _animatingOut
                                ? null
                                : (_) {
                                    if (_drag.dx > 100) {
                                      _swipe(liked: true);
                                    } else if (_drag.dx < -100) {
                                      _swipe(liked: false);
                                    } else {
                                      setState(() => _drag = Offset.zero);
                                    }
                                  },
                            child: AnimatedContainer(
                              duration: _animatingOut
                                  ? const Duration(milliseconds: 220)
                                  : Duration.zero,
                              transform: Matrix4.identity()
                                ..translate(_drag.dx, _drag.dy)
                                ..rotateZ(_drag.dx / 1000),
                              child: _DeckCard(
                                recipe: deck.first,
                                showBadges: true,
                                drag: _drag,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              if (deck.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'Skip',
                        icon: Icons.close_rounded,
                        color: AppColors.surface,
                        foreground: AppColors.textPrimary,
                        onPressed:
                            _animatingOut ? null : () => _swipe(liked: false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Save',
                        icon: Icons.favorite_rounded,
                        color: AppColors.tomato,
                        onPressed:
                            _animatingOut ? null : () => _swipe(liked: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DeckCard extends StatelessWidget {
  final Recipe recipe;
  final double scale;
  final double opacity;
  final bool showBadges;
  final Offset drag;

  const _DeckCard({
    required this.recipe,
    this.scale = 1.0,
    this.opacity = 1.0,
    this.showBadges = false,
    this.drag = Offset.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 320,
          height: 460,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: recipe.gradientColors,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                offset: const Offset(0, 16),
                blurRadius: 32,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Text(recipe.emoji,
                    style: const TextStyle(fontSize: 220)),
              ),
              if (showBadges) ...[
                Positioned(
                  top: 18,
                  left: 18,
                  child: Opacity(
                    opacity: (drag.dx / 80).clamp(0, 1),
                    child: _Stamp(
                      label: 'SAVE',
                      color: AppColors.primary,
                      angle: -0.2,
                    ),
                  ),
                ),
                Positioned(
                  top: 18,
                  right: 18,
                  child: Opacity(
                    opacity: (-drag.dx / 80).clamp(0, 1),
                    child: _Stamp(
                      label: 'SKIP',
                      color: AppColors.tomato,
                      angle: 0.2,
                    ),
                  ),
                ),
              ],
              Positioned(
                bottom: 22,
                left: 22,
                right: 22,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(recipe.category.emoji,
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            recipe.category.label,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: recipe.category.color,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const Spacer(),
                          MatchBadge(percent: 100),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        recipe.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recipe.tagline,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 14),
                          const SizedBox(width: 4),
                          Text('${recipe.cookMinutes} min',
                              style:
                                  Theme.of(context).textTheme.bodySmall),
                          const SizedBox(width: 12),
                          const Icon(Icons.local_fire_department_outlined,
                              size: 14),
                          const SizedBox(width: 4),
                          Text('${recipe.nutrition.calories} cal',
                              style:
                                  Theme.of(context).textTheme.bodySmall),
                          const Spacer(),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pushNamed(
                              AppRoutes.recipeDetail,
                              arguments: RankedRecipe(
                                recipe: recipe,
                                matchScore: 1.0,
                                haveIngredients:
                                    recipe.requiredIngredientIds,
                                missingIngredients: const [],
                                aiReason: recipe.whyRecommended,
                              ),
                            ),
                            child: const Text('Open'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  final String label;
  final Color color;
  final double angle;
  const _Stamp({
    required this.label,
    required this.color,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
