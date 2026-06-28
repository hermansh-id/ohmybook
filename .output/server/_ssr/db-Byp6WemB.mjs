import { r as __exportAll$1 } from "../_runtime.mjs";
import { t as cs } from "../_libs/neondatabase__serverless.mjs";
import { A as boolean, C as varchar, D as numeric, E as serial, M as unique, O as integer, S as pgTable, T as text, b as index, j as sql, k as date, n as drizzle, w as timestamp, x as check, y as primaryKey } from "../_libs/drizzle-orm.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/db-Byp6WemB.js
var db_Byp6WemB_exports = /* @__PURE__ */ __exportAll$1({
	_: () => accounts,
	a: () => readingGoals,
	b: () => users,
	c: () => bookQuotes,
	d: () => bookAuthors,
	f: () => bookGenres,
	g: () => goodreadsData,
	h: () => genres,
	i: () => monthlyStats,
	l: () => readingLog,
	m: () => books,
	n: () => db_exports,
	o: () => readingStats,
	p: () => authors,
	r: () => schema_exports,
	s: () => yearlyStats,
	t: () => db,
	u: () => readingSessions,
	v: () => sessions,
	x: () => __exportAll,
	y: () => verifications
});
var __defProp = Object.defineProperty;
var __exportAll = (all, no_symbols) => {
	let target = {};
	for (var name in all) __defProp(target, name, {
		get: all[name],
		enumerable: true
	});
	if (!no_symbols) __defProp(target, Symbol.toStringTag, { value: "Module" });
	return target;
};
var users = pgTable("users", {
	id: text("id").primaryKey().notNull(),
	name: varchar("name", { length: 100 }).notNull(),
	email: varchar("email", { length: 255 }).notNull().unique(),
	emailVerified: boolean("email_verified").default(false).notNull(),
	image: text("image"),
	createdAt: timestamp("created_at").defaultNow().notNull(),
	updatedAt: timestamp("updated_at").defaultNow().notNull()
}, (table) => ({ emailIdx: index("idx_users_email").on(table.email) }));
var sessions = pgTable("session", {
	id: text("id").primaryKey(),
	expiresAt: timestamp("expires_at").notNull(),
	token: text("token").notNull().unique(),
	createdAt: timestamp("created_at").notNull(),
	updatedAt: timestamp("updated_at").notNull(),
	ipAddress: text("ip_address"),
	userAgent: text("user_agent"),
	userId: text("user_id").notNull().references(() => users.id)
});
var accounts = pgTable("account", {
	id: text("id").primaryKey(),
	accountId: text("account_id").notNull(),
	providerId: text("provider_id").notNull(),
	userId: text("user_id").notNull().references(() => users.id),
	accessToken: text("access_token"),
	refreshToken: text("refresh_token"),
	idToken: text("id_token"),
	accessTokenExpiresAt: timestamp("access_token_expires_at"),
	refreshTokenExpiresAt: timestamp("refresh_token_expires_at"),
	scope: text("scope"),
	password: text("password"),
	createdAt: timestamp("created_at").notNull(),
	updatedAt: timestamp("updated_at").notNull()
});
var verifications = pgTable("verification", {
	id: text("id").primaryKey(),
	identifier: text("identifier").notNull(),
	value: text("value").notNull(),
	expiresAt: timestamp("expires_at").notNull(),
	createdAt: timestamp("created_at"),
	updatedAt: timestamp("updated_at")
});
var authors = pgTable("authors", {
	authorId: serial("author_id").primaryKey(),
	name: varchar("name", { length: 255 }).notNull().unique(),
	bio: text("bio"),
	createdAt: timestamp("created_at").defaultNow()
}, (table) => ({ nameIdx: index("idx_authors_name").on(table.name) }));
var genres = pgTable("genres", {
	genreId: serial("genre_id").primaryKey(),
	genreName: varchar("genre_name", { length: 100 }).notNull().unique(),
	description: text("description"),
	createdAt: timestamp("created_at").defaultNow()
});
var series = pgTable("series", {
	seriesId: serial("series_id").primaryKey(),
	title: varchar("title", { length: 255 }).notNull(),
	description: text("description"),
	totalBooks: integer("total_books").default(0),
	status: varchar("status", { length: 50 }).default("unknown"),
	createdAt: timestamp("created_at").defaultNow(),
	updatedAt: timestamp("updated_at").defaultNow()
}, (table) => [check("series_status_check", sql`${table.status} IN ('ongoing', 'completed', 'cancelled', 'unknown')`)]);
var books = pgTable("books", {
	bookId: serial("book_id").primaryKey(),
	title: varchar("title", { length: 255 }).notNull(),
	isbn: varchar("isbn", { length: 255 }),
	goodreadsUrl: text("goodreads_url"),
	year: integer("year"),
	pages: integer("pages"),
	addedAt: timestamp("added_at").defaultNow()
}, (table) => ({
	titleIdx: index("idx_books_title").on(table.title),
	isbnIdx: index("idx_books_isbn").on(table.isbn),
	yearIdx: index("idx_books_year").on(table.year)
}));
var goodreadsData = pgTable("goodreads_data", {
	bookId: integer("book_id").primaryKey().notNull().references(() => books.bookId, { onDelete: "cascade" }),
	goodreadsId: varchar("goodreads_id", { length: 50 }),
	description: text("description"),
	averageRating: numeric("average_rating", {
		precision: 3,
		scale: 2
	}),
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
	lastUpdated: timestamp("last_updated").defaultNow()
});
var bookAuthors = pgTable("book_authors", {
	bookId: integer("book_id").notNull().references(() => books.bookId, { onDelete: "cascade" }),
	authorId: integer("author_id").notNull().references(() => authors.authorId, { onDelete: "cascade" }),
	authorOrder: integer("author_order").default(1)
}, (table) => ({
	pk: primaryKey({ columns: [table.bookId, table.authorId] }),
	authorIdx: index("idx_book_authors_author").on(table.authorId),
	bookIdx: index("idx_book_authors_book").on(table.bookId)
}));
var bookGenres = pgTable("book_genres", {
	bookId: integer("book_id").notNull().references(() => books.bookId, { onDelete: "cascade" }),
	genreId: integer("genre_id").notNull().references(() => genres.genreId, { onDelete: "cascade" }),
	isPrimary: boolean("is_primary").default(false)
}, (table) => ({
	pk: primaryKey({ columns: [table.bookId, table.genreId] }),
	bookIdx: index("idx_book_genres_book").on(table.bookId),
	genreIdx: index("idx_book_genres_genre").on(table.genreId)
}));
var seriesBooks = pgTable("series_books", {
	seriesId: integer("series_id").notNull().references(() => series.seriesId, { onDelete: "cascade" }),
	bookId: integer("book_id").notNull().references(() => books.bookId, { onDelete: "cascade" }),
	position: integer("position").notNull(),
	isSideStory: boolean("is_side_story").default(false),
	createdAt: timestamp("created_at").defaultNow()
}, (table) => ({
	pk: primaryKey({ columns: [table.seriesId, table.bookId] }),
	bookIdx: index("idx_series_books_book").on(table.bookId),
	seriesIdx: index("idx_series_books_series").on(table.seriesId),
	positionIdx: index("idx_series_books_position").on(table.position)
}));
var readingLog = pgTable("reading_log", {
	logId: serial("log_id").primaryKey(),
	bookId: integer("book_id").notNull().references(() => books.bookId, { onDelete: "cascade" }),
	status: varchar("status", { length: 50 }).default("want_to_read"),
	dateAdded: date("date_added").defaultNow(),
	dateStarted: date("date_started"),
	dateFinished: date("date_finished"),
	currentPage: integer("current_page").default(0),
	rating: integer("rating"),
	review: text("review"),
	notes: text("notes"),
	readingDays: integer("reading_days"),
	reread: boolean("reread").default(false),
	rereadCount: integer("reread_count").default(0),
	tags: text("tags").array(),
	createdAt: timestamp("created_at").defaultNow(),
	updatedAt: timestamp("updated_at").defaultNow()
}, (table) => ({
	uniqueBookLog: unique("unique_book_log").on(table.bookId),
	statusIdx: index("idx_reading_log_status").on(table.status),
	dateFinishedIdx: index("idx_reading_log_date_finished").on(table.dateFinished),
	dateStartedIdx: index("idx_reading_log_date_started").on(table.dateStarted),
	ratingIdx: index("idx_reading_log_rating").on(table.rating),
	ratingCheck: check("reading_log_rating_check", sql`${table.rating} >= 1 AND ${table.rating} <= 5`),
	statusCheck: check("reading_log_status_check", sql`${table.status} IN ('want_to_read', 'reading', 'finished', 'did_not_finish', 'on_hold')`)
}));
var readingSessions = pgTable("reading_sessions", {
	sessionId: serial("session_id").primaryKey(),
	bookId: integer("book_id").notNull().references(() => books.bookId, { onDelete: "cascade" }),
	sessionDate: date("session_date").notNull(),
	pagesRead: integer("pages_read"),
	minutesRead: integer("minutes_read"),
	startPage: integer("start_page"),
	endPage: integer("end_page"),
	notes: text("notes"),
	createdAt: timestamp("created_at").defaultNow()
}, (table) => ({
	bookIdx: index("idx_reading_sessions_book").on(table.bookId),
	dateIdx: index("idx_reading_sessions_date").on(table.sessionDate)
}));
var bookQuotes = pgTable("book_quotes", {
	quoteId: serial("quote_id").primaryKey(),
	bookId: integer("book_id").notNull().references(() => books.bookId, { onDelete: "cascade" }),
	quoteText: text("quote_text").notNull(),
	pageNumber: integer("page_number"),
	chapter: varchar("chapter", { length: 255 }),
	tags: text("tags").array(),
	isFavorite: boolean("is_favorite").default(false),
	notes: text("notes"),
	createdAt: timestamp("created_at").defaultNow(),
	updatedAt: timestamp("updated_at").defaultNow()
}, (table) => ({
	bookIdx: index("idx_book_quotes_book").on(table.bookId),
	favoriteIdx: index("idx_book_quotes_favorite").on(table.isFavorite),
	createdAtIdx: index("idx_book_quotes_created").on(table.createdAt)
}));
var readingStats = pgTable("reading_stats", {
	statsId: serial("stats_id").primaryKey(),
	totalBooksRead: integer("total_books_read").default(0),
	totalBooksDnf: integer("total_books_dnf").default(0),
	totalPagesRead: integer("total_pages_read").default(0),
	totalBooksReading: integer("total_books_reading").default(0),
	totalBooksWantToRead: integer("total_books_want_to_read").default(0),
	averageRating: numeric("average_rating", {
		precision: 3,
		scale: 2
	}),
	averageBookLength: integer("average_book_length"),
	averageReadingDays: numeric("average_reading_days", {
		precision: 5,
		scale: 1
	}),
	currentReadingStreak: integer("current_reading_streak").default(0),
	longestReadingStreak: integer("longest_reading_streak").default(0),
	lastReadDate: date("last_read_date"),
	favoriteGenreId: integer("favorite_genre_id").references(() => genres.genreId),
	favoriteAuthorId: integer("favorite_author_id").references(() => authors.authorId),
	booksReadThisYear: integer("books_read_this_year").default(0),
	booksReadThisMonth: integer("books_read_this_month").default(0),
	pagesReadThisYear: integer("pages_read_this_year").default(0),
	pagesReadThisMonth: integer("pages_read_this_month").default(0),
	createdAt: timestamp("created_at").defaultNow(),
	updatedAt: timestamp("updated_at").defaultNow()
});
var yearlyStats = pgTable("yearly_stats", {
	yearId: serial("year_id").primaryKey(),
	year: integer("year").notNull().unique(),
	booksRead: integer("books_read").default(0),
	pagesRead: integer("pages_read").default(0),
	averageRating: numeric("average_rating", {
		precision: 3,
		scale: 2
	}),
	topGenreId: integer("top_genre_id").references(() => genres.genreId),
	topAuthorId: integer("top_author_id").references(() => authors.authorId),
	longestBookId: integer("longest_book_id"),
	shortestBookId: integer("shortest_book_id"),
	highestRatedBookId: integer("highest_rated_book_id"),
	createdAt: timestamp("created_at").defaultNow(),
	updatedAt: timestamp("updated_at").defaultNow()
}, (table) => [unique("yearly_stats_year_key").on(table.year)]);
var monthlyStats = pgTable("monthly_stats", {
	monthId: serial("month_id").primaryKey(),
	year: integer("year").notNull(),
	month: integer("month").notNull(),
	booksRead: integer("books_read").default(0),
	pagesRead: integer("pages_read").default(0),
	averageRating: numeric("average_rating", {
		precision: 3,
		scale: 2
	}),
	createdAt: timestamp("created_at").defaultNow(),
	updatedAt: timestamp("updated_at").defaultNow()
}, (table) => [unique("monthly_stats_year_month_key").on(table.year, table.month), check("monthly_stats_month_check", sql`${table.month} >= 1 AND ${table.month} <= 12`)]);
var readingGoals = pgTable("reading_goals", {
	goalId: serial("goal_id").primaryKey(),
	year: integer("year").notNull(),
	targetBooks: integer("target_books"),
	targetPages: integer("target_pages"),
	currentBooks: integer("current_books").default(0),
	currentPages: integer("current_pages").default(0),
	createdAt: timestamp("created_at").defaultNow(),
	updatedAt: timestamp("updated_at").defaultNow()
}, (table) => [unique("unique_year_goal").on(table.year)]);
var schema_exports = /* @__PURE__ */ __exportAll({
	accounts: () => accounts,
	authors: () => authors,
	bookAuthors: () => bookAuthors,
	bookGenres: () => bookGenres,
	bookQuotes: () => bookQuotes,
	books: () => books,
	genres: () => genres,
	goodreadsData: () => goodreadsData,
	monthlyStats: () => monthlyStats,
	readingGoals: () => readingGoals,
	readingLog: () => readingLog,
	readingSessions: () => readingSessions,
	readingStats: () => readingStats,
	series: () => series,
	seriesBooks: () => seriesBooks,
	sessions: () => sessions,
	users: () => users,
	verifications: () => verifications,
	yearlyStats: () => yearlyStats
});
var db_exports = /* @__PURE__ */ __exportAll({
	db: () => db,
	schema: () => schema_exports
});
if (!process.env.DATABASE_URL) throw new Error("DATABASE_URL environment variable is not set");
var db = drizzle(cs(process.env.DATABASE_URL), { schema: schema_exports });
//#endregion
export { sessions as _, bookGenres as a, yearlyStats as b, db as c, goodreadsData as d, monthlyStats as f, readingStats as g, readingSessions as h, bookAuthors as i, db_Byp6WemB_exports as l, readingLog as m, accounts as n, bookQuotes as o, readingGoals as p, authors as r, books as s, __exportAll as t, genres as u, users as v, verifications as y };
