import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/enums.dart';
import '../../data/services/ai_service.dart' show RankedRecipe;
import '../../providers/fridge_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../routes.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/mode_card.dart';
import '../../widgets/pill_tab_bar.dart';
import '../../widgets/recipe_card.dart';
import '../../widgets/section_header.dart';

class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final fridge = context.read<FridgeProvider>();
    await context.read<RecipeProvider>().generateSuggestions(fridge.selectedIds);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageHPadding,
              AppSpacing.lg,
              AppSpacing.pageHPadding,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Discover', style: context.text.headlineLarge),
                const SizedBox(height: 4),
                Text(
                  'Recipes ranked by what you have, what you love.',
                  style: context.text.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textTertiary,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('Matches'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('AI Created'),
                          const SizedBox(width: 5),
                          if (recipes.geminiAvailable)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusPill),
                              ),
                              child: const Text(
                                'AI',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1 — catalog matches
                _MatchesTab(
                  categoryTabs: categoryTabs,
                  onRefresh: _refresh,
                ),
                // Tab 2 — Gemini-generated recipes this session
                const _AiCreatedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchesTab extends StatelessWidget {
  final List<PillTab<RecipeCategory>> categoryTabs;
  final Future<void> Function() onRefresh;

  const _MatchesTab({required this.categoryTabs, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final recipes = context.watch<RecipeProvider>();

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHPadding,
          AppSpacing.lg,
          AppSpacing.pageHPadding,
          AppSpacing.huge,
        ),
        children: [
          // Quick mode launchers
          SizedBox(
            height: 175,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ModeCard(
                  title: 'Surprise Me',
                  subtitle: 'Genie rolls one for you.',
                  emoji: '🎲',
                  gradient: const [AppColors.citrus, AppColors.citrusDeep],
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
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.mood),
                ),
                const SizedBox(width: 12),
                ModeCard(
                  title: 'Swipe to discover',
                  subtitle: 'Tinder-style cards.',
                  emoji: '💚',
                  gradient: const [AppColors.moodCalm, AppColors.info],
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.swipeDeck),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          PillTabBar<RecipeCategory>(
            tabs: categoryTabs,
            selected: recipes.activeCategory,
            onSelected: (cat) {
              recipes.setActiveCategory(cat);
              onRefresh();
            },
          ),
          const SizedBox(height: AppSpacing.lg),

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
                  'Try removing the category filter or adding more ingredients in the Fridge tab.',
              actionLabel: 'Clear filter',
              onAction: () {
                recipes.setActiveCategory(null);
                onRefresh();
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
    );
  }
}

class _AiCreatedTab extends StatelessWidget {
  const _AiCreatedTab();

  @override
  Widget build(BuildContext context) {
    final recipes = context.watch<RecipeProvider>();
    final fridge = context.watch<FridgeProvider>();
    final generated = recipes.generatedRecipes;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHPadding,
        AppSpacing.lg,
        AppSpacing.pageHPadding,
        AppSpacing.huge,
      ),
      children: [
        if (!recipes.geminiAvailable)
          _DemoBanner(onLearnMore: () => _showSetupDialog(context)),

        const SizedBox(height: AppSpacing.md),

        if (generated.isEmpty)
          EmptyState(
            emoji: '🧞',
            title: 'Nothing here yet',
            subtitle: recipes.geminiAvailable
                ? 'Tap "Cook something new" on the Home tab and Genie will invent a unique recipe just for you.'
                : 'Use the "Cook something new" card on Home — in demo mode Genie picks a great match.',
            actionLabel: 'Go to Home',
            onAction: null,
          )
        else ...[
          SectionHeader(
            title: 'Your Genie recipes',
            subtitle: '${generated.length} created this session',
          ),
          const SizedBox(height: AppSpacing.md),
          ...generated.map((r) {
            final ranked = RankedRecipe(
              recipe: r,
              matchScore: 1.0,
              haveIngredients: r.requiredIngredientIds
                  .where(fridge.selectedIds.contains)
                  .toList(),
              missingIngredients: r.requiredIngredientIds
                  .where((id) => !fridge.selectedIds.contains(id))
                  .toList(),
              aiReason: r.whyRecommended,
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: RecipeListTile(
                ranked: ranked,
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.recipeDetail,
                  arguments: ranked,
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  void _showSetupDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enable AI mode 🧞'),
        content: const Text(
          'Run the app with your Gemini API key to unlock real AI recipe generation:\n\n'
          'flutter run \\\n  --dart-define=GEMINI_API_KEY=your_key\n\n'
          'Get a free key at ai.google.dev',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _DemoBanner extends StatelessWidget {
  final VoidCallback onLearnMore;
  const _DemoBanner({required this.onLearnMore});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.citrusSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.citrus.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Demo mode',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Add your Gemini API key to unlock real AI recipes.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onLearnMore,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: const Text('How?', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
