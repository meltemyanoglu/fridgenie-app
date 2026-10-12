# 07 · Step 5 – Automatic checks on GitHub (CI)

| | |
|---|---|
| **When** | 2026-10-12, 16:19 – 16:21 (Europe/Rome) |
| **Who** | Claude, for Bilge |
| **Commit** | see the status table in [README](README.md) |
| **Verified** | ✅ Worker CI job run locally with the exact same commands: install, 31 tests, bundle check all pass · ⚠️ the Flutter job will run for the first time on GitHub after the push |

## In one sentence
From now on, GitHub automatically checks every push and pull request, so a mistake is caught before it reaches `main`.

## Why
Until now there was one smoke test and nothing ran automatically. A broken change could be merged without anyone noticing.

## What runs, and when
File: `.github/workflows/ci.yml`. It runs on every push to `main` or `bilge-changes`, and on every pull request.

| Job | Steps | Takes about |
|---|---|---|
| **Flutter analyze & test** | `flutter pub get` → `flutter analyze` → `flutter test` | 3–5 min |
| **Worker test & bundle** | `npm ci` → `npm test` → `wrangler deploy --dry-run` (builds the Worker exactly like a real deploy, without uploading it) | 1 min |

If a new push arrives while checks are still running, the old run is cancelled to save time.

**Where to see it:** GitHub → the repo → **Actions** tab, or the ✅ / ❌ next to each commit and pull request.

## The test suite today
**61 Dart tests** in 12 files + **31 Worker tests** in 4 files.

| Area | File | Tests | Protects against |
|---|---|---|---|
| Models | `recipe_test.dart` | 5 | Saved data breaking the app; all 61 mock recipes round-trip |
| | `recipe_diet_test.dart` | 4 | Unsafe dietary matches |
| Services | `ingredient_matcher_test.dart` | 6 | "egg" → eggplant type mistakes |
| | `recipe_mapper_test.dart` | 3 | Bad AI data crashing the app |
| | `worker_fridgenie_api_test.dart` | 6 | Wrong headers/body, unhandled errors, timeouts |
| Storage | `local_store_test.dart` | 3 | One bad item wiping a list |
| | `store_migrations_test.dart` | 4 | Losing favorites or wrong streaks on upgrade |
| Providers | `fridge_and_grocery_provider_test.dart` | 9 | Lost taps, timer bugs, duplicates |
| | `recipe_provider_storage_test.dart` | 5 | Vanishing favorites |
| | `recipe_provider_logic_test.dart` | 6 | Stale results, stuck spinners, wrong fallbacks |
| | `user_provider_cooking_test.dart` | 9 | Wrong streaks, badges earned too early or never |
| App | `widget_test.dart` | 1 | The app not starting at all |
| Worker | `router.test.js` | 9 | Missing auth, rate limits, wrong CORS |
| | `scan.test.js` | 7 | Bad uploads, key leaks |
| | `recipes.test.js` | 12 | Unsafe or malformed AI recipes, leaked errors |
| | `diet.test.js` | 3 | Server and app disagreeing on diets |

## Decided on purpose
- **No format check yet.** `dart format` would fail on existing UI files that were never formatted, and reformatting Meltem's screens isn't part of backend work. It can be added later with one line, after a one-time `dart format lib test`.

## For Meltem
- After pushing, check the **Actions** tab. A ❌ shows exactly which test or lint failed.
- Running the same checks before pushing: `flutter analyze && flutter test`.

## How to check it yourself
```bash
flutter analyze && flutter test        # Flutter job
cd worker && npm ci && npm test         # Worker job
```
