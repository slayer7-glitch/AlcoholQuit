import { createRemoteJWKSet, jwtVerify } from "jose";
import { body, Env, HttpError, json } from "../../shared/http";
const appleKeys = createRemoteJWKSet(new URL("https://appleid.apple.com/auth/keys"));
export async function hash(value: string): Promise<string> {
  return Array.from(new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value))), b => b.toString(16).padStart(2, "0")).join("");
}
export async function authenticate(request: Request, env: Env): Promise<string> {
  const token = request.headers.get("Authorization")?.match(/^Bearer ([A-Za-z0-9-]+)$/)?.[1];
  if (!token) throw new HttpError(401, "authentication_required");
  const session = await env.DB.prepare("SELECT user_id FROM sessions WHERE token_hash = ? AND expires_at > ?").bind(await hash(token), Math.floor(Date.now() / 1000)).first<{user_id: string}>();
  if (!session) throw new HttpError(401, "invalid_session");
  return session.user_id;
}
export async function signIn(request: Request, env: Env): Promise<Response> {
  const input = await body(request);
  if (typeof input.identityToken !== "string" || typeof input.nonce !== "string" || input.nonce.length < 16 || input.nonce.length > 256) throw new HttpError(400, "invalid_credentials");
  let subject: string;
  try {
    const { payload } = await jwtVerify(input.identityToken, appleKeys, { issuer: "https://appleid.apple.com", audience: env.APPLE_CLIENT_ID, algorithms: ["RS256"], maxTokenAge: "5m" });
    if (!payload.sub || payload.nonce !== await hash(input.nonce)) throw new Error("nonce");
    subject = payload.sub;
  } catch { throw new HttpError(401, "invalid_apple_token"); }
  // Identity tokens are single-use for this exchange, even inside their valid window.
  await env.DB.prepare("DELETE FROM auth_exchanges WHERE expires_at < ?").bind(Math.floor(Date.now()/1000)).run();
  try {
    await env.DB.prepare("INSERT INTO auth_exchanges(token_hash,expires_at) VALUES (?,?)").bind(await hash(input.identityToken), Math.floor(Date.now()/1000)+600).run();
  } catch (error) {
    if (/constraint/i.test(String(error))) throw new HttpError(401, "identity_token_already_used");
    throw error;
  }
  await env.DB.prepare("DELETE FROM sessions WHERE expires_at < ?").bind(Math.floor(Date.now()/1000)).run();
  const userId = crypto.randomUUID();
  await env.DB.prepare("INSERT INTO accounts(id, apple_subject) VALUES (?, ?) ON CONFLICT(apple_subject) DO NOTHING").bind(userId, subject).run();
  const account = await env.DB.prepare("SELECT id FROM accounts WHERE apple_subject = ?").bind(subject).first<{id: string}>();
  if (!account) throw new Error("account_creation_failed");
  const token = crypto.randomUUID() + "-" + crypto.randomUUID();
  const expiresAt = Math.floor(Date.now() / 1000) + 3600;
  await env.DB.prepare("INSERT INTO sessions(token_hash, user_id, expires_at) VALUES (?, ?, ?)").bind(await hash(token), account.id, expiresAt).run();
  return json({ token, expiresAt, userId: account.id });
}
export async function logout(request: Request, env: Env): Promise<Response> {
  const token = request.headers.get("Authorization")!.slice(7);
  await env.DB.prepare("DELETE FROM sessions WHERE token_hash = ?").bind(await hash(token)).run();
  return new Response(null, {status: 204});
}
