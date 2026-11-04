import { addDays, formatMinutes, localNow, parseDate, parseTime, prettyDate, type Recurrence } from './dates';
import { Store, type Priority, type ProjectRow, type TaskRow } from './db';

export interface Tool {
  name: string;
  description: string;
  inputSchema: Record<string, unknown>;
  readOnly?: boolean;
  run(args: Record<string, any>, ctx: ToolContext): Promise<string>;
}

export interface ToolContext {
  store: Store;
  timeZone: string;
  now?: Date;
}

const PRIORITIES = ['red', 'orange', 'green'];
const RECURRENCES = ['none', 'daily', 'weekly', 'monthly'];

const idProp = {
  type: 'string',
  description: 'Task id: the 8-character code shown in brackets, e.g. "3f9a1c2e".',
};

const taskFields = {
  title: { type: 'string' },
  notes: { type: 'string' },
  priority: { type: 'string', enum: PRIORITIES, description: 'red = most urgent, green = least.' },
  due_date: { type: ['string', 'null'], description: 'YYYY-MM-DD in the user\'s local time zone. null = no date.' },
  due_time: { type: ['string', 'null'], description: 'HH:MM, 24-hour. null = no time. Needs a date.' },
  alarm: { type: 'boolean', description: 'Ring an alarm on the phone at the due time. Needs a date and time.' },
  recurrence: { type: 'string', enum: RECURRENCES, description: 'Repeat. Needs a date.' },
  project: { type: ['string', 'null'], description: 'Project name (partial match is fine). null = no project.' },
};

// ---------- Formatting ----------

const shortId = (uid: string) => uid.slice(0, 8);

async function projectNames(store: Store): Promise<Map<string, string>> {
  return new Map((await store.projects(true)).map((p) => [p.uid, p.name]));
}

const prioRank: Record<string, number> = { red: 0, orange: 1, green: 2 };

function sortTasks(list: TaskRow[]): TaskRow[] {
  return [...list].sort(
    (a, b) =>
      prioRank[a.priority] - prioRank[b.priority] ||
      (a.due_time ?? 9999) - (b.due_time ?? 9999) ||
      a.title.localeCompare(b.title),
  );
}

function line(t: TaskRow, names: Map<string, string>, showDate = false): string {
  const bits = [`${t.priority}`];
  if (showDate && t.due_date) bits.push(prettyDate(t.due_date));
  if (t.due_time != null) bits.push(formatMinutes(t.due_time));
  if (t.project_uid && names.has(t.project_uid)) bits.push(`project: ${names.get(t.project_uid)}`);
  if (t.alarm) bits.push('alarm');
  if (t.recurrence !== 'none') bits.push(`repeats ${t.recurrence}`);
  const box = t.done ? '[x]' : '[ ]';
  const notes = t.notes ? `\n    notes: ${t.notes.replace(/\n/g, ' ')}` : '';
  return `${box} [${shortId(t.uid)}] ${t.title} (${bits.join(' · ')})${notes}`;
}

function section(title: string, list: TaskRow[], names: Map<string, string>, showDate = false): string {
  if (list.length === 0) return '';
  return `## ${title} (${list.length})\n${list.map((t) => line(t, names, showDate)).join('\n')}\n`;
}

// ---------- Lookups ----------

async function findTask(store: Store, id: string): Promise<TaskRow> {
  const ref = String(id ?? '').trim().toLowerCase();
  if (ref.length < 4) throw new Error('Give the task id (at least 4 characters).');
  const matches = await store.tasks('t.uid LIKE ?', [`${ref}%`]);
  if (matches.length === 0) throw new Error(`No task with id "${id}".`);
  if (matches.length > 1) throw new Error(`Id "${id}" matches ${matches.length} tasks; give more characters.`);
  return matches[0];
}

async function resolveProject(store: Store, name: string | null | undefined): Promise<string | null | undefined> {
  if (name === undefined) return undefined;
  if (name === null || name.trim() === '') return null;
  const p = await store.findProject(name);
  if (!p) {
    const all = (await store.projects()).map((x) => x.name).join(', ') || 'none';
    throw new Error(`No project called "${name}". Projects: ${all}. Use add_project to create one.`);
  }
  return p.uid;
}

