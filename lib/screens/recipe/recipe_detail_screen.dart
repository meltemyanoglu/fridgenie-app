import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../../data/mock/mock_ingredients.dart';
import '../../data/services/ai_service.dart';
import '../../providers/fridge_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/match_badge.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_header.dart';

class RecipeDetailScreen extends StatefulWidget {
  final RankedRecipe ranked;
  const RecipeDetailScreen({super.key, required this.ranked});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final _ai = AIService();
  List<GrocerySuggestion> _groceries = [];

  @override
  void initState() {
    super.initState();
    _loadGroceries();
  }

  Future<void> _loadGroceries() async {
    final fridge = context.read<FridgeProvider>();
    final list = await _ai.suggestGroceries(
      recipe: widget.ranked.recipe,
      ingredientIds: fridge.inventoryIds,
    );
    if (!mounted) return;
    setState(() => _groceries = list);
  }

  void _markCooked() {
    context.read<UserProvider>().recordCookedRecipe();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cooked! Streak +1 🔥'),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.ranked.recipe;
    final fridge = context.watch<FridgeProvider>();
    final recipeProv = context.watch<RecipeProvider>();
    final isFav = recipeProv.isFavorite(r.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.background,
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
            actions: [
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                  color: isFav ? AppColors.tomato : AppColors.textPrimary,
                ),
                onPressed: () => recipeProv.toggleFavorite(r.id),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
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
                      right: -20,
                      bottom: -30,
                      child: Text(r.emoji,
                          style: const TextStyle(fontSize: 220)),
                    ),
                    Positioned(
                      left: 20,
                      bottom: 80,
                      child: MatchBadge(
                          percent: widget.ranked.matchPercent, dark: true),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.title,
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            r.tagline,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageHPadding,
              AppSpacing.lg,
              AppSpacing.pageHPadding,
              AppSpacing.huge,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick stats row
                Row(
                  children: [
                    _Stat(
                      icon: Icons.timer_outlined,
                      label: '${r.cookMinutes} min',
                    ),
                    _Stat(
                      icon: Icons.local_fire_department_outlined,
                      label: '${r.nutrition.calories} cal',
                    ),
                    _Stat(
                      icon: Icons.restaurant_rounded,
                      label: '${r.servings} serv',
                    ),
                    _Stat(
                      icon: Icons.star_outline_rounded,
                      label: r.difficulty.label,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Why we recommend
                GlassCard(
                  color: AppColors.primarySurface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🧞', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Text(
                            'Why Fridgenie picked this',
                            style: context.text.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(widget.ranked.aiReason,
                          style: context.text.bodyLarge),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Nutrition
                SectionHeader(title: 'Nutrition per serving'),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _NutritionCard(
                      label: 'Protein',
                      value: '${r.nutrition.proteinG}g',
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    _NutritionCard(
                      label: 'Carbs',
                      value: '${r.nutrition.carbsG}g',
                      color: AppColors.citrusDeep,
                    ),
                    const SizedBox(width: 8),
                    _NutritionCard(
                      label: 'Fat',
                      value: '${r.nutrition.fatG}g',
                      color: AppColors.tomato,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Ingredients
                SectionHeader(
                  title: 'Ingredients',
                  subtitle:
                      '${widget.ranked.haveIngredients.length}/${r.requiredIngredientIds.length} in your fridge',
                ),
                const SizedBox(height: AppSpacing.sm),
                _IngredientList(
                  ids: r.requiredIngredientIds,
                  haveIds: fridge.inventoryIds,
                  optional: false,
                ),
                if (r.optionalIngredientIds.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text('Optional',
                      style: context.text.titleSmall),
                  const SizedBox(height: 6),
                  _IngredientList(
                    ids: r.optionalIngredientIds,
                    haveIds: fridge.inventoryIds,
                    optional: true,
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),

                // Substitutions
                if (r.substitutions.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Smart swaps',
                    subtitle: 'Out of something? Try these.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...r.substitutions.map(
                    (s) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.citrusSurface,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🔁', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${s.missing} → ${s.swap}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.citrusDeep,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(s.reason,
                                    style: context.text.bodyMedium),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // Steps
                SectionHeader(title: 'Step by step'),
                const SizedBox(height: AppSpacing.sm),
                ...r.steps.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusPill),
                          ),
                          child: Text(
                            '${s.order}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.text,
                                  style: context.text.bodyLarge),
                              if (s.minutes != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    '${s.minutes} min',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryDark,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Grocery suggestions
                if (_groceries.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Grocery list',
                    subtitle: 'What you\'d need to complete this dish',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  GlassCard(
                    color: AppColors.tomatoSurface,
                    child: Column(
                      children: _groceries
                          .map(
                            (g) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Text(g.ingredient.emoji,
                                      style: const TextStyle(fontSize: 22)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(g.ingredient.name,
                                            style: context.text.titleMedium),
                                        Text(g.reason,
                                            style: context.text.bodySmall),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      context
                                          .read<FridgeProvider>()
                                          .toggleInventory(g.ingredient.id);
                                      setState(() => _groceries.remove(g));
                                    },
                                    child: const Text('Add'),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                PrimaryButton(
                  label: 'Mark as cooked',
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: _markCooked,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Stat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryDark),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _NutritionCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
                color: color,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientList extends StatelessWidget {
  final List<String> ids;
  final Set<String> haveIds;
  final bool optional;

  const _IngredientList({
    required this.ids,
    required this.haveIds,
    required this.optional,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ids.map((id) {
        final ing = MockIngredients.byId(id);
        final has = haveIds.contains(id);
        final fg = optional
            ? AppColors.textSecondary
            : (has ? AppColors.primaryDark : AppColors.tomato);
        final bg = optional
            ? AppColors.surface
            : (has ? AppColors.primarySurface : AppColors.tomatoSurface);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(ing?.emoji ?? '🍴',
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                ing?.name ?? id,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
              if (!optional) ...[
                const SizedBox(width: 6),
                Icon(
                  has ? Icons.check_rounded : Icons.add_shopping_cart_rounded,
                  size: 14,
                  color: fg,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
