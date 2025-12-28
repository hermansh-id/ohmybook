/**
 * Common database queries using Drizzle ORM
 *
 * This file contains helper functions for common database operations.
 * Import and use these in your Server Components, Server Actions, or API routes.
 */

import { db } from "./index";
import {
  books,
  authors,
  genres,
  series,
  readingLog,
  bookAuthors,
  bookGenres,
  seriesBooks,
  goodreadsData,
  readingStats,
  monthlyStats,
  yearlyStats,
  readingGoals,
  readingSessions,
} from "./schema";
import { eq, desc, and, sql, isNull } from "drizzle-orm";

// ============================================================================
// BOOKS
// ============================================================================

/**
 * Get all books with their authors and genres
 */
export async function getAllBooksWithDetails() {
  return await db
    .select({
      book: books,
      author: authors,
      genre: genres,
      readingStatus: readingLog,
      goodreads: goodreadsData,
    })
    .from(books)
    .leftJoin(bookAuthors, eq(books.bookId, bookAuthors.bookId))
    .leftJoin(authors, eq(bookAuthors.authorId, authors.authorId))
    .leftJoin(bookGenres, eq(books.bookId, bookGenres.bookId))
    .leftJoin(genres, eq(bookGenres.genreId, genres.genreId))
    .leftJoin(readingLog, eq(books.bookId, readingLog.bookId))
    .leftJoin(goodreadsData, eq(books.bookId, goodreadsData.bookId))
    .orderBy(desc(books.addedAt));
}

/**
 * Get a single book by ID with all related data
 */
export async function getBookById(bookId: number) {
  return await db
    .select()
    .from(books)
    .where(eq(books.bookId, bookId))
    .leftJoin(goodreadsData, eq(books.bookId, goodreadsData.bookId))
    .leftJoin(readingLog, eq(books.bookId, readingLog.bookId))
    .limit(1);
}

/**
 * Add a new book
 */
export async function createBook(bookData: {
  title: string;
  isbn?: string;
  year?: number;
  pages?: number;
  goodreadsUrl?: string;
}) {
  return await db.insert(books).values(bookData).returning();
}

// ============================================================================
// READING LOG
// ============================================================================

/**
 * Get currently reading books
 */
export async function getCurrentlyReadingBooks() {
  return await db
    .select({
      log: readingLog,
      book: books,
      authors: sql<string>`string_agg(DISTINCT ${authors.name}, ', ')`,
    })
    .from(readingLog)
    .innerJoin(books, eq(readingLog.bookId, books.bookId))
    .leftJoin(bookAuthors, eq(books.bookId, bookAuthors.bookId))
    .leftJoin(authors, eq(bookAuthors.authorId, authors.authorId))
    .where(eq(readingLog.status, "reading"))
    .groupBy(readingLog.logId, books.bookId)
    .orderBy(desc(readingLog.dateStarted));
}

/**
 * Get finished books
 */
export async function getFinishedBooks(limit: number = 50) {
  return await db
    .select({
      log: readingLog,
      book: books,
      authors: sql<string>`string_agg(DISTINCT ${authors.name}, ', ')`,
    })
    .from(readingLog)
    .innerJoin(books, eq(readingLog.bookId, books.bookId))
    .leftJoin(bookAuthors, eq(books.bookId, bookAuthors.bookId))
    .leftJoin(authors, eq(bookAuthors.authorId, authors.authorId))
    .where(eq(readingLog.status, "finished"))
    .groupBy(readingLog.logId, books.bookId)
    .orderBy(desc(readingLog.dateFinished))
    .limit(limit);
}

/**
 * Get finished books by date for calendar view
 * Returns books grouped by their finish date
 */
