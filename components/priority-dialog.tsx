"use client";

import * as React from "react";
import { Button } from "@/components/ui/button";
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
import { BookPicker } from "@/components/book-picker";
import { LEVEL_META, PRIORITY_LEVELS, type PriorityLevel } from "@/lib/planning-ui";
import { useSetPriority } from "@/lib/queries/planning";

export interface PriorityDraft {
  bookId: number | null;
  title?: string;
  level: PriorityLevel;
  reason: string;
  targetDate: string;
  estimatedMinutes: string;
}

const EMPTY: PriorityDraft = { bookId: null, level: "medium", reason: "", targetDate: "", estimatedMinutes: "" };

interface PriorityDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  /** When set, the book is fixed and the dialog edits that book's priority. */
  initial?: PriorityDraft | null;
}

export function PriorityDialog({ open, onOpenChange, initial }: PriorityDialogProps) {
  const [draft, setDraft] = React.useState<PriorityDraft>(EMPTY);
  const setPriority = useSetPriority();
  const editing = !!initial?.bookId;

  React.useEffect(() => {
    if (open) setDraft(initial ?? EMPTY);
  }, [open, initial]);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!draft.bookId) return;
    const minutes = draft.estimatedMinutes.trim() ? Number(draft.estimatedMinutes) : null;
    await setPriority.mutateAsync({
      bookId: draft.bookId,
      level: draft.level,
      reason: draft.reason.trim() || null,
      targetDate: draft.targetDate || null,
      estimatedMinutes: minutes,
    });
    onOpenChange(false);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-md">
        <DialogHeader>
          <DialogTitle>{editing ? "Edit priority" : "Prioritize a book"}</DialogTitle>
          <DialogDescription>
            Priority is separate from reading status. Change it whenever your plans change.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={submit} className="space-y-4">
          <div className="space-y-2">
            <Label>Book</Label>
            {editing ? (
              <p className="text-sm font-medium">{draft.title}</p>
            ) : (
              <BookPicker value={draft.bookId} onChange={(bookId, title) => setDraft((d) => ({ ...d, bookId, title }))} />
            )}
          </div>

          <div className="space-y-2">
            <Label>Priority</Label>
            <Select value={draft.level} onValueChange={(v) => setDraft((d) => ({ ...d, level: v as PriorityLevel }))}>
              <SelectTrigger className="min-h-11 w-full">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {PRIORITY_LEVELS.map((l) => (
                  <SelectItem key={l} value={l}>
                    <span className="flex items-center gap-2">
                      <span className={`size-2 rounded-full ${LEVEL_META[l].dot}`} />
                      {LEVEL_META[l].label}
                    </span>
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-2">
            <Label htmlFor="priority-reason">Why this book?</Label>
            <Textarea
              id="priority-reason"
              rows={2}
              placeholder="Long-standing wishlist, book club, casual reading..."
              value={draft.reason}
              onChange={(e) => setDraft((d) => ({ ...d, reason: e.target.value }))}
            />
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-2">
              <Label htmlFor="priority-target">Target date (optional)</Label>
              <Input
                id="priority-target"
                type="date"
                className="min-h-11"
                value={draft.targetDate}
                onChange={(e) => setDraft((d) => ({ ...d, targetDate: e.target.value }))}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="priority-minutes">Estimated minutes (optional)</Label>
              <Input
                id="priority-minutes"
                type="number"
                min={1}
                inputMode="numeric"
                className="min-h-11"
                placeholder="e.g. 360"
                value={draft.estimatedMinutes}
                onChange={(e) => setDraft((d) => ({ ...d, estimatedMinutes: e.target.value }))}
              />
            </div>
          </div>

          <DialogFooter className="gap-2 sm:gap-0">
            <Button type="button" variant="ghost" onClick={() => onOpenChange(false)}>
              Cancel
            </Button>
            <Button type="submit" disabled={!draft.bookId || setPriority.isPending}>
              {setPriority.isPending ? "Saving..." : "Save"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
