"use client";

import * as React from "react";
import { format } from "date-fns";
import { CalendarPlus, ChevronLeft, ChevronRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { addDays, fromDateKey, toDateKey, weekStartKey } from "@/lib/dates";
import { usePlanner } from "@/lib/queries/planning";
import type { PlannerItem } from "@/lib/db/planning-reads";
import { CompleteItemDialog, CreatePlanDialog, EditItemDialog, RescheduleDialog, WeekendPlanDialog } from "./plan-dialogs";
import { ListView, MonthView, WeekView } from "./planner-views";

type View = "list" | "week" | "month";

const firstOfMonth = (key: string) => `${key.slice(0, 7)}-01`;

function shiftMonth(key: string, delta: number) {
  const d = fromDateKey(firstOfMonth(key));
  d.setMonth(d.getMonth() + delta);
  return toDateKey(d);
}

export function PlannerClient() {
  const [view, setView] = React.useState<View>("list");
  const [anchor, setAnchor] = React.useState(() => toDateKey(new Date()));
  const [selectedDay, setSelectedDay] = React.useState(() => toDateKey(new Date()));

  const [createDate, setCreateDate] = React.useState<string | null>(null);
  const [weekendOpen, setWeekendOpen] = React.useState(false);
  const [completing, setCompleting] = React.useState<PlannerItem | null>(null);
  const [rescheduling, setRescheduling] = React.useState<PlannerItem | null>(null);
  const [editing, setEditing] = React.useState<PlannerItem | null>(null);

  const today = toDateKey(new Date());
  const weekStart = weekStartKey(anchor);
  const monthStart = firstOfMonth(anchor);

  const [from, to] =
    view === "month"
      ? [weekStartKey(monthStart), addDays(weekStartKey(monthStart), 41)]
      : [weekStart, addDays(weekStart, 6)];

  const { data: range, isLoading, error } = usePlanner(from, to);

  const label =
    view === "month"
      ? format(fromDateKey(monthStart), "MMMM yyyy")
      : `${format(fromDateKey(weekStart), "d MMM")} - ${format(fromDateKey(addDays(weekStart, 6)), "d MMM yyyy")}`;

  const move = (dir: -1 | 1) => {
    if (view === "month") {
      const next = shiftMonth(anchor, dir);
      setAnchor(next);
      setSelectedDay(next);
    } else {
      setAnchor(addDays(anchor, dir * 7));
    }
  };
  const goToday = () => {
    setAnchor(today);
    setSelectedDay(today);
  };

  const handlers = { onComplete: setCompleting, onReschedule: setRescheduling, onEdit: setEditing };
  const onAdd = (date: string) => setCreateDate(date);

  return (
    <div className="flex flex-col gap-4 p-4 md:gap-6 md:p-6">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Reading planner</h1>
          <p className="text-muted-foreground">Plan the reading you would like to do. Move or skip anything, any time.</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" className="min-h-11 flex-1 sm:min-h-9 sm:flex-none" onClick={() => setWeekendOpen(true)}>
            <CalendarPlus className="size-4" />
            Weekend plan
          </Button>
          <Button className="min-h-11 flex-1 sm:min-h-9 sm:flex-none" onClick={() => onAdd(view === "month" ? selectedDay : today)}>
            Plan reading
          </Button>
        </div>
      </div>

      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <Tabs
          value={view}
          onValueChange={(v) => {
            setView(v as View);
            if (v === "month") setSelectedDay(anchor);
          }}
        >
          <TabsList>
            <TabsTrigger value="list">List</TabsTrigger>
            <TabsTrigger value="week">Week</TabsTrigger>
            <TabsTrigger value="month">Month</TabsTrigger>
          </TabsList>
        </Tabs>
        <div className="flex items-center gap-1">
          <Button variant="outline" size="icon" className="size-11 sm:size-9" onClick={() => move(-1)} aria-label="Previous">
            <ChevronLeft className="size-4" />
          </Button>
          <Button variant="outline" className="min-h-11 min-w-36 sm:min-h-9" onClick={goToday}>
            {label}
          </Button>
          <Button variant="outline" size="icon" className="size-11 sm:size-9" onClick={() => move(1)} aria-label="Next">
            <ChevronRight className="size-4" />
          </Button>
        </div>
      </div>

      {isLoading && !range ? (
        <div className="space-y-3">
          {[0, 1, 2].map((i) => (
            <Skeleton key={i} className="h-20 w-full" />
          ))}
        </div>
      ) : error || !range ? (
        <p className="text-sm text-muted-foreground">Could not load your plan. Please refresh.</p>
      ) : view === "list" ? (
        <ListView range={range} weekStart={weekStart} onAdd={onAdd} {...handlers} />
      ) : view === "week" ? (
        <WeekView range={range} weekStart={weekStart} onAdd={onAdd} {...handlers} />
      ) : (
        <MonthView range={range} monthStart={monthStart} selected={selectedDay} onSelect={setSelectedDay} onAdd={onAdd} {...handlers} />
      )}

      <CreatePlanDialog
        open={createDate !== null}
        onOpenChange={(o) => !o && setCreateDate(null)}
        defaultDate={createDate ?? today}
      />
      <WeekendPlanDialog open={weekendOpen} onOpenChange={setWeekendOpen} weekStart={weekStart} />
      <CompleteItemDialog row={completing} sessions={range?.sessions ?? []} onClose={() => setCompleting(null)} />
      <RescheduleDialog row={rescheduling} onClose={() => setRescheduling(null)} />
      <EditItemDialog row={editing} onClose={() => setEditing(null)} />
    </div>
  );
}
