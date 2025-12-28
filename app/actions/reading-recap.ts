"use server";

import { db } from "@/lib/db";
import { books, readingLog, bookGenres, genres, bookAuthors, authors } from "@/lib/db/schema";
import { eq, and, sql, desc } from "drizzle-orm";

export interface MonthlyRecapData {
  month: string;
  year: number;
  booksFinished: number;
  pagesRead: number;
  topGenre: string | null;
  topRatedBook: {
    title: string;
    rating: number;
    authors: string;
  } | null;
  fastestBook: {
    title: string;
    days: number;
  } | null;
  totalReadingDays: number;
  favoriteAuthor: string | null;
}

export async function getMonthlyRecapAction(year: number, month: number): Promise<MonthlyRecapData> {
  try {
    // Get books finished this month
    const finishedBooks = await db
      .select({
        book: books,
        log: readingLog,
        authors: sql<string>`string_agg(DISTINCT ${authors.name}, ', ')`,
      })
      .from(readingLog)
      .innerJoin(books, eq(readingLog.bookId, books.bookId))
      .leftJoin(bookAuthors, eq(books.bookId, bookAuthors.bookId))
      .leftJoin(authors, eq(bookAuthors.authorId, authors.authorId))
      .where(
        and(
          eq(readingLog.status, "finished"),
          sql`EXTRACT(YEAR FROM ${readingLog.dateFinished}) = ${year}`,
          sql`EXTRACT(MONTH FROM ${readingLog.dateFinished}) = ${month}`
        )
      )
      .groupBy(readingLog.logId, books.bookId)
      .orderBy(desc(readingLog.dateFinished));

    const booksFinished = finishedBooks.length;
    const pagesRead = finishedBooks.reduce((sum, item) => sum + (item.book.pages || 0), 0);

    // Get top genre this month
    const topGenreResult = await db
      .select({
        genreName: genres.genreName,
        count: sql<number>`COUNT(DISTINCT ${books.bookId})::int`,
      })
      .from(readingLog)
      .innerJoin(books, eq(readingLog.bookId, books.bookId))
      .innerJoin(bookGenres, eq(books.bookId, bookGenres.bookId))
      .innerJoin(genres, eq(bookGenres.genreId, genres.genreId))
      .where(
        and(
          eq(readingLog.status, "finished"),
          sql`EXTRACT(YEAR FROM ${readingLog.dateFinished}) = ${year}`,
          sql`EXTRACT(MONTH FROM ${readingLog.dateFinished}) = ${month}`
        )
      )
      .groupBy(genres.genreId, genres.genreName)
      .orderBy(desc(sql`COUNT(DISTINCT ${books.bookId})`))
      .limit(1);

    const topGenre = topGenreResult[0]?.genreName || null;

    // Get top rated book this month
    const topRatedResult = finishedBooks
      .filter((item) => item.log.rating !== null)
      .sort((a, b) => (b.log.rating || 0) - (a.log.rating || 0))
      .slice(0, 1);

    const topRatedBook = topRatedResult[0]
      ? {
          title: topRatedResult[0].book.title,
          rating: topRatedResult[0].log.rating!,
          authors: topRatedResult[0].authors || "Unknown",
        }
      : null;

    // Get fastest book read (shortest reading days)
    const fastestResult = finishedBooks
      .filter((item) => item.log.readingDays !== null && item.log.readingDays > 0)
      .sort((a, b) => (a.log.readingDays || 999) - (b.log.readingDays || 999))
      .slice(0, 1);

    const fastestBook = fastestResult[0]
      ? {
          title: fastestResult[0].book.title,
          days: fastestResult[0].log.readingDays!,
        }
      : null;

    // Get total reading days this month
    const totalReadingDays = finishedBooks.reduce(
      (sum, item) => sum + (item.log.readingDays || 0),
      0
    );

    // Get favorite author (most books read from)
    const favoriteAuthorResult = await db
      .select({
        authorName: authors.name,
        count: sql<number>`COUNT(DISTINCT ${books.bookId})::int`,
      })
      .from(readingLog)
      .innerJoin(books, eq(readingLog.bookId, books.bookId))
      .innerJoin(bookAuthors, eq(books.bookId, bookAuthors.bookId))
      .innerJoin(authors, eq(bookAuthors.authorId, authors.authorId))
      .where(
        and(
          eq(readingLog.status, "finished"),
          sql`EXTRACT(YEAR FROM ${readingLog.dateFinished}) = ${year}`,
          sql`EXTRACT(MONTH FROM ${readingLog.dateFinished}) = ${month}`
        )
      )
      .groupBy(authors.authorId, authors.name)
      .orderBy(desc(sql`COUNT(DISTINCT ${books.bookId})`))
      .limit(1);

    const favoriteAuthor = favoriteAuthorResult[0]?.authorName || null;

    // Get month name
    const monthNames = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    const monthName = monthNames[month - 1];

    return {
      month: monthName,
      year,
      booksFinished,
      pagesRead,
      topGenre,
      topRatedBook,
      fastestBook,
      totalReadingDays,
      favoriteAuthor,
    };
  } catch (error) {
    console.error("Error fetching monthly recap:", error);
    return {
      month: "",
      year,
      booksFinished: 0,
      pagesRead: 0,
      topGenre: null,
      topRatedBook: null,
      fastestBook: null,
      totalReadingDays: 0,
      favoriteAuthor: null,
    };
  }
}
