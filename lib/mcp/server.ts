import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
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
import { addBook } from "@/actions/books";

function json(data: unknown) {
  return {
    content: [{ type: "text" as const, text: JSON.stringify(data, null, 2) }],
  };
}

const READ = { readOnlyHint: true, destructiveHint: false, openWorldHint: false };
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

  // --------------------------------------------------------------- write
  server.registerTool(
    "add_book",
    {
      title: "Add book",
      description:
        "Add a book to the library. Rejects duplicates (same ISBN or same title). Use list_authors_and_genres for IDs.",
      inputSchema: {
        title: z.string().min(1),
        authorIds: z.array(z.number().int()),
        genreIds: z.array(z.number().int()).optional(),
        isbn: z.string().optional(),
        year: z.number().int().optional(),
        pages: z.number().int().positive().optional(),
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
