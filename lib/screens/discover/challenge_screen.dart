import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../../data/mock/mock_ingredients.dart';
import '../../providers/recipe_provider.dart';
import '../../routes.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/ingredient_chip.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/recipe_card.dart';
import '../../widgets/section_header.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  final List<String> _picks = [];
  bool _ran = false;

  static const _maxPicks = 3;

  Future<void> _toggle(String id) async {
    setState(() {
      if (_picks.contains(id)) {
        _picks.remove(id);
      } else if (_picks.length < _maxPicks) {
        _picks.add(id);
      }
    });
  }

  Future<void> _run() async {
    setState(() => _ran = true);
    await context.read<RecipeProvider>().runChallenge(_picks);
  }

  @override
  Widget build(BuildContext context) {
    final results = context.watch<RecipeProvider>().challengeResults;

    return Scaffold(
      appBar: AppBar(title: const Text('3-Ingredient Challenge')),
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
              'Pick exactly 3.\nGet creative dinner ideas.',
              style: context.text.displaySmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Constraint is the chef\'s favorite seasoning.',
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Locked in',
                          style: context.text.titleLarge),
                      const Spacer(),
                      Text(
                        '${_picks.length}/$_maxPicks',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_picks.isEmpty)
                    Text(
                      'Tap ingredients below to lock them in.',
                      style: context.text.bodyMedium,
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _picks.map((id) {
                        final ing = MockIngredients.byId(id)!;
                        return IngredientChip(
                          ingredient: ing,
                          selected: true,
                          onTap: () => _toggle(id),
                          onRemove: () => _toggle(id),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: 'Pantry'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MockIngredients.common.map((ing) {
                final isSel = _picks.contains(ing.id);
                final disabled = !isSel && _picks.length >= _maxPicks;
                return Opacity(
                  opacity: disabled ? 0.5 : 1.0,
                  child: IngredientChip(
                    ingredient: ing,
                    selected: isSel,
                    onTap: disabled ? null : () => _toggle(ing.id),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Find recipes',
              icon: Icons.bolt_rounded,
              onPressed: _picks.length == _maxPicks ? _run : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_ran && results.isEmpty)
              EmptyState(
                emoji: '🤔',
                title: 'No matches with that combo',
                subtitle:
                    'Try swapping one ingredient — Genie loves pantry staples like garlic, eggs, or pasta.',
              )
            else if (results.isNotEmpty) ...[
              SectionHeader(
                title: 'Wins this challenge',
                subtitle: 'Recipes built around your 3 picks',
              ),
              const SizedBox(height: AppSpacing.sm),
              ...results.map(
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
