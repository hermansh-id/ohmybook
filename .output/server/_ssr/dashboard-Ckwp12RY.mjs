import { n as createServerFn } from "./ssr.mjs";
import { t as createServerRpc } from "./createServerRpc-A6pJPYTF.mjs";
import { i as getUnfinishedBooksAction } from "./reading-sessions-DGduYzP1.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/dashboard-Ckwp12RY.js
var getDashboardDataAction_createServerFn_handler = createServerRpc({
	id: "e88e2b677ff9038f1b2447f05172258080dbdfa3122214d38a3653e5d392d63b",
	name: "getDashboardDataAction",
	filename: "actions/dashboard.ts"
}, (opts) => getDashboardDataAction.__executeServer(opts));
var getDashboardDataAction = createServerFn({ method: "GET" }).handler(getDashboardDataAction_createServerFn_handler, async () => {
	const { getReadingStats, getCurrentYearGoal, getMonthlyStats, getFinishedBooks, getCurrentlyReadingBooks, getReadingSessions, getReadingHistory, getLibraryCompletion, getDailyReadingActivity, getReadingStreaks } = await import("./queries-CGoFn0cR.mjs").then((n) => n.b);
	const [stats, goal, monthlyStats, recentBooksData, currentlyReading, recentSessions, readingHistory, libraryCompletion, dailyActivity, streaks, unfinishedBooks] = await Promise.all([
		getReadingStats(),
		getCurrentYearGoal(),
		getMonthlyStats((/* @__PURE__ */ new Date()).getFullYear()),
		getFinishedBooks(5),
		getCurrentlyReadingBooks(),
		getReadingSessions(10),
		getReadingHistory(12),
		getLibraryCompletion(),
		getDailyReadingActivity(),
		getReadingStreaks(),
		getUnfinishedBooksAction()
	]);
	return {
		stats,
		goal,
		monthlyStats,
		recentBooksData,
		currentlyReading,
		recentSessions,
		readingHistory,
		libraryCompletion,
		dailyActivity,
		streaks,
		unfinishedBooks
	};
});
//#endregion
export { getDashboardDataAction_createServerFn_handler };
