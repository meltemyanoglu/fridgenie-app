import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../../providers/fridge_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../routes.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/ingredient_chip.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/recipe_card.dart';
import '../../widgets/section_header.dart';

class RescueScreen extends StatefulWidget {
  const RescueScreen({super.key});

  @override
  State<RescueScreen> createState() => _RescueScreenState();
}

class _RescueScreenState extends State<RescueScreen> {
  bool _ran = false;

  Future<void> _run() async {
    final fridge = context.read<FridgeProvider>();
    setState(() => _ran = true);
    await context.read<RecipeProvider>().runRescue(fridge.inventoryIds);
  }

  @override
  Widget build(BuildContext context) {
    final fridge = context.watch<FridgeProvider>();
    final results = context.watch<RecipeProvider>().rescueResults;

    return Scaffold(
      appBar: AppBar(title: const Text('Leftover Rescue')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHPadding,
            AppSpacing.lg,
            AppSpacing.pageHPadding,
            AppSpacing.huge,
          ),
          children: [
            Text(
              'Save what\'s wilting.\nWaste less. Eat better.',
              style: context.text.displaySmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Genie boosts forgiving, use-it-up recipes for what\'s already in your fridge.',
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            GlassCard(
              color: AppColors.tomatoSurface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('♻️', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Text(
                        'In your fridge right now',
                        style: context.text.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (fridge.inventory.isEmpty)
                    Text(
                      'Add ingredients to your fridge first — then I can rescue them.',
                      style: context.text.bodyMedium,
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: fridge.inventory
                          .map((i) => IngredientChip(ingredient: i))
                          .toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Rescue my fridge',
              icon: Icons.restart_alt_rounded,
              onPressed: fridge.inventory.isEmpty ? null : _run,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_ran) ...[
              SectionHeader(
                title: 'Made for what you have',
                subtitle: 'Forgiving recipes that hate waste',
              ),
              const SizedBox(height: AppSpacing.sm),
              if (results.isEmpty)
                EmptyState(
                  emoji: '🥕',
                  title: 'Nothing to rescue yet',
                  subtitle: 'Try adding more pantry items to your fridge.',
                )
              else
                ...results.take(10).map(
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
          ],
        ),
      ),
    );
  }
}
