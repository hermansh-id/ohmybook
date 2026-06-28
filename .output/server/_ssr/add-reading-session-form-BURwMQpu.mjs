import { o as __toESM } from "../_runtime.mjs";
import { t as cn } from "./utils-oIFR_d28.mjs";
import { u as require_react } from "../_libs/@floating-ui/react-dom+[...].mjs";
import { j as require_jsx_runtime } from "../_libs/@radix-ui/react-alert-dialog+[...].mjs";
import { t as Button } from "./button-PkU2hkqt.mjs";
import { J as BookOpen, L as Clock } from "../_libs/lucide-react.mjs";
import { t as Label } from "./label-Ca2nQBgL.mjs";
import { i as useQueryClient, t as useMutation } from "../_libs/tanstack__react-query.mjs";
import { a as SelectValue, i as SelectTrigger, n as SelectContent, r as SelectItem, t as Select } from "./select-BtVq9f46.mjs";
import { n as toast } from "../_libs/sonner.mjs";
import { t as createReadingSessionAction } from "./reading-sessions-DGduYzP1.mjs";
import { i as Track, n as Root, r as Thumb, t as Range } from "../_libs/radix-ui__react-slider.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/add-reading-session-form-BURwMQpu.js
var import_react = /* @__PURE__ */ __toESM(require_react());
var import_jsx_runtime = require_jsx_runtime();
function Slider({ className, defaultValue, value, min = 0, max = 100, ...props }) {
	const _values = import_react.useMemo(() => Array.isArray(value) ? value : Array.isArray(defaultValue) ? defaultValue : [min, max], [
		value,
		defaultValue,
		min,
		max
	]);
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Root, {
		"data-slot": "slider",
		defaultValue,
		value,
		min,
		max,
		className: cn("relative flex w-full touch-none items-center select-none data-[disabled]:opacity-50 data-[orientation=vertical]:h-full data-[orientation=vertical]:min-h-44 data-[orientation=vertical]:w-auto data-[orientation=vertical]:flex-col", className),
		...props,
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Track, {
			"data-slot": "slider-track",
			className: cn("bg-muted relative grow overflow-hidden rounded-full data-[orientation=horizontal]:h-1.5 data-[orientation=horizontal]:w-full data-[orientation=vertical]:h-full data-[orientation=vertical]:w-1.5"),
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Range, {
				"data-slot": "slider-range",
				className: cn("bg-primary absolute data-[orientation=horizontal]:h-full data-[orientation=vertical]:w-full")
			})
		}), Array.from({ length: _values.length }, (_, index) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Thumb, {
			"data-slot": "slider-thumb",
			className: "border-primary ring-ring/50 block size-4 shrink-0 rounded-full border bg-white shadow-sm transition-[color,box-shadow] hover:ring-4 focus-visible:ring-4 focus-visible:outline-hidden disabled:pointer-events-none disabled:opacity-50"
		}, index))]
	});
}
function AddReadingSessionForm({ books, onSuccess }) {
	const queryClient = useQueryClient();
	const [selectedBookId, setSelectedBookId] = (0, import_react.useState)(null);
	const [pagesRead, setPagesRead] = (0, import_react.useState)([0]);
	const [minutesRead, setMinutesRead] = (0, import_react.useState)([0]);
	const selectedBook = books.find((b) => b.id === selectedBookId);
	const totalPages = selectedBook?.pages || 0;
	const currentPage = selectedBook?.currentPage || 0;
	const remainingPages = Math.max(0, totalPages - currentPage);
	const maxPages = remainingPages > 0 ? remainingPages : 100;
	const createMutation = useMutation({
		mutationFn: createReadingSessionAction,
		onSuccess: (result) => {
			queryClient.invalidateQueries({ queryKey: ["reading-sessions"] });
			if (result.bookCompleted) {
				const toastMessage = `🎉 "${result.bookTitle}" completed!`;
				if (result.goodreadsUrl) {
					const goodreadsUrl = result.goodreadsUrl;
					toast.success(toastMessage, {
						description: "Mark it as read on Goodreads",
						action: {
							label: "Open Goodreads",
							onClick: () => {
								window.open(goodreadsUrl, "_blank");
							}
						},
						duration: 7e3
					});
				} else toast.success(toastMessage, { duration: 5e3 });
			} else toast.success("Reading session added!");
			setSelectedBookId(null);
			setPagesRead([0]);
			setMinutesRead([0]);
			if (onSuccess) onSuccess();
		},
		onError: () => {
			toast.error("Failed to add reading session");
		}
	});
	const handleSubmit = (e) => {
		e.preventDefault();
		if (!selectedBookId) {
			toast.error("Please select a book");
			return;
		}
		if (pagesRead[0] === 0 && minutesRead[0] === 0) {
			toast.error("Please add some reading progress");
			return;
		}
		if (pagesRead[0] > remainingPages && totalPages > 0) {
			toast.error(`You can only log ${remainingPages} more pages for this book`);
			return;
		}
		createMutation.mutate({
			bookId: selectedBookId,
			sessionDate: (/* @__PURE__ */ new Date()).toISOString().split("T")[0],
			pagesRead: pagesRead[0],
			minutesRead: minutesRead[0]
		});
	};
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("form", {
		onSubmit: handleSubmit,
		className: "space-y-6",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "space-y-2",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Label, {
					htmlFor: "book",
					children: "Select Book"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Select, {
					value: selectedBookId?.toString(),
					onValueChange: (value) => {
						setSelectedBookId(parseInt(value));
						setPagesRead([0]);
						setMinutesRead([0]);
					},
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectTrigger, {
						id: "book",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectValue, { placeholder: "Choose a book to read..." })
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectContent, { children: books.map((book) => /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(SelectItem, {
						value: book.id.toString(),
						children: [
							book.title,
							" ",
							book.pages > 0 && `(${book.pages} pages)`
						]
					}, book.id)) })]
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "space-y-3",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "flex items-center justify-between",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Label, {
							className: "flex items-center gap-2",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(BookOpen, { className: "h-4 w-4" }), "Pages Read"]
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
							className: "text-2xl font-bold text-primary",
							children: [pagesRead[0], /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
								className: "text-sm text-muted-foreground ml-1",
								children: ["/ ", remainingPages]
							})]
						})]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Slider, {
						value: pagesRead,
						onValueChange: setPagesRead,
						max: maxPages,
						step: 1,
						disabled: !selectedBookId,
						className: "w-full"
					}),
					selectedBookId && totalPages > 0 && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "text-xs space-y-1",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
							className: "text-muted-foreground",
							children: [
								"Current: page ",
								currentPage,
								" of ",
								totalPages,
								" (",
								Math.round(currentPage / totalPages * 100),
								"%)"
							]
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "text-muted-foreground",
							children: remainingPages > 0 ? `${remainingPages} pages remaining` : "Book completed!"
						})]
					}),
					!selectedBookId && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "text-xs text-muted-foreground",
						children: "Select a book first to set pages"
					})
				]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "space-y-3",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "flex items-center justify-between",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Label, {
							className: "flex items-center gap-2",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Clock, { className: "h-4 w-4" }), "Minutes Read"]
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
							className: "text-2xl font-bold text-primary",
							children: [minutesRead[0], /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "text-sm text-muted-foreground ml-1",
								children: "min"
							})]
						})]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Slider, {
						value: minutesRead,
						onValueChange: setMinutesRead,
						max: 300,
						step: 5,
						disabled: !selectedBookId,
						className: "w-full"
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "text-xs text-muted-foreground",
						children: !selectedBookId ? "Select a book first to set time" : "Drag to set how long you read (up to 5 hours)"
					})
				]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
				type: "submit",
				className: "w-full",
				size: "lg",
				disabled: !selectedBookId || createMutation.isPending,
				children: createMutation.isPending ? "Saving..." : "Add Reading Session"
			})
		]
	});
}
//#endregion
export { AddReadingSessionForm as t };
