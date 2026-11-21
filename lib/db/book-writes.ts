import { and, asc, eq, inArray, sql } from "drizzle-orm";
import { authors, bookAuthors, books } from "./schema";

/**
 * Atomic "create book + resolve/create authors + link" logic.
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
  genreIds?: number[];
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

export function planAuthors(input: Pick<CreateBookInput, "authorIds" | "authors">) {
  const ids = [...new Set(input.authorIds ?? [])];
  for (const id of ids) {
    if (!Number.isInteger(id)) throw new BookInputError(`Invalid author id: ${id}`);
  }

  const names: { name: string; key: string }[] = [];
  const seen = new Set<string>();
  for (const raw of input.authors ?? []) {
    const name = normalizeAuthorName(raw);
    if (!name) continue;
    if (name.length > 255) throw new BookInputError(`Author name too long: "${name.slice(0, 40)}…"`);
    const key = name.toLowerCase();
    if (seen.has(key)) continue; // first spelling wins
    seen.add(key);
    names.push({ name, key });
  }

  // Order: explicit IDs first, then names, in the order given.
  const items = [
    ...ids.map((id, i) => ({ ord: i + 1, id: id as number | null, key: null as string | null })),
    ...names.map((n, i) => ({ ord: ids.length + i + 1, id: null as number | null, key: n.key })),
  ];
  return { ids, names, items };
}

const BOOK_SEQ = sql`currval(pg_get_serial_sequence('books', 'book_id')::regclass)`;

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyDb = any;

export async function createBookWithAuthors(database: AnyDb, input: CreateBookInput) {
  const title = input.title?.trim();
  if (!title) throw new BookInputError("Title is required");

  const { ids, names, items } = planAuthors(input);

  // Fail early (and without writes) if a given author id does not exist.
  if (ids.length > 0) {
    const found = await database
      .select({ authorId: authors.authorId })
      .from(authors)
      .where(inArray(authors.authorId, ids));
    const foundIds = new Set<number>(found.map((r: { authorId: number }) => r.authorId));
    const missing = ids.filter((id) => !foundIds.has(id));
    if (missing.length > 0) throw new BookInputError(`Author id(s) not found: ${missing.join(", ")}`);
  }

  const genreIds = [...new Set(input.genreIds ?? [])];
  const isbn = input.isbn?.replace(/[-\s]/g, "") || null;

  // Statements run in order inside ONE transaction; the book id is read back
  // with currval() since earlier results are not available inside a batch.
  const build = (d: AnyDb) => {
    const stmts: unknown[] = [];

    if (names.length > 0) {
      stmts.push(
        d.execute(sql`
          INSERT INTO authors (name)
          SELECT v.name
          FROM (VALUES ${sql.join(names.map((n) => sql`(${n.name}::text, ${n.key}::text)`), sql`, `)}) AS v(name, key)
          WHERE NOT EXISTS (SELECT 1 FROM authors a WHERE lower(a.name) = v.key)
          ON CONFLICT DO NOTHING`),
      );
    }

    const bookIdx = stmts.length;
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

    if (items.length > 0) {
      stmts.push(
        d.execute(sql`
          INSERT INTO book_authors (book_id, author_id, author_order)
          SELECT ${BOOK_SEQ}, a.author_id, row_number() OVER (ORDER BY min(t.ord))
          FROM (VALUES ${sql.join(
            items.map((i) => sql`(${i.ord}::int, ${i.id}::int, ${i.key}::text)`),
            sql`, `,
          )}) AS t(ord, id, key)
          JOIN authors a
            ON (t.id IS NOT NULL AND a.author_id = t.id)
            OR (t.key IS NOT NULL AND lower(a.name) = t.key)
          GROUP BY a.author_id
          ON CONFLICT DO NOTHING`),
      );
    }

    if (genreIds.length > 0) {
      stmts.push(
        d.execute(sql`
          INSERT INTO book_genres (book_id, genre_id, is_primary)
          SELECT ${BOOK_SEQ}, g.genre_id, g.ord = 1
          FROM unnest(ARRAY[${sql.join(genreIds, sql`, `)}]::int[]) WITH ORDINALITY AS g(genre_id, ord)
          ON CONFLICT DO NOTHING`),
      );
    }

    if (input.coverUrl || input.description || input.publisher) {
      stmts.push(
        d.execute(sql`
          INSERT INTO goodreads_data (book_id, cover_url, description, publisher)
          VALUES (${BOOK_SEQ}, ${input.coverUrl || null}, ${input.description || null}, ${input.publisher || null})`),
      );
    }

    return { stmts, bookIdx };
  };

  let results: unknown[];
  let bookIdx: number;
  if (typeof database.batch === "function") {
    // neon-http: no interactive transactions; batch() is atomic.
    const built = build(database);
    bookIdx = built.bookIdx;
    results = await database.batch(built.stmts);
  } else {
    bookIdx = 0;
    results = await database.transaction(async (tx: AnyDb) => {
      const built = build(tx);
      bookIdx = built.bookIdx;
      const out: unknown[] = [];
      for (const q of built.stmts) out.push(await q);
      return out;
    });
  }

  const [row] = results[bookIdx] as { bookId: number }[];
  return getBookWithAuthors(database, row.bookId);
}

export async function getBookWithAuthors(database: AnyDb, bookId: number) {
  const [book] = await database.select().from(books).where(eq(books.bookId, bookId)).limit(1);
  const bookAuthorRows = await database
    .select({ authorId: authors.authorId, name: authors.name, order: bookAuthors.authorOrder })
    .from(bookAuthors)
    .innerJoin(authors, eq(bookAuthors.authorId, authors.authorId))
    .where(and(eq(bookAuthors.bookId, bookId)))
    .orderBy(asc(bookAuthors.authorOrder));
  return { ...book, authors: bookAuthorRows };
}
