import { eq, sql } from "drizzle-orm";
import { authors, books, genres, goodreadsData } from "./schema";
import { BookInputError, normalizeAuthorName } from "./book-writes";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyDb = any;

/** Find an author by name (case-insensitive) or create it. */
export async function addAuthor(database: AnyDb, input: { name: string; bio?: string }) {
  const name = normalizeAuthorName(input.name ?? "");
  if (!name) throw new BookInputError("Author name is required");
  if (name.length > 255) throw new BookInputError("Author name too long (max 255)");

  const find = async () =>
    (await database.select().from(authors).where(sql`lower(${authors.name}) = ${name.toLowerCase()}`).limit(1))[0];

  const existing = await find();
  if (existing) return { created: false, author: existing };

  await database.insert(authors).values({ name, bio: input.bio || null }).onConflictDoNothing();
  const author = await find(); // also covers a concurrent insert of the same name
  return { created: true, author };
}

/** Find a genre by name (case-insensitive) or create it. */
export async function addGenre(database: AnyDb, input: { name: string; description?: string }) {
  const name = normalizeAuthorName(input.name ?? "");
  if (!name) throw new BookInputError("Genre name is required");
  if (name.length > 100) throw new BookInputError("Genre name too long (max 100)");

  const find = async () =>
    (await database.select().from(genres).where(sql`lower(${genres.genreName}) = ${name.toLowerCase()}`).limit(1))[0];

  const existing = await find();
  if (existing) return { created: false, genre: existing };

  await database.insert(genres).values({ genreName: name, description: input.description || null }).onConflictDoNothing();
  const genre = await find();
  return { created: true, genre };
}

export interface UpdateBookDetailsInput {
  bookId: number;
  title?: string;
  isbn?: string;
  year?: number;
  pages?: number;
  goodreadsUrl?: string;
  coverUrl?: string;
  description?: string;
  publisher?: string;
}

/**
 * Edit book metadata. Only provided fields change; an empty string clears
 * isbn/goodreadsUrl/coverUrl/description/publisher. Cover, description and
 * publisher live in goodreads_data.
 */
export async function updateBookDetails(database: AnyDb, input: UpdateBookDetailsInput) {
  const { bookId, ...f } = input;
  if (!Number.isInteger(bookId)) throw new BookInputError("bookId must be an integer");
  if (Object.values(f).every((v) => v === undefined)) throw new BookInputError("Nothing to update");
  if (f.title !== undefined && !f.title.trim()) throw new BookInputError("Title cannot be empty");
  if (f.year !== undefined && !Number.isInteger(f.year)) throw new BookInputError("year must be an integer");
  if (f.pages !== undefined && (!Number.isInteger(f.pages) || f.pages < 0)) throw new BookInputError("pages must be a non-negative integer");

  const [book] = await database.select().from(books).where(eq(books.bookId, bookId)).limit(1);
  if (!book) throw new BookInputError(`Book ${bookId} not found`);

  const bookSet: Partial<typeof books.$inferInsert> = {};
  if (f.title !== undefined) bookSet.title = f.title.trim();
  if (f.isbn !== undefined) bookSet.isbn = f.isbn.replace(/[-\s]/g, "") || null;
  if (f.year !== undefined) bookSet.year = f.year || null;
  if (f.pages !== undefined) bookSet.pages = f.pages || null;
  if (f.goodreadsUrl !== undefined) bookSet.goodreadsUrl = f.goodreadsUrl || null;

  const grSet: Partial<typeof goodreadsData.$inferInsert> = {};
  if (f.coverUrl !== undefined) grSet.coverUrl = f.coverUrl || null;
  if (f.description !== undefined) grSet.description = f.description || null;
  if (f.publisher !== undefined) grSet.publisher = f.publisher || null;

  if (Object.keys(bookSet).length > 0) {
    await database.update(books).set(bookSet).where(eq(books.bookId, bookId));
  }
  if (Object.keys(grSet).length > 0) {
    await database
      .insert(goodreadsData)
      .values({ bookId, ...grSet })
      .onConflictDoUpdate({ target: goodreadsData.bookId, set: { ...grSet, lastUpdated: new Date() } });
  }

  const [updated] = await database.select().from(books).where(eq(books.bookId, bookId)).limit(1);
  const [gr] = await database.select().from(goodreadsData).where(eq(goodreadsData.bookId, bookId)).limit(1);
  return { ...updated, coverUrl: gr?.coverUrl ?? null, description: gr?.description ?? null, publisher: gr?.publisher ?? null };
}

/** Delete a book (cascades to its log, sessions, quotes, links). */
export async function deleteBook(database: AnyDb, bookId: number) {
  if (!Number.isInteger(bookId)) throw new BookInputError("bookId must be an integer");
  const [deleted] = await database.delete(books).where(eq(books.bookId, bookId)).returning({ bookId: books.bookId, title: books.title });
  if (!deleted) throw new BookInputError(`Book ${bookId} not found`);
  return deleted as { bookId: number; title: string };
}
