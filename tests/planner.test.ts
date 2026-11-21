import { beforeAll, beforeEach, describe, expect, test } from "bun:test";
import { PGlite } from "@electric-sql/pglite";
import { drizzle } from "drizzle-orm/pglite";
import { migrate } from "drizzle-orm/pglite/migrator";
import { count, eq, sql } from "drizzle-orm";
import * as schema from "@/lib/db/schema";
import { BookInputError } from "@/lib/db/book-writes";
import { getPlannerRange } from "@/lib/db/planning-reads";
import {
  addPlanItems,
  completePlanItem,
  createPlan,
  createPlanWithItems,
  deletePlanItem,
  expandRepeat,
  reopenPlanItem,
  reschedulePlanItem,
  setPriority,
  skipPlanItem,
  updatePlanItem,
} from "@/lib/db/planning-writes";

const { books, readingLog, readingPlanItems, readingSessions } = schema;
const db = drizzle(new PGlite(), { schema });

beforeAll(async () => {
  await migrate(db, { migrationsFolder: "./drizzle" });
});

const ids: Record<string, number> = {};
beforeEach(async () => {
  await db.execute(sql`TRUNCATE books RESTART IDENTITY CASCADE`);
  await db.execute(sql`TRUNCATE reading_plans RESTART IDENTITY CASCADE`);
  [{ bookId: ids.Middlemarch }] = await db.insert(books).values({ title: "Middlemarch", pages: 800 }).returning();
  [{ bookId: ids.Dubliners }] = await db.insert(books).values({ title: "Dubliners", pages: 200 }).returning();
  [{ bookId: ids.Short }] = await db.insert(books).values({ title: "Short", pages: 60 }).returning();
});

const count_ = async (t: typeof readingPlanItems | typeof readingSessions) => (await db.select({ n: count() }).from(t))[0].n;
const bad = (p: Promise<unknown>) => expect(p).rejects.toBeInstanceOf(BookInputError);

// 2026-11-21 is a Saturday, 2026-11-22 a Sunday
describe("expandRepeat", () => {
  test("weekdays within N weeks, starting at the first date", () => {
    expect(expandRepeat("2026-11-21", { weekdays: [5, 6], weeks: 2 })).toEqual(["2026-11-21", "2026-11-22", "2026-11-28", "2026-11-29"]);
    expect(expandRepeat("2026-11-23", { weekdays: [0], weeks: 3 })).toEqual(["2026-11-23", "2026-11-30", "2026-12-07"]);
  });
  test("validation", () => {
    expect(() => expandRepeat("2026-11-21", { weekdays: [], weeks: 1 })).toThrow(BookInputError);
    expect(() => expandRepeat("2026-11-21", { weekdays: [7], weeks: 1 })).toThrow(BookInputError);
    expect(() => expandRepeat("2026-11-21", { weekdays: [1], weeks: 27 })).toThrow(BookInputError);
  });
});

