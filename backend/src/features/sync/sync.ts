import { Env, HttpError, json } from "../../shared/http";
export async function sync(url: URL, env: Env, user: string): Promise<Response> {
  const raw = url.searchParams.get("cursor") ?? "0";
  if (!/^\d+$/.test(raw) || !Number.isSafeInteger(Number(raw))) throw new HttpError(400, "invalid_cursor");
  const rows = await env.DB.prepare("SELECT sequence,payload FROM changes WHERE user_id = ? AND sequence > ? ORDER BY sequence LIMIT 100").bind(user, Number(raw)).all<{sequence: number; payload: string}>();
  return json({ changes: rows.results.map(row => JSON.parse(row.payload)), cursor: rows.results.at(-1)?.sequence ?? Number(raw), hasMore: rows.results.length === 100 });
}
