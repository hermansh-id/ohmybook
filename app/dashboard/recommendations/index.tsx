import * as React from "react";
import { createFileRoute, Link } from "@tanstack/react-router";
import { BookOpen, CalendarPlus } from "lucide-react";
import { toast } from "sonner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Checkbox } from "@/components/ui/checkbox";
import { Skeleton } from "@/components/ui/skeleton";
import { CreatePlanDialog } from "@/components/planning/plan-dialogs";
import { addDays, toDateKey } from "@/lib/dates";
import { LEVEL_META, STATUS_LABEL, type PriorityLevel } from "@/lib/planning-ui";
import {
  useDismissRecommendation,
  usePostponeRecommendation,
  useRecommendations,
  useRestoreRecommendation,
} from "@/lib/queries/planning";

export const Route = createFileRoute("/dashboard/recommendations/")({
  component: RecommendationsPage,
});

const POSTPONE_DAYS = 7;

function RecommendationsPage() {
  const today = toDateKey(new Date());
  const [rereads, setRereads] = React.useState(false);
  const [planBook, setPlanBook] = React.useState<number | null>(null);

  const { data: recommendations = [], isLoading } = useRecommendations({ today, includeFinished: rereads });
  const dismiss = useDismissRecommendation();
  const postpone = usePostponeRecommendation();
  const restore = useRestoreRecommendation();

  const undo = (bookId: number) => ({
    label: "Undo",
    onClick: () => restore.mutate({ bookId }),
  });

  const onDismiss = async (bookId: number, title: string) => {
    await dismiss.mutateAsync({ bookId });
    toast(`Won't suggest ${title} again`, { action: undo(bookId) });
  };
  const onPostpone = async (bookId: number, title: string) => {
    await postpone.mutateAsync({ bookId, untilDate: addDays(today, POSTPONE_DAYS) });
    toast(`${title} is hidden for ${POSTPONE_DAYS} days`, { action: undo(bookId) });
  };

  return (
    <div className="flex flex-col gap-4 p-4 md:gap-6 md:p-6">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">What to read next</h1>
          <p className="text-muted-foreground">
            A short list based on your priorities and what you are reading, with the reason for each.
          </p>
        </div>
        <label className="flex min-h-11 cursor-pointer items-center gap-2 text-sm sm:min-h-9">
          <Checkbox checked={rereads} onCheckedChange={(v) => setRereads(v === true)} />
          Suggest rereads
        </label>
      </div>

      {isLoading ? (
        <div className="space-y-3">
          {[0, 1, 2].map((i) => (
            <Skeleton key={i} className="h-36 w-full" />
          ))}
        </div>
      ) : recommendations.length === 0 ? (
        <div className="flex min-h-[320px] flex-col items-center justify-center rounded-lg border border-dashed p-8 text-center">
          <BookOpen className="size-12 text-muted-foreground" />
          <h2 className="mt-4 text-lg font-semibold">Nothing to suggest right now</h2>
          <p className="mt-2 max-w-sm text-muted-foreground">
            {rereads
              ? "Finish and rate a few books and they can come back here as rereads."
              : "Add unread books to your library, or bring back ones you postponed. Setting a priority makes suggestions sharper."}
          </p>
        </div>
      ) : (
        <ol className="grid gap-3">
          {recommendations.map((book, index) => {
            const pct = book.pages && book.currentPage ? Math.min(100, Math.round((book.currentPage / book.pages) * 100)) : 0;
            return (
              <li key={book.bookId}>
                <Card>
                  <CardContent className="flex flex-col gap-4 pt-6 sm:flex-row">
                    <div className="flex gap-4 sm:flex-1">
                      {book.coverUrl ? (
                        <img src={book.coverUrl} alt="" className="h-24 w-16 shrink-0 rounded object-cover shadow-sm" />
                      ) : (
                        <div className="flex h-24 w-16 shrink-0 items-center justify-center rounded bg-muted">
                          <BookOpen className="size-6 text-muted-foreground" />
                        </div>
                      )}
                      <div className="min-w-0 flex-1 space-y-1.5">
                        <div className="flex flex-wrap items-center gap-2">
                          <span className="text-xs text-muted-foreground">{index + 1}</span>
                          {book.priority && (
                            <span className="inline-flex items-center gap-1.5 text-xs text-muted-foreground">
                              <span className={`size-2 rounded-full ${LEVEL_META[book.priority.level as PriorityLevel].dot}`} />
                              {LEVEL_META[book.priority.level as PriorityLevel].label}
                            </span>
                          )}
                          {book.status && <Badge variant="outline">{STATUS_LABEL[book.status] ?? book.status}</Badge>}
                          {book.plannedThisWeek && <Badge variant="outline">On this week&apos;s plan</Badge>}
                        </div>
                        <Link
                          to="/dashboard/books/$bookId"
                          params={{ bookId: String(book.bookId) }}
                          className="line-clamp-2 font-semibold hover:underline"
                        >
                          {book.title}
                        </Link>
                        {book.authors.length > 0 && (
                          <p className="line-clamp-1 text-sm text-muted-foreground">{book.authors.map((a) => a.name).join(", ")}</p>
                        )}
                        <p className="text-sm">{book.reason}</p>
                        {book.status === "reading" && book.pages ? (
                          <p className="text-xs text-muted-foreground">
                            {book.currentPage ?? 0}/{book.pages} pages · {pct}%
                          </p>
                        ) : book.pages ? (
                          <p className="text-xs text-muted-foreground">{book.pages} pages</p>
                        ) : null}
                      </div>
                    </div>
                    <div className="flex gap-2 sm:w-36 sm:flex-col">
                      <Button className="min-h-11 flex-1 sm:min-h-9 sm:flex-none" onClick={() => setPlanBook(book.bookId)}>
                        <CalendarPlus className="size-4" />
                        Plan it
                      </Button>
                      <Button
                        variant="outline"
                        className="min-h-11 flex-1 sm:min-h-9 sm:flex-none"
                        disabled={postpone.isPending}
                        onClick={() => onPostpone(book.bookId, book.title)}
                      >
                        Not now
                      </Button>
                      <Button
                        variant="ghost"
                        className="min-h-11 flex-1 text-muted-foreground sm:min-h-9 sm:flex-none"
                        disabled={dismiss.isPending}
                        onClick={() => onDismiss(book.bookId, book.title)}
                      >
                        Dismiss
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              </li>
            );
          })}
        </ol>
      )}

      <CreatePlanDialog
        open={planBook !== null}
        onOpenChange={(o) => !o && setPlanBook(null)}
        defaultDate={today}
        defaultBookId={planBook}
      />
    </div>
  );
}
