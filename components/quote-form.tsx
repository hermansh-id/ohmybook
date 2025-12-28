"use client";

import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Checkbox } from "@/components/ui/checkbox";
import { createQuoteAction, updateQuoteAction } from "@/app/actions/quotes";
import { toast } from "sonner";
import { Loader2, Star } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { getAllBooksAction } from "@/app/actions/books";

interface QuoteFormProps {
  quote?: {
    quoteId: number;
    bookId: number;
    quoteText: string;
    pageNumber: number | null;
    chapter: string | null;
    tags: string[] | null;
    isFavorite: boolean | null;
    notes: string | null;
  };
  onSuccess: () => void;
}

export function QuoteForm({ quote, onSuccess }: QuoteFormProps) {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [books, setBooks] = useState<any[]>([]);
  const [loadingBooks, setLoadingBooks] = useState(true);

  const [formData, setFormData] = useState({
    bookId: quote?.bookId || 0,
    quoteText: quote?.quoteText || "",
    pageNumber: quote?.pageNumber?.toString() || "",
    chapter: quote?.chapter || "",
    tags: quote?.tags?.join(", ") || "",
    isFavorite: quote?.isFavorite || false,
    notes: quote?.notes || "",
  });

  useEffect(() => {
    async function loadBooks() {
      try {
        const result = await getAllBooksAction();
        setBooks(result || []);
      } catch (error) {
        toast.error("Failed to load books");
      } finally {
        setLoadingBooks(false);
      }
    }
    loadBooks();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!formData.bookId) {
      toast.error("Please select a book");
      return;
    }

    if (!formData.quoteText.trim()) {
      toast.error("Please enter the quote text");
      return;
    }

    setIsSubmitting(true);

    try {
      const data = {
        bookId: formData.bookId,
        quoteText: formData.quoteText.trim(),
        pageNumber: formData.pageNumber ? parseInt(formData.pageNumber) : undefined,
        chapter: formData.chapter.trim() || undefined,
        tags: formData.tags
          ? formData.tags.split(",").map((tag) => tag.trim()).filter(Boolean)
          : undefined,
        isFavorite: formData.isFavorite,
        notes: formData.notes.trim() || undefined,
      };

      let result;
      if (quote) {
        result = await updateQuoteAction(quote.quoteId, data);
      } else {
        result = await createQuoteAction(data);
      }

      if (result.success) {
        toast.success(quote ? "Quote updated!" : "Quote added!");
        onSuccess();
        window.location.reload();
      } else {
        toast.error(result.error || "Failed to save quote");
      }
    } catch (error) {
      toast.error("An error occurred");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      {/* Book Selection */}
      <div className="space-y-2">
        <Label htmlFor="book">Book *</Label>
        {loadingBooks ? (
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <Loader2 className="h-4 w-4 animate-spin" />
            Loading books...
          </div>
        ) : (
          <Select
            value={formData.bookId.toString()}
            onValueChange={(value) =>
              setFormData({ ...formData, bookId: parseInt(value) })
            }
            disabled={!!quote}
          >
            <SelectTrigger>
              <SelectValue placeholder="Select a book" />
            </SelectTrigger>
            <SelectContent>
              {books.map((book) => (
                <SelectItem key={book.bookId} value={book.bookId.toString()}>
                  {book.title}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        )}
      </div>

      {/* Quote Text */}
      <div className="space-y-2">
        <Label htmlFor="quoteText">Quote *</Label>
        <Textarea
          id="quoteText"
          placeholder="Enter the quote text..."
          value={formData.quoteText}
          onChange={(e) =>
            setFormData({ ...formData, quoteText: e.target.value })
          }
          rows={5}
          required
        />
      </div>

      {/* Page Number & Chapter */}
      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <Label htmlFor="pageNumber">Page Number</Label>
          <Input
            id="pageNumber"
            type="number"
            placeholder="123"
            value={formData.pageNumber}
            onChange={(e) =>
              setFormData({ ...formData, pageNumber: e.target.value })
            }
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="chapter">Chapter</Label>
          <Input
            id="chapter"
            placeholder="Chapter 5"
            value={formData.chapter}
            onChange={(e) =>
              setFormData({ ...formData, chapter: e.target.value })
            }
          />
        </div>
      </div>

      {/* Tags */}
      <div className="space-y-2">
        <Label htmlFor="tags">Tags</Label>
        <Input
          id="tags"
          placeholder="inspiration, wisdom, favorite (comma-separated)"
          value={formData.tags}
          onChange={(e) => setFormData({ ...formData, tags: e.target.value })}
        />
        <p className="text-xs text-muted-foreground">
          Separate multiple tags with commas
        </p>
      </div>

      {/* Notes */}
      <div className="space-y-2">
        <Label htmlFor="notes">Personal Notes</Label>
        <Textarea
          id="notes"
          placeholder="Why this quote resonates with you..."
          value={formData.notes}
          onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
          rows={3}
        />
      </div>

      {/* Favorite */}
      <div className="flex items-center gap-2">
        <Checkbox
          id="isFavorite"
          checked={formData.isFavorite}
          onCheckedChange={(checked) =>
            setFormData({ ...formData, isFavorite: checked as boolean })
          }
        />
        <Label htmlFor="isFavorite" className="flex items-center gap-1 cursor-pointer">
          <Star className={`h-4 w-4 ${formData.isFavorite ? "fill-yellow-500 text-yellow-500" : ""}`} />
          Mark as favorite
        </Label>
      </div>

      {/* Submit */}
      <div className="flex gap-2 justify-end pt-4">
        <Button type="submit" disabled={isSubmitting}>
          {isSubmitting && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
          {quote ? "Update Quote" : "Add Quote"}
        </Button>
      </div>
    </form>
  );
}
