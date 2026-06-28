import { createServerFn } from "@tanstack/react-start";

export const getStatisticsDataAction = createServerFn({ method: "GET" }).handler(async () => {
  const {
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
  } = await import("@/lib/db/queries");

  const [stats, goal, monthlyStats, authors, genres, sessions, libraryStats, libraryCompletion, streaks, topRated, quoteStats, readingHistory, yearlyStats] =
    await Promise.all([
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

  return { stats, goal, monthlyStats, authors, genres, sessions, libraryStats, libraryCompletion, streaks, topRated, quoteStats, readingHistory, yearlyStats };
});
