import { beforeAll, beforeEach, describe, expect, test } from "bun:test";
import { PGlite } from "@electric-sql/pglite";
import { drizzle } from "drizzle-orm/pglite";
import { migrate } from "drizzle-orm/pglite/migrator";
import { sql } from "drizzle-orm";
import * as schema from "@/lib/db/schema";
import { BookInputError } from "@/lib/db/book-writes";
import { getReadingFocus } from "@/lib/db/planning-reads";
import { addPlanItems, completePlanItem, setPriority } from "@/lib/db/planning-writes";

const { books, readingLog, readingSessions } = schema;
const db = drizzle(new PGlite(), { schema });

beforeAll(async () => {
  await migrate(db, { migrationsFolder: "./drizzle" });
});

const ids: Record<string, number> = {};
beforeEach(async () => {
  await db.execute(sql`TRUNCATE books RESTART IDENTITY CASCADE`);
  for (const [t, pages] of [["Middlemarch", 800], ["Dubliners", 200], ["The Good Soldier", 250], ["Alice", 120]] as const) {
    [{ bookId: ids[t] }] = await db.insert(books).values({ title: t, pages }).returning();
  }
});

// Today = Thursday 2026-11-19; week Mon 16 - Sun 22; weekend Sat 21 / Sun 22
const TODAY = "2026-11-19";

describe("getReadingFocus", () => {
  test("priorities, today's plan, the weekend, weekly progress and what is being read", async () => {
    await setPriority(db, { bookId: ids.Middlemarch, level: "high", reason: "Long-standing wishlist" });
    await setPriority(db, { bookId: ids["The Good Soldier"], level: "critical" });
    await setPriority(db, { bookId: ids.Dubliners, level: "medium" });
    await setPriority(db, { bookId: ids.Alice, level: "low" });
    await db.insert(readingLog).values({ bookId: ids["The Good Soldier"], status: "reading", currentPage: 40, dateStarted: "2026-11-10" });
    await db.insert(readingSessions).values({ bookId: ids["The Good Soldier"], sessionDate: "2026-11-18", pagesRead: 10 });

    const [t1, , w1, w2] = await addPlanItems(db, [
      { bookId: ids["The Good Soldier"], scheduledDate: TODAY, plannedPages: 25 },
      { bookId: ids.Dubliners, scheduledDate: "2026-11-17", plannedPages: 20 },
      { bookId: ids.Middlemarch, scheduledDate: "2026-11-21", timeOfDay: "morning", plannedPages: 40 },
      { bookId: ids.Dubliners, scheduledDate: "2026-11-22", timeOfDay: "evening" },
    ]);
    await completePlanItem(db, t1.itemId, { actualPages: 20, sessionDate: TODAY });

    const f = await getReadingFocus(db, TODAY);
    expect(f.priorities.map((p) => p.title)).toEqual(["The Good Soldier", "Middlemarch", "Dubliners"]); // top 3, most important first
    expect(f.todayItems.map((i) => [i.title, i.item.status])).toEqual([["The Good Soldier", "completed"]]);
    expect(f.weekend).toEqual(["2026-11-21", "2026-11-22"]);
    expect(f.weekendItems.map((i) => i.item.itemId)).toEqual([w1.itemId, w2.itemId]);
    expect(f.week.plannedPages).toBe(85); // 25 + 20 + 40 (+ none)
    expect(f.week.actualPages).toBe(20);
    expect(f.week.completionPct).toBe(24);
    expect(f.reading.map((r) => r.title)).toEqual(["The Good Soldier"]);
  });

  test("needs attention: finished priority book, past target, stalled reading, open past plans", async () => {
    await db.insert(readingLog).values({ bookId: ids.Alice, status: "finished", dateFinished: "2026-11-10" });
    await setPriority(db, { bookId: ids.Alice, level: "low" });
    await setPriority(db, { bookId: ids.Middlemarch, level: "high", targetDate: "2026-11-01" });
    await db.insert(readingLog).values({ bookId: ids.Dubliners, status: "reading", currentPage: 5, dateStarted: "2026-10-01" });
    await db.insert(readingSessions).values({ bookId: ids.Dubliners, sessionDate: "2026-10-15", pagesRead: 5 });
    await addPlanItems(db, [{ bookId: ids["The Good Soldier"], scheduledDate: "2026-11-17", plannedPages: 10 }]); // never logged

    const f = await getReadingFocus(db, TODAY);
    const kinds = f.attention.map((a) => a.kind).sort();
    expect(kinds).toEqual(["past_target", "priority_book_finished", "stalled", "waiting_plans"]);
    expect(f.attention.find((a) => a.kind === "stalled")!.message).toContain("35 days");
    expect(f.attention.find((a) => a.kind === "waiting_plans")!.message).toContain("1 planned activity");
    // nothing here changed any priority by itself
    expect((await getReadingFocus(db, TODAY)).priorities.map((p) => p.priority.status)).toEqual(["active", "active"]);
  });

  test("a quiet week has no attention items and no completion percentage", async () => {
    const f = await getReadingFocus(db, TODAY);
    expect(f.attention).toEqual([]);
    expect(f.todayItems).toEqual([]);
    expect(f.week.completionPct).toBeNull();
  });

  test("validation", async () => {
    await expect(getReadingFocus(db, "today")).rejects.toBeInstanceOf(BookInputError);
  });
});
