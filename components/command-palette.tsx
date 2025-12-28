"use client";

import { useEffect, useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import { Command } from "cmdk";
import { searchBooksAction } from "@/app/actions/search";
import {
  Dialog,
  DialogContent,
} from "@/components/ui/dialog";
import {
  BookOpen,
  Calendar,
  Home,
  Settings,
  TrendingUp,
  Users,
  BarChart3,
  Lightbulb,
  Notebook,
  Plus,
  Search,
} from "lucide-react";
import { Badge } from "@/components/ui/badge";

interface SearchResult {
  bookId: number;
  title: string;
  isbn: string | null;
  pages: number | null;
  year: number | null;
  authorName: string;
  status: string | null;
}

export function CommandPalette() {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [search, setSearch] = useState("");
  const [searchResults, setSearchResults] = useState<SearchResult[]>([]);
  const [isSearching, setIsSearching] = useState(false);

  // Toggle command palette with Cmd+K or Ctrl+K
  useEffect(() => {
    const down = (e: KeyboardEvent) => {
      if (e.key === "k" && (e.metaKey || e.ctrlKey)) {
        e.preventDefault();
        setOpen((open) => !open);
      }
    };

    document.addEventListener("keydown", down);
    return () => document.removeEventListener("keydown", down);
  }, []);

  // Search books when query changes
  useEffect(() => {
    const searchBooks = async () => {
      if (search.length < 2) {
        setSearchResults([]);
        return;
      }

      setIsSearching(true);
      const results = await searchBooksAction(search);
      setSearchResults(results);
      setIsSearching(false);
    };

    const debounce = setTimeout(searchBooks, 300);
    return () => clearTimeout(debounce);
  }, [search]);

  const handleSelect = useCallback(
    (callback: () => void) => {
      setOpen(false);
      callback();
    },
    []
  );

  const pages = [
    {
      name: "Dashboard",
      icon: Home,
      url: "/dashboard",
    },
    {
      name: "Books",
      icon: BookOpen,
      url: "/dashboard/books",
    },
    {
      name: "Add Book",
      icon: Plus,
      url: "/dashboard/books/add",
    },
    {
      name: "Authors",
      icon: Users,
      url: "/dashboard/authors",
    },
    {
      name: "Genres",
      icon: TrendingUp,
      url: "/dashboard/genres",
    },
    {
      name: "Recommendations",
      icon: Lightbulb,
      url: "/dashboard/recommendations",
    },
    {
      name: "Calendar",
      icon: Calendar,
      url: "/dashboard/calendar",
    },
    {
      name: "Reading Log",
      icon: Notebook,
      url: "/dashboard/reading-log",
    },
    {
      name: "Statistics",
      icon: BarChart3,
      url: "/dashboard/statistics",
    },
    {
      name: "Settings",
      icon: Settings,
      url: "/dashboard/settings",
    },
  ];

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogContent className="overflow-hidden p-0 shadow-lg max-w-2xl">
        <Command className="rounded-lg border-none">
          <div className="flex items-center border-b px-3">
            <Search className="mr-2 h-4 w-4 shrink-0 opacity-50" />
            <Command.Input
              value={search}
              onValueChange={setSearch}
              placeholder="Search books or navigate..."
              className="flex h-11 w-full rounded-md bg-transparent py-3 text-sm outline-none placeholder:text-muted-foreground disabled:cursor-not-allowed disabled:opacity-50"
            />
            <kbd className="pointer-events-none ml-auto hidden h-5 select-none items-center gap-1 rounded border bg-muted px-1.5 font-mono text-[10px] font-medium opacity-100 sm:flex">
              <span className="text-xs">ESC</span>
            </kbd>
          </div>
          <Command.List className="max-h-[400px] overflow-y-auto overflow-x-hidden p-2">
            <Command.Empty className="py-6 text-center text-sm text-muted-foreground">
              {isSearching ? "Searching..." : "No results found."}
            </Command.Empty>

            {/* Navigation Pages */}
            {search.length < 2 && (
              <Command.Group heading="Pages" className="px-2 py-2">
                {pages.map((page) => (
                  <Command.Item
                    key={page.url}
                    value={page.name}
                    onSelect={() => handleSelect(() => router.push(page.url))}
                    className="flex items-center gap-2 rounded-sm px-2 py-2 text-sm cursor-pointer hover:bg-accent"
                  >
                    <page.icon className="h-4 w-4" />
                    <span>{page.name}</span>
                  </Command.Item>
                ))}
              </Command.Group>
            )}

            {/* Search Results */}
            {searchResults.length > 0 && (
              <Command.Group heading="Books" className="px-2 py-2">
                {searchResults.map((book) => (
                  <Command.Item
                    key={book.bookId}
                    value={`${book.title} ${book.authorName}`}
                    onSelect={() =>
                      handleSelect(() =>
                        router.push(`/dashboard/books/${book.bookId}`)
                      )
                    }
                    className="flex items-start gap-2 rounded-sm px-2 py-2 cursor-pointer hover:bg-accent"
                  >
                    <BookOpen className="h-4 w-4 mt-0.5 shrink-0" />
                    <div className="flex-1 overflow-hidden">
                      <div className="font-medium truncate">{book.title}</div>
                      <div className="text-xs text-muted-foreground truncate">
                        {book.authorName}
                      </div>
                    </div>
                    {book.status && (
                      <Badge variant="secondary" className="shrink-0 text-xs">
                        {book.status.replace("_", " ")}
                      </Badge>
                    )}
                  </Command.Item>
                ))}
              </Command.Group>
            )}
          </Command.List>
        </Command>
      </DialogContent>
    </Dialog>
  );
}
