import { o as __toESM } from "../_runtime.mjs";
import { t as cva } from "../_libs/class-variance-authority+clsx.mjs";
import { t as cn } from "./utils-oIFR_d28.mjs";
import { u as require_react } from "../_libs/@floating-ui/react-dom+[...].mjs";
import { j as require_jsx_runtime } from "../_libs/@radix-ui/react-alert-dialog+[...].mjs";
import { a as CardHeader, i as CardDescription, n as CardAction, o as CardTitle, r as CardContent, t as Card } from "./card-BxgehY3N.mjs";
import { a as SelectValue, i as SelectTrigger, n as SelectContent, r as SelectItem, t as Select } from "./select-BtVq9f46.mjs";
import { t as useIsMobile } from "./use-mobile-DyMkIwRl.mjs";
import { a as CartesianGrid, i as Area, n as YAxis, o as ResponsiveContainer, r as XAxis, s as Tooltip, t as AreaChart } from "../_libs/recharts+[...].mjs";
import { n as Root2, t as Item2 } from "../_libs/radix-ui__react-toggle-group.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/reading-history-chart-xWMwTWiM.js
var import_react = /* @__PURE__ */ __toESM(require_react());
var import_jsx_runtime = require_jsx_runtime();
var THEMES = {
	light: "",
	dark: ".dark"
};
var ChartContext = import_react.createContext(null);
function useChart() {
	const context = import_react.useContext(ChartContext);
	if (!context) throw new Error("useChart must be used within a <ChartContainer />");
	return context;
}
function ChartContainer({ id, className, children, config, ...props }) {
	const uniqueId = import_react.useId();
	const chartId = `chart-${id || uniqueId.replace(/:/g, "")}`;
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ChartContext.Provider, {
		value: { config },
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			"data-slot": "chart",
			"data-chart": chartId,
			className: cn("[&_.recharts-cartesian-axis-tick_text]:fill-muted-foreground [&_.recharts-cartesian-grid_line[stroke='#ccc']]:stroke-border/50 [&_.recharts-curve.recharts-tooltip-cursor]:stroke-border [&_.recharts-polar-grid_[stroke='#ccc']]:stroke-border [&_.recharts-radial-bar-background-sector]:fill-muted [&_.recharts-rectangle.recharts-tooltip-cursor]:fill-muted [&_.recharts-reference-line_[stroke='#ccc']]:stroke-border flex aspect-video justify-center text-xs [&_.recharts-dot[stroke='#fff']]:stroke-transparent [&_.recharts-layer]:outline-hidden [&_.recharts-sector]:outline-hidden [&_.recharts-sector[stroke='#fff']]:stroke-transparent [&_.recharts-surface]:outline-hidden", className),
			...props,
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(ChartStyle, {
				id: chartId,
				config
			}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ResponsiveContainer, { children })]
		})
	});
}
var ChartStyle = ({ id, config }) => {
	const colorConfig = Object.entries(config).filter(([, config]) => config.theme || config.color);
	if (!colorConfig.length) return null;
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("style", { dangerouslySetInnerHTML: { __html: Object.entries(THEMES).map(([theme, prefix]) => `
${prefix} [data-chart=${id}] {
${colorConfig.map(([key, itemConfig]) => {
		const color = itemConfig.theme?.[theme] || itemConfig.color;
		return color ? `  --color-${key}: ${color};` : null;
	}).join("\n")}
}
`).join("\n") } });
};
var ChartTooltip = Tooltip;
function ChartTooltipContent({ active, payload, className, indicator = "dot", hideLabel = false, hideIndicator = false, label, labelFormatter, labelClassName, formatter, color, nameKey, labelKey }) {
	const { config } = useChart();
	const tooltipLabel = import_react.useMemo(() => {
		if (hideLabel || !payload?.length) return null;
		const [item] = payload;
		const itemConfig = getPayloadConfigFromPayload(config, item, `${labelKey || item?.dataKey || item?.name || "value"}`);
		const value = !labelKey && typeof label === "string" ? config[label]?.label || label : itemConfig?.label;
		if (labelFormatter) return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
			className: cn("font-medium", labelClassName),
			children: labelFormatter(value, payload)
		});
		if (!value) return null;
		return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
			className: cn("font-medium", labelClassName),
			children: value
		});
	}, [
		label,
		labelFormatter,
		payload,
		hideLabel,
		labelClassName,
		config,
		labelKey
	]);
	if (!active || !payload?.length) return null;
	const nestLabel = payload.length === 1 && indicator !== "dot";
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: cn("border-border/50 bg-background grid min-w-[8rem] items-start gap-1.5 rounded-lg border px-2.5 py-1.5 text-xs shadow-xl", className),
		children: [!nestLabel ? tooltipLabel : null, /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
			className: "grid gap-1.5",
			children: payload.filter((item) => item.type !== "none").map((item, index) => {
				const itemConfig = getPayloadConfigFromPayload(config, item, `${nameKey || item.name || item.dataKey || "value"}`);
				const indicatorColor = color || item.payload.fill || item.color;
				return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: cn("[&>svg]:text-muted-foreground flex w-full flex-wrap items-stretch gap-2 [&>svg]:h-2.5 [&>svg]:w-2.5", indicator === "dot" && "items-center"),
					children: formatter && item?.value !== void 0 && item.name ? formatter(item.value, item.name, item, index, item.payload) : /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [itemConfig?.icon ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)(itemConfig.icon, {}) : !hideIndicator && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
						className: cn("shrink-0 rounded-[2px] border-(--color-border) bg-(--color-bg)", {
							"h-2.5 w-2.5": indicator === "dot",
							"w-1": indicator === "line",
							"w-0 border-[1.5px] border-dashed bg-transparent": indicator === "dashed",
							"my-0.5": nestLabel && indicator === "dashed"
						}),
						style: {
							"--color-bg": indicatorColor,
							"--color-border": indicatorColor
						}
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: cn("flex flex-1 justify-between leading-none", nestLabel ? "items-end" : "items-center"),
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "grid gap-1.5",
							children: [nestLabel ? tooltipLabel : null, /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "text-muted-foreground",
								children: itemConfig?.label || item.name
							})]
						}), item.value && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
							className: "text-foreground font-mono font-medium tabular-nums",
							children: item.value.toLocaleString()
						})]
					})] })
				}, item.dataKey);
			})
		})]
	});
}
function getPayloadConfigFromPayload(config, payload, key) {
	if (typeof payload !== "object" || payload === null) return;
	const payloadPayload = "payload" in payload && typeof payload.payload === "object" && payload.payload !== null ? payload.payload : void 0;
	let configLabelKey = key;
	if (key in payload && typeof payload[key] === "string") configLabelKey = payload[key];
	else if (payloadPayload && key in payloadPayload && typeof payloadPayload[key] === "string") configLabelKey = payloadPayload[key];
	return configLabelKey in config ? config[configLabelKey] : config[key];
}
var toggleVariants = cva("inline-flex items-center justify-center gap-2 rounded-md text-sm font-medium hover:bg-muted hover:text-muted-foreground disabled:pointer-events-none disabled:opacity-50 data-[state=on]:bg-accent data-[state=on]:text-accent-foreground [&_svg]:pointer-events-none [&_svg:not([class*='size-'])]:size-4 [&_svg]:shrink-0 focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px] outline-none transition-[color,box-shadow] aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive whitespace-nowrap", {
	variants: {
		variant: {
			default: "bg-transparent",
			outline: "border border-input bg-transparent shadow-xs hover:bg-accent hover:text-accent-foreground"
		},
		size: {
			default: "h-9 px-2 min-w-9",
			sm: "h-8 px-1.5 min-w-8",
			lg: "h-10 px-2.5 min-w-10"
		}
	},
	defaultVariants: {
		variant: "default",
		size: "default"
	}
});
var ToggleGroupContext = import_react.createContext({
	size: "default",
	variant: "default",
	spacing: 0
});
function ToggleGroup({ className, variant, size, spacing = 0, children, ...props }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Root2, {
		"data-slot": "toggle-group",
		"data-variant": variant,
		"data-size": size,
		"data-spacing": spacing,
		style: { "--gap": spacing },
		className: cn("group/toggle-group flex w-fit items-center gap-[--spacing(var(--gap))] rounded-md data-[spacing=default]:data-[variant=outline]:shadow-xs", className),
		...props,
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ToggleGroupContext.Provider, {
			value: {
				variant,
				size,
				spacing
			},
			children
		})
	});
}
function ToggleGroupItem({ className, children, variant, size, ...props }) {
	const context = import_react.useContext(ToggleGroupContext);
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Item2, {
		"data-slot": "toggle-group-item",
		"data-variant": context.variant || variant,
		"data-size": context.size || size,
		"data-spacing": context.spacing,
		className: cn(toggleVariants({
			variant: context.variant || variant,
			size: context.size || size
		}), "w-auto min-w-0 shrink-0 px-3 focus:z-10 focus-visible:z-10", "data-[spacing=0]:rounded-none data-[spacing=0]:shadow-none data-[spacing=0]:first:rounded-l-md data-[spacing=0]:last:rounded-r-md data-[spacing=0]:data-[variant=outline]:border-l-0 data-[spacing=0]:data-[variant=outline]:first:border-l", className),
		...props,
		children
	});
}
var chartConfig = {
	booksRead: {
		label: "Books Read",
		color: "var(--chart-1)"
	},
	pagesRead: {
		label: "Pages Read",
		color: "var(--chart-2)"
	}
};
function ReadingHistoryChart({ data, title = "Reading History", description = "Your reading activity over time" }) {
	useIsMobile();
	const [timeRange, setTimeRange] = import_react.useState("month");
	const [metric, setMetric] = import_react.useState("books");
	const processedData = import_react.useMemo(() => {
		if (data.length === 0) return [];
		if (timeRange === "week") {
			const weeks = /* @__PURE__ */ new Map();
			const now = /* @__PURE__ */ new Date();
			for (let i = 11; i >= 0; i--) {
				const weekStart = new Date(now);
				weekStart.setDate(now.getDate() - i * 7);
				weekStart.setHours(0, 0, 0, 0);
				new Date(weekStart).setDate(weekStart.getDate() + 6);
				const weekKey = `${weekStart.getMonth() + 1}/${weekStart.getDate()}`;
				weeks.set(weekKey, {
					booksRead: 0,
					pagesRead: 0
				});
			}
			data.forEach((item) => {
				const date = new Date(item.period);
				const weekStart = new Date(date);
				const dayOfWeek = date.getDay();
				weekStart.setDate(date.getDate() - dayOfWeek);
				weekStart.setHours(0, 0, 0, 0);
				const weekKey = `${weekStart.getMonth() + 1}/${weekStart.getDate()}`;
				const existing = weeks.get(weekKey);
				if (existing) {
					existing.booksRead += item.booksRead;
					existing.pagesRead += item.pagesRead;
				}
			});
			return Array.from(weeks.entries()).map(([period, values]) => ({
				period,
				booksRead: values.booksRead,
				pagesRead: values.pagesRead
			}));
		} else {
			const months = /* @__PURE__ */ new Map();
			const now = /* @__PURE__ */ new Date();
			for (let i = 11; i >= 0; i--) {
				const monthKey = new Date(now.getFullYear(), now.getMonth() - i, 1).toLocaleDateString("en-US", {
					month: "short",
					year: "numeric"
				});
				months.set(monthKey, {
					booksRead: 0,
					pagesRead: 0
				});
			}
			data.forEach((item) => {
				const monthKey = new Date(item.period).toLocaleDateString("en-US", {
					month: "short",
					year: "numeric"
				});
				const existing = months.get(monthKey);
				if (existing) {
					existing.booksRead += item.booksRead;
					existing.pagesRead += item.pagesRead;
				}
			});
			return Array.from(months.entries()).map(([period, values]) => ({
				period,
				booksRead: values.booksRead,
				pagesRead: values.pagesRead
			}));
		}
	}, [data, timeRange]);
	const maxValue = import_react.useMemo(() => {
		if (processedData.length === 0) return 10;
		const values = metric === "books" ? processedData.map((d) => d.booksRead) : processedData.map((d) => d.pagesRead);
		return Math.max(...values, 1);
	}, [processedData, metric]);
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Card, {
		className: "@container/card",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(CardHeader, { children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardTitle, { children: title }),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(CardDescription, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
				className: "hidden @[540px]/card:block",
				children: description
			}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
				className: "@[540px]/card:hidden",
				children: "Reading activity"
			})] }),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(CardAction, {
				className: "flex flex-col gap-2 @[540px]/card:flex-row",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(ToggleGroup, {
						type: "single",
						value: timeRange,
						onValueChange: (value) => value && setTimeRange(value),
						variant: "outline",
						className: "hidden *:data-[slot=toggle-group-item]:!px-4 @[540px]/card:flex",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(ToggleGroupItem, {
							value: "month",
							children: "By Month"
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ToggleGroupItem, {
							value: "week",
							children: "By Week"
						})]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Select, {
						value: timeRange,
						onValueChange: (value) => setTimeRange(value),
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectTrigger, {
							className: "flex w-32 **:data-[slot=select-value]:block **:data-[slot=select-value]:truncate @[540px]/card:hidden",
							size: "sm",
							"aria-label": "Select time range",
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectValue, { placeholder: "By Month" })
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(SelectContent, {
							className: "rounded-xl",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectItem, {
								value: "month",
								className: "rounded-lg",
								children: "By Month"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectItem, {
								value: "week",
								className: "rounded-lg",
								children: "By Week"
							})]
						})]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(ToggleGroup, {
						type: "single",
						value: metric,
						onValueChange: (value) => value && setMetric(value),
						variant: "outline",
						className: "hidden *:data-[slot=toggle-group-item]:!px-4 @[540px]/card:flex",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(ToggleGroupItem, {
							value: "books",
							children: "Books"
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ToggleGroupItem, {
							value: "pages",
							children: "Pages"
						})]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Select, {
						value: metric,
						onValueChange: (value) => setMetric(value),
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectTrigger, {
							className: "flex w-32 **:data-[slot=select-value]:block **:data-[slot=select-value]:truncate @[540px]/card:hidden",
							size: "sm",
							"aria-label": "Select metric",
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectValue, { placeholder: "Books" })
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(SelectContent, {
							className: "rounded-xl",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectItem, {
								value: "books",
								className: "rounded-lg",
								children: "Books"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(SelectItem, {
								value: "pages",
								className: "rounded-lg",
								children: "Pages"
							})]
						})]
					})
				]
			})
		] }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, {
			className: "px-2 pt-4 sm:px-6 sm:pt-6",
			children: processedData.length === 0 ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "flex h-[250px] items-center justify-center text-muted-foreground",
				children: "No reading data available"
			}) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ChartContainer, {
				config: chartConfig,
				className: "aspect-auto h-[250px] w-full",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(AreaChart, {
					data: processedData,
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("defs", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("linearGradient", {
							id: "fillBooks",
							x1: "0",
							y1: "0",
							x2: "0",
							y2: "1",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("stop", {
								offset: "5%",
								stopColor: "var(--chart-1)",
								stopOpacity: .8
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("stop", {
								offset: "95%",
								stopColor: "var(--chart-1)",
								stopOpacity: .1
							})]
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("linearGradient", {
							id: "fillPages",
							x1: "0",
							y1: "0",
							x2: "0",
							y2: "1",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("stop", {
								offset: "5%",
								stopColor: "var(--chart-2)",
								stopOpacity: .8
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("stop", {
								offset: "95%",
								stopColor: "var(--chart-2)",
								stopOpacity: .1
							})]
						})] }),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)(CartesianGrid, {
							vertical: false,
							strokeDasharray: "3 3",
							opacity: .3
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)(XAxis, {
							dataKey: "period",
							tickLine: false,
							axisLine: false,
							tickMargin: 8,
							minTickGap: 32,
							tick: { fontSize: 12 }
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)(YAxis, {
							tickLine: false,
							axisLine: false,
							tickMargin: 8,
							tick: { fontSize: 12 },
							domain: [0, maxValue]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)(ChartTooltip, {
							cursor: false,
							content: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ChartTooltipContent, {
								labelFormatter: (value) => {
									return timeRange === "month" ? `${value}` : `Week of ${value}`;
								},
								indicator: "dot"
							})
						}),
						metric === "books" ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Area, {
							dataKey: "booksRead",
							type: "monotone",
							fill: "url(#fillBooks)",
							stroke: "var(--chart-1)",
							strokeWidth: 2
						}) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Area, {
							dataKey: "pagesRead",
							type: "monotone",
							fill: "url(#fillPages)",
							stroke: "var(--chart-2)",
							strokeWidth: 2
						})
					]
				})
			})
		})]
	});
}
//#endregion
export { ReadingHistoryChart as t };
