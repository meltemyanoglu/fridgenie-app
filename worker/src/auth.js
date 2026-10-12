// App-token check and client identity used for rate limiting.
// The token is a speed bump against casual abuse, not real auth; rate limiting is the actual guard.

import { ApiError, ErrorCode } from "./http.js";

const TOKEN_HEADER = "X-Fridgenie-Token";
const DEVICE_HEADER = "X-Device-Id";
const DEVICE_ID_PATTERN = /^[A-Za-z0-9_-]{8,64}$/;

/** Throws 401 unless the request carries the configured app token. */
export function assertAppToken(request, env) {
  if (!env.APP_TOKEN) {
    throw new ApiError(500, ErrorCode.SERVER_MISCONFIGURED, "Server is not configured.", {
      logDetail: "Missing APP_TOKEN secret.",
    });
  }
  const provided = request.headers.get(TOKEN_HEADER) ?? "";
  if (!timingSafeEqual(provided, env.APP_TOKEN)) {
    throw new ApiError(401, ErrorCode.UNAUTHORIZED, "Missing or invalid app token.");
  }
}

/** Returns a stable key per client: the device id when well-formed, otherwise the caller IP. */
export function clientKey(request) {
  const deviceId = request.headers.get(DEVICE_HEADER);
  if (deviceId && DEVICE_ID_PATTERN.test(deviceId)) return `device:${deviceId}`;
  return `ip:${request.headers.get("CF-Connecting-IP") ?? "unknown"}`;
}

/** Compares two strings in time independent of where they first differ. */
function timingSafeEqual(a, b) {
  const encoder = new TextEncoder();
  const left = encoder.encode(a);
  const right = encoder.encode(b);
  let diff = left.length ^ right.length;
  for (let i = 0; i < right.length; i++) {
    diff |= (left[i] ?? 0) ^ right[i];
  }
  return diff === 0;
}
