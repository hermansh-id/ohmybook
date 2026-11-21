import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { db } from "@/lib/db";
import { BookInputError, attachAuthorsGenres } from "@/lib/db/book-writes";
import { addAuthor, addGenre, deleteBook, updateBookDetails } from "@/lib/db/library-writes";
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
  updateReadingSession,
  deleteReadingSession,
  getAllQuotes,
  getBookQuotes,
  getFavoriteQuotes,
  searchQuotes,
  createQuote,
  updateQuote,
  deleteQuote,
  toggleQuoteFavorite,
  getAllAuthorsWithBookCount,
  getAllGenresWithBookCount,
  getReadingStreaks,
  getCurrentYearGoal,
  setReadingGoal,
  getYearlyStats,
  getMonthlyStats,
  getTopRatedBooks,
  getReadingHistory,
} from "@/lib/db/queries";
import {
  addBook,
  lookupIsbn,
  lookupQrcbn,
  lookupGoodreadsUrl,
  getReadingRecommendations,
  refreshGoodreadsData,
} from "@/lib/server/books";
import { bookUrl, withBookUrls } from "@/lib/mcp/links";

type ToolResult = { content: { type: "text"; text: string }[]; isError?: boolean };

/** JSON text result. Every book-like object gets a direct `url` to its page. */
function json(data: unknown): ToolResult {
  return { content: [{ type: "text", text: JSON.stringify(withBookUrls(data), null, 2) }] };
}

function fail(error: string): ToolResult {
  return { isError: true, ...json({ success: false, error }) };
}

/** Run a tool body; input errors become tool errors the agent can read. */
async function run(fn: () => Promise<unknown>): Promise<ToolResult> {
  try {
    return json(await fn());
  } catch (error) {
    if (error instanceof BookInputError) return fail(error.message);
    throw error;
  }
}

const READ = { readOnlyHint: true, destructiveHint: false, openWorldHint: false };
const EXTERNAL_READ = { readOnlyHint: true, destructiveHint: false, openWorldHint: true };
const WRITE = { readOnlyHint: false, destructiveHint: false, openWorldHint: false };
const IDEMPOTENT_WRITE = { readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false };
const DESTRUCTIVE = { readOnlyHint: false, destructiveHint: true, idempotentHint: true, openWorldHint: false };

const dateStr = z.string().regex(/^\d{4}-\d{2}-\d{2}$/).describe("YYYY-MM-DD");

