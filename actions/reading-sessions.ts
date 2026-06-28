import { createServerFn } from "@tanstack/react-start";
import {
  getReadingSessions,
  getBookReadingSessions,
  createReadingSession,
  updateReadingSession,
  deleteReadingSession,
} from "@/lib/db/queries";
import { db } from "@/lib/db";
import { books, readingLog } from "@/lib/db/schema";
import { eq, or, isNull } from "drizzle-orm";

export const getReadingSessionsAction = createServerFn({ method: "POST" })
  .validator((d: { limit?: number }) => d)
  .handler(async ({ data }) => {
    try {
      const sessions = await getReadingSessions(data.limit ?? 50);
      return { success: true, data: sessions };
    } catch (error) {
      console.error("Error fetching reading sessions:", error);
      return { success: false, error: "Failed to fetch reading sessions" };
    }
  });

export const getBookReadingSessionsAction = createServerFn({ method: "POST" })
  .validator((d: { bookId: number }) => d)
  .handler(async ({ data }) => {
    try {
      const sessions = await getBookReadingSessions(data.bookId);
      return { success: true, data: sessions };
    } catch (error) {
      console.error("Error fetching book reading sessions:", error);
      return { success: false, error: "Failed to fetch book reading sessions" };
    }
  });

export const createReadingSessionAction = createServerFn({ method: "POST" })
  .validator(
    (d: {
      bookId: number;
      sessionDate: string;
      pagesRead?: number;
      minutesRead?: number;
      startPage?: number;
      endPage?: number;
      notes?: string;
    }) => d
  )
  .handler(async ({ data }) => {
    try {
      // Create the reading session
      const session = await createReadingSession({
        ...data,
        sessionDate: new Date(data.sessionDate),
      });

      // Get the book to check total pages and goodreads URL
      const [book] = await db
        .select({
          pages: books.pages,
          title: books.title,
          goodreadsUrl: books.goodreadsUrl,
        })
        .from(books)
        .where(eq(books.bookId, data.bookId))
        .limit(1);

      if (!book) {
        return { success: false, error: "Book not found" };
      }

      // Get or create reading_log entry
      let [log] = await db
        .select()
        .from(readingLog)
        .where(eq(readingLog.bookId, data.bookId))
        .limit(1);

      const pagesRead = data.pagesRead || 0;
      const currentPage = (log?.currentPage || 0) + pagesRead;
      const totalPages = book.pages || 0;
      const isCompleted = totalPages > 0 && currentPage >= totalPages;

      if (!log) {
        // Create new reading_log entry
        const newLogData: any = {
          bookId: data.bookId,
          currentPage: isCompleted ? totalPages : currentPage,
          status: isCompleted ? "finished" : "reading",
          dateStarted: new Date(data.sessionDate),
        };

        if (isCompleted) {
          newLogData.dateFinished = new Date(data.sessionDate);
        }

        [log] = await db
          .insert(readingLog)
          .values(newLogData)
          .returning();
      } else {
        // Update existing reading_log entry
        const updateData: any = {
          currentPage: isCompleted ? totalPages : currentPage,
          status: isCompleted ? "finished" : log.status === "want_to_read" ? "reading" : log.status,
          dateStarted: log.dateStarted || new Date(data.sessionDate),
          updatedAt: new Date(),
        };

        if (isCompleted) {
          updateData.dateFinished = new Date(data.sessionDate);
        }

        [log] = await db
          .update(readingLog)
          .set(updateData)
          .where(eq(readingLog.bookId, data.bookId))
          .returning();
      }

      return {
        success: true,
        data: session[0],
        bookCompleted: isCompleted,
        bookTitle: book.title,
        goodreadsUrl: book.goodreadsUrl || null,
      };
    } catch (error) {
      console.error("Error creating reading session:", error);
      return { success: false, error: "Failed to create reading session" };
    }
  });

export const updateReadingSessionAction = createServerFn({ method: "POST" })
  .validator(
    (d: {
      sessionId: number;
      sessionDate?: string;
      pagesRead?: number;
      minutesRead?: number;
      startPage?: number;
      endPage?: number;
      notes?: string;
    }) => d
  )
  .handler(async ({ data }) => {
    try {
      const { sessionId, ...rest } = data;
      const updateData = {
        ...rest,
        sessionDate: rest.sessionDate ? new Date(rest.sessionDate) : undefined,
      };

      const session = await updateReadingSession(sessionId, updateData);

      return { success: true, data: session[0] };
    } catch (error) {
      console.error("Error updating reading session:", error);
      return { success: false, error: "Failed to update reading session" };
    }
  });

export const deleteReadingSessionAction = createServerFn({ method: "POST" })
  .validator((d: { sessionId: number }) => d)
  .handler(async ({ data }) => {
    try {
      await deleteReadingSession(data.sessionId);
      return { success: true };
    } catch (error) {
      console.error("Error deleting reading session:", error);
      return { success: false, error: "Failed to delete reading session" };
    }
  });

export const getUnfinishedBooksAction = createServerFn({ method: "GET" })
  .handler(async () => {
    try {
      // Get all books with their reading status
      const booksWithStatus = await db
        .select({
          bookId: books.bookId,
          title: books.title,
          pages: books.pages,
          status: readingLog.status,
          currentPage: readingLog.currentPage,
        })
        .from(books)
        .leftJoin(readingLog, eq(books.bookId, readingLog.bookId))
        .where(
          or(
            eq(readingLog.status, "reading"),
            eq(readingLog.status, "want_to_read"),
            isNull(readingLog.status) // Books without reading log entry
          )
        );

      return booksWithStatus.map((book) => ({
        id: book.bookId,
        title: book.title,
        pages: book.pages || 0,
        currentPage: book.currentPage || 0,
        status: book.status || "want_to_read",
      }));
    } catch (error) {
      console.error("Error fetching unfinished books:", error);
      return [];
    }
  });