/** Applies the editable fields in args to a task. */
async function applyFields(store: Store, base: TaskRow, args: Record<string, any>): Promise<TaskRow> {
  const t = { ...base };
  if (args.title !== undefined) {
    if (!String(args.title).trim()) throw new Error('Title cannot be empty.');
    t.title = String(args.title).trim();
  }
  if (args.notes !== undefined) t.notes = String(args.notes);
  if (args.priority !== undefined) {
    if (!PRIORITIES.includes(args.priority)) throw new Error('priority must be red, orange or green.');
    t.priority = args.priority as Priority;
  }
  if (args.due_date !== undefined) {
    const newDate = args.due_date === null ? null : (parseDate(args.due_date), String(args.due_date));
    if (newDate !== t.due_date) t.recurrence_day = null; // monthly task repeats on the new day
    t.due_date = newDate;
  }
  if (args.due_time !== undefined) t.due_time = args.due_time === null ? null : parseTime(args.due_time);
  if (args.alarm !== undefined) t.alarm = args.alarm ? 1 : 0;
  if (args.recurrence !== undefined) {
    if (!RECURRENCES.includes(args.recurrence)) throw new Error('recurrence must be none, daily, weekly or monthly.');
    t.recurrence = args.recurrence as Recurrence;
  }
  const project = await resolveProject(store, args.project);
  if (project !== undefined) t.project_uid = project;
  if (args.alarm && (t.due_date == null || t.due_time == null)) {
    throw new Error('An alarm needs a due date and a due time.');
  }
  return t;
}

// ---------- Tools ----------

