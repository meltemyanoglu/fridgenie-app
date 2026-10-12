// Routing, auth, CORS and rate-limit behavior of the Worker entry point.

import { afterEach, describe, expect, it, vi } from "vitest";
import worker from "../src/index.js";
import { BASE_URL, TINY_JPEG_BASE64, denyLimiter, get, makeEnv, post } from "./helpers.js";

afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe("router", () => {
  it("serves health without a token", async () => {
    const res = await get("/v1/health");
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ status: "ok" });
    expect(res.headers.get("X-Request-Id")).toBeTruthy();
  });

  it("tolerates a trailing slash", async () => {
    expect((await get("/v1/health/")).status).toBe(200);
  });

  it("returns 404 for unknown paths, including the old root scan endpoint", async () => {
    const res = await post("/", { imageBase64: TINY_JPEG_BASE64 });
    expect(res.status).toBe(404);
    expect((await res.json()).error.code).toBe("NOT_FOUND");
  });

  it("returns 405 for the wrong method", async () => {
    const res = await get("/v1/scan");
    expect(res.status).toBe(405);
    expect((await res.json()).error.code).toBe("METHOD_NOT_ALLOWED");
  });

  it("rejects a missing or wrong app token", async () => {
    const missing = await post("/v1/scan", {}, { headers: { "X-Fridgenie-Token": "" } });
    const wrong = await post("/v1/scan", {}, { headers: { "X-Fridgenie-Token": "nope" } });
    expect(missing.status).toBe(401);
    expect(wrong.status).toBe(401);
    expect((await wrong.json()).error.code).toBe("UNAUTHORIZED");
  });

  it("reports misconfiguration without leaking which secret is missing", async () => {
    const res = await post("/v1/scan", {}, { env: makeEnv({ APP_TOKEN: undefined }) });
    const body = await res.json();
    expect(res.status).toBe(500);
    expect(body.error.code).toBe("SERVER_MISCONFIGURED");
    expect(JSON.stringify(body)).not.toContain("APP_TOKEN");
  });

  it("returns 429 when the limiter denies, keyed by device id", async () => {
    const limiter = denyLimiter();
    const res = await post("/v1/scan", { imageBase64: TINY_JPEG_BASE64 }, {
      env: makeEnv({ SCAN_RATE_LIMITER: limiter }),
    });
    expect(res.status).toBe(429);
    expect((await res.json()).error).toMatchObject({ code: "RATE_LIMITED", retryable: true });
    expect(limiter.limit).toHaveBeenCalledWith({ key: "device:device_abc12345" });
  });

  it("falls back to the caller IP when the device id is malformed", async () => {
    const limiter = denyLimiter();
    await post("/v1/scan", {}, {
      env: makeEnv({ SCAN_RATE_LIMITER: limiter }),
      headers: { "X-Device-Id": "bad id!", "CF-Connecting-IP": "203.0.113.7" },
    });
    expect(limiter.limit).toHaveBeenCalledWith({ key: "ip:203.0.113.7" });
  });

  it("echoes only allow-listed CORS origins", async () => {
    const allowed = await worker.fetch(
      new Request(`${BASE_URL}/v1/scan`, { method: "OPTIONS", headers: { Origin: "https://web.fridgenie.test" } }),
      makeEnv(),
    );
    const denied = await worker.fetch(
      new Request(`${BASE_URL}/v1/scan`, { method: "OPTIONS", headers: { Origin: "https://evil.test" } }),
      makeEnv(),
    );
    expect(allowed.status).toBe(204);
    expect(allowed.headers.get("Access-Control-Allow-Origin")).toBe("https://web.fridgenie.test");
    expect(denied.headers.get("Access-Control-Allow-Origin")).toBeNull();
  });
});
