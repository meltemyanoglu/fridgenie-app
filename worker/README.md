# Fridgenie API Worker

Cloudflare Worker that sits between the Flutter app and Google Gemini. The Gemini key lives only here as a secret; the app never sees it.

## Endpoints

All `POST` endpoints need two headers:

| Header | Value |
|---|---|
| `X-Fridgenie-Token` | The `APP_TOKEN` secret (also passed to the app at build time) |
| `X-Device-Id` | Optional, 8–64 chars `[A-Za-z0-9_-]`; used as the rate-limit key (falls back to IP) |

### `GET /v1/health`
Public. Returns `{ "status": "ok" }`.

### `POST /v1/scan`
```json
{ "imageBase64": "<base64 bytes>", "mimeType": "image/jpeg" }
```
`mimeType` is optional (default `image/jpeg`; also `png`, `webp`, `heic`, `heif`). Max ~5 MB image.

Returns `{ "ingredients": ["tomato", "eggs", "milk"] }` (lowercase, de-duplicated, max 15).

### `POST /v1/recipes`
```json
{
  "ingredients": ["tomato", "eggs"],
  "mode": "standard",
  "count": 1,
  "dietary": ["vegetarian"],
  "mood": "cozy",
  "cuisine": "turkish",
  "skill": "comfortable",
  "avoidTitles": ["Shakshuka"]
}
```
- `ingredients` is required (1–30) unless `mode` is `surpriseMe`.
- `count` is 1–4 (default 1).
- `mode`, `dietary`, `mood`, `cuisine`, `skill` use the Dart enum `.name` values; unknown values are ignored.
- Every returned recipe satisfies **all** requested dietary rules; non-compliant ones are discarded.

Returns `{ "recipes": [Recipe, ...] }`. Each recipe has `title, tagline, emoji, category, difficulty, cookMinutes, servings, nutrition{calories, proteinG, carbsG, fatG}, ingredients[], optionalIngredients[], steps[{order, text, minutes?}], substitutions[{missing, swap, reason}], moods[], cuisines[], dietary[], whyRecommended, tags[]`.

### Errors
Every error has the same shape, and `X-Request-Id` matches `requestId` in the logs:
```json
{ "error": { "code": "RATE_LIMITED", "message": "Too many requests. Please wait a minute.", "retryable": true }, "requestId": "..." }
```

| Status | Code | When |
|---|---|---|
| 400 | `BAD_REQUEST` | Invalid JSON or fields |
| 401 | `UNAUTHORIZED` | Missing/wrong app token |
| 404 / 405 | `NOT_FOUND` / `METHOD_NOT_ALLOWED` | Wrong path or method |
| 413 | `PAYLOAD_TOO_LARGE` | Body or image too big |
| 415 | `UNSUPPORTED_MEDIA_TYPE` | Not JSON, or unsupported image type |
| 422 | `AI_BAD_RESPONSE` | Gemini blocked the content |
| 429 | `RATE_LIMITED` / `QUOTA_EXCEEDED` | Too many requests from this device (per minute / per day); `Retry-After` says how long to wait |
| 502 / 503 | `AI_BAD_RESPONSE` / `AI_UNAVAILABLE` | Gemini failed, timed out or replied badly |
| 500 | `SERVER_MISCONFIGURED` / `INTERNAL` | Missing secret or unexpected bug |

## Deploy (first time)

1. Create a Gemini key at <https://aistudio.google.com/app/apikey>.
2. Install and log in:
   ```bash
   cd worker
   npm install
   npx wrangler login
   ```
3. Store the secrets (you are prompted for each value):
   ```bash
   npx wrangler secret put GEMINI_API_KEY
   npx wrangler secret put APP_TOKEN      # any long random string, e.g. from: openssl rand -hex 32
   ```
4. Deploy and note the URL (e.g. `https://fridgenie-api.<account>.workers.dev`):
   ```bash
   npm run deploy
   ```
5. Smoke-test it:
   ```bash
   URL=https://fridgenie-api.<account>.workers.dev
   curl $URL/v1/health
   curl -X POST $URL/v1/recipes \
     -H 'Content-Type: application/json' \
     -H "X-Fridgenie-Token: <APP_TOKEN>" \
     -d '{"ingredients":["tomato","eggs","onion"]}'
   ```

## Connect the Flutter app

1. Copy `config/fridgenie.example.json` (repo root) to `config/fridgenie.json`. That file is git-ignored.
2. Fill in the Worker URL and the same `APP_TOKEN` value.
3. Run or build with:
   ```bash
   flutter run --dart-define-from-file=config/fridgenie.json
   flutter build apk --dart-define-from-file=config/fridgenie.json
   ```
Without that flag the app runs in demo mode (mock scan, offline recipes) and never calls the network.

## Configuration

| Setting | Where | Purpose |
|---|---|---|
| `GEMINI_API_KEY` | secret | Google Gemini key |
| `APP_TOKEN` | secret | Shared token the app sends |
| `GEMINI_MODEL` | `wrangler.toml` `[vars]` | Pinned model id; change and redeploy to upgrade |
| `ALLOWED_ORIGINS` | `wrangler.toml` `[vars]` | Comma-separated web origins for CORS (only needed for Flutter web) |
| `SCAN_RATE_LIMITER` / `RECIPE_RATE_LIMITER` | `wrangler.toml` `[[ratelimits]]` | Requests per minute per device |

The app token is extractable from the app binary, so treat it as a speed bump. The rate limits and Google AI Studio quota caps are what actually protect the key.

### Daily quota (optional, recommended once you ship)

The per-minute limits stop bursts; the daily quota stops one device from slowly draining the Gemini allowance all day (40 scans and 120 recipe calls per device per UTC day by default, tunable via the `DAILY_*_QUOTA` vars). It needs a small KV store:

```bash
npx wrangler kv namespace create QUOTA_KV
```

Paste the printed `id` into the commented `[[kv_namespaces]]` block in `wrangler.toml`, uncomment it, and redeploy. A capped device gets `429 QUOTA_EXCEEDED` with a `Retry-After` header pointing at the next UTC midnight. Without the KV block the Worker runs exactly as before.

## Local development

```bash
cp .dev.vars.example .dev.vars   # fill in real values; the file is git-ignored
npm run dev                       # http://localhost:8787
npm test                          # unit tests, Gemini is mocked
npm run tail                      # live logs from the deployed Worker
```

## Code layout

| File | Responsibility |
|---|---|
| `src/index.js` | Routing, auth, rate limiting, error handling |
| `src/handlers/` | One file per endpoint |
| `src/validation.js` | Request parsing and normalization |
| `src/prompts.js` / `src/schemas.js` | What we ask Gemini, and the JSON shape it must return |
| `src/gemini.js` | HTTP client: timeout, single retry, error mapping |
| `src/sanitize.js` | Forces Gemini output into the API contract |
| `src/config.js` | Limits and enum lists shared by everything above |
