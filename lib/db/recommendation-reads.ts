import { and, desc, eq, isNotNull, isNull, notInArray, or, sql } from "drizzle-orm";
import { addDays, weekStartKey } from "@/lib/dates";
import {
  scoreRecommendations,
  type Candidate,
  type ReadingStatus,
  type Recommendation,
  type RecommendationContext,
} from "@/lib/recommendations";
import {
  authors,
  bookAuthors,
  bookGenres,
  books,
  genres,
  goodreadsData,
  readingLog,
  recommendationDismissals,
} from "./schema";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyDb = any;

const SEP = "||";

function parseAuthors(raw: string | null): { id: number; name: string }[] {
  if (!raw) return [];
  return raw.split(SEP).map((part) => {
    const i = part.indexOf(":");
    return { id: Number(part.slice(0, i)), name: part.slice(i + 1) };
  });
}

export interface RecommendationOptions {
  /** The user's today (YYYY-MM-DD). */
  today: string;
  limit?: number;
  mode?: "weekday" | "weekend";
  /** Suggest rereads (finished books) instead of unread ones. */
  includeFinished?: boolean;
}

async function loadCandidates(database: AnyDb, opts: RecommendationOptions): Promise<Candidate[]> {
  const weekStart = weekStartKey(opts.today);
  const weekEnd = addDays(weekStart, 6);

  const rows = await database
    .select({
      bookId: books.bookId,
      title: books.title,
      pages: books.pages,
      addedAt: books.addedAt,
      status: readingLog.status,
      currentPage: readingLog.currentPage,
      userRating: readingLog.rating,
      coverUrl: goodreadsData.coverUrl,
      goodreadsRating: goodreadsData.averageRating,
      goodreadsRatingsCount: goodreadsData.ratingsCount,
      authors: sql<string | null>`(SELECT string_agg(a.author_id::text || ':' || a.name, '||' ORDER BY ba.author_order) FROM book_authors ba JOIN authors a ON a.author_id = ba.author_id WHERE ba.book_id = ${books.bookId})`,
      genres: sql<string | null>`(SELECT string_agg(g.genre_name, '||' ORDER BY bg.is_primary DESC, g.genre_name) FROM book_genres bg JOIN genres g ON g.genre_id = bg.genre_id WHERE bg.book_id = ${books.bookId})`,
      lastSessionDate: sql<string | null>`(SELECT max(s.session_date)::text FROM reading_sessions s WHERE s.book_id = ${books.bookId})`,
      priorityLevel: sql<string | null>`(SELECT p.level FROM reading_priorities p WHERE p.book_id = ${books.bookId} AND p.status = 'active')`,
      priorityReason: sql<string | null>`(SELECT p.reason FROM reading_priorities p WHERE p.book_id = ${books.bookId} AND p.status = 'active')`,
      priorityTarget: sql<string | null>`(SELECT p.target_date::text FROM reading_priorities p WHERE p.book_id = ${books.bookId} AND p.status = 'active')`,
      dismissalKind: recommendationDismissals.kind,
      dismissalUntil: recommendationDismissals.untilDate,
      plannedThisWeek: sql<boolean>`EXISTS (SELECT 1 FROM reading_plan_items i WHERE i.book_id = ${books.bookId} AND i.status = 'planned' AND i.scheduled_date BETWEEN ${weekStart}::date AND ${weekEnd}::date)`,
    })
    .from(books)
    .leftJoin(readingLog, eq(readingLog.bookId, books.bookId))
    .leftJoin(goodreadsData, eq(goodreadsData.bookId, books.bookId))
    .leftJoin(recommendationDismissals, eq(recommendationDismissals.bookId, books.bookId))
    .where(
      opts.includeFinished
        ? eq(readingLog.status, "finished")
        : or(isNull(readingLog.status), notInArray(readingLog.status, ["finished", "did_not_finish"])),
    );

  return rows.map((r: Record<string, unknown>) => ({
    bookId: r.bookId as number,
    title: r.title as string,
    pages: (r.pages as number | null) ?? null,
    addedAt: r.addedAt ? new Date(r.addedAt as string | Date).toISOString() : null,
    status: (r.status as ReadingStatus | null) ?? null,
    currentPage: (r.currentPage as number | null) ?? null,
    lastSessionDate: (r.lastSessionDate as string | null) ?? null,
    authors: parseAuthors(r.authors as string | null),
    genres: r.genres ? (r.genres as string).split(SEP) : [],
    coverUrl: (r.coverUrl as string | null) ?? null,
    goodreadsRating: r.goodreadsRating != null ? Number(r.goodreadsRating) : null,
    goodreadsRatingsCount: (r.goodreadsRatingsCount as number | null) ?? null,
    userRating: (r.userRating as number | null) ?? null,
    priority: r.priorityLevel
      ? {
          level: r.priorityLevel as "critical" | "high" | "medium" | "low",
          reason: (r.priorityReason as string | null) ?? null,
          targetDate: (r.priorityTarget as string | null) ?? null,
        }
      : null,
    dismissal: r.dismissalKind
      ? { kind: r.dismissalKind as "dismissed" | "postponed", untilDate: (r.dismissalUntil as string | null) ?? null }
      : null,
    plannedThisWeek: Boolean(r.plannedThisWeek),
  }));
}

