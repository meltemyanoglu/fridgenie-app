// Minimal Gemini generateContent client with timeout, one retry on transient errors and JSON output.

import {
  DEFAULT_GEMINI_MODEL,
  GEMINI_BASE_URL,
  GEMINI_RETRY_DELAY_MS,
  GEMINI_TIMEOUT_MS,
} from "./config.js";
import { ApiError, ErrorCode } from "./http.js";

const RETRYABLE_STATUSES = new Set([429, 500, 502, 503, 504]);

/**
 * Calls Gemini and returns the parsed JSON object from the first candidate.
 * @param {object} args
 * @param {object} args.env Worker env with GEMINI_API_KEY and optional GEMINI_MODEL.
 * @param {object[]} args.parts Gemini content parts (text and/or inline_data).
 * @param {object} args.schema Response schema enforced by Gemini.
 * @param {number} args.temperature Sampling temperature.
 * @param {number} args.maxOutputTokens Output token budget.
 * @param {ReturnType<import("./http.js").createLogger>} args.logger Request logger.
 */
export async function generateJson({ env, parts, schema, temperature, maxOutputTokens, logger }) {
  if (!env.GEMINI_API_KEY) {
    throw new ApiError(500, ErrorCode.SERVER_MISCONFIGURED, "Server is not configured.", {
      logDetail: "Missing GEMINI_API_KEY secret.",
    });
  }

  const model = env.GEMINI_MODEL || DEFAULT_GEMINI_MODEL;
  const body = JSON.stringify({
    contents: [{ role: "user", parts }],
    generationConfig: {
      temperature,
      maxOutputTokens,
      responseMimeType: "application/json",
      responseSchema: schema,
    },
  });

  const url = `${GEMINI_BASE_URL}/${model}:generateContent`;
  const init = {
    method: "POST",
    headers: { "Content-Type": "application/json", "x-goog-api-key": env.GEMINI_API_KEY },
    body,
  };
  const response = await fetchWithRetry(url, init, logger);

  return extractJson(await response.json(), logger);
}

async function fetchWithRetry(url, init, logger) {
  for (let attempt = 1; attempt <= 2; attempt++) {
    const startedAt = Date.now();
    let response;
    try {
      response = await fetch(url, { ...init, signal: AbortSignal.timeout(GEMINI_TIMEOUT_MS) });
    } catch (error) {
      const timedOut = error?.name === "TimeoutError";
      logger.warn("Gemini request failed.", { attempt, timedOut, error: String(error) });
      if (timedOut || attempt === 2) {
        throw new ApiError(503, ErrorCode.AI_UNAVAILABLE, "The AI chef is not responding. Try again.", {
          retryable: true,
        });
      }
      await sleep(GEMINI_RETRY_DELAY_MS);
      continue;
    }

    logger.info("Gemini responded.", { attempt, status: response.status, ms: Date.now() - startedAt });
    if (response.ok) return response;

    const detail = (await response.text()).slice(0, 1000);
    if (RETRYABLE_STATUSES.has(response.status) && attempt === 1) {
      logger.warn("Gemini transient error; retrying.", { status: response.status, detail });
      await sleep(GEMINI_RETRY_DELAY_MS);
      continue;
    }

    logger.error("Gemini error.", { status: response.status, detail });
    throw mapGeminiStatus(response.status);
  }
  throw new ApiError(503, ErrorCode.AI_UNAVAILABLE, "The AI chef is not responding. Try again.", {
    retryable: true,
  });
}

/** Maps upstream failures to client-safe errors; 4xx from Gemini means our config is wrong. */
function mapGeminiStatus(status) {
  if (status === 429 || status >= 500) {
    return new ApiError(503, ErrorCode.AI_UNAVAILABLE, "The AI chef is busy. Try again shortly.", {
      retryable: true,
    });
  }
  return new ApiError(502, ErrorCode.AI_UNAVAILABLE, "The AI service is unavailable right now.");
}

function extractJson(payload, logger) {
  const blockReason = payload?.promptFeedback?.blockReason;
  const candidate = payload?.candidates?.[0];
  const finishReason = candidate?.finishReason;
  const text = (candidate?.content?.parts ?? [])
    .filter((part) => typeof part?.text === "string" && !part.thought)
    .map((part) => part.text)
    .join("")
    .trim();

  if (blockReason || !candidate || finishReason === "SAFETY" || finishReason === "PROHIBITED_CONTENT") {
    logger.warn("Gemini blocked the request.", { blockReason, finishReason });
    throw new ApiError(422, ErrorCode.AI_BAD_RESPONSE, "The AI chef could not handle this request.");
  }
  if (finishReason === "MAX_TOKENS" || !text) {
    logger.error("Gemini reply incomplete.", { finishReason, textLength: text.length });
    throw new ApiError(502, ErrorCode.AI_BAD_RESPONSE, "The AI reply was incomplete. Try again.", {
      retryable: true,
    });
  }

  try {
    return JSON.parse(text);
  } catch {
    logger.error("Gemini reply is not JSON.", { preview: text.slice(0, 300) });
    throw new ApiError(502, ErrorCode.AI_BAD_RESPONSE, "The AI reply was malformed. Try again.", {
      retryable: true,
    });
  }
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
