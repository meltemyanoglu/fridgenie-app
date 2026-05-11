import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// Horizontally-scrolling pill-tab bar for category filters.
class PillTabBar<T> extends StatelessWidget {
  final List<PillTab<T>> tabs;
  final T? selected;
  final ValueChanged<T?> onSelected;
  final bool allowAll;
  final String allLabel;

  const PillTabBar({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
    this.allowAll = true,
    this.allLabel = 'All',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 0),
        children: [
          if (allowAll)
            _Pill(
              label: allLabel,
              emoji: '✨',
              color: AppColors.primary,
              selected: selected == null,
              onTap: () => onSelected(null),
            ),
          for (final tab in tabs) ...[
            const SizedBox(width: 8),
            _Pill(
              label: tab.label,
              emoji: tab.emoji,
              color: tab.color,
              selected: selected == tab.value,
              onTap: () => onSelected(tab.value),
            ),
          ],
        ],
      ),
    );
  }
}

class PillTab<T> {
  final T value;
  final String label;
  final String emoji;
  final Color color;
  const PillTab({
    required this.value,
    required this.label,
    required this.emoji,
    required this.color,
  });
}

class _Pill extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.emoji,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: selected ? color : AppColors.outline,
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
