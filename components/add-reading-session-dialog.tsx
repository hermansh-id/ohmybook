"use client";

import { useState } from "react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { AddReadingSessionForm } from "@/components/add-reading-session-form";
import { useQueryClient } from "@tanstack/react-query";

interface AddReadingSessionDialogProps {
  books: Array<{
    id: number;
    title: string;
    pages: number;
    currentPage: number;
    status: string;
  }>;
  trigger: React.ReactNode;
}

export function AddReadingSessionDialog({
  books,
  trigger,
}: AddReadingSessionDialogProps) {
  const queryClient = useQueryClient();
  const [open, setOpen] = useState(false);

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>{trigger}</DialogTrigger>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>Add Reading Session</DialogTitle>
          <DialogDescription>
            Track your reading for today with sliders
          </DialogDescription>
        </DialogHeader>

        <AddReadingSessionForm
          books={books}
          onSuccess={() => {
            setOpen(false);
            queryClient.invalidateQueries({ queryKey: ["reading-sessions"] });
            queryClient.invalidateQueries({ queryKey: ["unfinished-books"] });
            queryClient.invalidateQueries({ queryKey: ["dashboard"] });
          }}
        />
      </DialogContent>
    </Dialog>
  );
}
