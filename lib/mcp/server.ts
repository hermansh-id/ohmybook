import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { db } from "@/lib/db";
import { BookInputError } from "@/lib/db/book-writes";
import { READING_STATUSES, updateBookReading } from "@/lib/db/reading-writes";
import {
  searchBooks,
  getBookById,
  getCurrentlyReadingBooks,
  getFinishedBooks,
  getWantToReadBooks,
  getLibraryStats,
  getReadingSessions,
  getBookReadingSessions,
  createReadingSession,
  getAllQuotes,
  searchQuotes,
  createQuote,
  toggleQuoteFavorite,
  getAllAuthorsWithBookCount,
  getAllGenresWithBookCount,
  getReadingStreaks,
} from "@/lib/db/queries";
import {
  addBook,
  lookupIsbn,
  lookupQrcbn,
  lookupGoodreadsUrl,
  getReadingRecommendations,
  refreshGoodreadsData,
} from "@/lib/server/books";

function json(data: unknown) {
  return {
    content: [{ type: "text" as const, text: JSON.stringify(data, null, 2) }],
  };
}

const READ = { readOnlyHint: true, destructiveHint: false, openWorldHint: false };
const EXTERNAL_READ = { readOnlyHint: true, destructiveHint: false, openWorldHint: true };
const WRITE = { readOnlyHint: false, destructiveHint: false, openWorldHint: false };

