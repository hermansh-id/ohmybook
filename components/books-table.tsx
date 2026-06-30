"use client";

import * as React from "react";
import {
  ColumnDef,
  ColumnFiltersState,
  SortingState,
  VisibilityState,
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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  DropdownMenu,
  DropdownMenuCheckboxItem,
  DropdownMenuContent,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Star,
  BookOpen,
  ArrowUpDown,
  ArrowUp,
  ArrowDown,
  X,
  SlidersHorizontal,
} from "lucide-react";

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

const STATUS_OPTIONS = [
  { value: "all",         label: "All statuses" },
  { value: "finished",    label: "Finished" },
  { value: "not_started", label: "Not started" },
];

const STATUS_BADGE: Record<string, { variant: "default" | "secondary" | "outline" | "destructive"; label: string }> = {
  finished:    { variant: "secondary", label: "Finished" },
  not_started: { variant: "outline",  label: "Not started" },
};

function SortHeader({ column, label }: { column: any; label: string }) {
  const sorted = column.getIsSorted();
  return (
    <Button
      variant="ghost"
      size="sm"
      className="-ml-3 h-8"
      onClick={() => column.toggleSorting(sorted === "asc")}
    >
      {label}
      {sorted === "asc" ? (
        <ArrowUp className="ml-1 h-3 w-3" />
      ) : sorted === "desc" ? (
        <ArrowDown className="ml-1 h-3 w-3" />
      ) : (
        <ArrowUpDown className="ml-1 h-3 w-3 opacity-40" />
      )}
    </Button>
  );
}

const columns: ColumnDef<Book>[] = [
  {
    accessorKey: "title",
    header: ({ column }) => <SortHeader column={column} label="Title" />,
    cell: ({ row }) => {
      const book = row.original;
      return (
        <div className="flex items-center gap-3 min-w-0">
          {book.coverUrl ? (
            <img
              src={book.coverUrl}
              alt={book.title}
              className="h-12 w-8 object-cover rounded shrink-0"
            />
          ) : (
            <div className="h-12 w-8 bg-muted rounded flex items-center justify-center shrink-0">
              <BookOpen className="h-4 w-4 text-muted-foreground" />
            </div>
          )}
          <div className="min-w-0">
            <p className="font-medium truncate">{book.title}</p>
            <p className="text-xs text-muted-foreground truncate">
              {book.authors?.length ? book.authors.map((a) => a.name).join(", ") : "Unknown"}
            </p>
          </div>
        </div>
      );
    },
    filterFn: "includesString",
  },
  {
    accessorKey: "genres",
    header: "Genres",
    cell: ({ row }) => (
      <div className="flex flex-wrap gap-1 hidden sm:flex">
        {row.original.genres?.length
          ? row.original.genres.slice(0, 2).map((g) => (
              <Badge key={g.id} variant="outline" className="text-xs whitespace-nowrap">
                {g.name}
              </Badge>
            ))
          : <span className="text-muted-foreground text-sm">—</span>}
      </div>
    ),
    enableSorting: false,
  },
  {
    accessorKey: "pages",
    header: ({ column }) => <SortHeader column={column} label="Pages" />,
    cell: ({ row }) => (
      <div className="text-center tabular-nums">{row.original.pages ?? "—"}</div>
    ),
  },
  {
    accessorKey: "year",
    header: ({ column }) => <SortHeader column={column} label="Year" />,
    cell: ({ row }) => (
      <div className="text-center tabular-nums">{row.original.year ?? "—"}</div>
    ),
  },
  {
    accessorKey: "rating",
    header: ({ column }) => <SortHeader column={column} label="Rating" />,
    cell: ({ row }) => {
      const r = row.original.rating;
      return r ? (
        <div className="flex items-center gap-1">
          <Star className="h-3 w-3 fill-yellow-400 text-yellow-400" />
          <span className="tabular-nums">{r}</span>
        </div>
      ) : (
        <span className="text-muted-foreground text-sm">—</span>
      );
    },
  },
  {
    accessorKey: "status",
    header: "Status",
    cell: ({ row }) => {
      const s = row.original.status;
      const cfg = STATUS_BADGE[s] ?? { variant: "outline" as const, label: s };
      return (
        <Badge variant={cfg.variant} className="whitespace-nowrap text-xs">
          {cfg.label}
        </Badge>
      );
    },
    filterFn: (row, _id, filterValue) =>
      filterValue === "all" || row.original.status === filterValue,
  },
];

