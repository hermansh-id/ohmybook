import { n as createServerFn } from "./ssr.mjs";
import { s as eq } from "../_libs/drizzle-orm.mjs";
import { c as db, i as bookAuthors, m as readingLog, p as readingGoals, r as authors, s as books } from "./db-Byp6WemB.mjs";
import { t as createServerRpc } from "./createServerRpc-A6pJPYTF.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/settings-CZ0nIegF.js
var updateReadingGoalAction_createServerFn_handler = createServerRpc({
	id: "8ed6337114281da34d0ce0d7a49d2e34b5c3570a3790adcec3ad26e056ad52ec",
	name: "updateReadingGoalAction",
	filename: "actions/settings.ts"
}, (opts) => updateReadingGoalAction.__executeServer(opts));
var updateReadingGoalAction = createServerFn({ method: "POST" }).validator((d) => d).handler(updateReadingGoalAction_createServerFn_handler, async ({ data }) => {
	try {
		const [existingGoal] = await db.select().from(readingGoals).where(eq(readingGoals.year, data.year)).limit(1);
		if (existingGoal) await db.update(readingGoals).set({
			targetBooks: data.targetBooks,
			targetPages: data.targetPages,
			updatedAt: /* @__PURE__ */ new Date()
		}).where(eq(readingGoals.year, data.year));
		else await db.insert(readingGoals).values({
			year: data.year,
			targetBooks: data.targetBooks,
			targetPages: data.targetPages
		});
		return { success: true };
	} catch (error) {
		console.error("Error updating reading goal:", error);
		return {
			success: false,
			error: "Failed to update reading goal"
		};
	}
});
var exportReadingLogToCsvAction_createServerFn_handler = createServerRpc({
	id: "e544e8af51ce7ff324d5f80698e9ff892a3b4678206664e5857614dde6877d7c",
	name: "exportReadingLogToCsvAction",
	filename: "actions/settings.ts"
}, (opts) => exportReadingLogToCsvAction.__executeServer(opts));
var exportReadingLogToCsvAction = createServerFn({ method: "GET" }).handler(exportReadingLogToCsvAction_createServerFn_handler, async () => {
	try {
		const groupedLogs = (await db.select({
			title: books.title,
			authorName: authors.name,
			isbn: books.isbn,
			pages: books.pages,
			rating: readingLog.rating,
			dateRead: readingLog.dateFinished,
			dateAdded: readingLog.dateAdded,
			status: readingLog.status,
			review: readingLog.review
		}).from(readingLog).innerJoin(books, eq(readingLog.bookId, books.bookId)).leftJoin(bookAuthors, eq(books.bookId, bookAuthors.bookId)).leftJoin(authors, eq(bookAuthors.authorId, authors.authorId)).orderBy(readingLog.dateFinished)).reduce((acc, log) => {
			const existing = acc.find((item) => item.title === log.title);
			if (existing && log.authorName) existing.authorName += `, ${log.authorName}`;
			else acc.push({ ...log });
			return acc;
		}, []);
		const headers = [
			"Title",
			"Author",
			"ISBN",
			"My Rating",
			"Date Read",
			"Date Added",
			"Bookshelves",
			"My Review",
			"Number of Pages"
		];
		const rows = groupedLogs.map((log) => {
			let shelf = "to-read";
			if (log.status === "finished") shelf = "read";
			else if (log.status === "reading") shelf = "currently-reading";
			return [
				`"${log.title || ""}"`,
				`"${log.authorName || ""}"`,
				`"${log.isbn || ""}"`,
				log.rating || "",
				log.dateRead || "",
				log.dateAdded || "",
				shelf,
				`"${(log.review || "").replace(/"/g, "\"\"")}"`,
				log.pages || ""
			];
		});
		return {
			success: true,
			data: [headers.join(","), ...rows.map((row) => row.join(","))].join("\n")
		};
	} catch (error) {
		console.error("Error exporting CSV:", error);
		return {
			success: false,
			error: "Failed to export CSV"
		};
	}
});
var getSettingsDataAction_createServerFn_handler = createServerRpc({
	id: "388d88d5e2acf7ae7390a2a4cfae5c7cf81bb1d3f2dd027da895395fe23ab666",
	name: "getSettingsDataAction",
	filename: "actions/settings.ts"
}, (opts) => getSettingsDataAction.__executeServer(opts));
var getSettingsDataAction = createServerFn({ method: "GET" }).handler(getSettingsDataAction_createServerFn_handler, async () => {
	const { db } = await import("./db-Byp6WemB.mjs").then((n) => n.l).then((n) => n.n);
	const { readingGoals } = await import("./db-Byp6WemB.mjs").then((n) => n.l).then((n) => n.r);
	const { eq } = await import("../_libs/drizzle-orm.mjs").then((n) => n.t);
	const currentYear = (/* @__PURE__ */ new Date()).getFullYear();
	const [goal] = await db.select().from(readingGoals).where(eq(readingGoals.year, currentYear)).limit(1);
	return {
		goal: goal || null,
		currentYear
	};
});
//#endregion
export { exportReadingLogToCsvAction_createServerFn_handler, getSettingsDataAction_createServerFn_handler, updateReadingGoalAction_createServerFn_handler };
