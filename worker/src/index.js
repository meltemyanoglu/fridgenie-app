const corsHeaders = {

  "Access-Control-Allow-Origin": "*",

  "Access-Control-Allow-Methods": "POST, OPTIONS",

  "Access-Control-Allow-Headers": "Content-Type",

  "Access-Control-Max-Age": "86400",

};

function json(body, status = 200) {

  return new Response(JSON.stringify(body), {

    status,

    headers: {

      "Content-Type": "application/json",

      ...corsHeaders,

    },

  });

}

const SCAN_PROMPT = `You are an ingredient detector for a smart cooking app.

Look at this fridge / pantry photo and identify visible food ingredients.

Return ONLY valid JSON in this exact shape, no prose, no code fence:

{"ingredients": ["tomato", "onion", "milk"]}

Rules:

- Lowercase, singular, simple common names.

- Only edible food / drink items.

- Maximum 12 items.

- If you can't identify anything, return {"ingredients": []}.`;

const RECIPE_PROMPT = `You are a creative recipe inventor for a smart cooking app called Fridgenie.

Invent ONE realistic recipe from the user's ingredients. Use basic pantry staples if needed: salt, pepper, oil, water.

Return ONLY valid JSON, no prose, no code fence, in this exact shape:

{

  "title": "Short recipe title",

  "tagline": "One-line hook",

  "emoji": "🍽️",

  "category": "comfort",

  "difficulty": "easy",

  "cookMinutes": 25,

  "servings": 2,

  "nutrition": { "calories": 480, "proteinG": 22, "carbsG": 56, "fatG": 18 },

  "ingredients": ["tomato", "onion", "garlic"],

  "optionalIngredients": ["basil"],

  "steps": [

    { "order": 1, "text": "Prepare the ingredients.", "minutes": 5 },

    { "order": 2, "text": "Cook everything until tender.", "minutes": 10 }

  ],

  "substitutions": [

    { "missing": "basil", "swap": "parsley", "reason": "Adds freshness" }

  ],

  "moods": ["cozy"],

  "cuisines": ["italian"],

  "dietary": ["noRestrictions"],

  "whyRecommended": "It uses what you already have.",

  "tags": ["weeknight", "easy"]

}

Rules:

- category must be one of: comfort, healthy, quick, budget, useItUp.

- difficulty must be one of: easy, medium, hard.

- moods only: cozy, energetic, calm, celebratory, adventurous, comforted.

- cuisines only: italian, mexican, japanese, indian, mediterranean, middleEastern, turkish, korean, thai, chinese, french, american.

- dietary only: vegetarian, vegan, pescatarian, glutenFree, dairyFree, keto, halal, kosher, noRestrictions.

- 4 to 7 steps.

- Be realistic and specific.`;

async function callGemini(env, body) {

  const url =

    "https://generativelanguage.googleapis.com/v1beta/models/" +

    "gemini-1.5-flash:generateContent?key=" +

    encodeURIComponent(env.GEMINI_API_KEY);

  const res = await fetch(url, {

    method: "POST",

    headers: { "Content-Type": "application/json" },

    body: JSON.stringify(body),

  });

  const text = await res.text();

  if (!res.ok) {

    console.log("Gemini error status:", res.status);

    console.log("Gemini error body:", text);

    return {

      ok: false,

      status: res.status,

      detail: text.slice(0, 1200),

    };

  }

  let parsed;

  try {

    parsed = JSON.parse(text);

  } catch (_) {

    return {

      ok: false,

      status: 502,

      detail: "Gemini returned non-JSON: " + text.slice(0, 400),

    };

  }

  const reply = parsed?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";

  if (!reply) {

    return {

      ok: false,

      status: 502,

      detail: "Gemini returned empty reply: " + text.slice(0, 400),

    };

  }

  return { ok: true, reply };

}

function safeJsonParse(reply) {

  try {

    return JSON.parse(reply);

  } catch (_) {

    const start = reply.indexOf("{");

    const end = reply.lastIndexOf("}");

    if (start >= 0 && end > start) {

      try {

        return JSON.parse(reply.slice(start, end + 1));

      } catch (_) {}

    }

  }

  return null;

}

async function handleScan(request, env) {

  let payload;

  try {

    payload = await request.json();

  } catch (_) {

    return json({ error: "Invalid JSON body." }, 400);

  }

  const imageBase64 = payload.imageBase64;

  const mimeType = payload.mimeType || "image/jpeg";

  if (!imageBase64 || typeof imageBase64 !== "string") {

    return json({ error: "imageBase64 string is required." }, 400);

  }

  if (imageBase64.length > 12000000) {

    return json({ error: "Image too large. Compress before upload." }, 413);

  }

  const out = await callGemini(env, {

    contents: [

      {

        role: "user",

        parts: [

          { text: SCAN_PROMPT },

          { inline_data: { mime_type: mimeType, data: imageBase64 } },

        ],

      },

    ],

    generationConfig: {

      temperature: 0.2,

      maxOutputTokens: 300,

    },

  });

  if (!out.ok) {

    return json({ error: `Gemini ${out.status}`, detail: out.detail }, out.status);

  }

  const parsed = safeJsonParse(out.reply) || {};

  const ingredients = Array.isArray(parsed.ingredients)

    ? parsed.ingredients

        .filter((x) => typeof x === "string")

        .map((s) => s.trim().toLowerCase())

        .filter(Boolean)

        .slice(0, 12)

    : [];

  return json({ ingredients });

}

