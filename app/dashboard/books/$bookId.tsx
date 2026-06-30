import { createFileRoute, redirect } from "@tanstack/react-router";
import { getBookDetailsAction } from "@/actions/books";
import { BookDetailsClient } from "./book-details-client";

export const Route = createFileRoute('/dashboard/books/$bookId')({
  loader: async ({ params }) => {
    const id = parseInt(params.bookId);
    if (isNaN(id)) throw redirect({ to: '/dashboard/books' });
    try {
      const book = await getBookDetailsAction({ data: { bookId: id } });
      return { book };
    } catch (error) {
      throw redirect({ to: '/dashboard/books' });
    }
  },
  component: BookDetailsPage,
});

function BookDetailsPage() {
  const { book } = Route.useLoaderData();
  return <BookDetailsClient book={book} />;
}
