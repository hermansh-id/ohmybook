import { createServerFn } from "@tanstack/react-start";
import { getAllBooksWithDetails, getBookById } from "@/lib/db/queries";
import { db } from "@/lib/db";
import { books, authors } from "@/lib/db/schema";
import { eq } from "drizzle-orm";
import {
  addBook,
  lookupIsbn,
  lookupQrcbn,
  lookupGoodreadsUrl,
  getReadingRecommendations,
  refreshGoodreadsData,
} from "@/lib/server/books";
import type { AddBookInput, BookLookupResult, RecommendationOptionsInput } from "@/lib/server/books";

export type { AddBookInput, BookLookupResult };

export const getBooksAction = createServerFn({ method: "GET" })
  .handler(async () => {
    try {
      const allBooks = await getAllBooksWithDetails();

      // Group by book and aggregate authors/genres
      const bookMap = new Map();

      allBooks.forEach((row) => {
        const bookId = row.book.bookId;

        if (!bookMap.has(bookId)) {
          bookMap.set(bookId, {
            id: bookId,
            title: row.book.title,
            isbn: row.book.isbn,
            year: row.book.year,
            pages: row.book.pages,
            addedAt: row.book.addedAt,
            authors: [],
            genres: [],
            status: row.readingStatus?.status || "not_started",
            rating: row.readingStatus?.rating || null,
            dateFinished: row.readingStatus?.dateFinished || null,
            currentPage: row.readingStatus?.currentPage || 0,
            coverUrl: row.goodreads?.coverUrl || null,
            averageRating: row.goodreads?.averageRating || null,
          });
        }

        const book = bookMap.get(bookId);

        if (row.author && !book.authors.some((a: any) => a.name === row.author?.name)) {
          book.authors.push({
            id: row.author.authorId,
            name: row.author.name,
          });
        }

        if (row.genre && !book.genres.some((g: any) => g.name === row.genre?.genreName)) {
          book.genres.push({
            id: row.genre.genreId,
            name: row.genre.genreName,
          });
        }
      });

      return Array.from(bookMap.values());
    } catch (error) {
      console.error("Error fetching books:", error);
      throw new Error("Failed to fetch books");
    }
  });

export const getBookDetailsAction = createServerFn({ method: "POST" })
  .validator((d: { bookId: number }) => d)
  .handler(async ({ data }) => {
    try {
      const result = await getBookById(data.bookId);

      if (!result || result.length === 0) {
        throw new Error("Book not found");
      }

      const bookData = result[0];

      return {
        id: bookData.books.bookId,
        title: bookData.books.title,
        isbn: bookData.books.isbn,
        year: bookData.books.year,
        pages: bookData.books.pages,
        addedAt: bookData.books.addedAt,
        goodreadsUrl: bookData.books.goodreadsUrl,
        status: bookData.reading_log?.status || "not_started",
        rating: bookData.reading_log?.rating || null,
        review: bookData.reading_log?.review || null,
        notes: bookData.reading_log?.notes || null,
        dateAdded: bookData.reading_log?.dateAdded || null,
        dateStarted: bookData.reading_log?.dateStarted || null,
        dateFinished: bookData.reading_log?.dateFinished || null,
        currentPage: bookData.reading_log?.currentPage || 0,
        readingDays: bookData.reading_log?.readingDays || null,
        tags: bookData.reading_log?.tags || [],
        coverUrl: bookData.goodreads_data?.coverUrl || null,
        description: bookData.goodreads_data?.description || null,
        averageRating: bookData.goodreads_data?.averageRating || null,
        ratingsCount: bookData.goodreads_data?.ratingsCount || null,
        publisher: bookData.goodreads_data?.publisher || null,
        publicationDate: bookData.goodreads_data?.publicationDate || null,
        logId: bookData.reading_log?.logId || null,
      };
    } catch (error) {
      console.error("Error fetching book details:", error);
      throw new Error("Failed to fetch book details");
    }
  });

