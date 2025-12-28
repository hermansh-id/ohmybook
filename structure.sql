-- ============================================================================
-- READING TRACKER DATABASE SCHEMA
-- Comprehensive schema untuk personal reading statistics & analytics
-- ============================================================================

-- Drop existing tables (cascade untuk delete dependencies)
DROP TABLE IF EXISTS reading_sessions CASCADE;
DROP TABLE IF EXISTS reading_goals CASCADE;
DROP TABLE IF EXISTS monthly_stats CASCADE;
DROP TABLE IF EXISTS yearly_stats CASCADE;
DROP TABLE IF EXISTS reading_stats CASCADE;
DROP TABLE IF EXISTS reading_log CASCADE;
DROP TABLE IF EXISTS series_books CASCADE;
DROP TABLE IF EXISTS book_genres CASCADE;
DROP TABLE IF EXISTS book_authors CASCADE;
DROP TABLE IF EXISTS goodreads_data CASCADE;
DROP TABLE IF EXISTS books CASCADE;
DROP TABLE IF EXISTS series CASCADE;
DROP TABLE IF EXISTS genres CASCADE;
DROP TABLE IF EXISTS authors CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Drop views
DROP VIEW IF EXISTS v_reading_streak CASCADE;
DROP VIEW IF EXISTS v_monthly_trends CASCADE;
DROP VIEW IF EXISTS v_author_stats CASCADE;
DROP VIEW IF EXISTS v_genre_stats CASCADE;
DROP VIEW IF EXISTS v_reading_progress CASCADE;
DROP VIEW IF EXISTS v_books_full CASCADE;

-- Drop functions
DROP FUNCTION IF EXISTS update_reading_days() CASCADE;
DROP FUNCTION IF EXISTS update_reading_stats() CASCADE;
DROP FUNCTION IF EXISTS update_monthly_stats() CASCADE;
DROP FUNCTION IF EXISTS update_yearly_stats() CASCADE;
DROP FUNCTION IF EXISTS update_series_total_books() CASCADE;
DROP FUNCTION IF EXISTS calculate_reading_streak() CASCADE;

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- Users table (optional, bisa single user atau multi-user)
CREATE TABLE users (
    user_id uuid DEFAULT gen_random_uuid() NOT NULL,
    username varchar(100) NOT NULL,
    email varchar(255) NOT NULL,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT users_pkey PRIMARY KEY (user_id),
    CONSTRAINT users_email_key UNIQUE (email),
    CONSTRAINT users_username_key UNIQUE (username)
);

CREATE INDEX idx_users_email ON users USING btree (email);
CREATE INDEX idx_users_username ON users USING btree (username);

-- Authors
CREATE TABLE authors (
    author_id serial NOT NULL,
    name varchar(255) NOT NULL,
    bio text,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT authors_pkey PRIMARY KEY (author_id),
    CONSTRAINT authors_name_key UNIQUE (name)
);

CREATE INDEX idx_authors_name ON authors USING btree (name);

-- Genres
CREATE TABLE genres (
    genre_id serial NOT NULL,
    genre_name varchar(100) NOT NULL,
    description text,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT genres_pkey PRIMARY KEY (genre_id),
    CONSTRAINT genres_name_key UNIQUE (genre_name)
);

-- Series
CREATE TABLE series (
    series_id serial NOT NULL,
    title varchar(255) NOT NULL,
    description text,
    total_books int DEFAULT 0,
    status varchar(50) DEFAULT 'unknown',
    created_at timestamp DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT series_pkey PRIMARY KEY (series_id),
    CONSTRAINT series_status_check CHECK (status IN ('ongoing', 'completed', 'cancelled', 'unknown'))
);

-- Books (core catalog)
CREATE TABLE books (
    book_id serial NOT NULL,
    title varchar(255) NOT NULL,
    isbn varchar(255),
    goodreads_url text,
    year int,
    pages int,
    added_at timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT books_pkey PRIMARY KEY (book_id)
);

CREATE INDEX idx_books_title ON books USING btree (title);
CREATE INDEX idx_books_isbn ON books USING btree (isbn);
CREATE INDEX idx_books_year ON books USING btree (year);

