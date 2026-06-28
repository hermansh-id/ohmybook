import { o as __toESM } from "../_runtime.mjs";
import { t as cn } from "./utils-oIFR_d28.mjs";
import { u as require_react } from "../_libs/@floating-ui/react-dom+[...].mjs";
import { a as Overlay2, c as Title2, i as Description2, j as require_jsx_runtime, n as Cancel, o as Portal2, r as Content2, s as Root2, t as Action } from "../_libs/@radix-ui/react-alert-dialog+[...].mjs";
import { n as buttonVariants, t as Button } from "./button-PkU2hkqt.mjs";
import { t as Badge } from "./badge-y-Up9thA.mjs";
import { h as Link } from "../_libs/@tanstack/react-router+[...].mjs";
import { d as updateBookAction, f as updateBookStatusAction, n as deleteBookAction, o as getBookDetailsAction, r as fetchGoodreadsDataAction, s as getBooksAction } from "./books-B1VN5UCC.mjs";
import { C as Pencil, I as Download, J as BookOpen, L as Clock, P as ExternalLink, Q as ArrowUpDown, W as Check, Z as ArrowUp, f as Star, m as SlidersHorizontal, n as X, q as Calendar, s as Trash2, tt as ArrowDown, u as Tag, x as Plus } from "../_libs/lucide-react.mjs";
import { t as Input } from "./input-BO5Hu60S.mjs";
import { a as DialogHeader, i as DialogFooter, n as DialogContent, o as DialogTitle, r as DialogDescription, t as Dialog } from "./dialog-DLnhFQTL.mjs";
import { t as Label } from "./label-Ca2nQBgL.mjs";
import { a as TableHeader, i as TableHead, n as TableBody, o as TableRow, r as TableCell, t as Table } from "./table-BD4r1fXY.mjs";
import { i as useQueryClient, n as useQuery, t as useMutation } from "../_libs/tanstack__react-query.mjs";
import { a as getFilteredRowModel, i as getCoreRowModel, n as useReactTable, o as getPaginationRowModel, s as getSortedRowModel, t as flexRender } from "../_libs/@tanstack/react-table+[...].mjs";
import { t as Separator } from "./separator-_u3Cq2VW.mjs";
import { a as SelectValue, i as SelectTrigger, n as SelectContent, r as SelectItem, t as Select } from "./select-BtVq9f46.mjs";
import { n as DropdownMenuCheckboxItem, r as DropdownMenuContent, s as DropdownMenuTrigger, t as DropdownMenu } from "./dropdown-menu-Dzvn-mwZ.mjs";
import { n as toast } from "../_libs/sonner.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/books-DzNYsrB6.js
var import_react = /* @__PURE__ */ __toESM(require_react());
var import_jsx_runtime = require_jsx_runtime();
function useBooks() {
	return useQuery({
		queryKey: ["books"],
		queryFn: () => getBooksAction(),
		staleTime: 1e3 * 60 * 2
	});
}
var STATUS_OPTIONS = [
	{
		value: "all",
		label: "All statuses"
	},
	{
		value: "finished",
		label: "Finished"
	},
	{
		value: "not_started",
		label: "Not started"
	}
];
var STATUS_BADGE = {
	finished: {
		variant: "secondary",
		label: "Finished"
	},
	not_started: {
		variant: "outline",
		label: "Not started"
	}
};
function SortHeader({ column, label }) {
	const sorted = column.getIsSorted();
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Button, {
		variant: "ghost",
		size: "sm",
		className: "-ml-3 h-8",
		onClick: () => column.toggleSorting(sorted === "asc"),
		children: [label, sorted === "asc" ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ArrowUp, { className: "ml-1 h-3 w-3" }) : sorted === "desc" ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ArrowDown, { className: "ml-1 h-3 w-3" }) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ArrowUpDown, { className: "ml-1 h-3 w-3 opacity-40" })]
	});
}
var columns = [
	{
		accessorKey: "title",
		header: ({ column }) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(SortHeader, {
			column,
			label: "Title"
		}),
		cell: ({ row }) => {
			const book = row.original;
			return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex items-center gap-3 min-w-0",
				children: [book.coverUrl ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("img", {
					src: book.coverUrl,
					alt: book.title,
					className: "h-12 w-8 object-cover rounded shrink-0"
				}) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "h-12 w-8 bg-muted rounded flex items-center justify-center shrink-0",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(BookOpen, { className: "h-4 w-4 text-muted-foreground" })
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "min-w-0",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "font-medium truncate",
						children: book.title
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "text-xs text-muted-foreground truncate",
						children: book.authors?.length ? book.authors.map((a) => a.name).join(", ") : "Unknown"
					})]
				})]
			});
		},
		filterFn: "includesString"
	},
	{
		id: "authors",
		accessorFn: (row) => row.authors?.map((a) => a.name).join(", ") ?? "",
		header: "Author(s)",
		cell: ({ getValue }) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
			className: "text-sm text-muted-foreground hidden md:block",
			children: getValue() || "Unknown"
		})
	},
	{
		accessorKey: "genres",
		header: "Genres",
		cell: ({ row }) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
			className: "flex flex-wrap gap-1 hidden sm:flex",
			children: row.original.genres?.length ? row.original.genres.slice(0, 2).map((g) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Badge, {
				variant: "outline",
				className: "text-xs whitespace-nowrap",
				children: g.name
			}, g.id)) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
				className: "text-muted-foreground text-sm",
				children: "—"
			})
		}),
		enableSorting: false
	},
	{
		accessorKey: "pages",
		header: ({ column }) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(SortHeader, {
			column,
			label: "Pages"
		}),
		cell: ({ row }) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
			className: "text-center tabular-nums",
			children: row.original.pages ?? "—"
		})
	},
	{
		accessorKey: "year",
		header: ({ column }) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(SortHeader, {
			column,
			label: "Year"
		}),
		cell: ({ row }) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
			className: "text-center tabular-nums",
			children: row.original.year ?? "—"
		})
	},
	{
		accessorKey: "rating",
		header: ({ column }) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(SortHeader, {
			column,
			label: "Rating"
		}),
		cell: ({ row }) => {
			const r = row.original.rating;
			return r ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex items-center gap-1",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Star, { className: "h-3 w-3 fill-yellow-400 text-yellow-400" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
					className: "tabular-nums",
					children: r
				})]
			}) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
				className: "text-muted-foreground text-sm",
				children: "—"
			});
		}
	},
	{
		accessorKey: "status",
		header: "Status",
		cell: ({ row }) => {
			const s = row.original.status;
			const cfg = STATUS_BADGE[s] ?? {
				variant: "outline",
				label: s
			};
			return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Badge, {
				variant: cfg.variant,
				className: "whitespace-nowrap text-xs",
				children: cfg.label
			});
		},
		filterFn: (row, _id, filterValue) => filterValue === "all" || row.original.status === filterValue
	}
];
function BooksTable({ data, onRowClick }) {
	const [sorting, setSorting] = import_react.useState([]);
	const [columnFilters, setColumnFilters] = import_react.useState([]);
	const [columnVisibility, setColumnVisibility] = import_react.useState({});
	const [globalFilter, setGlobalFilter] = import_react.useState("");
	const [statusFilter, setStatusFilter] = import_react.useState("all");
	const [genreFilter, setGenreFilter] = import_react.useState("all");
	const [pageSize, setPageSize] = import_react.useState(20);
	const uniqueGenres = import_react.useMemo(() => {
		const s = /* @__PURE__ */ new Set();
		data.forEach((b) => b.genres?.forEach((g) => s.add(g.name)));
		return Array.from(s).sort();
	}, [data]);
	const table = useReactTable({
		data: import_react.useMemo(() => {
			return data.filter((book) => {
				const statusMatch = statusFilter === "all" || book.status === statusFilter;
				const genreMatch = genreFilter === "all" || book.genres?.some((g) => g.name === genreFilter);
				return statusMatch && genreMatch;
			});
		}, [
			data,
			statusFilter,
			genreFilter
		]),
		columns,
		getCoreRowModel: getCoreRowModel(),
		getPaginationRowModel: getPaginationRowModel(),
		getSortedRowModel: getSortedRowModel(),
		getFilteredRowModel: getFilteredRowModel(),
		onSortingChange: setSorting,
		onColumnFiltersChange: setColumnFilters,
		onColumnVisibilityChange: setColumnVisibility,
		onGlobalFilterChange: setGlobalFilter,
		globalFilterFn: "includesString",
		state: {
			sorting,
			columnFilters,
			columnVisibility,
			globalFilter
		},
		initialState: { pagination: { pageSize } }
	});
	import_react.useEffect(() => {
		table.setPageSize(pageSize);
	}, [pageSize, table]);
	const hasActiveFilters = statusFilter !== "all" || genreFilter !== "all" || globalFilter !== "";
	const clearFilters = () => {
		setStatusFilter("all");
		setGenreFilter("all");
		setGlobalFilter("");
	};
	const totalFiltered = table.getFilteredRowModel().rows.length;
	const { pageIndex, pageSize: currentPageSize } = table.getState().pagination;
	const pageCount = table.getPageCount();
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "space-y-4",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex flex-col gap-3 sm:flex-row sm:items-center sm:flex-wrap",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
						placeholder: "Search title, author...",
						value: globalFilter,
						onChange: (e) => setGlobalFilter(e.target.value),
						className: "w-full sm:w-56"
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Select, {
						value: statusFilter,
						onValueChange: setStatusFilter,
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectTrigger, {
							className: "w-full sm:w-44",
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectValue, { placeholder: "Status" })
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectContent, { children: STATUS_OPTIONS.map((opt) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectItem, {
							value: opt.value,
							children: opt.label
						}, opt.value)) })]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Select, {
						value: genreFilter,
						onValueChange: setGenreFilter,
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectTrigger, {
							className: "w-full sm:w-44",
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectValue, { placeholder: "Genre" })
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(SelectContent, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectItem, {
							value: "all",
							children: "All genres"
						}), uniqueGenres.map((g) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectItem, {
							value: g,
							children: g
						}, g))] })]
					}),
					hasActiveFilters && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Button, {
						variant: "ghost",
						size: "sm",
						onClick: clearFilters,
						className: "gap-1 text-muted-foreground",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(X, { className: "h-3 w-3" }), "Clear"]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
						className: "sm:ml-auto flex items-center gap-2",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(DropdownMenu, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(DropdownMenuTrigger, {
							asChild: true,
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Button, {
								variant: "outline",
								size: "sm",
								className: "gap-1",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(SlidersHorizontal, { className: "h-4 w-4" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
									className: "hidden sm:inline",
									children: "Columns"
								})]
							})
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(DropdownMenuContent, {
							align: "end",
							children: table.getAllColumns().filter((col) => col.getCanHide()).map((col) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(DropdownMenuCheckboxItem, {
								className: "capitalize",
								checked: col.getIsVisible(),
								onCheckedChange: (v) => col.toggleVisibility(v),
								children: col.id
							}, col.id))
						})] })
					})
				]
			}),
			hasActiveFilters && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex flex-wrap gap-2",
				children: [
					globalFilter && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Badge, {
						variant: "secondary",
						className: "gap-1 pr-1",
						children: [
							"Search: ",
							globalFilter,
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
								onClick: () => setGlobalFilter(""),
								className: "ml-1 rounded hover:bg-muted",
								children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(X, { className: "h-3 w-3" })
							})
						]
					}),
					statusFilter !== "all" && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Badge, {
						variant: "secondary",
						className: "gap-1 pr-1",
						children: [STATUS_OPTIONS.find((o) => o.value === statusFilter)?.label, /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
							onClick: () => setStatusFilter("all"),
							className: "ml-1 rounded hover:bg-muted",
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(X, { className: "h-3 w-3" })
						})]
					}),
					genreFilter !== "all" && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Badge, {
						variant: "secondary",
						className: "gap-1 pr-1",
						children: [genreFilter, /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
							onClick: () => setGenreFilter("all"),
							className: "ml-1 rounded hover:bg-muted",
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(X, { className: "h-3 w-3" })
						})]
					})
				]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
				className: "text-sm text-muted-foreground",
				children: [
					totalFiltered,
					" book",
					totalFiltered !== 1 ? "s" : "",
					hasActiveFilters && ` (filtered from ${data.length})`
				]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "rounded-md border overflow-x-auto",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Table, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(TableHeader, { children: table.getHeaderGroups().map((hg) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(TableRow, { children: hg.headers.map((header) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(TableHead, {
					className: "whitespace-nowrap",
					children: header.isPlaceholder ? null : flexRender(header.column.columnDef.header, header.getContext())
				}, header.id)) }, hg.id)) }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(TableBody, { children: table.getRowModel().rows.length ? table.getRowModel().rows.map((row) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(TableRow, {
					onClick: () => onRowClick?.(row.original),
					className: "cursor-pointer hover:bg-muted/50",
					children: row.getVisibleCells().map((cell) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(TableCell, { children: flexRender(cell.column.columnDef.cell, cell.getContext()) }, cell.id))
				}, row.id)) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)(TableRow, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(TableCell, {
					colSpan: columns.length,
					className: "h-24 text-center text-muted-foreground",
					children: "No books found."
				}) }) })] })
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "flex items-center gap-2 text-sm text-muted-foreground",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", { children: "Rows per page" }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Select, {
						value: String(pageSize),
						onValueChange: (v) => setPageSize(Number(v)),
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectTrigger, {
							className: "h-8 w-16",
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectValue, {})
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectContent, { children: [
							10,
							20,
							50,
							100
						].map((n) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectItem, {
							value: String(n),
							children: n
						}, n)) })]
					})]
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "flex items-center gap-2 justify-center sm:justify-end",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
							className: "text-sm text-muted-foreground tabular-nums",
							children: pageCount === 0 ? "0 / 0" : `${pageIndex + 1} / ${pageCount}`
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
							variant: "outline",
							size: "sm",
							onClick: () => table.firstPage(),
							disabled: !table.getCanPreviousPage(),
							children: "«"
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
							variant: "outline",
							size: "sm",
							onClick: () => table.previousPage(),
							disabled: !table.getCanPreviousPage(),
							children: "‹"
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
							variant: "outline",
							size: "sm",
							onClick: () => table.nextPage(),
							disabled: !table.getCanNextPage(),
							children: "›"
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
							variant: "outline",
							size: "sm",
							onClick: () => table.lastPage(),
							disabled: !table.getCanNextPage(),
							children: "»"
						})
					]
				})]
			})
		]
	});
}
function EditBookDialog({ book, open, onOpenChange }) {
	const queryClient = useQueryClient();
	const [formData, setFormData] = (0, import_react.useState)({
		title: book.title,
		isbn: book.isbn || "",
		year: book.year?.toString() || "",
		pages: book.pages?.toString() || "",
		goodreadsUrl: book.goodreadsUrl || ""
	});
	const updateMutation = useMutation({
		mutationFn: updateBookAction,
		onSuccess: () => {
			queryClient.invalidateQueries({ queryKey: ["books"] });
			queryClient.invalidateQueries({ queryKey: ["book", book.id] });
			toast.success("Book updated successfully!");
			onOpenChange(false);
		},
		onError: () => {
			toast.error("Failed to update book");
		}
	});
	const handleSubmit = (e) => {
		e.preventDefault();
		updateMutation.mutate({
			bookId: book.id,
			title: formData.title,
			isbn: formData.isbn || void 0,
			year: formData.year ? parseInt(formData.year) : void 0,
			pages: formData.pages ? parseInt(formData.pages) : void 0,
			goodreadsUrl: formData.goodreadsUrl || void 0
		});
	};
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Dialog, {
		open,
		onOpenChange,
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(DialogContent, {
			className: "sm:max-w-[500px]",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(DialogHeader, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(DialogTitle, { children: "Edit Book" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(DialogDescription, { children: "Update the book information below" })] }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("form", {
				onSubmit: handleSubmit,
				className: "space-y-4 py-4",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "space-y-2",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Label, {
							htmlFor: "title",
							children: ["Title ", /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "text-destructive",
								children: "*"
							})]
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
							id: "title",
							value: formData.title,
							onChange: (e) => setFormData({
								...formData,
								title: e.target.value
							}),
							required: true
						})]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "space-y-2",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Label, {
							htmlFor: "isbn",
							children: "ISBN"
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
							id: "isbn",
							value: formData.isbn,
							onChange: (e) => setFormData({
								...formData,
								isbn: e.target.value
							}),
							placeholder: "978-0-123456-78-9"
						})]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "grid grid-cols-1 sm:grid-cols-2 gap-4",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "space-y-2",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Label, {
								htmlFor: "year",
								children: "Year"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
								id: "year",
								type: "number",
								value: formData.year,
								onChange: (e) => setFormData({
									...formData,
									year: e.target.value
								}),
								placeholder: "2024"
							})]
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "space-y-2",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Label, {
								htmlFor: "pages",
								children: "Pages"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
								id: "pages",
								type: "number",
								value: formData.pages,
								onChange: (e) => setFormData({
									...formData,
									pages: e.target.value
								}),
								placeholder: "350"
							})]
						})]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "space-y-2",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Label, {
							htmlFor: "goodreadsUrl",
							children: "Goodreads URL"
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
							id: "goodreadsUrl",
							type: "url",
							value: formData.goodreadsUrl,
							onChange: (e) => setFormData({
								...formData,
								goodreadsUrl: e.target.value
							}),
							placeholder: "https://www.goodreads.com/book/show/..."
						})]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(DialogFooter, {
						className: "gap-2 sm:gap-0",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
							type: "button",
							variant: "outline",
							onClick: () => onOpenChange(false),
							disabled: updateMutation.isPending,
							children: "Cancel"
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
							type: "submit",
							disabled: updateMutation.isPending,
							children: updateMutation.isPending ? "Saving..." : "Save Changes"
						})]
					})
				]
			})]
		})
	});
}
function AlertDialog({ ...props }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Root2, {
		"data-slot": "alert-dialog",
		...props
	});
}
function AlertDialogPortal({ ...props }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Portal2, {
		"data-slot": "alert-dialog-portal",
		...props
	});
}
function AlertDialogOverlay({ className, ...props }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Overlay2, {
		"data-slot": "alert-dialog-overlay",
		className: cn("data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 fixed inset-0 z-50 bg-black/50", className),
		...props
	});
}
function AlertDialogContent({ className, ...props }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(AlertDialogPortal, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(AlertDialogOverlay, {}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Content2, {
		"data-slot": "alert-dialog-content",
		className: cn("bg-background data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 fixed top-[50%] left-[50%] z-50 grid w-full max-w-[calc(100%-2rem)] translate-x-[-50%] translate-y-[-50%] gap-4 rounded-lg border p-6 shadow-lg duration-200 sm:max-w-lg", className),
		...props
	})] });
}
function AlertDialogHeader({ className, ...props }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
		"data-slot": "alert-dialog-header",
		className: cn("flex flex-col gap-2 text-center sm:text-left", className),
		...props
	});
}
function AlertDialogFooter({ className, ...props }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
		"data-slot": "alert-dialog-footer",
		className: cn("flex flex-col-reverse gap-2 sm:flex-row sm:justify-end", className),
		...props
	});
}
function AlertDialogTitle({ className, ...props }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Title2, {
		"data-slot": "alert-dialog-title",
		className: cn("text-lg font-semibold", className),
		...props
	});
}
function AlertDialogDescription({ className, ...props }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Description2, {
		"data-slot": "alert-dialog-description",
		className: cn("text-muted-foreground text-sm", className),
		...props
	});
}
function AlertDialogAction({ className, ...props }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Action, {
		className: cn(buttonVariants(), className),
		...props
	});
}
function AlertDialogCancel({ className, ...props }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Cancel, {
		className: cn(buttonVariants({ variant: "outline" }), className),
		...props
	});
}
function BookDetailsDialog({ bookId, open, onOpenChange }) {
	const queryClient = useQueryClient();
	const [selectedRating, setSelectedRating] = (0, import_react.useState)(0);
	const [showDeleteDialog, setShowDeleteDialog] = (0, import_react.useState)(false);
	const [showEditDialog, setShowEditDialog] = (0, import_react.useState)(false);
	const { data: book, isLoading } = useQuery({
		queryKey: ["book", bookId],
		queryFn: () => getBookDetailsAction(bookId),
		enabled: !!bookId && open
	});
	const updateMutation = useMutation({
		mutationFn: updateBookStatusAction,
		onSuccess: () => {
			queryClient.invalidateQueries({ queryKey: ["books"] });
			queryClient.invalidateQueries({ queryKey: ["book", bookId] });
			toast.success("Book updated successfully!");
		},
		onError: () => {
			toast.error("Failed to update book");
		}
	});
	const deleteMutation = useMutation({
		mutationFn: deleteBookAction,
		onSuccess: () => {
			queryClient.invalidateQueries({ queryKey: ["books"] });
			toast.success("Book deleted successfully!");
			onOpenChange(false);
			setShowDeleteDialog(false);
		},
		onError: () => {
			toast.error("Failed to delete book");
		}
	});
	const fetchGoodreadsMutation = useMutation({
		mutationFn: ({ bookId, isbn }) => fetchGoodreadsDataAction(bookId, isbn),
		onSuccess: (result) => {
			if (result.success) {
				queryClient.invalidateQueries({ queryKey: ["books"] });
				queryClient.invalidateQueries({ queryKey: ["book", bookId] });
				toast.success("Goodreads data fetched successfully!");
			} else toast.error(result.error || "Failed to fetch Goodreads data");
		},
		onError: (error) => {
			toast.error(error?.message || "Failed to fetch Goodreads data");
		}
	});
	const handleMarkAsFinished = () => {
		if (!book) {
			toast.error("Book data not available");
			return;
		}
		if (!selectedRating || selectedRating < 1 || selectedRating > 5) {
			toast.error("Please select a rating (1-5)");
			return;
		}
		updateMutation.mutate({
			bookId: book.id,
			logId: book.logId,
			status: "finished",
			rating: selectedRating,
			dateFinished: /* @__PURE__ */ new Date()
		});
	};
	const handleDelete = () => {
		if (!book) return;
		deleteMutation.mutate(book.id);
	};
	const handleFetchGoodreadsData = () => {
		if (!book || !book.isbn) {
			toast.error("ISBN is required to fetch Goodreads data");
			return;
		}
		fetchGoodreadsMutation.mutate({
			bookId: book.id,
			isbn: book.isbn
		});
	};
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Dialog, {
		open,
		onOpenChange,
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(DialogContent, {
				className: "max-w-3xl max-h-[90vh] overflow-y-auto",
				children: [isLoading && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "flex items-center justify-center p-8",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "text-muted-foreground",
						children: "Loading..."
					})
				}), book && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(DialogHeader, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "flex items-start justify-between gap-2",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "flex-1",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(DialogTitle, {
							className: "text-2xl",
							children: book.title
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(DialogDescription, { children: book.isbn && `ISBN: ${book.isbn}` })]
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "flex gap-2 shrink-0",
						children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Button, {
								variant: "outline",
								size: "sm",
								onClick: () => setShowEditDialog(true),
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Pencil, { className: "h-4 w-4" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
									className: "ml-2 hidden sm:inline",
									children: "Edit"
								})]
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
								asChild: true,
								variant: "outline",
								size: "sm",
								children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Link, {
									to: `/dashboard/books/${book.id}`,
									children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(ExternalLink, { className: "h-4 w-4 mr-2" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
										className: "hidden sm:inline",
										children: "View Details"
									})]
								})
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Button, {
								variant: "outline",
								size: "sm",
								onClick: () => setShowDeleteDialog(true),
								className: "text-destructive hover:text-destructive",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Trash2, { className: "h-4 w-4" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
									className: "ml-2 hidden sm:inline",
									children: "Delete"
								})]
							})
						]
					})]
				}) }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "grid gap-6 py-4",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "grid md:grid-cols-[200px_1fr] gap-6",
							children: [book.coverUrl ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("img", {
								src: book.coverUrl,
								alt: book.title,
								className: "w-full rounded-lg shadow-lg"
							}) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
								className: "aspect-[2/3] bg-muted rounded-lg flex items-center justify-center",
								children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(BookOpen, { className: "h-12 w-12 text-muted-foreground" })
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "space-y-4",
								children: [
									/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
										className: "flex flex-wrap gap-2",
										children: [book.status && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Badge, {
											variant: "default",
											children: book.status.replace(/_/g, " ")
										}), book.rating && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Badge, {
											variant: "secondary",
											className: "gap-1",
											children: [
												/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Star, { className: "h-3 w-3 fill-current" }),
												book.rating,
												"/5"
											]
										})]
									}),
									/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
										className: "grid grid-cols-2 gap-3 text-sm",
										children: [
											book.pages && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
												className: "flex items-center gap-2",
												children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(BookOpen, { className: "h-4 w-4 text-muted-foreground" }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", { children: [book.pages, " pages"] })]
											}),
											book.year && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
												className: "flex items-center gap-2",
												children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Calendar, { className: "h-4 w-4 text-muted-foreground" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", { children: book.year })]
											}),
											book.readingDays && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
												className: "flex items-center gap-2",
												children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Clock, { className: "h-4 w-4 text-muted-foreground" }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", { children: [book.readingDays, " days to read"] })]
											}),
											book.averageRating && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
												className: "flex items-center gap-2",
												children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Star, { className: "h-4 w-4 text-muted-foreground" }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", { children: [
													book.averageRating,
													" (",
													book.ratingsCount,
													" ratings)"
												] })]
											})
										]
									}),
									book.status === "reading" && book.pages && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
										className: "text-sm text-muted-foreground mb-1",
										children: [
											"Progress: ",
											book.currentPage,
											" / ",
											book.pages
										]
									}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
										className: "h-2 bg-muted rounded-full overflow-hidden",
										children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
											className: "h-full bg-primary",
											style: { width: `${book.currentPage / book.pages * 100}%` }
										})
									})] }),
									/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
										className: "space-y-1 text-sm",
										children: [book.dateStarted && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
											className: "flex justify-between",
											children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
												className: "text-muted-foreground",
												children: "Started:"
											}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", { children: new Date(book.dateStarted).toLocaleDateString() })]
										}), book.dateFinished && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
											className: "flex justify-between",
											children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
												className: "text-muted-foreground",
												children: "Finished:"
											}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", { children: new Date(book.dateFinished).toLocaleDateString() })]
										})]
									}),
									(book.publisher || book.publicationDate) && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
										className: "text-sm",
										children: [book.publisher && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
											className: "text-muted-foreground",
											children: book.publisher
										}), book.publicationDate && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
											className: "text-muted-foreground",
											children: [
												"Published:",
												" ",
												new Date(book.publicationDate).toLocaleDateString()
											]
										})]
									})
								]
							})]
						}),
						book.description && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Separator, {}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
							className: "font-semibold mb-2",
							children: "Description"
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "text-sm text-muted-foreground leading-relaxed",
							children: book.description
						})] })] }),
						book.isbn && !book.coverUrl && !book.description && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Separator, {}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
							className: "rounded-lg border border-dashed bg-muted/30 p-4",
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("h3", {
									className: "font-semibold mb-1 flex items-center gap-2",
									children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Download, { className: "h-4 w-4" }), "Goodreads Data Missing"]
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
									className: "text-sm text-muted-foreground",
									children: "Fetch book cover, description, and other details from Goodreads using ISBN"
								})] }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
									onClick: handleFetchGoodreadsData,
									disabled: fetchGoodreadsMutation.isPending,
									size: "sm",
									className: "w-full sm:w-auto shrink-0",
									children: fetchGoodreadsMutation.isPending ? "Fetching..." : "Fetch Data"
								})]
							})
						})] }),
						book.review && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Separator, {}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
							className: "font-semibold mb-2",
							children: "My Review"
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "text-sm leading-relaxed",
							children: book.review
						})] })] }),
						book.notes && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Separator, {}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
							className: "font-semibold mb-2",
							children: "Notes"
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "text-sm text-muted-foreground leading-relaxed",
							children: book.notes
						})] })] }),
						book.tags && book.tags.length > 0 && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Separator, {}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("h3", {
							className: "font-semibold mb-2 flex items-center gap-2",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Tag, { className: "h-4 w-4" }), "Tags"]
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
							className: "flex flex-wrap gap-2",
							children: book.tags.map((tag, index) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Badge, {
								variant: "outline",
								children: tag
							}, index))
						})] })] }),
						book.status !== "finished" ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Separator, {}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "rounded-lg border bg-muted/50 p-4",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("h3", {
								className: "font-semibold mb-3 flex items-center gap-2",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Check, { className: "h-4 w-4" }), "Mark as Finished"]
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "space-y-4",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("label", {
									className: "text-sm font-medium mb-2 block",
									children: "Your Rating"
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
									className: "flex gap-2 flex-wrap",
									children: [
										1,
										2,
										3,
										4,
										5
									].map((rating) => /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
										onClick: () => setSelectedRating(rating),
										className: `flex items-center gap-1 px-4 py-2 rounded-md border transition-colors min-w-[60px] justify-center ${selectedRating === rating ? "bg-primary text-primary-foreground border-primary" : "bg-background hover:bg-muted"}`,
										children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Star, { className: `h-4 w-4 ${selectedRating === rating ? "fill-current" : ""}` }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", { children: rating })]
									}, rating))
								})] }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
									onClick: handleMarkAsFinished,
									disabled: !selectedRating || updateMutation.isPending,
									className: "w-full sm:w-auto",
									children: updateMutation.isPending ? "Saving..." : "Mark as Finished"
								})]
							})]
						})] }) : /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Separator, {}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "rounded-lg border bg-muted/50 p-4",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("h3", {
								className: "font-semibold mb-3 flex items-center gap-2",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Star, { className: "h-4 w-4" }), book.rating ? "Update Rating" : "Add Rating"]
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "space-y-4",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("label", {
									className: "text-sm font-medium mb-2 block",
									children: ["Your Rating ", book.rating && `(Current: ${book.rating}/5)`]
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
									className: "flex gap-2 flex-wrap",
									children: [
										1,
										2,
										3,
										4,
										5
									].map((rating) => /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
										onClick: () => setSelectedRating(rating),
										className: `flex items-center gap-1 px-4 py-2 rounded-md border transition-colors min-w-[60px] justify-center ${selectedRating === rating ? "bg-primary text-primary-foreground border-primary" : "bg-background hover:bg-muted"}`,
										children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Star, { className: `h-4 w-4 ${selectedRating === rating ? "fill-current" : ""}` }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", { children: rating })]
									}, rating))
								})] }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
									onClick: () => {
										if (!book) {
											toast.error("Book data not available");
											return;
										}
										if (!selectedRating || selectedRating < 1 || selectedRating > 5) {
											toast.error("Please select a rating (1-5)");
											return;
										}
										updateMutation.mutate({
											bookId: book.id,
											logId: book.logId,
											status: "finished",
											rating: selectedRating,
											dateFinished: book.dateFinished ? new Date(book.dateFinished) : /* @__PURE__ */ new Date()
										});
									},
									disabled: !selectedRating || updateMutation.isPending,
									className: "w-full sm:w-auto",
									children: updateMutation.isPending ? "Saving..." : book.rating ? "Update Rating" : "Add Rating"
								})]
							})]
						})] })
					]
				})] })]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)(AlertDialog, {
				open: showDeleteDialog,
				onOpenChange: setShowDeleteDialog,
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(AlertDialogContent, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(AlertDialogHeader, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(AlertDialogTitle, { children: "Are you sure?" }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(AlertDialogDescription, { children: [
					"This will permanently delete \"",
					book?.title,
					"\" and all associated data. This action cannot be undone."
				] })] }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(AlertDialogFooter, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(AlertDialogCancel, { children: "Cancel" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(AlertDialogAction, {
					onClick: handleDelete,
					disabled: deleteMutation.isPending,
					className: "bg-destructive text-destructive-foreground hover:bg-destructive/90",
					children: deleteMutation.isPending ? "Deleting..." : "Delete"
				})] })] })
			}),
			book && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(EditBookDialog, {
				book: {
					id: book.id,
					title: book.title,
					isbn: book.isbn,
					year: book.year,
					pages: book.pages,
					goodreadsUrl: book.goodreadsUrl
				},
				open: showEditDialog,
				onOpenChange: setShowEditDialog
			})
		]
	});
}
function BooksClient() {
	const { data: books, isLoading, error } = useBooks();
	const [selectedBookId, setSelectedBookId] = (0, import_react.useState)(null);
	const [dialogOpen, setDialogOpen] = (0, import_react.useState)(false);
	const handleRowClick = (book) => {
		setSelectedBookId(book.id);
		setDialogOpen(true);
	};
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "flex flex-col gap-4 p-4 md:gap-6 md:p-6",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex items-center justify-between",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h1", {
					className: "text-3xl font-bold tracking-tight",
					children: "Books"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "text-muted-foreground",
					children: "Browse and manage your book collection"
				})] }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
					asChild: true,
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Link, {
						to: "/dashboard/books/add",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Plus, { className: "h-4 w-4 mr-2" }), "Add Book"]
					})
				})]
			}),
			isLoading && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "flex items-center justify-center p-8",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "text-muted-foreground",
					children: "Loading books..."
				})
			}),
			error && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "flex items-center justify-center p-8",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "text-destructive",
					children: "Failed to load books. Please try again."
				})
			}),
			books && books.length === 0 && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex flex-col items-center justify-center p-8",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(BookOpen, { className: "h-12 w-12 text-muted-foreground mb-4" }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "text-muted-foreground text-lg",
						children: "No books found"
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "text-sm text-muted-foreground",
						children: "Start adding books to your collection"
					})
				]
			}),
			books && books.length > 0 && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(BooksTable, {
				data: books,
				onRowClick: handleRowClick
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)(BookDetailsDialog, {
				bookId: selectedBookId,
				open: dialogOpen,
				onOpenChange: setDialogOpen
			})
		]
	});
}
function BooksPage() {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(BooksClient, {});
}
//#endregion
export { BooksPage as component };
