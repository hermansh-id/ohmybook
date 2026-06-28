import { o as __toESM } from "../_runtime.mjs";
import { u as require_react } from "../_libs/@floating-ui/react-dom+[...].mjs";
import { j as require_jsx_runtime } from "../_libs/@radix-ui/react-alert-dialog+[...].mjs";
import { c as HeadContent, d as Outlet, f as lazyRouteComponent, m as createRootRoute, p as createFileRoute, s as Scripts, u as createRouter } from "../_libs/@tanstack/react-router+[...].mjs";
import { t as Route$16 } from "../_bookId-C7OasE3q.mjs";
import { Bt as string, It as number, Lt as object, Pt as literal } from "../_libs/@better-auth/core+[...].mjs";
import { t as QueryClient } from "../_libs/tanstack__query-core.mjs";
import { r as QueryClientProvider } from "../_libs/tanstack__react-query.mjs";
import { _ as getReadingStreaks, d as getLibraryCompletion, f as getLibraryStats, g as getReadingStats, h as getReadingSessions, l as getCurrentYearGoal, m as getQuoteStats, o as getAuthorsWithStats, p as getMonthlyStats, u as getGenresWithStats, v as getTopRatedBooks, y as getYearlyStats } from "./queries-CGoFn0cR.mjs";
import { t as Toaster } from "../_libs/sonner.mjs";
import { t as auth } from "./auth-CxVFL592.mjs";
import { t as Route$17 } from "./dashboard-C6y-StmE.mjs";
import { t as J } from "../_libs/next-themes.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/router-30O1dbHh.js
var import_react = /* @__PURE__ */ __toESM(require_react());
var import_jsx_runtime = require_jsx_runtime();
function QueryProvider({ children }) {
	const [queryClient] = (0, import_react.useState)(() => new QueryClient({ defaultOptions: { queries: {
		staleTime: 60 * 1e3,
		refetchOnWindowFocus: false
	} } }));
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(QueryClientProvider, {
		client: queryClient,
		children
	});
}
function ThemeProvider$1({ children, ...props }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(J, {
		...props,
		children
	});
}
var globals_default = "/assets/globals-BQl_4yUe.css";
var Route$15 = createRootRoute({
	head: () => ({
		meta: [
			{ charSet: "utf-8" },
			{
				name: "viewport",
				content: "width=device-width, initial-scale=1"
			},
			{ title: "Bookjet - Reading Tracker" },
			{
				name: "description",
				content: "Track your reading journey"
			}
		],
		links: [{
			rel: "stylesheet",
			href: globals_default
		}]
	}),
	component: RootLayout
});
function RootLayout() {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("html", {
		lang: "en",
		suppressHydrationWarning: true,
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("head", { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(HeadContent, {}) }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("body", {
			className: "antialiased",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(ThemeProvider$1, {
				attribute: "class",
				defaultTheme: "system",
				enableSystem: true,
				disableTransitionOnChange: true,
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(QueryProvider, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Outlet, {}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Toaster, {
					richColors: true,
					position: "top-right"
				})] })
			}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Scripts, {})]
		})]
	});
}
var $$splitComponentImporter$12 = () => import("./login-BdxWX0zi.mjs");
var Route$14 = createFileRoute("/login")({ component: lazyRouteComponent($$splitComponentImporter$12, "component") });
var $$splitComponentImporter$11 = () => import("./app-KRCu2Eyr.mjs");
var Route$13 = createFileRoute("/")({ component: lazyRouteComponent($$splitComponentImporter$11, "component") });
var $$splitComponentImporter$10 = () => import("./dashboard-3QJ5z0dZ.mjs");
var Route$12 = createFileRoute("/dashboard/")({ component: lazyRouteComponent($$splitComponentImporter$10, "component") });
var $$splitComponentImporter$9 = () => import("./statistics-BzNzmzJL.mjs");
var Route$11 = createFileRoute("/dashboard/statistics/")({ component: lazyRouteComponent($$splitComponentImporter$9, "component") });
var $$splitComponentImporter$8 = () => import("./settings-CcfzfMDW.mjs");
var Route$10 = createFileRoute("/dashboard/settings/")({ component: lazyRouteComponent($$splitComponentImporter$8, "component") });
var $$splitComponentImporter$7 = () => import("./recommendations-DfV4hCnA.mjs");
var Route$9 = createFileRoute("/dashboard/recommendations/")({ component: lazyRouteComponent($$splitComponentImporter$7, "component") });
var $$splitComponentImporter$6 = () => import("./reading-log-Dvv_LEfe.mjs");
var Route$8 = createFileRoute("/dashboard/reading-log/")({ component: lazyRouteComponent($$splitComponentImporter$6, "component") });
var $$splitComponentImporter$5 = () => import("./quotes-Cfdtwhqt.mjs");
var Route$7 = createFileRoute("/dashboard/quotes/")({ component: lazyRouteComponent($$splitComponentImporter$5, "component") });
var $$splitComponentImporter$4 = () => import("./genres-BJVuL5np.mjs");
var Route$6 = createFileRoute("/dashboard/genres/")({ component: lazyRouteComponent($$splitComponentImporter$4, "component") });
var $$splitComponentImporter$3 = () => import("./calendar-CsARRILI.mjs");
var Route$5 = createFileRoute("/dashboard/calendar/")({ component: lazyRouteComponent($$splitComponentImporter$3, "component") });
var $$splitComponentImporter$2 = () => import("./books-DzNYsrB6.mjs");
var Route$4 = createFileRoute("/dashboard/books/")({ component: lazyRouteComponent($$splitComponentImporter$2, "component") });
var $$splitComponentImporter$1 = () => import("./authors-CbXpS8zS.mjs");
var Route$3 = createFileRoute("/dashboard/authors/")({ component: lazyRouteComponent($$splitComponentImporter$1, "component") });
var $$splitComponentImporter = () => import("./add-VOzFFSdL.mjs");
var Route$2 = createFileRoute("/dashboard/books/add")({ component: lazyRouteComponent($$splitComponentImporter, "component") });
object({
	title: string().min(1, "Title is required"),
	isbn: string().optional(),
	goodreadsUrl: string().url("Must be a valid URL").optional().or(literal("")),
	year: number().int().min(1e3).max(9999).optional().nullable(),
	pages: number().int().min(1).optional().nullable()
});
var MONTH_NAMES = [
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
];
var Route$1 = createFileRoute("/api/stats/markdown")({ server: { handlers: { GET: async () => {
	try {
		const [stats, goal, monthlyStats, authors, genres, sessions, libraryStats, libraryCompletion, streaks, topRated, quoteStats, yearlyStats] = await Promise.all([
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
			getYearlyStats()
		]);
		const readingStats = stats[0] || {
			totalBooksRead: 0,
			totalPagesRead: 0,
			totalBooksReading: 0,
			totalBooksWantToRead: 0,
			averageRating: 0,
			booksReadThisYear: 0,
			booksReadThisMonth: 0,
			pagesReadThisYear: 0,
			pagesReadThisMonth: 0
		};
		const yearGoal = goal[0] || {
			targetBooks: 52,
			currentBooks: 0
		};
		const totalReadingMinutes = sessions.reduce((sum, s) => sum + (s.session.minutesRead || 0), 0);
		const totalPagesFromSessions = sessions.reduce((sum, s) => sum + (s.session.pagesRead || 0), 0);
		const avgPagesPerSession = sessions.length > 0 ? Math.round(totalPagesFromSessions / sessions.length) : 0;
		const topAuthors = authors.filter((a) => a.booksRead > 0).sort((a, b) => b.booksRead - a.booksRead).slice(0, 10);
		const topGenres = genres.filter((g) => g.booksRead > 0).sort((a, b) => b.booksRead - a.booksRead).slice(0, 10);
		const targetBooks = yearGoal.targetBooks ?? 52;
		const currentBooks = yearGoal.currentBooks ?? 0;
		const goalProgress = targetBooks > 0 ? currentBooks / targetBooks * 100 : 0;
		const currentYear = (/* @__PURE__ */ new Date()).getFullYear();
		const now = /* @__PURE__ */ new Date();
		const allYears = yearlyStats.sort((a, b) => b.year - a.year);
		const readingHours = Math.floor(totalReadingMinutes / 60);
		const readingMins = totalReadingMinutes % 60;
		const lines = [];
		lines.push(`# Bookjet Reading Statistics`);
		lines.push(`> Generated on ${now.toLocaleDateString("en-US", {
			weekday: "long",
			year: "numeric",
			month: "long",
			day: "numeric"
		})}`);
		lines.push(``);
		lines.push(`## 🔥 Reading Streaks`);
		lines.push(``);
		lines.push(`| Metric | Value |`);
		lines.push(`|--------|-------|`);
		lines.push(`| Current Streak | ${streaks.currentStreak} days |`);
		lines.push(`| Best Streak | ${streaks.bestStreak} days |`);
		lines.push(`| Total Reading Days | ${streaks.totalReadingDays} days |`);
		lines.push(``);
		lines.push(`## 📚 Library Overview`);
		lines.push(``);
		lines.push(`| Metric | Value |`);
		lines.push(`|--------|-------|`);
		lines.push(`| Total Books in Library | ${libraryStats.totalBooks.toLocaleString()} |`);
		lines.push(`| Unique Authors | ${libraryStats.totalAuthors.toLocaleString()} |`);
		lines.push(`| Unique Genres | ${libraryStats.totalGenres.toLocaleString()} |`);
		lines.push(`| Total Pages in Library | ${libraryStats.totalPages.toLocaleString()} |`);
		lines.push(`| Average Pages per Book | ${libraryStats.avgPages.toLocaleString()} |`);
		lines.push(`| Books Read | ${libraryCompletion.booksRead} / ${libraryCompletion.totalBooks} (${libraryCompletion.percentage}%) |`);
		if (libraryCompletion.estimatedCompletionMonths != null) lines.push(`| Estimated Months to Complete Library | ${libraryCompletion.estimatedCompletionMonths} months |`);
		lines.push(``);
		lines.push(`## 📊 Overall Reading Stats`);
		lines.push(``);
		lines.push(`| Metric | Value |`);
		lines.push(`|--------|-------|`);
		lines.push(`| Books Read (All Time) | ${readingStats.totalBooksRead} |`);
		lines.push(`| Pages Read (All Time) | ${Number(readingStats.totalPagesRead).toLocaleString()} |`);
		lines.push(`| Average Rating | ${readingStats.averageRating ? Number(readingStats.averageRating).toFixed(2) : "N/A"} |`);
		lines.push(`| Total Reading Time | ${readingHours}h ${readingMins}m |`);
		lines.push(`| Reading Sessions Logged | ${sessions.length} |`);
		lines.push(`| Avg Pages per Session | ${avgPagesPerSession} |`);
		lines.push(``);
		lines.push(`## 📖 Current Status`);
		lines.push(``);
		lines.push(`| Status | Count |`);
		lines.push(`|--------|-------|`);
		lines.push(`| Currently Reading | ${readingStats.totalBooksReading} |`);
		lines.push(`| Want to Read | ${readingStats.totalBooksWantToRead} |`);
		lines.push(``);
		lines.push(`## 🎯 ${currentYear} Reading Goal`);
		lines.push(``);
		lines.push(`| Metric | Value |`);
		lines.push(`|--------|-------|`);
		lines.push(`| Target | ${targetBooks} books |`);
		lines.push(`| Progress | ${currentBooks} books |`);
		lines.push(`| Completion | ${goalProgress.toFixed(1)}% |`);
		lines.push(`| Status | ${goalProgress >= 100 ? "✅ Goal achieved!" : goalProgress >= 75 ? "🟡 Almost there" : goalProgress >= 50 ? "🔵 On track" : "🔴 Behind"} |`);
		lines.push(``);
		lines.push(`## 📅 This Year (${currentYear})`);
		lines.push(``);
		lines.push(`| Metric | Value |`);
		lines.push(`|--------|-------|`);
		lines.push(`| Books Read | ${readingStats.booksReadThisYear} |`);
		lines.push(`| Pages Read | ${Number(readingStats.pagesReadThisYear).toLocaleString()} |`);
		lines.push(`| Avg Books/Month | ${((readingStats.booksReadThisYear ?? 0) / Math.max(now.getMonth() + 1, 1)).toFixed(1)} |`);
		lines.push(``);
		lines.push(`## 📅 This Month (${MONTH_NAMES[now.getMonth()]} ${currentYear})`);
		lines.push(``);
		lines.push(`| Metric | Value |`);
		lines.push(`|--------|-------|`);
		lines.push(`| Books Read | ${readingStats.booksReadThisMonth} |`);
		lines.push(`| Pages Read | ${Number(readingStats.pagesReadThisMonth).toLocaleString()} |`);
		lines.push(``);
		if (monthlyStats.length > 0) {
			lines.push(`## 📆 ${currentYear} — Month by Month`);
			lines.push(``);
			lines.push(`| Month | Books | Pages |`);
			lines.push(`|-------|------:|------:|`);
			for (const m of monthlyStats) lines.push(`| ${MONTH_NAMES[(m.month || 1) - 1]} | ${m.booksRead || 0} | ${(m.pagesRead || 0).toLocaleString()} |`);
			const totalBooks = monthlyStats.reduce((s, m) => s + (m.booksRead || 0), 0);
			const totalPages = monthlyStats.reduce((s, m) => s + (m.pagesRead || 0), 0);
			lines.push(`| **Total** | **${totalBooks}** | **${totalPages.toLocaleString()}** |`);
			lines.push(``);
		}
		if (allYears.length > 0) {
			lines.push(`## 📈 Year over Year`);
			lines.push(``);
			lines.push(`| Year | Books | Pages |`);
			lines.push(`|------|------:|------:|`);
			for (const y of allYears) lines.push(`| ${y.year} | ${y.booksRead || 0} | ${(y.pagesRead || 0).toLocaleString()} |`);
			lines.push(``);
		}
		if (topRated.length > 0) {
			lines.push(`## ⭐ Top Rated Books`);
			lines.push(``);
			lines.push(`| # | Title | Author(s) | Rating |`);
			lines.push(`|---|-------|-----------|-------:|`);
			topRated.forEach((item, index) => {
				lines.push(`| ${index + 1} | ${item.book.title} | ${item.authors || "—"} | ★ ${item.log.rating} |`);
			});
			lines.push(``);
		}
		if (topAuthors.length > 0) {
			lines.push(`## 👤 Top Authors`);
			lines.push(``);
			lines.push(`| # | Author | In Library | Books Read | Avg Rating |`);
			lines.push(`|---|--------|------------|------------|------------|`);
			topAuthors.forEach((author, index) => {
				lines.push(`| ${index + 1} | ${author.author.name} | ${author.totalBooks} | ${author.booksRead} | ${author.averageRating ? `★ ${Number(author.averageRating).toFixed(1)}` : "—"} |`);
			});
			lines.push(``);
		}
		if (topGenres.length > 0) {
			lines.push(`## 🏷️ Top Genres`);
			lines.push(``);
			lines.push(`| # | Genre | In Library | Books Read | Avg Rating |`);
			lines.push(`|---|-------|------------|------------|------------|`);
			topGenres.forEach((genre, index) => {
				lines.push(`| ${index + 1} | ${genre.genre.genreName} | ${genre.totalBooks} | ${genre.booksRead} | ${genre.averageRating ? `★ ${Number(genre.averageRating).toFixed(1)}` : "—"} |`);
			});
			lines.push(``);
		}
		lines.push(`## 💬 Quotes & Highlights`);
		lines.push(``);
		lines.push(`| Metric | Value |`);
		lines.push(`|--------|-------|`);
		lines.push(`| Total Quotes Saved | ${quoteStats.totalQuotes} |`);
		lines.push(`| Favorite Quotes | ${quoteStats.favoriteQuotes} |`);
		lines.push(`| Books with Quotes | ${quoteStats.booksWithQuotes} |`);
		lines.push(``);
		lines.push(`---`);
		lines.push(`*Data from [Bookjet](https://bookjet.app) — your personal reading tracker*`);
		return new Response(lines.join("\n"), {
			status: 200,
			headers: {
				"Content-Type": "text/markdown; charset=utf-8",
				"Cache-Control": "no-store"
			}
		});
	} catch (error) {
		console.error("Stats markdown error:", error);
		return new Response("Failed to generate statistics", { status: 500 });
	}
} } } });
var Route = createFileRoute("/api/auth/$")({ server: { handlers: {
	GET: async ({ request }) => auth.handler(request),
	POST: async ({ request }) => auth.handler(request)
} } });
var LoginRoute = Route$14.update({
	id: "/login",
	path: "/login",
	getParentRoute: () => Route$15
});
var DashboardRoute = Route$17.update({
	id: "/dashboard",
	path: "/dashboard",
	getParentRoute: () => Route$15
});
var IndexRoute = Route$13.update({
	id: "/",
	path: "/",
	getParentRoute: () => Route$15
});
var DashboardIndexRoute = Route$12.update({
	id: "/",
	path: "/",
	getParentRoute: () => DashboardRoute
});
var DashboardStatisticsIndexRoute = Route$11.update({
	id: "/statistics/",
	path: "/statistics/",
	getParentRoute: () => DashboardRoute
});
var DashboardSettingsIndexRoute = Route$10.update({
	id: "/settings/",
	path: "/settings/",
	getParentRoute: () => DashboardRoute
});
var DashboardRecommendationsIndexRoute = Route$9.update({
	id: "/recommendations/",
	path: "/recommendations/",
	getParentRoute: () => DashboardRoute
});
var DashboardReadingLogIndexRoute = Route$8.update({
	id: "/reading-log/",
	path: "/reading-log/",
	getParentRoute: () => DashboardRoute
});
var DashboardQuotesIndexRoute = Route$7.update({
	id: "/quotes/",
	path: "/quotes/",
	getParentRoute: () => DashboardRoute
});
var DashboardGenresIndexRoute = Route$6.update({
	id: "/genres/",
	path: "/genres/",
	getParentRoute: () => DashboardRoute
});
var DashboardCalendarIndexRoute = Route$5.update({
	id: "/calendar/",
	path: "/calendar/",
	getParentRoute: () => DashboardRoute
});
var DashboardBooksIndexRoute = Route$4.update({
	id: "/books/",
	path: "/books/",
	getParentRoute: () => DashboardRoute
});
var DashboardAuthorsIndexRoute = Route$3.update({
	id: "/authors/",
	path: "/authors/",
	getParentRoute: () => DashboardRoute
});
var DashboardBooksAddRoute = Route$2.update({
	id: "/books/add",
	path: "/books/add",
	getParentRoute: () => DashboardRoute
});
var DashboardBooksBookIdRoute = Route$16.update({
	id: "/books/$bookId",
	path: "/books/$bookId",
	getParentRoute: () => DashboardRoute
});
var ApiStatsMarkdownRoute = Route$1.update({
	id: "/api/stats/markdown",
	path: "/api/stats/markdown",
	getParentRoute: () => Route$15
});
var ApiAuthSplatRoute = Route.update({
	id: "/api/auth/$",
	path: "/api/auth/$",
	getParentRoute: () => Route$15
});
var DashboardRouteChildren = {
	DashboardIndexRoute,
	DashboardBooksBookIdRoute,
	DashboardBooksAddRoute,
	DashboardAuthorsIndexRoute,
	DashboardBooksIndexRoute,
	DashboardCalendarIndexRoute,
	DashboardGenresIndexRoute,
	DashboardQuotesIndexRoute,
	DashboardReadingLogIndexRoute,
	DashboardRecommendationsIndexRoute,
	DashboardSettingsIndexRoute,
	DashboardStatisticsIndexRoute
};
var rootRouteChildren = {
	IndexRoute,
	DashboardRoute: DashboardRoute._addFileChildren(DashboardRouteChildren),
	LoginRoute,
	ApiAuthSplatRoute,
	ApiStatsMarkdownRoute
};
var routeTree = Route$15._addFileChildren(rootRouteChildren)._addFileTypes();
function getRouter() {
	return createRouter({
		routeTree,
		scrollRestoration: true
	});
}
//#endregion
export { getRouter };
