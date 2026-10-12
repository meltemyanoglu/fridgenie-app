// Request body parsing and validation; every user-provided value is normalized here before use.

import {
  COOKING_SKILLS,
  CUISINES,
  DIETARY_PREFERENCES,
  GENIE_MODES,
  IMAGE_MIME_TYPES,
  LIMITS,
  MOODS,
} from "./config.js";
import { ApiError, ErrorCode } from "./http.js";

const BASE64_PATTERN = /^[A-Za-z0-9+/]+={0,2}$/;
const CONTROL_CHARS_PATTERN = /[\u0000-\u001F\u007F]/g;

/** Reads and parses a JSON object body, rejecting oversized or malformed payloads. */
export async function readJsonBody(request, maxBytes) {
  const contentType = request.headers.get("Content-Type") ?? "";
  if (!contentType.toLowerCase().includes("application/json")) {
    throw new ApiError(415, ErrorCode.UNSUPPORTED_MEDIA_TYPE, "Content-Type must be application/json.");
  }

  const declaredLength = Number(request.headers.get("Content-Length"));
  if (Number.isFinite(declaredLength) && declaredLength > maxBytes) {
    throw tooLarge(maxBytes);
  }

  const text = await request.text();
  if (text.length > maxBytes) throw tooLarge(maxBytes);

  let body;
  try {
    body = JSON.parse(text);
  } catch {
    throw new ApiError(400, ErrorCode.BAD_REQUEST, "Body is not valid JSON.");
  }
  if (!isPlainObject(body)) {
    throw new ApiError(400, ErrorCode.BAD_REQUEST, "Body must be a JSON object.");
  }
  return body;
}

/** Validates a scan request: a base64 image with an allowed mime type. */
export function parseScanRequest(body) {
  const { imageBase64, mimeType = "image/jpeg" } = body;

  if (typeof imageBase64 !== "string" || imageBase64.length === 0) {
    throw new ApiError(400, ErrorCode.BAD_REQUEST, "imageBase64 is required.");
  }
  if (imageBase64.length > LIMITS.imageBase64Chars) {
    throw new ApiError(413, ErrorCode.PAYLOAD_TOO_LARGE, "Image is too large. Compress it before upload.");
  }
  if (!BASE64_PATTERN.test(imageBase64)) {
    throw new ApiError(400, ErrorCode.BAD_REQUEST, "imageBase64 is not valid base64.");
  }
  if (typeof mimeType !== "string" || !IMAGE_MIME_TYPES.includes(mimeType.toLowerCase())) {
    throw new ApiError(415, ErrorCode.UNSUPPORTED_MEDIA_TYPE, "Unsupported image type.");
  }

  return { imageBase64, mimeType: mimeType.toLowerCase() };
}

/** Validates a recipe request; unknown enum values are dropped instead of rejected. */
export function parseRecipeRequest(body) {
  const mode = pickEnum(body.mode, GENIE_MODES) ?? "standard";
  const ingredients = cleanStringList(body.ingredients, {
    maxItems: LIMITS.recipeMaxInputIngredients,
    maxChars: LIMITS.ingredientNameChars,
    lowercase: true,
  });

  if (ingredients.length === 0 && mode !== "surpriseMe") {
    throw new ApiError(400, ErrorCode.BAD_REQUEST, "At least one ingredient is required.");
  }

  const count = Number.isInteger(body.count) ? body.count : LIMITS.recipeCountMin;
  if (count < LIMITS.recipeCountMin || count > LIMITS.recipeCountMax) {
    throw new ApiError(
      400,
      ErrorCode.BAD_REQUEST,
      `count must be between ${LIMITS.recipeCountMin} and ${LIMITS.recipeCountMax}.`,
    );
  }

  return {
    ingredients,
    mode,
    count,
    dietary: pickEnumList(body.dietary, DIETARY_PREFERENCES),
    mood: pickEnum(body.mood, MOODS),
    cuisine: pickEnum(body.cuisine, CUISINES),
    skill: pickEnum(body.skill, COOKING_SKILLS),
    avoidTitles: cleanStringList(body.avoidTitles, {
      maxItems: LIMITS.avoidTitlesMax,
      maxChars: LIMITS.avoidTitleChars,
      lowercase: false,
    }),
  };
}

/** Trims, strips control characters, de-duplicates and caps a list of strings. */
export function cleanStringList(value, { maxItems, maxChars, lowercase }) {
  if (!Array.isArray(value)) return [];
  const seen = new Set();
  const out = [];
  for (const item of value) {
    if (typeof item !== "string") continue;
    let clean = item.replace(CONTROL_CHARS_PATTERN, " ").trim().slice(0, maxChars);
    if (lowercase) clean = clean.toLowerCase();
    const key = clean.toLowerCase();
    if (!clean || seen.has(key)) continue;
    seen.add(key);
    out.push(clean);
    if (out.length >= maxItems) break;
  }
  return out;
}

function pickEnum(value, allowed) {
  return typeof value === "string" && allowed.includes(value) ? value : null;
}

function pickEnumList(value, allowed) {
  if (!Array.isArray(value)) return [];
  return [...new Set(value.filter((v) => typeof v === "string" && allowed.includes(v)))];
}

function isPlainObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function tooLarge(maxBytes) {
  return new ApiError(413, ErrorCode.PAYLOAD_TOO_LARGE, `Request body exceeds ${maxBytes} bytes.`);
}
