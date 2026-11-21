import { and, asc, eq, inArray, sql } from "drizzle-orm";
import {
  books,
  readingLog,
  readingPlanItems,
  readingPlans,
  readingPriorities,
  readingPriorityHistory,
  readingSessions,
  weeklyReadingReviews,
} from "./schema";
import { BookInputError, runAtomic } from "./book-writes";
import { computeLogUpdate } from "./reading-progress";
import { addDays, isDateKey, weekStartKey, weekdayIndex } from "@/lib/dates";
import { getWeekSummary } from "./planning-reads";

export { getPriorityChanges, type PriorityChange } from "./planning-reads";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyDb = any;

// ============================================================================
// PRIORITIES
// A priority is not a reading status. Nothing here ever changes a priority
// unless the caller explicitly asks for it.
// ============================================================================

export const PRIORITY_LEVELS = ["critical", "high", "medium", "low"] as const;
export type PriorityLevel = (typeof PRIORITY_LEVELS)[number];

export interface SetPriorityInput {
  bookId: number;
  level?: PriorityLevel;
  /** undefined = unchanged, "" or null = clear */
  reason?: string | null;
  targetDate?: string | null;
  estimatedMinutes?: number | null;
}

async function requireBook(database: AnyDb, bookId: number) {
  if (!Number.isInteger(bookId)) throw new BookInputError("bookId must be an integer");
  const [book] = await database
    .select({ bookId: books.bookId, title: books.title, pages: books.pages })
    .from(books)
    .where(eq(books.bookId, bookId))
    .limit(1);
  if (!book) throw new BookInputError(`Book ${bookId} not found`);
  return book as { bookId: number; title: string; pages: number | null };
}

function validatePriorityFields(input: SetPriorityInput) {
  if (input.level !== undefined && !PRIORITY_LEVELS.includes(input.level)) {
    throw new BookInputError(`Invalid level "${input.level}". Use one of: ${PRIORITY_LEVELS.join(", ")}`);
  }
  if (input.targetDate !== undefined && input.targetDate !== null && !isDateKey(input.targetDate)) {
    throw new BookInputError("targetDate must be a valid YYYY-MM-DD date");
  }
  const m = input.estimatedMinutes;
  if (m !== undefined && m !== null && (!Number.isInteger(m) || m <= 0)) {
    throw new BookInputError("estimatedMinutes must be a positive integer");
  }
}

/**
 * Create the book's active priority, or update it. Only provided fields change.
 * Level changes are written to reading_priority_history in the same transaction.
 */
export async function setPriority(database: AnyDb, input: SetPriorityInput) {
  validatePriorityFields(input);
  await requireBook(database, input.bookId);

  const [active] = await database
    .select()
    .from(readingPriorities)
    .where(and(eq(readingPriorities.bookId, input.bookId), eq(readingPriorities.status, "active")))
    .limit(1);

  const changes: Partial<typeof readingPriorities.$inferInsert> = {};
  if (input.level !== undefined) changes.level = input.level;
  if (input.reason !== undefined) changes.reason = input.reason?.trim() || null;
  if (input.targetDate !== undefined) changes.targetDate = input.targetDate || null;
  if (input.estimatedMinutes !== undefined) changes.estimatedMinutes = input.estimatedMinutes ?? null;

  if (!active) {
    const level = input.level ?? "medium";
    const results = await runAtomic(database, (d) => [
      d.insert(readingPriorities).values({ bookId: input.bookId, ...changes, level, status: "active" }).returning(),
      d.insert(readingPriorityHistory).values({ bookId: input.bookId, fromLevel: null, toLevel: level, fromStatus: null, toStatus: "active" }),
    ]);
    return (results[0] as unknown[])[0] as typeof readingPriorities.$inferSelect;
  }

  if (Object.keys(changes).length === 0) throw new BookInputError("Nothing to update");
  const levelChanged = changes.level !== undefined && changes.level !== active.level;
  const results = await runAtomic(database, (d) => [
    d
      .update(readingPriorities)
      .set({ ...changes, updatedAt: new Date() })
      .where(eq(readingPriorities.priorityId, active.priorityId))
      .returning(),
    ...(levelChanged
      ? [d.insert(readingPriorityHistory).values({ bookId: input.bookId, fromLevel: active.level, toLevel: changes.level, fromStatus: "active", toStatus: "active" })]
      : []),
  ]);
  return (results[0] as unknown[])[0] as typeof readingPriorities.$inferSelect;
}

