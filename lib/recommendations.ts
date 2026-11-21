/**
 * Reading recommendations: pure scoring, no database. Every suggestion carries
 * the reasons it was suggested. Goodreads popularity is only a tie-breaker.
 */
import { daysBetween, weekdayIndex } from "@/lib/dates";

export type ReadingStatus = "want_to_read" | "reading" | "finished" | "did_not_finish" | "on_hold";

export interface Candidate {
  bookId: number;
  title: string;
  pages: number | null;
  /** YYYY-MM-DD or ISO timestamp */
  addedAt: string | null;
  status: ReadingStatus | null;
  currentPage: number | null;
  /** YYYY-MM-DD */
  lastSessionDate: string | null;
  authors: { id: number; name: string }[];
  genres: string[];
  coverUrl: string | null;
  goodreadsRating: number | null;
  goodreadsRatingsCount: number | null;
  /** The user's own rating of this book, if finished. */
  userRating: number | null;
  priority: { level: "critical" | "high" | "medium" | "low"; reason: string | null; targetDate: string | null } | null;
  dismissal: { kind: "dismissed" | "postponed"; untilDate: string | null } | null;
  /** Already has a planned (not yet done) activity this week. */
  plannedThisWeek: boolean;
}

export interface RecommendationContext {
  /** YYYY-MM-DD, the user's today. */
  today: string;
  /** Default: "weekend" on Saturday/Sunday, otherwise "weekday". */
  mode?: "weekday" | "weekend";
  /** Max suggestions. Default 5: a short list, not a backlog. */
  limit?: number;
  /** Rereads: only finished books are suggested. */
  includeFinished?: boolean;
  /** Genres of the most recently finished books, most recent first. */
  recentGenres: string[];
  /** Average user rating (1-5) of finished books, by lowercase author name / genre. */
  authorRatings: Record<string, number>;
  genreRatings: Record<string, number>;
}

export interface Recommendation extends Candidate {
  score: number;
  /** Clauses that complete "...because ...", e.g. "it is a high priority". */
  reasons: string[];
  /** A full sentence explaining the suggestion. */
  reason: string;
}

const PRIORITY_POINTS = { critical: 100, high: 70, medium: 40, low: 15 } as const;
const PRIORITY_WORDS = { critical: "a critical priority", high: "a high priority", medium: "a medium priority", low: "a low priority" } as const;

const MAX_CURRENTLY_READING = 2;

const plural = (n: number, word: string) => `${n} ${word}${n === 1 ? "" : "s"}`;
const dayKey = (value: string) => value.slice(0, 10);

function describeAge(days: number) {
  if (days >= 365) return `about ${plural(Math.round(days / 365), "year")}`;
  return plural(Math.round(days / 30), "month");
}

