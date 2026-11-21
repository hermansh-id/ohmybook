"use client";

import * as React from "react";
import { format } from "date-fns";
import { Plus, X } from "lucide-react";
import { BookPicker } from "@/components/book-picker";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group";
import { addDays, fromDateKey, toDateKey, weekStartKey, weekendOf } from "@/lib/dates";
import { TIMES_OF_DAY, TIME_LABEL, plannedLabel, type TimeOfDay } from "@/lib/planning-ui";
import {
  useAddPlanItems,
  useCompletePlanItem,
  useReschedulePlanItem,
  useUpdatePlanItem,
} from "@/lib/queries/planning";
import type { PlannerItem, PlannerSession } from "@/lib/db/planning-reads";

const intOrUndef = (v: string) => (v.trim() === "" ? undefined : Math.max(0, Math.floor(Number(v))));
const intOrNull = (v: string) => (v.trim() === "" ? null : Math.max(0, Math.floor(Number(v))));

function TimeOfDaySelect({ value, onChange }: { value: TimeOfDay; onChange: (v: TimeOfDay) => void }) {
  return (
    <Select value={value} onValueChange={(v) => onChange(v as TimeOfDay)}>
      <SelectTrigger className="min-h-11 w-full">
        <SelectValue />
      </SelectTrigger>
      <SelectContent>
        {TIMES_OF_DAY.map((t) => (
          <SelectItem key={t} value={t}>
            {TIME_LABEL[t]}
          </SelectItem>
        ))}
      </SelectContent>
    </Select>
  );
}

const WEEKDAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