/** Close the active priority as completed or cancelled (explicit user action). */
export async function closePriority(database: AnyDb, bookId: number, status: "completed" | "cancelled") {
  await requireBook(database, bookId);
  const [active] = await database
    .select()
    .from(readingPriorities)
    .where(and(eq(readingPriorities.bookId, bookId), eq(readingPriorities.status, "active")))
    .limit(1);
  if (!active) throw new BookInputError(`Book ${bookId} has no active priority`);

  const results = await runAtomic(database, (d) => [
    d.update(readingPriorities).set({ status, updatedAt: new Date() }).where(eq(readingPriorities.priorityId, active.priorityId)).returning(),
    d.insert(readingPriorityHistory).values({ bookId, fromLevel: active.level, toLevel: active.level, fromStatus: "active", toStatus: status }),
  ]);
  return (results[0] as unknown[])[0] as typeof readingPriorities.$inferSelect;
}

export const completePriority = (database: AnyDb, bookId: number) => closePriority(database, bookId, "completed");
export const cancelPriority = (database: AnyDb, bookId: number) => closePriority(database, bookId, "cancelled");

const LEVEL_RANK = sql`CASE ${readingPriorities.level} WHEN 'critical' THEN 0 WHEN 'high' THEN 1 WHEN 'medium' THEN 2 ELSE 3 END`;

export interface PriorityRow {
  priority: typeof readingPriorities.$inferSelect;
  bookId: number;
  title: string;
  pages: number | null;
  readingStatus: string | null;
  currentPage: number | null;
  authors: string | null;
  coverUrl: string | null;
}

export async function listPriorities(
  database: AnyDb,
  opts: { status?: "active" | "completed" | "cancelled" | "all" } = {},
): Promise<PriorityRow[]> {
  const status = opts.status ?? "active";
  const rows = await database
    .select({
      priority: readingPriorities,
      bookId: books.bookId,
      title: books.title,
      pages: books.pages,
      readingStatus: sql<string | null>`(SELECT rl.status FROM reading_log rl WHERE rl.book_id = ${books.bookId})`,
      currentPage: sql<number | null>`(SELECT rl.current_page FROM reading_log rl WHERE rl.book_id = ${books.bookId})`,
      authors: sql<string | null>`(SELECT string_agg(a.name, ', ' ORDER BY ba.author_order) FROM book_authors ba JOIN authors a ON a.author_id = ba.author_id WHERE ba.book_id = ${books.bookId})`,
      coverUrl: sql<string | null>`(SELECT g.cover_url FROM goodreads_data g WHERE g.book_id = ${books.bookId})`,
    })
    .from(readingPriorities)
    .innerJoin(books, eq(readingPriorities.bookId, books.bookId))
    .where(status === "all" ? undefined : eq(readingPriorities.status, status))
    .orderBy(asc(LEVEL_RANK), sql`${readingPriorities.targetDate} ASC NULLS LAST`, asc(readingPriorities.priorityId));
  return rows as PriorityRow[];
}

// ============================================================================
// READING PLANS
// planned_* is the original intent and is never overwritten. What happened is
// stored in actual_* and in the linked reading_sessions row.
// ============================================================================

export const TIMES_OF_DAY = ["morning", "afternoon", "evening", "anytime"] as const;
export type TimeOfDay = (typeof TIMES_OF_DAY)[number];
export const PLAN_KINDS = ["daily", "weekly", "weekend", "custom"] as const;
export type PlanKind = (typeof PLAN_KINDS)[number];

