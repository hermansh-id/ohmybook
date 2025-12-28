"use server";

import { getAllBooksWithDetails, getBookById } from "@/lib/db/queries";
import { db } from "@/lib/db";
import { books, authors, bookAuthors, goodreadsData, bookGenres } from "@/lib/db/schema";
import { eq } from "drizzle-orm";
import { revalidatePath } from "next/cache";
import * as cheerio from "cheerio";

export async function getBooksAction() {
  try {
    const books = await getAllBooksWithDetails();

    // Group by book and aggregate authors/genres
    const bookMap = new Map();

    books.forEach((row) => {
      const bookId = row.book.bookId;

      if (!bookMap.has(bookId)) {
        bookMap.set(bookId, {
          id: bookId,
          title: row.book.title,
          isbn: row.book.isbn,
          year: row.book.year,
          pages: row.book.pages,
          addedAt: row.book.addedAt,
          authors: [],
          genres: [],
          status: row.readingStatus?.status || "not_started",
          rating: row.readingStatus?.rating || null,
          dateFinished: row.readingStatus?.dateFinished || null,
          currentPage: row.readingStatus?.currentPage || 0,
          coverUrl: row.goodreads?.coverUrl || null,
          averageRating: row.goodreads?.averageRating || null,
        });
      }

      const book = bookMap.get(bookId);

      if (row.author && !book.authors.some((a: any) => a.name === row.author?.name)) {
        book.authors.push({
          id: row.author.authorId,
          name: row.author.name,
        });
      }

      if (row.genre && !book.genres.some((g: any) => g.name === row.genre?.genreName)) {
        book.genres.push({
          id: row.genre.genreId,
          name: row.genre.genreName,
        });
      }
    });

    return Array.from(bookMap.values());
  } catch (error) {
    console.error("Error fetching books:", error);
    throw new Error("Failed to fetch books");
  }
}

export async function getBookDetailsAction(bookId: number) {
  try {
    const result = await getBookById(bookId);

    if (!result || result.length === 0) {
      throw new Error("Book not found");
    }

    const bookData = result[0];

    return {
      id: bookData.books.bookId,
      title: bookData.books.title,
      isbn: bookData.books.isbn,
      year: bookData.books.year,
      pages: bookData.books.pages,
      addedAt: bookData.books.addedAt,
      goodreadsUrl: bookData.books.goodreadsUrl,
      status: bookData.reading_log?.status || "not_started",
      rating: bookData.reading_log?.rating || null,
      review: bookData.reading_log?.review || null,
      notes: bookData.reading_log?.notes || null,
      dateAdded: bookData.reading_log?.dateAdded || null,
      dateStarted: bookData.reading_log?.dateStarted || null,
      dateFinished: bookData.reading_log?.dateFinished || null,
      currentPage: bookData.reading_log?.currentPage || 0,
      readingDays: bookData.reading_log?.readingDays || null,
      tags: bookData.reading_log?.tags || [],
      coverUrl: bookData.goodreads_data?.coverUrl || null,
      description: bookData.goodreads_data?.description || null,
      averageRating: bookData.goodreads_data?.averageRating || null,
      ratingsCount: bookData.goodreads_data?.ratingsCount || null,
      publisher: bookData.goodreads_data?.publisher || null,
      publicationDate: bookData.goodreads_data?.publicationDate || null,
      logId: bookData.reading_log?.logId || null,
    };
  } catch (error) {
    console.error("Error fetching book details:", error);
    throw new Error("Failed to fetch book details");
  }
}

export async function updateBookStatusAction(data: {
  bookId: number;
  logId?: number | null;
  status: string;
  rating?: number | null;
  dateFinished?: Date | null;
}) {
  try {
    const { addToReadingLog, updateReadingStatus, markBookAsFinished } = await import(
      "@/lib/db/queries"
    );

    // If no logId, create new reading log entry
    if (!data.logId) {
      const result = await addToReadingLog(data.bookId, data.status as any);
      return result[0];
    }

    // If marking as finished, use special function
    if (data.status === "finished") {
      return await markBookAsFinished(data.logId, data.rating || undefined);
    }

    // Otherwise, update the reading status
    return await updateReadingStatus(data.logId, {
      status: data.status,
      rating: data.rating ?? undefined,
      dateFinished: data.dateFinished ?? undefined,
    });
  } catch (error) {
    console.error("Error updating book status:", error);
    throw new Error("Failed to update book status");
  }
}

