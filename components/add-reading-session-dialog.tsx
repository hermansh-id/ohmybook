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
import { useRouter } from "next/navigation";

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
  const router = useRouter();
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
            router.refresh();
          }}
        />
      </DialogContent>
    </Dialog>
  );
}
