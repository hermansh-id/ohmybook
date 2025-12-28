"use client";

import { useState } from "react";
import { useBooks } from "@/lib/queries/books";
import { BooksTable, Book } from "@/components/books-table";
import { BookDetailsDialog } from "@/components/book-details-dialog";
import { BookOpen, Plus } from "lucide-react";
import { Button } from "@/components/ui/button";
import Link from "next/link";

export function BooksClient() {
  const { data: books, isLoading, error } = useBooks();
  const [selectedBookId, setSelectedBookId] = useState<number | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);

  const handleRowClick = (book: Book) => {
    setSelectedBookId(book.id);
    setDialogOpen(true);
  };

  return (
    <div className="flex flex-col gap-4 p-4 md:gap-6 md:p-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Books</h1>
          <p className="text-muted-foreground">
            Browse and manage your book collection
          </p>
        </div>
        <Button asChild>
          <Link href="/dashboard/books/add">
            <Plus className="h-4 w-4 mr-2" />
            Add Book
          </Link>
        </Button>
      </div>

      {isLoading && (
        <div className="flex items-center justify-center p-8">
          <p className="text-muted-foreground">Loading books...</p>
        </div>
      )}

      {error && (
        <div className="flex items-center justify-center p-8">
          <p className="text-destructive">
            Failed to load books. Please try again.
          </p>
        </div>
      )}

      {books && books.length === 0 && (
        <div className="flex flex-col items-center justify-center p-8">
          <BookOpen className="h-12 w-12 text-muted-foreground mb-4" />
          <p className="text-muted-foreground text-lg">
            No books found
          </p>
          <p className="text-sm text-muted-foreground">
            Start adding books to your collection
          </p>
        </div>
      )}

      {books && books.length > 0 && (
        <BooksTable data={books} onRowClick={handleRowClick} />
      )}

      <BookDetailsDialog
        bookId={selectedBookId}
        open={dialogOpen}
        onOpenChange={setDialogOpen}
      />
    </div>
  );
}
