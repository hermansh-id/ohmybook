import { beforeAll, beforeEach, describe, expect, test } from "bun:test";
import { PGlite } from "@electric-sql/pglite";
import { drizzle } from "drizzle-orm/pglite";
import { migrate } from "drizzle-orm/pglite/migrator";
import { count, sql } from "drizzle-orm";
import * as schema from "@/lib/db/schema";
import { BookInputError } from "@/lib/db/book-writes";
import { getWeekSummary, listWeeklyReviews } from "@/lib/db/planning-reads";
import {
  addPlanItems,
  completePlanItem,
  reschedulePlanItem,
  saveWeeklyReview,
  skipPlanItem,
} from "@/lib/db/planning-writes";

const { books, readingLog, readingPriorityHistory, readingSessions, weeklyReadingReviews } = schema;
const db = drizzle(new PGlite(), { schema });

beforeAll(async () => {
  await migrate(db, { migrationsFolder: "./drizzle" });
});

const ids: Record<string, number> = {};
beforeEach(async () => {
  await db.execute(sql`TRUNCATE books RESTART IDENTITY CASCADE`);
  await db.execute(sql`TRUNCATE weekly_reading_reviews RESTART IDENTITY CASCADE`);
  [{ bookId: ids.Middlemarch }] = await db.insert(books).values({ title: "Middlemarch", pages: 800 }).returning();
  [{ bookId: ids.Dubliners }] = await db.insert(books).values({ title: "Dubliners", pages: 200 }).returning();
  [{ bookId: ids.Short }] = await db.insert(books).values({ title: "Short", pages: 60 }).returning();
});

// Week: Mon 2026-11-16 .. Sun 2026-11-22
async function seedWeek() {
  const [a, b, c, d] = await addPlanItems(db, [
    { bookId: ids.Middlemarch, scheduledDate: "2026-11-21", plannedPages: 40 },
    { bookId: ids.Dubliners, scheduledDate: "2026-11-21", plannedPages: 30 },
    { bookId: ids.Middlemarch, scheduledDate: "2026-11-22", plannedPages: 30 },
    { bookId: ids.Dubliners, scheduledDate: "2026-11-22", plannedPages: 20 },
  ]);
  await completePlanItem(db, a.itemId, { actualPages: 30, actualMinutes: 50, sessionDate: "2026-11-21" });
  await completePlanItem(db, b.itemId, { actualPages: 30, sessionDate: "2026-11-21" });
  await skipPlanItem(db, c.itemId);
  await reschedulePlanItem(db, d.itemId, { scheduledDate: "2026-11-23" }); // next week

  await db.insert(readingSessions).values([
    { bookId: ids.Short, sessionDate: "2026-11-22", pagesRead: 10, minutesRead: 20 }, // spontaneous, in week
    { bookId: ids.Short, sessionDate: "2026-11-10", pagesRead: 99, minutesRead: 99 }, // other week
  ]);
  await db.insert(readingLog).values({ bookId: ids.Short, status: "finished", dateFinished: "2026-11-20", rating: 4 });
  await db.insert(readingPriorityHistory).values([
    { bookId: ids.Middlemarch, fromLevel: "medium", toLevel: "high", fromStatus: "active", toStatus: "active", createdAt: new Date("2026-11-18T10:00:00Z") },
    { bookId: ids.Middlemarch, fromLevel: null, toLevel: "medium", fromStatus: null, toStatus: "active", createdAt: new Date("2026-11-10T10:00:00Z") },
  ]);
}

