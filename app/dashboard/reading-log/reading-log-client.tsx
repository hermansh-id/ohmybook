"use client";

import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
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
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Plus,
  BookOpen,
  Clock,
  FileText,
  Trash2,
  Calendar as CalendarIcon,
} from "lucide-react";
import { createReadingSessionAction, deleteReadingSessionAction } from "@/app/actions/reading-sessions";
import { useRouter } from "next/navigation";

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

interface Book {
  id: number;
  title: string;
  authors: { name: string }[];
}

interface ReadingLogClientProps {
  initialSessions: ReadingSession[];
  availableBooks: Book[];
}

export function ReadingLogClient({
  initialSessions,
  availableBooks,
}: ReadingLogClientProps) {
  const router = useRouter();
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [filterBookId, setFilterBookId] = useState<string>("all");

  // Form state
  const [formData, setFormData] = useState({
    bookId: "",
    sessionDate: new Date().toISOString().split("T")[0],
    pagesRead: "",
    minutesRead: "",
    startPage: "",
    endPage: "",
    notes: "",
  });

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

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!formData.bookId || !formData.sessionDate) {
      alert("Please select a book and date");
      return;
    }

    setIsSubmitting(true);

    try {
      const result = await createReadingSessionAction({
        bookId: parseInt(formData.bookId),
        sessionDate: formData.sessionDate,
        pagesRead: formData.pagesRead ? parseInt(formData.pagesRead) : undefined,
        minutesRead: formData.minutesRead
          ? parseInt(formData.minutesRead)
          : undefined,
        startPage: formData.startPage ? parseInt(formData.startPage) : undefined,
        endPage: formData.endPage ? parseInt(formData.endPage) : undefined,
        notes: formData.notes || undefined,
      });

      if (result.success) {
        setShowAddDialog(false);
        setFormData({
          bookId: "",
          sessionDate: new Date().toISOString().split("T")[0],
          pagesRead: "",
          minutesRead: "",
          startPage: "",
          endPage: "",
          notes: "",
        });
        router.refresh();
      } else {
        alert(result.error || "Failed to add reading session");
      }
    } catch (error) {
      alert("An error occurred");
    } finally {
      setIsSubmitting(false);
    }
  };

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
                {availableBooks.map((book) => (
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
              Log your reading session for today
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="book">Book *</Label>
              <Select
                value={formData.bookId}
                onValueChange={(value) =>
                  setFormData({ ...formData, bookId: value })
                }
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select a book" />
                </SelectTrigger>
                <SelectContent>
                  {availableBooks.map((book) => (
                    <SelectItem key={book.id} value={book.id.toString()}>
                      {book.title}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="date">Date *</Label>
              <Input
                id="date"
                type="date"
                value={formData.sessionDate}
                onChange={(e) =>
                  setFormData({ ...formData, sessionDate: e.target.value })
                }
                required
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="pages">Pages Read</Label>
                <Input
                  id="pages"
                  type="number"
                  placeholder="e.g. 50"
                  value={formData.pagesRead}
                  onChange={(e) =>
                    setFormData({ ...formData, pagesRead: e.target.value })
                  }
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="minutes">Minutes</Label>
                <Input
                  id="minutes"
                  type="number"
                  placeholder="e.g. 60"
                  value={formData.minutesRead}
                  onChange={(e) =>
                    setFormData({ ...formData, minutesRead: e.target.value })
                  }
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="startPage">Start Page</Label>
                <Input
                  id="startPage"
                  type="number"
                  placeholder="e.g. 1"
                  value={formData.startPage}
                  onChange={(e) =>
                    setFormData({ ...formData, startPage: e.target.value })
                  }
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="endPage">End Page</Label>
                <Input
                  id="endPage"
                  type="number"
                  placeholder="e.g. 50"
                  value={formData.endPage}
                  onChange={(e) =>
                    setFormData({ ...formData, endPage: e.target.value })
                  }
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="notes">Notes</Label>
              <Textarea
                id="notes"
                placeholder="Any thoughts or notes..."
                value={formData.notes}
                onChange={(e) =>
                  setFormData({ ...formData, notes: e.target.value })
                }
                rows={3}
              />
            </div>

            <DialogFooter>
              <Button
                type="button"
                variant="outline"
                onClick={() => setShowAddDialog(false)}
              >
                Cancel
              </Button>
              <Button type="submit" disabled={isSubmitting}>
                {isSubmitting ? "Adding..." : "Add Session"}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}
