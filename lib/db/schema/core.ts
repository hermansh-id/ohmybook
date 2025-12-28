import {
  pgTable,
  serial,
  varchar,
  text,
  timestamp,
  integer,
  numeric,
  date,
  check,
  index,
} from "drizzle-orm/pg-core";
import { sql } from "drizzle-orm";

// Authors
export const authors = pgTable(
  "authors",
  {
    authorId: serial("author_id").primaryKey(),
    name: varchar("name", { length: 255 }).notNull().unique(),
    bio: text("bio"),
    createdAt: timestamp("created_at").defaultNow(),
  },
  (table) => ({
    nameIdx: index("idx_authors_name").on(table.name),
  })
);

// Genres
export const genres = pgTable("genres", {
  genreId: serial("genre_id").primaryKey(),
  genreName: varchar("genre_name", { length: 100 }).notNull().unique(),
  description: text("description"),
  createdAt: timestamp("created_at").defaultNow(),
});

// Series
export const series = pgTable(
  "series",
  {
    seriesId: serial("series_id").primaryKey(),
    title: varchar("title", { length: 255 }).notNull(),
    description: text("description"),
    totalBooks: integer("total_books").default(0),
    status: varchar("status", { length: 50 }).default("unknown"),
    createdAt: timestamp("created_at").defaultNow(),
    updatedAt: timestamp("updated_at").defaultNow(),
  },
  (table) => [
    check(
      "series_status_check",
      sql`${table.status} IN ('ongoing', 'completed', 'cancelled', 'unknown')`
    ),
  ]
);

// Books
export const books = pgTable(
  "books",
  {
    bookId: serial("book_id").primaryKey(),
    title: varchar("title", { length: 255 }).notNull(),
    isbn: varchar("isbn", { length: 255 }),
    goodreadsUrl: text("goodreads_url"),
    year: integer("year"),
    pages: integer("pages"),
    addedAt: timestamp("added_at").defaultNow(),
  },
  (table) => ({
    titleIdx: index("idx_books_title").on(table.title),
    isbnIdx: index("idx_books_isbn").on(table.isbn),
    yearIdx: index("idx_books_year").on(table.year),
  })
);

// Goodreads data
export const goodreadsData = pgTable("goodreads_data", {
  bookId: integer("book_id")
    .primaryKey()
    .notNull()
    .references(() => books.bookId, { onDelete: "cascade" }),
  goodreadsId: varchar("goodreads_id", { length: 50 }),
  description: text("description"),
  averageRating: numeric("average_rating", { precision: 3, scale: 2 }),
  ratingsCount: integer("ratings_count"),
  reviewsCount: integer("reviews_count"),
  publicationDate: date("publication_date"),
  publisher: varchar("publisher", { length: 255 }),
  language: varchar("language", { length: 50 }),
  series: varchar("series", { length: 255 }),
  seriesPosition: integer("series_position"),
  originalTitle: varchar("original_title", { length: 255 }),
  originalPublicationYear: integer("original_publication_year"),
  coverUrl: text("cover_url"),
  awards: text("awards").array(),
  genres: text("genres").array(),
  scrapeDate: timestamp("scrape_date").defaultNow(),
  lastUpdated: timestamp("last_updated").defaultNow(),
});