// ============================================================================
// Plan reading (single item, optional repeat)
// ============================================================================
export function CreatePlanDialog({
  open,
  onOpenChange,
  defaultDate,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  defaultDate: string;
}) {
  const add = useAddPlanItems();
  const [bookId, setBookId] = React.useState<number | null>(null);
  const [date, setDate] = React.useState(defaultDate);
  const [time, setTime] = React.useState<TimeOfDay>("anytime");
  const [pages, setPages] = React.useState("");
  const [minutes, setMinutes] = React.useState("");
  const [startPage, setStartPage] = React.useState("");
  const [endPage, setEndPage] = React.useState("");
  const [notes, setNotes] = React.useState("");
  const [repeat, setRepeat] = React.useState(false);
  const [weekdays, setWeekdays] = React.useState<string[]>([]);
  const [weeks, setWeeks] = React.useState("4");

  React.useEffect(() => {
    if (!open) return;
    setBookId(null);
    setDate(defaultDate);
    setTime("anytime");
    setPages("");
    setMinutes("");
    setStartPage("");
    setEndPage("");
    setNotes("");
    setRepeat(false);
    setWeekdays([]);
    setWeeks("4");
  }, [open, defaultDate]);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!bookId) return;
    await add.mutateAsync({
      items: [
        {
          bookId,
          scheduledDate: date,
          timeOfDay: time,
          plannedPages: intOrNull(pages),
          plannedMinutes: intOrNull(minutes),
          plannedStartPage: intOrNull(startPage),
          plannedEndPage: intOrNull(endPage),
          notes: notes.trim() || null,
        },
      ],
      repeat: repeat ? { weekdays: weekdays.map(Number), weeks: Number(weeks) || 1 } : undefined,
    });
    onOpenChange(false);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Plan some reading</DialogTitle>
          <DialogDescription>A gentle intention, not a rule. You can move or skip it later.</DialogDescription>
        </DialogHeader>
        <form onSubmit={submit} className="space-y-4">
          <div className="space-y-2">
            <Label>Book</Label>
            <BookPicker value={bookId} onChange={(id) => setBookId(id)} />
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-2">
              <Label htmlFor="plan-date">Day</Label>
              <Input id="plan-date" type="date" required className="min-h-11" value={date} onChange={(e) => setDate(e.target.value)} />
            </div>
            <div className="space-y-2">
              <Label>Time of day</Label>
              <TimeOfDaySelect value={time} onChange={setTime} />
            </div>
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-2">
              <Label htmlFor="plan-pages">Pages</Label>
              <Input id="plan-pages" type="number" min={0} inputMode="numeric" className="min-h-11" placeholder="e.g. 30" value={pages} onChange={(e) => setPages(e.target.value)} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="plan-minutes">Minutes</Label>
              <Input id="plan-minutes" type="number" min={0} inputMode="numeric" className="min-h-11" placeholder="e.g. 45" value={minutes} onChange={(e) => setMinutes(e.target.value)} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="plan-start">From page (optional)</Label>
              <Input id="plan-start" type="number" min={0} inputMode="numeric" className="min-h-11" value={startPage} onChange={(e) => setStartPage(e.target.value)} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="plan-end">To page (optional)</Label>
              <Input id="plan-end" type="number" min={0} inputMode="numeric" className="min-h-11" value={endPage} onChange={(e) => setEndPage(e.target.value)} />
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="plan-notes">Notes</Label>
            <Textarea id="plan-notes" rows={2} placeholder="One short story, chapter 5..." value={notes} onChange={(e) => setNotes(e.target.value)} />
          </div>

          <div className="space-y-3 rounded-lg border p-3">
            <label className="flex min-h-8 cursor-pointer items-center gap-2 text-sm font-medium">
              <Checkbox checked={repeat} onCheckedChange={(v) => setRepeat(v === true)} />
              Repeat
            </label>
            {repeat && (
              <div className="space-y-3">
                <ToggleGroup
                  type="multiple"
                  variant="outline"
                  value={weekdays}
                  onValueChange={setWeekdays}
                  className="flex w-full flex-wrap justify-start"
                >
                  {WEEKDAYS.map((d, i) => (
                    <ToggleGroupItem key={d} value={String(i)} className="min-h-10 min-w-10 px-2" aria-label={d}>
                      {d}
                    </ToggleGroupItem>
                  ))}
                </ToggleGroup>
                <div className="flex items-center gap-2 text-sm">
                  <span>for</span>
                  <Input type="number" min={1} max={26} inputMode="numeric" className="min-h-10 w-20" value={weeks} onChange={(e) => setWeeks(e.target.value)} aria-label="Number of weeks" />
                  <span>weeks, starting from the day above</span>
                </div>
              </div>
            )}
          </div>

          <DialogFooter className="gap-2 sm:gap-0">
            <Button type="button" variant="ghost" onClick={() => onOpenChange(false)}>
              Cancel
            </Button>
            <Button type="submit" disabled={!bookId || add.isPending || (repeat && weekdays.length === 0)}>
              {add.isPending ? "Saving..." : "Add to plan"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

// ============================================================================
// Weekend plan (several books across Saturday and Sunday)
// ============================================================================
interface WeekendRow {
  day: 0 | 1; // 0 = Saturday, 1 = Sunday
  time: TimeOfDay;
  bookId: number | null;
  pages: string;
}

const newRow = (day: 0 | 1 = 0, time: TimeOfDay = "morning"): WeekendRow => ({ day, time, bookId: null, pages: "" });

export function WeekendPlanDialog({
  open,
  onOpenChange,
  weekStart,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  /** Monday of the week whose weekend is planned. */
  weekStart: string;
}) {
  const add = useAddPlanItems();
  const [rows, setRows] = React.useState<WeekendRow[]>([newRow(0, "morning"), newRow(1, "morning")]);
  const [sat, sun] = weekendOf(weekStart);

  React.useEffect(() => {
    if (open) setRows([newRow(0, "morning"), newRow(1, "morning")]);
  }, [open]);

  const update = (i: number, patch: Partial<WeekendRow>) => setRows((rs) => rs.map((r, idx) => (idx === i ? { ...r, ...patch } : r)));
  const valid = rows.filter((r) => r.bookId);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (valid.length === 0) return;
    await add.mutateAsync({
      plan: { title: "Weekend reading", kind: "weekend", startDate: sat, endDate: sun },
      items: valid.map((r) => ({
        bookId: r.bookId as number,
        scheduledDate: r.day === 0 ? sat : sun,
        timeOfDay: r.time,
        plannedPages: intOrNull(r.pages),
      })),
    });
    onOpenChange(false);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Weekend reading plan</DialogTitle>
          <DialogDescription>
            {format(fromDateKey(sat), "EEE d MMM")} and {format(fromDateKey(sun), "EEE d MMM")}. Add as many or as few as feels right.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={submit} className="space-y-3">
          {rows.map((r, i) => (
            <div key={i} className="space-y-2 rounded-lg border p-3">
              <div className="flex items-center gap-2">
                <Select value={String(r.day)} onValueChange={(v) => update(i, { day: Number(v) as 0 | 1 })}>
                  <SelectTrigger className="min-h-11 w-32">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="0">Saturday</SelectItem>
                    <SelectItem value="1">Sunday</SelectItem>
                  </SelectContent>
                </Select>
                <div className="flex-1">
                  <TimeOfDaySelect value={r.time} onChange={(time) => update(i, { time })} />
                </div>
                {rows.length > 1 && (
                  <Button type="button" variant="ghost" size="icon" className="size-11 shrink-0" aria-label="Remove row" onClick={() => setRows((rs) => rs.filter((_, idx) => idx !== i))}>
                    <X className="size-4" />
                  </Button>
                )}
              </div>
              <div className="flex gap-2">
                <div className="min-w-0 flex-1">
                  <BookPicker value={r.bookId} onChange={(id) => update(i, { bookId: id })} />
                </div>
                <Input
                  type="number"
                  min={0}
                  inputMode="numeric"
                  className="min-h-11 w-24"
                  placeholder="pages"
                  aria-label="Pages"
                  value={r.pages}
                  onChange={(e) => update(i, { pages: e.target.value })}
                />
              </div>
            </div>
          ))}
          <Button type="button" variant="outline" className="min-h-11 w-full sm:min-h-9" onClick={() => setRows((rs) => [...rs, newRow(0, "afternoon")])}>
            <Plus className="size-4" />
            Add another
          </Button>
          <DialogFooter className="gap-2 sm:gap-0">
            <Button type="button" variant="ghost" onClick={() => onOpenChange(false)}>
              Cancel
            </Button>
            <Button type="submit" disabled={valid.length === 0 || add.isPending}>
              {add.isPending ? "Saving..." : `Add ${valid.length || ""} to plan`.replace("  ", " ")}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

// ============================================================================
// Log a planned activity as done (never duplicates a session)
// ============================================================================
export function CompleteItemDialog({
  row,
  sessions,
  onClose,
}: {
  row: PlannerItem | null;
  /** Sessions loaded for the visible range, used to offer linking an existing one. */
  sessions: PlannerSession[];
  onClose: () => void;
}) {
  const complete = useCompletePlanItem();
  const [pages, setPages] = React.useState("");
  const [minutes, setMinutes] = React.useState("");
  const [date, setDate] = React.useState("");
  const [notes, setNotes] = React.useState("");
  const [link, setLink] = React.useState("new");

  React.useEffect(() => {
    if (!row) return;
    setPages(row.item.plannedPages != null ? String(row.item.plannedPages) : "");
    setMinutes(row.item.plannedMinutes != null ? String(row.item.plannedMinutes) : "");
    setDate(toDateKey(new Date()));
    setNotes("");
    setLink("new");
  }, [row]);

  const candidates = row ? sessions.filter((s) => s.bookId === row.bookId && s.linkedItemId === null) : [];

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!row) return;
    if (link !== "new") {
      await complete.mutateAsync({ itemId: row.item.itemId, linkSessionId: Number(link) });
    } else {
      await complete.mutateAsync({
        itemId: row.item.itemId,
        actualPages: intOrUndef(pages),
        actualMinutes: intOrUndef(minutes),
        sessionDate: date,
        notes: notes.trim() || undefined,
      });
    }
    onClose();
  };

  return (
    <Dialog open={!!row} onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Log reading</DialogTitle>
          <DialogDescription>
            {row?.title}
            {row && plannedLabel(row.item) ? ` · planned ${plannedLabel(row.item)}` : ""}. Your original plan is kept so you can compare later.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={submit} className="space-y-4">
          {candidates.length > 0 && (
            <div className="space-y-2">
              <Label>Reading session</Label>
              <Select value={link} onValueChange={setLink}>
                <SelectTrigger className="min-h-11 w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="new">Record a new session</SelectItem>
                  {candidates.map((s) => (
                    <SelectItem key={s.sessionId} value={String(s.sessionId)}>
                      Use the session I already logged: {format(fromDateKey(s.sessionDate), "d MMM")}
                      {s.pagesRead != null ? `, ${s.pagesRead} pages` : ""}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          )}

          {link === "new" && (
            <>
              <div className="grid gap-4 sm:grid-cols-2">
                <div className="space-y-2">
                  <Label htmlFor="done-pages">Pages read</Label>
                  <Input id="done-pages" type="number" min={0} inputMode="numeric" className="min-h-11" value={pages} onChange={(e) => setPages(e.target.value)} />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="done-minutes">Minutes</Label>
                  <Input id="done-minutes" type="number" min={0} inputMode="numeric" className="min-h-11" value={minutes} onChange={(e) => setMinutes(e.target.value)} />
                </div>
              </div>
              <div className="space-y-2">
                <Label htmlFor="done-date">Day you read</Label>
                <Input id="done-date" type="date" required className="min-h-11" value={date} onChange={(e) => setDate(e.target.value)} />
              </div>
              <div className="space-y-2">
                <Label htmlFor="done-notes">Notes</Label>
                <Textarea id="done-notes" rows={2} value={notes} onChange={(e) => setNotes(e.target.value)} />
              </div>
            </>
          )}

          <DialogFooter className="gap-2 sm:gap-0">
            <Button type="button" variant="ghost" onClick={onClose}>
              Cancel
            </Button>
            <Button type="submit" disabled={complete.isPending}>
              {complete.isPending ? "Saving..." : "Save"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

// ============================================================================
// Reschedule
// ============================================================================
export function RescheduleDialog({ row, onClose }: { row: PlannerItem | null; onClose: () => void }) {
  const reschedule = useReschedulePlanItem();
  const [date, setDate] = React.useState("");
  const [time, setTime] = React.useState<TimeOfDay>("anytime");

  React.useEffect(() => {
    if (!row) return;
    setDate(addDays(row.item.scheduledDate, 1));
    setTime(row.item.timeOfDay as TimeOfDay);
  }, [row]);

  const today = toDateKey(new Date());
  const quick = [
    { label: "Tomorrow", date: addDays(today, 1) },
    { label: "This weekend", date: weekendOf(weekStartKey(today))[0] >= today ? weekendOf(weekStartKey(today))[0] : today },
    { label: "Next Monday", date: addDays(weekStartKey(today), 7) },
  ];

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!row) return;
    await reschedule.mutateAsync({ itemId: row.item.itemId, scheduledDate: date, timeOfDay: time });
    onClose();
  };

  return (
    <Dialog open={!!row} onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="sm:max-w-sm">
        <DialogHeader>
          <DialogTitle>Move to another day</DialogTitle>
          <DialogDescription>{row?.title}</DialogDescription>
        </DialogHeader>
        <form onSubmit={submit} className="space-y-4">
          <div className="flex flex-wrap gap-2">
            {quick.map((q) => (
              <Button key={q.label} type="button" variant="outline" size="sm" className="min-h-9" onClick={() => setDate(q.date)}>
                {q.label}
              </Button>
            ))}
          </div>
          <div className="space-y-2">
            <Label htmlFor="resched-date">Day</Label>
            <Input id="resched-date" type="date" required className="min-h-11" value={date} onChange={(e) => setDate(e.target.value)} />
          </div>
          <div className="space-y-2">
            <Label>Time of day</Label>
            <TimeOfDaySelect value={time} onChange={setTime} />
          </div>
          <DialogFooter className="gap-2 sm:gap-0">
            <Button type="button" variant="ghost" onClick={onClose}>
              Cancel
            </Button>
            <Button type="submit" disabled={reschedule.isPending}>
              {reschedule.isPending ? "Saving..." : "Move"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

// ============================================================================
// Edit what is still planned
// ============================================================================
export function EditItemDialog({ row, onClose }: { row: PlannerItem | null; onClose: () => void }) {
  const update = useUpdatePlanItem();
  const [time, setTime] = React.useState<TimeOfDay>("anytime");
  const [pages, setPages] = React.useState("");
  const [minutes, setMinutes] = React.useState("");
  const [startPage, setStartPage] = React.useState("");
  const [endPage, setEndPage] = React.useState("");
  const [notes, setNotes] = React.useState("");

  React.useEffect(() => {
    if (!row) return;
    const i = row.item;
    setTime(i.timeOfDay as TimeOfDay);
    setPages(i.plannedPages != null ? String(i.plannedPages) : "");
    setMinutes(i.plannedMinutes != null ? String(i.plannedMinutes) : "");
    setStartPage(i.plannedStartPage != null ? String(i.plannedStartPage) : "");
    setEndPage(i.plannedEndPage != null ? String(i.plannedEndPage) : "");
    setNotes(i.notes ?? "");
  }, [row]);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!row) return;
    await update.mutateAsync({
      itemId: row.item.itemId,
      patch: {
        timeOfDay: time,
        plannedPages: intOrNull(pages),
        plannedMinutes: intOrNull(minutes),
        plannedStartPage: intOrNull(startPage),
        plannedEndPage: intOrNull(endPage),
        notes: notes.trim() || null,
      },
    });
    onClose();
  };

  return (
    <Dialog open={!!row} onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Edit plan</DialogTitle>
          <DialogDescription>{row?.title}</DialogDescription>
        </DialogHeader>
        <form onSubmit={submit} className="space-y-4">
          <div className="space-y-2">
            <Label>Time of day</Label>
            <TimeOfDaySelect value={time} onChange={setTime} />
          </div>
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-2">
              <Label htmlFor="edit-pages">Pages</Label>
              <Input id="edit-pages" type="number" min={0} inputMode="numeric" className="min-h-11" value={pages} onChange={(e) => setPages(e.target.value)} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="edit-minutes">Minutes</Label>
              <Input id="edit-minutes" type="number" min={0} inputMode="numeric" className="min-h-11" value={minutes} onChange={(e) => setMinutes(e.target.value)} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="edit-start">From page</Label>
              <Input id="edit-start" type="number" min={0} inputMode="numeric" className="min-h-11" value={startPage} onChange={(e) => setStartPage(e.target.value)} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="edit-end">To page</Label>
              <Input id="edit-end" type="number" min={0} inputMode="numeric" className="min-h-11" value={endPage} onChange={(e) => setEndPage(e.target.value)} />
            </div>
          </div>
          <div className="space-y-2">
            <Label htmlFor="edit-notes">Notes</Label>
            <Textarea id="edit-notes" rows={2} value={notes} onChange={(e) => setNotes(e.target.value)} />
          </div>
          <DialogFooter className="gap-2 sm:gap-0">
            <Button type="button" variant="ghost" onClick={onClose}>
              Cancel
            </Button>
            <Button type="submit" disabled={update.isPending}>
              {update.isPending ? "Saving..." : "Save"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
