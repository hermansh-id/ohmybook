import { getBookDetailsAction } from "@/app/actions/books";
import { BookDetailsClient } from "./book-details-client";
import { notFound } from "next/navigation";

interface PageProps {
  params: Promise<{ bookId: string }>;
}

export default async function BookDetailsPage({ params }: PageProps) {
  const { bookId } = await params;
  const id = parseInt(bookId);

  if (isNaN(id)) {
    notFound();
  }

  try {
    const book = await getBookDetailsAction(id);
    return <BookDetailsClient book={book} />;
  } catch (error) {
    notFound();
  }
}
