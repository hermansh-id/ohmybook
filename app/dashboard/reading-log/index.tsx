import { createFileRoute } from "@tanstack/react-router";
import { ReadingLogClient } from "./reading-log-client";

export const Route = createFileRoute('/dashboard/reading-log/')({
  component: () => <ReadingLogClient />,
});
