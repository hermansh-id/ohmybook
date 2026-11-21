"use client";

import * as React from "react";
import { Link } from "@tanstack/react-router";
import { format } from "date-fns";
import { CalendarClock, MoreHorizontal, Plus } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { Progress } from "@/components/ui/progress";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { PriorityDialog, type PriorityDraft } from "@/components/priority-dialog";
import { fromDateKey, toDateKey } from "@/lib/dates";
import { LEVEL_META, PRIORITY_LEVELS, STATUS_LABEL, formatMinutes, type PriorityLevel } from "@/lib/planning-ui";
import {
  useCancelPriority,
  useCompletePriority,
  usePriorities,
  usePriorityChanges,
  useSetPriority,
} from "@/lib/queries/planning";

type Tab = "active" | "completed" | "cancelled";

export function PrioritiesClient() {
  const [tab, setTab] = React.useState<Tab>("active");
  const [dialogOpen, setDialogOpen] = React.useState(false);
  const [editing, setEditing] = React.useState<PriorityDraft | null>(null);

  const { data: rows = [], isLoading, error } = usePriorities(tab);
  const { data: changes = [] } = usePriorityChanges(8);
  const setPriority = useSetPriority();
  const complete = useCompletePriority();
  const cancel = useCancelPriority();
  const today = toDateKey(new Date());

  const grouped = PRIORITY_LEVELS.map((level) => ({
    level,
    items: rows.filter((r) => r.priority.level === level),
  })).filter((g) => g.items.length > 0);

  const openNew = () => {
    setEditing(null);
    setDialogOpen(true);
  };
  const openEdit = (r: (typeof rows)[number]) => {
    setEditing({
      bookId: r.bookId,
      title: r.title,
      level: r.priority.level as PriorityLevel,
      reason: r.priority.reason ?? "",
      targetDate: r.priority.targetDate ?? "",
      estimatedMinutes: r.priority.estimatedMinutes ? String(r.priority.estimatedMinutes) : "",
    });
    setDialogOpen(true);
  };

  return (
    <div className="flex flex-col gap-4 p-4 md:gap-6 md:p-6">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Reading priorities</h1>
          <p className="text-muted-foreground">
            What matters most to read, and why. Separate from what you are currently reading.
          </p>
        </div>
        <Button onClick={openNew} className="min-h-11 sm:min-h-9">
          <Plus className="size-4" />
          Prioritize a book
        </Button>
      </div>

      <Tabs value={tab} onValueChange={(v) => setTab(v as Tab)}>
        <TabsList>
          <TabsTrigger value="active">Active</TabsTrigger>
          <TabsTrigger value="completed">Completed</TabsTrigger>
          <TabsTrigger value="cancelled">Cancelled</TabsTrigger>
        </TabsList>
      </Tabs>

      {isLoading ? (
        <div className="space-y-3">
          {[0, 1, 2].map((i) => (
            <Skeleton key={i} className="h-24 w-full" />
          ))}
        </div>
      ) : error ? (
        <p className="text-sm text-muted-foreground">Could not load priorities. Please refresh.</p>
      ) : grouped.length === 0 ? (
        <div className="flex min-h-[240px] flex-col items-center justify-center gap-2 rounded-lg border border-dashed p-6 text-center">
          <p className="font-medium">{tab === "active" ? "No priorities yet" : `Nothing ${tab}`}</p>
          {tab === "active" && (
            <p className="max-w-sm text-sm text-muted-foreground">
              Pick the few books you want to read next and say why. You can change this any time.
            </p>
          )}
        </div>
      ) : (
        grouped.map(({ level, items }) => (
          <section key={level} className="space-y-2">
            <h2 className="flex items-center gap-2 text-sm font-medium uppercase tracking-wide text-muted-foreground">
              <span className={`size-2 rounded-full ${LEVEL_META[level].dot}`} />
              {LEVEL_META[level].label}
              <span className="font-normal">({items.length})</span>
            </h2>
            <div className="grid gap-3">
              {items.map((r) => {
                const overdue = tab === "active" && r.priority.targetDate && r.priority.targetDate < today && r.readingStatus !== "finished";
                const pct = r.pages && r.currentPage ? Math.min(100, Math.round((r.currentPage / r.pages) * 100)) : 0;
                return (
                  <Card key={r.priority.priorityId}>
                    <CardContent className="flex flex-col gap-3 pt-6 sm:flex-row sm:items-start sm:justify-between">
                      <div className="min-w-0 flex-1 space-y-1.5">
                        <Link
                          to="/dashboard/books/$bookId"
                          params={{ bookId: String(r.bookId) }}
                          className="block truncate font-medium hover:underline"
                        >
                          {r.title}
                        </Link>
                        {r.authors && <p className="truncate text-sm text-muted-foreground">{r.authors}</p>}
                        {r.priority.reason && <p className="text-sm">{r.priority.reason}</p>}
                        <div className="flex flex-wrap items-center gap-x-3 gap-y-1 pt-1 text-xs text-muted-foreground">
                          {r.readingStatus && <Badge variant="outline">{STATUS_LABEL[r.readingStatus] ?? r.readingStatus}</Badge>}
                          {r.priority.targetDate && (
                            <span className={`inline-flex items-center gap-1 ${overdue ? "text-amber-600 dark:text-amber-400" : ""}`}>
                              <CalendarClock className="size-3.5" />
                              {overdue ? "Past target: " : "Target "}
                              {format(fromDateKey(r.priority.targetDate), "d MMM yyyy")}
                            </span>
                          )}
                          {formatMinutes(r.priority.estimatedMinutes) && <span>~{formatMinutes(r.priority.estimatedMinutes)}</span>}
                        </div>
                        {r.readingStatus === "reading" && r.pages ? (
                          <div className="flex items-center gap-2 pt-1">
                            <Progress value={pct} className="h-1.5 max-w-48" />
                            <span className="text-xs text-muted-foreground">
                              {r.currentPage ?? 0}/{r.pages}
                            </span>
                          </div>
                        ) : null}
                        {tab === "active" && r.readingStatus === "finished" && (
                          <p className="pt-1 text-xs text-muted-foreground">
                            You finished this book. Mark the priority completed when you are ready.
                          </p>
                        )}
                      </div>

                      {tab === "active" && (
                        <div className="flex items-center gap-2 self-start">
                          <Select
                            value={r.priority.level}
                            onValueChange={(v) => setPriority.mutate({ bookId: r.bookId, level: v as PriorityLevel })}
                          >
                            <SelectTrigger className="min-h-11 w-32 sm:min-h-9" aria-label="Change priority">
                              <SelectValue />
                            </SelectTrigger>
                            <SelectContent>
                              {PRIORITY_LEVELS.map((l) => (
                                <SelectItem key={l} value={l}>
                                  {LEVEL_META[l].label}
                                </SelectItem>
                              ))}
                            </SelectContent>
                          </Select>
                          <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                              <Button variant="ghost" size="icon" className="size-11 sm:size-9" aria-label="More actions">
                                <MoreHorizontal className="size-4" />
                              </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align="end">
                              <DropdownMenuItem onSelect={() => openEdit(r)}>Edit details</DropdownMenuItem>
                              <DropdownMenuItem onSelect={() => complete.mutate(r.bookId)}>Mark completed</DropdownMenuItem>
                              <DropdownMenuItem onSelect={() => cancel.mutate(r.bookId)}>Cancel priority</DropdownMenuItem>
                            </DropdownMenuContent>
                          </DropdownMenu>
                        </div>
                      )}
                    </CardContent>
                  </Card>
                );
              })}
            </div>
          </section>
        ))
      )}

      {changes.length > 0 && (
        <section className="space-y-2 pt-2">
          <h2 className="text-sm font-medium uppercase tracking-wide text-muted-foreground">Recent changes</h2>
          <ul className="space-y-1 text-sm text-muted-foreground">
            {changes.map((c) => (
              <li key={c.historyId}>
                <span className="text-foreground">{c.title}</span>{" "}
                {c.fromLevel === null
                  ? `prioritized as ${LEVEL_META[c.toLevel as PriorityLevel]?.label ?? c.toLevel}`
                  : c.fromStatus === c.toStatus
                    ? `${LEVEL_META[c.fromLevel as PriorityLevel]?.label ?? c.fromLevel} to ${LEVEL_META[c.toLevel as PriorityLevel]?.label ?? c.toLevel}`
                    : `priority ${c.toStatus}`}
                {c.createdAt ? `, ${format(new Date(c.createdAt), "d MMM")}` : ""}
              </li>
            ))}
          </ul>
        </section>
      )}

      <PriorityDialog open={dialogOpen} onOpenChange={setDialogOpen} initial={editing} />
    </div>
  );
}
