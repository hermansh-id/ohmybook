import { createFileRoute } from "@tanstack/react-router";
import { ReviewsClient } from "./reviews-client";

export const Route = createFileRoute("/dashboard/reviews/")({
  component: ReviewsPage,
});

function ReviewsPage() {
  return <ReviewsClient />;
}
