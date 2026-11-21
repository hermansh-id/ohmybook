"use client";

import { Link } from "@tanstack/react-router";
import { format } from "date-fns";
import { Check, CircleDashed, MoreHorizontal, MoveRight, SkipForward } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { fromDateKey } from "@/lib/dates";
import { TIME_LABEL, actualLabel, plannedLabel, type TimeOfDay } from "@/lib/planning-ui";
import { useDeletePlanItem, useReopenPlanItem, useSkipPlanItem } from "@/lib/queries/planning";
import type { PlannerItem } from "@/lib/db/planning-reads";
import { cn } from "@/lib/utils";

interface PlanItemCardProps {
  row: PlannerItem;
  /** Where a rescheduled item went (looked up from the loaded range, may be unknown). */
  movedTo?: string | null;
  compact?: boolean;
  onComplete: (row: PlannerItem) => void;
  onReschedule: (row: PlannerItem) => void;
  onEdit: (row: PlannerItem) => void;
}

export function PlanItemCard({ row, movedTo, compact, onComplete, onReschedule, onEdit }: PlanItemCardProps) {
  const { item } = row;
  const skip = useSkipPlanItem();
  const reopen = useReopenPlanItem();
  const remove = useDeletePlanItem();

  const planned = plannedLabel(item);
  const actual = item.status === "completed" ? actualLabel(item) : "";
  const done = item.status === "completed";
  const inactive = item.status === "skipped" || item.status === "rescheduled";

  return (
    <div
      className={cn(
        "rounded-lg border bg-card border-l-4 p-3",
        item.status === "planned" && "border-l-sky-400",
        done && "border-l-emerald-500",
        inactive && "border-l-zinc-300 opacity-70 dark:border-l-zinc-600",
      )}
    >
      <div className="flex items-start justify-between gap-2">
        <div className="min-w-0 flex-1">
          <Link
            to="/dashboard/books/$bookId"
            params={{ bookId: String(row.bookId) }}
            className={cn("block truncate text-sm font-medium hover:underline", item.status === "skipped" && "line-through")}
          >
            {row.title}
          </Link>
          <p className="mt-0.5 text-xs text-muted-foreground">
            {TIME_LABEL[item.timeOfDay as TimeOfDay] ?? item.timeOfDay}
            {planned ? ` · ${planned}` : ""}
          </p>
        </div>

        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" size="icon" className="-mr-1 -mt-1 size-10 shrink-0 sm:size-8" aria-label="Item actions">
              <MoreHorizontal className="size-4" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            {(item.status === "planned" || item.status === "skipped") && (
              <DropdownMenuItem onSelect={() => onComplete(row)}>Log as done</DropdownMenuItem>
            )}
            {item.status === "planned" && (
              <>
                <DropdownMenuItem onSelect={() => onEdit(row)}>Edit</DropdownMenuItem>
                <DropdownMenuItem onSelect={() => onReschedule(row)}>Reschedule</DropdownMenuItem>
                <DropdownMenuItem onSelect={() => skip.mutate({ itemId: item.itemId })}>Skip</DropdownMenuItem>
              </>
            )}
            {item.status === "skipped" && (
              <>
                <DropdownMenuItem onSelect={() => reopen.mutate({ itemId: item.itemId })}>Put back on plan</DropdownMenuItem>
                <DropdownMenuItem onSelect={() => onReschedule(row)}>Reschedule</DropdownMenuItem>
              </>
            )}
            {item.status !== "completed" && (
              <>
                <DropdownMenuSeparator />
                <DropdownMenuItem onSelect={() => remove.mutate({ itemId: item.itemId })}>Remove</DropdownMenuItem>
              </>
            )}
          </DropdownMenuContent>
        </DropdownMenu>
      </div>

      {!compact && item.notes && <p className="mt-1.5 text-sm text-muted-foreground">{item.notes}</p>}

      <div className="mt-2 flex flex-wrap items-center gap-2 text-xs">
        {item.status === "planned" && (
          <Badge variant="outline" className="gap-1 font-normal">
            <CircleDashed className="size-3" />
            Planned
          </Badge>
        )}
        {done && (
          <Badge variant="outline" className="gap-1 border-emerald-500/50 font-normal text-emerald-700 dark:text-emerald-400">
            <Check className="size-3" />
            Done{actual ? `: ${actual}` : ""}
          </Badge>
        )}
        {item.status === "skipped" && (
          <Badge variant="outline" className="gap-1 font-normal">
            <SkipForward className="size-3" />
            Skipped
          </Badge>
        )}
        {item.status === "rescheduled" && (
          <Badge variant="outline" className="gap-1 font-normal">
            <MoveRight className="size-3" />
            Moved{movedTo ? ` to ${format(fromDateKey(movedTo), "EEE d MMM")}` : ""}
          </Badge>
        )}
        {item.status === "planned" && !compact && (
          <Button variant="ghost" size="sm" className="h-7 px-2 text-xs" onClick={() => onComplete(row)}>
            Log as done
          </Button>
        )}
      </div>
    </div>
  );
}