export interface PlanItemInput {
  bookId: number;
  scheduledDate: string;
  timeOfDay?: TimeOfDay;
  plannedPages?: number | null;
  plannedMinutes?: number | null;
  plannedStartPage?: number | null;
  plannedEndPage?: number | null;
  notes?: string | null;
}

/** Repeat on these weekdays (0 = Monday ... 6 = Sunday) for N weeks starting at the item's date. */
export interface RepeatRule {
  weekdays: number[];
  weeks: number;
}

const MAX_ITEMS_PER_CALL = 200;
const MAX_REPEAT_WEEKS = 26;

const nonNegInt = (v: unknown) => v === undefined || v === null || (Number.isInteger(v) && (v as number) >= 0);

function validateItemInput(i: PlanItemInput) {
  if (!Number.isInteger(i.bookId)) throw new BookInputError("bookId must be an integer");
  if (!isDateKey(i.scheduledDate)) throw new BookInputError("scheduledDate must be a valid YYYY-MM-DD date");
  if (i.timeOfDay !== undefined && !TIMES_OF_DAY.includes(i.timeOfDay)) {
    throw new BookInputError(`Invalid timeOfDay. Use one of: ${TIMES_OF_DAY.join(", ")}`);
  }
  for (const [k, v] of Object.entries({
    plannedPages: i.plannedPages,
    plannedMinutes: i.plannedMinutes,
    plannedStartPage: i.plannedStartPage,
    plannedEndPage: i.plannedEndPage,
  })) {
    if (!nonNegInt(v)) throw new BookInputError(`${k} must be a non-negative integer`);
  }
  if (i.plannedStartPage != null && i.plannedEndPage != null && i.plannedEndPage < i.plannedStartPage) {
    throw new BookInputError("plannedEndPage must be on or after plannedStartPage");
  }
}

/** Dates a repeat rule produces, starting at `start` (inclusive) and covering `weeks` weeks. */
export function expandRepeat(start: string, repeat: RepeatRule): string[] {
  const weekdays = [...new Set(repeat.weekdays)];
  if (weekdays.length === 0 || weekdays.some((d) => !Number.isInteger(d) || d < 0 || d > 6)) {
    throw new BookInputError("repeat.weekdays must contain days 0 (Mon) to 6 (Sun)");
  }
  if (!Number.isInteger(repeat.weeks) || repeat.weeks < 1 || repeat.weeks > MAX_REPEAT_WEEKS) {
    throw new BookInputError(`repeat.weeks must be between 1 and ${MAX_REPEAT_WEEKS}`);
  }
  const out: string[] = [];
  for (let d = 0; d < repeat.weeks * 7; d++) {
    const date = addDays(start, d);
    if (weekdays.includes(weekdayIndex(date))) out.push(date);
  }
  if (out.length === 0) throw new BookInputError("The repeat rule produces no dates");
  return out;
}

export interface CreatePlanInput {
  title: string;
  kind?: PlanKind;
  startDate?: string | null;
  endDate?: string | null;
  notes?: string | null;
}

export async function createPlan(database: AnyDb, input: CreatePlanInput) {
  const title = input.title?.trim();
  if (!title) throw new BookInputError("Plan title is required");
  if (input.kind !== undefined && !PLAN_KINDS.includes(input.kind)) throw new BookInputError("Invalid plan kind");
  for (const [k, v] of [["startDate", input.startDate], ["endDate", input.endDate]] as const) {
    if (v && !isDateKey(v)) throw new BookInputError(`${k} must be a valid YYYY-MM-DD date`);
  }
  if (input.startDate && input.endDate && input.endDate < input.startDate) {
    throw new BookInputError("endDate must be on or after startDate");
  }
  const [plan] = await database
    .insert(readingPlans)
    .values({
      title,
      kind: input.kind ?? "custom",
      startDate: input.startDate || null,
      endDate: input.endDate || null,
      notes: input.notes?.trim() || null,
    })
    .returning();
  return plan as typeof readingPlans.$inferSelect;
}

