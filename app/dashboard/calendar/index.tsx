import { createFileRoute } from "@tanstack/react-router";
import { CalendarClient } from "./calendar-client";

export const Route = createFileRoute('/dashboard/calendar/')({
  component: CalendarPage,
});

function CalendarPage() {
  return <CalendarClient />;
}
