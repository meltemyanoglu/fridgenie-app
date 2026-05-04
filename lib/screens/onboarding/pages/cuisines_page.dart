import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/enums.dart';

class CuisinesPage extends StatelessWidget {
  final Set<CuisineType> selected;
  final ValueChanged<Set<CuisineType>> onChanged;

  const CuisinesPage({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  void _toggle(CuisineType c) {
    final next = Set<CuisineType>.from(selected);
    if (next.contains(c)) {
      next.remove(c);
    } else {
      next.add(c);
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
            'Which kitchens do\nyou love living in?',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pick at least one — I\'ll lean into these in your daily picks.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: CuisineType.values.map((c) {
              final isSelected = selected.contains(c);
              return GestureDetector(
                onTap: () => _toggle(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 110,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.primarySurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.outline,
                      width: 1.6,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(c.emoji, style: const TextStyle(fontSize: 30)),
                      const SizedBox(height: 6),
                      Text(
                        c.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isSelected
                              ? AppColors.primaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
