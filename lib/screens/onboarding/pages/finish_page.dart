import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/enums.dart';

class FinishPage extends StatelessWidget {
  final String name;
  final CookingSkill skill;
  final Set<CuisineType> cuisines;
  final Mood mood;

  const FinishPage({
    super.key,
    required this.name,
    required this.skill,
    required this.cuisines,
    required this.mood,
  });

  @override
  Widget build(BuildContext context) {
    final cuisineList = cuisines.isEmpty
        ? 'all cuisines'
        : cuisines.map((c) => c.label).take(3).join(', ');
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHPadding,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🧞‍♂️', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 14),
                Text(
                  'You\'re ready, ${name.isEmpty ? 'Chef' : name}.',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'I\'ll start with $cuisineList — tuned to your ${mood.label.toLowerCase()} mood and ${skill.label.toLowerCase()} skill.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          _Bullet(
            emoji: '🥚',
            title: 'Add what\'s in your fridge',
            body: 'Tap or scan ingredients — I\'ll learn what you usually keep around.',
          ),
          _Bullet(
            emoji: '✨',
            title: 'Hit Generate Meals',
            body: 'I rank recipes by how well they match your fridge, mood, and tastes.',
          ),
          _Bullet(
            emoji: '🔥',
            title: 'Cook to keep your streak',
            body: 'Daily streaks, badges, and Genie tips make small cooking wins stick.',
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String emoji;
  final String title;
  final String body;
  const _Bullet({required this.emoji, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.outline),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(body,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