describe("getWeekSummary", () => {
  test("planned vs actual, activities, books and changes for the week", async () => {
    await seedWeek();
    const s = await getWeekSummary(db, "2026-11-19"); // any day in the week is normalized to Monday
    expect(s.weekStart).toBe("2026-11-16");
    expect(s.weekEnd).toBe("2026-11-22");

    // the rescheduled item is not counted against this week
    expect(s.activities).toEqual({ total: 3, planned: 0, completed: 2, skipped: 1, rescheduled: 1 });
    expect(s.pages.planned).toBe(100); // 40 + 30 + 30
    expect(s.pages.actualFromPlans).toBe(60);
    expect(s.pages.completionPct).toBe(60);
    expect(s.pages.totalRead).toBe(70); // 30 + 30 + 10 spontaneous; the other week's session is excluded
    expect(s.minutesRead).toBe(70); // 50 + 20 (item B had no minutes planned)
    expect(s.sessionsLogged).toBe(3);

    expect(s.booksCompleted.map((b) => b.title)).toEqual(["Short"]);
    expect(s.activeReading.map((b) => b.title)).toEqual(["Dubliners", "Middlemarch"]);
    expect(s.priorityChanges).toHaveLength(1);
    expect(s.priorityChanges[0]).toMatchObject({ title: "Middlemarch", fromLevel: "medium", toLevel: "high" });
    expect(s.review).toBeNull();
  });

  test("an empty week has no completion percentage (nothing to measure)", async () => {
    const s = await getWeekSummary(db, "2026-11-16");
    expect(s.pages).toEqual({ planned: 0, actualFromPlans: 0, completionPct: null, totalRead: 0 });
    expect(s.activities.total).toBe(0);
  });

  test("completion is capped at 100 when you read more than planned", async () => {
    const [a] = await addPlanItems(db, [{ bookId: ids.Middlemarch, scheduledDate: "2026-11-17", plannedPages: 10 }]);
    await completePlanItem(db, a.itemId, { actualPages: 40, sessionDate: "2026-11-17" });
    expect((await getWeekSummary(db, "2026-11-16")).pages.completionPct).toBe(100);
  });

  test("validation", async () => {
    await expect(getWeekSummary(db, "nope")).rejects.toBeInstanceOf(BookInputError);
  });
});

describe("saveWeeklyReview", () => {
  test("saves reflections with a snapshot of the week, normalized to Monday", async () => {
    await seedWeek();
    const r = await saveWeeklyReview(db, {
      weekStart: "2026-11-20",
      wentWell: "  Finished the short book ",
      blockers: "Tired in the evenings",
      nextWeekChanges: "Read in the morning",
    });
    expect(r).toMatchObject({
      weekStart: "2026-11-16",
      wentWell: "Finished the short book",
      blockers: "Tired in the evenings",
      nextWeekChanges: "Read in the morning",
      plannedItems: 3,
      completedItems: 2,
      skippedItems: 1,
      plannedPages: 100,
      actualPages: 60,
      totalPagesRead: 70,
      totalMinutes: 70,
      booksCompleted: 1,
    });
    expect((await getWeekSummary(db, "2026-11-16")).review?.wentWell).toBe("Finished the short book");
  });

  test("saving again updates in place: one review per week, untouched fields are kept, empty clears", async () => {
    await saveWeeklyReview(db, { weekStart: "2026-11-16", wentWell: "good", blockers: "busy" });
    const r = await saveWeeklyReview(db, { weekStart: "2026-11-18", nextWeekChanges: "earlier", blockers: "" });
    expect(r).toMatchObject({ wentWell: "good", blockers: null, nextWeekChanges: "earlier" });
    expect((await db.select({ n: count() }).from(weeklyReadingReviews))[0].n).toBe(1);
  });

  test("snapshot refreshes with the week's current numbers", async () => {
    const first = await saveWeeklyReview(db, { weekStart: "2026-11-16", wentWell: "x" });
    expect(first.totalPagesRead).toBe(0);
    await db.insert(readingSessions).values({ bookId: ids.Short, sessionDate: "2026-11-17", pagesRead: 12, minutesRead: 15 });
    const second = await saveWeeklyReview(db, { weekStart: "2026-11-16" });
    expect(second).toMatchObject({ wentWell: "x", totalPagesRead: 12, totalMinutes: 15 });
  });

  test("lists reviews newest first; validation", async () => {
    await saveWeeklyReview(db, { weekStart: "2026-11-02", wentWell: "a" });
    await saveWeeklyReview(db, { weekStart: "2026-11-16", wentWell: "b" });
    expect((await listWeeklyReviews(db)).map((r) => r.weekStart)).toEqual(["2026-11-16", "2026-11-02"]);
    await expect(saveWeeklyReview(db, { weekStart: "bad" })).rejects.toBeInstanceOf(BookInputError);
    await expect(saveWeeklyReview(db, { weekStart: "2026-11-16", wentWell: "x".repeat(5000) })).rejects.toBeInstanceOf(BookInputError);
  });
});
