import { beforeAll, beforeEach, describe, expect, test } from "bun:test";
import { PGlite } from "@electric-sql/pglite";
import { drizzle } from "drizzle-orm/pglite";
import { migrate } from "drizzle-orm/pglite/migrator";
import { count, sql } from "drizzle-orm";
import * as schema from "@/lib/db/schema";
import { BookInputError } from "@/lib/db/book-writes";
import { cancelPriority, completePriority, getPriorityChanges, listPriorities, setPriority } from "@/lib/db/planning-writes";

const { books, readingLog, readingPriorities } = schema;
const db = drizzle(new PGlite(), { schema });

beforeAll(async () => {
  await migrate(db, { migrationsFolder: "./drizzle" });
});

const ids: Record<string, number> = {};
beforeEach(async () => {
  await db.execute(sql`TRUNCATE books RESTART IDENTITY CASCADE`);
  for (const t of ["Middlemarch", "Dubliners", "Alice", "The Good Soldier"]) {
    [{ bookId: ids[t] }] = await db.insert(books).values({ title: t, pages: 300 }).returning();
  }
});

describe("setPriority", () => {
  test("creates an active priority with defaults and logs history", async () => {
    const p = await setPriority(db, { bookId: ids.Middlemarch, level: "high", reason: "  Long-standing wishlist " });
    expect(p).toMatchObject({ level: "high", status: "active", reason: "Long-standing wishlist" });
    const hist = await getPriorityChanges(db);
    expect(hist).toHaveLength(1);
    expect(hist[0]).toMatchObject({ title: "Middlemarch", fromLevel: null, toLevel: "high", toStatus: "active" });
  });

  test("level defaults to medium", async () => {
    expect((await setPriority(db, { bookId: ids.Alice })).level).toBe("medium");
  });

  test("updates in place (one active per book), only provided fields change, logs level change only", async () => {
    await setPriority(db, { bookId: ids.Dubliners, level: "high", reason: "Planned exploration", targetDate: "2026-12-01", estimatedMinutes: 300 });
    const u = await setPriority(db, { bookId: ids.Dubliners, level: "critical" });
    expect(u).toMatchObject({ level: "critical", reason: "Planned exploration", targetDate: "2026-12-01", estimatedMinutes: 300 });
    await setPriority(db, { bookId: ids.Dubliners, reason: "New reason" }); // no level change -> no history row
    expect((await db.select({ n: count() }).from(readingPriorities))[0].n).toBe(1);
    const hist = await getPriorityChanges(db);
    expect(hist.map((h) => `${h.fromLevel}>${h.toLevel}`)).toEqual(["high>critical", "null>high"]);
  });

  test("empty string / null clear optional fields", async () => {
    await setPriority(db, { bookId: ids.Alice, reason: "x", targetDate: "2026-12-01", estimatedMinutes: 60 });
    const u = await setPriority(db, { bookId: ids.Alice, reason: "", targetDate: null, estimatedMinutes: null });
    expect(u).toMatchObject({ reason: null, targetDate: null, estimatedMinutes: null });
  });

  test("priority is independent of reading status and never changes it", async () => {
    await db.insert(readingLog).values({ bookId: ids["The Good Soldier"], status: "reading", currentPage: 40 });
    await setPriority(db, { bookId: ids["The Good Soldier"], level: "low" });
    await setPriority(db, { bookId: ids["The Good Soldier"], level: "critical" });
    const [log] = await db.select().from(readingLog);
    expect(log).toMatchObject({ status: "reading", currentPage: 40 });
  });

  test("validation", async () => {
    const bad = (i: Parameters<typeof setPriority>[1]) => expect(setPriority(db, i)).rejects.toBeInstanceOf(BookInputError);
    await bad({ bookId: ids.Alice, level: "urgent" as never });
    await bad({ bookId: ids.Alice, targetDate: "2026-13-40" });
    await bad({ bookId: ids.Alice, estimatedMinutes: 0 });
    await bad({ bookId: 9999, level: "high" });
    await setPriority(db, { bookId: ids.Alice, level: "low" });
    await bad({ bookId: ids.Alice }); // nothing to update
  });
});

describe("complete / cancel / list", () => {
  test("completing frees the slot: a new active priority can be created afterwards", async () => {
    await setPriority(db, { bookId: ids.Middlemarch, level: "high" });
    const done = await completePriority(db, ids.Middlemarch);
    expect(done.status).toBe("completed");
    await setPriority(db, { bookId: ids.Middlemarch, level: "low" }); // reread
    expect((await db.select({ n: count() }).from(readingPriorities))[0].n).toBe(2);
    expect(await listPriorities(db)).toHaveLength(1);
    expect(await listPriorities(db, { status: "all" })).toHaveLength(2);
  });

  test("cancel; closing without an active priority errors", async () => {
    await setPriority(db, { bookId: ids.Alice, level: "medium" });
    expect((await cancelPriority(db, ids.Alice)).status).toBe("cancelled");
    await expect(cancelPriority(db, ids.Alice)).rejects.toBeInstanceOf(BookInputError);
  });

  test("list is ordered critical > high > medium > low, then target date", async () => {
    await setPriority(db, { bookId: ids.Alice, level: "medium" });
    await setPriority(db, { bookId: ids.Dubliners, level: "high", targetDate: "2026-12-10" });
    await setPriority(db, { bookId: ids.Middlemarch, level: "high", targetDate: "2026-12-01" });
    await setPriority(db, { bookId: ids["The Good Soldier"], level: "critical" });
    const titles = (await listPriorities(db)).map((r: { title: string }) => r.title);
    expect(titles).toEqual(["The Good Soldier", "Middlemarch", "Dubliners", "Alice"]);
  });

  test("list carries reading status/progress without being coupled to it", async () => {
    await db.insert(readingLog).values({ bookId: ids.Alice, status: "reading", currentPage: 12 });
    await setPriority(db, { bookId: ids.Alice, level: "low" });
    const [row] = await listPriorities(db);
    expect(row).toMatchObject({ readingStatus: "reading", currentPage: 12, bookId: ids.Alice });
  });

  test("one active priority per book is enforced by the database too", async () => {
    await db.insert(readingPriorities).values({ bookId: ids.Alice, level: "low", status: "active" });
    await expect(
      (async () => { await db.insert(readingPriorities).values({ bookId: ids.Alice, level: "high", status: "active" }); })(),
    ).rejects.toThrow();
  });
});