describe("plans and items", () => {
  test("weekend plan with several books across days", async () => {
    const plan = await createPlan(db, { title: "Weekend reading", kind: "weekend", startDate: "2026-11-21", endDate: "2026-11-22" });
    const items = await addPlanItems(
      db,
      [
        { bookId: ids.Middlemarch, scheduledDate: "2026-11-21", timeOfDay: "morning", plannedPages: 30 },
        { bookId: ids.Dubliners, scheduledDate: "2026-11-21", timeOfDay: "afternoon", plannedPages: 20 },
        { bookId: ids.Middlemarch, scheduledDate: "2026-11-22", timeOfDay: "morning", plannedPages: 30 },
        { bookId: ids.Dubliners, scheduledDate: "2026-11-22", timeOfDay: "evening", notes: "  one short story " },
      ],
      { planId: plan.planId },
    );
    expect(items).toHaveLength(4);
    expect(items.every((i) => i.planId === plan.planId && i.status === "planned")).toBe(true);
    expect(items[3].notes).toBe("one short story");
  });

  test("createPlanWithItems rolls the empty plan back when items are invalid", async () => {
    await bad(createPlanWithItems(db, { title: "Doomed", kind: "weekend" }, [{ bookId: 999, scheduledDate: "2026-11-21" }]));
    expect((await db.select().from(schema.readingPlans)).length).toBe(0);
    const ok = await createPlanWithItems(db, { title: "Fine", kind: "weekend" }, [{ bookId: ids.Short, scheduledDate: "2026-11-21" }]);
    expect(ok.items[0].planId).toBe(ok.plan.planId);
  });

  test("repeating schedule creates independent items sharing a group", async () => {
    const items = await addPlanItems(db, [{ bookId: ids.Middlemarch, scheduledDate: "2026-11-21", plannedPages: 30 }], {
      repeat: { weekdays: [5, 6], weeks: 2 },
    });
    expect(items.map((i) => i.scheduledDate)).toEqual(["2026-11-21", "2026-11-22", "2026-11-28", "2026-11-29"]);
    expect(new Set(items.map((i) => i.recurrenceGroup)).size).toBe(1);
    await skipPlanItem(db, items[0].itemId); // others unaffected
    expect((await db.select().from(readingPlanItems).where(eq(readingPlanItems.status, "planned"))).length).toBe(3);
  });

  test("validation", async () => {
    await bad(addPlanItems(db, []));
    await bad(addPlanItems(db, [{ bookId: 999, scheduledDate: "2026-11-21" }]));
    await bad(addPlanItems(db, [{ bookId: ids.Short, scheduledDate: "2026-02-31" }]));
    await bad(addPlanItems(db, [{ bookId: ids.Short, scheduledDate: "2026-11-21", plannedPages: -1 }]));
    await bad(addPlanItems(db, [{ bookId: ids.Short, scheduledDate: "2026-11-21", plannedStartPage: 50, plannedEndPage: 10 }]));
    await bad(addPlanItems(db, [{ bookId: ids.Short, scheduledDate: "2026-11-21" }], { planId: 999 }));
    await bad(createPlan(db, { title: "  " }));
    expect(await count_(readingPlanItems)).toBe(0);
  });

  test("update only while planned; skip and reopen are reversible", async () => {
    const [item] = await addPlanItems(db, [{ bookId: ids.Dubliners, scheduledDate: "2026-11-21", plannedPages: 20 }]);
    const u = await updatePlanItem(db, item.itemId, { plannedPages: 25, notes: "after lunch" });
    expect(u).toMatchObject({ plannedPages: 25, notes: "after lunch" });
    await bad(updatePlanItem(db, item.itemId, {}));
    const s = await skipPlanItem(db, item.itemId, "too tired");
    expect(s).toMatchObject({ status: "skipped", notes: "too tired" });
    await bad(updatePlanItem(db, item.itemId, { plannedPages: 1 }));
    expect((await reopenPlanItem(db, item.itemId)).status).toBe("planned");
    await bad(reopenPlanItem(db, item.itemId));
  });

  test("reschedule keeps history and copies the original plan", async () => {
    const [item] = await addPlanItems(db, [{ bookId: ids.Middlemarch, scheduledDate: "2026-11-21", timeOfDay: "morning", plannedPages: 30, notes: "n" }]);
    const moved = await reschedulePlanItem(db, item.itemId, { scheduledDate: "2026-11-23", timeOfDay: "evening" });
    expect(moved).toMatchObject({ scheduledDate: "2026-11-23", timeOfDay: "evening", plannedPages: 30, notes: "n", status: "planned" });
    const [old] = await db.select().from(readingPlanItems).where(eq(readingPlanItems.itemId, item.itemId));
    expect(old).toMatchObject({ status: "rescheduled", rescheduledToItemId: moved.itemId, scheduledDate: "2026-11-21" });
    await bad(reschedulePlanItem(db, item.itemId, { scheduledDate: "2026-11-24" })); // already moved
    await bad(reschedulePlanItem(db, moved.itemId, { scheduledDate: "bad" }));
  });

  test("delete planned items, never completed ones", async () => {
    const [a, b] = await addPlanItems(db, [
      { bookId: ids.Short, scheduledDate: "2026-11-21" },
      { bookId: ids.Short, scheduledDate: "2026-11-22" },
    ]);
    await deletePlanItem(db, a.itemId);
    await completePlanItem(db, b.itemId, { actualPages: 10 });
    await bad(deletePlanItem(db, b.itemId));
    expect(await count_(readingPlanItems)).toBe(1);
  });
});

