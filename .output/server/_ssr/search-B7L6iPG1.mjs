import { n as createServerFn } from "./ssr.mjs";
import { j as sql, s as eq, u as ilike, v as or } from "../_libs/drizzle-orm.mjs";
import { c as db, i as bookAuthors, m as readingLog, r as authors, s as books } from "./db-Byp6WemB.mjs";
import { t as createServerRpc } from "./createServerRpc-A6pJPYTF.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/search-B7L6iPG1.js
var searchBooksAction_createServerFn_handler = createServerRpc({
	id: "d13d9d99695250c767c71e6bd1236e1649aa9bf9883cf42891e136021443b405",
	name: "searchBooksAction",
	filename: "actions/search.ts"
}, (opts) => searchBooksAction.__executeServer(opts));
var searchBooksAction = createServerFn({ method: "POST" }).validator((d) => d).handler(searchBooksAction_createServerFn_handler, async ({ data }) => {
	try {
		if (!data.query || data.query.trim().length < 2) return [];
		const searchPattern = `%${data.query}%`;
		return await db.select({
			bookId: books.bookId,
			title: books.title,
			isbn: books.isbn,
			pages: books.pages,
			year: books.year,
			authorName: sql`string_agg(DISTINCT ${authors.name}, ', ')`,
			status: readingLog.status
		}).from(books).leftJoin(bookAuthors, eq(books.bookId, bookAuthors.bookId)).leftJoin(authors, eq(bookAuthors.authorId, authors.authorId)).leftJoin(readingLog, eq(books.bookId, readingLog.bookId)).where(or(ilike(books.title, searchPattern), ilike(books.isbn, searchPattern), ilike(authors.name, searchPattern))).groupBy(books.bookId, readingLog.status).limit(10);
	} catch (error) {
		console.error("Error searching books:", error);
		return [];
	}
});
//#endregion
export { searchBooksAction_createServerFn_handler };
