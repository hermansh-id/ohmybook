import { useQuery } from "@tanstack/react-query";
import { getCalendarDataAction } from "@/actions/calendar";

export const calendarQueryKey = (year: number, month: number) => ["calendar", year, month] as const;

export function useCalendar(year: number, month: number) {
  return useQuery({
    queryKey: calendarQueryKey(year, month),
    queryFn: () => getCalendarDataAction({ data: { year, month } }),
    staleTime: 1000 * 60 * 5,
  });
}