interface BooksTableProps {
  data: Book[];
  onRowClick?: (book: Book) => void;
}

export function BooksTable({ data, onRowClick }: BooksTableProps) {
  const [sorting, setSorting] = React.useState<SortingState>([]);
  const [columnFilters, setColumnFilters] = React.useState<ColumnFiltersState>([]);
  const [columnVisibility, setColumnVisibility] = React.useState<VisibilityState>({});
  const [globalFilter, setGlobalFilter] = React.useState("");
  const [statusFilter, setStatusFilter] = React.useState("all");
  const [genreFilter, setGenreFilter] = React.useState("all");
  const [pageSize, setPageSize] = React.useState(20);

  const uniqueGenres = React.useMemo(() => {
    const s = new Set<string>();
    data.forEach((b) => b.genres?.forEach((g) => s.add(g.name)));
    return Array.from(s).sort();
  }, [data]);

  const filteredData = React.useMemo(() => {
    return data.filter((book) => {
      const statusMatch = statusFilter === "all" || book.status === statusFilter;
      const genreMatch = genreFilter === "all" || book.genres?.some((g) => g.name === genreFilter);
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
    onColumnVisibilityChange: setColumnVisibility,
    onGlobalFilterChange: setGlobalFilter,
    globalFilterFn: "includesString",
    state: { sorting, columnFilters, columnVisibility, globalFilter },
    initialState: { pagination: { pageSize } },
  });

  React.useEffect(() => {
    table.setPageSize(pageSize);
  }, [pageSize, table]);

  const hasActiveFilters = statusFilter !== "all" || genreFilter !== "all" || globalFilter !== "";

  const clearFilters = () => {
    setStatusFilter("all");
    setGenreFilter("all");
    setGlobalFilter("");
  };

  const totalFiltered = table.getFilteredRowModel().rows.length;
  const { pageIndex, pageSize: currentPageSize } = table.getState().pagination;
  const pageCount = table.getPageCount();

  return (
    <div className="space-y-4">
      {/* Filter bar */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:flex-wrap">
        <Input
          placeholder="Search title, author..."
          value={globalFilter}
          onChange={(e) => setGlobalFilter(e.target.value)}
          className="w-full sm:w-56"
        />

        <Select value={statusFilter} onValueChange={setStatusFilter}>
          <SelectTrigger className="w-full sm:w-44">
            <SelectValue placeholder="Status" />
          </SelectTrigger>
          <SelectContent>
            {STATUS_OPTIONS.map((opt) => (
              <SelectItem key={opt.value} value={opt.value}>
                {opt.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>

        <Select value={genreFilter} onValueChange={setGenreFilter}>
          <SelectTrigger className="w-full sm:w-44">
            <SelectValue placeholder="Genre" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All genres</SelectItem>
            {uniqueGenres.map((g) => (
              <SelectItem key={g} value={g}>{g}</SelectItem>
            ))}
          </SelectContent>
        </Select>

        {hasActiveFilters && (
          <Button variant="ghost" size="sm" onClick={clearFilters} className="gap-1 text-muted-foreground">
            <X className="h-3 w-3" />
            Clear
          </Button>
        )}

        <div className="sm:ml-auto flex items-center gap-2">
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="outline" size="sm" className="gap-1">
                <SlidersHorizontal className="h-4 w-4" />
                <span className="hidden sm:inline">Columns</span>
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              {table
                .getAllColumns()
                .filter((col) => col.getCanHide())
                .map((col) => (
                  <DropdownMenuCheckboxItem
                    key={col.id}
                    className="capitalize"
                    checked={col.getIsVisible()}
                    onCheckedChange={(v) => col.toggleVisibility(v)}
                  >
                    {col.id}
                  </DropdownMenuCheckboxItem>
                ))}
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      </div>

      {/* Active filter chips */}
      {hasActiveFilters && (
        <div className="flex flex-wrap gap-2">
          {globalFilter && (
            <Badge variant="secondary" className="gap-1 pr-1">
              Search: {globalFilter}
              <button onClick={() => setGlobalFilter("")} className="ml-1 rounded hover:bg-muted">
                <X className="h-3 w-3" />
              </button>
            </Badge>
          )}
          {statusFilter !== "all" && (
            <Badge variant="secondary" className="gap-1 pr-1">
              {STATUS_OPTIONS.find((o) => o.value === statusFilter)?.label}
              <button onClick={() => setStatusFilter("all")} className="ml-1 rounded hover:bg-muted">
                <X className="h-3 w-3" />
              </button>
            </Badge>
          )}
          {genreFilter !== "all" && (
            <Badge variant="secondary" className="gap-1 pr-1">
              {genreFilter}
              <button onClick={() => setGenreFilter("all")} className="ml-1 rounded hover:bg-muted">
                <X className="h-3 w-3" />
              </button>
            </Badge>
          )}
        </div>
      )}

      {/* Result count */}
      <p className="text-sm text-muted-foreground">
        {totalFiltered} book{totalFiltered !== 1 ? "s" : ""}
        {hasActiveFilters && ` (filtered from ${data.length})`}
      </p>

      {/* Table */}
      <div className="rounded-md border overflow-x-auto">
        <Table>
          <TableHeader>
            {table.getHeaderGroups().map((hg) => (
              <TableRow key={hg.id}>
                {hg.headers.map((header) => (
                  <TableHead key={header.id} className="whitespace-nowrap">
                    {header.isPlaceholder
                      ? null
                      : flexRender(header.column.columnDef.header, header.getContext())}
                  </TableHead>
                ))}
              </TableRow>
            ))}
          </TableHeader>
          <TableBody>
            {table.getRowModel().rows.length ? (
              table.getRowModel().rows.map((row) => (
                <TableRow
                  key={row.id}
                  onClick={() => onRowClick?.(row.original)}
                  className="cursor-pointer hover:bg-muted/50"
                >
                  {row.getVisibleCells().map((cell) => (
                    <TableCell key={cell.id}>
                      {flexRender(cell.column.columnDef.cell, cell.getContext())}
                    </TableCell>
                  ))}
                </TableRow>
              ))
            ) : (
              <TableRow>
                <TableCell colSpan={columns.length} className="h-24 text-center text-muted-foreground">
                  No books found.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>

      {/* Pagination */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div className="flex items-center gap-2 text-sm text-muted-foreground">
          <span>Rows per page</span>
          <Select value={String(pageSize)} onValueChange={(v) => setPageSize(Number(v))}>
            <SelectTrigger className="h-8 w-16">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {[10, 20, 50, 100].map((n) => (
                <SelectItem key={n} value={String(n)}>{n}</SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        <div className="flex items-center gap-2 justify-center sm:justify-end">
          <span className="text-sm text-muted-foreground tabular-nums">
            {pageCount === 0 ? "0 / 0" : `${pageIndex + 1} / ${pageCount}`}
          </span>
          <Button variant="outline" size="sm" onClick={() => table.firstPage()} disabled={!table.getCanPreviousPage()}>
            «
          </Button>
          <Button variant="outline" size="sm" onClick={() => table.previousPage()} disabled={!table.getCanPreviousPage()}>
            ‹
          </Button>
          <Button variant="outline" size="sm" onClick={() => table.nextPage()} disabled={!table.getCanNextPage()}>
            ›
          </Button>
          <Button variant="outline" size="sm" onClick={() => table.lastPage()} disabled={!table.getCanNextPage()}>
            »
          </Button>
        </div>
      </div>
    </div>
  );
}
