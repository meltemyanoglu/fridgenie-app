// Gemini structured-output schemas (OpenAPI subset), so replies are valid JSON in the expected shape.

import {
  CUISINES,
  DIETARY_PREFERENCES,
  DIFFICULTY_LEVELS,
  LIMITS,
  MOODS,
  RECIPE_CATEGORIES,
} from "./config.js";

const stringEnum = (values) => ({ type: "STRING", enum: [...values] });
const stringArray = (extra = {}) => ({ type: "ARRAY", items: { type: "STRING" }, ...extra });

export const SCAN_RESPONSE_SCHEMA = Object.freeze({
  type: "OBJECT",
  properties: {
    ingredients: stringArray({ maxItems: LIMITS.scanMaxIngredients }),
  },
  required: ["ingredients"],
});

const RECIPE_SCHEMA = {
  type: "OBJECT",
  properties: {
    title: { type: "STRING" },
    tagline: { type: "STRING" },
    emoji: { type: "STRING" },
    category: stringEnum(RECIPE_CATEGORIES),
    difficulty: stringEnum(DIFFICULTY_LEVELS),
    cookMinutes: { type: "INTEGER" },
    servings: { type: "INTEGER" },
    nutrition: {
      type: "OBJECT",
      properties: {
        calories: { type: "INTEGER" },
        proteinG: { type: "INTEGER" },
        carbsG: { type: "INTEGER" },
        fatG: { type: "INTEGER" },
      },
      required: ["calories", "proteinG", "carbsG", "fatG"],
    },
    ingredients: stringArray({ minItems: 1 }),
    optionalIngredients: stringArray(),
    steps: {
      type: "ARRAY",
      minItems: 3,
      maxItems: 8,
      items: {
        type: "OBJECT",
        properties: {
          text: { type: "STRING" },
          minutes: { type: "INTEGER" },
        },
        required: ["text"],
      },
    },
    substitutions: {
      type: "ARRAY",
      items: {
        type: "OBJECT",
        properties: {
          missing: { type: "STRING" },
          swap: { type: "STRING" },
          reason: { type: "STRING" },
        },
        required: ["missing", "swap", "reason"],
      },
    },
    moods: { type: "ARRAY", items: stringEnum(MOODS) },
    cuisines: { type: "ARRAY", items: stringEnum(CUISINES) },
    dietary: { type: "ARRAY", items: stringEnum(DIETARY_PREFERENCES) },
    whyRecommended: { type: "STRING" },
    tags: stringArray({ maxItems: 6 }),
  },
  required: [
    "title",
    "tagline",
    "emoji",
    "category",
    "difficulty",
    "cookMinutes",
    "servings",
    "nutrition",
    "ingredients",
    "steps",
    "moods",
    "cuisines",
    "dietary",
    "whyRecommended",
  ],
};

/** Schema for exactly `count` recipes wrapped in `{ recipes: [...] }`. */
export function recipesResponseSchema(count) {
  return {
    type: "OBJECT",
    properties: {
      recipes: { type: "ARRAY", items: RECIPE_SCHEMA, minItems: count, maxItems: count },
    },
    required: ["recipes"],
  };
}
