import { o as __toESM } from "../_runtime.mjs";
import { t as cn } from "./utils-oIFR_d28.mjs";
import { u as require_react } from "../_libs/@floating-ui/react-dom+[...].mjs";
import { j as require_jsx_runtime } from "../_libs/@radix-ui/react-alert-dialog+[...].mjs";
import { t as Button } from "./button-PkU2hkqt.mjs";
import { t as Badge } from "./badge-y-Up9thA.mjs";
import { r as CardContent, t as Card } from "./card-BxgehY3N.mjs";
import { n as createServerFn } from "./ssr.mjs";
import { t as createSsrRpc } from "./createSsrRpc-C1p7zOu_.mjs";
import { i as getAllBooksAction } from "./books-B1VN5UCC.mjs";
import { C as Pencil, D as LoaderCircle, F as EllipsisVertical, J as BookOpen, W as Check, b as Quote, f as Star, h as Share2, s as Trash2, x as Plus } from "../_libs/lucide-react.mjs";
import { t as Input } from "./input-BO5Hu60S.mjs";
import { a as DialogHeader, n as DialogContent, o as DialogTitle, r as DialogDescription, s as DialogTrigger, t as Dialog } from "./dialog-DLnhFQTL.mjs";
import { t as Label } from "./label-Ca2nQBgL.mjs";
import { n as CheckboxIndicator, t as Checkbox$1 } from "../_libs/@radix-ui/react-checkbox+[...].mjs";
import { t as Skeleton } from "./skeleton-D7Ivmigh.mjs";
import { n as useQuery } from "../_libs/tanstack__react-query.mjs";
import { a as SelectValue, i as SelectTrigger, n as SelectContent, r as SelectItem, t as Select } from "./select-BtVq9f46.mjs";
import { i as DropdownMenuItem, o as DropdownMenuSeparator, r as DropdownMenuContent, s as DropdownMenuTrigger, t as DropdownMenu } from "./dropdown-menu-Dzvn-mwZ.mjs";
import { n as toast } from "../_libs/sonner.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/quotes-Cfdtwhqt.js
var import_react = /* @__PURE__ */ __toESM(require_react());
var import_jsx_runtime = require_jsx_runtime();
var createQuoteAction = createServerFn({ method: "POST" }).validator((d) => d).handler(createSsrRpc("5be86db5a7c3be44b7ead75eb13a7cc18430e0d98e526f7b6396435b673621af"));
var updateQuoteAction = createServerFn({ method: "POST" }).validator((d) => d).handler(createSsrRpc("f2c7b8eb645901ff1b264169558edd0b9a5a3d802348b1645e280ad69b7c49f8"));
var deleteQuoteAction = createServerFn({ method: "POST" }).validator((d) => d).handler(createSsrRpc("bd81548eab56db8f8b670e277c60efa81de4937a717e3e393c42902faeaee2d8"));
var toggleQuoteFavoriteAction = createServerFn({ method: "POST" }).validator((d) => d).handler(createSsrRpc("115930e6ab838671b9e8597b1eb07fc45c277b9a70363eeef4c2af3f59707cfe"));
var getQuotesDataAction = createServerFn({ method: "GET" }).handler(createSsrRpc("0f4470ee978b0ac56785452903cbd9c680bc6e3a5e9814d0549ab2d266344f2f"));
var quotesQueryKey = ["quotes"];
function useQuotes() {
	return useQuery({
		queryKey: quotesQueryKey,
		queryFn: () => getQuotesDataAction(),
		staleTime: 1e3 * 60 * 2
	});
}
function Textarea({ className, ...props }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("textarea", {
		"data-slot": "textarea",
		className: cn("border-input placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-ring/50 aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive dark:bg-input/30 flex field-sizing-content min-h-16 w-full rounded-md border bg-transparent px-3 py-2 text-base shadow-xs transition-[color,box-shadow] outline-none focus-visible:ring-[3px] disabled:cursor-not-allowed disabled:opacity-50 md:text-sm", className),
		...props
	});
}
function Checkbox({ className, ...props }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Checkbox$1, {
		"data-slot": "checkbox",
		className: cn("peer border-input dark:bg-input/30 data-[state=checked]:bg-primary data-[state=checked]:text-primary-foreground dark:data-[state=checked]:bg-primary data-[state=checked]:border-primary focus-visible:border-ring focus-visible:ring-ring/50 aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive size-4 shrink-0 rounded-[4px] border shadow-xs transition-shadow outline-none focus-visible:ring-[3px] disabled:cursor-not-allowed disabled:opacity-50", className),
		...props,
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CheckboxIndicator, {
			"data-slot": "checkbox-indicator",
			className: "grid place-content-center text-current transition-none",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Check, { className: "size-3.5" })
		})
	});
}
function QuoteForm({ quote, onSuccess }) {
	const [isSubmitting, setIsSubmitting] = (0, import_react.useState)(false);
	const [books, setBooks] = (0, import_react.useState)([]);
	const [loadingBooks, setLoadingBooks] = (0, import_react.useState)(true);
	const [formData, setFormData] = (0, import_react.useState)({
		bookId: quote?.bookId || 0,
		quoteText: quote?.quoteText || "",
		pageNumber: quote?.pageNumber?.toString() || "",
		chapter: quote?.chapter || "",
		tags: quote?.tags?.join(", ") || "",
		isFavorite: quote?.isFavorite || false,
		notes: quote?.notes || ""
	});
	(0, import_react.useEffect)(() => {
		async function loadBooks() {
			try {
				setBooks(await getAllBooksAction() || []);
			} catch (error) {
				toast.error("Failed to load books");
			} finally {
				setLoadingBooks(false);
			}
		}
		loadBooks();
	}, []);
	const handleSubmit = async (e) => {
		e.preventDefault();
		if (!formData.bookId) {
			toast.error("Please select a book");
			return;
		}
		if (!formData.quoteText.trim()) {
			toast.error("Please enter the quote text");
			return;
		}
		setIsSubmitting(true);
		try {
			const data = {
				bookId: formData.bookId,
				quoteText: formData.quoteText.trim(),
				pageNumber: formData.pageNumber ? parseInt(formData.pageNumber) : void 0,
				chapter: formData.chapter.trim() || void 0,
				tags: formData.tags ? formData.tags.split(",").map((tag) => tag.trim()).filter(Boolean) : void 0,
				isFavorite: formData.isFavorite,
				notes: formData.notes.trim() || void 0
			};
			let result;
			if (quote) result = await updateQuoteAction(quote.quoteId, data);
			else result = await createQuoteAction(data);
			if (result.success) {
				toast.success(quote ? "Quote updated!" : "Quote added!");
				onSuccess();
				window.location.reload();
			} else toast.error(result.error || "Failed to save quote");
		} catch (error) {
			toast.error("An error occurred");
		} finally {
			setIsSubmitting(false);
		}
	};
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("form", {
		onSubmit: handleSubmit,
		className: "space-y-4",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "space-y-2",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Label, {
					htmlFor: "book",
					children: "Book *"
				}), loadingBooks ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "flex items-center gap-2 text-sm text-muted-foreground",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(LoaderCircle, { className: "h-4 w-4 animate-spin" }), "Loading books..."]
				}) : /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Select, {
					value: formData.bookId.toString(),
					onValueChange: (value) => setFormData({
						...formData,
						bookId: parseInt(value)
					}),
					disabled: !!quote,
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectTrigger, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectValue, { placeholder: "Select a book" }) }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectContent, { children: books.map((book) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectItem, {
						value: book.bookId.toString(),
						children: book.title
					}, book.bookId)) })]
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "space-y-2",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Label, {
					htmlFor: "quoteText",
					children: "Quote *"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Textarea, {
					id: "quoteText",
					placeholder: "Enter the quote text...",
					value: formData.quoteText,
					onChange: (e) => setFormData({
						...formData,
						quoteText: e.target.value
					}),
					rows: 5,
					required: true
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "grid grid-cols-2 gap-4",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "space-y-2",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Label, {
						htmlFor: "pageNumber",
						children: "Page Number"
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
						id: "pageNumber",
						type: "number",
						placeholder: "123",
						value: formData.pageNumber,
						onChange: (e) => setFormData({
							...formData,
							pageNumber: e.target.value
						})
					})]
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "space-y-2",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Label, {
						htmlFor: "chapter",
						children: "Chapter"
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
						id: "chapter",
						placeholder: "Chapter 5",
						value: formData.chapter,
						onChange: (e) => setFormData({
							...formData,
							chapter: e.target.value
						})
					})]
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "space-y-2",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Label, {
						htmlFor: "tags",
						children: "Tags"
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
						id: "tags",
						placeholder: "inspiration, wisdom, favorite (comma-separated)",
						value: formData.tags,
						onChange: (e) => setFormData({
							...formData,
							tags: e.target.value
						})
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "text-xs text-muted-foreground",
						children: "Separate multiple tags with commas"
					})
				]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "space-y-2",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Label, {
					htmlFor: "notes",
					children: "Personal Notes"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Textarea, {
					id: "notes",
					placeholder: "Why this quote resonates with you...",
					value: formData.notes,
					onChange: (e) => setFormData({
						...formData,
						notes: e.target.value
					}),
					rows: 3
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex items-center gap-2",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Checkbox, {
					id: "isFavorite",
					checked: formData.isFavorite,
					onCheckedChange: (checked) => setFormData({
						...formData,
						isFavorite: checked
					})
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Label, {
					htmlFor: "isFavorite",
					className: "flex items-center gap-1 cursor-pointer",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Star, { className: `h-4 w-4 ${formData.isFavorite ? "fill-yellow-500 text-yellow-500" : ""}` }), "Mark as favorite"]
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "flex gap-2 justify-end pt-4",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Button, {
					type: "submit",
					disabled: isSubmitting,
					children: [isSubmitting && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(LoaderCircle, { className: "h-4 w-4 mr-2 animate-spin" }), quote ? "Update Quote" : "Add Quote"]
				})
			})
		]
	});
}
function AddQuoteButton({ variant = "outline" }) {
	const [isOpen, setIsOpen] = (0, import_react.useState)(false);
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Dialog, {
		open: isOpen,
		onOpenChange: setIsOpen,
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(DialogTrigger, {
			asChild: true,
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Button, {
				variant,
				size: "sm",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Plus, { className: "h-4 w-4 mr-2" }), "Add Quote"]
			})
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(DialogContent, {
			className: "sm:max-w-[600px] max-h-[90vh] overflow-y-auto",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(DialogHeader, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(DialogTitle, { children: "Add New Quote" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(DialogDescription, { children: "Save a memorable quote or passage from a book" })] }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(QuoteForm, { onSuccess: () => setIsOpen(false) })]
		})]
	});
}
function EditQuoteDialog({ quote, book, isOpen, onClose }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Dialog, {
		open: isOpen,
		onOpenChange: onClose,
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(DialogContent, {
			className: "sm:max-w-[600px] max-h-[90vh] overflow-y-auto",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(DialogHeader, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(DialogTitle, { children: "Edit Quote" }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(DialogDescription, { children: ["Update your quote from ", book.title] })] }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(QuoteForm, {
				quote,
				onSuccess: onClose
			})]
		})
	});
}
function QuoteCard({ quote, book, authors }) {
	const [isFavorite, setIsFavorite] = (0, import_react.useState)(quote.isFavorite || false);
	const [isEditOpen, setIsEditOpen] = (0, import_react.useState)(false);
	const [isDeleting, setIsDeleting] = (0, import_react.useState)(false);
	const handleToggleFavorite = async () => {
		try {
			await toggleQuoteFavoriteAction(quote.quoteId);
			setIsFavorite(!isFavorite);
			toast.success(isFavorite ? "Removed from favorites" : "Added to favorites");
		} catch (error) {
			toast.error("Failed to update favorite status");
		}
	};
	const handleDelete = async () => {
		if (!confirm("Are you sure you want to delete this quote?")) return;
		setIsDeleting(true);
		try {
			await deleteQuoteAction(quote.quoteId);
			toast.success("Quote deleted");
			window.location.reload();
		} catch (error) {
			toast.error("Failed to delete quote");
			setIsDeleting(false);
		}
	};
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Card, {
		className: `relative ${isFavorite ? "border-yellow-500/50" : ""}`,
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(CardContent, {
			className: "pt-6",
			children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "flex items-start justify-between gap-2 mb-3",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "flex-1 min-w-0",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
							className: "font-semibold text-lg line-clamp-1",
							children: book.title
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "text-sm text-muted-foreground line-clamp-1",
							children: authors
						})]
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "flex items-center gap-1",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
							variant: "ghost",
							size: "icon",
							onClick: handleToggleFavorite,
							className: "h-8 w-8",
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Star, { className: `h-4 w-4 ${isFavorite ? "fill-yellow-500 text-yellow-500" : ""}` })
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(DropdownMenu, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(DropdownMenuTrigger, {
							asChild: true,
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
								variant: "ghost",
								size: "icon",
								className: "h-8 w-8",
								children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(EllipsisVertical, { className: "h-4 w-4" })
							})
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(DropdownMenuContent, {
							align: "end",
							children: [
								/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(DropdownMenuItem, {
									onClick: () => setIsEditOpen(true),
									children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Pencil, { className: "h-4 w-4 mr-2" }), "Edit"]
								}),
								/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(DropdownMenuItem, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Share2, { className: "h-4 w-4 mr-2" }), "Share"] }),
								/* @__PURE__ */ (0, import_jsx_runtime.jsx)(DropdownMenuSeparator, {}),
								/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(DropdownMenuItem, {
									onClick: handleDelete,
									disabled: isDeleting,
									className: "text-destructive",
									children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Trash2, { className: "h-4 w-4 mr-2" }), "Delete"]
								})
							]
						})] })]
					})]
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("blockquote", {
					className: "border-l-4 border-primary pl-4 py-2 mb-3",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
						className: "text-base italic leading-relaxed",
						children: [
							"\"",
							quote.quoteText,
							"\""
						]
					})
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "flex flex-wrap items-center gap-2 text-sm text-muted-foreground mb-3",
					children: [quote.pageNumber && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
						className: "flex items-center gap-1",
						children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)(BookOpen, { className: "h-3 w-3" }),
							"Page ",
							quote.pageNumber
						]
					}), quote.chapter && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", { children: ["• ", quote.chapter] })]
				}),
				quote.tags && quote.tags.length > 0 && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "flex flex-wrap gap-1 mb-3",
					children: quote.tags.map((tag) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Badge, {
						variant: "secondary",
						className: "text-xs",
						children: tag
					}, tag))
				}),
				quote.notes && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "mt-3 pt-3 border-t",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "text-sm text-muted-foreground",
						children: quote.notes
					})
				})
			]
		})
	}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(EditQuoteDialog, {
		quote,
		book,
		isOpen: isEditOpen,
		onClose: () => setIsEditOpen(false)
	})] });
}
function QuotesClient() {
	const { data, isLoading } = useQuotes();
	const quotes = data?.quotes ?? [];
	const stats = data?.stats ?? {
		totalQuotes: 0,
		favoriteQuotes: 0,
		booksWithQuotes: 0
	};
	if (isLoading) return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "flex flex-col gap-4 p-4 md:gap-6 md:p-6",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Skeleton, { className: "h-10 w-64" }),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "grid gap-4 sm:grid-cols-3",
				children: [...Array(3)].map((_, i) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Skeleton, { className: "h-24" }, i))
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "grid gap-4 md:grid-cols-2",
				children: [...Array(4)].map((_, i) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Skeleton, { className: "h-40" }, i))
			})
		]
	});
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "flex flex-col gap-4 p-4 md:gap-6 md:p-6",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex items-center justify-between",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("h1", {
					className: "text-3xl font-bold tracking-tight flex items-center gap-2",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Quote, { className: "h-8 w-8" }), "Quotes & Highlights"]
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "text-muted-foreground",
					children: "Your collection of memorable passages"
				})] }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(AddQuoteButton, {})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "grid gap-4 sm:grid-cols-3",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Card, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, {
						className: "pt-6",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "flex items-center justify-between",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "space-y-1",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
									className: "text-sm text-muted-foreground",
									children: "Total Quotes"
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
									className: "text-3xl font-bold",
									children: stats.totalQuotes
								})]
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Quote, { className: "h-8 w-8 text-muted-foreground" })]
						})
					}) }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Card, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, {
						className: "pt-6",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "flex items-center justify-between",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "space-y-1",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
									className: "text-sm text-muted-foreground",
									children: "Favorites"
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
									className: "text-3xl font-bold",
									children: stats.favoriteQuotes
								})]
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Star, { className: "h-8 w-8 text-yellow-500 fill-yellow-500" })]
						})
					}) }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Card, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, {
						className: "pt-6",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "flex items-center justify-between",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "space-y-1",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
									className: "text-sm text-muted-foreground",
									children: "Books with Quotes"
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
									className: "text-3xl font-bold",
									children: stats.booksWithQuotes
								})]
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(BookOpen, { className: "h-8 w-8 text-muted-foreground" })]
						})
					}) })
				]
			}),
			quotes.length === 0 ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Card, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(CardContent, {
				className: "flex flex-col items-center justify-center py-12",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Quote, { className: "h-12 w-12 text-muted-foreground mb-4" }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
						className: "text-lg font-semibold mb-2",
						children: "No quotes yet"
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "text-sm text-muted-foreground mb-4 text-center max-w-sm",
						children: "Start saving your favorite quotes and memorable passages from the books you read"
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(AddQuoteButton, { variant: "default" })
				]
			}) }) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "grid gap-4 md:grid-cols-2",
				children: quotes.map((item) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(QuoteCard, {
					quote: item.quote,
					book: item.book,
					authors: item.authors || "Unknown"
				}, item.quote.quoteId))
			})
		]
	});
}
var SplitComponent = () => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(QuotesClient, {});
//#endregion
export { SplitComponent as component };