/**
 * Schedule reading. Every item may be expanded by `opts.repeat` into one item
 * per matching date (all share a recurrence_group so they can be found later).
 * Items stay independent afterwards: nothing forces the schedule.
 */
export async function addPlanItems(
  database: AnyDb,
  items: PlanItemInput[],
  opts: { planId?: number | null; repeat?: RepeatRule } = {},
) {
  if (!Array.isArray(items) || items.length === 0) throw new BookInputError("Provide at least one item");
  items.forEach(validateItemInput);

  const bookIds = [...new Set(items.map((i) => i.bookId))];
  const found = await database.select({ id: books.bookId }).from(books).where(inArray(books.bookId, bookIds));
  const have = new Set<number>(found.map((r: { id: number }) => r.id));
  const missing = bookIds.filter((id) => !have.has(id));
  if (missing.length) throw new BookInputError(`Book id(s) not found: ${missing.join(", ")}`);

  if (opts.planId != null) {
    const [plan] = await database.select({ id: readingPlans.planId }).from(readingPlans).where(eq(readingPlans.planId, opts.planId)).limit(1);
    if (!plan) throw new BookInputError(`Plan ${opts.planId} not found`);
  }

  const group = opts.repeat ? crypto.randomUUID().slice(0, 8) : null;
  const rows = items.flatMap((i) =>
    (opts.repeat ? expandRepeat(i.scheduledDate, opts.repeat) : [i.scheduledDate]).map((scheduledDate) => ({
      planId: opts.planId ?? null,
      bookId: i.bookId,
      scheduledDate,
      timeOfDay: i.timeOfDay ?? "anytime",
      plannedPages: i.plannedPages ?? null,
      plannedMinutes: i.plannedMinutes ?? null,
      plannedStartPage: i.plannedStartPage ?? null,
      plannedEndPage: i.plannedEndPage ?? null,
      notes: i.notes?.trim() || null,
      recurrenceGroup: group,
    })),
  );
  if (rows.length > MAX_ITEMS_PER_CALL) throw new BookInputError(`Too many items (max ${MAX_ITEMS_PER_CALL} per call)`);

  const created = await database.insert(readingPlanItems).values(rows).returning();
  return created as (typeof readingPlanItems.$inferSelect)[];
}

async function requireItem(database: AnyDb, itemId: number) {
  if (!Number.isInteger(itemId)) throw new BookInputError("itemId must be an integer");
  const [item] = await database.select().from(readingPlanItems).where(eq(readingPlanItems.itemId, itemId)).limit(1);
  if (!item) throw new BookInputError(`Plan item ${itemId} not found`);
  return item as typeof readingPlanItems.$inferSelect;
}

export interface UpdatePlanItemInput {
  timeOfDay?: TimeOfDay;
  plannedPages?: number | null;
  plannedMinutes?: number | null;
  plannedStartPage?: number | null;
  plannedEndPage?: number | null;
  notes?: string | null;
}

