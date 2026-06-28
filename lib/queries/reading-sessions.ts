import { useQuery } from "@tanstack/react-query";
import { getReadingSessionsAction } from "@/actions/reading-sessions";
import { getUnfinishedBooksAction } from "@/actions/reading-sessions";

export const readingSessionsQueryKey = ["reading-sessions"] as const;
export const unfinishedBooksQueryKey = ["unfinished-books"] as const;

export function useReadingSessions(limit = 100) {
  return useQuery({
    queryKey: [...readingSessionsQueryKey, limit],
    queryFn: () => getReadingSessionsAction({ data: { limit } }),
    staleTime: 1000 * 60,
  });
}

export function useUnfinishedBooks() {
  return useQuery({
    queryKey: unfinishedBooksQueryKey,
    queryFn: () => getUnfinishedBooksAction(),
    staleTime: 1000 * 60,
  });
}
