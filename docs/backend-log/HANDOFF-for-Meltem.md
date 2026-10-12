# Handoff for Meltem 💛

Hi Meltem! Bilge reworked the backend side of Fridgenie, together with Claude. Your UI is untouched except for a handful of one-line changes, all listed below. This page is everything you need to know, in one place.

## TL;DR
- The app now gets its AI **only through our own server** (a Cloudflare Worker). The secret Gemini key is no longer inside the app, so nobody can steal it from an installed copy.
- Saved data (favorites, fridge, grocery list, profile) can no longer be lost or wiped.
- Diets are respected strictly, streaks count real days, and badges are earned for real.
- Tests run automatically on GitHub for every push.

## What you need to do
1. **Create the accounts** (they should be yours, since it's your app): a free [Cloudflare](https://dash.cloudflare.com/sign-up) account and a [Google AI Studio](https://aistudio.google.com/app/apikey) Gemini key. Then add Bilge.
2. **Deploy the Worker once**: about 10 minutes, step by step in [`worker/README.md`](../../worker/README.md).
3. **Run the app with real AI**:
   ```bash
   cp config/fridgenie.example.json config/fridgenie.json   # fill in URL + token
   flutter run --dart-define-from-file=config/fridgenie.json
   ```
   Without that flag the app runs in **demo mode**, exactly like before.
4. **Check the Actions tab** on GitHub: the first CI run on `bilge-changes` shows whether `flutter analyze` and `flutter test` pass.

## Changes inside your screens (all small)
| File | What changed | Why |
|---|---|---|
| `home_screen.dart` | One import line; tip of the day uses the shared `AIService` | `GenieMode` moved; no duplicate services |
| `rescue_screen.dart` | One import line | `GenieMode` moved to `models/enums.dart` |
| `recipe_detail_screen.dart` | `toggleFavorite(r)`; `markCooked(...)`; "cooked" message shows the real streak and new badges; shared `AIService` | Favorites store the full recipe; real streaks/badges |
| `surprise_screen.dart` | Passes the fridge contents to `rollSurprise` | Surprise Me uses what's in your fridge |
| `suggestions_screen.dart`, `scan_screen.dart` | Demo-mode help text updated | The old text pointed to a setup that no longer exists |

Every provider method your screens use kept its name (`generateWithGemini`, `geminiAvailable`, `geminiError`, `suggestions`, `favorites`, …).

## New things you *can* use (optional)
| What | Where | Idea |
|---|---|---|
| `recipe.extraIngredientNames` | `Recipe` | AI ingredients not in our catalog (e.g. "saffron"); show them under the ingredient list |
| `moodState`, `surpriseState`, `challengeState`, `rescueState` | `RecipeProvider` | Per-screen spinners / error messages |
| `surpriseFallbackReason` | `RecipeProvider` | Explain when Surprise showed a demo recipe instead of AI |
| `CookResult` (`streak`, `streakIncreased`, `newBadges`) | returned by `markCooked` | Celebrate new badges 🎉 |
| `FridgenieApiException.userMessage` | AI errors | Ready-made friendly error texts |

## Things we noticed in the UI (your call)
- The "already saved" snackbar in `recipe_detail_screen.dart` is in Turkish (*"Bu tarif zaten kaydedilmiş!"*); the rest of the app is English.
- **"Waste saved (kg)"** on the profile is always 0, because nothing calculates it. Open question: how should it be estimated? Until decided, consider hiding it.
- `fridge_door_widget.dart` uses SharedPreferences directly for its own UI state. That's fine; it could use `context.read<LocalStore>()` later for consistency.
- CI shows 7 style hints in your files: `unnecessary_underscores` in `animated_blob.dart:43`, `badges_screen.dart:72` (×2), `scan_screen.dart:293`, `surprise_screen.dart:100`, `mood_screen.dart:73` (write `_` instead of `__`), and a deprecated `translate` in `swipe_deck_screen.dart:118` (use `translateByDouble`). They don't block anything.
- Code formatting: `dart format lib test` was never run on the project. If you run it once, we can add a format check to CI.

## Where to read more
Each step is explained in plain language, with timestamps, in this folder. Start with [README](README.md).
