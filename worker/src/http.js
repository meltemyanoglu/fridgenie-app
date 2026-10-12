// HTTP helpers: typed API errors, JSON responses, CORS and structured logging.

/** Stable error codes the Flutter client maps to user-facing messages. */
export const ErrorCode = Object.freeze({
  BAD_REQUEST: "BAD_REQUEST",
  UNAUTHORIZED: "UNAUTHORIZED",
  NOT_FOUND: "NOT_FOUND",
  METHOD_NOT_ALLOWED: "METHOD_NOT_ALLOWED",
  PAYLOAD_TOO_LARGE: "PAYLOAD_TOO_LARGE",
  UNSUPPORTED_MEDIA_TYPE: "UNSUPPORTED_MEDIA_TYPE",
  RATE_LIMITED: "RATE_LIMITED",
  AI_UNAVAILABLE: "AI_UNAVAILABLE",
  AI_BAD_RESPONSE: "AI_BAD_RESPONSE",
  SERVER_MISCONFIGURED: "SERVER_MISCONFIGURED",
  INTERNAL: "INTERNAL",
});

/** Error that is safe to return to the client; internal details go only to logs. */
export class ApiError extends Error {
  /**
   * @param {number} status HTTP status code.
   * @param {string} code One of {@link ErrorCode}.
   * @param {string} message Client-safe message.
   * @param {{retryable?: boolean, logDetail?: unknown}} [options]
   */
  constructor(status, code, message, options = {}) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.code = code;
    this.retryable = options.retryable ?? false;
    this.logDetail = options.logDetail;
  }
}

/** Builds CORS headers; native apps send no Origin, so only allow-listed web origins are echoed. */
export function corsHeaders(request, env) {
  const origin = request.headers.get("Origin");
  const allowed = (env.ALLOWED_ORIGINS ?? "")
    .split(",")
    .map((o) => o.trim())
    .filter(Boolean);

  const headers = {
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, X-Fridgenie-Token, X-Device-Id",
    "Access-Control-Max-Age": "86400",
    Vary: "Origin",
  };
  if (origin && allowed.includes(origin)) {
    headers["Access-Control-Allow-Origin"] = origin;
  }
  return headers;
}

/** Serializes a JSON body with the request id and CORS headers attached. */
export function jsonResponse(body, { status = 200, requestId, cors = {} } = {}) {
  const headers = { "Content-Type": "application/json; charset=utf-8", ...cors };
  if (requestId) headers["X-Request-Id"] = requestId;
  return new Response(JSON.stringify(body), { status, headers });
}

/** Converts any thrown value into a client-safe error response. */
export function errorResponse(error, { requestId, cors }) {
  const apiError =
    error instanceof ApiError
      ? error
      : new ApiError(500, ErrorCode.INTERNAL, "Unexpected server error.");

  return jsonResponse(
    {
      error: {
        code: apiError.code,
        message: apiError.message,
        retryable: apiError.retryable,
      },
      requestId,
    },
    { status: apiError.status, requestId, cors },
  );
}

/** Creates a logger that writes one JSON line per event, tagged with the request id. */
export function createLogger(requestId) {
  const write = (level, message, fields) =>
    console.log(JSON.stringify({ level, message, requestId, ...fields }));

  return {
    info: (message, fields = {}) => write("info", message, fields),
    warn: (message, fields = {}) => write("warn", message, fields),
    error: (message, fields = {}) => write("error", message, fields),
  };
}
