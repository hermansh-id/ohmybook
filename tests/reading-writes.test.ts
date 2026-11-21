import { beforeAll, beforeEach, describe, expect, test } from "bun:test";
import { PGlite } from "@electric-sql/pglite";
import { drizzle } from "drizzle-orm/pglite";
import { migrate } from "drizzle-orm/pglite/migrator";
import { count, sql } from "drizzle-orm";
import * as schema from "@/lib/db/schema";
import { BookInputError } from "@/lib/db/book-writes";
import { updateBookReading } from "@/lib/db/reading-writes";

const { books, readingLog } = schema;
const db = drizzle(new PGlite(), { schema });
const today = new Date().toISOString().slice(0, 10);

beforeAll(async () => {
  await migrate(db, { migrationsFolder: "./drizzle" });
});

let bookId: number;
beforeEach(async () => {
  await db.execute(sql`TRUNCATE books RESTART IDENTITY CASCADE`);
  [{ bookId }] = await db.insert(books).values({ title: "Test Book", pages: 200 }).returning();
});

const logs = async () => (await db.select({ n: count() }).from(readingLog))[0].n;

describe("updateBookReading", () => {
  test("finished + rating on a book without a log creates it", async () => {
    const log = await updateBookReading(db, { bookId, status: "finished", rating: 4 });
    expect(log.status).toBe("finished");
    expect(log.rating).toBe(4);
    expect(log.dateFinished).toBe(today);
    expect(log.title).toBe("Test Book");
    expect(await logs()).toBe(1);
  });

  test("updates only provided fields on an existing log (one row per book)", async () => {
    await updateBookReading(db, { bookId, status: "reading", currentPage: 50 });
    const log = await updateBookReading(db, { bookId, rating: 5 });
    expect(log.status).toBe("reading");
    expect(log.currentPage).toBe(50);
    expect(log.rating).toBe(5);
    expect(await logs()).toBe(1);
  });

  test("reading stamps dateStarted once, finished keeps explicit dateFinished", async () => {
    const a = await updateBookReading(db, { bookId, status: "reading", dateStarted: "2026-01-02" });
    expect(a.dateStarted).toBe("2026-01-02");
    const b = await updateBookReading(db, { bookId, status: "reading" });
    expect(b.dateStarted).toBe("2026-01-02");
    const c = await updateBookReading(db, { bookId, status: "finished", dateFinished: "2026-02-03" });
    expect(c.dateFinished).toBe("2026-02-03");
  });

  test("rating alone on a new book defaults status to want_to_read", async () => {
    const log = await updateBookReading(db, { bookId, rating: 3 });
    expect(log.status).toBe("want_to_read");
  });

  test("validation errors", async () => {
    const bad = (i: Parameters<typeof updateBookReading>[1]) => expect(updateBookReading(db, i)).rejects.toBeInstanceOf(BookInputError);
    await bad({ bookId, rating: 6 });
    await bad({ bookId, rating: 0 });
    await bad({ bookId, rating: 2.5 });
    await bad({ bookId, status: "done" as never });
    await bad({ bookId, dateFinished: "03/02/2026" });
    await bad({ bookId });
    await bad({ bookId: 99999, status: "finished" });
    expect(await logs()).toBe(0);
  });
});