-- Goodreads data (enrichment)
CREATE TABLE goodreads_data (
    book_id int NOT NULL,
    goodreads_id varchar(50),
    description text,
    average_rating numeric(3, 2),
    ratings_count int,
    reviews_count int,
    publication_date date,
    publisher varchar(255),
    language varchar(50),
    series varchar(255),
    series_position int,
    original_title varchar(255),
    original_publication_year int,
    cover_url text,
    awards text[],
    genres text[],
    scrape_date timestamp DEFAULT CURRENT_TIMESTAMP,
    last_updated timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT goodreads_data_pkey PRIMARY KEY (book_id),
    CONSTRAINT goodreads_data_book_id_fkey FOREIGN KEY (book_id) 
        REFERENCES books(book_id) ON DELETE CASCADE
);

-- ============================================================================
-- RELATIONSHIP TABLES
-- ============================================================================

-- Book-Author relationship (many-to-many)
CREATE TABLE book_authors (
    book_id int NOT NULL,
    author_id int NOT NULL,
    author_order int DEFAULT 1,
    CONSTRAINT book_authors_pkey PRIMARY KEY (book_id, author_id),
    CONSTRAINT book_authors_author_id_fkey FOREIGN KEY (author_id) 
        REFERENCES authors(author_id) ON DELETE CASCADE,
    CONSTRAINT book_authors_book_id_fkey FOREIGN KEY (book_id) 
        REFERENCES books(book_id) ON DELETE CASCADE
);

CREATE INDEX idx_book_authors_author ON book_authors USING btree (author_id);
CREATE INDEX idx_book_authors_book ON book_authors USING btree (book_id);

-- Book-Genre relationship (many-to-many)
CREATE TABLE book_genres (
    book_id int NOT NULL,
    genre_id int NOT NULL,
    is_primary bool DEFAULT false,
    CONSTRAINT book_genres_pkey PRIMARY KEY (book_id, genre_id),
    CONSTRAINT book_genres_book_id_fkey FOREIGN KEY (book_id) 
        REFERENCES books(book_id) ON DELETE CASCADE,
    CONSTRAINT book_genres_genre_id_fkey FOREIGN KEY (genre_id) 
        REFERENCES genres(genre_id) ON DELETE CASCADE
);

CREATE INDEX idx_book_genres_book ON book_genres USING btree (book_id);
CREATE INDEX idx_book_genres_genre ON book_genres USING btree (genre_id);

-- Series-Book relationship
CREATE TABLE series_books (
    series_id int NOT NULL,
    book_id int NOT NULL,
    position int NOT NULL,
    is_side_story bool DEFAULT false,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT series_books_pkey PRIMARY KEY (series_id, book_id),
    CONSTRAINT series_books_book_id_fkey FOREIGN KEY (book_id) 
        REFERENCES books(book_id) ON DELETE CASCADE,
    CONSTRAINT series_books_series_id_fkey FOREIGN KEY (series_id) 
        REFERENCES series(series_id) ON DELETE CASCADE
);

CREATE INDEX idx_series_books_book ON series_books USING btree (book_id);
CREATE INDEX idx_series_books_series ON series_books USING btree (series_id);
CREATE INDEX idx_series_books_position ON series_books USING btree (position);

-- ============================================================================
-- READING TRACKING TABLES
-- ============================================================================

-- Reading log (main tracking table)
CREATE TABLE reading_log (
    log_id serial NOT NULL,
    book_id int NOT NULL,
    
    -- Status tracking
    status varchar(50) DEFAULT 'want_to_read',
    
    -- Date tracking
    date_added date DEFAULT CURRENT_DATE,
    date_started date,
    date_finished date,
    
    -- Progress tracking
    current_page int DEFAULT 0,
    
    -- Rating & review
    rating int,
    review text,
    notes text,
    
    -- Reading metrics
    reading_days int,
    reread bool DEFAULT false,
    reread_count int DEFAULT 0,
    
    -- Tags for personal categorization
    tags text[],
    
    -- Metadata
    created_at timestamp DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT reading_log_pkey PRIMARY KEY (log_id),
    CONSTRAINT reading_log_rating_check CHECK (rating >= 1 AND rating <= 5),
    CONSTRAINT reading_log_status_check CHECK (status IN (
        'want_to_read', 
        'reading', 
        'finished', 
        'did_not_finish', 
        'on_hold'
    )),
    CONSTRAINT unique_book_log UNIQUE (book_id),
    CONSTRAINT reading_log_book_id_fkey FOREIGN KEY (book_id) 
        REFERENCES books(book_id) ON DELETE CASCADE
);

