import { useQuery } from "@tanstack/react-query";
import { getStatisticsDataAction } from "@/actions/statistics";

export const statisticsQueryKey = ["statistics"] as const;

export function useStatistics() {
  return useQuery({
    queryKey: statisticsQueryKey,
    queryFn: () => getStatisticsDataAction(),
    staleTime: 1000 * 60 * 5,
  });
}
