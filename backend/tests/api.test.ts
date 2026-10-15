import { beforeAll, beforeEach, afterEach, describe, expect, it, vi } from "vitest";
import { DatabaseSync } from "node:sqlite";
import { readFileSync } from "node:fs";
import api from "../src/index";
import { generateKeyPair, SignJWT } from "jose";
import { hash } from "../src/features/authentication/authentication";
import type { Env } from "../src/shared/http";

const testKeys = vi.hoisted(() => ({ publicKey: undefined as any, privateKey: undefined as any }));
vi.mock("jose", async (original) => {
  const jose = await original<typeof import("jose")>();
  return { ...jose, createRemoteJWKSet: () => async () => testKeys.publicKey };
});
beforeAll(async () => { Object.assign(testKeys, await generateKeyPair("RS256")); });
async function identity(options: {audience?: string; nonce?: string; issuer?: string; expired?: boolean} = {}) {
  return new SignJWT({nonce: await hash(options.nonce ?? "a".repeat(32))})
    .setProtectedHeader({alg: "RS256", kid: "test"}).setSubject("apple-user")
    .setIssuer(options.issuer ?? "https://appleid.apple.com")
    .setAudience(options.audience ?? "com.alcoholquit.app")
    .setIssuedAt().setExpirationTime(options.expired ? Math.floor(Date.now()/1000)-1 : "5m")
    .sign(testKeys.privateKey);
}

