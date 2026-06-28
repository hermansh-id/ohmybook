import { createServerFn } from "@tanstack/react-start";

export const getCalendarDataAction = createServerFn({ method: "GET" })
  .validator((d: { year: number; month: number }) => d)
  .handler(async ({ data }) => {
    const { getFinishedBooksByDate } = await import("@/lib/db/queries");
    const books = await getFinishedBooksByDate(data.year, data.month);
    return { books, year: data.year, month: data.month };
  });
