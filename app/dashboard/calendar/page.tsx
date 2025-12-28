import { CalendarClient } from "./calendar-client";
import { getFinishedBooksByDate } from "@/lib/db/queries";

interface PageProps {
  searchParams: Promise<{ year?: string; month?: string }>;
}

export default async function CalendarPage({ searchParams }: PageProps) {
  const params = await searchParams;
  const currentDate = new Date();
  const year = params.year ? parseInt(params.year) : currentDate.getFullYear();
  const month = params.month
    ? parseInt(params.month)
    : currentDate.getMonth() + 1;

  // Fetch books finished in the selected month/year
  const books = await getFinishedBooksByDate(year, month);

  return (
    <CalendarClient
      initialBooks={books}
      initialYear={year}
      initialMonth={month}
    />
  );
}
