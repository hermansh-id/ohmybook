import { describe, expect, test } from "bun:test";
import { addDays, daysBetween, isDateKey, todayInTimezone, weekDays, weekStartKey, weekdayIndex, weekendOf } from "@/lib/dates";

describe("dates", () => {
  test("isDateKey", () => {
    expect(isDateKey("2026-02-28")).toBe(true);
    expect(isDateKey("2026-02-30")).toBe(false);
    expect(isDateKey("26-1-1")).toBe(false);
    expect(isDateKey(5)).toBe(false);
  });
  test("addDays crosses month/year boundaries", () => {
    expect(addDays("2026-12-31", 1)).toBe("2027-01-01");
    expect(addDays("2026-03-01", -1)).toBe("2026-02-28");
  });
  test("weeks start on Monday", () => {
    expect(weekdayIndex("2026-11-21")).toBe(5); // Saturday
    expect(weekStartKey("2026-11-21")).toBe("2026-11-16");
    expect(weekStartKey("2026-11-22")).toBe("2026-11-16"); // Sunday belongs to the Monday before
    expect(weekStartKey("2026-11-16")).toBe("2026-11-16");
    expect(weekDays("2026-11-16")).toHaveLength(7);
    expect(weekendOf("2026-11-16")).toEqual(["2026-11-21", "2026-11-22"]);
    expect(daysBetween("2026-11-16", "2026-11-22")).toBe(6);
  });
  test("todayInTimezone returns a date key and respects the zone", () => {
    expect(isDateKey(todayInTimezone("UTC"))).toBe(true);
    const diff = daysBetween(todayInTimezone("Pacific/Kiritimati"), todayInTimezone("Pacific/Pago_Pago"));
    expect(Math.abs(diff)).toBeLessThanOrEqual(2);
  });
});
