// POST /v1/recipes: generates 1..4 recipes from the user's ingredients and preferences.

import { LIMITS } from "../config.js";
import { satisfiesDiet } from "../diet.js";
import { generateJson } from "../gemini.js";
import { ApiError, ErrorCode } from "../http.js";
import { buildRecipePrompt } from "../prompts.js";
import { sanitizeRecipes } from "../sanitize.js";
import { recipesResponseSchema } from "../schemas.js";
import { parseRecipeRequest, readJsonBody } from "../validation.js";

const TOKENS_PER_RECIPE = 3000;
const TOKEN_HEADROOM = 2048;

/** Returns `{ recipes: Recipe[] }`; recipes that miss a requested dietary rule are discarded. */
export async function handleRecipes({ request, env, logger }) {
  const recipeRequest = parseRecipeRequest(await readJsonBody(request, LIMITS.recipeBodyBytes));
  logger.info("Recipes requested.", {
    mode: recipeRequest.mode,
    count: recipeRequest.count,
    ingredients: recipeRequest.ingredients.length,
    dietary: recipeRequest.dietary,
  });

  const raw = await generateJson({
    env,
    logger,
    parts: [{ text: buildRecipePrompt(recipeRequest) }],
    schema: recipesResponseSchema(recipeRequest.count),
    temperature: 0.85,
    maxOutputTokens: TOKENS_PER_RECIPE * recipeRequest.count + TOKEN_HEADROOM,
  });

  const all = sanitizeRecipes(raw);
  const recipes = all.filter((recipe) => satisfiesDiet(recipe.dietary, recipeRequest.dietary));

  if (recipes.length < all.length) {
    logger.warn("Dropped recipes violating dietary rules.", { dropped: all.length - recipes.length });
  }
  if (recipes.length === 0) {
    throw new ApiError(502, ErrorCode.AI_BAD_RESPONSE, "The AI chef could not create a fitting recipe. Try again.", {
      retryable: true,
    });
  }

  logger.info("Recipes completed.", { returned: recipes.length });
  return { recipes };
}
