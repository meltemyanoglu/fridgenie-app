/// Every on-device storage key in one place, all prefixed `fridgenie.`.
class StorageKeys {
  StorageKeys._();

  /// Bumped when stored data changes shape; see StoreMigrations.
  static const schemaVersion = 'fridgenie.schema_version';
  static const deviceId = 'fridgenie.device_id';

  // Fridge
  static const inventory = 'fridgenie.inventory';
  static const selected = 'fridgenie.selected';

  // Recipes
  static const generatedRecipes = 'fridgenie.generated_recipes';
  static const favoriteRecipes = 'fridgenie.favorite_recipes';

  /// Schema 1 only: favorite ids and titles, replaced by favoriteRecipes.
  static const legacyFavorites = 'fridgenie.favorites';
  static const legacyFavoriteTitles = 'fridgenie.favorite_titles';

  // Grocery
  static const groceryList = 'fridgenie.grocery_list';

  // User profile
  static const onboardingDone = 'fridgenie.onboarding_done';
  static const name = 'fridgenie.name';
  static const dietary = 'fridgenie.dietary';
  static const skill = 'fridgenie.skill';
  static const cuisines = 'fridgenie.cuisines';
  static const mood = 'fridgenie.mood';
  static const avatarEmoji = 'fridgenie.avatar_emoji';
  static const avatarBgColor = 'fridgenie.avatar_bg_color';
  static const recipesCooked = 'fridgenie.recipes_cooked';
  static const currentStreak = 'fridgenie.current_streak';
  static const longestStreak = 'fridgenie.longest_streak';
}
