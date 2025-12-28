"use server";

import { db } from "@/lib/db";
import { books, authors, bookAuthors, readingLog } from "@/lib/db/schema";
import { or, ilike, eq, sql } from "drizzle-orm";

export async function searchBooksAction(query: string) {
  try {
    if (!query || query.trim().length < 2) {
      return [];
    }

    const searchPattern = `%${query}%`;

    // Search books by title, author, or ISBN
    const results = await db
      .select({
        bookId: books.bookId,
        title: books.title,
        isbn: books.isbn,
        pages: books.pages,
        year: books.year,
        authorName: sql<string>`string_agg(DISTINCT ${authors.name}, ', ')`,
        status: readingLog.status,
      })
      .from(books)
      .leftJoin(bookAuthors, eq(books.bookId, bookAuthors.bookId))
      .leftJoin(authors, eq(bookAuthors.authorId, authors.authorId))
      .leftJoin(readingLog, eq(books.bookId, readingLog.bookId))
      .where(
        or(
          ilike(books.title, searchPattern),
          ilike(books.isbn, searchPattern),
          ilike(authors.name, searchPattern)
        )
      )
      .groupBy(books.bookId, readingLog.status)
      .limit(10);

    return results;
  } catch (error) {
    console.error("Error searching books:", error);
    return [];
  }
}
