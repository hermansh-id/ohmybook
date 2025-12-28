import { pgTable, integer, boolean, timestamp, primaryKey, index } from "drizzle-orm/pg-core";
import { books } from "./core";
import { authors } from "./core";
import { genres } from "./core";
import { series } from "./core";

// Book-Author relationship (many-to-many)
export const bookAuthors = pgTable(
  "book_authors",
  {
    bookId: integer("book_id")
      .notNull()
      .references(() => books.bookId, { onDelete: "cascade" }),
    authorId: integer("author_id")
      .notNull()
      .references(() => authors.authorId, { onDelete: "cascade" }),
    authorOrder: integer("author_order").default(1),
  },
  (table) => ({
    pk: primaryKey({ columns: [table.bookId, table.authorId] }),
    authorIdx: index("idx_book_authors_author").on(table.authorId),
    bookIdx: index("idx_book_authors_book").on(table.bookId),
  })
);

// Book-Genre relationship (many-to-many)
export const bookGenres = pgTable(
  "book_genres",
  {
    bookId: integer("book_id")
      .notNull()
      .references(() => books.bookId, { onDelete: "cascade" }),
    genreId: integer("genre_id")
      .notNull()
      .references(() => genres.genreId, { onDelete: "cascade" }),
    isPrimary: boolean("is_primary").default(false),
  },
  (table) => ({
    pk: primaryKey({ columns: [table.bookId, table.genreId] }),
    bookIdx: index("idx_book_genres_book").on(table.bookId),
    genreIdx: index("idx_book_genres_genre").on(table.genreId),
  })
);

// Series-Book relationship
export const seriesBooks = pgTable(
  "series_books",
  {
    seriesId: integer("series_id")
      .notNull()
      .references(() => series.seriesId, { onDelete: "cascade" }),
    bookId: integer("book_id")
      .notNull()
      .references(() => books.bookId, { onDelete: "cascade" }),
    position: integer("position").notNull(),
    isSideStory: boolean("is_side_story").default(false),
    createdAt: timestamp("created_at").defaultNow(),
  },
  (table) => ({
    pk: primaryKey({ columns: [table.seriesId, table.bookId] }),
    bookIdx: index("idx_series_books_book").on(table.bookId),
    seriesIdx: index("idx_series_books_series").on(table.seriesId),
    positionIdx: index("idx_series_books_position").on(table.position),
  })
);
