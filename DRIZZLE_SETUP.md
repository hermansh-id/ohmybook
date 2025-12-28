# Drizzle ORM + Neon PostgreSQL Setup Guide

This project uses [Drizzle ORM](https://orm.drizzle.team/) with [Neon](https://neon.tech/) serverless PostgreSQL database.

## Setup Instructions

### 1. Create a Neon Database

1. Go to [neon.tech](https://neon.tech/) and create an account
2. Create a new project
3. Copy your connection string (it looks like: `postgresql://user:password@host.neon.tech/dbname?sslmode=require`)

### 2. Configure Environment Variables

1. Copy the example environment file:
   ```bash
   cp .env.example .env.local
   ```

2. Update `.env.local` with your Neon connection string:
   ```
   DATABASE_URL=postgresql://user:password@host.neon.tech/dbname?sslmode=require
   ```

### 3. Push Schema to Database

For development, you can push your schema directly to the database:

```bash
bun db:push
```

This will sync your schema with the database without creating migration files.

### 4. (Optional) Generate and Run Migrations

For production or when you want to track schema changes:

```bash
# Generate migration files
bun db:generate

# Apply migrations to database
bun db:migrate
```

Migration files will be created in the `drizzle/` directory.

## Available Scripts

- `bun db:generate` - Generate migration files from schema changes
- `bun db:migrate` - Apply pending migrations to the database
- `bun db:push` - Push schema changes directly to database (useful for development)
- `bun db:studio` - Open Drizzle Studio to browse your database

## Schema Overview

The database schema includes:

### Core Tables
- `users` - User accounts
- `authors` - Book authors
- `genres` - Book genres
- `series` - Book series
- `books` - Book catalog
- `goodreads_data` - Enriched data from Goodreads

### Relationship Tables
- `book_authors` - Many-to-many relationship between books and authors
- `book_genres` - Many-to-many relationship between books and genres
- `series_books` - Links books to series

### Reading Tracking
- `reading_log` - Main reading tracking table (status, dates, ratings, reviews)
- `reading_sessions` - Detailed reading session tracking

### Statistics
- `reading_stats` - Overall reading statistics
- `yearly_stats` - Yearly reading statistics
- `monthly_stats` - Monthly reading statistics
- `reading_goals` - Reading goals per year

## Using the Database in Your App

Import and use the database client:

```typescript
import { db } from "@/lib/db";
import { books, authors, readingLog } from "@/lib/db/schema";
import { eq } from "drizzle-orm";

// Select all books
const allBooks = await db.select().from(books);

// Select with join
const booksWithAuthors = await db
  .select()
  .from(books)
  .leftJoin(bookAuthors, eq(books.bookId, bookAuthors.bookId))
  .leftJoin(authors, eq(bookAuthors.authorId, authors.authorId));

// Insert a new book
const newBook = await db
  .insert(books)
  .values({
    title: "Example Book",
    isbn: "1234567890",
    year: 2024,
    pages: 300,
  })
  .returning();

// Update reading log
await db
  .update(readingLog)
  .set({ status: "finished", dateFinished: new Date() })
  .where(eq(readingLog.bookId, 1));
```

## Drizzle Studio

Drizzle Studio is a visual database browser. Launch it with:

```bash
bun db:studio
```

This will open a web interface at `https://local.drizzle.studio` where you can:
- Browse all tables and data
- Run queries
- Edit data directly
- View relationships

## Deployment to Vercel

1. Add your `DATABASE_URL` environment variable to Vercel:
   - Go to your project settings in Vercel
   - Navigate to Environment Variables
   - Add `DATABASE_URL` with your Neon connection string

2. The Neon serverless driver is optimized for Vercel Edge Functions and serverless environments.

## Important Notes

### Triggers and Functions

The original `structure.sql` includes PostgreSQL triggers and functions for:
- Auto-calculating reading days
- Auto-updating statistics
- Auto-updating series book counts

**These are NOT included in the Drizzle schema** because:
1. Drizzle doesn't support trigger/function definitions in schema
2. For serverless environments, it's better to handle this logic in your application code

If you need these triggers, you can:
- Run the SQL from `structure.sql` directly in your Neon database console
- Or implement the logic in your application code

### Views

The original schema includes several views (v_books_full, v_reading_progress, etc.). These are also not included in the Drizzle schema. You can:
- Create them manually using raw SQL
- Or use Drizzle's query builder to create equivalent queries

Example of creating a view manually:

```typescript
import { sql } from "drizzle-orm";
import { db } from "@/lib/db";

// Execute raw SQL to create view
await db.execute(sql`
  CREATE VIEW v_books_full AS
  SELECT ...
`);
```

## Learn More

- [Drizzle ORM Documentation](https://orm.drizzle.team/docs/overview)
- [Neon Documentation](https://neon.tech/docs/introduction)
- [Drizzle + Neon Guide](https://orm.drizzle.team/docs/get-started-postgresql#neon)
