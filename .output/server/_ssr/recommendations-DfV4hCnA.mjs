import { j as require_jsx_runtime } from "../_libs/@radix-ui/react-alert-dialog+[...].mjs";
import { t as Badge } from "./badge-y-Up9thA.mjs";
import { h as Link } from "../_libs/@tanstack/react-router+[...].mjs";
import { c as getReadingRecommendationsAction } from "./books-B1VN5UCC.mjs";
import { J as BookOpen, f as Star } from "../_libs/lucide-react.mjs";
import { t as Skeleton } from "./skeleton-D7Ivmigh.mjs";
import { n as useQuery } from "../_libs/tanstack__react-query.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/recommendations-DfV4hCnA.js
var import_jsx_runtime = require_jsx_runtime();
function RecommendationsPage() {
	const { data: recommendations = [], isLoading } = useQuery({
		queryKey: ["recommendations"],
		queryFn: () => getReadingRecommendationsAction(),
		staleTime: 1e3 * 60 * 10
	});
	if (isLoading) return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "flex-1 space-y-4 p-4 md:p-8 pt-6",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Skeleton, { className: "h-9 w-64" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
			className: "grid gap-4 md:grid-cols-2 lg:grid-cols-3",
			children: [...Array(6)].map((_, i) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Skeleton, { className: "h-36" }, i))
		})]
	});
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "flex-1 space-y-4 p-4 md:p-8 pt-6",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
			className: "flex items-center justify-between",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
				className: "text-3xl font-bold tracking-tight",
				children: "What to Read Next"
			})
		}), recommendations.length === 0 ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "flex flex-col items-center justify-center rounded-lg border border-dashed p-8 text-center min-h-[400px]",
			children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)(BookOpen, { className: "h-12 w-12 text-muted-foreground" }),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
					className: "mt-4 text-lg font-semibold",
					children: "No recommendations yet"
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "text-muted-foreground mt-2 max-w-sm",
					children: "Add unread books to your library to get personalized recommendations"
				})
			]
		}) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
			className: "grid gap-4 md:grid-cols-2 lg:grid-cols-3",
			children: recommendations.map((book, index) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Link, {
				to: "/dashboard/books/$bookId",
				params: { bookId: String(book.id) },
				className: "group",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "rounded-lg border bg-card p-4 hover:bg-accent transition-colors h-full",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "flex gap-4",
						children: [book.coverUrl ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("img", {
							src: book.coverUrl,
							alt: book.title,
							className: "w-16 h-24 object-cover rounded shadow-sm flex-shrink-0"
						}) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
							className: "w-16 h-24 bg-muted rounded flex items-center justify-center flex-shrink-0",
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(BookOpen, { className: "h-6 w-6 text-muted-foreground" })
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "flex-1 min-w-0",
							children: [
								/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
									className: "flex items-start gap-2 mb-1",
									children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Badge, {
										variant: "outline",
										className: "text-xs",
										children: ["#", index + 1]
									}), book.status === "reading" && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Badge, {
										className: "text-xs",
										children: "Reading"
									})]
								}),
								/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
									className: "font-semibold line-clamp-2 group-hover:text-primary transition-colors mb-1",
									children: book.title
								}),
								book.authors.length > 0 && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
									className: "text-sm text-muted-foreground line-clamp-1",
									children: book.authors.map((a) => a.name).join(", ")
								}),
								/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
									className: "flex items-center gap-3 mt-2 text-xs text-muted-foreground",
									children: [book.averageRating && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
										className: "flex items-center gap-1",
										children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Star, { className: "h-3 w-3 fill-yellow-500 text-yellow-500" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", { children: book.averageRating })]
									}), book.pages && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", { children: [book.pages, "p"] })]
								})
							]
						})]
					})
				})
			}, book.id))
		})]
	});
}
//#endregion
export { RecommendationsPage as component };
