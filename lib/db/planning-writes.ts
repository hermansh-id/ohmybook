import { and, asc, eq, sql } from "drizzle-orm";
import { books, readingPriorities, readingPriorityHistory } from "./schema";
import { BookInputError, runAtomic } from "./book-writes";
import { isDateKey } from "@/lib/dates";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyDb = any;

// ============================================================================
// PRIORITIES
// A priority is not a reading status. Nothing here ever changes a priority
// unless the caller explicitly asks for it.
// ============================================================================

export const PRIORITY_LEVELS = ["critical", "high", "medium", "low"] as const;
export type PriorityLevel = (typeof PRIORITY_LEVELS)[number];

export interface SetPriorityInput {
  bookId: number;
  level?: PriorityLevel;
  /** undefined = unchanged, "" or null = clear */
  reason?: string | null;
  targetDate?: string | null;
  estimatedMinutes?: number | null;
}

async function requireBook(database: AnyDb, bookId: number) {
  if (!Number.isInteger(bookId)) throw new BookInputError("bookId must be an integer");
  const [book] = await database
    .select({ bookId: books.bookId, title: books.title, pages: books.pages })
    .from(books)
    .where(eq(books.bookId, bookId))
    .limit(1);
  if (!book) throw new BookInputError(`Book ${bookId} not found`);
  return book as { bookId: number; title: string; pages: number | null };
}

function validatePriorityFields(input: SetPriorityInput) {
  if (input.level !== undefined && !PRIORITY_LEVELS.includes(input.level)) {
    throw new BookInputError(`Invalid level "${input.level}". Use one of: ${PRIORITY_LEVELS.join(", ")}`);
  }
  if (input.targetDate !== undefined && input.targetDate !== null && !isDateKey(input.targetDate)) {
    throw new BookInputError("targetDate must be a valid YYYY-MM-DD date");
  }
  const m = input.estimatedMinutes;
  if (m !== undefined && m !== null && (!Number.isInteger(m) || m <= 0)) {
    throw new BookInputError("estimatedMinutes must be a positive integer");
  }
}

/**
 * Create the book's active priority, or update it. Only provided fields change.
 * Level changes are written to reading_priority_history in the same transaction.
 */
export async function setPriority(database: AnyDb, input: SetPriorityInput) {
  validatePriorityFields(input);
  await requireBook(database, input.bookId);

  const [active] = await database
    .select()
    .from(readingPriorities)
    .where(and(eq(readingPriorities.bookId, input.bookId), eq(readingPriorities.status, "active")))
    .limit(1);

  const changes: Partial<typeof readingPriorities.$inferInsert> = {};
  if (input.level !== undefined) changes.level = input.level;
  if (input.reason !== undefined) changes.reason = input.reason?.trim() || null;
  if (input.targetDate !== undefined) changes.targetDate = input.targetDate || null;
  if (input.estimatedMinutes !== undefined) changes.estimatedMinutes = input.estimatedMinutes ?? null;

  if (!active) {
    const level = input.level ?? "medium";
    const results = await runAtomic(database, (d) => [
      d.insert(readingPriorities).values({ bookId: input.bookId, ...changes, level, status: "active" }).returning(),
      d.insert(readingPriorityHistory).values({ bookId: input.bookId, fromLevel: null, toLevel: level, fromStatus: null, toStatus: "active" }),
    ]);
    return (results[0] as unknown[])[0] as typeof readingPriorities.$inferSelect;
  }

  if (Object.keys(changes).length === 0) throw new BookInputError("Nothing to update");
  const levelChanged = changes.level !== undefined && changes.level !== active.level;
  const results = await runAtomic(database, (d) => [
    d
      .update(readingPriorities)
      .set({ ...changes, updatedAt: new Date() })
      .where(eq(readingPriorities.priorityId, active.priorityId))
      .returning(),
    ...(levelChanged
      ? [d.insert(readingPriorityHistory).values({ bookId: input.bookId, fromLevel: active.level, toLevel: changes.level, fromStatus: "active", toStatus: "active" })]
      : []),
  ]);
  return (results[0] as unknown[])[0] as typeof readingPriorities.$inferSelect;
}

