"use client";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { BookOpen, Calendar, Star, FileText, ArrowLeft, ExternalLink } from "lucide-react";
import Link from "next/link";

interface BookDetailsClientProps {
  book: {
    id: number;
    title: string;
    isbn: string | null;
    year: number | null;
    pages: number | null;
    addedAt: Date | string | null;
    goodreadsUrl: string | null;
    status: string;
    rating: number | null;
    review: string | null;
    notes: string | null;
    dateAdded: Date | string | null;
    dateStarted: Date | string | null;
    dateFinished: Date | string | null;
    currentPage: number;
    readingDays: number | null;
    tags: string[];
    coverUrl: string | null;
    description: string | null;
    averageRating: number | string | null;
    ratingsCount: number | string | null;
    publisher: string | null;
    publicationDate: Date | string | null;
    logId: number | null;
  };
}

export function BookDetailsClient({ book }: BookDetailsClientProps) {
  const statusLabels: Record<string, string> = {
    want_to_read: "Want to Read",
    reading: "Currently Reading",
    finished: "Finished",
    did_not_finish: "Did Not Finish",
    on_hold: "On Hold",
  };

  const statusColors: Record<string, string> = {
    want_to_read: "secondary",
    reading: "default",
    finished: "default",
    did_not_finish: "destructive",
    on_hold: "outline",
  };

  return (
    <div className="flex flex-col gap-4 p-4 md:gap-6 md:p-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon" asChild>
          <Link href="/dashboard/books">
            <ArrowLeft className="h-4 w-4" />
          </Link>
        </Button>
        <div>
          <h1 className="text-3xl font-bold tracking-tight">{book.title}</h1>
          <p className="text-muted-foreground">Book Details</p>
        </div>
      </div>

      <div className="grid gap-6 md:grid-cols-3">
        {/* Left Column - Cover & Basic Info */}
        <div className="space-y-4">
          <Card>
            <CardContent className="pt-6">
              {book.coverUrl ? (
                <img
                  src={book.coverUrl}
                  alt={book.title}
                  className="w-full rounded-lg shadow-lg"
                />
              ) : (
                <div className="flex aspect-[2/3] w-full items-center justify-center rounded-lg bg-muted">
                  <BookOpen className="h-16 w-16 text-muted-foreground" />
                </div>
              )}

              <div className="mt-4 space-y-2">
                <Badge variant={statusColors[book.status] as any}>
                  {statusLabels[book.status]}
                </Badge>

                {book.rating && (
                  <div className="flex items-center gap-1">
                    <Star className="h-4 w-4 fill-yellow-400 text-yellow-400" />
                    <span className="font-semibold">{book.rating}</span>
                    <span className="text-sm text-muted-foreground">/5</span>
                  </div>
                )}

                {book.goodreadsUrl && (
                  <Button variant="outline" size="sm" className="w-full" asChild>
                    <a
                      href={book.goodreadsUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      <ExternalLink className="mr-2 h-4 w-4" />
                      View on Goodreads
                    </a>
                  </Button>
                )}
              </div>
            </CardContent>
          </Card>

          {/* Book Stats */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Book Information</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3 text-sm">
              {book.pages && (
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Pages</span>
                  <span className="font-medium">{book.pages}</span>
                </div>
              )}
              {book.year && (
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Year</span>
                  <span className="font-medium">{book.year}</span>
                </div>
              )}
              {book.isbn && (
                <div className="flex justify-between">
                  <span className="text-muted-foreground">ISBN</span>
                  <span className="font-medium text-xs">{book.isbn}</span>
                </div>
              )}
              {book.publisher && (
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Publisher</span>
                  <span className="font-medium">{book.publisher}</span>
                </div>
              )}
              {book.averageRating && (
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Avg. Rating</span>
                  <span className="font-medium">
                    {book.averageRating} ({book.ratingsCount} ratings)
                  </span>
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Right Column - Details */}
        <div className="space-y-4 md:col-span-2">
          {/* Description */}
          {book.description && (
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <FileText className="h-5 w-5" />
                  Description
                </CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-sm leading-relaxed text-muted-foreground">
                  {book.description}
                </p>
              </CardContent>
            </Card>
          )}

          {/* Reading Progress */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Calendar className="h-5 w-5" />
                Reading Progress
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="grid gap-4 sm:grid-cols-2">
                {book.dateAdded && (
                  <div>
                    <p className="text-sm text-muted-foreground">Date Added</p>
                    <p className="font-medium">
                      {new Date(book.dateAdded).toLocaleDateString()}
                    </p>
                  </div>
                )}
                {book.dateStarted && (
                  <div>
                    <p className="text-sm text-muted-foreground">Date Started</p>
                    <p className="font-medium">
                      {new Date(book.dateStarted).toLocaleDateString()}
                    </p>
                  </div>
                )}
                {book.dateFinished && (
                  <div>
                    <p className="text-sm text-muted-foreground">Date Finished</p>
                    <p className="font-medium">
                      {new Date(book.dateFinished).toLocaleDateString()}
                    </p>
                  </div>
                )}
                {book.readingDays && (
                  <div>
                    <p className="text-sm text-muted-foreground">Reading Days</p>
                    <p className="font-medium">{book.readingDays} days</p>
                  </div>
                )}
              </div>

              {book.status === "reading" && book.pages && (
                <div>
                  <div className="mb-2 flex justify-between text-sm">
                    <span className="text-muted-foreground">Progress</span>
                    <span className="font-medium">
                      {book.currentPage} / {book.pages} pages (
                      {Math.round((book.currentPage / book.pages) * 100)}%)
                    </span>
                  </div>
                  <div className="h-2 overflow-hidden rounded-full bg-secondary">
                    <div
                      className="h-full bg-primary transition-all"
                      style={{
                        width: `${(book.currentPage / book.pages) * 100}%`,
                      }}
                    />
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Review */}
          {book.review && (
            <Card>
              <CardHeader>
                <CardTitle>My Review</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-sm leading-relaxed">{book.review}</p>
              </CardContent>
            </Card>
          )}

          {/* Notes */}
          {book.notes && (
            <Card>
              <CardHeader>
                <CardTitle>Notes</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-sm leading-relaxed">{book.notes}</p>
              </CardContent>
            </Card>
          )}

          {/* Tags */}
          {book.tags && book.tags.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle>Tags</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="flex flex-wrap gap-2">
                  {book.tags.map((tag, i) => (
                    <Badge key={i} variant="outline">
                      {tag}
                    </Badge>
                  ))}
                </div>
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </div>
  );
}
