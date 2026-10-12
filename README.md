# 🍳 Fridgenie

Fridgenie is a Flutter app that helps you decide what to cook using the ingredients you already have.

Instead of thinking “what should I cook?”, you just pick what’s in your fridge and the app suggests meals for you.

---

## What you can do

-  Select ingredients from your fridge  
-  Get instant meal suggestions  
-  Try different cooking modes (challenge, surprise, mood-based)  
-  Track your cooking streak  
-  See how many meals you’ve created  

---

## Main Features

- **Ingredient selection** → tap to add/remove  
- **Meal generation** → AI-style suggestions  
- **Genie modes** → fun ways to explore recipes  
- **Progress tracking** → streak, stats, badges  
- **Clean UI** → simple and modern design  

---

## How to run

### Demo mode (no setup)
Runs fully offline with mock scanning and the built-in recipe catalog.

```bash
git clone https://github.com/meltemyanoglu/fridgenie-app.git
cd fridgenie-app
flutter pub get
flutter run
```

### With real AI
The AI runs behind our own Cloudflare Worker, so the app never contains the Gemini key.

1. Deploy the Worker once: see [`worker/README.md`](worker/README.md).
2. Copy `config/fridgenie.example.json` to `config/fridgenie.json` (git-ignored) and fill in the Worker URL and app token.
3. Run:
   ```bash
   flutter run --dart-define-from-file=config/fridgenie.json
   ```

---

## How it's built

```
Screens (lib/screens, lib/widgets)
   │  read/watch
Providers (lib/providers)          ← app state: fridge, recipes, grocery, user
   │                     │
Services (lib/data/services)     LocalStore (lib/data/storage)
   │  FridgenieApi                  on-device storage + migrations
   ▼
Cloudflare Worker (worker/)      ← holds the Gemini key, rate-limits, validates
   ▼
Google Gemini
```

| Folder | What lives there |
|---|---|
| `lib/screens`, `lib/widgets` | UI |
| `lib/providers` | App state (`FridgeProvider`, `RecipeProvider`, `GroceryProvider`, `UserProvider`) |
| `lib/data/models` | Data shapes (`Recipe`, `Ingredient`, `CookingStats`, …) |
| `lib/data/services` | AI client, offline recipe brain, ingredient matching, badge rules |
| `lib/data/storage` | On-device storage, keys and data migrations |
| `lib/data/mock` | Built-in ingredient and recipe catalog |
| `worker/` | Backend API (Cloudflare Worker) |
| `docs/backend-log/` | Step-by-step log of the backend work |

---

## Tests

```bash
flutter analyze && flutter test     # app
cd worker && npm test                # backend
```

GitHub Actions runs both on every push and pull request (see the **Actions** tab).

---

## Backend work log

Every backend change is explained, with timestamps, in [`docs/backend-log/`](docs/backend-log/README.md).