CREATE INDEX idx_reading_log_status ON reading_log USING btree (status);
CREATE INDEX idx_reading_log_date_finished ON reading_log USING btree (date_finished);
CREATE INDEX idx_reading_log_date_started ON reading_log USING btree (date_started);
CREATE INDEX idx_reading_log_rating ON reading_log USING btree (rating);

-- Reading sessions (detailed activity tracking - optional)
CREATE TABLE reading_sessions (
    session_id serial NOT NULL,
    book_id int NOT NULL,
    session_date date NOT NULL,
    pages_read int,
    minutes_read int,
    start_page int,
    end_page int,
    notes text,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT reading_sessions_pkey PRIMARY KEY (session_id),
    CONSTRAINT reading_sessions_book_id_fkey FOREIGN KEY (book_id) 
        REFERENCES books(book_id) ON DELETE CASCADE
);

CREATE INDEX idx_reading_sessions_book ON reading_sessions USING btree (book_id);
CREATE INDEX idx_reading_sessions_date ON reading_sessions USING btree (session_date);

-- ============================================================================
-- STATISTICS TABLES
-- ============================================================================

-- Overall reading statistics
CREATE TABLE reading_stats (
    stats_id serial NOT NULL,
    
    -- Basic counts
    total_books_read int DEFAULT 0,
    total_books_dnf int DEFAULT 0,
    total_pages_read int DEFAULT 0,
    total_books_reading int DEFAULT 0,
    total_books_want_to_read int DEFAULT 0,
    
    -- Averages
    average_rating numeric(3, 2),
    average_book_length int,
    average_reading_days numeric(5, 1),
    
    -- Streaks & patterns
    current_reading_streak int DEFAULT 0,
    longest_reading_streak int DEFAULT 0,
    last_read_date date,
    
    -- Favorites
    favorite_genre_id int,
    favorite_author_id int,
    
    -- Year tracking
    books_read_this_year int DEFAULT 0,
    books_read_this_month int DEFAULT 0,
    pages_read_this_year int DEFAULT 0,
    pages_read_this_month int DEFAULT 0,
    
    -- Metadata
    created_at timestamp DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT reading_stats_pkey PRIMARY KEY (stats_id),
    CONSTRAINT reading_stats_favorite_genre_fkey FOREIGN KEY (favorite_genre_id) 
        REFERENCES genres(genre_id),
    CONSTRAINT reading_stats_favorite_author_fkey FOREIGN KEY (favorite_author_id) 
        REFERENCES authors(author_id)
);

-- Yearly statistics snapshot
CREATE TABLE yearly_stats (
    year_id serial NOT NULL,
    year int NOT NULL,
    
    books_read int DEFAULT 0,
    pages_read int DEFAULT 0,
    average_rating numeric(3, 2),
    
    top_genre_id int,
    top_author_id int,
    
    longest_book_id int,
    shortest_book_id int,
    highest_rated_book_id int,
    
    created_at timestamp DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT yearly_stats_pkey PRIMARY KEY (year_id),
    CONSTRAINT yearly_stats_year_key UNIQUE (year),
    CONSTRAINT yearly_stats_top_genre_fkey FOREIGN KEY (top_genre_id) 
        REFERENCES genres(genre_id),
    CONSTRAINT yearly_stats_top_author_fkey FOREIGN KEY (top_author_id) 
        REFERENCES authors(author_id)
);

-- Monthly statistics
CREATE TABLE monthly_stats (
    month_id serial NOT NULL,
    year int NOT NULL,
    month int NOT NULL,
    
    books_read int DEFAULT 0,
    pages_read int DEFAULT 0,
    average_rating numeric(3, 2),
    
    created_at timestamp DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT monthly_stats_pkey PRIMARY KEY (month_id),
    CONSTRAINT monthly_stats_year_month_key UNIQUE (year, month),
    CONSTRAINT monthly_stats_month_check CHECK (month >= 1 AND month <= 12)
);

-- Reading goals
CREATE TABLE reading_goals (
    goal_id serial NOT NULL,
    year int NOT NULL,
    
    target_books int,
    target_pages int,
    
    current_books int DEFAULT 0,
    current_pages int DEFAULT 0,
    
    created_at timestamp DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT reading_goals_pkey PRIMARY KEY (goal_id),
    CONSTRAINT unique_year_goal UNIQUE (year)
);

