import { useQuery } from "@tanstack/react-query";
import { getQuotesDataAction } from "@/actions/quotes";

export const quotesQueryKey = ["quotes"] as const;

export function useQuotes() {
  return useQuery({
    queryKey: quotesQueryKey,
    queryFn: () => getQuotesDataAction(),
    staleTime: 1000 * 60 * 2,
  });
}
