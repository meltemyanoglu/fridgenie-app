import '../models/enums.dart';
import '../models/ingredient.dart';

class MockIngredients {
  MockIngredients._();

  static const List<Ingredient> all = [
    // ── Produce ─────────────────────────────────────────────────────────
    Ingredient(id: 'tomato',      name: 'Tomato',       emoji: '🍅', category: IngredientCategory.produce, common: true),
    Ingredient(id: 'onion',       name: 'Onion',        emoji: '🧅', category: IngredientCategory.produce, common: true),
    Ingredient(id: 'garlic',      name: 'Garlic',       emoji: '🧄', category: IngredientCategory.produce, common: true),
    Ingredient(id: 'spinach',     name: 'Spinach',      emoji: '🥬', category: IngredientCategory.produce, common: true),
    Ingredient(id: 'bell_pepper', name: 'Bell Pepper',  emoji: '🫑', category: IngredientCategory.produce, common: true),
    Ingredient(id: 'carrot',      name: 'Carrot',       emoji: '🥕', category: IngredientCategory.produce, common: true),
    Ingredient(id: 'potato',      name: 'Potato',       emoji: '🥔', category: IngredientCategory.produce, common: true),
    Ingredient(id: 'broccoli',    name: 'Broccoli',     emoji: '🥦', category: IngredientCategory.produce, common: true),
    Ingredient(id: 'cucumber',    name: 'Cucumber',     emoji: '🥒', category: IngredientCategory.produce, common: true),
    Ingredient(id: 'mushroom',    name: 'Mushroom',     emoji: '🍄', category: IngredientCategory.produce, common: true),
    Ingredient(id: 'avocado',     name: 'Avocado',      emoji: '🥑', category: IngredientCategory.produce, common: true),
    Ingredient(id: 'lemon',       name: 'Lemon',        emoji: '🍋', category: IngredientCategory.produce, common: true),
    Ingredient(id: 'lime',        name: 'Lime',         emoji: '🟢', category: IngredientCategory.produce, common: true),
    Ingredient(id: 'corn',        name: 'Corn',         emoji: '🌽', category: IngredientCategory.produce, common: true),
    Ingredient(id: 'zucchini',    name: 'Zucchini',     emoji: '🥒', category: IngredientCategory.produce, common: true),
    Ingredient(id: 'eggplant',    name: 'Eggplant',     emoji: '🍆', category: IngredientCategory.produce, common: true),
    Ingredient(id: 'sweet_potato',name: 'Sweet Potato', emoji: '🍠', category: IngredientCategory.produce, common: true),
    Ingredient(id: 'lettuce',     name: 'Lettuce',      emoji: '🥗', category: IngredientCategory.produce, common: true),
    Ingredient(id: 'celery',      name: 'Celery',       emoji: '🌿', category: IngredientCategory.produce, common: true),
    Ingredient(id: 'green_bean',  name: 'Green Beans',  emoji: '🫘', category: IngredientCategory.produce, common: true),
    Ingredient(id: 'peas',        name: 'Peas',         emoji: '🟢', category: IngredientCategory.produce, common: true),
    Ingredient(id: 'cabbage',     name: 'Cabbage',      emoji: '🥬', category: IngredientCategory.produce, common: true),
    Ingredient(id: 'cauliflower', name: 'Cauliflower',  emoji: '🥦', category: IngredientCategory.produce, common: true),
    Ingredient(id: 'leek',        name: 'Leek',         emoji: '🧅', category: IngredientCategory.produce),
    Ingredient(id: 'asparagus',   name: 'Asparagus',    emoji: '🌿', category: IngredientCategory.produce),

    // ── Protein ─────────────────────────────────────────────────────────
    Ingredient(id: 'eggs',        name: 'Eggs',         emoji: '🥚', category: IngredientCategory.protein, common: true),
    Ingredient(id: 'chicken',     name: 'Chicken',      emoji: '🍗', category: IngredientCategory.protein, common: true),
    Ingredient(id: 'beef',        name: 'Beef',         emoji: '🥩', category: IngredientCategory.protein, common: true),
    Ingredient(id: 'salmon',      name: 'Salmon',       emoji: '🐟', category: IngredientCategory.protein, common: true),
    Ingredient(id: 'tuna',        name: 'Tuna',         emoji: '🥫', category: IngredientCategory.protein, common: true),
    Ingredient(id: 'tofu',        name: 'Tofu',         emoji: '🧈', category: IngredientCategory.protein, common: true),
    Ingredient(id: 'chickpeas',   name: 'Chickpeas',    emoji: '🫘', category: IngredientCategory.protein, common: true),
    Ingredient(id: 'lentils',     name: 'Lentils',      emoji: '🥣', category: IngredientCategory.protein, common: true),
    Ingredient(id: 'shrimp',      name: 'Shrimp',       emoji: '🍤', category: IngredientCategory.protein, common: true),
    Ingredient(id: 'lamb',        name: 'Lamb',         emoji: '🥩', category: IngredientCategory.protein, common: true),
    Ingredient(id: 'turkey',      name: 'Turkey',       emoji: '🍗', category: IngredientCategory.protein, common: true),
    Ingredient(id: 'black_beans', name: 'Black Beans',  emoji: '🫘', category: IngredientCategory.protein, common: true),
    Ingredient(id: 'sardines',    name: 'Sardines',     emoji: '🐟', category: IngredientCategory.protein),
    Ingredient(id: 'pork',        name: 'Pork',         emoji: '🥩', category: IngredientCategory.protein),

    // ── Dairy ───────────────────────────────────────────────────────────
    Ingredient(id: 'cheese',      name: 'Cheese',       emoji: '🧀', category: IngredientCategory.dairy, common: true),
    Ingredient(id: 'feta',        name: 'Feta',         emoji: '🧀', category: IngredientCategory.dairy, common: true),
    Ingredient(id: 'milk',        name: 'Milk',         emoji: '🥛', category: IngredientCategory.dairy, common: true),
    Ingredient(id: 'yogurt',      name: 'Yogurt',       emoji: '🥛', category: IngredientCategory.dairy, common: true),
    Ingredient(id: 'butter',      name: 'Butter',       emoji: '🧈', category: IngredientCategory.dairy, common: true),
    Ingredient(id: 'cream',       name: 'Cream',        emoji: '🥛', category: IngredientCategory.dairy, common: true),
    Ingredient(id: 'mozzarella',  name: 'Mozzarella',   emoji: '🧀', category: IngredientCategory.dairy, common: true),
    Ingredient(id: 'parmesan',    name: 'Parmesan',     emoji: '🧀', category: IngredientCategory.dairy, common: true),

    // ── Grains ──────────────────────────────────────────────────────────
    Ingredient(id: 'rice',        name: 'Rice',         emoji: '🍚', category: IngredientCategory.grains, common: true),
    Ingredient(id: 'pasta',       name: 'Pasta',        emoji: '🍝', category: IngredientCategory.grains, common: true),
    Ingredient(id: 'bread',       name: 'Bread',        emoji: '🍞', category: IngredientCategory.grains, common: true),
    Ingredient(id: 'flour',       name: 'Flour',        emoji: '🌾', category: IngredientCategory.grains, common: true),
    Ingredient(id: 'oats',        name: 'Oats',         emoji: '🥣', category: IngredientCategory.grains, common: true),
    Ingredient(id: 'quinoa',      name: 'Quinoa',       emoji: '🌾', category: IngredientCategory.grains, common: true),
    Ingredient(id: 'tortilla',    name: 'Tortilla',     emoji: '🫓', category: IngredientCategory.grains, common: true),
    Ingredient(id: 'couscous',    name: 'Couscous',     emoji: '🍚', category: IngredientCategory.grains, common: true),
    Ingredient(id: 'pita',        name: 'Pita Bread',   emoji: '🫓', category: IngredientCategory.grains, common: true),
    Ingredient(id: 'noodles',     name: 'Noodles',      emoji: '🍜', category: IngredientCategory.grains, common: true),

    // ── Pantry ──────────────────────────────────────────────────────────
    Ingredient(id: 'olive_oil',    name: 'Olive Oil',    emoji: '🫒', category: IngredientCategory.pantry, common: true),
    Ingredient(id: 'tomato_sauce', name: 'Tomato Sauce', emoji: '🥫', category: IngredientCategory.pantry, common: true),
    Ingredient(id: 'beans',        name: 'Beans',        emoji: '🫘', category: IngredientCategory.pantry, common: true),
    Ingredient(id: 'sugar',        name: 'Sugar',        emoji: '🍬', category: IngredientCategory.pantry, common: true),
    Ingredient(id: 'honey',        name: 'Honey',        emoji: '🍯', category: IngredientCategory.pantry, common: true),
    Ingredient(id: 'coconut_milk', name: 'Coconut Milk', emoji: '🥥', category: IngredientCategory.pantry, common: true),
    Ingredient(id: 'stock',        name: 'Broth/Stock',  emoji: '🍵', category: IngredientCategory.pantry, common: true),
    Ingredient(id: 'canned_tomato',name: 'Canned Tomatoes',emoji: '🥫', category: IngredientCategory.pantry, common: true),

    // ── Herbs & spices ──────────────────────────────────────────────────
    Ingredient(id: 'basil',     name: 'Basil',        emoji: '🌿', category: IngredientCategory.herbs, common: true),
    Ingredient(id: 'parsley',   name: 'Parsley',      emoji: '🌿', category: IngredientCategory.herbs, common: true),
    Ingredient(id: 'cilantro',  name: 'Cilantro',     emoji: '🌿', category: IngredientCategory.herbs, common: true),
    Ingredient(id: 'chili',     name: 'Chili Flakes', emoji: '🌶️', category: IngredientCategory.herbs, common: true),
    Ingredient(id: 'cumin',     name: 'Cumin',        emoji: '🌰', category: IngredientCategory.herbs, common: true),
    Ingredient(id: 'paprika',   name: 'Paprika',      emoji: '🌶️', category: IngredientCategory.herbs, common: true),
    Ingredient(id: 'ginger',    name: 'Ginger',       emoji: '🫚', category: IngredientCategory.herbs, common: true),
    Ingredient(id: 'turmeric',  name: 'Turmeric',     emoji: '🌿', category: IngredientCategory.herbs, common: true),
    Ingredient(id: 'oregano',   name: 'Oregano',      emoji: '🌿', category: IngredientCategory.herbs, common: true),
    Ingredient(id: 'thyme',     name: 'Thyme',        emoji: '🌿', category: IngredientCategory.herbs, common: true),
    Ingredient(id: 'rosemary',  name: 'Rosemary',     emoji: '🌿', category: IngredientCategory.herbs, common: true),
    Ingredient(id: 'cinnamon',  name: 'Cinnamon',     emoji: '🌰', category: IngredientCategory.herbs, common: true),

    // ── Condiments ──────────────────────────────────────────────────────
    Ingredient(id: 'soy_sauce',   name: 'Soy Sauce',   emoji: '🍶', category: IngredientCategory.condiments, common: true),
    Ingredient(id: 'mustard',     name: 'Mustard',     emoji: '🟡', category: IngredientCategory.condiments, common: true),
    Ingredient(id: 'mayo',        name: 'Mayonnaise',  emoji: '🥚', category: IngredientCategory.condiments, common: true),
    Ingredient(id: 'vinegar',     name: 'Vinegar',     emoji: '🍶', category: IngredientCategory.condiments, common: true),
    Ingredient(id: 'hot_sauce',   name: 'Hot Sauce',   emoji: '🌶️', category: IngredientCategory.condiments, common: true),
    Ingredient(id: 'ketchup',     name: 'Ketchup',     emoji: '🍅', category: IngredientCategory.condiments, common: true),
    Ingredient(id: 'tahini',      name: 'Tahini',      emoji: '🫙', category: IngredientCategory.condiments, common: true),
    Ingredient(id: 'peanut_butter',name: 'Peanut Butter',emoji: '🥜', category: IngredientCategory.condiments, common: true),
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
