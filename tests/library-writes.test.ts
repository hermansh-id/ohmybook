import { beforeAll, beforeEach, describe, expect, test } from "bun:test";
import { PGlite } from "@electric-sql/pglite";
import { drizzle } from "drizzle-orm/pglite";
import { migrate } from "drizzle-orm/pglite/migrator";
import { count, sql } from "drizzle-orm";
import * as schema from "@/lib/db/schema";
import { BookInputError, createBookWithAuthors } from "@/lib/db/book-writes";
import { addAuthor, addGenre, deleteBook, updateBookDetails } from "@/lib/db/library-writes";
import { bookUrl, withBookUrls } from "@/lib/mcp/links";

const { authors, books } = schema;
const db = drizzle(new PGlite(), { schema });

beforeAll(async () => {
  await migrate(db, { migrationsFolder: "./drizzle" });
  // uq_authors_name_lower comes from drizzle/0001
});
beforeEach(async () => {
  await db.execute(sql`TRUNCATE books, authors, genres RESTART IDENTITY CASCADE`);
});

describe("addAuthor / addGenre", () => {
  test("create once, then reuse case-insensitively", async () => {
    const a = await addAuthor(db, { name: "  Aria   Wiratma ", bio: "bio" });
    expect(a.created).toBe(true);
    expect(a.author.name).toBe("Aria Wiratma");
    const b = await addAuthor(db, { name: "ARIA wiratma" });
    expect(b.created).toBe(false);
    expect(b.author.authorId).toBe(a.author.authorId);
    expect((await db.select({ n: count() }).from(authors))[0].n).toBe(1);

    const g = await addGenre(db, { name: "Sejarah" });
    const g2 = await addGenre(db, { name: "sejarah" });
    expect(g.created).toBe(true);
    expect(g2.created).toBe(false);
    expect(g2.genre.genreId).toBe(g.genre.genreId);
  });

  test("empty names rejected", async () => {
    await expect(addAuthor(db, { name: "  " })).rejects.toBeInstanceOf(BookInputError);
    await expect(addGenre(db, { name: "" })).rejects.toBeInstanceOf(BookInputError);
  });
});

describe("updateBookDetails", () => {
  test("updates book fields and goodreads fields, clears with empty string", async () => {
    const book = await createBookWithAuthors(db, { title: "Old", authors: ["X"], isbn: "123", pages: 100 });
    const u = await updateBookDetails(db, {
      bookId: book.bookId,
      title: " New Title ",
      year: 2020,
      isbn: "978-1-23",
      coverUrl: "https://x/c.jpg",
      publisher: "Marjin Kiri",
    });
    expect(u.title).toBe("New Title");
    expect(u.year).toBe(2020);
    expect(u.pages).toBe(100); // untouched
    expect(u.isbn).toBe("97812" + "3");
    expect(u.coverUrl).toBe("https://x/c.jpg");
    expect(u.publisher).toBe("Marjin Kiri");
    const cleared = await updateBookDetails(db, { bookId: book.bookId, coverUrl: "", isbn: "" });
    expect(cleared.coverUrl).toBeNull();
    expect(cleared.isbn).toBeNull();
    expect(cleared.publisher).toBe("Marjin Kiri");
  });

  test("errors", async () => {
    const book = await createBookWithAuthors(db, { title: "T" });
    await expect(updateBookDetails(db, { bookId: book.bookId })).rejects.toBeInstanceOf(BookInputError);
    await expect(updateBookDetails(db, { bookId: book.bookId, title: " " })).rejects.toBeInstanceOf(BookInputError);
    await expect(updateBookDetails(db, { bookId: 999, title: "x" })).rejects.toBeInstanceOf(BookInputError);
  });
});

describe("deleteBook", () => {
  test("deletes and returns title; unknown id errors", async () => {
    const book = await createBookWithAuthors(db, { title: "Bye", authors: ["A"] });
    expect(await deleteBook(db, book.bookId)).toEqual({ bookId: book.bookId, title: "Bye" });
    expect((await db.select({ n: count() }).from(books))[0].n).toBe(0);
    await expect(deleteBook(db, book.bookId)).rejects.toBeInstanceOf(BookInputError);
  });
});

describe("links", () => {
  test("withBookUrls adds url to book-like objects, deeply", () => {
    process.env.BETTER_AUTH_URL = "https://ohmybook.vercel.app/";
    expect(bookUrl(849)).toBe("https://ohmybook.vercel.app/dashboard/books/849");
    const out = withBookUrls([{ book: { bookId: 7, title: "A" }, authors: "x", when: new Date(0) }]);
    expect((out[0].book as Record<string, unknown>).url).toBe("https://ohmybook.vercel.app/dashboard/books/7");
    expect(out[0].when).toBeInstanceOf(Date);
    expect((out[0] as Record<string, unknown>).url).toBeUndefined();
  });
});
