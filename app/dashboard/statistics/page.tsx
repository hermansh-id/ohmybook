import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  getReadingStats,
  getCurrentYearGoal,
  getMonthlyStats,
  getAuthorsWithStats,
  getGenresWithStats,
  getReadingSessions,
  getLibraryStats,
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
} from "lucide-react";

export default async function StatisticsPage() {
  const [stats, goal, monthlyStats, authors, genres, sessions, libraryStats] = await Promise.all([
    getReadingStats(),
    getCurrentYearGoal(),
    getMonthlyStats(new Date().getFullYear()),
    getAuthorsWithStats(),
    getGenresWithStats(),
    getReadingSessions(100),
    getLibraryStats(),
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

  const totalReadingTime = sessions.reduce(
    (sum, s) => sum + (s.session.minutesRead || 0),
    0
  );

  const avgPagesPerDay =
    sessions.length > 0
      ? sessions.reduce((sum, s) => sum + (s.session.pagesRead || 0), 0) /
        sessions.length
      : 0;

  // Top authors
  const topAuthors = authors
    .filter((a) => a.booksRead > 0)
    .sort((a, b) => b.booksRead - a.booksRead)
    .slice(0, 5);

  // Top genres
  const topGenres = genres
    .filter((g) => g.booksRead > 0)
    .sort((a, b) => b.booksRead - a.booksRead)
    .slice(0, 5);

  const targetBooks = yearGoal.targetBooks ?? 52;
  const currentBooks = yearGoal.currentBooks ?? 0;

  const goalProgress = targetBooks > 0
    ? (currentBooks / targetBooks) * 100
    : 0;

  return (
    <div className="flex flex-col gap-4 p-4 md:gap-6 md:p-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Statistics</h1>
        <p className="text-muted-foreground">
          Overview of your reading journey
        </p>
      </div>

      {/* Library Overview */}
      <Card className="border-2">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Library className="h-5 w-5 text-primary" />
            Library Overview
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
            <div className="space-y-1">
              <div className="flex items-center gap-2">
                <BookOpen className="h-4 w-4 text-muted-foreground" />
                <p className="text-sm text-muted-foreground">Total Books</p>
              </div>
              <p className="text-3xl font-bold">{libraryStats.totalBooks}</p>
            </div>
            <div className="space-y-1">
              <div className="flex items-center gap-2">
                <Users className="h-4 w-4 text-muted-foreground" />
                <p className="text-sm text-muted-foreground">Authors</p>
              </div>
              <p className="text-3xl font-bold">{libraryStats.totalAuthors}</p>
            </div>
            <div className="space-y-1">
              <div className="flex items-center gap-2">
                <Tags className="h-4 w-4 text-muted-foreground" />
                <p className="text-sm text-muted-foreground">Genres</p>
              </div>
              <p className="text-3xl font-bold">{libraryStats.totalGenres}</p>
            </div>
            <div className="space-y-1">
              <div className="flex items-center gap-2">
                <FileText className="h-4 w-4 text-muted-foreground" />
                <p className="text-sm text-muted-foreground">Total Pages</p>
              </div>
              <p className="text-3xl font-bold">{libraryStats.totalPages.toLocaleString()}</p>
            </div>
            <div className="space-y-1">
              <div className="flex items-center gap-2">
                <TrendingUp className="h-4 w-4 text-muted-foreground" />
                <p className="text-sm text-muted-foreground">Avg Pages/Book</p>
              </div>
              <p className="text-3xl font-bold">{libraryStats.avgPages}</p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Overall Statistics */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <p className="text-sm text-muted-foreground">Books Read</p>
                <p className="text-2xl font-bold">{readingStats.totalBooksRead}</p>
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
                  {readingStats.averageRating
                    ? Number(readingStats.averageRating).toFixed(1)
                    : "N/A"}
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
                  {Math.floor(totalReadingTime / 60)}h
                </p>
              </div>
              <Clock className="h-8 w-8 text-muted-foreground" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Current Status */}
      <div className="grid gap-4 lg:grid-cols-3">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between mb-2">
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
            <div className="flex items-center justify-between mb-2">
              <div className="space-y-1">
                <p className="text-sm text-muted-foreground">Want to Read</p>
                <p className="text-3xl font-bold">{readingStats.totalBooksWantToRead}</p>
              </div>
              <Target className="h-8 w-8 text-orange-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between mb-2">
              <div className="space-y-1">
                <p className="text-sm text-muted-foreground">Avg Pages/Day</p>
                <p className="text-3xl font-bold">{Math.round(avgPagesPerDay)}</p>
              </div>
              <TrendingUp className="h-8 w-8 text-green-500" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Year Goal */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center gap-2">
              <Target className="h-5 w-5" />
              {new Date().getFullYear()} Reading Goal
            </CardTitle>
            <Badge variant={goalProgress >= 100 ? "default" : "secondary"}>
              {goalProgress.toFixed(0)}%
            </Badge>
          </div>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            <div className="flex justify-between text-sm">
              <span className="text-muted-foreground">Progress</span>
              <span className="font-medium">
                {currentBooks} / {targetBooks} books
              </span>
            </div>
            <div className="h-4 overflow-hidden rounded-full bg-secondary">
              <div
                className={`h-full transition-all ${
                  goalProgress >= 100 ? "bg-green-500" : "bg-primary"
                }`}
                style={{ width: `${Math.min(goalProgress, 100)}%` }}
              />
            </div>
            {goalProgress >= 100 && (
              <p className="text-sm text-green-600 dark:text-green-400 flex items-center gap-1">
                <Award className="h-4 w-4" />
                Goal achieved! 🎉
              </p>
            )}
          </div>
        </CardContent>
      </Card>

      {/* This Year & Month */}
      <div className="grid gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Calendar className="h-5 w-5" />
              This Year
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
                <span className="font-semibold">{readingStats.pagesReadThisYear}</span>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Calendar className="h-5 w-5" />
              This Month
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
                <span className="font-semibold">{readingStats.pagesReadThisMonth}</span>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Top Authors & Genres */}
      <div className="grid gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Top Authors</CardTitle>
          </CardHeader>
          <CardContent>
            {topAuthors.length === 0 ? (
              <p className="text-sm text-muted-foreground text-center py-4">
                No authors yet
              </p>
            ) : (
              <div className="space-y-3">
                {topAuthors.map((author, index) => (
                  <div
                    key={author.author.authorId}
                    className="flex items-center justify-between"
                  >
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-bold text-muted-foreground w-6">
                        #{index + 1}
                      </span>
                      <span className="font-medium">{author.author.name}</span>
                    </div>
                    <Badge variant="secondary">{author.booksRead} books</Badge>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Top Genres</CardTitle>
          </CardHeader>
          <CardContent>
            {topGenres.length === 0 ? (
              <p className="text-sm text-muted-foreground text-center py-4">
                No genres yet
              </p>
            ) : (
              <div className="space-y-3">
                {topGenres.map((genre, index) => (
                  <div
                    key={genre.genre.genreId}
                    className="flex items-center justify-between"
                  >
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-bold text-muted-foreground w-6">
                        #{index + 1}
                      </span>
                      <span className="font-medium">{genre.genre.genreName}</span>
                    </div>
                    <Badge variant="secondary">{genre.booksRead} books</Badge>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
