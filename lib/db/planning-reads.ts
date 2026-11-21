import { and, asc, desc, eq, gte, lte, sql } from "drizzle-orm";
import { addDays, isDateKey, weekStartKey } from "@/lib/dates";
import { BookInputError } from "./book-writes";
import {
  books,
  readingLog,
  readingPlanItems,
  readingPriorities,
  readingPriorityHistory,
  readingSessions,
  weeklyReadingReviews,
} from "./schema";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyDb = any;

export interface PlannerItem {
  item: typeof readingPlanItems.$inferSelect;
  bookId: number;
  title: string;
  pages: number | null;
  authors: string | null;
  coverUrl: string | null;
  currentPage: number | null;
}

export interface PlannerSession {
  sessionId: number;
  bookId: number;
  title: string;
  sessionDate: string;
  pagesRead: number | null;
  minutesRead: number | null;
  /** The plan item this session fulfilled, if any (spontaneous sessions have none). */
  linkedItemId: number | null;
}

export interface PlannerTarget {
  priorityId: number;
  bookId: number;
  title: string;
  level: string;
  targetDate: string;
}

export interface PlannerFinished {
  bookId: number;
  title: string;
  dateFinished: string;
  rating: number | null;
}

export interface PlannerRange {
  from: string;
  to: string;
  items: PlannerItem[];
  sessions: PlannerSession[];
  targets: PlannerTarget[];
  finished: PlannerFinished[];
}

const TIME_RANK = sql`CASE ${readingPlanItems.timeOfDay} WHEN 'morning' THEN 0 WHEN 'afternoon' THEN 1 WHEN 'evening' THEN 2 ELSE 3 END`;

/** Everything the planner/calendar draws between two dates (inclusive). */
export async function getPlannerRange(database: AnyDb, from: string, to: string): Promise<PlannerRange> {
  if (!isDateKey(from) || !isDateKey(to)) throw new BookInputError("from and to must be valid YYYY-MM-DD dates");
  if (to < from) throw new BookInputError("to must be on or after from");

  const items = await database
    .select({
      item: readingPlanItems,
      bookId: books.bookId,
      title: books.title,
      pages: books.pages,
      authors: sql<string | null>`(SELECT string_agg(a.name, ', ' ORDER BY ba.author_order) FROM book_authors ba JOIN authors a ON a.author_id = ba.author_id WHERE ba.book_id = ${books.bookId})`,
      coverUrl: sql<string | null>`(SELECT g.cover_url FROM goodreads_data g WHERE g.book_id = ${books.bookId})`,
      currentPage: sql<number | null>`(SELECT rl.current_page FROM reading_log rl WHERE rl.book_id = ${books.bookId})`,
    })
    .from(readingPlanItems)
    .innerJoin(books, eq(readingPlanItems.bookId, books.bookId))
    .where(and(gte(readingPlanItems.scheduledDate, from), lte(readingPlanItems.scheduledDate, to)))
    .orderBy(asc(readingPlanItems.scheduledDate), asc(TIME_RANK), asc(readingPlanItems.itemId));

  const sessions = await database
    .select({
      sessionId: readingSessions.sessionId,
      bookId: books.bookId,
      title: books.title,
      sessionDate: readingSessions.sessionDate,
      pagesRead: readingSessions.pagesRead,
      minutesRead: readingSessions.minutesRead,
      linkedItemId: sql<number | null>`(SELECT i.item_id FROM reading_plan_items i WHERE i.session_id = ${readingSessions.sessionId} LIMIT 1)`,
    })
    .from(readingSessions)
    .innerJoin(books, eq(readingSessions.bookId, books.bookId))
    .where(and(gte(readingSessions.sessionDate, from), lte(readingSessions.sessionDate, to)))
    .orderBy(asc(readingSessions.sessionDate), asc(readingSessions.sessionId));

  const targets = await database
    .select({
      priorityId: readingPriorities.priorityId,
      bookId: books.bookId,
      title: books.title,
      level: readingPriorities.level,
      targetDate: readingPriorities.targetDate,
    })
    .from(readingPriorities)
    .innerJoin(books, eq(readingPriorities.bookId, books.bookId))
    .where(
      and(
        eq(readingPriorities.status, "active"),
        gte(readingPriorities.targetDate, from),
        lte(readingPriorities.targetDate, to),
      ),
    )
    .orderBy(asc(readingPriorities.targetDate), asc(readingPriorities.priorityId));

  const finished = await database
    .select({
      bookId: books.bookId,
      title: books.title,
      dateFinished: readingLog.dateFinished,
      rating: readingLog.rating,
    })
    .from(readingLog)
    .innerJoin(books, eq(readingLog.bookId, books.bookId))
    .where(and(eq(readingLog.status, "finished"), gte(readingLog.dateFinished, from), lte(readingLog.dateFinished, to)))
    .orderBy(asc(readingLog.dateFinished));

  return { from, to, items, sessions, targets, finished } as PlannerRange;
}