export function createMcpServer() {
  const server = new McpServer({ name: "bookjet", version: "1.0.0" });

  // ---------------------------------------------------------------- read
  server.registerTool(
    "search_books",
    {
      title: "Search books",
      description: "Search books in the library by title or author name (max 50 results).",
      inputSchema: { query: z.string().min(1) },
      annotations: READ,
    },
    async ({ query }) => json(await searchBooks(query)),
  );

  server.registerTool(
    "get_book",
    {
      title: "Get book",
      description: "Get one book by bookId, plus its reading sessions.",
      inputSchema: { bookId: z.number().int() },
      annotations: READ,
    },
    async ({ bookId }) =>
      json({
        book: await getBookById(bookId),
        sessions: await getBookReadingSessions(bookId),
      }),
  );

  server.registerTool(
    "list_books_by_status",
    {
      title: "List books by status",
      description:
        "List books by reading status: 'reading' (currently reading), 'finished' (most recent first), or 'want_to_read'.",
      inputSchema: {
        status: z.enum(["reading", "finished", "want_to_read"]),
        limit: z.number().int().min(1).max(200).optional().describe("Only for 'finished'. Default 50."),
      },
      annotations: READ,
    },
    async ({ status, limit }) => {
      if (status === "reading") return json(await getCurrentlyReadingBooks());
      if (status === "finished") return json(await getFinishedBooks(limit ?? 50));
      return json(await getWantToReadBooks());
    },
  );

  server.registerTool(
    "get_library_stats",
    {
      title: "Library stats",
      description: "Overall library stats and reading streaks.",
      inputSchema: {},
      annotations: READ,
    },
    async () => json({ stats: await getLibraryStats(), streaks: await getReadingStreaks() }),
  );

  server.registerTool(
    "list_reading_sessions",
    {
      title: "List reading sessions",
      description: "Most recent reading sessions with book details.",
      inputSchema: { limit: z.number().int().min(1).max(200).optional() },
      annotations: READ,
    },
    async ({ limit }) => json(await getReadingSessions(limit ?? 50)),
  );

  server.registerTool(
    "list_quotes",
    {
      title: "List or search quotes",
      description: "List recent quotes, or search quote text when 'query' is given.",
      inputSchema: {
        query: z.string().optional(),
        limit: z.number().int().min(1).max(200).optional(),
      },
      annotations: READ,
    },
    async ({ query, limit }) =>
      json(query ? await searchQuotes(query) : await getAllQuotes(limit ?? 50)),
  );

  server.registerTool(
    "list_authors_and_genres",
    {
      title: "List authors and genres",
      description: "All authors and genres with book counts, including their IDs (needed by add_book).",
      inputSchema: {},
      annotations: READ,
    },
    async () =>
      json({
        authors: await getAllAuthorsWithBookCount(),
        genres: await getAllGenresWithBookCount(),
      }),
  );

  server.registerTool(
    "get_reading_recommendations",
    {
      title: "Reading recommendations",
      description:
        "Top 10 unread/in-progress books from the library, ranked by Goodreads rating, popularity, length and time in library.",
      inputSchema: {},
      annotations: READ,
    },
    async () => json(await getReadingRecommendations()),
  );

  server.registerTool(
    "lookup_book",
    {
      title: "Look up book (Goodreads)",
      description:
        "Look up book metadata (title, authors, year, pages, cover, description, Goodreads URL) from Goodreads. Provide exactly ONE of: isbn, qrcbn, goodreadsUrl. Does not write to the library; pass the result to add_book. May fail if Goodreads blocks the request: then retry or ask the user for the details.",
      inputSchema: {
        isbn: z.string().optional().describe("ISBN-10 or ISBN-13"),
        qrcbn: z.string().optional().describe("Raw QRCBN code"),
        goodreadsUrl: z.string().url().optional().describe("goodreads.com book URL"),
      },
      annotations: EXTERNAL_READ,
    },
    async ({ isbn, qrcbn, goodreadsUrl }) => {
      const given = [isbn, qrcbn, goodreadsUrl].filter(Boolean);
      if (given.length !== 1) {
        return { isError: true, ...json({ success: false, error: "Provide exactly one of isbn, qrcbn, goodreadsUrl" }) };
      }
      const result = isbn
        ? await lookupIsbn(isbn)
        : qrcbn
          ? await lookupQrcbn(qrcbn)
          : await lookupGoodreadsUrl(goodreadsUrl!);
      return { ...(result.success ? {} : { isError: true }), ...json(result) };
    },
  );

  // --------------------------------------------------------------- write
  server.registerTool(
    "refresh_goodreads_data",
    {
      title: "Refresh Goodreads data",
      description:
        "Fetch cover, description and Goodreads URL from Goodreads for an existing book and save them. Uses the book's Goodreads URL, or its ISBN if there is none.",
      inputSchema: { bookId: z.number().int() },
      annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: true },
    },
    async ({ bookId }) => {
      const result = await refreshGoodreadsData(bookId);
      return { ...(result.success ? {} : { isError: true }), ...json(result) };
    },
  );

  server.registerTool(
    "add_book",
    {
      title: "Add book",
      description:
        "Add a book to the library. Pass author NAMES in 'authors': existing authors are reused (case-insensitive), missing ones are created automatically, no ID lookup needed. 'authorIds' is still accepted for existing authors. Rejects duplicates (same ISBN or same title). Returns the created book with its authors.",
      inputSchema: {
        title: z.string().min(1),
        authors: z.array(z.string().min(1)).optional().describe("Author names, e.g. ['Aria Wiratma Yudhistira']"),
        authorIds: z.array(z.number().int()).optional().describe("IDs of existing authors"),
        genreIds: z.array(z.number().int()).optional(),
        isbn: z.string().optional(),
        year: z.number().int().optional(),
        pages: z.number().int().positive().optional(),
        publisher: z.string().optional(),
        goodreadsUrl: z.string().url().optional(),
        coverUrl: z.string().url().optional(),
        description: z.string().optional(),
      },
      annotations: WRITE,
    },
    async (input) => json(await addBook(input)),
  );

  server.registerTool(
    "log_reading_session",
    {
      title: "Log reading session",
      description: "Record a reading session for a book.",
      inputSchema: {
        bookId: z.number().int(),
        sessionDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).describe("YYYY-MM-DD"),
        pagesRead: z.number().int().min(0).optional(),
        minutesRead: z.number().int().min(0).optional(),
        startPage: z.number().int().min(0).optional(),
        endPage: z.number().int().min(0).optional(),
        notes: z.string().optional(),
      },
      annotations: WRITE,
    },
    async ({ sessionDate, ...rest }) =>
      json(await createReadingSession({ ...rest, sessionDate: new Date(sessionDate) })),
  );

  server.registerTool(
    "update_book",
    {
      title: "Update book reading status",
      description:
        "Set a book's reading status and/or rating (creates the reading log entry if the book has none). Status: want_to_read, reading, finished, did_not_finish, on_hold. Rating: 1-5. Setting 'finished' stamps today as the finish date and 'reading' as the start date unless already set or given. Only the provided fields change.",
      inputSchema: {
        bookId: z.number().int(),
        status: z.enum(READING_STATUSES).optional(),
        rating: z.number().int().min(1).max(5).optional(),
        review: z.string().optional(),
        currentPage: z.number().int().min(0).optional(),
        dateStarted: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional().describe("YYYY-MM-DD"),
        dateFinished: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional().describe("YYYY-MM-DD"),
      },
      annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false },
    },
    async (input) => {
      try {
        return json({ success: true, readingLog: await updateBookReading(db, input) });
      } catch (error) {
        if (error instanceof BookInputError) {
          return { isError: true, ...json({ success: false, error: error.message }) };
        }
        throw error;
      }
    },
  );

  server.registerTool(
    "add_quote",
    {
      title: "Add quote",
      description: "Save a quote from a book.",
      inputSchema: {
        bookId: z.number().int(),
        quoteText: z.string().min(1),
        pageNumber: z.number().int().optional(),
        chapter: z.string().optional(),
        tags: z.array(z.string()).optional(),
        isFavorite: z.boolean().optional(),
        notes: z.string().optional(),
      },
      annotations: WRITE,
    },
    async (input) => json(await createQuote(input)),
  );

  server.registerTool(
    "toggle_quote_favorite",
    {
      title: "Toggle quote favorite",
      description: "Flip the favorite flag of a quote.",
      inputSchema: { quoteId: z.number().int() },
      annotations: WRITE,
    },
    async ({ quoteId }) => json(await toggleQuoteFavorite(quoteId)),
  );

  return server;
}
