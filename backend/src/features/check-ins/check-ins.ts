import { body, Env, HttpError, json } from "../../shared/http";
interface Row { id: string; local_date: string; revision: number; deleted: number; mood: string; drinking_status: string; note: string }
export async function writeCheckIn(request: Request, env: Env, user: string, id: string): Promise<Response> {
  if (!/^[0-9a-f-]{36}$/i.test(id)) throw new HttpError(400, "invalid_id");
  const input = await body(request);
  if (!Number.isSafeInteger(input.revision) || (input.revision as number) < 0) throw new HttpError(400, "revision_required");
  const existing = await env.DB.prepare("SELECT * FROM check_ins WHERE user_id = ? AND id = ?").bind(user, id).first<Row>();
  const expected = existing?.revision ?? 0;
  const deleting = request.method === "DELETE";
  if (deleting && !existing) throw new HttpError(404, "not_found");
  if (!deleting) {
    if (typeof input.localDate !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(input.localDate) || !Number.isFinite(Date.parse(input.localDate)) || new Date(input.localDate).toISOString().slice(0, 10) !== input.localDate) throw new HttpError(400, "invalid_date");
    if (!["Great", "Okay", "Low", "Overwhelmed"].includes(input.mood as string) || !["No", "Yes", "Prefer not to say"].includes(input.drinkingStatus as string) || typeof input.note !== "string" || input.note.length > 4000) throw new HttpError(400, "invalid_check_in");
    // An identical retry is safe even if the first response was lost.
    if (existing && !existing.deleted && input.revision === expected - 1 && existing.local_date === input.localDate && existing.mood === input.mood && existing.drinking_status === input.drinkingStatus && existing.note === input.note) return json({ id, revision: expected });
  } else if (existing?.deleted && input.revision === expected - 1) return json({id, revision: expected});
  if (input.revision !== expected) throw new HttpError(409, "revision_conflict");
  const revision = expected + 1;
  const localDate = deleting ? existing!.local_date : input.localDate as string;
  const mood = deleting ? existing!.mood : input.mood as string;
  const status = deleting ? existing!.drinking_status : input.drinkingStatus as string;
  const note = deleting ? "" : input.note as string;
  const deleted = deleting ? 1 : 0;
  const payload = JSON.stringify({id, localDate, mood, drinkingStatus: status, note, revision, deleted: !!deleted});
  try {
    // A failed optimistic update makes the change insert fail too, rolling back the batch.
    await env.DB.batch([
      env.DB.prepare(`INSERT INTO check_ins(id,user_id,local_date,mood,drinking_status,note,revision,deleted)
        VALUES (?,?,?,?,?,?,?,?) ON CONFLICT(user_id,id) DO UPDATE SET local_date=excluded.local_date,mood=excluded.mood,drinking_status=excluded.drinking_status,note=excluded.note,revision=excluded.revision,deleted=excluded.deleted WHERE check_ins.revision = ?`).bind(id,user,localDate,mood,status,note,revision,deleted,expected),
      env.DB.prepare("INSERT INTO changes(user_id,record_id,revision,deleted,payload) VALUES (CASE WHEN changes() = 1 THEN ? ELSE NULL END,?,?,?,?)").bind(user,id,revision,deleted,payload)
    ]);
  } catch (error) {
    if (/constraint/i.test(String(error))) throw new HttpError(409, "record_conflict");
    throw error;
  }
  return json({id, revision});
}
