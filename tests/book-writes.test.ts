import { beforeAll, beforeEach, describe, expect, test } from "bun:test";
import { PGlite } from "@electric-sql/pglite";
import { drizzle } from "drizzle-orm/pglite";
import { migrate } from "drizzle-orm/pglite/migrator";
import { count, sql } from "drizzle-orm";
import * as schema from "@/lib/db/schema";
import {
  BookInputError,
  attachAuthorsGenres,
  createBookWithAuthors,
  normalizeAuthorName,
  planAuthors,
} from "@/lib/db/book-writes";

const { authors, books, bookAuthors, genres, goodreadsData } = schema;

const client = new PGlite();
const db = drizzle(client, { schema });

beforeAll(async () => {
  await migrate(db, { migrationsFolder: "./drizzle" });
  // Same index as lib/db/schema/core.ts (applied by `db:push` in real DBs)
  await db.execute(sql`CREATE UNIQUE INDEX uq_authors_name_lower ON authors (lower(name))`);
});

beforeEach(async () => {
  await db.execute(sql`TRUNCATE books, authors, genres RESTART IDENTITY CASCADE`);
});

const total = async (table: typeof authors | typeof books | typeof bookAuthors) =>
  (await db.select({ n: count() }).from(table))[0].n;

describe("planAuthors", () => {
  test("normalizes whitespace/case and dedupes", () => {
    const plan = planAuthors({ authors: ["  Aria   Wiratma ", "aria wiratma", "", "  "], authorIds: [3, 3, 4] });
    expect(plan.ids).toEqual([3, 4]);
    expect(plan.names).toEqual([{ name: "Aria Wiratma", key: "aria wiratma" }]);
    expect(plan.items.map((i) => i.ord)).toEqual([1, 2, 3]);
    expect(normalizeAuthorName("  A \t B  ")).toBe("A B");
  });
});

