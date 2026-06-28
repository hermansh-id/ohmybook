import { createFileRoute } from "@tanstack/react-router";
import { QuotesClient } from "./quotes-client";

export const Route = createFileRoute('/dashboard/quotes/')({
  component: () => <QuotesClient />,
});
