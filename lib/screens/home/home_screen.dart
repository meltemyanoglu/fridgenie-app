import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/extensions.dart';
import '../../data/mock/mock_ingredients.dart';
import '../../data/models/enums.dart';
import '../../data/services/ai_service.dart';
import '../../providers/fridge_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/user_provider.dart';
import '../../routes.dart';
import '../../widgets/animated_blob.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/ingredient_chip.dart';
import '../../widgets/mode_card.dart';
import '../../widgets/pill_tab_bar.dart';
import '../../widgets/primary_button.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Seed selection from inventory + auto-generate suggestions on first build.
      final fridge = context.read<FridgeProvider>();
      if (fridge.selectedIds.isEmpty && fridge.inventoryIds.isNotEmpty) {
        fridge.addManyToSelection(fridge.inventoryIds.take(5));
      }
      _regenerate();
    });
  }

  Future<void> _regenerate() async {
    final fridge = context.read<FridgeProvider>();
    final recipes = context.read<RecipeProvider>();
    await recipes.generateSuggestions(fridge.selectedIds);
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Late-night cravings';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'Tonight';
  }

  @override
  Widget build(BuildContext context) {
    final fridge = context.watch<FridgeProvider>();
    final recipes = context.watch<RecipeProvider>();
    final user = context.watch<UserProvider>();
    final tip = _ai.tipOfTheDay();
    final categoryTabs = RecipeCategory.values
        .map((c) => PillTab<RecipeCategory>(
              value: c,
              label: c.label,
              emoji: c.emoji,
              color: c.color,
            ))
        .toList();

    return Stack(
      children: [
        Positioned(
          top: -120,
          right: -80,
          child: const AnimatedBlob(
            size: 280,
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
                AppSpacing.lg,
                AppSpacing.pageHPadding,
                AppSpacing.huge,
              ),
              children: [
                // ── Top bar (greeting + streak) ─────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: context.text.bodyMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${user.profile.name} 👋',
                            style: context.text.headlineLarge,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context)
                          .pushNamed(AppRoutes.badges),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusPill),
                          border: Border.all(color: AppColors.outline),
                        ),
                        child: Row(
                          children: [
                            const Text('🔥',
                                style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              '${user.profile.currentStreak} days',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Hero "What's in your fridge today?" ──────────────────
                _HeroCard(
                  selectedCount: fridge.selectedIds.length,
                  onTapPantry: widget.onOpenPantry,
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Quick-pick ingredient chips ──────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: SectionHeader(
                        title: 'Tonight\'s ingredients',
                        subtitle: '${fridge.selectedIds.length} selected · tap to toggle',
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: MockIngredients.common.map((ing) {
                    final selected = fridge.isSelected(ing.id);
                    return IngredientChip(
                      ingredient: ing,
                      selected: selected,
                      onTap: () {
                        fridge.toggleSelected(ing.id);
                        _regenerate();
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Generate Meals CTA ───────────────────────────────────
                PrimaryButton(
                  label: 'Generate meal ideas',
                  icon: Icons.auto_awesome_rounded,
                  loading: recipes.suggestionsState == RequestState.loading,
                  onPressed: fridge.selectedIds.isEmpty ? null : _regenerate,
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Categories pill bar ──────────────────────────────────
                PillTabBar<RecipeCategory>(
                  tabs: categoryTabs,
                  selected: recipes.activeCategory,
                  onSelected: (cat) {
                    recipes.setActiveCategory(cat);
                    _regenerate();
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Suggestions ──────────────────────────────────────────
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
                    height: 320,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: recipes.suggestions.length.clamp(0, 6),
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final r = recipes.suggestions[i];
                        return SizedBox(
                          width: 280,
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

                const SizedBox(height: AppSpacing.xxl),

                // ── Daily Genie tip ──────────────────────────────────────
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
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Text(tip.emoji,
                            style: const TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tip.title,
                                style: context.text.titleLarge),
                            const SizedBox(height: 4),
                            Text(tip.body,
                                style: context.text.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Modes (Surprise Me, Challenge, Rescue, Mood) ─────────
                SectionHeader(
                  title: 'Genie modes',
                  subtitle: 'New ways to cook tonight',
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 210,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ModeCard(
                        title: 'Surprise Me',
                        subtitle: 'Roll the dice, get a chef-picked dinner.',
                        emoji: '🎲',
                        gradient: const [
                          AppColors.citrus,
                          AppColors.citrusDeep,
                        ],
                        onTap: () => Navigator.of(context)
                            .pushNamed(AppRoutes.surprise),
                      ),
                      const SizedBox(width: 12),
                      ModeCard(
                        title: '3-Ingredient Challenge',
                        subtitle: 'Lock 3 items, cook from constraint.',
                        emoji: '🏆',
                        gradient: const [
                          Color(0xFF8AD49C),
                          AppColors.primary,
                        ],
                        onTap: () => Navigator.of(context)
                            .pushNamed(AppRoutes.challenge),
                      ),
                      const SizedBox(width: 12),
                      ModeCard(
                        title: 'Leftover Rescue',
                        subtitle: 'Save what\'s wilting, make it delicious.',
                        emoji: '♻️',
                        gradient: const [
                          AppColors.moodCozy,
                          AppColors.tomato,
                        ],
                        onTap: () => Navigator.of(context)
                            .pushNamed(AppRoutes.rescue),
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
                        onTap: () => Navigator.of(context)
                            .pushNamed(AppRoutes.mood),
                      ),
                      const SizedBox(width: 12),
                      ModeCard(
                        title: 'Swipe to discover',
                        subtitle: 'Tinder-style recipe discovery.',
                        emoji: '💚',
                        gradient: const [
                          AppColors.moodCalm,
                          AppColors.info,
                        ],
                        onTap: () => Navigator.of(context)
                            .pushNamed(AppRoutes.swipeDeck),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // ── Streak / stats card ──────────────────────────────────
                GlassCard(
                  color: AppColors.primarySurface,
                  child: Row(
                    children: [
                      StreakRing(
                        days: user.profile.currentStreak,
                        target: 7,
                        size: 130,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('You\'re on a roll',
                                style: AppTypography.wordmark.copyWith(
                                  fontSize: 22,
                                  color: AppColors.primaryDark,
                                )),
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
                                  .map((b) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                              AppSpacing.radiusPill),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(b.emoji,
                                                style: const TextStyle(
                                                    fontSize: 13)),
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
                                      ))
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
}

class _HeroCard extends StatelessWidget {
  final int selectedCount;
  final VoidCallback? onTapPantry;
  const _HeroCard({required this.selectedCount, this.onTapPantry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
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
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Text('🧊', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'What\'s in your fridge today?',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            selectedCount == 0
                ? 'Tap a few ingredients below — I\'ll dream up dinners that match.'
                : 'I see $selectedCount ingredients — pulling matches now.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniAction(
                icon: Icons.kitchen_rounded,
                label: 'Open pantry',
                onTap: onTapPantry,
              ),
              const SizedBox(width: 10),
              _MiniAction(
                icon: Icons.center_focus_strong_rounded,
                label: 'Scan fridge',
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.scan),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _MiniAction({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primaryDark),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionsLoading extends StatelessWidget {
  const _SuggestionsLoading();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => Container(
          width: 240,
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