export async function getFinishedBooksByDate(year?: number, month?: number) {
  let whereConditions = [eq(readingLog.status, "finished")];

  // Filter by year and month if provided
  if (year && month) {
    whereConditions.push(
      sql`EXTRACT(YEAR FROM ${readingLog.dateFinished}) = ${year}`,
      sql`EXTRACT(MONTH FROM ${readingLog.dateFinished}) = ${month}`
    );
  } else if (year) {
    whereConditions.push(
      sql`EXTRACT(YEAR FROM ${readingLog.dateFinished}) = ${year}`
    );
  }

  return await db
    .select({
      log: readingLog,
      book: books,
      authors: sql<string>`string_agg(DISTINCT ${authors.name}, ', ')`,
      goodreads: goodreadsData,
    })
    .from(readingLog)
    .innerJoin(books, eq(readingLog.bookId, books.bookId))
    .leftJoin(bookAuthors, eq(books.bookId, bookAuthors.bookId))
    .leftJoin(authors, eq(bookAuthors.authorId, authors.authorId))
    .leftJoin(goodreadsData, eq(books.bookId, goodreadsData.bookId))
    .where(and(...whereConditions))
    .groupBy(readingLog.logId, books.bookId, goodreadsData.bookId)
    .orderBy(desc(readingLog.dateFinished));
}

/**
 * Get books on want-to-read list
 */
export async function getWantToReadBooks() {
  return await db
    .select({
      log: readingLog,
      book: books,
      authors: sql<string>`string_agg(DISTINCT ${authors.name}, ', ')`,
      goodreads: goodreadsData,
    })
    .from(readingLog)
    .innerJoin(books, eq(readingLog.bookId, books.bookId))
    .leftJoin(bookAuthors, eq(books.bookId, bookAuthors.bookId))
    .leftJoin(authors, eq(bookAuthors.authorId, authors.authorId))
    .leftJoin(goodreadsData, eq(books.bookId, goodreadsData.bookId))
    .where(eq(readingLog.status, "want_to_read"))
    .groupBy(readingLog.logId, books.bookId, goodreadsData.bookId)
    .orderBy(desc(readingLog.dateAdded));
}

/**
 * Add a book to reading log
 */
export async function addToReadingLog(
  bookId: number,
  status: "want_to_read" | "reading" | "finished" | "did_not_finish" | "on_hold" = "want_to_read"
) {
  return await db
    .insert(readingLog)
    .values({
      bookId,
      status,
    })
    .returning();
}

/**
 * Update reading status
 */
export async function updateReadingStatus(
  logId: number,
  updates: {
    status?: string;
    currentPage?: number;
    dateStarted?: string | Date;
    dateFinished?: string | Date;
    rating?: number;
    review?: string;
  }
) {
  // Convert Date objects to strings
  const dbUpdates: any = { ...updates };
  if (dbUpdates.dateStarted instanceof Date) {
    dbUpdates.dateStarted = dbUpdates.dateStarted.toISOString().split('T')[0];
  }
  if (dbUpdates.dateFinished instanceof Date) {
    dbUpdates.dateFinished = dbUpdates.dateFinished.toISOString().split('T')[0];
  }

  return await db
    .update(readingLog)
    .set(dbUpdates)
    .where(eq(readingLog.logId, logId))
    .returning();
}

/**
 * Mark book as finished
 */
export async function markBookAsFinished(
  logId: number,
  rating?: number,
  review?: string
) {
  const today = new Date().toISOString().split('T')[0];
  return await db
    .update(readingLog)
    .set({
      status: "finished",
      dateFinished: today,
      rating,
      review,
    })
    .where(eq(readingLog.logId, logId))
    .returning();
}

// ============================================================================
// STATISTICS
// ============================================================================

/**
 * Get overall reading statistics
 */
export async function getReadingStats() {
  return await db.select().from(readingStats).limit(1);
}

/**
 * Get yearly statistics
 */
export async function getYearlyStats(year?: number) {
  const query = db.select().from(yearlyStats);

  if (year) {
    return await query.where(eq(yearlyStats.year, year)).limit(1);
  }

  return await query.orderBy(desc(yearlyStats.year));
}

/**
 * Get monthly statistics
 */
export async function getMonthlyStats(year: number) {
  return await db
    .select()
    .from(monthlyStats)
    .where(eq(monthlyStats.year, year))
    .orderBy(desc(monthlyStats.month));
}

