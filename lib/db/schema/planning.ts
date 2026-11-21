import {
  pgTable,
  serial,
  integer,
  varchar,
  date,
  text,
  timestamp,
  check,
  index,
  uniqueIndex,
  type AnyPgColumn,
} from "drizzle-orm/pg-core";
import { sql } from "drizzle-orm";
import { books } from "./core";
import { readingSessions } from "./reading";

// A priority is NOT a reading status: a book can be "reading" at any priority.
// At most one ACTIVE priority per book; completed/cancelled rows are history.
export const readingPriorities = pgTable(
  "reading_priorities",
  {
    priorityId: serial("priority_id").primaryKey(),
    bookId: integer("book_id")
      .notNull()
      .references(() => books.bookId, { onDelete: "cascade" }),
    level: varchar("level", { length: 20 }).notNull().default("medium"),
    reason: text("reason"),
    targetDate: date("target_date"),
    estimatedMinutes: integer("estimated_minutes"),
    status: varchar("status", { length: 20 }).notNull().default("active"),
    createdAt: timestamp("created_at").defaultNow(),
    updatedAt: timestamp("updated_at").defaultNow(),
  },
  (table) => ({
    activeBookUnique: uniqueIndex("uq_reading_priorities_active_book")
      .on(table.bookId)
      .where(sql`${table.status} = 'active'`),
    bookIdx: index("idx_reading_priorities_book").on(table.bookId),
    statusIdx: index("idx_reading_priorities_status").on(table.status),
    targetDateIdx: index("idx_reading_priorities_target_date").on(table.targetDate),
    levelCheck: check(
      "reading_priorities_level_check",
      sql`${table.level} IN ('critical', 'high', 'medium', 'low')`
    ),
    statusCheck: check(
      "reading_priorities_status_check",
      sql`${table.status} IN ('active', 'completed', 'cancelled')`
    ),
    estimateCheck: check(
      "reading_priorities_estimate_check",
      sql`${table.estimatedMinutes} IS NULL OR ${table.estimatedMinutes} > 0`
    ),
  })
);

// Every level/status change, so the weekly review can show "what changed".
export const readingPriorityHistory = pgTable(
  "reading_priority_history",
  {
    historyId: serial("history_id").primaryKey(),
    bookId: integer("book_id")
      .notNull()
      .references(() => books.bookId, { onDelete: "cascade" }),
    fromLevel: varchar("from_level", { length: 20 }),
    toLevel: varchar("to_level", { length: 20 }),
    fromStatus: varchar("from_status", { length: 20 }),
    toStatus: varchar("to_status", { length: 20 }),
    createdAt: timestamp("created_at").defaultNow(),
  },
  (table) => ({
    bookIdx: index("idx_reading_priority_history_book").on(table.bookId),
    createdIdx: index("idx_reading_priority_history_created").on(table.createdAt),
  })
);

// Optional container for a plan ("Weekend plan", "Week of ..."). Items may also stand alone.
export const readingPlans = pgTable(
  "reading_plans",
  {
    planId: serial("plan_id").primaryKey(),
    title: varchar("title", { length: 255 }).notNull(),
    kind: varchar("kind", { length: 20 }).notNull().default("custom"),
    startDate: date("start_date"),
    endDate: date("end_date"),
    notes: text("notes"),
    createdAt: timestamp("created_at").defaultNow(),
    updatedAt: timestamp("updated_at").defaultNow(),
  },
  (table) => ({
    startIdx: index("idx_reading_plans_start").on(table.startDate),
    kindCheck: check(
      "reading_plans_kind_check",
      sql`${table.kind} IN ('daily', 'weekly', 'weekend', 'custom')`
    ),
  })
);