// ============================================================================
// PRIORITY HISTORY
// ============================================================================

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

// ============================================================================
// WEEKLY REVIEW
// ============================================================================

export interface WeekSummary {
  weekStart: string;
  weekEnd: string;
  /** Plan activities this week, not counting ones that were moved elsewhere. */
  activities: { total: number; planned: number; completed: number; skipped: number; rescheduled: number };
  pages: {
    /** Pages planned on activities that were not moved away. */
    planned: number;
    /** Pages logged on completed plan items. */
    actualFromPlans: number;
    /** Share of planned pages that were read, 0-100 (null when nothing was planned). Capped at 100. */
    completionPct: number | null;
    /** Everything read this week, including spontaneous sessions. */
    totalRead: number;
  };
  minutesRead: number;
  sessionsLogged: number;
  booksCompleted: { bookId: number; title: string; dateFinished: string; rating: number | null }[];
  activeReading: { bookId: number; title: string; currentPage: number | null; pages: number | null }[];
  priorityChanges: PriorityChange[];
  review: typeof weeklyReadingReviews.$inferSelect | null;
}

export async function getWeekSummary(database: AnyDb, weekStartInput: string): Promise<WeekSummary> {
  if (!isDateKey(weekStartInput)) throw new BookInputError("weekStart must be a valid YYYY-MM-DD date");
  const weekStart = weekStartKey(weekStartInput);
  const weekEnd = addDays(weekStart, 6);

  const items = await database
    .select({
      status: readingPlanItems.status,
      plannedPages: readingPlanItems.plannedPages,
      actualPages: readingPlanItems.actualPages,
    })
    .from(readingPlanItems)
    .where(and(gte(readingPlanItems.scheduledDate, weekStart), lte(readingPlanItems.scheduledDate, weekEnd)));

  const count = (s: string) => items.filter((i: { status: string }) => i.status === s).length;
  const kept = items.filter((i: { status: string }) => i.status !== "rescheduled");
  const plannedPages = kept.reduce((n: number, i: { plannedPages: number | null }) => n + (i.plannedPages ?? 0), 0);
  const actualFromPlans = items
    .filter((i: { status: string }) => i.status === "completed")
    .reduce((n: number, i: { actualPages: number | null }) => n + (i.actualPages ?? 0), 0);

  const [sessionTotals] = await database
    .select({
      pages: sql<number>`COALESCE(SUM(${readingSessions.pagesRead}), 0)::int`,
      minutes: sql<number>`COALESCE(SUM(${readingSessions.minutesRead}), 0)::int`,
      sessions: sql<number>`COUNT(*)::int`,
    })
    .from(readingSessions)
    .where(and(gte(readingSessions.sessionDate, weekStart), lte(readingSessions.sessionDate, weekEnd)));

  const booksCompleted = await database
    .select({ bookId: books.bookId, title: books.title, dateFinished: readingLog.dateFinished, rating: readingLog.rating })
    .from(readingLog)
    .innerJoin(books, eq(readingLog.bookId, books.bookId))
    .where(and(eq(readingLog.status, "finished"), gte(readingLog.dateFinished, weekStart), lte(readingLog.dateFinished, weekEnd)))
    .orderBy(asc(readingLog.dateFinished));

  const activeReading = await database
    .select({ bookId: books.bookId, title: books.title, currentPage: readingLog.currentPage, pages: books.pages })
    .from(readingLog)
    .innerJoin(books, eq(readingLog.bookId, books.bookId))
    .where(eq(readingLog.status, "reading"))
    .orderBy(asc(books.title));

  const priorityChanges = await getPriorityChanges(database, { sinceDate: weekStart, untilDate: weekEnd, limit: 50 });

  const [review] = await database.select().from(weeklyReadingReviews).where(eq(weeklyReadingReviews.weekStart, weekStart)).limit(1);

  return {
    weekStart,
    weekEnd,
    activities: {
      total: kept.length,
      planned: count("planned"),
      completed: count("completed"),
      skipped: count("skipped"),
      rescheduled: count("rescheduled"),
    },
    pages: {
      planned: plannedPages,
      actualFromPlans,
      completionPct: plannedPages > 0 ? Math.min(100, Math.round((actualFromPlans / plannedPages) * 100)) : null,
      totalRead: sessionTotals?.pages ?? 0,
    },
    minutesRead: sessionTotals?.minutes ?? 0,
    sessionsLogged: sessionTotals?.sessions ?? 0,
    booksCompleted,
    activeReading,
    priorityChanges,
    review: review ?? null,
  } as WeekSummary;
}

/** Saved reviews, newest week first. */
export async function listWeeklyReviews(database: AnyDb, limit = 12) {
  return database.select().from(weeklyReadingReviews).orderBy(desc(weeklyReadingReviews.weekStart)).limit(limit) as Promise<
    (typeof weeklyReadingReviews.$inferSelect)[]
  >;
}
