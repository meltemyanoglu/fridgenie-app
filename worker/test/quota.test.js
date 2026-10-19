// Daily per-device quota: counting, reset at UTC midnight, optional binding.

import { afterEach, describe, expect, it, vi } from "vitest";
import { enforceDailyQuota, secondsUntilNextUtcDay } from "../src/quota.js";
import { TINY_JPEG_BASE64, denyLimiter, makeEnv, post } from "./helpers.js";

afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

/** In-memory stand-in for a KV namespace. */
function fakeKv(initial = {}) {
  const data = new Map(Object.entries(initial));
  return {
    data,
    get: vi.fn(async (key) => data.get(key) ?? null),
    put: vi.fn(async (key, value) => void data.set(key, value)),
  };
}

const silentLogger = { info: () => {}, warn: () => {}, error: () => {} };
const noon = new Date("2026-10-19T12:00:00Z");

function enforce(kv, overrides = {}) {
  return enforceDailyQuota({
    kv,
    action: "scan",
    clientKey: "device:abc",
    limit: 3,
    now: noon,
    logger: silentLogger,
    ...overrides,
  });
}

describe("enforceDailyQuota", () => {
  it("counts per device and per UTC day", async () => {
    const kv = fakeKv();
    await enforce(kv);
    await enforce(kv);
    expect(kv.data.get("quota:scan:device:abc:2026-10-19")).toBe("2");

    const [, , options] = kv.put.mock.calls[0];
    expect(options.expirationTtl).toBe(2 * 86_400);
  });

  it("throws 429 QUOTA_EXCEEDED at the limit, with Retry-After to midnight", async () => {
    const kv = fakeKv({ "quota:scan:device:abc:2026-10-19": "3" });
    const error = await enforce(kv).catch((e) => e);

    expect(error.status).toBe(429);
    expect(error.code).toBe("QUOTA_EXCEEDED");
    expect(error.retryable).toBe(true);
    expect(error.retryAfterSeconds).toBe(12 * 3600);
    expect(kv.put).not.toHaveBeenCalled();
  });

  it("a new UTC day starts a fresh counter", async () => {
    const kv = fakeKv({ "quota:scan:device:abc:2026-10-19": "3" });
    await enforce(kv, { now: new Date("2026-10-20T00:00:01Z") });
    expect(kv.data.get("quota:scan:device:abc:2026-10-20")).toBe("1");
  });

  it("skips when the binding is missing or the limit is off", async () => {
    await expect(enforce(undefined)).resolves.toBeUndefined();
    const kv = fakeKv();
    await enforce(kv, { limit: 0 });
    expect(kv.put).not.toHaveBeenCalled();
  });
});

describe("secondsUntilNextUtcDay", () => {
  it("handles midday, near-midnight and month ends", () => {
    expect(secondsUntilNextUtcDay(new Date("2026-10-19T12:00:00Z"))).toBe(43_200);
    expect(secondsUntilNextUtcDay(new Date("2026-10-19T23:59:59Z"))).toBe(1);
    expect(secondsUntilNextUtcDay(new Date("2026-10-31T23:00:00Z"))).toBe(3600);
  });
});

describe("quota through the router", () => {
  it("returns 429 with Retry-After and does not reach Gemini", async () => {
    const fetchMock = vi.fn();
    vi.stubGlobal("fetch", fetchMock);
    const day = new Date().toISOString().slice(0, 10);
    const kv = fakeKv({ [`quota:scan:device:device_abc12345:${day}`]: "40" });

    const res = await post("/v1/scan", { imageBase64: TINY_JPEG_BASE64 }, {
      env: makeEnv({ QUOTA_KV: kv }),
    });

    expect(res.status).toBe(429);
    expect((await res.json()).error.code).toBe("QUOTA_EXCEEDED");
    expect(Number(res.headers.get("Retry-After"))).toBeGreaterThan(0);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("honors the DAILY_SCAN_QUOTA env override", async () => {
    const day = new Date().toISOString().slice(0, 10);
    const kv = fakeKv({ [`quota:scan:device:device_abc12345:${day}`]: "2" });

    const res = await post("/v1/scan", { imageBase64: TINY_JPEG_BASE64 }, {
      env: makeEnv({ QUOTA_KV: kv, DAILY_SCAN_QUOTA: "2" }),
    });

    expect(res.status).toBe(429);
  });

  it("the per-minute rate limit also sends Retry-After: 60", async () => {
    const res = await post("/v1/scan", { imageBase64: TINY_JPEG_BASE64 }, {
      env: makeEnv({ SCAN_RATE_LIMITER: denyLimiter() }),
    });
    expect(res.status).toBe(429);
    expect(res.headers.get("Retry-After")).toBe("60");
  });
});
