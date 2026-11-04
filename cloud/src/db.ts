import { nextDueDate, type Recurrence } from './dates';

export type Priority = 'red' | 'orange' | 'green';

export interface TaskRow {
  uid: string;
  project_uid: string | null;
  title: string;
  notes: string;
  priority: Priority;
  due_date: string | null;
  due_time: number | null;
  alarm: number;
  recurrence: Recurrence;
  recurrence_day: number | null;
  done: number;
  done_at: number | null;
  created_at: number;
  updated_at: number;
  deleted: number;
  rev: number;
}

export interface ProjectRow {
  uid: string;
  name: string;
  archived: number;
  created_at: number;
  updated_at: number;
  deleted: number;
  rev: number;
}

const TASK_COLS = [
  'uid', 'project_uid', 'title', 'notes', 'priority', 'due_date', 'due_time', 'alarm',
  'recurrence', 'recurrence_day', 'done', 'done_at', 'created_at', 'updated_at', 'deleted', 'rev',
] as const;
const PROJECT_COLS = ['uid', 'name', 'archived', 'created_at', 'updated_at', 'deleted', 'rev'] as const;

export class Store {
  constructor(private db: D1Database, private clock: () => number = Date.now) {}

  private async nextRev(): Promise<number> {
    const r = await this.db
      .prepare("UPDATE meta SET value = value + 1 WHERE key = 'rev' RETURNING value")
      .first<{ value: number }>();
    return r!.value;
  }

  async currentRev(): Promise<number> {
    const r = await this.db.prepare("SELECT value FROM meta WHERE key = 'rev'").first<{ value: number }>();
    return r?.value ?? 0;
  }

  // ---------- Reads ----------

  async getTask(uid: string): Promise<TaskRow | null> {
    return this.db.prepare('SELECT * FROM tasks WHERE uid = ? AND deleted = 0').bind(uid).first<TaskRow>();
  }

  /** Open and done tasks, excluding deleted ones and archived projects. */
  async tasks(where: string, params: unknown[] = []): Promise<TaskRow[]> {
    const sql = `SELECT t.* FROM tasks t LEFT JOIN projects p ON p.uid = t.project_uid
      WHERE t.deleted = 0 AND (p.uid IS NULL OR (p.archived = 0 AND p.deleted = 0)) AND (${where})`;
    return (await this.db.prepare(sql).bind(...params).all<TaskRow>()).results;
  }

  async projects(includeArchived = false): Promise<ProjectRow[]> {
    const sql = `SELECT * FROM projects WHERE deleted = 0 ${includeArchived ? '' : 'AND archived = 0'} ORDER BY name`;
    return (await this.db.prepare(sql).all<ProjectRow>()).results;
  }

  async getProject(uid: string): Promise<ProjectRow | null> {
    return this.db.prepare('SELECT * FROM projects WHERE uid = ? AND deleted = 0').bind(uid).first<ProjectRow>();
  }

  /** Finds a project by exact or partial name (case-insensitive). */
  async findProject(name: string): Promise<ProjectRow | null> {
    const all = await this.projects(true);
    const n = name.trim().toLowerCase();
    return all.find((p) => p.name.toLowerCase() === n) ?? all.find((p) => p.name.toLowerCase().includes(n)) ?? null;
  }

  // ---------- Writes ----------

  private async putTask(t: TaskRow): Promise<void> {
    const vals = TASK_COLS.map((c) => t[c]);
    await this.db
      .prepare(`INSERT OR REPLACE INTO tasks (${TASK_COLS.join(',')}) VALUES (${TASK_COLS.map(() => '?').join(',')})`)
      .bind(...vals)
      .run();
  }

  private async putProject(p: ProjectRow): Promise<void> {
    const vals = PROJECT_COLS.map((c) => p[c]);
    await this.db
      .prepare(`INSERT OR REPLACE INTO projects (${PROJECT_COLS.join(',')}) VALUES (${PROJECT_COLS.map(() => '?').join(',')})`)
      .bind(...vals)
      .run();
  }

  /** Same rules as TaskService.normalise in the phone app. */
  static normalise(t: TaskRow): TaskRow {
    const out = { ...t };
    if (out.due_date == null) {
      out.due_time = null;
      out.recurrence = 'none';
    }
    if (out.due_date == null || out.due_time == null) out.alarm = 0;
    if (out.recurrence === 'monthly') {
      out.recurrence_day = out.recurrence_day ?? Number(out.due_date!.slice(8, 10));
    } else {
      out.recurrence_day = null;
    }
    return out;
  }

