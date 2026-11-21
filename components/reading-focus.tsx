"use client";

import * as React from "react";
import { Link } from "@tanstack/react-router";
import { format } from "date-fns";
import { Check, CircleDashed, SkipForward } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import { Skeleton } from "@/components/ui/skeleton";
import { CompleteItemDialog, CreatePlanDialog } from "@/components/planning/plan-dialogs";
import { fromDateKey, toDateKey } from "@/lib/dates";
import { LEVEL_META, TIME_LABEL, actualLabel, plannedLabel, type PriorityLevel, type TimeOfDay } from "@/lib/planning-ui";
import { useReadingFocus } from "@/lib/queries/planning";
import type { PlannerItem } from "@/lib/db/planning-reads";

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="min-w-0 space-y-2">
      <h3 className="text-xs font-medium uppercase tracking-wide text-muted-foreground">{title}</h3>
      {children}
    </section>
  );
}

function ItemLine({ row, onLog }: { row: PlannerItem; onLog?: (row: PlannerItem) => void }) {
  const { item } = row;
  const Icon = item.status === "completed" ? Check : item.status === "skipped" ? SkipForward : CircleDashed;
  const detail = item.status === "completed" ? actualLabel(item) : plannedLabel(item);
  return (
    <li className="flex min-h-9 items-center gap-2 text-sm">
      <Icon className={`size-4 shrink-0 ${item.status === "completed" ? "text-emerald-600" : "text-muted-foreground"}`} />
      <div className="min-w-0 flex-1">
        <Link
          to="/dashboard/books/$bookId"
          params={{ bookId: String(row.bookId) }}
          className={`block truncate hover:underline ${item.status === "skipped" ? "line-through text-muted-foreground" : ""}`}
        >
          {row.title}
        </Link>
        <p className="truncate text-xs text-muted-foreground">
          {TIME_LABEL[item.timeOfDay as TimeOfDay]}
          {detail ? ` · ${detail}` : ""}
        </p>
      </div>
      {onLog && item.status === "planned" && (
        <Button variant="outline" size="sm" className="h-9 shrink-0" onClick={() => onLog(row)}>
          Log
        </Button>
      )}
    </li>
  );
}

const ATTENTION_LINK = {
  past_target: "/dashboard/priorities",
  priority_book_finished: "/dashboard/priorities",
  stalled: "/dashboard/planner",
  waiting_plans: "/dashboard/planner",
} as const;