-- ============================================================================
-- VIEWS FOR ANALYTICS
-- ============================================================================

-- View: Books with full details
CREATE VIEW v_books_full AS
SELECT 
    b.book_id,
    b.title,
    b.isbn,
    b.year,
    b.pages,
    b.added_at,
    string_agg(DISTINCT a.name, ', ' ORDER BY a.name) as authors,
    string_agg(DISTINCT g.genre_name, ', ' ORDER BY g.genre_name) as genres,
    s.title as series_name,
    sb.position as series_position,
    gd.goodreads_id,
    gd.average_rating as goodreads_rating,
    gd.ratings_count as goodreads_ratings_count,
    gd.cover_url,
    gd.description,
    gd.publisher,
    rl.status as reading_status,
    rl.rating as my_rating,
    rl.date_started,
    rl.date_finished,
    rl.current_page,
    rl.review
FROM books b
LEFT JOIN book_authors ba ON b.book_id = ba.book_id
LEFT JOIN authors a ON ba.author_id = a.author_id
LEFT JOIN book_genres bg ON b.book_id = bg.book_id
LEFT JOIN genres g ON bg.genre_id = g.genre_id
LEFT JOIN series_books sb ON b.book_id = sb.book_id
LEFT JOIN series s ON sb.series_id = s.series_id
LEFT JOIN goodreads_data gd ON b.book_id = gd.book_id
LEFT JOIN reading_log rl ON b.book_id = rl.book_id
GROUP BY 
    b.book_id, 
    s.title, 
    sb.position, 
    gd.goodreads_id,
    gd.average_rating, 
    gd.ratings_count,
    gd.cover_url,
    gd.description,
    gd.publisher,
    rl.status,
    rl.rating,
    rl.date_started,
    rl.date_finished,
    rl.current_page,
    rl.review;

-- View: Reading progress with calculations
CREATE VIEW v_reading_progress AS
SELECT 
    rl.log_id,
    rl.book_id,
    b.title,
    b.pages,
    rl.status,
    rl.current_page,
    rl.date_added,
    rl.date_started,
    rl.date_finished,
    rl.rating,
    rl.reading_days,
    rl.review,
    CASE 
        WHEN b.pages > 0 AND rl.current_page > 0 
        THEN ROUND((rl.current_page::numeric / b.pages::numeric) * 100, 2)
        ELSE 0
    END as progress_percentage,
    CASE
        WHEN rl.date_started IS NOT NULL AND rl.status = 'reading'
        THEN CURRENT_DATE - rl.date_started
        ELSE NULL
    END as days_reading,
    CASE
        WHEN b.pages > 0 AND rl.current_page > 0 AND rl.date_started IS NOT NULL AND rl.status = 'reading'
        THEN ROUND((b.pages - rl.current_page)::numeric / 
            NULLIF((rl.current_page::numeric / NULLIF(CURRENT_DATE - rl.date_started, 0)), 0), 0)
        ELSE NULL
    END as estimated_days_remaining
FROM reading_log rl
JOIN books b ON rl.book_id = b.book_id;

-- View: Genre statistics
CREATE VIEW v_genre_stats AS
SELECT 
    g.genre_id,
    g.genre_name,
    COUNT(rl.log_id) as total_books,
    COUNT(CASE WHEN rl.status = 'finished' THEN 1 END) as books_finished,
    COUNT(CASE WHEN rl.status = 'did_not_finish' THEN 1 END) as books_dnf,
    COUNT(CASE WHEN rl.status = 'reading' THEN 1 END) as books_reading,
    ROUND(AVG(CASE WHEN rl.rating IS NOT NULL THEN rl.rating END), 2) as average_rating,
    SUM(CASE WHEN rl.status = 'finished' THEN b.pages ELSE 0 END) as total_pages_read,
    ROUND(
        COUNT(CASE WHEN rl.status = 'finished' THEN 1 END)::numeric / 
        NULLIF(COUNT(rl.log_id), 0) * 100, 
        2
    ) as completion_rate