export interface AddBookInput {
  title: string;
  isbn?: string;
  goodreadsUrl?: string;
  year?: number;
  pages?: number;
  authorIds: number[];
  genreIds?: number[];
  coverUrl?: string;
  description?: string;
}

export async function addBookAction(input: AddBookInput) {
  try {
    // Insert the book
    const [book] = await db
      .insert(books)
      .values({
        title: input.title,
        isbn: input.isbn || null,
        goodreadsUrl: input.goodreadsUrl || null,
        year: input.year || null,
        pages: input.pages || null,
      })
      .returning();

    // Link authors to the book
    if (input.authorIds.length > 0) {
      await db.insert(bookAuthors).values(
        input.authorIds.map((authorId, index) => ({
          bookId: book.bookId,
          authorId,
          authorOrder: index + 1,
        }))
      );
    }

    // Link genres to the book
    if (input.genreIds && input.genreIds.length > 0) {
      await db.insert(bookGenres).values(
        input.genreIds.map((genreId, index) => ({
          bookId: book.bookId,
          genreId,
          isPrimary: index === 0, // First genre is primary
        }))
      );
    }

    // Save Goodreads data if available
    if (input.coverUrl || input.description) {
      try {
        await db.insert(goodreadsData).values({
          bookId: book.bookId,
          coverUrl: input.coverUrl || null,
          description: input.description || null,
        });
      } catch (error) {
        console.error("Error saving Goodreads data:", error);
        // Don't fail the whole operation if Goodreads data fails
      }
    }

    revalidatePath("/books");
    revalidatePath("/dashboard");
    return { success: true, bookId: book.bookId };
  } catch (error) {
    console.error("Error adding book:", error);
    return { success: false, error: "Failed to add book" };
  }
}

export async function deleteBookAction(bookId: number) {
  try {
    // Delete the book (cascade will handle related records)
    await db.delete(books).where(eq(books.bookId, bookId));

    revalidatePath("/dashboard/books");
    revalidatePath("/dashboard");
    return { success: true };
  } catch (error) {
    console.error("Error deleting book:", error);
    return { success: false, error: "Failed to delete book" };
  }
}

export interface UpdateBookInput {
  bookId: number;
  title?: string;
  isbn?: string;
  year?: number;
  pages?: number;
  goodreadsUrl?: string;
}

export async function updateBookAction(input: UpdateBookInput) {
  try {
    const { bookId, ...updateData } = input;

    // Build update object with only provided fields
    const dataToUpdate: any = {};
    if (updateData.title !== undefined) dataToUpdate.title = updateData.title;
    if (updateData.isbn !== undefined) dataToUpdate.isbn = updateData.isbn || null;
    if (updateData.year !== undefined) dataToUpdate.year = updateData.year || null;
    if (updateData.pages !== undefined) dataToUpdate.pages = updateData.pages || null;
    if (updateData.goodreadsUrl !== undefined) dataToUpdate.goodreadsUrl = updateData.goodreadsUrl || null;

    await db
      .update(books)
      .set(dataToUpdate)
      .where(eq(books.bookId, bookId));

    revalidatePath("/dashboard/books");
    revalidatePath("/dashboard");
    return { success: true };
  } catch (error) {
    console.error("Error updating book:", error);
    return { success: false, error: "Failed to update book" };
  }
}

export async function getAuthorsAction() {
  try {
    const allAuthors = await db
      .select({
        authorId: authors.authorId,
        name: authors.name,
      })
      .from(authors)
      .orderBy(authors.name);

    return allAuthors;
  } catch (error) {
    console.error("Error fetching authors:", error);
    return [];
  }
}

export interface BookLookupResult {
  success: boolean;
  data?: {
    title: string;
    authors: string[];
    year?: number;
    pages?: number;
    goodreadsUrl: string;
    coverUrl?: string;
    description?: string;
  };
  error?: string;
}

