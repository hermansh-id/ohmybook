import { useQuery } from "@tanstack/react-query";
import { getGenresWithStatsAction } from "@/actions/genres";

export const genresQueryKey = ["genres"] as const;

export function useGenres() {
  return useQuery({
    queryKey: genresQueryKey,
    queryFn: () => getGenresWithStatsAction(),
    staleTime: 1000 * 60 * 5,
  });
}