/** Edit what is still planned. Completed items keep their original plan (use reschedule to move dates). */
export async function updatePlanItem(database: AnyDb, itemId: number, patch: UpdatePlanItemInput) {
  const item = await requireItem(database, itemId);
  if (item.status !== "planned") throw new BookInputError(`Only planned items can be edited (this one is ${item.status})`);
  validateItemInput({ bookId: item.bookId, scheduledDate: item.scheduledDate, ...patch });

  const changes: Partial<typeof readingPlanItems.$inferInsert> = {};
  if (patch.timeOfDay !== undefined) changes.timeOfDay = patch.timeOfDay;
  if (patch.plannedPages !== undefined) changes.plannedPages = patch.plannedPages;
  if (patch.plannedMinutes !== undefined) changes.plannedMinutes = patch.plannedMinutes;
  if (patch.plannedStartPage !== undefined) changes.plannedStartPage = patch.plannedStartPage;
  if (patch.plannedEndPage !== undefined) changes.plannedEndPage = patch.plannedEndPage;
  if (patch.notes !== undefined) changes.notes = patch.notes?.trim() || null;
  if (Object.keys(changes).length === 0) throw new BookInputError("Nothing to update");

  const [updated] = await database
    .update(readingPlanItems)
    .set({ ...changes, updatedAt: new Date() })
    .where(eq(readingPlanItems.itemId, itemId))
    .returning();
  return updated as typeof readingPlanItems.$inferSelect;
}

/** Skipping is not failing: it is reversible with reopenPlanItem. */
export async function skipPlanItem(database: AnyDb, itemId: number, note?: string) {
  const item = await requireItem(database, itemId);
  if (item.status !== "planned") throw new BookInputError(`Only planned items can be skipped (this one is ${item.status})`);
  const [updated] = await database
    .update(readingPlanItems)
    .set({ status: "skipped", notes: note?.trim() ? note.trim() : item.notes, updatedAt: new Date() })
    .where(eq(readingPlanItems.itemId, itemId))
    .returning();
  return updated as typeof readingPlanItems.$inferSelect;
}

export async function reopenPlanItem(database: AnyDb, itemId: number) {
  const item = await requireItem(database, itemId);
  if (item.status !== "skipped") throw new BookInputError(`Only skipped items can be reopened (this one is ${item.status})`);
  const [updated] = await database
    .update(readingPlanItems)
    .set({ status: "planned", updatedAt: new Date() })
    .where(eq(readingPlanItems.itemId, itemId))
    .returning();
  return updated as typeof readingPlanItems.$inferSelect;
}

/**
 * Move an item to another day. The original stays as history (status
 * "rescheduled", pointing at its replacement); the replacement copies the
 * original plan.
 */
export async function reschedulePlanItem(
  database: AnyDb,
  itemId: number,
  target: { scheduledDate: string; timeOfDay?: TimeOfDay },
) {
  const item = await requireItem(database, itemId);
  if (item.status !== "planned" && item.status !== "skipped") {
    throw new BookInputError(`Only planned or skipped items can be rescheduled (this one is ${item.status})`);
  }
  if (!isDateKey(target.scheduledDate)) throw new BookInputError("scheduledDate must be a valid YYYY-MM-DD date");
  if (target.timeOfDay !== undefined && !TIMES_OF_DAY.includes(target.timeOfDay)) throw new BookInputError("Invalid timeOfDay");

  const seq = sql`currval(pg_get_serial_sequence('reading_plan_items', 'item_id')::regclass)`;
  const results = await runAtomic(database, (d) => [
    d
      .insert(readingPlanItems)
      .values({
        planId: item.planId,
        bookId: item.bookId,
        scheduledDate: target.scheduledDate,
        timeOfDay: target.timeOfDay ?? item.timeOfDay,
        plannedPages: item.plannedPages,
        plannedMinutes: item.plannedMinutes,
        plannedStartPage: item.plannedStartPage,
        plannedEndPage: item.plannedEndPage,
        notes: item.notes,
        recurrenceGroup: item.recurrenceGroup,
      })
      .returning(),
    d
      .update(readingPlanItems)
      .set({ status: "rescheduled", rescheduledToItemId: seq, updatedAt: new Date() })
      .where(eq(readingPlanItems.itemId, itemId)),
  ]);
  return (results[0] as unknown[])[0] as typeof readingPlanItems.$inferSelect;
}

export async function deletePlanItem(database: AnyDb, itemId: number) {
  const item = await requireItem(database, itemId);
  if (item.status === "completed") throw new BookInputError("Completed items are part of your reading history and cannot be deleted");
  await database.delete(readingPlanItems).where(eq(readingPlanItems.itemId, itemId));
  return { itemId };
}

