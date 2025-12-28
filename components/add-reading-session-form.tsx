"use client";

import { useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { createReadingSessionAction, getUnfinishedBooksAction } from "@/app/actions/reading-sessions";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Slider } from "@/components/ui/slider";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { BookOpen, Clock } from "lucide-react";
import { toast } from "sonner";

interface AddReadingSessionFormProps {
  books: Array<{
    id: number;
    title: string;
    pages: number;
    currentPage: number;
    status: string;
  }>;
  onSuccess?: () => void;
}

export function AddReadingSessionForm({ books, onSuccess }: AddReadingSessionFormProps) {
  const queryClient = useQueryClient();
  const [selectedBookId, setSelectedBookId] = useState<number | null>(null);
  const [pagesRead, setPagesRead] = useState([0]);
  const [minutesRead, setMinutesRead] = useState([0]);

  const selectedBook = books.find((b) => b.id === selectedBookId);
  const totalPages = selectedBook?.pages || 0;
  const currentPage = selectedBook?.currentPage || 0;
  const remainingPages = Math.max(0, totalPages - currentPage);
  const maxPages = remainingPages > 0 ? remainingPages : 100;

  const createMutation = useMutation({
    mutationFn: createReadingSessionAction,
    onSuccess: (result) => {
      queryClient.invalidateQueries({ queryKey: ["reading-sessions"] });

      if (result.bookCompleted) {
        toast.success("🎉 Book completed! Would you like to rate it?", {
          action: {
            label: "Rate Book",
            onClick: () => {
              // Navigate to book details or show rating dialog
              // We'll implement this in the next step
            },
          },
          duration: 5000,
        });
      } else {
        toast.success("Reading session added!");
      }

      // Reset form
      setSelectedBookId(null);
      setPagesRead([0]);
      setMinutesRead([0]);
      // Call callback if provided
      if (onSuccess) {
        onSuccess();
      }
    },
    onError: () => {
      toast.error("Failed to add reading session");
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    if (!selectedBookId) {
      toast.error("Please select a book");
      return;
    }

    if (pagesRead[0] === 0 && minutesRead[0] === 0) {
      toast.error("Please add some reading progress");
      return;
    }

    // Validation: can't log more pages than remaining
    if (pagesRead[0] > remainingPages && totalPages > 0) {
      toast.error(`You can only log ${remainingPages} more pages for this book`);
      return;
    }

    createMutation.mutate({
      bookId: selectedBookId,
      sessionDate: new Date().toISOString().split("T")[0],
      pagesRead: pagesRead[0],
      minutesRead: minutesRead[0],
    });
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {/* Book Selection */}
      <div className="space-y-2">
        <Label htmlFor="book">Select Book</Label>
        <Select
          value={selectedBookId?.toString()}
          onValueChange={(value) => {
            setSelectedBookId(parseInt(value));
            // Reset sliders when book changes
            setPagesRead([0]);
            setMinutesRead([0]);
          }}
        >
          <SelectTrigger id="book">
            <SelectValue placeholder="Choose a book to read..." />
          </SelectTrigger>
          <SelectContent>
            {books.map((book) => (
              <SelectItem key={book.id} value={book.id.toString()}>
                {book.title} {book.pages > 0 && `(${book.pages} pages)`}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {/* Pages Read Slider */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <Label className="flex items-center gap-2">
            <BookOpen className="h-4 w-4" />
            Pages Read
          </Label>
          <span className="text-2xl font-bold text-primary">
            {pagesRead[0]}
            <span className="text-sm text-muted-foreground ml-1">
              / {remainingPages}
            </span>
          </span>
        </div>
        <Slider
          value={pagesRead}
          onValueChange={setPagesRead}
          max={maxPages}
          step={1}
          disabled={!selectedBookId}
          className="w-full"
        />
        {selectedBookId && totalPages > 0 && (
          <div className="text-xs space-y-1">
            <p className="text-muted-foreground">
              Current: page {currentPage} of {totalPages} ({Math.round((currentPage / totalPages) * 100)}%)
            </p>
            <p className="text-muted-foreground">
              {remainingPages > 0
                ? `${remainingPages} pages remaining`
                : "Book completed!"}
            </p>
          </div>
        )}
        {!selectedBookId && (
          <p className="text-xs text-muted-foreground">
            Select a book first to set pages
          </p>
        )}
      </div>

      {/* Minutes Read Slider */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <Label className="flex items-center gap-2">
            <Clock className="h-4 w-4" />
            Minutes Read
          </Label>
          <span className="text-2xl font-bold text-primary">
            {minutesRead[0]}
            <span className="text-sm text-muted-foreground ml-1">min</span>
          </span>
        </div>
        <Slider
          value={minutesRead}
          onValueChange={setMinutesRead}
          max={300}
          step={5}
          disabled={!selectedBookId}
          className="w-full"
        />
        <p className="text-xs text-muted-foreground">
          {!selectedBookId
            ? "Select a book first to set time"
            : "Drag to set how long you read (up to 5 hours)"}
        </p>
      </div>

      {/* Submit Button */}
      <Button
        type="submit"
        className="w-full"
        size="lg"
        disabled={!selectedBookId || createMutation.isPending}
      >
        {createMutation.isPending ? "Saving..." : "Add Reading Session"}
      </Button>
    </form>
  );
}