FROM genres g
LEFT JOIN book_genres bg ON g.genre_id = bg.genre_id
LEFT JOIN reading_log rl ON bg.book_id = rl.book_id
LEFT JOIN books b ON rl.book_id = b.book_id
GROUP BY g.genre_id, g.genre_name
HAVING COUNT(rl.log_id) > 0
ORDER BY books_finished DESC;

-- View: Author statistics
CREATE VIEW v_author_stats AS
SELECT 
    a.author_id,
    a.name,
    COUNT(rl.log_id) as total_books,
    COUNT(CASE WHEN rl.status = 'finished' THEN 1 END) as books_finished,
    ROUND(AVG(CASE WHEN rl.rating IS NOT NULL THEN rl.rating END), 2) as average_rating,
    SUM(CASE WHEN rl.status = 'finished' THEN b.pages ELSE 0 END) as total_pages_read,
    MAX(rl.date_finished) as last_book_finished
FROM authors a
LEFT JOIN book_authors ba ON a.author_id = ba.author_id
LEFT JOIN reading_log rl ON ba.book_id = rl.book_id
LEFT JOIN books b ON rl.book_id = b.book_id
GROUP BY a.author_id, a.name
HAVING COUNT(rl.log_id) > 0
ORDER BY books_finished DESC;

-- View: Monthly reading trends
CREATE VIEW v_monthly_trends AS
SELECT 
    EXTRACT(YEAR FROM date_finished)::int as year,
    EXTRACT(MONTH FROM date_finished)::int as month,
    TO_CHAR(date_finished, 'Month') as month_name,
    COUNT(*) as books_finished,
    SUM(b.pages) as pages_read,
    ROUND(AVG(rating), 2) as average_rating,
    ROUND(AVG(reading_days), 1) as average_reading_days,
    MIN(b.pages) as shortest_book,
    MAX(b.pages) as longest_book
FROM reading_log rl
JOIN books b ON rl.book_id = b.book_id
WHERE status = 'finished' AND date_finished IS NOT NULL
GROUP BY 
    EXTRACT(YEAR FROM date_finished), 
    EXTRACT(MONTH FROM date_finished),
    TO_CHAR(date_finished, 'Month')
ORDER BY year DESC, month DESC;

-- View: Reading streak calculation
CREATE VIEW v_reading_streak AS
WITH daily_reads AS (
    SELECT DISTINCT date_finished as read_date
    FROM reading_log
    WHERE status = 'finished' AND date_finished IS NOT NULL
    ORDER BY date_finished DESC
),
streak_groups AS (
    SELECT 
        read_date,
        read_date - (ROW_NUMBER() OVER (ORDER BY read_date))::int * INTERVAL '1 day' as group_date
    FROM daily_reads
),
current_streak AS (
    SELECT COUNT(*) as streak_days
    FROM streak_groups
    WHERE group_date = (
        SELECT group_date 
        FROM streak_groups 
        WHERE read_date = (SELECT MAX(read_date) FROM daily_reads)
    )
),
longest_streak AS (
    SELECT MAX(streak_count) as max_streak
    FROM (
        SELECT group_date, COUNT(*) as streak_count
        FROM streak_groups
        GROUP BY group_date
    ) sub
)
SELECT 
    COALESCE((SELECT streak_days FROM current_streak), 0) as current_streak,
    COALESCE((SELECT max_streak FROM longest_streak), 0) as longest_streak,
    (SELECT MAX(read_date) FROM daily_reads) as last_read_date;

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- Function: Calculate reading days when book is finished
CREATE OR REPLACE FUNCTION update_reading_days()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'finished' AND NEW.date_finished IS NOT NULL AND NEW.date_started IS NOT NULL THEN
        NEW.reading_days = NEW.date_finished - NEW.date_started + 1;
    END IF;
    
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_reading_days
    BEFORE INSERT OR UPDATE ON reading_log
    FOR EACH ROW
    EXECUTE FUNCTION update_reading_days();

-- Function: Update overall reading stats
CREATE OR REPLACE FUNCTION update_reading_stats()
RETURNS TRIGGER AS $$
DECLARE
    v_stats_id int;
