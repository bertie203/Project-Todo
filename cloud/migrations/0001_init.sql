-- Rows are never hard-deleted: deleted = 1 lets the phone learn about deletions.
-- rev increases on every write so the phone can ask for "everything since rev N".
-- updated_at is epoch milliseconds; the newer write wins.

CREATE TABLE meta (key TEXT PRIMARY KEY, value INTEGER NOT NULL);
INSERT INTO meta (key, value) VALUES ('rev', 0);

CREATE TABLE projects (
  uid TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  archived INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted INTEGER NOT NULL DEFAULT 0,
  rev INTEGER NOT NULL
);

CREATE TABLE tasks (
  uid TEXT PRIMARY KEY,
  project_uid TEXT,
  title TEXT NOT NULL,
  notes TEXT NOT NULL DEFAULT '',
  priority TEXT NOT NULL DEFAULT 'green',
  due_date TEXT,            -- YYYY-MM-DD, local date
  due_time INTEGER,         -- minutes after midnight
  alarm INTEGER NOT NULL DEFAULT 0,
  recurrence TEXT NOT NULL DEFAULT 'none',
  recurrence_day INTEGER,
  done INTEGER NOT NULL DEFAULT 0,
  done_at INTEGER,          -- epoch ms
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted INTEGER NOT NULL DEFAULT 0,
  rev INTEGER NOT NULL
);

CREATE INDEX tasks_rev ON tasks (rev);
CREATE INDEX projects_rev ON projects (rev);
CREATE INDEX tasks_due ON tasks (due_date);
