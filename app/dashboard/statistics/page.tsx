import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { ReadingHistoryChart } from "@/components/reading-history-chart";
import {
  getReadingStats,
  getCurrentYearGoal,
  getMonthlyStats,
  getAuthorsWithStats,
  getGenresWithStats,
  getReadingSessions,
  getLibraryStats,
  getLibraryCompletion,
  getReadingStreaks,
  getTopRatedBooks,
  getQuoteStats,
  getReadingHistory,
  getYearlyStats,
} from "@/lib/db/queries";
import {
  BookOpen,
  FileText,
  Star,
  Target,
  TrendingUp,
  Clock,
  Calendar,
  Award,
  Library,
  Users,
  Tags,
  Flame,
  Trophy,
  Quote,
  Heart,
  CheckCircle2,
  BookMarked,
  BarChart3,
  ExternalLink,
  Percent,
} from "lucide-react";
import Link from "next/link";

const MONTH_NAMES = [
  "Jan", "Feb", "Mar", "Apr", "May", "Jun",
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
];

export default async function StatisticsPage() {
  const [
    stats,
    goal,
    monthlyStats,
    authors,
    genres,
    sessions,
    libraryStats,
    libraryCompletion,
    streaks,
    topRated,
    quoteStats,
    readingHistory,
    yearlyStats,
  ] = await Promise.all([
    getReadingStats(),
    getCurrentYearGoal(),
    getMonthlyStats(new Date().getFullYear()),
    getAuthorsWithStats(),
    getGenresWithStats(),
    getReadingSessions(500),
    getLibraryStats(),
    getLibraryCompletion(),
    getReadingStreaks(),
    getTopRatedBooks(10),
    getQuoteStats(),
    getReadingHistory(24),
    getYearlyStats(),
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

  const yearGoal = goal[0] || { targetBooks: 52, currentBooks: 0 };

  const totalReadingMinutes = sessions.reduce((sum, s) => sum + (s.session.minutesRead || 0), 0);
  const totalPagesFromSessions = sessions.reduce((sum, s) => sum + (s.session.pagesRead || 0), 0);
  const avgPagesPerSession = sessions.length > 0 ? Math.round(totalPagesFromSessions / sessions.length) : 0;

  const topAuthors = authors.filter((a) => a.booksRead > 0).sort((a, b) => b.booksRead - a.booksRead).slice(0, 10);
  const topGenres = genres.filter((g) => g.booksRead > 0).sort((a, b) => b.booksRead - a.booksRead).slice(0, 10);

  const targetBooks = yearGoal.targetBooks ?? 52;
  const currentBooks = yearGoal.currentBooks ?? 0;
  const goalProgress = targetBooks > 0 ? (currentBooks / targetBooks) * 100 : 0;
  const booksAhead = currentBooks - Math.floor((new Date().getMonth() / 12) * targetBooks);

  const currentYear = new Date().getFullYear();
  const monthlyForYear = monthlyStats;

  const allYears = yearlyStats as Array<{ year: number; booksRead?: number; pagesRead?: number }>;

  const didNotFinishCount = sessions.length; // placeholder — real count needs separate query

  return (
    <div className="flex flex-col gap-6 p-4 md:p-6">
      <div className="flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Statistics</h1>
          <p className="text-muted-foreground">Complete overview of your reading journey</p>
        </div>
        <Link
          href="/api/stats/markdown"
          target="_blank"
          className="flex items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground transition-colors mt-2 sm:mt-0"
        >
          <ExternalLink className="h-3.5 w-3.5" />
          View as Markdown
        </Link>
      </div>

      {/* ── STREAKS ── */}
      <div className="grid gap-4 sm:grid-cols-3">
        <Card className="border-orange-200 dark:border-orange-900">
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <p className="text-sm text-muted-foreground">Current Streak</p>
                <p className="text-3xl font-bold">{streaks.currentStreak} <span className="text-base font-normal text-muted-foreground">days</span></p>
              </div>
              <Flame className="h-9 w-9 text-orange-500" />
            </div>
          </CardContent>
        </Card>
        <Card className="border-yellow-200 dark:border-yellow-900">
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <p className="text-sm text-muted-foreground">Best Streak</p>
                <p className="text-3xl font-bold">{streaks.bestStreak} <span className="text-base font-normal text-muted-foreground">days</span></p>
              </div>
              <Trophy className="h-9 w-9 text-yellow-500" />
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <p className="text-sm text-muted-foreground">Total Reading Days</p>
                <p className="text-3xl font-bold">{streaks.totalReadingDays} <span className="text-base font-normal text-muted-foreground">days</span></p>
              </div>
              <Calendar className="h-9 w-9 text-muted-foreground" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* ── LIBRARY OVERVIEW ── */}
      <Card className="border-2">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Library className="h-5 w-5 text-primary" />
            Library Overview
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-5">
            <div className="space-y-1">
              <div className="flex items-center gap-1.5">
                <BookOpen className="h-4 w-4 text-muted-foreground" />
                <p className="text-sm text-muted-foreground">Total Books</p>
              </div>
              <p className="text-3xl font-bold">{libraryStats.totalBooks.toLocaleString()}</p>
            </div>
            <div className="space-y-1">
              <div className="flex items-center gap-1.5">
                <Users className="h-4 w-4 text-muted-foreground" />
                <p className="text-sm text-muted-foreground">Authors</p>
              </div>
              <p className="text-3xl font-bold">{libraryStats.totalAuthors.toLocaleString()}</p>
            </div>
            <div className="space-y-1">
              <div className="flex items-center gap-1.5">
                <Tags className="h-4 w-4 text-muted-foreground" />
                <p className="text-sm text-muted-foreground">Genres</p>
              </div>
              <p className="text-3xl font-bold">{libraryStats.totalGenres.toLocaleString()}</p>
            </div>
            <div className="space-y-1">
              <div className="flex items-center gap-1.5">
                <FileText className="h-4 w-4 text-muted-foreground" />
                <p className="text-sm text-muted-foreground">Total Pages</p>
              </div>
              <p className="text-3xl font-bold">{libraryStats.totalPages.toLocaleString()}</p>
            </div>
            <div className="space-y-1">
              <div className="flex items-center gap-1.5">
                <BarChart3 className="h-4 w-4 text-muted-foreground" />
                <p className="text-sm text-muted-foreground">Avg Pages/Book</p>
              </div>
              <p className="text-3xl font-bold">{libraryStats.avgPages.toLocaleString()}</p>
            </div>
          </div>

          <Separator className="my-6" />

          {/* Completion bar */}
          <div className="space-y-3">
            <div className="flex items-center justify-between text-sm">
              <div className="flex items-center gap-1.5">
                <Percent className="h-4 w-4 text-muted-foreground" />
                <span className="text-muted-foreground">Library Completion</span>
              </div>
              <span className="font-semibold">
                {libraryCompletion.booksRead} / {libraryCompletion.totalBooks} books ({libraryCompletion.percentage}%)
              </span>
            </div>
            <div className="h-3 overflow-hidden rounded-full bg-secondary">
              <div
                className="h-full bg-primary transition-all"
                style={{ width: `${Math.min(libraryCompletion.percentage, 100)}%` }}
              />
            </div>
            {libraryCompletion.estimatedCompletionMonths != null && (
              <p className="text-xs text-muted-foreground">
                At your current pace, ~{libraryCompletion.estimatedCompletionMonths} months to finish the rest
              </p>
            )}
          </div>
        </CardContent>
      </Card>

      {/* ── OVERALL STATS ── */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <p className="text-sm text-muted-foreground">Books Read (All Time)</p>
                <p className="text-2xl font-bold">{readingStats.totalBooksRead}</p>
              </div>
              <CheckCircle2 className="h-8 w-8 text-green-500" />
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <p className="text-sm text-muted-foreground">Pages Read (All Time)</p>
                <p className="text-2xl font-bold">{Number(readingStats.totalPagesRead).toLocaleString()}</p>
              </div>
              <FileText className="h-8 w-8 text-muted-foreground" />
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <p className="text-sm text-muted-foreground">Avg Rating</p>
                <p className="text-2xl font-bold">
                  {readingStats.averageRating ? Number(readingStats.averageRating).toFixed(2) : "—"}
                </p>
              </div>
              <Star className="h-8 w-8 text-yellow-400 fill-yellow-400" />
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <p className="text-sm text-muted-foreground">Reading Time</p>
                <p className="text-2xl font-bold">
                  {totalReadingMinutes >= 60
                    ? `${Math.floor(totalReadingMinutes / 60)}h ${totalReadingMinutes % 60}m`
                    : `${totalReadingMinutes}m`}
                </p>
              </div>
              <Clock className="h-8 w-8 text-muted-foreground" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* ── CURRENT STATUS ── */}
      <div className="grid gap-4 sm:grid-cols-3">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <p className="text-sm text-muted-foreground">Currently Reading</p>
                <p className="text-3xl font-bold">{readingStats.totalBooksReading}</p>
              </div>
              <BookOpen className="h-8 w-8 text-blue-500" />
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <p className="text-sm text-muted-foreground">Want to Read</p>
                <p className="text-3xl font-bold">{readingStats.totalBooksWantToRead}</p>
              </div>
              <BookMarked className="h-8 w-8 text-orange-500" />
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <p className="text-sm text-muted-foreground">Avg Pages / Session</p>
                <p className="text-3xl font-bold">{avgPagesPerSession}</p>
              </div>
              <TrendingUp className="h-8 w-8 text-green-500" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* ── YEAR GOAL ── */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center gap-2">
              <Target className="h-5 w-5" />
              {currentYear} Reading Goal
            </CardTitle>
            <Badge variant={goalProgress >= 100 ? "default" : "secondary"}>
              {goalProgress.toFixed(0)}%
            </Badge>
          </div>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            <div className="flex justify-between text-sm">
              <span className="text-muted-foreground">Progress</span>
              <span className="font-medium">{currentBooks} / {targetBooks} books</span>
            </div>
            <div className="h-4 overflow-hidden rounded-full bg-secondary">
              <div
                className={`h-full transition-all ${goalProgress >= 100 ? "bg-green-500" : "bg-primary"}`}
                style={{ width: `${Math.min(goalProgress, 100)}%` }}
              />
            </div>
            <div className="flex items-center justify-between text-xs text-muted-foreground">
              <span>
                {booksAhead >= 0
                  ? `${booksAhead} books ahead of schedule`
                  : `${Math.abs(booksAhead)} books behind schedule`}
              </span>
              {goalProgress >= 100 && (
                <span className="text-green-600 dark:text-green-400 flex items-center gap-1">
                  <Award className="h-3.5 w-3.5" />
                  Goal achieved!
                </span>
              )}
            </div>
          </div>
        </CardContent>
      </Card>

      {/* ── THIS YEAR / THIS MONTH ── */}
      <div className="grid gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Calendar className="h-5 w-5" />
              This Year ({currentYear})
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              <div className="flex justify-between">
                <span className="text-sm text-muted-foreground">Books Read</span>
                <span className="font-semibold">{readingStats.booksReadThisYear}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-muted-foreground">Pages Read</span>
                <span className="font-semibold">{Number(readingStats.pagesReadThisYear).toLocaleString()}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-muted-foreground">Avg Books/Month</span>
                <span className="font-semibold">
                  {((readingStats.booksReadThisYear ?? 0) / Math.max(new Date().getMonth() + 1, 1)).toFixed(1)}
                </span>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Calendar className="h-5 w-5" />
              This Month ({MONTH_NAMES[new Date().getMonth()]})
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              <div className="flex justify-between">
                <span className="text-sm text-muted-foreground">Books Read</span>
                <span className="font-semibold">{readingStats.booksReadThisMonth}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-muted-foreground">Pages Read</span>
                <span className="font-semibold">{Number(readingStats.pagesReadThisMonth).toLocaleString()}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-muted-foreground">Reading Sessions</span>
                <span className="font-semibold">
                  {sessions.filter((s) => {
                    const d = new Date(s.session.sessionDate || "");
                    return d.getMonth() === new Date().getMonth() && d.getFullYear() === currentYear;
                  }).length}
                </span>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* ── READING HISTORY CHART ── */}
      <ReadingHistoryChart
        data={readingHistory.filter(r => r.period !== null) as { period: string; booksRead: number; pagesRead: number }[]}
        title="Reading History"
        description="Books and pages finished over the last 24 months"
      />

      {/* ── MONTHLY BREAKDOWN (current year) ── */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <BarChart3 className="h-5 w-5" />
            {currentYear} — Month by Month
          </CardTitle>
        </CardHeader>
        <CardContent>
          {monthlyForYear.length === 0 ? (
            <p className="text-sm text-muted-foreground text-center py-4">No monthly data yet</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b text-left text-muted-foreground">
                    <th className="pb-2 font-medium">Month</th>
                    <th className="pb-2 font-medium text-right">Books</th>
                    <th className="pb-2 font-medium text-right">Pages</th>
                  </tr>
                </thead>
                <tbody>
                  {monthlyForYear.map((m) => (
                    <tr key={m.month} className="border-b last:border-0">
                      <td className="py-2 font-medium">{MONTH_NAMES[(m.month || 1) - 1]}</td>
                      <td className="py-2 text-right">{m.booksRead || 0}</td>
                      <td className="py-2 text-right">{(m.pagesRead || 0).toLocaleString()}</td>
                    </tr>
                  ))}
                </tbody>
                <tfoot>
                  <tr className="text-muted-foreground font-semibold">
                    <td className="pt-3">Total</td>
                    <td className="pt-3 text-right">{monthlyForYear.reduce((s, m) => s + (m.booksRead || 0), 0)}</td>
                    <td className="pt-3 text-right">{monthlyForYear.reduce((s, m) => s + (m.pagesRead || 0), 0).toLocaleString()}</td>
                  </tr>
                </tfoot>
              </table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* ── YEARLY HISTORY ── */}
      {allYears.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <TrendingUp className="h-5 w-5" />
              Year over Year
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b text-left text-muted-foreground">
                    <th className="pb-2 font-medium">Year</th>
                    <th className="pb-2 font-medium text-right">Books</th>
                    <th className="pb-2 font-medium text-right">Pages</th>
                  </tr>
                </thead>
                <tbody>
                  {allYears.sort((a, b) => b.year - a.year).map((y) => (
                    <tr key={y.year} className="border-b last:border-0">
                      <td className="py-2 font-medium">{y.year}</td>
                      <td className="py-2 text-right">{y.booksRead || 0}</td>
                      <td className="py-2 text-right">{(y.pagesRead || 0).toLocaleString()}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      )}

      {/* ── TOP RATED BOOKS ── */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Star className="h-5 w-5 text-yellow-400 fill-yellow-400" />
            Top Rated Books
          </CardTitle>
        </CardHeader>
        <CardContent>
          {topRated.length === 0 ? (
            <p className="text-sm text-muted-foreground text-center py-4">No rated books yet</p>
          ) : (
            <div className="space-y-3">
              {topRated.map((item, index) => (
                <div key={item.log.logId} className="flex items-center justify-between gap-2">
                  <div className="flex items-center gap-2 min-w-0">
                    <span className="text-sm font-bold text-muted-foreground w-6 shrink-0">#{index + 1}</span>
                    <div className="min-w-0">
                      <p className="font-medium truncate">{item.book.title}</p>
                      {item.authors && (
                        <p className="text-xs text-muted-foreground truncate">{item.authors}</p>
                      )}
                    </div>
                  </div>
                  <div className="flex items-center gap-1 shrink-0">
                    <Star className="h-3.5 w-3.5 text-yellow-400 fill-yellow-400" />
                    <span className="text-sm font-semibold">{item.log.rating}</span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* ── TOP AUTHORS & GENRES ── */}
      <div className="grid gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Users className="h-5 w-5" />
              Top Authors
            </CardTitle>
          </CardHeader>
          <CardContent>
            {topAuthors.length === 0 ? (
              <p className="text-sm text-muted-foreground text-center py-4">No authors yet</p>
            ) : (
              <div className="space-y-3">
                {topAuthors.map((author, index) => (
                  <div key={author.author.authorId} className="flex items-center justify-between gap-2">
                    <div className="flex items-center gap-2 min-w-0">
                      <span className="text-sm font-bold text-muted-foreground w-6 shrink-0">#{index + 1}</span>
                      <div className="min-w-0">
                        <p className="font-medium truncate">{author.author.name}</p>
                        <p className="text-xs text-muted-foreground">{author.totalBooks} in library</p>
                      </div>
                    </div>
                    <div className="flex flex-col items-end gap-0.5 shrink-0">
                      <Badge variant="secondary">{author.booksRead} read</Badge>
                      {author.averageRating && (
                        <span className="text-xs text-muted-foreground">★ {Number(author.averageRating).toFixed(1)}</span>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Tags className="h-5 w-5" />
              Top Genres
            </CardTitle>
          </CardHeader>
          <CardContent>
            {topGenres.length === 0 ? (
              <p className="text-sm text-muted-foreground text-center py-4">No genres yet</p>
            ) : (
              <div className="space-y-3">
                {topGenres.map((genre, index) => (
                  <div key={genre.genre.genreId} className="flex items-center justify-between gap-2">
                    <div className="flex items-center gap-2 min-w-0">
                      <span className="text-sm font-bold text-muted-foreground w-6 shrink-0">#{index + 1}</span>
                      <div className="min-w-0">
                        <p className="font-medium truncate">{genre.genre.genreName}</p>
                        <p className="text-xs text-muted-foreground">{genre.totalBooks} in library</p>
                      </div>
                    </div>
                    <div className="flex flex-col items-end gap-0.5 shrink-0">
                      <Badge variant="secondary">{genre.booksRead} read</Badge>
                      {genre.averageRating && (
                        <span className="text-xs text-muted-foreground">★ {Number(genre.averageRating).toFixed(1)}</span>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* ── QUOTES ── */}
      <div className="grid gap-4 sm:grid-cols-3">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <p className="text-sm text-muted-foreground">Total Quotes</p>
                <p className="text-3xl font-bold">{quoteStats.totalQuotes}</p>
              </div>
              <Quote className="h-8 w-8 text-muted-foreground" />
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <p className="text-sm text-muted-foreground">Favorites</p>
                <p className="text-3xl font-bold">{quoteStats.favoriteQuotes}</p>
              </div>
              <Heart className="h-8 w-8 text-red-400" />
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <p className="text-sm text-muted-foreground">Books with Quotes</p>
                <p className="text-3xl font-bold">{quoteStats.booksWithQuotes}</p>
              </div>
              <BookOpen className="h-8 w-8 text-muted-foreground" />
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
