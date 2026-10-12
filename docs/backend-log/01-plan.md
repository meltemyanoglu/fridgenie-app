# 01 · The plan

| | |
|---|---|
| **When** | 2026-10-12, 14:37 (Europe/Rome) |
| **Who** | Bilge, with Claude |
| **Commit** | none (planning) |

## In one sentence
Fix the backend in six small steps, each one a separate commit on the `bilge-changes` branch, without breaking Meltem's screens.

## Ground rules
- All work happens on **`bilge-changes`**. Nothing is merged into `main` until Bilge says so.
- **Provider method names stay the same** wherever possible, so the UI keeps working with little or no change.
- Every step gets **its own commit** and **its own log file** in this folder.
- The secret AI key must only ever live inside the Worker, never in the app.

## The steps

| Step | Goal | Why it matters |
|---|---|---|
| 0 | Setup: repo access, accounts | Cloudflare account + Gemini key, owned by Meltem |
| 1 | Rewrite the Worker | Fixes the key leak (server side) and the broken scan |
| 2 | One clean API layer in Dart | App talks only to the Worker; key removed from the app |
| 3 | Fix storage | No more lost taps, lost favorites or wiped recipes |
| 4 | Fix business logic | Correct dietary filter, real streaks and badges, no stuck spinners |
| 5 | Tests + CI | Every future change is checked automatically on GitHub |
| 6 | Cleanup + handoff | README, notes for Meltem, final review |

## Accounts (Step 0)
Ideally Meltem owns these, since it's her app, and adds Bilge:
- **Cloudflare** (free) – hosts the Worker.
- **Google AI Studio** – creates the Gemini key. The key is stored only as a Worker secret.
