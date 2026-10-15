PRAGMA foreign_keys = ON;
CREATE TABLE accounts (id TEXT PRIMARY KEY, apple_subject TEXT NOT NULL UNIQUE, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE sessions (token_hash TEXT PRIMARY KEY, user_id TEXT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE, expires_at INTEGER NOT NULL);
CREATE TABLE check_ins (
  id TEXT NOT NULL, user_id TEXT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  local_date TEXT NOT NULL, mood TEXT NOT NULL, drinking_status TEXT NOT NULL, note TEXT NOT NULL DEFAULT '',
  revision INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, id)
);
CREATE UNIQUE INDEX one_active_day ON check_ins(user_id, local_date) WHERE deleted = 0;
CREATE TABLE changes (
  sequence INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  record_id TEXT NOT NULL, revision INTEGER NOT NULL, deleted INTEGER NOT NULL, payload TEXT NOT NULL
);
CREATE INDEX changes_owner ON changes(user_id, sequence);
CREATE TABLE preferences (user_id TEXT PRIMARY KEY REFERENCES accounts(id) ON DELETE CASCADE, payload TEXT NOT NULL);