export function createMcpServer() {
  const server = new McpServer({ name: "bookjet", version: "1.1.0" });

  // ================================================================ read
  server.registerTool(
    "search_books",
    {
      title: "Search books",
      description: "Search books by title or author name (max 50 results). Each book includes a direct `url`.",
      inputSchema: { query: z.string().min(1) },
      annotations: READ,
    },
    async ({ query }) => json(await searchBooks(query)),
  );

  server.registerTool(
    "get_book",
    {
      title: "Get book",
      description: "Get one book by bookId with its reading sessions and quotes, plus a direct `url`.",
      inputSchema: { bookId: z.number().int() },
      annotations: READ,
    },
    async ({ bookId }) => {
      const [book] = await getBookById(bookId);
      if (!book) return fail(`Book ${bookId} not found`);
      return json({
        book,
        sessions: await getBookReadingSessions(bookId),
        quotes: await getBookQuotes(bookId),
      });
    },
  );

  server.registerTool(
    "get_book_link",
    {
      title: "Get direct link to a book",
      description:
        "Get the direct app link(s) to a book page. Provide bookId, or a title/author query (returns up to 10 matches). Links open the book page in the Bookjet dashboard (login required).",
      inputSchema: {
        bookId: z.number().int().optional(),
        query: z.string().min(1).optional(),
      },
      annotations: READ,
    },
    async ({ bookId, query }) => {
      if ((bookId === undefined) === (query === undefined)) return fail("Provide exactly one of bookId or query");
      if (bookId !== undefined) {
        const [book] = await getBookById(bookId);
        if (!book) return fail(`Book ${bookId} not found`);
        return json({ bookId, title: book.books.title, url: bookUrl(bookId) });
      }
      const rows = await searchBooks(query!);
      return json(rows.slice(0, 10).map((r) => ({ bookId: r.book.bookId, title: r.book.title, authors: r.authors, url: bookUrl(r.book.bookId) })));
    },
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
    "get_top_rated_books",
    {
      title: "Top rated books",
      description: "Your highest-rated books.",
      inputSchema: { limit: z.number().int().min(1).max(100).optional() },
      annotations: READ,
    },
    async ({ limit }) => json(await getTopRatedBooks(limit ?? 10)),
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
    "get_reading_goal",
    {
      title: "Reading goal progress",
      description: "This year's reading goal with actual progress (books and pages finished).",
      inputSchema: {},
      annotations: READ,
    },
    async () => json(await getCurrentYearGoal()),
  );

  server.registerTool(
    "get_yearly_stats",
    {
      title: "Yearly stats",
      description: "Reading stats per year, or for one year.",
      inputSchema: { year: z.number().int().optional() },
      annotations: READ,
    },
    async ({ year }) => json(await getYearlyStats(year)),
  );

  server.registerTool(
    "get_monthly_stats",
    {
      title: "Monthly stats",
      description: "Reading stats per month for a year.",
      inputSchema: { year: z.number().int() },
      annotations: READ,
    },
    async ({ year }) => json(await getMonthlyStats(year)),
  );

  server.registerTool(
    "get_reading_history",
    {
      title: "Reading history",
      description: "Books finished/pages read over the last N months.",
      inputSchema: { months: z.number().int().min(1).max(120).optional().describe("Default 12") },
      annotations: READ,
    },
    async ({ months }) => json(await getReadingHistory(months ?? 12)),
  );

  server.registerTool(
    "list_reading_sessions",
    {
      title: "List reading sessions",
      description: "Most recent reading sessions with book details (includes sessionId for update/delete).",
      inputSchema: { limit: z.number().int().min(1).max(200).optional() },
      annotations: READ,
    },
    async ({ limit }) => json(await getReadingSessions(limit ?? 50)),
  );

  server.registerTool(
    "list_quotes",
    {
      title: "List or search quotes",
      description:
        "List recent quotes (includes quoteId for update/delete). Filter by 'query' (text search), 'bookId', or 'favoritesOnly'.",
      inputSchema: {
        query: z.string().optional(),
        bookId: z.number().int().optional(),
        favoritesOnly: z.boolean().optional(),
        limit: z.number().int().min(1).max(200).optional(),
      },
      annotations: READ,
    },
    async ({ query, bookId, favoritesOnly, limit }) => {
      if (query) return json(await searchQuotes(query));
      if (bookId !== undefined) return json(await getBookQuotes(bookId));
      if (favoritesOnly) return json(await getFavoriteQuotes());
      return json(await getAllQuotes(limit ?? 50));
    },
  );

  server.registerTool(
    "list_authors_and_genres",
    {
      title: "List authors and genres",
      description: "All authors and genres with book counts and IDs.",
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
    async () => {
      const recs = await getReadingRecommendations();
      return json(recs.map((r: { id: number; title: string }) => ({ ...r, bookId: r.id })));
    },
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
      if (given.length !== 1) return fail("Provide exactly one of isbn, qrcbn, goodreadsUrl");
      const result = isbn ? await lookupIsbn(isbn) : qrcbn ? await lookupQrcbn(qrcbn) : await lookupGoodreadsUrl(goodreadsUrl!);
      return { ...(result.success ? {} : { isError: true }), ...json(result) };
    },
  );

  // =============================================================== write
  server.registerTool(
    "add_book",
    {
      title: "Add book",
      description:
        "Add a book to the library. Pass author and genre NAMES in 'authors'/'genres': existing ones are reused (case-insensitive), missing ones are created automatically, no ID lookup needed. 'authorIds'/'genreIds' are still accepted. Rejects duplicates (same ISBN or same title). Returns the created book with authors, genres and a direct `url`.",
      inputSchema: {
        title: z.string().min(1),
        authors: z.array(z.string().min(1)).optional().describe("Author names, e.g. ['Aria Wiratma Yudhistira']"),
        authorIds: z.array(z.number().int()).optional().describe("IDs of existing authors"),
        genres: z.array(z.string().min(1)).optional().describe("Genre names; the first becomes the primary genre"),
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
    "update_book_details",
    {
      title: "Edit book details",
      description:
        "Edit a book's metadata: title, isbn, year, pages, goodreadsUrl, coverUrl, description, publisher. Only provided fields change; an empty string clears isbn/goodreadsUrl/coverUrl/description/publisher. For authors/genres use add_book_authors / add_book_genres.",
      inputSchema: {
        bookId: z.number().int(),
        title: z.string().optional(),
        isbn: z.string().optional(),
        year: z.number().int().optional(),
        pages: z.number().int().min(0).optional(),
        goodreadsUrl: z.string().optional(),
        coverUrl: z.string().optional(),
        description: z.string().optional(),
        publisher: z.string().optional(),
      },
      annotations: IDEMPOTENT_WRITE,
    },
    async (input) => run(async () => ({ success: true, book: await updateBookDetails(db, input) })),
  );

  server.registerTool(
    "add_book_authors",
    {
      title: "Add authors to a book",
      description:
        "Add authors to an existing book by name (reused case-insensitively or created) and/or ID. Additive and idempotent. Returns the book with all authors and genres.",
      inputSchema: {
        bookId: z.number().int(),
        authors: z.array(z.string().min(1)).optional(),
        authorIds: z.array(z.number().int()).optional(),
      },
      annotations: IDEMPOTENT_WRITE,
    },
    async ({ bookId, ...rest }) => run(async () => ({ success: true, book: await attachAuthorsGenres(db, bookId, rest) })),
  );

  server.registerTool(
    "add_book_genres",
    {
      title: "Add genres to a book",
      description:
        "Add genres to an existing book by name (reused case-insensitively or created) and/or ID. Additive and idempotent; becomes the primary genre if the book has none. Returns the book with all authors and genres.",
      inputSchema: {
        bookId: z.number().int(),
        genres: z.array(z.string().min(1)).optional(),
        genreIds: z.array(z.number().int()).optional(),
      },
      annotations: IDEMPOTENT_WRITE,
    },
    async ({ bookId, ...rest }) => run(async () => ({ success: true, book: await attachAuthorsGenres(db, bookId, rest) })),
  );

  server.registerTool(
    "add_author",
    {
      title: "Add author",
      description: "Create an author, or return the existing one (case-insensitive name match).",
      inputSchema: { name: z.string().min(1), bio: z.string().optional() },
      annotations: IDEMPOTENT_WRITE,
    },
    async (input) => run(() => addAuthor(db, input)),
  );

  server.registerTool(
    "add_genre",
    {
      title: "Add genre",
      description: "Create a genre, or return the existing one (case-insensitive name match).",
      inputSchema: { name: z.string().min(1), description: z.string().optional() },
      annotations: IDEMPOTENT_WRITE,
    },
    async (input) => run(() => addGenre(db, input)),
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
        dateStarted: dateStr.optional(),
        dateFinished: dateStr.optional(),
      },
      annotations: IDEMPOTENT_WRITE,
    },
    async (input) => run(async () => ({ success: true, readingLog: await updateBookReading(db, input) })),
  );

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
    "log_reading_session",
    {
      title: "Log reading session",
      description: "Record a reading session for a book.",
      inputSchema: {
        bookId: z.number().int(),
        sessionDate: dateStr,
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
    "update_reading_session",
    {
      title: "Edit reading session",
      description: "Edit a reading session (get sessionId from list_reading_sessions). Only provided fields change.",
      inputSchema: {
        sessionId: z.number().int(),
        sessionDate: dateStr.optional(),
        pagesRead: z.number().int().min(0).optional(),
        minutesRead: z.number().int().min(0).optional(),
        startPage: z.number().int().min(0).optional(),
        endPage: z.number().int().min(0).optional(),
        notes: z.string().optional(),
      },
      annotations: IDEMPOTENT_WRITE,
    },
    async ({ sessionId, sessionDate, ...rest }) => {
      const hasChange = sessionDate !== undefined || Object.values(rest).some((v) => v !== undefined);
      if (!hasChange) return fail("Nothing to update");
      const rows = await updateReadingSession(sessionId, {
        ...rest,
        sessionDate: sessionDate ? new Date(sessionDate) : undefined,
      });
      return rows.length ? json({ success: true, session: rows[0] }) : fail(`Reading session ${sessionId} not found`);
    },
  );

  server.registerTool(
    "delete_reading_session",
    {
      title: "Delete reading session",
      description: "Permanently delete a reading session. Ask the user to confirm first.",
      inputSchema: { sessionId: z.number().int() },
      annotations: DESTRUCTIVE,
    },
    async ({ sessionId }) => {
      const rows = await deleteReadingSession(sessionId);
      return rows.length ? json({ success: true, deleted: rows[0] }) : fail(`Reading session ${sessionId} not found`);
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
    "update_quote",
    {
      title: "Edit quote",
      description: "Edit a quote (get quoteId from list_quotes). Only provided fields change.",
      inputSchema: {
        quoteId: z.number().int(),
        quoteText: z.string().min(1).optional(),
        pageNumber: z.number().int().optional(),
        chapter: z.string().optional(),
        tags: z.array(z.string()).optional(),
        isFavorite: z.boolean().optional(),
        notes: z.string().optional(),
      },
      annotations: IDEMPOTENT_WRITE,
    },
    async ({ quoteId, ...rest }) => {
      if (Object.values(rest).every((v) => v === undefined)) return fail("Nothing to update");
      const rows = await updateQuote(quoteId, rest);
      return rows.length ? json({ success: true, quote: rows[0] }) : fail(`Quote ${quoteId} not found`);
    },
  );

  server.registerTool(
    "toggle_quote_favorite",
    {
      title: "Toggle quote favorite",
      description: "Flip the favorite flag of a quote.",
      inputSchema: { quoteId: z.number().int() },
      annotations: WRITE,
    },
    async ({ quoteId }) => run(async () => toggleQuoteFavorite(quoteId).catch((e: Error) => { throw new BookInputError(e.message); })),
  );

  server.registerTool(
    "delete_quote",
    {
      title: "Delete quote",
      description: "Permanently delete a quote. Ask the user to confirm first.",
      inputSchema: { quoteId: z.number().int() },
      annotations: DESTRUCTIVE,
    },
    async ({ quoteId }) => {
      const rows = await deleteQuote(quoteId);
      return rows.length ? json({ success: true, deleted: rows[0] }) : fail(`Quote ${quoteId} not found`);
    },
  );

  server.registerTool(
    "set_reading_goal",
    {
      title: "Set reading goal",
      description: "Set the reading goal (target books and/or pages) for a year.",
      inputSchema: {
        year: z.number().int().min(1900).max(2200),
        targetBooks: z.number().int().min(1).optional(),
        targetPages: z.number().int().min(1).optional(),
      },
      annotations: IDEMPOTENT_WRITE,
    },
    async ({ year, targetBooks, targetPages }) => {
      if (targetBooks === undefined && targetPages === undefined) return fail("Provide targetBooks and/or targetPages");
      return json(await setReadingGoal(year, targetBooks, targetPages));
    },
  );

  server.registerTool(
    "delete_book",
    {
      title: "Delete book",
      description:
        "PERMANENTLY delete a book and everything attached to it (reading log, sessions, quotes, links). Cannot be undone. Ask the user to confirm, then pass confirm=true.",
      inputSchema: { bookId: z.number().int(), confirm: z.literal(true).describe("Must be true") },
      annotations: DESTRUCTIVE,
    },
    async ({ bookId }) => run(async () => ({ success: true, deleted: await deleteBook(db, bookId) })),
  );

  return server;
}
