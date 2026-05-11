import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/badge.dart';
import '../../providers/user_provider.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Badges')),
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
              'Cook to collect.',
              style: context.text.displaySmall,
            ),
            const SizedBox(height: 6),
            Text(
              '${user.earnedBadgeCount} of ${user.badges.length} unlocked.',
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            ...user.badges.map((b) => _BadgeRow(badge: b)),
          ],
        ),
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  final CookingBadge badge;
  const _BadgeRow({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: badge.earned ? AppColors.surface : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: badge.earned ? AppColors.primary : AppColors.outline,
          width: 1.4,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Opacity(
            opacity: badge.earned ? 1.0 : 0.4,
            child: Image.asset(
              badge.assetPath,
              width: 64,
              height: 64,
              errorBuilder: (_, __, ___) => Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: badge.earned ? AppColors.leafGradient : null,
                  color: badge.earned ? null : AppColors.outline,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text(badge.emoji,
                    style: const TextStyle(fontSize: 32)),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        badge.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (badge.earned)
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary, size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  badge.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: badge.progress / 100,
                          minHeight: 6,
                          backgroundColor: AppColors.outline,
                          valueColor: AlwaysStoppedAnimation(
                            badge.earned
                                ? AppColors.primary
                                : AppColors.citrusDeep,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${badge.progress}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