export function scoreCandidate(c: Candidate, ctx: RecommendationContext): { score: number; reasons: string[] } | null {
  // ---- eligibility
  if (c.status === "did_not_finish") return null;
  if (ctx.includeFinished ? c.status !== "finished" : c.status === "finished") return null;
  if (c.dismissal) {
    if (c.dismissal.kind === "dismissed") return null;
    if (c.dismissal.untilDate && c.dismissal.untilDate > ctx.today) return null; // postponed, not yet
  }

  const mode = ctx.mode ?? (weekdayIndex(ctx.today) >= 5 ? "weekend" : "weekday");
  let score = 0;
  const reasons: { points: number; text: string }[] = [];
  const add = (points: number, text?: string) => {
    score += points;
    if (text && points > 0) reasons.push({ points, text });
  };

  // ---- what you said matters
  if (c.priority) {
    add(PRIORITY_POINTS[c.priority.level], `it is ${PRIORITY_WORDS[c.priority.level]} for you`);
    if (c.priority.targetDate) {
      const left = daysBetween(ctx.today, c.priority.targetDate);
      if (left < 0) add(35, "it is past its target date");
      else if (left <= 7) add(30, left === 0 ? "its target date is today" : `its target date is in ${plural(left, "day")}`);
      else if (left <= 30) add(15, `its target date is in ${plural(left, "day")}`);
    }
  }

  // ---- where you are
  const remaining = c.pages && c.currentPage != null ? c.pages - c.currentPage : null;
  if (c.status === "reading") {
    add(45, "you are already reading it");
    if (remaining != null && remaining > 0 && remaining <= 100) add(12, `only ${plural(remaining, "page")} are left`);
    if (c.lastSessionDate && daysBetween(dayKey(c.lastSessionDate), ctx.today) >= 14) {
      add(5, `it has been ${plural(daysBetween(dayKey(c.lastSessionDate), ctx.today), "day")} since you last picked it up`);
    }
  } else if (c.status === "on_hold") {
    score -= 15; // paused on purpose
  } else if (c.addedAt) {
    const days = daysBetween(dayKey(c.addedAt), ctx.today);
    if (days >= 0) {
      const points = Math.min(15, days / 20);
      add(points, days >= 60 ? `it has waited in your library for ${describeAge(days)}` : undefined);
    }
  }

  // ---- fit for the time you have
  if (c.status !== "reading" && c.pages) {
    if (mode === "weekend" && c.pages <= 250) add(10, "it is short enough for a weekend");
    else if (mode === "weekday" && c.pages <= 200) add(8, "it fits a shorter reading session");
  }

  // ---- variety and taste
  const recent = ctx.recentGenres.map((g) => g.toLowerCase());
  const lastFew = new Set(recent.slice(0, 3));
  const lowerGenres = c.genres.map((g) => g.toLowerCase());
  if (lowerGenres.length > 0 && recent.length > 0) {
    if (lowerGenres.every((g) => lastFew.has(g))) {
      score -= 10; // same kind of book as your last few reads
    } else {
      const fresh = c.genres.find((g) => !new Set(recent.slice(0, 5)).has(g.toLowerCase()));
      if (fresh) add(10, `it adds variety (you have read little ${fresh} lately)`);
    }
  }
  for (const a of c.authors) {
    const avg = ctx.authorRatings[a.name.toLowerCase()];
    if (avg !== undefined && avg >= 4 && c.status !== "finished") {
      add(12, `you rated other books by ${a.name} highly`);
      break;
    }
  }
  if (lowerGenres.some((g) => (ctx.genreRatings[g] ?? 0) >= 4.5)) add(4);
  if (c.status === "finished" && c.userRating && c.userRating >= 4) add(20, `you rated it ${c.userRating}/5 last time`);

  // ---- you may already have decided
  if (c.plannedThisWeek) score -= 30;

  // ---- popularity is only a tie-breaker
  if (c.goodreadsRating && c.goodreadsRating > 3) add(Math.min(3, (c.goodreadsRating - 3) * 1.5));

  return {
    score: Math.round(score * 10) / 10,
    reasons: reasons.sort((a, b) => b.points - a.points).map((r) => r.text),
  };
}

function sentence(title: string, reasons: string[], mode: "weekday" | "weekend", status: ReadingStatus | null) {
  if (reasons.length === 0) return `${title} is a good candidate from your library.`;
  const top = reasons.slice(0, 3);
  const list = top.length > 1 ? `${top.slice(0, -1).join(", ")}, and ${top[top.length - 1]}` : top[0];
  const lead =
    status === "reading"
      ? `Consider continuing ${title}`
      : mode === "weekend"
        ? `Consider reading ${title} this weekend`
        : `Consider reading ${title} next`;
  return `${lead} because ${list}.`;
}

/** Score, rank and trim. At most 2 "currently reading" books so the list never becomes a second backlog. */
export function scoreRecommendations(candidates: Candidate[], ctx: RecommendationContext): Recommendation[] {
  const mode = ctx.mode ?? (weekdayIndex(ctx.today) >= 5 ? "weekend" : "weekday");
  const limit = ctx.limit ?? 5;

  const scored: Recommendation[] = [];
  for (const c of candidates) {
    const s = scoreCandidate(c, ctx);
    if (!s) continue;
    scored.push({ ...c, score: s.score, reasons: s.reasons, reason: sentence(c.title, s.reasons, mode, c.status) });
  }
  scored.sort((a, b) => b.score - a.score || a.title.localeCompare(b.title));

  const out: Recommendation[] = [];
  let reading = 0;
  for (const r of scored) {
    if (out.length >= limit) break;
    if (r.status === "reading") {
      if (reading >= MAX_CURRENTLY_READING) continue;
      reading++;
    }
    out.push(r);
  }
  return out;
}
