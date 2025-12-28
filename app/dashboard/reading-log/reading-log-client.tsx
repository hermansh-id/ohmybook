"use client";

import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
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
  Plus,
  BookOpen,
  Clock,
  FileText,
  Trash2,
  Calendar as CalendarIcon,
} from "lucide-react";
import { deleteReadingSessionAction } from "@/app/actions/reading-sessions";
import { useRouter } from "next/navigation";
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

interface UnfinishedBook {
  id: number;
  title: string;
  pages: number;
  currentPage: number;
  status: string;
}

interface ReadingLogClientProps {
  initialSessions: ReadingSession[];
  unfinishedBooks: UnfinishedBook[];
}

export function ReadingLogClient({
  initialSessions,
  unfinishedBooks,
}: ReadingLogClientProps) {
  const router = useRouter();
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [filterBookId, setFilterBookId] = useState<string>("all");

  // Calculate statistics
  const stats = {
    totalSessions: initialSessions.length,
    totalPages: initialSessions.reduce(
      (sum, s) => sum + (s.session.pagesRead || 0),
      0
    ),
    totalMinutes: initialSessions.reduce(
      (sum, s) => sum + (s.session.minutesRead || 0),
      0
    ),
    totalHours: Math.floor(
      initialSessions.reduce((sum, s) => sum + (s.session.minutesRead || 0), 0) / 60
    ),
  };

  // Filter sessions
  const filteredSessions =
    filterBookId === "all"
      ? initialSessions
      : initialSessions.filter(
          (s) => s.session.bookId.toString() === filterBookId
        );

  const handleDelete = async (sessionId: number) => {
    if (!confirm("Are you sure you want to delete this session?")) return;

    const result = await deleteReadingSessionAction(sessionId);

    if (result.success) {
      router.refresh();
    } else {
      alert(result.error || "Failed to delete session");
    }
  };

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

      {/* Filter */}
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
          {filteredSessions.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-center">
              <BookOpen className="mb-4 h-12 w-12 text-muted-foreground" />
              <p className="text-lg font-medium">No reading sessions yet</p>
              <p className="text-sm text-muted-foreground">
                Start tracking your reading by adding a session
              </p>
            </div>
          ) : (
            <div className="space-y-4">
              {filteredSessions.map((session) => (
                <div
                  key={session.session.sessionId}
                  className="flex items-start justify-between gap-4 rounded-lg border p-4 transition-colors hover:bg-accent"
                >
                  <div className="flex-1 space-y-2">
                    <div className="flex items-start justify-between">
                      <div>
                        <h4 className="font-semibold">{session.book.title}</h4>
                        <p className="text-sm text-muted-foreground">
                          {session.authors}
                        </p>
                      </div>
                      <Badge variant="outline">
                        {new Date(session.session.sessionDate).toLocaleDateString()}
                      </Badge>
                    </div>

                    <div className="flex flex-wrap gap-3 text-sm">
                      {session.session.pagesRead && (
                        <div className="flex items-center gap-1 text-muted-foreground">
                          <BookOpen className="h-4 w-4" />
                          <span>
                            {session.session.pagesRead} pages
                            {session.session.startPage && session.session.endPage && (
                              <span className="ml-1">
                                (p. {session.session.startPage}-{session.session.endPage})
                              </span>
                            )}
                          </span>
                        </div>
                      )}
                      {session.session.minutesRead && (
                        <div className="flex items-center gap-1 text-muted-foreground">
                          <Clock className="h-4 w-4" />
                          <span>{session.session.minutesRead} minutes</span>
                        </div>
                      )}
                    </div>

                    {session.session.notes && (
                      <div className="flex items-start gap-1 text-sm">
                        <FileText className="h-4 w-4 text-muted-foreground mt-0.5" />
                        <p className="text-muted-foreground">{session.session.notes}</p>
                      </div>
                    )}
                  </div>

                  <Button
                    variant="ghost"
                    size="icon"
                    onClick={() => handleDelete(session.session.sessionId)}
                    className="text-destructive hover:text-destructive"
                  >
                    <Trash2 className="h-4 w-4" />
                  </Button>
                </div>
              ))}
            </div>
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
              router.refresh();
            }}
          />
        </DialogContent>
      </Dialog>
    </div>
  );
}
