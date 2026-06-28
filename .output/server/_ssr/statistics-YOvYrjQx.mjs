import { n as createServerFn } from "./ssr.mjs";
import { t as createServerRpc } from "./createServerRpc-A6pJPYTF.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/statistics-YOvYrjQx.js
var getStatisticsDataAction_createServerFn_handler = createServerRpc({
	id: "696a6f6d36029880bba2fe11f38dc95c298e06ed23bfd11c6c097f8a0e9dc555",
	name: "getStatisticsDataAction",
	filename: "actions/statistics.ts"
}, (opts) => getStatisticsDataAction.__executeServer(opts));
var getStatisticsDataAction = createServerFn({ method: "GET" }).handler(getStatisticsDataAction_createServerFn_handler, async () => {
	const { getReadingStats, getCurrentYearGoal, getMonthlyStats, getAuthorsWithStats, getGenresWithStats, getReadingSessions, getLibraryStats, getLibraryCompletion, getReadingStreaks, getTopRatedBooks, getQuoteStats, getReadingHistory, getYearlyStats } = await import("./queries-CGoFn0cR.mjs").then((n) => n.b);
	const [stats, goal, monthlyStats, authors, genres, sessions, libraryStats, libraryCompletion, streaks, topRated, quoteStats, readingHistory, yearlyStats] = await Promise.all([
		getReadingStats(),
		getCurrentYearGoal(),
		getMonthlyStats((/* @__PURE__ */ new Date()).getFullYear()),
		getAuthorsWithStats(),
		getGenresWithStats(),
		getReadingSessions(500),
		getLibraryStats(),
		getLibraryCompletion(),
		getReadingStreaks(),
		getTopRatedBooks(10),
		getQuoteStats(),
		getReadingHistory(24),
		getYearlyStats()
	]);
	return {
		stats,
		goal,
		monthlyStats,
		authors,
		genres,
		sessions,
		libraryStats,
		libraryCompletion,
		streaks,
		topRated,
		quoteStats,
		readingHistory,
		yearlyStats
	};
});
//#endregion
export { getStatisticsDataAction_createServerFn_handler };
