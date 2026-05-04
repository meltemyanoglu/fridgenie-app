import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/enums.dart';

class DietaryPage extends StatelessWidget {
  final Set<DietaryPreference> selected;
  final ValueChanged<Set<DietaryPreference>> onChanged;

  const DietaryPage({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  void _toggle(DietaryPreference pref) {
    final next = Set<DietaryPreference>.from(selected);
    if (pref == DietaryPreference.noRestrictions) {
      next
        ..clear()
        ..add(DietaryPreference.noRestrictions);
    } else {
      next.remove(DietaryPreference.noRestrictions);
      if (next.contains(pref)) {
        next.remove(pref);
      } else {
        next.add(pref);
      }
      if (next.isEmpty) next.add(DietaryPreference.noRestrictions);
    }
    onChanged(next);
  }

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
            'Anything I should\nleave off your plate?',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pick any that apply. You can change these later.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: DietaryPreference.values.map((p) {
              final isSelected = selected.contains(p);
              return _Choice(
                label: p.label,
                emoji: p.emoji,
                selected: isSelected,
                onTap: () => _toggle(p),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;
  const _Choice({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outline,
            width: 1.4,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    offset: const Offset(0, 6),
                    blurRadius: 14,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
