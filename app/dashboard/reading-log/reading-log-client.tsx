import { useState, useMemo } from "react";
import {
  useReactTable,
  getCoreRowModel,
  getSortedRowModel,
  getFilteredRowModel,
  getPaginationRowModel,
  flexRender,
  createColumnHelper,
  type SortingState,
} from "@tanstack/react-table";
import { useQueryClient } from "@tanstack/react-query";
import { useReadingSessions, useUnfinishedBooks } from "@/lib/queries/reading-sessions";
import { deleteReadingSessionAction } from "@/actions/reading-sessions";
import { toast } from "sonner";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Plus,
  BookOpen,
  Trash2,
  ChevronUp,
  ChevronDown,
  ChevronsUpDown,
} from "lucide-react";
import { AddReadingSessionForm } from "@/components/add-reading-session-form";

interface ReadingSession {
  session: {
    sessionId: number;
    bookId: number;
    sessionDate: string;
    pagesRead: number | null;
    minutesRead: number | null;
    startPage: number | null;
    endPage: number | null;
    notes: string | null;
  };
  book: {
    bookId: number;
    title: string;
  };
  authors: string;
}

const columnHelper = createColumnHelper<ReadingSession>();

export function ReadingLogClient() {
  const queryClient = useQueryClient();
  const { data: sessionsData, isLoading: sessionsLoading } = useReadingSessions(100);
  const { data: unfinishedBooksData, isLoading: booksLoading } = useUnfinishedBooks();

  const sessions: ReadingSession[] = sessionsData?.data ?? [];
  const unfinishedBooks = unfinishedBooksData ?? [];

  const [showAddDialog, setShowAddDialog] = useState(false);
  const [filterBookId, setFilterBookId] = useState<string>("all");
  const [sorting, setSorting] = useState<SortingState>([]);

  const isLoading = sessionsLoading || booksLoading;

  const stats = useMemo(() => ({
    totalSessions: sessions.length,
    totalPages: sessions.reduce((sum, s) => sum + (s.session.pagesRead || 0), 0),
    totalMinutes: sessions.reduce((sum, s) => sum + (s.session.minutesRead || 0), 0),
    totalHours: Math.floor(sessions.reduce((sum, s) => sum + (s.session.minutesRead || 0), 0) / 60),
  }), [sessions]);

  const filteredData = useMemo(() =>
    filterBookId === "all"
      ? sessions
      : sessions.filter((s) => s.session.bookId.toString() === filterBookId),
    [sessions, filterBookId]
  );

  const handleDelete = async (sessionId: number) => {
    if (!confirm("Delete this session?")) return;
    const result = await deleteReadingSessionAction(sessionId);
    if (result.success) {
      toast.success("Session deleted");
      queryClient.invalidateQueries({ queryKey: ["reading-sessions"] });
      queryClient.invalidateQueries({ queryKey: ["unfinished-books"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard"] });
    } else {
      toast.error(result.error || "Failed to delete session");
    }
  };

  const columns = useMemo(() => [
    columnHelper.accessor((row) => row.session.sessionDate, {
      id: "date",
      header: "Date",
      cell: (info) => new Date(info.getValue()).toLocaleDateString(),
      enableSorting: true,
    }),
    columnHelper.accessor((row) => row.book.title, {
      id: "book",
      header: "Book",
      cell: (info) => <span className="font-medium">{info.getValue()}</span>,
      enableSorting: true,
    }),
    columnHelper.accessor((row) => row.authors, {
      id: "authors",
      header: "Author",
      cell: (info) => <span className="text-muted-foreground">{info.getValue()}</span>,
      enableSorting: false,
    }),
    columnHelper.accessor((row) => row.session.pagesRead ?? 0, {
      id: "pages",
      header: "Pages",
      cell: (info) => info.getValue() || "—",
      enableSorting: true,
    }),
    columnHelper.accessor((row) => row.session.minutesRead ?? 0, {
      id: "time",
      header: "Time",
      cell: (info) => info.getValue() ? `${info.getValue()} min` : "—",
      enableSorting: true,
    }),
    columnHelper.accessor((row) => row.session.notes, {
      id: "notes",
      header: "Notes",
      cell: (info) => (
        <span className="text-muted-foreground text-xs line-clamp-1 max-w-[200px]">
          {info.getValue() || "—"}
        </span>
      ),
      enableSorting: false,
    }),
    columnHelper.display({
      id: "actions",
      header: "",
      cell: (info) => (
        <Button
          variant="ghost"
          size="icon"
          onClick={() => handleDelete(info.row.original.session.sessionId)}
          className="text-destructive hover:text-destructive"
        >
          <Trash2 className="h-4 w-4" />
        </Button>
      ),
      enableSorting: false,
    }),
  ], []);

  const table = useReactTable({
    data: filteredData,
    columns,
    state: { sorting },
    onSortingChange: setSorting,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    initialState: { pagination: { pageSize: 20 } },
  });

  if (isLoading) {
    return (
      <div className="flex flex-col gap-4 p-4 md:gap-6 md:p-6">
        <div className="flex items-center justify-between">
          <div className="space-y-2">
            <Skeleton className="h-8 w-48" />
            <Skeleton className="h-4 w-64" />
          </div>
          <Skeleton className="h-10 w-32" />
        </div>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <Card key={i}>
              <CardContent className="pt-6">
                <Skeleton className="h-4 w-24 mb-2" />
                <Skeleton className="h-8 w-16" />
              </CardContent>
            </Card>
          ))}
        </div>
        <Card>
          <CardContent className="pt-6">
            <Skeleton className="h-64 w-full" />
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-4 p-4 md:gap-6 md:p-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Reading Log</h1>
          <p className="text-muted-foreground">
            Track your daily reading sessions
          </p>
        </div>
        <Button onClick={() => setShowAddDialog(true)}>
          <Plus className="mr-2 h-4 w-4" />
          Add Session
        </Button>
      </div>

      {/* Statistics */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardContent className="pt-6">
            <div className="space-y-1">
              <p className="text-sm text-muted-foreground">Total Sessions</p>
              <p className="text-2xl font-bold">{stats.totalSessions}</p>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="space-y-1">
              <p className="text-sm text-muted-foreground">Pages Read</p>
              <p className="text-2xl font-bold">{stats.totalPages}</p>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="space-y-1">
              <p className="text-sm text-muted-foreground">Total Hours</p>
              <p className="text-2xl font-bold">{stats.totalHours}h</p>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="space-y-1">
              <p className="text-sm text-muted-foreground">Avg Pages/Session</p>
              <p className="text-2xl font-bold">
                {stats.totalSessions > 0
                  ? Math.round(stats.totalPages / stats.totalSessions)
                  : 0}
              </p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Table */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Reading Sessions</CardTitle>
            <Select value={filterBookId} onValueChange={setFilterBookId}>
              <SelectTrigger className="w-[200px]">
                <SelectValue placeholder="Filter by book" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Books</SelectItem>
                {unfinishedBooks.map((book) => (
                  <SelectItem key={book.id} value={book.id.toString()}>
                    {book.title}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </CardHeader>
        <CardContent>
          {filteredData.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-center">
              <BookOpen className="mb-4 h-12 w-12 text-muted-foreground" />
              <p className="text-lg font-medium">No reading sessions yet</p>
              <p className="text-sm text-muted-foreground">
                Start tracking your reading by adding a session
              </p>
            </div>
          ) : (
            <>
              <div className="overflow-x-auto rounded-md border">
                <Table>
                  <TableHeader>
                    {table.getHeaderGroups().map((headerGroup) => (
                      <TableRow key={headerGroup.id}>
                        {headerGroup.headers.map((header) => (
                          <TableHead key={header.id}>
                            {header.isPlaceholder ? null : (
                              <div
                                className={
                                  header.column.getCanSort()
                                    ? "flex items-center gap-1 cursor-pointer select-none"
                                    : ""
                                }
                                onClick={header.column.getToggleSortingHandler()}
                              >
                                {flexRender(header.column.columnDef.header, header.getContext())}
                                {header.column.getCanSort() && (
                                  header.column.getIsSorted() === "asc" ? (
                                    <ChevronUp className="h-3 w-3" />
                                  ) : header.column.getIsSorted() === "desc" ? (
                                    <ChevronDown className="h-3 w-3" />
                                  ) : (
                                    <ChevronsUpDown className="h-3 w-3 text-muted-foreground" />
                                  )
                                )}
                              </div>
                            )}
                          </TableHead>
                        ))}
                      </TableRow>
                    ))}
                  </TableHeader>
                  <TableBody>
                    {table.getRowModel().rows.map((row) => (
                      <TableRow key={row.id}>
                        {row.getVisibleCells().map((cell) => (
                          <TableCell key={cell.id}>
                            {flexRender(cell.column.columnDef.cell, cell.getContext())}
                          </TableCell>
                        ))}
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
              {/* Pagination */}
              <div className="flex items-center justify-between mt-4">
                <p className="text-sm text-muted-foreground">
                  Page {table.getState().pagination.pageIndex + 1} of {table.getPageCount()} ({filteredData.length} sessions)
                </p>
                <div className="flex gap-2">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => table.previousPage()}
                    disabled={!table.getCanPreviousPage()}
                  >
                    Previous
                  </Button>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => table.nextPage()}
                    disabled={!table.getCanNextPage()}
                  >
                    Next
                  </Button>
                </div>
              </div>
            </>
          )}
        </CardContent>
      </Card>

      {/* Add Session Dialog */}
      <Dialog open={showAddDialog} onOpenChange={setShowAddDialog}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>Add Reading Session</DialogTitle>
            <DialogDescription>
              Track your reading for today with sliders
            </DialogDescription>
          </DialogHeader>

          <AddReadingSessionForm
            books={unfinishedBooks}
            onSuccess={() => {
              setShowAddDialog(false);
              queryClient.invalidateQueries({ queryKey: ["reading-sessions"] });
              queryClient.invalidateQueries({ queryKey: ["unfinished-books"] });
              queryClient.invalidateQueries({ queryKey: ["dashboard"] });
            }}
          />
        </DialogContent>
      </Dialog>
    </div>
  );
}
