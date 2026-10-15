import { authenticate, logout, signIn } from "./features/authentication/authentication";
import { writeCheckIn } from "./features/check-ins/check-ins";
import { preferences, removeAccount } from "./features/settings/settings";
import { sync } from "./features/sync/sync";
import { Env, HttpError, json } from "./shared/http";
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    try {
      const url = new URL(request.url); const path = url.pathname;
      if (path === "/health" && request.method === "GET") return json({status: "ok"});
      const allowed = await env.RATE_LIMITER.limit({ key: request.headers.get("CF-Connecting-IP") ?? "local" });
      if (!allowed.success) return json({error: "rate_limited"},429);
      if (path === "/v1/auth/apple" && request.method === "POST") return await signIn(request,env);
      const user = await authenticate(request,env);
      if (path === "/v1/auth/logout" && request.method === "POST") return await logout(request,env);
      if (path === "/v1/me" && request.method === "DELETE") return await removeAccount(env,user);
      if (path === "/v1/me" && request.method === "GET") {
        const row = await env.DB.prepare("SELECT payload FROM preferences WHERE user_id = ?").bind(user).first<{payload: string}>();
        return json({userId: user, preferences: row ? JSON.parse(row.payload) : null});
      }
      if (path === "/v1/me/preferences" && request.method === "PATCH") return await preferences(request,env,user);
      if (path === "/v1/sync" && request.method === "GET") return await sync(url,env,user);
      const match = path.match(/^\/v1\/check-ins\/([^/]+)$/);
      if (match && ["PUT","DELETE"].includes(request.method)) return await writeCheckIn(request,env,user,match[1]);
      return json({error: "not_found"},404);
    } catch (error) {
      return error instanceof HttpError ? json({error:error.code},error.status) : json({error:"internal_error"},500);
    }
  }
};
