import { useQuery } from "@tanstack/react-query";
import { getSettingsDataAction } from "@/actions/settings";

export const settingsQueryKey = ["settings"] as const;

export function useSettings() {
  return useQuery({
    queryKey: settingsQueryKey,
    queryFn: () => getSettingsDataAction(),
    staleTime: 1000 * 60 * 5,
  });
}
