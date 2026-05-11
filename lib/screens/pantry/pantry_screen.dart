import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions.dart';
import '../../data/mock/mock_ingredients.dart';
import '../../data/models/enums.dart';
import '../../data/models/ingredient.dart';
import '../../providers/fridge_provider.dart';
import '../../routes.dart';
import '../../widgets/fridge_door_widget.dart';
import '../../widgets/ingredient_chip.dart';
import '../../widgets/section_header.dart';

/// Inventory manager. User adds/removes what they have at home; selections
/// drive Home/Discover suggestions. Includes ingredient search, category
/// jump, and a CTA to launch the AI photo scan.
class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  String _query = '';
  IngredientCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final fridge = context.watch<FridgeProvider>();
    final all = MockIngredients.all.where((i) {
      final q = _query.trim().toLowerCase();
      final matchesQuery = q.isEmpty || i.name.toLowerCase().contains(q);
      final matchesCat = _filter == null || i.category == _filter;
      return matchesQuery && matchesCat;
    }).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHPadding,
          AppSpacing.lg,
          AppSpacing.pageHPadding,
          AppSpacing.huge,
        ),
        children: [
          Text('Your fridge', style: context.text.headlineLarge),
          const SizedBox(height: 4),
          Text(
            '${fridge.inventoryIds.length} items in pantry · ${fridge.selectedIds.length} chosen for cooking',
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),

          FridgeDoorWidget(
            inventoryIds: fridge.inventoryIds,
            selectedIds: fridge.selectedIds,
            onToggleSelected: fridge.toggleSelected,
            onScanTap: () => Navigator.of(context).pushNamed(AppRoutes.scan),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Search
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Search ingredients…',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Category filter
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _CatChip(
                  label: 'All',
                  emoji: '🧺',
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                for (final c in IngredientCategory.values) ...[
                  const SizedBox(width: 8),
                  _CatChip(
                    label: c.label,
                    emoji: c.emoji,
                    selected: _filter == c,
                    onTap: () => setState(() => _filter = c),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // In-pantry section
          if (fridge.inventory.isNotEmpty) ...[
            SectionHeader(
              title: 'In your fridge',
              subtitle: 'Tap to use in tonight\'s suggestions',
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: fridge.inventory.map((ing) {
                return IngredientChip(
                  ingredient: ing,
                  compact: true,
                  selected: fridge.isSelected(ing.id),
                  onTap: () => fridge.toggleSelected(ing.id),
                  onRemove: () => fridge.toggleInventory(ing.id),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Catalog
          SectionHeader(
            title: 'Add ingredients',
            subtitle: 'Tap to add to your fridge',
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: all
                .where((i) => !fridge.isInInventory(i.id))
                .map((ing) => _AddChip(
                      ingredient: ing,
                      onTap: () => fridge.toggleInventory(ing.id),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;
  const _CatChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outline,
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  final Ingredient ingredient;
  final VoidCallback onTap;
  const _AddChip({required this.ingredient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(color: AppColors.outline, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ingredient.emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              ingredient.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.add_rounded,
                size: 14, color: AppColors.primaryDark),
          ],
        ),
      ),
    );
  }
}
