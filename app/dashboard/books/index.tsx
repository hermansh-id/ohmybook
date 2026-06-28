import { createFileRoute } from "@tanstack/react-router";
import { BooksClient } from "./books-client";

export const Route = createFileRoute('/dashboard/books/')({
  component: BooksPage,
});

function BooksPage() {
  return <BooksClient />;
}