BEGIN
    -- Get or create stats record
    SELECT stats_id INTO v_stats_id FROM reading_stats LIMIT 1;
    
    IF v_stats_id IS NULL THEN
        INSERT INTO reading_stats (stats_id) VALUES (1);
        v_stats_id = 1;
    END IF;
    
    -- Update stats
    UPDATE reading_stats SET
        total_books_read = (
            SELECT COUNT(*) FROM reading_log WHERE status = 'finished'
        ),
        total_books_dnf = (
            SELECT COUNT(*) FROM reading_log WHERE status = 'did_not_finish'
        ),
        total_books_reading = (
            SELECT COUNT(*) FROM reading_log WHERE status = 'reading'
        ),
        total_books_want_to_read = (
            SELECT COUNT(*) FROM reading_log WHERE status = 'want_to_read'
        ),
        total_pages_read = (
            SELECT COALESCE(SUM(b.pages), 0)
            FROM reading_log rl
            JOIN books b ON rl.book_id = b.book_id
            WHERE rl.status = 'finished'
        ),
        average_rating = (
            SELECT ROUND(AVG(rating), 2)
            FROM reading_log
            WHERE status = 'finished' AND rating IS NOT NULL
        ),
        average_book_length = (
            SELECT ROUND(AVG(b.pages))
            FROM reading_log rl
            JOIN books b ON rl.book_id = b.book_id
            WHERE rl.status = 'finished'
        ),
        average_reading_days = (
            SELECT ROUND(AVG(reading_days), 1)
            FROM reading_log
            WHERE status = 'finished' AND reading_days IS NOT NULL
        ),
        books_read_this_year = (
            SELECT COUNT(*)
            FROM reading_log
            WHERE status = 'finished' 
            AND EXTRACT(YEAR FROM date_finished) = EXTRACT(YEAR FROM CURRENT_DATE)
        ),
        books_read_this_month = (
            SELECT COUNT(*)
            FROM reading_log
            WHERE status = 'finished' 
            AND EXTRACT(YEAR FROM date_finished) = EXTRACT(YEAR FROM CURRENT_DATE)
            AND EXTRACT(MONTH FROM date_finished) = EXTRACT(MONTH FROM CURRENT_DATE)
        ),
        pages_read_this_year = (
            SELECT COALESCE(SUM(b.pages), 0)
            FROM reading_log rl
            JOIN books b ON rl.book_id = b.book_id
            WHERE rl.status = 'finished' 
            AND EXTRACT(YEAR FROM rl.date_finished) = EXTRACT(YEAR FROM CURRENT_DATE)
        ),
        pages_read_this_month = (
            SELECT COALESCE(SUM(b.pages), 0)
            FROM reading_log rl
            JOIN books b ON rl.book_id = b.book_id
            WHERE rl.status = 'finished' 
            AND EXTRACT(YEAR FROM rl.date_finished) = EXTRACT(YEAR FROM CURRENT_DATE)
            AND EXTRACT(MONTH FROM rl.date_finished) = EXTRACT(MONTH FROM CURRENT_DATE)
        ),
        last_read_date = (
            SELECT MAX(date_finished)
            FROM reading_log
            WHERE status = 'finished'
        ),
        favorite_genre_id = (
            SELECT g.genre_id
            FROM book_genres bg
            JOIN reading_log rl ON bg.book_id = rl.book_id
            JOIN genres g ON bg.genre_id = g.genre_id
            WHERE rl.status = 'finished'
            GROUP BY g.genre_id
            ORDER BY COUNT(*) DESC
            LIMIT 1
        ),
        favorite_author_id = (
            SELECT a.author_id
            FROM book_authors ba
            JOIN reading_log rl ON ba.book_id = rl.book_id
            JOIN authors a ON ba.author_id = a.author_id
            WHERE rl.status = 'finished'
            GROUP BY a.author_id
            ORDER BY COUNT(*) DESC
            LIMIT 1
        ),
        updated_at = CURRENT_TIMESTAMP
    WHERE stats_id = v_stats_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_reading_stats
    AFTER INSERT OR UPDATE OR DELETE ON reading_log
    FOR EACH STATEMENT
    EXECUTE FUNCTION update_reading_stats();

-- Function: Update monthly stats
CREATE OR REPLACE FUNCTION update_monthly_stats()
RETURNS TRIGGER AS $$
DECLARE
    v_year int;
    v_month int;