export async function lookupBookByISBN(isbn: string): Promise<BookLookupResult> {
  try {
    // Clean ISBN (remove hyphens and spaces)
    const cleanIsbn = isbn.replace(/[-\s]/g, "");

    // Validate ISBN (10 or 13 digits)
    if (!/^\d{10}(\d{3})?$/.test(cleanIsbn)) {
      return { success: false, error: "Invalid ISBN format" };
    }

    // Search Goodreads
    const searchUrl = `https://www.goodreads.com/search?utf8=%E2%9C%93&q=${cleanIsbn}&search_type=books&search%5Bfield%5D=on`;

    const response = await fetch(searchUrl, {
      redirect: "follow",
      headers: {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
      },
    });

    if (!response.ok) {
      return { success: false, error: "Failed to fetch from Goodreads" };
    }

    const html = await response.text();
    const $ = cheerio.load(html);

    // Check if we got redirected to a book page or still on search results
    const currentUrl = response.url;
    const isBookPage = currentUrl.includes("/book/show/");

    if (!isBookPage) {
      // We're still on search results, try to get the first result
      const firstBookLink = $('a.bookTitle').first().attr('href');
      if (!firstBookLink) {
        return { success: false, error: "Book not found on Goodreads" };
      }

      // Fetch the actual book page
      const bookUrl = `https://www.goodreads.com${firstBookLink}`;
      const bookResponse = await fetch(bookUrl, {
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
        },
      });

      if (!bookResponse.ok) {
        return { success: false, error: "Failed to fetch book page" };
      }

      const bookHtml = await bookResponse.text();
      return parseBookPage(bookHtml, bookUrl);
    }

    // We're already on the book page
    return parseBookPage(html, currentUrl);
  } catch (error) {
    console.error("Error looking up book:", error);
    return { success: false, error: "An error occurred while looking up the book" };
  }
}

function parseBookPage(html: string, url: string): BookLookupResult {
  try {
    const $ = cheerio.load(html);

    // Extract title
    const title = $('h1[data-testid="bookTitle"]').text().trim() ||
                  $('.BookPageTitleSection__title h1').text().trim() ||
                  $('h1.Text.Text__title1').text().trim();

    if (!title) {
      return { success: false, error: "Could not extract book title" };
    }

    // Extract authors
    const authors: string[] = [];
    $('span[data-testid="name"]').each((_, el) => {
      const authorName = $(el).text().trim();
      if (authorName) authors.push(authorName);
    });

    // Fallback for authors
    if (authors.length === 0) {
      $('.ContributorLink__name').each((_, el) => {
        const authorName = $(el).text().trim();
        if (authorName) authors.push(authorName);
      });
    }

    // Extract publication year
    let year: number | undefined;
    const pubInfo = $('p[data-testid="publicationInfo"]').text();
    const yearMatch = pubInfo.match(/(\d{4})/);
    if (yearMatch) {
      year = parseInt(yearMatch[1]);
    }

    // Extract pages
    let pages: number | undefined;
    const pagesText = $('p[data-testid="pagesFormat"]').text();
    const pagesMatch = pagesText.match(/(\d+)\s*pages/i);
    if (pagesMatch) {
      pages = parseInt(pagesMatch[1]);
    }

    // Extract cover URL
    const coverUrl = $('img.ResponsiveImage').first().attr('src') ||
                     $('.BookCover__image img').first().attr('src');

    // Extract description
    const description = $('div[data-testid="description"]').text().trim() ||
                       $('.DetailsLayoutRightParagraph__widthConstrained').text().trim();

    return {
      success: true,
      data: {
        title,
        authors,
        year,
        pages,
        goodreadsUrl: url,
        coverUrl,
        description,
      },
    };
  } catch (error) {
    console.error("Error parsing book page:", error);
    return { success: false, error: "Failed to parse book data" };
  }
}