async function loadTasteContext(database: AnyDb) {
  // Genres of the five most recently finished books, most recent first.
  const recent = await database
    .select({
      bookId: readingLog.bookId,
      genres: sql<string | null>`(SELECT string_agg(g.genre_name, '||') FROM book_genres bg JOIN genres g ON g.genre_id = bg.genre_id WHERE bg.book_id = ${readingLog.bookId})`,
    })
    .from(readingLog)
    .where(and(eq(readingLog.status, "finished"), isNotNull(readingLog.dateFinished)))
    .orderBy(desc(readingLog.dateFinished), desc(readingLog.logId))
    .limit(5);
  const recentGenres: string[] = [];
  for (const r of recent as { genres: string | null }[]) {
    for (const g of r.genres ? r.genres.split(SEP) : []) if (!recentGenres.includes(g)) recentGenres.push(g);
  }

  const rated = and(eq(readingLog.status, "finished"), isNotNull(readingLog.rating));
  const byAuthor = await database
    .select({ k: sql<string>`lower(${authors.name})`, avg: sql<number>`avg(${readingLog.rating})::float` })
    .from(readingLog)
    .innerJoin(bookAuthors, eq(bookAuthors.bookId, readingLog.bookId))
    .innerJoin(authors, eq(authors.authorId, bookAuthors.authorId))
    .where(rated)
    .groupBy(sql`lower(${authors.name})`);
  const byGenre = await database
    .select({ k: sql<string>`lower(${genres.genreName})`, avg: sql<number>`avg(${readingLog.rating})::float` })
    .from(readingLog)
    .innerJoin(bookGenres, eq(bookGenres.bookId, readingLog.bookId))
    .innerJoin(genres, eq(genres.genreId, bookGenres.genreId))
    .where(rated)
    .groupBy(sql`lower(${genres.genreName})`);

  const toMap = (rows: { k: string; avg: number }[]) => Object.fromEntries(rows.map((r) => [r.k, Number(r.avg)]));
  return { recentGenres, authorRatings: toMap(byAuthor), genreRatings: toMap(byGenre) };
}

/** Ranked, explained suggestions (default: at most 5). */
export async function getRecommendations(database: AnyDb, opts: RecommendationOptions): Promise<Recommendation[]> {
  const [candidates, taste] = await Promise.all([loadCandidates(database, opts), loadTasteContext(database)]);
  const ctx: RecommendationContext = {
    today: opts.today,
    mode: opts.mode,
    limit: opts.limit,
    includeFinished: opts.includeFinished,
    ...taste,
  };
  return scoreRecommendations(candidates, ctx);
}

