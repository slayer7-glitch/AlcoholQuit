import { body, Env, HttpError, json } from "../../shared/http";
export async function preferences(request: Request, env: Env, user: string): Promise<Response> {
  const input = await body(request);
  if (!["Boy hero", "Girl hero", "No mascot"].includes(input.companion as string) || typeof input.reason !== "string" || input.reason.length > 2000 || typeof input.quitDate !== "string" || !Number.isFinite(Date.parse(input.quitDate))) throw new HttpError(400, "invalid_preferences");
  const payload = JSON.stringify({ companion: input.companion, reason: input.reason, quitDate: input.quitDate });
  await env.DB.prepare("INSERT INTO preferences(user_id,payload) VALUES (?,?) ON CONFLICT(user_id) DO UPDATE SET payload=excluded.payload").bind(user,payload).run();
  return json(JSON.parse(payload));
}
export async function removeAccount(env: Env, user: string): Promise<Response> {
  // Foreign-key cascades remove active data and revoke every session atomically.
  await env.DB.prepare("DELETE FROM accounts WHERE id = ?").bind(user).run();
  return new Response(null, {status: 204});
}
