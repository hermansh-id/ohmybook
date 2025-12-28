"use server";

import { db } from "@/lib/db";
import { readingGoals, readingLog, books, bookAuthors, authors } from "@/lib/db/schema";
import { eq } from "drizzle-orm";
import { revalidatePath } from "next/cache";

export async function updateReadingGoalAction(data: {
  year: number;
  targetBooks: number;
  targetPages: number;
}) {
  try {
    // Check if goal exists for this year
    const [existingGoal] = await db
      .select()
      .from(readingGoals)
      .where(eq(readingGoals.year, data.year))
      .limit(1);

    if (existingGoal) {
      // Update existing goal
      await db
        .update(readingGoals)
        .set({
          targetBooks: data.targetBooks,
          targetPages: data.targetPages,
          updatedAt: new Date(),
        })
        .where(eq(readingGoals.year, data.year));
    } else {
      // Create new goal
      await db.insert(readingGoals).values({
        year: data.year,
        targetBooks: data.targetBooks,
        targetPages: data.targetPages,
      });
    }

    revalidatePath("/dashboard");
    revalidatePath("/dashboard/settings");

    return { success: true };
  } catch (error) {
    console.error("Error updating reading goal:", error);
    return { success: false, error: "Failed to update reading goal" };
  }
}

export async function exportReadingLogToCsvAction() {
  try {
    // Get all reading log entries with book and author info
    const logs = await db
      .select({
        title: books.title,
        authorName: authors.name,
        isbn: books.isbn,
        pages: books.pages,
        rating: readingLog.rating,
        dateRead: readingLog.dateFinished,
        dateAdded: readingLog.dateAdded,
        status: readingLog.status,
        review: readingLog.review,
      })
      .from(readingLog)
      .innerJoin(books, eq(readingLog.bookId, books.bookId))
      .leftJoin(bookAuthors, eq(books.bookId, bookAuthors.bookId))
      .leftJoin(authors, eq(bookAuthors.authorId, authors.authorId))
      .orderBy(readingLog.dateFinished);

    // Group by book to combine multiple authors
    const groupedLogs = logs.reduce((acc: any[], log) => {
      const existing = acc.find((item) => item.title === log.title);
      if (existing && log.authorName) {
        existing.authorName += `, ${log.authorName}`;
      } else {
        acc.push({ ...log });
      }
      return acc;
    }, []);

    // Convert to Goodreads CSV format
    const headers = [
      "Title",
      "Author",
      "ISBN",
      "My Rating",
      "Date Read",
      "Date Added",
      "Bookshelves",
      "My Review",
      "Number of Pages",
    ];

    const rows = groupedLogs.map((log) => {
      // Map status to Goodreads shelf
      let shelf = "to-read";
      if (log.status === "finished") shelf = "read";
      else if (log.status === "reading") shelf = "currently-reading";

      return [
        `"${log.title || ""}"`,
        `"${log.authorName || ""}"`,
        `"${log.isbn || ""}"`,
        log.rating || "",
        log.dateRead || "",
        log.dateAdded || "",
        shelf,
        `"${(log.review || "").replace(/"/g, '""')}"`, // Escape quotes
        log.pages || "",
      ];
    });

    const csvContent = [headers.join(","), ...rows.map((row) => row.join(","))].join("\n");

    return { success: true, data: csvContent };
  } catch (error) {
    console.error("Error exporting CSV:", error);
    return { success: false, error: "Failed to export CSV" };
  }
}