BEGIN
    IF NEW.status = 'finished' AND NEW.date_finished IS NOT NULL THEN
        v_year = EXTRACT(YEAR FROM NEW.date_finished);
        v_month = EXTRACT(MONTH FROM NEW.date_finished);
        
        INSERT INTO monthly_stats (year, month, books_read, pages_read, average_rating)
        VALUES (v_year, v_month, 0, 0, 0)
        ON CONFLICT (year, month) DO NOTHING;
        
        UPDATE monthly_stats SET
            books_read = (
                SELECT COUNT(*)
                FROM reading_log
                WHERE status = 'finished'
                AND EXTRACT(YEAR FROM date_finished) = v_year
                AND EXTRACT(MONTH FROM date_finished) = v_month
            ),
            pages_read = (
                SELECT COALESCE(SUM(b.pages), 0)
                FROM reading_log rl
                JOIN books b ON rl.book_id = b.book_id
                WHERE rl.status = 'finished'
                AND EXTRACT(YEAR FROM rl.date_finished) = v_year
                AND EXTRACT(MONTH FROM rl.date_finished) = v_month
            ),
            average_rating = (
                SELECT ROUND(AVG(rating), 2)
                FROM reading_log
                WHERE status = 'finished'
                AND rating IS NOT NULL
                AND EXTRACT(YEAR FROM date_finished) = v_year
                AND EXTRACT(MONTH FROM date_finished) = v_month
            ),
            updated_at = CURRENT_TIMESTAMP
        WHERE year = v_year AND month = v_month;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_monthly_stats
    AFTER INSERT OR UPDATE ON reading_log
    FOR EACH ROW
    EXECUTE FUNCTION update_monthly_stats();

-- Function: Update yearly stats
CREATE OR REPLACE FUNCTION update_yearly_stats()
RETURNS TRIGGER AS $$
DECLARE
    v_year int;
BEGIN
    IF NEW.status = 'finished' AND NEW.date_finished IS NOT NULL THEN
        v_year = EXTRACT(YEAR FROM NEW.date_finished);
        
        INSERT INTO yearly_stats (year, books_read, pages_read)
        VALUES (v_year, 0, 0)
        ON CONFLICT (year) DO NOTHING;
        
        UPDATE yearly_stats SET
            books_read = (
                SELECT COUNT(*)
                FROM reading_log
                WHERE status = 'finished'
                AND EXTRACT(YEAR FROM date_finished) = v_year
            ),
            pages_read = (
                SELECT COALESCE(SUM(b.pages), 0)
                FROM reading_log rl
                JOIN books b ON rl.book_id = b.book_id
                WHERE rl.status = 'finished'
                AND EXTRACT(YEAR FROM rl.date_finished) = v_year
            ),
            average_rating = (
                SELECT ROUND(AVG(rating), 2)
                FROM reading_log
                WHERE status = 'finished'
                AND rating IS NOT NULL
                AND EXTRACT(YEAR FROM date_finished) = v_year
            ),
            top_genre_id = (
                SELECT g.genre_id
                FROM book_genres bg
                JOIN reading_log rl ON bg.book_id = rl.book_id
                JOIN genres g ON bg.genre_id = g.genre_id
                WHERE rl.status = 'finished'
                AND EXTRACT(YEAR FROM rl.date_finished) = v_year
                GROUP BY g.genre_id
                ORDER BY COUNT(*) DESC
                LIMIT 1
            ),
            top_author_id = (
                SELECT a.author_id
                FROM book_authors ba
                JOIN reading_log rl ON ba.book_id = rl.book_id
                JOIN authors a ON ba.author_id = a.author_id
                WHERE rl.status = 'finished'
                AND EXTRACT(YEAR FROM rl.date_finished) = v_year
                GROUP BY a.author_id
                ORDER BY COUNT(*) DESC
                LIMIT 1
            ),
            longest_book_id = (
                SELECT b.book_id
                FROM reading_log rl
                JOIN books b ON rl.book_id = b.book_id
                WHERE rl.status = 'finished'
                AND EXTRACT(YEAR FROM rl.date_finished) = v_year
                ORDER BY b.pages DESC
                LIMIT 1
            ),
            shortest_book_id = (
                SELECT b.book_id
                FROM reading_log rl
                JOIN books b ON rl.book_id = b.book_id
                WHERE rl.status = 'finished'
                AND EXTRACT(YEAR FROM rl.date_finished) = v_year
                AND b.pages > 0
                ORDER BY b.pages ASC
                LIMIT 1
            ),
            highest_rated_book_id = (
                SELECT rl.book_id
                FROM reading_log rl
                WHERE rl.status = 'finished'
                AND rl.rating IS NOT NULL
                AND EXTRACT(YEAR FROM rl.date_finished) = v_year
                ORDER BY rl.rating DESC, rl.date_finished DESC
                LIMIT 1
            ),
            updated_at = CURRENT_TIMESTAMP
        WHERE year = v_year;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_yearly_stats
    AFTER INSERT OR UPDATE ON reading_log
    FOR EACH ROW
    EXECUTE FUNCTION update_yearly_stats();