// Execute the real migration and SQL, including transactions and foreign keys.
let db: DatabaseSync;
let env: Env;
const owner = "owner-token";
const other = "other-token";
const id = "11111111-1111-4111-8111-111111111111";
const input = {localDate: "2026-10-15", mood: "Okay", drinkingStatus: "No", note: "Private note", revision: 0};
function statement(sql: string, params: unknown[] = []): any {
  return {
    bind: (...args: unknown[]) => statement(sql,args),
    first: async () => db.prepare(sql).get(...params as []) ?? null,
    all: async () => ({results: db.prepare(sql).all(...params as [])}),
    run: async () => db.prepare(sql).run(...params as [])
  };
}
async function call(path: string, method = "GET", payload?: unknown, token = owner) {
  return api.fetch(new Request("https://api.example.test" + path, {method, headers: {Authorization: `Bearer ${token}`, "Content-Type": "application/json"}, body: payload === undefined ? undefined : JSON.stringify(payload)}),env);
}
beforeEach(async () => {
  db = new DatabaseSync(":memory:"); db.exec(readFileSync(new URL("../migrations/0001_initial.sql",import.meta.url).pathname,"utf8"));
  db.exec(readFileSync(new URL("../migrations/0002_auth_replay.sql",import.meta.url).pathname,"utf8"));
  env = {RATE_LIMITER: {limit: async () => ({success:true})}, APPLE_CLIENT_ID: "com.alcoholquit.app", DB: {
    prepare: (sql: string) => statement(sql),
    batch: async (statements: any[]) => {
      db.exec("BEGIN");
      try { const results = []; for (const item of statements) results.push(await item.run()); db.exec("COMMIT"); return results; }
      catch (error) { db.exec("ROLLBACK"); throw error; }
    }
  } as unknown as D1Database};
  for (const [user,token] of [["owner",owner],["other",other]]) {
    db.prepare("INSERT INTO accounts(id,apple_subject) VALUES (?,?)").run(user,user);
    db.prepare("INSERT INTO sessions(token_hash,user_id,expires_at) VALUES (?,?,?)").run(await hash(token),user,Math.floor(Date.now()/1000)+3600);
  }
});
afterEach(() => db.close());
describe("Worker API", () => {
  it("serves health without authentication and rejects private requests", async () => {
    expect((await call("/health", "GET",undefined, "invalid")).status).toBe(200);
    expect((await call("/v1/me", "GET",undefined, "invalid")).status).toBe(401);
  });
  it("limits requests before accessing private data", async () => {
    env.RATE_LIMITER = {limit: async () => ({success:false})};
    expect((await call("/v1/me")).status).toBe(429);
  });
  it("persists a check-in, accepts retries, and keeps sync private", async () => {
    expect((await call(`/v1/check-ins/${id}`,"PUT",input)).status).toBe(200);
    expect((await call(`/v1/check-ins/${id}`,"PUT",input)).status).toBe(200);
    const result = await (await call("/v1/sync")).json() as any;
    expect(result.changes).toHaveLength(1); expect(result.changes[0].note).toBe("Private note");
    expect((await (await call("/v1/sync","GET",undefined,other)).json() as any).changes).toEqual([]);
  });
  it("rejects stale edits and duplicate calendar days", async () => {
    await call(`/v1/check-ins/${id}`,"PUT",input);
    expect((await call(`/v1/check-ins/${id}`,"PUT",{...input,note:"Stale edit"})).status).toBe(409);
    expect((await call("/v1/check-ins/22222222-2222-4222-8222-222222222222","PUT",input)).status).toBe(409);
  });
  it("validates real calendar dates and note bounds", async () => {
    expect((await call(`/v1/check-ins/${id}`,"PUT",{...input,localDate:"2026-02-30"})).status).toBe(400);
    expect((await call(`/v1/check-ins/${id}`,"PUT",{...input,note:"x".repeat(4001)})).status).toBe(400);
    expect((await call("/v1/sync?cursor=abc")).status).toBe(400);
  });
  it("synchronizes deletion tombstones and permits safe deletion retries", async () => {
    await call(`/v1/check-ins/${id}`,"PUT",input);
    expect((await call(`/v1/check-ins/${id}`,"DELETE",{revision:1})).status).toBe(200);
    expect((await call(`/v1/check-ins/${id}`,"DELETE",{revision:1})).status).toBe(200);
    const result = await (await call("/v1/sync?cursor=1")).json() as any;
    expect(result.changes).toHaveLength(1); expect(result.changes[0].deleted).toBe(true); expect(result.changes[0].note).toBe("");
  });
  it("doesn't let another account delete an entry", async () => {
    await call(`/v1/check-ins/${id}`,"PUT",input);
    expect((await call(`/v1/check-ins/${id}`,"DELETE",{revision:1},other)).status).toBe(404);
    expect((await (await call("/v1/sync")).json() as any).changes).toHaveLength(1);
  });
  it("deletes account data and immediately revokes sessions", async () => {
    await call(`/v1/check-ins/${id}`,"PUT",input);
    expect((await call("/v1/me","DELETE")).status).toBe(204);
    expect((await call("/v1/me")).status).toBe(401);
    expect(db.prepare("SELECT * FROM check_ins").all()).toEqual([]);
    expect(db.prepare("SELECT * FROM changes").all()).toEqual([]);
  });
  it("verifies signed Apple credentials and rejects replay", async () => {
    const identityToken = await identity();
    const response = await call("/v1/auth/apple","POST",{identityToken,nonce:"a".repeat(32)});
    expect(response.status).toBe(200);
    const session = await response.json() as any;
    expect((await call("/v1/me","GET",undefined,session.token)).status).toBe(200);
    expect((await call("/v1/auth/apple","POST",{identityToken,nonce:"a".repeat(32)})).status).toBe(401);
  });
  it("rejects incorrect audience, issuer, nonce, and expired Apple tokens", async () => {
    for (const options of [{audience:"another.app"},{issuer:"https://attacker.test"},{nonce:"b".repeat(32)},{expired:true}]) {
      expect((await call("/v1/auth/apple","POST",{identityToken: await identity(options),nonce:"a".repeat(32)})).status).toBe(401);
    }
  });
  it("rejects malformed Apple identity credentials", async () => {
    expect((await call("/v1/auth/apple","POST",{identityToken:"invalid",nonce:"a".repeat(32)})).status).toBe(401);
  });
  it("persists preferences for the signed-in account only", async () => {
    expect((await call("/v1/me/preferences","PATCH",{companion:"Girl hero",reason:"My family",quitDate:"2026-10-15"})).status).toBe(200);
    expect((await (await call("/v1/me")).json() as any).preferences.reason).toBe("My family");
    expect((await (await call("/v1/me","GET",undefined,other)).json() as any).preferences).toBeNull();
  });
});
