"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Plus } from "lucide-react";
import { QuoteForm } from "./quote-form";

interface AddQuoteButtonProps {
  variant?: "default" | "outline" | "ghost";
}

export function AddQuoteButton({ variant = "outline" }: AddQuoteButtonProps) {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <DialogTrigger asChild>
        <Button variant={variant} size="sm">
          <Plus className="h-4 w-4 mr-2" />
          Add Quote
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-[600px] max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Add New Quote</DialogTitle>
          <DialogDescription>
            Save a memorable quote or passage from a book
          </DialogDescription>
        </DialogHeader>
        <QuoteForm onSuccess={() => setIsOpen(false)} />
      </DialogContent>
    </Dialog>
  );
}
