import { createServerFn } from "@tanstack/react-start";
import { getUnfinishedBooksAction } from "@/actions/reading-sessions";

export const getDashboardDataAction = createServerFn({ method: "GET" }).handler(async () => {
  const {
    getReadingStats,
    getCurrentYearGoal,
    getMonthlyStats,
    getFinishedBooks,
    getCurrentlyReadingBooks,
    getReadingSessions,
    getReadingHistory,
    getLibraryCompletion,
    getDailyReadingActivity,
    getReadingStreaks,
  } = await import("@/lib/db/queries");

  const [stats, goal, monthlyStats, recentBooksData, currentlyReading, recentSessions, readingHistory, libraryCompletion, dailyActivity, streaks, unfinishedBooks] =
    await Promise.all([
      getReadingStats(),
      getCurrentYearGoal(),
      getMonthlyStats(new Date().getFullYear()),
      getFinishedBooks(5),
      getCurrentlyReadingBooks(),
      getReadingSessions(10),
      getReadingHistory(12),
      getLibraryCompletion(),
      getDailyReadingActivity(),
      getReadingStreaks(),
      getUnfinishedBooksAction(),
    ]);

  return { stats, goal, monthlyStats, recentBooksData, currentlyReading, recentSessions, readingHistory, libraryCompletion, dailyActivity, streaks, unfinishedBooks };
});
