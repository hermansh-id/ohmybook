import { o as __toESM } from "../_runtime.mjs";
import { u as require_react } from "../_libs/@floating-ui/react-dom+[...].mjs";
import { j as require_jsx_runtime } from "../_libs/@radix-ui/react-alert-dialog+[...].mjs";
import { t as Button } from "./button-PkU2hkqt.mjs";
import { t as Badge } from "./badge-y-Up9thA.mjs";
import { a as CardHeader, o as CardTitle, r as CardContent, t as Card } from "./card-BxgehY3N.mjs";
import { h as Link } from "../_libs/@tanstack/react-router+[...].mjs";
import { n as createServerFn } from "./ssr.mjs";
import { t as createSsrRpc } from "./createSsrRpc-C1p7zOu_.mjs";
import { H as ChevronLeft, J as BookOpen, P as ExternalLink, V as ChevronRight } from "../_libs/lucide-react.mjs";
import { t as Skeleton } from "./skeleton-D7Ivmigh.mjs";
import { n as useQuery } from "../_libs/tanstack__react-query.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/calendar-CsARRILI.js
var import_react = /* @__PURE__ */ __toESM(require_react());
var import_jsx_runtime = require_jsx_runtime();
var getCalendarDataAction = createServerFn({ method: "GET" }).validator((d) => d).handler(createSsrRpc("6c42d6417d44c4d66474a8d327f5ffa4b56a883088d443640616c585d6a3861b"));
var calendarQueryKey = (year, month) => [
	"calendar",
	year,
	month
];
function useCalendar(year, month) {
	return useQuery({
		queryKey: calendarQueryKey(year, month),
		queryFn: () => getCalendarDataAction({ data: {
			year,
			month
		} }),
		staleTime: 1e3 * 60 * 5
	});
}
function CalendarClient() {
	const now = /* @__PURE__ */ new Date();
	const [year, setYear] = (0, import_react.useState)(now.getFullYear());
	const [month, setMonth] = (0, import_react.useState)(now.getMonth() + 1);
	const [selectedDate, setSelectedDate] = (0, import_react.useState)();
	const { data, isLoading } = useCalendar(year, month);
	const books = data?.books ?? [];
	const currentDate = new Date(year, month - 1);
	const booksByDate = (0, import_react.useMemo)(() => {
		const grouped = /* @__PURE__ */ new Map();
		books.forEach((book) => {
			if (book.log.dateFinished) {
				const dateKey = new Date(book.log.dateFinished).toISOString().split("T")[0];
				if (!grouped.has(dateKey)) grouped.set(dateKey, []);
				grouped.get(dateKey).push(book);
			}
		});
		return grouped;
	}, [books]);
	const selectedBooks = (0, import_react.useMemo)(() => {
		if (!selectedDate) return [];
		const dateKey = selectedDate.toISOString().split("T")[0];
		return booksByDate.get(dateKey) || [];
	}, [selectedDate, booksByDate]);
	const daysInMonth = (0, import_react.useMemo)(() => {
		const lastDay = new Date(year, month, 0);
		const days = [];
		for (let d = 1; d <= lastDay.getDate(); d++) {
			const date = new Date(year, month - 1, d);
			const dateKey = date.toISOString().split("T")[0];
			const booksCount = booksByDate.get(dateKey)?.length || 0;
			days.push({
				date,
				day: d,
				dateKey,
				booksCount,
				isToday: date.toDateString() === (/* @__PURE__ */ new Date()).toDateString(),
				isSelected: selectedDate?.toDateString() === date.toDateString()
			});
		}
		return days;
	}, [
		year,
		month,
		booksByDate,
		selectedDate
	]);
	const handleMonthChange = (increment) => {
		const newDate = new Date(year, month - 1 + increment);
		setYear(newDate.getFullYear());
		setMonth(newDate.getMonth() + 1);
		setSelectedDate(void 0);
	};
	if (isLoading) return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "flex flex-col gap-4 p-4 md:gap-6 md:p-6",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "space-y-2",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Skeleton, { className: "h-9 w-64" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Skeleton, { className: "h-4 w-48" })]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "grid grid-cols-2 gap-4 md:grid-cols-4",
				children: Array.from({ length: 4 }).map((_, i) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Card, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(CardContent, {
					className: "pt-6",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Skeleton, { className: "h-4 w-24 mb-2" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Skeleton, { className: "h-8 w-16" })]
				}) }, i))
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Card, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, {
				className: "pt-6",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Skeleton, { className: "h-64 w-full" })
			}) })
		]
	});
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "flex flex-col gap-4 p-4 md:gap-6 md:p-6",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h1", {
				className: "text-3xl font-bold tracking-tight",
				children: "Reading Calendar"
			}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
				className: "text-muted-foreground",
				children: "Track your finished books by date"
			})] }),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "grid grid-cols-2 gap-4 md:grid-cols-4",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Card, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, {
						className: "pt-6",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "space-y-1",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "text-sm text-muted-foreground",
								children: "Books Finished"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "text-2xl font-bold",
								children: books.length
							})]
						})
					}) }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Card, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, {
						className: "pt-6",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "space-y-1",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "text-sm text-muted-foreground",
								children: "Total Pages"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "text-2xl font-bold",
								children: books.reduce((sum, book) => sum + (book.book.pages || 0), 0)
							})]
						})
					}) }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Card, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, {
						className: "pt-6",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "space-y-1",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "text-sm text-muted-foreground",
								children: "Average Rating"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "text-2xl font-bold",
								children: books.filter((b) => b.log.rating).length > 0 ? (books.reduce((sum, book) => sum + (book.log.rating || 0), 0) / books.filter((b) => b.log.rating).length).toFixed(1) : "N/A"
							})]
						})
					}) }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Card, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, {
						className: "pt-6",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "space-y-1",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "text-sm text-muted-foreground",
								children: "Days Reading"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "text-2xl font-bold",
								children: booksByDate.size
							})]
						})
					}) })
				]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Card, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardHeader, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex items-center justify-between",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardTitle, { children: currentDate.toLocaleDateString("en-US", {
					month: "long",
					year: "numeric"
				}) }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "flex gap-2",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
						variant: "outline",
						size: "icon",
						onClick: () => handleMonthChange(-1),
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ChevronLeft, { className: "h-4 w-4" })
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
						variant: "outline",
						size: "icon",
						onClick: () => handleMonthChange(1),
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ChevronRight, { className: "h-4 w-4" })
					})]
				})]
			}) }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(CardContent, { children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "grid grid-cols-7 gap-1.5 mb-1.5 text-center text-xs font-medium text-muted-foreground",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { children: "Sun" }),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { children: "Mon" }),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { children: "Tue" }),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { children: "Wed" }),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { children: "Thu" }),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { children: "Fri" }),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { children: "Sat" })
					]
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "grid grid-cols-7 gap-1.5",
					children: [Array.from({ length: new Date(year, month - 1, 1).getDay() }).map((_, i) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "h-12" }, `empty-${i}`)), daysInMonth.map((dayInfo) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
						onClick: () => setSelectedDate(dayInfo.date),
						className: `
                  h-12 rounded-md border-2 p-1 text-xs font-medium transition-all
                  hover:shadow-md hover:scale-105
                  ${dayInfo.isSelected ? "border-primary bg-primary text-primary-foreground shadow-lg scale-105" : dayInfo.booksCount > 0 ? "border-green-500 bg-green-50 dark:bg-green-950 text-green-900 dark:text-green-100" : dayInfo.isToday ? "border-blue-500 bg-blue-50 dark:bg-blue-950" : "border-border hover:border-muted-foreground"}
                `,
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "flex flex-col items-center justify-center h-full",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "text-sm leading-none",
								children: dayInfo.day
							}), dayInfo.booksCount > 0 && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "text-[10px] mt-0.5 font-bold leading-none",
								children: dayInfo.booksCount
							})]
						})
					}, dayInfo.dateKey))]
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "flex flex-wrap gap-3 mt-3 text-xs",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "flex items-center gap-1.5",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "w-3 h-3 rounded border-2 border-green-500 bg-green-50 dark:bg-green-950" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "text-muted-foreground",
								children: "Has books"
							})]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "flex items-center gap-1.5",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "w-3 h-3 rounded border-2 border-blue-500 bg-blue-50 dark:bg-blue-950" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "text-muted-foreground",
								children: "Today"
							})]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "flex items-center gap-1.5",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "w-3 h-3 rounded border-2 border-primary bg-primary" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "text-muted-foreground",
								children: "Selected"
							})]
						})
					]
				})
			] })] }),
			selectedDate && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Card, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardHeader, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(CardTitle, {
				className: "flex items-center gap-2",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(BookOpen, { className: "h-5 w-5" }), selectedDate.toLocaleDateString("en-US", {
					month: "long",
					day: "numeric",
					year: "numeric"
				})]
			}) }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, { children: selectedBooks.length === 0 ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex flex-col items-center justify-center py-8 text-center",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(BookOpen, { className: "mb-2 h-12 w-12 text-muted-foreground" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "text-sm text-muted-foreground",
					children: "No books finished on this date"
				})]
			}) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "grid gap-4 sm:grid-cols-2 lg:grid-cols-3",
				children: selectedBooks.map((book) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Link, {
					to: `/dashboard/books/${book.book.bookId}`,
					className: "flex flex-col gap-3 rounded-lg border p-4 transition-all hover:bg-accent hover:shadow-md group",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "flex gap-3",
						children: [book.goodreads?.coverUrl ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("img", {
							src: book.goodreads.coverUrl,
							alt: book.book.title,
							className: "h-32 w-22 rounded object-cover transition-transform group-hover:scale-105"
						}) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
							className: "flex h-32 w-22 items-center justify-center rounded bg-muted transition-transform group-hover:scale-105",
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(BookOpen, { className: "h-8 w-8 text-muted-foreground" })
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "flex-1 space-y-2",
							children: [
								/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
									className: "flex items-start justify-between gap-2",
									children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h4", {
										className: "font-semibold leading-tight group-hover:text-primary transition-colors line-clamp-2",
										children: book.book.title
									}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ExternalLink, { className: "h-4 w-4 text-muted-foreground opacity-0 group-hover:opacity-100 transition-opacity shrink-0" })]
								}),
								/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
									className: "text-sm text-muted-foreground",
									children: book.authors
								}),
								/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
									className: "flex items-center gap-2",
									children: [book.log.rating && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Badge, {
										variant: "secondary",
										children: ["⭐ ", book.log.rating]
									}), book.book.pages && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
										className: "text-xs text-muted-foreground",
										children: [book.book.pages, " pages"]
									})]
								})
							]
						})]
					})
				}, book.log.logId))
			}) })] })
		]
	});
}
function CalendarPage() {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CalendarClient, {});
}
//#endregion
export { CalendarPage as component };
