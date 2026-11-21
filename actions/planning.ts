import { createServerFn } from "@tanstack/react-start";
import { db } from "@/lib/db";
import { BookInputError } from "@/lib/db/book-writes";
import { getPlannerRange, getWeekSummary, listWeeklyReviews } from "@/lib/db/planning-reads";
import {
  addPlanItems,
  cancelPriority,
  completePlanItem,
  completePriority,
  createPlanWithItems,
  deletePlanItem,
  getPriorityChanges,
  listPriorities,
  reopenPlanItem,
  reschedulePlanItem,
  saveWeeklyReview,
  setPriority,
  skipPlanItem,
  updatePlanItem,
  type CompletePlanItemInput,
  type CreatePlanInput,
  type PlanItemInput,
  type RepeatRule,
  type SaveWeeklyReviewInput,
  type SetPriorityInput,
  type TimeOfDay,
  type UpdatePlanItemInput,
} from "@/lib/db/planning-writes";

// Server functions for the reading-planning feature. Keep all DB work inside
// handlers so none of it is bundled into the browser.

type Result<T> = { success: true; data: T } | { success: false; error: string };

async function wrap<T>(fn: () => Promise<T>): Promise<Result<T>> {
  try {
    return { success: true, data: await fn() };
  } catch (error) {
    if (error instanceof BookInputError) return { success: false, error: error.message };
    console.error("Planning action failed:", error);
    return { success: false, error: "Something went wrong. Please try again." };
  }
}

// ---------------------------------------------------------------- priorities
export const getPrioritiesAction = createServerFn({ method: "GET" })
  .validator((d: { status?: "active" | "completed" | "cancelled" | "all" } | undefined) => d ?? {})
  .handler(({ data }) => wrap(() => listPriorities(db, { status: data.status })));

export const getPriorityChangesAction = createServerFn({ method: "GET" })
  .validator((d: { sinceDate?: string; limit?: number } | undefined) => d ?? {})
  .handler(({ data }) => wrap(() => getPriorityChanges(db, data)));

export const setPriorityAction = createServerFn({ method: "POST" })
  .validator((d: SetPriorityInput) => d)
  .handler(({ data }) => wrap(() => setPriority(db, data)));

export const completePriorityAction = createServerFn({ method: "POST" })
  .validator((d: { bookId: number }) => d)
  .handler(({ data }) => wrap(() => completePriority(db, data.bookId)));

export const cancelPriorityAction = createServerFn({ method: "POST" })
  .validator((d: { bookId: number }) => d)
  .handler(({ data }) => wrap(() => cancelPriority(db, data.bookId)));

// ------------------------------------------------------------------- planner
export const getPlannerRangeAction = createServerFn({ method: "GET" })
  .validator((d: { from: string; to: string }) => d)
  .handler(({ data }) => wrap(() => getPlannerRange(db, data.from, data.to)));

export const addPlanItemsAction = createServerFn({ method: "POST" })
  .validator((d: { items: PlanItemInput[]; repeat?: RepeatRule; plan?: CreatePlanInput }) => d)
  .handler(({ data }) =>
    wrap(async () => {
      if (data.plan) return (await createPlanWithItems(db, data.plan, data.items, data.repeat)).items;
      return addPlanItems(db, data.items, { repeat: data.repeat });
    }),
  );

export const updatePlanItemAction = createServerFn({ method: "POST" })
  .validator((d: { itemId: number; patch: UpdatePlanItemInput }) => d)
  .handler(({ data }) => wrap(() => updatePlanItem(db, data.itemId, data.patch)));

export const skipPlanItemAction = createServerFn({ method: "POST" })
  .validator((d: { itemId: number; note?: string }) => d)
  .handler(({ data }) => wrap(() => skipPlanItem(db, data.itemId, data.note)));

export const reopenPlanItemAction = createServerFn({ method: "POST" })
  .validator((d: { itemId: number }) => d)
  .handler(({ data }) => wrap(() => reopenPlanItem(db, data.itemId)));

export const reschedulePlanItemAction = createServerFn({ method: "POST" })
  .validator((d: { itemId: number; scheduledDate: string; timeOfDay?: TimeOfDay }) => d)
  .handler(({ data }) =>
    wrap(() => reschedulePlanItem(db, data.itemId, { scheduledDate: data.scheduledDate, timeOfDay: data.timeOfDay })),
  );

export const deletePlanItemAction = createServerFn({ method: "POST" })
  .validator((d: { itemId: number }) => d)
  .handler(({ data }) => wrap(() => deletePlanItem(db, data.itemId)));

export const completePlanItemAction = createServerFn({ method: "POST" })
  .validator((d: { itemId: number } & CompletePlanItemInput) => d)
  .handler(({ data }) => {
    const { itemId, ...input } = data;
    return wrap(() => completePlanItem(db, itemId, input));
  });

// -------------------------------------------------------------- weekly review
export const getWeekSummaryAction = createServerFn({ method: "GET" })
  .validator((d: { weekStart: string }) => d)
  .handler(({ data }) => wrap(() => getWeekSummary(db, data.weekStart)));

export const getWeeklyReviewsAction = createServerFn({ method: "GET" })
  .validator((d: { limit?: number } | undefined) => d ?? {})
  .handler(({ data }) => wrap(() => listWeeklyReviews(db, data.limit)));

export const saveWeeklyReviewAction = createServerFn({ method: "POST" })
  .validator((d: SaveWeeklyReviewInput) => d)
  .handler(({ data }) => wrap(() => saveWeeklyReview(db, data)));
