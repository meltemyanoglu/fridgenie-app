import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/enums.dart';
import '../../providers/fridge_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/user_provider.dart';
import '../../routes.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/recipe_card.dart';
import '../../widgets/section_header.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  Mood? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserProvider>();
      _select(user.profile.defaultMood);
    });
  }

  Future<void> _select(Mood mood) async {
    setState(() => _selected = mood);
    final fridge = context.read<FridgeProvider>();
    await context
        .read<RecipeProvider>()
        .suggestForMood(mood, fridge.selectedIds.isEmpty ? fridge.inventoryIds : fridge.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    final results = context.watch<RecipeProvider>().moodSuggestions;

    return Scaffold(
      appBar: AppBar(title: const Text('Cook for my mood')),
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
              'How are you feeling?',
              style: context.text.displaySmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Genie matches recipes to your mood, not just your fridge.',
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: Mood.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final m = Mood.values[i];
                  final isSel = _selected == m;
                  return GestureDetector(
                    onTap: () => _select(m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 128,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: isSel
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  m.color.withValues(alpha: 0.55),
                                  m.color.withValues(alpha: 0.25),
                                ],
                              )
                            : null,
                        color: isSel ? null : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(
                          color: isSel ? m.color : AppColors.outline,
                          width: 1.6,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(m.emoji,
                              style: const TextStyle(fontSize: 28)),
                          Text(
                            m.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_selected != null) ...[
              SectionHeader(
                title: 'For your ${_selected!.label.toLowerCase()} mood',
                subtitle: _selected!.tagline,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (results.isEmpty)
                EmptyState(
                  emoji: '🍽️',
                  title: 'Nothing matches yet',
                  subtitle:
                      'Add a few ingredients in your fridge to get mood-matched ideas.',
                )
              else
                ...results.take(8).map(
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
