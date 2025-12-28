import {
  pgTable,
  serial,
  integer,
  varchar,
  date,
  text,
  boolean,
  timestamp,
  check,
  unique,
  index,
} from "drizzle-orm/pg-core";
import { sql } from "drizzle-orm";
import { books } from "./core";

// Reading log (main tracking table)
export const readingLog = pgTable(
  "reading_log",
  {
    logId: serial("log_id").primaryKey(),
    bookId: integer("book_id")
      .notNull()
      .references(() => books.bookId, { onDelete: "cascade" }),

    // Status tracking
    status: varchar("status", { length: 50 }).default("want_to_read"),

    // Date tracking
    dateAdded: date("date_added").defaultNow(),
    dateStarted: date("date_started"),
    dateFinished: date("date_finished"),

    // Progress tracking
    currentPage: integer("current_page").default(0),

    // Rating & review
    rating: integer("rating"),
    review: text("review"),
    notes: text("notes"),

    // Reading metrics
    readingDays: integer("reading_days"),
    reread: boolean("reread").default(false),
    rereadCount: integer("reread_count").default(0),

    // Tags for personal categorization
    tags: text("tags").array(),

    // Metadata
    createdAt: timestamp("created_at").defaultNow(),
    updatedAt: timestamp("updated_at").defaultNow(),
  },
  (table) => ({
    uniqueBookLog: unique("unique_book_log").on(table.bookId),
    statusIdx: index("idx_reading_log_status").on(table.status),
    dateFinishedIdx: index("idx_reading_log_date_finished").on(table.dateFinished),
    dateStartedIdx: index("idx_reading_log_date_started").on(table.dateStarted),
    ratingIdx: index("idx_reading_log_rating").on(table.rating),
    ratingCheck: check(
      "reading_log_rating_check",
      sql`${table.rating} >= 1 AND ${table.rating} <= 5`
    ),
    statusCheck: check(
      "reading_log_status_check",
      sql`${table.status} IN ('want_to_read', 'reading', 'finished', 'did_not_finish', 'on_hold')`
    ),
  })
);

// Reading sessions (detailed activity tracking)
export const readingSessions = pgTable(
  "reading_sessions",
  {
    sessionId: serial("session_id").primaryKey(),
    bookId: integer("book_id")
      .notNull()
      .references(() => books.bookId, { onDelete: "cascade" }),
    sessionDate: date("session_date").notNull(),
    pagesRead: integer("pages_read"),
    minutesRead: integer("minutes_read"),
    startPage: integer("start_page"),
    endPage: integer("end_page"),
    notes: text("notes"),
    createdAt: timestamp("created_at").defaultNow(),
  },
  (table) => ({
    bookIdx: index("idx_reading_sessions_book").on(table.bookId),
    dateIdx: index("idx_reading_sessions_date").on(table.sessionDate),
  })
);
