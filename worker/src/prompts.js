// Prompt builders for scanning and recipe generation; output shape is enforced by schemas.js.

import { CUISINES } from "./config.js";

export const SCAN_PROMPT = [
  "You are the ingredient detector of Fridgenie, a smart cooking app.",
  "Identify the edible food and drink items clearly visible in this fridge or pantry photo.",
  "Rules:",
  "- Use lowercase, singular, simple common names (\"tomato\", not \"Roma tomatoes\").",
  "- Ignore containers, brands, packaging text and anything not edible.",
  "- Do not guess items you cannot actually see.",
  "- Return an empty list if nothing is identifiable.",
].join("\n");

const DIETARY_LABELS = Object.freeze({
  vegetarian: "vegetarian",
  vegan: "vegan",
  pescatarian: "pescatarian",
  glutenFree: "gluten-free",
  dairyFree: "dairy-free",
  keto: "keto",
  halal: "halal",
  kosher: "kosher",
});

const MODE_INSTRUCTIONS = Object.freeze({
  standard: "Create well-balanced, satisfying recipes.",
  surpriseMe: "Be creative and surprising: combine ingredients in an unexpected but delightful way.",
  challenge3: "CHALLENGE: use ONLY the first 3 listed ingredients plus basic staples. Keep it minimal and clever.",
  leftoversRescue: "LEFTOVER RESCUE: use as many listed ingredients as possible to reduce food waste.",
  healthyQuick: "HEALTHY & QUICK: under 20 minutes, high protein, lower calorie, nutrient-dense.",
  moodBased: "MOOD COOKING: tailor flavors, textures and presentation to the user's current mood.",
});

/** Builds the recipe prompt from a validated request (see validation.parseRecipeRequest). */
export function buildRecipePrompt(request, random = Math.random) {
  const { ingredients, mode, count, dietary, mood, cuisine, skill, avoidTitles } = request;
  const restrictions = dietary.filter((d) => d !== "noRestrictions").map((d) => DIETARY_LABELS[d]);
  const cuisineHint = cuisine ?? CUISINES[Math.floor(random() * CUISINES.length)];

  const lines = [
    "You are Fridgenie, a warm and creative home chef.",
    count === 1
      ? "Invent exactly ONE realistic recipe."
      : `Invent exactly ${count} realistic, clearly different recipes.`,
    ingredients.length > 0
      ? `Available ingredients: ${ingredients.join(", ")}.`
      : "The fridge is empty: invent a recipe from common, inexpensive ingredients.",
    "Basic staples may be assumed: salt, pepper, oil, water.",
    restrictions.length > 0
      ? `Every recipe MUST satisfy ALL of these dietary requirements: ${restrictions.join(", ")}.`
      : "",
    mood ? `User mood: ${mood}.` : "",
    cuisine
      ? `Preferred cuisine: ${cuisine}.`
      : `Cuisine inspiration: ${cuisineHint} (adapt if the ingredients clearly suit another cuisine).`,
    skill ? `Cooking skill level: ${skill}.` : "",
    MODE_INSTRUCTIONS[mode],
    avoidTitles.length > 0 ? `Do NOT reuse these recipe titles: ${avoidTitles.join("; ")}.` : "",
    "Field rules:",
    "- tagline: one catchy line, at most 60 characters.",
    "- emoji: a single food emoji.",
    "- ingredients: simple lowercase names of everything the recipe needs, excluding basic staples.",
    "- steps: 4 to 7 clear steps; minutes only where the step takes time.",
    "- dietary: only the requirements the recipe truly satisfies.",
    "- whyRecommended: 1 to 2 sentences on why it fits the user right now.",
  ];

  return lines.filter(Boolean).join("\n");
}
