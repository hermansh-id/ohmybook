import { n as createServerFn } from "./ssr.mjs";
import { a as desc, j as sql, o as and, s as eq } from "../_libs/drizzle-orm.mjs";
import { a as bookGenres, c as db, i as bookAuthors, m as readingLog, r as authors, s as books, u as genres } from "./db-Byp6WemB.mjs";
import { t as createServerRpc } from "./createServerRpc-A6pJPYTF.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/reading-recap-DtTLwSLJ.js
var getMonthlyRecapAction_createServerFn_handler = createServerRpc({
	id: "fd85bbeff9114a414a6b16d5c4ac196140d2f7675248a332a45017d9bf202d37",
	name: "getMonthlyRecapAction",
	filename: "actions/reading-recap.ts"
}, (opts) => getMonthlyRecapAction.__executeServer(opts));
var getMonthlyRecapAction = createServerFn({ method: "POST" }).validator((d) => d).handler(getMonthlyRecapAction_createServerFn_handler, async ({ data }) => {
	const { year, month } = data;
	try {
		const finishedBooks = await db.select({
			book: books,
			log: readingLog,
			authors: sql`string_agg(DISTINCT ${authors.name}, ', ')`
		}).from(readingLog).innerJoin(books, eq(readingLog.bookId, books.bookId)).leftJoin(bookAuthors, eq(books.bookId, bookAuthors.bookId)).leftJoin(authors, eq(bookAuthors.authorId, authors.authorId)).where(and(eq(readingLog.status, "finished"), sql`EXTRACT(YEAR FROM ${readingLog.dateFinished}) = ${year}`, sql`EXTRACT(MONTH FROM ${readingLog.dateFinished}) = ${month}`)).groupBy(readingLog.logId, books.bookId).orderBy(desc(readingLog.dateFinished));
		const booksFinished = finishedBooks.length;
		const pagesRead = finishedBooks.reduce((sum, item) => sum + (item.book.pages || 0), 0);
		const topGenre = (await db.select({
			genreName: genres.genreName,
			count: sql`COUNT(DISTINCT ${books.bookId})::int`
		}).from(readingLog).innerJoin(books, eq(readingLog.bookId, books.bookId)).innerJoin(bookGenres, eq(books.bookId, bookGenres.bookId)).innerJoin(genres, eq(bookGenres.genreId, genres.genreId)).where(and(eq(readingLog.status, "finished"), sql`EXTRACT(YEAR FROM ${readingLog.dateFinished}) = ${year}`, sql`EXTRACT(MONTH FROM ${readingLog.dateFinished}) = ${month}`)).groupBy(genres.genreId, genres.genreName).orderBy(desc(sql`COUNT(DISTINCT ${books.bookId})`)).limit(1))[0]?.genreName || null;
		const topRatedResult = finishedBooks.filter((item) => item.log.rating !== null).sort((a, b) => (b.log.rating || 0) - (a.log.rating || 0)).slice(0, 1);
		const topRatedBook = topRatedResult[0] ? {
			title: topRatedResult[0].book.title,
			rating: topRatedResult[0].log.rating,
			authors: topRatedResult[0].authors || "Unknown"
		} : null;
		const fastestResult = finishedBooks.filter((item) => item.log.readingDays !== null && item.log.readingDays > 0).sort((a, b) => (a.log.readingDays || 999) - (b.log.readingDays || 999)).slice(0, 1);
		const fastestBook = fastestResult[0] ? {
			title: fastestResult[0].book.title,
			days: fastestResult[0].log.readingDays
		} : null;
		const totalReadingDays = finishedBooks.reduce((sum, item) => sum + (item.log.readingDays || 0), 0);
		const favoriteAuthor = (await db.select({
			authorName: authors.name,
			count: sql`COUNT(DISTINCT ${books.bookId})::int`
		}).from(readingLog).innerJoin(books, eq(readingLog.bookId, books.bookId)).innerJoin(bookAuthors, eq(books.bookId, bookAuthors.bookId)).innerJoin(authors, eq(bookAuthors.authorId, authors.authorId)).where(and(eq(readingLog.status, "finished"), sql`EXTRACT(YEAR FROM ${readingLog.dateFinished}) = ${year}`, sql`EXTRACT(MONTH FROM ${readingLog.dateFinished}) = ${month}`)).groupBy(authors.authorId, authors.name).orderBy(desc(sql`COUNT(DISTINCT ${books.bookId})`)).limit(1))[0]?.authorName || null;
		return {
			month: [
				"January",
				"February",
				"March",
				"April",
				"May",
				"June",
				"July",
				"August",
				"September",
				"October",
				"November",
				"December"
			][month - 1],
			year,
			booksFinished,
			pagesRead,
			topGenre,
			topRatedBook,
			fastestBook,
			totalReadingDays,
			favoriteAuthor
		};
	} catch (error) {
		console.error("Error fetching monthly recap:", error);
		return {
			month: "",
			year,
			booksFinished: 0,
			pagesRead: 0,
			topGenre: null,
			topRatedBook: null,
			fastestBook: null,
			totalReadingDays: 0,
			favoriteAuthor: null
		};
	}
});
//#endregion
export { getMonthlyRecapAction_createServerFn_handler };
