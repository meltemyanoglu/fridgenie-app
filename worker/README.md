# Fridgenie vision worker

Cloudflare Worker that takes a base64 fridge photo and returns the food
ingredients Gemini Vision spotted. The Gemini API key lives only on the
Worker — the Flutter app never sees it.

## Deploy in 5 steps

### 1. Get a Gemini API key (free)

Visit <https://aistudio.google.com/app/apikey>, click **Create API key**,
copy it. The free tier of `gemini-2.0-flash` is 1500 requests/day — plenty
for an MVP.

### 2. Install Wrangler

```bash
cd worker
npm install
```

### 3. Authenticate with Cloudflare

```bash
npx wrangler login
```

This opens your browser; sign in with a free Cloudflare account.

### 4. Stash the Gemini key as a secret

```bash
npx wrangler secret put GEMINI_API_KEY
```

Paste the key when prompted. It's stored encrypted by Cloudflare and
exposed to the Worker as `env.GEMINI_API_KEY`.

### 5. Deploy

```bash
npx wrangler deploy
```

You'll get a URL like `https://fridgenie-vision.<your-handle>.workers.dev`.
Save it — that's the value Flutter needs.

## Wire the URL into the Flutter app

```bash
flutter run --dart-define=FRIDGENIE_BACKEND=https://fridgenie-vision.you.workers.dev
```

When `FRIDGENIE_BACKEND` is set, `createDefaultRecognizer()` picks
`BackendVisionRecognizer` automatically. No `OPENAI_API_KEY` needed.

For App Store / Play Store builds, hardcode it in
`lib/data/services/ingredient_recognizer.dart` (the `_kBackendUrl`
fallback) or pass it via your CI as a `--dart-define`.

## Test locally

Run the Worker locally:

```bash
npx wrangler dev
```

Then hit it:

```bash
# tiny test with a real JPEG
IMG=$(base64 -i some_fridge_photo.jpg)
curl -X POST http://127.0.0.1:8787 \
  -H 'Content-Type: application/json' \
  -d "{\"imageBase64\":\"$IMG\"}"
```

Expected response:

```json
{ "ingredients": ["tomato", "milk", "eggs", "onion"] }
```

## Rate limiting (recommended once you ship)

Free tier abuse is real. Easiest fix is Cloudflare's built-in
**Rate Limiting Rules** (Dashboard → your zone → Security → Rate Limiting).
Set something like *10 requests per minute per IP* in front of this Worker.

For per-device quotas, switch to Workers KV: store a daily counter keyed
by an opaque device ID the app sends in a header.

## API contract

```
POST  /
Content-Type: application/json

{
  "imageBase64": "<JPEG bytes, base64>",
  "mimeType":    "image/jpeg"   // optional, default image/jpeg
}

→ 200 OK
{ "ingredients": ["tomato", "onion", "milk", ...] }

→ 4xx / 5xx
{ "error": "...", "detail": "..." }
```
