import 'enums.dart';

class Ingredient {
  final String id;
  final String name;
  final String emoji;
  final IngredientCategory category;
  final bool common; // shown in quick-pick

  const Ingredient({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    this.common = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ingredient && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
