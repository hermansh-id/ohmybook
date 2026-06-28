import { createFileRoute } from "@tanstack/react-router";
import { AuthorsClient } from "./authors-client";

export const Route = createFileRoute('/dashboard/authors/')({
  component: () => <AuthorsClient />,
});
