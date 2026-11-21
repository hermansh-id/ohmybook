import { eq } from "drizzle-orm";
import { books, readingLog } from "./schema";
import { BookInputError } from "./book-writes";

export const READING_STATUSES = [
  "want_to_read",
  "reading",
  "finished",
  "did_not_finish",
  "on_hold",
] as const;
export type ReadingStatus = (typeof READING_STATUSES)[number];

export interface UpdateBookReadingInput {
  bookId: number;
  status?: ReadingStatus;
  /** 1-5 */
  rating?: number;
  review?: string;
  currentPage?: number;
  /** YYYY-MM-DD */
  dateStarted?: string;
  /** YYYY-MM-DD */
  dateFinished?: string;
}

const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;
const today = () => new Date().toISOString().slice(0, 10);

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyDb = any;

/**
 * Create or update the reading_log row (one per book) for a book.
 * Only the provided fields are changed. Dates default sensibly:
 * status "finished" sets dateFinished (today) and "reading" sets dateStarted
 * (today) when they are still empty.
 */
export async function updateBookReading(database: AnyDb, input: UpdateBookReadingInput) {
  const { bookId, status, rating, review, currentPage, dateStarted, dateFinished } = input;

  if (!Number.isInteger(bookId)) throw new BookInputError("bookId must be an integer");
  if (status !== undefined && !READING_STATUSES.includes(status)) {
    throw new BookInputError(`Invalid status "${status}". Use one of: ${READING_STATUSES.join(", ")}`);
  }
  if (rating !== undefined && (!Number.isInteger(rating) || rating < 1 || rating > 5)) {
    throw new BookInputError("rating must be an integer from 1 to 5");
  }
  if (currentPage !== undefined && (!Number.isInteger(currentPage) || currentPage < 0)) {
    throw new BookInputError("currentPage must be a non-negative integer");
  }
  for (const [k, v] of [["dateStarted", dateStarted], ["dateFinished", dateFinished]] as const) {
    if (v !== undefined && !DATE_RE.test(v)) throw new BookInputError(`${k} must be YYYY-MM-DD`);
  }
  if ([status, rating, review, currentPage, dateStarted, dateFinished].every((v) => v === undefined)) {
    throw new BookInputError("Nothing to update: provide status, rating, review, currentPage or dates");
  }

  const [book] = await database
    .select({ bookId: books.bookId, title: books.title })
    .from(books)
    .where(eq(books.bookId, bookId))
    .limit(1);
  if (!book) throw new BookInputError(`Book ${bookId} not found`);

  const [existing] = await database.select().from(readingLog).where(eq(readingLog.bookId, bookId)).limit(1);

  const changes: Partial<typeof readingLog.$inferInsert> = {};
  if (status !== undefined) changes.status = status;
  if (rating !== undefined) changes.rating = rating;
  if (review !== undefined) changes.review = review;
  if (currentPage !== undefined) changes.currentPage = currentPage;
  if (dateStarted !== undefined) changes.dateStarted = dateStarted;
  if (dateFinished !== undefined) changes.dateFinished = dateFinished;

  if (status === "finished" && changes.dateFinished === undefined && !existing?.dateFinished) {
    changes.dateFinished = today();
  }
  if (status === "reading" && changes.dateStarted === undefined && !existing?.dateStarted) {
    changes.dateStarted = today();
  }

  const [log] = await database
    .insert(readingLog)
    .values({ bookId, ...changes })
    .onConflictDoUpdate({ target: readingLog.bookId, set: { ...changes, updatedAt: new Date() } })
    .returning();

  return { ...log, title: book.title };
}
