/**
 * Calendar-date helpers. Dates travel as "YYYY-MM-DD" keys (the shape of
 * Postgres `date` columns) and are manipulated with UTC arithmetic so that
 * timezones and DST can never shift a key by a day.
 */

const KEY_RE = /^\d{4}-\d{2}-\d{2}$/;

export function isDateKey(value: unknown): value is string {
  if (typeof value !== "string" || !KEY_RE.test(value)) return false;
  const [y, m, d] = value.split("-").map(Number);
  const t = new Date(Date.UTC(y, m - 1, d));
  return t.getUTCFullYear() === y && t.getUTCMonth() === m - 1 && t.getUTCDate() === d;
}

function toUtc(key: string) {
  const [y, m, d] = key.split("-").map(Number);
  return new Date(Date.UTC(y, m - 1, d));
}

/** Local calendar date of a Date as a key (browser: the user's own date). */
export function toDateKey(date: Date): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

/** Local-midnight Date for a key (for calendar widgets). */
export function fromDateKey(key: string): Date {
  const [y, m, d] = key.split("-").map(Number);
  return new Date(y, m - 1, d);
}

export function addDays(key: string, days: number): string {
  const t = toUtc(key);
  t.setUTCDate(t.getUTCDate() + days);
  return t.toISOString().slice(0, 10);
}

/** 0 = Monday ... 6 = Sunday. */
export function weekdayIndex(key: string): number {
  return (toUtc(key).getUTCDay() + 6) % 7;
}

/** Monday of the week containing `key`. */
export function weekStartKey(key: string): string {
  return addDays(key, -weekdayIndex(key));
}

export function weekDays(weekStart: string): string[] {
  return Array.from({ length: 7 }, (_, i) => addDays(weekStart, i));
}

/** Saturday and Sunday of the week starting at `weekStart` (Monday). */
export function weekendOf(weekStart: string): [string, string] {
  return [addDays(weekStart, 5), addDays(weekStart, 6)];
}

export function daysBetween(fromKey: string, toKey: string): number {
  return Math.round((toUtc(toKey).getTime() - toUtc(fromKey).getTime()) / 86_400_000);
}

/** Today's date in a timezone (server/MCP default: APP_TIMEZONE or Asia/Jakarta). */
export function todayInTimezone(tz?: string): string {
  const zone = tz || process.env.APP_TIMEZONE || "Asia/Jakarta";
  // en-CA formats as YYYY-MM-DD
  return new Intl.DateTimeFormat("en-CA", { timeZone: zone, year: "numeric", month: "2-digit", day: "2-digit" }).format(new Date());
}
