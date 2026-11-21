import { and, asc, eq, gte, lte, sql } from "drizzle-orm";
import { isDateKey } from "@/lib/dates";
import { BookInputError } from "./book-writes";
import { books, readingLog, readingPlanItems, readingPriorities, readingSessions } from "./schema";

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