describe("createBookWithAuthors", () => {
  test("new author name: creates author, book and link, returns details", async () => {
    const book = await createBookWithAuthors(db, {
      title: "Dilarang Gondrong!",
      authors: ["Aria Wiratma Yudhistira"],
      isbn: "978-979-1260-07-56",
      year: 2018,
      pages: 180,
      publisher: "Marjin Kiri",
    });
    expect(book.title).toBe("Dilarang Gondrong!");
    expect(book.isbn).toBe("978979126007" + "56");
    expect(book.authors).toHaveLength(1);
    expect(book.authors[0].name).toBe("Aria Wiratma Yudhistira");
    expect(await total(authors)).toBe(1);
    const [gr] = await db.select().from(goodreadsData);
    expect(gr.publisher).toBe("Marjin Kiri");
  });

  test("existing author name is reused (no new author row)", async () => {
    const [a] = await db.insert(authors).values({ name: "Pramoedya Ananta Toer" }).returning();
    const book = await createBookWithAuthors(db, { title: "Bumi Manusia", authors: ["Pramoedya Ananta Toer"] });
    expect(book.authors.map((x: { authorId: number }) => x.authorId)).toEqual([a.authorId]);
    expect(await total(authors)).toBe(1);
  });

  test("multiple authors keep given order", async () => {
    await db.insert(authors).values({ name: "Existing One" });
    const book = await createBookWithAuthors(db, {
      title: "Collab",
      authors: ["New Two", "Existing One", "New Three"],
    });
    expect(book.authors.map((a: { name: string }) => a.name)).toEqual(["New Two", "Existing One", "New Three"]);
    expect(book.authors.map((a: { order: number }) => a.order)).toEqual([1, 2, 3]);
    expect(await total(authors)).toBe(3);
  });

  test("case-insensitive + whitespace matching", async () => {
    const [a] = await db.insert(authors).values({ name: "Aria Wiratma" }).returning();
    const book = await createBookWithAuthors(db, { title: "X", authors: ["  ARIA   wiratma "] });
    expect(book.authors[0].authorId).toBe(a.authorId);
    expect(await total(authors)).toBe(1);
  });

  test("no duplicate authors or links within one request", async () => {
    const [a] = await db.insert(authors).values({ name: "Same Person" }).returning();
    const book = await createBookWithAuthors(db, {
      title: "Dupes",
      authorIds: [a.authorId, a.authorId],
      authors: ["same person", "SAME PERSON", "Same  Person"],
    });
    expect(book.authors).toHaveLength(1);
    expect(await total(bookAuthors)).toBe(1);
    expect(await total(authors)).toBe(1);
  });

  test("concurrent creates with the same new author yield one author row", async () => {
    await Promise.all([
      createBookWithAuthors(db, { title: "Book A", authors: ["Race Author"] }),
      createBookWithAuthors(db, { title: "Book B", authors: ["race author"] }),
    ]);
    expect(await total(authors)).toBe(1);
    expect(await total(bookAuthors)).toBe(2);
  });

  test("unique index rejects case-variant authors at DB level", async () => {
    await db.insert(authors).values({ name: "Case Test" });
    await expect((async () => { await db.insert(authors).values({ name: "case test" }); })()).rejects.toThrow();
  });

  test("backward compat: authorIds only", async () => {
    const [a, b] = await db.insert(authors).values([{ name: "A" }, { name: "B" }]).returning();
    const book = await createBookWithAuthors(db, { title: "Legacy", authorIds: [b.authorId, a.authorId] });
    expect(book.authors.map((x: { name: string }) => x.name)).toEqual(["B", "A"]);
    expect(await total(authors)).toBe(2);
  });

  test("authorIds + authors mixed, overlapping, no duplicate link", async () => {
    const [a] = await db.insert(authors).values({ name: "Mixed" }).returning();
    const book = await createBookWithAuthors(db, {
      title: "Mix",
      authorIds: [a.authorId],
      authors: ["mixed", "Brand New"],
    });
    expect(book.authors.map((x: { name: string }) => x.name)).toEqual(["Mixed", "Brand New"]);
  });

  test("genres linked, first is primary", async () => {
    const [g1, g2] = await db.insert(genres).values([{ genreName: "G1" }, { genreName: "G2" }]).returning();
    const book = await createBookWithAuthors(db, {
      title: "Genre",
      authors: ["Someone"],
      genreIds: [g2.genreId, g1.genreId],
    });
    const rows = await db.execute(sql`SELECT genre_id, is_primary FROM book_genres WHERE book_id = ${book.bookId} ORDER BY genre_id`);
    const primary = (rows.rows as { genre_id: number; is_primary: boolean }[]).find((r) => r.is_primary);
    expect(primary?.genre_id).toBe(g2.genreId);
  });

  test("rollback: failure after author creation leaves no author, book or link", async () => {
    // publisher > varchar(255) makes the LAST statement fail, after the author and book were written
    await expect(
      createBookWithAuthors(db, { title: "Doomed", authors: ["Ghost Author"], publisher: "x".repeat(300) }),
    ).rejects.toThrow();
    expect(await total(authors)).toBe(0);
    expect(await total(books)).toBe(0);
    expect(await total(bookAuthors)).toBe(0);
  });

  test("genre names: reused case-insensitively or created, first is primary", async () => {
    const [g] = await db.insert(genres).values({ genreName: "Sejarah" }).returning();
    const book = await createBookWithAuthors(db, { title: "G", authors: ["A"], genres: ["sejarah", "Politik", "  POLITIK "] });
    expect(book.genres.map((x: { name: string }) => x.name).sort()).toEqual(["Politik", "Sejarah"]);
    const primary = book.genres.find((x: { isPrimary: boolean }) => x.isPrimary);
    expect(primary.genreId).toBe(g.genreId);
    expect((await db.select({ n: count() }).from(genres))[0].n).toBe(2);
  });

  test("unknown genreId is rejected before any write", async () => {
    await expect(
      createBookWithAuthors(db, { title: "Bad", authors: ["Would Be New"], genreIds: [9999] }),
    ).rejects.toBeInstanceOf(BookInputError);
    expect(await total(authors)).toBe(0);
    expect(await total(books)).toBe(0);
  });

  test("unknown authorId is rejected before any write", async () => {
    await expect(
      createBookWithAuthors(db, { title: "Bad", authorIds: [4242], authors: ["Would Be New"] }),
    ).rejects.toBeInstanceOf(BookInputError);
    expect(await total(authors)).toBe(0);
    expect(await total(books)).toBe(0);
  });

  test("empty title is rejected", async () => {
    await expect(createBookWithAuthors(db, { title: "   ", authors: ["X"] })).rejects.toBeInstanceOf(BookInputError);
  });
});

describe("attachAuthorsGenres", () => {
  test("adds authors/genres to an existing book, idempotent, keeps order", async () => {
    const book = await createBookWithAuthors(db, { title: "Base", authors: ["First"], genres: ["One"] });
    const r1 = await attachAuthorsGenres(db, book.bookId, { authors: ["second", "FIRST"], genres: ["one", "Two"] });
    expect(r1.authors.map((a: { name: string }) => a.name)).toEqual(["First", "second"]);
    expect(r1.genres.map((g: { name: string }) => g.name)).toEqual(["One", "Two"]);
    expect(r1.genres.filter((g: { isPrimary: boolean }) => g.isPrimary)).toHaveLength(1);
    const r2 = await attachAuthorsGenres(db, book.bookId, { authors: ["Second"], genres: ["two"] });
    expect(r2.authors).toHaveLength(2);
    expect(r2.genres).toHaveLength(2);
  });

  test("errors: unknown book, nothing to add", async () => {
    await expect(attachAuthorsGenres(db, 999, { authors: ["X"] })).rejects.toBeInstanceOf(BookInputError);
    const book = await createBookWithAuthors(db, { title: "B2" });
    await expect(attachAuthorsGenres(db, book.bookId, {})).rejects.toBeInstanceOf(BookInputError);
  });
});
