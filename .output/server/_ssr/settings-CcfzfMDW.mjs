import { o as __toESM } from "../_runtime.mjs";
import { u as require_react } from "../_libs/@floating-ui/react-dom+[...].mjs";
import { j as require_jsx_runtime } from "../_libs/@radix-ui/react-alert-dialog+[...].mjs";
import { t as Button } from "./button-PkU2hkqt.mjs";
import { a as CardHeader, i as CardDescription, o as CardTitle, r as CardContent, t as Card } from "./card-BxgehY3N.mjs";
import { n as createServerFn } from "./ssr.mjs";
import { t as createSsrRpc } from "./createSsrRpc-C1p7zOu_.mjs";
import { I as Download, J as BookOpen, c as Target, g as Settings } from "../_libs/lucide-react.mjs";
import { t as Input } from "./input-BO5Hu60S.mjs";
import { t as Label } from "./label-Ca2nQBgL.mjs";
import { t as Skeleton } from "./skeleton-D7Ivmigh.mjs";
import { i as useQueryClient, n as useQuery, t as useMutation } from "../_libs/tanstack__react-query.mjs";
import { n as toast } from "../_libs/sonner.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/settings-CcfzfMDW.js
var import_react = /* @__PURE__ */ __toESM(require_react());
var import_jsx_runtime = require_jsx_runtime();
var updateReadingGoalAction = createServerFn({ method: "POST" }).validator((d) => d).handler(createSsrRpc("8ed6337114281da34d0ce0d7a49d2e34b5c3570a3790adcec3ad26e056ad52ec"));
var exportReadingLogToCsvAction = createServerFn({ method: "GET" }).handler(createSsrRpc("e544e8af51ce7ff324d5f80698e9ff892a3b4678206664e5857614dde6877d7c"));
var getSettingsDataAction = createServerFn({ method: "GET" }).handler(createSsrRpc("388d88d5e2acf7ae7390a2a4cfae5c7cf81bb1d3f2dd027da895395fe23ab666"));
var settingsQueryKey = ["settings"];
function useSettings() {
	return useQuery({
		queryKey: settingsQueryKey,
		queryFn: () => getSettingsDataAction(),
		staleTime: 1e3 * 60 * 5
	});
}
function SettingsForm({ currentGoal }) {
	const queryClient = useQueryClient();
	const [targetBooks, setTargetBooks] = (0, import_react.useState)(currentGoal.targetBooks);
	const [targetPages, setTargetPages] = (0, import_react.useState)(currentGoal.targetPages);
	const updateMutation = useMutation({
		mutationFn: updateReadingGoalAction,
		onSuccess: (result) => {
			if (result.success) {
				toast.success("Reading goal updated successfully!");
				queryClient.invalidateQueries({ queryKey: ["settings"] });
				queryClient.invalidateQueries({ queryKey: ["dashboard"] });
				queryClient.invalidateQueries({ queryKey: ["statistics"] });
			} else toast.error(result.error || "Failed to update goal");
		},
		onError: () => {
			toast.error("Failed to update reading goal");
		}
	});
	const handleSubmit = (e) => {
		e.preventDefault();
		if (targetBooks < 0 || targetPages < 0) {
			toast.error("Targets must be positive numbers");
			return;
		}
		updateMutation.mutate({
			year: currentGoal.year,
			targetBooks,
			targetPages
		});
	};
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("form", {
		onSubmit: handleSubmit,
		className: "space-y-4",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "space-y-2",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Label, {
						htmlFor: "targetBooks",
						className: "flex items-center gap-2",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(BookOpen, { className: "h-4 w-4" }), "Books Target"]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
						id: "targetBooks",
						type: "number",
						min: "0",
						value: targetBooks,
						onChange: (e) => setTargetBooks(parseInt(e.target.value) || 0),
						placeholder: "e.g., 52"
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "text-xs text-muted-foreground",
						children: "Number of books you want to read this year"
					})
				]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "space-y-2",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Label, {
						htmlFor: "targetPages",
						className: "flex items-center gap-2",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Target, { className: "h-4 w-4" }), "Pages Target (Optional)"]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
						id: "targetPages",
						type: "number",
						min: "0",
						value: targetPages,
						onChange: (e) => setTargetPages(parseInt(e.target.value) || 0),
						placeholder: "e.g., 10000"
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "text-xs text-muted-foreground",
						children: "Total pages you want to read this year"
					})
				]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
				type: "submit",
				className: "w-full",
				disabled: updateMutation.isPending,
				children: updateMutation.isPending ? "Saving..." : "Save Goal"
			})
		]
	});
}
function ExportCsvButton() {
	const [isExporting, setIsExporting] = (0, import_react.useState)(false);
	const handleExport = async () => {
		setIsExporting(true);
		try {
			const result = await exportReadingLogToCsvAction();
			if (result.success && result.data) {
				const blob = new Blob([result.data], { type: "text/csv;charset=utf-8;" });
				const url = URL.createObjectURL(blob);
				const link = document.createElement("a");
				link.href = url;
				link.download = `bookjet-reading-log-${(/* @__PURE__ */ new Date()).toISOString().split("T")[0]}.csv`;
				document.body.appendChild(link);
				link.click();
				document.body.removeChild(link);
				URL.revokeObjectURL(url);
				toast.success("Reading log exported successfully!");
			} else toast.error(result.error || "Failed to export");
		} catch (error) {
			toast.error("Failed to export reading log");
		} finally {
			setIsExporting(false);
		}
	};
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Button, {
		onClick: handleExport,
		disabled: isExporting,
		variant: "outline",
		className: "w-full",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Download, { className: "mr-2 h-4 w-4" }), isExporting ? "Exporting..." : "Export to Goodreads CSV"]
	});
}
function SettingsPage() {
	const { data, isLoading } = useSettings();
	const currentYear = (/* @__PURE__ */ new Date()).getFullYear();
	if (isLoading) return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "flex flex-col gap-4 p-4 md:gap-6 md:p-6",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "space-y-2",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Skeleton, { className: "h-9 w-48" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Skeleton, { className: "h-4 w-64" })]
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "grid gap-6 md:grid-cols-2",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Card, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, {
				className: "pt-6",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Skeleton, { className: "h-48 w-full" })
			}) }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Card, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, {
				className: "pt-6",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Skeleton, { className: "h-48 w-full" })
			}) })]
		})]
	});
	const goal = data?.goal;
	const year = data?.currentYear ?? currentYear;
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "flex flex-col gap-4 p-4 md:gap-6 md:p-6",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("h1", {
			className: "text-3xl font-bold tracking-tight flex items-center gap-2",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Settings, { className: "h-8 w-8" }), "Settings"]
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
			className: "text-muted-foreground",
			children: "Manage your reading goals and export your data"
		})] }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "grid gap-6 md:grid-cols-2",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Card, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(CardHeader, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardTitle, { children: "Annual Reading Goal" }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(CardDescription, { children: ["Set your target for ", year] })] }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(SettingsForm, { currentGoal: {
				targetBooks: goal?.targetBooks || 52,
				targetPages: goal?.targetPages || 0,
				year
			} }) })] }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Card, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(CardHeader, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardTitle, { children: "Export Data" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardDescription, { children: "Export your reading log to import into Goodreads" })] }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, {
				className: "space-y-4",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "space-y-2",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "text-sm text-muted-foreground",
						children: "Download your reading log as a CSV file that can be imported directly into Goodreads."
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ExportCsvButton, {})]
				})
			})] })]
		})]
	});
}
//#endregion
export { SettingsPage as component };
