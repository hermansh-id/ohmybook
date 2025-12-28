import {
  pgTable,
  serial,
  integer,
  numeric,
  date,
  timestamp,
  check,
  unique,
} from "drizzle-orm/pg-core";
import { sql } from "drizzle-orm";
import { genres, authors, books } from "./core";

// Overall reading statistics
export const readingStats = pgTable("reading_stats", {
  statsId: serial("stats_id").primaryKey(),

  // Basic counts
  totalBooksRead: integer("total_books_read").default(0),
  totalBooksDnf: integer("total_books_dnf").default(0),
  totalPagesRead: integer("total_pages_read").default(0),
  totalBooksReading: integer("total_books_reading").default(0),
  totalBooksWantToRead: integer("total_books_want_to_read").default(0),

  // Averages
  averageRating: numeric("average_rating", { precision: 3, scale: 2 }),
  averageBookLength: integer("average_book_length"),
  averageReadingDays: numeric("average_reading_days", { precision: 5, scale: 1 }),

  // Streaks & patterns
  currentReadingStreak: integer("current_reading_streak").default(0),
  longestReadingStreak: integer("longest_reading_streak").default(0),
  lastReadDate: date("last_read_date"),

  // Favorites
  favoriteGenreId: integer("favorite_genre_id").references(() => genres.genreId),
  favoriteAuthorId: integer("favorite_author_id").references(() => authors.authorId),

  // Year tracking
  booksReadThisYear: integer("books_read_this_year").default(0),
  booksReadThisMonth: integer("books_read_this_month").default(0),
  pagesReadThisYear: integer("pages_read_this_year").default(0),
  pagesReadThisMonth: integer("pages_read_this_month").default(0),

  // Metadata
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

// Yearly statistics snapshot
export const yearlyStats = pgTable(
  "yearly_stats",
  {
    yearId: serial("year_id").primaryKey(),
    year: integer("year").notNull().unique(),

    booksRead: integer("books_read").default(0),
    pagesRead: integer("pages_read").default(0),
    averageRating: numeric("average_rating", { precision: 3, scale: 2 }),

    topGenreId: integer("top_genre_id").references(() => genres.genreId),
    topAuthorId: integer("top_author_id").references(() => authors.authorId),

    longestBookId: integer("longest_book_id"),
    shortestBookId: integer("shortest_book_id"),
    highestRatedBookId: integer("highest_rated_book_id"),

    createdAt: timestamp("created_at").defaultNow(),
    updatedAt: timestamp("updated_at").defaultNow(),
  },
  (table) => [unique("yearly_stats_year_key").on(table.year)]
);

// Monthly statistics
export const monthlyStats = pgTable(
  "monthly_stats",
  {
    monthId: serial("month_id").primaryKey(),
    year: integer("year").notNull(),
    month: integer("month").notNull(),

    booksRead: integer("books_read").default(0),
    pagesRead: integer("pages_read").default(0),
    averageRating: numeric("average_rating", { precision: 3, scale: 2 }),

    createdAt: timestamp("created_at").defaultNow(),
    updatedAt: timestamp("updated_at").defaultNow(),
  },
  (table) => [
    unique("monthly_stats_year_month_key").on(table.year, table.month),
    check(
      "monthly_stats_month_check",
      sql`${table.month} >= 1 AND ${table.month} <= 12`
    ),
  ]
);

// Reading goals
export const readingGoals = pgTable(
  "reading_goals",
  {
    goalId: serial("goal_id").primaryKey(),
    year: integer("year").notNull(),

    targetBooks: integer("target_books"),
    targetPages: integer("target_pages"),

    currentBooks: integer("current_books").default(0),
    currentPages: integer("current_pages").default(0),

    createdAt: timestamp("created_at").defaultNow(),
    updatedAt: timestamp("updated_at").defaultNow(),
  },
  (table) => [unique("unique_year_goal").on(table.year)]
);