/**
 * Get current year's reading goal with actual progress
 */
export async function getCurrentYearGoal() {
  const currentYear = new Date().getFullYear();

  // Get the goal settings
  const goalData = await db
    .select()
    .from(readingGoals)
    .where(eq(readingGoals.year, currentYear))
    .limit(1);

  // Count books actually finished this year
  const progress = await db
    .select({
      count: sql<number>`COUNT(DISTINCT ${readingLog.logId})::int`,
      totalPages: sql<number>`COALESCE(SUM(${books.pages}), 0)::int`,
    })
    .from(readingLog)
    .leftJoin(books, eq(readingLog.bookId, books.bookId))
    .where(
      and(
        eq(readingLog.status, "finished"),
        sql`EXTRACT(YEAR FROM ${readingLog.dateFinished}) = ${currentYear}`
      )
    );

  const currentBooks = progress[0]?.count || 0;
  const currentPages = progress[0]?.totalPages || 0;

  // If no goal exists, return default with actual progress
  if (goalData.length === 0) {
    return [{
      goalId: 0,
      year: currentYear,
      targetBooks: 52,
      targetPages: null,
      currentBooks,
      currentPages,
      createdAt: new Date(),
      updatedAt: new Date(),
    }];
  }

  // Return goal with actual progress
  return [{
    ...goalData[0],
    currentBooks,
    currentPages,
  }];
}

/**
 * Set reading goal for a year
 */
export async function setReadingGoal(
  year: number,
  targetBooks?: number,
  targetPages?: number
) {
  return await db
    .insert(readingGoals)
    .values({
      year,
      targetBooks,
      targetPages,
    })
    .onConflictDoUpdate({
      target: readingGoals.year,
      set: {
        targetBooks,
        targetPages,
      },
    })
    .returning();
}

// ============================================================================
// AUTHORS & GENRES
// ============================================================================

/**
 * Get all authors with book counts
 */
export async function getAllAuthorsWithBookCount() {
  return await db
    .select({
      author: authors,
      bookCount: sql<number>`count(distinct ${bookAuthors.bookId})`,
    })
    .from(authors)
    .leftJoin(bookAuthors, eq(authors.authorId, bookAuthors.authorId))
    .groupBy(authors.authorId)
    .orderBy(desc(sql`count(distinct ${bookAuthors.bookId})`));
}

/**
 * Get all genres with book counts
 */
export async function getAllGenresWithBookCount() {
  return await db
    .select({
      genre: genres,
      bookCount: sql<number>`count(distinct ${bookGenres.bookId})`,
    })
    .from(genres)
    .leftJoin(bookGenres, eq(genres.genreId, bookGenres.genreId))
    .groupBy(genres.genreId)
    .orderBy(desc(sql`count(distinct ${bookGenres.bookId})`));
}

/**
 * Create a new author
 */
export async function createAuthor(name: string, bio?: string) {
  return await db
    .insert(authors)
    .values({ name, bio })
    .onConflictDoNothing()
    .returning();
}

/**
 * Create a new genre
 */
export async function createGenre(genreName: string, description?: string) {
  return await db
    .insert(genres)
    .values({ genreName, description })
    .onConflictDoNothing()
    .returning();
}

/**
 * Link book to author
 */
export async function linkBookToAuthor(
  bookId: number,
  authorId: number,
  authorOrder: number = 1
) {
  return await db
    .insert(bookAuthors)
    .values({ bookId, authorId, authorOrder })
    .onConflictDoNothing();
}

/**
 * Link book to genre
 */
export async function linkBookToGenre(
  bookId: number,
  genreId: number,
  isPrimary: boolean = false
) {
  return await db
    .insert(bookGenres)
    .values({ bookId, genreId, isPrimary })
    .onConflictDoNothing();
}

// ============================================================================
// SERIES
// ============================================================================

/**
 * Get all series with book counts
 */
