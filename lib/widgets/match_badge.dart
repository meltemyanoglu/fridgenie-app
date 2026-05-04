import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// Pill that shows ingredient match percentage on a recipe card.
class MatchBadge extends StatelessWidget {
  final int percent;
  final bool dark;

  const MatchBadge({super.key, required this.percent, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final color = percent >= 80
        ? AppColors.primary
        : percent >= 50
            ? AppColors.citrusDeep
            : AppColors.tomato;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: 0.92) : color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$percent% match',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
