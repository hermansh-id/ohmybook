import { n as createServerFn } from "./ssr.mjs";
import { c as db, u as genres } from "./db-Byp6WemB.mjs";
import { t as createServerRpc } from "./createServerRpc-A6pJPYTF.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/genres-wlmuRDuj.js
var getGenresAction_createServerFn_handler = createServerRpc({
	id: "600b96fe6bc263f507bb4e51b8c075cf8f2e48a9187c9a11c7b53763f7f15193",
	name: "getGenresAction",
	filename: "actions/genres.ts"
}, (opts) => getGenresAction.__executeServer(opts));
var getGenresAction = createServerFn({ method: "GET" }).handler(getGenresAction_createServerFn_handler, async () => {
	try {
		return await db.select({
			genreId: genres.genreId,
			genreName: genres.genreName
		}).from(genres).orderBy(genres.genreName);
	} catch (error) {
		console.error("Error fetching genres:", error);
		return [];
	}
});
var addGenre_createServerFn_handler = createServerRpc({
	id: "b6aec75738ca1669be65b3d0f67ffe736a5c36811a9dc9faab788289ac9d6b61",
	name: "addGenre",
	filename: "actions/genres.ts"
}, (opts) => addGenre.__executeServer(opts));
var addGenre = createServerFn({ method: "POST" }).validator((d) => d).handler(addGenre_createServerFn_handler, async ({ data }) => {
	try {
		const [genre] = await db.insert(genres).values({
			genreName: data.genreName,
			description: data.description || null
		}).returning();
		return {
			success: true,
			genre
		};
	} catch (error) {
		console.error("Error adding genre:", error);
		return {
			success: false,
			error: "Failed to add genre"
		};
	}
});
var getGenresWithStatsAction_createServerFn_handler = createServerRpc({
	id: "d122679c877b5eff4dc661a1f67cbb4741a21118c8425755ead1d88e971adab3",
	name: "getGenresWithStatsAction",
	filename: "actions/genres.ts"
}, (opts) => getGenresWithStatsAction.__executeServer(opts));
var getGenresWithStatsAction = createServerFn({ method: "GET" }).handler(getGenresWithStatsAction_createServerFn_handler, async () => {
	const { getGenresWithStats } = await import("./queries-CGoFn0cR.mjs").then((n) => n.b);
	return getGenresWithStats();
});
//#endregion
export { addGenre_createServerFn_handler, getGenresAction_createServerFn_handler, getGenresWithStatsAction_createServerFn_handler };