  async createTask(fields: Partial<TaskRow> & { title: string }): Promise<TaskRow> {
    const now = this.clock();
    const t = Store.normalise({
      uid: crypto.randomUUID(),
      project_uid: null,
      notes: '',
      priority: 'green',
      due_date: null,
      due_time: null,
      alarm: 0,
      recurrence: 'none',
      recurrence_day: null,
      done: 0,
      done_at: null,
      created_at: now,
      deleted: 0,
      ...fields,
      updated_at: now,
      rev: await this.nextRev(),
    } as TaskRow);
    await this.putTask(t);
    return t;
  }

  async saveTask(t: TaskRow): Promise<TaskRow> {
    const out = Store.normalise({ ...t, updated_at: this.clock(), rev: await this.nextRev() });
    await this.putTask(out);
    return out;
  }

  /** Marks done. A recurring task gets its next instance. Returns that instance. */
  async completeTask(t: TaskRow, today: string): Promise<TaskRow | null> {
    const now = this.clock();
    await this.saveTask({ ...t, done: 1, done_at: now });
    if (t.recurrence === 'none' || t.due_date == null) return null;
    return this.createTask({
      project_uid: t.project_uid,
      title: t.title,
      notes: t.notes,
      priority: t.priority,
      due_date: nextDueDate(t.due_date, t.recurrence, today, t.recurrence_day),
      due_time: t.due_time,
      alarm: t.alarm,
      recurrence: t.recurrence,
      recurrence_day: t.recurrence_day,
    });
  }

  async deleteTask(t: TaskRow): Promise<void> {
    await this.saveTask({ ...t, deleted: 1 });
  }

  async createProject(name: string): Promise<ProjectRow> {
    const now = this.clock();
    const p: ProjectRow = {
      uid: crypto.randomUUID(),
      name,
      archived: 0,
      created_at: now,
      updated_at: now,
      deleted: 0,
      rev: await this.nextRev(),
    };
    await this.putProject(p);
    return p;
  }

  // ---------- Sync with the phone ----------

  /**
   * Applies rows sent by the phone. A row wins if it is newer than the
   * stored one. Returns everything changed since [since], including the
   * phone's own rows, plus the new cursor.
   */
  async sync(
    since: number,
    incoming: { projects?: ProjectRow[]; tasks?: TaskRow[] },
  ): Promise<{ rev: number; projects: ProjectRow[]; tasks: TaskRow[] }> {
    for (const p of incoming.projects ?? []) {
      const old = await this.db.prepare('SELECT updated_at FROM projects WHERE uid = ?').bind(p.uid).first<{ updated_at: number }>();
      if (old && old.updated_at >= p.updated_at) continue;
      await this.putProject({ ...pickProject(p), rev: await this.nextRev() });
    }
    for (const t of incoming.tasks ?? []) {
      const old = await this.db.prepare('SELECT updated_at FROM tasks WHERE uid = ?').bind(t.uid).first<{ updated_at: number }>();
      if (old && old.updated_at >= t.updated_at) continue;
      await this.putTask({ ...pickTask(t), rev: await this.nextRev() });
    }
    const projects = (await this.db.prepare('SELECT * FROM projects WHERE rev > ? ORDER BY rev').bind(since).all<ProjectRow>()).results;
    const tasks = (await this.db.prepare('SELECT * FROM tasks WHERE rev > ? ORDER BY rev').bind(since).all<TaskRow>()).results;
    return { rev: await this.currentRev(), projects, tasks };
  }
}

function pickTask(t: TaskRow): TaskRow {
  const priority: Priority = ['red', 'orange', 'green'].includes(t.priority) ? t.priority : 'green';
  const recurrence: Recurrence = ['none', 'daily', 'weekly', 'monthly'].includes(t.recurrence) ? t.recurrence : 'none';
  if (typeof t.uid !== 'string' || typeof t.title !== 'string' || typeof t.updated_at !== 'number') {
    throw new Error('Bad task row');
  }
  return {
    uid: t.uid,
    project_uid: t.project_uid ?? null,
    title: t.title,
    notes: t.notes ?? '',
    priority,
    due_date: t.due_date ?? null,
    due_time: t.due_time ?? null,
    alarm: t.alarm ? 1 : 0,
    recurrence,
    recurrence_day: t.recurrence_day ?? null,
    done: t.done ? 1 : 0,
    done_at: t.done_at ?? null,
    created_at: t.created_at ?? t.updated_at,
    updated_at: t.updated_at,
    deleted: t.deleted ? 1 : 0,
    rev: 0,
  };
}

function pickProject(p: ProjectRow): ProjectRow {
  if (typeof p.uid !== 'string' || typeof p.name !== 'string' || typeof p.updated_at !== 'number') {
    throw new Error('Bad project row');
  }
  return {
    uid: p.uid,
    name: p.name,
    archived: p.archived ? 1 : 0,
    created_at: p.created_at ?? p.updated_at,
    updated_at: p.updated_at,
    deleted: p.deleted ? 1 : 0,
    rev: 0,
  };
}
