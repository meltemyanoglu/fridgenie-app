import '../models/enums.dart';
import '../models/ingredient.dart';

/// Hand-curated ingredient catalog. ~50 items spanning every category — enough
/// to make the picker feel real without overwhelming.
class MockIngredients {
  MockIngredients._();

  static const List<Ingredient> all = [
    // ── Produce ─────────────────────────────────────────────────────────
    Ingredient(id: 'tomato', name: 'Tomato', emoji: '🍅', category: IngredientCategory.produce, common: true),
    Ingredient(id: 'onion', name: 'Onion', emoji: '🧅', category: IngredientCategory.produce, common: true),
    Ingredient(id: 'garlic', name: 'Garlic', emoji: '🧄', category: IngredientCategory.produce, common: true),
    Ingredient(id: 'spinach', name: 'Spinach', emoji: '🥬', category: IngredientCategory.produce, common: true),
    Ingredient(id: 'bell_pepper', name: 'Bell Pepper', emoji: '🫑', category: IngredientCategory.produce),
    Ingredient(id: 'carrot', name: 'Carrot', emoji: '🥕', category: IngredientCategory.produce, common: true),
    Ingredient(id: 'potato', name: 'Potato', emoji: '🥔', category: IngredientCategory.produce, common: true),
    Ingredient(id: 'broccoli', name: 'Broccoli', emoji: '🥦', category: IngredientCategory.produce),
    Ingredient(id: 'cucumber', name: 'Cucumber', emoji: '🥒', category: IngredientCategory.produce),
    Ingredient(id: 'mushroom', name: 'Mushroom', emoji: '🍄', category: IngredientCategory.produce),
    Ingredient(id: 'avocado', name: 'Avocado', emoji: '🥑', category: IngredientCategory.produce),
    Ingredient(id: 'lemon', name: 'Lemon', emoji: '🍋', category: IngredientCategory.produce, common: true),
    Ingredient(id: 'lime', name: 'Lime', emoji: '🟢', category: IngredientCategory.produce),
    Ingredient(id: 'corn', name: 'Corn', emoji: '🌽', category: IngredientCategory.produce),
    Ingredient(id: 'zucchini', name: 'Zucchini', emoji: '🥒', category: IngredientCategory.produce),
    Ingredient(id: 'eggplant', name: 'Eggplant', emoji: '🍆', category: IngredientCategory.produce),

    // ── Protein ─────────────────────────────────────────────────────────
    Ingredient(id: 'eggs', name: 'Eggs', emoji: '🥚', category: IngredientCategory.protein, common: true),
    Ingredient(id: 'chicken', name: 'Chicken', emoji: '🍗', category: IngredientCategory.protein, common: true),
    Ingredient(id: 'beef', name: 'Beef', emoji: '🥩', category: IngredientCategory.protein),
    Ingredient(id: 'salmon', name: 'Salmon', emoji: '🐟', category: IngredientCategory.protein),
    Ingredient(id: 'tuna', name: 'Tuna (canned)', emoji: '🥫', category: IngredientCategory.protein),
    Ingredient(id: 'tofu', name: 'Tofu', emoji: '🧈', category: IngredientCategory.protein),
    Ingredient(id: 'chickpeas', name: 'Chickpeas', emoji: '🫘', category: IngredientCategory.protein, common: true),
    Ingredient(id: 'lentils', name: 'Lentils', emoji: '🥣', category: IngredientCategory.protein),

    // ── Dairy ───────────────────────────────────────────────────────────
    Ingredient(id: 'cheese', name: 'Cheese', emoji: '🧀', category: IngredientCategory.dairy, common: true),
    Ingredient(id: 'feta', name: 'Feta', emoji: '🧀', category: IngredientCategory.dairy),
    Ingredient(id: 'milk', name: 'Milk', emoji: '🥛', category: IngredientCategory.dairy, common: true),
    Ingredient(id: 'yogurt', name: 'Yogurt', emoji: '🥛', category: IngredientCategory.dairy, common: true),
    Ingredient(id: 'butter', name: 'Butter', emoji: '🧈', category: IngredientCategory.dairy, common: true),
    Ingredient(id: 'cream', name: 'Cream', emoji: '🥛', category: IngredientCategory.dairy),

    // ── Grains ──────────────────────────────────────────────────────────
    Ingredient(id: 'rice', name: 'Rice', emoji: '🍚', category: IngredientCategory.grains, common: true),
    Ingredient(id: 'pasta', name: 'Pasta', emoji: '🍝', category: IngredientCategory.grains, common: true),
    Ingredient(id: 'bread', name: 'Bread', emoji: '🍞', category: IngredientCategory.grains, common: true),
    Ingredient(id: 'flour', name: 'Flour', emoji: '🌾', category: IngredientCategory.grains),
    Ingredient(id: 'oats', name: 'Oats', emoji: '🥣', category: IngredientCategory.grains),
    Ingredient(id: 'quinoa', name: 'Quinoa', emoji: '🌾', category: IngredientCategory.grains),
    Ingredient(id: 'tortilla', name: 'Tortilla', emoji: '🫓', category: IngredientCategory.grains),

    // ── Pantry ──────────────────────────────────────────────────────────
    Ingredient(id: 'olive_oil', name: 'Olive Oil', emoji: '🫒', category: IngredientCategory.pantry, common: true),
    Ingredient(id: 'tomato_sauce', name: 'Tomato Sauce', emoji: '🥫', category: IngredientCategory.pantry),
    Ingredient(id: 'beans', name: 'Beans', emoji: '🫘', category: IngredientCategory.pantry),
    Ingredient(id: 'sugar', name: 'Sugar', emoji: '🍬', category: IngredientCategory.pantry),
    Ingredient(id: 'honey', name: 'Honey', emoji: '🍯', category: IngredientCategory.pantry),

    // ── Herbs & spices ──────────────────────────────────────────────────
    Ingredient(id: 'basil', name: 'Basil', emoji: '🌿', category: IngredientCategory.herbs),
    Ingredient(id: 'parsley', name: 'Parsley', emoji: '🌿', category: IngredientCategory.herbs),
    Ingredient(id: 'cilantro', name: 'Cilantro', emoji: '🌿', category: IngredientCategory.herbs),
    Ingredient(id: 'chili', name: 'Chili Flakes', emoji: '🌶️', category: IngredientCategory.herbs),
    Ingredient(id: 'cumin', name: 'Cumin', emoji: '🌰', category: IngredientCategory.herbs),
    Ingredient(id: 'paprika', name: 'Paprika', emoji: '🌶️', category: IngredientCategory.herbs),
    Ingredient(id: 'ginger', name: 'Ginger', emoji: '🫚', category: IngredientCategory.herbs),

    // ── Condiments ──────────────────────────────────────────────────────
    Ingredient(id: 'soy_sauce', name: 'Soy Sauce', emoji: '🍶', category: IngredientCategory.condiments),
    Ingredient(id: 'mustard', name: 'Mustard', emoji: '🟡', category: IngredientCategory.condiments),
    Ingredient(id: 'mayo', name: 'Mayonnaise', emoji: '🥚', category: IngredientCategory.condiments),
    Ingredient(id: 'vinegar', name: 'Vinegar', emoji: '🍶', category: IngredientCategory.condiments),
  ];

  static Ingredient? byId(String id) {
    for (final ing in all) {
      if (ing.id == id) return ing;
    }
    return null;
  }

  static List<Ingredient> byCategory(IngredientCategory cat) =>
      all.where((i) => i.category == cat).toList();

  static List<Ingredient> get common =>
      all.where((i) => i.common).toList();
}
