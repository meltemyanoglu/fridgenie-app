import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/extensions.dart';
import '../../data/mock/mock_recipes.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/user_provider.dart';
import '../../routes.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/recipe_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/streak_ring.dart';
import '../../data/services/ai_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final recipeProv = context.watch<RecipeProvider>();
    final favorites = recipeProv.favorites
        .map((id) =>
            recipeProv.generatedById(id) ?? MockRecipes.byId(id))
        .toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHPadding,
          AppSpacing.lg,
          AppSpacing.pageHPadding,
          AppSpacing.huge,
        ),
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _showAvatarEditor(context, user),
                child: Stack(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: user.profile.avatarBgColor != null
                            ? Color(user.profile.avatarBgColor!)
                            : null,
                        gradient: user.profile.avatarBgColor == null
                            ? AppColors.leafGradient
                            : null,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                      child: user.profile.avatarEmoji != null
                          ? Text(user.profile.avatarEmoji!,
                              style: const TextStyle(fontSize: 34))
                          : _initials(user),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit,
                            size: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.profile.name,
                        style: context.text.headlineLarge),
                    Text(
                      '${user.profile.skill.label} · ${user.profile.defaultMood.label} mood',
                      style: context.text.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => _showSettingsSheet(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Streak + stats
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
                      Text('Lifetime',
                          style: AppTypography.wordmark.copyWith(
                            fontSize: 22,
                            color: AppColors.primaryDark,
                          )),
                      const SizedBox(height: 8),
                      _Stat(
                        emoji: '🍳',
                        label: 'Recipes cooked',
                        value: '${user.profile.recipesCooked}',
                      ),
                      _Stat(
                        emoji: '🏆',
                        label: 'Longest streak',
                        value: '${user.profile.longestStreak} days',
                      ),
                      _Stat(
                        emoji: '♻️',
                        label: 'Waste saved',
                        value:
                            '${(user.profile.wasteSavedGrams / 1000).toStringAsFixed(1)} kg',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Badges
          SectionHeader(
            title: 'Badges',
            subtitle:
                '${user.earnedBadgeCount} of ${user.badges.length} earned',
            onSeeAll: () => Navigator.of(context).pushNamed(AppRoutes.badges),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: user.badges.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final b = user.badges[i];
                return _BadgeChip(badge: b);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Taste profile
          SectionHeader(title: 'Taste profile'),
          const SizedBox(height: AppSpacing.sm),
          GlassCard(
            child: Column(
              children: user.profile.taste.axes.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 96,
                        child: Text(
                          e.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: e.value,
                            minHeight: 10,
                            backgroundColor: AppColors.surfaceMuted,
                            valueColor: const AlwaysStoppedAnimation(
                                AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 36,
                        child: Text(
                          '${(e.value * 100).round()}%',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Favorites
          if (favorites.isNotEmpty) ...[
            SectionHeader(
              title: 'Saved recipes',
              subtitle: '${favorites.length} favorites',
            ),
            const SizedBox(height: AppSpacing.sm),
            ...favorites.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: RecipeListTile(
                  ranked: RankedRecipeStub.fromRecipe(r),
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
    );
  }

  Widget _initials(UserProvider user) => Text(
        user.profile.name.isNotEmpty
            ? user.profile.name[0].toUpperCase()
            : '🧞',
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      );

  void _showAvatarEditor(BuildContext context, UserProvider user) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AvatarEditorSheet(userProvider: user),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Text('Settings',
                  style: Theme.of(sheetCtx).textTheme.headlineSmall),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.replay_rounded),
                title: const Text('Re-run onboarding'),
                subtitle: const Text('Reset your taste & cuisine prefs'),
                onTap: () async {
                  await context.read<UserProvider>().resetOnboarding();
                  if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.onboarding,
                      (_) => false,
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('About Fridgenie'),
                subtitle: const Text('v1.0.0 · made with 🥒 + ☀️'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  const _Stat({
    required this.emoji,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final dynamic badge; // CookingBadge
  const _BadgeChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    final earned = badge.earned as bool;
    return Container(
      width: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: earned ? AppColors.surface : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: earned ? AppColors.primary : AppColors.outline,
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Opacity(
            opacity: earned ? 1.0 : 0.5,
            child: Text(badge.emoji as String,
                style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(height: 6),
          Text(
            badge.name as String,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: earned ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (badge.progress as int) / 100,
              minHeight: 4,
              backgroundColor: AppColors.outline,
              valueColor: AlwaysStoppedAnimation(
                  earned ? AppColors.primary : AppColors.citrusDeep),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper to build a RankedRecipe from a plain Recipe (for favorites).
class RankedRecipeStub {
  static RankedRecipe fromRecipe(dynamic recipe) => RankedRecipe(
        recipe: recipe,
        matchScore: 1.0,
        haveIngredients: recipe.requiredIngredientIds as List<String>,
        missingIngredients: const [],
        aiReason: recipe.whyRecommended as String,
      );
}


class _AvatarEditorSheet extends StatelessWidget {
  final UserProvider userProvider;

  const _AvatarEditorSheet({required this.userProvider});

  static const _emojis = [
    '🧑‍🍳', '👩‍🍳', '🧞', '🍳', '🥗', '🍜',
    '🍕', '🌮', '🥩', '🍣', '🥑', '🌶️',
    '🧁', '🍰', '🥘', '🫕', '🍲', '🥙',
    '🧆', '🫔', '🥨', '🍱', '🥟', '🍛',
    '🐻', '🦊', '🐱', '🐶', '🦋', '🌻',
  ];

  static const _palette = [
    Color(0xFFE2F3DF),
    Color(0xFFFFF6D6),
    Color(0xFFFFE3E3),
    Color(0xFFDCF0FF),
    Color(0xFFF0E6FF),
    Color(0xFFFFEDD5),
    Color(0xFFD6F5EE),
    Color(0xFFFCE4EC),
    Color(0xFFEDE7F6),
    Color(0xFFE8F5E9),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Customize your profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Choose your avatar',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _emojis.map((emoji) {
              final selected = userProvider.profile.avatarEmoji == emoji;
              return GestureDetector(
                onTap: () async {
                  await userProvider.setAvatarEmoji(emoji);
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primarySurface
                        : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Text(emoji,
                      style: const TextStyle(fontSize: 28)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            'Background color',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _palette.map((color) {
              final selected =
                  userProvider.profile.avatarBgColor == color.toARGB32();
              return GestureDetector(
                onTap: () async {
                  await userProvider.setAvatarBgColor(color.toARGB32());
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.outline,
                      width: selected ? 2.5 : 1,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded,
                          size: 18, color: AppColors.primary)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