export async function getReadingRecommendationsAction() {
  try {
    const allBooks = await getAllBooksWithDetails();

    // Group by book and aggregate data
    const bookMap = new Map();

    allBooks.forEach((row) => {
      const bookId = row.book.bookId;

      if (!bookMap.has(bookId)) {
        bookMap.set(bookId, {
          id: bookId,
          title: row.book.title,
          isbn: row.book.isbn,
          year: row.book.year,
          pages: row.book.pages,
          addedAt: row.book.addedAt,
          authors: [],
          genres: [],
          status: row.readingStatus?.status || "not_started",
          rating: row.readingStatus?.rating || null,
          coverUrl: row.goodreads?.coverUrl || null,
          averageRating: row.goodreads?.averageRating || null,
          ratingsCount: row.goodreads?.ratingsCount || null,
          description: row.goodreads?.description || null,
        });
      }

      const book = bookMap.get(bookId);

      if (row.author && !book.authors.some((a: any) => a.name === row.author?.name)) {
        book.authors.push({
          id: row.author.authorId,
          name: row.author.name,
        });
      }

      if (row.genre && !book.genres.some((g: any) => g.name === row.genre?.genreName)) {
        book.genres.push({
          id: row.genre.genreId,
          name: row.genre.genreName,
        });
      }
    });

    const booksArray = Array.from(bookMap.values());

    // Filter unread books (not_started or reading)
    const unreadBooks = booksArray.filter(
      (book) => book.status === "not_started" || book.status === "reading"
    );

    // Calculate recommendation scores
    const recommendations = unreadBooks.map((book) => {
      let score = 0;

      // Prioritize books currently reading
      if (book.status === "reading") score += 100;

      // Higher Goodreads rating = higher score
      if (book.averageRating) {
        score += parseFloat(book.averageRating.toString()) * 10;
      }

      // More ratings = more popular = higher score
      if (book.ratingsCount) {
        score += Math.min(book.ratingsCount / 100, 20); // Cap at 20 points
      }

      // Shorter books get slightly higher score (easier to finish)
      if (book.pages) {
        score += Math.max(0, (500 - book.pages) / 100);
      }

      // Older books in library (should read soon)
      if (book.addedAt) {
        const daysInLibrary = (Date.now() - new Date(book.addedAt).getTime()) / (1000 * 60 * 60 * 24);
        score += Math.min(daysInLibrary / 10, 15); // Cap at 15 points
      }

      return { ...book, recommendationScore: score };
    });

    // Sort by recommendation score
    recommendations.sort((a, b) => b.recommendationScore - a.recommendationScore);

    // Return top 10 recommendations
    return recommendations.slice(0, 10);
  } catch (error) {
    console.error("Error getting recommendations:", error);
    return [];
  }
}

export async function fetchGoodreadsDataAction(bookId: number, isbn: string) {
  try {
    console.log("Fetching Goodreads data for book:", bookId, "ISBN:", isbn);

    // Lookup book data from Goodreads using ISBN
    const result = await lookupBookByISBN(isbn);

    console.log("Lookup result:", result);

    if (!result.success || !result.data) {
      console.error("Lookup failed:", result.error);
      return { success: false, error: result.error || "Failed to fetch Goodreads data" };
    }

    // Check if Goodreads data already exists for this book
    const existingData = await db
      .select()
      .from(goodreadsData)
      .where(eq(goodreadsData.bookId, bookId))
      .limit(1);

    console.log("Existing data:", existingData.length > 0 ? "Found" : "Not found");

    const goodreadsDataToSave = {
      coverUrl: result.data.coverUrl || null,
      description: result.data.description || null,
      lastUpdated: new Date(),
    };

    console.log("Data to save:", goodreadsDataToSave);

    if (existingData.length > 0) {
      // Update existing Goodreads data
      const updated = await db
        .update(goodreadsData)
        .set(goodreadsDataToSave)
        .where(eq(goodreadsData.bookId, bookId))
        .returning();

      console.log("Updated data:", updated);
    } else {
      // Insert new Goodreads data
      const inserted = await db.insert(goodreadsData).values({
        bookId,
        ...goodreadsDataToSave,
      }).returning();

      console.log("Inserted data:", inserted);
    }

    // Update book's Goodreads URL if we have one
    if (result.data.goodreadsUrl) {
      await db
        .update(books)
        .set({ goodreadsUrl: result.data.goodreadsUrl })
        .where(eq(books.bookId, bookId));

      console.log("Updated book with Goodreads URL");
    }

    revalidatePath("/dashboard/books");
    revalidatePath("/dashboard");

    console.log("Successfully saved Goodreads data");
    return { success: true };
  } catch (error) {
    console.error("Error fetching Goodreads data:", error);
    return { success: false, error: error instanceof Error ? error.message : "Failed to fetch Goodreads data" };
  }
}
