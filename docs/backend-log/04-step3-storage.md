# 04 · Step 3 – Storage that never loses data

| | |
|---|---|
| **When** | 2026-10-12, 15:13 – 15:19 (Europe/Rome) |
| **Who** | Claude, for Bilge |
| **Commit** | see the status table in [README](README.md) |
| **Verified** | ✅ mock recipe data checked for round-trip edge cases (61 recipes, none found) · ⚠️ Dart code **not compiled yet**: run `flutter analyze` and `flutter test` |

## In one sentence
Everything the app saves on the phone (fridge, favorites, grocery list, profile) now loads instantly at startup, survives restarts, and can't be wiped by one bad entry.

## Why
| Problem before | What the user saw |
|---|---|
| Each provider loaded its data in the background *after* the app started; saves before that were ignored | A tap right after opening the app could be forgotten |
| Favorites stored only an id; old AI recipes were deleted after 50 new ones | Favorite AI recipes silently vanished |
| One corrupted saved recipe made the whole list fail to load | All saved AI recipes disappeared |
| Ingredients picked on the home screen but not in the fridge were dropped on restart | The selection reset every time |
| Grocery timers kept running after "Clear all" | An item added right after could get deleted |

## What changed

### One storage door: `LocalStore`
`lib/data/storage/local_store.dart` is opened **once, before the first screen**, and given to every provider. So providers read their data immediately and nothing can be lost while "loading". It also:
- reads lists **item by item**: a broken item is skipped and logged, the rest is kept,
- logs every failed disk write instead of ignoring it.

### All keys in one file
`lib/data/storage/storage_keys.dart` lists every saved key. The names did not change, so existing data on phones keeps working.

### Data upgrades: `StoreMigrations`
A tiny "schema version" is now saved. When data changes shape, a migration step upgrades it once at startup.
- **v1 → v2**: old favorites (ids only) are turned into full recipe copies. Favorites that were already lost in v1 can't be recovered, and the log says how many.

### Favorites store the full recipe
`RecipeProvider` now saves the whole recipe for each favorite, so a favorite can never disappear, whatever happens to other lists. The generated-recipes list is capped at 50 in memory as well as on disk.

### Tolerant models
- `Recipe.fromJson`: unknown values get safe defaults, steps are renumbered 1, 2, 3…, and a missing card gradient gets the category's colors (this also fixes a possible crash).
- `GroceryItem` is now immutable and validated when loaded.

### Provider fixes
| Provider | Fix |
|---|---|
| `FridgeProvider` | Loads instantly; home-screen selections survive restarts; removing from the fridge unselects |
| `GroceryProvider` | Timers cancelled on clear/remove; leftover checked items dropped on start; unique ids |
| `UserProvider` | Loads instantly (no more `hydrate()`), unknown saved values skipped instead of guessed |
| `RecipeProvider` | Full-recipe favorites; a right swipe doesn't create a duplicate-title favorite |

## Small UI touch
`recipe_detail_screen.dart`: `toggleFavorite(r.id, title: r.title)` became `toggleFavorite(r)`. That is the only screen change in this step.

## For Meltem
- The "already saved" snackbar in `recipe_detail_screen.dart` is in Turkish (*"Bu tarif zaten kaydedilmiş!"*) while the rest of the app is English. Worth aligning.
- `fridge_door_widget.dart` still talks to SharedPreferences directly for its own UI state. That's fine; it could use `context.read<LocalStore>()` later for consistency.

## How to check it yourself
```bash
flutter pub get
flutter analyze
flutter test test/data test/providers
```
Manual check: favorite an AI recipe, generate many more, restart the app: the favorite is still there.

## Tests added
- `local_store_test.dart`: bad items skipped, broken JSON tolerated
- `store_migrations_test.dart`: v1 favorites migrated, runs only once
- `recipe_test.dart`: all 61 mock recipes round-trip; broken data gets defaults
- `fridge_and_grocery_provider_test.dart`: restarts, timers, duplicates
- `recipe_provider_storage_test.dart`: favorites outlive the 50 cap, duplicate titles, swipes
