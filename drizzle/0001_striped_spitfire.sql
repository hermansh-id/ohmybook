-- Idempotent on purpose: the OAuth tables and uq_authors_name_lower were applied to
-- existing databases with `db:push` before this migration existed.
CREATE TABLE IF NOT EXISTS "oauth_access_token" (
	"id" text PRIMARY KEY NOT NULL,
	"access_token" text NOT NULL,
	"refresh_token" text NOT NULL,
	"access_token_expires_at" timestamp NOT NULL,
	"refresh_token_expires_at" timestamp NOT NULL,
	"client_id" text NOT NULL,
	"user_id" text,
	"scopes" text NOT NULL,
	"created_at" timestamp NOT NULL,
	"updated_at" timestamp NOT NULL,
	CONSTRAINT "oauth_access_token_access_token_unique" UNIQUE("access_token"),
	CONSTRAINT "oauth_access_token_refresh_token_unique" UNIQUE("refresh_token")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "oauth_application" (
	"id" text PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"icon" text,
	"metadata" text,
	"client_id" text NOT NULL,
	"client_secret" text,
	"redirect_urls" text NOT NULL,
	"type" text NOT NULL,
	"disabled" boolean DEFAULT false,
	"user_id" text,
	"created_at" timestamp NOT NULL,
	"updated_at" timestamp NOT NULL,
	CONSTRAINT "oauth_application_client_id_unique" UNIQUE("client_id")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "oauth_consent" (
	"id" text PRIMARY KEY NOT NULL,
	"client_id" text NOT NULL,
	"user_id" text NOT NULL,
	"scopes" text NOT NULL,
	"created_at" timestamp NOT NULL,
	"updated_at" timestamp NOT NULL,
	"consent_given" boolean NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "reading_plan_items" (
	"item_id" serial PRIMARY KEY NOT NULL,
	"plan_id" integer,
	"book_id" integer NOT NULL,
	"scheduled_date" date NOT NULL,
	"time_of_day" varchar(20) DEFAULT 'anytime' NOT NULL,
	"planned_pages" integer,
	"planned_minutes" integer,
	"planned_start_page" integer,
	"planned_end_page" integer,
	"notes" text,
	"status" varchar(20) DEFAULT 'planned' NOT NULL,
	"actual_pages" integer,
	"actual_minutes" integer,
	"completed_at" timestamp,
	"session_id" integer,
	"rescheduled_to_item_id" integer,
	"recurrence_group" varchar(64),
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now(),
	CONSTRAINT "reading_plan_items_status_check" CHECK ("reading_plan_items"."status" IN ('planned', 'completed', 'skipped', 'rescheduled')),
	CONSTRAINT "reading_plan_items_time_check" CHECK ("reading_plan_items"."time_of_day" IN ('morning', 'afternoon', 'evening', 'anytime')),
	CONSTRAINT "reading_plan_items_amounts_check" CHECK (("reading_plan_items"."planned_pages" IS NULL OR "reading_plan_items"."planned_pages" >= 0)
        AND ("reading_plan_items"."planned_minutes" IS NULL OR "reading_plan_items"."planned_minutes" >= 0)
        AND ("reading_plan_items"."actual_pages" IS NULL OR "reading_plan_items"."actual_pages" >= 0)
        AND ("reading_plan_items"."actual_minutes" IS NULL OR "reading_plan_items"."actual_minutes" >= 0))
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "reading_plans" (
	"plan_id" serial PRIMARY KEY NOT NULL,
	"title" varchar(255) NOT NULL,
	"kind" varchar(20) DEFAULT 'custom' NOT NULL,
	"start_date" date,
	"end_date" date,
	"notes" text,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now(),
	CONSTRAINT "reading_plans_kind_check" CHECK ("reading_plans"."kind" IN ('daily', 'weekly', 'weekend', 'custom'))
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "reading_priorities" (
	"priority_id" serial PRIMARY KEY NOT NULL,
	"book_id" integer NOT NULL,
	"level" varchar(20) DEFAULT 'medium' NOT NULL,
	"reason" text,
	"target_date" date,
	"estimated_minutes" integer,
	"status" varchar(20) DEFAULT 'active' NOT NULL,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now(),
	CONSTRAINT "reading_priorities_level_check" CHECK ("reading_priorities"."level" IN ('critical', 'high', 'medium', 'low')),
	CONSTRAINT "reading_priorities_status_check" CHECK ("reading_priorities"."status" IN ('active', 'completed', 'cancelled')),
	CONSTRAINT "reading_priorities_estimate_check" CHECK ("reading_priorities"."estimated_minutes" IS NULL OR "reading_priorities"."estimated_minutes" > 0)
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "reading_priority_history" (
	"history_id" serial PRIMARY KEY NOT NULL,
	"book_id" integer NOT NULL,
	"from_level" varchar(20),
	"to_level" varchar(20),
	"from_status" varchar(20),
	"to_status" varchar(20),
	"created_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "recommendation_dismissals" (
	"dismissal_id" serial PRIMARY KEY NOT NULL,
	"book_id" integer NOT NULL,
	"kind" varchar(20) DEFAULT 'dismissed' NOT NULL,
	"until_date" date,
	"created_at" timestamp DEFAULT now(),
	CONSTRAINT "recommendation_dismissals_kind_check" CHECK ("recommendation_dismissals"."kind" IN ('dismissed', 'postponed'))
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "weekly_reading_reviews" (
	"review_id" serial PRIMARY KEY NOT NULL,
	"week_start" date NOT NULL,
	"went_well" text,
	"blockers" text,
	"next_week_changes" text,
	"planned_items" integer DEFAULT 0 NOT NULL,
	"completed_items" integer DEFAULT 0 NOT NULL,
	"skipped_items" integer DEFAULT 0 NOT NULL,
	"planned_pages" integer DEFAULT 0 NOT NULL,
	"actual_pages" integer DEFAULT 0 NOT NULL,
	"total_pages_read" integer DEFAULT 0 NOT NULL,
	"total_minutes" integer DEFAULT 0 NOT NULL,
	"books_completed" integer DEFAULT 0 NOT NULL,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
DO $$ BEGIN ALTER TABLE "oauth_access_token" ADD CONSTRAINT "oauth_access_token_client_id_oauth_application_client_id_fk" FOREIGN KEY ("client_id") REFERENCES "public"."oauth_application"("client_id") ON DELETE cascade ON UPDATE no action; EXCEPTION WHEN duplicate_object THEN NULL; END $$;--> statement-breakpoint
DO $$ BEGIN ALTER TABLE "oauth_access_token" ADD CONSTRAINT "oauth_access_token_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action; EXCEPTION WHEN duplicate_object THEN NULL; END $$;--> statement-breakpoint
DO $$ BEGIN ALTER TABLE "oauth_application" ADD CONSTRAINT "oauth_application_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action; EXCEPTION WHEN duplicate_object THEN NULL; END $$;--> statement-breakpoint
DO $$ BEGIN ALTER TABLE "oauth_consent" ADD CONSTRAINT "oauth_consent_client_id_oauth_application_client_id_fk" FOREIGN KEY ("client_id") REFERENCES "public"."oauth_application"("client_id") ON DELETE cascade ON UPDATE no action; EXCEPTION WHEN duplicate_object THEN NULL; END $$;--> statement-breakpoint
DO $$ BEGIN ALTER TABLE "oauth_consent" ADD CONSTRAINT "oauth_consent_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action; EXCEPTION WHEN duplicate_object THEN NULL; END $$;--> statement-breakpoint
DO $$ BEGIN ALTER TABLE "reading_plan_items" ADD CONSTRAINT "reading_plan_items_plan_id_reading_plans_plan_id_fk" FOREIGN KEY ("plan_id") REFERENCES "public"."reading_plans"("plan_id") ON DELETE set null ON UPDATE no action; EXCEPTION WHEN duplicate_object THEN NULL; END $$;--> statement-breakpoint
DO $$ BEGIN ALTER TABLE "reading_plan_items" ADD CONSTRAINT "reading_plan_items_book_id_books_book_id_fk" FOREIGN KEY ("book_id") REFERENCES "public"."books"("book_id") ON DELETE cascade ON UPDATE no action; EXCEPTION WHEN duplicate_object THEN NULL; END $$;--> statement-breakpoint
DO $$ BEGIN ALTER TABLE "reading_plan_items" ADD CONSTRAINT "reading_plan_items_session_id_reading_sessions_session_id_fk" FOREIGN KEY ("session_id") REFERENCES "public"."reading_sessions"("session_id") ON DELETE set null ON UPDATE no action; EXCEPTION WHEN duplicate_object THEN NULL; END $$;--> statement-breakpoint
DO $$ BEGIN ALTER TABLE "reading_plan_items" ADD CONSTRAINT "reading_plan_items_rescheduled_to_item_id_reading_plan_items_item_id_fk" FOREIGN KEY ("rescheduled_to_item_id") REFERENCES "public"."reading_plan_items"("item_id") ON DELETE set null ON UPDATE no action; EXCEPTION WHEN duplicate_object THEN NULL; END $$;--> statement-breakpoint
DO $$ BEGIN ALTER TABLE "reading_priorities" ADD CONSTRAINT "reading_priorities_book_id_books_book_id_fk" FOREIGN KEY ("book_id") REFERENCES "public"."books"("book_id") ON DELETE cascade ON UPDATE no action; EXCEPTION WHEN duplicate_object THEN NULL; END $$;--> statement-breakpoint
DO $$ BEGIN ALTER TABLE "reading_priority_history" ADD CONSTRAINT "reading_priority_history_book_id_books_book_id_fk" FOREIGN KEY ("book_id") REFERENCES "public"."books"("book_id") ON DELETE cascade ON UPDATE no action; EXCEPTION WHEN duplicate_object THEN NULL; END $$;--> statement-breakpoint
DO $$ BEGIN ALTER TABLE "recommendation_dismissals" ADD CONSTRAINT "recommendation_dismissals_book_id_books_book_id_fk" FOREIGN KEY ("book_id") REFERENCES "public"."books"("book_id") ON DELETE cascade ON UPDATE no action; EXCEPTION WHEN duplicate_object THEN NULL; END $$;--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_reading_plan_items_date" ON "reading_plan_items" USING btree ("scheduled_date");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_reading_plan_items_book" ON "reading_plan_items" USING btree ("book_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_reading_plan_items_plan" ON "reading_plan_items" USING btree ("plan_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_reading_plan_items_status" ON "reading_plan_items" USING btree ("status");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_reading_plan_items_session" ON "reading_plan_items" USING btree ("session_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_reading_plan_items_recurrence" ON "reading_plan_items" USING btree ("recurrence_group");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_reading_plans_start" ON "reading_plans" USING btree ("start_date");--> statement-breakpoint
CREATE UNIQUE INDEX IF NOT EXISTS "uq_reading_priorities_active_book" ON "reading_priorities" USING btree ("book_id") WHERE "reading_priorities"."status" = 'active';--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_reading_priorities_book" ON "reading_priorities" USING btree ("book_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_reading_priorities_status" ON "reading_priorities" USING btree ("status");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_reading_priorities_target_date" ON "reading_priorities" USING btree ("target_date");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_reading_priority_history_book" ON "reading_priority_history" USING btree ("book_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_reading_priority_history_created" ON "reading_priority_history" USING btree ("created_at");--> statement-breakpoint
CREATE UNIQUE INDEX IF NOT EXISTS "uq_recommendation_dismissals_book" ON "recommendation_dismissals" USING btree ("book_id");--> statement-breakpoint
CREATE UNIQUE INDEX IF NOT EXISTS "uq_weekly_reading_reviews_week" ON "weekly_reading_reviews" USING btree ("week_start");--> statement-breakpoint
CREATE UNIQUE INDEX IF NOT EXISTS "uq_authors_name_lower" ON "authors" USING btree (lower("name"));