async function handleGenerateRecipe(request, env) {

  let payload;

  try {

    payload = await request.json();

  } catch (_) {

    return json({ error: "Invalid JSON body." }, 400);

  }

  const ingredients = Array.isArray(payload.ingredients)

    ? payload.ingredients

        .filter((x) => typeof x === "string")

        .map((s) => s.trim().toLowerCase())

        .filter(Boolean)

        .slice(0, 30)

    : [];

  if (ingredients.length === 0) {

    return json({ error: "ingredients array is required." }, 400);

  }

  const dietary = Array.isArray(payload.dietary) ? payload.dietary : [];

  const mood = typeof payload.mood === "string" ? payload.mood : "";

  const cuisine = typeof payload.cuisine === "string" ? payload.cuisine : "";

  const skill = typeof payload.skill === "string" ? payload.skill : "";

  const avoidTitles = Array.isArray(payload.avoidTitles)

    ? payload.avoidTitles.slice(0, 20)

    : [];

  const userMsg = [

    `Ingredients available: ${ingredients.join(", ")}.`,

    dietary.length ? `Dietary: ${dietary.join(", ")}.` : "",

    mood ? `Mood: ${mood}.` : "",

    cuisine ? `Preferred cuisine: ${cuisine}.` : "",

    skill ? `Cooking skill: ${skill}.` : "",

    avoidTitles.length

      ? `Avoid these existing titles: ${avoidTitles.join(", ")}.`

      : "",

    "Return ONE recipe as valid JSON.",

  ]

    .filter(Boolean)

    .join("\n");

  const out = await callGemini(env, {

    contents: [

      {

        role: "user",

        parts: [{ text: RECIPE_PROMPT + "\n\n" + userMsg }],

      },

    ],

    generationConfig: {

      temperature: 0.85,

      maxOutputTokens: 1200,

    },

  });

  if (!out.ok) {

    return json({ error: `Gemini ${out.status}`, detail: out.detail }, out.status);

  }

  const recipe = safeJsonParse(out.reply);

  if (!recipe || typeof recipe !== "object") {

    return json(

      {

        error: "Could not parse generated recipe.",

        raw: out.reply.slice(0, 400),

      },

      502,

    );

  }

  const cleaned = {

    title: typeof recipe.title === "string" ? recipe.title : "Genie Original",

    tagline: typeof recipe.tagline === "string" ? recipe.tagline : "",

    emoji: typeof recipe.emoji === "string" ? recipe.emoji : "🍽️",

    category: typeof recipe.category === "string" ? recipe.category : "comfort",

    difficulty: typeof recipe.difficulty === "string" ? recipe.difficulty : "easy",

    cookMinutes: Number(recipe.cookMinutes) || 25,

    servings: Number(recipe.servings) || 2,

    nutrition: {

      calories: Number(recipe?.nutrition?.calories) || 400,

      proteinG: Number(recipe?.nutrition?.proteinG) || 15,

      carbsG: Number(recipe?.nutrition?.carbsG) || 45,

      fatG: Number(recipe?.nutrition?.fatG) || 15,

    },

    ingredients: Array.isArray(recipe.ingredients)

      ? recipe.ingredients.filter((x) => typeof x === "string")

      : ingredients,

    optionalIngredients: Array.isArray(recipe.optionalIngredients)

      ? recipe.optionalIngredients.filter((x) => typeof x === "string")

      : [],

    steps: Array.isArray(recipe.steps)

      ? recipe.steps

          .filter((s) => s && typeof s.text === "string")

          .map((s, i) => ({

            order: Number(s.order) || i + 1,

            text: s.text,

            minutes: s.minutes == null ? null : Number(s.minutes),

          }))

      : [],

    substitutions: Array.isArray(recipe.substitutions)

      ? recipe.substitutions.filter(

          (s) =>

            s &&

            typeof s.missing === "string" &&

            typeof s.swap === "string",

        )

      : [],

    moods: Array.isArray(recipe.moods)

      ? recipe.moods.filter((x) => typeof x === "string")

      : ["cozy"],

    cuisines: Array.isArray(recipe.cuisines)

      ? recipe.cuisines.filter((x) => typeof x === "string")

      : [],

    dietary: Array.isArray(recipe.dietary)

      ? recipe.dietary.filter((x) => typeof x === "string")

      : ["noRestrictions"],

    whyRecommended:

      typeof recipe.whyRecommended === "string"

        ? recipe.whyRecommended

        : "Genie improvised this recipe from your ingredients.",

    tags: Array.isArray(recipe.tags)

      ? recipe.tags.filter((x) => typeof x === "string")

      : ["ai-generated"],

  };

  return json({ recipe: cleaned });

}

export default {

  async fetch(request, env) {

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

    const url = new URL(request.url);

    const path = url.pathname.replace(/\/+$/, "") || "/";

    try {

      if (path === "/generate-recipe") {

        return await handleGenerateRecipe(request, env);

      }

      return await handleScan(request, env);

    } catch (e) {

      return json({ error: "Server error", detail: String(e) }, 500);

    }

  },

};