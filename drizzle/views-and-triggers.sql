-- ============================================================================
-- VIEWS AND TRIGGERS FOR BOOKJET
-- ============================================================================
-- Run this file after pushing your Drizzle schema to add views, triggers,
-- and functions that are not supported by Drizzle ORM.
--
-- You can run this in your Neon dashboard SQL editor or using psql:
-- psql $DATABASE_URL -f drizzle/views-and-triggers.sql
-- ============================================================================

-- ============================================================================
-- VIEWS FOR ANALYTICS
-- ============================================================================

-- View: Books with full details
CREATE OR REPLACE VIEW v_books_full AS
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
CREATE OR REPLACE VIEW v_reading_progress AS
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
CREATE OR REPLACE VIEW v_genre_stats AS
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
CREATE OR REPLACE VIEW v_author_stats AS
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
CREATE OR REPLACE VIEW v_monthly_trends AS
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
CREATE OR REPLACE VIEW v_reading_streak AS
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

DROP TRIGGER IF EXISTS trigger_update_reading_days ON reading_log;
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

DROP TRIGGER IF EXISTS trigger_update_reading_stats ON reading_log;
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

DROP TRIGGER IF EXISTS trigger_update_monthly_stats ON reading_log;
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

DROP TRIGGER IF EXISTS trigger_update_yearly_stats ON reading_log;
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

DROP TRIGGER IF EXISTS trigger_update_series_books_insert ON series_books;
CREATE TRIGGER trigger_update_series_books_insert
    AFTER INSERT ON series_books
    FOR EACH ROW
    EXECUTE FUNCTION update_series_total_books();

DROP TRIGGER IF EXISTS trigger_update_series_books_delete ON series_books;
CREATE TRIGGER trigger_update_series_books_delete
    AFTER DELETE ON series_books
    FOR EACH ROW
    EXECUTE FUNCTION update_series_total_books();

-- ============================================================================
-- INITIAL DATA
-- ============================================================================

-- Insert initial reading stats record
INSERT INTO reading_stats (stats_id) VALUES (1)
ON CONFLICT (stats_id) DO NOTHING;

-- Create current year goal
INSERT INTO reading_goals (year, target_books)
VALUES (EXTRACT(YEAR FROM CURRENT_DATE), 52)
ON CONFLICT (year) DO NOTHING;

-- ============================================================================
-- END OF SETUP
-- ============================================================================
