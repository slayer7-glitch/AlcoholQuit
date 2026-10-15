export class HttpError extends Error {
  constructor(public status: number, public code: string) { super(code); }
}
export function json(data: unknown, status = 200): Response {
  return Response.json(data, { status, headers: { "Cache-Control": "no-store", "X-Content-Type-Options": "nosniff" } });
}
export async function body(request: Request): Promise<Record<string, unknown>> {
  if (!(request.headers.get("content-type") ?? "").startsWith("application/json")) throw new HttpError(415, "json_required");
  const reader = request.body?.getReader();
  if (!reader) throw new HttpError(400, "invalid_json");
  let size = 0; const chunks: Uint8Array[] = [];
  while (true) {
    const { value, done } = await reader.read(); if (done) break;
    size += value.byteLength;
    if (size > 16384) { await reader.cancel(); throw new HttpError(413, "body_too_large"); }
    chunks.push(value);
  }
  const bytes = new Uint8Array(size); let offset = 0;
  for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.length; }
  let value: unknown;
  try { value = JSON.parse(new TextDecoder().decode(bytes)); } catch { throw new HttpError(400, "invalid_json"); }
  if (!value || typeof value !== "object" || Array.isArray(value)) throw new HttpError(400, "invalid_json");
  return value as Record<string, unknown>;
}
export interface Env { DB: D1Database; APPLE_CLIENT_ID: string; RATE_LIMITER: { limit(options: { key: string }): Promise<{ success: boolean }> } }
