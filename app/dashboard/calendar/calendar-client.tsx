import { useState, useMemo } from "react";
import { useCalendar } from "@/lib/queries/calendar";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { BookOpen, ChevronLeft, ChevronRight, ExternalLink, Flag } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Link } from "@tanstack/react-router";
import { toDateKey } from "@/lib/dates";
import { plannedLabel } from "@/lib/planning-ui";
import { usePlanner } from "@/lib/queries/planning";

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

export function CalendarClient() {
  const now = new Date();
  const [year, setYear] = useState(now.getFullYear());
  const [month, setMonth] = useState(now.getMonth() + 1);
  const [selectedDate, setSelectedDate] = useState<Date | undefined>();

  const { data, isLoading } = useCalendar(year, month);
  const books: FinishedBook[] = data?.books ?? [];

  // Planned reading, actual sessions and target dates for the visible month
  const { data: planner } = usePlanner(
    toDateKey(new Date(year, month - 1, 1)),
    toDateKey(new Date(year, month, 0)),
  );
  const overlay = useMemo(() => {
    const byDay = new Map<string, { planned: number; done: number; other: number; target: number }>();
    const bump = (key: string, field: "planned" | "done" | "other" | "target") => {
      const cur = byDay.get(key) ?? { planned: 0, done: 0, other: 0, target: 0 };
      cur[field]++;
      byDay.set(key, cur);
    };
    for (const r of planner?.items ?? []) {
      if (r.item.status === "planned") bump(r.item.scheduledDate, "planned");
      else if (r.item.status === "completed") bump(r.item.scheduledDate, "done");
    }
    for (const x of planner?.sessions ?? []) if (x.linkedItemId === null) bump(x.sessionDate, "other");
    for (const t of planner?.targets ?? []) bump(t.targetDate, "target");
    return byDay;
  }, [planner]);

  const currentDate = new Date(year, month - 1);

  // Group books by date
  const booksByDate = useMemo(() => {
    const grouped = new Map<string, FinishedBook[]>();

    books.forEach((book) => {
      if (book.log.dateFinished) {
        const dateKey = String(book.log.dateFinished).slice(0, 10);

        if (!grouped.has(dateKey)) {
          grouped.set(dateKey, []);
        }
        grouped.get(dateKey)!.push(book);
      }
    });

    return grouped;
  }, [books]);

  // Get books for selected date
  const selectedBooks = useMemo(() => {
    if (!selectedDate) return [];
    return booksByDate.get(toDateKey(selectedDate)) || [];
  }, [selectedDate, booksByDate]);

  // Generate days for current month
  const daysInMonth = useMemo(() => {
    const lastDay = new Date(year, month, 0);
    const days = [];

    for (let d = 1; d <= lastDay.getDate(); d++) {
      const date = new Date(year, month - 1, d);
      const dateKey = toDateKey(date);
      const booksCount = booksByDate.get(dateKey)?.length || 0;

      days.push({
        date,
        day: d,
        dateKey,
        booksCount,
        marks: overlay.get(dateKey),
        isToday: date.toDateString() === new Date().toDateString(),
        isSelected: selectedDate?.toDateString() === date.toDateString(),
      });
    }

    return days;
  }, [year, month, booksByDate, selectedDate, overlay]);

  const handleMonthChange = (increment: number) => {
    const newDate = new Date(year, month - 1 + increment);
    setYear(newDate.getFullYear());
    setMonth(newDate.getMonth() + 1);
    setSelectedDate(undefined);
  };

  if (isLoading) {
    return (
      <div className="flex flex-col gap-4 p-4 md:gap-6 md:p-6">
        <div className="space-y-2">
          <Skeleton className="h-9 w-64" />
          <Skeleton className="h-4 w-48" />
        </div>
        <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <Card key={i}>
              <CardContent className="pt-6">
                <Skeleton className="h-4 w-24 mb-2" />
                <Skeleton className="h-8 w-16" />
              </CardContent>
            </Card>
          ))}
        </div>
        <Card>
          <CardContent className="pt-6">
            <Skeleton className="h-64 w-full" />
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-4 p-4 md:gap-6 md:p-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Reading Calendar</h1>
        <p className="text-muted-foreground">
          Track your finished books by date
        </p>
      </div>

      {/* Stats summary */}
      <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
        <Card>
          <CardContent className="pt-6">
            <div className="space-y-1">
              <p className="text-sm text-muted-foreground">Books Finished</p>
              <p className="text-2xl font-bold">{books.length}</p>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="space-y-1">
              <p className="text-sm text-muted-foreground">Total Pages</p>
              <p className="text-2xl font-bold">
                {books.reduce((sum, book) => sum + (book.book.pages || 0), 0)}
              </p>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="space-y-1">
              <p className="text-sm text-muted-foreground">Average Rating</p>
              <p className="text-2xl font-bold">
                {books.filter((b) => b.log.rating).length > 0
                  ? (
                      books.reduce((sum, book) => sum + (book.log.rating || 0), 0) /
                      books.filter((b) => b.log.rating).length
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

      {/* Calendar */}
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

          {/* Calendar Grid */}
          <div className="grid grid-cols-7 gap-1.5">
            {/* Empty cells for days before month starts */}
            {Array.from({ length: new Date(year, month - 1, 1).getDay() }).map((_, i) => (
              <div key={`empty-${i}`} className="h-14" />
            ))}

            {/* Actual days */}
            {daysInMonth.map((dayInfo) => (
              <button
                key={dayInfo.dateKey}
                onClick={() => setSelectedDate(dayInfo.date)}
                className={`
                  h-14 rounded-md border-2 p-1 text-xs font-medium transition-all
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
                  {dayInfo.marks && (
                    <span className="mt-1 flex items-center gap-0.5">
                      {dayInfo.marks.planned > 0 && <span className="size-2 rounded-full border-2 border-sky-500" />}
                      {dayInfo.marks.done > 0 && <span className="size-2 rounded-full bg-emerald-600" />}
                      {dayInfo.marks.other > 0 && <span className="size-2 rounded-full bg-zinc-400" />}
                      {dayInfo.marks.target > 0 && <Flag className="size-2.5 text-amber-500" />}
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
            <div className="flex items-center gap-1.5">
              <span className="size-2.5 rounded-full border-2 border-sky-500" />
              <span className="text-muted-foreground">Planned</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="size-2.5 rounded-full bg-emerald-600" />
              <span className="text-muted-foreground">Plan done</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="size-2.5 rounded-full bg-zinc-400" />
              <span className="text-muted-foreground">Other reading</span>
            </div>
            <div className="flex items-center gap-1.5">
              <Flag className="size-3 text-amber-500" />
              <span className="text-muted-foreground">Target date</span>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Books list for selected date */}
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
            {(() => {
              const key = toDateKey(selectedDate);
              const items = (planner?.items ?? []).filter((r) => r.item.scheduledDate === key && r.item.status !== "rescheduled");
              const sessions = (planner?.sessions ?? []).filter((x) => x.sessionDate === key && x.linkedItemId === null);
              const targets = (planner?.targets ?? []).filter((t) => t.targetDate === key);
              if (items.length + sessions.length + targets.length === 0) return null;
              return (
                <div className="mb-4 space-y-1.5 text-sm">
                  {items.map((r) => (
                    <p key={r.item.itemId} className="flex items-center gap-2">
                      <span
                        className={`size-2.5 shrink-0 rounded-full ${r.item.status === "completed" ? "bg-emerald-600" : "border-2 border-sky-500"}`}
                      />
                      <span className="truncate">
                        {r.title}
                        <span className="text-muted-foreground">
                          {" "}
                          · {r.item.status === "completed" ? "done" : r.item.status === "skipped" ? "skipped" : "planned"}
                          {plannedLabel(r.item) ? ` ${plannedLabel(r.item)}` : ""}
                        </span>
                      </span>
                    </p>
                  ))}
                  {sessions.map((x) => (
                    <p key={x.sessionId} className="flex items-center gap-2">
                      <span className="size-2.5 shrink-0 rounded-full bg-zinc-400" />
                      <span className="truncate">
                        {x.title}
                        <span className="text-muted-foreground"> · read{x.pagesRead ? ` ${x.pagesRead} pages` : ""}</span>
                      </span>
                    </p>
                  ))}
                  {targets.map((t) => (
                    <p key={t.priorityId} className="flex items-center gap-2">
                      <Flag className="size-3 shrink-0 text-amber-500" />
                      <span className="truncate">
                        {t.title}
                        <span className="text-muted-foreground"> · target date</span>
                      </span>
                    </p>
                  ))}
                  <Link to="/dashboard/planner" className="inline-block pt-1 text-xs text-muted-foreground underline">
                    Open planner
                  </Link>
                </div>
              );
            })()}
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
                    to={`/dashboard/books/${book.book.bookId}`}
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
