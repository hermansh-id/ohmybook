import { asc, eq, inArray, sql } from "drizzle-orm";
import { authors, bookAuthors, bookGenres, books, genres } from "./schema";

/**
 * Atomic book writes: create a book (resolving/creating authors and genres by
 * name) or attach authors/genres to an existing book.
 *
 * The database parameter is injected so the exact same code runs against
 * neon-http in production (via `db.batch`, which is one transaction) and
 * against any driver with `.transaction` (PGlite in tests).
 */

export class BookInputError extends Error {}

export interface CreateBookInput {
  title: string;
  isbn?: string | null;
  goodreadsUrl?: string | null;
  year?: number | null;
  pages?: number | null;
  /** Existing author IDs. */
  authorIds?: number[];
  /** Author names; matched case-insensitively, created if missing. */
  authors?: string[];
  /** Existing genre IDs. */
  genreIds?: number[];
  /** Genre names; matched case-insensitively, created if missing. */
  genres?: string[];
  coverUrl?: string | null;
  description?: string | null;
  publisher?: string | null;
}

/** Trim and collapse internal whitespace. */
export function normalizeAuthorName(name: string) {
  return name.trim().replace(/\s+/g, " ");
}

/** Case-insensitive comparison key. */
export function authorKey(name: string) {
  return normalizeAuthorName(name).toLowerCase();
}

type Item = { ord: number; id: number | null; key: string | null };

function planNamed(rawIds: number[] | undefined, rawNames: string[] | undefined, label: string, maxLen: number) {
  const ids = [...new Set(rawIds ?? [])];
  for (const id of ids) {
    if (!Number.isInteger(id)) throw new BookInputError(`Invalid ${label} id: ${id}`);
  }

  const names: { name: string; key: string }[] = [];
  const seen = new Set<string>();
  for (const raw of rawNames ?? []) {
    const name = normalizeAuthorName(raw);
    if (!name) continue;
    if (name.length > maxLen) throw new BookInputError(`${label} name too long: "${name.slice(0, 40)}…"`);
    const key = name.toLowerCase();
    if (seen.has(key)) continue; // first spelling wins
    seen.add(key);
    names.push({ name, key });
  }

  // Order: explicit IDs first, then names, in the order given.
  const items: Item[] = [
    ...ids.map((id, i) => ({ ord: i + 1, id: id as number | null, key: null as string | null })),
    ...names.map((n, i) => ({ ord: ids.length + i + 1, id: null as number | null, key: n.key })),
  ];
  return { ids, names, items };
}

export function planAuthors(input: Pick<CreateBookInput, "authorIds" | "authors">) {
  return planNamed(input.authorIds, input.authors, "Author", 255);
}