export const updateBookStatusAction = createServerFn({ method: "POST" })
  .validator(
    (d: {
      bookId: number;
      logId?: number | null;
      status: string;
      rating?: number | null;
      dateFinished?: Date | null;
    }) => d
  )
  .handler(async ({ data }) => {
    try {
      const { addToReadingLog, updateReadingStatus, markBookAsFinished } = await import(
        "@/lib/db/queries"
      );

      // If no logId, create new reading log entry
      if (!data.logId) {
        const result = await addToReadingLog(data.bookId, data.status as any);
        return result[0];
      }

      // If marking as finished, use special function
      if (data.status === "finished") {
        return await markBookAsFinished(data.logId, data.rating ?? undefined);
      }

      // Otherwise, update the reading status
      return await updateReadingStatus(data.logId, {
        status: data.status,
        rating: data.rating ?? undefined,
        dateFinished: data.dateFinished ?? undefined,
      });
    } catch (error) {
      console.error("Error updating book status:", error);
      throw new Error("Failed to update book status");
    }
  });

export const addBookAction = createServerFn({ method: "POST" })
  .validator((d: AddBookInput) => d)
  .handler(({ data }) => addBook(data));

export const deleteBookAction = createServerFn({ method: "POST" })
  .validator((d: { bookId: number }) => d)
  .handler(async ({ data }) => {
    try {
      // Delete the book (cascade will handle related records)
      await db.delete(books).where(eq(books.bookId, data.bookId));

      return { success: true };
    } catch (error) {
      console.error("Error deleting book:", error);
      return { success: false, error: "Failed to delete book" };
    }
  });

export interface UpdateBookInput {
  bookId: number;
  title?: string;
  isbn?: string;
  year?: number;
  pages?: number;
  goodreadsUrl?: string;
}

export const updateBookAction = createServerFn({ method: "POST" })
  .validator((d: UpdateBookInput) => d)
  .handler(async ({ data }) => {
    try {
      const { bookId, ...updateData } = data;

      // Build update object with only provided fields
      const dataToUpdate: any = {};
      if (updateData.title !== undefined) dataToUpdate.title = updateData.title;
      if (updateData.isbn !== undefined) dataToUpdate.isbn = updateData.isbn || null;
      if (updateData.year !== undefined) dataToUpdate.year = updateData.year || null;
      if (updateData.pages !== undefined) dataToUpdate.pages = updateData.pages || null;
      if (updateData.goodreadsUrl !== undefined) dataToUpdate.goodreadsUrl = updateData.goodreadsUrl || null;

      await db
        .update(books)
        .set(dataToUpdate)
        .where(eq(books.bookId, bookId));

      return { success: true };
    } catch (error) {
      console.error("Error updating book:", error);
      return { success: false, error: "Failed to update book" };
    }
  });

export const getAllBooksAction = createServerFn({ method: "GET" })
  .handler(async () => {
    try {
      const allBooks = await db
        .select({
          bookId: books.bookId,
          title: books.title,
        })
        .from(books)
        .orderBy(books.title);

      return allBooks;
    } catch (error) {
      console.error("Error fetching books:", error);
      return [];
    }
  });

export const getAuthorsAction = createServerFn({ method: "GET" })
  .handler(async () => {
    try {
      const allAuthors = await db
        .select({
          authorId: authors.authorId,
          name: authors.name,
        })
        .from(authors)
        .orderBy(authors.name);

      return allAuthors;
    } catch (error) {
      console.error("Error fetching authors:", error);
      return [];
    }
  });

export const lookupBookByISBN = createServerFn({ method: "POST" })
  .validator((d: { isbn: string }) => d)
  .handler(({ data }) => lookupIsbn(data.isbn));

export const lookupBookByQRCBN = createServerFn({ method: "POST" })
  .validator((d: { code: string }) => d)
  .handler(({ data }) => lookupQrcbn(data.code));

export const getReadingRecommendationsAction = createServerFn({ method: "GET" })
  .validator((d: RecommendationOptionsInput | undefined) => d ?? {})
  .handler(({ data }) => getReadingRecommendations(data));

export const lookupBookByGoodreadsUrl = createServerFn({ method: "POST" })
  .validator((d: { url: string }) => d)
  .handler(({ data }) => lookupGoodreadsUrl(data.url));

export const fetchGoodreadsDataAction = createServerFn({ method: "POST" })
  .validator((d: { bookId: number; isbn: string }) => d)
  .handler(({ data }) => refreshGoodreadsData(data.bookId, { isbn: data.isbn }));
