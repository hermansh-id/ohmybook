import { createFileRoute } from "@tanstack/react-router";
import { PlannerClient } from "./planner-client";

export const Route = createFileRoute("/dashboard/planner/")({
  component: PlannerPage,
});

function PlannerPage() {
  return <PlannerClient />;
}
