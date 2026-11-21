"use client";

import * as React from "react";
import { Link } from "@tanstack/react-router";
import { format } from "date-fns";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import { Skeleton } from "@/components/ui/skeleton";
import { Textarea } from "@/components/ui/textarea";
import { addDays, fromDateKey, toDateKey, weekStartKey } from "@/lib/dates";
import { LEVEL_META, formatMinutes, type PriorityLevel } from "@/lib/planning-ui";
import { useSaveWeeklyReview, useWeekSummary, useWeeklyReviews } from "@/lib/queries/planning";

const range = (weekStart: string) =>
  `${format(fromDateKey(weekStart), "d MMM")} - ${format(fromDateKey(addDays(weekStart, 6)), "d MMM yyyy")}`;

function priorityChangeText(c: { fromLevel: string | null; toLevel: string | null; fromStatus: string | null; toStatus: string | null }) {
  const name = (l: string | null) => LEVEL_META[l as PriorityLevel]?.label ?? l ?? "";
  if (c.fromLevel === null) return `prioritized as ${name(c.toLevel)}`;
  if (c.fromStatus !== c.toStatus) return `priority ${c.toStatus}`;
  return `${name(c.fromLevel)} to ${name(c.toLevel)}`;
}

export function ReviewsClient() {
  const [weekStart, setWeekStart] = React.useState(() => weekStartKey(toDateKey(new Date())));
  const { data: summary, isLoading, error } = useWeekSummary(weekStart);
  const { data: past = [] } = useWeeklyReviews(8);
  const save = useSaveWeeklyReview();

  const [wentWell, setWentWell] = React.useState("");
  const [blockers, setBlockers] = React.useState("");
  const [nextWeek, setNextWeek] = React.useState("");

  // Load the saved reflection for the visible week (and reset when the week changes).
  const reviewKey = summary ? `${summary.weekStart}:${summary.review?.updatedAt ? new Date(summary.review.updatedAt).getTime() : "none"}` : "";
  React.useEffect(() => {
    if (!summary || summary.weekStart !== weekStart) return;
    setWentWell(summary.review?.wentWell ?? "");
    setBlockers(summary.review?.blockers ?? "");
    setNextWeek(summary.review?.nextWeekChanges ?? "");
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [reviewKey]);

  const thisWeek = weekStartKey(toDateKey(new Date()));
  const onSave = (e: React.FormEvent) => {
    e.preventDefault();
    save.mutate({ weekStart, wentWell, blockers, nextWeekChanges: nextWeek });
  };

  const pages = summary?.pages;
  const pct = pages?.completionPct ?? null;

  return (
    <div className="flex flex-col gap-4 p-4 md:gap-6 md:p-6">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Weekly review</h1>
          <p className="text-muted-foreground">A look back, not a score. A gap between plan and reality just shows what to adjust.</p>
        </div>
        <div className="flex items-center gap-1">
          <Button variant="outline" size="icon" className="size-11 sm:size-9" aria-label="Previous week" onClick={() => setWeekStart(addDays(weekStart, -7))}>
            <ChevronLeft className="size-4" />
          </Button>
          <Button variant="outline" className="min-h-11 min-w-44 sm:min-h-9" onClick={() => setWeekStart(thisWeek)}>
            {weekStart === thisWeek ? `This week: ${range(weekStart)}` : range(weekStart)}
          </Button>
          <Button variant="outline" size="icon" className="size-11 sm:size-9" aria-label="Next week" onClick={() => setWeekStart(addDays(weekStart, 7))}>
            <ChevronRight className="size-4" />
          </Button>
        </div>
      </div>

      {isLoading && !summary ? (
        <div className="space-y-3">
          <Skeleton className="h-40 w-full" />
          <Skeleton className="h-56 w-full" />
        </div>
      ) : error || !summary ? (
        <p className="text-sm text-muted-foreground">Could not load this week. Please refresh.</p>
      ) : (
        <>
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">How the week went</CardTitle>
              <CardDescription>
                {summary.activities.total === 0
                  ? "Nothing was planned this week."
                  : `${summary.activities.completed} of ${summary.activities.total} planned activities done${summary.activities.skipped ? `, ${summary.activities.skipped} skipped` : ""}${summary.activities.rescheduled ? `, ${summary.activities.rescheduled} moved` : ""}.`}
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-5">
              {pages!.planned > 0 && (
                <div className="space-y-2">
                  <div className="flex items-baseline justify-between gap-2">
                    <p className="text-2xl font-semibold tabular-nums">
                      {pages!.actualFromPlans}
                      <span className="text-base font-normal text-muted-foreground"> / {pages!.planned} planned pages</span>
                    </p>
                    {pct !== null && <p className="text-sm text-muted-foreground">{pct}%</p>}
                  </div>
                  <Progress value={pct ?? 0} className="h-2" />
                </div>
              )}

              <dl className="grid grid-cols-2 gap-4 sm:grid-cols-4">
                <div>
                  <dt className="text-xs text-muted-foreground">Pages read</dt>
                  <dd className="text-lg font-medium tabular-nums">{pages!.totalRead}</dd>
                </div>
                <div>
                  <dt className="text-xs text-muted-foreground">Time reading</dt>
                  <dd className="text-lg font-medium">{formatMinutes(summary.minutesRead) ?? "0m"}</dd>
                </div>
                <div>
                  <dt className="text-xs text-muted-foreground">Books finished</dt>
                  <dd className="text-lg font-medium tabular-nums">{summary.booksCompleted.length}</dd>
                </div>
                <div>
                  <dt className="text-xs text-muted-foreground">Currently reading</dt>
                  <dd className="text-lg font-medium tabular-nums">{summary.activeReading.length}</dd>
                </div>
              </dl>

              {summary.booksCompleted.length > 0 && (
                <div>
                  <h3 className="mb-1 text-sm font-medium">Finished this week</h3>
                  <ul className="space-y-0.5 text-sm">
                    {summary.booksCompleted.map((b) => (
                      <li key={b.bookId}>
                        <Link to="/dashboard/books/$bookId" params={{ bookId: String(b.bookId) }} className="hover:underline">
                          {b.title}
                        </Link>
                        {b.rating ? <span className="text-muted-foreground"> · {b.rating}/5</span> : null}
                      </li>
                    ))}
                  </ul>
                </div>
              )}

              {summary.activeReading.length > 0 && (
                <div>
                  <h3 className="mb-1 text-sm font-medium">In progress</h3>
                  <ul className="space-y-0.5 text-sm">
                    {summary.activeReading.map((b) => (
                      <li key={b.bookId} className="flex items-baseline justify-between gap-2">
                        <Link to="/dashboard/books/$bookId" params={{ bookId: String(b.bookId) }} className="truncate hover:underline">
                          {b.title}
                        </Link>
                        {b.pages ? (
                          <span className="shrink-0 text-xs text-muted-foreground">
                            {b.currentPage ?? 0}/{b.pages}
                          </span>
                        ) : null}
                      </li>
                    ))}
                  </ul>
                </div>
              )}

              {summary.priorityChanges.length > 0 && (
                <div>
                  <h3 className="mb-1 text-sm font-medium">Priority changes</h3>
                  <ul className="space-y-0.5 text-sm text-muted-foreground">
                    {summary.priorityChanges.map((c) => (
                      <li key={c.historyId}>
                        <span className="text-foreground">{c.title}</span> {priorityChangeText(c)}
                      </li>
                    ))}
                  </ul>
                </div>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Reflection</CardTitle>
              <CardDescription>A few honest lines help next week's plan fit your real life.</CardDescription>
            </CardHeader>
            <CardContent>
              <form onSubmit={onSave} className="space-y-4">
                <div className="space-y-2">
                  <label htmlFor="went-well" className="text-sm font-medium">
                    What went well this week?
                  </label>
                  <Textarea id="went-well" rows={3} value={wentWell} onChange={(e) => setWentWell(e.target.value)} />
                </div>
                <div className="space-y-2">
                  <label htmlFor="blockers" className="text-sm font-medium">
                    What prevented you from following the plan?
                  </label>
                  <Textarea id="blockers" rows={3} value={blockers} onChange={(e) => setBlockers(e.target.value)} />
                </div>
                <div className="space-y-2">
                  <label htmlFor="next-week" className="text-sm font-medium">
                    What should change next week?
                  </label>
                  <Textarea id="next-week" rows={3} value={nextWeek} onChange={(e) => setNextWeek(e.target.value)} />
                </div>
                <div className="flex items-center gap-3">
                  <Button type="submit" className="min-h-11 sm:min-h-9" disabled={save.isPending}>
                    {save.isPending ? "Saving..." : summary.review ? "Update review" : "Save review"}
                  </Button>
                  {summary.review?.updatedAt && (
                    <span className="text-xs text-muted-foreground">Saved {format(new Date(summary.review.updatedAt), "d MMM, HH:mm")}</span>
                  )}
                </div>
              </form>
            </CardContent>
          </Card>
        </>
      )}

      {past.length > 0 && (
        <section className="space-y-2">
          <h2 className="text-sm font-medium uppercase tracking-wide text-muted-foreground">Past reviews</h2>
          <ul className="divide-y rounded-lg border">
            {past.map((r) => (
              <li key={r.reviewId}>
                <button
                  type="button"
                  onClick={() => setWeekStart(r.weekStart)}
                  className="flex min-h-14 w-full flex-col items-start gap-0.5 px-4 py-2 text-left hover:bg-accent"
                >
                  <span className="text-sm font-medium">
                    {range(r.weekStart)}
                    <span className="font-normal text-muted-foreground">
                      {" "}
                      · {r.actualPages}/{r.plannedPages} planned pages · {r.totalPagesRead} read
                    </span>
                  </span>
                  {r.wentWell && <span className="line-clamp-1 text-xs text-muted-foreground">{r.wentWell}</span>}
                </button>
              </li>
            ))}
          </ul>
        </section>
      )}
    </div>
  );
}