export interface CompletePlanItemInput {
  actualPages?: number;
  actualMinutes?: number;
  startPage?: number;
  endPage?: number;
  /** The day the reading actually happened (default: the scheduled date). */
  sessionDate?: string;
  notes?: string;
  /** Attach a reading session that was already logged instead of creating one. */
  linkSessionId?: number;
}

/**
 * Complete a planned activity without ever duplicating a reading session:
 * either links an existing session, or creates exactly one. Progress on the
 * book is updated with the same rules as logging a session directly.
 * Everything is one transaction; planned_* values are left untouched.
 */
export async function completePlanItem(database: AnyDb, itemId: number, input: CompletePlanItemInput = {}) {
  const item = await requireItem(database, itemId);
  if (item.status === "completed" || item.sessionId) throw new BookInputError("This item is already completed");
  if (item.status === "rescheduled") throw new BookInputError("This item was rescheduled; complete its replacement instead");

  // ---- link an already-logged session: no new session, no progress change
  if (input.linkSessionId !== undefined) {
    const [session] = await database.select().from(readingSessions).where(eq(readingSessions.sessionId, input.linkSessionId)).limit(1);
    if (!session) throw new BookInputError(`Reading session ${input.linkSessionId} not found`);
    if (session.bookId !== item.bookId) throw new BookInputError("That session belongs to a different book");
    const [taken] = await database
      .select({ id: readingPlanItems.itemId })
      .from(readingPlanItems)
      .where(eq(readingPlanItems.sessionId, input.linkSessionId))
      .limit(1);
    if (taken) throw new BookInputError("That session is already linked to another plan item");

    const [updated] = await database
      .update(readingPlanItems)
      .set({
        status: "completed",
        actualPages: session.pagesRead ?? null,
        actualMinutes: session.minutesRead ?? null,
        sessionId: session.sessionId,
        completedAt: new Date(),
        updatedAt: new Date(),
      })
      .where(eq(readingPlanItems.itemId, itemId))
      .returning();
    return { item: updated as typeof readingPlanItems.$inferSelect, session, bookCompleted: false, created: false };
  }

  // ---- create exactly one session
  const sessionDate = input.sessionDate ?? item.scheduledDate;
  if (!isDateKey(sessionDate)) throw new BookInputError("sessionDate must be a valid YYYY-MM-DD date");

  const derivedPages =
    input.startPage != null && input.endPage != null && input.endPage >= input.startPage
      ? input.endPage - input.startPage + 1
      : undefined;
  const pagesRead = input.actualPages ?? derivedPages ?? item.plannedPages ?? 0;
  const minutesRead = input.actualMinutes ?? item.plannedMinutes ?? null;
  for (const [k, v] of [["actualPages", pagesRead], ["actualMinutes", minutesRead], ["startPage", input.startPage], ["endPage", input.endPage]] as const) {
    if (!nonNegInt(v)) throw new BookInputError(`${k} must be a non-negative integer`);
  }

  const [book] = await database.select({ pages: books.pages }).from(books).where(eq(books.bookId, item.bookId)).limit(1);
  const [prevLog] = await database.select().from(readingLog).where(eq(readingLog.bookId, item.bookId)).limit(1);
  const update = computeLogUpdate(prevLog, book?.pages, pagesRead, sessionDate);

  const logValues = {
    currentPage: update.currentPage,
    status: update.status,
    dateStarted: update.dateStarted,
    ...(update.dateFinished ? { dateFinished: update.dateFinished } : {}),
  };
  const seq = sql`currval(pg_get_serial_sequence('reading_sessions', 'session_id')::regclass)`;

  const results = await runAtomic(database, (d) => [
    d
      .insert(readingSessions)
      .values({
        bookId: item.bookId,
        sessionDate,
        pagesRead,
        minutesRead,
        startPage: input.startPage ?? item.plannedStartPage ?? null,
        endPage: input.endPage ?? item.plannedEndPage ?? null,
        notes: input.notes?.trim() || null,
      })
      .returning(),
    d
      .insert(readingLog)
      .values({ bookId: item.bookId, ...logValues })
      .onConflictDoUpdate({ target: readingLog.bookId, set: { ...logValues, updatedAt: new Date() } }),
    d
      .update(readingPlanItems)
      .set({
        status: "completed",
        actualPages: pagesRead,
        actualMinutes: minutesRead,
        sessionId: seq,
        completedAt: new Date(),
        updatedAt: new Date(),
      })
      .where(eq(readingPlanItems.itemId, itemId)),
  ]);

  const session = (results[0] as unknown[])[0];
  const [done] = await database.select().from(readingPlanItems).where(eq(readingPlanItems.itemId, itemId)).limit(1);
  return { item: done as typeof readingPlanItems.$inferSelect, session, bookCompleted: update.isCompleted, created: true };
}

