import { describe, expect, test } from "bun:test";
import { computeLogUpdate } from "@/lib/db/reading-progress";

const D = "2026-11-21";

describe("computeLogUpdate (same rules the log-session action always had)", () => {
  test("no log yet: starts reading at the session date", () => {
    expect(computeLogUpdate(null, 200, 30, D)).toEqual({
      currentPage: 30, status: "reading", dateStarted: D, dateFinished: null, isCompleted: false,
    });
  });

  test("want_to_read becomes reading; other statuses are kept", () => {
    expect(computeLogUpdate({ currentPage: 0, status: "want_to_read", dateStarted: null }, 200, 10, D).status).toBe("reading");
    expect(computeLogUpdate({ currentPage: 50, status: "on_hold", dateStarted: "2026-01-01" }, 200, 10, D).status).toBe("on_hold");
  });

  test("adds pages to current page and keeps the original start date", () => {
    const u = computeLogUpdate({ currentPage: 50, status: "reading", dateStarted: "2026-01-01" }, 200, 25, D);
    expect(u.currentPage).toBe(75);
    expect(u.dateStarted).toBe("2026-01-01");
    expect(u.dateFinished).toBeNull();
  });

  test("reaching the last page finishes the book and caps current page", () => {
    const u = computeLogUpdate({ currentPage: 190, status: "reading", dateStarted: "2026-01-01" }, 200, 30, D);
    expect(u).toMatchObject({ currentPage: 200, status: "finished", dateFinished: D, isCompleted: true });
  });

  test("unknown page count never auto-finishes", () => {
    expect(computeLogUpdate(null, null, 500, D).isCompleted).toBe(false);
    expect(computeLogUpdate(null, 0, 500, D).status).toBe("reading");
  });
});
