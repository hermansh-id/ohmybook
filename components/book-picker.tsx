"use client";

import * as React from "react";
import { Check, ChevronsUpDown } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Command, CommandEmpty, CommandInput, CommandItem, CommandList } from "@/components/ui/command";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { useAllBooks } from "@/lib/queries/books";
import { cn } from "@/lib/utils";

interface BookPickerProps {
  value: number | null;
  onChange: (bookId: number, title: string) => void;
  placeholder?: string;
  disabled?: boolean;
  className?: string;
}

/** Fast book selection from the existing library (type to filter). */
export function BookPicker({ value, onChange, placeholder = "Select a book", disabled, className }: BookPickerProps) {
  const [open, setOpen] = React.useState(false);
  const { data: books = [], isLoading } = useAllBooks();
  const selected = books.find((b) => b.bookId === value);

  return (
    <Popover open={open} onOpenChange={setOpen} modal>
      <PopoverTrigger asChild>
        <Button
          type="button"
          variant="outline"
          role="combobox"
          aria-expanded={open}
          disabled={disabled}
          className={cn("min-h-11 w-full justify-between font-normal", !selected && "text-muted-foreground", className)}
        >
          <span className="truncate">{selected?.title ?? (isLoading ? "Loading books..." : placeholder)}</span>
          <ChevronsUpDown className="ml-2 size-4 shrink-0 opacity-50" />
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-[--radix-popover-trigger-width] min-w-64 p-0" align="start">
        <Command>
          <CommandInput placeholder="Search your library..." />
          <CommandList>
            <CommandEmpty>No book found.</CommandEmpty>
            {books.map((b) => (
              <CommandItem
                key={b.bookId}
                value={`${b.title} ${b.bookId}`}
                onSelect={() => {
                  onChange(b.bookId, b.title);
                  setOpen(false);
                }}
              >
                <Check className={cn("mr-2 size-4", value === b.bookId ? "opacity-100" : "opacity-0")} />
                <span className="truncate">{b.title}</span>
              </CommandItem>
            ))}
          </CommandList>
        </Command>
      </PopoverContent>
    </Popover>
  );
}
