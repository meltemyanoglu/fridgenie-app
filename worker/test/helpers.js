// Shared test fixtures: env, request builders and Gemini reply stubs.

import { vi } from "vitest";
import worker from "../src/index.js";

export const APP_TOKEN = "test-app-token-123";
export const BASE_URL = "https://api.fridgenie.test";
export const TINY_JPEG_BASE64 = "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAP8=";

/** Builds an env with secrets and limiters that allow everything unless told otherwise. */
export function makeEnv(overrides = {}) {
  return {
    GEMINI_API_KEY: "gemini-test-key",
    APP_TOKEN,
    GEMINI_MODEL: "gemini-test-model",
    ALLOWED_ORIGINS: "https://web.fridgenie.test",
    SCAN_RATE_LIMITER: allowLimiter(),
    RECIPE_RATE_LIMITER: allowLimiter(),
    ...overrides,
  };
}

export function allowLimiter() {
  return { limit: vi.fn(async () => ({ success: true })) };
}

export function denyLimiter() {
  return { limit: vi.fn(async () => ({ success: false })) };
}

/** Sends an authorized JSON POST through the worker. */
export function post(path, body, { env = makeEnv(), headers = {} } = {}) {
  const request = new Request(`${BASE_URL}${path}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Fridgenie-Token": APP_TOKEN,
      "X-Device-Id": "device_abc12345",
      ...headers,
    },
    body: typeof body === "string" ? body : JSON.stringify(body),
  });
  return worker.fetch(request, env);
}

export function get(path, { env = makeEnv(), headers = {} } = {}) {
  return worker.fetch(new Request(`${BASE_URL}${path}`, { headers }), env);
}

/** Wraps a JSON object the way Gemini's generateContent returns it. */
export function geminiReply(json, { finishReason = "STOP" } = {}) {
  return new Response(
    JSON.stringify({
      candidates: [{ finishReason, content: { parts: [{ text: JSON.stringify(json) }] } }],
    }),
    { status: 200, headers: { "Content-Type": "application/json" } },
  );
}

/** Stubs global fetch with a queue of responses and returns the mock for assertions. */
export function stubGemini(...responses) {
  const fetchMock = vi.fn();
  for (const response of responses) {
    fetchMock.mockImplementationOnce(async () =>
      typeof response === "function" ? response() : response,
    );
  }
  vi.stubGlobal("fetch", fetchMock);
  return fetchMock;
}

export function validRecipe(overrides = {}) {
  return {
    title: "Tomato Egg Skillet",
    tagline: "Weeknight hero",
    emoji: "🍳",
    category: "quick",
    difficulty: "easy",
    cookMinutes: 15,
    servings: 2,
    nutrition: { calories: 320, proteinG: 18, carbsG: 12, fatG: 20 },
    ingredients: ["tomato", "eggs"],
    optionalIngredients: ["basil"],
    steps: [
      { text: "Chop tomatoes.", minutes: 3 },
      { text: "Cook tomatoes.", minutes: 5 },
      { text: "Add eggs and cook.", minutes: 5 },
    ],
    substitutions: [{ missing: "basil", swap: "parsley", reason: "Fresh herb" }],
    moods: ["cozy"],
    cuisines: ["mediterranean"],
    dietary: ["vegetarian", "glutenFree"],
    whyRecommended: "Uses what you have.",
    tags: ["quick"],
    ...overrides,
  };
}