export function planGenres(input: Pick<CreateBookInput, "genreIds" | "genres">) {
  return planNamed(input.genreIds, input.genres, "Genre", 100);
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyDb = any;

const BOOK_SEQ = sql`currval(pg_get_serial_sequence('books', 'book_id')::regclass)`;
const valuesList = (rows: ReturnType<typeof sql>[]) => sql.join(rows, sql`, `);

async function assertIdsExist(
  database: AnyDb,
  ids: number[],
  table: typeof authors | typeof genres,
  col: typeof authors.authorId | typeof genres.genreId,
  label: string,
) {
  if (ids.length === 0) return;
  const found = await database.select({ id: col }).from(table).where(inArray(col, ids));
  const foundIds = new Set<number>(found.map((r: { id: number }) => r.id));
  const missing = ids.filter((id) => !foundIds.has(id));
  if (missing.length > 0) throw new BookInputError(`${label} id(s) not found: ${missing.join(", ")}`);
}

// ---- statement builders (all run inside one transaction) -------------------

function insertMissingAuthors(d: AnyDb, names: { name: string; key: string }[]) {
  return d.execute(sql`
    INSERT INTO authors (name)
    SELECT v.name
    FROM (VALUES ${valuesList(names.map((n) => sql`(${n.name}::text, ${n.key}::text)`))}) AS v(name, key)
    WHERE NOT EXISTS (SELECT 1 FROM authors a WHERE lower(a.name) = v.key)
    ON CONFLICT DO NOTHING`);
}

function insertMissingGenres(d: AnyDb, names: { name: string; key: string }[]) {
  return d.execute(sql`
    INSERT INTO genres (genre_name)
    SELECT v.name
    FROM (VALUES ${valuesList(names.map((n) => sql`(${n.name}::text, ${n.key}::text)`))}) AS v(name, key)
    WHERE NOT EXISTS (SELECT 1 FROM genres g WHERE lower(g.genre_name) = v.key)
    ON CONFLICT DO NOTHING`);
}

function linkAuthors(d: AnyDb, bookIdExpr: ReturnType<typeof sql>, items: Item[], orderOffset: ReturnType<typeof sql>) {
  return d.execute(sql`
    INSERT INTO book_authors (book_id, author_id, author_order)
    SELECT ${bookIdExpr}, a.author_id, ${orderOffset} + row_number() OVER (ORDER BY min(t.ord))
    FROM (VALUES ${valuesList(items.map((i) => sql`(${i.ord}::int, ${i.id}::int, ${i.key}::text)`))}) AS t(ord, id, key)
    JOIN authors a
      ON (t.id IS NOT NULL AND a.author_id = t.id)
      OR (t.key IS NOT NULL AND lower(a.name) = t.key)
    GROUP BY a.author_id
    ON CONFLICT DO NOTHING`);
}

function linkGenres(d: AnyDb, bookIdExpr: ReturnType<typeof sql>, items: Item[], primaryIfNone: boolean) {
  const canBePrimary = primaryIfNone
    ? sql`NOT EXISTS (SELECT 1 FROM book_genres bg WHERE bg.book_id = ${bookIdExpr} AND bg.is_primary)`
    : sql`true`;
  return d.execute(sql`
    INSERT INTO book_genres (book_id, genre_id, is_primary)
    SELECT ${bookIdExpr}, g.genre_id, (${canBePrimary} AND row_number() OVER (ORDER BY min(t.ord)) = 1)
    FROM (VALUES ${valuesList(items.map((i) => sql`(${i.ord}::int, ${i.id}::int, ${i.key}::text)`))}) AS t(ord, id, key)
    JOIN genres g
      ON (t.id IS NOT NULL AND g.genre_id = t.id)
      OR (t.key IS NOT NULL AND lower(g.genre_name) = t.key)
    GROUP BY g.genre_id
    ON CONFLICT DO NOTHING`);
}

/**
 * Run statements built by `build` atomically.
 * neon-http has no interactive transactions, but batch() is one transaction.
 * Returns the results array.
 */
export async function runAtomic(database: AnyDb, build: (d: AnyDb) => unknown[]): Promise<unknown[]> {
  if (typeof database.batch === "function") {
    return database.batch(build(database));
  }
  return database.transaction(async (tx: AnyDb) => {
    const out: unknown[] = [];
    for (const q of build(tx)) out.push(await q);
    return out;
  });
}

// ---- public API -------------------------------------------------------------

export async function createBookWithAuthors(database: AnyDb, input: CreateBookInput) {
  const title = input.title?.trim();
  if (!title) throw new BookInputError("Title is required");

  const authorPlan = planAuthors(input);
  const genrePlan = planGenres(input);

  // Fail early (and without writes) if a given id does not exist.
  await assertIdsExist(database, authorPlan.ids, authors, authors.authorId, "Author");
  await assertIdsExist(database, genrePlan.ids, genres, genres.genreId, "Genre");

  const isbn = input.isbn?.replace(/[-\s]/g, "") || null;

  // The book id is read back with currval() since earlier results are not
  // available inside a batch.
  let bookIdx = 0;
  const results = await runAtomic(database, (d) => {
    const stmts: unknown[] = [];
    if (authorPlan.names.length > 0) stmts.push(insertMissingAuthors(d, authorPlan.names));
    if (genrePlan.names.length > 0) stmts.push(insertMissingGenres(d, genrePlan.names));

    bookIdx = stmts.length;
    stmts.push(
      d
        .insert(books)
        .values({
          title,
          isbn,
          goodreadsUrl: input.goodreadsUrl || null,
          year: input.year || null,
          pages: input.pages || null,
        })
        .returning({ bookId: books.bookId }),
    );

    if (authorPlan.items.length > 0) stmts.push(linkAuthors(d, BOOK_SEQ, authorPlan.items, sql`0`));
    if (genrePlan.items.length > 0) stmts.push(linkGenres(d, BOOK_SEQ, genrePlan.items, false));

    if (input.coverUrl || input.description || input.publisher) {
      stmts.push(
        d.execute(sql`
          INSERT INTO goodreads_data (book_id, cover_url, description, publisher)
          VALUES (${BOOK_SEQ}, ${input.coverUrl || null}, ${input.description || null}, ${input.publisher || null})`),
      );
    }
    return stmts;
  });

  const [row] = results[bookIdx] as { bookId: number }[];
  return getBookWithAuthors(database, row.bookId);
}

/**
 * Add authors and/or genres to an existing book (additive, idempotent).
 * Names are matched case-insensitively and created when missing.
 */
export async function attachAuthorsGenres(
  database: AnyDb,
  bookId: number,
  input: Pick<CreateBookInput, "authorIds" | "authors" | "genreIds" | "genres">,
) {
  if (!Number.isInteger(bookId)) throw new BookInputError("bookId must be an integer");
  const [book] = await database.select({ id: books.bookId }).from(books).where(eq(books.bookId, bookId)).limit(1);
  if (!book) throw new BookInputError(`Book ${bookId} not found`);

  const authorPlan = planAuthors(input);
  const genrePlan = planGenres(input);
  if (authorPlan.items.length === 0 && genrePlan.items.length === 0) {
    throw new BookInputError("Provide at least one author or genre");
  }
  await assertIdsExist(database, authorPlan.ids, authors, authors.authorId, "Author");
  await assertIdsExist(database, genrePlan.ids, genres, genres.genreId, "Genre");

  const id = sql`${bookId}::int`;
  await runAtomic(database, (d) => {
    const stmts: unknown[] = [];
    if (authorPlan.names.length > 0) stmts.push(insertMissingAuthors(d, authorPlan.names));
    if (genrePlan.names.length > 0) stmts.push(insertMissingGenres(d, genrePlan.names));
    if (authorPlan.items.length > 0) {
      const offset = sql`(SELECT coalesce(max(author_order), 0) FROM book_authors WHERE book_id = ${id})`;
      stmts.push(linkAuthors(d, id, authorPlan.items, offset));
    }
    if (genrePlan.items.length > 0) stmts.push(linkGenres(d, id, genrePlan.items, true));
    return stmts;
  });

  return getBookWithAuthors(database, bookId);
}

export async function getBookWithAuthors(database: AnyDb, bookId: number) {
  const [book] = await database.select().from(books).where(eq(books.bookId, bookId)).limit(1);
  const bookAuthorRows = await database
    .select({ authorId: authors.authorId, name: authors.name, order: bookAuthors.authorOrder })
    .from(bookAuthors)
    .innerJoin(authors, eq(bookAuthors.authorId, authors.authorId))
    .where(eq(bookAuthors.bookId, bookId))
    .orderBy(asc(bookAuthors.authorOrder));
  const bookGenreRows = await database
    .select({ genreId: genres.genreId, name: genres.genreName, isPrimary: bookGenres.isPrimary })
    .from(bookGenres)
    .innerJoin(genres, eq(bookGenres.genreId, genres.genreId))
    .where(eq(bookGenres.bookId, bookId))
    .orderBy(asc(genres.genreName));
  return { ...book, authors: bookAuthorRows, genres: bookGenreRows };
}
