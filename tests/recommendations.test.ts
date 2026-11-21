import { beforeAll, beforeEach, describe, expect, test } from "bun:test";
import { PGlite } from "@electric-sql/pglite";
import { drizzle } from "drizzle-orm/pglite";
import { migrate } from "drizzle-orm/pglite/migrator";
import { sql } from "drizzle-orm";
import * as schema from "@/lib/db/schema";
import { BookInputError, createBookWithAuthors } from "@/lib/db/book-writes";
import { getRecommendations } from "@/lib/db/recommendation-reads";
import { addPlanItems, dismissRecommendation, postponeRecommendation, restoreRecommendation, setPriority } from "@/lib/db/planning-writes";
import { scoreRecommendations, type Candidate, type RecommendationContext } from "@/lib/recommendations";

// 2026-11-18 is a Wednesday; 2026-11-21 a Saturday
const ctx = (over: Partial<RecommendationContext> = {}): RecommendationContext => ({
  today: "2026-11-18",
  recentGenres: [],
  authorRatings: {},
  genreRatings: {},
  ...over,
});

let nextId = 1;
const cand = (over: Partial<Candidate> = {}): Candidate => {
  const id = nextId++;
  return {
    bookId: id,
    title: `Book ${id}`,
    pages: 300,
    addedAt: "2026-11-01T00:00:00Z",
    status: "want_to_read",
    currentPage: null,
    lastSessionDate: null,
    authors: [],
    genres: [],
    coverUrl: null,
    goodreadsRating: null,
    goodreadsRatingsCount: null,
    userRating: null,
    priority: null,
    dismissal: null,
    plannedThisWeek: false,
    ...over,
  };
};
const titles = (rs: { title: string }[]) => rs.map((r) => r.title);

