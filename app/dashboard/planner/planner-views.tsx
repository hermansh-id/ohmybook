"use client";

import { Link } from "@tanstack/react-router";
import { format } from "date-fns";
import { Flag, Plus } from "lucide-react";
import { Button } from "@/components/ui/button";
import { addDays, fromDateKey, toDateKey, weekDays, weekStartKey } from "@/lib/dates";
import { cn } from "@/lib/utils";
import type { PlannerItem, PlannerRange } from "@/lib/db/planning-reads";
import { PlanItemCard } from "@/components/planning/plan-item-card";

export interface ItemHandlers {
  onComplete: (row: PlannerItem) => void;
  onReschedule: (row: PlannerItem) => void;
  onEdit: (row: PlannerItem) => void;
}

interface ViewProps extends ItemHandlers {
  range: PlannerRange;
  onAdd: (date: string) => void;
}

function movedToDate(range: PlannerRange, row: PlannerItem) {
  const target = row.item.rescheduledToItemId;
  return target ? (range.items.find((r) => r.item.itemId === target)?.item.scheduledDate ?? null) : null;
}

/** Everything that happens on one day. */
export function DayDetail({
  date,
  range,
  compact,
  onAdd,
  onComplete,
  onReschedule,
  onEdit,
}: ViewProps & { date: string; compact?: boolean }) {
  const items = range.items.filter((r) => r.item.scheduledDate === date);
  const spontaneous = range.sessions.filter((s) => s.sessionDate === date && s.linkedItemId === null);
  const targets = range.targets.filter((t) => t.targetDate === date);
  const finished = range.finished.filter((f) => f.dateFinished === date);
  const empty = items.length === 0 && spontaneous.length === 0 && targets.length === 0 && finished.length === 0;

  return (
    <div className="space-y-2">
      {items.map((row) => (
        <PlanItemCard
          key={row.item.itemId}
          row={row}
          compact={compact}
          movedTo={movedToDate(range, row)}
          onComplete={onComplete}
          onReschedule={onReschedule}
          onEdit={onEdit}
        />
      ))}

      {spontaneous.map((s) => (
        <p key={s.sessionId} className="flex items-center gap-2 px-1 text-xs text-muted-foreground">
          <span className="size-2 shrink-0 rounded-full bg-zinc-400" />
          <span className="truncate">
            Also read{" "}
            <Link to="/dashboard/books/$bookId" params={{ bookId: String(s.bookId) }} className="text-foreground hover:underline">
              {s.title}
            </Link>
            {s.pagesRead ? `, ${s.pagesRead} pages` : ""}
          </span>
        </p>
      ))}

      {targets.map((t) => (
        <p key={t.priorityId} className="flex items-center gap-2 px-1 text-xs text-muted-foreground">
          <Flag className="size-3 shrink-0 text-amber-500" />
          <span className="truncate">Target date: {t.title}</span>
        </p>
      ))}

      {finished.map((f) => (
        <p key={f.bookId} className="flex items-center gap-2 px-1 text-xs text-muted-foreground">
          <span className="size-2 shrink-0 rounded-full bg-emerald-600" />
          <span className="truncate">Finished {f.title}</span>
        </p>
      ))}

      {empty && !compact && <p className="px-1 text-sm text-muted-foreground">Nothing planned.</p>}

      <Button variant="ghost" size="sm" className="h-9 w-full justify-start text-muted-foreground" onClick={() => onAdd(date)}>
        <Plus className="size-4" />
        Add
      </Button>
    </div>
  );
}

function DayHeading({ date, today }: { date: string; today: string }) {
  return (
    <h3 className="flex items-baseline gap-2 text-sm font-medium">
      {format(fromDateKey(date), "EEEE d MMM")}
      {date === today && <span className="text-xs font-normal text-sky-600 dark:text-sky-400">Today</span>}
    </h3>
  );
}

