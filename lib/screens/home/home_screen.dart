import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/extensions.dart';
import '../../data/mock/mock_ingredients.dart';
import '../../data/models/enums.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/gemini_service.dart';
import '../../providers/fridge_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/user_provider.dart';
import '../../routes.dart';
import '../../widgets/animated_blob.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/ingredient_chip.dart';
import '../../widgets/interactive_basket.dart';
import '../../widgets/mode_card.dart';
import '../../widgets/pill_tab_bar.dart';
import '../../widgets/recipe_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/streak_ring.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenPantry;
  const HomeScreen({super.key, this.onOpenPantry});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _ai = AIService();
  bool _showAllIngredients = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fridge = context.read<FridgeProvider>();
      if (fridge.selectedIds.isEmpty && fridge.inventoryIds.isNotEmpty) {
        fridge.addManyToSelection(fridge.inventoryIds.take(5));
      }
      _regenerate();
    });
  }

  Future<void> _regenerate() async {
    final fridge = context.read<FridgeProvider>();
    await context.read<RecipeProvider>().generateSuggestions(fridge.selectedIds);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.tomato,
        behavior: SnackBarBehavior.floating,
        content: Text(message,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.citrusDeep,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Text('💡 ', style: TextStyle(fontSize: 16)),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Late-night cravings';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'Good night';
  }

  @override
  Widget build(BuildContext context) {
    final fridge = context.watch<FridgeProvider>();
    final recipes = context.watch<RecipeProvider>();
    final user = context.watch<UserProvider>();
    final tip = _ai.tipOfTheDay();

    final categoryTabs = RecipeCategory.values
        .map(
          (c) => PillTab<RecipeCategory>(
            value: c,
            label: c.label,
            emoji: c.emoji,
            color: c.color,
          ),
        )
        .toList();

    return Stack(
      children: [
        const Positioned(
          top: -120,
          right: -80,
          child: AnimatedBlob(
            size: 260,
            colors: [AppColors.primarySurface, AppColors.background],
          ),
        ),
        SafeArea(
          child: RefreshIndicator(
            onRefresh: _regenerate,
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHPadding,
                AppSpacing.md,
                AppSpacing.pageHPadding,
                130,
              ),
              children: [
                _ChefHeader(
                  greeting: _greeting(),
                  name: user.profile.name,
                  streak: user.profile.currentStreak,
                  geminiAvailable: recipes.geminiAvailable,
                  onTapStreak: () =>
                      Navigator.of(context).pushNamed(AppRoutes.badges),
                ),

                const SizedBox(height: AppSpacing.lg),

                const InteractiveBasket(),

                const SizedBox(height: AppSpacing.lg),

                _HeroCard(
                  selectedCount: fridge.selectedIds.length,
                  onTapPantry: widget.onOpenPantry,
                ),

                const SizedBox(height: AppSpacing.lg),

                Row(
                  children: [
                    Expanded(
                      child: SectionHeader(
                        title: 'Tonight\'s ingredients',
                        subtitle: fridge.selectedIds.isEmpty
                            ? 'Pick what you have at home'
                            : '${fridge.selectedIds.length} selected · tap to edit',
                      ),
                    ),
                    if (fridge.selectedIds.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          fridge.clearSelected();
                          _regenerate();
                        },
                        child: const Text('Clear'),
                      ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                _IngredientGrid(
                  ingredients: MockIngredients.common,
                  showAll: _showAllIngredients,
                  selectedIds: fridge.selectedIds,
                  onTap: (id) {
                    fridge.toggleSelected(id);
                    _regenerate();
                  },
                  onToggleShowAll: () =>
                      setState(() => _showAllIngredients = !_showAllIngredients),
                ),

                const SizedBox(height: AppSpacing.lg),

                PillTabBar<RecipeCategory>(
                  tabs: categoryTabs,
                  selected: recipes.activeCategory,
                  onSelected: (cat) {
                    recipes.setActiveCategory(cat);
                    _regenerate();
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                if (recipes.suggestionsState == RequestState.loading)
                  const _SuggestionsLoading()
                else if (recipes.suggestions.isEmpty)
                  EmptyState(
                    emoji: '🥄',
                    title: 'Nothing matches yet',
                    subtitle:
                        'Add a few ingredients above and Fridgenie will rustle up some ideas.',
                    actionLabel: 'Open my fridge',
                    onAction: widget.onOpenPantry,
                  )
                else
                  SizedBox(
                    height: 300,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: recipes.suggestions.length.clamp(0, 6),
                      separatorBuilder: (context, i) => const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final r = recipes.suggestions[i];
                        return SizedBox(
                          width: 270,
                          child: RecipeCard(
                            ranked: r,
                            onTap: () => Navigator.of(context).pushNamed(
                              AppRoutes.recipeDetail,
                              arguments: r,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: AppSpacing.xl),

                SectionHeader(
                  title: 'Today\'s Genie tip',
                  subtitle: 'A small habit, big payoff',
                ),

                const SizedBox(height: AppSpacing.sm),

                GlassCard(
                  color: AppColors.citrusSurface,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Text(
                          tip.emoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tip.title, style: context.text.titleLarge),
                            const SizedBox(height: 4),
                            Text(tip.body, style: context.text.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                SectionHeader(
                  title: 'Genie modes',
                  subtitle: 'New ways to cook tonight',
                ),

                const SizedBox(height: AppSpacing.md),

                SizedBox(
                  height: 210,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    children: [
                      ModeCard(
                        title: 'Surprise Me',
                        subtitle: 'Roll the dice, get a chef-picked dinner.',
                        emoji: '🎲',
                        gradient: const [AppColors.citrus, AppColors.citrusDeep],
                        onTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.surprise),
                      ),
                      const SizedBox(width: 12),
                      ModeCard(
                        title: '3-Ingredient Challenge',
                        subtitle: 'Lock 3 items, cook from constraint.',
                        emoji: '🏆',
                        gradient: const [Color(0xFF8AD49C), AppColors.primary],
                        onTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.challenge),
                      ),
                      const SizedBox(width: 12),
                      ModeCard(
                        title: 'Leftover Rescue',
                        subtitle: 'Save what\'s wilting, make it delicious.',
                        emoji: '♻️',
                        gradient: const [AppColors.moodCozy, AppColors.tomato],
                        onTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.rescue),
                      ),
                      const SizedBox(width: 12),
                      ModeCard(
                        title: 'Cook for my mood',
                        subtitle: 'Pick a vibe, get matched recipes.',
                        emoji: '🌈',
                        gradient: const [
                          AppColors.moodCelebratory,
                          AppColors.moodAdventurous,
                        ],
                        onTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.mood),
                      ),
                      const SizedBox(width: 12),
                      ModeCard(
                        title: 'Healthy & Quick',
                        subtitle: 'Under 20 min, high protein, full of life.',
                        emoji: '⚡️',
                        gradient: const [
                          AppColors.primaryLight,
                          AppColors.citrus,
                        ],
                        onTap: () => _launchHealthyQuick(fridge.selectedIds),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                GlassCard(
                  color: AppColors.primarySurface,
                  child: Row(
                    children: [
                      StreakRing(
                        days: user.profile.currentStreak,
                        target: 7,
                        size: 118,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'You\'re on a roll',
                              style: AppTypography.wordmark.copyWith(
                                fontSize: 21,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${user.profile.recipesCooked} recipes cooked · '
                              '${(user.profile.wasteSavedGrams / 1000).toStringAsFixed(1)}kg saved',
                              style: context.text.bodyMedium,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: user.badges
                                  .where((b) => b.earned)
                                  .take(4)
                                  .map(
                                    (b) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusPill,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            b.emoji,
                                            style:
                                                const TextStyle(fontSize: 13),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            b.name,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primaryDark,
                                            ),
                                          ),
                                        ],
                                      ),
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchHealthyQuick(Set<String> ingredientIds) async {
    final recipes = context.read<RecipeProvider>();

    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const _GeneratingSheet(),
    );

    final ranked = await recipes.generateWithGemini(
      ingredientIds: ingredientIds.toList(),
      mode: GenieMode.healthyQuick,
    );

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (ranked == null) {
      _showError('Couldn\'t generate a healthy recipe. Try again!');
      return;
    }

    if (!recipes.lastGenerationUsedGemini && recipes.geminiError != null) {
      _showInfo(recipes.geminiError!);
    }

    Navigator.of(context).pushNamed(AppRoutes.recipeDetail, arguments: ranked);
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _ChefHeader extends StatelessWidget {
  final String greeting;
  final String name;
  final int streak;
  final bool geminiAvailable;
  final VoidCallback onTapStreak;

  const _ChefHeader({
    required this.greeting,
    required this.name,
    required this.streak,
    required this.geminiAvailable,
    required this.onTapStreak,
  });

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProvider>().profile;
    final bgColor = profile.avatarBgColor != null
        ? Color(profile.avatarBgColor!)
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 74,
            height: 74,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bgColor,
              gradient: bgColor == null ? AppColors.heroGradient : null,
              borderRadius: BorderRadius.circular(28),
            ),
            child: profile.avatarEmoji != null
                ? Text(profile.avatarEmoji!,
                    style: const TextStyle(fontSize: 40))
                : const _AnimatedChefEmoji(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: context.text.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.wordmark.copyWith(
                    fontSize: 34,
                    color: AppColors.textPrimary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ready to cook something clever?',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Streak pill
              GestureDetector(
                onTap: onTapStreak,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    border: Border.all(color: AppColors.outline, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text(
                        '$streak',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // AI status dot
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: geminiAvailable
                          ? AppColors.primary
                          : AppColors.textTertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    geminiAvailable ? 'AI on' : 'Demo',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: geminiAvailable
                          ? AppColors.primaryDark
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

}


class _HeroCard extends StatelessWidget {
  final int selectedCount;
  final VoidCallback? onTapPantry;

  const _HeroCard({required this.selectedCount, this.onTapPantry});

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedCount > 0;
    final status = hasSelection
        ? '$selectedCount ${selectedCount == 1 ? 'ingredient' : 'ingredients'} selected'
        : 'No ingredients selected';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(
                  Icons.kitchen_outlined,
                  size: 22,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What\'s in your fridge?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pick ingredients to get matching recipes',
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.3,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasSelection ? AppColors.primary : AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                status,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroAction(
                  icon: Icons.inventory_2_outlined,
                  label: 'Open pantry',
                  onTap: onTapPantry,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroAction(
                  icon: Icons.document_scanner_outlined,
                  label: 'Scan fridge',
                  filled: true,
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.scan),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback? onTap;

  const _HeroAction({
    required this.icon,
    required this.label,
    this.filled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppColors.textOnPrimary : AppColors.textPrimary;

    return Material(
      color: filled ? AppColors.primaryDark : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        side: filled
            ? BorderSide.none
            : const BorderSide(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: fg,
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


class _AnimatedChefEmoji extends StatefulWidget {
  const _AnimatedChefEmoji();

  @override
  State<_AnimatedChefEmoji> createState() => _AnimatedChefEmojiState();
}

class _AnimatedChefEmojiState extends State<_AnimatedChefEmoji>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
    _float = Tween<double>(begin: -2, end: 2)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (context, child) =>
          Transform.translate(offset: Offset(0, _float.value), child: child),
      child: const Text('👩‍🍳', style: TextStyle(fontSize: 40)),
    );
  }
}

class _SuggestionsLoading extends StatelessWidget {
  const _SuggestionsLoading();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (ctx, i) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) => Container(
          width: 230,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          alignment: Alignment.center,
          child: const CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
    );
  }
}

/// Ingredient chip grid: shows complete rows initially, expands on "See all".
class _IngredientGrid extends StatelessWidget {
  final List<dynamic> ingredients;
  final bool showAll;
  final Set<String> selectedIds;
  final void Function(String id) onTap;
  final VoidCallback onToggleShowAll;

  const _IngredientGrid({
    required this.ingredients,
    required this.showAll,
    required this.selectedIds,
    required this.onTap,
    required this.onToggleShowAll,
  });

  // Estimate chip width: emoji(13) + gap(5) + text + horizontal padding(16)
  // Average ingredient name ~8 chars × 6.5px ≈ 52px → total ~86px
  static double _estimateChipWidth(String name) =>
      13 + 5 + name.length * 6.5 + 16;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        const hSpacing = 6.0;

        // Figure out how many complete rows fit in the "collapsed" view
        int count = 0;
        double rowWidth = 0;
        int rows = 0;
        const maxRows = 3;

        for (final ing in ingredients) {
          final chipW = _estimateChipWidth(ing.name as String);
          if (rowWidth + chipW > maxWidth + hSpacing) {
            rows++;
            rowWidth = chipW + hSpacing;
          } else {
            rowWidth += chipW + hSpacing;
          }
          if (rows >= maxRows) break;
          count++;
        }

        final visible = showAll ? ingredients : ingredients.take(count).toList();
        final hasMore = ingredients.length > count;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: hSpacing,
              runSpacing: 6,
              children: visible.map((ing) {
                final selected = selectedIds.contains(ing.id as String);
                return AnimatedScale(
                  scale: selected ? 1.04 : 1.0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  child: IngredientChip(
                    ingredient: ing,
                    selected: selected,
                    compact: true,
                    onTap: () => onTap(ing.id as String),
                  ),
                );
              }).toList(),
            ),
            if (hasMore) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: onToggleShowAll,
                  icon: Icon(
                    showAll
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                  ),
                  label: Text(
                    showAll ? 'Show less' : 'See all ingredients',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Bottom sheet shown while Genie is cooking. Cycles through friendly copy
/// so the wait feels intentional.
class _GeneratingSheet extends StatefulWidget {
  const _GeneratingSheet();

  @override
  State<_GeneratingSheet> createState() => _GeneratingSheetState();
}

class _GeneratingSheetState extends State<_GeneratingSheet> {
  static const _lines = [
    'Looking at what you have…',
    'Thinking about flavors…',
    'Picking the right technique…',
    'Writing the steps…',
    'Plating it up…',
  ];
  int _idx = 0;
  late final StreamSubscription<int> _tickerSub;

  @override
  void initState() {
    super.initState();
    _tickerSub = Stream<int>.periodic(
        const Duration(milliseconds: 1600), (i) => i + 1).listen((i) {
      if (!mounted) return;
      setState(() => _idx = i % _lines.length);
    });
  }

  @override
  void dispose() {
    _tickerSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFFA855F7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Text('🧞', style: TextStyle(fontSize: 44)),
          ),
          const SizedBox(height: 18),
          Text(
            'Genie is cooking…',
            style: AppTypography.wordmark.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              _lines[_idx],
              key: ValueKey(_idx),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          const SizedBox(height: 24),
          const LinearProgressIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceMuted,
          ),
        ],
      ),
    );
  }
}
