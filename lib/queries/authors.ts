import { useQuery } from "@tanstack/react-query";
import { getAuthorsWithStatsAction } from "@/actions/authors";

export const authorsQueryKey = ["authors"] as const;

export function useAuthors() {
  return useQuery({
    queryKey: authorsQueryKey,
    queryFn: () => getAuthorsWithStatsAction(),
    staleTime: 1000 * 60 * 5,
  });
}