export function ListView({ weekStart, ...props }: ViewProps & { weekStart: string }) {
  const today = toDateKey(new Date());
  return (
    <div className="space-y-6">
      {weekDays(weekStart).map((date) => (
        <section key={date} className="space-y-2">
          <DayHeading date={date} today={today} />
          <DayDetail date={date} {...props} />
        </section>
      ))}
    </div>
  );
}

export function WeekView({ weekStart, ...props }: ViewProps & { weekStart: string }) {
  const today = toDateKey(new Date());
  return (
    <div className="grid gap-4 md:grid-cols-4 lg:grid-cols-7">
      {weekDays(weekStart).map((date) => (
        <section key={date} className={cn("min-w-0 space-y-2 rounded-lg border p-3", date === today && "border-sky-400/60")}>
          <DayHeading date={date} today={today} />
          <DayDetail date={date} compact {...props} />
        </section>
      ))}
    </div>
  );
}

function Legend() {
  return (
    <ul className="flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted-foreground">
      <li className="flex items-center gap-1.5">
        <span className="size-2.5 rounded-full border-2 border-sky-500" /> Planned
      </li>
      <li className="flex items-center gap-1.5">
        <span className="size-2.5 rounded-full bg-emerald-600" /> Done
      </li>
      <li className="flex items-center gap-1.5">
        <span className="size-2.5 rounded-full bg-zinc-400" /> Other reading
      </li>
      <li className="flex items-center gap-1.5">
        <Flag className="size-3 text-amber-500" /> Target date
      </li>
    </ul>
  );
}

export function MonthView({
  monthStart,
  selected,
  onSelect,
  range,
  ...handlers
}: ViewProps & { monthStart: string; selected: string; onSelect: (date: string) => void }) {
  const today = toDateKey(new Date());
  const gridStart = weekStartKey(monthStart);
  const cells = Array.from({ length: 42 }, (_, i) => addDays(gridStart, i));
  const month = monthStart.slice(0, 7);

  return (
    <div className="space-y-4">
      <div>
        <div className="grid grid-cols-7 pb-1 text-center text-xs text-muted-foreground">
          {["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].map((d) => (
            <div key={d}>{d}</div>
          ))}
        </div>
        <div className="grid grid-cols-7 gap-1">
          {cells.map((date) => {
            const items = range.items.filter((r) => r.item.scheduledDate === date);
            const planned = items.filter((r) => r.item.status === "planned").length;
            const done = items.filter((r) => r.item.status === "completed").length;
            const other = range.sessions.filter((s) => s.sessionDate === date && s.linkedItemId === null).length;
            const target = range.targets.some((t) => t.targetDate === date);
            const finished = range.finished.some((f) => f.dateFinished === date);
            return (
              <button
                key={date}
                type="button"
                onClick={() => onSelect(date)}
                aria-label={format(fromDateKey(date), "EEEE d MMMM")}
                aria-pressed={selected === date}
                className={cn(
                  "flex min-h-14 flex-col items-center gap-1 rounded-md border p-1 text-sm transition-colors hover:bg-accent sm:min-h-16",
                  !date.startsWith(month) && "text-muted-foreground/50",
                  date === today && "border-sky-400/70",
                  selected === date && "bg-accent ring-2 ring-ring",
                )}
              >
                <span className="text-xs sm:text-sm">{Number(date.slice(8))}</span>
                <span className="flex flex-wrap items-center justify-center gap-0.5">
                  {planned > 0 && <span className="size-2 rounded-full border-2 border-sky-500" />}
                  {done > 0 && <span className="size-2 rounded-full bg-emerald-600" />}
                  {other > 0 && <span className="size-2 rounded-full bg-zinc-400" />}
                  {finished && <span className="size-2 rounded-sm bg-emerald-600" />}
                  {target && <Flag className="size-2.5 text-amber-500" />}
                </span>
              </button>
            );
          })}
        </div>
      </div>
      <Legend />
      <section className="space-y-2 border-t pt-4">
        <DayHeading date={selected} today={today} />
        <DayDetail date={selected} range={range} {...handlers} />
      </section>
    </div>
  );
}
