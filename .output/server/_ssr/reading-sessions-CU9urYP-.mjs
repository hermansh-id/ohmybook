import { n as createServerFn } from "./ssr.mjs";
import { f as isNull, s as eq, v as or } from "../_libs/drizzle-orm.mjs";
import { c as db, m as readingLog, s as books } from "./db-Byp6WemB.mjs";
import { t as createServerRpc } from "./createServerRpc-A6pJPYTF.mjs";
import { C as updateReadingSession, c as getBookReadingSessions, h as getReadingSessions, i as deleteReadingSession, n as createReadingSession } from "./queries-CGoFn0cR.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/reading-sessions-CU9urYP-.js
var getReadingSessionsAction_createServerFn_handler = createServerRpc({
	id: "7b218efcbe2a3dd853960b5948497bea0c87a427cb21f76557d9829a21a81391",
	name: "getReadingSessionsAction",
	filename: "actions/reading-sessions.ts"
}, (opts) => getReadingSessionsAction.__executeServer(opts));
var getReadingSessionsAction = createServerFn({ method: "POST" }).validator((d) => d).handler(getReadingSessionsAction_createServerFn_handler, async ({ data }) => {
	try {
		return {
			success: true,
			data: await getReadingSessions(data.limit ?? 50)
		};
	} catch (error) {
		console.error("Error fetching reading sessions:", error);
		return {
			success: false,
			error: "Failed to fetch reading sessions"
		};
	}
});
var getBookReadingSessionsAction_createServerFn_handler = createServerRpc({
	id: "5d19854c6c65d6b8c9f9ba4b03fb305faf59c5bad6f5c2eaf254c1bad48eb876",
	name: "getBookReadingSessionsAction",
	filename: "actions/reading-sessions.ts"
}, (opts) => getBookReadingSessionsAction.__executeServer(opts));
var getBookReadingSessionsAction = createServerFn({ method: "POST" }).validator((d) => d).handler(getBookReadingSessionsAction_createServerFn_handler, async ({ data }) => {
	try {
		return {
			success: true,
			data: await getBookReadingSessions(data.bookId)
		};
	} catch (error) {
		console.error("Error fetching book reading sessions:", error);
		return {
			success: false,
			error: "Failed to fetch book reading sessions"
		};
	}
});
var createReadingSessionAction_createServerFn_handler = createServerRpc({
	id: "d212cfcf5d471e6286c41abb64a5dfee3e96fcf4d8ddd06ad55cabb2253eef8d",
	name: "createReadingSessionAction",
	filename: "actions/reading-sessions.ts"
}, (opts) => createReadingSessionAction.__executeServer(opts));
var createReadingSessionAction = createServerFn({ method: "POST" }).validator((d) => d).handler(createReadingSessionAction_createServerFn_handler, async ({ data }) => {
	try {
		const session = await createReadingSession({
			...data,
			sessionDate: new Date(data.sessionDate)
		});
		const [book] = await db.select({
			pages: books.pages,
			title: books.title,
			goodreadsUrl: books.goodreadsUrl
		}).from(books).where(eq(books.bookId, data.bookId)).limit(1);
		if (!book) return {
			success: false,
			error: "Book not found"
		};
		let [log] = await db.select().from(readingLog).where(eq(readingLog.bookId, data.bookId)).limit(1);
		const pagesRead = data.pagesRead || 0;
		const currentPage = (log?.currentPage || 0) + pagesRead;
		const totalPages = book.pages || 0;
		const isCompleted = totalPages > 0 && currentPage >= totalPages;
		if (!log) {
			const newLogData = {
				bookId: data.bookId,
				currentPage: isCompleted ? totalPages : currentPage,
				status: isCompleted ? "finished" : "reading",
				dateStarted: new Date(data.sessionDate)
			};
			if (isCompleted) newLogData.dateFinished = new Date(data.sessionDate);
			[log] = await db.insert(readingLog).values(newLogData).returning();
		} else {
			const updateData = {
				currentPage: isCompleted ? totalPages : currentPage,
				status: isCompleted ? "finished" : log.status === "want_to_read" ? "reading" : log.status,
				dateStarted: log.dateStarted || new Date(data.sessionDate),
				updatedAt: /* @__PURE__ */ new Date()
			};
			if (isCompleted) updateData.dateFinished = new Date(data.sessionDate);
			[log] = await db.update(readingLog).set(updateData).where(eq(readingLog.bookId, data.bookId)).returning();
		}
		return {
			success: true,
			data: session[0],
			bookCompleted: isCompleted,
			bookTitle: book.title,
			goodreadsUrl: book.goodreadsUrl || null
		};
	} catch (error) {
		console.error("Error creating reading session:", error);
		return {
			success: false,
			error: "Failed to create reading session"
		};
	}
});
var updateReadingSessionAction_createServerFn_handler = createServerRpc({
	id: "272174318505e75970f1c607abf95ae70aeb6d1a35929615fed51fba20d9d4e8",
	name: "updateReadingSessionAction",
	filename: "actions/reading-sessions.ts"
}, (opts) => updateReadingSessionAction.__executeServer(opts));
var updateReadingSessionAction = createServerFn({ method: "POST" }).validator((d) => d).handler(updateReadingSessionAction_createServerFn_handler, async ({ data }) => {
	try {
		const { sessionId, ...rest } = data;
		return {
			success: true,
			data: (await updateReadingSession(sessionId, {
				...rest,
				sessionDate: rest.sessionDate ? new Date(rest.sessionDate) : void 0
			}))[0]
		};
	} catch (error) {
		console.error("Error updating reading session:", error);
		return {
			success: false,
			error: "Failed to update reading session"
		};
	}
});
var deleteReadingSessionAction_createServerFn_handler = createServerRpc({
	id: "ecd934a809c0df1df243deaca01561e04806c94eacc82fa2f7d2ddf8bbd93e86",
	name: "deleteReadingSessionAction",
	filename: "actions/reading-sessions.ts"
}, (opts) => deleteReadingSessionAction.__executeServer(opts));
var deleteReadingSessionAction = createServerFn({ method: "POST" }).validator((d) => d).handler(deleteReadingSessionAction_createServerFn_handler, async ({ data }) => {
	try {
		await deleteReadingSession(data.sessionId);
		return { success: true };
	} catch (error) {
		console.error("Error deleting reading session:", error);
		return {
			success: false,
			error: "Failed to delete reading session"
		};
	}
});
var getUnfinishedBooksAction_createServerFn_handler = createServerRpc({
	id: "a1a91c60c4233061b249bc33e3286c07227ffd67e89bed665d67168eec5295ff",
	name: "getUnfinishedBooksAction",
	filename: "actions/reading-sessions.ts"
}, (opts) => getUnfinishedBooksAction.__executeServer(opts));
var getUnfinishedBooksAction = createServerFn({ method: "GET" }).handler(getUnfinishedBooksAction_createServerFn_handler, async () => {
	try {
		return (await db.select({
			bookId: books.bookId,
			title: books.title,
			pages: books.pages,
			status: readingLog.status,
			currentPage: readingLog.currentPage
		}).from(books).leftJoin(readingLog, eq(books.bookId, readingLog.bookId)).where(or(eq(readingLog.status, "reading"), eq(readingLog.status, "want_to_read"), isNull(readingLog.status)))).map((book) => ({
			id: book.bookId,
			title: book.title,
			pages: book.pages || 0,
			currentPage: book.currentPage || 0,
			status: book.status || "want_to_read"
		}));
	} catch (error) {
		console.error("Error fetching unfinished books:", error);
		return [];
	}
});
//#endregion
export { createReadingSessionAction_createServerFn_handler, deleteReadingSessionAction_createServerFn_handler, getBookReadingSessionsAction_createServerFn_handler, getReadingSessionsAction_createServerFn_handler, getUnfinishedBooksAction_createServerFn_handler, updateReadingSessionAction_createServerFn_handler };
