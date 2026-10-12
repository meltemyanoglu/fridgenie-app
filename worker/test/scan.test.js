// POST /v1/scan: validation, Gemini request shape and response sanitizing.

import { afterEach, describe, expect, it, vi } from "vitest";
import { TINY_JPEG_BASE64, geminiReply, post, stubGemini } from "./helpers.js";

afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe("POST /v1/scan", () => {
  it("returns cleaned ingredients and calls Gemini with header auth and a schema", async () => {
    const fetchMock = stubGemini(
      geminiReply({ ingredients: ["Tomato", " eggs ", "tomato", "", 42, "Milk"] }),
    );

    const res = await post("/v1/scan", { imageBase64: TINY_JPEG_BASE64, mimeType: "image/JPEG" });

    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ ingredients: ["tomato", "eggs", "milk"] });

    const [url, init] = fetchMock.mock.calls[0];
    const sent = JSON.parse(init.body);
    expect(url).toContain("/gemini-test-model:generateContent");
    expect(url).not.toContain("key=");
    expect(init.headers["x-goog-api-key"]).toBe("gemini-test-key");
    expect(sent.generationConfig.responseSchema.required).toEqual(["ingredients"]);
    expect(sent.contents[0].parts[1].inline_data).toEqual({ mime_type: "image/jpeg", data: TINY_JPEG_BASE64 });
  });

  it("requires a JSON content type", async () => {
    const res = await post("/v1/scan", "x", { headers: { "Content-Type": "text/plain" } });
    expect(res.status).toBe(415);
  });

  it("rejects malformed JSON and non-object bodies", async () => {
    expect((await post("/v1/scan", "{oops")).status).toBe(400);
    expect((await post("/v1/scan", "[1,2]")).status).toBe(400);
  });

  it("rejects a missing or invalid image", async () => {
    expect((await post("/v1/scan", {})).status).toBe(400);
    expect((await post("/v1/scan", { imageBase64: "not base64!!" })).status).toBe(400);
  });

  it("rejects unsupported image types", async () => {
    const res = await post("/v1/scan", { imageBase64: TINY_JPEG_BASE64, mimeType: "image/gif" });
    expect(res.status).toBe(415);
  });

  it("rejects oversized bodies before calling Gemini", async () => {
    const fetchMock = stubGemini();
    const res = await post("/v1/scan", { imageBase64: "A".repeat(7_000_001) });
    expect(res.status).toBe(413);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("returns an empty list when Gemini sees nothing", async () => {
    stubGemini(geminiReply({ ingredients: [] }));
    const res = await post("/v1/scan", { imageBase64: TINY_JPEG_BASE64 });
    expect(await res.json()).toEqual({ ingredients: [] });
  });
});
