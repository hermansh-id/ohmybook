CREATE TABLE "users" (
	"id" text PRIMARY KEY NOT NULL,
	"name" varchar(100) NOT NULL,
	"email" varchar(255) NOT NULL,
	"email_verified" boolean DEFAULT false NOT NULL,
	"image" text,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "users_email_unique" UNIQUE("email")
);
--> statement-breakpoint
CREATE TABLE "account" (
	"id" text PRIMARY KEY NOT NULL,
	"account_id" text NOT NULL,
	"provider_id" text NOT NULL,
	"user_id" text NOT NULL,
	"access_token" text,
	"refresh_token" text,
	"id_token" text,
	"access_token_expires_at" timestamp,
	"refresh_token_expires_at" timestamp,
	"scope" text,
	"password" text,
	"created_at" timestamp NOT NULL,
	"updated_at" timestamp NOT NULL
);
--> statement-breakpoint
CREATE TABLE "session" (
	"id" text PRIMARY KEY NOT NULL,
	"expires_at" timestamp NOT NULL,
	"token" text NOT NULL,
	"created_at" timestamp NOT NULL,
	"updated_at" timestamp NOT NULL,
	"ip_address" text,
	"user_agent" text,
	"user_id" text NOT NULL,
	CONSTRAINT "session_token_unique" UNIQUE("token")
);
--> statement-breakpoint
CREATE TABLE "verification" (
	"id" text PRIMARY KEY NOT NULL,
	"identifier" text NOT NULL,
	"value" text NOT NULL,
	"expires_at" timestamp NOT NULL,
	"created_at" timestamp,
	"updated_at" timestamp
);
--> statement-breakpoint
CREATE TABLE "authors" (
	"author_id" serial PRIMARY KEY NOT NULL,
	"name" varchar(255) NOT NULL,
	"bio" text,
	"created_at" timestamp DEFAULT now(),
	CONSTRAINT "authors_name_unique" UNIQUE("name")
);
--> statement-breakpoint
CREATE TABLE "books" (
	"book_id" serial PRIMARY KEY NOT NULL,
	"title" varchar(255) NOT NULL,
	"isbn" varchar(255),
	"goodreads_url" text,
	"year" integer,
	"pages" integer,
	"added_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "genres" (
	"genre_id" serial PRIMARY KEY NOT NULL,
	"genre_name" varchar(100) NOT NULL,
	"description" text,
	"created_at" timestamp DEFAULT now(),
	CONSTRAINT "genres_genre_name_unique" UNIQUE("genre_name")
);
--> statement-breakpoint
CREATE TABLE "goodreads_data" (
	"book_id" integer PRIMARY KEY NOT NULL,
	"goodreads_id" varchar(50),
	"description" text,
	"average_rating" numeric(3, 2),
	"ratings_count" integer,
	"reviews_count" integer,
	"publication_date" date,
	"publisher" varchar(255),
	"language" varchar(50),
	"series" varchar(255),
	"series_position" integer,
	"original_title" varchar(255),
	"original_publication_year" integer,
	"cover_url" text,
	"awards" text[],
	"genres" text[],
	"scrape_date" timestamp DEFAULT now(),
	"last_updated" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "series" (
	"series_id" serial PRIMARY KEY NOT NULL,
	"title" varchar(255) NOT NULL,
	"description" text,
	"total_books" integer DEFAULT 0,
	"status" varchar(50) DEFAULT 'unknown',
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now(),
	CONSTRAINT "series_status_check" CHECK ("series"."status" IN ('ongoing', 'completed', 'cancelled', 'unknown'))
);
--> statement-breakpoint
CREATE TABLE "book_authors" (
	"book_id" integer NOT NULL,
	"author_id" integer NOT NULL,
	"author_order" integer DEFAULT 1,
	CONSTRAINT "book_authors_book_id_author_id_pk" PRIMARY KEY("book_id","author_id")
);
--> statement-breakpoint
CREATE TABLE "book_genres" (
	"book_id" integer NOT NULL,
	"genre_id" integer NOT NULL,
	"is_primary" boolean DEFAULT false,
	CONSTRAINT "book_genres_book_id_genre_id_pk" PRIMARY KEY("book_id","genre_id")
);
--> statement-breakpoint
CREATE TABLE "series_books" (
	"series_id" integer NOT NULL,
	"book_id" integer NOT NULL,
	"position" integer NOT NULL,
	"is_side_story" boolean DEFAULT false,
	"created_at" timestamp DEFAULT now(),
	CONSTRAINT "series_books_series_id_book_id_pk" PRIMARY KEY("series_id","book_id")
);
--> statement-breakpoint
CREATE TABLE "book_quotes" (
	"quote_id" serial PRIMARY KEY NOT NULL,
	"book_id" integer NOT NULL,
	"quote_text" text NOT NULL,
	"page_number" integer,
	"chapter" varchar(255),
	"tags" text[],
	"is_favorite" boolean DEFAULT false,
	"notes" text,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "reading_log" (
	"log_id" serial PRIMARY KEY NOT NULL,
	"book_id" integer NOT NULL,
	"status" varchar(50) DEFAULT 'want_to_read',
	"date_added" date DEFAULT now(),
	"date_started" date,
	"date_finished" date,
	"current_page" integer DEFAULT 0,
	"rating" integer,
	"review" text,
	"notes" text,
	"reading_days" integer,
	"reread" boolean DEFAULT false,
	"reread_count" integer DEFAULT 0,
	"tags" text[],
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now(),
	CONSTRAINT "unique_book_log" UNIQUE("book_id"),
	CONSTRAINT "reading_log_rating_check" CHECK ("reading_log"."rating" >= 1 AND "reading_log"."rating" <= 5),
	CONSTRAINT "reading_log_status_check" CHECK ("reading_log"."status" IN ('want_to_read', 'reading', 'finished', 'did_not_finish', 'on_hold'))
);
--> statement-breakpoint
CREATE TABLE "reading_sessions" (
	"session_id" serial PRIMARY KEY NOT NULL,
	"book_id" integer NOT NULL,
	"session_date" date NOT NULL,
	"pages_read" integer,
	"minutes_read" integer,
	"start_page" integer,
	"end_page" integer,
	"notes" text,
	"created_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "monthly_stats" (
	"month_id" serial PRIMARY KEY NOT NULL,
	"year" integer NOT NULL,
	"month" integer NOT NULL,
	"books_read" integer DEFAULT 0,
	"pages_read" integer DEFAULT 0,
	"average_rating" numeric(3, 2),
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now(),
	CONSTRAINT "monthly_stats_year_month_key" UNIQUE("year","month"),
	CONSTRAINT "monthly_stats_month_check" CHECK ("monthly_stats"."month" >= 1 AND "monthly_stats"."month" <= 12)
);
--> statement-breakpoint
CREATE TABLE "reading_goals" (
	"goal_id" serial PRIMARY KEY NOT NULL,
	"year" integer NOT NULL,
	"target_books" integer,
	"target_pages" integer,
	"current_books" integer DEFAULT 0,
	"current_pages" integer DEFAULT 0,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now(),
	CONSTRAINT "unique_year_goal" UNIQUE("year")
);
--> statement-breakpoint
CREATE TABLE "reading_stats" (
	"stats_id" serial PRIMARY KEY NOT NULL,
	"total_books_read" integer DEFAULT 0,
	"total_books_dnf" integer DEFAULT 0,
	"total_pages_read" integer DEFAULT 0,
	"total_books_reading" integer DEFAULT 0,
	"total_books_want_to_read" integer DEFAULT 0,
	"average_rating" numeric(3, 2),
	"average_book_length" integer,
	"average_reading_days" numeric(5, 1),
	"current_reading_streak" integer DEFAULT 0,
	"longest_reading_streak" integer DEFAULT 0,
	"last_read_date" date,
	"favorite_genre_id" integer,
	"favorite_author_id" integer,
	"books_read_this_year" integer DEFAULT 0,
	"books_read_this_month" integer DEFAULT 0,
	"pages_read_this_year" integer DEFAULT 0,
	"pages_read_this_month" integer DEFAULT 0,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "yearly_stats" (
	"year_id" serial PRIMARY KEY NOT NULL,
	"year" integer NOT NULL,
	"books_read" integer DEFAULT 0,
	"pages_read" integer DEFAULT 0,
	"average_rating" numeric(3, 2),
	"top_genre_id" integer,
	"top_author_id" integer,
	"longest_book_id" integer,
	"shortest_book_id" integer,
	"highest_rated_book_id" integer,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now(),
	CONSTRAINT "yearly_stats_year_unique" UNIQUE("year"),
	CONSTRAINT "yearly_stats_year_key" UNIQUE("year")
);
--> statement-breakpoint
ALTER TABLE "account" ADD CONSTRAINT "account_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "session" ADD CONSTRAINT "session_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "goodreads_data" ADD CONSTRAINT "goodreads_data_book_id_books_book_id_fk" FOREIGN KEY ("book_id") REFERENCES "public"."books"("book_id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "book_authors" ADD CONSTRAINT "book_authors_book_id_books_book_id_fk" FOREIGN KEY ("book_id") REFERENCES "public"."books"("book_id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "book_authors" ADD CONSTRAINT "book_authors_author_id_authors_author_id_fk" FOREIGN KEY ("author_id") REFERENCES "public"."authors"("author_id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "book_genres" ADD CONSTRAINT "book_genres_book_id_books_book_id_fk" FOREIGN KEY ("book_id") REFERENCES "public"."books"("book_id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "book_genres" ADD CONSTRAINT "book_genres_genre_id_genres_genre_id_fk" FOREIGN KEY ("genre_id") REFERENCES "public"."genres"("genre_id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "series_books" ADD CONSTRAINT "series_books_series_id_series_series_id_fk" FOREIGN KEY ("series_id") REFERENCES "public"."series"("series_id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "series_books" ADD CONSTRAINT "series_books_book_id_books_book_id_fk" FOREIGN KEY ("book_id") REFERENCES "public"."books"("book_id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "book_quotes" ADD CONSTRAINT "book_quotes_book_id_books_book_id_fk" FOREIGN KEY ("book_id") REFERENCES "public"."books"("book_id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "reading_log" ADD CONSTRAINT "reading_log_book_id_books_book_id_fk" FOREIGN KEY ("book_id") REFERENCES "public"."books"("book_id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "reading_sessions" ADD CONSTRAINT "reading_sessions_book_id_books_book_id_fk" FOREIGN KEY ("book_id") REFERENCES "public"."books"("book_id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "reading_stats" ADD CONSTRAINT "reading_stats_favorite_genre_id_genres_genre_id_fk" FOREIGN KEY ("favorite_genre_id") REFERENCES "public"."genres"("genre_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "reading_stats" ADD CONSTRAINT "reading_stats_favorite_author_id_authors_author_id_fk" FOREIGN KEY ("favorite_author_id") REFERENCES "public"."authors"("author_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "yearly_stats" ADD CONSTRAINT "yearly_stats_top_genre_id_genres_genre_id_fk" FOREIGN KEY ("top_genre_id") REFERENCES "public"."genres"("genre_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "yearly_stats" ADD CONSTRAINT "yearly_stats_top_author_id_authors_author_id_fk" FOREIGN KEY ("top_author_id") REFERENCES "public"."authors"("author_id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "idx_users_email" ON "users" USING btree ("email");--> statement-breakpoint
CREATE INDEX "idx_authors_name" ON "authors" USING btree ("name");--> statement-breakpoint
CREATE INDEX "idx_books_title" ON "books" USING btree ("title");--> statement-breakpoint
CREATE INDEX "idx_books_isbn" ON "books" USING btree ("isbn");--> statement-breakpoint
CREATE INDEX "idx_books_year" ON "books" USING btree ("year");--> statement-breakpoint
CREATE INDEX "idx_book_authors_author" ON "book_authors" USING btree ("author_id");--> statement-breakpoint
CREATE INDEX "idx_book_authors_book" ON "book_authors" USING btree ("book_id");--> statement-breakpoint
CREATE INDEX "idx_book_genres_book" ON "book_genres" USING btree ("book_id");--> statement-breakpoint
CREATE INDEX "idx_book_genres_genre" ON "book_genres" USING btree ("genre_id");--> statement-breakpoint
CREATE INDEX "idx_series_books_book" ON "series_books" USING btree ("book_id");--> statement-breakpoint
CREATE INDEX "idx_series_books_series" ON "series_books" USING btree ("series_id");--> statement-breakpoint
CREATE INDEX "idx_series_books_position" ON "series_books" USING btree ("position");--> statement-breakpoint
CREATE INDEX "idx_book_quotes_book" ON "book_quotes" USING btree ("book_id");--> statement-breakpoint
CREATE INDEX "idx_book_quotes_favorite" ON "book_quotes" USING btree ("is_favorite");--> statement-breakpoint
CREATE INDEX "idx_book_quotes_created" ON "book_quotes" USING btree ("created_at");--> statement-breakpoint
CREATE INDEX "idx_reading_log_status" ON "reading_log" USING btree ("status");--> statement-breakpoint
CREATE INDEX "idx_reading_log_date_finished" ON "reading_log" USING btree ("date_finished");--> statement-breakpoint
CREATE INDEX "idx_reading_log_date_started" ON "reading_log" USING btree ("date_started");--> statement-breakpoint
CREATE INDEX "idx_reading_log_rating" ON "reading_log" USING btree ("rating");--> statement-breakpoint
CREATE INDEX "idx_reading_sessions_book" ON "reading_sessions" USING btree ("book_id");--> statement-breakpoint
CREATE INDEX "idx_reading_sessions_date" ON "reading_sessions" USING btree ("session_date");