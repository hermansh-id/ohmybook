"use client";

import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Star, MoreVertical, Pencil, Trash2, Share2, BookOpen } from "lucide-react";
import { useState } from "react";
import { toggleQuoteFavoriteAction, deleteQuoteAction } from "@/app/actions/quotes";
import { toast } from "sonner";
import { EditQuoteDialog } from "./edit-quote-dialog";

interface QuoteCardProps {
  quote: {
    quoteId: number;
    bookId: number;
    quoteText: string;
    pageNumber: number | null;
    chapter: string | null;
    tags: string[] | null;
    isFavorite: boolean | null;
    notes: string | null;
    createdAt: Date | null;
  };
  book: {
    bookId: number;
    title: string;
  };
  authors: string;
}

export function QuoteCard({ quote, book, authors }: QuoteCardProps) {
  const [isFavorite, setIsFavorite] = useState(quote.isFavorite || false);
  const [isEditOpen, setIsEditOpen] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);

  const handleToggleFavorite = async () => {
    try {
      await toggleQuoteFavoriteAction(quote.quoteId);
      setIsFavorite(!isFavorite);
      toast.success(isFavorite ? "Removed from favorites" : "Added to favorites");
    } catch (error) {
      toast.error("Failed to update favorite status");
    }
  };

  const handleDelete = async () => {
    if (!confirm("Are you sure you want to delete this quote?")) return;

    setIsDeleting(true);
    try {
      await deleteQuoteAction(quote.quoteId);
      toast.success("Quote deleted");
      window.location.reload();
    } catch (error) {
      toast.error("Failed to delete quote");
      setIsDeleting(false);
    }
  };

  return (
    <>
      <Card className={`relative ${isFavorite ? "border-yellow-500/50" : ""}`}>
        <CardContent className="pt-6">
          {/* Header */}
          <div className="flex items-start justify-between gap-2 mb-3">
            <div className="flex-1 min-w-0">
              <h3 className="font-semibold text-lg line-clamp-1">{book.title}</h3>
              <p className="text-sm text-muted-foreground line-clamp-1">{authors}</p>
            </div>
            <div className="flex items-center gap-1">
              <Button
                variant="ghost"
                size="icon"
                onClick={handleToggleFavorite}
                className="h-8 w-8"
              >
                <Star
                  className={`h-4 w-4 ${
                    isFavorite ? "fill-yellow-500 text-yellow-500" : ""
                  }`}
                />
              </Button>
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="ghost" size="icon" className="h-8 w-8">
                    <MoreVertical className="h-4 w-4" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end">
                  <DropdownMenuItem onClick={() => setIsEditOpen(true)}>
                    <Pencil className="h-4 w-4 mr-2" />
                    Edit
                  </DropdownMenuItem>
                  <DropdownMenuItem>
                    <Share2 className="h-4 w-4 mr-2" />
                    Share
                  </DropdownMenuItem>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem
                    onClick={handleDelete}
                    disabled={isDeleting}
                    className="text-destructive"
                  >
                    <Trash2 className="h-4 w-4 mr-2" />
                    Delete
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>
          </div>

          {/* Quote Text */}
          <blockquote className="border-l-4 border-primary pl-4 py-2 mb-3">
            <p className="text-base italic leading-relaxed">"{quote.quoteText}"</p>
          </blockquote>

          {/* Metadata */}
          <div className="flex flex-wrap items-center gap-2 text-sm text-muted-foreground mb-3">
            {quote.pageNumber && (
              <span className="flex items-center gap-1">
                <BookOpen className="h-3 w-3" />
                Page {quote.pageNumber}
              </span>
            )}
            {quote.chapter && (
              <span>• {quote.chapter}</span>
            )}
          </div>

          {/* Tags */}
          {quote.tags && quote.tags.length > 0 && (
            <div className="flex flex-wrap gap-1 mb-3">
              {quote.tags.map((tag) => (
                <Badge key={tag} variant="secondary" className="text-xs">
                  {tag}
                </Badge>
              ))}
            </div>
          )}

          {/* Notes */}
          {quote.notes && (
            <div className="mt-3 pt-3 border-t">
              <p className="text-sm text-muted-foreground">{quote.notes}</p>
            </div>
          )}
        </CardContent>
      </Card>

      <EditQuoteDialog
        quote={quote}
        book={book}
        isOpen={isEditOpen}
        onClose={() => setIsEditOpen(false)}
      />
    </>
  );
}
