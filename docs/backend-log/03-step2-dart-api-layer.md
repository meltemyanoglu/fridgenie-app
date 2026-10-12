# 03 · Step 2 – One clean API layer in the app

| | |
|---|---|
| **When** | 2026-10-12, 15:04 – 15:12 (Europe/Rome) |
| **Who** | Claude, for Bilge |
| **Commit** | `1bb47dc` feat(app): route all AI calls through the Worker |
| **Verified** | ✅ ingredient matching logic simulated against all 28 test cases · ⚠️ Dart code **not compiled yet**: run `flutter analyze` and `flutter test` |

## In one sentence
The app now talks to the AI **only through our Worker**, so the secret Gemini key is no longer inside the app at all.

## Why
Before this step, the app called Google directly with the key baked into the app. Anyone could extract the key from the installed app. Three separate pieces of code also did the same job (and disagreed with each other).

## What changed

### New pieces
| File | What it does |
|---|---|
| `lib/core/config/app_config.dart` | Reads the Worker URL and app token at build time |
| `lib/data/services/fridgenie_api.dart` | The **contract**: "scan a photo" and "generate recipes", plus friendly error messages |
| `lib/data/services/worker_fridgenie_api.dart` | The real implementation that calls the Worker |
| `lib/data/services/recipe_mapper.dart` | Turns the Worker's JSON into a `Recipe` (the only place this happens now) |
| `lib/data/services/ingredient_matcher.dart` | Turns AI names ("cherry tomatoes") into catalog items (`tomato`) |
| `lib/data/services/device_id.dart` | Random anonymous id per install, used only for rate limiting |
| `config/fridgenie.example.json` | Template for the Worker URL + token (the real file is git-ignored) |

### Removed
- `gemini_service.dart` (called Google directly, with the key in the app)
- `recipe_generator.dart` (was never used)
- `OpenAIVisionRecognizer` and the old backend recognizer (replaced by one recognizer that uses the Worker)

### Better ingredient matching
The old code matched by "contains", so `egg` matched `eggplant`. The new matcher:
- matches **whole words** only,
- understands plurals (`tomatoes` → `tomato`) and accents (`jalapeño` → `chili`),
- picks the **most specific** phrase (`peanut butter` beats `butter`),
- uses the **main noun** (`chicken stock` → stock, `chicken breast` → chicken),
- knows synonyms (`aubergine` → eggplant, `spaghetti` → pasta),
- refuses wrong guesses on purpose (`black pepper` is **not** bell pepper).

Ingredients the AI mentions that aren't in our catalog are no longer silently lost. They are kept in a new `Recipe.extraIngredientNames` field (see "For Meltem").

### Friendlier errors
Every failure now has a clear type and a ready-made message, for example *"Genie needs a short break. Try again in a minute."* when rate-limited. When the AI fails, the app still shows an offline recipe and explains why, as before.

### Small fixes along the way
- "Surprise Me" now really asks the AI (before, it always returned the same demo recipe).
- The offline fallback now picks a recipe that fits your ingredients and the requested mode, instead of a random one.
- Only real AI recipes are saved to the "generated" list (demo recipes no longer pile up there).
- Every AI call logs its duration and the Worker `requestId`, so problems can be traced end to end.

## What stayed the same (on purpose)
All provider methods the screens use kept their names (`generateWithGemini`, `geminiAvailable`, `geminiError`, …). The only screen edits are two import lines (`home_screen.dart`, `rescue_screen.dart`), because `GenieMode` moved to `models/enums.dart`.

## For Meltem
- **New optional UI idea:** `recipe.extraIngredientNames` lists ingredients that aren't in our catalog (e.g. "saffron"). The recipe detail screen could show them under the ingredient list.

## How to run the app against the Worker
```bash
cp config/fridgenie.example.json config/fridgenie.json   # then fill in URL + token
flutter run --dart-define-from-file=config/fridgenie.json
```
Without the flag, the app runs in demo mode exactly like before.

## How to check it yourself
```bash
flutter pub get
flutter analyze        # expect: No issues found
flutter test           # new tests in test/data/services/
```

## Tests added
- `ingredient_matcher_test.dart`: plurals, whole words, synonyms, accents
- `recipe_mapper_test.dart`: full mapping, bad data, unique ids
- `worker_fridgenie_api_test.dart`: headers, request body, error codes, timeouts, offline
