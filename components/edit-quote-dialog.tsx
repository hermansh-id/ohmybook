"use client";

import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { QuoteForm } from "./quote-form";

interface EditQuoteDialogProps {
  quote: {
    quoteId: number;
    bookId: number;
    quoteText: string;
    pageNumber: number | null;
    chapter: string | null;
    tags: string[] | null;
    isFavorite: boolean | null;
    notes: string | null;
  };
  book: {
    bookId: number;
    title: string;
  };
  isOpen: boolean;
  onClose: () => void;
}

export function EditQuoteDialog({ quote, book, isOpen, onClose }: EditQuoteDialogProps) {
  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-[600px] max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Edit Quote</DialogTitle>
          <DialogDescription>
            Update your quote from {book.title}
          </DialogDescription>
        </DialogHeader>
        <QuoteForm quote={quote} onSuccess={onClose} />
      </DialogContent>
    </Dialog>
  );
}
