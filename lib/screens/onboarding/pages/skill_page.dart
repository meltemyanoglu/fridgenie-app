import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/enums.dart';

class SkillPage extends StatelessWidget {
  final CookingSkill selected;
  final ValueChanged<CookingSkill> onChanged;

  const SkillPage({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHPadding,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text(
            'How comfortable are you in the kitchen?',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'I\'ll match recipes to your skill — no shame in any answer.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xxl),
          ...CookingSkill.values.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _SkillRow(
                skill: s,
                selected: selected == s,
                onTap: () => onChanged(s),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  final CookingSkill skill;
  final bool selected;
  final VoidCallback onTap;

  const _SkillRow({
    required this.skill,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outline,
            width: 1.6,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Text(skill.emoji, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skill.label,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    skill.tagline,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.outline,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
