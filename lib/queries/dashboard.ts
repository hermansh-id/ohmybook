import { useQuery } from "@tanstack/react-query";
import { getDashboardDataAction } from "@/actions/dashboard";

export const dashboardQueryKey = ["dashboard"] as const;

export function useDashboardData() {
  return useQuery({
    queryKey: dashboardQueryKey,
    queryFn: () => getDashboardDataAction(),
    staleTime: 1000 * 60 * 2,
  });
}