describe("completePlanItem", () => {
  test("creates exactly one session, updates progress, preserves planned values", async () => {
    const [item] = await addPlanItems(db, [{ bookId: ids.Middlemarch, scheduledDate: "2026-11-21", plannedPages: 30, plannedMinutes: 45 }]);
    const r = await completePlanItem(db, item.itemId, { actualPages: 22, actualMinutes: 40, sessionDate: "2026-11-21" });

    expect(r.created).toBe(true);
    expect(r.item).toMatchObject({ status: "completed", plannedPages: 30, plannedMinutes: 45, actualPages: 22, actualMinutes: 40 });
    expect(r.item.sessionId).not.toBeNull();
    expect(await count_(readingSessions)).toBe(1);
    const [session] = await db.select().from(readingSessions);
    expect(session).toMatchObject({ bookId: ids.Middlemarch, sessionDate: "2026-11-21", pagesRead: 22, minutesRead: 40 });
    expect(session.sessionId).toBe(r.item.sessionId as number);

    const [log] = await db.select().from(readingLog);
    expect(log).toMatchObject({ bookId: ids.Middlemarch, status: "reading", currentPage: 22, dateStarted: "2026-11-21" });
  });

  test("defaults to the planned amounts and the scheduled date", async () => {
    const [item] = await addPlanItems(db, [{ bookId: ids.Dubliners, scheduledDate: "2026-11-22", plannedPages: 20 }]);
    const r = await completePlanItem(db, item.itemId);
    expect(r.item).toMatchObject({ actualPages: 20, plannedPages: 20 });
    const [session] = await db.select().from(readingSessions);
    expect(session).toMatchObject({ pagesRead: 20, sessionDate: "2026-11-22" });
  });

  test("works for items with no amounts at all", async () => {
    const [item] = await addPlanItems(db, [{ bookId: ids.Dubliners, scheduledDate: "2026-11-22", notes: "one short story" }]);
    const r = await completePlanItem(db, item.itemId, { notes: "read The Sisters" });
    expect(r.item.status).toBe("completed");
    expect(await count_(readingSessions)).toBe(1);
  });

  test("accumulates onto existing progress and finishes the book on the last page", async () => {
    await db.insert(readingLog).values({ bookId: ids.Short, status: "reading", currentPage: 40, dateStarted: "2026-11-01" });
    const [item] = await addPlanItems(db, [{ bookId: ids.Short, scheduledDate: "2026-11-21", plannedPages: 20 }]);
    const r = await completePlanItem(db, item.itemId, { actualPages: 25, sessionDate: "2026-11-21" });
    expect(r.bookCompleted).toBe(true);
    const [log] = await db.select().from(readingLog);
    expect(log).toMatchObject({ status: "finished", currentPage: 60, dateStarted: "2026-11-01", dateFinished: "2026-11-21" });
  });

  test("a failure in the last step rolls back the session and progress", async () => {
    const [item] = await addPlanItems(db, [{ bookId: ids.Dubliners, scheduledDate: "2026-11-21", plannedPages: 10 }]);
    // sessionDate is valid, but a negative derived value would be rejected before writing; force a DB failure instead:
    await db.execute(sql`ALTER TABLE reading_plan_items ADD CONSTRAINT force_fail CHECK (actual_pages IS NULL OR actual_pages < 1000)`);
    await expect(completePlanItem(db, item.itemId, { actualPages: 5000 })).rejects.toThrow();
    await db.execute(sql`ALTER TABLE reading_plan_items DROP CONSTRAINT force_fail`);
    expect(await count_(readingSessions)).toBe(0);
    expect((await db.select().from(readingLog)).length).toBe(0);
    expect((await db.select().from(readingPlanItems))[0].status).toBe("planned");
  });

  test("never double-completes: no duplicate sessions", async () => {
    const [item] = await addPlanItems(db, [{ bookId: ids.Short, scheduledDate: "2026-11-21", plannedPages: 5 }]);
    await completePlanItem(db, item.itemId);
    await bad(completePlanItem(db, item.itemId));
    expect(await count_(readingSessions)).toBe(1);
  });

  test("skipped items can still be completed; rescheduled ones cannot", async () => {
    const [a, b] = await addPlanItems(db, [
      { bookId: ids.Short, scheduledDate: "2026-11-21", plannedPages: 5 },
      { bookId: ids.Short, scheduledDate: "2026-11-22", plannedPages: 5 },
    ]);
    await skipPlanItem(db, a.itemId);
    expect((await completePlanItem(db, a.itemId)).item.status).toBe("completed");
    await reschedulePlanItem(db, b.itemId, { scheduledDate: "2026-11-23" });
    await bad(completePlanItem(db, b.itemId));
  });

  test("linkSessionId attaches an existing spontaneous session without creating another", async () => {
    const [session] = await db.insert(readingSessions).values({ bookId: ids.Dubliners, sessionDate: "2026-11-21", pagesRead: 18, minutesRead: 30 }).returning();
    const [item] = await addPlanItems(db, [{ bookId: ids.Dubliners, scheduledDate: "2026-11-21", plannedPages: 20 }]);
    const r = await completePlanItem(db, item.itemId, { linkSessionId: session.sessionId });
    expect(r.created).toBe(false);
    expect(r.item).toMatchObject({ status: "completed", actualPages: 18, actualMinutes: 30, plannedPages: 20, sessionId: session.sessionId });
    expect(await count_(readingSessions)).toBe(1);
    expect((await db.select().from(readingLog)).length).toBe(0); // progress was already applied when it was logged

    const [other] = await addPlanItems(db, [{ bookId: ids.Dubliners, scheduledDate: "2026-11-22" }]);
    await bad(completePlanItem(db, other.itemId, { linkSessionId: session.sessionId })); // already linked
    await bad(completePlanItem(db, other.itemId, { linkSessionId: 9999 }));
    const [wrongBook] = await db.insert(readingSessions).values({ bookId: ids.Short, sessionDate: "2026-11-21" }).returning();
    await bad(completePlanItem(db, other.itemId, { linkSessionId: wrongBook.sessionId }));
  });

  test("deleting the session later keeps the completed item and its actuals", async () => {
    const [item] = await addPlanItems(db, [{ bookId: ids.Dubliners, scheduledDate: "2026-11-21", plannedPages: 20 }]);
    const r = await completePlanItem(db, item.itemId, { actualPages: 12 });
    await db.delete(readingSessions).where(eq(readingSessions.sessionId, r.item.sessionId!));
    const [after] = await db.select().from(readingPlanItems);
    expect(after).toMatchObject({ status: "completed", actualPages: 12, sessionId: null });
  });
});

