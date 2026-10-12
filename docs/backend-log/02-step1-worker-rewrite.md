# 02 · Step 1 – Worker rewrite

| | |
|---|---|
| **When** | 2026-10-12, 14:40 – 14:49 (Europe/Rome) |
| **Who** | Claude, for Bilge |
| **Commit** | `9213696` feat(worker): rewrite API worker with auth, rate limiting and structured output |
| **Verified** | ✅ 27 automated tests pass · ✅ ran in the real Cloudflare runtime locally · ⏳ not deployed yet |

## In one sentence
The Worker (the small server between the app and Google's AI) was rebuilt so it is secure, uses a current AI model, and always returns clean, predictable data.

## Why
The old Worker used a retired AI model (so scanning failed), let anyone on the internet use it, and leaked Google's internal error messages.

## What changed

### New endpoints
| Endpoint | What it does |
|---|---|
| `GET /v1/health` | "Am I alive?" check, no password needed |
| `POST /v1/scan` | Send a fridge photo → get a list of ingredients |
| `POST /v1/recipes` | Send ingredients + preferences → get 1 to 4 recipes |

The `/v1/` prefix lets us change the API later without breaking old app versions.

### Security
- **App token**: every request must send a shared secret (`X-Fridgenie-Token`). Random callers get `401`.
- **Rate limiting**: each phone may do 6 scans and 10 recipe requests per minute. More → `429`.
- **CORS**: only web addresses we list are allowed. Phone apps are unaffected.
- **Key in header**: the Gemini key is sent in a header, not in the URL (URLs end up in logs).
- **No leaks**: Google's error details go only to our logs, never to the caller.

> The app token can be dug out of the app, so it is a speed bump. The rate limit and Google's own quota are the real protection.

### Reliability
- **Current model** `gemini-3.5-flash-lite`, set in `wrangler.toml`. Upgrading = change one line and redeploy.
- **Structured output**: Gemini is told the exact JSON shape to return, so no more "find the JSON inside the text" hacks.
- **Sanitizing**: even so, every answer is cleaned (numbers clamped, steps renumbered, unknown values dropped).
- **Dietary safety**: if a recipe doesn't meet *all* the user's dietary rules, the server throws it away.
- **Timeout + retry**: waits max 25 s for Google, retries once if Google is temporarily busy.

### Clear errors
Every error looks the same, with a code the app can turn into a friendly message:
```json
{ "error": { "code": "RATE_LIMITED", "message": "Too many requests. Please wait a minute.", "retryable": true }, "requestId": "..." }
```

### Logs
Every request writes one-line JSON logs with a `requestId`. The same id is returned in the `X-Request-Id` header, so a user's problem can be found in the logs with `npm run tail`.

### Cleanup
- Removed the Xcode build cache that was committed by mistake in `worker/build/`.
- Upgraded Wrangler from v3 to v4.

## Files
| File | Role |
|---|---|
| `worker/src/index.js` | Routing, password check, rate limit, error handling |
| `worker/src/handlers/scan.js`, `recipes.js` | One file per endpoint |
| `worker/src/validation.js` | Checks and cleans everything the app sends |
| `worker/src/prompts.js`, `schemas.js` | What we ask Gemini, and the JSON shape it must answer with |
| `worker/src/gemini.js` | Talks to Google: timeout, retry, error mapping |
| `worker/src/sanitize.js` | Cleans Gemini's answer |
| `worker/src/config.js` | All limits and allowed values in one place |
| `worker/test/*.test.js` | 27 tests |
| `worker/README.md` | API contract + deploy guide |

## How to check it yourself
```bash
cd worker
npm install
npm test          # expect: 27 passed
```

## Still to do by a human
Deploy it (≈10 min, see `worker/README.md` → "Deploy (first time)"). Keep the Worker URL and the `APP_TOKEN` value: the app needs both.
