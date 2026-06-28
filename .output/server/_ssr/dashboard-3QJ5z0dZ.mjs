import { o as __toESM } from "../_runtime.mjs";
import { u as require_react } from "../_libs/@floating-ui/react-dom+[...].mjs";
import { j as require_jsx_runtime } from "../_libs/@radix-ui/react-alert-dialog+[...].mjs";
import { t as Button } from "./button-PkU2hkqt.mjs";
import { t as Badge } from "./badge-y-Up9thA.mjs";
import { a as CardHeader, o as CardTitle, r as CardContent, t as Card } from "./card-BxgehY3N.mjs";
import { h as Link } from "../_libs/@tanstack/react-router+[...].mjs";
import { n as createServerFn } from "./ssr.mjs";
import { t as createSsrRpc } from "./createSsrRpc-C1p7zOu_.mjs";
import { H as ChevronLeft, I as Download, J as BookOpen, L as Clock, M as Flame, N as FileText, V as ChevronRight, X as Award, a as Trophy, c as Target, f as Star, h as Share2, n as X, o as TrendingUp, p as Sparkles, q as Calendar, t as Zap } from "../_libs/lucide-react.mjs";
import { t as Skeleton } from "./skeleton-D7Ivmigh.mjs";
import { n as useQuery } from "../_libs/tanstack__react-query.mjs";
import { n as toast } from "../_libs/sonner.mjs";
import { a as TooltipTrigger, i as TooltipProvider, n as Tooltip, r as TooltipContent, t as AddReadingSessionDialog } from "./add-reading-session-dialog-Dhb6Qyks.mjs";
import { t as ReadingHistoryChart } from "./reading-history-chart-xWMwTWiM.mjs";
import { t as toPng } from "../_libs/html-to-image.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/dashboard-3QJ5z0dZ.js
var import_react = /* @__PURE__ */ __toESM(require_react());
var import_jsx_runtime = require_jsx_runtime();
var getDashboardDataAction = createServerFn({ method: "GET" }).handler(createSsrRpc("e88e2b677ff9038f1b2447f05172258080dbdfa3122214d38a3653e5d392d63b"));
var dashboardQueryKey = ["dashboard"];
function useDashboardData() {
	return useQuery({
		queryKey: dashboardQueryKey,
		queryFn: () => getDashboardDataAction(),
		staleTime: 1e3 * 60 * 2
	});
}
function ReadingHeatmap({ data, currentStreak = 0, bestStreak = 0 }) {
	const heatmapData = (0, import_react.useMemo)(() => {
		const today = /* @__PURE__ */ new Date();
		const days = [];
		const activityMap = /* @__PURE__ */ new Map();
		data.forEach((activity) => {
			activityMap.set(activity.date, activity);
		});
		for (let i = 364; i >= 0; i--) {
			const date = new Date(today);
			date.setDate(date.getDate() - i);
			date.setHours(0, 0, 0, 0);
			const dateStr = date.toISOString().split("T")[0];
			const activity = activityMap.get(dateStr);
			days.push({
				date: dateStr,
				dayOfWeek: date.getDay(),
				pagesRead: activity?.pagesRead || 0,
				minutesRead: activity?.minutesRead || 0,
				sessionCount: activity?.sessionCount || 0
			});
		}
		return days;
	}, [data]);
	const weeks = (0, import_react.useMemo)(() => {
		const weeksList = [];
		let currentWeek = [];
		heatmapData.forEach((day, index) => {
			if (index === 0 && day.dayOfWeek !== 0) for (let i = 0; i < day.dayOfWeek; i++) currentWeek.push({
				date: "",
				dayOfWeek: i,
				pagesRead: 0,
				minutesRead: 0,
				sessionCount: 0
			});
			currentWeek.push(day);
			if (day.dayOfWeek === 6 || index === heatmapData.length - 1) {
				weeksList.push([...currentWeek]);
				currentWeek = [];
			}
		});
		return weeksList;
	}, [heatmapData]);
	const getColorClass = (pagesRead) => {
		if (pagesRead === 0) return "bg-secondary hover:bg-secondary/80";
		if (pagesRead < 20) return "bg-emerald-200 dark:bg-emerald-900 hover:bg-emerald-300 dark:hover:bg-emerald-800";
		if (pagesRead < 50) return "bg-emerald-400 dark:bg-emerald-700 hover:bg-emerald-500 dark:hover:bg-emerald-600";
		if (pagesRead < 100) return "bg-emerald-600 dark:bg-emerald-500 hover:bg-emerald-700 dark:hover:bg-emerald-400";
		return "bg-emerald-800 dark:bg-emerald-300 hover:bg-emerald-900 dark:hover:bg-emerald-200";
	};
	const formatDate = (dateStr) => {
		if (!dateStr) return "";
		return new Date(dateStr).toLocaleDateString("en-US", {
			month: "short",
			day: "numeric",
			year: "numeric"
		});
	};
	const months = [
		"Jan",
		"Feb",
		"Mar",
		"Apr",
		"May",
		"Jun",
		"Jul",
		"Aug",
		"Sep",
		"Oct",
		"Nov",
		"Dec"
	];
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Card, {
		className: "w-full",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardHeader, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			className: "flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(CardTitle, {
				className: "flex items-center gap-2",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Flame, { className: "h-5 w-5 text-orange-500" }), "Reading Activity"]
			}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex gap-4 text-sm",
				children: [currentStreak > 0 && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "flex items-center gap-1",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Flame, { className: "h-4 w-4 text-orange-500" }),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
							className: "font-semibold",
							children: currentStreak
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
							className: "text-muted-foreground",
							children: "day streak"
						})
					]
				}), bestStreak > 0 && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "flex items-center gap-1",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
							className: "text-muted-foreground",
							children: "Best:"
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
							className: "font-semibold",
							children: bestStreak
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
							className: "text-muted-foreground",
							children: "days"
						})
					]
				})]
			})]
		}) }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, {
			className: "pb-6 overflow-x-auto",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "min-w-max",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(TooltipProvider, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "flex flex-col gap-1",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "flex gap-1",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "w-10" }), weeks.map((week, weekIndex) => {
								const firstDay = week.find((d) => d.date);
								if (!firstDay) return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "w-3.5" }, weekIndex);
								const date = new Date(firstDay.date);
								return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
									className: "w-3.5",
									children: date.getDate() <= 7 && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
										className: "text-[10px] text-muted-foreground font-medium",
										children: months[date.getMonth()]
									})
								}, weekIndex);
							})]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "flex gap-1",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
								className: "flex flex-col gap-1",
								children: [
									"Sun",
									"Mon",
									"Tue",
									"Wed",
									"Thu",
									"Fri",
									"Sat"
								].map((day, i) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
									className: "h-3.5 w-10 flex items-center",
									children: i % 2 === 1 && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
										className: "text-[10px] text-muted-foreground font-medium",
										children: day
									})
								}, i))
							}), weeks.map((week, weekIndex) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
								className: "flex flex-col gap-1",
								children: Array.from({ length: 7 }).map((_, dayIndex) => {
									const dayData = week.find((d) => d.dayOfWeek === dayIndex);
									if (!dayData || !dayData.date) return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "h-3.5 w-3.5" }, dayIndex);
									return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Tooltip, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(TooltipTrigger, {
										asChild: true,
										children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: `h-3.5 w-3.5 rounded-sm transition-colors cursor-pointer ${getColorClass(dayData.pagesRead)}` })
									}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(TooltipContent, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
										className: "text-sm",
										children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
											className: "font-semibold",
											children: formatDate(dayData.date)
										}), dayData.sessionCount > 0 ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [
											/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", { children: [dayData.pagesRead, " pages"] }),
											/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", { children: [dayData.minutesRead, " minutes"] }),
											/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", { children: [
												dayData.sessionCount,
												" session",
												dayData.sessionCount > 1 ? "s" : ""
											] })
										] }) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
											className: "text-muted-foreground",
											children: "No reading activity"
										})]
									}) })] }, dayIndex);
								})
							}, weekIndex))]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "flex items-center gap-2 mt-4 text-xs text-muted-foreground",
							children: [
								/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
									className: "font-medium",
									children: "Less"
								}),
								/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
									className: "flex gap-1",
									children: [
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "h-3.5 w-3.5 rounded-sm bg-secondary border border-muted" }),
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "h-3.5 w-3.5 rounded-sm bg-emerald-200 dark:bg-emerald-900" }),
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "h-3.5 w-3.5 rounded-sm bg-emerald-400 dark:bg-emerald-700" }),
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "h-3.5 w-3.5 rounded-sm bg-emerald-600 dark:bg-emerald-500" }),
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "h-3.5 w-3.5 rounded-sm bg-emerald-800 dark:bg-emerald-300" })
									]
								}),
								/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
									className: "font-medium",
									children: "More"
								})
							]
						})
					]
				}) })
			})
		})]
	});
}
var ShareableRecapCard = (0, import_react.forwardRef)(({ data }, ref) => {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		ref,
		style: {
			position: "relative",
			overflow: "hidden",
			width: "1080px",
			height: "1920px",
			background: "linear-gradient(135deg, #0f2027 0%, #203a43 25%, #2c5364 50%, #0f2027 100%)",
			fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Segoe UI', sans-serif"
		},
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			style: {
				position: "absolute",
				inset: 0,
				overflow: "hidden"
			},
			children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { style: {
					position: "absolute",
					top: "-10%",
					left: "-5%",
					width: "600px",
					height: "600px",
					background: "radial-gradient(circle, rgba(0, 122, 255, 0.4) 0%, transparent 70%)",
					borderRadius: "9999px",
					filter: "blur(80px)"
				} }),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { style: {
					position: "absolute",
					bottom: "-10%",
					right: "-5%",
					width: "700px",
					height: "700px",
					background: "radial-gradient(circle, rgba(88, 86, 214, 0.3) 0%, transparent 70%)",
					borderRadius: "9999px",
					filter: "blur(80px)"
				} }),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { style: {
					position: "absolute",
					top: "30%",
					right: "10%",
					width: "400px",
					height: "400px",
					background: "radial-gradient(circle, rgba(94, 92, 230, 0.25) 0%, transparent 70%)",
					borderRadius: "9999px",
					filter: "blur(60px)"
				} }),
				[...Array(20)].map((_, i) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { style: {
					position: "absolute",
					borderRadius: "9999px",
					background: "rgba(255,255,255,0.15)",
					width: Math.random() * 6 + 3 + "px",
					height: Math.random() * 6 + 3 + "px",
					left: Math.random() * 100 + "%",
					top: Math.random() * 100 + "%"
				} }, i))
			]
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
			style: {
				position: "relative",
				zIndex: 10,
				minHeight: "100%",
				display: "flex",
				flexDirection: "column",
				alignItems: "center",
				justifyContent: "center",
				padding: "5rem 4rem"
			},
			children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					style: {
						textAlign: "center",
						marginBottom: "3rem"
					},
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h1", {
						style: {
							fontSize: "3rem",
							fontWeight: 900,
							color: "white",
							marginBottom: "0.25rem",
							textShadow: "0 0 50px rgba(255,255,255,0.5), 0 8px 30px rgba(0,0,0,0.3)"
						},
						children: "My Reading"
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("h2", {
						style: {
							fontSize: "4rem",
							fontWeight: 900,
							color: "white",
							textShadow: "0 0 30px rgba(255,255,255,0.4), 0 6px 20px rgba(0,0,0,0.3)"
						},
						children: [
							data.month,
							" ",
							data.year
						]
					})]
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					style: {
						display: "grid",
						gridTemplateColumns: "1fr 1fr",
						gap: "2.5rem",
						width: "100%",
						maxWidth: "900px",
						marginBottom: "3rem"
					},
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						style: { position: "relative" },
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { style: {
							position: "absolute",
							inset: 0,
							background: "linear-gradient(135deg, rgba(0, 122, 255, 0.3), rgba(88, 86, 214, 0.2))",
							borderRadius: "2rem",
							filter: "blur(20px)",
							transform: "scale(1.05)"
						} }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							style: {
								position: "relative",
								background: "linear-gradient(135deg, rgba(255,255,255,0.15), rgba(255,255,255,0.05))",
								backdropFilter: "blur(20px) saturate(180%)",
								borderRadius: "2rem",
								padding: "2rem 1.5rem",
								border: "1px solid rgba(255,255,255,0.25)",
								textAlign: "center",
								boxShadow: "0 8px 32px 0 rgba(0, 0, 0, 0.37)"
							},
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
								style: {
									fontSize: "7rem",
									fontWeight: 700,
									color: "white",
									marginBottom: "0.2rem",
									textShadow: "0 4px 30px rgba(0, 122, 255, 0.6)",
									letterSpacing: "-0.02em"
								},
								children: data.booksFinished
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								style: {
									fontSize: "2.75rem",
									fontWeight: 600,
									color: "rgba(255,255,255,0.95)",
									letterSpacing: "0.02em"
								},
								children: data.booksFinished === 1 ? "Book" : "Books"
							})]
						})]
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						style: { position: "relative" },
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { style: {
							position: "absolute",
							inset: 0,
							background: "linear-gradient(135deg, rgba(88, 86, 214, 0.3), rgba(94, 92, 230, 0.2))",
							borderRadius: "2rem",
							filter: "blur(20px)",
							transform: "scale(1.05)"
						} }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							style: {
								position: "relative",
								background: "linear-gradient(135deg, rgba(255,255,255,0.15), rgba(255,255,255,0.05))",
								backdropFilter: "blur(20px) saturate(180%)",
								borderRadius: "2rem",
								padding: "2rem 1.5rem",
								border: "1px solid rgba(255,255,255,0.25)",
								textAlign: "center",
								boxShadow: "0 8px 32px 0 rgba(0, 0, 0, 0.37)"
							},
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
								style: {
									fontSize: "7rem",
									fontWeight: 700,
									color: "white",
									marginBottom: "0.2rem",
									textShadow: "0 4px 30px rgba(88, 86, 214, 0.6)",
									letterSpacing: "-0.02em"
								},
								children: data.pagesRead.toLocaleString()
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								style: {
									fontSize: "2.75rem",
									fontWeight: 600,
									color: "rgba(255,255,255,0.95)",
									letterSpacing: "0.02em"
								},
								children: "Pages"
							})]
						})]
					})]
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					style: {
						display: "flex",
						flexDirection: "column",
						gap: "1.75rem",
						width: "100%",
						maxWidth: "900px"
					},
					children: [
						data.topGenre && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							style: { position: "relative" },
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { style: {
								position: "absolute",
								inset: 0,
								background: "linear-gradient(135deg, rgba(0, 122, 255, 0.25), rgba(10, 132, 255, 0.15))",
								borderRadius: "1.5rem",
								filter: "blur(16px)"
							} }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								style: {
									position: "relative",
									background: "linear-gradient(135deg, rgba(255,255,255,0.12), rgba(255,255,255,0.04))",
									backdropFilter: "blur(16px) saturate(180%)",
									borderRadius: "1.5rem",
									padding: "2rem 2.5rem",
									border: "1px solid rgba(255,255,255,0.2)",
									display: "flex",
									alignItems: "center",
									gap: "2rem",
									boxShadow: "0 4px 24px 0 rgba(0, 0, 0, 0.25)"
								},
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("svg", {
									width: "72",
									height: "72",
									viewBox: "0 0 24 24",
									fill: "none",
									stroke: "#0a84ff",
									strokeWidth: "2",
									strokeLinecap: "round",
									strokeLinejoin: "round",
									style: {
										filter: "drop-shadow(0 0 24px rgba(10, 132, 255, 0.8))",
										flexShrink: 0
									},
									children: [
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)("path", { d: "M6 9H4.5a2.5 2.5 0 0 1 0-5H6" }),
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)("path", { d: "M18 9h1.5a2.5 2.5 0 0 0 0-5H18" }),
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)("path", { d: "M4 22h16" }),
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)("path", { d: "M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22" }),
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)("path", { d: "M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22" }),
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)("path", { d: "M18 2H6v7a6 6 0 0 0 12 0V2Z" })
									]
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
									style: { flex: 1 },
									children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
										style: {
											fontSize: "2rem",
											color: "rgba(255,255,255,0.75)",
											fontWeight: 600,
											marginBottom: "0.5rem",
											letterSpacing: "0.01em"
										},
										children: "Favorite Genre"
									}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
										style: {
											fontSize: "3.5rem",
											fontWeight: 700,
											color: "white",
											textShadow: "0 4px 20px rgba(10, 132, 255, 0.4)",
											letterSpacing: "-0.01em"
										},
										children: data.topGenre
									})]
								})]
							})]
						}),
						data.topRatedBook && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							style: { position: "relative" },
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { style: {
								position: "absolute",
								inset: 0,
								background: "linear-gradient(135deg, rgba(255, 159, 10, 0.3), rgba(255, 214, 10, 0.15))",
								borderRadius: "1.5rem",
								filter: "blur(16px)"
							} }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								style: {
									position: "relative",
									background: "linear-gradient(135deg, rgba(255,255,255,0.12), rgba(255,255,255,0.04))",
									backdropFilter: "blur(16px) saturate(180%)",
									borderRadius: "1.5rem",
									padding: "2rem 2.5rem",
									border: "1px solid rgba(255,255,255,0.2)",
									display: "flex",
									alignItems: "center",
									gap: "2rem",
									boxShadow: "0 4px 24px 0 rgba(0, 0, 0, 0.25)"
								},
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("svg", {
									width: "72",
									height: "72",
									viewBox: "0 0 24 24",
									fill: "#ff9f0a",
									stroke: "#ff9f0a",
									strokeWidth: "2",
									strokeLinecap: "round",
									strokeLinejoin: "round",
									style: {
										filter: "drop-shadow(0 0 24px rgba(255, 159, 10, 0.8))",
										flexShrink: 0
									},
									children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("polygon", { points: "12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" })
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
									style: { flex: 1 },
									children: [
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
											style: {
												fontSize: "2rem",
												color: "rgba(255,255,255,0.75)",
												fontWeight: 600,
												marginBottom: "0.5rem",
												letterSpacing: "0.01em"
											},
											children: "Top Rated"
										}),
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
											style: {
												fontSize: "3.25rem",
												fontWeight: 700,
												color: "white",
												marginBottom: "0.5rem",
												textShadow: "0 4px 20px rgba(255, 159, 10, 0.4)",
												letterSpacing: "-0.01em"
											},
											children: data.topRatedBook.title
										}),
										/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
											style: {
												display: "flex",
												alignItems: "center",
												gap: "1rem",
												flexWrap: "wrap"
											},
											children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
												style: {
													fontSize: "2rem",
													color: "rgba(255,255,255,0.85)",
													fontWeight: 500
												},
												children: ["by ", data.topRatedBook.authors]
											}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
												style: {
													display: "flex",
													alignItems: "center",
													gap: "0.75rem",
													background: "rgba(255,159,10,0.25)",
													padding: "0.75rem 1.25rem",
													borderRadius: "9999px",
													border: "1px solid rgba(255,159,10,0.3)"
												},
												children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("svg", {
													width: "24",
													height: "24",
													viewBox: "0 0 24 24",
													fill: "#ff9f0a",
													stroke: "none",
													children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("polygon", { points: "12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" })
												}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
													style: {
														fontSize: "2rem",
														fontWeight: 700,
														color: "white"
													},
													children: data.topRatedBook.rating
												})]
											})]
										})
									]
								})]
							})]
						}),
						data.fastestBook && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							style: { position: "relative" },
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { style: {
								position: "absolute",
								inset: 0,
								background: "linear-gradient(135deg, rgba(48, 209, 88, 0.3), rgba(52, 199, 89, 0.15))",
								borderRadius: "1.5rem",
								filter: "blur(16px)"
							} }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								style: {
									position: "relative",
									background: "linear-gradient(135deg, rgba(255,255,255,0.12), rgba(255,255,255,0.04))",
									backdropFilter: "blur(16px) saturate(180%)",
									borderRadius: "1.5rem",
									padding: "2rem 2.5rem",
									border: "1px solid rgba(255,255,255,0.2)",
									display: "flex",
									alignItems: "center",
									gap: "2rem",
									boxShadow: "0 4px 24px 0 rgba(0, 0, 0, 0.25)"
								},
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("svg", {
									width: "72",
									height: "72",
									viewBox: "0 0 24 24",
									fill: "#30d158",
									stroke: "#30d158",
									strokeWidth: "2",
									strokeLinecap: "round",
									strokeLinejoin: "round",
									style: {
										filter: "drop-shadow(0 0 24px rgba(48, 209, 88, 0.8))",
										flexShrink: 0
									},
									children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("polygon", { points: "13 2 3 14 12 14 11 22 21 10 12 10 13 2" })
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
									style: { flex: 1 },
									children: [
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
											style: {
												fontSize: "2rem",
												color: "rgba(255,255,255,0.75)",
												fontWeight: 600,
												marginBottom: "0.5rem",
												letterSpacing: "0.01em"
											},
											children: "Fastest Read"
										}),
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
											style: {
												fontSize: "3.25rem",
												fontWeight: 700,
												color: "white",
												marginBottom: "0.5rem",
												textShadow: "0 4px 20px rgba(48, 209, 88, 0.4)",
												letterSpacing: "-0.01em"
											},
											children: data.fastestBook.title
										}),
										/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
											style: {
												fontSize: "2.25rem",
												color: "rgba(255,255,255,0.85)",
												fontWeight: 600
											},
											children: [
												data.fastestBook.days,
												" ",
												data.fastestBook.days === 1 ? "day" : "days"
											]
										})
									]
								})]
							})]
						})
					]
				}),
				/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					style: {
						marginTop: "3rem",
						textAlign: "center"
					},
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
						style: {
							fontSize: "2.25rem",
							color: "rgba(255,255,255,0.5)",
							fontWeight: 500,
							display: "flex",
							alignItems: "center",
							gap: "1rem",
							justifyContent: "center",
							letterSpacing: "0.02em"
						},
						children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("svg", {
								width: "28",
								height: "28",
								viewBox: "0 0 24 24",
								fill: "none",
								stroke: "rgba(255,255,255,0.5)",
								strokeWidth: "2",
								strokeLinecap: "round",
								strokeLinejoin: "round",
								children: [
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("path", { d: "m12 3-1.912 5.813a2 2 0 0 1-1.275 1.275L3 12l5.813 1.912a2 2 0 0 1 1.275 1.275L12 21l1.912-5.813a2 2 0 0 1 1.275-1.275L21 12l-5.813-1.912a2 2 0 0 1-1.275-1.275L12 3Z" }),
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("path", { d: "M5 3v4" }),
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("path", { d: "M19 17v4" }),
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("path", { d: "M3 5h4" }),
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("path", { d: "M17 19h4" })
								]
							}),
							"Made with Bookjet",
							/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("svg", {
								width: "28",
								height: "28",
								viewBox: "0 0 24 24",
								fill: "none",
								stroke: "rgba(255,255,255,0.5)",
								strokeWidth: "2",
								strokeLinecap: "round",
								strokeLinejoin: "round",
								children: [
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("path", { d: "m12 3-1.912 5.813a2 2 0 0 1-1.275 1.275L3 12l5.813 1.912a2 2 0 0 1 1.275 1.275L12 21l1.912-5.813a2 2 0 0 1 1.275-1.275L21 12l-5.813-1.912a2 2 0 0 1-1.275-1.275L12 3Z" }),
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("path", { d: "M5 3v4" }),
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("path", { d: "M19 17v4" }),
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("path", { d: "M3 5h4" }),
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("path", { d: "M17 19h4" })
								]
							})
						]
					})
				})
			]
		})]
	});
});
ShareableRecapCard.displayName = "ShareableRecapCard";
function useCounter(end, duration = 2e3, isActive = false) {
	const [count, setCount] = (0, import_react.useState)(0);
	(0, import_react.useEffect)(() => {
		if (!isActive) {
			setCount(0);
			return;
		}
		let startTime = null;
		const startValue = 0;
		const animate = (currentTime) => {
			if (startTime === null) startTime = currentTime;
			const progress = Math.min((currentTime - startTime) / duration, 1);
			const easeOutQuart = 1 - Math.pow(1 - progress, 4);
			setCount(Math.floor(easeOutQuart * (end - startValue) + startValue));
			if (progress < 1) requestAnimationFrame(animate);
		};
		requestAnimationFrame(animate);
	}, [
		end,
		duration,
		isActive
	]);
	return count;
}
function FloatingParticles({ color = "white" }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
		className: "absolute inset-0 overflow-hidden pointer-events-none",
		children: [...Array(20)].map((_, i) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
			className: "absolute rounded-full opacity-20",
			style: {
				width: Math.random() * 4 + 2 + "px",
				height: Math.random() * 4 + 2 + "px",
				background: color,
				left: Math.random() * 100 + "%",
				top: Math.random() * 100 + "%",
				animation: `float ${Math.random() * 10 + 10}s linear infinite`,
				animationDelay: Math.random() * 5 + "s"
			}
		}, i))
	});
}
function Sparkle({ className = "" }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
		className: `absolute ${className}`,
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Sparkles, { className: "h-6 w-6 text-yellow-300 animate-pulse" })
	});
}
function MonthlyRecap({ data, isOpen, onClose }) {
	const [currentSlide, setCurrentSlide] = (0, import_react.useState)(0);
	const [touchStart, setTouchStart] = (0, import_react.useState)(0);
	const [touchEnd, setTouchEnd] = (0, import_react.useState)(0);
	const shareableCardRef = (0, import_react.useRef)(null);
	const booksCount = useCounter(data.booksFinished, 2e3, currentSlide === 1);
	const pagesCount = useCounter(data.pagesRead, 2500, currentSlide === 1);
	const slides = [
		{
			gradient: "from-purple-600 via-pink-600 to-red-600",
			content: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "relative flex flex-col items-center justify-center h-full text-center px-6 overflow-hidden",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(FloatingParticles, {}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Sparkle, { className: "top-20 left-10 animate-ping" }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Sparkle, { className: "top-40 right-20 animate-pulse" }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Sparkle, { className: "bottom-32 left-1/4" }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Sparkle, { className: "bottom-20 right-1/3 animate-ping" }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "mb-8 relative",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "absolute inset-0 bg-white/20 blur-3xl rounded-full animate-pulse" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(BookOpen, {
							className: "h-24 w-24 text-white relative z-10 mx-auto mb-4 drop-shadow-2xl animate-in zoom-in duration-700",
							style: { filter: "drop-shadow(0 0 30px rgba(255,255,255,0.5))" }
						})]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h1", {
						className: "text-6xl md:text-7xl font-black text-white mb-4 animate-in slide-in-from-bottom duration-700 delay-150",
						style: {
							textShadow: "0 0 40px rgba(255,255,255,0.5), 0 10px 30px rgba(0,0,0,0.3)",
							background: "linear-gradient(to bottom, white, rgba(255,255,255,0.8))",
							WebkitBackgroundClip: "text",
							WebkitTextFillColor: "transparent",
							backgroundClip: "text"
						},
						children: "Your Reading"
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("h2", {
						className: "text-5xl md:text-6xl font-black text-white mb-8 animate-in slide-in-from-bottom duration-700 delay-300",
						style: { textShadow: "0 0 30px rgba(255,255,255,0.4), 0 8px 20px rgba(0,0,0,0.3)" },
						children: [
							data.month,
							" ",
							data.year
						]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "text-2xl text-white/90 animate-in fade-in duration-700 delay-500 font-medium",
						style: { textShadow: "0 2px 10px rgba(0,0,0,0.3)" },
						children: "Let's celebrate your journey ✨"
					})
				]
			})
		},
		{
			gradient: "from-blue-600 via-cyan-600 to-teal-600",
			content: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "relative flex flex-col items-center justify-center h-full text-center px-6 overflow-hidden",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(FloatingParticles, { color: "rgba(255,255,255,0.6)" }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "absolute top-1/4 left-1/4 w-64 h-64 bg-white/10 rounded-full blur-3xl animate-pulse" }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "absolute bottom-1/4 right-1/4 w-80 h-80 bg-cyan-300/10 rounded-full blur-3xl animate-pulse delay-700" }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "mb-12 relative z-10",
						children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
								className: "text-9xl md:text-[12rem] font-black text-white mb-6 relative animate-in zoom-in duration-1000",
								style: {
									textShadow: "0 0 60px rgba(255,255,255,0.8), 0 0 100px rgba(96, 165, 250, 0.4), 0 20px 40px rgba(0,0,0,0.3)",
									background: "linear-gradient(to bottom, white, rgba(255,255,255,0.7))",
									WebkitBackgroundClip: "text",
									WebkitTextFillColor: "transparent",
									backgroundClip: "text"
								},
								children: booksCount
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Sparkle, { className: "-top-4 -right-8" }),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Sparkle, { className: "-bottom-4 -left-8" }),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
								className: "text-4xl md:text-5xl font-bold text-white animate-in slide-in-from-bottom duration-700 delay-300",
								style: { textShadow: "0 4px 20px rgba(0,0,0,0.3)" },
								children: data.booksFinished === 1 ? "Book Finished" : "Books Finished"
							})
						]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "relative animate-in slide-in-from-bottom duration-700 delay-500",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "absolute inset-0 bg-gradient-to-r from-white/30 to-cyan-300/30 rounded-3xl blur-xl" }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "relative bg-white/20 backdrop-blur-md rounded-3xl px-12 py-8 border-2 border-white/30",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
								className: "text-6xl md:text-7xl font-black text-white mb-3",
								style: { textShadow: "0 0 30px rgba(255,255,255,0.5), 0 4px 15px rgba(0,0,0,0.3)" },
								children: pagesCount.toLocaleString()
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
								className: "text-2xl text-white/95 font-semibold flex items-center gap-2 justify-center",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(BookOpen, { className: "h-6 w-6" }), "Pages Read"]
							})]
						})]
					})
				]
			})
		},
		...data.topGenre ? [{
			gradient: "from-orange-600 via-red-600 to-pink-600",
			content: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "relative flex flex-col items-center justify-center h-full text-center px-6 overflow-hidden",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(FloatingParticles, { color: "rgba(255,215,0,0.4)" }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "mb-10 relative animate-in zoom-in duration-1000",
						children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "absolute inset-0 bg-yellow-300/40 blur-3xl rounded-full animate-pulse" }),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Trophy, {
								className: "h-32 w-32 text-yellow-300 relative z-10 mx-auto mb-6 animate-bounce",
								style: { filter: "drop-shadow(0 0 40px rgba(253, 224, 71, 0.8)) drop-shadow(0 10px 30px rgba(0,0,0,0.4))" }
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Sparkle, { className: "-top-6 -right-6 animate-ping" }),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Sparkle, { className: "-bottom-6 -left-6 animate-pulse" }),
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Sparkle, { className: "top-1/2 -right-10" })
						]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
						className: "text-4xl md:text-5xl font-bold text-white mb-12 animate-in slide-in-from-bottom duration-700 delay-200",
						style: { textShadow: "0 4px 20px rgba(0,0,0,0.4)" },
						children: "Your Favorite Genre"
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "relative animate-in slide-in-from-bottom duration-700 delay-400",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "absolute inset-0 bg-gradient-to-br from-yellow-400/30 to-orange-400/30 rounded-3xl blur-2xl scale-110" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
							className: "relative bg-gradient-to-br from-white/25 to-white/10 backdrop-blur-md rounded-3xl px-16 py-10 border-2 border-white/40 shadow-2xl",
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
								className: "text-5xl md:text-6xl font-black text-white",
								style: {
									textShadow: "0 0 40px rgba(255,255,255,0.6), 0 6px 25px rgba(0,0,0,0.4)",
									background: "linear-gradient(to bottom, white, rgba(255,255,255,0.85))",
									WebkitBackgroundClip: "text",
									WebkitTextFillColor: "transparent",
									backgroundClip: "text"
								},
								children: data.topGenre
							})
						})]
					})
				]
			})
		}] : [],
		...data.topRatedBook ? [{
			gradient: "from-yellow-600 via-orange-600 to-red-600",
			content: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex flex-col items-center justify-center h-full text-center px-6",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
						className: "mb-6",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Star, { className: "h-16 w-16 text-yellow-300 fill-yellow-300 mx-auto mb-4" })
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
						className: "text-3xl md:text-4xl font-bold text-white mb-6",
						children: "Top Rated Book"
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "bg-white/20 backdrop-blur-sm rounded-2xl px-8 py-8 max-w-md",
						children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
								className: "text-3xl md:text-4xl font-bold text-white mb-3",
								children: data.topRatedBook.title
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
								className: "text-lg text-white/80 mb-4",
								children: ["by ", data.topRatedBook.authors]
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "flex items-center justify-center gap-2",
								children: [
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Star, { className: "h-8 w-8 text-yellow-300 fill-yellow-300" }),
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
										className: "text-4xl font-bold text-white",
										children: data.topRatedBook.rating
									}),
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
										className: "text-2xl text-white/80",
										children: "/5"
									})
								]
							})
						]
					})
				]
			})
		}] : [],
		...data.fastestBook ? [{
			gradient: "from-green-600 via-emerald-600 to-teal-600",
			content: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex flex-col items-center justify-center h-full text-center px-6",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
						className: "mb-6",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Zap, { className: "h-16 w-16 text-yellow-300 fill-yellow-300 mx-auto mb-4" })
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
						className: "text-3xl md:text-4xl font-bold text-white mb-6",
						children: "Fastest Read"
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "bg-white/20 backdrop-blur-sm rounded-2xl px-8 py-8 max-w-md",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
							className: "text-3xl md:text-4xl font-bold text-white mb-4",
							children: data.fastestBook.title
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "flex items-center justify-center gap-2",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Calendar, { className: "h-6 w-6 text-white/80" }), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
								className: "text-2xl font-bold text-white",
								children: [
									data.fastestBook.days,
									" ",
									data.fastestBook.days === 1 ? "day" : "days"
								]
							})]
						})]
					})
				]
			})
		}] : [],
		...data.favoriteAuthor ? [{
			gradient: "from-indigo-600 via-purple-600 to-pink-600",
			content: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex flex-col items-center justify-center h-full text-center px-6",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
					className: "text-3xl md:text-4xl font-bold text-white mb-8",
					children: "Your Favorite Author"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "bg-white/20 backdrop-blur-sm rounded-2xl px-12 py-8",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
						className: "text-4xl md:text-5xl font-bold text-white",
						children: data.favoriteAuthor
					})
				})]
			})
		}] : [],
		{
			gradient: "from-slate-800 via-slate-900 to-black",
			content: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex flex-col items-center justify-center h-full text-center px-6",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
						className: "text-4xl md:text-5xl font-bold text-white mb-12",
						children: "Keep Reading!"
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "grid grid-cols-2 gap-6 max-w-2xl w-full mb-12",
						children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "bg-white/10 backdrop-blur-sm rounded-xl p-6",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
									className: "text-4xl font-bold text-white mb-2",
									children: data.booksFinished
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
									className: "text-sm text-white/70",
									children: "Books"
								})]
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "bg-white/10 backdrop-blur-sm rounded-xl p-6",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
									className: "text-4xl font-bold text-white mb-2",
									children: data.pagesRead.toLocaleString()
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
									className: "text-sm text-white/70",
									children: "Pages"
								})]
							}),
							data.totalReadingDays > 0 && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "bg-white/10 backdrop-blur-sm rounded-xl p-6",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
									className: "text-4xl font-bold text-white mb-2",
									children: data.totalReadingDays
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
									className: "text-sm text-white/70",
									children: "Reading Days"
								})]
							}),
							data.topGenre && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "bg-white/10 backdrop-blur-sm rounded-xl p-6",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
									className: "text-2xl font-bold text-white mb-2",
									children: data.topGenre
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
									className: "text-sm text-white/70",
									children: "Top Genre"
								})]
							})
						]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
						className: "text-lg text-white/60 mt-12",
						children: [
							data.month,
							" ",
							data.year
						]
					})
				]
			})
		}
	];
	const totalSlides = slides.length;
	const nextSlide = () => {
		if (currentSlide < totalSlides - 1) setCurrentSlide(currentSlide + 1);
		else onClose();
	};
	const prevSlide = () => {
		if (currentSlide > 0) setCurrentSlide(currentSlide - 1);
	};
	const handleTouchStart = (e) => {
		setTouchStart(e.targetTouches[0].clientX);
	};
	const handleTouchMove = (e) => {
		setTouchEnd(e.targetTouches[0].clientX);
	};
	const handleTouchEnd = () => {
		if (!touchStart || !touchEnd) return;
		const distance = touchStart - touchEnd;
		if (distance > 50) nextSlide();
		if (distance < -50) prevSlide();
		setTouchStart(0);
		setTouchEnd(0);
	};
	(0, import_react.useEffect)(() => {
		if (isOpen) {
			setCurrentSlide(0);
			document.body.style.overflow = "hidden";
		} else document.body.style.overflow = "unset";
		return () => {
			document.body.style.overflow = "unset";
		};
	}, [isOpen]);
	(0, import_react.useEffect)(() => {
		const handleKeyDown = (e) => {
			if (!isOpen) return;
			if (e.key === "ArrowRight") nextSlide();
			if (e.key === "ArrowLeft") prevSlide();
			if (e.key === "Escape") onClose();
		};
		window.addEventListener("keydown", handleKeyDown);
		return () => window.removeEventListener("keydown", handleKeyDown);
	}, [isOpen, currentSlide]);
	if (!isOpen) return null;
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "fixed inset-0 z-50 overflow-hidden",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: `absolute inset-0 bg-gradient-to-br ${slides[currentSlide].gradient} transition-all duration-500` }),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "absolute top-4 left-4 right-4 flex gap-1 z-10",
				children: slides.map((_, index) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "h-1 flex-1 bg-white/30 rounded-full overflow-hidden",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: `h-full bg-white transition-all duration-300 ${index < currentSlide ? "w-full" : index === currentSlide ? "w-full" : "w-0"}` })
				}, index))
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
				variant: "ghost",
				size: "icon",
				onClick: onClose,
				className: "absolute top-4 right-4 z-10 text-white hover:bg-white/20",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(X, { className: "h-6 w-6" })
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "absolute inset-0 flex items-center justify-center",
				onTouchStart: handleTouchStart,
				onTouchMove: handleTouchMove,
				onTouchEnd: handleTouchEnd,
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "w-full h-full max-w-2xl relative",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
						className: "w-full h-full animate-in fade-in slide-in-from-right-4 duration-300",
						children: slides[currentSlide].content
					}, currentSlide)
				})
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "absolute inset-y-0 left-0 right-0 flex items-center justify-between px-4 pointer-events-none",
				children: [
					currentSlide > 0 && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
						variant: "ghost",
						size: "icon",
						onClick: prevSlide,
						className: "pointer-events-auto text-white hover:bg-white/20 h-12 w-12",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ChevronLeft, { className: "h-8 w-8" })
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "flex-1" }),
					currentSlide < totalSlides - 1 && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
						variant: "ghost",
						size: "icon",
						onClick: nextSlide,
						className: "pointer-events-auto text-white hover:bg-white/20 h-12 w-12",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ChevronRight, { className: "h-8 w-8" })
					})
				]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "absolute inset-0 flex md:hidden",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "flex-1",
					onClick: prevSlide,
					style: { opacity: 0 }
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "flex-1",
					onClick: nextSlide,
					style: { opacity: 0 }
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "fixed -left-[9999px] -top-[9999px]",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ShareableRecapCard, {
					ref: shareableCardRef,
					data
				})
			})
		]
	});
}
var getMonthlyRecapAction = createServerFn({ method: "POST" }).validator((d) => d).handler(createSsrRpc("fd85bbeff9114a414a6b16d5c4ac196140d2f7675248a332a45017d9bf202d37"));
function MonthlyRecapButton() {
	const [isOpen, setIsOpen] = (0, import_react.useState)(false);
	const [recapData, setRecapData] = (0, import_react.useState)(null);
	const [isLoading, setIsLoading] = (0, import_react.useState)(false);
	const [isGeneratingImage, setIsGeneratingImage] = (0, import_react.useState)(false);
	const shareableCardRef = (0, import_react.useRef)(null);
	const handleOpenRecap = async () => {
		setIsLoading(true);
		try {
			const now = /* @__PURE__ */ new Date();
			const data = await getMonthlyRecapAction(now.getFullYear(), now.getMonth() + 1);
			if (data.booksFinished === 0) {
				toast.info("No books finished this month yet. Keep reading!");
				return;
			}
			setRecapData(data);
			setIsOpen(true);
		} catch (error) {
			toast.error("Failed to load monthly recap");
		} finally {
			setIsLoading(false);
		}
	};
	const generateShareableImage = async () => {
		let dataToUse = recapData;
		if (!dataToUse) {
			setIsLoading(true);
			try {
				const now = /* @__PURE__ */ new Date();
				const data = await getMonthlyRecapAction(now.getFullYear(), now.getMonth() + 1);
				if (data.booksFinished === 0) {
					toast.info("No books finished this month yet. Keep reading!");
					return;
				}
				setRecapData(data);
				dataToUse = data;
			} catch (error) {
				toast.error("Failed to load monthly recap");
				return;
			} finally {
				setIsLoading(false);
			}
		}
		await new Promise((resolve) => setTimeout(resolve, 300));
		if (!shareableCardRef.current) {
			toast.error("Failed to generate image. Please try again.");
			return;
		}
		setIsGeneratingImage(true);
		toast.info("Generating image...");
		try {
			const dataUrl = await toPng(shareableCardRef.current, {
				quality: .95,
				pixelRatio: 1,
				backgroundColor: "#0f2027",
				width: 1080,
				height: 1920,
				style: {
					transform: "scale(1)",
					transformOrigin: "top left"
				}
			});
			const blob = await (await fetch(dataUrl)).blob();
			const url = URL.createObjectURL(blob);
			const link = document.createElement("a");
			link.download = `reading-recap-${dataToUse.month}-${dataToUse.year}.png`;
			link.href = url;
			link.click();
			URL.revokeObjectURL(url);
			toast.success("Image downloaded!");
		} catch (error) {
			console.error("Error generating image:", error);
			toast.error("Failed to generate image: " + error.message);
		} finally {
			setIsGeneratingImage(false);
		}
	};
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "flex gap-2",
		children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Button, {
			onClick: handleOpenRecap,
			disabled: isLoading,
			size: "sm",
			className: "bg-primary",
			children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Sparkles, { className: "h-4 w-4 sm:mr-2" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
				className: "hidden sm:inline",
				children: isLoading ? "Loading..." : "Monthly Recap"
			})]
		}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Button, {
			onClick: generateShareableImage,
			disabled: isLoading || isGeneratingImage,
			size: "sm",
			variant: "outline",
			className: "shrink-0",
			title: "Download Monthly Recap Image",
			children: [isGeneratingImage ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Download, { className: "h-4 w-4 animate-pulse" }) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Share2, { className: "h-4 w-4" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
				className: "ml-2 hidden md:inline",
				children: "Share"
			})]
		})]
	}), recapData && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(MonthlyRecap, {
		data: recapData,
		isOpen,
		onClose: () => setIsOpen(false)
	}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
		className: "fixed -left-[9999px] -top-[9999px] pointer-events-none",
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ShareableRecapCard, {
			ref: shareableCardRef,
			data: recapData
		})
	})] })] });
}
function DashboardPage() {
	const { data, isLoading } = useDashboardData();
	if (isLoading) return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "flex flex-col gap-4 p-4 md:gap-6 md:p-6",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "flex items-center justify-between",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "space-y-2",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Skeleton, { className: "h-9 w-48" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Skeleton, { className: "h-4 w-64" })]
				})
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "grid gap-4 sm:grid-cols-2 lg:grid-cols-5",
				children: Array.from({ length: 5 }).map((_, i) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Card, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(CardContent, {
					className: "pt-6",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Skeleton, { className: "h-4 w-24 mb-2" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Skeleton, { className: "h-8 w-16" })]
				}) }, i))
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Card, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, {
				className: "pt-6",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Skeleton, { className: "h-48 w-full" })
			}) })
		]
	});
	const { stats, goal, recentBooksData, currentlyReading, recentSessions, readingHistory, unfinishedBooks, libraryCompletion, dailyActivity, streaks } = data ?? {};
	const readingStats = stats?.[0] || {
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
	const yearGoal = goal?.[0] || {
		targetBooks: 52,
		currentBooks: 0
	};
	const targetBooks = yearGoal.targetBooks ?? 52;
	const currentBooks = yearGoal.currentBooks ?? 0;
	const goalProgress = targetBooks > 0 ? currentBooks / targetBooks * 100 : 0;
	const totalReadingTime = (recentSessions ?? []).reduce((sum, s) => sum + (s.session.minutesRead || 0), 0);
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
		className: "flex flex-col gap-4 p-4 md:gap-6 md:p-6",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "flex items-center justify-between",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h1", {
					className: "text-3xl font-bold tracking-tight",
					children: "Dashboard"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "text-muted-foreground",
					children: "Welcome back to your reading journey"
				})] })
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "flex items-center justify-between",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "flex gap-2",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(MonthlyRecapButton, {}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(AddReadingSessionDialog, {
						books: unfinishedBooks ?? [],
						trigger: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Button, {
							size: "sm",
							variant: "outline",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(FileText, { className: "mr-2 h-4 w-4" }), "Log Session"]
						})
					})]
				})
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Card, {
				className: "border-2",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardHeader, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "flex items-center justify-between",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(CardTitle, {
						className: "flex items-center gap-2",
						children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Target, { className: "h-5 w-5 text-primary" }),
							(/* @__PURE__ */ new Date()).getFullYear(),
							" Reading Goal"
						]
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "flex items-center gap-2",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Badge, {
							variant: goalProgress >= 100 ? "default" : "secondary",
							className: goalProgress >= 100 ? "bg-green-600" : "",
							children: [goalProgress.toFixed(0), "%"]
						}), goalProgress >= 100 && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Award, { className: "h-5 w-5 text-green-600" })]
					})]
				}) }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "space-y-3",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "flex justify-between text-sm",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
								className: "text-muted-foreground",
								children: "Progress"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
								className: "font-semibold text-lg",
								children: [
									currentBooks,
									" / ",
									targetBooks,
									" books"
								]
							})]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
							className: "h-6 overflow-hidden rounded-full bg-secondary",
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
								className: `h-full transition-all ${goalProgress >= 100 ? "bg-green-500" : "bg-primary"}`,
								style: { width: `${Math.min(goalProgress, 100)}%` }
							})
						}),
						goalProgress >= 100 ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "text-sm text-green-600 dark:text-green-400 font-medium",
							children: "🎉 Congratulations! You've achieved your reading goal!"
						}) : /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
							className: "text-sm text-muted-foreground",
							children: [targetBooks - currentBooks, " books remaining"]
						})
					]
				}) })]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Card, {
				className: "border-2",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardHeader, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(CardTitle, {
					className: "flex items-center gap-2",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(BookOpen, { className: "h-5 w-5 text-purple-600" }), "Library Completion"]
				}) }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "space-y-4",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "space-y-2",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "flex justify-between text-sm",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
									className: "text-muted-foreground",
									children: "Progress"
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
									className: "font-semibold text-lg",
									children: [libraryCompletion?.percentage, "%"]
								})]
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "h-6 overflow-hidden rounded-full bg-secondary relative",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
									className: "h-full bg-gradient-to-r from-purple-600 to-indigo-600 transition-all",
									style: { width: `${Math.min(libraryCompletion?.percentage ?? 0, 100)}%` }
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
									className: "absolute inset-0 flex items-center justify-center",
									children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
										className: "text-xs font-bold text-foreground mix-blend-difference",
										children: [
											libraryCompletion?.booksRead,
											" / ",
											libraryCompletion?.totalBooks,
											" books"
										]
									})
								})]
							})]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "grid grid-cols-2 gap-4",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "space-y-1",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
									className: "text-sm text-muted-foreground",
									children: "Books Read"
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
									className: "text-2xl font-bold",
									children: libraryCompletion?.booksRead
								})]
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "space-y-1",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
									className: "text-sm text-muted-foreground",
									children: "Total Library"
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
									className: "text-2xl font-bold",
									children: libraryCompletion?.totalBooks
								})]
							})]
						}),
						libraryCompletion?.estimatedCompletionMonths !== null && libraryCompletion?.estimatedCompletionMonths > 0 && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
							className: "pt-3 border-t",
							children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "flex items-center justify-between",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
									className: "text-sm text-muted-foreground",
									children: "Estimated to finish in"
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Badge, {
									variant: "secondary",
									className: "bg-purple-100 text-purple-900 dark:bg-purple-950 dark:text-purple-100",
									children: [
										libraryCompletion?.estimatedCompletionMonths,
										" ",
										libraryCompletion?.estimatedCompletionMonths === 1 ? "month" : "months"
									]
								})]
							})
						})
					]
				}) })]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "w-full",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(ReadingHeatmap, {
					data: dailyActivity ?? [],
					currentStreak: streaks?.currentStreak ?? 0,
					bestStreak: streaks?.bestStreak ?? 0
				})
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "grid gap-4 sm:grid-cols-2 lg:grid-cols-5",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Card, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, {
						className: "pt-6",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "flex items-center justify-between",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "space-y-1",
								children: [
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
										className: "text-sm text-muted-foreground",
										children: "Books Read"
									}),
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
										className: "text-2xl font-bold",
										children: readingStats.totalBooksRead
									}),
									/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
										className: "text-xs text-muted-foreground",
										children: [readingStats.booksReadThisYear, " this year"]
									})
								]
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(BookOpen, { className: "h-8 w-8 text-muted-foreground" })]
						})
					}) }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Card, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, {
						className: "pt-6",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "flex items-center justify-between",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "space-y-1",
								children: [
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
										className: "text-sm text-muted-foreground",
										children: "Pages Read"
									}),
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
										className: "text-2xl font-bold",
										children: readingStats.totalPagesRead
									}),
									/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
										className: "text-xs text-muted-foreground",
										children: [readingStats.pagesReadThisMonth, " this month"]
									})
								]
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(FileText, { className: "h-8 w-8 text-muted-foreground" })]
						})
					}) }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Card, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, {
						className: "pt-6",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "flex items-center justify-between",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "space-y-1",
								children: [
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
										className: "text-sm text-muted-foreground",
										children: "Current Streak"
									}),
									/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
										className: "text-2xl font-bold flex items-center gap-1",
										children: [streaks?.currentStreak ?? 0, (streaks?.currentStreak ?? 0) > 0 && /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Flame, { className: "h-5 w-5 text-orange-500" })]
									}),
									/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
										className: "text-xs text-muted-foreground",
										children: [
											"Best: ",
											streaks?.bestStreak ?? 0,
											" days"
										]
									})
								]
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Flame, { className: "h-8 w-8 text-orange-500" })]
						})
					}) }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Card, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, {
						className: "pt-6",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "flex items-center justify-between",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "space-y-1",
								children: [
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
										className: "text-sm text-muted-foreground",
										children: "Reading Now"
									}),
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
										className: "text-2xl font-bold",
										children: readingStats.totalBooksReading
									}),
									/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
										className: "text-xs text-muted-foreground",
										children: [readingStats.totalBooksWantToRead, " to read"]
									})
								]
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(TrendingUp, { className: "h-8 w-8 text-blue-500" })]
						})
					}) }),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Card, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, {
						className: "pt-6",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "flex items-center justify-between",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
								className: "space-y-1",
								children: [
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
										className: "text-sm text-muted-foreground",
										children: "Reading Days"
									}),
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
										className: "text-2xl font-bold",
										children: streaks?.totalReadingDays ?? 0
									}),
									/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
										className: "text-xs text-muted-foreground",
										children: [
											Math.floor(totalReadingTime / 60),
											"h ",
											totalReadingTime % 60,
											"m total"
										]
									})
								]
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Clock, { className: "h-8 w-8 text-muted-foreground" })]
						})
					}) })
				]
			}),
			(currentlyReading ?? []).length > 0 && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Card, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardHeader, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex items-center justify-between",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(CardTitle, {
					className: "flex items-center gap-2",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(BookOpen, { className: "h-5 w-5" }), "Currently Reading"]
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
					asChild: true,
					variant: "ghost",
					size: "sm",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Link, {
						to: "/dashboard/books",
						children: "View All"
					})
				})]
			}) }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "grid gap-4 sm:grid-cols-2 lg:grid-cols-3",
				children: currentlyReading.slice(0, 3).map((item) => /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Card, {
					className: "overflow-hidden",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, {
						className: "p-4",
						children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "space-y-2",
							children: [
								/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h4", {
									className: "font-semibold line-clamp-1",
									children: item.book.title
								}),
								/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
									className: "text-sm text-muted-foreground line-clamp-1",
									children: item.authors
								}),
								item.book.pages && item.log.currentPage !== null && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
									className: "space-y-1",
									children: [
										/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
											className: "flex justify-between text-xs",
											children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
												className: "text-muted-foreground",
												children: "Progress"
											}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
												className: "font-medium",
												children: [Math.round(item.log.currentPage / item.book.pages * 100), "%"]
											})]
										}),
										/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
											className: "h-2 overflow-hidden rounded-full bg-secondary",
											children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
												className: "h-full bg-primary transition-all",
												style: { width: `${item.log.currentPage / item.book.pages * 100}%` }
											})
										}),
										/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
											className: "text-xs text-muted-foreground",
											children: [
												item.log.currentPage,
												" / ",
												item.book.pages,
												" pages"
											]
										})
									]
								})
							]
						})
					})
				}, item.log.logId))
			}) })] }),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)(ReadingHistoryChart, {
				data: (readingHistory ?? []).map((item) => ({
					period: item.period || (/* @__PURE__ */ new Date()).toISOString(),
					booksRead: item.booksRead || 0,
					pagesRead: item.pagesRead || 0
				})),
				title: "Reading History",
				description: "Track your reading progress over time"
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Card, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardHeader, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex items-center justify-between",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(CardTitle, {
					className: "flex items-center gap-2",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Star, { className: "h-5 w-5" }), "Recently Finished"]
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
					asChild: true,
					variant: "ghost",
					size: "sm",
					children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Link, {
						to: "/dashboard/calendar",
						children: "View Calendar"
					})
				})]
			}) }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, { children: (recentBooksData ?? []).length === 0 ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
				className: "flex flex-col items-center justify-center py-8 text-center",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(BookOpen, { className: "mb-2 h-12 w-12 text-muted-foreground" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
					className: "text-sm text-muted-foreground",
					children: "No books finished yet. Keep reading!"
				})]
			}) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
				className: "space-y-3",
				children: recentBooksData.map((item) => /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
					className: "flex items-center justify-between rounded-lg border p-3 transition-colors hover:bg-accent",
					children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "flex-1",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h4", {
							className: "font-medium",
							children: item.book.title
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
							className: "flex items-center gap-2 mt-1",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "text-sm text-muted-foreground",
								children: item.authors
							}), item.book.pages && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
								className: "text-xs text-muted-foreground",
								children: [
									"• ",
									item.book.pages,
									" pages"
								]
							})]
						})]
					}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "flex items-center gap-2",
						children: [item.log.rating && /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Badge, {
							variant: "secondary",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Star, { className: "h-3 w-3 fill-yellow-400 text-yellow-400 mr-1" }), item.log.rating]
						}), item.log.dateFinished && /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
							className: "text-xs text-muted-foreground",
							children: new Date(item.log.dateFinished).toLocaleDateString("en-US", {
								month: "short",
								day: "numeric"
							})
						})]
					})]
				}, item.log.logId))
			}) })] })
		]
	});
}
//#endregion
export { DashboardPage as component };