-- Function: Update series total books
CREATE OR REPLACE FUNCTION update_series_total_books()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        UPDATE series SET 
            total_books = (
                SELECT COUNT(*) 
                FROM series_books 
                WHERE series_id = OLD.series_id
            ),
            updated_at = CURRENT_TIMESTAMP
        WHERE series_id = OLD.series_id;
        RETURN OLD;
    ELSE
        UPDATE series SET 
            total_books = (
                SELECT COUNT(*) 
                FROM series_books 
                WHERE series_id = NEW.series_id
            ),
            updated_at = CURRENT_TIMESTAMP
        WHERE series_id = NEW.series_id;
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_series_books_insert
    AFTER INSERT ON series_books
    FOR EACH ROW
    EXECUTE FUNCTION update_series_total_books();

CREATE TRIGGER trigger_update_series_books_delete
    AFTER DELETE ON series_books
    FOR EACH ROW
    EXECUTE FUNCTION update_series_total_books();

-- ============================================================================
-- INITIAL DATA & SETUP
-- ============================================================================

-- Insert initial reading stats record
INSERT INTO reading_stats (stats_id) VALUES (1);

-- Create current year goal
INSERT INTO reading_goals (year, target_books)
VALUES (EXTRACT(YEAR FROM CURRENT_DATE), 52)
ON CONFLICT (year) DO NOTHING;

-- ============================================================================
-- USEFUL QUERIES FOR DASHBOARD
-- ============================================================================

-- Query 1: Overview statistics
COMMENT ON VIEW v_books_full IS 
'SELECT * FROM reading_stats LIMIT 1;';

-- Query 2: Currently reading books
COMMENT ON VIEW v_reading_progress IS 
'SELECT * FROM v_reading_progress WHERE status = ''reading'' ORDER BY date_started;';

-- Query 3: Top rated books
COMMENT ON TABLE books IS 
'SELECT b.title, a.name as author, rl.rating, rl.date_finished
FROM reading_log rl
JOIN books b ON rl.book_id = b.book_id
JOIN book_authors ba ON b.book_id = ba.book_id
JOIN authors a ON ba.author_id = a.author_id
WHERE rl.status = ''finished'' AND rl.rating IS NOT NULL
ORDER BY rl.rating DESC, rl.date_finished DESC
LIMIT 10;';

-- Query 4: Reading by genre
COMMENT ON TABLE genres IS 
'SELECT * FROM v_genre_stats ORDER BY books_finished DESC;';

-- Query 5: Monthly trends
COMMENT ON TABLE monthly_stats IS 
'SELECT * FROM v_monthly_trends LIMIT 12;';

-- Query 6: Reading goal progress
COMMENT ON TABLE reading_goals IS 
'SELECT 
    rg.year,
    rg.target_books,
    rg.current_books,
    ROUND((rg.current_books::numeric / NULLIF(rg.target_books, 0)) * 100, 2) as progress_percentage,
    rg.target_books - rg.current_books as books_remaining
FROM reading_goals rg
WHERE rg.year = EXTRACT(YEAR FROM CURRENT_DATE);';

-- Query 7: Books to read next (recommendations based on favorite genres)
COMMENT ON TABLE book_genres IS 
'SELECT DISTINCT b.*, gd.cover_url
FROM books b
JOIN book_genres bg ON b.book_id = bg.book_id
JOIN goodreads_data gd ON b.book_id = gd.book_id
LEFT JOIN reading_log rl ON b.book_id = rl.book_id
WHERE rl.book_id IS NULL
AND bg.genre_id IN (
    SELECT favorite_genre_id FROM reading_stats LIMIT 1
)
ORDER BY gd.average_rating DESC
LIMIT 10;';

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================