export async function getAllSeries() {
  return await db
    .select({
      series: series,
      bookCount: sql<number>`count(${seriesBooks.bookId})`,
    })
    .from(series)
    .leftJoin(seriesBooks, eq(series.seriesId, seriesBooks.seriesId))
    .groupBy(series.seriesId)
    .orderBy(desc(series.createdAt));
}

/**
 * Get books in a series
 */
export async function getBooksInSeries(seriesId: number) {
  return await db
    .select({
      seriesBook: seriesBooks,
      book: books,
      authors: sql<string>`string_agg(DISTINCT ${authors.name}, ', ')`,
    })
    .from(seriesBooks)
    .innerJoin(books, eq(seriesBooks.bookId, books.bookId))
    .leftJoin(bookAuthors, eq(books.bookId, bookAuthors.bookId))
    .leftJoin(authors, eq(bookAuthors.authorId, authors.authorId))
    .where(eq(seriesBooks.seriesId, seriesId))
    .groupBy(seriesBooks.seriesId, seriesBooks.bookId, books.bookId)
    .orderBy(seriesBooks.position);
}

// ============================================================================
// ANALYTICS QUERIES
// ============================================================================

/**
 * Get top rated books
 */
export async function getTopRatedBooks(limit: number = 10) {
  return await db
    .select({
      log: readingLog,
      book: books,
      authors: sql<string>`string_agg(DISTINCT ${authors.name}, ', ')`,
    })
    .from(readingLog)
    .innerJoin(books, eq(readingLog.bookId, books.bookId))
    .leftJoin(bookAuthors, eq(books.bookId, bookAuthors.bookId))
    .leftJoin(authors, eq(bookAuthors.authorId, authors.authorId))
    .where(and(eq(readingLog.status, "finished"), sql`${readingLog.rating} IS NOT NULL`))
    .groupBy(readingLog.logId, books.bookId)
    .orderBy(desc(readingLog.rating), desc(readingLog.dateFinished))
    .limit(limit);
}

/**
 * Get reading activity by month for current year
 */
export async function getReadingActivityThisYear() {
  const currentYear = new Date().getFullYear();

  return await db
    .select()
    .from(monthlyStats)
    .where(eq(monthlyStats.year, currentYear))
    .orderBy(monthlyStats.month);
}

/**
 * Search books by title or author
 */
export async function searchBooks(query: string) {
  return await db
    .select({
      book: books,
      authors: sql<string>`string_agg(DISTINCT ${authors.name}, ', ')`,
    })
    .from(books)
    .leftJoin(bookAuthors, eq(books.bookId, bookAuthors.bookId))
    .leftJoin(authors, eq(bookAuthors.authorId, authors.authorId))
    .where(
      sql`${books.title} ILIKE ${"%" + query + "%"} OR ${authors.name} ILIKE ${"%" + query + "%"}`
    )
    .groupBy(books.bookId)
    .limit(50);
}

// ============================================================================
// READING SESSIONS
// ============================================================================

/**
 * Get all reading sessions with book details
 */
export async function getReadingSessions(limit: number = 50) {
  return await db
    .select({
      session: readingSessions,
      book: books,
      authors: sql<string>`string_agg(DISTINCT ${authors.name}, ', ')`,
    })
    .from(readingSessions)
    .innerJoin(books, eq(readingSessions.bookId, books.bookId))
    .leftJoin(bookAuthors, eq(books.bookId, bookAuthors.bookId))
    .leftJoin(authors, eq(bookAuthors.authorId, authors.authorId))
    .groupBy(readingSessions.sessionId, books.bookId)
    .orderBy(desc(readingSessions.sessionDate), desc(readingSessions.createdAt))
    .limit(limit);
}

/**
 * Get reading sessions for a specific book
 */
export async function getBookReadingSessions(bookId: number) {
  return await db
    .select()
    .from(readingSessions)
    .where(eq(readingSessions.bookId, bookId))
    .orderBy(desc(readingSessions.sessionDate));
}

/**
 * Create a new reading session
 */
