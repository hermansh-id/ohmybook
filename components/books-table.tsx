"use client";

import * as React from "react";
import {
  ColumnDef,
  ColumnFiltersState,
  SortingState,
  flexRender,
  getCoreRowModel,
  getFilteredRowModel,
  getPaginationRowModel,
  getSortedRowModel,
  useReactTable,
} from "@tanstack/react-table";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Star, BookOpen } from "lucide-react";

export type Book = {
  id: number;
  title: string;
  authors: Array<{ id: number; name: string }>;
  genres: Array<{ id: number; name: string }>;
  pages: number | null;
  year: number | null;
  status: string;
  rating: number | null;
  averageRating: string | null;
  coverUrl: string | null;
};

const columns: ColumnDef<Book>[] = [
  {
    accessorKey: "title",
    header: "Title",
    cell: ({ row }) => {
      const book = row.original;
      return (
        <div className="flex items-center gap-3">
          {book.coverUrl ? (
            <img
              src={book.coverUrl}
              alt={book.title}
              className="h-12 w-8 object-cover rounded"
            />
          ) : (
            <div className="h-12 w-8 bg-muted rounded flex items-center justify-center">
              <BookOpen className="h-4 w-4 text-muted-foreground" />
            </div>
          )}
          <div className="font-medium">{book.title}</div>
        </div>
      );
    },
  },
  {
    accessorKey: "authors",
    header: "Author(s)",
    cell: ({ row }) => {
      const authors = row.original.authors;
      return (
        <div className="text-sm">
          {authors && authors.length > 0
            ? authors.map((a) => a.name).join(", ")
            : "Unknown"}
        </div>
      );
    },
  },
  {
    accessorKey: "genres",
    header: "Genres",
    cell: ({ row }) => {
      const genres = row.original.genres;
      return (
        <div className="flex flex-wrap gap-1">
          {genres && genres.length > 0
            ? genres.slice(0, 2).map((g) => (
                <Badge key={g.id} variant="outline" className="text-xs">
                  {g.name}
                </Badge>
              ))
            : "-"}
        </div>
      );
    },
  },
  {
    accessorKey: "pages",
    header: "Pages",
    cell: ({ row }) => {
      const pages = row.original.pages;
      return <div className="text-center">{pages || "-"}</div>;
    },
  },
  {
    accessorKey: "year",
    header: "Year",
    cell: ({ row }) => {
      const year = row.original.year;
      return <div className="text-center">{year || "-"}</div>;
    },
  },
  {
    accessorKey: "rating",
    header: "My Rating",
    cell: ({ row }) => {
      const rating = row.original.rating;
      return rating ? (
        <div className="flex items-center gap-1">
          <Star className="h-3 w-3 fill-current text-yellow-500" />
          <span>{rating}</span>
        </div>
      ) : (
        <div className="text-muted-foreground">-</div>
      );
    },
  },
  {
    accessorKey: "status",
    header: "Status",
    cell: ({ row }) => {
      const status = row.original.status;
      const statusColors: Record<string, string> = {
        reading: "default",
        finished: "secondary",
        want_to_read: "outline",
        did_not_finish: "destructive",
        on_hold: "secondary",
      };
      return (
        <Badge variant={statusColors[status] as any || "outline"}>
          {status.replace(/_/g, " ")}
        </Badge>
      );
    },
  },
];

interface BooksTableProps {
  data: Book[];
  onRowClick?: (book: Book) => void;
}