export const tools: Tool[] = [
  {
    name: 'todays_plan',
    readOnly: true,
    description:
      "The user's plan for today: late tasks (not done on their day), tasks due today, what is already done today, and the next 7 days. Call this first when the user asks what they are doing today, wants to plan their day, or says something like \"let's get cracking\".",
    inputSchema: { type: 'object', properties: {} },
    async run(_args, { store, timeZone, now }) {
      const { date: today, minutes } = localNow(timeZone, now);
      const weekEnd = addDays(today, 8);
      const names = await projectNames(store);
      const late = await store.tasks('t.done = 0 AND t.due_date < ?', [today]);
      const due = await store.tasks('t.done = 0 AND t.due_date = ?', [today]);
      // Local midnight as epoch ms (the extra minute covers the seconds).
      const startOfDay = (now ?? new Date()).getTime() - minutes * 60_000 - 60_000;
      const doneToday = await store.tasks('t.done = 1 AND t.done_at >= ?', [startOfDay]);
      const upcoming = await store.tasks('t.done = 0 AND t.due_date > ? AND t.due_date < ?', [today, weekEnd]);
      const undated = await store.tasks('t.done = 0 AND t.due_date IS NULL');

      const lateSorted = [...late].sort((a, b) => (b.due_date! < a.due_date! ? -1 : 1));
      const byDay = new Map<string, TaskRow[]>();
      for (const t of upcoming) byDay.set(t.due_date!, [...(byDay.get(t.due_date!) ?? []), t]);
      const upcomingText = [...byDay.keys()]
        .sort()
        .map((d) => `### ${prettyDate(d)}\n${sortTasks(byDay.get(d)!).map((t) => line(t, names)).join('\n')}`)
        .join('\n');

      return [
        `Today is ${prettyDate(today)} (${today}), local time ${formatMinutes(minutes)}, time zone ${timeZone}.`,
        '',
        section('Late: not done on their day', lateSorted, names, true) || 'Nothing late.\n',
        section('Due today', sortTasks(due), names) || 'Nothing else due today.\n',
        section('Done today', sortTasks(doneToday), names),
        upcoming.length ? `## Next 7 days (${upcoming.length})\n${upcomingText}\n` : 'Nothing due in the next 7 days.\n',
        undated.length ? `Also ${undated.length} undated open task(s); use list_tasks with undated=true to see them.` : '',
      ].join('\n');
    },
  },
  {
    name: 'list_tasks',
    readOnly: true,
    description: 'Lists tasks by date range, project, or undated. Dates are YYYY-MM-DD, inclusive.',
    inputSchema: {
      type: 'object',
      properties: {
        from: { type: 'string', description: 'First due date, YYYY-MM-DD.' },
        to: { type: 'string', description: 'Last due date, YYYY-MM-DD.' },
        project: { type: 'string', description: 'Only tasks in this project.' },
        undated: { type: 'boolean', description: 'Only tasks with no due date.' },
        include_done: { type: 'boolean', description: 'Include completed tasks. Default false.' },
      },
    },
    async run(args, { store }) {
      const where: string[] = [];
      const params: unknown[] = [];
      if (!args.include_done) where.push('t.done = 0');
      if (args.undated) where.push('t.due_date IS NULL');
      if (args.from) where.push('t.due_date >= ?'), params.push((parseDate(args.from), args.from));
      if (args.to) where.push('t.due_date <= ?'), params.push((parseDate(args.to), args.to));
      if (args.project) {
        where.push('t.project_uid = ?');
        params.push(await resolveProject(store, args.project));
      }
      const rows = await store.tasks(where.join(' AND ') || '1 = 1', params);
      const names = await projectNames(store);
      rows.sort((a, b) => (a.due_date ?? '9999').localeCompare(b.due_date ?? '9999') || prioRank[a.priority] - prioRank[b.priority]);
      if (rows.length === 0) return 'No matching tasks.';
      return `${rows.length} task(s):\n${rows.map((t) => line(t, names, true)).join('\n')}`;
    },
  },
  {
    name: 'add_task',
    description: 'Adds a task. Only title is required.',
    inputSchema: { type: 'object', properties: taskFields, required: ['title'] },
    async run(args, { store }) {
      if (!args.title || !String(args.title).trim()) throw new Error('A title is needed.');
      const draft = await applyFields(store, {
        title: '', notes: '', priority: 'green', due_date: null, due_time: null, alarm: 0,
        recurrence: 'none', recurrence_day: null, project_uid: null,
      } as TaskRow, args);
      const { uid: _u, rev: _r, updated_at: _a, created_at: _c, ...fields } = draft;
      const t = await store.createTask(fields);
      return `Added: ${line(t, await projectNames(store), true)}`;
    },
  },
  {
    name: 'update_task',
    description:
      'Changes a task. Use this to reschedule (due_date, due_time), rename, change priority, move to another project, or turn the alarm on or off. Only the fields given are changed.',
    inputSchema: { type: 'object', properties: { id: idProp, ...taskFields }, required: ['id'] },
    async run(args, { store }) {
      const t = await findTask(store, args.id);
      const saved = await store.saveTask(await applyFields(store, t, args));
      return `Updated: ${line(saved, await projectNames(store), true)}`;
    },
  },
  {
    name: 'complete_task',
    description: 'Marks a task done. A repeating task gets its next occurrence created automatically.',
    inputSchema: { type: 'object', properties: { id: idProp }, required: ['id'] },
    async run(args, { store, timeZone, now }) {
      const t = await findTask(store, args.id);
      if (t.done) return `Already done: ${t.title}`;
      const next = await store.completeTask(t, localNow(timeZone, now).date);
      const names = await projectNames(store);
      return next ? `Done: ${t.title}. Next occurrence: ${line(next, names, true)}` : `Done: ${t.title}`;
    },
  },
  {
    name: 'reopen_task',
    description: 'Marks a completed task as not done.',
    inputSchema: { type: 'object', properties: { id: idProp }, required: ['id'] },
    async run(args, { store }) {
      const t = await findTask(store, args.id);
      const saved = await store.saveTask({ ...t, done: 0, done_at: null });
      return `Reopened: ${line(saved, await projectNames(store), true)}`;
    },
  },
  {
    name: 'delete_task',
    description: 'Deletes a task permanently. Confirm with the user first.',
    inputSchema: { type: 'object', properties: { id: idProp }, required: ['id'] },
    async run(args, { store }) {
      const t = await findTask(store, args.id);
      await store.deleteTask(t);
      return `Deleted: ${t.title}`;
    },
  },
  {
    name: 'list_projects',
    readOnly: true,
    description: 'Lists projects with their open task counts.',
    inputSchema: {
      type: 'object',
      properties: { include_archived: { type: 'boolean' } },
    },
    async run(args, { store }) {
      const projects: ProjectRow[] = await store.projects(!!args.include_archived);
      if (projects.length === 0) return 'No projects.';
      const open = await store.tasks('t.done = 0');
      return projects
        .map((p) => {
          const mine = open.filter((t) => t.project_uid === p.uid);
          const red = mine.filter((t) => t.priority === 'red').length;
          return `- ${p.name}${p.archived ? ' (archived)' : ''}: ${mine.length} open${red ? `, ${red} red` : ''}`;
        })
        .join('\n');
    },
  },
  {
    name: 'add_project',
    description: 'Creates a project.',
    inputSchema: { type: 'object', properties: { name: { type: 'string' } }, required: ['name'] },
    async run(args, { store }) {
      const name = String(args.name ?? '').trim();
      if (!name) throw new Error('A name is needed.');
      if (await store.findProject(name).then((p) => p?.name.toLowerCase() === name.toLowerCase())) {
        return `Project "${name}" already exists.`;
      }
      await store.createProject(name);
      return `Added project: ${name}`;
    },
  },
];