/** Create a plan (e.g. "Weekend reading") together with its items; removes the empty plan if the items are invalid. */
export async function createPlanWithItems(
  database: AnyDb,
  plan: CreatePlanInput,
  items: PlanItemInput[],
  repeat?: RepeatRule,
) {
  const created = await createPlan(database, plan);
  try {
    const rows = await addPlanItems(database, items, { planId: created.planId, repeat });
    return { plan: created, items: rows };
  } catch (error) {
    await database.delete(readingPlans).where(eq(readingPlans.planId, created.planId));
    throw error;
  }
}

// ============================================================================
// WEEKLY REVIEW
// ============================================================================

export interface SaveWeeklyReviewInput {
  /** Any date in the week; normalized to that week's Monday. */
  weekStart: string;
  /** undefined = keep what was saved, "" = clear */
  wentWell?: string;
  blockers?: string;
  nextWeekChanges?: string;
}

const MAX_REFLECTION = 4000;

/**
 * Save the reflection for a week and snapshot the week's numbers, so the
 * history keeps showing what the week looked like when it was reviewed.
 */
export async function saveWeeklyReview(database: AnyDb, input: SaveWeeklyReviewInput) {
  if (!isDateKey(input.weekStart)) throw new BookInputError("weekStart must be a valid YYYY-MM-DD date");
  for (const k of ["wentWell", "blockers", "nextWeekChanges"] as const) {
    if ((input[k]?.length ?? 0) > MAX_REFLECTION) throw new BookInputError(`${k} is too long (max ${MAX_REFLECTION} characters)`);
  }
  const weekStart = weekStartKey(input.weekStart);
  const summary = await getWeekSummary(database, weekStart);

  const clean = (v: string | undefined) => (v === undefined ? undefined : v.trim() || null);
  const reflections = {
    ...(input.wentWell !== undefined ? { wentWell: clean(input.wentWell) } : {}),
    ...(input.blockers !== undefined ? { blockers: clean(input.blockers) } : {}),
    ...(input.nextWeekChanges !== undefined ? { nextWeekChanges: clean(input.nextWeekChanges) } : {}),
  };
  const snapshot = {
    plannedItems: summary.activities.total,
    completedItems: summary.activities.completed,
    skippedItems: summary.activities.skipped,
    plannedPages: summary.pages.planned,
    actualPages: summary.pages.actualFromPlans,
    totalPagesRead: summary.pages.totalRead,
    totalMinutes: summary.minutesRead,
    booksCompleted: summary.booksCompleted.length,
  };

  const [saved] = await database
    .insert(weeklyReadingReviews)
    .values({ weekStart, ...reflections, ...snapshot })
    .onConflictDoUpdate({
      target: weeklyReadingReviews.weekStart,
      set: { ...reflections, ...snapshot, updatedAt: new Date() },
    })
    .returning();
  return saved as typeof weeklyReadingReviews.$inferSelect;
}
