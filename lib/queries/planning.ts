"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import {
  cancelPriorityAction,
  completePriorityAction,
  getPrioritiesAction,
  getPriorityChangesAction,
  setPriorityAction,
} from "@/actions/planning";

type Result<T> = { success: true; data: T } | { success: false; error: string };

function unwrap<T>(result: Result<T>): T {
  if (!result.success) throw new Error(result.error);
  return result.data;
}

export const planningKeys = {
  priorities: ["priorities"] as const,
  priorityChanges: ["priority-changes"] as const,
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
