import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../data/models/ingredient.dart';

/// Playful ingredient chip with emoji + name. Two visual modes:
/// - selectable (toggle look)
/// - dismissible (used in selection trays)
class IngredientChip extends StatelessWidget {
  final Ingredient ingredient;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool compact;

  const IngredientChip({
    super.key,
    required this.ingredient,
    this.selected = false,
    this.onTap,
    this.onRemove,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.primary : AppColors.surface;
    final fg = selected ? AppColors.textOnPrimary : AppColors.textPrimary;
    final border = selected ? AppColors.primary : AppColors.outline;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: border, width: 1.4),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  offset: const Offset(0, 4),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(ingredient.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                ingredient.name,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 13 : 14,
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onRemove,
                  child: Icon(Icons.close_rounded, size: 16, color: fg),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
