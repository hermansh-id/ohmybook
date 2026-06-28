import { createFileRoute } from "@tanstack/react-router";
import { GenresClient } from "./genres-client";

export const Route = createFileRoute('/dashboard/genres/')({
  component: () => <GenresClient />,
});
