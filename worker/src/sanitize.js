// Normalizes Gemini output into the exact API contract, even if the model bends the schema.

import {
  CUISINES,
  DIETARY_PREFERENCES,
  DIFFICULTY_LEVELS,
  LIMITS,
  MOODS,
  RECIPE_CATEGORIES,
} from "./config.js";
import { cleanStringList } from "./validation.js";

const DEFAULT_EMOJI = "🍽️";

/** Returns de-duplicated, lowercase ingredient names from a scan reply. */
export function sanitizeScanResult(raw) {
  return {
    ingredients: cleanStringList(raw?.ingredients, {
      maxItems: LIMITS.scanMaxIngredients,
      maxChars: LIMITS.ingredientNameChars,
      lowercase: true,
    }),
  };
}

/** Returns the valid recipes from a generation reply; invalid entries are dropped. */
export function sanitizeRecipes(raw) {
  const list = Array.isArray(raw?.recipes) ? raw.recipes : [];
  return list.map(sanitizeRecipe).filter((recipe) => recipe !== null);
}

function sanitizeRecipe(raw) {
  if (raw === null || typeof raw !== "object") return null;

  const title = text(raw.title, 80);
  const ingredients = names(raw.ingredients);
  const steps = sanitizeSteps(raw.steps);
  if (!title || ingredients.length === 0 || steps.length === 0) return null;

  return {
    title,
    tagline: text(raw.tagline, 80),
    emoji: emoji(raw.emoji),
    category: oneOf(raw.category, RECIPE_CATEGORIES, "comfort"),
    difficulty: oneOf(raw.difficulty, DIFFICULTY_LEVELS, "easy"),
    cookMinutes: clampInt(raw.cookMinutes, 1, 600, 25),
    servings: clampInt(raw.servings, 1, 12, 2),
    nutrition: {
      calories: clampInt(raw.nutrition?.calories, 0, 5000, 0),
      proteinG: clampInt(raw.nutrition?.proteinG, 0, 500, 0),
      carbsG: clampInt(raw.nutrition?.carbsG, 0, 1000, 0),
      fatG: clampInt(raw.nutrition?.fatG, 0, 500, 0),
    },
    ingredients,
    optionalIngredients: names(raw.optionalIngredients),
    steps,
    substitutions: sanitizeSubstitutions(raw.substitutions),
    moods: enumList(raw.moods, MOODS),
    cuisines: enumList(raw.cuisines, CUISINES),
    dietary: enumList(raw.dietary, DIETARY_PREFERENCES),
    whyRecommended: text(raw.whyRecommended, LIMITS.recipeTextChars),
    tags: cleanStringList(raw.tags, { maxItems: 6, maxChars: 30, lowercase: true }),
  };
}

/** Keeps steps with text and renumbers them 1..n so ordering never depends on the model. */
function sanitizeSteps(value) {
  if (!Array.isArray(value)) return [];
  return value
    .map((step) => ({ text: text(step?.text, LIMITS.recipeTextChars), minutes: step?.minutes }))
    .filter((step) => step.text)
    .map((step, index) => {
      const minutes = clampInt(step.minutes, 1, 600, null);
      return minutes === null
        ? { order: index + 1, text: step.text }
        : { order: index + 1, text: step.text, minutes };
    });
}

function sanitizeSubstitutions(value) {
  if (!Array.isArray(value)) return [];
  return value
    .map((sub) => ({
      missing: text(sub?.missing, LIMITS.ingredientNameChars).toLowerCase(),
      swap: text(sub?.swap, LIMITS.ingredientNameChars).toLowerCase(),
      reason: text(sub?.reason, 160),
    }))
    .filter((sub) => sub.missing && sub.swap)
    .slice(0, 6);
}

function names(value) {
  return cleanStringList(value, {
    maxItems: LIMITS.recipeMaxInputIngredients,
    maxChars: LIMITS.ingredientNameChars,
    lowercase: true,
  });
}

function text(value, maxChars) {
  return typeof value === "string" ? value.trim().slice(0, maxChars) : "";
}

/** Caps by code points (not UTF-16 units) so multi-part emoji are never split in half. */
function emoji(value) {
  if (typeof value !== "string") return DEFAULT_EMOJI;
  const trimmed = Array.from(value.trim()).slice(0, 8).join("");
  return trimmed || DEFAULT_EMOJI;
}

function oneOf(value, allowed, fallback) {
  return typeof value === "string" && allowed.includes(value) ? value : fallback;
}

function enumList(value, allowed) {
  if (!Array.isArray(value)) return [];
  return [...new Set(value.filter((v) => typeof v === "string" && allowed.includes(v)))];
}

function clampInt(value, min, max, fallback) {
  const number = Number(value);
  if (value === null || value === undefined || !Number.isFinite(number)) return fallback;
  return Math.min(max, Math.max(min, Math.round(number)));
}