export async function createReadingSession(data: {
  bookId: number;
  sessionDate: Date;
  pagesRead?: number;
  minutesRead?: number;
  startPage?: number;
  endPage?: number;
  notes?: string;
}) {
  return await db.insert(readingSessions).values({
    ...data,
    // Convert Date object to "YYYY-MM-DD" string
    sessionDate: data.sessionDate.toISOString().split('T')[0],
  }).returning();
}

/**
 * Update a reading session
 */
export async function updateReadingSession(
  sessionId: number,
  data: {
    sessionDate?: Date;
    pagesRead?: number;
    minutesRead?: number;
    startPage?: number;
    endPage?: number;
    notes?: string;
  }
) {
  return await db
    .update(readingSessions)
    .set({
      ...data,
      // Convert Date object to "YYYY-MM-DD" string
      sessionDate: data.sessionDate?.toISOString().split('T')[0],
    })
    .where(eq(readingSessions.sessionId, sessionId))
    .returning();
}

/**
 * Delete a reading session
 */
export async function deleteReadingSession(sessionId: number) {
  return await db
    .delete(readingSessions)
    .where(eq(readingSessions.sessionId, sessionId))
    .returning();
}

// ============================================================================
// AUTHORS & GENRES STATISTICS
// ============================================================================

/**
 * Get all authors with statistics
 */
export async function getAuthorsWithStats() {
  return await db
    .select({
      author: authors,
      totalBooks: sql<number>`COUNT(DISTINCT ${books.bookId})::int`,
      totalPages: sql<number>`COALESCE(SUM(${books.pages}), 0)::int`,
      booksRead: sql<number>`COUNT(DISTINCT CASE WHEN ${readingLog.status} = 'finished' THEN ${books.bookId} END)::int`,
      averageRating: sql<number>`ROUND(AVG(${readingLog.rating})::numeric, 1)`,
    })
    .from(authors)
    .leftJoin(bookAuthors, eq(authors.authorId, bookAuthors.authorId))
    .leftJoin(books, eq(bookAuthors.bookId, books.bookId))
    .leftJoin(readingLog, eq(books.bookId, readingLog.bookId))
    .groupBy(authors.authorId)
    .orderBy(desc(sql`COUNT(DISTINCT ${books.bookId})`));
}

/**
 * Get all genres with statistics
 */
export async function getGenresWithStats() {
  return await db
    .select({
      genre: genres,
      totalBooks: sql<number>`COUNT(DISTINCT ${books.bookId})::int`,
      totalPages: sql<number>`COALESCE(SUM(${books.pages}), 0)::int`,
      booksRead: sql<number>`COUNT(DISTINCT CASE WHEN ${readingLog.status} = 'finished' THEN ${books.bookId} END)::int`,
      averageRating: sql<number>`ROUND(AVG(${readingLog.rating})::numeric, 1)`,
    })
    .from(genres)
    .leftJoin(bookGenres, eq(genres.genreId, bookGenres.genreId))
    .leftJoin(books, eq(bookGenres.bookId, books.bookId))
    .leftJoin(readingLog, eq(books.bookId, readingLog.bookId))
    .groupBy(genres.genreId)
    .orderBy(desc(sql`COUNT(DISTINCT ${books.bookId})`));
}

/**
 * Get reading history data for charts
 * Returns daily data of books finished and pages read
 */
export async function getReadingHistory(months: number = 12) {
  const startDate = new Date();
  startDate.setMonth(startDate.getMonth() - months);
  startDate.setHours(0, 0, 0, 0);

  return await db
    .select({
      period: sql<string>`DATE(${readingLog.dateFinished})`,
      booksRead: sql<number>`COUNT(DISTINCT ${readingLog.logId})::int`,
      pagesRead: sql<number>`COALESCE(SUM(${books.pages}), 0)::int`,
    })
    .from(readingLog)
    .leftJoin(books, eq(readingLog.bookId, books.bookId))
    .where(
      and(
        eq(readingLog.status, "finished"),
        sql`${readingLog.dateFinished} >= ${startDate.toISOString()}`
      )
    )
    .groupBy(sql`DATE(${readingLog.dateFinished})`)
    .orderBy(sql`DATE(${readingLog.dateFinished})`);
}
