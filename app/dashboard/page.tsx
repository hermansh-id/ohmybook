import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { ReadingHistoryChart } from "@/components/reading-history-chart";
import {
  getReadingStats,
  getCurrentYearGoal,
  getMonthlyStats,
  getFinishedBooks,
  getCurrentlyReadingBooks,
  getReadingSessions,
  getReadingHistory,
} from "@/lib/db/queries";
import { getUnfinishedBooksAction } from "@/app/actions/reading-sessions";
import {
  BookOpen,
  Target,
  TrendingUp,
  Clock,
  Plus,
  Star,
  FileText,
  Award,
} from "lucide-react";
import Link from "next/link";
import { AddReadingSessionDialog } from "@/components/add-reading-session-dialog";
import { MonthlyRecapButton } from "@/components/dashboard-client";

export default async function DashboardPage() {
  // Fetch dashboard data
  const [stats, goal, monthlyStats, recentBooksData, currentlyReading, recentSessions, readingHistory, unfinishedBooks] =
    await Promise.all([
      getReadingStats(),
      getCurrentYearGoal(),
      getMonthlyStats(new Date().getFullYear()),
      getFinishedBooks(5),
      getCurrentlyReadingBooks(),
      getReadingSessions(10),
      getReadingHistory(12),
      getUnfinishedBooksAction(),
    ]);

  const readingStats = stats[0] || {
    totalBooksRead: 0,
    totalPagesRead: 0,
    totalBooksReading: 0,
    totalBooksWantToRead: 0,
    averageRating: 0,
    booksReadThisYear: 0,
    booksReadThisMonth: 0,
    pagesReadThisYear: 0,
    pagesReadThisMonth: 0,
  };

  const yearGoal = goal[0] || {
    targetBooks: 52,
    currentBooks: 0,
  };

  const targetBooks = yearGoal.targetBooks ?? 52;
  const currentBooks = yearGoal.currentBooks ?? 0;

  const goalProgress =
    targetBooks > 0 ? (currentBooks / targetBooks) * 100 : 0;

  const totalReadingTime = recentSessions.reduce(
    (sum, s) => sum + (s.session.minutesRead || 0),
    0
  );

  return (
    <div className="flex flex-col gap-4 p-4 md:gap-6 md:p-6">
      {/* Welcome Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Dashboard</h1>
          <p className="text-muted-foreground">Welcome back to your reading journey</p>
        </div>
        <div className="flex gap-2">
          <MonthlyRecapButton />
          <AddReadingSessionDialog
            books={unfinishedBooks}
            trigger={
              <Button size="sm" variant="outline">
                <FileText className="mr-2 h-4 w-4" />
                Log Session
              </Button>
            }
          />
        </div>
      </div>

      {/* Reading Goal Progress - Prominent */}
      <Card className="border-2">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center gap-2">
              <Target className="h-5 w-5 text-primary" />
              {new Date().getFullYear()} Reading Goal
            </CardTitle>
            <div className="flex items-center gap-2">
              <Badge
                variant={goalProgress >= 100 ? "default" : "secondary"}
                className={goalProgress >= 100 ? "bg-green-600" : ""}
              >
                {goalProgress.toFixed(0)}%
              </Badge>
              {goalProgress >= 100 && <Award className="h-5 w-5 text-green-600" />}
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            <div className="flex justify-between text-sm">
              <span className="text-muted-foreground">Progress</span>
              <span className="font-semibold text-lg">
                {currentBooks} / {targetBooks} books
              </span>
            </div>
            <div className="h-6 overflow-hidden rounded-full bg-secondary">
              <div
                className={`h-full transition-all ${
                  goalProgress >= 100 ? "bg-green-500" : "bg-primary"
                }`}
                style={{ width: `${Math.min(goalProgress, 100)}%` }}
              />
            </div>
            {goalProgress >= 100 ? (
              <p className="text-sm text-green-600 dark:text-green-400 font-medium">
                🎉 Congratulations! You've achieved your reading goal!
              </p>
            ) : (
              <p className="text-sm text-muted-foreground">
                {targetBooks - currentBooks} books remaining
              </p>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Quick Stats */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <p className="text-sm text-muted-foreground">Books Read</p>
                <p className="text-2xl font-bold">{readingStats.totalBooksRead}</p>
                <p className="text-xs text-muted-foreground">
                  {readingStats.booksReadThisYear} this year
                </p>
              </div>
              <BookOpen className="h-8 w-8 text-muted-foreground" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <p className="text-sm text-muted-foreground">Pages Read</p>
                <p className="text-2xl font-bold">{readingStats.totalPagesRead}</p>
                <p className="text-xs text-muted-foreground">
                  {readingStats.pagesReadThisMonth} this month
                </p>
              </div>
              <FileText className="h-8 w-8 text-muted-foreground" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <p className="text-sm text-muted-foreground">Reading Now</p>
                <p className="text-2xl font-bold">{readingStats.totalBooksReading}</p>
                <p className="text-xs text-muted-foreground">
                  {readingStats.totalBooksWantToRead} to read
                </p>
              </div>
              <TrendingUp className="h-8 w-8 text-blue-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <p className="text-sm text-muted-foreground">Reading Time</p>
                <p className="text-2xl font-bold">{Math.floor(totalReadingTime / 60)}h</p>
                <p className="text-xs text-muted-foreground">
                  {totalReadingTime % 60}m last 10 sessions
                </p>
              </div>
              <Clock className="h-8 w-8 text-muted-foreground" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Currently Reading */}
      {currentlyReading.length > 0 && (
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle className="flex items-center gap-2">
                <BookOpen className="h-5 w-5" />
                Currently Reading
              </CardTitle>
              <Button asChild variant="ghost" size="sm">
                <Link href="/dashboard/books">View All</Link>
              </Button>
            </div>
          </CardHeader>
          <CardContent>
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {currentlyReading.slice(0, 3).map((item) => (
                <Card key={item.log.logId} className="overflow-hidden">
                  <CardContent className="p-4">
                    <div className="space-y-2">
                      <h4 className="font-semibold line-clamp-1">{item.book.title}</h4>
                      <p className="text-sm text-muted-foreground line-clamp-1">
                        {item.authors}
                      </p>
                      {item.book.pages && item.log.currentPage !== null && (
                        <div className="space-y-1">
                          <div className="flex justify-between text-xs">
                            <span className="text-muted-foreground">Progress</span>
                            <span className="font-medium">
                              {Math.round((item.log.currentPage / item.book.pages) * 100)}%
                            </span>
                          </div>
                          <div className="h-2 overflow-hidden rounded-full bg-secondary">
                            <div
                              className="h-full bg-primary transition-all"
                              style={{
                                width: `${(item.log.currentPage / item.book.pages) * 100}%`,
                              }}
                            />
                          </div>
                          <p className="text-xs text-muted-foreground">
                            {item.log.currentPage} / {item.book.pages} pages
                          </p>
                        </div>
                      )}
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Reading History Chart */}
      <ReadingHistoryChart
        data={readingHistory.map(item => ({
          period: item.period || new Date().toISOString(),
          booksRead: item.booksRead || 0,
          pagesRead: item.pagesRead || 0,
        }))}
        title="Reading History"
        description="Track your reading progress over time"
      />

      {/* Recently Finished Books */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center gap-2">
              <Star className="h-5 w-5" />
              Recently Finished
            </CardTitle>
            <Button asChild variant="ghost" size="sm">
              <Link href="/dashboard/calendar">View Calendar</Link>
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {recentBooksData.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-8 text-center">
              <BookOpen className="mb-2 h-12 w-12 text-muted-foreground" />
              <p className="text-sm text-muted-foreground">
                No books finished yet. Keep reading!
              </p>
            </div>
          ) : (
            <div className="space-y-3">
              {recentBooksData.map((item) => (
                <div
                  key={item.log.logId}
                  className="flex items-center justify-between rounded-lg border p-3 transition-colors hover:bg-accent"
                >
                  <div className="flex-1">
                    <h4 className="font-medium">{item.book.title}</h4>
                    <div className="flex items-center gap-2 mt-1">
                      <p className="text-sm text-muted-foreground">{item.authors}</p>
                      {item.book.pages && (
                        <span className="text-xs text-muted-foreground">
                          • {item.book.pages} pages
                        </span>
                      )}
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    {item.log.rating && (
                      <Badge variant="secondary">
                        <Star className="h-3 w-3 fill-yellow-400 text-yellow-400 mr-1" />
                        {item.log.rating}
                      </Badge>
                    )}
                    {item.log.dateFinished && (
                      <span className="text-xs text-muted-foreground">
                        {new Date(item.log.dateFinished).toLocaleDateString("en-US", {
                          month: "short",
                          day: "numeric",
                        })}
                      </span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
