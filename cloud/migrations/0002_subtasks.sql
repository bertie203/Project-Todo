-- Ordered steps of a task, as a JSON array of {title, done}.
ALTER TABLE tasks ADD COLUMN subtasks TEXT NOT NULL DEFAULT '[]';

