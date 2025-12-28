"use client";

import { useState, useMemo } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { BookOpen, ChevronLeft, ChevronRight, ExternalLink } from "lucide-react";
import { Button } from "@/components/ui/button";
import Link from "next/link";

interface FinishedBook {
  log: {
    logId: number;
    dateFinished: string | null;
    rating: number | null;
  };
  book: {
    bookId: number;
    title: string;
    pages: number | null;
  };
  authors: string;
  goodreads: {
    coverUrl: string | null;
  } | null;
}

interface CalendarClientProps {
  initialBooks: FinishedBook[];
  initialYear: number;
  initialMonth: number;
}

export function CalendarClient({
  initialBooks,
  initialYear,
  initialMonth,
}: CalendarClientProps) {
  const [currentDate, setCurrentDate] = useState(
    new Date(initialYear, initialMonth - 1)
  );
  const [selectedDate, setSelectedDate] = useState<Date | undefined>();

  // Group books by date
  const booksByDate = useMemo(() => {
    const grouped = new Map<string, FinishedBook[]>();

    initialBooks.forEach((book) => {
      if (book.log.dateFinished) {
        const date = new Date(book.log.dateFinished);
        const dateKey = date.toISOString().split("T")[0];

        if (!grouped.has(dateKey)) {
          grouped.set(dateKey, []);
        }
        grouped.get(dateKey)!.push(book);
      }
    });

    return grouped;
  }, [initialBooks]);

  // Get books for selected date
  const selectedBooks = useMemo(() => {
    if (!selectedDate) return [];
    const dateKey = selectedDate.toISOString().split("T")[0];
    return booksByDate.get(dateKey) || [];
  }, [selectedDate, booksByDate]);

  // Generate days for current month
  const daysInMonth = useMemo(() => {
    const year = currentDate.getFullYear();
    const month = currentDate.getMonth();
    const firstDay = new Date(year, month, 1);
    const lastDay = new Date(year, month + 1, 0);
    const days = [];

    for (let d = 1; d <= lastDay.getDate(); d++) {
      const date = new Date(year, month, d);
      const dateKey = date.toISOString().split("T")[0];
      const booksCount = booksByDate.get(dateKey)?.length || 0;

      days.push({
        date,
        day: d,
        dateKey,
        booksCount,
        isToday:
          date.toDateString() === new Date().toDateString(),
        isSelected:
          selectedDate?.toDateString() === date.toDateString(),
      });
    }

    return days;
  }, [currentDate, booksByDate, selectedDate]);

  const handleMonthChange = (increment: number) => {
    const newDate = new Date(currentDate);
    newDate.setMonth(newDate.getMonth() + increment);
    setCurrentDate(newDate);
    window.location.href = `/dashboard/calendar?year=${newDate.getFullYear()}&month=${newDate.getMonth() + 1}`;
  };

  return (
    <div className="flex flex-col gap-4 p-4 md:gap-6 md:p-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Reading Calendar</h1>
        <p className="text-muted-foreground">
          Track your finished books by date
        </p>
      </div>

      {/* Stats summary - MOVED TO TOP */}
      <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
        <Card>
          <CardContent className="pt-6">
            <div className="space-y-1">
              <p className="text-sm text-muted-foreground">Books Finished</p>
              <p className="text-2xl font-bold">{initialBooks.length}</p>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="space-y-1">
              <p className="text-sm text-muted-foreground">Total Pages</p>
              <p className="text-2xl font-bold">
                {initialBooks.reduce(
                  (sum, book) => sum + (book.book.pages || 0),
                  0
                )}
              </p>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="space-y-1">
              <p className="text-sm text-muted-foreground">Average Rating</p>
              <p className="text-2xl font-bold">
                {initialBooks.filter((b) => b.log.rating).length > 0
                  ? (
                      initialBooks.reduce(
                        (sum, book) => sum + (book.log.rating || 0),
                        0
                      ) / initialBooks.filter((b) => b.log.rating).length
                    ).toFixed(1)
                  : "N/A"}
              </p>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="space-y-1">
              <p className="text-sm text-muted-foreground">Days Reading</p>
              <p className="text-2xl font-bold">{booksByDate.size}</p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Calendar - Full Width Horizontal */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>
              {currentDate.toLocaleDateString("en-US", {
                month: "long",
                year: "numeric",
              })}
            </CardTitle>
            <div className="flex gap-2">
              <Button
                variant="outline"
                size="icon"
                onClick={() => handleMonthChange(-1)}
              >
                <ChevronLeft className="h-4 w-4" />
              </Button>
              <Button
                variant="outline"
                size="icon"
                onClick={() => handleMonthChange(1)}
              >
                <ChevronRight className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {/* Day names */}
          <div className="grid grid-cols-7 gap-1.5 mb-1.5 text-center text-xs font-medium text-muted-foreground">
            <div>Sun</div>
            <div>Mon</div>
            <div>Tue</div>
            <div>Wed</div>
            <div>Thu</div>
            <div>Fri</div>
            <div>Sat</div>
          </div>

          {/* Calendar Grid - Simplified */}
          <div className="grid grid-cols-7 gap-1.5">
            {/* Empty cells for days before month starts */}
            {Array.from({ length: new Date(currentDate.getFullYear(), currentDate.getMonth(), 1).getDay() }).map((_, i) => (
              <div key={`empty-${i}`} className="h-12" />
            ))}

            {/* Actual days */}
            {daysInMonth.map((dayInfo) => (
              <button
                key={dayInfo.dateKey}
                onClick={() => setSelectedDate(dayInfo.date)}
                className={`
                  h-12 rounded-md border-2 p-1 text-xs font-medium transition-all
                  hover:shadow-md hover:scale-105
                  ${
                    dayInfo.isSelected
                      ? "border-primary bg-primary text-primary-foreground shadow-lg scale-105"
                      : dayInfo.booksCount > 0
                      ? "border-green-500 bg-green-50 dark:bg-green-950 text-green-900 dark:text-green-100"
                      : dayInfo.isToday
                      ? "border-blue-500 bg-blue-50 dark:bg-blue-950"
                      : "border-border hover:border-muted-foreground"
                  }
                `}
              >
                <div className="flex flex-col items-center justify-center h-full">
                  <span className="text-sm leading-none">{dayInfo.day}</span>
                  {dayInfo.booksCount > 0 && (
                    <span className="text-[10px] mt-0.5 font-bold leading-none">
                      {dayInfo.booksCount}
                    </span>
                  )}
                </div>
              </button>
            ))}
          </div>

          {/* Legend */}
          <div className="flex flex-wrap gap-3 mt-3 text-xs">
            <div className="flex items-center gap-1.5">
              <div className="w-3 h-3 rounded border-2 border-green-500 bg-green-50 dark:bg-green-950" />
              <span className="text-muted-foreground">Has books</span>
            </div>
            <div className="flex items-center gap-1.5">
              <div className="w-3 h-3 rounded border-2 border-blue-500 bg-blue-50 dark:bg-blue-950" />
              <span className="text-muted-foreground">Today</span>
            </div>
            <div className="flex items-center gap-1.5">
              <div className="w-3 h-3 rounded border-2 border-primary bg-primary" />
              <span className="text-muted-foreground">Selected</span>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Books list for selected date - BELOW CALENDAR */}
      {selectedDate && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <BookOpen className="h-5 w-5" />
              {selectedDate.toLocaleDateString("en-US", {
                month: "long",
                day: "numeric",
                year: "numeric",
              })}
            </CardTitle>
          </CardHeader>
          <CardContent>
            {selectedBooks.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-8 text-center">
                <BookOpen className="mb-2 h-12 w-12 text-muted-foreground" />
                <p className="text-sm text-muted-foreground">
                  No books finished on this date
                </p>
              </div>
            ) : (
              <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                {selectedBooks.map((book) => (
                  <Link
                    key={book.log.logId}
                    href={`/dashboard/books/${book.book.bookId}`}
                    className="flex flex-col gap-3 rounded-lg border p-4 transition-all hover:bg-accent hover:shadow-md group"
                  >
                    <div className="flex gap-3">
                      {book.goodreads?.coverUrl ? (
                        <img
                          src={book.goodreads.coverUrl}
                          alt={book.book.title}
                          className="h-32 w-22 rounded object-cover transition-transform group-hover:scale-105"
                        />
                      ) : (
                        <div className="flex h-32 w-22 items-center justify-center rounded bg-muted transition-transform group-hover:scale-105">
                          <BookOpen className="h-8 w-8 text-muted-foreground" />
                        </div>
                      )}
                      <div className="flex-1 space-y-2">
                        <div className="flex items-start justify-between gap-2">
                          <h4 className="font-semibold leading-tight group-hover:text-primary transition-colors line-clamp-2">
                            {book.book.title}
                          </h4>
                          <ExternalLink className="h-4 w-4 text-muted-foreground opacity-0 group-hover:opacity-100 transition-opacity shrink-0" />
                        </div>
                        <p className="text-sm text-muted-foreground">
                          {book.authors}
                        </p>
                        <div className="flex items-center gap-2">
                          {book.log.rating && (
                            <Badge variant="secondary">
                              ⭐ {book.log.rating}
                            </Badge>
                          )}
                          {book.book.pages && (
                            <span className="text-xs text-muted-foreground">
                              {book.book.pages} pages
                            </span>
                          )}
                        </div>
                      </div>
                    </div>
                  </Link>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      )}
    </div>
  );
}
