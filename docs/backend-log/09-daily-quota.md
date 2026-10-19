# 09 · Daily per-device quota and Retry-After

| | |
|---|---|
| **When** | 2026-10-19, 09:56 – 10:05 (Europe/Rome) |
| **Who** | Claude, for Bilge |
| **Commit** | see the status table in [README](README.md) |
| **Verified** | ✅ 39 Worker tests pass (8 new) · ✅ deploy dry-run bundles cleanly · ⚠️ Dart change checked by CI on push |

## In one sentence
One phone can no longer drain the whole Gemini allowance over a day, and every "slow down" answer now says exactly how long to wait.

## Why
The per-minute limits (6 scans, 10 recipes) stop bursts, but a device staying just under them could still make ~8 600 AI calls per day — enough to exhaust the free Gemini quota for everyone. This was listed as "idea for later" in [08](08-step6-cleanup-handoff.md); it's now done.

## What changed

### Daily quota (server)
- Each device gets **40 scans and 120 recipe generations per UTC day** (tunable in `wrangler.toml` via `DAILY_SCAN_QUOTA` / `DAILY_RECIPES_QUOTA`).
- Over the cap → `429 QUOTA_EXCEEDED` with a `Retry-After` header pointing at the next UTC midnight. Counters expire by themselves.
- It's **optional and off until activated**: it needs a tiny Cloudflare KV store (one command, see `worker/README.md` → "Daily quota"). Without it, the Worker behaves exactly as before — so Bilge's pending deploy is unaffected.

### Retry-After everywhere
The per-minute `429 RATE_LIMITED` now also sends `Retry-After: 60`, the standard way to tell clients how long to back off.

### Friendlier message in the app
The app used to show "try again in a minute" for every 429. A daily cap now gets its own message: *"Genie reached today's limit. Try again tomorrow."* (`FridgenieErrorCode.quotaExceeded`).

### Cost visibility
Every Gemini reply's token counts are now logged (`Gemini usage.` lines in `wrangler tail`), so actual AI usage per request is visible without opening Google's dashboard.

## Files
| File | Change |
|---|---|
| `worker/src/quota.js` | New: the daily counter and the midnight math |
| `worker/src/index.js` | Quota check wired in after the rate limit |
| `worker/src/http.js`, `rateLimit.js` | `Retry-After` support |
| `worker/src/gemini.js` | Token-usage logging |
| `worker/wrangler.toml`, `README.md` | Quota vars + how to activate |
| `lib/data/services/fridgenie_api.dart` | `quotaExceeded` code + message |
| `worker/test/quota.test.js` (8 tests), 1 new Dart test | Counting, midnight reset, overrides, headers, missing binding |

## How to check it yourself
```bash
cd worker && npm test     # expect: 39 passed
```
To activate in production: `worker/README.md` → "Daily quota (optional)".