/** Close the active priority as completed or cancelled (explicit user action). */
export async function closePriority(database: AnyDb, bookId: number, status: "completed" | "cancelled") {
  await requireBook(database, bookId);
  const [active] = await database
    .select()
    .from(readingPriorities)
    .where(and(eq(readingPriorities.bookId, bookId), eq(readingPriorities.status, "active")))
    .limit(1);
  if (!active) throw new BookInputError(`Book ${bookId} has no active priority`);

  const results = await runAtomic(database, (d) => [
    d.update(readingPriorities).set({ status, updatedAt: new Date() }).where(eq(readingPriorities.priorityId, active.priorityId)).returning(),
    d.insert(readingPriorityHistory).values({ bookId, fromLevel: active.level, toLevel: active.level, fromStatus: "active", toStatus: status }),
  ]);
  return (results[0] as unknown[])[0] as typeof readingPriorities.$inferSelect;
}

export const completePriority = (database: AnyDb, bookId: number) => closePriority(database, bookId, "completed");
export const cancelPriority = (database: AnyDb, bookId: number) => closePriority(database, bookId, "cancelled");

const LEVEL_RANK = sql`CASE ${readingPriorities.level} WHEN 'critical' THEN 0 WHEN 'high' THEN 1 WHEN 'medium' THEN 2 ELSE 3 END`;

export interface PriorityRow {
  priority: typeof readingPriorities.$inferSelect;
  bookId: number;
  title: string;
  pages: number | null;
  readingStatus: string | null;
  currentPage: number | null;
  authors: string | null;
  coverUrl: string | null;
}

export interface PriorityChange {
  historyId: number;
  bookId: number;
  title: string;
  fromLevel: string | null;
  toLevel: string | null;
  fromStatus: string | null;
  toStatus: string | null;
  createdAt: Date | null;
}

export async function listPriorities(
  database: AnyDb,
  opts: { status?: "active" | "completed" | "cancelled" | "all" } = {},
): Promise<PriorityRow[]> {
  const status = opts.status ?? "active";
  const rows = await database
    .select({
      priority: readingPriorities,
      bookId: books.bookId,
      title: books.title,
      pages: books.pages,
      readingStatus: sql<string | null>`(SELECT rl.status FROM reading_log rl WHERE rl.book_id = ${books.bookId})`,
      currentPage: sql<number | null>`(SELECT rl.current_page FROM reading_log rl WHERE rl.book_id = ${books.bookId})`,
      authors: sql<string | null>`(SELECT string_agg(a.name, ', ' ORDER BY ba.author_order) FROM book_authors ba JOIN authors a ON a.author_id = ba.author_id WHERE ba.book_id = ${books.bookId})`,
      coverUrl: sql<string | null>`(SELECT g.cover_url FROM goodreads_data g WHERE g.book_id = ${books.bookId})`,
    })
    .from(readingPriorities)
    .innerJoin(books, eq(readingPriorities.bookId, books.bookId))
    .where(status === "all" ? undefined : eq(readingPriorities.status, status))
    .orderBy(asc(LEVEL_RANK), sql`${readingPriorities.targetDate} ASC NULLS LAST`, asc(readingPriorities.priorityId));
  return rows as PriorityRow[];
}

/** Priority changes since a date (inclusive), newest first. */
export async function getPriorityChanges(
  database: AnyDb,
  opts: { sinceDate?: string; untilDate?: string; limit?: number } = {},
): Promise<PriorityChange[]> {
  const conds = [];
  if (opts.sinceDate) conds.push(sql`${readingPriorityHistory.createdAt} >= ${opts.sinceDate}::date`);
  if (opts.untilDate) conds.push(sql`${readingPriorityHistory.createdAt} < (${opts.untilDate}::date + 1)`);
  return database
    .select({
      historyId: readingPriorityHistory.historyId,
      bookId: books.bookId,
      title: books.title,
      fromLevel: readingPriorityHistory.fromLevel,
      toLevel: readingPriorityHistory.toLevel,
      fromStatus: readingPriorityHistory.fromStatus,
      toStatus: readingPriorityHistory.toStatus,
      createdAt: readingPriorityHistory.createdAt,
    })
    .from(readingPriorityHistory)
    .innerJoin(books, eq(readingPriorityHistory.bookId, books.bookId))
    .where(conds.length ? and(...conds) : undefined)
    .orderBy(sql`${readingPriorityHistory.createdAt} DESC`, sql`${readingPriorityHistory.historyId} DESC`)
    .limit(opts.limit ?? 50);
}
