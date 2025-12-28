"use client";

import { useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { updateBookAction } from "@/app/actions/books";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { toast } from "sonner";

interface EditBookDialogProps {
  book: {
    id: number;
    title: string;
    isbn?: string | null;
    year?: number | null;
    pages?: number | null;
    goodreadsUrl?: string | null;
  };
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function EditBookDialog({ book, open, onOpenChange }: EditBookDialogProps) {
  const queryClient = useQueryClient();
  const [formData, setFormData] = useState({
    title: book.title,
    isbn: book.isbn || "",
    year: book.year?.toString() || "",
    pages: book.pages?.toString() || "",
    goodreadsUrl: book.goodreadsUrl || "",
  });

  const updateMutation = useMutation({
    mutationFn: updateBookAction,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["books"] });
      queryClient.invalidateQueries({ queryKey: ["book", book.id] });
      toast.success("Book updated successfully!");
      onOpenChange(false);
    },
    onError: () => {
      toast.error("Failed to update book");
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    updateMutation.mutate({
      bookId: book.id,
      title: formData.title,
      isbn: formData.isbn || undefined,
      year: formData.year ? parseInt(formData.year) : undefined,
      pages: formData.pages ? parseInt(formData.pages) : undefined,
      goodreadsUrl: formData.goodreadsUrl || undefined,
    });
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <DialogTitle>Edit Book</DialogTitle>
          <DialogDescription>
            Update the book information below
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4 py-4">
          {/* Title */}
          <div className="space-y-2">
            <Label htmlFor="title">
              Title <span className="text-destructive">*</span>
            </Label>
            <Input
              id="title"
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              required
            />
          </div>

          {/* ISBN */}
          <div className="space-y-2">
            <Label htmlFor="isbn">ISBN</Label>
            <Input
              id="isbn"
              value={formData.isbn}
              onChange={(e) => setFormData({ ...formData, isbn: e.target.value })}
              placeholder="978-0-123456-78-9"
            />
          </div>

          {/* Year and Pages - Mobile-first grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="year">Year</Label>
              <Input
                id="year"
                type="number"
                value={formData.year}
                onChange={(e) => setFormData({ ...formData, year: e.target.value })}
                placeholder="2024"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="pages">Pages</Label>
              <Input
                id="pages"
                type="number"
                value={formData.pages}
                onChange={(e) => setFormData({ ...formData, pages: e.target.value })}
                placeholder="350"
              />
            </div>
          </div>

          {/* Goodreads URL */}
          <div className="space-y-2">
            <Label htmlFor="goodreadsUrl">Goodreads URL</Label>
            <Input
              id="goodreadsUrl"
              type="url"
              value={formData.goodreadsUrl}
              onChange={(e) => setFormData({ ...formData, goodreadsUrl: e.target.value })}
              placeholder="https://www.goodreads.com/book/show/..."
            />
          </div>

          <DialogFooter className="gap-2 sm:gap-0">
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
              disabled={updateMutation.isPending}
            >
              Cancel
            </Button>
            <Button type="submit" disabled={updateMutation.isPending}>
              {updateMutation.isPending ? "Saving..." : "Save Changes"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
