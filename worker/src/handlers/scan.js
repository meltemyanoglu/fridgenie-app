// POST /v1/scan: detects ingredients in a fridge photo.

import { LIMITS } from "../config.js";
import { generateJson } from "../gemini.js";
import { SCAN_PROMPT } from "../prompts.js";
import { sanitizeScanResult } from "../sanitize.js";
import { SCAN_RESPONSE_SCHEMA } from "../schemas.js";
import { parseScanRequest, readJsonBody } from "../validation.js";

/** Returns `{ ingredients: string[] }` for a validated photo upload. */
export async function handleScan({ request, env, logger }) {
  const { imageBase64, mimeType } = parseScanRequest(
    await readJsonBody(request, LIMITS.scanBodyBytes),
  );
  logger.info("Scan requested.", { mimeType, imageChars: imageBase64.length });

  const raw = await generateJson({
    env,
    logger,
    parts: [{ text: SCAN_PROMPT }, { inline_data: { mime_type: mimeType, data: imageBase64 } }],
    schema: SCAN_RESPONSE_SCHEMA,
    temperature: 0.2,
    maxOutputTokens: 1024,
  });

  const result = sanitizeScanResult(raw);
  logger.info("Scan completed.", { detected: result.ingredients.length });
  return result;
}
