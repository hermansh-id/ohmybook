"use server";

import { getAllBooksWithDetails, getBookById } from "@/lib/db/queries";
import { db } from "@/lib/db";
import { books, authors, bookAuthors } from "@/lib/db/schema";
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

    revalidatePath("/books");
    revalidatePath("/dashboard");
    return { success: true, bookId: book.bookId };
  } catch (error) {
    console.error("Error adding book:", error);
    return { success: false, error: "Failed to add book" };
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
