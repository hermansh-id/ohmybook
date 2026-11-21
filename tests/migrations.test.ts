import { expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { PGlite } from "@electric-sql/pglite";
import { drizzle } from "drizzle-orm/pglite";
import { migrate } from "drizzle-orm/pglite/migrator";
import { sql } from "drizzle-orm";

test("migrations apply cleanly, and 0001 is safe to re-run on an already-pushed DB", async () => {
  const db = drizzle(new PGlite());
  await migrate(db, { migrationsFolder: "./drizzle" });

  const tables = (await db.execute(sql`SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'`)).rows.map(
    (r) => (r as { table_name: string }).table_name,
  );
  for (const t of [
    "reading_priorities",
    "reading_priority_history",
    "reading_plans",
    "reading_plan_items",
    "weekly_reading_reviews",
    "recommendation_dismissals",
    "oauth_application",
  ]) {
    expect(tables).toContain(t);
  }

  // Re-run the whole 0001 file: must not throw (simulates `db:push`-managed prod)
  const file = readFileSync("./drizzle/0001_striped_spitfire.sql", "utf8");
  for (const stmt of file.split("--> statement-breakpoint")) {
    if (stmt.trim()) await db.execute(sql.raw(stmt));
  }
});
