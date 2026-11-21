export const PRIORITY_LEVELS = ["critical", "high", "medium", "low"] as const;
export type PriorityLevel = (typeof PRIORITY_LEVELS)[number];

// Quiet, editorial colors: small dots instead of loud badges.
export const LEVEL_META: Record<PriorityLevel, { label: string; dot: string }> = {
  critical: { label: "Critical", dot: "bg-rose-500" },
  high: { label: "High", dot: "bg-amber-500" },
  medium: { label: "Medium", dot: "bg-sky-500" },
  low: { label: "Low", dot: "bg-zinc-400" },
};

export const STATUS_LABEL: Record<string, string> = {
  want_to_read: "Want to read",
  reading: "Reading",
  finished: "Finished",
  did_not_finish: "Did not finish",
  on_hold: "On hold",
};

export function formatMinutes(minutes: number | null | undefined) {
  if (!minutes) return null;
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  return h ? (m ? `${h}h ${m}m` : `${h}h`) : `${m}m`;
}

export const TIMES_OF_DAY = ["morning", "afternoon", "evening", "anytime"] as const;
export type TimeOfDay = (typeof TIMES_OF_DAY)[number];
export const TIME_LABEL: Record<TimeOfDay, string> = {
  morning: "Morning",
  afternoon: "Afternoon",
  evening: "Evening",
  anytime: "Anytime",
};

interface PlannedAmounts {
  plannedPages: number | null;
  plannedMinutes: number | null;
  plannedStartPage: number | null;
  plannedEndPage: number | null;
}

/** "p. 100-130 · 45m" / "30 pages" / "" */
export function plannedLabel(i: PlannedAmounts): string {
  const parts: string[] = [];
  if (i.plannedStartPage != null && i.plannedEndPage != null) parts.push(`p. ${i.plannedStartPage}-${i.plannedEndPage}`);
  else if (i.plannedPages != null) parts.push(`${i.plannedPages} ${i.plannedPages === 1 ? "page" : "pages"}`);
  const m = formatMinutes(i.plannedMinutes);
  if (m) parts.push(m);
  return parts.join(" · ");
}

/** "22 of 30 pages" style comparison of what happened versus the plan. */
export function actualLabel(i: PlannedAmounts & { actualPages: number | null; actualMinutes: number | null }): string {
  const parts: string[] = [];
  if (i.actualPages != null) {
    parts.push(i.plannedPages != null ? `${i.actualPages} of ${i.plannedPages} pages` : `${i.actualPages} pages`);
  }
  const am = formatMinutes(i.actualMinutes);
  if (am) {
    const pm = formatMinutes(i.plannedMinutes);
    parts.push(pm ? `${am} of ${pm}` : am);
  }
  return parts.join(" · ");
}
