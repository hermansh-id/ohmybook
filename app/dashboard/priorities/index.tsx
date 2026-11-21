import { createFileRoute } from "@tanstack/react-router";
import { PrioritiesClient } from "./priorities-client";

export const Route = createFileRoute("/dashboard/priorities/")({
  component: PrioritiesPage,
});

function PrioritiesPage() {
  return <PrioritiesClient />;
}
