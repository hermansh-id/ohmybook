"use server";

import { NextResponse } from "next/server";
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
  getYearlyStats,
} from "@/lib/db/queries";

const MONTH_NAMES = [
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December",
];

export async function GET() {
  try {
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

    const currentYear = new Date().getFullYear();
    const now = new Date();
    const allYears = (yearlyStats as Array<{ year: number; booksRead?: number; pagesRead?: number }>)
      .sort((a, b) => b.year - a.year);

    const readingHours = Math.floor(totalReadingMinutes / 60);
    const readingMins = totalReadingMinutes % 60;

    const lines: string[] = [];

    lines.push(`# Bookjet Reading Statistics`);
    lines.push(`> Generated on ${now.toLocaleDateString("en-US", { weekday: "long", year: "numeric", month: "long", day: "numeric" })}`);
    lines.push(``);

    // Streaks
    lines.push(`## 🔥 Reading Streaks`);
    lines.push(``);
    lines.push(`| Metric | Value |`);
    lines.push(`|--------|-------|`);
    lines.push(`| Current Streak | ${streaks.currentStreak} days |`);
    lines.push(`| Best Streak | ${streaks.bestStreak} days |`);
    lines.push(`| Total Reading Days | ${streaks.totalReadingDays} days |`);
    lines.push(``);

    // Library overview
    lines.push(`## 📚 Library Overview`);
    lines.push(``);
    lines.push(`| Metric | Value |`);
    lines.push(`|--------|-------|`);
    lines.push(`| Total Books in Library | ${libraryStats.totalBooks.toLocaleString()} |`);
    lines.push(`| Unique Authors | ${libraryStats.totalAuthors.toLocaleString()} |`);
    lines.push(`| Unique Genres | ${libraryStats.totalGenres.toLocaleString()} |`);
    lines.push(`| Total Pages in Library | ${libraryStats.totalPages.toLocaleString()} |`);
    lines.push(`| Average Pages per Book | ${libraryStats.avgPages.toLocaleString()} |`);
    lines.push(`| Books Read | ${libraryCompletion.booksRead} / ${libraryCompletion.totalBooks} (${libraryCompletion.percentage}%) |`);
    if (libraryCompletion.estimatedCompletionMonths != null) {
      lines.push(`| Estimated Months to Complete Library | ${libraryCompletion.estimatedCompletionMonths} months |`);
    }
    lines.push(``);

    // Overall stats
    lines.push(`## 📊 Overall Reading Stats`);
    lines.push(``);
    lines.push(`| Metric | Value |`);
    lines.push(`|--------|-------|`);
    lines.push(`| Books Read (All Time) | ${readingStats.totalBooksRead} |`);
    lines.push(`| Pages Read (All Time) | ${Number(readingStats.totalPagesRead).toLocaleString()} |`);
    lines.push(`| Average Rating | ${readingStats.averageRating ? Number(readingStats.averageRating).toFixed(2) : "N/A"} |`);
    lines.push(`| Total Reading Time | ${readingHours}h ${readingMins}m |`);
    lines.push(`| Reading Sessions Logged | ${sessions.length} |`);
    lines.push(`| Avg Pages per Session | ${avgPagesPerSession} |`);
    lines.push(``);

    // Current status
    lines.push(`## 📖 Current Status`);
    lines.push(``);
    lines.push(`| Status | Count |`);
    lines.push(`|--------|-------|`);
    lines.push(`| Currently Reading | ${readingStats.totalBooksReading} |`);
    lines.push(`| Want to Read | ${readingStats.totalBooksWantToRead} |`);
    lines.push(``);

    // Year goal
    lines.push(`## 🎯 ${currentYear} Reading Goal`);
    lines.push(``);
    lines.push(`| Metric | Value |`);
    lines.push(`|--------|-------|`);
    lines.push(`| Target | ${targetBooks} books |`);
    lines.push(`| Progress | ${currentBooks} books |`);
    lines.push(`| Completion | ${goalProgress.toFixed(1)}% |`);
    lines.push(`| Status | ${goalProgress >= 100 ? "✅ Goal achieved!" : goalProgress >= 75 ? "🟡 Almost there" : goalProgress >= 50 ? "🔵 On track" : "🔴 Behind"} |`);
    lines.push(``);

    // This year / month
    lines.push(`## 📅 This Year (${currentYear})`);
    lines.push(``);
    lines.push(`| Metric | Value |`);
    lines.push(`|--------|-------|`);
    lines.push(`| Books Read | ${readingStats.booksReadThisYear} |`);
    lines.push(`| Pages Read | ${Number(readingStats.pagesReadThisYear).toLocaleString()} |`);
    lines.push(`| Avg Books/Month | ${((readingStats.booksReadThisYear ?? 0) / Math.max(now.getMonth() + 1, 1)).toFixed(1)} |`);
    lines.push(``);

    lines.push(`## 📅 This Month (${MONTH_NAMES[now.getMonth()]} ${currentYear})`);
    lines.push(``);
    lines.push(`| Metric | Value |`);
    lines.push(`|--------|-------|`);
    lines.push(`| Books Read | ${readingStats.booksReadThisMonth} |`);
    lines.push(`| Pages Read | ${Number(readingStats.pagesReadThisMonth).toLocaleString()} |`);
    lines.push(``);

    // Monthly breakdown
    if (monthlyStats.length > 0) {
      lines.push(`## 📆 ${currentYear} — Month by Month`);
      lines.push(``);
      lines.push(`| Month | Books | Pages |`);
      lines.push(`|-------|------:|------:|`);
      for (const m of monthlyStats) {
        lines.push(`| ${MONTH_NAMES[(m.month || 1) - 1]} | ${m.booksRead || 0} | ${(m.pagesRead || 0).toLocaleString()} |`);
      }
      const totalBooks = monthlyStats.reduce((s, m) => s + (m.booksRead || 0), 0);
      const totalPages = monthlyStats.reduce((s, m) => s + (m.pagesRead || 0), 0);
      lines.push(`| **Total** | **${totalBooks}** | **${totalPages.toLocaleString()}** |`);
      lines.push(``);
    }

    // Year over year
    if (allYears.length > 0) {
      lines.push(`## 📈 Year over Year`);
      lines.push(``);
      lines.push(`| Year | Books | Pages |`);
      lines.push(`|------|------:|------:|`);
      for (const y of allYears) {
        lines.push(`| ${y.year} | ${y.booksRead || 0} | ${(y.pagesRead || 0).toLocaleString()} |`);
      }
      lines.push(``);
    }

    // Top rated books
    if (topRated.length > 0) {
      lines.push(`## ⭐ Top Rated Books`);
      lines.push(``);
      lines.push(`| # | Title | Author(s) | Rating |`);
      lines.push(`|---|-------|-----------|-------:|`);
      topRated.forEach((item, index) => {
        lines.push(`| ${index + 1} | ${item.book.title} | ${item.authors || "—"} | ★ ${item.log.rating} |`);
      });
      lines.push(``);
    }

    // Top authors
    if (topAuthors.length > 0) {
      lines.push(`## 👤 Top Authors`);
      lines.push(``);
      lines.push(`| # | Author | In Library | Books Read | Avg Rating |`);
      lines.push(`|---|--------|------------|------------|------------|`);
      topAuthors.forEach((author, index) => {
        lines.push(
          `| ${index + 1} | ${author.author.name} | ${author.totalBooks} | ${author.booksRead} | ${author.averageRating ? `★ ${Number(author.averageRating).toFixed(1)}` : "—"} |`
        );
      });
      lines.push(``);
    }

    // Top genres
    if (topGenres.length > 0) {
      lines.push(`## 🏷️ Top Genres`);
      lines.push(``);
      lines.push(`| # | Genre | In Library | Books Read | Avg Rating |`);
      lines.push(`|---|-------|------------|------------|------------|`);
      topGenres.forEach((genre, index) => {
        lines.push(
          `| ${index + 1} | ${genre.genre.genreName} | ${genre.totalBooks} | ${genre.booksRead} | ${genre.averageRating ? `★ ${Number(genre.averageRating).toFixed(1)}` : "—"} |`
        );
      });
      lines.push(``);
    }

    // Quotes
    lines.push(`## 💬 Quotes & Highlights`);
    lines.push(``);
    lines.push(`| Metric | Value |`);
    lines.push(`|--------|-------|`);
    lines.push(`| Total Quotes Saved | ${quoteStats.totalQuotes} |`);
    lines.push(`| Favorite Quotes | ${quoteStats.favoriteQuotes} |`);
    lines.push(`| Books with Quotes | ${quoteStats.booksWithQuotes} |`);
    lines.push(``);

    lines.push(`---`);
    lines.push(`*Data from [Bookjet](https://bookjet.app) — your personal reading tracker*`);

    const markdown = lines.join("\n");

    return new NextResponse(markdown, {
      status: 200,
      headers: {
        "Content-Type": "text/markdown; charset=utf-8",
        "Cache-Control": "no-store",
      },
    });
  } catch (error) {
    console.error("Stats markdown error:", error);
    return new NextResponse("Failed to generate statistics", { status: 500 });
  }
}
