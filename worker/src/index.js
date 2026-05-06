/**
 * Fridgenie ingredient-detection Worker.
 *
 * Receives a base64-encoded fridge photo from the Flutter app, asks Gemini
 * 2.0 Flash to identify visible food ingredients, and returns a clean JSON
 * list. The Gemini API key never leaves Cloudflare — clients only see this
 * Worker's URL.
 *
 * Deploy with `wrangler deploy`. Configure GEMINI_API_KEY via
 * `wrangler secret put GEMINI_API_KEY`.
 */

const SYSTEM_PROMPT = `You are an ingredient detector for a smart cooking app.
Look at this fridge / pantry photo and identify visible food ingredients.

Return ONLY valid JSON in this exact shape, no prose, no code fence:
{"ingredients": ["tomato", "onion", "milk"]}

Rules:
- Lowercase, singular, simple common names (tomato, not "Roma tomato").
- Only edible food / drink items.
- Maximum 12 items.
- If you can't identify anything, return {"ingredients": []}.`;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
  "Access-Control-Max-Age": "86400",
};

function json(body, status = 200, extraHeaders = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders,
      ...extraHeaders,
    },
  });
}

export default {
  async fetch(request, env, ctx) {
    // CORS preflight
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    if (request.method !== "POST") {
      return json({ error: "Method not allowed" }, 405);
    }

    if (!env.GEMINI_API_KEY) {
      return json(
        { error: "Server misconfigured: missing GEMINI_API_KEY secret." },
        500,
      );
    }

    // ── Tiny abuse guard: cap request body size and require Content-Type
    const contentType = request.headers.get("Content-Type") || "";
    if (!contentType.includes("application/json")) {
      return json({ error: "Expected application/json body." }, 415);
    }

    let payload;
    try {
      payload = await request.json();
    } catch (_) {
      return json({ error: "Invalid JSON body." }, 400);
    }

    const imageBase64 = payload.imageBase64;
    const mimeType = payload.mimeType || "image/jpeg";
    if (!imageBase64 || typeof imageBase64 !== "string") {
      return json({ error: "imageBase64 (string) is required." }, 400);
    }
    // Reject huge payloads (~12 MB base64 ≈ 9 MB binary).
    if (imageBase64.length > 12_000_000) {
      return json({ error: "Image too large. Compress before upload." }, 413);
    }

    const geminiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/" +
      "gemini-2.0-flash:generateContent?key=" +
      encodeURIComponent(env.GEMINI_API_KEY);

    const geminiBody = {
      contents: [
        {
          role: "user",
          parts: [
            { text: SYSTEM_PROMPT },
            {
              inline_data: {
                mime_type: mimeType,
                data: imageBase64,
              },
            },
          ],
        },
      ],
      generationConfig: {
        temperature: 0.2,
        responseMimeType: "application/json",
        maxOutputTokens: 300,
      },
    };

    let geminiRes;
    try {
      geminiRes = await fetch(geminiUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(geminiBody),
      });
    } catch (e) {
      return json({ error: "Upstream network error", detail: String(e) }, 502);
    }

    const geminiText = await geminiRes.text();
    if (!geminiRes.ok) {
      return json(
        {
          error: `Gemini ${geminiRes.status}`,
          detail: geminiText.slice(0, 400),
        },
        geminiRes.status,
      );
    }

    let geminiJson;
    try {
      geminiJson = JSON.parse(geminiText);
    } catch (_) {
      return json({ error: "Gemini returned non-JSON." }, 502);
    }

    // The model's text answer lives at candidates[0].content.parts[0].text.
    const reply =
      geminiJson?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";

    let ingredients = [];
    try {
      const parsed = JSON.parse(reply);
      if (parsed && Array.isArray(parsed.ingredients)) {
        ingredients = parsed.ingredients
          .filter((x) => typeof x === "string")
          .map((s) => s.trim().toLowerCase())
          .filter(Boolean)
          .slice(0, 12);
      }
    } catch (_) {
      // If the model added stray text, salvage the {...} block.
      const start = reply.indexOf("{");
      const end = reply.lastIndexOf("}");
      if (start >= 0 && end > start) {
        try {
          const inner = JSON.parse(reply.slice(start, end + 1));
          if (inner && Array.isArray(inner.ingredients)) {
            ingredients = inner.ingredients
              .filter((x) => typeof x === "string")
              .map((s) => s.trim().toLowerCase())
              .filter(Boolean)
              .slice(0, 12);
          }
        } catch (_) {
          /* fall through to empty list */
        }
      }
    }

    return json({ ingredients });
  },
};
