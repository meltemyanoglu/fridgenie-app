# 00 · Backend analysis

| | |
|---|---|
| **When** | 2026-10-12, 14:25 – 14:37 (Europe/Rome) |
| **Who** | Bilge, with Claude |
| **Commit** | none (read-only review) |

## In one sentence
We read every backend-related file in the app and listed what is broken, what is risky, and what is just messy.

## What "backend" means in Fridgenie
Fridgenie is a Flutter app. It has no classic server, so the "backend" is everything that is not UI:

| Part | Files | What it does |
|---|---|---|
| Cloudflare Worker | `worker/src/index.js` | A tiny server that talks to Google Gemini (AI) for the app |
| AI services | `lib/data/services/*.dart` | Code in the app that asks the AI for recipes and scans photos |
| Providers | `lib/providers/*.dart` | The app's "brain": fridge contents, recipes, favorites, profile, grocery list |
| Models | `lib/data/models/*.dart` | The shape of the data (Recipe, Ingredient, …) |
| Storage | SharedPreferences | Saves data on the phone between app launches |

## 🔴 Critical problems

1. **The secret AI key was inside the app.** `GeminiService` called Google directly with the API key baked in at build time. Anyone can extract it from the installed app and use it at Meltem's expense. The same applied to the OpenAI recognizer.
2. **The server's recipe endpoint was never used.** `RecipeGenerator` (which calls the Worker) existed but nothing created it. Recipes went straight from the phone to Google.
3. **The Worker used a retired AI model** (`gemini-1.5-flash`), so photo scanning could not work.
4. **The Worker was open to everyone.** No password, no rate limit, any website allowed. Anyone who found the URL could spend the AI quota. It also sent Google's internal error text back to callers.

## 🟠 Bugs

| Bug | Effect for the user |
|---|---|
| "Surprise Me" sent an empty ingredient list | Always showed the same demo recipe, never a real AI one |
| Only 50 generated recipes were kept, and favorites pointed to them by id | Old favorite AI recipes silently disappeared |
| Dietary filter used "any match" | A vegan + gluten-free user could get a gluten-free meat recipe |
| Streak = +1 per cooked recipe | Cooking 7 times in one day earned the "7-day streak" badge; it never reset |
| Badges hardcoded as earned | New users already "had" 3 badges |
| Storage loaded asynchronously, saves ignored until then | Taps right after app start could be lost |
| No error handling in several async methods | A failure left the screen spinning forever |
| One shared loading flag for many features | Two screens loading at once confused each other |
| Ingredient matching used "contains" | "egg" became "eggplant", "apple" became "pineapple" |
| One corrupted saved recipe threw an error | All saved AI recipes were wiped |
| Empty gradient list allowed | Could crash the recipe card |

## 🟡 Code health

- Recipe parsing existed in **three** places that had already drifted apart.
- Three different "result" classes for the same idea (`RankedRecipe`, `RankedResult`, `RecipeResult`).
- Screens created services directly instead of getting them from Provider.
- No structured AI output, no retries, one smoke test, Xcode build cache committed inside `worker/`.
- ✅ Good news: no API keys were ever committed to git history.
