import { o as __toESM } from "../_runtime.mjs";
import { u as require_react } from "../_libs/@floating-ui/react-dom+[...].mjs";
import { j as require_jsx_runtime } from "../_libs/@radix-ui/react-alert-dialog+[...].mjs";
import { t as Button } from "./button-PkU2hkqt.mjs";
import { a as CardHeader, o as CardTitle, r as CardContent, t as Card } from "./card-BxgehY3N.mjs";
import { B as ChevronUp, J as BookOpen, U as ChevronDown, s as Trash2, x as Plus, z as ChevronsUpDown } from "../_libs/lucide-react.mjs";
import { a as DialogHeader, n as DialogContent, o as DialogTitle, r as DialogDescription, t as Dialog } from "./dialog-DLnhFQTL.mjs";
import { t as Skeleton } from "./skeleton-D7Ivmigh.mjs";
import { a as TableHeader, i as TableHead, n as TableBody, o as TableRow, r as TableCell, t as Table } from "./table-BD4r1fXY.mjs";
import { i as useQueryClient, n as useQuery } from "../_libs/tanstack__react-query.mjs";
import { a as getFilteredRowModel, i as getCoreRowModel, n as useReactTable, o as getPaginationRowModel, r as createColumnHelper, s as getSortedRowModel, t as flexRender } from "../_libs/@tanstack/react-table+[...].mjs";
import { a as SelectValue, i as SelectTrigger, n as SelectContent, r as SelectItem, t as Select } from "./select-BtVq9f46.mjs";
import { n as toast } from "../_libs/sonner.mjs";
import { i as getUnfinishedBooksAction, n as deleteReadingSessionAction, r as getReadingSessionsAction } from "./reading-sessions-DGduYzP1.mjs";
import { t as AddReadingSessionForm } from "./add-reading-session-form-BURwMQpu.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/reading-log-Dvv_LEfe.js
var import_react = /* @__PURE__ */ __toESM(require_react());
var import_jsx_runtime = require_jsx_runtime();
var readingSessionsQueryKey = ["reading-sessions"];
var unfinishedBooksQueryKey = ["unfinished-books"];
function useReadingSessions(limit = 100) {
	return useQuery({
		queryKey: [...readingSessionsQueryKey, limit],
		queryFn: () => getReadingSessionsAction({ data: { limit } }),
		staleTime: 1e3 * 60
	});
}
function useUnfinishedBooks() {
	return useQuery({
		queryKey: unfinishedBooksQueryKey,
		queryFn: () => getUnfinishedBooksAction(),
		staleTime: 1e3 * 60
	});
}
var columnHelper = createColumnHelper();
function ReadingLogClient() {
	const queryClient = useQueryClient();
	const { data: sessionsData, isLoading: sessionsLoading } = useReadingSessions(100);
	const { data: unfinishedBooksData, isLoading: booksLoading } = useUnfinishedBooks();
	const sessions = sessionsData?.data ?? [];
	const unfinishedBooks = unfinishedBooksData ?? [];
	const [showAddDialog, setShowAddDialog] = (0, import_react.useState)(false);
	const [filterBookId, setFilterBookId] = (0, import_react.useState)("all");
	const [sorting, setSorting] = (0, import_react.useState)([]);
	const isLoading = sessionsLoading || booksLoading;
	const stats = (0, import_react.useMemo)(() => ({
		totalSessions: sessions.length,
		totalPages: sessions.reduce((sum, s) => sum + (s.session.pagesRead || 0), 0),
		totalMinutes: sessions.reduce((sum, s) => sum + (s.session.minutesRead || 0), 0),
		totalHours: Math.floor(sessions.reduce((sum, s) => sum + (s.session.minutesRead || 0), 0) / 60)
	}), [sessions]);
	const filteredData = (0, import_react.useMemo)(() => filterBookId === "all" ? sessions : sessions.filter((s) => s.session.bookId.toString() === filterBookId), [sessions, filterBookId]);
	const handleDelete = async (sessionId) => {
		if (!confirm("Delete this session?")) return;
		const result = await deleteReadingSessionAction(sessionId);
		if (result.success) {
			toast.success("Session deleted");
			queryClient.invalidateQueries({ queryKey: ["reading-sessions"] });
			queryClient.invalidateQueries({ queryKey: ["unfinished-books"] });
			queryClient.invalidateQueries({ queryKey: ["dashboard"] });
		} else toast.error(result.error || "Failed to delete session");
	};
	const table = useReactTable({
		data: filteredData,
		columns: (0, import_react.useMemo)(() => [
			columnHelper.accessor((row) => row.session.sessionDate, {
				id: "date",
				header: "Date",
				cell: (info) => new Date(info.getValue()).toLocaleDateString(),
				enableSorting: true
			}),
			columnHelper.accessor((row) => row.book.title, {
				id: "book",
				header: "Book",
				cell: (info) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
					className: "font-medium",
					children: info.getValue()
				}),
				enableSorting: true
			}),
			columnHelper.accessor((row) => row.authors, {
				id: "authors",
				header: "Author",
				cell: (info) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
					className: "text-muted-foreground",
					children: info.getValue()
				}),
				enableSorting: false
			}),
			columnHelper.accessor((row) => row.session.pagesRead ?? 0, {
				id: "pages",
				header: "Pages",
				cell: (info) => info.getValue() || "—",
				enableSorting: true
			}),
			columnHelper.accessor((row) => row.session.minutesRead ?? 0, {
				id: "time",
				header: "Time",
				cell: (info) => info.getValue() ? `${info.getValue()} min` : "—",
				enableSorting: true
			}),
			columnHelper.accessor((row) => row.session.notes, {
				id: "notes",
				header: "Notes",
				cell: (info) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
					className: "text-muted-foreground text-xs line-clamp-1 max-w-[200px]",
					children: info.getValue() || "—"
				}),
				enableSorting: false
			}),
			columnHelper.display({
				id: "actions",
				header: "",
				cell: (info) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
					variant: "ghost",
					size: "icon",
					onClick: () => handleDelete(info.row.original.session.sessionId),
					className: "text-destructive hover:text-destructive",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Trash2, { className: "h-4 w-4" })
				}),
				enableSorting: false
			})
		], []),
		state: { sorting },
		onSortingChange: setSorting,
		getCoreRowModel: getCoreRowModel(),
		getSortedRowModel: getSortedRowModel(),
		getFilteredRowModel: getFilteredRowModel(),
		getPaginationRowModel: getPaginationRowModel(),
		initialState: { pagination: { pageSize: 20 } }
	});
	if (isLoading) return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "flex flex-col gap-4 p-4 md:gap-6 md:p-6",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex items-center justify-between",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "space-y-2",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Skeleton, { className: "h-8 w-48" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Skeleton, { className: "h-4 w-64" })]
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Skeleton, { className: "h-10 w-32" })]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "grid gap-4 sm:grid-cols-2 lg:grid-cols-4",
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
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex items-center justify-between",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h1", {
					className: "text-3xl font-bold tracking-tight",
					children: "Reading Log"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "text-muted-foreground",
					children: "Track your daily reading sessions"
				})] }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Button, {
					onClick: () => setShowAddDialog(true),
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Plus, { className: "mr-2 h-4 w-4" }), "Add Session"]
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "grid gap-4 sm:grid-cols-2 lg:grid-cols-4",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Card, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, {
						className: "pt-6",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "space-y-1",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "text-sm text-muted-foreground",
								children: "Total Sessions"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "text-2xl font-bold",
								children: stats.totalSessions
							})]
						})
					}) }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Card, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, {
						className: "pt-6",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "space-y-1",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "text-sm text-muted-foreground",
								children: "Pages Read"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "text-2xl font-bold",
								children: stats.totalPages
							})]
						})
					}) }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Card, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, {
						className: "pt-6",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "space-y-1",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "text-sm text-muted-foreground",
								children: "Total Hours"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
								className: "text-2xl font-bold",
								children: [stats.totalHours, "h"]
							})]
						})
					}) }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Card, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, {
						className: "pt-6",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "space-y-1",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "text-sm text-muted-foreground",
								children: "Avg Pages/Session"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "text-2xl font-bold",
								children: stats.totalSessions > 0 ? Math.round(stats.totalPages / stats.totalSessions) : 0
							})]
						})
					}) })
				]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Card, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardHeader, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex items-center justify-between",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardTitle, { children: "Reading Sessions" }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Select, {
					value: filterBookId,
					onValueChange: setFilterBookId,
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectTrigger, {
						className: "w-[200px]",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectValue, { placeholder: "Filter by book" })
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(SelectContent, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectItem, {
						value: "all",
						children: "All Books"
					}), unfinishedBooks.map((book) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectItem, {
						value: book.id.toString(),
						children: book.title
					}, book.id))] })]
				})]
			}) }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, { children: filteredData.length === 0 ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex flex-col items-center justify-center py-12 text-center",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(BookOpen, { className: "mb-4 h-12 w-12 text-muted-foreground" }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "text-lg font-medium",
						children: "No reading sessions yet"
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "text-sm text-muted-foreground",
						children: "Start tracking your reading by adding a session"
					})
				]
			}) : /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "overflow-x-auto rounded-md border",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Table, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(TableHeader, { children: table.getHeaderGroups().map((headerGroup) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(TableRow, { children: headerGroup.headers.map((header) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(TableHead, { children: header.isPlaceholder ? null : /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: header.column.getCanSort() ? "flex items-center gap-1 cursor-pointer select-none" : "",
					onClick: header.column.getToggleSortingHandler(),
					children: [flexRender(header.column.columnDef.header, header.getContext()), header.column.getCanSort() && (header.column.getIsSorted() === "asc" ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ChevronUp, { className: "h-3 w-3" }) : header.column.getIsSorted() === "desc" ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ChevronDown, { className: "h-3 w-3" }) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ChevronsUpDown, { className: "h-3 w-3 text-muted-foreground" }))]
				}) }, header.id)) }, headerGroup.id)) }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(TableBody, { children: table.getRowModel().rows.map((row) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(TableRow, { children: row.getVisibleCells().map((cell) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(TableCell, { children: flexRender(cell.column.columnDef.cell, cell.getContext()) }, cell.id)) }, row.id)) })] })
			}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex items-center justify-between mt-4",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
					className: "text-sm text-muted-foreground",
					children: [
						"Page ",
						table.getState().pagination.pageIndex + 1,
						" of ",
						table.getPageCount(),
						" (",
						filteredData.length,
						" sessions)"
					]
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "flex gap-2",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
						variant: "outline",
						size: "sm",
						onClick: () => table.previousPage(),
						disabled: !table.getCanPreviousPage(),
						children: "Previous"
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
						variant: "outline",
						size: "sm",
						onClick: () => table.nextPage(),
						disabled: !table.getCanNextPage(),
						children: "Next"
					})]
				})]
			})] }) })] }),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Dialog, {
				open: showAddDialog,
				onOpenChange: setShowAddDialog,
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(DialogContent, {
					className: "max-w-md",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(DialogHeader, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(DialogTitle, { children: "Add Reading Session" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(DialogDescription, { children: "Track your reading for today with sliders" })] }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(AddReadingSessionForm, {
						books: unfinishedBooks,
						onSuccess: () => {
							setShowAddDialog(false);
							queryClient.invalidateQueries({ queryKey: ["reading-sessions"] });
							queryClient.invalidateQueries({ queryKey: ["unfinished-books"] });
							queryClient.invalidateQueries({ queryKey: ["dashboard"] });
						}
					})]
				})
			})
		]
	});
}
var SplitComponent = () => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ReadingLogClient, {});
//#endregion
export { SplitComponent as component };
