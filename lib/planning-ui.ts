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
