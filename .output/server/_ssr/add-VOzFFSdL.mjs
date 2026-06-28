import { o as __toESM } from "../_runtime.mjs";
import { t as cn } from "./utils-oIFR_d28.mjs";
import { u as require_react } from "../_libs/@floating-ui/react-dom+[...].mjs";
import { j as require_jsx_runtime } from "../_libs/@radix-ui/react-alert-dialog+[...].mjs";
import { a as Slot } from "../_libs/@radix-ui/react-avatar+[...].mjs";
import { t as Button } from "./button-PkU2hkqt.mjs";
import { t as Badge } from "./badge-y-Up9thA.mjs";
import { r as CardContent, t as Card } from "./card-BxgehY3N.mjs";
import { g as useNavigate } from "../_libs/@tanstack/react-router+[...].mjs";
import { a as getAuthorsAction, l as lookupBookByGoodreadsUrl, t as addBookAction, u as lookupBookByISBN } from "./books-B1VN5UCC.mjs";
import { D as LoaderCircle, K as Camera, W as Check, _ as Search, n as X, v as ScanLine, x as Plus, y as ScanBarcode, z as ChevronsUpDown } from "../_libs/lucide-react.mjs";
import { t as Input } from "./input-BO5Hu60S.mjs";
import { a as DialogHeader, i as DialogFooter, n as DialogContent, o as DialogTitle, r as DialogDescription, t as Dialog } from "./dialog-DLnhFQTL.mjs";
import { t as Label } from "./label-Ca2nQBgL.mjs";
import { t as addAuthor } from "./authors-CvrsKKX8.mjs";
import { n as getGenresAction, t as addGenre } from "./genres-DLeE_Pci.mjs";
import { t as _e } from "../_libs/cmdk.mjs";
import { Bt as string, It as number, Lt as object, Pt as literal } from "../_libs/@better-auth/core+[...].mjs";
import { a as useFormContext, i as useForm, n as Controller, o as useFormState, r as FormProvider, t as a } from "../_libs/@hookform/resolvers+[...].mjs";
import { i as Trigger, n as Portal, r as Root2, t as Content2 } from "../_libs/@radix-ui/react-popover+[...].mjs";
import { t as Html5Qrcode } from "../_libs/html5-qrcode.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/add-VOzFFSdL.js
var import_react = /* @__PURE__ */ __toESM(require_react());
var import_jsx_runtime = require_jsx_runtime();
var Form = FormProvider;
var FormFieldContext = import_react.createContext({});
var FormField = ({ ...props }) => {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(FormFieldContext.Provider, {
		value: { name: props.name },
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Controller, { ...props })
	});
};
var useFormField = () => {
	const fieldContext = import_react.useContext(FormFieldContext);
	const itemContext = import_react.useContext(FormItemContext);
	const { getFieldState } = useFormContext();
	const formState = useFormState({ name: fieldContext.name });
	const fieldState = getFieldState(fieldContext.name, formState);
	if (!fieldContext) throw new Error("useFormField should be used within <FormField>");
	const { id } = itemContext;
	return {
		id,
		name: fieldContext.name,
		formItemId: `${id}-form-item`,
		formDescriptionId: `${id}-form-item-description`,
		formMessageId: `${id}-form-item-message`,
		...fieldState
	};
};
var FormItemContext = import_react.createContext({});
function FormItem({ className, ...props }) {
	const id = import_react.useId();
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(FormItemContext.Provider, {
		value: { id },
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
			"data-slot": "form-item",
			className: cn("grid gap-2", className),
			...props
		})
	});
}
function FormLabel({ className, ...props }) {
	const { error, formItemId } = useFormField();
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Label, {
		"data-slot": "form-label",
		"data-error": !!error,
		className: cn("data-[error=true]:text-destructive", className),
		htmlFor: formItemId,
		...props
	});
}
function FormControl({ ...props }) {
	const { error, formItemId, formDescriptionId, formMessageId } = useFormField();
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Slot, {
		"data-slot": "form-control",
		id: formItemId,
		"aria-describedby": !error ? `${formDescriptionId}` : `${formDescriptionId} ${formMessageId}`,
		"aria-invalid": !!error,
		...props
	});
}
function FormMessage({ className, ...props }) {
	const { error, formMessageId } = useFormField();
	const body = error ? String(error?.message ?? "") : props.children;
	if (!body) return null;
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
		"data-slot": "form-message",
		id: formMessageId,
		className: cn("text-destructive text-sm", className),
		...props,
		children: body
	});
}
function Command$1({ className, ...props }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(_e, {
		"data-slot": "command",
		className: cn("bg-popover text-popover-foreground flex h-full w-full flex-col overflow-hidden rounded-md", className),
		...props
	});
}
function CommandInput({ className, ...props }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		"data-slot": "command-input-wrapper",
		className: "flex h-9 items-center gap-2 border-b px-3",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Search, { className: "size-4 shrink-0 opacity-50" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(_e.Input, {
			"data-slot": "command-input",
			className: cn("placeholder:text-muted-foreground flex h-10 w-full rounded-md bg-transparent py-3 text-sm outline-hidden disabled:cursor-not-allowed disabled:opacity-50", className),
			...props
		})]
	});
}
function CommandList({ className, ...props }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(_e.List, {
		"data-slot": "command-list",
		className: cn("max-h-[300px] scroll-py-1 overflow-x-hidden overflow-y-auto", className),
		...props
	});
}
function CommandEmpty({ ...props }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(_e.Empty, {
		"data-slot": "command-empty",
		className: "py-6 text-center text-sm",
		...props
	});
}
function CommandGroup({ className, ...props }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(_e.Group, {
		"data-slot": "command-group",
		className: cn("text-foreground [&_[cmdk-group-heading]]:text-muted-foreground overflow-hidden p-1 [&_[cmdk-group-heading]]:px-2 [&_[cmdk-group-heading]]:py-1.5 [&_[cmdk-group-heading]]:text-xs [&_[cmdk-group-heading]]:font-medium", className),
		...props
	});
}
function CommandItem({ className, ...props }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(_e.Item, {
		"data-slot": "command-item",
		className: cn("data-[selected=true]:bg-accent data-[selected=true]:text-accent-foreground [&_svg:not([class*='text-'])]:text-muted-foreground relative flex cursor-default items-center gap-2 rounded-sm px-2 py-1.5 text-sm outline-hidden select-none data-[disabled=true]:pointer-events-none data-[disabled=true]:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4", className),
		...props
	});
}
function Popover({ ...props }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Root2, {
		"data-slot": "popover",
		...props
	});
}
function PopoverTrigger({ ...props }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Trigger, {
		"data-slot": "popover-trigger",
		...props
	});
}
function PopoverContent({ className, align = "center", sideOffset = 4, ...props }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Portal, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Content2, {
		"data-slot": "popover-content",
		align,
		sideOffset,
		className: cn("bg-popover text-popover-foreground data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 z-50 w-72 origin-(--radix-popover-content-transform-origin) rounded-md border p-4 shadow-md outline-hidden", className),
		...props
	}) });
}
function BarcodeScanner({ onScan, onClose, isOpen }) {
	const scannerRef = (0, import_react.useRef)(null);
	(0, import_react.useRef)(null);
	const [isScanning, setIsScanning] = (0, import_react.useState)(false);
	const [isCapturing, setIsCapturing] = (0, import_react.useState)(false);
	const [error, setError] = (0, import_react.useState)(null);
	const [hasPermission, setHasPermission] = (0, import_react.useState)(null);
	const hasScannedRef = (0, import_react.useRef)(false);
	(0, import_react.useEffect)(() => {
		if (!isOpen) {
			stopScanning();
			hasScannedRef.current = false;
			return;
		}
		hasScannedRef.current = false;
		startScanning();
		return () => {
			stopScanning();
		};
	}, [isOpen]);
	async function startScanning() {
		try {
			setError(null);
			setIsScanning(true);
			const scanner = new Html5Qrcode("barcode-reader");
			scannerRef.current = scanner;
			const cameraConfig = { facingMode: { exact: "environment" } };
			try {
				await scanner.start(cameraConfig, {
					fps: 30,
					qrbox: function(viewfinderWidth, viewfinderHeight) {
						const qrboxSize = Math.floor(Math.min(viewfinderWidth, viewfinderHeight) * .7);
						return {
							width: qrboxSize,
							height: Math.floor(qrboxSize * .6)
						};
					},
					aspectRatio: 1.777778,
					disableFlip: false
				}, (decodedText) => {
					if (hasScannedRef.current) return;
					hasScannedRef.current = true;
					onScan(decodedText);
					stopScanning();
					onClose();
				}, () => {});
			} catch (exactError) {
				await scanner.start({ facingMode: "environment" }, {
					fps: 30,
					qrbox: function(viewfinderWidth, viewfinderHeight) {
						const qrboxSize = Math.floor(Math.min(viewfinderWidth, viewfinderHeight) * .7);
						return {
							width: qrboxSize,
							height: Math.floor(qrboxSize * .6)
						};
					},
					aspectRatio: 1.777778,
					disableFlip: false
				}, (decodedText) => {
					if (hasScannedRef.current) return;
					hasScannedRef.current = true;
					onScan(decodedText);
					stopScanning();
					onClose();
				}, () => {});
			}
			setHasPermission(true);
		} catch (err) {
			if (err.name === "NotAllowedError" || err.toString().includes("Permission denied")) {
				setError("Camera permission denied. Please allow camera access to scan barcodes.");
				setHasPermission(false);
			} else if (err.name === "NotFoundError" || err.toString().includes("No camera found")) {
				setError("No camera found on this device.");
				setHasPermission(false);
			} else if (err.name === "NotReadableError" || err.toString().includes("not readable")) {
				setError("Camera is being used by another app. Please close other apps and try again.");
				setHasPermission(false);
			} else if (err.name === "OverconstrainedError") {
				setError("Camera configuration not supported on this device. Please try a different device.");
				setHasPermission(false);
			} else setError(`Failed to start camera: ${err.message || "Unknown error"}. Please try again.`);
			setIsScanning(false);
		}
	}
	async function stopScanning() {
		if (scannerRef.current) try {
			if (scannerRef.current.getState() === 2) await scannerRef.current.stop();
			if (scannerRef.current) scannerRef.current.clear();
		} catch (err) {} finally {
			scannerRef.current = null;
		}
		setIsScanning(false);
	}
	async function captureAndProcess() {
		const videoElement = document.querySelector("#barcode-reader video");
		if (!videoElement) {
			setError("Camera not ready. Please wait a moment and try again.");
			return;
		}
		try {
			setIsCapturing(true);
			setError(null);
			const canvas = document.createElement("canvas");
			canvas.width = videoElement.videoWidth;
			canvas.height = videoElement.videoHeight;
			const ctx = canvas.getContext("2d");
			if (!ctx) throw new Error("Could not get canvas context");
			ctx.drawImage(videoElement, 0, 0, canvas.width, canvas.height);
			const blob = await new Promise((resolve, reject) => {
				canvas.toBlob((b) => {
					if (b) resolve(b);
					else reject(/* @__PURE__ */ new Error("Failed to create blob"));
				}, "image/jpeg", .95);
			});
			const file = new File([blob], "capture.jpg", { type: "image/jpeg" });
			onScan(await new Html5Qrcode("barcode-reader-temp").scanFile(file, false));
			stopScanning();
			onClose();
		} catch (err) {
			setError("Could not detect barcode in captured image. Try adjusting position and lighting.");
		} finally {
			setIsCapturing(false);
		}
	}
	if (!isOpen) return null;
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
		className: "fixed inset-0 z-50 bg-background/80 backdrop-blur-sm",
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
			className: "fixed inset-0 z-50 flex items-center justify-center p-4",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "relative w-full max-w-lg rounded-lg border bg-background p-6 shadow-lg",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "mb-4 flex items-center justify-between",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "flex items-center gap-2",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Camera, { className: "h-5 w-5" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
								className: "text-lg font-semibold",
								children: "Scan Barcode"
							})]
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
							variant: "ghost",
							size: "icon",
							onClick: () => {
								stopScanning();
								onClose();
							},
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(X, { className: "h-4 w-4" })
						})]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
						id: "barcode-reader-temp",
						className: "hidden"
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "relative overflow-hidden rounded-lg border",
						children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
								id: "barcode-reader",
								className: cn("w-full", error && "hidden")
							}),
							error && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "flex min-h-[300px] flex-col items-center justify-center p-8 text-center",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
									className: "text-sm text-destructive",
									children: error
								}), hasPermission === false && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
									className: "mt-2 text-xs text-muted-foreground",
									children: "Check your browser settings to enable camera access."
								})]
							}),
							isScanning && !error && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
								className: "absolute bottom-4 left-0 right-0 flex justify-center",
								children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Button, {
									onClick: captureAndProcess,
									disabled: isCapturing,
									size: "lg",
									className: "shadow-lg",
									children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(ScanLine, { className: "mr-2 h-5 w-5" }), isCapturing ? "Processing..." : "Capture & Scan"]
								})
							})
						]
					}),
					isScanning && !error && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "mt-4 text-center space-y-1",
						children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "text-sm font-medium text-muted-foreground",
								children: "Position barcode in frame, then click \"Capture & Scan\""
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "text-xs text-muted-foreground",
								children: "📚 ISBN barcodes are usually on the back cover"
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "text-xs text-muted-foreground",
								children: "💡 Tips: Good lighting, keep barcode flat and clear"
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "text-xs text-muted-foreground",
								children: "📱 Works better on iPhone than auto-scanning!"
							})
						]
					}),
					error && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
						className: "mt-4 flex justify-center",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
							variant: "outline",
							onClick: () => {
								setError(null);
								startScanning();
							},
							children: "Try Again"
						})
					})
				]
			})
		})
	});
}
var formSchema = object({
	title: string().min(1, "Title is required"),
	isbn: string().optional(),
	goodreadsUrl: string().url("Must be a valid URL").optional().or(literal("")),
	year: number().int().min(1e3).max(9999).optional().nullable(),
	pages: number().int().min(1).optional().nullable()
});
function AddBookPage() {
	const navigate = useNavigate();
	const [authors, setAuthors] = (0, import_react.useState)([]);
	const [selectedAuthors, setSelectedAuthors] = (0, import_react.useState)([]);
	const [genres, setGenres] = (0, import_react.useState)([]);
	const [selectedGenres, setSelectedGenres] = (0, import_react.useState)([]);
	const [open, setOpen] = (0, import_react.useState)(false);
	const [genreOpen, setGenreOpen] = (0, import_react.useState)(false);
	const [isSubmitting, setIsSubmitting] = (0, import_react.useState)(false);
	const [showAddAuthorDialog, setShowAddAuthorDialog] = (0, import_react.useState)(false);
	const [newAuthorName, setNewAuthorName] = (0, import_react.useState)("");
	const [newAuthorBio, setNewAuthorBio] = (0, import_react.useState)("");
	const [isAddingAuthor, setIsAddingAuthor] = (0, import_react.useState)(false);
	const [showAddGenreDialog, setShowAddGenreDialog] = (0, import_react.useState)(false);
	const [newGenreName, setNewGenreName] = (0, import_react.useState)("");
	const [newGenreDescription, setNewGenreDescription] = (0, import_react.useState)("");
	const [isAddingGenre, setIsAddingGenre] = (0, import_react.useState)(false);
	const [isLookingUp, setIsLookingUp] = (0, import_react.useState)(false);
	const [lookupError, setLookupError] = (0, import_react.useState)(null);
	const [isGoodreadsLookingUp, setIsGoodreadsLookingUp] = (0, import_react.useState)(false);
	const [goodreadsLookupError, setGoodreadsLookupError] = (0, import_react.useState)(null);
	const [showScanner, setShowScanner] = (0, import_react.useState)(false);
	const [bookPreview, setBookPreview] = (0, import_react.useState)(null);
	const form = useForm({
		resolver: a(formSchema),
		defaultValues: {
			title: "",
			isbn: "",
			goodreadsUrl: "",
			year: null,
			pages: null
		}
	});
	(0, import_react.useEffect)(() => {
		async function loadAuthors() {
			setAuthors(await getAuthorsAction());
		}
		loadAuthors();
	}, []);
	(0, import_react.useEffect)(() => {
		async function loadGenres() {
			setGenres(await getGenresAction());
		}
		loadGenres();
	}, []);
	async function onSubmit(values) {
		if (selectedAuthors.length === 0) {
			alert("Please select at least one author");
			return;
		}
		setIsSubmitting(true);
		try {
			const result = await addBookAction({
				title: values.title,
				isbn: values.isbn,
				goodreadsUrl: values.goodreadsUrl,
				year: values.year ?? void 0,
				pages: values.pages ?? void 0,
				authorIds: selectedAuthors.map((a) => a.authorId),
				genreIds: selectedGenres.map((g) => g.genreId),
				coverUrl: bookPreview?.coverUrl,
				description: bookPreview?.description
			});
			if (result.success) navigate({ to: "/dashboard/books" });
			else alert(result.error || "Failed to add book");
		} catch (error) {
			alert("Failed to add book");
		} finally {
			setIsSubmitting(false);
		}
	}
	async function handleAddAuthor() {
		if (!newAuthorName.trim()) {
			alert("Author name is required");
			return;
		}
		setIsAddingAuthor(true);
		try {
			const result = await addAuthor({
				name: newAuthorName.trim(),
				bio: newAuthorBio.trim() || void 0
			});
			if (result.success && result.author) {
				const newAuthor = {
					authorId: result.author.authorId,
					name: result.author.name
				};
				setAuthors((prev) => [...prev, newAuthor].sort((a, b) => a.name.localeCompare(b.name)));
				setSelectedAuthors((prev) => [...prev, newAuthor]);
				setNewAuthorName("");
				setNewAuthorBio("");
				setShowAddAuthorDialog(false);
			} else alert(result.error || "Failed to add author");
		} catch (error) {
			alert("Failed to add author");
		} finally {
			setIsAddingAuthor(false);
		}
	}
	function toggleAuthor(author) {
		setSelectedAuthors((prev) => {
			if (prev.find((a) => a.authorId === author.authorId)) return prev.filter((a) => a.authorId !== author.authorId);
			return [...prev, author];
		});
	}
	function removeAuthor(authorId) {
		setSelectedAuthors((prev) => prev.filter((a) => a.authorId !== authorId));
	}
	async function handleAddGenre() {
		if (!newGenreName.trim()) {
			alert("Genre name is required");
			return;
		}
		setIsAddingGenre(true);
		try {
			const result = await addGenre({
				genreName: newGenreName.trim(),
				description: newGenreDescription.trim() || void 0
			});
			if (result.success && result.genre) {
				const newGenre = {
					genreId: result.genre.genreId,
					genreName: result.genre.genreName
				};
				setGenres((prev) => [...prev, newGenre].sort((a, b) => a.genreName.localeCompare(b.genreName)));
				setSelectedGenres((prev) => [...prev, newGenre]);
				setNewGenreName("");
				setNewGenreDescription("");
				setShowAddGenreDialog(false);
			} else alert(result.error || "Failed to add genre");
		} catch (error) {
			alert("Failed to add genre");
		} finally {
			setIsAddingGenre(false);
		}
	}
	function toggleGenre(genre) {
		setSelectedGenres((prev) => {
			if (prev.find((g) => g.genreId === genre.genreId)) return prev.filter((g) => g.genreId !== genre.genreId);
			return [...prev, genre];
		});
	}
	function removeGenre(genreId) {
		setSelectedGenres((prev) => prev.filter((g) => g.genreId !== genreId));
	}
	async function handleBarcodeScan(barcode) {
		form.setValue("isbn", barcode);
		setIsLookingUp(true);
		setLookupError(null);
		try {
			const result = await lookupBookByISBN(barcode.trim());
			if (!result.success || !result.data) {
				setLookupError(result.error || "Book not found");
				return;
			}
			const { data } = result;
			form.setValue("title", data.title);
			if (data.year) form.setValue("year", data.year);
			if (data.pages) form.setValue("pages", data.pages);
			if (data.goodreadsUrl) form.setValue("goodreadsUrl", data.goodreadsUrl);
			if (data.authors && data.authors.length > 0) {
				const authorsToSelect = [];
				const processedNames = /* @__PURE__ */ new Set();
				for (const authorName of data.authors) {
					const normalizedName = authorName.toLowerCase().trim();
					if (processedNames.has(normalizedName)) continue;
					processedNames.add(normalizedName);
					let existingAuthor = authors.find((a) => a.name.toLowerCase() === normalizedName);
					if (!existingAuthor) {
						const addResult = await addAuthor({ name: authorName.trim() });
						if (addResult.success && addResult.author) {
							const newAuthor = {
								authorId: addResult.author.authorId,
								name: addResult.author.name
							};
							setAuthors((prev) => [...prev, newAuthor].sort((a, b) => a.name.localeCompare(b.name)));
							existingAuthor = newAuthor;
						}
					}
					if (existingAuthor) authorsToSelect.push(existingAuthor);
				}
				setSelectedAuthors(authorsToSelect);
			}
			setBookPreview({
				coverUrl: data.coverUrl,
				description: data.description,
				goodreadsUrl: data.goodreadsUrl
			});
			setLookupError(null);
		} catch (error) {
			console.error("Lookup error:", error);
			setLookupError("An error occurred during lookup");
			setBookPreview(null);
		} finally {
			setIsLookingUp(false);
		}
	}
	async function handleIsbnLookup() {
		const isbn = form.getValues("isbn");
		if (!isbn || !isbn.trim()) {
			setLookupError("Please enter an ISBN first");
			return;
		}
		setIsLookingUp(true);
		setLookupError(null);
		try {
			const result = await lookupBookByISBN(isbn.trim());
			if (!result.success || !result.data) {
				setLookupError(result.error || "Book not found");
				return;
			}
			const { data } = result;
			form.setValue("title", data.title);
			if (data.year) form.setValue("year", data.year);
			if (data.pages) form.setValue("pages", data.pages);
			if (data.goodreadsUrl) form.setValue("goodreadsUrl", data.goodreadsUrl);
			if (data.authors && data.authors.length > 0) {
				const authorsToSelect = [];
				const processedNames = /* @__PURE__ */ new Set();
				for (const authorName of data.authors) {
					const normalizedName = authorName.toLowerCase().trim();
					if (processedNames.has(normalizedName)) continue;
					processedNames.add(normalizedName);
					let existingAuthor = authors.find((a) => a.name.toLowerCase() === normalizedName);
					if (!existingAuthor) {
						const addResult = await addAuthor({ name: authorName.trim() });
						if (addResult.success && addResult.author) {
							const newAuthor = {
								authorId: addResult.author.authorId,
								name: addResult.author.name
							};
							setAuthors((prev) => [...prev, newAuthor].sort((a, b) => a.name.localeCompare(b.name)));
							existingAuthor = newAuthor;
						}
					}
					if (existingAuthor) authorsToSelect.push(existingAuthor);
				}
				setSelectedAuthors(authorsToSelect);
			}
			setBookPreview({
				coverUrl: data.coverUrl,
				description: data.description,
				goodreadsUrl: data.goodreadsUrl
			});
			setLookupError(null);
		} catch (error) {
			console.error("Lookup error:", error);
			setLookupError("An error occurred during lookup");
			setBookPreview(null);
		} finally {
			setIsLookingUp(false);
		}
	}
	async function handleGoodreadsLookup() {
		const goodreadsUrl = form.getValues("goodreadsUrl");
		if (!goodreadsUrl || !goodreadsUrl.trim()) {
			setGoodreadsLookupError("Please enter a Goodreads URL first");
			return;
		}
		setIsGoodreadsLookingUp(true);
		setGoodreadsLookupError(null);
		try {
			const result = await lookupBookByGoodreadsUrl(goodreadsUrl.trim());
			if (!result.success || !result.data) {
				setGoodreadsLookupError(result.error || "Failed to fetch book data");
				return;
			}
			const { data } = result;
			form.setValue("title", data.title);
			if (data.year) form.setValue("year", data.year);
			if (data.pages) form.setValue("pages", data.pages);
			if (data.authors && data.authors.length > 0) {
				const authorsToSelect = [];
				const processedNames = /* @__PURE__ */ new Set();
				for (const authorName of data.authors) {
					const normalizedName = authorName.toLowerCase().trim();
					if (processedNames.has(normalizedName)) continue;
					processedNames.add(normalizedName);
					let existingAuthor = authors.find((a) => a.name.toLowerCase() === normalizedName);
					if (!existingAuthor) {
						const addResult = await addAuthor({ name: authorName.trim() });
						if (addResult.success && addResult.author) {
							const newAuthor = {
								authorId: addResult.author.authorId,
								name: addResult.author.name
							};
							setAuthors((prev) => [...prev, newAuthor].sort((a, b) => a.name.localeCompare(b.name)));
							existingAuthor = newAuthor;
						}
					}
					if (existingAuthor) authorsToSelect.push(existingAuthor);
				}
				setSelectedAuthors(authorsToSelect);
			}
			setBookPreview({
				coverUrl: data.coverUrl,
				description: data.description,
				goodreadsUrl: data.goodreadsUrl
			});
			setGoodreadsLookupError(null);
		} catch (error) {
			console.error("Goodreads lookup error:", error);
			setGoodreadsLookupError("An error occurred during lookup");
			setBookPreview(null);
		} finally {
			setIsGoodreadsLookingUp(false);
		}
	}
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "flex flex-col gap-4 p-4 md:gap-6 md:p-6",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h1", {
			className: "text-2xl font-bold md:text-3xl",
			children: "Add New Book"
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
			className: "mt-2 text-sm text-muted-foreground",
			children: "Add a book to your collection"
		})] }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "mx-auto w-full max-w-2xl",
			children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Form, {
					...form,
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("form", {
						onSubmit: form.handleSubmit(onSubmit),
						className: "space-y-6",
						children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)(FormField, {
								control: form.control,
								name: "isbn",
								render: ({ field }) => /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(FormItem, { children: [
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)(FormLabel, { children: "ISBN" }),
									/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
										className: "flex gap-2",
										children: [
											/* @__PURE__ */ (0, import_jsx_runtime.jsx)(FormControl, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
												placeholder: "Enter ISBN or scan barcode",
												...field
											}) }),
											/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Button, {
												type: "button",
												variant: "outline",
												onClick: () => setShowScanner(true),
												disabled: isLookingUp,
												className: "shrink-0",
												title: "Scan barcode",
												children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(ScanBarcode, { className: "h-4 w-4" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
													className: "ml-2 hidden sm:inline",
													children: "Scan"
												})]
											}),
											/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Button, {
												type: "button",
												variant: "outline",
												onClick: handleIsbnLookup,
												disabled: isLookingUp,
												className: "shrink-0",
												children: [isLookingUp ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)(LoaderCircle, { className: "h-4 w-4 animate-spin" }) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Search, { className: "h-4 w-4" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
													className: "ml-2 hidden sm:inline",
													children: "Lookup"
												})]
											})
										]
									}),
									lookupError && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
										className: "text-sm text-destructive mt-1",
										children: lookupError
									}),
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
										className: "text-sm text-muted-foreground",
										children: "Scan the barcode or enter ISBN manually, then click Lookup"
									}),
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)(FormMessage, {})
								] })
							}),
							bookPreview && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Card, {
								className: "overflow-hidden",
								children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, {
									className: "p-0",
									children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
										className: "flex flex-col gap-4 p-4 sm:flex-row sm:gap-6",
										children: [bookPreview.coverUrl && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
											className: "flex-shrink-0",
											children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("img", {
												src: bookPreview.coverUrl,
												alt: "Book cover",
												className: "h-48 w-auto rounded-md border object-cover shadow-sm sm:h-56"
											})
										}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
											className: "flex-1 space-y-3",
											children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h3", {
												className: "font-semibold text-sm text-muted-foreground uppercase tracking-wide",
												children: "Preview from Goodreads"
											}), bookPreview.goodreadsUrl && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("a", {
												href: bookPreview.goodreadsUrl,
												target: "_blank",
												rel: "noopener noreferrer",
												className: "text-xs text-primary hover:underline",
												children: "View on Goodreads →"
											})] }), bookPreview.description && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
												className: "text-sm text-muted-foreground line-clamp-6",
												children: bookPreview.description
											}) })]
										})]
									})
								})
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)(FormField, {
								control: form.control,
								name: "title",
								render: ({ field }) => /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(FormItem, { children: [
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)(FormLabel, { children: "Title *" }),
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)(FormControl, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
										placeholder: "Enter book title",
										...field
									}) }),
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)(FormMessage, {})
								] })
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "space-y-4",
								children: [
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)(FormLabel, { children: "Authors *" }),
									selectedAuthors.length > 0 && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
										className: "flex flex-wrap gap-2",
										children: selectedAuthors.map((author) => /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Badge, {
											variant: "secondary",
											children: [author.name, /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
												type: "button",
												onClick: () => removeAuthor(author.authorId),
												className: "ml-2 hover:text-destructive",
												children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(X, { className: "h-3 w-3" })
											})]
										}, author.authorId))
									}),
									/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
										className: "flex gap-2",
										children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Popover, {
											open,
											onOpenChange: setOpen,
											children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(PopoverTrigger, {
												asChild: true,
												children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Button, {
													type: "button",
													variant: "outline",
													role: "combobox",
													"aria-expanded": open,
													className: "flex-1 justify-between",
													children: ["Select authors...", /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ChevronsUpDown, { className: "ml-2 h-4 w-4 shrink-0 opacity-50" })]
												})
											}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(PopoverContent, {
												className: "w-[--radix-popover-trigger-width] p-0",
												children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Command$1, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(CommandInput, { placeholder: "Search authors..." }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(CommandList, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(CommandEmpty, { children: "No author found." }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CommandGroup, { children: authors.map((author) => /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(CommandItem, {
													value: author.name,
													onSelect: () => {
														toggleAuthor(author);
													},
													children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Check, { className: cn("mr-2 h-4 w-4", selectedAuthors.find((a) => a.authorId === author.authorId) ? "opacity-100" : "opacity-0") }), author.name]
												}, author.authorId)) })] })] })
											})]
										}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
											type: "button",
											variant: "outline",
											size: "icon",
											onClick: () => setShowAddAuthorDialog(true),
											title: "Add new author",
											children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Plus, { className: "h-4 w-4" })
										})]
									})
								]
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "space-y-4",
								children: [
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)(FormLabel, { children: "Genres" }),
									selectedGenres.length > 0 && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
										className: "flex flex-wrap gap-2",
										children: selectedGenres.map((genre) => /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Badge, {
											variant: "secondary",
											children: [genre.genreName, /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
												type: "button",
												onClick: () => removeGenre(genre.genreId),
												className: "ml-2 hover:text-destructive",
												children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(X, { className: "h-3 w-3" })
											})]
										}, genre.genreId))
									}),
									/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
										className: "flex gap-2",
										children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Popover, {
											open: genreOpen,
											onOpenChange: setGenreOpen,
											children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(PopoverTrigger, {
												asChild: true,
												children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Button, {
													type: "button",
													variant: "outline",
													role: "combobox",
													"aria-expanded": genreOpen,
													className: "flex-1 justify-between",
													children: ["Select genres...", /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ChevronsUpDown, { className: "ml-2 h-4 w-4 shrink-0 opacity-50" })]
												})
											}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(PopoverContent, {
												className: "w-[--radix-popover-trigger-width] p-0",
												children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Command$1, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(CommandInput, { placeholder: "Search genres..." }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(CommandList, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(CommandEmpty, { children: "No genre found." }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CommandGroup, { children: genres.map((genre) => /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(CommandItem, {
													value: genre.genreName,
													onSelect: () => {
														toggleGenre(genre);
													},
													children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Check, { className: cn("mr-2 h-4 w-4", selectedGenres.find((g) => g.genreId === genre.genreId) ? "opacity-100" : "opacity-0") }), genre.genreName]
												}, genre.genreId)) })] })] })
											})]
										}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
											type: "button",
											variant: "outline",
											size: "icon",
											onClick: () => setShowAddGenreDialog(true),
											title: "Add new genre",
											children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Plus, { className: "h-4 w-4" })
										})]
									})
								]
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)(FormField, {
								control: form.control,
								name: "goodreadsUrl",
								render: ({ field }) => /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(FormItem, { children: [
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)(FormLabel, { children: "Goodreads URL" }),
									/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
										className: "flex gap-2",
										children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(FormControl, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
											placeholder: "https://www.goodreads.com/book/show/...",
											...field
										}) }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Button, {
											type: "button",
											variant: "outline",
											onClick: handleGoodreadsLookup,
											disabled: isGoodreadsLookingUp,
											className: "shrink-0",
											children: [isGoodreadsLookingUp ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)(LoaderCircle, { className: "h-4 w-4 animate-spin" }) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Search, { className: "h-4 w-4" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
												className: "ml-2 hidden sm:inline",
												children: "Lookup"
											})]
										})]
									}),
									goodreadsLookupError && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
										className: "text-sm text-destructive mt-1",
										children: goodreadsLookupError
									}),
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
										className: "text-sm text-muted-foreground",
										children: "For books without ISBN, paste Goodreads URL and click Lookup"
									}),
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)(FormMessage, {})
								] })
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "grid grid-cols-1 gap-4 sm:grid-cols-2",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(FormField, {
									control: form.control,
									name: "year",
									render: ({ field }) => /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(FormItem, { children: [
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)(FormLabel, { children: "Publication Year" }),
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)(FormControl, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
											type: "number",
											placeholder: "2024",
											...field,
											onChange: (e) => {
												const value = e.target.value;
												field.onChange(value === "" ? null : parseInt(value));
											},
											value: field.value ?? ""
										}) }),
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)(FormMessage, {})
									] })
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(FormField, {
									control: form.control,
									name: "pages",
									render: ({ field }) => /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(FormItem, { children: [
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)(FormLabel, { children: "Pages" }),
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)(FormControl, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
											type: "number",
											placeholder: "300",
											...field,
											onChange: (e) => {
												const value = e.target.value;
												field.onChange(value === "" ? null : parseInt(value));
											},
											value: field.value ?? ""
										}) }),
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)(FormMessage, {})
									] })
								})]
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "flex flex-col gap-3 sm:flex-row sm:justify-end",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
									type: "button",
									variant: "outline",
									onClick: () => navigate({ to: "/dashboard/books" }),
									className: "w-full sm:w-auto",
									children: "Cancel"
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
									type: "submit",
									disabled: isSubmitting,
									className: "w-full sm:w-auto",
									children: isSubmitting ? "Adding..." : "Add Book"
								})]
							})
						]
					})
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Dialog, {
					open: showAddAuthorDialog,
					onOpenChange: setShowAddAuthorDialog,
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(DialogContent, { children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(DialogHeader, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(DialogTitle, { children: "Add New Author" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(DialogDescription, { children: "Create a new author to add to your collection" })] }),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "space-y-4 py-4",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "space-y-2",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("label", {
									htmlFor: "author-name",
									className: "text-sm font-medium",
									children: "Name *"
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
									id: "author-name",
									placeholder: "Author name",
									value: newAuthorName,
									onChange: (e) => setNewAuthorName(e.target.value)
								})]
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "space-y-2",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("label", {
									htmlFor: "author-bio",
									className: "text-sm font-medium",
									children: "Bio (optional)"
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
									id: "author-bio",
									placeholder: "Brief biography",
									value: newAuthorBio,
									onChange: (e) => setNewAuthorBio(e.target.value)
								})]
							})]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(DialogFooter, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
							type: "button",
							variant: "outline",
							onClick: () => {
								setShowAddAuthorDialog(false);
								setNewAuthorName("");
								setNewAuthorBio("");
							},
							children: "Cancel"
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
							type: "button",
							onClick: handleAddAuthor,
							disabled: isAddingAuthor,
							children: isAddingAuthor ? "Adding..." : "Add Author"
						})] })
					] })
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Dialog, {
					open: showAddGenreDialog,
					onOpenChange: setShowAddGenreDialog,
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(DialogContent, { children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(DialogHeader, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(DialogTitle, { children: "Add New Genre" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(DialogDescription, { children: "Create a new genre to categorize your books" })] }),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "space-y-4 py-4",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "space-y-2",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("label", {
									htmlFor: "genre-name",
									className: "text-sm font-medium",
									children: "Name *"
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
									id: "genre-name",
									placeholder: "Genre name",
									value: newGenreName,
									onChange: (e) => setNewGenreName(e.target.value)
								})]
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "space-y-2",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("label", {
									htmlFor: "genre-description",
									className: "text-sm font-medium",
									children: "Description (optional)"
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
									id: "genre-description",
									placeholder: "Brief description",
									value: newGenreDescription,
									onChange: (e) => setNewGenreDescription(e.target.value)
								})]
							})]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(DialogFooter, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
							type: "button",
							variant: "outline",
							onClick: () => {
								setShowAddGenreDialog(false);
								setNewGenreName("");
								setNewGenreDescription("");
							},
							children: "Cancel"
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
							type: "button",
							onClick: handleAddGenre,
							disabled: isAddingGenre,
							children: isAddingGenre ? "Adding..." : "Add Genre"
						})] })
					] })
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)(BarcodeScanner, {
					isOpen: showScanner,
					onScan: handleBarcodeScan,
					onClose: () => setShowScanner(false)
				})
			]
		})]
	});
}
//#endregion
export { AddBookPage as component };
