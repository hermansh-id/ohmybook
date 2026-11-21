import { createServerFn } from "@tanstack/react-start";
import { db } from "@/lib/db";
import { BookInputError } from "@/lib/db/book-writes";
import {
  cancelPriority,
  completePriority,
  getPriorityChanges,
  listPriorities,
  setPriority,
  type SetPriorityInput,
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
