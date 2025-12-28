"use client";

import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { getBookDetailsAction, updateBookStatusAction } from "@/app/actions/books";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { Button } from "@/components/ui/button";
import { BookOpen, Calendar, Star, Clock, Tag, Check } from "lucide-react";
import { toast } from "sonner";

interface BookDetailsDialogProps {
  bookId: number | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function BookDetailsDialog({
  bookId,
  open,
  onOpenChange,
}: BookDetailsDialogProps) {
  const queryClient = useQueryClient();
  const [selectedRating, setSelectedRating] = useState<number>(0);

  const { data: book, isLoading } = useQuery({
    queryKey: ["book", bookId],
    queryFn: () => getBookDetailsAction(bookId!),
    enabled: !!bookId && open,
  });

  const updateMutation = useMutation({
    mutationFn: updateBookStatusAction,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["books"] });
      queryClient.invalidateQueries({ queryKey: ["book", bookId] });
      toast.success("Book updated successfully!");
    },
    onError: () => {
      toast.error("Failed to update book");
    },
  });

  const handleMarkAsFinished = () => {
    if (!book || !selectedRating) {
      toast.error("Please select a rating");
      return;
    }

    updateMutation.mutate({
      bookId: book.id,
      logId: book.logId,
      status: "finished",
      rating: selectedRating,
      dateFinished: new Date(),
    });
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-3xl max-h-[90vh] overflow-y-auto">
        {isLoading && (
          <div className="flex items-center justify-center p-8">
            <p className="text-muted-foreground">Loading...</p>
          </div>
        )}

        {book && (
          <>
            <DialogHeader>
              <DialogTitle className="text-2xl">{book.title}</DialogTitle>
              <DialogDescription>
                {book.isbn && `ISBN: ${book.isbn}`}
              </DialogDescription>
            </DialogHeader>

            <div className="grid gap-6 py-4">
              {/* Cover and Basic Info */}
              <div className="grid md:grid-cols-[200px_1fr] gap-6">
                {book.coverUrl ? (
                  <img
                    src={book.coverUrl}
                    alt={book.title}
                    className="w-full rounded-lg shadow-lg"
                  />
                ) : (
                  <div className="aspect-[2/3] bg-muted rounded-lg flex items-center justify-center">
                    <BookOpen className="h-12 w-12 text-muted-foreground" />
                  </div>
                )}

                <div className="space-y-4">
                  {/* Status and Rating */}
                  <div className="flex flex-wrap gap-2">
                    {book.status && (
                      <Badge variant="default">
                        {book.status.replace(/_/g, " ")}
                      </Badge>
                    )}
                    {book.rating && (
                      <Badge variant="secondary" className="gap-1">
                        <Star className="h-3 w-3 fill-current" />
                        {book.rating}/5
                      </Badge>
                    )}
                  </div>

                  {/* Book Stats */}
                  <div className="grid grid-cols-2 gap-3 text-sm">
                    {book.pages && (
                      <div className="flex items-center gap-2">
                        <BookOpen className="h-4 w-4 text-muted-foreground" />
                        <span>{book.pages} pages</span>
                      </div>
                    )}
                    {book.year && (
                      <div className="flex items-center gap-2">
                        <Calendar className="h-4 w-4 text-muted-foreground" />
                        <span>{book.year}</span>
                      </div>
                    )}
                    {book.readingDays && (
                      <div className="flex items-center gap-2">
                        <Clock className="h-4 w-4 text-muted-foreground" />
                        <span>{book.readingDays} days to read</span>
                      </div>
                    )}
                    {book.averageRating && (
                      <div className="flex items-center gap-2">
                        <Star className="h-4 w-4 text-muted-foreground" />
                        <span>
                          {book.averageRating} ({book.ratingsCount} ratings)
                        </span>
                      </div>
                    )}
                  </div>

                  {/* Reading Progress */}
                  {book.status === "reading" && book.pages && (
                    <div>
                      <div className="text-sm text-muted-foreground mb-1">
                        Progress: {book.currentPage} / {book.pages}
                      </div>
                      <div className="h-2 bg-muted rounded-full overflow-hidden">
                        <div
                          className="h-full bg-primary"
                          style={{
                            width: `${(book.currentPage / book.pages) * 100}%`,
                          }}
                        />
                      </div>
                    </div>
                  )}

                  {/* Dates */}
                  <div className="space-y-1 text-sm">
                    {book.dateStarted && (
                      <div className="flex justify-between">
                        <span className="text-muted-foreground">Started:</span>
                        <span>
                          {new Date(book.dateStarted).toLocaleDateString()}
                        </span>
                      </div>
                    )}
                    {book.dateFinished && (
                      <div className="flex justify-between">
                        <span className="text-muted-foreground">Finished:</span>
                        <span>
                          {new Date(book.dateFinished).toLocaleDateString()}
                        </span>
                      </div>
                    )}
                  </div>

                  {/* Publisher Info */}
                  {(book.publisher || book.publicationDate) && (
                    <div className="text-sm">
                      {book.publisher && (
                        <div className="text-muted-foreground">
                          {book.publisher}
                        </div>
                      )}
                      {book.publicationDate && (
                        <div className="text-muted-foreground">
                          Published:{" "}
                          {new Date(book.publicationDate).toLocaleDateString()}
                        </div>
                      )}
                    </div>
                  )}
                </div>
              </div>

              {/* Description */}
              {book.description && (
                <>
                  <Separator />
                  <div>
                    <h3 className="font-semibold mb-2">Description</h3>
                    <p className="text-sm text-muted-foreground leading-relaxed">
                      {book.description}
                    </p>
                  </div>
                </>
              )}

              {/* Review */}
              {book.review && (
                <>
                  <Separator />
                  <div>
                    <h3 className="font-semibold mb-2">My Review</h3>
                    <p className="text-sm leading-relaxed">{book.review}</p>
                  </div>
                </>
              )}

              {/* Notes */}
              {book.notes && (
                <>
                  <Separator />
                  <div>
                    <h3 className="font-semibold mb-2">Notes</h3>
                    <p className="text-sm text-muted-foreground leading-relaxed">
                      {book.notes}
                    </p>
                  </div>
                </>
              )}

              {/* Tags */}
              {book.tags && book.tags.length > 0 && (
                <>
                  <Separator />
                  <div>
                    <h3 className="font-semibold mb-2 flex items-center gap-2">
                      <Tag className="h-4 w-4" />
                      Tags
                    </h3>
                    <div className="flex flex-wrap gap-2">
                      {book.tags.map((tag: string, index: number) => (
                        <Badge key={index} variant="outline">
                          {tag}
                        </Badge>
                      ))}
                    </div>
                  </div>
                </>
              )}

              {/* Mark as Finished - Mobile-first design */}
              {book.status !== "finished" && (
                <>
                  <Separator />
                  <div className="rounded-lg border bg-muted/50 p-4">
                    <h3 className="font-semibold mb-3 flex items-center gap-2">
                      <Check className="h-4 w-4" />
                      Mark as Finished
                    </h3>
                    <div className="space-y-4">
                      {/* Rating Selector - Mobile-first */}
                      <div>
                        <label className="text-sm font-medium mb-2 block">
                          Your Rating
                        </label>
                        <div className="flex gap-2 flex-wrap">
                          {[1, 2, 3, 4, 5].map((rating) => (
                            <button
                              key={rating}
                              onClick={() => setSelectedRating(rating)}
                              className={`flex items-center gap-1 px-4 py-2 rounded-md border transition-colors min-w-[60px] justify-center ${
                                selectedRating === rating
                                  ? "bg-primary text-primary-foreground border-primary"
                                  : "bg-background hover:bg-muted"
                              }`}
                            >
                              <Star
                                className={`h-4 w-4 ${
                                  selectedRating === rating ? "fill-current" : ""
                                }`}
                              />
                              <span>{rating}</span>
                            </button>
                          ))}
                        </div>
                      </div>

                      {/* Submit Button */}
                      <Button
                        onClick={handleMarkAsFinished}
                        disabled={!selectedRating || updateMutation.isPending}
                        className="w-full sm:w-auto"
                      >
                        {updateMutation.isPending ? "Saving..." : "Mark as Finished"}
                      </Button>
                    </div>
                  </div>
                </>
              )}
            </div>
          </>
        )}
      </DialogContent>
    </Dialog>
  );
}