describe("getPlannerRange", () => {
  test("returns plan items, sessions, target dates and finished books for the range", async () => {
    const [a, b] = await addPlanItems(db, [
      { bookId: ids.Middlemarch, scheduledDate: "2026-11-21", timeOfDay: "afternoon", plannedPages: 30 },
      { bookId: ids.Dubliners, scheduledDate: "2026-11-21", timeOfDay: "morning", plannedPages: 20 },
      { bookId: ids.Short, scheduledDate: "2026-12-30" }, // outside the range
    ]);
    await completePlanItem(db, a.itemId, { actualPages: 28, sessionDate: "2026-11-21" });
    await db.insert(readingSessions).values({ bookId: ids.Short, sessionDate: "2026-11-22", pagesRead: 10 });
    await setPriority(db, { bookId: ids.Middlemarch, level: "high", targetDate: "2026-11-30" });
    await db.insert(readingLog).values({ bookId: ids.Short, status: "finished", dateFinished: "2026-11-25", rating: 4 });

    const r = await getPlannerRange(db, "2026-11-16", "2026-11-30");
    expect(r.items.map((i) => i.title)).toEqual(["Dubliners", "Middlemarch"]); // morning before afternoon
    expect(r.items.find((i) => i.title === "Middlemarch")!.item.status).toBe("completed");
    expect(r.sessions).toHaveLength(2);
    expect(r.sessions.find((s) => s.title === "Middlemarch")!.linkedItemId).toBe(a.itemId);
    expect(r.sessions.find((s) => s.title === "Short")!.linkedItemId).toBeNull(); // spontaneous
    expect(r.targets).toEqual([expect.objectContaining({ title: "Middlemarch", targetDate: "2026-11-30", level: "high" })]);
    expect(r.finished).toEqual([expect.objectContaining({ title: "Short", dateFinished: "2026-11-25", rating: 4 })]);
    expect(b.itemId).toBeGreaterThan(0);
  });

  test("validation", async () => {
    await bad(getPlannerRange(db, "nope", "2026-11-30"));
    await bad(getPlannerRange(db, "2026-12-01", "2026-11-30"));
  });
});
