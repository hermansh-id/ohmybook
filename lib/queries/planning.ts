"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import {
  addPlanItemsAction,
  cancelPriorityAction,
  completePlanItemAction,
  completePriorityAction,
  deletePlanItemAction,
  getPlannerRangeAction,
  getPrioritiesAction,
  getPriorityChangesAction,
  getWeekSummaryAction,
  getWeeklyReviewsAction,
  reopenPlanItemAction,
  reschedulePlanItemAction,
  saveWeeklyReviewAction,
  setPriorityAction,
  skipPlanItemAction,
  updatePlanItemAction,
} from "@/actions/planning";

type Result<T> = { success: true; data: T } | { success: false; error: string };

function unwrap<T>(result: Result<T>): T {
  if (!result.success) throw new Error(result.error);
  return result.data;
}

export const planningKeys = {
  priorities: ["priorities"] as const,
  priorityChanges: ["priority-changes"] as const,
  planner: ["planner"] as const,
};

/** Everything a planning change can affect. */
const RELATED_KEYS = [
  ["priorities"],
  ["priority-changes"],
  ["planner"],
  ["reading-focus"],
  ["weekly-review"],
  ["recommendations"],
  ["reading-sessions"],
  ["dashboard"],
  ["unfinished-books"],
] as const;

export function useInvalidatePlanning() {
  const queryClient = useQueryClient();
  return () => Promise.all(RELATED_KEYS.map((queryKey) => queryClient.invalidateQueries({ queryKey: [...queryKey] })));
}

/** Mutation that unwraps the {success,error} envelope, toasts, and refreshes related data. */
export function usePlanningMutation<TVars, TData>(
  fn: (vars: TVars) => Promise<Result<TData>>,
  opts: { success?: string | ((data: TData) => string) } = {},
) {
  const invalidate = useInvalidatePlanning();
  return useMutation({
    mutationFn: async (vars: TVars) => unwrap(await fn(vars)),
    onSuccess: async (data) => {
      await invalidate();
      const msg = typeof opts.success === "function" ? opts.success(data) : opts.success;
      if (msg) toast.success(msg);
    },
    onError: (error: Error) => toast.error(error.message || "Something went wrong"),
  });
}

// ---------------------------------------------------------------- priorities
export function usePriorities(status: "active" | "completed" | "cancelled" | "all" = "active") {
  return useQuery({
    queryKey: [...planningKeys.priorities, status],
    queryFn: async () => unwrap(await getPrioritiesAction({ data: { status } })),
    staleTime: 1000 * 30,
  });
}

export function usePriorityChanges(limit = 20) {
  return useQuery({
    queryKey: [...planningKeys.priorityChanges, limit],
    queryFn: async () => unwrap(await getPriorityChangesAction({ data: { limit } })),
    staleTime: 1000 * 30,
  });
}

export const useSetPriority = () =>
  usePlanningMutation((vars: Parameters<typeof setPriorityAction>[0]["data"]) => setPriorityAction({ data: vars }), {
    success: "Priority saved",
  });
export const useCompletePriority = () =>
  usePlanningMutation((bookId: number) => completePriorityAction({ data: { bookId } }), { success: "Marked as completed" });
export const useCancelPriority = () =>
  usePlanningMutation((bookId: number) => cancelPriorityAction({ data: { bookId } }), { success: "Priority cancelled" });

// ------------------------------------------------------------------- planner
export function usePlanner(from: string, to: string) {
  return useQuery({
    queryKey: [...planningKeys.planner, from, to],
    queryFn: async () => unwrap(await getPlannerRangeAction({ data: { from, to } })),
    staleTime: 1000 * 30,
    placeholderData: (prev) => prev,
  });
}

type Vars<F extends (...args: never[]) => unknown> = Parameters<F>[0] extends { data: infer D } ? D : never;

export const useAddPlanItems = () =>
  usePlanningMutation((vars: Vars<typeof addPlanItemsAction>) => addPlanItemsAction({ data: vars }), {
    success: (items) => (items.length === 1 ? "Added to your plan" : `${items.length} reading plans added`),
  });
export const useUpdatePlanItem = () =>
  usePlanningMutation((vars: Vars<typeof updatePlanItemAction>) => updatePlanItemAction({ data: vars }), { success: "Plan updated" });
export const useSkipPlanItem = () =>
  usePlanningMutation((vars: Vars<typeof skipPlanItemAction>) => skipPlanItemAction({ data: vars }), { success: "Skipped. You can reopen it any time." });
export const useReopenPlanItem = () =>
  usePlanningMutation((vars: Vars<typeof reopenPlanItemAction>) => reopenPlanItemAction({ data: vars }), { success: "Back on the plan" });
export const useReschedulePlanItem = () =>
  usePlanningMutation((vars: Vars<typeof reschedulePlanItemAction>) => reschedulePlanItemAction({ data: vars }), { success: "Rescheduled" });
export const useDeletePlanItem = () =>
  usePlanningMutation((vars: Vars<typeof deletePlanItemAction>) => deletePlanItemAction({ data: vars }), { success: "Removed from your plan" });
export const useCompletePlanItem = () =>
  usePlanningMutation((vars: Vars<typeof completePlanItemAction>) => completePlanItemAction({ data: vars }), {
    success: (r) => (r.bookCompleted ? "Logged. You finished the book!" : "Reading logged"),
  });

// -------------------------------------------------------------- weekly review
export function useWeekSummary(weekStart: string) {
  return useQuery({
    queryKey: ["weekly-review", "summary", weekStart],
    queryFn: async () => unwrap(await getWeekSummaryAction({ data: { weekStart } })),
    staleTime: 1000 * 30,
    placeholderData: (prev) => prev,
  });
}

export function useWeeklyReviews(limit = 12) {
  return useQuery({
    queryKey: ["weekly-review", "list", limit],
    queryFn: async () => unwrap(await getWeeklyReviewsAction({ data: { limit } })),
    staleTime: 1000 * 30,
  });
}

export const useSaveWeeklyReview = () =>
  usePlanningMutation((vars: Vars<typeof saveWeeklyReviewAction>) => saveWeeklyReviewAction({ data: vars }), {
    success: "Review saved",
  });
