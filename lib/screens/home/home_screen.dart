import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/extensions.dart';
import '../../data/mock/mock_ingredients.dart';
import '../../data/models/enums.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/ingredient_recognizer.dart' show RecognizerException;
import '../../data/services/recipe_generator.dart';
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
    final recipes = context.read<RecipeProvider>();
    await recipes.generateSuggestions(fridge.selectedIds);
  }

  Future<void> _generateNewRecipe() async {
    final fridge = context.read<FridgeProvider>();
    final recipes = context.read<RecipeProvider>();
    final user = context.read<UserProvider>();
    final generator = context.read<RecipeGenerator?>();

    if (generator == null) return;
    if (fridge.selectedIds.isEmpty) return;

    // Show a non-dismissible loading sheet while Gemini cooks the recipe up.
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const _GeneratingSheet(),
    );

    try {
      final recipe = await generator.generate(
        ingredients: fridge.selectedIds.toList(),
        dietary: user.profile.dietary,
        mood: user.profile.defaultMood,
        cuisine: user.profile.favoriteCuisines.isNotEmpty
            ? user.profile.favoriteCuisines.first
            : null,
        skill: user.profile.skill,
        avoidTitles: recipes.generatedRecipes
            .map((r) => r.title)
            .take(10)
            .toList(),
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // close loading sheet

      recipes.addGeneratedRecipe(recipe);

      // Wrap into a RankedRecipe (100% match — it was made for you).
      final ranked = RankedRecipe(
        recipe: recipe,
        matchScore: 1.0,
        haveIngredients: recipe.requiredIngredientIds,
        missingIngredients: const [],
        aiReason: recipe.whyRecommended,
      );

      Navigator.of(context).pushNamed(
        AppRoutes.recipeDetail,
        arguments: ranked,
      );
    } on RecognizerException catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showError('Couldn\'t cook one up: $e');
    }
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

    final visibleIngredients = _showAllIngredients
        ? MockIngredients.common
        : MockIngredients.common.take(9).toList();

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
        Positioned(
          top: -120,
          right: -80,
          child: const AnimatedBlob(
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

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: visibleIngredients.map((ing) {
                    final selected = fridge.isSelected(ing.id);

                    return AnimatedScale(
                      scale: selected ? 1.04 : 1.0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutBack,
                      child: IngredientChip(
                        ingredient: ing,
                        selected: selected,
                        compact: true,
                        onTap: () {
                          fridge.toggleSelected(ing.id);
                          _regenerate();
                        },
                      ),
                    );
                  }).toList(),
                ),

                if (MockIngredients.common.length > 9) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showAllIngredients = !_showAllIngredients;
                        });
                      },
                      icon: Icon(
                        _showAllIngredients
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                      ),
                      label: Text(
                        _showAllIngredients
                            ? 'Show less'
                            : 'Show all ingredients',
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),

                _AnimatedGenerateButton(
                  loading: recipes.suggestionsState == RequestState.loading,
                  disabled: fridge.selectedIds.isEmpty,
                  onPressed: _regenerate,
                ),

                if (context.read<RecipeGenerator?>() != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _CookSomethingNewCard(
                    disabled: fridge.selectedIds.isEmpty,
                    onTap: _generateNewRecipe,
                  ),
                ],

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
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
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
                        gradient: const [
                          AppColors.citrus,
                          AppColors.citrusDeep,
                        ],
                        onTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.surprise),
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
}

class _ChefHeader extends StatelessWidget {
  final String greeting;
  final String name;
  final int streak;
  final VoidCallback onTapStreak;

  const _ChefHeader({
    required this.greeting,
    required this.name,
    required this.streak,
    required this.onTapStreak,
  });

  @override
  Widget build(BuildContext context) {
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
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const _AnimatedChefEmoji(),
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
                  '$name 👋',
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
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onTapStreak,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                border: Border.all(color: AppColors.outline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 5),
                  Text(
                    '$streak',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final int selectedCount;
  final VoidCallback? onTapPantry;

  const _HeroCard({
    required this.selectedCount,
    this.onTapPantry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.09),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Text('🧊', style: TextStyle(fontSize: 21)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'What\'s in your fridge today?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            selectedCount == 0
                ? 'Tap a few ingredients below — I\'ll dream up dinners that match.'
                : 'I see $selectedCount ingredients — pulling matches now.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Flexible(
                child: _MiniAction(
                  icon: Icons.kitchen_rounded,
                  label: 'Open pantry',
                  onTap: onTapPantry,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: _MiniAction(
                  icon: Icons.center_focus_strong_rounded,
                  label: 'Scan fridge',
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

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _MiniAction({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: AppColors.primaryDark),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
    );
  }
}

class _AnimatedGenerateButton extends StatefulWidget {
  final bool loading;
  final bool disabled;
  final VoidCallback onPressed;

  const _AnimatedGenerateButton({
    required this.loading,
    required this.disabled,
    required this.onPressed,
  });

  @override
  State<_AnimatedGenerateButton> createState() =>
      _AnimatedGenerateButtonState();
}

class _AnimatedGenerateButtonState extends State<_AnimatedGenerateButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 1.0, end: 1.025).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shouldAnimate = !widget.disabled && !widget.loading;

    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(
          scale: shouldAnimate ? _scale.value : 1.0,
          child: child,
        );
      },
      child: PrimaryButton(
        label: widget.loading ? 'Creating ideas...' : 'Generate meal ideas',
        icon: Icons.auto_awesome_rounded,
        loading: widget.loading,
        onPressed: widget.disabled ? null : widget.onPressed,
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

    _float = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _float.value),
          child: child,
        );
      },
      child: const Text(
        '👩‍🍳',
        style: TextStyle(fontSize: 40),
      ),
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
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => Container(
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

/// Sub-CTA shown right under the main "Generate meal ideas" button. Asks
/// Gemini to invent something new from the user's fridge instead of matching
/// a fixed catalog.
class _CookSomethingNewCard extends StatelessWidget {
  final bool disabled;
  final VoidCallback onTap;

  const _CookSomethingNewCard({
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: AppColors.sunsetGradient,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: [
              BoxShadow(
                color: AppColors.citrusDeep.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🧞', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cook something new',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Let Genie invent a recipe from what you have',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom-sheet shown while Gemini is generating. Plays a small spinner +
/// rotating "thinking" copy to make a 5-15 sec wait feel intentional.
class _GeneratingSheet extends StatefulWidget {
  const _GeneratingSheet();

  @override
  State<_GeneratingSheet> createState() => _GeneratingSheetState();
}

class _GeneratingSheetState extends State<_GeneratingSheet> {
  static const _lines = [
    'Looking at what you have…',
    'Thinking about flavors…',
    'Picking a method…',
    'Writing the steps…',
    'Plating it up…',
  ];
  int _idx = 0;
  late final Stream<int> _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Stream<int>.periodic(
        const Duration(milliseconds: 1600), (i) => i + 1);
    _ticker.listen((i) {
      if (!mounted) return;
      setState(() => _idx = i % _lines.length);
    });
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
            margin: const EdgeInsets.only(bottom: 22),
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.sunsetGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.citrusDeep.withValues(alpha: 0.4),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: const Text('🧞', style: TextStyle(fontSize: 42)),
          ),
          const SizedBox(height: 18),
          Text(
            'Genie is cooking…',
            style: AppTypography.wordmark.copyWith(
              fontSize: 22,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            child: Text(
              _lines[_idx],
              key: ValueKey(_idx),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}