describe("scoreRecommendations", () => {
  test("never suggests finished or did-not-finish books (unless rereads are asked for)", () => {
    const list = [cand({ title: "A" }), cand({ title: "Done", status: "finished" }), cand({ title: "Dropped", status: "did_not_finish" })];
    expect(titles(scoreRecommendations(list, ctx()))).toEqual(["A"]);
    const reread = scoreRecommendations(list, ctx({ includeFinished: true }));
    expect(titles(reread)).toEqual(["Done"]); // DNF is never suggested
  });

  test("want_to_read books are candidates (the old engine skipped them)", () => {
    expect(titles(scoreRecommendations([cand({ title: "Wishlist", status: "want_to_read" }), cand({ title: "NoLog", status: null })], ctx())).sort()).toEqual(["NoLog", "Wishlist"]);
  });

  test("user priority outranks everything else: critical > high > medium > low > none", () => {
    const mk = (title: string, level: "critical" | "high" | "medium" | "low" | null) =>
      cand({ title, priority: level ? { level, reason: null, targetDate: null } : null });
    const out = scoreRecommendations([mk("none", null), mk("low", "low"), mk("critical", "critical"), mk("medium", "medium"), mk("high", "high")], ctx());
    expect(titles(out)).toEqual(["critical", "high", "medium", "low", "none"]);
  });

  test("Goodreads popularity is only a tie-breaker", () => {
    const popular = cand({ title: "Popular", goodreadsRating: 4.9 });
    const prioritized = cand({ title: "Mine", priority: { level: "low", reason: null, targetDate: null } });
    expect(titles(scoreRecommendations([popular, prioritized], ctx()))[0]).toBe("Mine");
    const a = cand({ title: "A" });
    const b = cand({ title: "B", goodreadsRating: 4.5 });
    expect(titles(scoreRecommendations([a, b], ctx()))[0]).toBe("B"); // wins a tie, nothing more
  });

  test("a book you are reading is surfaced, with a reason", () => {
    const [r] = scoreRecommendations([cand({ title: "Middlemarch", status: "reading", currentPage: 100, pages: 800 })], ctx());
    expect(r.reasons).toContain("you are already reading it");
    expect(r.reason).toBe("Consider continuing Middlemarch because you are already reading it.");
  });

  test("shows only a few suggestions: default 5, at most 2 currently-reading", () => {
    const reading = [1, 2, 3, 4].map((i) => cand({ title: `Reading ${i}`, status: "reading", currentPage: 10 }));
    const queued = [1, 2, 3, 4, 5, 6].map((i) => cand({ title: `Queued ${i}` }));
    const out = scoreRecommendations([...reading, ...queued], ctx());
    expect(out).toHaveLength(5);
    expect(out.filter((r) => r.status === "reading")).toHaveLength(2);
    expect(scoreRecommendations(queued, ctx({ limit: 3 }))).toHaveLength(3);
  });

  test("dismissed is never suggested; postponed is hidden until its date", () => {
    const dismissed = cand({ title: "Dismissed", dismissal: { kind: "dismissed", untilDate: null } });
    const postponed = cand({ title: "Postponed", dismissal: { kind: "postponed", untilDate: "2026-11-25" } });
    expect(scoreRecommendations([dismissed, postponed], ctx())).toHaveLength(0);
    expect(titles(scoreRecommendations([dismissed, postponed], ctx({ today: "2026-11-25" })))).toEqual(["Postponed"]);
  });

  test("target dates raise urgency; past targets are called out", () => {
    const mk = (title: string, targetDate: string | null) =>
      cand({ title, priority: { level: "medium", reason: null, targetDate } });
    const out = scoreRecommendations([mk("far", "2027-03-01"), mk("soon", "2026-11-22"), mk("late", "2026-11-10")], ctx());
    expect(titles(out)).toEqual(["late", "soon", "far"]);
    expect(out[0].reasons).toContain("it is past its target date");
    expect(out[1].reasons).toContain("its target date is in 4 days");
  });

  test("genre diversity: same genre as your last reads is nudged down, a fresh genre up", () => {
    const c = ctx({ recentGenres: ["Fantasy", "Fantasy", "Crime"] });
    const same = cand({ title: "Same", genres: ["Fantasy"] });
    const fresh = cand({ title: "Fresh", genres: ["History"] });
    const out = scoreRecommendations([same, fresh], c);
    expect(titles(out)).toEqual(["Fresh", "Same"]);
    expect(out[0].reasons.join(" ")).toContain("adds variety");
  });

  test("length fit: short books suit a weekend, and the bonus is explained", () => {
    const short = cand({ title: "Short", pages: 120 });
    const long = cand({ title: "Long", pages: 900 });
    const weekend = scoreRecommendations([long, short], ctx({ mode: "weekend" }));
    expect(titles(weekend)).toEqual(["Short", "Long"]);
    expect(weekend[0].reasons).toContain("it is short enough for a weekend");
    // mode follows the day of the week by default
    expect(scoreRecommendations([short], ctx({ today: "2026-11-21" }))[0].reason).toContain("this weekend");
    expect(scoreRecommendations([short], ctx({ today: "2026-11-18" }))[0].reason).toContain("next because");
  });

  test("your own past ratings of an author count", () => {
    const loved = cand({ title: "Loved author", authors: [{ id: 1, name: "Ursula" }] });
    const other = cand({ title: "Other" });
    const out = scoreRecommendations([other, loved], ctx({ authorRatings: { ursula: 4.5 } }));
    expect(titles(out)).toEqual(["Loved author", "Other"]);
    expect(out[0].reasons).toContain("you rated other books by Ursula highly");
  });

  test("a book already on this week's plan is ranked lower, and paused books too", () => {
    const planned = cand({ title: "Planned", plannedThisWeek: true });
    const paused = cand({ title: "Paused", status: "on_hold", currentPage: 50 });
    const plain = cand({ title: "Plain" });
    expect(titles(scoreRecommendations([planned, paused, plain], ctx()))[0]).toBe("Plain");
  });

  test("every suggestion explains itself; the sentence matches the example style", () => {
    const [r] = scoreRecommendations(
      [cand({ title: "Dubliners", pages: 200, priority: { level: "high", reason: null, targetDate: null } })],
      ctx({ mode: "weekend" }),
    );
    expect(r.reasons.length).toBeGreaterThan(0);
    expect(r.reason).toBe("Consider reading Dubliners this weekend because it is a high priority for you, and it is short enough for a weekend.");
    expect(scoreRecommendations([cand({ title: "Bare" })], ctx())[0].reason).toContain("Bare");
  });

  test("rereads: highly rated finished books explain why", () => {
    const [r] = scoreRecommendations([cand({ title: "Beloved", status: "finished", userRating: 5 })], ctx({ includeFinished: true }));
    expect(r.reasons).toContain("you rated it 5/5 last time");
  });
});

// ------------------------------------------------------------------- database
const { readingLog } = schema;
const db = drizzle(new PGlite(), { schema });

beforeAll(async () => {
  await migrate(db, { migrationsFolder: "./drizzle" });
});
beforeEach(async () => {
  await db.execute(sql`TRUNCATE books, authors, genres RESTART IDENTITY CASCADE`);
});

