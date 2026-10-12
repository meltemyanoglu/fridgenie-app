// Central limits and enum lists shared by validation, prompts and response schemas.
// Enum values match the Dart enum `.name` values in lib/data/models/enums.dart.

export const API_VERSION = "v1";

export const DEFAULT_GEMINI_MODEL = "gemini-3.5-flash-lite";
export const GEMINI_BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models";
export const GEMINI_TIMEOUT_MS = 25_000;
export const GEMINI_RETRY_DELAY_MS = 600;

export const LIMITS = Object.freeze({
  scanBodyBytes: 8_000_000,
  recipeBodyBytes: 32_000,
  imageBase64Chars: 7_000_000,
  scanMaxIngredients: 15,
  recipeMaxInputIngredients: 30,
  ingredientNameChars: 40,
  avoidTitlesMax: 20,
  avoidTitleChars: 80,
  recipeCountMin: 1,
  recipeCountMax: 4,
  recipeTextChars: 600,
});

export const IMAGE_MIME_TYPES = Object.freeze([
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/heic",
  "image/heif",
]);

export const RECIPE_CATEGORIES = Object.freeze(["comfort", "healthy", "quick", "budget", "useItUp"]);

export const DIFFICULTY_LEVELS = Object.freeze(["easy", "medium", "hard"]);

export const MOODS = Object.freeze(["cozy", "energetic", "calm", "celebratory", "adventurous", "comforted"]);

export const CUISINES = Object.freeze([
  "italian",
  "mexican",
  "japanese",
  "indian",
  "mediterranean",
  "middleEastern",
  "turkish",
  "korean",
  "thai",
  "chinese",
  "french",
  "american",
]);

export const DIETARY_PREFERENCES = Object.freeze([
  "vegetarian",
  "vegan",
  "pescatarian",
  "glutenFree",
  "dairyFree",
  "keto",
  "halal",
  "kosher",
  "noRestrictions",
]);

export const COOKING_SKILLS = Object.freeze(["beginner", "comfortable", "confident", "pro"]);

export const GENIE_MODES = Object.freeze([
  "standard",
  "surpriseMe",
  "challenge3",
  "leftoversRescue",
  "healthyQuick",
  "moodBased",
]);