// A planned reading activity. planned_* is the original intent and is never
// overwritten; what actually happened lives in actual_* and in the linked
// reading_sessions row (planned and actual stay separate concepts).
export const readingPlanItems = pgTable(
  "reading_plan_items",
  {
    itemId: serial("item_id").primaryKey(),
    planId: integer("plan_id").references(() => readingPlans.planId, { onDelete: "set null" }),
    bookId: integer("book_id")
      .notNull()
      .references(() => books.bookId, { onDelete: "cascade" }),
    scheduledDate: date("scheduled_date").notNull(),
    timeOfDay: varchar("time_of_day", { length: 20 }).notNull().default("anytime"),

    plannedPages: integer("planned_pages"),
    plannedMinutes: integer("planned_minutes"),
    plannedStartPage: integer("planned_start_page"),
    plannedEndPage: integer("planned_end_page"),
    notes: text("notes"),

    status: varchar("status", { length: 20 }).notNull().default("planned"),

    actualPages: integer("actual_pages"),
    actualMinutes: integer("actual_minutes"),
    completedAt: timestamp("completed_at"),
    sessionId: integer("session_id").references(() => readingSessions.sessionId, { onDelete: "set null" }),

    rescheduledToItemId: integer("rescheduled_to_item_id").references(
      (): AnyPgColumn => readingPlanItems.itemId,
      { onDelete: "set null" }
    ),
    recurrenceGroup: varchar("recurrence_group", { length: 64 }),

    createdAt: timestamp("created_at").defaultNow(),
    updatedAt: timestamp("updated_at").defaultNow(),
  },
  (table) => ({
    dateIdx: index("idx_reading_plan_items_date").on(table.scheduledDate),
    bookIdx: index("idx_reading_plan_items_book").on(table.bookId),
    planIdx: index("idx_reading_plan_items_plan").on(table.planId),
    statusIdx: index("idx_reading_plan_items_status").on(table.status),
    sessionIdx: index("idx_reading_plan_items_session").on(table.sessionId),
    recurrenceIdx: index("idx_reading_plan_items_recurrence").on(table.recurrenceGroup),
    statusCheck: check(
      "reading_plan_items_status_check",
      sql`${table.status} IN ('planned', 'completed', 'skipped', 'rescheduled')`
    ),
    timeCheck: check(
      "reading_plan_items_time_check",
      sql`${table.timeOfDay} IN ('morning', 'afternoon', 'evening', 'anytime')`
    ),
    amountsCheck: check(
      "reading_plan_items_amounts_check",
      sql`(${table.plannedPages} IS NULL OR ${table.plannedPages} >= 0)
        AND (${table.plannedMinutes} IS NULL OR ${table.plannedMinutes} >= 0)
        AND (${table.actualPages} IS NULL OR ${table.actualPages} >= 0)
        AND (${table.actualMinutes} IS NULL OR ${table.actualMinutes} >= 0)`
    ),
  })
);

// One review per week (week_start = Monday). Counts are a snapshot taken when saved.
export const weeklyReadingReviews = pgTable(
  "weekly_reading_reviews",
  {
    reviewId: serial("review_id").primaryKey(),
    weekStart: date("week_start").notNull(),
    wentWell: text("went_well"),
    blockers: text("blockers"),
    nextWeekChanges: text("next_week_changes"),
    plannedItems: integer("planned_items").notNull().default(0),
    completedItems: integer("completed_items").notNull().default(0),
    skippedItems: integer("skipped_items").notNull().default(0),
    plannedPages: integer("planned_pages").notNull().default(0),
    actualPages: integer("actual_pages").notNull().default(0),
    totalPagesRead: integer("total_pages_read").notNull().default(0),
    totalMinutes: integer("total_minutes").notNull().default(0),
    booksCompleted: integer("books_completed").notNull().default(0),
    createdAt: timestamp("created_at").defaultNow(),
    updatedAt: timestamp("updated_at").defaultNow(),
  },
  (table) => ({
    weekUnique: uniqueIndex("uq_weekly_reading_reviews_week").on(table.weekStart),
  })
);

// "Not now" / "Dismiss" on a recommendation.
export const recommendationDismissals = pgTable(
  "recommendation_dismissals",
  {
    dismissalId: serial("dismissal_id").primaryKey(),
    bookId: integer("book_id")
      .notNull()
      .references(() => books.bookId, { onDelete: "cascade" }),
    kind: varchar("kind", { length: 20 }).notNull().default("dismissed"),
    untilDate: date("until_date"),
    createdAt: timestamp("created_at").defaultNow(),
  },
  (table) => ({
    bookUnique: uniqueIndex("uq_recommendation_dismissals_book").on(table.bookId),
    kindCheck: check(
      "recommendation_dismissals_kind_check",
      sql`${table.kind} IN ('dismissed', 'postponed')`
    ),
  })
);
