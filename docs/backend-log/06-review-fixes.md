# 06 · Independent review and fixes

| | |
|---|---|
| **When** | 2026-10-12, 15:27 – 16:19 (Europe/Rome) |
| **Who** | Review by a separate Claude agent that had not written the code; fixes by Claude, for Bilge |
| **Commit** | `bfdddcf` fix(app): address independent review findings |
| **Verified** | ✅ reviewer checked every changed call site and hand-traced every test against the mock data: **no compile errors found**, all test expectations hold · ⚠️ still needs a real `flutter analyze` / `flutter test` run |

## In one sentence
Because Flutter can't run in Claude's sandbox, a second, independent reviewer read all the Dart changes from Steps 2–4 like a compiler would. It found no compile errors, but it did find one broken test and some real bugs, which are fixed here.

## What the review found, and what was done

### Blocker
| Finding | Fix |
|---|---|
| The app smoke test would fail: the splash screen leaves a 1.7 s timer running, and Google Fonts tries to download fonts during tests | The test now unmounts the app and waits for the timer; a new `test/flutter_test_config.dart` turns off font downloads for all tests |

### Bugs
| Finding | Fix |
|---|---|
| Old (v1) streaks had no dates and were inflated, so long-time users would instantly "earn" Week Warrior | The v1 → v2 migration resets undated streaks to 0; the "recipes cooked" total is kept |
| Cooking the same Surprise recipe 3 times earned Wildcard; any recipe from the last challenge counted for Minimalist | Each Surprise/challenge recipe now counts **once** |
| Re-adding "Milk" while a checked "Milk" was about to vanish was ignored, then Milk disappeared | Re-adding un-checks it and keeps it on the list |
| The "Cooked!" message always said "Streak +1" | It now shows the real streak, and names any new badge |

### Minor
| Finding | Fix |
|---|---|
| The AI client could be closed by a provider that didn't own it | Shared with `Provider.value`; it lives as long as the app |
| Surprise Me hid why it showed a demo recipe; two quick rolls could finish out of order | New `surpriseFallbackReason`; stale results are ignored |
| The streak on screen could be stale if the app stayed open across days | The streak is now checked every time it is read |
| Programming errors were reported as "network" errors; a missing charset could garble emoji | Only real connection errors count as network; responses are always decoded as UTF-8 |
| "almond milk" matched dairy milk; decomposed accents (`n` + `~`) weren't folded | Plant milks are explicitly unmatched; combining accent marks are removed first |
| Two unnecessary `dart:typed_data` imports (lint) | Removed |

## For Meltem
- `recipe_detail_screen.dart`: the "cooked" snackbar text changed (see the table above). Adjust the wording or style as you like.
- `recipeProvider.surpriseFallbackReason` can be shown on the Surprise screen when the AI wasn't used.

## How to check it yourself
```bash
flutter analyze
flutter test
```

## Tests added or updated
- `widget_test.dart`: no pending timers, no font downloads
- `store_migrations_test.dart`: undated streak reset
- `fridge_and_grocery_provider_test.dart`: re-adding a checked item
- `recipe_provider_logic_test.dart`: a surprise counts once
- `ingredient_matcher_test.dart`: decomposed accents, plant milks
