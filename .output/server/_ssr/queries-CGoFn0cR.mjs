import { a as desc, j as sql, o as and, s as eq } from "../_libs/drizzle-orm.mjs";
import { a as bookGenres, b as yearlyStats, c as db, d as goodreadsData, f as monthlyStats, g as readingStats, h as readingSessions, i as bookAuthors, m as readingLog, o as bookQuotes, p as readingGoals, r as authors, s as books, t as __exportAll, u as genres } from "./db-Byp6WemB.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/queries-CGoFn0cR.js
/**
* Common database queries using Drizzle ORM
*
* This file contains helper functions for common database operations.
* Import and use these in your Server Components, Server Actions, or API routes.
*/
var queries_exports = /* @__PURE__ */ __exportAll({
	addToReadingLog: () => addToReadingLog,
	createQuote: () => createQuote,
	createReadingSession: () => createReadingSession,
	deleteQuote: () => deleteQuote,
	deleteReadingSession: () => deleteReadingSession,
	getAllBooksWithDetails: () => getAllBooksWithDetails,
	getAllQuotes: () => getAllQuotes,
	getAuthorsWithStats: () => getAuthorsWithStats,
	getBookById: () => getBookById,
	getBookReadingSessions: () => getBookReadingSessions,
	getCurrentYearGoal: () => getCurrentYearGoal,
	getCurrentlyReadingBooks: () => getCurrentlyReadingBooks,
	getDailyReadingActivity: () => getDailyReadingActivity,
	getFinishedBooks: () => getFinishedBooks,
	getFinishedBooksByDate: () => getFinishedBooksByDate,
	getGenresWithStats: () => getGenresWithStats,
	getLibraryCompletion: () => getLibraryCompletion,
	getLibraryStats: () => getLibraryStats,
	getMonthlyStats: () => getMonthlyStats,
	getQuoteStats: () => getQuoteStats,
	getReadingHistory: () => getReadingHistory,
	getReadingSessions: () => getReadingSessions,
	getReadingStats: () => getReadingStats,
	getReadingStreaks: () => getReadingStreaks,
	getTopRatedBooks: () => getTopRatedBooks,
	getYearlyStats: () => getYearlyStats,
	markBookAsFinished: () => markBookAsFinished,
	toggleQuoteFavorite: () => toggleQuoteFavorite,
	updateQuote: () => updateQuote,
	updateReadingSession: () => updateReadingSession,
	updateReadingStatus: () => updateReadingStatus
});
/**
* Get all books with their authors and genres
*/
async function getAllBooksWithDetails() {
	return await db.select({
		book: books,
		author: authors,
		genre: genres,
		readingStatus: readingLog,
		goodreads: goodreadsData
	}).from(books).leftJoin(bookAuthors, eq(books.bookId, bookAuthors.bookId)).leftJoin(authors, eq(bookAuthors.authorId, authors.authorId)).leftJoin(bookGenres, eq(books.bookId, bookGenres.bookId)).leftJoin(genres, eq(bookGenres.genreId, genres.genreId)).leftJoin(readingLog, eq(books.bookId, readingLog.bookId)).leftJoin(goodreadsData, eq(books.bookId, goodreadsData.bookId)).orderBy(desc(books.addedAt));
}
/**
* Get a single book by ID with all related data
*/
async function getBookById(bookId) {
	return await db.select().from(books).where(eq(books.bookId, bookId)).leftJoin(goodreadsData, eq(books.bookId, goodreadsData.bookId)).leftJoin(readingLog, eq(books.bookId, readingLog.bookId)).limit(1);
}
/**
* Get currently reading books
*/
async function getCurrentlyReadingBooks() {
	return await db.select({
		log: readingLog,
		book: books,
		authors: sql`string_agg(DISTINCT ${authors.name}, ', ')`
	}).from(readingLog).innerJoin(books, eq(readingLog.bookId, books.bookId)).leftJoin(bookAuthors, eq(books.bookId, bookAuthors.bookId)).leftJoin(authors, eq(bookAuthors.authorId, authors.authorId)).where(eq(readingLog.status, "reading")).groupBy(readingLog.logId, books.bookId).orderBy(desc(readingLog.dateStarted));
}
/**
* Get finished books
*/
async function getFinishedBooks(limit = 50) {
	return await db.select({
		log: readingLog,
		book: books,
		authors: sql`string_agg(DISTINCT ${authors.name}, ', ')`
	}).from(readingLog).innerJoin(books, eq(readingLog.bookId, books.bookId)).leftJoin(bookAuthors, eq(books.bookId, bookAuthors.bookId)).leftJoin(authors, eq(bookAuthors.authorId, authors.authorId)).where(eq(readingLog.status, "finished")).groupBy(readingLog.logId, books.bookId).orderBy(desc(readingLog.dateFinished)).limit(limit);
}
/**
* Get finished books by date for calendar view
* Returns books grouped by their finish date
*/
async function getFinishedBooksByDate(year, month) {
	let whereConditions = [eq(readingLog.status, "finished")];
	if (year && month) whereConditions.push(sql`EXTRACT(YEAR FROM ${readingLog.dateFinished}) = ${year}`, sql`EXTRACT(MONTH FROM ${readingLog.dateFinished}) = ${month}`);
	else if (year) whereConditions.push(sql`EXTRACT(YEAR FROM ${readingLog.dateFinished}) = ${year}`);
	return await db.select({
		log: readingLog,
		book: books,
		authors: sql`string_agg(DISTINCT ${authors.name}, ', ')`,
		goodreads: goodreadsData
	}).from(readingLog).innerJoin(books, eq(readingLog.bookId, books.bookId)).leftJoin(bookAuthors, eq(books.bookId, bookAuthors.bookId)).leftJoin(authors, eq(bookAuthors.authorId, authors.authorId)).leftJoin(goodreadsData, eq(books.bookId, goodreadsData.bookId)).where(and(...whereConditions)).groupBy(readingLog.logId, books.bookId, goodreadsData.bookId).orderBy(desc(readingLog.dateFinished));
}
/**
* Add a book to reading log
*/
async function addToReadingLog(bookId, status = "want_to_read") {
	return await db.insert(readingLog).values({
		bookId,
		status
	}).returning();
}
/**
* Update reading status
*/
async function updateReadingStatus(logId, updates) {
	const dbUpdates = { ...updates };
	if (dbUpdates.dateStarted instanceof Date) dbUpdates.dateStarted = dbUpdates.dateStarted.toISOString().split("T")[0];
	if (dbUpdates.dateFinished instanceof Date) dbUpdates.dateFinished = dbUpdates.dateFinished.toISOString().split("T")[0];
	return await db.update(readingLog).set(dbUpdates).where(eq(readingLog.logId, logId)).returning();
}
/**
* Mark book as finished
*/
async function markBookAsFinished(logId, rating, review) {
	const today = (/* @__PURE__ */ new Date()).toISOString().split("T")[0];
	return await db.update(readingLog).set({
		status: "finished",
		dateFinished: today,
		rating,
		review
	}).where(eq(readingLog.logId, logId)).returning();
}
/**
* Get overall reading statistics
*/
async function getReadingStats() {
	return await db.select().from(readingStats).limit(1);
}
/**
* Get library completion statistics
*/
async function getLibraryCompletion() {
	const totalBooks = (await db.select({ count: sql`COUNT(*)::int` }).from(books))[0]?.count || 0;
	const booksRead = (await db.select({ count: sql`COUNT(DISTINCT ${readingLog.bookId})::int` }).from(readingLog).where(eq(readingLog.status, "finished")))[0]?.count || 0;
	const percentage = totalBooks > 0 ? Math.round(booksRead / totalBooks * 100) : 0;
	const firstReadingResult = await db.select({ date: readingLog.dateFinished }).from(readingLog).where(eq(readingLog.status, "finished")).orderBy(readingLog.dateFinished).limit(1);
	let estimatedCompletionMonths = null;
	if (firstReadingResult.length > 0 && booksRead > 0) {
		const firstDate = new Date(firstReadingResult[0].date);
		const now = /* @__PURE__ */ new Date();
		const avgBooksPerMonth = booksRead / ((now.getFullYear() - firstDate.getFullYear()) * 12 + (now.getMonth() - firstDate.getMonth()) + 1);
		const booksRemaining = totalBooks - booksRead;
		estimatedCompletionMonths = avgBooksPerMonth > 0 ? Math.ceil(booksRemaining / avgBooksPerMonth) : null;
	}
	return {
		totalBooks,
		booksRead,
		percentage,
		estimatedCompletionMonths
	};
}
/**
* Get library statistics (total counts)
*/
async function getLibraryStats() {
	const totalBooks = (await db.select({ count: sql`COUNT(*)::int` }).from(books))[0]?.count || 0;
	const totalAuthors = (await db.select({ count: sql`COUNT(DISTINCT ${authors.authorId})::int` }).from(authors).innerJoin(bookAuthors, eq(authors.authorId, bookAuthors.authorId)))[0]?.count || 0;
	const totalGenres = (await db.select({ count: sql`COUNT(DISTINCT ${genres.genreId})::int` }).from(genres).innerJoin(bookGenres, eq(genres.genreId, bookGenres.genreId)))[0]?.count || 0;
	const pagesResult = await db.select({
		totalPages: sql`COALESCE(SUM(${books.pages}), 0)::int`,
		avgPages: sql`COALESCE(ROUND(AVG(${books.pages})::numeric, 0), 0)::int`
	}).from(books);
	return {
		totalBooks,
		totalAuthors,
		totalGenres,
		totalPages: pagesResult[0]?.totalPages || 0,
		avgPages: pagesResult[0]?.avgPages || 0
	};
}
/**
* Get yearly statistics
*/
async function getYearlyStats(year) {
	const query = db.select().from(yearlyStats);
	if (year) return await query.where(eq(yearlyStats.year, year)).limit(1);
	return await query.orderBy(desc(yearlyStats.year));
}
/**
* Get monthly statistics
*/
async function getMonthlyStats(year) {
	return await db.select().from(monthlyStats).where(eq(monthlyStats.year, year)).orderBy(desc(monthlyStats.month));
}
/**
* Get current year's reading goal with actual progress
*/
async function getCurrentYearGoal() {
	const currentYear = (/* @__PURE__ */ new Date()).getFullYear();
	const goalData = await db.select().from(readingGoals).where(eq(readingGoals.year, currentYear)).limit(1);
	const progress = await db.select({
		count: sql`COUNT(DISTINCT ${readingLog.logId})::int`,
		totalPages: sql`COALESCE(SUM(${books.pages}), 0)::int`
	}).from(readingLog).leftJoin(books, eq(readingLog.bookId, books.bookId)).where(and(eq(readingLog.status, "finished"), sql`EXTRACT(YEAR FROM ${readingLog.dateFinished}) = ${currentYear}`));
	const currentBooks = progress[0]?.count || 0;
	const currentPages = progress[0]?.totalPages || 0;
	if (goalData.length === 0) return [{
		goalId: 0,
		year: currentYear,
		targetBooks: 52,
		targetPages: null,
		currentBooks,
		currentPages,
		createdAt: /* @__PURE__ */ new Date(),
		updatedAt: /* @__PURE__ */ new Date()
	}];
	return [{
		...goalData[0],
		currentBooks,
		currentPages
	}];
}
/**
* Get top rated books
*/
async function getTopRatedBooks(limit = 10) {
	return await db.select({
		log: readingLog,
		book: books,
		authors: sql`string_agg(DISTINCT ${authors.name}, ', ')`
	}).from(readingLog).innerJoin(books, eq(readingLog.bookId, books.bookId)).leftJoin(bookAuthors, eq(books.bookId, bookAuthors.bookId)).leftJoin(authors, eq(bookAuthors.authorId, authors.authorId)).where(and(eq(readingLog.status, "finished"), sql`${readingLog.rating} IS NOT NULL`)).groupBy(readingLog.logId, books.bookId).orderBy(desc(readingLog.rating), desc(readingLog.dateFinished)).limit(limit);
}
/**
* Get all reading sessions with book details
*/
async function getReadingSessions(limit = 50) {
	return await db.select({
		session: readingSessions,
		book: books,
		authors: sql`string_agg(DISTINCT ${authors.name}, ', ')`
	}).from(readingSessions).innerJoin(books, eq(readingSessions.bookId, books.bookId)).leftJoin(bookAuthors, eq(books.bookId, bookAuthors.bookId)).leftJoin(authors, eq(bookAuthors.authorId, authors.authorId)).groupBy(readingSessions.sessionId, books.bookId).orderBy(desc(readingSessions.sessionDate), desc(readingSessions.createdAt)).limit(limit);
}
/**
* Get reading sessions for a specific book
*/
async function getBookReadingSessions(bookId) {
	return await db.select().from(readingSessions).where(eq(readingSessions.bookId, bookId)).orderBy(desc(readingSessions.sessionDate));
}
/**
* Create a new reading session
*/
async function createReadingSession(data) {
	return await db.insert(readingSessions).values({
		...data,
		sessionDate: data.sessionDate.toISOString().split("T")[0]
	}).returning();
}
/**
* Update a reading session
*/
async function updateReadingSession(sessionId, data) {
	return await db.update(readingSessions).set({
		...data,
		sessionDate: data.sessionDate?.toISOString().split("T")[0]
	}).where(eq(readingSessions.sessionId, sessionId)).returning();
}
/**
* Delete a reading session
*/
async function deleteReadingSession(sessionId) {
	return await db.delete(readingSessions).where(eq(readingSessions.sessionId, sessionId)).returning();
}
/**
* Get all authors with statistics
*/
async function getAuthorsWithStats() {
	return await db.select({
		author: authors,
		totalBooks: sql`COUNT(DISTINCT ${books.bookId})::int`,
		totalPages: sql`COALESCE(SUM(${books.pages}), 0)::int`,
		booksRead: sql`COUNT(DISTINCT CASE WHEN ${readingLog.status} = 'finished' THEN ${books.bookId} END)::int`,
		averageRating: sql`ROUND(AVG(${readingLog.rating})::numeric, 1)`
	}).from(authors).leftJoin(bookAuthors, eq(authors.authorId, bookAuthors.authorId)).leftJoin(books, eq(bookAuthors.bookId, books.bookId)).leftJoin(readingLog, eq(books.bookId, readingLog.bookId)).groupBy(authors.authorId).orderBy(desc(sql`COUNT(DISTINCT ${books.bookId})`));
}
/**
* Get all genres with statistics
*/
async function getGenresWithStats() {
	return await db.select({
		genre: genres,
		totalBooks: sql`COUNT(DISTINCT ${books.bookId})::int`,
		totalPages: sql`COALESCE(SUM(${books.pages}), 0)::int`,
		booksRead: sql`COUNT(DISTINCT CASE WHEN ${readingLog.status} = 'finished' THEN ${books.bookId} END)::int`,
		averageRating: sql`ROUND(AVG(${readingLog.rating})::numeric, 1)`
	}).from(genres).leftJoin(bookGenres, eq(genres.genreId, bookGenres.genreId)).leftJoin(books, eq(bookGenres.bookId, books.bookId)).leftJoin(readingLog, eq(books.bookId, readingLog.bookId)).groupBy(genres.genreId).orderBy(desc(sql`COUNT(DISTINCT ${books.bookId})`));
}
/**
* Get reading history data for charts
* Returns daily data of books finished and pages read
*/
async function getReadingHistory(months = 12) {
	const startDate = /* @__PURE__ */ new Date();
	startDate.setMonth(startDate.getMonth() - months);
	startDate.setHours(0, 0, 0, 0);
	return await db.select({
		period: sql`DATE(${readingLog.dateFinished})`,
		booksRead: sql`COUNT(DISTINCT ${readingLog.logId})::int`,
		pagesRead: sql`COALESCE(SUM(${books.pages}), 0)::int`
	}).from(readingLog).leftJoin(books, eq(readingLog.bookId, books.bookId)).where(and(eq(readingLog.status, "finished"), sql`${readingLog.dateFinished} >= ${startDate.toISOString()}`)).groupBy(sql`DATE(${readingLog.dateFinished})`).orderBy(sql`DATE(${readingLog.dateFinished})`);
}
/**
* Get daily reading activity for heatmap (last 365 days)
* Combines reading sessions and books finished
*/
async function getDailyReadingActivity(days = 365) {
	const startDate = /* @__PURE__ */ new Date();
	startDate.setDate(startDate.getDate() - days);
	startDate.setHours(0, 0, 0, 0);
	const sessionActivity = await db.select({
		date: sql`DATE(${readingSessions.sessionDate})`,
		pagesRead: sql`COALESCE(SUM(${readingSessions.pagesRead}), 0)::int`,
		minutesRead: sql`COALESCE(SUM(${readingSessions.minutesRead}), 0)::int`,
		sessionCount: sql`COUNT(*)::int`
	}).from(readingSessions).where(sql`${readingSessions.sessionDate} >= ${startDate.toISOString().split("T")[0]}`).groupBy(sql`DATE(${readingSessions.sessionDate})`).orderBy(sql`DATE(${readingSessions.sessionDate})`);
	const finishedActivity = await db.select({
		date: sql`DATE(${readingLog.dateFinished})`,
		pagesRead: sql`COALESCE(SUM(${books.pages}), 0)::int`,
		booksFinished: sql`COUNT(*)::int`
	}).from(readingLog).leftJoin(books, eq(readingLog.bookId, books.bookId)).where(and(eq(readingLog.status, "finished"), sql`${readingLog.dateFinished} >= ${startDate.toISOString().split("T")[0]}`)).groupBy(sql`DATE(${readingLog.dateFinished})`).orderBy(sql`DATE(${readingLog.dateFinished})`);
	const activityMap = /* @__PURE__ */ new Map();
	sessionActivity.forEach((activity) => {
		activityMap.set(activity.date, {
			date: activity.date,
			pagesRead: activity.pagesRead,
			minutesRead: activity.minutesRead,
			sessionCount: activity.sessionCount
		});
	});
	finishedActivity.forEach((activity) => {
		if (!activityMap.has(activity.date)) activityMap.set(activity.date, {
			date: activity.date,
			pagesRead: activity.pagesRead,
			minutesRead: 0,
			sessionCount: activity.booksFinished
		});
	});
	return Array.from(activityMap.values()).sort((a, b) => a.date.localeCompare(b.date));
}
/**
* Calculate reading streaks
* Returns current streak and best streak
* Combines reading sessions and books finished
*/
async function getReadingStreaks() {
	const sessionDates = await db.select({ date: sql`DATE(${readingSessions.sessionDate})` }).from(readingSessions).groupBy(sql`DATE(${readingSessions.sessionDate})`);
	const finishedDates = await db.select({ date: sql`DATE(${readingLog.dateFinished})` }).from(readingLog).where(eq(readingLog.status, "finished")).groupBy(sql`DATE(${readingLog.dateFinished})`);
	const allDatesSet = /* @__PURE__ */ new Set();
	sessionDates.forEach((d) => allDatesSet.add(d.date));
	finishedDates.forEach((d) => d.date && allDatesSet.add(d.date));
	if (allDatesSet.size === 0) return {
		currentStreak: 0,
		bestStreak: 0,
		totalReadingDays: 0
	};
	const dates = Array.from(allDatesSet).map((d) => new Date(d)).sort((a, b) => b.getTime() - a.getTime());
	const today = /* @__PURE__ */ new Date();
	today.setHours(0, 0, 0, 0);
	let currentStreak = 0;
	let checkDate = new Date(today);
	for (const date of dates) {
		const readDate = new Date(date);
		readDate.setHours(0, 0, 0, 0);
		const diffDays = Math.floor((checkDate.getTime() - readDate.getTime()) / (1e3 * 60 * 60 * 24));
		if (diffDays === 0 || diffDays === 1) {
			currentStreak++;
			checkDate = readDate;
		} else break;
	}
	let bestStreak = 0;
	let tempStreak = 1;
	for (let i = 0; i < dates.length - 1; i++) {
		const currentDate = new Date(dates[i]);
		const nextDate = new Date(dates[i + 1]);
		currentDate.setHours(0, 0, 0, 0);
		nextDate.setHours(0, 0, 0, 0);
		if (Math.floor((currentDate.getTime() - nextDate.getTime()) / (1e3 * 60 * 60 * 24)) === 1) tempStreak++;
		else {
			bestStreak = Math.max(bestStreak, tempStreak);
			tempStreak = 1;
		}
	}
	bestStreak = Math.max(bestStreak, tempStreak);
	return {
		currentStreak,
		bestStreak,
		totalReadingDays: dates.length
	};
}
/**
* Get all quotes with book details
*/
async function getAllQuotes(limit) {
	const query = db.select({
		quote: bookQuotes,
		book: books,
		authors: sql`string_agg(DISTINCT ${authors.name}, ', ')`
	}).from(bookQuotes).innerJoin(books, eq(bookQuotes.bookId, books.bookId)).leftJoin(bookAuthors, eq(books.bookId, bookAuthors.bookId)).leftJoin(authors, eq(bookAuthors.authorId, authors.authorId)).groupBy(bookQuotes.quoteId, books.bookId).orderBy(desc(bookQuotes.createdAt));
	if (limit) return await query.limit(limit);
	return await query;
}
/**
* Create a new quote
*/
async function createQuote(data) {
	return await db.insert(bookQuotes).values(data).returning();
}
/**
* Update a quote
*/
async function updateQuote(quoteId, data) {
	return await db.update(bookQuotes).set({
		...data,
		updatedAt: /* @__PURE__ */ new Date()
	}).where(eq(bookQuotes.quoteId, quoteId)).returning();
}
/**
* Delete a quote
*/
async function deleteQuote(quoteId) {
	return await db.delete(bookQuotes).where(eq(bookQuotes.quoteId, quoteId)).returning();
}
/**
* Toggle quote favorite status
*/
async function toggleQuoteFavorite(quoteId) {
	const quote = await db.select().from(bookQuotes).where(eq(bookQuotes.quoteId, quoteId)).limit(1);
	if (quote.length === 0) throw new Error("Quote not found");
	return await db.update(bookQuotes).set({
		isFavorite: !quote[0].isFavorite,
		updatedAt: /* @__PURE__ */ new Date()
	}).where(eq(bookQuotes.quoteId, quoteId)).returning();
}
/**
* Get quote statistics
*/
async function getQuoteStats() {
	const totalQuotes = await db.select({ count: sql`COUNT(*)::int` }).from(bookQuotes);
	const favoriteCount = await db.select({ count: sql`COUNT(*)::int` }).from(bookQuotes).where(eq(bookQuotes.isFavorite, true));
	const booksWithQuotes = await db.select({ count: sql`COUNT(DISTINCT ${bookQuotes.bookId})::int` }).from(bookQuotes);
	return {
		totalQuotes: totalQuotes[0]?.count || 0,
		favoriteQuotes: favoriteCount[0]?.count || 0,
		booksWithQuotes: booksWithQuotes[0]?.count || 0
	};
}
//#endregion
export { updateReadingSession as C, updateQuote as S, getReadingStreaks as _, getAllBooksWithDetails as a, queries_exports as b, getBookReadingSessions as c, getLibraryCompletion as d, getLibraryStats as f, getReadingStats as g, getReadingSessions as h, deleteReadingSession as i, getCurrentYearGoal as l, getQuoteStats as m, createReadingSession as n, getAuthorsWithStats as o, getMonthlyStats as p, deleteQuote as r, getBookById as s, createQuote as t, getGenresWithStats as u, getTopRatedBooks as v, toggleQuoteFavorite as x, getYearlyStats as y };
