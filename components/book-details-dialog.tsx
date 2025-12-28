"use client";

import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { getBookDetailsAction, updateBookStatusAction, deleteBookAction, fetchGoodreadsDataAction } from "@/app/actions/books";
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
import { BookOpen, Calendar, Star, Clock, Tag, Check, ExternalLink, Trash2, Download, Pencil } from "lucide-react";
import { toast } from "sonner";
import Link from "next/link";
import { EditBookDialog } from "@/components/edit-book-dialog";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";

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
  const router = useRouter();
  const queryClient = useQueryClient();
  const [selectedRating, setSelectedRating] = useState<number>(0);
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);
  const [showEditDialog, setShowEditDialog] = useState(false);

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

  const deleteMutation = useMutation({
    mutationFn: deleteBookAction,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["books"] });
      toast.success("Book deleted successfully!");
      onOpenChange(false);
      setShowDeleteDialog(false);
    },
    onError: () => {
      toast.error("Failed to delete book");
    },
  });

  const fetchGoodreadsMutation = useMutation({
    mutationFn: ({ bookId, isbn }: { bookId: number; isbn: string }) =>
      fetchGoodreadsDataAction(bookId, isbn),
    onSuccess: (result) => {
      if (result.success) {
        queryClient.invalidateQueries({ queryKey: ["books"] });
        queryClient.invalidateQueries({ queryKey: ["book", bookId] });
        toast.success("Goodreads data fetched successfully!");
      } else {
        toast.error(result.error || "Failed to fetch Goodreads data");
      }
    },
    onError: (error: any) => {
      toast.error(error?.message || "Failed to fetch Goodreads data");
    },
  });

  const handleMarkAsFinished = () => {
    if (!book) {
      toast.error("Book data not available");
      return;
    }

    if (!selectedRating || selectedRating < 1 || selectedRating > 5) {
      toast.error("Please select a rating (1-5)");
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

  const handleDelete = () => {
    if (!book) return;
    deleteMutation.mutate(book.id);
  };

  const handleFetchGoodreadsData = () => {
    if (!book || !book.isbn) {
      toast.error("ISBN is required to fetch Goodreads data");
      return;
    }
    fetchGoodreadsMutation.mutate({ bookId: book.id, isbn: book.isbn });
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
              <div className="flex items-start justify-between gap-2">
                <div className="flex-1">
                  <DialogTitle className="text-2xl">{book.title}</DialogTitle>
                  <DialogDescription>
                    {book.isbn && `ISBN: ${book.isbn}`}
                  </DialogDescription>
                </div>
                <div className="flex gap-2 shrink-0">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setShowEditDialog(true)}
                  >
                    <Pencil className="h-4 w-4" />
                    <span className="ml-2 hidden sm:inline">Edit</span>
                  </Button>
                  <Button asChild variant="outline" size="sm">
                    <Link href={`/dashboard/books/${book.id}`}>
                      <ExternalLink className="h-4 w-4 mr-2" />
                      <span className="hidden sm:inline">View Details</span>
                    </Link>
                  </Button>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setShowDeleteDialog(true)}
                    className="text-destructive hover:text-destructive"
                  >
                    <Trash2 className="h-4 w-4" />
                    <span className="ml-2 hidden sm:inline">Delete</span>
                  </Button>
                </div>
              </div>
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

              {/* Fetch Goodreads Data - Show when ISBN exists but no Goodreads data */}
              {book.isbn && !book.coverUrl && !book.description && (
                <>
                  <Separator />
                  <div className="rounded-lg border border-dashed bg-muted/30 p-4">
                    <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
                      <div>
                        <h3 className="font-semibold mb-1 flex items-center gap-2">
                          <Download className="h-4 w-4" />
                          Goodreads Data Missing
                        </h3>
                        <p className="text-sm text-muted-foreground">
                          Fetch book cover, description, and other details from Goodreads using ISBN
                        </p>
                      </div>
                      <Button
                        onClick={handleFetchGoodreadsData}
                        disabled={fetchGoodreadsMutation.isPending}
                        size="sm"
                        className="w-full sm:w-auto shrink-0"
                      >
                        {fetchGoodreadsMutation.isPending ? "Fetching..." : "Fetch Data"}
                      </Button>
                    </div>
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

              {/* Mark as Finished / Update Rating - Mobile-first design */}
              {book.status !== "finished" ? (
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
              ) : (
                <>
                  <Separator />
                  <div className="rounded-lg border bg-muted/50 p-4">
                    <h3 className="font-semibold mb-3 flex items-center gap-2">
                      <Star className="h-4 w-4" />
                      {book.rating ? "Update Rating" : "Add Rating"}
                    </h3>
                    <div className="space-y-4">
                      {/* Rating Selector - Mobile-first */}
                      <div>
                        <label className="text-sm font-medium mb-2 block">
                          Your Rating {book.rating && `(Current: ${book.rating}/5)`}
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
                        onClick={() => {
                          if (!book) {
                            toast.error("Book data not available");
                            return;
                          }

                          if (!selectedRating || selectedRating < 1 || selectedRating > 5) {
                            toast.error("Please select a rating (1-5)");
                            return;
                          }

                          updateMutation.mutate({
                            bookId: book.id,
                            logId: book.logId,
                            status: "finished",
                            rating: selectedRating,
                            dateFinished: book.dateFinished ? new Date(book.dateFinished) : new Date(),
                          });
                        }}
                        disabled={!selectedRating || updateMutation.isPending}
                        className="w-full sm:w-auto"
                      >
                        {updateMutation.isPending ? "Saving..." : book.rating ? "Update Rating" : "Add Rating"}
                      </Button>
                    </div>
                  </div>
                </>
              )}
            </div>
          </>
        )}
      </DialogContent>

      {/* Delete Confirmation Dialog */}
      <AlertDialog open={showDeleteDialog} onOpenChange={setShowDeleteDialog}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Are you sure?</AlertDialogTitle>
            <AlertDialogDescription>
              This will permanently delete "{book?.title}" and all associated data.
              This action cannot be undone.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleDelete}
              disabled={deleteMutation.isPending}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              {deleteMutation.isPending ? "Deleting..." : "Delete"}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      {/* Edit Book Dialog */}
      {book && (
        <EditBookDialog
          book={{
            id: book.id,
            title: book.title,
            isbn: book.isbn,
            year: book.year,
            pages: book.pages,
            goodreadsUrl: book.goodreadsUrl,
          }}
          open={showEditDialog}
          onOpenChange={setShowEditDialog}
        />
      )}
    </Dialog>
  );
}
