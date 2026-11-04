// Dates are local calendar dates as "YYYY-MM-DD" strings.
// Same rules as lib/logic/recurrence.dart in the phone app.

export type Recurrence = 'none' | 'daily' | 'weekly' | 'monthly';

interface Ymd {
  y: number;
  m: number; // 1-12
  d: number;
}

export function parseDate(s: string): Ymd {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(s);
  if (!m) throw new Error(`Bad date "${s}", use YYYY-MM-DD`);
  const v = { y: +m[1], m: +m[2], d: +m[3] };
  if (v.m < 1 || v.m > 12 || v.d < 1 || v.d > daysInMonth(v.y, v.m)) {
    throw new Error(`Bad date "${s}"`);
  }
  return v;
}

export function formatDate({ y, m, d }: Ymd): string {
  return `${String(y).padStart(4, '0')}-${String(m).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
}

export function daysInMonth(y: number, m: number): number {
  return new Date(Date.UTC(y, m, 0)).getUTCDate();
}

/** Adds days to a date string. Uses UTC maths, so no clock-change issues. */
export function addDays(s: string, days: number): string {
  const { y, m, d } = parseDate(s);
  const t = new Date(Date.UTC(y, m - 1, d + days));
  return formatDate({ y: t.getUTCFullYear(), m: t.getUTCMonth() + 1, d: t.getUTCDate() });
}

/** Day of week, Monday = 1 ... Sunday = 7. */
export function weekday(s: string): number {
  const { y, m, d } = parseDate(s);
  const w = new Date(Date.UTC(y, m - 1, d)).getUTCDay();
  return w === 0 ? 7 : w;
}

export function stepRecurrence(from: string, r: Recurrence, monthDay?: number | null): string {
  switch (r) {
    case 'none':
      throw new Error('Task does not repeat');
    case 'daily':
      return addDays(from, 1);
    case 'weekly':
      return addDays(from, 7);
    case 'monthly': {
      const { y, m, d } = parseDate(from);
      const ny = m === 12 ? y + 1 : y;
      const nm = m === 12 ? 1 : m + 1;
      const day = monthDay ?? d;
      return formatDate({ y: ny, m: nm, d: Math.min(day, daysInMonth(ny, nm)) });
    }
  }
}

/** Next due date after completing; always after today. */
export function nextDueDate(due: string, r: Recurrence, today: string, monthDay?: number | null): string {
  let next = stepRecurrence(due, r, monthDay);
  while (next <= today) next = stepRecurrence(next, r, monthDay);
  return next;
}

/** Today's date and current minutes in the given time zone. */
export function localNow(timeZone: string, now = new Date()): { date: string; minutes: number } {
  const parts = Object.fromEntries(
    new Intl.DateTimeFormat('en-GB', {
      timeZone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      hourCycle: 'h23',
    })
      .formatToParts(now)
      .map((p) => [p.type, p.value]),
  );
  return {
    date: `${parts.year}-${parts.month}-${parts.day}`,
    minutes: Number(parts.hour) * 60 + Number(parts.minute),
  };
}

export function formatMinutes(min: number): string {
  return `${String(Math.floor(min / 60)).padStart(2, '0')}:${String(min % 60).padStart(2, '0')}`;
}

/** "14:30" or "9:05" -> minutes after midnight. */
export function parseTime(s: string): number {
  const m = /^(\d{1,2}):(\d{2})$/.exec(s.trim());
  if (!m || +m[1] > 23 || +m[2] > 59) throw new Error(`Bad time "${s}", use HH:MM`);
  return +m[1] * 60 + +m[2];
}

const DAY_NAMES = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const MONTH_NAMES = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/** "2026-11-04" -> "Wed 4 Nov". */
export function prettyDate(s: string): string {
  const { m, d } = parseDate(s);
  return `${DAY_NAMES[weekday(s)]} ${d} ${MONTH_NAMES[m]}`;
}

/** Whole days from a to b (b - a). */
export function daysBetween(a: string, b: string): number {
  const pa = parseDate(a);
  const pb = parseDate(b);
  return Math.round((Date.UTC(pb.y, pb.m - 1, pb.d) - Date.UTC(pa.y, pa.m - 1, pa.d)) / 86_400_000);
}