/** "Your reading focus": priorities, today, weekend, week progress, reading now, needs attention. */
export function ReadingFocus() {
  const today = toDateKey(new Date());
  const { data, isLoading, isError } = useReadingFocus(today);
  const [logging, setLogging] = React.useState<PlannerItem | null>(null);
  const [planOpen, setPlanOpen] = React.useState(false);

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <Skeleton className="h-6 w-48" />
        </CardHeader>
        <CardContent className="grid gap-6 md:grid-cols-2 xl:grid-cols-3">
          {[0, 1, 2].map((i) => (
            <Skeleton key={i} className="h-28 w-full" />
          ))}
        </CardContent>
      </Card>
    );
  }

  // The rest of the dashboard must keep working even if planning data is unavailable.
  if (isError || !data) {
    return (
      <Card>
        <CardContent className="pt-6 text-sm text-muted-foreground">Your reading focus is unavailable right now.</CardContent>
      </Card>
    );
  }

  const pct = data.week.completionPct;
  const [sat, sun] = data.weekend;
  const weekendBy = (day: string) => data.weekendItems.filter((i) => i.item.scheduledDate === day);

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between gap-2 space-y-0">
        <CardTitle className="text-lg">Your reading focus</CardTitle>
        <Button asChild variant="ghost" size="sm" className="h-9">
          <Link to="/dashboard/planner">Open planner</Link>
        </Button>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="grid gap-6 md:grid-cols-2 xl:grid-cols-3">
          <Section title="Current priority">
            {data.priorities.length === 0 ? (
              <p className="text-sm text-muted-foreground">
                No priorities yet.{" "}
                <Link to="/dashboard/priorities" className="underline">
                  Choose what matters most
                </Link>
                .
              </p>
            ) : (
              <ul className="space-y-2">
                {data.priorities.map((p) => (
                  <li key={p.priority.priorityId} className="text-sm">
                    <div className="flex items-center gap-2">
                      <span className={`size-2 shrink-0 rounded-full ${LEVEL_META[p.priority.level as PriorityLevel].dot}`} />
                      <Link to="/dashboard/books/$bookId" params={{ bookId: String(p.bookId) }} className="truncate font-medium hover:underline">
                        {p.title}
                      </Link>
                      <span className="shrink-0 text-xs text-muted-foreground">{LEVEL_META[p.priority.level as PriorityLevel].label}</span>
                    </div>
                    {p.priority.reason && <p className="line-clamp-1 pl-4 text-xs text-muted-foreground">{p.priority.reason}</p>}
                  </li>
                ))}
              </ul>
            )}
          </Section>

          <Section title="Today's plan">
            {data.todayItems.length === 0 ? (
              <div className="space-y-2">
                <p className="text-sm text-muted-foreground">Nothing planned for today.</p>
                <Button variant="outline" size="sm" className="h-9" onClick={() => setPlanOpen(true)}>
                  Plan reading
                </Button>
              </div>
            ) : (
              <ul className="space-y-1">
                {data.todayItems.map((row) => (
                  <ItemLine key={row.item.itemId} row={row} onLog={setLogging} />
                ))}
              </ul>
            )}
          </Section>

          <Section title="This weekend">
            {data.weekendItems.length === 0 ? (
              <p className="text-sm text-muted-foreground">
                Nothing planned yet.{" "}
                <Link to="/dashboard/planner" className="underline">
                  Plan the weekend
                </Link>
                .
              </p>
            ) : (
              <div className="space-y-2">
                {[sat, sun].map(
                  (day) =>
                    weekendBy(day).length > 0 && (
                      <div key={day}>
                        <p className="text-xs font-medium">{format(fromDateKey(day), "EEEE")}</p>
                        <ul className="space-y-1">
                          {weekendBy(day).map((row) => (
                            <ItemLine key={row.item.itemId} row={row} onLog={setLogging} />
                          ))}
                        </ul>
                      </div>
                    ),
                )}
              </div>
            )}
          </Section>

          <Section title="Weekly progress">
            {data.week.plannedPages > 0 ? (
              <div className="space-y-2">
                <p className="text-sm">
                  <span className="text-xl font-semibold tabular-nums">{data.week.actualPages}</span>
                  <span className="text-muted-foreground"> / {data.week.plannedPages} planned pages</span>
                </p>
                <Progress value={pct ?? 0} className="h-1.5" />
                <p className="text-xs text-muted-foreground">
                  {data.week.activities.completed} of {data.week.activities.total} activities done
                  {pct !== null ? ` · ${pct}%` : ""}
                </p>
              </div>
            ) : (
              <p className="text-sm text-muted-foreground">No pages planned this week.</p>
            )}
          </Section>

          <Section title="Reading now">
            {data.reading.length === 0 ? (
              <p className="text-sm text-muted-foreground">Not reading anything at the moment.</p>
            ) : (
              <ul className="space-y-2">
                {data.reading.slice(0, 4).map((b) => {
                  const p = b.pages && b.currentPage ? Math.min(100, Math.round((b.currentPage / b.pages) * 100)) : 0;
                  return (
                    <li key={b.bookId} className="space-y-1 text-sm">
                      <div className="flex items-baseline justify-between gap-2">
                        <Link to="/dashboard/books/$bookId" params={{ bookId: String(b.bookId) }} className="truncate hover:underline">
                          {b.title}
                        </Link>
                        {b.pages ? (
                          <span className="shrink-0 text-xs text-muted-foreground">
                            {b.currentPage ?? 0}/{b.pages}
                          </span>
                        ) : null}
                      </div>
                      {b.pages ? <Progress value={p} className="h-1" /> : null}
                    </li>
                  );
                })}
              </ul>
            )}
          </Section>

          {data.attention.length > 0 && (
            <Section title="Needs attention">
              <ul className="space-y-1.5 text-sm">
                {data.attention.slice(0, 4).map((a, i) => (
                  <li key={`${a.kind}-${a.bookId ?? i}`}>
                    <Link to={ATTENTION_LINK[a.kind]} className="text-muted-foreground hover:text-foreground hover:underline">
                      {a.message}
                    </Link>
                  </li>
                ))}
              </ul>
            </Section>
          )}
        </div>
      </CardContent>

      <CompleteItemDialog row={logging} sessions={data.unlinkedSessions} onClose={() => setLogging(null)} />
      <CreatePlanDialog open={planOpen} onOpenChange={setPlanOpen} defaultDate={today} />
    </Card>
  );
}
