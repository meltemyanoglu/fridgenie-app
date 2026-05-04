import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/enums.dart';
import '../../providers/fridge_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../routes.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/mode_card.dart';
import '../../widgets/pill_tab_bar.dart';
import '../../widgets/recipe_card.dart';
import '../../widgets/section_header.dart';

/// Discover tab — full list of ranked suggestions filtered by category,
/// plus quick-launch tiles for the sticky modes.
class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final fridge = context.read<FridgeProvider>();
    await context.read<RecipeProvider>()
        .generateSuggestions(fridge.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    final recipes = context.watch<RecipeProvider>();
    final categoryTabs = RecipeCategory.values
        .map((c) => PillTab<RecipeCategory>(
              value: c,
              label: c.label,
              emoji: c.emoji,
              color: c.color,
            ))
        .toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHPadding,
            AppSpacing.lg,
            AppSpacing.pageHPadding,
            AppSpacing.huge,
          ),
          children: [
            Text('Discover', style: context.text.headlineLarge),
            const SizedBox(height: 4),
            Text(
              'Recipes ranked by what you have, what you love, and how you feel.',
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Categories
            PillTabBar<RecipeCategory>(
              tabs: categoryTabs,
              selected: recipes.activeCategory,
              onSelected: (cat) {
                recipes.setActiveCategory(cat);
                _refresh();
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Quick mode launchers
            SizedBox(
              height: 180,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ModeCard(
                    title: 'Swipe to discover',
                    subtitle: 'Tinder-style cards.',
                    emoji: '💚',
                    gradient: const [
                      AppColors.moodCalm,
                      AppColors.info,
                    ],
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.swipeDeck),
                  ),
                  const SizedBox(width: 12),
                  ModeCard(
                    title: 'Surprise Me',
                    subtitle: 'AI rolls one for you.',
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
                    title: 'Cook for my mood',
                    subtitle: 'Pick a vibe.',
                    emoji: '🌈',
                    gradient: const [
                      AppColors.moodCelebratory,
                      AppColors.moodAdventurous,
                    ],
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.mood),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            SectionHeader(
              title: 'Top matches for tonight',
              subtitle: '${recipes.suggestions.length} ranked picks',
            ),
            const SizedBox(height: AppSpacing.md),

            if (recipes.suggestionsState == RequestState.loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (recipes.suggestions.isEmpty)
              EmptyState(
                emoji: '🍽️',
                title: 'No matches yet',
                subtitle:
                    'Try removing the category filter or adding more ingredients.',
                actionLabel: 'Clear filter',
                onAction: () {
                  recipes.setActiveCategory(null);
                  _refresh();
                },
              )
            else
              ...recipes.suggestions.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: RecipeListTile(
                    ranked: r,
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.recipeDetail,
                      arguments: r,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