export function BooksTable({ data, onRowClick }: BooksTableProps) {
  const [sorting, setSorting] = React.useState<SortingState>([]);
  const [columnFilters, setColumnFilters] = React.useState<ColumnFiltersState>([]);
  const [globalFilter, setGlobalFilter] = React.useState("");
  const [statusFilter, setStatusFilter] = React.useState<string>("all");
  const [genreFilter, setGenreFilter] = React.useState<string>("all");

  // Get unique genres from all books
  const uniqueGenres = React.useMemo(() => {
    const genreSet = new Set<string>();
    data.forEach((book) => {
      book.genres?.forEach((genre) => genreSet.add(genre.name));
    });
    return Array.from(genreSet).sort();
  }, [data]);

  // Filter data based on status and genre
  const filteredData = React.useMemo(() => {
    return data.filter((book) => {
      // Simple status filter: finished or not finished
      let statusMatch = true;
      if (statusFilter === "finished") {
        statusMatch = book.status === "finished";
      } else if (statusFilter === "not_finished") {
        statusMatch = book.status !== "finished";
      }

      const genreMatch =
        genreFilter === "all" ||
        book.genres?.some((g) => g.name === genreFilter);

      return statusMatch && genreMatch;
    });
  }, [data, statusFilter, genreFilter]);

  const table = useReactTable({
    data: filteredData,
    columns,
    getCoreRowModel: getCoreRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    onSortingChange: setSorting,
    onColumnFiltersChange: setColumnFilters,
    onGlobalFilterChange: setGlobalFilter,
    globalFilterFn: "includesString",
    state: {
      sorting,
      columnFilters,
      globalFilter,
    },
    initialState: {
      pagination: {
        pageSize: 20,
      },
    },
  });

  return (
    <div className="space-y-4">
      {/* Mobile-first: Stack filters vertically, horizontal on larger screens */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <Input
          placeholder="Search books, authors..."
          value={globalFilter ?? ""}
          onChange={(event) => setGlobalFilter(event.target.value)}
          className="w-full sm:max-w-xs"
        />
        <div className="flex flex-col gap-2 sm:flex-row sm:items-center">
          {/* Status Filter - Simple: Finished or Not Finished */}
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="h-10 rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
          >
            <option value="all">All Books</option>
            <option value="finished">Finished</option>
            <option value="not_finished">Not Finished</option>
          </select>

          {/* Genre Filter */}
          <select
            value={genreFilter}
            onChange={(e) => setGenreFilter(e.target.value)}
            className="h-10 rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
          >
            <option value="all">All Genres</option>
            {uniqueGenres.map((genre) => (
              <option key={genre} value={genre}>
                {genre}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Result count */}
      <div className="text-sm text-muted-foreground">
        {table.getFilteredRowModel().rows.length} book(s)
      </div>

      <div className="rounded-md border">
        <Table>
          <TableHeader>
            {table.getHeaderGroups().map((headerGroup) => (
              <TableRow key={headerGroup.id}>
                {headerGroup.headers.map((header) => (
                  <TableHead key={header.id}>
                    {header.isPlaceholder
                      ? null
                      : flexRender(
                          header.column.columnDef.header,
                          header.getContext()
                        )}
                  </TableHead>
                ))}
              </TableRow>
            ))}
          </TableHeader>
          <TableBody>
            {table.getRowModel().rows?.length ? (
              table.getRowModel().rows.map((row) => (
                <TableRow
                  key={row.id}
                  data-state={row.getIsSelected() && "selected"}
                  onClick={() => onRowClick?.(row.original)}
                  className="cursor-pointer hover:bg-muted/50"
                >
                  {row.getVisibleCells().map((cell) => (
                    <TableCell key={cell.id}>
                      {flexRender(
                        cell.column.columnDef.cell,
                        cell.getContext()
                      )}
                    </TableCell>
                  ))}
                </TableRow>
              ))
            ) : (
              <TableRow>
                <TableCell
                  colSpan={columns.length}
                  className="h-24 text-center"
                >
                  No books found.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>

      {/* Mobile-first pagination */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <div className="text-sm text-muted-foreground text-center sm:text-left">
          Page {table.getState().pagination.pageIndex + 1} of{" "}
          {table.getPageCount()}
        </div>
        <div className="flex items-center justify-center gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={() => table.previousPage()}
            disabled={!table.getCanPreviousPage()}
            className="min-w-[100px]"
          >
            Previous
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={() => table.nextPage()}
            disabled={!table.getCanNextPage()}
            className="min-w-[100px]"
          >
            Next
          </Button>
        </div>
      </div>
    </div>
  );
}