const book = (title: string, extra: Partial<Parameters<typeof createBookWithAuthors>[1]> = {}) =>
  createBookWithAuthors(db, { title, pages: 200, authors: [`Author of ${title}`], ...extra });

describe("getRecommendations (database)", () => {
  test("loads candidates with status, priority, planned flag; excludes finished/dnf/dismissed", async () => {
    const wish = await book("Wishlist");
    const nolog = await book("No log yet");
    const reading = await book("In progress");
    const finished = await book("Finished one");
    const dnf = await book("Dropped one");
    const hidden = await book("Hidden one");
    await db.insert(readingLog).values([
      { bookId: wish.bookId, status: "want_to_read" },
      { bookId: reading.bookId, status: "reading", currentPage: 50 },
      { bookId: finished.bookId, status: "finished", dateFinished: "2026-11-01", rating: 5 },
      { bookId: dnf.bookId, status: "did_not_finish" },
    ]);
    await setPriority(db, { bookId: wish.bookId, level: "high", reason: "wishlist", targetDate: "2026-11-30" });
    await addPlanItems(db, [{ bookId: reading.bookId, scheduledDate: "2026-11-19", plannedPages: 20 }]);
    await dismissRecommendation(db, hidden.bookId);

    const out = await getRecommendations(db, { today: "2026-11-18", limit: 10 });
    expect(titles(out).sort()).toEqual(["In progress", "No log yet", "Wishlist"]);
    const w = out.find((r) => r.title === "Wishlist")!;
    expect(w.priority).toEqual({ level: "high", reason: "wishlist", targetDate: "2026-11-30" });
    expect(w.authors).toEqual([{ id: expect.any(Number), name: "Author of Wishlist" }]);
    expect(out.find((r) => r.title === "In progress")!.plannedThisWeek).toBe(true);
    expect(out.find((r) => r.title === "No log yet")!.status).toBeNull();
    expect(nolog.bookId).toBeGreaterThan(0);
    expect(out[0].title).toBe("Wishlist"); // the one with a priority and a target date
  });

  test("postpone hides until the date, restore brings it back", async () => {
    const b = await book("Later");
    await postponeRecommendation(db, b.bookId, "2026-11-25");
    expect(await getRecommendations(db, { today: "2026-11-18" })).toHaveLength(0);
    expect(await getRecommendations(db, { today: "2026-11-25" })).toHaveLength(1);
    await restoreRecommendation(db, b.bookId);
    expect(await getRecommendations(db, { today: "2026-11-18" })).toHaveLength(1);
    await dismissRecommendation(db, b.bookId);
    expect(await getRecommendations(db, { today: "2026-12-30" })).toHaveLength(0);
    await expect(postponeRecommendation(db, b.bookId, "soon")).rejects.toBeInstanceOf(BookInputError);
    await expect(dismissRecommendation(db, 9999)).rejects.toBeInstanceOf(BookInputError);
  });

  test("taste context: recent genres and author ratings come from finished books", async () => {
    const f1 = await book("Fantasy read", { genres: ["Fantasy"], authors: ["Ursula"] });
    const f2 = await book("Fantasy read 2", { genres: ["Fantasy"] });
    const f3 = await book("Fantasy read 3", { genres: ["Fantasy"] });
    await db.insert(readingLog).values([
      { bookId: f1.bookId, status: "finished", dateFinished: "2026-11-10", rating: 5 },
      { bookId: f2.bookId, status: "finished", dateFinished: "2026-11-05", rating: 4 },
      { bookId: f3.bookId, status: "finished", dateFinished: "2026-11-01", rating: 3 },
    ]);
    const sameGenre = await book("More fantasy", { genres: ["Fantasy"] });
    const byUrsula = await book("Another by Ursula", { genres: ["Fantasy"], authors: ["Ursula"] });
    const history = await book("History book", { genres: ["History"] });
    const out = await getRecommendations(db, { today: "2026-11-18", limit: 10 });
    expect(titles(out)[0]).toBe("Another by Ursula"); // liked author wins even in a familiar genre
    expect(titles(out).indexOf("History book")).toBeLessThan(titles(out).indexOf("More fantasy"));
    expect(sameGenre.bookId + byUrsula.bookId + history.bookId).toBeGreaterThan(0);
  });

  test("rereads mode returns only finished books", async () => {
    const done = await book("Beloved");
    await book("Unread");
    await db.insert(readingLog).values({ bookId: done.bookId, status: "finished", dateFinished: "2026-10-01", rating: 5 });
    const out = await getRecommendations(db, { today: "2026-11-18", includeFinished: true });
    expect(titles(out)).toEqual(["Beloved"]);
  });
});
