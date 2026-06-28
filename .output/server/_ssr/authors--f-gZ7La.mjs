import { n as createServerFn } from "./ssr.mjs";
import { c as db, r as authors } from "./db-Byp6WemB.mjs";
import { t as createServerRpc } from "./createServerRpc-A6pJPYTF.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/authors--f-gZ7La.js
var addAuthor_createServerFn_handler = createServerRpc({
	id: "9a03d43cf1f7201da32f130d08605e61c2f3187415ec98af61e9e8a161620e1b",
	name: "addAuthor",
	filename: "actions/authors.ts"
}, (opts) => addAuthor.__executeServer(opts));
var addAuthor = createServerFn({ method: "POST" }).validator((d) => d).handler(addAuthor_createServerFn_handler, async ({ data }) => {
	try {
		const [author] = await db.insert(authors).values({
			name: data.name,
			bio: data.bio || null
		}).onConflictDoUpdate({
			target: authors.name,
			set: { name: authors.name }
		}).returning();
		return {
			success: true,
			author
		};
	} catch (error) {
		console.error("Error adding author:", error);
		return {
			success: false,
			error: "Failed to add author"
		};
	}
});
var getAuthorsWithStatsAction_createServerFn_handler = createServerRpc({
	id: "135805530c9e9062a7fa69e30dc674290514d842344e6d4d291143519a35822e",
	name: "getAuthorsWithStatsAction",
	filename: "actions/authors.ts"
}, (opts) => getAuthorsWithStatsAction.__executeServer(opts));
var getAuthorsWithStatsAction = createServerFn({ method: "GET" }).handler(getAuthorsWithStatsAction_createServerFn_handler, async () => {
	const { getAuthorsWithStats } = await import("./queries-CGoFn0cR.mjs").then((n) => n.b);
	return getAuthorsWithStats();
});
//#endregion
export { addAuthor_createServerFn_handler, getAuthorsWithStatsAction_createServerFn_handler };
