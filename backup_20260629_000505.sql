--
-- PostgreSQL database dump
--

\restrict QVc8a6BkCiFZBqQccLhGeZVsHOD3GeNPFSSEgdTpJYCygAaQ78Lv4EYMcqot0BG

-- Dumped from database version 15.18 (3d3ac1c)
-- Dumped by pg_dump version 16.14 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: update_monthly_stats(); Type: FUNCTION; Schema: public; Owner: default
--

CREATE FUNCTION public.update_monthly_stats() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.update_monthly_stats() OWNER TO "default";

--
-- Name: update_reading_days(); Type: FUNCTION; Schema: public; Owner: default
--

CREATE FUNCTION public.update_reading_days() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.status = 'finished' AND NEW.date_finished IS NOT NULL AND NEW.date_started IS NOT NULL THEN
        NEW.reading_days = NEW.date_finished - NEW.date_started + 1;
    END IF;

    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_reading_days() OWNER TO "default";

--
-- Name: update_reading_stats(); Type: FUNCTION; Schema: public; Owner: default
--

CREATE FUNCTION public.update_reading_stats() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.update_reading_stats() OWNER TO "default";

--
-- Name: update_series_total_books(); Type: FUNCTION; Schema: public; Owner: default
--

CREATE FUNCTION public.update_series_total_books() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.update_series_total_books() OWNER TO "default";

--
-- Name: update_yearly_stats(); Type: FUNCTION; Schema: public; Owner: default
--

CREATE FUNCTION public.update_yearly_stats() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.update_yearly_stats() OWNER TO "default";

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: account; Type: TABLE; Schema: public; Owner: default
--

CREATE TABLE public.account (
    id text NOT NULL,
    account_id text NOT NULL,
    provider_id text NOT NULL,
    user_id text NOT NULL,
    access_token text,
    refresh_token text,
    id_token text,
    access_token_expires_at timestamp without time zone,
    refresh_token_expires_at timestamp without time zone,
    scope text,
    password text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.account OWNER TO "default";

--
-- Name: authors; Type: TABLE; Schema: public; Owner: default
--

CREATE TABLE public.authors (
    author_id integer NOT NULL,
    name character varying(255) NOT NULL,
    bio text,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.authors OWNER TO "default";

--
-- Name: authors_author_id_seq; Type: SEQUENCE; Schema: public; Owner: default
--

CREATE SEQUENCE public.authors_author_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.authors_author_id_seq OWNER TO "default";

--
-- Name: authors_author_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: default
--

ALTER SEQUENCE public.authors_author_id_seq OWNED BY public.authors.author_id;


--
-- Name: book_authors; Type: TABLE; Schema: public; Owner: default
--

CREATE TABLE public.book_authors (
    book_id integer NOT NULL,
    author_id integer NOT NULL,
    author_order integer DEFAULT 1
);


ALTER TABLE public.book_authors OWNER TO "default";

--
-- Name: book_genres; Type: TABLE; Schema: public; Owner: default
--

CREATE TABLE public.book_genres (
    book_id integer NOT NULL,
    genre_id integer NOT NULL,
    is_primary boolean DEFAULT false
);


ALTER TABLE public.book_genres OWNER TO "default";

--
-- Name: book_quotes; Type: TABLE; Schema: public; Owner: default
--

CREATE TABLE public.book_quotes (
    quote_id integer NOT NULL,
    book_id integer NOT NULL,
    quote_text text NOT NULL,
    page_number integer,
    chapter character varying(255),
    tags text[],
    is_favorite boolean DEFAULT false,
    notes text,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.book_quotes OWNER TO "default";

--
-- Name: book_quotes_quote_id_seq; Type: SEQUENCE; Schema: public; Owner: default
--

CREATE SEQUENCE public.book_quotes_quote_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.book_quotes_quote_id_seq OWNER TO "default";

--
-- Name: book_quotes_quote_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: default
--

ALTER SEQUENCE public.book_quotes_quote_id_seq OWNED BY public.book_quotes.quote_id;


--
-- Name: books; Type: TABLE; Schema: public; Owner: default
--

CREATE TABLE public.books (
    book_id integer NOT NULL,
    title character varying(255) NOT NULL,
    isbn character varying(255),
    goodreads_url text,
    year integer,
    pages integer,
    added_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.books OWNER TO "default";

--
-- Name: books_book_id_seq; Type: SEQUENCE; Schema: public; Owner: default
--

CREATE SEQUENCE public.books_book_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.books_book_id_seq OWNER TO "default";

--
-- Name: books_book_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: default
--

ALTER SEQUENCE public.books_book_id_seq OWNED BY public.books.book_id;


--
-- Name: genres; Type: TABLE; Schema: public; Owner: default
--

CREATE TABLE public.genres (
    genre_id integer NOT NULL,
    genre_name character varying(100) NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.genres OWNER TO "default";

--
-- Name: genres_genre_id_seq; Type: SEQUENCE; Schema: public; Owner: default
--

CREATE SEQUENCE public.genres_genre_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.genres_genre_id_seq OWNER TO "default";

--
-- Name: genres_genre_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: default
--

ALTER SEQUENCE public.genres_genre_id_seq OWNED BY public.genres.genre_id;


--
-- Name: goodreads_data; Type: TABLE; Schema: public; Owner: default
--

CREATE TABLE public.goodreads_data (
    book_id integer NOT NULL,
    goodreads_id character varying(50),
    description text,
    average_rating numeric(3,2),
    ratings_count integer,
    reviews_count integer,
    publication_date date,
    publisher character varying(255),
    language character varying(50),
    series character varying(255),
    series_position integer,
    original_title character varying(255),
    original_publication_year integer,
    cover_url text,
    awards text[],
    genres text[],
    scrape_date timestamp without time zone DEFAULT now(),
    last_updated timestamp without time zone DEFAULT now()
);


ALTER TABLE public.goodreads_data OWNER TO "default";

--
-- Name: monthly_stats; Type: TABLE; Schema: public; Owner: default
--

CREATE TABLE public.monthly_stats (
    month_id integer NOT NULL,
    year integer NOT NULL,
    month integer NOT NULL,
    books_read integer DEFAULT 0,
    pages_read integer DEFAULT 0,
    average_rating numeric(3,2),
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT monthly_stats_month_check CHECK (((month >= 1) AND (month <= 12)))
);


ALTER TABLE public.monthly_stats OWNER TO "default";

--
-- Name: monthly_stats_month_id_seq; Type: SEQUENCE; Schema: public; Owner: default
--

CREATE SEQUENCE public.monthly_stats_month_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.monthly_stats_month_id_seq OWNER TO "default";

--
-- Name: monthly_stats_month_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: default
--

ALTER SEQUENCE public.monthly_stats_month_id_seq OWNED BY public.monthly_stats.month_id;


--
-- Name: reading_goals; Type: TABLE; Schema: public; Owner: default
--

CREATE TABLE public.reading_goals (
    goal_id integer NOT NULL,
    year integer NOT NULL,
    target_books integer,
    target_pages integer,
    current_books integer DEFAULT 0,
    current_pages integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.reading_goals OWNER TO "default";

--
-- Name: reading_goals_goal_id_seq; Type: SEQUENCE; Schema: public; Owner: default
--

CREATE SEQUENCE public.reading_goals_goal_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reading_goals_goal_id_seq OWNER TO "default";

--
-- Name: reading_goals_goal_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: default
--

ALTER SEQUENCE public.reading_goals_goal_id_seq OWNED BY public.reading_goals.goal_id;


--
-- Name: reading_log; Type: TABLE; Schema: public; Owner: default
--

CREATE TABLE public.reading_log (
    log_id integer NOT NULL,
    book_id integer NOT NULL,
    status character varying(50) DEFAULT 'want_to_read'::character varying,
    date_added date DEFAULT now(),
    date_started date,
    date_finished date,
    current_page integer DEFAULT 0,
    rating integer,
    review text,
    notes text,
    reading_days integer,
    reread boolean DEFAULT false,
    reread_count integer DEFAULT 0,
    tags text[],
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT reading_log_rating_check CHECK (((rating >= 1) AND (rating <= 5))),
    CONSTRAINT reading_log_status_check CHECK (((status)::text = ANY ((ARRAY['want_to_read'::character varying, 'reading'::character varying, 'finished'::character varying, 'did_not_finish'::character varying, 'on_hold'::character varying])::text[])))
);


ALTER TABLE public.reading_log OWNER TO "default";

--
-- Name: reading_log_log_id_seq; Type: SEQUENCE; Schema: public; Owner: default
--

CREATE SEQUENCE public.reading_log_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reading_log_log_id_seq OWNER TO "default";

--
-- Name: reading_log_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: default
--

ALTER SEQUENCE public.reading_log_log_id_seq OWNED BY public.reading_log.log_id;


--
-- Name: reading_sessions; Type: TABLE; Schema: public; Owner: default
--

CREATE TABLE public.reading_sessions (
    session_id integer NOT NULL,
    book_id integer NOT NULL,
    session_date date NOT NULL,
    pages_read integer,
    minutes_read integer,
    start_page integer,
    end_page integer,
    notes text,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.reading_sessions OWNER TO "default";

--
-- Name: reading_sessions_session_id_seq; Type: SEQUENCE; Schema: public; Owner: default
--

CREATE SEQUENCE public.reading_sessions_session_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reading_sessions_session_id_seq OWNER TO "default";

--
-- Name: reading_sessions_session_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: default
--

ALTER SEQUENCE public.reading_sessions_session_id_seq OWNED BY public.reading_sessions.session_id;


--
-- Name: reading_stats; Type: TABLE; Schema: public; Owner: default
--

CREATE TABLE public.reading_stats (
    stats_id integer NOT NULL,
    total_books_read integer DEFAULT 0,
    total_books_dnf integer DEFAULT 0,
    total_pages_read integer DEFAULT 0,
    total_books_reading integer DEFAULT 0,
    total_books_want_to_read integer DEFAULT 0,
    average_rating numeric(3,2),
    average_book_length integer,
    average_reading_days numeric(5,1),
    current_reading_streak integer DEFAULT 0,
    longest_reading_streak integer DEFAULT 0,
    last_read_date date,
    favorite_genre_id integer,
    favorite_author_id integer,
    books_read_this_year integer DEFAULT 0,
    books_read_this_month integer DEFAULT 0,
    pages_read_this_year integer DEFAULT 0,
    pages_read_this_month integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.reading_stats OWNER TO "default";

--
-- Name: reading_stats_stats_id_seq; Type: SEQUENCE; Schema: public; Owner: default
--

CREATE SEQUENCE public.reading_stats_stats_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reading_stats_stats_id_seq OWNER TO "default";

--
-- Name: reading_stats_stats_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: default
--

ALTER SEQUENCE public.reading_stats_stats_id_seq OWNED BY public.reading_stats.stats_id;


--
-- Name: series; Type: TABLE; Schema: public; Owner: default
--

CREATE TABLE public.series (
    series_id integer NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    total_books integer DEFAULT 0,
    status character varying(50) DEFAULT 'unknown'::character varying,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT series_status_check CHECK (((status)::text = ANY ((ARRAY['ongoing'::character varying, 'completed'::character varying, 'cancelled'::character varying, 'unknown'::character varying])::text[])))
);


ALTER TABLE public.series OWNER TO "default";

--
-- Name: series_books; Type: TABLE; Schema: public; Owner: default
--

CREATE TABLE public.series_books (
    series_id integer NOT NULL,
    book_id integer NOT NULL,
    "position" integer NOT NULL,
    is_side_story boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.series_books OWNER TO "default";

--
-- Name: series_series_id_seq; Type: SEQUENCE; Schema: public; Owner: default
--

CREATE SEQUENCE public.series_series_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.series_series_id_seq OWNER TO "default";

--
-- Name: series_series_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: default
--

ALTER SEQUENCE public.series_series_id_seq OWNED BY public.series.series_id;


--
-- Name: session; Type: TABLE; Schema: public; Owner: default
--

CREATE TABLE public.session (
    id text NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    token text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ip_address text,
    user_agent text,
    user_id text NOT NULL
);


ALTER TABLE public.session OWNER TO "default";

--
-- Name: users; Type: TABLE; Schema: public; Owner: default
--

CREATE TABLE public.users (
    id text NOT NULL,
    name character varying(100) NOT NULL,
    email character varying(255) NOT NULL,
    email_verified boolean DEFAULT false NOT NULL,
    image text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.users OWNER TO "default";

--
-- Name: verification; Type: TABLE; Schema: public; Owner: default
--

CREATE TABLE public.verification (
    id text NOT NULL,
    identifier text NOT NULL,
    value text NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.verification OWNER TO "default";

--
-- Name: yearly_stats; Type: TABLE; Schema: public; Owner: default
--

CREATE TABLE public.yearly_stats (
    year_id integer NOT NULL,
    year integer NOT NULL,
    books_read integer DEFAULT 0,
    pages_read integer DEFAULT 0,
    average_rating numeric(3,2),
    top_genre_id integer,
    top_author_id integer,
    longest_book_id integer,
    shortest_book_id integer,
    highest_rated_book_id integer,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.yearly_stats OWNER TO "default";

--
-- Name: yearly_stats_year_id_seq; Type: SEQUENCE; Schema: public; Owner: default
--

CREATE SEQUENCE public.yearly_stats_year_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.yearly_stats_year_id_seq OWNER TO "default";

--
-- Name: yearly_stats_year_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: default
--

ALTER SEQUENCE public.yearly_stats_year_id_seq OWNED BY public.yearly_stats.year_id;


--
-- Name: authors author_id; Type: DEFAULT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.authors ALTER COLUMN author_id SET DEFAULT nextval('public.authors_author_id_seq'::regclass);


--
-- Name: book_quotes quote_id; Type: DEFAULT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.book_quotes ALTER COLUMN quote_id SET DEFAULT nextval('public.book_quotes_quote_id_seq'::regclass);


--
-- Name: books book_id; Type: DEFAULT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.books ALTER COLUMN book_id SET DEFAULT nextval('public.books_book_id_seq'::regclass);


--
-- Name: genres genre_id; Type: DEFAULT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.genres ALTER COLUMN genre_id SET DEFAULT nextval('public.genres_genre_id_seq'::regclass);


--
-- Name: monthly_stats month_id; Type: DEFAULT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.monthly_stats ALTER COLUMN month_id SET DEFAULT nextval('public.monthly_stats_month_id_seq'::regclass);


--
-- Name: reading_goals goal_id; Type: DEFAULT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.reading_goals ALTER COLUMN goal_id SET DEFAULT nextval('public.reading_goals_goal_id_seq'::regclass);


--
-- Name: reading_log log_id; Type: DEFAULT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.reading_log ALTER COLUMN log_id SET DEFAULT nextval('public.reading_log_log_id_seq'::regclass);


--
-- Name: reading_sessions session_id; Type: DEFAULT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.reading_sessions ALTER COLUMN session_id SET DEFAULT nextval('public.reading_sessions_session_id_seq'::regclass);


--
-- Name: reading_stats stats_id; Type: DEFAULT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.reading_stats ALTER COLUMN stats_id SET DEFAULT nextval('public.reading_stats_stats_id_seq'::regclass);


--
-- Name: series series_id; Type: DEFAULT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.series ALTER COLUMN series_id SET DEFAULT nextval('public.series_series_id_seq'::regclass);


--
-- Name: yearly_stats year_id; Type: DEFAULT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.yearly_stats ALTER COLUMN year_id SET DEFAULT nextval('public.yearly_stats_year_id_seq'::regclass);


--
-- Data for Name: account; Type: TABLE DATA; Schema: public; Owner: default
--

COPY public.account (id, account_id, provider_id, user_id, access_token, refresh_token, id_token, access_token_expires_at, refresh_token_expires_at, scope, password, created_at, updated_at) FROM stdin;
a3x5ZX2nyzFRwtUJzaNqmOY1nN3gvThr	x7AQqtCDmNVKBeH3KgWXOluUdZyQKYUI	credential	x7AQqtCDmNVKBeH3KgWXOluUdZyQKYUI	\N	\N	\N	\N	\N	\N	80472a66dd8d23365d8588b8d57177a3:2b255e12f845c9f1231b5440fcddfb4b8ea924a836d921fc700897b7dbc075d7c602335c061fbdea59aa8f3c5cee7beae6f6c4eebd361a2d8be1764256b364d8	2025-12-27 07:26:55.135	2025-12-27 07:26:55.135
4EjsuWDenLh4si1urAn2K2BdzMEbLtwK	QPxsNolOyPUfFobN4evEzjZGD45lYM8p	credential	QPxsNolOyPUfFobN4evEzjZGD45lYM8p	\N	\N	\N	\N	\N	\N	53f1ae2e9b6bd7b220e78d9a2fca257c:80c8bbb12bc889312bfe1c16ba90b893bfa73df677ca8fd7ac2e6aa67e0e411da8dc5238ebea9b6c1307703a6fa1037fb35fd5c1ec55c1499c164a097c5e1b7e	2025-12-28 05:52:55.072	2025-12-28 05:52:55.072
\.


--
-- Data for Name: authors; Type: TABLE DATA; Schema: public; Owner: default
--

COPY public.authors (author_id, name, bio, created_at) FROM stdin;
1	Herman Melville	\N	2025-12-27 06:57:37.348381
2	Sir Arthur Conan Doyle	\N	2025-12-27 06:57:37.631982
3	Roald Dahl	\N	2025-12-27 06:57:37.881918
4	Will Durant	\N	2025-12-27 06:57:38.130371
7	Ary Andra	\N	2025-12-27 06:57:38.385022
8	Larry Gonick	\N	2025-12-27 06:57:38.634418
9	W.H.D Rouse	\N	2025-12-27 06:57:38.890542
10	George Orwell	\N	2025-12-27 06:57:39.141495
11	Kahlil Gibran	\N	2025-12-27 06:57:39.390608
12	Albert Camus	\N	2025-12-27 06:57:39.639277
13	Syaikh Nizami	\N	2025-12-27 06:57:39.901832
14	Tere Liye	\N	2025-12-27 06:57:40.149981
15	Tere-Liye	\N	2025-12-27 06:57:40.401244
16	Emha Ainun Nadjib	\N	2025-12-27 06:57:40.650045
17	Sujiwo Tejo	\N	2025-12-27 06:57:40.898684
18	Triskaidekaman	\N	2025-12-27 06:57:41.146871
19	Ibnu Sina	\N	2025-12-27 06:57:41.396478
20	Kompas (Kumpulan Pengarang)	\N	2025-12-27 06:57:41.645409
21	Ahmad Ridlo Su	\N	2025-12-27 06:57:41.893781
22	Chindi Andriyani	\N	2025-12-27 06:57:42.143197
23	Haidar Bagir	\N	2025-12-27 06:57:42.40493
24	Michael Pollan	\N	2025-12-27 06:57:42.653954
25	Bram Stoker	\N	2025-12-27 06:57:42.901543
26	Setyo Wardoyo	\N	2025-12-27 06:57:43.150078
27	Eka Kurniawan	\N	2025-12-27 06:57:43.402765
28	Yuniar Sapardi	\N	2025-12-27 06:57:43.651141
29	Komang Budi Aryasa	\N	2025-12-27 06:57:43.899485
30	Fahruddin Faiz	\N	2025-12-27 06:57:44.148001
31	Dr. Th. Stevens	\N	2025-12-27 06:57:44.410575
32	Soe Hok Gie	\N	2025-12-27 06:57:44.675138
33	Catherine Hughes	\N	2025-12-27 06:57:44.924071
34	Th Stevens	\N	2025-12-27 06:57:45.172644
35	Noam Chomsky	\N	2025-12-27 06:57:45.42175
36	Wahyu Saronto	\N	2025-12-27 06:57:45.669822
37	Ismail Fajrie Alatas	\N	2025-12-27 06:57:45.917893
40	Kanjeng Pangeran HaryaTjakraningrat	\N	2025-12-27 06:57:46.175282
41	Ridwan Sanjaya	\N	2025-12-27 06:57:46.444649
42	Elif Shafak	\N	2025-12-27 06:57:46.69287
43	Kang Cahya	\N	2025-12-27 06:57:46.941632
44	Awan Pribadi Basuki	\N	2025-12-27 06:57:47.189557
45	Darrell Huff	\N	2025-12-27 06:57:47.439844
46	Jeremy Stangroom	\N	2025-12-27 06:57:47.689275
47	Rivan Kurniawan	\N	2025-12-27 06:57:47.937303
48	Luis M Rocha	\N	2025-12-27 06:57:48.185589
49	Khopkah	\N	2025-12-27 06:57:48.492367
50	Ready Susanto	\N	2025-12-27 06:57:48.745667
51	Saludin Muis	\N	2025-12-27 06:57:49.026451
52	Soedjipto Abimanyu	\N	2025-12-27 06:57:49.312339
53	Yon Machmudi	\N	2025-12-27 06:57:49.618707
54	Luis Miguel Rocha	\N	2025-12-27 06:57:49.868594
55	William Win Yang	\N	2025-12-27 06:57:50.119517
56	Annie Sailendra	\N	2025-12-27 06:57:50.370051
57	Lauma Kiwe	\N	2025-12-27 06:57:50.64292
58	Asti Musman	\N	2025-12-27 06:57:50.896836
59	Kirana Rahardha	\N	2025-12-27 06:57:51.148404
60	Erica Reischer	\N	2025-12-27 06:57:51.479624
61	Rusydie Anwar	\N	2025-12-27 06:57:51.771354
62	Jeong Seon Yong	\N	2025-12-27 06:57:52.075963
63	Abdul Syukur al-Azizi	\N	2025-12-27 06:57:52.360034
64	Ibn Rusyd	\N	2025-12-27 06:57:52.607585
65	Bendung Layungkuning	\N	2025-12-27 06:57:52.85578
66	Purwadi	\N	2025-12-27 06:57:53.104192
67	Wawan Susetya	\N	2025-12-27 06:57:53.35277
68	Ronggowarsito	\N	2025-12-27 06:57:53.600845
69	Budiono Herusatoto	\N	2025-12-27 06:57:53.848787
70	Jalaluddin Rumi	\N	2025-12-27 06:57:54.104332
71	Setyo Hajar Dewantoro	\N	2025-12-27 06:57:54.432509
72	Adityo Jatmiko	\N	2025-12-27 06:57:54.682601
73	Imam Al-Ghazali	\N	2025-12-27 06:57:54.931339
74	Jean-Phillipe Thivet	\N	2025-12-27 06:57:55.17872
75	Shafiyyurahman Al-Mubarakfuri	\N	2025-12-27 06:57:55.426225
76	Nyoman S.Pendit	\N	2025-12-27 06:57:55.673933
77	Damar Shashangka	\N	2025-12-27 06:57:55.929217
78	Mulla Sadra	\N	2025-12-27 06:57:56.185835
79	W. L. Olthof	\N	2025-12-27 06:57:56.433867
80	C. Rajagopalachari	\N	2025-12-27 06:57:56.691025
81	Nyoman S. Pendit	\N	2025-12-27 06:57:56.944025
82	Jami	\N	2025-12-27 06:57:57.201501
83	Miguel De Cervantes	\N	2025-12-27 06:57:57.499554
84	Iksaka Banu	\N	2025-12-27 06:57:57.847867
85	Hartwell James	\N	2025-12-27 06:57:58.116854
86	Pramoedya Ananta Toer	\N	2025-12-27 06:57:58.383731
87	Andrea hirata	\N	2025-12-27 06:57:58.644782
88	Jostein Gaarder	\N	2025-12-27 06:57:58.953045
89	Eric Weiner	\N	2025-12-27 06:57:59.227623
90	Tommy Suprapto	\N	2025-12-27 06:57:59.50057
91	Jules Archer	\N	2025-12-27 06:57:59.795297
92	Budi Hardiman	\N	2025-12-27 06:58:00.055821
93	Niccolo Machiavelli	\N	2025-12-27 06:58:00.304248
94	Immanuel Kant	\N	2025-12-27 06:58:00.766845
95	Theodor Valentiner	\N	2025-12-27 06:58:01.116219
96	Carl Jung	\N	2025-12-27 06:58:01.386558
97	James S. Stramel	\N	2025-12-27 06:58:01.673578
98	Jean Paul Sartre	\N	2025-12-27 06:58:01.939961
99	Irfan Afifi	\N	2025-12-27 06:58:02.439971
100	Nietzsche	\N	2025-12-27 06:58:02.710833
101	Paulo Freire	\N	2025-12-27 06:58:02.971064
102	Van Der Weij	\N	2025-12-27 06:58:03.231637
103	Edward Bernays	\N	2025-12-27 06:58:03.49221
104	Bertrand Russell	\N	2025-12-27 06:58:04.220027
105	R. Setiawan	\N	2025-12-27 06:58:04.507896
106	Terry Eagleton	\N	2025-12-27 06:58:05.129736
107	Authority and The Individual	\N	2025-12-27 06:58:05.85201
108	Haryo Sasongko	\N	2025-12-27 06:58:06.223425
109	Franz Magnis Suseno	\N	2025-12-27 06:58:06.488069
110	Goenawan Mohamad	\N	2025-12-27 06:58:06.7424
111	Rene Descartes	\N	2025-12-27 06:58:07.016208
112	Soekarno	\N	2025-12-27 06:58:07.274983
113	K. Bertens	\N	2025-12-27 06:58:07.554425
114	Francisco Jose Ayala	\N	2025-12-27 06:58:07.822612
115	James Fulcher	\N	2025-12-27 06:58:08.08253
116	Muchtar Habibi	\N	2025-12-27 06:58:08.350582
117	Wahana Komputer	\N	2025-12-27 06:58:08.635831
118	Maslen Sibarani	\N	2025-12-27 06:58:08.895244
119	Widodo Budiharto	\N	2025-12-27 06:58:09.171861
120	Lutfi Gani	\N	2025-12-27 06:58:09.432108
121	Ahmad Rosid Komarudin	\N	2025-12-27 06:58:09.688652
122	Edy Winarno	\N	2025-12-27 06:58:09.95069
123	Agus Hartanto	\N	2025-12-27 06:58:10.20567
124	Ian Pearson	\N	2025-12-27 06:58:10.453829
125	Budi Raharjo	\N	2025-12-27 06:58:10.711471
126	Dedik Kurniawan	\N	2025-12-27 06:58:11.013716
127	Imam Robandi	\N	2025-12-27 06:58:11.264472
129	Zulfian Azmi	\N	2025-12-27 06:58:11.511795
130	I Putu Agus Eka Pratama	\N	2025-12-27 06:58:11.839864
131	Rifkie Primartha	\N	2025-12-27 06:58:12.088482
132	Suyanto	\N	2025-12-27 06:58:12.356654
133	George Berkowski	\N	2025-12-27 06:58:12.604783
134	Fathansyah	\N	2025-12-27 06:58:12.852786
135	Seng Hansun	\N	2025-12-27 06:58:13.100501
136	Thomas Nield	\N	2025-12-27 06:58:13.37594
137	Antonio Gulli	\N	2025-12-27 06:58:13.694714
138	Ernst Mayr	\N	2025-12-27 06:58:13.942346
141	Richard Dawkins	\N	2025-12-27 06:58:14.189558
142	Meera Senthilingam	\N	2025-12-27 06:58:14.502329
143	Jim Alhalili	\N	2025-12-27 06:58:14.809914
144	Paul Davies	\N	2025-12-27 06:58:15.056928
145	Neil de Grasse Tyson	\N	2025-12-27 06:58:15.306097
146	Albert Einstein	\N	2025-12-27 06:58:15.631971
147	Jason Beaird	\N	2025-12-27 06:58:15.89898
148	Gregg Braden	\N	2025-12-27 06:58:16.146452
149	Carl Sagan	\N	2025-12-27 06:58:16.44735
150	Sean Carroll	\N	2025-12-27 06:58:16.695031
151	Jong Jek Siang	\N	2025-12-27 06:58:16.960173
152	Yusman Wiyatmo	\N	2025-12-27 06:58:17.208393
153	Charles Darwin	\N	2025-12-27 06:58:17.458695
154	Yangsun Cho	\N	2025-12-27 06:58:17.70672
155	Wono Setya Budhi	\N	2025-12-27 06:58:17.954645
156	Yuval Noah Harari	\N	2025-12-27 06:58:18.20243
157	Agus Sudibyo	\N	2025-12-27 06:58:18.450251
158	Willy Abdillah	\N	2025-12-27 06:58:18.697937
159	Ristia Ariza	\N	2025-12-27 06:58:18.94599
160	NObuhiro Watsuki	\N	2025-12-27 06:58:19.196705
161	William Shakespeare	\N	2025-12-27 06:58:19.444872
162	One	\N	2025-12-27 06:58:19.692413
163	Miyamoto Musashi	\N	2025-12-27 06:58:19.940115
164	Stephen Hawking	\N	2025-12-27 06:58:20.188431
165	Alfred Russel Wallace	\N	2025-12-27 06:58:20.441085
166	Jules Verne	\N	2025-12-27 06:58:20.748659
167	Brian Clegg	\N	2025-12-27 06:58:21.02189
168	Tan Malaka	\N	2025-12-27 06:58:21.362817
169	Max Weber	\N	2025-12-27 06:58:21.670283
170	Anand Neelakantan	\N	2025-12-27 06:58:21.919161
171	Damaika	\N	2025-12-27 06:58:22.166985
172	Mpu Prapanca	\N	2025-12-27 06:58:22.414886
173	Akhyar Yusuf Lubis	\N	2025-12-27 06:58:22.662893
174	Zalprulkhan	\N	2025-12-27 06:58:22.910764
175	Bernard H. M. Vlekke	\N	2025-12-27 06:58:23.158616
176	Miriam Budiardjo	\N	2025-12-27 06:58:23.406254
177	Martin Heidegger	\N	2025-12-27 06:58:23.65428
178	Al-Ghazali	\N	2025-12-27 06:58:23.908291
179	Mohammad Hatta	\N	2025-12-27 06:58:24.15634
180	Osamu Tezuka	\N	2025-12-27 06:58:24.404547
182	Andrea Acri	\N	2025-12-27 06:58:24.65185
183	G.W.F. hegel	\N	2025-12-27 06:58:24.899345
184	Abdul Qadir Al-Jailani	\N	2025-12-27 06:58:25.147116
185	Aristoteles	\N	2025-12-27 06:58:25.395488
186	C.S. Lewis	\N	2025-12-27 06:58:25.643116
187	Naoki Urasawa	\N	2025-12-27 06:58:25.890612
188	Li Xushuang	\N	2025-12-27 06:58:26.138775
189	Chen Mengmin	\N	2025-12-27 06:58:26.386574
190	Junji Ito	\N	2025-12-27 06:58:26.636024
191	Plutarch	\N	2025-12-27 06:58:26.884375
192	Agus Wahyudi	\N	2025-12-27 06:58:27.131964
193	Paulo  Coelho	\N	2025-12-27 06:58:27.390469
194	Franz Kafka	\N	2025-12-27 06:58:27.638598
195	Masashi Kishimoto	\N	2025-12-27 06:58:27.887974
196	Eichiro Oda	\N	2025-12-27 06:58:28.136018
197	Mas Marco Kartodikromo	\N	2025-12-27 06:58:28.384775
198	Rick Riordan	\N	2025-12-27 06:58:28.635531
199	Voltaire	\N	2025-12-27 06:58:28.882706
200	Yuto Suzuki	\N	2025-12-27 06:58:29.131736
201	Herman Hesse	\N	2025-12-27 06:58:29.379285
202	Frank Herbert	\N	2025-12-27 06:58:29.627102
203	Antoine De Sain-Exupery	\N	2025-12-27 06:58:29.87516
204	Antoine De Saint Exupery	\N	2025-12-27 06:58:30.123023
205	Tsuguma Ohba	\N	2025-12-27 06:58:30.371483
206	Ernest Hemingway	\N	2025-12-27 06:58:30.68374
207	Lao Tzu	\N	2025-12-27 06:58:30.932321
208	Nasruddin Hodja	\N	2025-12-27 06:58:31.180021
209	Fyodor Dostoevsky	\N	2025-12-27 06:58:31.501244
210	Edith Hamilton	\N	2025-12-27 06:58:31.807776
211	Robert Greene	\N	2025-12-27 06:58:32.05585
212	Mochtar Lubis	\N	2025-12-27 06:58:32.303449
213	Brian Khrisna	\N	2025-12-27 06:58:32.55085
214	Penerbit Kakatua	\N	2025-12-27 06:58:32.798205
215	Leila S. Chudori	\N	2025-12-27 06:58:33.046644
216	Masaaki Nakayama	\N	2025-12-27 06:58:33.294817
217	Ziggy Zezsyazeoviennazabrizkie	\N	2025-12-27 06:58:33.542534
218	David Deutsch	\N	2025-12-27 06:58:33.862337
219	Leo Tolstoy	\N	2025-12-27 06:58:34.110235
220	Inoue Takehiko	\N	2025-12-27 06:58:34.369738
221	Soren Kierkegaard	\N	2025-12-27 06:58:34.675813
222	Intan Paramaditha	\N	2025-12-27 06:58:34.923917
223	Budi Darma	\N	2025-12-27 06:58:35.171168
224	Maman Suherman	\N	2025-12-27 06:58:35.418953
225	Andre Gide	\N	2025-12-27 06:58:35.666908
226	Ahmad Tohari	\N	2025-12-27 06:58:35.914795
227	Stanislaw Lem	\N	2025-12-27 06:58:36.164767
228	Nawal el-Saadawi	\N	2025-12-27 06:58:36.412753
229	Semaoen	\N	2025-12-27 06:58:36.661577
230	W. R. Supraatman	\N	2025-12-27 06:58:36.909599
231	Ali Sadikin	\N	2025-12-27 06:58:37.157243
233	Marchella FP	\N	2025-12-27 06:58:37.653226
234	Susiloe Bambang Yudhoyono	\N	2025-12-27 06:58:37.900585
235	Che Guevara	\N	2025-12-27 06:58:38.148431
237	Goethe	\N	2025-12-27 06:58:38.644077
238	Ray Bradbury	\N	2025-12-27 06:58:38.976745
239	Dipa Nusantara Aidit	\N	2025-12-27 06:58:39.225064
240	Joseph McCabe	\N	2025-12-27 06:58:39.488941
241	Teddy Wibisana	\N	2025-12-27 06:58:39.747585
242	Saskia Wieringa	\N	2025-12-27 06:58:39.997389
243	J. Kevin Baird	\N	2025-12-27 06:58:40.253382
244	R. F. Kuang	\N	2025-12-27 06:58:40.501758
245	Rutger Bregman	\N	2025-12-27 06:58:40.74934
246	Okky Madasari	\N	2025-12-27 06:58:40.996629
248	Taizan5	\N	2025-12-27 06:58:41.244933
249	H. G. Wells	\N	2025-12-27 06:58:41.49264
250	Koyoharu Gotouge	\N	2025-12-27 06:58:41.740457
251	F. Scott Fitzgerald	\N	2025-12-27 06:58:41.988767
252	A. A. Navis	\N	2025-12-27 06:58:42.237318
253	Dian Purnomo	\N	2025-12-27 06:58:42.485033
254	Joseph Stalin	\N	2025-12-27 06:58:42.73339
255	Seno Gumira Ajidarma	\N	2025-12-27 06:58:42.982378
256	Thomas More	\N	2025-12-27 06:58:43.230806
257	Edgar Allan Poe	\N	2025-12-27 06:58:43.483055
258	Sesuji	\N	2025-12-27 06:58:43.732048
259	Sabahattin Ali	\N	2025-12-27 06:58:43.979611
260	Kugane Maruyama	\N	2025-12-27 06:58:44.228189
261	Buya Hamka	\N	2025-12-27 06:58:44.47616
262	Zaky Yamani	\N	2025-12-27 06:58:44.729922
263	Vincent Bevins	\N	2025-12-27 06:58:44.977923
264	Sui Ishida	\N	2025-12-27 06:58:45.22692
265	NH. Dini	\N	2025-12-27 06:58:45.474751
266	Ong Hok Ham	\N	2025-12-27 06:58:45.727189
267	Martin Suryajaya	\N	2025-12-27 06:58:45.974348
268	Ida Fitri	\N	2025-12-27 06:58:46.221761
269	andre septiawan	\N	2025-12-27 06:58:46.557154
270	Zoulfa Katouh	\N	2025-12-27 06:58:46.805493
271	Dido Michielsen	\N	2025-12-27 06:58:47.053036
272	Claudio Orrego Vicuna	\N	2025-12-28 06:02:57.628721
273	Claudio Orrego Vicuña	\N	2025-12-28 06:12:55.183838
274	Ronny Agustinus	\N	2025-12-28 06:12:55.538686
276	Ahmad Asnawi	\N	2025-12-28 07:39:40.58802
277	Imam Risdiyanto	\N	2025-12-28 07:39:41.603342
278	Rabindranath Tagore	\N	2025-12-28 10:43:16.080514
279	Ryūnosuke Akutagawa	\N	2025-12-28 10:54:43.646189
280	Arishima Takeo	\N	2025-12-28 10:54:45.047347
281	HAYASHI FUMIKO	\N	2025-12-28 10:54:45.388348
282	Yasunari Kawabata	\N	2025-12-28 10:57:59.04259
283	Endah Raharjo	\N	2025-12-28 10:58:00.011958
284	Adam Smith	\N	2025-12-28 14:33:05.948312
285	Nin Bakdi Soemanto	\N	2025-12-28 14:33:06.337849
286	Soe Tjen Marching	\N	2025-12-28 14:34:31.666675
287	Laksmi Pamuntjak	\N	2025-12-28 14:37:43.302776
288	Maxim Gorky	\N	2025-12-28 14:39:52.49758
289	Dwi Susanto	\N	2025-12-28 14:45:12.169041
290	Takeru Hokazono	\N	2026-01-16 04:29:43.586944
291	Anggi Virgianti	\N	2026-01-16 04:30:26.954323
292	Aswini Rosita	\N	2026-01-16 04:32:57.747497
293	Takashi Nagasaki	\N	2026-01-16 07:11:01.278252
294	Gege Akutami	\N	2026-01-26 04:52:50.788026
295	鈴木祐斗	\N	2026-01-26 15:43:51.011739
296	Tatsuki Fujimoto	\N	2026-02-01 10:38:47.449874
297	Hasina Sari	\N	2026-02-01 10:38:47.76223
298	Sapardi Djoko Damono	\N	2026-02-13 08:15:16.704086
299	Mustika Maria	\N	2026-02-15 09:21:50.012359
300	Kuntowijoyo	\N	2026-02-15 11:26:40.363741
301	Bondan Winarno	\N	2026-02-15 11:26:40.694151
302	Franz Magnis-Suseno	\N	2026-02-17 10:04:27.03898
303	Ugoran Prasad	\N	2026-02-17 10:05:16.345672
304	Gabriel García Márquez	\N	2026-02-17 10:08:31.434862
305	Djokolelono	\N	2026-02-17 10:08:31.804128
306	Y.B. Mangunwijaya	\N	2026-02-17 10:10:22.932559
307	M. Ali Imron	\N	2026-02-19 08:59:57.009675
308	Arthur Conan Doyle	\N	2026-02-21 19:13:05.396284
309	Puthut EA	\N	2026-02-22 16:10:58.971893
310	Nurul Hanafi	\N	2026-02-22 16:15:20.108039
311	Friedrich Nietzsche	\N	2026-02-22 16:17:38.537171
312	R.J. Hollingdale	\N	2026-02-22 16:17:38.851163
313	Michael Tanner	\N	2026-02-22 16:17:39.14335
314	ابن كثير	\N	2026-02-24 03:18:26.85556
315	Ibnu Katsir	\N	2026-02-24 03:18:27.194946
316	Stephen Metcalf	\N	2026-02-24 07:38:45.483681
317	Richard Kemen	\N	2026-02-28 11:44:04.557689
318	Satoshi Shiki	\N	2026-02-28 11:54:16.711769
319	Inio Asano	\N	2026-02-28 15:12:15.76101
320	Rizky Maulana	\N	2026-02-28 15:12:16.129379
321	Sutan Takdir Alisjahbana	\N	2026-03-02 04:32:21.19212
322	Tania Murray Li	\N	2026-03-02 13:57:25.501191
323	Pujo Semedi	\N	2026-03-02 13:57:25.848575
324	Achdiat K. Mihardja	\N	2026-03-03 02:50:38.954987
325	Yosuke Takahashi	\N	2026-03-03 03:27:46.441089
326	Kanako Inuki	\N	2026-03-03 03:27:46.824818
327	John Roosa	\N	2026-03-03 08:51:10.845208
328	Hendarto Setiadi	\N	2026-03-03 08:51:11.189866
329	Dian Indrinuswati	\N	2026-03-03 09:17:41.19775
330	Savitri Scherer	\N	2026-03-03 16:29:28.167971
331	Tan Swie Ling	\N	2026-03-04 10:55:55.448495
332	Peter Kasenda	\N	2026-03-04 10:56:38.93464
333	Frisian Yuniardi	\N	2026-03-08 15:13:26.386607
334	Antony Loewenstein	\N	2026-03-08 16:21:12.548286
335	Muhamad Haripin	\N	2026-03-08 16:21:12.898213
336	Alexander Haryanto	\N	2026-03-08 20:39:44.344561
337	Uketsu	\N	2026-03-09 07:22:22.645272
338	Eri Pramestiningtyas	\N	2026-03-09 07:22:22.978192
339	L. Frank Baum	\N	2026-03-10 05:07:54.793473
340	Rosi L. Simamora	\N	2026-03-10 05:07:55.130721
341	Marvin Harris	\N	2026-03-10 14:26:57.719535
342	Ninus D. Andarnuswari	\N	2026-03-10 14:26:58.033
343	Dicky P. Ermandara	\N	2026-03-10 14:26:58.333754
344	Hajime Isayama	\N	2026-03-11 03:00:12.548285
345	Danarto	\N	2026-03-11 16:07:16.691926
346	Chanhyuk Lee	\N	2026-03-19 19:23:50.48665
347	Iingliana	\N	2026-03-19 19:23:50.840965
348	Tim Buku TEMPO	\N	2026-03-19 19:24:26.39437
349	Ayu Utami	\N	2026-03-19 19:26:43.22723
350	R.F. Kuang	\N	2026-03-19 19:27:14.480665
351	Poppy D. Chusfani	\N	2026-03-19 19:27:14.795774
352	Mike Pearl	\N	2026-03-19 19:28:15.032959
353	Gou Tanabe	\N	2026-03-19 19:31:38.830293
354	Zack Davisson	\N	2026-03-19 19:31:39.18309
355	H.P. Lovecraft	\N	2026-03-19 19:31:39.488307
356	Abd al-Rahman al-Kawakibi	\N	2026-03-19 19:35:13.939697
357	عبد الرحمن الكواكبي	\N	2026-03-19 19:35:14.281274
358	Osamu Nishi	\N	2026-03-23 05:07:56.675402
359	Cicilia Oday	\N	2026-03-23 12:24:05.882974
360	Keigo Higashino	\N	2026-03-25 15:42:39.009342
361	Faira Ammadea	\N	2026-03-25 15:42:39.344226
362	Shiro Usazaki	\N	2026-03-25 15:44:33.101589
363	Yoshiyuki Sadamoto	\N	2026-04-01 08:50:18.442844
364	Ayu Arsandhi Patty	\N	2026-04-01 08:50:18.821607
365	Reni Indardini	\N	2026-04-03 03:07:44.980369
366	Nadia Habibie	\N	2026-04-03 06:11:34.9585
367	Aufar Satria	\N	2026-04-03 06:11:35.290456
368	Djenar Maesa Ayu	\N	2026-04-04 11:04:58.70695
369	Oka Rusmini	\N	2026-04-04 20:29:11.511805
370	Osamu Dazai	\N	2026-04-05 19:36:02.184996
371	Herald van der Linde	\N	2026-04-07 10:36:41.586683
372	Arif Bagus Prasetyo	\N	2026-04-07 10:36:41.934203
373	Adolfo Bioy Casares	\N	2026-04-08 03:58:19.749401
374	Lamtarida Simbolon	\N	2026-04-08 03:58:20.114963
375	Mieko Kawakami	\N	2026-04-11 09:00:31.52979
376	Ribeka Ota	\N	2026-04-11 09:00:31.968007
377	新井久幸	\N	2026-04-11 10:26:19.421142
378	Hisayuki Arai	\N	2026-04-11 10:26:19.80846
380	Haruki Murakami	\N	2026-04-13 19:10:33.739191
381	Remy Sylado	\N	2026-04-15 04:28:03.528894
382	Khara	\N	2026-04-15 05:27:12.637325
383	Jane Austen	\N	2026-04-20 04:48:14.190494
384	Rini Nurul Badariah	\N	2026-04-20 04:48:14.542115
385	Natalie Jenner	\N	2026-04-20 04:48:14.910819
386	Charles Dickens	\N	2026-04-20 08:31:24.372849
387	Dion Yulianto	\N	2026-04-20 08:31:24.743818
388	Alberto Manguel	\N	2026-05-03 12:15:44.034387
389	Dwi Pranoto	\N	2026-05-03 12:15:44.409731
390	Sōji Shimada	\N	2026-05-04 04:54:06.203704
391	Barokah Ruziati	\N	2026-05-04 04:54:06.54811
392	Staven Andersen	\N	2026-05-04 04:54:06.864662
393	Iroy Mahyuni	\N	2026-05-05 05:53:44.798402
394	Umar Kayam	\N	2026-05-10 15:33:29.318109
395	Kohei Horikoshi	\N	2026-05-10 15:38:26.333923
396	Kouhei Horikoshi	\N	2026-05-14 06:52:21.038992
397	Caleb D. Cook	\N	2026-05-14 06:52:21.379605
398	Leonid Andreyev	\N	2026-05-18 16:20:53.675647
399	Eva Widyasari	\N	2026-05-18 16:20:54.042664
400	Virginia Woolf	\N	2026-05-29 04:34:33.858796
401	Nadya Andwiani	\N	2026-05-29 04:34:34.220703
402	Carmen Kahn	\N	2026-05-31 09:16:41.197373
403	Jack Armstrong	\N	2026-05-31 09:16:41.853878
404	Fatimah	\N	2026-05-31 15:26:06.401219
405	Ifa Nabila	\N	2026-05-31 15:26:07.568513
406	Emhaf	\N	2026-05-31 15:54:26.887684
407	Alexandre Dumas	\N	2026-05-31 15:54:51.532637
408	Naguib Mahfouz	\N	2026-05-31 15:57:30.776048
409	Muhammad Marzuq	\N	2026-05-31 15:57:31.09402
410	Rh. Widada	\N	2026-05-31 15:57:31.467403
411	Boris Pasternak	\N	2026-05-31 15:59:10.033155
412	John Bayley	\N	2026-05-31 15:59:10.345588
413	Max Hayward	\N	2026-05-31 15:59:10.68724
414	Harry A. Poeze	\N	2026-05-31 16:00:05.085304
415	Tasha Agrippina	\N	2026-05-31 16:00:05.409766
416	Mikhail Bakunin	\N	2026-05-31 16:01:43.279416
417	Sam Dolgoff	\N	2026-05-31 16:01:43.700538
418	Umberto Eco	\N	2026-05-31 16:02:08.564392
419	Samuel Beckett	\N	2026-05-31 16:02:38.311182
420	Max Arifin	\N	2026-05-31 16:08:38.68699
421	Arif B. Prasetyo	\N	2026-05-31 16:12:38.362263
422	Milan Kundera	\N	2026-05-31 16:13:20.601349
423	Landung Simatupang	\N	2026-05-31 16:13:20.938386
424	Iwan Simatupang	\N	2026-05-31 16:14:46.763934
425	Natsume Sōseki	\N	2026-05-31 16:15:24.249729
426	Matthew Gregory Lewis	\N	2026-05-31 16:15:48.821191
427	Lien Laksmana	\N	2026-05-31 16:15:49.229598
428	Philip Horne	\N	2026-05-31 16:18:35.418675
429	Katrin Bandel	\N	2026-05-31 16:20:18.041433
430	Matt Ridley	\N	2026-05-31 16:21:30.532099
431	Vijay Prashad	\N	2026-05-31 16:22:03.422606
432	Noor Cholis	\N	2026-05-31 16:27:10.898495
433	Takehiko Inoue	\N	2026-05-31 16:45:45.771234
434	E.P. Armanda	\N	2026-05-31 16:45:46.098574
435	Edhi Martono	\N	2026-05-31 16:50:11.870828
436	Honoré de Balzac	\N	2026-06-04 18:17:34.954639
437	Yogas Ardiansyah	\N	2026-06-04 18:17:35.309434
438	Olle Törnquist	\N	2026-06-04 18:17:55.00616
439	Harsutejo	\N	2026-06-04 18:17:55.323837
440	Salman Rushdie	\N	2026-06-12 01:09:50.34786
441	Riichiro Inagaki	\N	2026-06-27 19:53:34.696428
442	Boichi	\N	2026-06-27 19:53:36.894471
443	Knut Hamsun	\N	2026-06-28 15:33:38.297316
444	Marianne Katoppo	\N	2026-06-28 15:33:38.634229
445	Tatsuya Endo	\N	2026-06-28 15:35:00.820082
446	Juan Hadrianus	\N	2026-06-28 15:35:01.229783
447	Eiichiro Oda	\N	2026-06-28 15:36:35.765112
448	Comte de Lautréamont	\N	2026-06-28 15:47:54.516997
449	Boam Ramdani	\N	2026-06-28 15:47:55.907705
450	Ango Sakaguchi	\N	2026-06-28 15:56:21.710452
451	Ivan Diaz Sancho	\N	2026-06-28 15:56:23.902876
452	Clayton Maris	\N	2026-06-28 15:58:48.538066
453	坂口安吾	\N	2026-06-28 16:05:53.561547
\.


--
-- Data for Name: book_authors; Type: TABLE DATA; Schema: public; Owner: default
--

COPY public.book_authors (book_id, author_id, author_order) FROM stdin;
2	1	1
4	2	1
5	2	1
6	4	1
7	7	1
8	8	1
9	9	1
10	10	1
11	11	1
12	12	1
13	13	1
14	15	1
15	16	1
16	11	1
17	17	1
18	18	1
19	19	1
20	20	1
21	21	1
22	22	1
23	16	1
24	23	1
25	24	1
26	8	1
27	25	1
28	26	1
29	27	1
30	28	1
31	29	1
32	30	1
33	34	1
34	32	1
35	33	1
36	8	1
37	8	1
38	35	1
39	36	1
40	37	1
41	8	1
42	8	1
43	40	1
45	8	1
46	41	1
47	42	1
48	43	1
49	44	1
50	45	1
51	46	1
52	47	1
53	54	1
54	49	1
55	50	1
56	52	1
57	51	1
58	53	1
59	55	1
60	56	1
61	57	1
62	58	1
63	59	1
64	60	1
65	61	1
66	62	1
67	11	1
68	63	1
69	64	1
70	23	1
71	23	1
72	11	1
73	65	1
74	66	1
75	67	1
76	72	1
77	68	1
78	69	1
79	70	1
80	11	1
81	71	1
82	73	1
83	74	1
84	80	1
85	75	1
86	81	1
87	77	1
89	78	1
90	79	1
91	12	1
92	82	1
93	12	1
94	83	1
95	84	1
96	85	1
97	86	1
98	27	1
99	87	1
100	88	1
101	88	1
102	88	1
103	88	1
104	27	1
105	10	1
106	89	1
107	86	1
108	90	1
109	95	1
110	91	1
111	92	1
112	93	1
113	94	1
114	86	1
115	86	1
116	96	1
117	97	1
118	98	1
119	99	1
120	100	1
121	101	1
122	102	1
123	12	1
124	103	1
125	104	1
126	104	1
127	105	1
128	106	1
129	104	1
130	108	1
131	109	1
132	110	1
133	111	1
134	112	1
135	113	1
136	100	1
137	114	1
138	115	1
139	116	1
140	20	1
141	124	1
142	125	1
143	126	1
144	127	1
145	117	1
146	118	1
147	119	1
148	120	1
149	121	1
150	122	1
151	123	1
152	129	1
153	130	1
154	131	1
155	132	1
156	132	1
157	125	1
158	133	1
159	125	1
160	132	1
161	134	1
162	135	1
163	136	1
164	137	1
165	132	1
166	104	1
167	138	1
168	141	1
169	142	1
170	143	1
171	143	1
172	141	1
173	144	1
174	145	1
175	104	1
176	146	1
177	147	1
178	148	1
179	141	1
180	149	1
181	153	1
182	150	1
183	151	1
184	152	1
185	154	1
186	155	1
187	158	1
188	149	1
189	156	1
190	149	1
191	157	1
192	100	1
193	159	1
194	160	1
195	167	1
196	8	1
197	10	1
198	93	1
199	161	1
200	162	1
201	163	1
202	164	1
203	165	1
204	166	1
205	168	1
206	169	1
207	170	1
208	172	1
209	156	1
210	168	1
211	173	1
212	174	1
213	175	1
214	176	1
215	100	1
216	179	1
217	179	1
218	179	1
219	177	1
220	30	1
221	30	1
222	178	1
223	109	1
224	180	1
225	180	1
226	180	1
227	180	1
229	182	1
230	183	1
231	184	1
232	185	1
233	186	1
234	186	1
235	186	1
236	186	1
237	186	1
238	186	1
239	186	1
241	187	1
242	187	1
243	188	1
244	189	1
246	190	1
247	191	1
248	192	1
249	193	1
250	196	1
251	196	1
252	196	1
253	190	1
254	194	1
255	195	1
256	197	1
257	180	1
258	194	1
259	194	1
260	194	1
261	8	1
262	198	1
263	200	1
264	201	1
265	195	1
266	202	1
267	8	1
268	200	1
269	204	1
270	200	1
271	187	1
272	200	1
273	200	1
274	205	1
275	206	1
276	207	1
277	187	1
278	208	1
279	200	1
280	198	1
281	200	1
282	200	1
283	209	1
284	210	1
285	195	1
286	209	1
287	211	1
288	193	1
289	205	1
290	202	1
291	200	1
292	212	1
293	200	1
294	195	1
295	200	1
296	200	1
297	200	1
298	212	1
299	180	1
300	195	1
301	205	1
302	205	1
303	205	1
304	200	1
305	205	1
306	205	1
307	180	1
308	195	1
309	195	1
310	195	1
311	195	1
312	198	1
313	187	1
314	187	1
315	195	1
316	195	1
317	195	1
318	195	1
319	209	1
320	195	1
321	213	1
322	195	1
323	195	1
324	187	1
325	214	1
326	198	1
327	168	1
328	215	1
329	198	1
330	216	1
331	217	1
332	214	1
333	86	1
334	180	1
335	198	1
336	187	1
337	199	1
338	217	1
340	209	1
341	195	1
342	193	1
343	185	1
344	218	1
345	219	1
346	214	1
347	196	1
348	220	1
349	220	1
350	219	1
351	196	1
352	217	1
353	214	1
354	196	1
355	220	1
356	220	1
357	221	1
358	222	1
359	196	1
360	223	1
361	195	1
362	164	1
363	224	1
364	225	1
365	180	1
366	226	1
367	200	1
368	227	1
369	228	1
370	196	1
371	196	1
372	214	1
373	219	1
374	223	1
375	196	1
376	229	1
377	220	1
378	230	1
379	190	1
380	231	1
381	233	1
382	179	1
383	187	1
384	180	1
385	234	1
386	234	1
387	235	1
388	237	1
389	219	1
390	214	1
391	238	1
392	104	1
393	98	1
394	145	1
395	243	1
396	242	1
397	241	1
398	240	1
399	239	1
400	244	1
401	195	1
402	245	1
403	246	1
404	200	1
405	195	1
406	215	1
407	14	1
408	248	1
409	248	1
410	195	1
411	249	1
412	220	1
413	220	1
414	246	1
415	220	1
416	196	1
417	250	1
418	250	1
419	195	1
420	196	1
421	220	1
422	220	1
423	212	1
424	212	1
425	187	1
426	251	1
427	200	1
428	252	1
429	187	1
430	226	1
431	250	1
432	250	1
433	220	1
434	220	1
435	195	1
436	217	1
437	220	1
438	253	1
439	220	1
440	220	1
441	220	1
442	220	1
443	220	1
444	220	1
445	254	1
446	255	1
447	87	1
448	256	1
449	250	1
450	257	1
451	258	1
452	259	1
453	250	1
454	220	1
455	200	1
456	250	1
457	250	1
458	260	1
459	250	1
460	250	1
461	250	1
462	195	1
463	261	1
464	226	1
465	187	1
466	262	1
467	263	1
468	264	1
469	246	1
470	194	1
471	265	1
472	266	1
473	267	1
474	215	1
475	268	1
476	269	1
477	270	1
478	196	1
479	196	1
480	271	1
483	12	1
483	276	2
483	277	3
484	278	1
485	279	1
485	280	2
485	281	3
486	212	1
487	282	1
487	283	2
488	273	1
488	274	2
489	284	1
489	285	2
490	286	1
491	215	1
492	287	1
493	288	1
494	289	1
495	195	1
496	290	1
497	250	1
497	291	2
498	250	1
498	291	2
499	187	1
499	292	2
500	217	1
501	250	1
501	291	2
502	187	1
502	180	2
502	293	3
503	250	1
503	291	2
504	250	1
504	291	2
505	250	1
505	291	2
506	294	1
507	200	1
507	295	2
508	294	1
509	294	1
510	296	1
510	297	2
511	187	1
511	292	2
512	294	1
513	294	1
514	250	1
514	291	2
515	27	1
516	294	1
517	250	1
517	291	2
518	250	1
518	291	2
519	250	1
519	291	2
520	250	1
520	291	2
521	250	1
521	291	2
522	294	1
523	298	1
524	294	1
524	299	2
525	300	1
525	301	2
525	255	3
526	294	1
527	294	1
530	27	1
530	222	2
530	303	3
531	27	1
532	302	1
533	304	1
533	305	2
534	306	1
535	187	1
535	292	2
536	294	1
537	307	1
538	307	1
539	307	1
540	307	1
541	307	1
542	307	1
543	308	1
544	309	1
545	290	1
546	309	1
547	310	1
548	311	1
548	312	2
548	313	3
549	311	1
550	290	1
551	314	1
551	315	2
552	311	1
552	316	2
553	290	1
554	317	1
555	318	1
556	319	1
556	320	2
557	264	1
558	321	1
559	187	1
559	293	2
559	180	3
560	322	1
560	323	2
561	324	1
562	190	1
562	325	2
562	326	3
563	327	1
563	328	2
564	190	1
564	329	2
565	330	1
566	195	1
567	332	1
568	318	1
569	318	1
569	180	2
570	187	1
570	333	2
571	334	1
571	335	2
572	336	1
573	337	1
573	338	2
574	296	1
575	339	1
575	340	2
576	27	1
577	341	1
577	342	2
577	343	3
578	294	1
578	299	2
579	296	1
580	187	1
581	344	1
582	337	1
582	338	2
583	345	1
584	345	1
585	345	1
586	306	1
587	200	1
588	222	1
589	346	1
589	347	2
590	348	1
591	246	1
592	226	1
593	306	1
594	349	1
595	350	1
595	351	2
596	352	1
597	353	1
597	354	2
597	355	3
598	356	1
598	357	2
599	358	1
600	359	1
601	360	1
601	361	2
602	358	1
602	362	2
603	318	1
604	305	1
605	363	1
605	364	2
606	348	1
607	202	1
607	365	2
608	366	1
608	367	2
609	294	1
610	368	1
611	226	1
612	369	1
613	318	1
613	180	2
614	370	1
614	310	2
615	371	1
615	372	2
616	373	1
616	374	2
617	294	1
618	375	1
618	376	2
619	377	1
619	378	2
619	376	3
620	294	1
621	380	1
622	381	1
623	363	1
623	382	2
623	364	3
624	306	1
626	386	1
626	387	2
627	20	1
629	388	1
629	389	2
630	383	1
630	384	2
630	385	3
631	390	1
631	391	2
631	392	3
632	393	1
633	394	1
634	395	1
635	396	1
635	397	2
636	288	1
637	255	1
638	395	1
639	398	1
639	399	2
640	195	1
641	395	1
642	400	1
642	401	2
643	161	1
644	161	1
644	404	2
644	405	3
645	400	1
646	406	1
647	407	1
647	285	2
648	408	1
648	409	2
648	410	3
649	411	1
649	412	2
649	413	3
650	386	1
651	414	1
651	415	2
652	416	1
652	417	2
653	418	1
654	419	1
655	255	1
655	345	2
656	278	1
657	282	1
657	420	2
658	278	1
659	278	1
659	421	2
660	422	1
660	423	2
661	394	1
662	424	1
663	425	1
663	310	2
664	426	1
664	427	2
665	386	1
665	428	2
666	429	1
667	255	1
668	430	1
669	431	1
669	274	2
670	223	1
671	27	1
672	27	1
673	422	1
673	432	2
674	187	1
674	293	2
675	395	1
676	363	1
677	363	1
678	363	1
679	363	1
680	395	1
681	395	1
682	395	1
683	395	1
684	395	1
685	395	1
686	395	1
687	395	1
688	395	1
689	395	1
690	395	1
691	395	1
692	395	1
693	395	1
694	395	1
695	395	1
696	395	1
697	395	1
698	395	1
699	395	1
700	395	1
701	395	1
702	433	1
702	434	2
703	12	1
703	435	2
704	436	1
704	437	2
705	438	1
705	439	2
705	110	3
706	440	1
707	441	1
707	442	2
708	187	1
708	333	2
709	441	1
710	441	1
711	441	1
711	442	2
712	441	1
712	442	2
713	441	1
713	442	2
714	441	1
715	441	1
716	441	1
717	441	1
718	441	1
719	441	1
719	442	2
720	441	1
721	27	1
722	443	1
722	444	2
723	445	1
723	446	2
724	445	1
724	446	2
725	447	1
726	447	1
727	447	1
728	447	1
729	447	1
730	447	1
731	447	1
732	447	1
733	447	1
734	447	1
735	344	1
736	344	1
737	344	1
738	223	1
739	450	1
739	451	2
740	450	1
740	452	2
741	450	1
742	450	1
743	450	1
744	450	1
\.


--
-- Data for Name: book_genres; Type: TABLE DATA; Schema: public; Owner: default
--

COPY public.book_genres (book_id, genre_id, is_primary) FROM stdin;
2	2	f
4	1	f
4	2	f
5	2	f
5	4	f
6	6	f
7	13	f
8	6	f
8	14	f
9	8	f
9	15	f
10	2	f
10	12	f
10	16	f
11	15	f
12	2	f
12	15	f
12	17	f
13	2	f
13	10	f
14	2	f
14	4	f
15	2	f
15	15	f
15	17	f
16	2	f
16	15	f
17	15	f
17	17	f
18	2	f
19	11	f
19	17	f
19	18	f
20	19	f
21	20	f
22	20	f
23	15	f
23	17	f
24	11	f
24	15	f
25	7	f
25	21	f
26	7	f
26	14	f
27	2	f
27	22	f
28	2	f
29	2	f
30	23	f
31	23	f
32	17	f
33	6	f
34	20	f
35	3	f
35	7	f
36	7	f
36	14	f
37	6	f
37	14	f
38	12	f
38	25	f
39	18	f
39	25	f
40	11	f
40	25	f
41	7	f
41	14	f
42	7	f
42	14	f
43	8	f
43	15	f
43	25	f
45	7	f
45	14	f
46	23	f
47	2	f
47	11	f
48	23	f
49	23	f
50	7	f
50	25	f
51	7	f
51	19	f
52	24	f
53	2	f
54	7	f
55	20	f
56	15	f
56	25	f
57	26	f
58	20	f
59	24	f
60	18	f
61	24	f
62	15	f
63	21	f
64	25	f
65	20	f
66	24	f
67	15	f
68	11	f
69	17	f
70	17	f
71	17	f
72	15	f
72	17	f
73	15	f
73	17	f
74	17	f
75	17	f
76	11	f
76	17	f
77	8	f
77	11	f
77	15	f
78	8	f
78	11	f
78	15	f
79	11	f
79	15	f
79	17	f
80	17	f
81	17	f
82	11	f
83	14	f
83	17	f
84	11	f
84	15	f
85	6	f
85	11	f
86	11	f
86	15	f
87	8	f
87	11	f
87	15	f
89	17	f
90	6	f
91	15	f
91	17	f
92	2	f
92	10	f
93	2	f
93	17	f
94	2	f
95	2	f
96	2	f
97	2	f
98	2	f
99	2	f
100	2	f
101	2	f
102	2	f
103	2	f
103	17	f
104	2	f
105	2	f
105	4	f
106	6	f
106	20	f
107	2	f
108	18	f
108	25	f
109	17	f
109	20	f
110	6	f
110	20	f
111	17	f
111	25	f
112	17	f
113	17	f
114	2	f
114	10	f
115	2	f
115	10	f
116	17	f
116	18	f
117	17	f
118	17	f
119	17	f
120	17	f
121	17	f
122	17	f
122	20	f
123	17	f
124	17	f
124	18	f
125	17	f
125	20	f
126	17	f
127	17	f
128	17	f
129	17	f
130	20	f
131	17	f
132	17	f
133	17	f
134	17	f
135	17	f
136	17	f
137	17	f
137	20	f
138	17	f
139	17	f
139	25	f
140	17	f
141	17	f
141	23	f
142	23	f
143	23	f
144	23	f
145	23	f
146	7	f
147	23	f
148	23	f
149	23	f
150	23	f
151	23	f
152	23	f
153	23	f
154	23	f
155	23	f
156	23	f
157	23	f
158	23	f
158	24	f
159	23	f
160	23	f
161	23	f
162	23	f
163	23	f
164	23	f
165	23	f
166	17	f
167	7	f
167	28	f
168	7	f
168	28	f
169	7	f
169	21	f
169	28	f
170	7	f
171	7	f
172	7	f
173	7	f
174	7	f
175	7	f
176	7	f
177	23	f
178	7	f
179	7	f
179	28	f
180	7	f
181	7	f
181	28	f
182	7	f
183	7	f
184	7	f
185	14	f
185	23	f
186	7	f
187	7	f
188	7	f
189	7	f
190	7	f
191	25	f
192	17	f
193	21	f
194	9	f
195	7	f
195	23	f
196	7	f
196	14	f
197	15	f
197	17	f
197	20	f
198	17	f
199	2	f
199	10	f
200	9	f
201	17	f
202	7	f
203	6	f
204	2	f
205	17	f
206	17	f
207	2	f
207	15	f
208	6	f
208	15	f
209	7	f
210	17	f
211	17	f
212	6	f
212	17	f
213	6	f
214	12	f
215	17	f
216	20	f
217	20	f
218	20	f
219	17	f
220	17	f
221	17	f
222	17	f
223	12	f
224	9	f
225	9	f
226	9	f
227	9	f
229	6	f
229	11	f
230	17	f
231	11	f
232	12	f
232	17	f
233	1	f
233	2	f
233	16	f
234	1	f
234	2	f
234	16	f
235	1	f
235	2	f
235	16	f
236	1	f
236	2	f
236	16	f
237	1	f
237	2	f
237	16	f
238	1	f
238	2	f
238	16	f
239	1	f
239	2	f
239	16	f
241	4	f
241	9	f
242	4	f
242	9	f
243	3	f
244	3	f
246	9	f
246	22	f
247	6	f
247	20	f
248	15	f
249	2	f
250	9	f
251	9	f
252	9	f
253	9	f
253	22	f
254	2	f
255	9	f
256	2	f
257	9	f
258	15	f
259	2	f
259	17	f
260	2	f
261	14	f
262	2	f
263	9	f
264	2	f
264	17	f
265	9	f
266	2	f
267	14	f
267	25	f
268	9	f
269	2	f
270	9	f
271	9	f
272	9	f
273	9	f
274	9	f
275	2	f
276	17	f
277	9	f
278	15	f
279	9	f
280	2	f
281	9	f
282	9	f
283	2	f
284	15	f
285	9	f
286	2	f
287	29	f
288	2	f
288	17	f
289	9	f
290	2	f
291	9	f
292	2	f
293	9	f
294	9	f
295	9	f
296	9	f
297	9	f
298	2	f
299	9	f
300	9	f
301	9	f
302	9	f
303	9	f
304	9	f
305	9	f
306	9	f
307	9	f
308	9	f
309	9	f
310	9	f
311	9	f
312	2	f
313	9	f
314	9	f
315	9	f
316	9	f
317	9	f
318	9	f
319	2	f
319	17	f
320	9	f
321	2	f
322	9	f
323	9	f
324	9	f
325	2	f
326	2	f
327	17	f
328	2	f
329	2	f
330	9	f
331	2	f
332	15	f
333	6	f
334	9	f
335	2	f
336	9	f
337	2	f
338	2	f
340	2	f
340	17	f
341	9	f
342	2	f
343	17	f
344	7	f
345	2	f
345	17	f
346	15	f
347	9	f
348	9	f
349	9	f
350	17	f
351	9	f
352	2	f
353	15	f
354	9	f
355	9	f
356	9	f
357	17	f
358	2	f
359	9	f
360	15	f
360	17	f
361	9	f
362	7	f
363	2	f
364	2	f
364	17	f
365	9	f
366	2	f
367	9	f
368	2	f
369	2	f
369	17	f
370	9	f
371	9	f
372	15	f
373	2	f
374	2	f
375	9	f
376	2	f
376	17	f
377	9	f
378	2	f
379	9	f
380	12	f
381	15	f
382	17	f
383	9	f
384	9	f
385	12	f
386	12	f
387	20	f
388	2	f
389	2	f
390	2	f
390	15	f
391	2	f
392	17	f
393	17	f
393	18	f
394	7	f
395	6	f
395	21	f
396	6	f
397	6	f
398	6	f
399	12	f
399	17	f
400	2	f
401	9	f
402	7	f
402	17	f
403	2	f
404	9	f
405	9	f
406	2	f
407	2	f
408	9	f
409	9	f
410	9	f
411	2	f
412	9	f
413	9	f
414	2	f
415	9	f
416	9	f
417	9	f
418	9	f
419	9	f
420	9	f
421	9	f
422	9	f
423	17	f
424	2	f
425	9	f
426	2	f
427	9	f
428	2	f
429	9	f
430	2	f
431	9	f
432	9	f
433	9	f
434	9	f
435	9	f
436	2	f
437	9	f
438	2	f
439	9	f
440	9	f
441	9	f
442	9	f
443	9	f
444	9	f
445	17	f
446	2	f
447	2	f
448	2	f
449	9	f
450	2	f
451	2	f
452	2	f
453	9	f
454	9	f
455	9	f
456	9	f
457	9	f
458	2	f
459	9	f
460	9	f
461	9	f
462	9	f
463	2	f
464	2	f
465	9	f
466	2	f
467	6	f
468	9	f
469	2	f
470	2	f
471	2	f
472	2	f
473	17	f
473	23	f
474	2	f
475	2	f
476	2	f
477	2	f
478	9	f
479	9	f
480	2	f
483	15	t
483	17	f
484	17	t
485	15	t
485	30	f
486	30	t
487	2	t
487	16	f
488	2	t
488	16	f
489	17	t
489	24	f
490	2	t
490	6	f
491	2	t
492	2	t
493	2	t
494	6	t
495	9	t
496	9	t
497	9	t
498	9	t
499	9	t
500	2	t
501	9	t
502	9	t
503	9	t
504	9	t
505	9	t
506	9	t
507	9	t
508	9	t
509	9	t
510	9	t
511	9	t
512	9	t
513	9	t
514	9	t
515	2	t
516	9	t
517	9	t
518	9	t
519	9	t
520	9	t
521	9	t
522	9	t
523	9	t
524	9	t
525	30	t
526	9	t
527	9	t
530	30	t
531	2	t
532	17	t
533	2	t
534	2	t
535	9	t
536	9	t
537	11	t
538	11	t
539	11	t
540	11	t
541	11	t
542	11	t
543	2	t
544	30	t
545	9	t
546	30	t
547	2	t
548	17	t
548	20	f
549	17	t
550	9	t
551	11	t
551	6	f
552	17	t
553	9	t
554	2	t
555	9	t
556	9	t
557	9	t
558	2	t
559	9	t
560	25	t
560	17	f
561	2	t
562	9	t
563	6	t
564	9	t
565	20	t
566	9	t
567	20	t
567	6	f
568	9	t
569	9	t
570	9	t
571	12	t
571	6	f
572	20	t
573	2	t
573	22	f
573	18	f
574	9	t
575	2	t
575	3	f
576	30	t
577	6	t
577	17	f
578	9	t
579	9	t
580	9	t
581	9	t
582	2	t
583	30	t
584	30	t
585	30	t
586	2	t
587	9	t
588	30	t
588	22	f
589	2	t
590	20	t
591	2	t
592	2	t
593	2	t
594	2	t
595	2	t
596	6	t
597	9	t
598	11	t
598	12	f
599	9	t
600	2	t
601	2	t
601	4	f
602	9	t
603	9	t
604	2	t
605	9	t
606	20	t
607	2	t
608	28	t
609	9	t
610	30	t
611	30	t
612	2	t
613	9	t
614	2	t
615	2	t
615	6	f
616	2	t
617	9	t
618	2	t
619	15	t
620	9	t
621	2	t
622	2	t
623	9	t
624	2	t
626	2	t
627	20	t
629	15	t
630	2	t
631	2	t
631	4	f
632	2	t
633	2	t
634	9	t
635	9	t
636	30	t
637	2	t
638	9	t
639	2	t
640	9	t
641	9	t
642	25	t
642	17	f
643	2	t
644	2	t
645	2	t
646	17	t
647	2	t
648	2	t
649	2	t
650	2	t
651	6	t
652	25	t
652	17	f
653	17	t
654	2	t
655	2	t
656	2	t
657	2	t
658	15	t
659	15	t
660	2	t
661	2	t
662	2	t
663	2	t
664	2	t
665	2	t
666	15	t
667	30	t
668	28	t
668	7	f
669	2	t
670	2	t
671	15	t
672	15	t
673	2	t
674	9	t
675	9	t
676	9	t
677	9	t
678	9	t
679	9	t
680	9	t
681	9	t
682	9	t
683	9	t
684	9	t
685	9	t
686	9	t
687	9	t
688	9	t
689	9	t
690	9	t
691	9	t
692	9	t
693	9	t
694	9	t
695	9	t
696	9	t
697	9	t
698	9	t
699	9	t
700	9	t
701	9	t
702	9	t
703	17	t
704	2	t
705	6	t
706	15	t
707	9	t
708	9	t
709	9	t
710	9	t
711	9	t
712	9	t
713	9	t
714	9	t
715	9	t
716	9	t
717	9	t
718	9	t
719	9	t
720	9	t
721	15	t
722	2	t
723	9	t
724	9	t
725	9	t
726	9	t
727	9	t
728	9	t
729	9	t
730	9	t
731	9	t
732	9	t
733	9	t
734	9	t
735	9	t
736	9	t
737	9	t
738	2	t
739	30	t
740	2	t
741	2	t
743	2	t
744	15	t
\.


--
-- Data for Name: book_quotes; Type: TABLE DATA; Schema: public; Owner: default
--

COPY public.book_quotes (quote_id, book_id, quote_text, page_number, chapter, tags, is_favorite, notes, created_at, updated_at) FROM stdin;
1	105	quote 1	213	5	{inspiration}	t	\N	2025-12-28 16:44:33.488158	2025-12-28 16:44:33.488158
\.


--
-- Data for Name: books; Type: TABLE DATA; Schema: public; Owner: default
--

COPY public.books (book_id, title, isbn, goodreads_url, year, pages, added_at) FROM stdin;
2	Moby Dick	9786238392476	https://www.goodreads.com/book/show/29235308-moby-dick?from_search=true&from_srp=true&qid=gUD8ZbXhTx&rank=4	2024	76	2025-01-04 07:06:26.663
4	A Study In Scarlet	9786020631660	https://www.goodreads.com/book/show/43523263-a-study-in-scarlet?from_search=true&from_srp=true&qid=4XsWERKuuV&rank=1	2019	\N	2024-11-22 08:05:00
5	The Case Book of Sherlock Holmes	9786020637099	https://www.goodreads.com/book/show/162823.The_Case_Book_of_Sherlock_Holmes?ac=1&from_search=true&qid=QeKHwUqHkI&rank=1	2019	\N	2024-11-22 09:25:00
6	The Lessons of History	9786236219850	https://www.goodreads.com/book/show/174713.The_Lessons_of_History?from_search=true&from_srp=true&qid=Rm8Rq2dHOp&rank=2	1928	\N	2024-11-22 09:30:00
7	Aboday	9786026564092	https://www.goodreads.com/book/show/37663320-firmitas---aboday?from_search=true&from_srp=true&qid=RCIXEYCYNA&rank=1	2017	255	2024-11-22 09:32:00
8	Kartun Riwayat Peradaban Modern 01	9786024814595	https://www.goodreads.com/book/show/1510028.Kartun_Riwayat_Peradaban_Modern_Jilid_I?from_search=true&from_srp=true&qid=NMB5hYu4bz&rank=1	2007	\N	2024-11-22 09:34:00
9	The Odyssey of Homer	9786029682861	https://www.goodreads.com/book/show/1297872.The_Odyssey_of_Homer?from_search=true&from_srp=true&qid=ItkVMgXHpz&rank=2	1937	\N	2024-11-22 09:39:00
10	Animal Farm	9786022912828	https://www.goodreads.com/book/show/170448.Animal_Farm?from_search=true&from_srp=true&qid=hBJzfDr4KC&rank=5	1945	\N	2024-11-22 09:41:00
11	Setitis Air Mata, Seulas Senyuman	9786237046240	https://www.gramedia.com/products/kahlil-gibran-setitis-air-mata-seulas-senyum?srsltid=AfmBOoqrRN6WzvmsoPqHXjUP6LTM2i0MwJ1rYJDxgq2t_rL73jfumyDq	2019	\N	2024-11-22 09:46:00
12	Kejatuhan	9786237543817	https://www.goodreads.com/book/show/35967270-kejatuhan?from_search=true&from_srp=true&qid=xFbCGC1E7P&rank=1	1956	\N	2024-11-22 09:49:00
13	Layla Majnun	9786025568497	https://www.goodreads.com/book/show/67397.Layla_and_Majnun?from_search=true&from_srp=true&qid=FzWJhH4hEL&rank=1	2019	\N	2024-11-22 09:50:00
14	Negeri Para Bedebah	9789792285529	https://www.goodreads.com/book/show/15721334-negeri-para-bedebah?from_search=true&from_srp=true&qid=NHfVRoQD57&rank=1	2012	\N	2024-11-22 09:53:00
15	Markesot Bertutur	9786024411145	https://www.goodreads.com/book/show/3078425-markesot-bertutur?from_search=true&from_srp=true&qid=B5UJB17dX6&rank=1	1993	\N	2024-11-22 09:58:00
16	Sayap Sayap Patah	9786026154361	https://www.goodreads.com/book/show/58015819-sayap-sayap-patah?from_search=true&from_srp=true&qid=ocxbqS7I49&rank=2	2018	\N	2024-11-22 09:59:00
17	Sabdo Cinta Angon Kasih	9786022915140	https://www.goodreads.com/book/show/44443381-sabdo-cinta-angon-kasih?from_search=true&from_srp=true&qid=xb7vfeXoFO&rank=1	2018	\N	2024-11-22 10:00:00
18	Buku Panduan Matematika Terapan	9786020383026	https://www.goodreads.com/book/show/39335587-buku-panduan-matematika-terapan?from_search=true&from_srp=true&qid=PLlaoZVjaX&rank=1	2018	\N	2024-11-22 10:02:00
19	Terapi Jiwa (Ahwal An-Nafs)	9786234006575	https://www.gramedia.com/products/terapi-jiwa?srsltid=AfmBOoph87rn-2E_HMXcK53pKN_Xu2DwAoeqtsNdvlCczfEy4m14n_8P	2023	\N	2024-11-22 10:07:00
20	TTS Kompas 3	9786024123680	https://www.gramedia.com/products/tts-pilihan-kompas-jilid-3-edisi-baru	2011	\N	2024-11-22 10:10:00
21	Ibnu Sina (biografi)	9786026380210	https://www.gramedia.com/products/ibnu-sina?srsltid=AfmBOorEAAR9HcChRbdgovbPkRaU7vjEEB_Bnu8c1gM4OTf_2uzczT3s	2017	\N	2024-11-22 10:12:00
22	Jalaluddin Rumi	9786020770772	https://www.goodreads.com/book/show/60646275-jejak-langkah-sang-sufi-jalaluddin-rumi?from_search=true&from_srp=true&qid=6Q2MaZB6b5&rank=1	2019	\N	2024-11-22 10:13:00
23	Pemimpin yang Tuhan	9786022915126	https://www.goodreads.com/book/show/41948416-pemimpin-yang-tuhan?from_search=true&from_srp=true&qid=g4xtXVe93S&rank=1	2018	\N	2024-11-22 10:14:00
24	Dari Allah menuju Allah	9786023856084	https://www.goodreads.com/book/show/44312826-dari-allah-menuju-allah?from_search=true&from_srp=true&qid=XUsvBfLdIM&rank=1	2019	\N	2024-11-22 10:18:00
25	Food Rules	9786020635651	https://www.goodreads.com/book/show/7015635-food-rules?from_search=true&from_srp=true&qid=B7d65grWPU&rank=1	2009	\N	2024-11-22 10:22:00
26	Kartun Aljabar	9786024816780	https://www.goodreads.com/book/show/59511152-kartun-aljabar?from_search=true&from_srp=true&qid=sg3y4qdowu&rank=1	2015	\N	2024-11-22 10:23:00
27	Dracula	9789792228663	https://www.goodreads.com/book/show/17245.Dracula?ac=1&from_search=true&qid=vbwlhrCONg&rank=1	1988	\N	2024-11-22 10:27:00
28	The Rise of Majapahit	9786024528850	https://www.goodreads.com/book/show/24337340-the-rise-of-majapahit?from_search=true&from_srp=true&qid=soxGz0D7PA&rank=1	2014	\N	2024-11-22 13:51:00
29	Perempuan Patah Hati yang Kembali Menemukan Cinta Melalui Mimpi	9786022918738	https://www.goodreads.com/book/show/24636477-perempuan-patah-hati-yang-kembali-menemukan-cinta-melalui-mimpi?from_search=true&from_srp=true&qid=s7KAVc83b7&rank=1	2015	\N	2024-11-22 13:53:00
30	Semua bisa menjadi programmer python case study	9786230011689	https://www.goodreads.com/book/show/107556672-semua-bisa-menjadi-programmer-python-basic?from_search=true&from_srp=true&qid=cvuynrOl6I&rank=12	2020	\N	2024-11-22 13:56:00
31	AINomics	9786230011689	https://ebooks.gramedia.com/id/buku/ainomics-economic-artificial-intelligence-hubungan-manusia-dengan-mesin	2021	\N	2024-11-22 13:57:00
32	Mati Sebelum Mati Buka Kesadaran Hakiki	9786232424005	https://www.goodreads.com/book/show/219733614-mati-sebelum-mati-buka-kesadaran-hakiki?from_search=true&from_srp=true&qid=CzenAqkFch&rank=1	2023	\N	2024-11-22 13:58:00
33	Tarekat Mason Bebas dan Masyarakat di Hindia Belanda dan Indonesia 1764-1962	9794168041	https://www.goodreads.com/book/show/6687124-tarekat-mason-bebas-dan-masyarakat-di-hindia-belanda-dan-indonesia-1764-?from_search=true&from_srp=true&qid=VCTy4affTV&rank=1	1994	\N	2024-11-22 14:06:00
34	Soe Hok Gie Sekali Lagi	9786024241346	https://www.goodreads.com/book/show/7299756-soe-hok-gie-sekali-lagi?from_search=true&from_srp=true&qid=86whSF24kV&rank=1	2016	\N	2024-11-22 14:09:00
35	Ensiklopedia saintis cilik: Dinosaurus	9786024819798	https://www.goodreads.com/book/show/126859481-ensiklopedia-saintis-cilik?from_search=true&from_srp=true&qid=burMJkppDk&rank=1	2023	\N	2024-11-22 14:12:00
36	Kartun Fisika	9786024813321	https://www.goodreads.com/book/show/1665043.Kartun_Fisika?from_search=true&from_srp=true&qid=2l70GHbcL5&rank=1	1990	\N	2024-11-22 14:13:00
37	Kartun riwayat peradaban 01	9786024241537	https://www.goodreads.com/book/show/1463296.Kartun_Riwayat_Peradaban_Jilid_I?from_search=true&from_srp=true&qid=uYdAmrYkBd&rank=1	1990	\N	2024-11-22 14:15:00
38	On Palestine	9786231863171	https://www.goodreads.com/book/show/23129811-on-palestine?from_search=true&from_srp=true&qid=MBTDCmZEOh&rank=1	2024	\N	2024-11-22 14:24:00
39	Intelijen	9786230103988	https://www.gramedia.com/products/intelijen-teori-intelijenpembangunan-jaringan-ed-ix	2020	\N	2024-11-22 14:27:00
40	What is religious authority	9786024413316	https://www.goodreads.com/book/show/55873408-what-is-religious-authority?from_search=true&from_srp=true&qid=sikgnsbYAf&rank=1	2024	\N	2024-11-22 14:29:00
41	Kartun Genetika	9786024813420	https://www.goodreads.com/book/show/1725165.Kartun_Biologi_Genetika?from_search=true&from_srp=true&qid=NNqEgwmddv&rank=1	2020	\N	2024-11-22 14:30:00
42	Kartun Kalkulus	9786024816209	https://www.goodreads.com/book/show/58968798-kartun-kalkulus?from_search=true&from_srp=true&qid=Nqfj9LPLVC&rank=1	2012	\N	2024-11-22 14:32:00
43	Kitab Primbon Betaljemur Adamakna	9786237586920	https://www.goodreads.com/book/show/126986253-kitab-primbon-betaljemur-adammakna?from_search=true&from_srp=true&qid=uGQkK7mRDM&rank=1	2023	\N	2024-11-22 14:34:00
45	Kartun Statistik	9786024814151	https://www.goodreads.com/book/show/1723050.Kartun_Statistik?from_search=true&from_srp=true&qid=wEC9b8hBpl&rank=1	1993	\N	2024-11-22 14:35:00
46	Membuat laporan pdf untuk aplikasi web dengan PHP 5	9789792758696	https://perpustakaan.palcomtech.ac.id/index.php?p=show_detail&id=2909&keywords=	2009	\N	2024-11-22 18:09:00
47	Empat Puluh Kaidah Cinta	9789799106872	https://www.goodreads.com/book/show/23156483-empat-puluh-kaidah-cinta?from_search=true&from_srp=true&qid=5RJEv2PJGp&rank=1	2014	\N	2024-11-22 18:12:00
48	Membuat aplikasi mobile native dengan javascript by nativescript	9786026231178	https://www.gramedia.com/products/membuat-aplikasi-mobile-native-dengan-javascript-by-nativescript	2018	\N	2024-11-22 18:13:00
49	Konsep dan Implementasi Pemorgraman Laravel 5	9786026231017	https://www.gramedia.com/products/konsep-dan-implementasi-pemrograman-laravel-5-edisi-2019-1?srsltid=AfmBOooah4w4-BCRSJBerJjx9m0MNLXdjcyzqUKzHqTlmr7EAT9Bqhq9&is_open_image_preview=true	2017	\N	2024-11-22 18:15:00
50	Berbohong dengan Statistik	9786024816032	https://www.goodreads.com/book/show/1605929.Berbohong_dengan_Statistik?from_search=true&from_srp=true&qid=JhnPf0jWc8&rank=1	2002	\N	2024-11-22 18:16:00
51	Teka teki enstein	9786020363370	https://www.goodreads.com/book/show/6411322-einstein-s-riddle?from_search=true&from_srp=true&qid=OkjQGop6Eh&rank=2	2009	\N	2024-11-22 18:17:00
52	FUNDAMENTAL vs TECHNICAL	9786230018527	https://www.goodreads.com/book/show/57018627-fundamental-vs-technical?from_search=true&from_srp=true&qid=hrG8iFYfMD&rank=1	2020	\N	2024-11-22 18:21:00
53	Pope's Assassin	9780515150179	https://www.goodreads.com/book/show/159430689-the-pope-s-assassin-by-rocha-luis-miguel-2011-mass-market-paperback?from_search=true&from_srp=true&qid=bp6JLeuVME&rank=2	2011	\N	2024-11-22 18:24:00
54	Konsep Dasar Kimia Analitik	9794560669	https://onesearch.id/Record/IOS4100.slims-2796	1990	\N	2024-11-22 18:25:00
55	Plato Guru para filosof	9786023501366	https://www.gramedia.com/products/plato-guru-para-filosof	2016	\N	2024-11-22 18:27:00
56	Intisari kitab-kitab Adiluhung Jawa	9786022556992	https://mpn.kominfo.go.id/perpus/index.php?p=show_detail&id=14144&keywords=	2014	\N	2024-11-22 18:29:00
57	Prinsip dasar cara kerja robot	9789797567248	https://bintangpusnas.perpusnas.go.id/konten/BK258/prinsip-dasar-cara-kerja-robot	2011	\N	2024-11-22 18:31:00
58	Tarbiyah Cinta	9789790172975	https://www.goodreads.com/book/show/38918169-tarbiyah-cinta-imam-al-ghazali?from_search=true&from_srp=true&qid=un6RiZXhUd&rank=1	2014	\N	2024-11-22 18:33:00
59	Dragon Slayer Trading Strategy	9786230026270	https://www.goodreads.com/book/show/58208046-dragon-slayer-trading-strategy?from_search=true&from_srp=true&qid=PdYKFC2M7K&rank=1	2021	\N	2024-11-22 18:41:00
60	Amazing NLP	9786027624801	https://www.gramedia.com/products/amazing-nlp-neuro-linguistic-programming	2017	\N	2024-11-22 18:42:00
61	Jatuh Bangun Bos Bos Startup	9786025479045	https://www.gramedia.com/products/jatuh-bangun-bos-bos-starup	2018	\N	2024-11-22 18:43:00
62	Pitutur Luhur Jawa	9786026595232	https://www.goodreads.com/book/show/6185416-pitutur-luhur-pujangga-jawa?from_search=true&from_srp=true&qid=qiEsAQ3VGY&rank=1	2017	\N	2024-11-22 18:45:00
63	Obat-Obat sederhana untuk kesehatan sehari hari	9786230045592	https://www.goodreads.com/book/show/204345983-obat-obat-sederhana-untuk-kesehatan-sehari-hari?from_search=true&from_srp=true&qid=BK0GnsCkki&rank=1	2023	\N	2024-11-22 18:46:00
64	Seni Menjadi Orang Tua Hebat	9786020529431	https://www.goodreads.com/book/show/203850754-seni-menjadi-orang-tua-hebat?from_search=true&from_srp=true&qid=Ei9HcJmDxm&rank=1	2022	\N	2024-11-22 18:47:00
65	Kesaktian dan Tarekat Sunan Kalijaga	9786025805691	https://www.gramedia.com/products/kesaktian-dan-tarekat-sunan-kalijaga	2018	\N	2024-11-22 18:49:00
66	Nak, Belajarlah Soal uang	9786020662145	https://www.goodreads.com/book/show/61980232-nak-belajarlah-soal-uang?from_search=true&from_srp=true&qid=xDjlFCsngV&rank=1	2022	\N	2024-11-22 18:50:00
67	Rahasia Cinta Kahlil Gibran	9786020273051	https://www.goodreads.com/book/show/52221793-rahasia-cinta-kahlil-gibran?from_search=true&from_srp=true&qid=yr3J0ikT1a&rank=1	2015	\N	2024-11-23 03:49:00
68	Untold Islamic History	9786024073091	https://www.goodreads.com/book/show/222125126-untold-islamic-history---mengungkap-sumbangan-keilmuan-dan-peradaban-isl?from_search=true&from_srp=true&qid=bfw8qsp2Dp&rank=1	2018	\N	2024-11-23 03:51:00
69	Tahafut At-tahafut	9793477830	https://www.goodreads.com/book/show/59851015-tahafut-at-tahafut-sanggahan-atas-tahafut-al-falasifah?from_search=true&from_srp=true&qid=PbvtNWO9GO&rank=1	2004	\N	2024-11-23 03:52:00
70	Semesta Cinta	9786023857760	https://www.goodreads.com/book/show/28916433-semesta-cinta?from_search=true&from_srp=true&qid=oEnF5cYhM8&rank=1	2015	\N	2024-11-23 03:53:00
71	Belajar Hidup dari Rumi	9786020989815	https://www.goodreads.com/book/show/27070469-belajar-hidup-dari-rumi?from_search=true&from_srp=true&qid=5S9OLemXS8&rank=1	2015	\N	2024-11-23 03:57:00
72	Sang Nabi	9786026154354	https://www.goodreads.com/book/show/5990048-sang-nabi?from_search=true&from_srp=true&qid=e1iEx0ufaT&rank=2	2018	\N	2024-11-23 03:58:00
73	Sangkan Paraning Dumadi	9786025792021	https://www.goodreads.com/book/show/41963828-sangkan-paraning-dumadi?from_search=true&from_srp=true&qid=k7JEATAU5W&rank=1	2018	\N	2024-11-23 04:00:00
74	Tasawuf Jawa	9786025792489	https://www.gramedia.com/products/tasawuf-jawa	2022	\N	2024-11-23 04:01:00
75	Falsafah Astagina	9786230006685	https://ebooks.gramedia.com/id/buku/falsafah-asthagina	2019	\N	2024-11-23 04:02:00
76	Tafsir Ajaran Wedhatama	0	https://bpcbjatim.kemdikbud.go.id/slims/index.php?p=show_detail&id=1927&keywords=	2012	\N	2024-11-23 04:04:00
77	Paramayoga	9791685169	https://www.goodreads.com/book/show/1604439.Paramayoga?from_search=true&from_srp=true&qid=aXPqI4nXVy&rank=1	2017	\N	2024-11-23 04:05:00
78	Mitologi Jawa	9786025792304	https://www.goodreads.com/book/show/51094092-mitologi-jawa?from_search=true&from_srp=true&qid=jvYsy2mbJx&rank=1	2019	\N	2024-11-23 04:06:00
79	Semesta Matsnawi	6025024580	https://www.goodreads.com/book/show/40110482-semesta-matsnawi?from_search=true&from_srp=true&qid=0LOE9DlbcX&rank=1	2018	\N	2024-11-23 04:08:00
80	Yesus Anak Manusia	0	https://www.goodreads.com/book/show/8436049-yesus-sang-anak-manusia?from_search=true&from_srp=true&qid=8mICQcs5V7&rank=1	2003	\N	2024-11-23 04:09:00
81	Suwung	9786026799296	https://www.goodreads.com/book/show/36277836-suwung?from_search=true&from_srp=true&qid=RRcsjc9Y5K&rank=1	2017	\N	2024-11-23 04:11:00
82	Ikhtisar Ihya Ulumiddin	9786027406483	https://www.goodreads.com/book/show/44311062-ikhtisar-ihya-ulumiddin?from_search=true&from_srp=true&qid=1uh8vTY320&rank=1	2017	\N	2024-11-23 04:27:00
83	Filokomik	9786024814656	https://www.goodreads.com/book/show/55233270-filokomik?from_search=true&from_srp=true&qid=Dcxo0tkuXb&rank=1	2020	\N	2024-11-23 04:28:00
84	Kitab Epos Mahabharata	9786027640504	https://www.goodreads.com/book/show/17561448-kitab-epos-mahabharata?from_search=true&from_srp=true&qid=S7qewzpRt8&rank=1	2014	\N	2024-11-23 04:31:00
85	Sirah Nabawiyyah	9789795926641	https://www.goodreads.com/book/show/18716413-ar-rahiq-al-makhtum-sirah-nabawiyyah?from_search=true&from_srp=true&qid=aPURQ5CJIK&rank=5	2008	\N	2024-11-23 04:33:00
86	Ramayana	9789792222876	https://www.goodreads.com/book/show/1645649.Ramayana?from_search=true&from_srp=true&qid=7N1pvW7hps&rank=1	2003	\N	2024-11-23 04:35:00
87	Serat Dewa Ruci	9786025792373	https://www.goodreads.com/book/show/51599713-serat-dewa-ruci?from_search=true&from_srp=true&qid=nIXzIUUCOk&rank=1	2017	\N	2024-11-23 04:36:00
89	Filsafat Wujud	9793237521	https://www.goodreads.com/book/show/8435779-filsafat-wujud-mulla-sadra?from_search=true&from_srp=true&qid=HQjknt94RL&rank=1	2002	\N	2024-11-23 04:37:00
90	Babad Tanah Jawa	9786025792847	https://www.gramedia.com/products/babad-tanah-jawi-mulai-dari-nabi-adam-sampai-runtuhnya-mata?srsltid=AfmBOoqePBRHiKvT2t1f8Wxv60HHut1WPqBsKhTEls4v3n0vbiZ5NXXc	2019	\N	2024-11-23 04:38:00
91	Summer	9786021526866	https://www.goodreads.com/book/show/2409779.Summer?from_search=true&from_srp=true&qid=ynSPK54q91&rank=3	1995	\N	2024-11-23 06:38:00
92	Mahabbah	9786026799340	https://www.goodreads.com/book/show/38461244-mahabbah?from_search=true&from_srp=true&qid=iu03kqabth&rank=1	2018	\N	2024-11-23 06:39:00
93	The Stranger	9786026657848	https://www.goodreads.com/book/show/49552.The_Stranger?from_search=true&from_srp=true&qid=iq79nfYL0X&rank=3	2018	\N	2024-11-23 06:40:00
94	Petualangan Don Quixote	9786026657626	https://www.goodreads.com/book/show/36985707-petualangan-don-quixote?from_search=true&from_srp=true&qid=nzcRyZ78xI&rank=1	2017	\N	2024-11-23 06:41:00
95	Semua untuk Hindia	9786024248246	https://www.goodreads.com/book/show/22175715-semua-untuk-hindia?from_search=true&from_srp=true&qid=yAtBQIc09u&rank=1	2014	\N	2024-11-23 06:43:00
96	World Fairy Tales	9786232201905	https://www.goodreads.com/book/show/58462921-world-fairy-tales?from_search=true&from_srp=true&qid=g4oeXdHFXx&rank=1	2021	\N	2024-11-23 06:44:00
97	Drama Mangir	9786026208804	https://www.goodreads.com/book/show/12838503-drama-mangir?from_search=true&from_srp=true&qid=F6BgsaH6cO&rank=1	2000	\N	2024-11-23 06:45:00
98	Manusia Harimau	9786020324654	https://www.goodreads.com/book/show/23012658-man-tiger?from_search=true&from_srp=true&qid=v6xzqQgEv4&rank=1	2019	\N	2024-11-23 06:46:00
99	Orang-Orang Biasa	9786022915249	https://www.goodreads.com/book/show/44156290-orang-orang-biasa?from_search=true&from_srp=true&qid=OB3yFUq2qF&rank=1	2019	\N	2024-11-23 06:47:00
100	Dunia Cecilia	9789794338865	https://www.goodreads.com/book/show/26115985-dunia-cecilia?from_search=true&from_srp=true&qid=ygxW3RKy9I&rank=1	2018	\N	2024-11-23 06:48:00
101	Princess of Tales	9786024410957	https://www.goodreads.com/book/show/44434134-princess-of-tales?from_search=true&from_srp=true&qid=XzYrQOAVgU&rank=1	2019	\N	2024-11-23 06:49:00
102	Dunia Anna	9789794338421	https://www.goodreads.com/book/show/23433546-dunia-anna?from_search=true&from_srp=true&qid=3iXPb76MbZ&rank=1	2019	\N	2024-11-23 06:50:00
103	Dunia Sophie	9786024410209	https://www.goodreads.com/book/show/1658408.Dunia_Sophie?from_search=true&from_srp=true&qid=r7Dgf1tOUW&rank=1	2019	\N	2024-11-23 06:52:00
104	Cantik Itu Luka	9786020312583	https://www.goodreads.com/book/show/1353409.Cantik_itu_Luka?from_search=true&from_srp=true&qid=gWL0J4vVeg&rank=1	2018	\N	2024-11-23 06:53:00
105	1984	9786022917311	https://www.goodreads.com/book/show/61439040-1984?from_search=true&from_srp=true&qid=gKRtgSd9tL&rank=3	2021	\N	2024-11-23 06:54:00
106	The Geography of Genius	9786024412616	https://www.goodreads.com/book/show/25111093-the-geography-of-genius?from_search=true&from_srp=true&qid=pUSBZaxiSG&rank=2	2021	\N	2024-11-23 06:55:00
107	Anak Semua Bangsa	9789799731241	https://www.goodreads.com/book/show/1398044.Anak_Semua_Bangsa?from_search=true&from_srp=true&qid=yHbZS8Yjqr&rank=1	2018	\N	2024-11-23 07:30:00
108	Komunikasi Propaganda	9786029791259	https://onesearch.id/Record/IOS2858.NADAR000000000008378	2011	\N	2024-11-23 07:31:00
109	Immanuel Kant dan Karyanya	9786232056008	https://www.gramedia.com/products/immanuel-kant-dan-karyanya	2021	\N	2024-11-23 07:32:00
110	Kisah Para Diktator	9791683646	https://www.goodreads.com/book/show/3172015-kisah-para-diktator?from_search=true&from_srp=true&qid=mHe6JsXr6B&rank=1	1967	\N	2024-11-23 07:34:00
111	Humanisme dan Sesudahya	9786024813468	https://www.goodreads.com/book/show/15725782-humanisme-dan-sesudahnya?from_search=true&from_srp=true&qid=wbRLnoGTFo&rank=1	2020	\N	2024-11-23 07:37:00
112	Il Principe	9789791683425	https://www.goodreads.com/book/show/6615124-il-principe-di-niccol-machiavelli?from_search=true&from_srp=true&qid=bCDNwWQ1gJ&rank=1	2014	\N	2024-11-23 07:38:00
113	Kritik atas akal budi praktis	9793721537	https://www.goodreads.com/book/show/26813958-kritik-atas-akal-budi-praktis?from_search=true&from_srp=true&qid=rjy98RA1hR&rank=1	1956	\N	2024-11-23 07:39:00
114	Rumah Kaca	9789799731265	https://www.goodreads.com/book/show/1353452.Rumah_Kaca?from_search=true&from_srp=true&qid=HHslHeXuyu&rank=1	2006	\N	2024-11-23 07:40:00
115	Jejak Langkah	9789799731258	https://www.goodreads.com/book/show/1398066.Jejak_Langkah?from_search=true&from_srp=true&qid=MqvzoCjDtl&rank=1	2006	\N	2024-11-23 07:41:00
116	Pedoman Teori Psikoanalisis	9786234004892	https://books.google.co.id/books/about/Pedoman_Teori_Psikoanalisis.html?id=Ke3GEAAAQBAJ&redir_esc=y	2023	\N	2024-11-23 07:55:00
117	Cara menulis Makalah Filsafat	9793237182	https://www.goodreads.com/book/show/26065679-cara-menulis-makalah-filsafat?from_search=true&from_srp=true&qid=rQPIwu24Z0&rank=1	2009	\N	2024-11-23 07:56:00
118	Eksistensialisme dan Humanisme	9799289939	https://www.goodreads.com/book/show/7015724-eksistensialisme-dan-humanisme?from_search=true&from_srp=true&qid=k7XHTkgCM2&rank=1	1960	\N	2024-11-23 07:57:00
119	Jurgen Habermas: Senjakala Modernitas	9786027696938	https://www.gramedia.com/products/jurgen-habermas-senjakala-modernitas-1	2019	\N	2024-11-23 07:59:00
120	Lahirnya Tragedi	9789791685375	https://www.goodreads.com/book/show/7070614-lahirnya-tragedi?from_search=true&from_srp=true&qid=ixlQsRB7wG&rank=1	1993	\N	2024-11-23 08:00:00
121	Pendidikan Kaum Tertindas	9786025792427	https://www.goodreads.com/book/show/1807169.Pendidikan_Kaum_Tertindas?from_search=true&from_srp=true&qid=nCcpmzMrcA&rank=1	2019	\N	2024-11-23 08:01:00
122	Filsuf-Filsuf Besar tentang Manusia	9786020367699	https://www.goodreads.com/book/show/7070596-filsuf-filsuf-besar-tentang-manusia?from_search=true&from_srp=true&qid=8ULH6cU6od&rank=1	2017	\N	2024-11-23 08:05:00
123	Mite Sisifus	0	https://www.goodreads.com/book/show/3313669-mite-sisifus?from_search=true&from_srp=true&qid=f89OjSgUoN&rank=1	1999	\N	2024-11-23 08:07:00
124	Propaganda Manipulasi Opini Masyarakat	9786239606169	https://www.goodreads.com/book/show/60315775-propaganda?from_search=true&from_srp=true&qid=mzl86H227x&rank=1	2005	\N	2024-11-23 08:08:00
125	Bagaimana Saya Menulis	9786237378341	https://www.goodreads.com/book/show/56808821-bagaimana-saya-menulis?from_search=true&from_srp=true&qid=nNBHvjcczq&rank=1	2020	\N	2024-11-23 08:09:00
168	Sungai dari Firdaus	9786024249984	https://www.goodreads.com/book/show/5551765-sungai-dari-firdaus?from_search=true&from_srp=true&qid=Ahq3QaNkDN&rank=1	2005	\N	2024-11-23 12:53:00
126	Persoalan Mendasar Filsafat	9786025149863	https://www.goodreads.com/book/show/31799.The_Problems_of_Philosophy?from_search=true&from_srp=true&qid=ZFbTf4FUY0&rank=4	1997	\N	2024-11-23 08:11:00
127	Subjektivitas dalam filsafat politik alain badiou dan slavoj zizek	9786236699225	https://www.gramedia.com/products/subjektivitas-dalam-filsafat-politik-alain-badiou-dan-slavoj	2021	\N	2024-11-23 08:15:00
128	Mengapa Marx Benar	9786239073916	https://www.goodreads.com/book/show/52593484-mengapa-marx-benar?from_search=true&from_srp=true&qid=fntGBJSgwR&rank=1	2019	\N	2024-11-23 08:16:00
129	Authority and the Individual	9786237378242	https://www.goodreads.com/book/show/662912.Authority_and_the_Individual?from_search=true&from_srp=true&qid=lcUgFJP1bK&rank=1	1985	\N	2024-11-23 08:17:00
130	Bung Karno Nasionalisme dan Demokrasi	0	http://103.78.106.29:8123/inlislite3/opac/detail-opac?id=14368	2005	\N	2024-11-23 08:18:00
131	Pemikiran Karl Marx	9786020331416	https://www.goodreads.com/book/show/3183649-pemikiran-karl-marx?from_search=true&from_srp=true&qid=k2kOrz238h&rank=1	1999	\N	2024-11-23 08:18:00
132	Dari Sinai Sampai Al-Ghazali	9786232935235	https://www.goodreads.com/book/show/59039542-dari-sinai-sampai-al-ghazali?from_search=true&from_srp=true&qid=IHn3FMhgSz&rank=1	2021	\N	2024-11-23 08:19:00
133	Diskursus dan Metode	9786237378273	https://www.goodreads.com/book/show/6147324-diskursus-metode?from_search=true&from_srp=true&qid=Xt9UtatTnx&rank=1	2020	\N	2024-11-23 08:20:00
134	Islam Sontoloyo	9786028635196	https://www.goodreads.com/book/show/7558313-islam-sontoloyo?from_search=true&from_srp=true&qid=Jd8mPZl8Y2&rank=1	2017	\N	2024-11-23 08:22:00
135	Filsafat Barat Kontemporer	9786020309262	https://www.goodreads.com/book/show/4309628-filsafat-barat-kontemporer?from_search=true&from_srp=true&qid=v4rC4KnoZ4&rank=1	2014	\N	2024-11-23 08:24:00
136	The Will to Power	9786025792359	https://www.goodreads.com/book/show/31785.The_Will_to_Power?from_search=true&from_srp=true&qid=FjHDhhy6im&rank=1	2019	\N	2024-11-23 08:25:00
137	Sumbangsih untuk Sains dan Agama	9786236699089	https://www.goodreads.com/book/show/181335459-el-regalo-de-darwin-a-la-ciencia-y-a-la-religi-n?from_search=true&from_srp=true&qid=og8EvFVUGO&rank=1	2020	\N	2024-11-23 08:26:00
138	Kapitalisme Sebuah Pengantar Singkat	9786237378532	https://www.goodreads.com/book/show/74649.Capitalism?from_search=true&from_srp=true&qid=mzYLllAmKd&rank=1	2021	\N	2024-11-23 08:28:00
139	Surplus Pekerja di Kapitalisme Pinggiran	9789791260619	https://www.goodreads.com/book/show/31845767-surplus-pekerja-di-kapitalisme-pinggiran?from_search=true&from_srp=true&qid=TVbkNnerph&rank=1	2016	\N	2024-11-23 08:28:00
140	Filsafat di Indonesia Politik dan Hukum	9786232410657	https://www.gramedia.com/products/filsafat-di-indonesia-politik-dan-hukum	2019	\N	2024-11-23 08:30:00
141	You Tomorrow	9786021201466	https://www.goodreads.com/book/show/17184321-you-tomorrow?from_search=true&from_srp=true&qid=ffykKXAaMS&rank=1	2013	\N	2024-11-23 10:17:00
142	Mudah Belajar Python	9786021514894	https://www.goodreads.com/book/show/51325062-mudah-belajar-python-untuk-aplikasi-desktop-dan-web?from_search=true&from_srp=true&qid=Wnuxyp9M8x&rank=1	2015	\N	2024-11-23 10:18:00
143	Buku Sakti Teknik Hacking	9786020266305	https://www.goodreads.com/book/show/44172819-buku-sakti-teknik-hacking?from_search=true&from_srp=true&qid=h7pqPvOVFb&rank=1	2015	\N	2024-11-23 10:19:00
144	Artificial Intelligence	9786230102936	https://www.gramedia.com/products/artificial-intelligence	2019	\N	2024-11-23 10:21:00
145	Mudah membuat game 3 dimensi unity 3D	9789792946444	https://www.gramedia.com/products/mudah-membuat-game-3-dimensi-menggunakan-unity-3d	2014	\N	2024-11-23 10:22:00
146	Aljabar Linier	9789797695651	https://www.gramedia.com/products/aljabar-linier-edisi-kedua	2013	\N	2024-11-23 10:23:00
147	Machine Learning & Computational Intelligence	9789792958492	https://ebooks.gramedia.com/id/buku/machine-learning-3	2016	\N	2024-11-23 10:25:00
148	Menguasai Angular JS untuk Membuat Website Dinamis	9786026231123	https://www.gramedia.com/products/menguasai-angular-js-untuk-membuat-website-dinamis	2017	\N	2024-11-23 10:26:00
149	Otomatisasi Administrasi Jaringan dengan Script Python	9786020823294	https://www.gramedia.com/products/otomatisasi-administrasi-jaringan-dengan-script-python	2018	\N	2024-11-23 10:29:00
150	Belajar Hacking dari Nol untuk Pemula	9786020258935	https://www.goodreads.com/book/show/107552740-belajar-hacking-dari-nol-untuk-pemula?from_search=true&from_srp=true&qid=3BNa6jcUaS&rank=1	2015	\N	2024-11-23 10:30:00
151	Membuat web profil sekolah + PPDB Online	9786027190511	https://www.penerbitlokomedia.com/produk-53/membuat-web-profil-sekolah--ppdb-online.html	2015	\N	2024-11-23 10:31:00
152	Pengantar Sistem pakar dan Metode	9786023182565	https://www.mitrawacanamedia.com/pengantar-sistem-pakar-dan-metode	2017	\N	2024-11-23 10:39:00
153	Handbook data warehouse	9786026232564	https://www.gramedia.com/products/handbook-data-warehouse-dvd	2018	\N	2024-11-23 10:42:00
154	Belajar Machine Learning Teknik dan Praktek	9786026232670	https://www.gramedia.com/products/belajar-machine-learning-teori-dan-praktik-cd	2018	\N	2024-11-23 10:43:00
155	Swarm Intelligence	9786026232519	https://www.goodreads.com/book/show/40123077-swarm-intelligence-and-bio-inspired-computation?from_search=true&from_srp=true&qid=EJQVpuFuRS&rank=1	2017	\N	2024-11-23 10:45:00
156	Artificial Intelligence	9786021514443	https://www.goodreads.com/book/show/49618262-artificial-intelligence?from_search=true&from_srp=true&qid=zf13HUO2xU&rank=1	2014	\N	2024-11-23 10:47:00
157	Belajar Otodidak Flask	9786026232267	https://www.gramedia.com/products/belajar-otodidak-flask	2017	\N	2024-11-23 10:48:00
158	How to Build a Billion Dollar App	9786237162605	https://www.goodreads.com/book/show/23658963-how-to-build-a-billion-dollar-app?from_search=true&from_srp=true&qid=PzrttViYEx&rank=2	2020	\N	2024-11-23 10:58:00
159	Mudah Belajar Ruby	9786026232335	https://www.gramedia.com/products/mudah-belajar-ruby-cd	2017	\N	2024-11-23 10:59:00
160	Evolutionary Machine Learning	9786237131380	https://www.gramedia.com/products/evolutionary-machine-learning	2020	\N	2024-11-23 11:00:00
161	Basis Data	9786021514870	https://www.goodreads.com/book/show/3501200-basis-data?from_search=true&from_srp=true&qid=Vwu0itcLSY&rank=1	2015	\N	2024-11-23 11:01:00
162	Pemrograman Android dengan Android Studio IDE	9789792960945	https://www.gramedia.com/products/pemrograman-android-dengan-android-studio-ide	2018	\N	2024-11-23 11:02:00
163	Essential Math for Data Science	9781098102937	https://www.goodreads.com/book/show/61174480-essential-math-for-data-science?from_search=true&from_srp=true&qid=VrS623X8OU&rank=1	2022	\N	2024-11-23 11:04:00
164	Deep Learning with TensorFlow 2 and Keras	9781838823412	https://www.goodreads.com/book/show/50214042-deep-learning-with-tensorflow-2-and-keras?from_search=true&from_srp=true&qid=zlxzCXiKxp&rank=1	2019	\N	2024-11-23 11:04:00
165	Data Mining untuk Klasifikasi dan Klasterisasi Data	9786026232366	https://www.gramedia.com/products/data-mining-edisi-revisi	2017	\N	2024-11-23 11:05:00
166	The Analysis of Mind	9786025644801	https://www.goodreads.com/book/show/54025919-the-analysis-of-mind?from_search=true&from_srp=true&qid=HxpNvBVX0d&rank=1	1921	\N	2024-11-23 12:50:00
167	Evolusi	9786024810016	https://www.goodreads.com/book/show/8493685-evolusi?from_search=true&from_srp=true&qid=b0mDI1754f&rank=1	2015	\N	2024-11-23 12:52:00
169	Wabah dan Pandemi	9786024816315	https://www.goodreads.com/book/show/58964807-wabah-dan-pandemi?from_search=true&from_srp=true&qid=N9S2j1aD59&rank=1	2020	\N	2024-11-23 12:54:00
170	Dunia Menurut Fisika	9786024817428	https://www.goodreads.com/book/show/59779147-dunia-menurut-fisika?from_search=true&from_srp=true&qid=hA2QiSNQuu&rank=1	2020	\N	2024-11-23 12:56:00
171	Suka Cita Sains	9786231340764	https://www.goodreads.com/book/show/204788114-sukacita-sains?from_search=true&from_srp=true&qid=FcXk2bILKV&rank=1	2023	\N	2024-11-23 12:58:00
172	The Magic of Reality	9786024816056	https://www.goodreads.com/book/show/11256979-the-magic-of-reality?from_search=true&from_srp=true&qid=aD99GH9KPW&rank=3	2021	\N	2024-11-23 13:00:00
173	Tiga Menit Terakhir	9786024814380	https://www.goodreads.com/book/show/54566338-tiga-menit-terakhir?from_search=true&from_srp=true&qid=C80A6qS8DT&rank=1	2020	\N	2024-11-23 13:02:00
174	Astrofisika untuk Orang Sibuk	9786020616322	https://www.goodreads.com/book/show/42290277-astrofisika-untuk-orang-sibuk?from_search=true&from_srp=true&qid=TBJjFSBIaU&rank=1	2018	\N	2024-11-23 13:03:00
175	Teori Relativitas Enstein Penjelasan Populer untuk Umum	9792458700	https://www.berdikaribook.red/products/384423/berdikari-__-russell%3B-teori-relativitas-einstein-penjelasan-populer-untuk-umum-__-pustaka-pelajar	1960	\N	2024-11-23 13:04:00
176	Relativitas teori khusus dan umum	9786024810979	https://www.goodreads.com/book/show/44101657-relativitas?from_search=true&from_srp=true&qid=cxuoEA88kz&rank=1	2005	\N	2024-11-23 13:05:00
177	The Principles of Beautiful Web Design	9789792958133	https://www.goodreads.com/book/show/258823.The_Principles_of_Beautiful_Web_Design?from_search=true&from_srp=true&qid=FlgTFO0xSh&rank=4	2016	\N	2024-11-23 13:07:00
178	The Divine Matrix	9786026799418	https://www.goodreads.com/book/show/90560.The_Divine_Matrix?from_search=true&from_srp=true&qid=dTW9WjyZoq&rank=4	2007	\N	2024-11-23 13:08:00
179	The Selfish Gene	9786024247287	https://www.goodreads.com/book/show/61535.The_Selfish_Gene?from_search=true&from_srp=true&qid=gOkfWA8uIb&rank=5	2017	\N	2024-11-23 13:12:00
180	The Demon-Haunted World	9786024810436	https://www.goodreads.com/book/show/17349.The_Demon_Haunted_World?from_search=true&from_srp=true&qid=SEGFDlNrhY&rank=4	2018	\N	2024-11-23 13:13:00
181	The Origin of Species	9786237586869	https://www.goodreads.com/book/show/32331601-the-origin-of-species?from_search=true&from_srp=true&qid=44W9WsqZoW&rank=1	2022	\N	2024-11-23 13:14:00
182	Yang Jauh Tersembunyi	9786024816483	https://www.goodreads.com/book/show/59065670-yang-jauh-tersembunyi?from_search=true&from_srp=true&qid=FoH9nxolIS&rank=1	2021	\N	2024-11-23 13:16:00
183	Matematika Diskrit dan Aplikasinya pada Ilmu Komputer	9789792907612	https://www.gramedia.com/products/matematika-diskrit-dan-aplikasinya-pada-ilmu-komputer200153	2002	\N	2024-11-23 13:17:00
184	Fisika Nuklir 	9792458611	https://www.goodreads.com/book/show/1723657.Fisika_Nuklir_dalam_Telaah_Semi_Klasik_Kuantum?from_search=true&from_srp=true&qid=Jgl5QHAtJx&rank=1	2006	\N	2024-11-23 13:18:00
185	Why? 3D Printing	9786020495767	https://www.goodreads.com/book/show/104576094-why-way-3d-printing?from_search=true&from_srp=true&qid=OfMvy9jlub&rank=2	2017	\N	2024-11-23 13:22:00
186	Matematika untuk Semua	9786022982791	https://www.gramedia.com/products/berpikir-matematis-matematika-untuk-semua	2015	\N	2024-11-23 13:23:00
187	Metode Penelitian Terpadu Sistem Informasi	9789792961133	https://www.gramedia.com/products/metode-penelitian-terpadu-sistem-informasi-pemodelan-teoret	2018	\N	2024-11-23 13:26:00
188	Kosmos	9786024242244	https://www.goodreads.com/book/show/6782803-kosmos?from_search=true&from_srp=true&qid=CHtursvd21&rank=1	2016	\N	2024-11-23 13:27:00
189	Sapiens	9786024244163	https://www.goodreads.com/book/show/23692271-sapiens?ref=nav_sb_ss_1_7	2017	\N	2024-11-23 13:28:00
191	Jagat Digital	9786024812126	https://www.goodreads.com/book/show/53096829-jagat-digital?from_search=true&from_srp=true&qid=tXtILMcP6l&rank=1	2019	\N	2024-11-23 13:30:00
192	Sang Dionysus	9786231893840	https://www.gramedia.com/products/sang-dionysus	2024	\N	2024-11-23 15:10:00
193	Anatomi Fisiologi Manusia	9786231648754	https://www.gramedia.com/products/anatomi-fisiologi-manusia-3	2024	\N	2024-11-23 15:13:00
194	Samurai X Hokkaido Arc 1	9786230036965	https://www.goodreads.com/book/show/75464640-samurai-x-hokkaido-arc-vol-1?from_search=true&from_srp=true&qid=78djdisqtT&rank=1	2016	\N	2024-11-23 15:15:00
195	Mahadata	9786024816001	https://www.goodreads.com/book/show/58290173-mahadata?from_search=true&from_srp=true&qid=NIF0jbEZqW&rank=1	2021	\N	2024-11-23 15:17:00
196	Kartun Kimia	9786024813338	https://www.goodreads.com/book/show/1725177.Kartun_Kimia?from_search=true&from_srp=true&qid=v1CjZ6eCDq&rank=1	2005	\N	2024-11-23 15:18:00
197	Mengapa saya menulis	9786237543862	https://www.goodreads.com/book/show/195879153-mengapa-saya-menulis?from_search=true&from_srp=true&qid=KigNmhqXCQ&rank=1	2023	\N	2024-11-23 15:20:00
198	Konspirasi	9786238476145	https://www.goodreads.com/book/show/221829100-konspirasi?from_search=true&from_srp=true&qid=3mFTSHaZ9i&rank=1	2024	\N	2024-11-23 15:21:00
199	Romeo dan Juliet	9786231645401	https://www.goodreads.com/book/show/52586270-romeo-dan-juliet?from_search=true&from_srp=true&qid=ghfrKZy7LL&rank=1	2024	\N	2024-11-23 15:23:00
200	Mob Psycho 100 : 1	9786230015786	https://www.goodreads.com/book/show/35335209-mob-psycho-100-1?from_search=true&from_srp=true&qid=v6WXFcIENs&rank=1	2020	\N	2024-11-23 15:24:00
201	Kitab Lima Unsur	9786238108633	https://www.gramedia.com/products/kitab-lima-unsur	2004	\N	2024-11-23 15:25:00
202	Rancang Agung	9789792264395	https://www.goodreads.com/book/show/10241625-the-grand-design---rancang-agung?from_search=true&from_srp=true&qid=tpwSs6IDgH&rank=1	2010	\N	2024-11-23 15:26:00
203	Sejarah Nusantara	9786231644923	https://www.gramedia.com/products/sejarah-nusantara-the-malay-archipelago-perjalanan-penjhttps://www.gramedia.com/products/sejarah-nusantara-the-malay-archipelago-perjalanan-penj	2024	\N	2024-11-23 15:27:00
204	English Classics: Journey to the centre of the earth	9786020375281	https://www.goodreads.com/book/show/4347293-journey-to-the-centre-of-the-earth-childrens-illustrated-classics?from_search=true&from_srp=true&qid=BOuoJL3lA1&rank=1	2017	\N	2024-11-23 15:28:00
205	Madilog	9786025792403	https://www.goodreads.com/book/show/1607269.Madilog?from_search=true&from_srp=true&qid=XSNJfscq6s&rank=1	2019	\N	2024-11-23 15:31:00
206	Etika Protestan dan Spirit Kapitalisme	9792458281	https://www.goodreads.com/book/show/74176.The_Protestant_Ethic_and_the_Spirit_of_Capitalism?from_search=true&from_srp=true&qid=UPznvryxNt&rank=2	1992	\N	2024-11-23 15:34:00
207	Mahakurawa 2: Kaliyuga	9786026799470	https://www.goodreads.com/book/show/51893827-mahakurawa-2?from_search=true&from_srp=true&qid=4PYHeXzugP&rank=1	2015	\N	2024-11-23 15:39:00
208	kakawin nagara kartagama	9786025792946	https://www.goodreads.com/book/show/58284876-kakawin-nagarakertagama?from_search=true&from_srp=true&qid=8pPf6Yv7xh&rank=3	2015	\N	2024-11-23 15:41:00
209	Homo Deus	9786026577337	https://www.goodreads.com/book/show/31138556-homo-deus?from_search=true&from_srp=true&qid=Vzmk0b8fVV&rank=1	2018	\N	2024-11-23 15:42:00
210	Menuju Merdeka 100 Persen	9791685126	https://www.goodreads.com/book/show/36110733-tan-malaka?from_search=true&from_srp=true&qid=UEVjiRvkyF&rank=2	2017	\N	2024-11-23 15:44:00
211	Pemikiran Kritis Kontemporer	9789797698546	https://www.gramedia.com/products/pemikiran-kritis-kontemporer	2014	\N	2024-11-23 15:53:00
212	Fisafat Modern Barat	9786027996747	https://www.gramedia.com/products/filsafat-modern-barat	2018	\N	2024-11-23 15:54:00
213	Nusantara: sejarah Indonesia	9786026208064	https://www.goodreads.com/book/show/3273735-nusantara?from_search=true&from_srp=true&qid=VwgW27irFB&rank=1	2018	\N	2024-11-23 15:55:00
214	Dasar Dasar Ilmu Politik	9789792234947	https://www.goodreads.com/book/show/6390570-dasar-dasar-ilmu-politik?from_search=true&from_srp=true&qid=Dew2HAEG1I&rank=1	2008	\N	2024-11-23 15:56:00
215	Zarathustra	9791684642	https://www.goodreads.com/book/show/51893.Thus_Spoke_Zarathustra?from_search=true&from_srp=true&qid=fnFnq9XUmS&rank=1	2005	\N	2024-11-23 15:57:00
216	Untuk Negeriku 1 Bukittinggi-Rotterdam Lewat Betawi	9786024124229	https://www.goodreads.com/book/show/11228295-bukittinggi---rotterdam-lewat-betawi?from_search=true&from_srp=true&qid=DTuRUeCdcA&rank=1	2011	\N	2024-11-23 15:59:00
217	Untuk Negeriku 2 Berjuang dan Dibuang	9786024124229	https://www.goodreads.com/book/show/11236486-berjuang-dan-dibuang?from_search=true&from_srp=true&qid=akOZpkXgCj&rank=1	2011	\N	2024-11-23 16:00:00
218	Untuk Negeriku 3 Menuju Gerbang Kemerdekaan	9786024124229	https://www.goodreads.com/book/show/11303407-menuju-gerbang-kemerdekaan?from_search=true&from_srp=true&qid=LUtCmmam9P&rank=1	2011	\N	2024-11-23 16:01:00
219	Introduction to Metaphysics	9786239926588	https://www.goodreads.com/book/show/92402.Introduction_to_Metaphysics?from_search=true&from_srp=true&qid=wwhK1ujj2D&rank=1	2023	\N	2024-11-23 16:02:00
220	Filsafat Kebahagiaan	9786024413323	https://www.goodreads.com/book/show/203902146-filsafat-kebahagiaan?from_search=true&from_srp=true&qid=dXR9ERNs4Q&rank=1	2023	\N	2024-11-23 16:03:00
221	Sebelum Filsafat	9786027462533	https://www.goodreads.com/book/show/51809335-sebelum-filsafat?from_search=true&from_srp=true&qid=GjL687mQwM&rank=1	2013	\N	2024-11-23 16:04:00
222	Alkimia Kebahagiaan	9786238476053	https://www.goodreads.com/book/show/208964223-alkimia-kebahagiaan?from_search=true&from_srp=true&qid=qdaQG22dUA&rank=1	2024	\N	2024-11-23 16:05:00
223	Etika Politik	9786020334707	https://www.goodreads.com/book/show/1604607.Etika_Politik?from_search=true&from_srp=true&qid=ksIcF2JBwi&rank=1	1987	\N	2024-11-23 16:06:00
224	Buddha 4 Hutan Uruwela	9786231340511	https://www.goodreads.com/book/show/1739755.Buddha_4?from_search=true&from_srp=true&qid=hyeug2eX3N&rank=1	2024	\N	2024-11-23 16:11:00
225	Buddha 3 Dewadatta	9786231340504	https://www.goodreads.com/book/show/1739696.Buddha_3?from_search=true&from_srp=true&qid=GuvkpqwV7q&rank=1	2024	\N	2024-11-23 16:11:00
226	Buddha 2 Empat Perjumpaan	9786231340498	https://www.goodreads.com/book/show/1739624.Buddha_2?from_search=true&from_srp=true&qid=Stuhw0Q3MC&rank=1	2024	\N	2024-11-23 16:12:00
227	Buddha 1 Kapilawastu	9786231340481	https://www.goodreads.com/book/show/1739593.Buddha_1?from_search=true&from_srp=true&qid=2J5QrLyDWE&rank=1	2024	\N	2024-11-23 16:13:00
229	Dari Siwaisme Jawa ke Agama Hindu Bali	9786024816681	https://www.goodreads.com/book/show/60308635-dari-siwaisme-jawa-ke-agama-hindu-bali?from_search=true&from_srp=true&qid=WpXuNkwDco&rank=1	2021	\N	2024-11-23 16:15:00
230	Filsafat Sejarah	9799483212	https://www.goodreads.com/book/show/25241.The_Philosophy_of_History?from_search=true&from_srp=true&qid=BiJjN2V36E&rank=1	2001	\N	2024-11-23 16:16:00
231	Sirrul Asrar	9786237327318	https://www.goodreads.com/book/show/25835224-the-secret-of-secrets?from_search=true&from_srp=true&qid=gqBxsdSHfL&rank=1	2019	\N	2024-11-23 16:17:00
232	Politik	9791685401	https://www.goodreads.com/book/show/9788457-politika-aristoteles-politik-griechisch-und-deutsch?from_search=true&from_srp=true&qid=0eREb2bxZs&rank=2	2017	\N	2024-11-23 16:18:00
233	Narnia:The Magician Nephew	9786020336398	https://www.goodreads.com/book/show/133673801-the-chronicles-of-narnia?from_search=true&from_srp=true&qid=DkGGAdN6Qb&rank=1	2024	\N	2024-11-23 16:22:00
234	Narnia:The Lion, The Witch and The Wardrobe	9786020644547	https://www.goodreads.com/book/show/132080146-the-lion-the-witch-and-the-wardrobe?from_search=true&from_srp=true&qid=JBqEaPs8vU&rank=1	2024	\N	2024-11-23 16:23:00
235	Narnia: The Horse and his Boy	9786020336411	https://www.goodreads.com/book/show/84119.The_Horse_and_His_Boy?from_search=true&from_srp=true&qid=8USevsjJgq&rank=1	2024	\N	2024-11-23 16:24:00
236	Narnia:Prince Caspian	9786020336435	https://www.goodreads.com/book/show/121749.Prince_Caspian?from_search=true&from_srp=true&qid=SHou76oYCT&rank=1	2024	\N	2024-11-23 16:25:00
237	Narnia:The Voyage of The Dawn Threader	9786020336510	https://www.goodreads.com/book/show/140225.The_Voyage_of_the_Dawn_Treader?from_search=true&from_srp=true&qid=svB8ZLkbPA&rank=1	2024	\N	2024-11-23 16:26:00
238	Narnia:The Silver Chair	9786020336459	https://www.goodreads.com/book/show/65641.The_Silver_Chair?from_search=true&from_srp=true&qid=GSalqBokT0&rank=2	2024	\N	2024-11-23 16:27:00
239	Narnia:The Last Battle	9786020336534	https://www.goodreads.com/book/show/84369.The_Last_Battle?from_search=true&from_srp=true&qid=QWCJqdRVO6&rank=1	2024	\N	2024-11-23 16:28:00
241	Monster Vol. 2	9786230311123	https://www.goodreads.com/book/show/7477710-naoki-urasawa-s-monster-volume-2?from_search=true&from_srp=true&qid=oS9aSJoCiA&rank=2	2023	\N	2024-11-23 16:30:00
242	Monster Vol. 1	9786230310508	https://www.goodreads.com/book/show/6609784-naoki-urasawa-s-monster-volume-1?from_search=true&from_srp=true&qid=DLILJK9JrW&rank=1	2023	\N	2024-11-23 16:30:00
243	Penenun, Pendongeng dan Kain Brokat Ajaib	9786230407079	https://www.goodreads.com/book/show/60805602-penenun-pendongeng-dan-kain-brokat-ajaib?from_search=true&from_srp=true&qid=vs5W9rLxF6&rank=1	2022	\N	2024-11-23 16:34:00
244	Si Hitam dan Si Merah	9786230407062	https://www.goodreads.com/book/show/60805589-si-hitam-dan-si-merah?from_search=true&from_srp=true&qid=VBHUrfCgKd&rank=1	2022	\N	2024-11-23 16:35:00
246	Uzumaki	9786230307003	https://www.goodreads.com/book/show/17837762-uzumaki	2010	\N	2024-11-24 13:48:00
247	Brutus: Kisah sang pengkhianat	9786238392971	https://www.goodreads.com/book/show/34746513-brutus?from_search=true&from_srp=true&qid=67Ws6vYKCe&rank=4	2024	\N	2024-12-16 07:39:00
248	Darmagandhul	9786238392988	https://www.goodreads.com/book/show/28109889-darmagandhul?from_search=true&from_srp=true&qid=4mdDYktfxN&rank=2	2024	\N	2024-12-16 17:17:00
249	The Alchemist	9786020656069	https://www.goodreads.com/book/show/18144590-the-alchemist?ref=nav_sb_ss_1_13	2005	\N	2024-12-26 05:02:00
250	 One Piece Chapter 1	978792039504	https://www.goodreads.com/book/show/1237398.One_Piece_Volume_1?from_search=true&from_srp=true&qid=T4l7Fyjwhn&rank=1	2002	206	2025-01-08 16:58:27.699
251	 One Piece Chapter 2	97897920400005	https://www.goodreads.com/book/show/364956.One_Piece_Volume_2?from_search=true&from_srp=true&qid=6uC2igDPMc&rank=1	2002	205	2025-01-08 16:59:41.627
252	 One Piece Chapter 3	9789792041224	https://www.goodreads.com/book/show/364957.One_Piece_Volume_3?from_search=true&from_srp=true&qid=jDM62UDmOq&rank=1	2002	205	2025-01-08 17:00:37.283
253	Gyo vol.1 & vol.2	9786230309731	https://www.goodreads.com/book/show/22716175-gyo?from_search=true&from_srp=true&qid=Nj1ul11fRt&rank=1	2024	377	2025-01-08 17:05:01.751
254	Metamorfosis	9786237543602	https://www.goodreads.com/book/show/75309771-la-metamorfosis?from_search=true&from_srp=true&qid=NE4t2BITff&rank=3	2024	84	2025-01-08 17:07:06.038
255	Naruto Bind Up Edition 01	9786230054952	https://www.goodreads.com/book/show/205127614-naruto-bind-up-edition-01?from_search=true&from_srp=true&qid=fXrmjAq1ky&rank=1	2024	385	2025-01-08 17:09:35.436
256	Student Hidjo	97862237586616	https://www.goodreads.com/book/show/1815215.Student_Hidjo?from_search=true&from_srp=true&qid=lLnq2WqOA3&rank=1	2022	186	2025-01-09 08:22:32.145
257	Buddha 5 Taman Rusa	9786231340528	https://www.goodreads.com/book/show/1739765.Buddha_5?from_search=true&from_srp=true&qid=RPRVQa5UHF&rank=1	2024	352	2025-01-09 15:17:08.344
258	Surat untuk ayah	9786025084812	https://www.goodreads.com/book/show/36684919-surat-untuk-ayah?from_search=true&from_srp=true&qid=Lwbq2JO4iV&rank=1	2024	86	2025-01-10 20:24:45.113
259	Candide	9786238476190	https://www.goodreads.com/book/show/19380.Candide?from_search=true&from_srp=true&qid=IuYEB1wMOb&rank=1	2024	153	2025-01-12 07:32:58.115
260	Putusan	9786238476152	https://www.goodreads.com/book/show/221828942-putusan?from_search=true&from_srp=true&qid=M1TUr61a4h&rank=1	2024	142	2025-01-13 04:36:56.31
261	Kartun Lingkungan	97860248115363	https://www.goodreads.com/book/show/1723108.Kartun_Lingkungan?from_search=true&from_srp=true&qid=QdaSaINKNK&rank=1	2024	230	2025-01-15 06:41:04.016
262	Percy Jackson 1: The Lighning thief	9786232422537	https://www.goodreads.com/book/show/123675190-the-lightning-thief?from_search=true&from_srp=true&qid=HDtExVtWON&rank=4	2004	344	2025-01-15 20:44:23.794
263	Sakamoto Days 1	9786230037313	https://www.goodreads.com/book/show/55980428-sakamoto-days-1?ac=1&from_search=true&qid=ujYxxc0YPW&rank=1	2024	188	2025-01-18 18:59:43.177
264	Siddharta	9786237543879	https://www.goodreads.com/book/show/208509126-siddharta?from_search=true&from_srp=true&qid=q8ZWXGsodR&rank=1	2024	162	2025-01-19 11:34:37.359
265	Naruto Bind Up Edition 02	9786230054969	https://www.goodreads.com/book/show/208430346-naruto-bind-up-edition-02?from_search=true&from_srp=true&qid=EmuWqZpmpw&rank=1	2024	377	2025-01-21 11:25:47.722
266	Dune 1	9786231340061	https://www.goodreads.com/book/show/44767458-dune?from_search=true&from_srp=true&qid=3i2j50lbFO&rank=2	2023	455	2025-01-22 17:03:55.301
267	Hiper-Kapitalisme	9786231343109	https://www.goodreads.com/book/show/54315378-hiper-kapitalizm?from_search=true&from_srp=true&qid=AMC6jKGRTy&rank=1	2024	231	2025-01-24 17:53:08.293
268	Sakamoto Days 2	9786230046414	https://www.goodreads.com/book/show/57557794-sakamoto-days-2?from_search=true&from_srp=true&qid=PKuOidCHyS&rank=1	2024	190	2025-01-26 10:09:34.283
269	Le Petit Prince	9786020323411	https://www.goodreads.com/book/show/28320660-le-petit-prince?from_search=true&from_srp=true&qid=iivsBecsq6&rank=2	2011	118	2025-01-27 11:41:16.363
270	Sakamoto Days 03	9786230047510	https://www.goodreads.com/book/show/78942103-sakamoto-days-vol-03?from_search=true&from_srp=true&qid=l1CJTEFn3u&rank=1	2024	186	2025-01-27 11:43:18.776
271	Pluto 01	9786230314476	https://www.goodreads.com/book/show/4000324-pluto-01?from_search=true&from_srp=true&qid=6S7TxAsCsc&rank=3	2024	200	2025-01-28 10:14:39.643
272	Sakamoto Days 04	9786230048562	https://www.goodreads.com/book/show/62328717-sakamoto-days---tome-04?from_search=true&from_srp=true&qid=ijidEF6FeH&rank=1	2024	195	2025-01-28 10:16:38.996
273	Sakamoto Days 05	978623004906	https://www.goodreads.com/book/show/170176600-sakamoto-days-vol-05?from_search=true&from_srp=true&qid=1nnABqPDF7&rank=1	2024	187	2025-01-28 10:17:37.642
274	Death Note Pocket Edition 01	9786230309557	https://www.goodreads.com/book/show/3237493-death-note-01?from_search=true&from_srp=true&qid=DxoAD56n1p&rank=1	2024	350	2025-02-05 15:54:10.279
275	Lelaki Tua dan Laut	9786237543428	https://www.goodreads.com/book/show/6493574-lelaki-tua-dan-laut?from_search=true&from_srp=true&qid=4jLf5rlooT&rank=1	2023	105	2025-02-05 15:55:39.991
276	Tao Te Ching	9786238108688	https://www.goodreads.com/book/show/19277381-the-tao-te-ching-of-lao-tzu?from_search=true&from_srp=true&qid=1g5tChZAXq&rank=1	2024	167	2025-02-05 15:56:48.076
277	Monster Volume 3	9786230312043	https://www.goodreads.com/book/show/7478330-naoki-urasawa-s-monster-volume-3?from_search=true&from_srp=true&qid=CnQXTGzR37&rank=1	2024	450	2025-02-05 15:58:35.077
278	Kumpulan Humor Nasruddin Hodja	9786027328495	https://www.goodreads.com/book/show/36342984-kumpulan-humor?from_search=true&from_srp=true&qid=r01maLRNLK&rank=1	2024	220	2025-02-08 15:17:26.392
279	Sakamoto Days 6	9786230050749	https://www.goodreads.com/book/show/59962187-sakamoto-days-6?from_search=true&from_srp=true&qid=SVLJ0oJ02s&rank=1	2023	193	2025-02-08 15:19:20.587
280	Percy Jackson 2 The Sea of Monsters	9786232422544	https://www.goodreads.com/book/show/40727118-the-sea-of-monsters?from_search=true&from_srp=true&qid=G0RbUYXHup&rank=1	2023	268	2025-02-10 10:16:53.289
281	sakamoto days 07	9786230055805	https://www.goodreads.com/book/show/120561373-sakamoto-days---tome-07?from_search=true&from_srp=true&qid=25B0G1GHKg&rank=1	2024	185	2025-02-12 10:16:07.682
282	Sakamoto Days 08	9786230056833	https://www.goodreads.com/book/show/125536698-sakamoto-days---tome-08?from_search=true&from_srp=true&qid=gNib29lQQY&rank=1	2024	190	2025-02-15 18:15:59.418
283	Catatan dari Bawah Tanah	9786237543749	https://www.goodreads.com/book/show/5502895-catatan-dari-bawah-tanah?from_search=true&from_srp=true&qid=a68gJLogse&rank=1	2024	185	2025-02-16 04:46:16.069
284	Mythology	97866232201613	https://www.goodreads.com/book/show/23522.Mythology?from_search=true&from_srp=true&qid=kRWdWqv5f2&rank=2	2017	484	2025-02-18 04:41:58.92
285	Naruto Bind Up Edition 03	9786230056444	https://www.goodreads.com/book/show/209759573-naruto-bind-up-edition-03?from_search=true&from_srp=true&qid=rHCCCnDBwj&rank=1	2024	355	2025-02-20 15:38:12.856
286	Sang Penjudi	9786237543718	https://www.goodreads.com/book/show/123014503-sang-penjudi?from_search=true&from_srp=true&qid=HwI4c3iu4C&rank=1	2024	245	2025-02-22 18:24:27.76
287	Versi Ringkas 48 Laws of Power	9786236083857	https://www.goodreads.com/book/show/216950278-48-laws-of-power-versi-ringkas?from_search=true&from_srp=true&qid=eF3vD0CcQl&rank=1	2024	276	2025-02-23 04:41:55.744
288	Veronika memutuskan mati	9786020385273	https://www.goodreads.com/book/show/3366169-veronika-memutuskan-mati?from_search=true&from_srp=true&qid=k8vjCMYAZi&rank=1	1998	272	2025-03-01 10:34:25.787
289	Death Note 2	9786230310041	https://www.goodreads.com/book/show/13619.Death_Note_Vol_2?from_search=true&from_srp=true&qid=y1uhGzMTs1&rank=1	2024	339	2025-03-02 10:03:02.908
290	Dune 02	9786231340269	https://www.goodreads.com/book/show/130827852-chapter-house-dune-by-frank-herbert?from_search=true&from_srp=true&qid=L6qTGF4ig3&rank=2	2023	430	2025-03-03 10:19:54.724
291	Sakamoto Days 09	9786230057977	https://www.goodreads.com/book/show/156022798-sakamoto-days---tome-09?from_search=true&from_srp=true&qid=SvRcEefuFX&rank=1	2024	195	2025-03-03 14:37:14.213
292	Penyamun dalam rimba	9786236421918	https://www.goodreads.com/book/show/10256033-penyamun-dalam-rimba?from_search=true&from_srp=true&qid=K6dCR1Fgjm&rank=1	1972	124	2025-03-03 14:38:27.957
293	Sakamoto Days 10	9786230059087	https://www.goodreads.com/book/show/63002195-sakamoto-days-10?from_search=true&from_srp=true&qid=w7WKmcDyZT&rank=1	2024	150	2025-03-08 19:30:52.3
294	Naruto Bind Up Edition 04	9786230057045	https://www.goodreads.com/book/show/210636617-naruto-bind-up-edition-04?from_search=true&from_srp=true&qid=9o96UwE3qg&rank=1	2024	360	2025-03-08 19:31:46.778
295	Sakamoto Days 11	9786230060113	https://www.goodreads.com/book/show/63294555-sakamoto-days-11?from_search=true&from_srp=true&qid=4MiX9bCeci&rank=1	2024	190	2025-03-12 15:03:33.968
296	Sakamoto Days 12	9786230061172	https://www.goodreads.com/book/show/124938191-sakamoto-days-12?from_search=true&from_srp=true&qid=HEaDM5iVtl&rank=2	2024	190	2025-03-12 15:04:10.936
297	Sakamoto Days 13	9786230068164	https://www.goodreads.com/book/show/198704052-sakamoto-days-13?from_search=true&from_srp=true&qid=CIWlBglkKp&rank=1	2025	190	2025-03-12 15:05:29.794
298	Jalan tak ada ujung	9789794619803	https://www.goodreads.com/book/show/1910412.Jalan_Tak_Ada_Ujung?from_search=true&from_srp=true&qid=9HaYMGrOYI&rank=1	2016	165	2025-03-12 15:06:25.925
299	Buddha 06 Ananda	9786231340535	https://www.goodreads.com/book/show/123356850-ananda-buddha-book-6?from_search=true&from_srp=true&qid=v66qpOysD5&rank=1	2024	362	2025-03-12 18:31:06.852
300	Naruto Bind Up Edition 05	9786230057816	https://www.goodreads.com/book/show/212344651-naruto-bind-up-edition-05?from_search=true&from_srp=true&qid=4H2nzU6Ljt&rank=5	2024	350	2025-03-13 09:57:16.691
301	Death Note 03	9786230311093	https://www.goodreads.com/book/show/199310942-death-note-black-edition-03?from_search=true&from_srp=true&qid=2pKawZ9MIg&rank=2	2024	390	2025-03-15 08:00:34.336
302	Death Note 04	9786230312038	https://www.goodreads.com/book/show/2671839-death-note-04?from_search=true&from_srp=true&qid=EalrfWrlbS&rank=1	2024	400	2025-03-15 08:03:10.58
303	Death Note 05	9786230312496	https://www.goodreads.com/book/show/5998606-death-note-05?from_search=true&from_srp=true&qid=hrkL4xCpTp&rank=1	2024	400	2025-03-15 08:04:35.253
304	Sakamoto Days 14	9786230069000	https://www.goodreads.com/book/show/201296872-sakamoto-days-14?from_search=true&from_srp=true&qid=oaIWOwIXSg&rank=1	2025	178	2025-03-15 17:12:32.015
305	Death Note 6	9786230313578	https://www.goodreads.com/book/show/50204647-death-note-6?from_search=true&from_srp=true&qid=qz2uHKLxwo&rank=4	2024	400	2025-03-15 17:13:30.705
306	Death Note 07	9786230314544	https://www.goodreads.com/book/show/38275355-death-note---black-edition-volume-07?from_search=true&from_srp=true&qid=i77tFFrpio&rank=4	2024	352	2025-03-15 19:22:03.303
307	Buddha 7 Pangeran Ajatasattu	9786231340542	https://www.goodreads.com/book/show/160068.Buddha_Vol_7?from_search=true&from_srp=true&qid=YjrO0rz9uP&rank=2	2024	420	2025-03-16 19:59:48.158
308	Naruto Bind Up Edition 06	9786230058080	https://www.goodreads.com/book/show/213980305-naruto-bind-up-edition-06?from_search=true&from_srp=true&qid=IV2OmMKTT0&rank=1	2024	390	2025-03-17 19:08:15.384
309	Naruto Bind Up Edition 07	9786230058462	https://www.goodreads.com/book/show/216356522-naruto-bind-up-edition-07?from_search=true&from_srp=true&qid=9iDIeMIhty&rank=1	2024	355	2025-03-18 09:59:43.415
310	Naruto Bind Up Edition 08	9786230059063	https://www.goodreads.com/book/show/217312432-naruto-bind-up-edition-08?from_search=true&from_srp=true&qid=HVJbilrDGF&rank=1	2024	355	2025-03-18 10:00:22.539
311	Naruto Bind Up Edition 09	9786230059643	https://www.goodreads.com/book/show/218425086-naruto-bind-up-edition-09?from_search=true&from_srp=true&qid=YJuzsSaYsZ&rank=1	2024	355	2025-03-18 10:01:05.601
312	Percy Jackson 3 The titan curse	9786232422551	https://www.goodreads.com/book/show/561456.The_Titan_s_Curse?from_search=true&from_srp=true&qid=dIpKdpT67F&rank=1	2007	304	2025-03-18 16:29:51.161
313	Monster Vol. 4	9786230312458	https://www.goodreads.com/book/show/7347940-naoki-urasawa-s-monster-volume-4?from_search=true&from_srp=true&qid=ECWzGJplyl&rank=1	2025	400	2025-03-19 09:02:30.915
314	20th Century Boys Complete Edition Volume 1	9786230068454	https://www.goodreads.com/book/show/226830599-20th-century-boys-the-complete-edition-01?from_search=true&from_srp=true&qid=Not7dRP7x2&rank=1	2025	410	2025-03-19 09:03:34.542
315	Naruto Bind Up Edition 10	9786230060069	https://www.goodreads.com/book/show/220343453-naruto-bind-up-edition-10?from_search=true&from_srp=true&qid=A8tuk4NQf7&rank=1	2024	360	2025-03-20 16:49:43.442
316	Naruto Bind Up Edition 11	9786230060663	https://www.goodreads.com/book/show/221294411-naruto-bind-up-edition-11?from_search=true&from_srp=true&qid=Wp4psa7jP8&rank=1	2024	370	2025-03-20 16:50:19.433
317	Naruto Bind Up Edition 12	9786230061318	https://www.goodreads.com/book/show/222355245-naruto-bind-up-edition-12?from_search=true&from_srp=true&qid=GGFDyF0nqu&rank=1	2024	360	2025-03-20 16:50:58.196
318	Naruto Bind Up Edition 13	9786230067860	https://www.goodreads.com/book/show/223121338-naruto-bind-up-edition-13?from_search=true&from_srp=true&qid=b2x62ubXVB&rank=1	2024	350	2025-03-20 18:30:28.874
319	Malam-malam putih	9786027328488	https://www.goodreads.com/book/show/34697857-malam-putih?from_search=true&from_srp=true&qid=mroSlQ9fet&rank=1	2025	250	2025-03-22 12:37:58.96
320	Naruto Bind Up Edition 14	9786230068195	https://www.goodreads.com/book/show/228496880-naruto-bind-up-edition-14?from_search=true&from_srp=true&qid=OQgPsHfY90&rank=1	2024	370	2025-03-23 17:21:51.02
321	Seporsi mie ayam sebelum mati	9786020531328	https://www.goodreads.com/book/show/223441713-seporsi-mie-ayam-sebelum-mati?from_search=true&from_srp=true&qid=5IL9RQjbpz&rank=1	2025	208	2025-03-26 03:37:34.136
322	Naruto Bind Up Edition 15	9786230068720	https://www.goodreads.com/book/show/220343453-naruto-bind-up-edition-10?from_search=true&from_srp=true&qid=nf4G5w7lFI&rank=1	2025	370	2025-03-26 03:38:20.055
323	Naruto Bind Up Edition 16	9786230069130	https://www.goodreads.com/book/show/29499024-naruto-3-in-1-edition-vol-16?from_search=true&from_srp=true&qid=V6ppTyl9gV&rank=4	2025	370	2025-03-27 05:40:44.175
324	Monster Vol.5 	9786230313035	https://www.goodreads.com/book/show/8072727-naoki-urasawa-s-monster-volume-5?from_search=true&from_srp=true&qid=CRSh78KYJF&rank=1	2025	400	2025-03-27 19:46:29.664
325	Buku Cerita Perempuan	9786237543305	https://www.goodreads.com/book/show/58261259-buku-cerita-perempuan?from_search=true&from_srp=true&qid=ppBO7jx4ds&rank=1	2021	158	2025-03-29 02:31:52.47
326	Percy Jackson #4 The battle of labyrinth	9786232422568	https://www.goodreads.com/book/show/8130423-the-battle-of-the-labyrinth?from_search=true&from_srp=true&qid=8phSm8DZl9&rank=1	2022	336	2025-03-29 12:59:41.297
327	Menuju Republik Indonesia	4862089028735	https://www.goodreads.com/book/show/8857716-naar-de-republiek-indonesia?from_search=true&from_srp=true&qid=D6VNWzxSnt&rank=1	2023	75	2025-03-30 17:29:20.297
328	Laut Bercerita	9786024246945	https://www.goodreads.com/book/show/36393774-laut-bercerita?from_search=true&from_srp=true&qid=SH4abZD24M&rank=1	2017	375	2025-04-02 15:12:40.172
329	Percy Jackson #5 The last olympian	9786232422575	https://www.goodreads.com/book/show/4556058-the-last-olympian?from_search=true&from_srp=true&qid=Ng1fG5Mnpc&rank=1	2009	355	2025-04-03 05:17:17.383
330	PTSD Radio Volume 1	9786230069093	https://www.goodreads.com/book/show/60543010-ptsd-radio-1-vol-1-2?from_search=true&from_srp=true&qid=h7FpweotyC&rank=2	2025	318	2025-04-04 15:56:16.121
331	Kita Pergi Hari Ini	9786231342690	https://www.goodreads.com/book/show/59345269-kita-pergi-hari-ini?from_search=true&from_srp=true&qid=dOboPmWUAz&rank=1	2025	195	2025-04-09 03:28:12.949
332	Kumpulan Cerita Rakyat Asia Tenggara	9786237543114	https://www.goodreads.com/book/show/54555561-kumpulan-cerita-rakyat-asia-tenggara?from_search=true&from_srp=true&qid=ZuVSqKR1Kc&rank=1	2020	129	2025-04-12 02:00:36.499
333	Perawan remaja dalam cengkereman militer	9786026208828	https://www.goodreads.com/book/show/12068827-perawan-remaja-dalam-cengkeraman-militer?from_search=true&from_srp=true&qid=nm2yEdfdKe&rank=1	2001	246	2025-04-12 02:03:03.806
334	BlackJack Bind Up 01	9786230067921	https://www.goodreads.com/book/show/40381674-black-jack-n-01-08?from_search=true&from_srp=true&qid=Qf08JEIdwz&rank=1	2024	411	2025-04-17 11:50:33.119
335	Percy Jackson #6 The chalice of the gods	9786232424128	https://www.goodreads.com/book/show/63048246-the-chalice-of-the-gods?from_search=true&from_srp=true&qid=TZavo42Dc0&rank=1	2023	240	2025-04-21 05:46:58.138
336	Pluto 2	9786230315589	https://www.goodreads.com/book/show/6236051-pluto?from_search=true&from_srp=true&qid=4WFSibBn5E&rank=1	2025	195	2025-04-21 08:42:56.313
337	Zadig	9786238476237	https://www.goodreads.com/book/show/6859478-voltaire-zadig-ou-la-destin-e?from_search=true&from_srp=true&qid=BCiJ9bm0Ws&rank=1	2025	118	2025-04-27 00:16:49.12
338	Di Tanah Lada	9786231342485	https://www.goodreads.com/book/show/27213435-di-tanah-lada?from_search=true&from_srp=true&qid=XgVihuGDXz&rank=1	2024	285	2025-04-27 00:20:03.439
340	Kembar	9786025370687	https://www.goodreads.com/book/show/51820545-kembar?from_search=true&from_srp=true&qid=xHPfMzAGms&rank=1	2019	257	2025-05-02 05:04:08.328
341	Naruto Bind Up Edition 17	9786230069765	https://www.goodreads.com/book/show/164111927-naruto-volume-34-the-reunion-naruto-v34-paperback?from_search=true&from_srp=true&qid=4mT2AW3n9M&rank=2	2025	320	2025-05-02 14:31:44.372
342	Brida	9789792299427	https://www.goodreads.com/book/show/69654727-brida---cole-o-paulo-coelho?from_search=true&from_srp=true&qid=ncrUvj9ysL&rank=2	2024	232	2025-05-02 14:33:01.566
343	Tentang Langit	9786233052498	https://www.goodreads.com/book/show/12230167	2021	189	2025-05-03 05:45:16.011
344	The Fabric of Reality	9786231340108	https://www.goodreads.com/book/show/177068.The_Fabric_of_Reality?from_search=true&from_srp=true&qid=KYzfCMugYH&rank=1	2023	413	2025-05-03 06:03:11.401
345	Kematian Ivan Ilyich	9786237543329	https://www.goodreads.com/book/show/23356815-kematian-ivan-ilyich?from_search=true&from_srp=true&qid=wkXem3IQ5B&rank=1	2021	97	2025-05-05 03:37:21.836
346	Kumpulan Cerita Rakyat Korea	9786237543268	https://www.goodreads.com/book/show/57576859-kumpulan-cerita-rakyat-korea?from_search=true&from_srp=true&qid=nt1uaxSWC7&rank=1	2021	99	2025-05-08 06:53:19.78
347	One Piece 04	9789792042139	https://www.goodreads.com/book/show/164973712-one-piece-east-blue-volume-10-12-by-oda-eiichiro-author-may-04-2?from_search=true&from_srp=true&qid=GraC26Qx4x&rank=5	2002	187	2025-05-09 22:31:34.461
348	Slamdunk #1	9786230030598	https://www.goodreads.com/book/show/1311355.Slam_Dunk_Vol_1?from_search=true&from_srp=true&qid=ncarJ8R5aX&rank=1	2024	300	2025-05-13 06:37:19.264
349	Slamdunk #2	9786230030604	https://www.goodreads.com/book/show/4945364-slam-dunk-vol-2?ac=1&from_search=true&qid=iJ8bVvl9m3&rank=3	2024	217	2025-05-13 06:38:08.635
350	Berapa Luas Tanah yang Dibutuhkan Seorang Manusia	9786237543381	https://www.goodreads.com/book/show/59314040-berapa-luas-tanah-yang-dibutuhkan-seorang-manusia?from_search=true&from_srp=true&qid=OuQKsYWnX9&rank=1	2021	151	2025-05-13 06:39:26.923
351	One Piece 05	9789792043167	https://www.goodreads.com/book/show/128971332-one-piece-volume-5-one-piece-05-by-oda-eiichiro-author-2004?from_search=true&from_srp=true&qid=4e93XFVusf&rank=1	2002	187	2025-05-15 03:54:40.304
352	Jakarta Sebelum Pagi	9786020531373	https://www.goodreads.com/book/show/34311766-jakarta-sebelum-pagi?from_search=true&from_srp=true&qid=ri1NzrhuBm&rank=1	2025	257	2025-05-15 03:55:56.606
353	Kumpulan Rakyat Jepang	9786025084805	https://www.goodreads.com/book/show/36684843-kumpulan-cerita-rakyat-jepang?from_search=true&from_srp=true&qid=cnvay7yEZd&rank=1	2017	105	2025-05-16 03:13:46.774
354	One Piece #6	9789792044591	https://www.goodreads.com/book/show/364950.One_Piece_Volume_6?from_search=true&from_srp=true&qid=xpL3V2sYB7&rank=1	2002	183	2025-05-16 03:16:34.134
355	Slam Dunk 03	9786230030611	https://www.goodreads.com/book/show/1989838.Slam_Dunk_Vol_3	2024	300	2025-05-17 03:06:39.031
356	Slam Dunk 04	9786230030628	https://www.goodreads.com/book/show/131913142-slam-dunk-04?from_search=true&from_srp=true&qid=qOzvDmioNA&rank=1	2024	265	2025-05-17 03:08:12.829
357	Takut dan Gemetar	978238476268	https://www.goodreads.com/book/show/40202576-takut-dan-gemetar?from_search=true&from_srp=true&qid=yWpFzU3i7Q&rank=1	2024	151	2025-05-19 11:39:21.917
358	Malam Seribu Jahanam	9786020671444	https://www.goodreads.com/book/show/179532331-malam-seribu-jahanam?from_search=true&from_srp=true&qid=q7Xv6MvMLz&rank=1	2023	352	2025-05-20 15:23:41.861
359	One Piece 105	9786230056826	https://www.goodreads.com/book/show/176443002-one-piece-vol-105?from_search=true&from_srp=true&qid=HKzhUQvgEY&rank=1	2024	186	2025-05-22 03:19:29.595
360	Harmonium	9786020672489	https://www.goodreads.com/book/show/1422433.Harmonium?from_search=true&from_srp=true&qid=QkLkh3Y0y8&rank=1	1995	196	2025-05-24 04:41:07.426
361	Naruto Bind Up Edition 18	9786230070303	https://www.goodreads.com/book/show/46166345-naruto---volume-36?from_search=true&from_srp=true&qid=EIjoinmQss&rank=2	2025	375	2025-05-24 04:42:01.27
362	A brief history of time	9789792292121	https://www.goodreads.com/book/show/39715700-a-brief-history-of-time-sejarah-singkat-waktu	2013	290	2025-05-24 15:57:00.957
363	Re: dan perempuan	9786024815615	https://www.goodreads.com/book/show/58730640-re?from_search=true&from_srp=true&qid=8IsgZIwp7x&rank=1	2021	326	2025-05-25 03:18:30.515
364	Amoral	9786238476114	https://www.goodreads.com/book/show/211712940-amoral?from_search=true&from_srp=true&qid=CmA1BPJf4J&rank=1	2024	179	2025-05-26 03:52:15.096
365	Buddha 8 : Jetawana	9786231340559	https://www.goodreads.com/book/show/1739929.Buddha_8?from_search=true&from_srp=true&qid=C0NsEDOCMK&rank=1	2025	362	2025-05-26 11:12:20.847
366	Ronggeng Dukuh Paruk	9786020681955	https://www.goodreads.com/book/show/1334844.Ronggeng_Dukuh_Paruk?from_search=true&from_srp=true&qid=K4kN27rFae&rank=1	2025	518	2025-05-28 17:19:49.256
367	Sakamoto Days Vol.15	9786230070341	https://www.goodreads.com/book/show/209363183-sakamoto-days-15?ac=1&from_search=true&qid=xWaE95GUQV&rank=1	2025	185	2025-05-29 08:29:48.724
368	Solaris	9786237543725	https://www.goodreads.com/book/show/95558.Solaris?from_search=true&from_srp=true&qid=FdZOU3cYLS&rank=2	2025	275	2025-05-31 03:01:58.923
369	Perempuan di titik nol	9786024334383	https://www.goodreads.com/book/show/1341023.Perempuan_di_Titik_Nol?from_search=true&from_srp=true&qid=Vb8Sth9eBe&rank=1	1989	176	2025-06-01 12:48:56.943
370	One Piece 106	9786230058417	https://www.goodreads.com/book/show/199798712-one-piece-vol-106?from_search=true&from_srp=true&qid=UpQyf3vgO6&rank=1	2025	200	2025-06-04 11:43:37.615
371	One Piece 107	9786230068409	https://www.goodreads.com/book/show/207297378-one-piece-volume-107?from_search=true&from_srp=true&qid=UKEpDzoA8K&rank=1	2025	200	2025-06-04 11:44:18.023
372	Kumpulan Cerita Rakyat Cina	9786027328471	https://www.goodreads.com/book/show/35012293-kumpulan-cerita-rakyat-cina?from_search=true&from_srp=true&qid=l2eXuIypVP&rank=1	2024	118	2025-06-04 11:45:07.213
373	Haji Murad	9786024413071	https://www.goodreads.com/book/show/18071363-haji-murad?from_search=true&from_srp=true&qid=IT4S3yqHnd&rank=1	1912	254	2025-06-07 04:42:41.827
374	Orang - orang bloomington	9786023850211	https://www.goodreads.com/book/show/2236672.Orang_Orang_Bloomington?from_search=true&from_srp=true&qid=OqUXufN8mb&rank=1	2016	307	2025-06-07 04:44:33.461
375	One Piece 108	9786230070280	https://www.goodreads.com/book/show/212030687-one-piece-vol-108?from_search=true&from_srp=true&qid=57vwA88eYu&rank=1	2025	210	2025-06-07 05:56:44.299
376	Hikayat Kadiroen	9789791684569	https://www.goodreads.com/book/show/1563690.Hikayat_Kadiroen?from_search=true&from_srp=true&qid=QzKXZISXs8&rank=1	2018	251	2025-06-10 02:19:45.466
377	Slam Dunk 5	9786230030635	https://www.goodreads.com/book/show/551871.Slam_Dunk_Vol_5?from_search=true&from_srp=true&qid=OnnzmhR16z&rank=1	2024	321	2025-06-11 03:37:29.039
378	Perawan Desa	978623724834	https://www.goodreads.com/book/show/61176232-perawan-desa?from_search=true&from_srp=true&qid=HoYANdZYuJ&rank=1	2022	100	2025-06-15 03:11:07.134
379	Shiver	9786230315374	https://www.goodreads.com/book/show/34852851-shiver?from_search=true&from_srp=true&qid=ayBDfGjwGB&rank=1	2025	350	2025-06-17 05:44:10.363
380	Taantangan Demokrasi	9794163201	https://www.goodreads.com/book/show/1430242.Tantangan_Demokrasi?from_search=true&from_srp=true&qid=SYVZiJhNrV&rank=1	1995	83	2025-06-25 14:14:55.984
381	Kamu Terlalu Banyak Bercanda	9786239067106	https://www.goodreads.com/book/show/45834865-kamu-terlalu-banyak-bercanda?from_search=true&from_srp=true&qid=RNszxGpkhC&rank=1	2020	194	2025-06-25 14:19:10.861
382	Demokrasi Kita	9786028635391	https://www.goodreads.com/book/show/1431515.Demokrasi_Kita?from_search=true&from_srp=true&qid=bJzl1Otfxc&rank=2	2018	164	2025-06-25 14:22:04.808
383	20th Century Boys Volume 2	9786230069888	https://www.goodreads.com/book/show/5071380-20th-century-boys-volume-2?from_search=true&from_srp=true&qid=yATs1GVlPp&rank=3	2025	415	2025-06-25 14:24:59.828
384	Black Jack 2	9786230068904	https://www.goodreads.com/book/show/174379.Black_Jack_Vol_2?from_search=true&from_srp=true&qid=MCiyD5DNDw&rank=5	2025	400	2025-06-30 09:06:06.311
385	Pidato Politik 1 juli 2004 SBY	000000000000000	https://books.google.com/books/about/Bersama_kita_bisa.html?id=gkF-YgEACAAJ	2004	40	2025-06-30 09:07:36.632
386	Pidato Politik 1 juni 2004 SBY	00000000000000000000	https://books.google.com/books/about/Bersama_kita_bisa.html?id=gkF-YgEACAAJ	2004	40	2025-06-30 09:08:11.295
387	Dari Sierra Mestra menuju Havana	9791680116	https://www.goodreads.com/book/show/40813375-dari-sierra-maestra-menuju-havana?from_search=true&from_srp=true&qid=sd4K8IWD0r&rank=1	2007	111	2025-07-09 04:31:44.715
388	Penderitaan Pemuda Werther	9786238476091	https://www.goodreads.com/book/show/5193041-penderitaan-pemuda-werther?from_search=true&from_srp=true&qid=H7eBtIYzAA&rank=1	2024	177	2025-07-11 02:29:39.746
389	Sonata Kreutzer	9786238476336	https://www.goodreads.com/book/show/141077.The_Kreutzer_Sonata?ac=1&from_search=true&qid=UCZByEjJJl&rank=1	2025	129	2025-07-11 16:38:02.317
390	Kisah 1001 malam	9786237543756	https://www.goodreads.com/book/show/8906349-kisah-1001-malam?from_search=true&from_srp=true&qid=43b39Xvx7S&rank=1	2023	544	2025-07-12 16:31:28.773
391	Fahrenheit 451	9786238476367	https://www.goodreads.com/book/show/13079982-fahrenheit-451	2025	201	2025-07-12 17:26:44.253
392	Sejarah Filsafat Barat	9793237341	https://www.goodreads.com/book/show/7044698-sejarah-filsafat-barat?from_search=true&from_srp=true&qid=wOsD8Lclqq&rank=1	2002	1107	2025-07-17 13:35:15.96
393	Seks dan Revolusi	9786025792502	https://www.goodreads.com/book/show/7010659-seks-dan-revolusi?from_search=true&from_srp=true&qid=GLR6gQHh0d&rank=1	2019	258	2025-07-17 13:36:33.413
394	Jatuh Ke Lubang Hitam	9786231341976	https://www.goodreads.com/book/show/217195528-jatuh-ke-lubang-hitam?ac=1&from_search=true&qid=FMHpTEu1B0&rank=1	2006	352	2025-07-17 13:38:45.158
395	Eksperimen keji Kedokteran Penjajahan Jepang	978623735714	https://www.goodreads.com/book/show/55351213-eksperiman-keji-kedokteran-penjajahan-jepang?from_search=true&from_srp=true&qid=DYhZQdFhUG&rank=1	2015	320	2025-07-17 13:42:55.481
396	Propaganda & Genosida di Indonesia	9786237357117	https://www.goodreads.com/book/show/54905860-propaganda-dan-genosida-di-indonesia?from_search=true&from_srp=true&qid=Qr583DVwIz&rank=1	2020	236	2025-07-17 13:44:56.622
397	Aldera	9786233466844	https://www.goodreads.com/book/show/62916818-aldera?from_search=true&from_srp=true&qid=BCjhOphEoN&rank=1	2022	200	2025-07-17 13:46:15.533
398	The Golden Age of History	9786232201309	https://www.goodreads.com/book/show/18720905-the-golden-ages-of-history?from_search=true&from_srp=true&qid=8FGzkkLMnn&rank=1	2011	262	2025-07-17 13:48:03.928
399	Jalan ke Demokrasi Rakyat bagi Indonesia	9786238852413	https://www.goodreads.com/book/show/170206614-the-road-to-people-s-democracy-for-indonesia-by-d-n-aidit	2023	534	2025-07-17 13:49:42.509
400	Babel	9786027760813	https://www.goodreads.com/book/show/213870316-babel	2022	638	2025-07-17 13:53:35.197
401	Naruto Bind Up Edition 19	9786230070686	https://www.goodreads.com/book/show/5660026-naruto-vol-37?ref=nav_sb_ss_1_14	2025	378	2025-07-24 15:39:22.811
402	Humankind	9786020649191	https://www.goodreads.com/book/show/52879286-humankind?from_search=true&from_srp=true&qid=F71GgV0xnH&rank=1	2021	443	2025-07-26 16:30:30.911
403	Entrok	9786020652191	https://www.goodreads.com/book/show/7876993-entrok?from_search=true&from_srp=true&qid=HzGLdZY4ui&rank=1	2010	288	2025-08-03 17:26:41.155
404	Sakamoto Days 16	9786230071072	https://www.goodreads.com/book/show/209363323-sakamoto-days-16?from_search=true&from_srp=true&qid=OAuiadQxsN&rank=1	2025	190	2025-08-03 17:27:57.903
405	Naruto Bind Up Edition 20	9786230071164	https://www.goodreads.com/book/show/3714426-naruto-39?from_search=true&from_srp=true&qid=WJ3x88LHVY&rank=1	2025	373	2025-08-03 17:29:14.685
406	Pulang	9786024242756	https://www.goodreads.com/book/show/16174176-pulang?from_search=true&from_srp=true&qid=Bh3FR9hjHq&rank=1	2012	454	2025-08-04 07:48:37.893
407	Hujan	9786239987879	https://www.goodreads.com/book/show/28446637-hujan?from_search=true&from_srp=true&qid=B8pn4DWjNG&rank=1	2024	317	2025-08-05 06:22:54.357
408	Takopi's Original Sin Volume 1	9786230309274	https://www.goodreads.com/book/show/71037196-takopi-s-original-sin-1?ac=1&from_search=true&qid=uN7cnLR25M&rank=2	2022	200	2025-08-11 08:47:40.253
409	Takopi's Original Sin Volume 2	39786230309465	https://www.goodreads.com/book/show/93850474-takopi-s-original-sin-2?ac=1&from_search=true&qid=Upetz1u99E&rank=3	2022	200	2025-08-11 08:48:52.131
410	Naruto Bind Up Edition 21	9786230071782	https://www.goodreads.com/book/show/5463398-naruto-vol-42?ref=nav_sb_ss_1_9	2025	340	2025-08-19 18:06:35.506
411	Mesin Waktu	9786237543077	https://www.goodreads.com/book/show/51811500-mesin-waktu?from_search=true&from_srp=true&qid=yNzUR5kWlx&rank=1	2025	118	2025-08-21 16:50:24.704
412	Slamdunk 6	9786230031571	https://www.goodreads.com/book/show/201672348-slam-dunk-new-edition-vol-06?ac=1&from_search=true&qid=yO7zGaTwWj&rank=5	2024	300	2025-08-22 19:26:22.039
506	Jujutsu Kaisen Vol. 1	9786230022180	https://www.goodreads.com/book/show/56660563-jujutsu-kaisen-vol-1	2018	200	2026-01-26 04:53:02.752248
413	Slam Dunk 07	9786230031588	https://www.goodreads.com/book/show/52314860-slam-dunk-vol-7?from_search=true&from_srp=true&qid=9NZpdwoA0D&rank=3	2024	300	2025-08-25 04:36:45.075
414	Maryam	9786020652153	https://www.goodreads.com/book/show/13487232-maryam?from_search=true&from_srp=true&qid=AWZnO7PK9H&rank=1	2025	271	2025-09-01 05:32:12.315
415	SlamDunk 8	9786230031595	https://www.goodreads.com/book/show/53308615-slam-dunk-vol-8?from_search=true&from_srp=true&qid=FtgUI3Tdu5&rank=3	2024	340	2025-09-01 05:32:51.254
416	One Piece 7	978979204833	https://www.goodreads.com/book/show/364954.One_Piece_Volume_7?from_search=true&from_srp=true&qid=ifbB3o0bxI&rank=1	2023	150	2025-09-02 06:19:57.64
417	Demon Slayer 1	9786230017193	https://www.goodreads.com/book/show/36538793-demon-slayer?from_search=true&from_srp=true&qid=FT2J5T3pXI&rank=1	2020	190	2025-09-02 19:22:16.517
418	Demon Slayer 2	9786230018220	https://www.goodreads.com/book/show/38926432-demon-slayer?from_search=true&from_srp=true&qid=dz0UIJ1haA&rank=1	2020	190	2025-09-02 19:23:16.541
419	Naruto Bind Up 22	9786230072413	https://www.goodreads.com/book/show/5822950-naruto-vol-44?from_search=true&from_srp=true&qid=2vg81yVsY2&rank=1	2025	425	2025-09-03 13:52:50.219
420	One Piece 8	9789792046571	https://www.goodreads.com/book/show/364955.One_Piece_Volume_8?from_search=true&from_srp=true&qid=qe5WHYAKjo&rank=1	2002	180	2025-09-03 17:54:58.774
421	Slam Dunk 9	9786230031601	https://www.goodreads.com/book/show/54390224-slam-dunk-vol-9?from_search=true&from_srp=true&qid=HyFJTwXVRd&rank=3	2024	410	2025-09-05 00:36:14.73
422	Slam Dunk 10	9786230031618	https://www.goodreads.com/book/show/54625224-slam-dunk-vol-10?from_search=true&from_srp=true&qid=xEiiA9BEmS&rank=3	2024	360	2025-09-06 18:07:38.347
423	Manusia Indonesia	9786233213295	https://www.goodreads.com/book/show/1795582.Manusia_Indonesia?from_search=true&from_srp=true&qid=Gi87eCt6FQ&rank=2	2023	140	2025-09-07 14:06:24.482
424	Senja Di Jakarta	9786024335885	https://www.goodreads.com/book/show/1921356.Senja_di_Jakarta?from_search=true&from_srp=true&qid=qw2Cyyrru7&rank=2	1992	300	2025-09-11 16:25:12.391
425	Mujirushi	9786230021633	https://www.goodreads.com/book/show/52758085-mujirushi?from_search=true&from_srp=true&qid=FbjtSo78Ta&rank=1	2020	240	2025-09-11 19:56:56.267
426	Tuan Besar Gatsby	9786237543541	https://www.goodreads.com/book/show/41733839-the-great-gatsby?ac=1&from_search=true&qid=TpPqX8oT2U&rank=1	2025	221	2025-09-13 03:27:39.231
427	Sakamoto days 17	9786230072321	https://www.goodreads.com/book/show/213790753-sakamoto-days-17?from_search=true&from_srp=true&qid=Vh35L70Zi4&rank=1	2025	180	2025-09-13 18:52:57.322
428	Robohnya Surau Kami	9789792261295	https://www.goodreads.com/book/show/1455480.Robohnya_Surau_Kami?from_search=true&from_srp=true&qid=LUxiidl51u&rank=1	2025	138	2025-09-14 13:35:04.92
429	Monster 06	9786230316180	https://www.goodreads.com/book/show/29621622-monster-volume-06?from_search=true&from_srp=true&qid=b6RJEqr1Wm&rank=1	2025	400	2025-09-19 08:20:36.726
430	Orang-orang proyek	9786020320595	https://www.goodreads.com/book/show/1511836.Orang_orang_Proyek?from_search=true&from_srp=true&qid=khC26GCtke&rank=1	2025	253	2025-09-20 05:20:05.778
431	Demon Slayer 3	9786230018961	https://www.goodreads.com/book/show/38926402-demon-slayer?from_search=true&from_srp=true&qid=VcZ01teiJH&rank=1	2024	183	2025-09-22 05:30:01.483
432	Demon Slayer 4	9786230019685	https://www.goodreads.com/book/show/40680067-demon-slayer?from_search=true&from_srp=true&qid=iyHwavbipy&rank=1	2024	190	2025-09-22 05:31:11.057
433	Slam Dunk 11	9786230035326	https://www.goodreads.com/book/show/55135379-slam-dunk-vol-11?from_search=true&from_srp=true&qid=EbciHj6dCC&rank=2	2024	308	2025-09-24 18:48:50.866
434	Slam Dunk #12	9786230035333	https://www.goodreads.com/book/show/55374674-slam-dunk-vol-12?from_search=true&from_srp=true&qid=f9WCHHtIqt&rank=4	2025	260	2025-10-08 07:07:18.423
435	Naruto Bind Up Edition 23	9786230072918	https://www.goodreads.com/book/show/5527835-naruto-vol-45?from_search=true&from_srp=true&qid=kCYMy3ibab&rank=1	2025	350	2025-10-13 18:49:34.024
436	Semua Ikan di Langit	9786023758067	https://www.goodreads.com/book/show/33848032-semua-ikan-di-langit?from_search=true&from_srp=true&qid=OfgqIl7KMS&rank=1	2025	216	2025-10-15 14:26:32.553
437	Slam Dunk 13	9786230035340	https://www.goodreads.com/book/show/55685278-slam-dunk-vol-13?from_search=true&from_srp=true&qid=GKxyTO6McF&rank=3	2025	225	2025-10-15 15:33:02.396
438	Perempuan yang Menangis kepada Bulan Hitam	9786020648453	https://www.goodreads.com/book/show/55817473-perempuan-yang-menangis-kepada-bulan-hitam?from_search=true&from_srp=true&qid=rehVzF0sNu&rank=1	2020	312	2025-10-17 09:17:36.639
439	Slam Dunk 14	9786230035357	https://www.goodreads.com/book/show/55852858-slam-dunk-vol-14?from_search=true&from_srp=true&qid=QTqiUvHE9P&rank=3	2025	250	2025-10-19 13:25:46.112
440	Slam Dunk 15	9786230035364	https://www.goodreads.com/book/show/56157418-slam-dunk-vol-15?from_search=true&from_srp=true&qid=LaeSSJqHZY&rank=3	2025	345	2025-10-20 05:30:41.241
441	Slam Dunk 16	9786230037023	https://www.goodreads.com/book/show/56556196-slam-dunk-vol-16?from_search=true&from_srp=true&qid=FBjjkMy0SF&rank=2	2025	285	2025-10-21 04:59:47.173
442	Slam Dunk 17	9786230031030	https://www.goodreads.com/book/show/57011927-slam-dunk-vol-17?from_search=true&from_srp=true&qid=WfKXujDJO4&rank=3	2025	265	2025-10-21 05:00:30.848
443	Slam Dunk 18	9786230037047	https://www.goodreads.com/book/show/55754438-slam-dunk-18?from_search=true&from_srp=true&qid=vRxhAFewb8&rank=2	2025	223	2025-10-21 05:01:08.412
444	Slam Dunk 19	9786230037054	https://www.goodreads.com/book/show/55755352-slam-dunk-19?from_search=true&from_srp=true&qid=frgEv85oGx&rank=2	2025	285	2025-10-21 05:01:44.738
445	Materialisme Dialektis Historis	978999519336	http://goodreads.com/book/show/694454.Dialectical_and_Historical_Materialism?from_search=true&from_srp=true&qid=1ocgQ4eGbC&rank=1	2022	65	2025-10-22 06:58:53.871
446	Tiga Drama	9786020679747	https://www.goodreads.com/book/show/1025847.Mengapa_Kau_Culik_Anak_Kami_?from_search=true&from_srp=true&qid=MUr5myZuqf&rank=1	2024	120	2025-10-23 12:39:00.465
447	Laskar Pelangi	9786022916628	https://www.goodreads.com/book/show/1362193.Laskar_Pelangi?from_search=true&from_srp=true&qid=ERIvgxkezU&rank=1	2025	328	2025-10-24 18:33:11.224
448	Utopia	9786237543657	https://www.goodreads.com/book/show/18414.Utopia?from_search=true&from_srp=true&qid=04uNhWAeSp&rank=1	2025	172	2025-10-25 05:16:22.063
449	Demon Slayer 5	9786230024382	https://www.goodreads.com/book/show/40680065-demon-slayer?from_search=true&from_srp=true&qid=2h8SCoA6XJ&rank=1	2024	191	2025-10-28 06:53:28.032
450	Runtuhnya Rumah Keluarga Usher	9786238476084	https://www.goodreads.com/book/show/212724981-runtuhnya-rumah-keluarga-usher?from_search=true&from_srp=true&qid=qM4GzB3hus&rank=1	2025	127	2025-10-28 06:54:33.095
451	Tentang Suatu Tempat di Wilayah Kinki	9786347128997	https://www.goodreads.com/book/show/241910439-tentang-suatu-tempat-di-wilayah-kinki?from_search=true&from_srp=true&qid=3cP0OadVbZ&rank=1	2025	365	2025-10-31 15:40:30.86
452	Madonna Bermantel Bulu	9786238476510	https://www.goodreads.com/book/show/240342272-madonna-bermantel-bulu?from_search=true&from_srp=true&qid=pP9OMGJnjm&rank=1	2025	220	2025-11-03 03:38:18.058
453	Demon Slayer 6	9786230024689	https://www.goodreads.com/book/show/42633905-demon-slayer?from_search=true&from_srp=true&qid=8evj5T3rTJ&rank=1	2025	220	2025-11-03 03:39:01.786
454	Slam Dunk 20	9786230037061	https://www.goodreads.com/book/show/58022578-slam-dunk-vol-20?from_search=true&from_srp=true&qid=E1telRn8Ww&rank=11	2025	250	2025-11-03 03:39:38.109
455	Sakamoto Days 18	9786230073281	https://www.goodreads.com/book/show/214921144-sakamoto-days-18?from_search=true&from_srp=true&qid=StQMjHmsyD&rank=1	2025	200	2025-11-03 03:40:29.231
456	Demon Slayer 7	9786230027871	https://www.goodreads.com/book/show/42633909-demon-slayer?from_search=true&from_srp=true&qid=nWK0zwZ8RX&rank=1	2025	210	2025-11-06 14:48:04.888
457	Demon Slayer 8	9786230029806	https://www.goodreads.com/book/show/43909410-demon-slayer?from_search=true&from_srp=true&qid=gHJmeuWAcn&rank=1	2025	210	2025-11-06 14:49:50.817
458	Overlord Light Novel 1	9786231034342	https://www.goodreads.com/book/show/27415387-overlord-vol-1?from_search=true&from_srp=true&qid=8Fdo4zBYRN&rank=2	2025	420	2025-11-06 14:55:08.672
459	Demon Slayer 9	9786230031281	https://www.goodreads.com/book/show/43909413-demon-slayer?from_search=true&from_srp=true&qid=CK50r0PE52&rank=1	2025	210	2025-11-07 03:38:58.394
460	Demon Slayer 10	9786230033711	https://www.goodreads.com/book/show/52228762-demon-slayer?from_search=true&from_srp=true&qid=Vse41JrpKS&rank=1	2025	210	2025-11-07 03:39:32.992
461	Demon Slayer 11	9786230035388	https://www.goodreads.com/book/show/51245114-demon-slayer?from_search=true&from_srp=true&qid=L4Hhu3G98b&rank=1	2025	210	2025-11-07 03:40:21.698
462	Naruto Bind Up 26	9786230073403	https://www.goodreads.com/book/show/6435922-naruto-vol-47?from_search=true&from_srp=true&qid=Qd8wbUMCcJ&rank=1	2025	400	2025-11-08 17:12:11.046
463	Tenggelamnya Kapal Van der Wijk	9786022504160	https://www.goodreads.com/book/show/1307394.Tenggelamnya_Kapal_Van_Der_Wijck?from_search=true&from_srp=true&qid=l60xTDVhsu&rank=1	2017	255	2025-11-08 17:13:10.367
464	Berkisar Merah	9789792266320	https://www.goodreads.com/book/show/1302793.Bekisar_Merah?from_search=true&from_srp=true&qid=PGOPAFtCWr&rank=1	2011	358	2025-11-13 03:53:14.1
465	20th Century Boys 3	9786230071935	https://www.goodreads.com/book/show/40680082-20th-century-boys?from_search=true&from_srp=true&qid=UnS5bs0aWa&rank=2	2025	440	2025-11-13 03:57:44.156
473	Filsafat Kecerdasan Buatan	9786233595612		2025	245	2025-11-27 08:18:10.935
483	Caligula dan Lakon Lainnya	9789791684378	https://www.goodreads.com/book/show/51618676-caligula-dan-lakon-lainnya	1944	284	2025-12-28 07:56:37.288855
468	Choujin X 1	9786230072765	https://www.goodreads.com/book/show/244071016-choujin-x-vol-1	2025	256	2025-11-17 07:08:33.483
472	Madiun Dalam Kemelut Sejarah	9786024810610	https://www.goodreads.com/book/show/42977277-madiun-dalam-kemelut-sejarah	2025	379	2025-11-25 10:21:36.618
480	Lebih Putih Dariku	9786020788326	https://www.goodreads.com/book/show/61304582-lebih-putih-dariku	2025	284	2025-12-14 02:59:01.392
479	One Piece 10	9789792049046	https://www.goodreads.com/book/show/6811238-one-piece-10	2024	220	2025-12-07 03:48:22.085
478	One Piece 9	9789792048179	https://www.goodreads.com/book/show/6811227-one-piece-9	2024	250	2025-12-07 03:47:41.487
488	Kenang-Kenangan Mengejutkan Si Beruang Kutub	9789791260824	https://www.goodreads.com/book/show/42901124-kenang-kenangan-mengejutkan-si-beruang-kutub	2010	68	2025-12-28 11:08:11.258129
467	Metode Jakarta	9781541742406	https://www.goodreads.com/book/show/53054943-the-jakarta-method	2025	410	2025-11-16 16:43:02.368
477	As Long As the lemon grow	9780316351485	https://www.goodreads.com/book/show/182761378-as-long-as-the-lemon-trees-grow	2022	475	2025-12-07 03:46:53.104
484	Agama Manusia	9789791685092	https://www.goodreads.com/book/show/58672044-agama-manusia	1933	322	2025-12-28 10:44:03.970057
485	Beras dan Cerita-cerita Bergizi Lainnya	6214942618617	https://www.goodreads.com/book/show/198468968-beras-dan-cerita-cerita-bergizi-lainnya	2023	186	2025-12-28 10:55:22.02983
486	Kuli Kontrak	9786238771394	https://www.goodreads.com/book/show/6085244-kuli-kontrak?ac=1&from_search=true&qid=hjXN4m9DYG&rank=1	1982	164	2025-12-28 10:57:25.562285
487	Seribu Bangau	9786021491362	https://www.goodreads.com/book/show/25173017-seribu-bangau	1952	145	2025-12-28 10:58:23.553764
489	The Wealth of Nations	9786237586685	https://www.goodreads.com/book/show/239684020-the-wealth-of-nations	1776	752	2025-12-28 14:33:31.724035
476	Inyik Balang	9786231342355	https://www.goodreads.com/book/show/218633553-inyik-balang	2024	157	2025-11-30 15:03:35.518
475	Paya Nie	9786020788562	https://www.goodreads.com/book/show/216190763-paya-nie	2024	196	2025-11-30 10:53:10.616
474	Malam terakhir	9786024248239	https://www.goodreads.com/book/show/38402314-malam-terakhir	2018	119	2025-11-29 18:02:28.632
466	Kereta Semar Lembu	9786020664637	https://www.goodreads.com/book/show/62686455-kereta-semar-lembu	2022	318	2025-11-13 18:31:45.915
469	Pasung Jiwa	9786020652177	https://www.goodreads.com/book/show/239197650-pasung-jiwa	2025	328	2025-11-18 10:55:18.038
470	Proses	9789174291490	https://www.goodreads.com/book/show/11605374-processen	2025	279	2025-11-22 07:01:29.53
471	Pada sebuah kapal	9789792249729	https://www.goodreads.com/book/show/231679541-pada-sebuah-kapal	2024	351	2025-11-24 07:15:33.153
490	Dari Dalam Kubur	9786020788036	https://www.goodreads.com/book/show/55286991-dari-dalam-kubur	2020	509	2025-12-28 14:34:48.836834
491	Namaku Alam: Jilid 1	9786231340825	https://www.goodreads.com/book/show/195965151-namaku-alam	2023	448	2025-12-28 14:36:44.91658
492	Amba	9786020350219	https://www.goodreads.com/book/show/54633383-amba	2012	580	2025-12-28 14:37:54.636698
493	Pecundang	9789791685399	https://www.goodreads.com/book/show/2681495-pecundang?ac=1&from_search=true&qid=ncGbEZYMxa&rank=1	1907	405	2025-12-28 14:40:01.666993
494	Lekra, Lesbumi, Manifes Kebudayaan	9786029324839	\N	2023	250	2025-12-28 14:47:29.345283
495	Naruto Bind Up 25	9786230074448	https://www.goodreads.com/book/show/48581040-naruto---vol-49?ref=nav_sb_ss_1_13	2025	340	2026-01-09 03:42:36.005969
496	Kagurabachi Vol. 1	9786230069338	https://www.goodreads.com/book/show/230061948-kagurabachi-vol-1	2024	216	2026-01-16 04:29:55.218185
497	Demon Slayer: Kimetsu No Yaiba Vol. 12	9786230036767	https://www.goodreads.com/book/show/75608169-demon-slayer	2018	192	2026-01-16 04:30:45.431606
498	Demon Slayer: Kimetsu No Yaiba 13	9786230046810	https://www.goodreads.com/book/show/124083433-demon-slayer	2018	200	2026-01-16 04:31:49.412213
499	Pluto, 03	9786230316203	https://www.goodreads.com/book/show/236581213-pluto-03	2006	200	2026-01-16 04:33:09.642223
500	Kapan Nanti	9786020668659	https://www.goodreads.com/book/show/80344350-kapan-nanti	2023	133	2026-01-16 07:09:23.367238
501	Demon Slayer: Kimetsu No Yaiba 15	9786230049941	https://www.goodreads.com/book/show/199957491-demon-slayer	2019	200	2026-01-16 07:10:30.591869
502	Pluto 04	9786230317293	https://www.goodreads.com/book/show/240075446-pluto-04	2006	200	2026-01-16 07:11:12.073261
503	Demon Slayer: Kimetsu no Yaiba 14	9786230048265	https://www.goodreads.com/book/show/185650221-demon-slayer	2019	192	2026-01-16 07:11:50.216111
504	Demon Slayer: Kimetsu no Yaiba 16	9786230055751	https://www.goodreads.com/book/show/204990701-demon-slayer	2019	192	2026-01-16 07:12:34.819573
505	Demon Slayer: Kimetsu no Yaiba 17	9786230057021	https://www.goodreads.com/book/show/209419761-demon-slayer	2019	192	2026-01-25 04:18:54.841992
507	SAKAMOTO DAYS 19	\N	https://www.goodreads.com/book/show/214982855-sakamoto-days-19?ac=1&from_search=true&qid=dOSBuPjUrx&rank=1	2024	192	2026-01-26 15:44:00.177829
508	Jujutsu Kaisen Vol. 3	9786230024672	https://www.goodreads.com/book/show/58422935-jujutsu-kaisen-vol-3	2018	200	2026-02-01 01:57:34.761031
509	Jujutsu Kaisen, Vol. 2	9786230024399	https://www.goodreads.com/book/show/57586433-jujutsu-kaisen-vol-2	2018	200	2026-02-01 01:59:47.052156
510	Goodbye, Eri	9786230315169	https://www.goodreads.com/book/show/220925261-goodbye-eri	2022	208	2026-02-01 10:38:57.562538
511	Pluto, 05	9786230317347	https://www.goodreads.com/book/show/242443449-pluto-05	2007	192	2026-02-04 01:38:12.108728
512	Jujutsu Kaisen Vol. 4	9786230026942	https://www.goodreads.com/book/show/59511179-jujutsu-kaisen-vol-4	2019	192	2026-02-04 02:58:42.877163
513	Jujutsu Kaisen Vol. 5	9786230029783	https://www.goodreads.com/book/show/60163790-jujutsu-kaisen-vol-5	2019	200	2026-02-05 04:11:36.643199
514	Demon Slayer: Kimetsu no Yaiba 18	9786230057946	https://www.goodreads.com/book/show/212801715-demon-slayer	2019	192	2026-02-07 06:59:24.538631
515	Anjing Mengeong, Kucing Menggonggong	9786020673851	https://www.goodreads.com/book/show/214866554-anjing-mengeong-kucing-menggonggong	2024	148	2026-02-08 11:25:45.01229
516	Jujutsu Kaisen Vol. 6	9786230031274	https://www.goodreads.com/book/show/60729727-jujutsu-kaisen-vol-6	2019	200	2026-02-08 11:26:12.713899
517	Demon Slayer: Kimetsu no Yaiba 19	9786230059544	https://www.goodreads.com/book/show/217149152-demon-slayer	2020	200	2026-02-11 04:40:58.885724
518	Demon Slayer: Kimetsu No Yaiba 20	9786230060830	https://www.goodreads.com/book/show/220150494-demon-slayer	2020	200	2026-02-11 04:42:02.879442
519	Demon Slayer: Kimetsu no Yaiba 21	9786230068515	https://www.goodreads.com/book/show/231951248-demon-slayer	2020	200	2026-02-11 04:42:53.887925
520	Demon Slayer 22	9786230071614	https://www.goodreads.com/book/show/240296916-demon-slayer-22	2020	200	2026-02-11 04:43:32.526638
521	Demon Slayer: Kimetsu no Yaiba 23	9786230073007	https://www.goodreads.com/book/show/242003723-demon-slayer	2020	240	2026-02-11 04:45:00.981691
522	Jujutsu Kaisen Vol. 7	9786230035883	https://www.goodreads.com/book/show/62989492-jujutsu-kaisen-vol-7	2019	200	2026-02-13 04:39:00.376674
523	Hujan Bulan Juni	9786020318431	https://www.goodreads.com/book/show/25736858-hujan-bulan-juni	2015	144	2026-02-13 08:15:25.694846
524	Jujutsu Kaisen 8	9786230036828	https://www.goodreads.com/book/show/76753348-jujutsu-kaisen-8	2020	200	2026-02-15 09:22:23.63895
525	Pistol Perdamaian: Cerpen Pilihan Kompas 1996	9786024121884	https://www.goodreads.com/book/show/34410296-pistol-perdamaian	1996	208	2026-02-15 11:27:03.449088
526	Jujutsu Kaisen Vol. 9	9786230046698	https://www.goodreads.com/book/show/124947455-jujutsu-kaisen-vol-9	2020	192	2026-02-17 03:53:13.392617
527	Jujutsu Kaisen Vol. 10	9786230047916	https://www.goodreads.com/book/show/182894168-jujutsu-kaisen-vol-10	2020	200	2026-02-17 03:53:46.905625
530	Kumpulan Budak Setan	9786020333649	https://www.goodreads.com/book/show/31378883-kumpulan-budak-setan	2010	174	2026-02-17 10:05:36.97504
531	O	9786020325590	https://www.goodreads.com/book/show/27808997-o	2016	470	2026-02-17 10:06:26.971208
532	Demokrasi, Ateisme, Seksualitas: Catatan tentang Guncangan-Guncangan Budaya di Abad Ke-21	9786020685687	https://www.goodreads.com/book/show/247711932-demokrasi-ateisme-seksualitas	2025	186	2026-02-17 10:07:14.726009
533	One Hundred Years of Solitude - Seratus Tahun Kesunyian	9786020613550	https://www.goodreads.com/book/show/41382031-one-hundred-years-of-solitude---seratus-tahun-kesunyian	1967	488	2026-02-17 10:08:56.125837
534	Burung-Burung Manyar	9789797098421	https://www.goodreads.com/book/show/1379444.Burung_Burung_Manyar	1981	320	2026-02-17 10:10:31.658533
535	Pluto, 06	9786230317989	https://www.goodreads.com/book/show/246281839-pluto-06	2008	202	2026-02-18 03:09:49.439991
536	Jujutsu Kaisen Vol. 11	9786230049651	https://www.goodreads.com/book/show/198989081-jujutsu-kaisen-vol-11	2020	200	2026-02-18 03:35:39.934837
537	Selayang pandang agama konghucu & tao	9786231892546	\N	2023	104	2026-02-19 09:00:17.748695
538	Selayang Pandang Agama Zoroaster & Shinto	9786231892560	\N	2023	100	2026-02-20 16:28:33.635334
539	Selayang Pandang Agama Islam	9786231892522	\N	2023	95	2026-02-20 16:29:48.017348
540	Selayang Pandang Agama Hindu & Buddha	9786231892515	\N	2023	100	2026-02-20 16:32:20.805946
541	Selayang Pandang Agama Kristen	9786231892539	\N	2023	100	2026-02-21 19:11:36.133112
542	Selayang Pandang Agama Yahudi	9786231892553	\N	2023	100	2026-02-21 19:12:14.882236
543	The Valley of Fear	9786021142363	https://www.goodreads.com/book/show/34097097-the-valley-of-fear	1914	290	2026-02-21 19:13:15.95286
544	Kupu-Kupu Bersayap Gelap	9786025868948	https://www.goodreads.com/book/show/52669132-kupu-kupu-bersayap-gelap	2006	184	2026-02-22 16:11:13.600025
545	Kagurabachi Vol. 2	9786230070402	https://www.goodreads.com/book/show/235035891-kagurabachi-vol-2	2024	208	2026-02-22 16:12:20.287705
546	Dua Tangisan pada Satu Malam	9789797090654	https://www.goodreads.com/book/show/1528393.Dua_Tangisan_pada_Satu_Malam	2003	158	2026-02-22 16:14:33.581269
547	Makan Siang Okta: Sebuah Cerita Tiga Bagian	9786025868511	https://www.goodreads.com/book/show/49788397-makan-siang-okta	2019	170	2026-02-22 16:15:27.318626
548	Ecce Homo	9780140445152	https://www.goodreads.com/book/show/479356.Ecce_Homo	1908	144	2026-02-22 16:17:52.294896
549	Fajar	9786347157331	https://www.goodreads.com/book/show/34495436-der-wanderer-und-sein-schatten?ac=1&from_search=true&qid=7jpLTwYXYK&rank=1	2018	576	2026-02-23 08:43:50.326026
550	Kagurabachi 03	9786230072253	https://www.goodreads.com/book/show/245816407-kagurabachi-03	2024	192	2026-02-23 08:44:35.508526
551	Kisah Para Nabi	9789791303842	https://www.goodreads.com/book/show/36556711-kisah-para-nabi	2016	847	2026-02-24 03:18:49.473142
552	Hammer of the Gods	97800000000137	https://www.goodreads.com/book/show/226188.Hammer_of_the_Gods?ac=1&from_search=true&qid=HguiyZogyy&rank=1	1879	240	2026-02-24 07:39:30.550905
553	Kagurabachi 04	9786230074288	https://www.goodreads.com/book/show/247049404-kagurabachi-04	2024	180	2026-02-25 07:42:14.168832
554	LENYAP	6267711955275	https://www.goodreads.com/book/show/247069691-lenyap?ac=1&from_search=true&qid=heDBsA8HnV&rank=1	2026	172	2026-02-28 11:44:36.51431
555	The Tale of Dororo and Hyakkimaru Vol. 1	9786230068348	https://www.goodreads.com/book/show/229060862-the-tale-of-dororo-and-hyakkimaru-vol-1	2019	192	2026-02-28 11:54:26.57368
556	Héroes	9786230316906	https://www.goodreads.com/book/show/236236887-h-roes	2018	176	2026-02-28 15:12:23.695044
557	Choujin X, Vol. 2	9786230076602	https://www.goodreads.com/book/show/62919659-choujin-x-vol-2?ac=1&from_search=true&qid=taQQp48xFO&rank=3	2021	268	2026-02-28 15:13:38.877463
558	Layar Terkembang	9784070653	https://www.goodreads.com/book/show/1494305.Layar_Terkembang?ac=1&from_search=true&qid=rJVekbfboi&rank=1	1936	200	2026-03-02 04:32:27.727861
190	Shadows of Forgotten Ancestors	9786024819583	https://www.goodreads.com/book/show/61662.Shadows_of_Forgotten_Ancestors?from_search=true&from_srp=true&qid=b83LS64fNX&rank=2	2023	500	2024-11-23 13:29:00
560	Hidup Bersama Raksasa	9786020788302	https://www.goodreads.com/book/show/61315868-hidup-bersama-raksasa	2022	362	2026-03-02 13:57:44.8223
559	PLUTO 7	9786230318405	https://www.goodreads.com/book/show/10717841-pluto?ac=1&from_search=true&qid=LuqnxMEFOO&rank=1	2009	202	2026-03-02 09:01:10.148154
561	Atheis	9786022601197	https://www.goodreads.com/book/show/212010681-atheis	1949	261	2026-03-03 02:50:51.490098
562	Blind Side: Horror Anthology Comic	9786230316623	https://www.goodreads.com/book/show/232319751-blind-side	2016	200	2026-03-03 03:27:53.051383
563	Riwayat Terkubur: Kekerasan Antikomunis 1965-1966 di Indonesia	9786020788517	https://www.goodreads.com/book/show/210071600-riwayat-terkubur?ac=1&from_search=true&qid=xKWtoa3VXC&rank=1	2020	512	2026-03-03 08:51:17.595945
564	Hellstar Remina	9786230309304	https://www.goodreads.com/book/show/126532470-hellstar-remina	2005	296	2026-03-03 09:17:47.195776
565	Pramoedya A Toer: Dari Budaya Ke Politik 1950-1965	9786029402971	https://www.goodreads.com/book/show/45755197-pramoedya-a-toer?ac=1&from_search=true&qid=uvmYD4sCQ8&rank=4	1981	42	2026-03-03 16:29:37.520856
566	Naruto Bind Up 26	9786230076732	https://www.goodreads.com/book/show/144131204-naruto-52?ac=1&from_search=true&qid=Gu4LrgP3xi&rank=3	2026	390	2026-03-03 20:10:59.058125
567	Sukarno, Marxisme & Leninisme: Akar Pemikiran Kiri & Revolusi Indonesia	9786029402452	https://www.goodreads.com/book/show/23296694-sukarno-marxisme-leninisme?ac=1&from_search=true&qid=tTI8iSn4Pe&rank=1	2014	274	2026-03-04 10:56:54.398005
568	The Legend of Dororo and Hyakkimaru Vol. 2	9786230069598	https://www.goodreads.com/book/show/231951067-the-legend-of-dororo-and-hyakkimaru-vol-2	2025	192	2026-03-08 15:10:36.072039
569	The Legend of Dororo and Hyakkimaru Vol. 3	9786230070792	https://www.goodreads.com/book/show/53426674-the-legend-of-dororo-and-hyakkimaru-vol-3	2021	180	2026-03-08 15:12:48.669048
570	Monster Vol. 7	9786230318375	https://www.goodreads.com/book/show/247708968-monster-vol-7	2008	416	2026-03-08 15:13:33.068619
571	Laboratorium Palestina	6267718505915	https://www.goodreads.com/book/show/244485473-laboratorium-palestina?ref=nav_sb_ss_1_22	2023	328	2026-03-08 16:21:35.722281
572	Jalan Sunyi Gabriel Garcia Marquez	9786347102058	\N	2025	160	2026-03-08 20:40:11.166612
573	Teka-Teki Rumah Aneh	9786020669960	https://www.goodreads.com/book/show/123850391-teka-teki-rumah-aneh	2021	224	2026-03-09 07:22:35.358595
574	Chainsaw Man 1	9786230309212	https://www.goodreads.com/book/show/89576801-chainsaw-man-1	2019	192	2026-03-09 13:44:38.971011
575	Penyihir Dahsyat dari Oz	9786020686455	https://www.goodreads.com/book/show/245327978-penyihir-dahsyat-dari-oz	1900	184	2026-03-10 05:08:08.182348
576	Cinta Tak Ada Mati	9786020386355	https://www.goodreads.com/book/show/40170238-cinta-tak-ada-mati	2005	160	2026-03-10 06:21:31.328122
577	Sapi, Babi, Perang dan Tukang Sihir: Menjawab Teka-teki Kebudayaan	9789791260886	https://www.goodreads.com/book/show/62654693-sapi-babi-perang-dan-tukang-sihir	1974	262	2026-03-10 14:27:11.344406
578	Jujutsu Kaisen Vol. 12	9786230050619	https://www.goodreads.com/book/show/202954368-jujutsu-kaisen-vol-12	2020	200	2026-03-10 17:59:33.499166
579	Chainsaw Man Vol. 2	9786230310423	https://www.goodreads.com/book/show/124932285-chainsaw-man-vol-2	2019	192	2026-03-10 18:00:12.585869
580	20th Century Boys: The Perfect Edition, Vol. 4	9786230074424	https://www.goodreads.com/book/show/42867490-20th-century-boys?ac=1&from_search=true&qid=4eg519fWKK&rank=1	2016	424	2026-03-11 02:59:05.920018
581	Attack on Titan Bind Up Vol. 3	9786230057038	https://www.goodreads.com/book/show/17262714-attack-on-titan-vol-6?ref=nav_sb_ss_1_17	2011	192	2026-03-11 03:00:32.316883
582	Teka-Teki Gambar Aneh	9786020687209	https://www.goodreads.com/book/show/246934899-teka-teki-gambar-aneh	2022	312	2026-03-11 16:08:10.280748
583	Adam Ma'rifat	9786026651112	https://www.goodreads.com/book/show/36986923-adam-ma-rifat	1982	112	2026-03-11 16:08:33.020352
584	Setangkai Melati di Sayap Jibril	9786022792048	https://www.goodreads.com/book/show/29545369-setangkai-melati-di-sayap-jibril	2000	436	2026-03-11 16:09:06.919709
585	Godlob: Kumpulan Cerita Pendek	9786026651150	https://www.goodreads.com/book/show/35842814-godlob	1974	252	2026-03-11 16:09:28.600811
586	Rara Mendut	9786020634753	https://www.goodreads.com/book/show/50811427-rara-mendut	1983	345	2026-03-15 17:44:54.386907
587	SAKAMOTO DAYS 20	9786630076745	https://www.goodreads.com/book/show/221715496-sakamoto-days-20?ac=1&from_search=true&qid=E8TKdGvgMf&rank=1	2025	200	2026-03-15 17:46:30.178684
588	Sihir Perempuan	9786020683980	https://www.goodreads.com/book/show/237132821-sihir-perempuan	2005	192	2026-03-19 19:22:57.825723
589	Fish in The Water	9786020648781	https://www.goodreads.com/book/show/56853651-fish-in-the-water	2019	176	2026-03-19 19:24:02.99398
590	Sjahrir: Peran Besar Bung Kecil	9786024817626	https://www.goodreads.com/book/show/61335523-sjahrir	2010	223	2026-03-19 19:24:41.0149
591	86	9786020652207	https://www.goodreads.com/book/show/239019233-86	2011	256	2026-03-19 19:25:02.110223
592	Di Kaki Bukit Cibalak	9786020305134	https://www.goodreads.com/book/show/22454922-di-kaki-bukit-cibalak	1986	192	2026-03-19 19:25:34.405824
593	Genduk Duku	9786020633190	https://www.goodreads.com/book/show/50811980-genduk-duku	1987	280	2026-03-19 19:26:01.347268
594	Saman	9786024243999	https://www.goodreads.com/book/show/40022099-saman	1998	205	2026-03-19 19:26:56.223752
595	Yellowface	9786020672793	https://www.goodreads.com/book/show/198981124-yellowface	2023	336	2026-03-19 19:27:26.338655
596	The Day It Finally Happens - Ketika Hari Itu Tiba: Alien Jurassic Park, Manusia Abadi, dan Fenomena Lain	9786230030147	https://www.goodreads.com/book/show/231153992-the-day-it-finally-happens---ketika-hari-itu-tiba	2019	328	2026-03-19 19:28:25.136375
597	H.P. Lovecraft's The Call of Cthulhu	97862303199396	https://www.goodreads.com/book/show/204191787-h-p-lovecraft-s-the-call-of-cthulhu?ac=1&from_search=true&qid=sUciNaWKIr&rank=1	2019	282	2026-03-19 19:31:52.129358
598	Panduan Melawan Tirani	9786238661381	https://www.goodreads.com/book/show/2312458._	1902	157	2026-03-19 19:35:57.786627
599	Ichi the Witch Vol. 1	9786230073892	https://www.goodreads.com/book/show/245963376-ichi-the-witch-vol-1	2025	200	2026-03-23 05:08:08.495115
600	Duri dan Kutuk	9786020676005	https://www.goodreads.com/book/show/209187186-duri-dan-kutuk	2024	192	2026-03-23 12:24:16.881276
601	Yôgisha X No Kenshin - Kesetiaan Mr. X	9786020330525	https://www.goodreads.com/book/show/31142330-y-gisha-x-no-kenshin---kesetiaan-mr-x	2005	320	2026-03-25 15:43:04.475942
602	Ichi the Witch, Vol. 2	9786230074677	https://www.goodreads.com/book/show/235991947-ichi-the-witch-vol-2?ac=1&from_search=true&qid=omBKa4X4wP&rank=2	2025	192	2026-03-25 15:44:40.235562
603	The Tale of Dororo and Hyakkimaru Vol. 4	9786230073052	https://www.goodreads.com/book/show/244261838-the-tale-of-dororo-and-hyakkimaru-vol-4	2025	200	2026-03-25 19:17:18.540021
604	Terlontar ke Masa Silam	9786231342836	https://www.goodreads.com/book/show/229011148-terlontar-ke-masa-silam	1971	107	2026-04-01 07:14:31.770673
605	Neon Genesis Evangelion Vol. 1	9786230309502	https://www.goodreads.com/book/show/198276806-neon-genesis-evangelion-vol-1	1996	336	2026-04-01 08:50:32.211494
606	Sjahrir: Peran Besar Bung Kecil	9786024817626	https://www.goodreads.com/book/show/61335523-sjahrir	2010	223	2026-04-02 07:47:15.333008
607	Dune Mesias	9786231341662	https://www.goodreads.com/book/show/209161139-dune-mesias	1969	336	2026-04-03 03:07:57.717624
608	Climate Action 101	9786231344717	https://www.goodreads.com/book/show/245120957-climate-action-101	2025	172	2026-04-03 06:11:57.754303
609	Jujutsu Kaisen Vol. 13	9786230055850	https://www.goodreads.com/book/show/205304409-jujutsu-kaisen-vol-13	2020	200	2026-04-03 06:12:32.503816
610	Mereka Bilang, Saya Monyet!	9786020322469	https://www.goodreads.com/book/show/29537763-mereka-bilang-saya-monyet	2002	148	2026-04-04 11:05:10.236119
611	Mata yang Enak Dipandang	9786020300597	https://www.goodreads.com/book/show/18867903-mata-yang-enak-dipandang?ref=nav_sb_ss_1_24	2013	216	2026-04-04 16:15:37.589479
612	Tarian Bumi	9786020685359	https://www.goodreads.com/book/show/241996263-tarian-bumi	2000	188	2026-04-04 20:29:22.630335
613	The Tale of Dororo and Hyakkimaru Vol. 5	9786230074172	https://www.goodreads.com/book/show/245963964-the-tale-of-dororo-and-hyakkimaru-vol-5?ref=nav_sb_ss_1_20	2025	200	2026-04-04 21:08:36.159713
614	Tertolak Sebagai Manusia	9786237543480	https://www.goodreads.com/book/show/61259200-tertolak-sebagai-manusia?ref=nav_sb_ss_1_8	1948	154	2026-04-05 19:36:10.4224
615	Majapahit: Intrik, Pengkhianatan, dan Peperangan di Kerajaan Terbesar Indonesia	9786231344816	https://www.goodreads.com/book/show/243859154-majapahit	2024	464	2026-04-07 10:36:57.011998
616	Penemuan Morel	9786238476138	https://www.goodreads.com/book/show/221829787-penemuan-morel	1940	118	2026-04-08 03:58:29.008715
617	Jujutsu Kaisen Vol. 14	9786230057403	https://www.goodreads.com/book/show/210946891-jujutsu-kaisen-vol-14	2021	200	2026-04-08 18:18:08.558036
618	Heaven	9786231341181	https://www.goodreads.com/book/show/203925758-heaven	2009	232	2026-04-11 09:00:40.699992
619	Hook Your Readers	9786235467405	https://www.goodreads.com/book/show/250632279-hook-your-readers	2026	300	2026-04-11 10:26:33.980871
620	Jujutsu Kaisen Vol. 15	9786230058585	https://www.goodreads.com/book/show/215519337-jujutsu-kaisen-vol-15	2021	200	2026-04-11 11:06:27.125344
621	Norwegian Wood	9786024248352	https://www.goodreads.com/book/show/39787524-norwegian-wood	1987	426	2026-04-13 19:10:44.739441
622	Ca Bau Kan	9786024818753	https://www.goodreads.com/book/show/123169651-ca-bau-kan	1999	392	2026-04-15 04:28:12.117875
623	Neon Genesis Evangelion - Collector's Edition 02	9786230310188	https://www.goodreads.com/book/show/202427756-neon-genesis-evangelion---collector-s-edition-02	1997	344	2026-04-15 05:27:24.007284
624	Lusi Lindri	9786020633411	https://www.goodreads.com/book/show/50812292-lusi-lindri	1994	380	2026-04-16 19:17:07.153515
626	Serial Petualang Oliver Twist	9786237586074	https://www.goodreads.com/book/show/18367697-serial-petualang-oliver-twist	1838	179	2026-04-20 08:31:34.879673
627	PRAMOEDYA ANANTA TOER: Pujangga Penuh Paradoks	9786235236995	\N	2026	256	2026-04-25 13:12:46.358869
629	Sisi Balik Permadani: Catatan-Catatan tentang Seni Penerjemahan	9786020788722	https://www.goodreads.com/book/show/251425139-sisi-balik-permadani	2026	124	2026-05-03 12:16:24.489564
630	Keangkuhan dan Prasangka	9786238476022	https://www.goodreads.com/book/show/221829660-keangkuhan-dan-prasangka	1813	471	2026-05-03 12:17:31.824634
631	The Tokyo Zodiac Murders - Pembunuhan Zodiak Tokyo	9789792285918	https://www.goodreads.com/book/show/15724390-the-tokyo-zodiac-murders---pembunuhan-zodiak-tokyo	1981	360	2026-05-04 04:54:25.685217
632	Selusoh Sialang Rayo	9786347010384	https://www.goodreads.com/book/show/231107172-selusoh-sialang-rayo	2022	1164	2026-05-05 05:54:12.681348
633	Para Priyayi: Sebuah Novel	9786238668687	https://www.goodreads.com/book/show/247516689-para-priyayi	1992	432	2026-05-10 15:33:51.423911
634	My Hero Academia 1	9786024285883	https://www.goodreads.com/book/show/36226984-my-hero-academia-1	2014	192	2026-05-10 15:38:52.657005
635	My Hero Academia, Vol. 2	9786024286675	https://www.goodreads.com/book/show/25111261-my-hero-academia-vol-2?ref=nav_sb_ss_2_17	2015	207	2026-05-14 06:52:30.962241
636	Chelkash and Other Stories	9786238476596	https://www.goodreads.com/book/show/370665.Chelkash_and_Other_Stories?ac=1&from_search=true&qid=rXRL6pHgTt&rank=1	1894	94	2026-05-14 13:37:12.087095
637	Kalatidha	9786020622842	https://www.goodreads.com/book/show/2040560.Kalatidha?ref=nav_sb_ss_1_9	2007	234	2026-05-16 04:46:06.097058
638	My Hero Academia, Vol. 3	9786024286668	https://www.goodreads.com/book/show/25814001-my-hero-academia-vol-3?ref=nav_sb_ss_3_17	2015	190	2026-05-17 09:01:51.89726
639	Tujuh yang Digantung	6267714685978	https://www.goodreads.com/book/show/251468380-tujuh-yang-digantung?ac=1&from_search=true&qid=hpseRflFGh&rank=1	1908	160	2026-05-18 16:21:03.742032
640	Naruto Bind Up 27	9786230077838	https://www.goodreads.com/book/show/137331216-naruto?ref=nav_sb_ss_2_9	2010	328	2026-05-27 23:50:11.094229
641	My Hero Academia, Vol. 4	9786024287924	https://www.goodreads.com/book/show/25814066-my-hero-academia-vol-4?ref=nav_sb_ss_1_18	2015	189	2026-05-28 00:08:12.408817
642	Ruang bagi Perempuan	9786237543633	https://www.goodreads.com/book/show/63248630-ruang-bagi-perempuan?ref=nav_sb_ss_1_16	1929	160	2026-05-29 04:34:52.07293
643	Macbeth	9789791685269	https://www.goodreads.com/book/show/43913694-macbeth?ac=1&from_search=true&qid=wMP4CdKKuX&rank=1	1623	214	2026-05-31 09:16:53.472658
644	Hamlet	9786025170218	https://www.goodreads.com/book/show/43545845-hamlet	1601	216	2026-05-31 15:26:21.766365
645	Mrs. Dalloway	9786237586661	https://www.goodreads.com/book/show/60594141-mrs-dalloway	1925	252	2026-05-31 15:30:04.883916
646	Gramsci: Catatan-Catatan dari Penjara	9786231647986	https://www.goodreads.com/book/show/244934641-gramsci	2024	216	2026-05-31 15:54:38.961893
647	The Count of Monte Cristo	9786231860743	https://www.goodreads.com/book/show/233995500-the-count-of-monte-cristo	1846	628	2026-05-31 15:54:59.359502
648	Kisah Seribu Satu Siang dan Malam	9786237586029	https://www.goodreads.com/book/show/57516801-kisah-seribu-satu-siang-dan-malam	1979	360	2026-05-31 15:57:39.493119
649	Doctor Zhivago	9786237586210	https://www.goodreads.com/book/show/130440.Doctor_Zhivago?ac=1&from_search=true&qid=r3QsEUwR1S&rank=1	1957	592	2026-05-31 15:59:18.050756
650	A Christmas Carol	9789791685085	https://www.goodreads.com/book/show/52762824-a-christmas-carol	1843	156	2026-05-31 15:59:39.432513
651	PKI Sibar: Persekutuan Aneh antara Pemerintah Belanda dan Orang Komunis di Australia	9786029402476	https://www.goodreads.com/book/show/24589063-pki-sibar	2014	196	2026-05-31 16:00:20.304549
652	On Anarchism	9786237624530	https://www.goodreads.com/book/show/203890.On_Anarchism?ref=nav_sb_ss_2_8	1972	453	2026-05-31 16:01:55.646632
653	On Signs	9786236166802	https://www.goodreads.com/book/show/60436896-on-signs	2022	\N	2026-05-31 16:02:29.661593
654	Menunggu Godot	9789791684682	https://www.goodreads.com/book/show/29364108-menunggu-godot	1951	266	2026-05-31 16:02:56.517847
655	Wisanggeni: Sang Buronan	9786231891860	https://www.goodreads.com/book/show/1025833.Wisanggeni?ref=nav_sb_ss_1_10	1984	92	2026-05-31 16:04:31.851295
656	Bimala	9789791685054	https://www.goodreads.com/book/show/6087605-bimala?ref=nav_sb_ss_1_6	2008	284	2026-05-31 16:07:00.754443
657	Seribu Burung Bangau	9789791685177	https://www.goodreads.com/book/show/3682390-seribu-burung-bangau?ref=nav_sb_ss_1_20	1952	202	2026-05-31 16:09:07.088569
658	Kesatuan Kreatif	9786025792342	https://www.goodreads.com/book/show/2692676-kesatuan-kreatif?ref=nav_sb_ss_3_9	1922	188	2026-05-31 16:10:39.06664
659	Batu-Batu Lapar	9789791685108	https://www.goodreads.com/book/show/12027778-batu-batu-lapar?ref=nav_sb_ss_1_15	1895	251	2026-05-31 16:12:56.864884
660	Identity - Identitas	9789799845986	https://www.goodreads.com/book/show/2785943-identity---identitas	1997	175	2026-05-31 16:13:47.873251
661	Seribu Kunang-Kunang di Manhattan	9786025226069	https://www.goodreads.com/book/show/42958942-seribu-kunang-kunang-di-manhattan	1972	98	2026-05-31 16:14:31.019895
662	Merahnya Merah	9789797753122	https://www.goodreads.com/book/show/53998647-merahnya-merah	1968	200	2026-05-31 16:15:01.984535
663	Botchan	9786237543671	https://www.goodreads.com/book/show/123027647-botchan	1906	178	2026-05-31 16:15:32.477273
664	Sang Rahib	9786239396657	https://www.goodreads.com/book/show/57134191-sang-rahib	1796	512	2026-05-31 16:15:59.978315
665	Oliver Twist	9786020361086	https://www.goodreads.com/book/show/18254.Oliver_Twist?from_search=true&from_srp=bcnISL50we&qid=1	1838	608	2026-05-31 16:19:09.165142
666	Seks, Teks, Konteks; Esei-esei Kritik Sastra 2001-2021	9786329679165	https://www.goodreads.com/book/show/244721663-seks-teks-konteks-esei-esei-kritik-sastra-2001-2021?ref=nav_sb_ss_1_12	2025	650	2026-05-31 16:20:28.785695
667	Senja dan Cinta yang Berdarah	9789797098513	https://www.goodreads.com/book/show/23125037-senja-dan-cinta-yang-berdarah	2014	822	2026-05-31 16:21:08.675255
668	Genom: Kisah Spesies Manusia Dalam 23 Bab	9786020339764	https://www.goodreads.com/book/show/35835615-genom	1999	466	2026-05-31 16:21:47.944839
669	Bintang Merah Menerangi Dunia Ketiga	9786020788012	https://www.goodreads.com/book/show/55400518-bintang-merah-menerangi-dunia-ketiga	2017	137	2026-05-31 16:22:19.989602
670	Ny. Talis: Kisah Mengenai Madras	9786020672663	https://www.goodreads.com/book/show/199009980-ny-talis	1996	279	2026-05-31 16:22:51.126841
671	Senyap yang Lebih Nyaring	6262702323558	https://www.goodreads.com/book/show/244807341-senyap-yang-lebih-nyaring	2025	402	2026-05-31 16:24:32.942603
672	Usaha Menulis Silsilah Bacaan: Blog 2008-2011, 2015-2019	62-6270-2323-558	https://www.goodreads.com/book/show/244807384-usaha-menulis-silsilah-bacaan	2025	412	2026-05-31 16:26:12.103797
673	Kekekalan	9786027328440	https://www.goodreads.com/book/show/34660173-kekekalan	1990	366	2026-05-31 16:27:22.068648
674	PLUTO: Urasawa x Tezuka, Vol. 8	9786230319891	https://www.goodreads.com/book/show/6889271-pluto?ref=nav_sb_ss_1_7	2009	256	2026-05-31 16:29:02.846028
675	My Hero Academia 05	9786024287955	https://www.goodreads.com/book/show/40212337-my-hero-academia-05	2015	192	2026-05-31 16:29:28.650739
676	Neon Genesis Evangelion. Collector's Edition Vol. 3	9786230312182	https://www.goodreads.com/book/show/210513717-neon-genesis-evangelion-collector-s-edition-vol-3	2000	368	2026-05-31 16:31:04.818369
677	Neon Genesis Evangelion Vol. 4	9786230313103	https://www.goodreads.com/book/show/217086278-neon-genesis-evangelion-vol-4	2021	368	2026-05-31 16:31:46.941364
678	Neon Genesis Evangelion - Collector's Edition Vol. 5	9786230314629	https://www.goodreads.com/book/show/221181047-neon-genesis-evangelion---collector-s-edition-vol-5	2021	352	2026-05-31 16:32:48.592093
679	Neon Genesis Evangelion Vol. 6	9786230315657	https://www.goodreads.com/book/show/228328434-neon-genesis-evangelion-vol-6	2021	352	2026-05-31 16:33:24.795469
680	My Hero Academia Vol. 6	9786024287931	https://www.goodreads.com/book/show/40993604-my-hero-academia-vol-6	2015	192	2026-05-31 16:35:48.777243
681	My Hero Academia Vol. 7	9786024800604	https://www.goodreads.com/book/show/42185290-my-hero-academia-vol-7	2016	192	2026-05-31 16:36:07.520997
682	My Hero Academia 08	9786024800611	https://www.goodreads.com/book/show/43569816-my-hero-academia-08	2016	192	2026-05-31 16:36:27.122866
683	My Hero Academia 09	9786024800628	https://www.goodreads.com/book/show/44046757-my-hero-academia-09	2016	192	2026-05-31 16:36:45.549324
684	My Hero Academia Vol. 10	9786024802103	https://www.goodreads.com/book/show/45431824-my-hero-academia-vol-10	2016	192	2026-05-31 16:37:02.053778
685	My Hero Academia 11	9786024802141	https://www.goodreads.com/book/show/49576171-my-hero-academia-11	2016	208	2026-05-31 16:37:16.083877
686	My Hero Academia 12	9786024802530	https://www.goodreads.com/book/show/51896227-my-hero-academia-12	2017	200	2026-05-31 16:38:01.562268
687	My Hero Academia Vol. 13	9786024809515	https://www.goodreads.com/book/show/51377539-my-hero-academia-vol-13	2017	184	2026-05-31 16:38:37.088921
688	My Hero Academia Vol. 14	9786024809713	https://www.goodreads.com/book/show/52763050-my-hero-academia-vol-14	2017	208	2026-05-31 16:39:11.060302
689	My Hero Academia Vol. 15	9786024809720	https://www.goodreads.com/book/show/54393670-my-hero-academia-vol-15	2017	192	2026-05-31 16:40:42.178138
690	My Hero Academia Vol. 16	9786230302824	https://www.goodreads.com/book/show/57033170-my-hero-academia-vol-16	2017	192	2026-05-31 16:41:02.362823
691	My Hero Academia Vol. 17	9786230302848	https://www.goodreads.com/book/show/57754853-my-hero-academia-vol-17	2018	192	2026-05-31 16:41:20.547602
692	My Hero Academia Vol. 18	9786230303937	https://www.goodreads.com/book/show/58422820-my-hero-academia-vol-18	2018	184	2026-05-31 16:42:03.167714
693	My Hero Academia Vol. 19	9786230306884	https://www.goodreads.com/book/show/60593496-my-hero-academia-vol-19	2018	192	2026-05-31 16:42:26.822251
694	My Hero Academia Vol. 20	9786230307270	https://www.goodreads.com/book/show/61137037-my-hero-academia-vol-20	2018	200	2026-05-31 16:43:06.601934
695	My Hero Academia Vol. 21	9786230308031	https://www.goodreads.com/book/show/61778567-my-hero-academia-vol-21	2018	200	2026-05-31 16:43:25.459123
696	My Hero Academia 22	9786230308741	https://www.goodreads.com/book/show/62829783-my-hero-academia-22	2019	192	2026-05-31 16:43:43.769195
697	My Hero Academia Vol. 23	9786230309373	https://www.goodreads.com/book/show/75608227-my-hero-academia-vol-23	2019	200	2026-05-31 16:44:02.302701
698	My Hero Academia Vol. 24	9786230310669	https://www.goodreads.com/book/show/156426250-my-hero-academia-vol-24	2019	192	2026-05-31 16:44:20.310779
699	My Hero Academia Vol. 25	9786230311239	https://www.goodreads.com/book/show/196498331-my-hero-academia-vol-25	2019	200	2026-05-31 16:44:41.552245
700	My Hero Academia Vol. 27	9786230312526	https://www.goodreads.com/book/show/210518317-my-hero-academia-vol-27	2020	184	2026-05-31 16:45:07.786579
701	My Hero Academia Vol. 28	9786230313585	https://www.goodreads.com/book/show/213752147-my-hero-academia-vol-28	2020	184	2026-05-31 16:45:26.023628
702	Vagabond Bind up Edition 01	9786230077562	https://www.goodreads.com/book/show/251261253-vagabond-bind-up-edition-01	2026	488	2026-05-31 16:45:53.317158
703	Krisis Kebebasan	9789794618639	https://www.goodreads.com/book/show/3268162-krisis-kebebasan?ac=1&from_search=true&qid=KaCn2iwz6X&rank=1	1988	118	2026-05-31 16:50:24.141642
704	Kembara dari Paris ke Jawa	9786239396640	https://www.goodreads.com/book/show/57146583-kembara-dari-paris-ke-jawa	1832	144	2026-06-04 18:17:44.050326
705	Penghancuran PKI	9789793731254	https://www.goodreads.com/book/show/12962696-penghancuran-pki	2011	383	2026-06-04 18:18:05.163476
706	tanah air imajiner	9786239072186	https://www.goodreads.com/book/show/537762.Imaginary_Homelands	2019	74	2026-06-12 01:10:24.572547
707	Dr. Stone Vol. 1	9786230033926	https://www.goodreads.com/book/show/61646423-dr-stone-vol-1	2017	200	2026-06-27 19:53:57.978454
708	Monster 08	9786230319143	https://www.goodreads.com/book/show/250574011-monster-08	2008	432	2026-06-28 15:24:58.242414
709	Dr. Stone Vol. 2	9786230035982	https://www.goodreads.com/book/show/63050026-dr-stone-vol-2	2017	192	2026-06-28 15:27:37.863673
710	Dr. Stone Vol. 3	9786230036781	https://www.goodreads.com/book/show/75262654-dr-stone-vol-3	2017	200	2026-06-28 15:28:44.610342
711	Dr. Stone Vol. 4	9786230046179	https://www.goodreads.com/book/show/123726049-dr-stone-vol-4	2018	192	2026-06-28 15:28:59.937507
712	Dr. Stone Vol. 5	9786230047886	https://www.goodreads.com/book/show/198687396-dr-stone-vol-5	2018	200	2026-06-28 15:29:15.059385
713	Dr. Stone Vol. 6	9786230050633	https://www.goodreads.com/book/show/202427792-dr-stone-vol-6	2018	192	2026-06-28 15:29:29.793477
714	Dr. Stone Vol. 7	9786230052316	https://www.goodreads.com/book/show/203988660-dr-stone-vol-7	2018	200	2026-06-28 15:29:45.759072
715	Dr. Stone Vol. 8	9786230058578	https://www.goodreads.com/book/show/215519203-dr-stone-vol-8	2018	192	2026-06-28 15:29:58.507211
716	Dr. Stone Vol. 9	9786230059599	https://www.goodreads.com/book/show/217999730-dr-stone-vol-9	2019	200	2026-06-28 15:30:11.133671
717	Dr. Stone Vol. 10	9786230060656	https://www.goodreads.com/book/show/220150454-dr-stone-vol-10	2019	192	2026-06-28 15:30:25.172244
718	Dr. Stone Vol. 11	9786230061738	https://www.goodreads.com/book/show/222806038-dr-stone-vol-11	2019	200	2026-06-28 15:30:38.476334
719	Dr.STONE 12	9786230068553	https://www.goodreads.com/book/show/231645501-dr-stone-12	2019	200	2026-06-28 15:32:05.009825
720	Dr. Stone Vol. 13	9786230069178	https://www.goodreads.com/book/show/231950360-dr-stone-vol-13	2019	192	2026-06-28 15:32:22.170354
721	Tragedimu Komediku	9786235869186	https://www.goodreads.com/book/show/199223222-tragedimu-komediku	2023	276	2026-06-28 15:33:22.892802
722	Lapar	9789794618509	https://www.goodreads.com/book/show/18493141-lapar	1890	284	2026-06-28 15:33:45.281051
723	Tista Vol. 1	9786230068560	https://www.goodreads.com/book/show/228904644-tista-vol-1	2008	202	2026-06-28 15:35:09.528086
724	Tista Vol. 2	9786230068577	https://www.goodreads.com/book/show/228904777-tista-vol-2	2008	234	2026-06-28 15:35:49.006047
725	One Piece 11: Penjahat Besar Dari Timur	9789792049435	https://www.goodreads.com/book/show/6811282-one-piece-11	1999	189	2026-06-28 15:36:43.255797
726	One Piece 12: Legenda Dimulai	9789792050813	https://www.goodreads.com/book/show/6811320-one-piece-12	2000	181	2026-06-28 15:37:27.395147
727	One Piece 13: Tenanglah!!	9789792051605	https://www.goodreads.com/book/show/6811332-one-piece-13	2000	188	2026-06-28 15:38:04.665502
728	One Piece 14: Naluri	9789792053258	https://www.goodreads.com/book/show/6811343-one-piece-14	2000	189	2026-06-28 15:39:14.032935
729	One Piece 15: Terus!	9789792054156	https://www.goodreads.com/book/show/6811352-one-piece-15	2000	203	2026-06-28 15:39:30.771039
730	One Piece 16: Hasrat Yang Diwariskan	9789792055382	https://www.goodreads.com/book/show/6811354-one-piece-16	2000	\N	2026-06-28 15:39:47.606205
731	One Piece 19: Pemberontakan	9789792058789	https://www.goodreads.com/book/show/6811427-one-piece-19	2001	213	2026-06-28 15:40:04.234693
732	One Piece 20: Perang Penentuan Di Alubarna	9789792059793	https://www.goodreads.com/book/show/6811431-one-piece-20	2001	213	2026-06-28 15:40:27.673239
733	One Piece 21: Negara Ideal	9789792061444	https://www.goodreads.com/book/show/6811461-one-piece-21	2001	191	2026-06-28 15:40:45.995817
734	One Piece 23: Petualangan Vivi	9789792063431	https://www.goodreads.com/book/show/6811478-one-piece-23	2002	212	2026-06-28 15:41:23.809861
735	Attack on Titan, Bind Up 6	9786230060267	https://www.goodreads.com/book/show/18077957-attack-on-titan-vol-11?from_search=true&from_srp=true&qid=jftalq0cn1&rank=1	2013	192	2026-06-28 15:44:05.448123
736	Attack on Titan Bind Up 4	9786230058059	https://www.goodreads.com/book/show/17568815-attack-on-titan-vol-7?from_search=true&from_srp=true&qid=BzjaYL1q6h&rank=1	2012	192	2026-06-28 15:45:25.162047
737	Attack on Titan Bind Up 5	9786230059391	https://www.goodreads.com/book/show/18077955-attack-on-titan-vol-9?from_search=true&from_srp=true&qid=ZyC5BRVHvo&rank=1	2012	192	2026-06-28 15:46:24.685898
738	Rafilus	9786232425255	https://www.goodreads.com/book/show/1422434.Rafilus?ref=nav_sb_ss_1_7	1988	198	2026-06-28 15:47:24.601398
739	Idiota	9796213120031	https://www.goodreads.com/book/show/222856651-la-idiota?from_search=true&from_srp=true&qid=H2p8flQmOu&rank=2	1946	55	2026-06-28 15:56:33.129908
740	In the Cherry Wood of Full Bloom	9796213120031	https://www.goodreads.com/book/show/218072939-in-the-cherry-wood-of-full-bloom	1947	43	2026-06-28 15:59:21.102687
741	Kurotanimura	9796213120031	https://www.goodreads.com/book/show/19253586-kurotanimura?from_search=true&from_srp=true&qid=DHRyNB2zim&rank=2	2012	36	2026-06-28 16:01:09.877685
742	Perempuan yang mencuci cawat iblis biru	9796213120031	https://www.goodreads.com/book/show/26064658	1949	226	2026-06-28 16:06:34.979051
743	Putri Yonaga dan Mimio	9796213120031	https://www.goodreads.com/book/show/18999538-yonagahime-to-mimio?from_search=true&from_srp=true&qid=XvGLOLjvgV&rank=1	2012	110	2026-06-28 16:08:02.4951
744	Kemerosotan Peradaban	9796213120031	https://www.goodreads.com/book/show/56088971-discourse-on-decadence?from_search=true&from_srp=true&qid=TOhoD9lrmI&rank=1	1946	100	2026-06-28 16:10:49.042246
\.


--
-- Data for Name: genres; Type: TABLE DATA; Schema: public; Owner: default
--

COPY public.genres (genre_id, genre_name, description, created_at) FROM stdin;
1	Fantasy	\N	2025-12-27 06:58:48.984619
2	Novel	\N	2025-12-27 06:58:49.242031
3	Children	\N	2025-12-27 06:58:49.489335
4	Crime	\N	2025-12-27 06:58:49.736923
6	History	\N	2025-12-27 06:58:49.99121
7	Science	\N	2025-12-27 06:58:50.242533
8	Myth	\N	2025-12-27 06:58:50.489902
9	Manga	\N	2025-12-27 06:58:50.737748
10	Romance	\N	2025-12-27 06:58:50.985994
11	Religion	\N	2025-12-27 06:58:51.26574
12	Politics	\N	2025-12-27 06:58:51.513688
13	Architecture	\N	2025-12-27 06:58:51.774306
14	Comic	\N	2025-12-27 06:58:52.021862
15	Literature	\N	2025-12-27 06:58:52.288237
16	Fabel	\N	2025-12-27 06:58:52.536263
17	Philosophy	\N	2025-12-27 06:58:52.784214
18	Psychology	\N	2025-12-27 06:58:53.031749
19	Entertainment	\N	2025-12-27 06:58:53.280712
20	Biography	\N	2025-12-27 06:58:53.529076
21	Health	\N	2025-12-27 06:58:53.776321
22	Horror	\N	2025-12-27 06:58:54.023897
23	Tech	\N	2025-12-27 06:58:54.272559
24	Economic	\N	2025-12-27 06:58:54.540716
25	Social	\N	2025-12-27 06:58:54.82956
26	Engineering	\N	2025-12-27 06:58:55.07721
28	Biology	\N	2025-12-27 06:58:55.324862
29	Self Improvement	\N	2025-12-27 06:58:55.57657
30	Cerpen	\N	2025-12-28 10:55:18.405889
\.


--
-- Data for Name: goodreads_data; Type: TABLE DATA; Schema: public; Owner: default
--

COPY public.goodreads_data (book_id, goodreads_id, description, average_rating, ratings_count, reviews_count, publication_date, publisher, language, series, series_position, original_title, original_publication_year, cover_url, awards, genres, scrape_date, last_updated) FROM stdin;
2	29235308	How is this book unique?  \n  Unabridged (100% Original content)  \n Formatted for e-reader  \n Font adjustments & biography included  \n Illustrated   \n \n About Moby Dick by Herman Melvillel   \n \nMoby-Dick; or, The Whale (1851) is a novel by Herman Melville considered an outstanding work of Romanticism and the American Renaissance. A sailor called Ishmael narrates the obsessive quest of Ahab, captain of the whaler Pequod, for revenge on Moby Dick, a white whale which on a previous voyage destroyed Ahab's ship and severed his leg at the knee. Although the novel was a commercial failure and out of print at the time of the author's death in 1891, its reputation as a Great American Novel grew during the 20th century. William Faulkner confessed he wished he had written it himself, and D. H. Lawrence called it "one of the strangest and most wonderful books in the world", and "the greatest book of the sea ever written". "Call me Ishmael" is one of world literature's most famous opening sentences. The product of a year and a half of writing, the book is dedicated to Nathaniel Hawthorne, "in token of my admiration for his genius", and draws on Melville's experience at sea, on his reading in whaling literature, and on literary inspirations such as Shakespeare and the Bible. The detailed and realistic descriptions of whale hunting and of extracting whale oil, as well as life aboard ship among a culturally diverse crew, are mixed with exploration of class and social status, good and evil, and the existence of God. In addition to narrative prose, Melville uses styles and literary devices ranging from songs, poetry and catalogs to Shakespearean stage directions, soliloquies and asides.	\N	587716	24777	1851-10-17	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1456046599i/29235308.jpg	{}	{}	2025-01-16 16:47:49.818	2025-01-16 16:47:49.818
4	43523263	A Study in Scarlet is a detective mystery novel written by Sir Arthur Conan Doyle, introducing his new characters, "consulting detective" Sherlock Holmes and his friend and chronicler, Dr. John Watson, who later became two of the most famous characters in literature. leads with a heading which establishes the role of Dr. Watson as narrator and sets up the narrative stand-point that the work to follow is not fiction.	\N	468691	18798	1887-12-26	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1547057318i/43523263.jpg	{}	{}	2025-01-16 17:15:03.808	2025-01-16 17:15:03.808
5	162823	'When you have eliminated all which is impossible, then whatever remains, however improbable, must be the truth.'\n\nIn this, the final collection of Sherlock Holmes adventures, the intrepid detective and his faithful companion Dr Watson examine and solve twelve cases that puzzle clients, baffle the police and provide readers with the thrill of the chase.\n\nThese mysteries - involving an illustrious client and a Sussex vampire; the problems of Thor Bridge and of the Lions Mane; a creeping man and the three-gabled house - all test the bravery of Dr Watson and the brilliant mind of Mr Sherlock Homes, the greatest detective we have ever known.\n\nContains 12 stories published 1921–1927.\n* "The Adventure of the Mazarin Stone" (1921)\n* "The Problem of Thor Bridge" (1922)\n* "The Adventure of the Creeping Man" (1923)\n* "The Adventure of the Sussex Vampire" (1924)\n* "The Adventure of the Three Garridebs" (1924)\n* "The Adventure of the Illustrious Client" (1924)\n* "The Adventure of the Three Gables" (1926)\n* "The Adventure of the Blanched Soldier" (1926)\n* "The Adventure of the Lion's Mane" (1926)\n* "The Adventure of the Retired Colourman" (1926)\n* "The Adventure of the Veiled Lodger" (1927)\n* "The Adventure of Shoscombe Old Place" (1927)	\N	28633	1504	1927-06-15	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1316863480i/162823.jpg	{}	{}	2025-01-17 05:41:20.966	2025-01-17 05:41:25.3
6	174713	In this illuminating and thoughtful book, Will and Ariel Durant have succeeded in distilling for the reader the accumulated store of knowledge and experience from their four decades of work on the ten monumental volumes of "The Story of Civilization." The result is a survey of human history, full of dazzling insights into the nature of human experience, the evolution of civilization, the culture of man. With the completion of their life's work they look back and ask what history has to say about the nature, the conduct and the prospects of man, seeking in the great lives, the great ideas, the great events of the past for the meaning of man's long journey through war, conquest and creation - and for the great themes that can help us to understand our own era.To the Durants, history is "not merely a warning reminder of man's follies and crimes, but also an encouraging remembrance of generative souls ... a spacious country of the mind wherein a thousand saints, statesman, inventors, scientists, poets, artists, musicians, lovers, and philosophers still live and speak, teach and carve and sing..."Designed to accompany the ten-volume set of "The Story of Civilization, The Lessons of History" is, in its own right, a profound and original work of history and philosophy.	\N	18413	1769	1968-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1387722025i/174713.jpg	{}	{}	2025-01-16 17:29:45.054	2025-01-16 17:29:45.054
7	37663320	This book opens up a little secret of ABODAY; an architectural firm based in Jakarta.	\N	50	7	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1514089476i/37663320.jpg	{}	{}	2025-01-16 17:37:56.037	2025-01-16 17:37:56.037
8	1510028	Seri ini merupakan lanjutan trilogi Kartun Riwayat Peradaban. Buku ini dibuka dengan kisah kerajaan-kerajaan Indian terakhir di Benua Amerika sebelum Columbus datang, fajar sains modern di Eropa, dan diakhiri dengan perdebatan sengit mengenai rumusan konstitusi Amerika Serikat.\n\nSecara kocak namun mendalam, Gonick melukiskan kejamnya era penaklukan bangsa-bangsa Eropa terhadap bangsa-bangsa lain. Sebaliknya, ia juga lukiskan munculnya kesadaran untuk merdeka di Amerika dan tarik-ulur para pendiri bangsa ketika merancang konstitusi.	\N	1123	86	2006-12-26	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1466598699i/1510028.jpg	{}	{}	2025-01-16 17:44:37.844	2025-01-16 17:44:37.844
9	1297872	The most eloquent translation of Homer's epic chronicle of the Greek hero Odysseus and his arduous journey home after the Trojan War	\N	1127456	21501	0700-12-31	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1436895011i/1297872.jpg	{}	{}	2025-01-16 17:19:32.612	2025-01-16 17:19:32.612
10	170448	Librarian's note: There is an Alternate Cover Edition for this edition of this book here.\n\nA farm is taken over by its overworked, mistreated animals. With flaming idealism and stirring slogans, they set out to create a paradise of progress, justice, and equality. Thus the stage is set for one of the most telling satiric fables ever penned –a razor-edged fairy tale for grown-ups that records the evolution from revolution against tyranny to a totalitarianism just as terrible. \nWhen Animal Farm was first published, Stalinist Russia was seen as its target. Today it is devastatingly clear that wherever and whenever freedom is attacked, under whatever banner, the cutting clarity and savage comedy of George Orwell’s masterpiece have a meaning and message still ferociously fresh.	\N	4155644	108702	1945-08-16	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1325861570i/170448.jpg	{}	{}	2025-01-16 17:24:11.122	2025-01-16 17:24:11.122
11	\N	Cinta adalah ketika dia mulai mencintai orang lain dan kamu masih bisa tersenyum dan berkata, “Aku turut berbahagia untukmu.”\nApabila cinta tidak bertemu, bebaskan dirimu, biarkan hatimu kembali ke alam bebas lagi. Kau mungkin menyadari, bahwa kamu menemukan cinta dan kehilangannya, tapi, ketika cinta itu mati, kamu tidak perlu mati bersama cinta itu.\n\nCinta yang sebenarnya adalah ketika kamu menitikkan air mata dan masih peduli terhadapnya. Cinta adalah ketika dia tidak mempedulikanmu dan kamu masih menunggunya dengan setia.\n\nBerisi puisi-puisi dan syair pilihan karya Kahlil Gibran. Tema yang diambil sangat dekat dengan kehidupan sehari-hari, seperti cinta dan rindu, kesedihan dan juga kebahagiaan, kebebasan, persahabatan, keluarga, kasih sayang, keinginan, jodoh, pernikahan, dan kehidupan serta kematian. Syair-syair tersebut begitu mendalam maknanya, dan senantiasa menarik, seperti tidak pernah bosan untuk dibaca.\n\nKahlil Gibran berbicara tentang sesuatu yang mendasar dalam hidup. Sesuatu yang sangat dekat dengan kehidupan kita sehari-hari, dan tak terpisahkan dari diri kita. Seperti cinta dan rindu, kesedihan dan kebahagiaan, kebebasan, persahabatan, keluarga, kasih sayang, keinginan, jodoh, pernikahan, juga tentang kehidupan dan kematian. Syair-syair Gibran mengajak kita untuk berselancar ke relung rahasia diri kita sendiri.	\N	\N	\N	\N	Checklist			\N	Kahlil Gibran: Setitis Air Mata, Seulas Senyum	\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/9786237046240_kahlil-gibran.jpg	{}	{}	2025-01-17 04:57:02.642	2025-01-17 04:57:06.739
12	35967270	Kejatuhan adalah sebuah novel filosofis yang pertama kali diterbitkan pada tahun 1956. Merupakan karya fiksi lengkap terakhir Albert Camus. Bersetting di Amsterdam, Kejatuhan terdiri dari serangkaian monolog dramatis oleh “hakim-pengaku” yang memproklamirkan diri Jean-Baptiste Clamence, saat dia merenungkan kehidupannya kepada seorang asing.\n\nDalam sejumlah besar pengakuan, Clamence menceritakan keberhasilannya sebagai seorang pengacara Paris kaya yang sangat dihormati oleh rekan-rekannya; krisisnya, dan “kejatuhan” penghabisannya dari kehormatan, dimaksudkan untuk memohon, dalam istilah sekuler, Kejatuhan Manusia di Taman Firdaus.\n\nNovel Kejatuhan mengeksplorasi tema ketidakbersalahan, hukuman penjara, ketiadaan, dan kebenaran. Dalam sebuah sanjungan untuk Albert Camus, filsuf eksistensialis Jean-Paul Sartre menggambarkan novel ini sebagai “mungkin yang paling indah dan paling sedikit dipahami” dari buku-buku Camus.\n\nNovel ini juga mengeksplorasi salah satu keyakinan membingungkan Albert Camus: kita masing-masing bertanggung jawab. Untuk semuanya. Selama zamannya, era Perang Dunia II, menurut Camus, semua orang hidup bersalah karena perang itu. Jika mereka tidak secara langsung menyebabkan perang itu, maka adalah kesalahan mereka karena tidak menghentikannya.	\N	118841	7596	1956-05-15	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1502252556i/35967270.jpg	{}	{}	2025-01-17 04:31:20.618	2025-01-17 04:31:20.618
13	67397	The text is a prose rendition of Nizami's 12th-century poetic masterpiece, in which he reshapes the legends of Majnun, the quintessential romantic fool, into a tale of the ideal lover. For the Sufis, Majnun represents the perfect devotee of the "religion of the heart," and the story is an allegory of the soul's longing for God. This is a beautiful production, and it includes a final chapter newly translated from the Persian by Omid Safi and Zia Inayat Khan.	\N	4068	509	1192-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1170672261i/67397.jpg	{}	{}	2025-01-16 17:45:59.883	2025-01-16 17:45:59.883
14	15721334	Di negeri para bedebah, kisah fiksi kalah seru dibanding kisah nyata.\n\nDi negeri para bedebah, musang berbulu domba berkeliaran di halaman rumah.\n\nTetapi setidaknya, Kawan, di negeri para bedebah, petarung sejati tidak akan pernah berkhianat.	\N	11020	1249	2012-07-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1340606900i/15721334.jpg	{}	{}	2025-01-16 17:55:09.403	2025-01-16 17:55:09.403
15	3078425	Markesot adalah sosok lugu nan cerdas, mbeling, terkadang misterius. Dalam kesehariannya dengan sahabat-sahabatnya, Markembloh, Markasan, Markemon, dan lain-lain yang tergabung dalam Konsorsium Para Mbambung (KPMb), Markesot memperbincangkan seabrek problem masyarakat kita. Dari konflik politik internasional sampai soal celana. Dari tasawuf hingga filosofi urap. Dalam gaya bertutur khas Jawa Timuran yang penuh canda dan sindiran, Markesot mengajak kita meneropong kehidupan secara arif dan menemukan hakikat di balik nilai-nilai semu yang merajalela.\n\nMarkesot Bertutur adalah salah satu karya emas dalam perjalanan kepengarangan Emha Ainun Nadjib. Setelah lama "absen", buku ini hadir kembali menyapa pembaca. Dan terbukti, apa yang diperbincangkannya masih terus relevan dengan kondisi Indonesia.	\N	458	31	1993-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1234252798i/3078425.jpg	{}	{}	2025-01-16 17:54:04.777	2025-01-16 17:54:04.777
16	58015819	Dengan sensitivitasnya yang luar biasa, Kahlil Gibran merajut sebuah kisah cinta tentang sepasang kekasih yang indah dan menggelora. Namun, cinta mereka bukanlah tanpa halangan. Tradisi, tabu, politik, dan ketidakadilan menjadi penghalang bagi keduanya untuk bersatu.\n\nSederhana, tetapi penuh makna. Itulah yang membuat karya Gibran begitu dekat di hati pembacanya. Diterjemahkan secara langsung oleh Sapardi Djoko Damono, penyair legendaris Indonesia, menjadikan napas liris dan puitis di dalam buku ini tetap semakin terasa keindahannya.\n\nInilah salah satu kisah cinta paling megah dan paling dikenal sepanjang masa, yang sering disandingkan bersama Romeo & Juliet karya William Shakespeare.	\N	112	24	1922-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1620746019i/58015819.jpg	{}	{}	2025-01-16 17:25:15.737	2025-01-16 17:25:15.737
17	44443381	Mbok Jamu berselendang ungu itu menjadi sumber kebahagiaan bagi orang-orang yang datang dan pergi membeli dagangannya. Bukan karena rambut hitam kehijauannya, lereng keningnya yang bening, atau kecantikannya yang tiada tara. Para pria menjadi platinum member jamunya karena Mbok Jamu pintar memosisikan diri sebagai konco wingking. Perempuan yang posisinya selangkah di belakang pria?\n\nTunggu dulu, arti dari istilah itu baru tepat jika kita memandang hidup secara linear. Padahal, hidup ini berputar bagai Cokro Manggilingan. Ia di belakang, tapi sejatinya juga berada di depan karena takdir siklus. Itulah keistimewaan Mbok Jamu.\n\nOrang-orang di sekitarnya memang tak pernah peka membaca pertanda. Berbeda dengan Sabdo Palon dan Budak Angon, dua makhluk spiritual dari Majapahit dan Pajajaran yang selalu mengikuti Mbok Jamu dalam senyap. Mereka yakin, Mbok Jamu bukanlah perempuan biasa. Dirinya pastilah putri raja yang menitis ke raga rakyat biasa. Meski terlihat tak berkuasa, ia mampu menjadi penentu kemenangan dalam kompetisi pilpres tahun kapan pun.\n\nSekarang ... mari saksikan bersama, ke mata angin manakah Jangka Jayabaya dan Uga Wangsit Siliwangi, kedua ramalan akbar Jawa dan Sunda yang untuk kali pertamanya dihimpun dalam sebuah kitab, menemui takdirnya dalam cinta Mbok Jamu?	\N	38	6	2018-11-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1571119975i/44443381.jpg	{}	{}	2025-01-16 17:46:25.652	2025-01-16 17:46:25.652
56	\N		\N	\N	\N	\N				\N		\N	https://mpn.kominfo.go.id/perpus/lib/minigalnano/createthumb.php?filename=images/docs/16099.jpg.jpg&width=200	{}	{}	2025-01-18 19:17:27.103	2025-01-18 19:17:28.807
18	39335587	Pertanyaan P-NP (sesuatu yang bisa diperhitungkan-sesuatu yang tidak bisa diperhitungkan) muncul setelah Prima didatangi oleh hantu yang mengajarinya cara berhitung dan berbagai teori matematika di dalam mimpi. Teka-teki itu semakin mengusiknya ketika ia bertemu Tarsa—si cerdas yang juga memiliki pertanyaan sama tentang P-NP. Namun, meski telah mencurahkan seluruh hidupnya, Prima tak juga mampu menemukan jawabannya. Tentu. Karena, siapa pula manusia di dunia ini yang bisa menjawab kapan ia akan dimatikan?	\N	383	111	2018-04-30	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1523574518i/39335587.jpg	{}	{}	2025-01-16 17:47:41.379	2025-01-16 17:47:41.379
19	\N	Apakah para akademisi yang ingin mendalami ilmu psikologi perlu memiliki referensi terkait pandangan dari segi agama yang menjadi psikologi Islam?, jawabannya perlu. Terlebih lagi pembahasan terkait jiwa manusia secara khusus hingga menguliti hingga ke dasar ilmunya. Dalam buku ini, Ibnu Sina tidak hanya mengungkapkan jiwa dalam perspektif sains, namun juga dalam agama sekaligus. Pendapat Ibnu Sina yang berbeda dengan ilmuwan lainnya, dengan mencantumkan bukti aqli dan naqli menjadikan bacaan ini menarik untuk dijadikan rujukan utama ilmuwan Psikologi.\n\nBuku referensi psikologi ini adalah hasil terjemahan dari buku Ahwal An-Nafs yang berisikan dua judul pembahasan sekaligus yakni Ahwal An-Nafs (Ragam Perilaku Jiwa) dan Tsalats Rasa'il fi An-Nafs (Tiga Risalah Tentang Jiwa).\n\nDalam dua bukunya ini, Ibnu Sina merumuskan berbagai pengertian jiwa dan persoalan di dalamnya, disertai dengan pembahasan yang mudah dimengerti walau telah berumur lebih dari 1000 tahun yang lalu. Hingga saat ini buku ini masih menjadi referensi utama Ilmu Psikologi Dunia dan telah direkomendasikan oleh Prof. Dr. Ahmad Fuad al-Ahwani, guru besar filsafat Cairo University.\n\nTiap filsuf selalu melibatkan pembahasan mengenai jiwa manusia. Oleh karena itu merupakan hal yang paling dekat dengan diri kita, tetapi begitu samar dan misterius. Setiap kali para filsuf menyangka bahwa mereka sudah lebih mengetahuinya, mendalami hakikatnya, mengungkapkan rahasianya, dan memahami esensinya, tetapi ilmu itu tetap seperti fatamorgana, padahal esensinya merupakan suatu pemandangan yang indah.	\N	\N	\N	\N	Anak Hebat Indonesia			\N	Terapi Jiwa	\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/picture_meta/2023/7/21/thmajvcxzu2lkfse4bunj7.jpg	{}	{}	2025-01-17 05:05:34.914	2025-01-17 05:05:39.066
20	\N	Para seniman lokal di Kota Lviv, Ukraina menciptakan TTS dengan tinggi 30 meter yang akhirnya menutupi dinding luar sebuah apartemen. Ini adalah jilid ketiga dari seri buku terlaris TTS Pilihan Kompas yang penikmatnya membludak hingga mancanegara. Nyonya Susi yang berusia 49 tahun adalah seorang perempuan Indonesia yang sudah lama tinggal atau menetap di Melbourne, Australia. Nyonya Susi mengaku bahwasannya buku TTS Pilihan Kompas sanggup atau dapat mengobati rasa rindunya kepada Tanah Air. Ia bahkan sampai membeli sebanyak 20 eksemplar untuk dibagi-bagikan kepada para sahabatnya yang juga bermukim di negeri Kanguru tersebut.\n\nSelalu ada kisah menarik di seputar TTS. Misalnya saja pada tahun 2011, seorang mahasiswa dari Universitas Binus Jakarta mendapatkan penghargaan Guinness World Records setelah dirinya berhasil memecahkan rekor mengisi TTS dengan mengumpulkan 550 orang untuk bisa mengerjakan TTS bersama-sama. Buku TTS Pilihan Kompas Jilid 3 Edisi Baru ini antara lain berisikan uraian step by step cara mudah membuat TTS. Tujuan yaitu agar Anda tidak hanya sekedar menjadi pengisi TTS saja, tetapi Anda juga mampu untuk berkarya dengan membuat TTS sendiri. Dua kontributor TTS Kompas yang bernama Bambing Danu Ismoyo dan Dwiwoko Soeprijono juga berbagi pengalaman. Banyak cara untuk mengasah pikiran dengan seru dan asyik dengan mainkan semua TTS yang berada di dalam buku TTS Pilihan Kompas Jilid 3 Edisi Baru ini.	\N	\N	\N	\N				\N		\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/9786024123680_TTS-Pilihan-Kompas-Jilid-3-Edisi-Baru.jpg	{}	{}	2025-01-17 05:28:13.583	2025-01-17 05:28:17.687
21	\N	Sinopsis Buku\nIBNU SINA ( AVICENNA ) : SARJANA, PUJANGGA, DAN FILSUF BESAR DUNIA (BIOGRAFI SINGKAT 980-1037 M)\nBapak Filsuf, demikianlah julukan bagi Ibnu Sina yang diberikan oleh sebagian besar filsuf Islam di Timur. Ia merupakan tokoh kerohanian yang besar. Ajaran filsafatnya yang dikenal baik sebagai mashai atau filsafat paripatetik, merupakan sintesis ajaran-ajaran Islam dengan filsafat aristotelianisme dan neoplatonisme, menjadi sebuah dimensi intelektual yang permanen dalam dunia Islam.\n\nFilsafatnya bertahan sebagai ajaran yang hidup sampai hari ini, khususnya filsafat abad pertengahan.\n\nDalam sejarah pemikiran abad pertengahan, sosok Ibnu Sina memiliki banyak hal unik. Di antara para filsuf muslim, ia tidak hanya unik, tetapi juga memperoleh penghargaan yang tinggi hingga masa kini.\n\nIa adalah satu-satunya filsuf besar Islam yang telah berhasil membangun sistem filsafat yang lengkap dan terperinci, suatu sistem yang telah mendominasi tradisi filsafat muslim beberapa abad.\nBuku ini adalah kombinasi biografi, hikayah dan sejarah tapi lebih menitikberatkan kepada pemahaman filsafat islam pada masa itu.\nBuku ini juga menerangkan bagaimana cerdasnya Ibnu Sina di berbagai bidang ilmu, karena tentu saja orang sekarang lebih mengenal Ibnu Sina hanya sebagai Bapak Kedokteran saja. Jauh lebih dari, buku ini juga mengajak kita untuk menilik bagaimana sumbangsih filsafatnya bagi dunia ini.\nDitulis oleh lulusan Ponpes dan Sastra Arab, buku ini kaya akan hal-hal baru yang mungkin. Dapat digali lebih dalam lagi, ditunjang dengan bahasanya yang mudah dimengerti.\n\n	\N	\N	\N	2018-01-01	Anak Hebat Indonesia			\N	Ibnu Sina	\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/9786026380210_Ibnu-Sina.jpg	{}	{}	2025-01-17 05:08:11.841	2025-01-17 05:08:15.825
22	60646275	Dunia sufi Islam merupakan sebuah dunia yang cukup menarik untuk di perbincangkan. Sejak zaman dahulu embrio-embrio mistik telah ada dalam sanubari setiap muslim. Namun eksistensinya mencuat setelah muncul tokoh-tokoh yang melambungkan ajaran tersebut.\n\nSalah satu tokoh yang terkenal dengan mistiknya adalah Maulana Jalaluddin Rumi. Seorang ahli mistik yang tak hanya tenggelam dalam kesufiannya secara personal. Namun ia juga menjadi seorang pioner atas berdirinya tarekat yang berusaha untuk bertaqarrub dengan Sang Pencipta. Dalam ajaran-ajarannya, Rumi mengajarkan bahwa ekstase cinta merupakan hal penting untuk mencapai kedekatan yang sesungguhnya.\n\nDan dalam buku ini, terangkum jejak-jejak langkah kehidupan Sang Sufi Jalaluddin Rumi, baik yang erat hubungannya dengan kesufian, kesusastraan, maupun gambaran karya-karyanya yang hingga kini masih fenomenal. Dalam jejak sang sufi tersebut tentunya tersimpan banyak pelajaran yang dapat dijadikan pijakan untuk generasi sekarang yang mulai minim akan kecintaanya terhadap Dzat Yang Maha Pencinta.	\N	3	1	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1647669841i/60646275.jpg	{}	{}	2025-01-16 15:55:50.123	2025-01-16 15:55:50.123
241	7477710	Tenma, que cayó en la trampa preparada por Johan, es ahora un supuesto asesino en serie buscado por la policía. Tras eludir por los pelos el cerco policial, persigue a Johan para evitar otro asesinato y demostrar su inocencia. \n\nCavando en su pasado, se acerca cada vez más al monstruo. \n\nNina ha sido capturada por un grupo neonazi. Mientras, Tenma la busca, pues es la única persona que puede decirle quién es Johan, y al hacerlo descubre un dato terrorífico. Los ultraderechistas conspiran para convertirlo en el nuevo Hitler.	\N	5868	407	1995-12-31	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1262465699i/7477710.jpg	{}	{}	2025-01-16 16:46:03.262	2025-01-16 16:46:03.262
23	41948416	“Kenapa sekarang ini manusia menjadi sangat pemarah?”\n\nPertanyaan yang dilontarkan Emha Ainun Nadjib di atas tampaknya mewakili banyak orang di negeri ini. Kita semua menjadi sering marah pada hal-hal yang justru sebelumnya bisa kita tertawakan bersama. Belakangan, kita juga cepat marah pada perbedaan pendapat, termasuk dalam menentukan “siapa yang paling pantas menjadi pemimpin”.\n\nSetiap orang pasti memilih pemimpin yang bisa dipercaya.Namun, percaya membabi buta kepada pemimpin tersebut justru bisa menjadi persoalan. Berprasangka baik memang perbuatan yang dianjurkan. Namun, selalu berprasangka baik tanpa sedikit pun meletakkan sikap kritis malah membahayakan.\n\nMelalui Pemimpin yang "Tuhan", sekali lagi Emha mengajak kita untuk mawas diri. Tidak hanya kepada pemimpin yang lalim, tetapi juga berhati-hati agar jangan sampai terjebak menjadi rakyat yang lalim.	\N	46	7	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1537403590i/41948416.jpg	{}	{}	2025-01-16 17:04:26.435	2025-01-16 17:04:26.435
24	44312826	Milik sufi bukan sekadar huruf dan tinta,\ntapi hati putih penaka salju.\nMilik cendekiawan adalah\njejak-jejak pena.\nApakah milik sufi?\nJejak-jejak kaki.\nRumi bukanlah seorang penulis ‘irfân seperti Ibn ‘Arabi—yang menulis puluhan jilid buku. Karya utama Rumi adalah Matsnawi, kumpulan puisi, yang darinya kutipan-kutipan dalam buku ini diambil. Namun, justru karena efisiensi dari medium puisi ini, Rumi bisa mengungkapkan apa yang diungkapkan dalam berjilid-jilid buku oleh seorang arif seperti Ibn ‘Arabi, ke dalam puisi-puisi yang relatif jauh lebih pendek.\n\nDalam buku ini, Haidar Bagir, menjelaskan secara ringkas, populer, dan sistematis prinsip-prinsip tasawuf melalui keindahan puisi-puisi Rumi.	\N	25	10	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1552135117i/44312826.jpg	{}	{}	2025-01-16 17:49:50.126	2025-01-16 17:49:50.126
25	7015635	A definitive compendium of food wisdom\n\nEating doesn't have to be so complicated. In this age of ever-more elaborate diets and conflicting health advice, Food Rules brings a welcome simplicity to our daily decisions about food. Written with the clarity, concision and wit that has become bestselling author Michael Pollan's trademark, this indispensable handbook lays out a set of straightforward, memorable rules for eating wisely, one per page, accompanied by a concise explanation. It's an easy-to-use guide that draws from a variety of traditions, suggesting how different cultures through the ages have arrived at the same enduring wisdom about food. Whether at the supermarket or an all-you-can-eat buffet, this is the perfect guide for anyone who ever wondered, "What should I eat?"	\N	47960	4289	2008-12-29	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1348526224i/7015635.jpg	{}	{}	2025-01-16 17:29:31.383	2025-01-16 17:29:31.383
26	59511152	BUKU ALJABAR BERGAMBAR YANG ENAK DIBACA DAN LENGKAP.\nMari belajar aljabar bersama Larry Gonick! Dari operasi dasar (tambah/kurang/kali/bagi), konsep persamaan dan peubah, sampai grafik dan kuadrat, semua dijelaskan dengan kartun menarik dan humor segar, juga banyak contoh dan latihan soal. Kombinasi sempurna hiburan dan pendidikan—cocok untuk siswa SMA, mahasiswa, guru, dosen, orangtua, dan profesional.	\N	149	16	2015-01-14	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1635751075i/59511152.jpg	{}	{}	2025-01-16 17:12:00.578	2025-01-16 17:12:00.578
27	17245	You can find an alternative cover edition for this ISBN here and here.\n\nWhen Jonathan Harker visits Transylvania to help Count Dracula with the purchase of a London house, he makes a series of horrific discoveries about his client. Soon afterwards, various bizarre incidents unfold in England: an apparently unmanned ship is wrecked off the coast of Whitby; a young woman discovers strange puncture marks on her neck; and the inmate of a lunatic asylum raves about the 'Master' and his imminent arrival.\n\nIn Dracula, Bram Stoker created one of the great masterpieces of the horror genre, brilliantly evoking a nightmare world of vampires and vampire hunters and also illuminating the dark corners of Victorian sexuality and desire.\n\nThis Norton Critical Edition includes a rich selection of background and source materials in three areas: Contexts includes probable inspirations for Dracula in the earlier works of James Malcolm Rymer and Emily Gerard. Also included are a discussion of Stoker's working notes for the novel and "Dracula's Guest," the original opening chapter to Dracula. Reviews and Reactions reprints five early reviews of the novel. "Dramatic and Film Variations" focuses on theater and film adaptations of Dracula, two indications of the novel's unwavering appeal. David J. Skal, Gregory A. Waller, and Nina Auerbach offer their varied perspectives. Checklists of both dramatic and film adaptations are included.\n\nCriticism collects seven theoretical interpretations of Dracula by Phyllis A. Roth, Carol A. Senf, Franco Moretti, Christopher Craft, Bram Dijkstra, Stephen D. Arata, and Talia Schaffer.\n\nA Chronology and a Selected Bibliography are included.	\N	1360277	52952	1897-05-25	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1387151694i/17245.jpg	{}	{}	2025-01-17 05:27:02.085	2025-01-17 05:27:06.172
28	24337340	"Pertahankan keutuhan tanah leluhur\nyang telah diwariskan ini\ndari rongrongan bangsa mana pun.\ntidak ada sejengkal pun tanah yang direbut bangsa lain.\nPertahankan ini!"\n\n"Gunakan segala kemampuan yang ada.\nTidak ada alasan untuk menunda.\nGunakan tanganmu, gunakan kakimu,\ngunakan otakmu untuk menggugah akalmu.\n\n"Jika engkau lelah bayangkan sakitmu.\nJika engkau sakit bayangkan semangatmu.\nJika semangatmu kendur\ntarik gendewamu, putar tobakmu,\ndan benamkan keris di dada musuhmu!"\n\n"Tidak ada lagi darah sia-sia dan air mata.\nHanya keutuhan wilayah dan Jagat Gilang Gemilang\nmenjadi hak tlatah Nusantara."\n"Hancurkan Mongolia!"\n\nRaden Wijaya - 1293 Masehi	\N	73	16	2014-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1420616601i/24337340.jpg	{}	{}	2025-01-16 17:39:57.808	2025-01-16 17:39:57.808
29	24636477	"Kalian orang-orang tolol yang percaya kepada mimpi.”\n\nMimpi itu memberitahunya bahwa ia akan memperoleh seorang kekasih. Dalam mimpinya, si kekasih tinggal di kota kecil bernama Pangandaran. Setiap sore, lelaki yang akan menjadi kekasihnya sering berlari di sepanjang pantai ditemani seekor anjing kampung. Ia bisa melihat dadanya yang telanjang, gelap dan basah oleh keringat, berkilauan memantulkan cahaya matahari. Setiap kali ia terbangun dari mimpi itu, ia selalu tersenyum. Jelas ia sudah jatuh cinta kepada lelaki itu.	\N	1987	360	2015-02-28	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1464281082i/24636477.jpg	{}	{}	2025-01-16 17:18:01.689	2025-01-16 17:18:01.689
251	364956	As a kid, Monkey D. Luffy vowed to become King of the Pirates and find the legendary treasure called the "One Piece." The enchanted Gum-Gum Fruit has given Luffy the power to stretch like rubber--and his new crewmate, the infamous pirate hunter Roronoa Zolo, strikes fear into the hearts of other buccaneers! But what chance does one rubber guy stand against Nami, a thief so tough she specializes in robbing pirates...or Captain Buggy, a fiendish pirate lord whose weird, clownish appearance conceals even weirder powers? It's pirate vs. pirate in the second swashbuckling volume of One Piece!	\N	27554	1364	1998-04-03	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1388531494i/364956.jpg	{}	{}	2025-01-16 17:37:16.587	2025-01-16 17:37:16.587
30	107556672	Buku dengan Judul Semua Bisa Menjadi Programmer Python Basic ini merupakan buku serial awal seri pemrograman Python. Walaupun Anda tidak memiliki dasar pemrograman, Anda dapat mengikutinya. Materi yang saling berhubungan membuat Anda dengan mudah belajar dari buku ini. Bahasa Pemrograman Python merupakan sepuluh bahasa terpopuler di dunia. Menggunakan bahasa Python, kesan pertama yang kita dapat adalah cepat dalam eksekusi program, baik program kecil maupun program besar. Buku ini membahas mulai dari program sederhana hingga database dan game, dengan menggunakan database populer saat ini MySQL dan SQLite. Dengan mengacu beberapa buku penulis yang best seller, maka terciptalah buku ini. Dalam buku ini penulis membahas dari awal instalasi Python hingga Anda dapat menjadi programmer database dengan Python. Topik yang dibahas dalam buku ini - Mengenal Python - Program Sekuensial - Program Pencabangan - Program Pengulangan - Fungsi - Program Database MySQL - Program Database SQLite - Program List - Program GUI Python - Program Game Python - Pemrograman OOP Python - dan lain-lain	\N	0	0	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1679354686i/107556672.jpg	{}	{}	2025-01-17 04:47:04.349	2025-01-17 04:47:08.168
31	\N	Diskusi dan topik tentang kecerdasan buatan selalu mengundang sisi positif (optimis) dan sisi negatif (pesimis) dari pengaruhnya terhadap kehidupan manusia di masa depan. Sisi menakutkan lebih mendominasi topik-topik perdebatan dibandingkan dengan nilainya bagi kehidupan ke depannya.\n\n	\N	\N	\N	\N				\N	Ainomics - Economic Artificial Intelligence: Hubungan Manusia dengan Mesin	\N	https://ebooks.gramedia.com/ebook-covers/77085/image_highres/BLK_AEAIHMDM2022835474.jpg	{}	{}	2025-01-17 05:51:55.552	2025-01-17 05:51:59.777
32	219733614	Kebudayaan Jawa sangat kaya dengan nilai-nilai kemanusiaan, keilahian, serta kearifan lokal; juga sangat memperhatikan makna-makna hidup batiniah.\n\nLebih dari itu, budaya Jawa sangat terbuka untuk beradaptasi dengan berbagai tradisi, termasuk tradisi religius-spiritual, seperti Hindu, Buddha, dan Islam, sehingga membuatnya semakin beragam.\n\nBuku ini membahas kearifan-kearifan Jawa dengan menyelami makna, menemukan hikmah serta kaitannya dengan kehidupan masa kini. Siapa pun, dari latar belakang apa pun, bisa mengambil pelajaran dan menerapkan nilai-nilai luhur di dalamnya.	\N	13	2	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1727599590i/219733614.jpg	{}	{}	2025-01-16 17:49:40.828	2025-01-16 17:49:40.828
33	6687124	Walaupun masa silam Tarekat Mason Bebas masih tersimpan dalam bentuk gedung-gedungnya yang lama, dalam ingatan ia telah pudar terhapus oleh waktu. Studi ini bermaksud untuk memberi tempat kepada Tarekat Mason Bebas dalam sejarah Indonesia selama abad 19 dan 20,\n\nMenjadi pertanyaan yang menggelitik pemikiran bagaimana para anggota dari suatu pergerakan yang merupakan ciptaan dari masa Penerangan Eropa dan yang dipindahkan ke bumi Asia, dapat mewujudkan cita-cita humanistis dalam suatu alam kolonial.\n\nBagaimana pula para anggota Tarekat Mason Bebas bereaksi terhadap ketimpangan-ketimpangan dan apa pula usaha mereka untuk memperbaiki keadaan ini? Memang harus diakui bahwa dengan keanggotaan yang hanya berjumlah paling banyak 1500 orang dan yang tersebar di antara 25 satuan loge, pengaruhnya pasti terbatas. Namun, di mana mereka bergerak hasilnya nyata.\n\nPenulis, seorang sejawaran dari Universitas Amsterdam, juga berpendapat bahwa loge merupakan tempat-tempat dimana orang belanda dan orang Indonesia dapat bertemu pada tingkat yang sama tinggi dan sama rendah dalam suasana saling menghormati.	\N	46	9	1994-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1487507021i/6687124.jpg	{}	{}	2025-01-16 18:03:15.143	2025-01-16 18:03:15.143
34	7299756	Dari sisa ingatan dan catatan minim, mantan enam rekan (Freddy Lasut sudah almarhum) perjalanan Soe Hok-gie (27 tahun) dan Idhan Dhanvantari Lubis (20), berusaha menulis ulang kesaksian sebenarnya tragedi perjalanan pendakian ke Gunung Semeru, nun 40 tahun lalu.\n\nAristides Katoppo (71): “Hok-gie terlalu cepat pergi, tapi kalau dia hidup dan sekarang sudah umur 67 tahun, apa dia tahan tidak bikin ribut-ribut?” Komentar Tides yang 40 tahun lalu, meminta bantuan helikopter TNI-AL untuk turun di alun-alun kota Malang, lalu ikut heli itu mengapung dan terkurung kabut tebal di kaki Semeru.\n\nMaman Abdurachman (65): “Saya mungkin shock dan dehidrasi, hingga menganggu kondisi dan stres. Tapi saya tidak kesurupan, saya sadar kok, cuma merasa badan panas sekali,” ujar Maman yang tidak trauma dan tidak melarang putrinya menjadi pendaki gunung Mapala UI juga.\n\nHerman Onesimus Lantang (69): “Saya yang memimpin evakuasi jenasah Hok-Gie dan Idhan, tentu dengan dukungan tim besar dari Malang dan Jakarta, bukan sendirian,” ujar Herman yang ketimpa sial juga. “Masih lelah dan baru masuk ke kota Malang, gua diinterogasi polisi, diperiksa dan diminta kesaksian tentang Hok-Gie dan Idhan itu bukan korban pembunuhan di Semeru.”\n\nAnton Wijana alias Wiwiek (63): “Aku satu-satunya anggota tim yang fasih berbahasa Jawa, makanya aku diajak turun duluan bareng Tides, untuk minta bantuan ke Malang dan Jakarta. Yang terjadi kemudian, ya kerja sama kemanusiaan sejati,” kata Wiwiek yang mengenang solidaritas zaman dirinya aktif di pergerakan anak-anak jaket kuning UI.\n\nRudy Badil (64): “Saya datang, saya lihat, saya rasakan, saya pulang, saya bertanggung jawab dan saya menulis kembali kesaksian peristiwa 40 tahun lalu itu,” ujarnya, seraya menjelaskan sulitnya merekonstruksi ingatan masa 40 tahun lalu. “Salah-salah dikit, harap maklum.”\n\n---oOo---\n\nSoe Hok-Gie … sekali lagi, diharapkan menjadi buku baru sekali lagi tentang Soe Hok-gie, berisikan kisah saksi hidup pendakian di zaman awal Orde Baru. Juga saksi-saksi teman dan konco dekat Hok-gie dalam soal “buku pesta dan cinta di kampus UI Rawamangun-Salemba”, tentu juga perihal alam bangsanya yang baru menapak di zaman pembangunan – sebelum menapak ke zaman reformasi.\n\nBuku baru tentang Soe Hok-gie ini, khususnya akan memuat komentar dan telaah penulis dan pengamat “cuaca” sosial budaya politik budaya Indonesia. Rupanya ada kemiripan yang tidak sama tapi nyaris serupa, antara situasi sekarang dan 40-an tahun lalu.\n\nIni buku tentang perilaku dan pemikiran terhadap keadaan bangsa dan negara. Sebab dari kumpulan tulisan pilihan Hok-gie, rasanya masih cocok sebagai “bumbu bandingan”, perihal politik pemerintahan, di zamannya Hok-gie sebagai penulis muda di usia di tahun 1963-1969, sampai di zaman reformasi 2009n ini.\n\nRekan seprofesi, mantan anak-anak gerakan Orde Baru pun, masih sempat menulis tentang Hok-gie. Bukan pengamat senior saja, malah beberapa pengamat dan pemerhati yang tidak sempat berkenalan dengan Soe, ikutan menyumbangkan buah pikirannya dalam buku kecil 400-an halaman yang akan terbit khusus, di hari peringatan meninggalnya Soe dan Idhan, 16 Desember 2009 nanti.\n\nHok-gie bukan hanya tajam menulis kritik terbuka, dia juga mampu menulis puisi alam sehalus kabut Mandalawangi. Juga pilihan puisi dan lirik-lirik lagu, menunjukkan selera kepedulian Hok-gie terhadap seni budaya manusia universal tanpa batasan.\n\nKesetaraan, kepedulian dan kemajemukan merupakan garis besar dan haluan utama segala tulisan di media massa dengan nama: Soe Hok-gie.	\N	1410	98	2009-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1260412749i/7299756.jpg	{}	{}	2025-01-16 17:35:02.295	2025-01-16 17:35:02.295
35	126859481	The third title in National Geographic Little Kids First Big Book series, this book is for kids 4- to 8-years-old who LOVE dinos! The prehistoric world comes alive with dinosaurs small, big, giant, and gigantic, with stunning illustrations by Franco Tempesta—who illustrated National Geographic Kids The Ultimate Dinopedia. Bursting with fun facts and age appropriate information, each spread features a different dinosaur, along with simple text in big type that is perfect for little kids. Young dino fans will love the interactivity included in every chapter, and parents will appreciate tips to help carry readers’ experience beyond the page.	\N	976	56	2011-10-10	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1681026442i/126859481.jpg	{}	{}	2025-01-16 17:12:14.398	2025-01-16 17:12:14.398
36	1665043	It's been said that before physics students can fly with Feynman they need to walk with Halliday and Resnick. Those of us who are still toddling along, however, need Larry Gonick. Gonick's characteristically quirky drawings are teamed with physicist Art Huffman's prose to produce lessons like this: picture Sir Isaac Newton driving a Mack truck labeled "Big Inertia." Ike is talking into a CB radio, saying: "Breaker one nine: force overcomes inertia and produces acceleration. Do you read?" As the jacket copy says, "If you think a negative charge is something that shows up on your credit-card bill--if you imagine that Ohm's law dictates how long to meditate--if you believe that Newtonian mechanics will fix your car," here's the book for you. --Mary Ellen Curtin	\N	1065	92	1989-12-31	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1612049079i/1665043.jpg	{}	{}	2025-01-17 05:35:46.558	2025-01-17 05:35:50.857
37	1463296	Indonesian version of The Cartoon History of the Universe.\n\nTranslator: Frans Kowa\nEditor: Utti Setiawati, Andya Primanda\n\nSebelum Sang Waktu mulai berdetak, Semesta termampatkan dalam sebutir partikel yang panas. Dalam buku ini Larry Gonick memampatkan kira-kira 15.000.000.000 tahun perjalanan Sang Waktu ke dalam Seri Kartun Riwayat Peradaban dengan kemahiran memadukan unsur pendidikan dan hiburan. \n\nTerdiri atas tujuh bab, jilid I buku ini adalah pembuka seri Kartun Sejarah Riwayat yang menangkap peristiwa sejak Ledakan Besar sampai pemerintahan Alexander Agung. \n\nKartun Riwayat Peradaban merupakan buku pertama yang pernah ditulis oleh Larry Gonick.	\N	3529	282	1980-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1601036728i/1463296.jpg	{}	{}	2025-01-16 17:40:50.734	2025-01-16 17:40:50.734
38	23129811	Operation Protective Edge, Israel's most recent assault on Gaza, left thousands of Palestinians dead and cleared the way for another Israeli land grab. The need to stand in solidarity with Palestinians has never been greater. Ilan Pappé and Noam Chomsky, two leading voices in the struggle to liberate Palestine, discuss the road ahead for Palestinians and how the international community can pressure Israel to end its human rights abuses against the people of Palestine. On Palestine is the sequel to their acclaimed book Gaza in Crisis.	\N	10226	1380	2015-05-07	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1427756115i/23129811.jpg	{}	{}	2025-01-16 17:34:11.761	2025-01-16 17:34:11.761
678	\N	Kaworu Nagisa. Fifth Child yang dikirim langsung oleh Komite untuk bergabung dengan NERV. Apakah tujuan sebenarnya?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1730699668i/221181047.jpg	\N	\N	2026-05-31 16:32:48.611774	2026-05-31 16:32:48.611774
39	\N	Buku Intelijen: Teori Intelijen Dan Pembangunan Jaringan ini mengulas intelijen yang dikerjakan oleh negara saja, yakni Badan Intelijen Negara (BIN). Intelijen menyajikan teori-teori intelijen dan aplikasinya, agen dan rekrutmennya, pelaksanaan operasi rahasia, professional intelijen, serta beberapa pengalaman penulis dalam mengemban fungsi intelijen di jajaran Polri dan BIN. Memang, dunia intelijen sangat menarik dan penuh tantangan, seperti terekam dalam banyak buku dan film yang mengangkat tema spionase. Namun kehebatan intelijen tersebut seringkali hanya fatamorgana.\n\nRealita dunia intelijen, terlebih di Indonesia, tidak sepenuhnya seperti tergambar dalam media-media itu. Melalui edisi revisi ini, yang memuat bab tambahan tentang penyadapan (regulasi dan kontroversinya), pembaca akan memiliki gambaran lebih utuh tentang kerja dan tantangan peran intelijen di Indonesia; pengetahuan yang bisa berguna bagi profesi apapun. Serta perkembangan isu intelijen yang baru yaitu cybercrime.\n\nIntelijen: Teori Intelijen Dan Pembangunan Jaringan adalah buku yang ditulis oleh Y. Wahyu Saronto. Buku yang terdiri dari 322 halaman ini cocok untuk kamu yang ingin mengetahui tentang teori intelijen dan pembangunan jaringan. Buku ini memuat informasi yang dikemas secara jelas, lengkap, dan detail. Bahasa yang digunakan juga mudah dipahami oleh para pembaca.	\N	\N	\N	\N				\N		\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/img104_16aG7KX.jpg	{}	{}	2025-01-17 05:34:57.505	2025-01-17 05:35:01.811
40	55873408	An anthropologist's groundbreaking account of how Islamic religious authority is assembled through the unceasing labor of community building on the island of Java\n\nThis compelling book draws on Ismail Fajrie Alatas's unique insights as an anthropologist to provide a new understanding of Islamic religious authority, showing how religious leaders unite diverse aspects of life and contest differing Muslim perspectives to create distinctly Muslim communities.\n\nTaking readers from the eighteenth century to today, Alatas traces the movements of Muslim saints and scholars from Yemen to Indonesia and looks at how they traversed complex cultural settings while opening new channels for the transmission of Islamic teachings. He describes the rise to prominence of Indonesia's leading Sufi master, Habib Luthfi, and his rivalries with competing religious leaders, revealing why some Muslim voices become authoritative while others don't. Alatas examines how Habib Luthfi has used the infrastructures of the Sufi order and the Indonesian state to build a durable religious community, while deploying genealogy and hagiography to present himself as a successor of the Prophet Muḥammad.\n\nChallenging prevailing conceptions of what it means to be Muslim, What Is Religious Authority? demonstrates how the concrete and sustained labors of translation, mobilization, collaboration, and competition are the very dynamics that give Islam its power and diversity.	\N	10	2	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1615873862i/55873408.jpg	{}	{}	2025-01-16 18:12:06.423	2025-01-16 18:12:06.423
41	1725165	Gonick menjelaskan secara sederhana, jernih, dan kocak, seluk-beluk genetika mendel seperti yang dikenal dalam biologi molekuler mutakhir.	\N	971	75	1982-12-31	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1635777585i/1725165.jpg	{}	{}	2025-01-16 17:12:58.143	2025-01-16 17:12:58.143
42	58968798	BUKU KALKULUS BERGAMBAR YANG ENAK DIBACA DAN LENGKAP.\n\nLarry Gonick, kartunis yang lulusan matematika, menyajikan buku pelajaran kalkulus bergambar tingkat kuliah tahun pertama yang menjelaskan dunia fungsi, limit, turunan, dan integral. Menggunakan ilustrasi jelas dan membantu—serta humor untuk membuat ringan bahasan berat—Gonick mengajarkan dasar kalkulus, dengan banyak contoh dan latihan soal. Kombinasi sempurna hiburan dan pendidikan—cocok untuk mahasiswa, guru, dosen, orangtua, dan profesional.\n\n"Bagaimana cara memanusiakan kalkulus dan membuat konsepnya jadi menarik? Jawaban cerdas Larry Gonick adalah tokoh-tokoh kartun yang berbicara, berkomentar, bercanda—sambil mengajar persamaan dan konsep dan kegunaan kalkulus. Pencapaian luar biasa, dan sangat seru."\n– LISA RANDALL, profesor fisika Harvard University dan penulis Knocking on HeavenS Door\n\nLARRY GONICK telah membuat komik sejarah, sains, dan subjek lain selama empat puluh tahun lebih. Dia pernah menjadi pengajar kalkulus di Harvard (tempat dia mendapat gelar BAdan MA matematika) serta Knight Science Journalism Fellow di MIT. Dia staf kartunis di majalah Muse.	\N	248	34	2011-12-27	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1631329215i/58968798.jpg	{}	{}	2025-01-16 18:08:00.197	2025-01-16 18:08:00.197
43	126986253		\N	0	0	\N	\N	\N	\N	\N	\N	\N	https://dryofg8nmyqjw.cloudfront.net/images/no-cover.png	{}	{}	2025-01-16 18:14:16.137	2025-01-16 18:14:16.137
45	1723050	Jika kamu menyangka Distribusi Normal adalah bagian dari kebijakan distribusi sembako nasional; gagal menemukan siaran radio di frekuensi relatif; atau mengira heteroskedastik sinonim dengan heteroseksual, maka kamu perlu memiliki buku ini.	\N	1521	127	1993-07-14	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1472202937i/1723050.jpg	{}	{}	2025-01-16 18:02:01.457	2025-01-16 18:02:01.457
46	\N	Problem utama dalam pembuatan aplikasi web seringkali terletak pada pencetakan laporan yang tidak rapi. Jika menggunakan default tampilan di web browser hasil pencetakan tidak terlalu memuaskan. Pemisahan halaman seringkali ticlak pada batas yang diinginkan. Namun jika mengandalkan pemanfaatan aplikasi pengolah kata (word processor) yang berjalan di salah satu sistem operasi, maka sistem operasi lain tentunya tidak dapat membaca laporan tersebut dengan format yang sama, bahkan mungkin tidak ada aplikasi yang terhubung dengan laporan tersebut. Untuk itu diperlukan bentuk laporan yang universal clan dapat digunakan oleh komputer dengan sistem operasi apa pun. Laporan PDF dianggap cukup universal clan telah tersedia aplikasi pembacanya di berbagai sistem operasi, baik Windows maupun Linux. Untuk itu diperlukan kemampuan tambahan agar PHP dapat membuat laporan dalam format PDF. Buku ini membahas mengenai pembuatan laporan berbasis PDF untuk aplikasi web. Trik dalam pembuatan laporan PDF dapat ditemukan di sini untuk mempermudah Anda membuat bentuk-bentuk laporan yang diinginkan.	\N	\N	\N	2009-01-11	PT Elex Media Komputindo			\N		\N	https://perpustakaan.palcomtech.ac.id/lib/minigalnano/createthumb.php?filename=../../images/docs/201356ff.jpg.jpg&width=200	{}	{}	2025-01-17 04:44:19.052	2025-01-17 04:44:22.416
57	\N	Pada dekade terakhir ini, kemajuan yang dicapai dalam penelitian robot sungguh mengagumkan, tidak hanya mampu membuat tangan robot dengan jari-jari yang terlihat sempurna, bisa bermain musik seperti piano dan guitar. Namun juga kemampuan berdiri dan berjalan layaknya manusia.\n\nTentu kehebatan sistem robot tidak hanya terletak pada perangkat kerasnya tetapi juga perangkat lunak pengendali fungsinya. Kecanggihan perangkat lunak masih sangat terbatasi oleh perkembangan sensor peraba yang memungkinkan robot mampu mendeteksi kondisi sekelilingnya dan melakukan adaptasi melalui umpan balik ke perangkat lunak pengendali.\n\nBuku ini memuat secara garis besar konsep lengan robot berjari yang mampu melakukan berbagai fungsi dan bagaimana pengendalian secara mekanik dilakukan yaitu menyangkut kestabilan dan kerjasama antara bagian.\n\n-Sistem Robot Berlengan Banyak\n-Manipulasi Kinematik\n-Kontrol Kinematik\n-Distribusi Beban Dan Kontrol Interaksi\n-Tangan Robot Berjari Banyak\n-Optimalisasi Pegangan Dan Kontrol	\N	\N	\N	2011-01-01	Graha Ilmu			\N	Prinsip Dasar Cara Kerja Robot	\N	https://bintangpusnas.perpusnas.go.id/api/getImage/C9789797567248.JPG	{}	{}	2025-01-17 04:58:39.957	2025-01-17 04:58:43.431
47	23156483	Dalam novel ini, Elif Shafak, novelis terkemuka Turki, merangkai dua jalinan cerita dengan latar berbeda: kehidupan Ella Rubinstein, seorang ibu tiga anak yang tak bahagia dengan pernikahannya, serta kisah perjumpaan dua tokoh dari abad ke-13, Jalaluddin Rumi dan Syams dari Tabriz, seorang darwis pengembara yang eksentrik. Berdua, mereka menjelmakan puisi-puisi cinta yang tak lekang oleh waktu.\n\nElla berusia empat puluh tahun ketika menerima tawaran sebagai pembaca naskah dari suatu agen di Boston. Naskah yang menjadi tugas\npertamanya, Sweet Blasphemy, novel karya Aziz Zahara, membuat Ella hanyut dalam kisah perjumpaan Syams dan Rumi; suatu perjumpaan\nyang mengubah Rumi dari seorang ulama konvensional menjadi penyair mistik penuh semangat, penganjur cinta, dan perintis tarian ekstatis darwis yang berpusar-pusar. Empat puluh kaidah cinta yang dituturkan Syams menyadarkan Ella bahwa kisah Rumi tak lain merupakan cerminan dirinya, dan Aziz yang mirip Syams itu, memang datang untuk dia, untuk membebaskan Ella.	\N	188683	21596	2008-12-31	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1409826110i/23156483.jpg	{}	{}	2025-01-16 17:11:45.716	2025-01-16 17:11:45.716
48	\N	Apakah Anda seorang pengembang Aplikasi Hybrid dan sedang mencari cara untuk membuat Aplikasi yang benar-benar Native? Atau Anda seorang pengembang web (Web Developer) yang sedang mencari cara untuk meng-upgrade skill ke dunia pengembangan mobile?	\N	\N	\N	\N				\N		\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/9786026231178_Membuat-Aplikasi-Mobile-Native-dengan-Javascript-by-Nativescript.jpg	{}	{}	2025-01-17 05:44:27.804	2025-01-17 05:44:31.977
49	\N	Mau mengembangkan perangkat lunak dengan cepat? Menggunakan framework laravel adalah salah satu solusinya. Menurut Survey Stack Overflow 2021, laravel termasuk ke Top 15 Framework yang sering digunakan oleh software developers. Posisinya tepat berada di bawah Django sebagai framework Python, serta Angularjs dari Javascript.\n\nLaravel merupakan framework yang dapat membantu web developer dalam memaksimalkan penggunaan PHP dalam proses pengembangan website. Seperti diketahui, PHP sendiri merupakan bahasa pemrograman yang cukup dinamis. Dimana kehadiran Laravel kemudian membuat PHP menjadi lebih powerful, cepat, aman, dan simple.\n\nMenguasai Laravel memang cenderung sulit bagi sebagian besar programmer. Padahal, salah satu framework PHP ini merupakan yang paling efisien waktu jika dibandingkan dengan bentuk lainnya.\n\nSupaya lancar saat melakukan Laravel tutorial, pastikan server Anda memenuhi persyaratan berikut.\nWeb server.\nPHP >= 7.3.\nEkstensi PHP. BCMath PHP Extension. Ctype PHP Extension. Fileinfo PHP Extension. JSON PHP Extension. Mbstring PHP Extension. OpenSSL Php Extension. PDO PHP Extension. Tokenizer PHP Extension. XML PHP Extension.\nDan jangan lupa untuk sering-sering membaca buku, salah satunya adalah buku ini.\n\nBuku ini membantu Anda untuk mempelajari Laravel dengan cara yang mudah, sistematis dan menyeluruh (30 BAB). Disajikan dalam bentuk LANGKAH DEMI LANGKAH. Setiap materi disertai STUDI KASUS. Bahkan, ada beberapa materi yang tidak ada dalam dokumentasi resmi LARAVEL.	\N	\N	\N	\N				\N	Konsep Dan Implementasi Pemrograman Laravel 5	\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/konsep.jpg	{}	{}	2025-01-18 19:05:41.992	2025-01-18 19:05:43.646
50	1605929	Jika Anda percaya iklan 'tujuh dari sepuluh perempuan Indonesia memakai produk X' atau hasil penelitian 'dua dari tiga lelaki Jakarta berselingkuh', maka Anda memerlukan buku ini.	\N	17142	1728	1954-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1271217306i/1605929.jpg	{}	{}	2025-01-16 17:36:56.817	2025-01-16 17:36:56.817
51	6411322	A unique compilation of logical teasers and lateral-thinking problems designed to stretch your brainpower and strengthen your mind.\n\nRiddles, paradoxes, and conundrums have been confusing and confounding people since at least the time of the Ancient Greeks. The eponymous riddle, according to legend, was devised by Albert Einstein as a child. He claimed that only about 2% of the population would be able to work out the correct answer. There are no tricks and there is only one answer. It requires the cool application of logic to solve. And a lot of patience.\n\nEinstein's Riddle features fifty of the toughest logic problems, lateral thinking puzzles, and tests of mental agility. By turns entertaining and infuriating, the puzzles challenge our preconceptions, tell us about how we reason, and provide a rigorous intellectual workout.	\N	356	32	2009-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1312041188i/6411322.jpg	{}	{}	2025-01-16 17:28:46.111	2025-01-16 17:28:46.111
52	57018627	Warren Buffett & George Soros. Apakah Anda tahu bahwa kedua orang ini sangat dikagumi dalam dunia investasi pasar modal? Ya, mereka berdua memang sangat sukses di bidangnya, sampai-sampai apa pun perkataan mereka dapat menggerakkan sentimen pasar. Yang menarik, mereka berdua memiliki pendekatan yang berbeda saat berinvestasi. Warren Buffett terkenal dengan pendekatan ala fundamentalnya, sedangkan George Soros lebih memilih untuk melakukan trading dalam berbagai macam underlying asset. Nah, di Indonesia sendiri, masih banyak juga investor yang masih bingung memilih pendekatan mana yang paling cocok untuk berinvestasi pada pasar modal, fundamental atau teknikal? Jika Anda adalah salah satu investor saham yang masih galau karena belum menemukan gaya investasi yang cocok, maka buku ini adalah jawaban untuk menjawab rasa galau itu, karena buku ini akan mengupas tuntas tentang kedua gaya investasi tersebut secara praktikal. Menarik bukan? Tunggu apa lagi. Beli bukunya sekarang dan segera baca! Salam cuan.	\N	15	3	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1612952874i/57018627.jpg	{}	{}	2025-01-16 17:31:00.899	2025-01-16 17:31:00.899
53	159430689		\N	2	0	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1697883927i/159430689.jpg	{}	{}	2025-01-16 17:40:15.815	2025-01-16 17:40:15.815
54	\N		\N	\N	\N	\N				\N		\N	https://onesearch.id/Cover/Show?author=Khopkar%2C+S.M.&callnumber=&size=medium&title=Konsep+Dasar+Kimia+Analitik+%2F+S.M.+Khopkar&isbn=9794560669	{}	{}	2025-01-18 19:01:33.835	2025-01-18 19:01:35.226
55	\N	Dampak Plato pada kajian filsafat dan manusia jauh lebih langgeng daripada tanah airnya, Yunani. Meski Yunani hancur, gagasannya tentang matematika, sains, moral, dan teori politik masih dipelajari hingga kini. Sekalipun Plato meninggal pada 348 S.M., pemikirannya tentang penggunaan akal untuk menciptakan masyarakat yang adil dan kesetaraan individu menjadi dasar pemikiran demokrasi modern sekarang ini.\n\nOleh sebab itu, sangat penting bagi generasi muda untuk mengetahui dan menapaki jejak langkah serta pemikiran Plato yang tertulis dalam buku ini. Plato adalah salah seorang filsuf paling berpengaruh dan sekaligus menjadi panutan bagi para pemikir dunia.\n\nSinopsis\nPlato seorang filsuf Yunani yang terbesar. Minat dan daya jelajahnya sangat luas, mulai dari metafisika, seni, sastra, kebudayaan, sosial, psikologi, pendidikan, agama, politik, dan masih banyak lagi. Ia merupakan filosof yang sangat brilian dan produktif melansir pemikiran-pemikiran yang orisinal dan mendalam. Jejak pengaruh pemikiran Plato sangat kuat tertancap dalam sejarah dan peradaban umat manusia dari waktu ke waktu. Kaum beragama, agamawan, dan para pemikir agama juga banyak yang terpengaruh pemikiran Plato. Daya gugah dan getar agama banyak dipengaruhi oleh pemikiran para filosof Yunani, khususnya Plato.	\N	\N	\N	\N				\N		\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/9786023501366_9786023501366.jpg	{}	{}	2025-01-17 05:32:15.496	2025-01-17 05:32:19.797
58	38918169	Kisah tentang para pencinta, kekasih yang merindu, dan sejoli yang akhirnya harus merelakan perasaannya telah berabad-abad meramaikan sejarah manusia. Entah berapa banyak syair digubah dan lagu-lagu dinyanyikan untuk mengungkapkan tawa dan air mata karena ketiganya. Seiring berjalannya waktu dan setelah melihat berbagai peristiwa terjadi akibat semua itu, tebersit tanya di hati kita tentang apa sebenarnya arti cinta, rindu, dan rela.\n\nTarbiyah cinta Imam Al-Ghazali adalah sebuah ikhtiar membahasakan ulang konsep cinta, rindu, dan rela yang ada di dalam kitab Ihya' Ulumuddin. Penjelasan Sang Hujjatul Islam tentang tiga hal itu tidak saja akan membuka mata kita betapa Islam, di samping memberikan perhatian besar terhadap masalah yang sangat personal dan mendasar dalam hidup itu, juga mengingatkan kita tentang betapa penting menjaga kesucian hati.	\N	0	0	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1520093231i/38918169.jpg	{}	{}	2025-01-16 18:11:54.804	2025-01-16 18:11:54.804
59	58208046	Ini adalah buku tentang memahami cara kerja sistem kapitalisme modern, yang puncaknya digunakan untuk memprediksi trading. Baik itu saham, crypto, forex, index, ataupun commodity.\nPrediksi dengan akurasi nyaris 100% sebagaimana yang dilakukan pemain besar berskala dunia, seperti George Soros dan para spekulan dunia lainnya.\nMereka tidak memelototi chart sebagai panduan utama mereka. Mereka tidak melakukan diversifikasi saat melakukan serangan besar mereka. Mereka mempertaruhkan seluruh kekayaan mereka dalam serangan satu pukulan. Mereka bahkan berutang untuk itu.\n\nKarena jika kemungkinan menang sudah nyaris 100%, untuk apa kita diversifikasi?\nKarena jika kemungkinan menang sudah nyaris 100%, alangkah bodohnya jika tidak menggunakan semua resourcesyang ada, kalau perlu berutang.\nLebih dari itu, buku ini juga bercerita tentang bagaimana mengamankan diri saat krisis, bagaimana mengakumulasi kekayaan saat masa kemakmuran, dan memanennya saat krisis, juga apa yang sebaiknya kita lakukan saat kita sudah terlanjur terjerumus dalam krisis.\n"Success means vety patient, but aggressive when it's time."	\N	8	3	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1622415679i/58208046.jpg	{}	{}	2025-01-16 17:55:57.349	2025-01-16 17:55:57.349
60	\N	Sejak kemunculannya di era 70-an, sebagaimana temuan pada umumnya, NLP telah mengalami banyak perkembangan. Seiring dengan itu, NLP kian dinikmati banyak kalangan, mulai dari pebisnis, olahragawan, terapis, artis, hingga tokoh politik dunia. Konsep modeling yang ditawarkan NLP mampu menyita perhatian dan minat setiap kalangan yang mendambakan pengembangan diri, kebahagiaan, serta kesuksesan. Bagi kalangan ini, NLP mampu menjadi seperangkat alat jitu yang berfungsi untuk memprogram pikiran supaya dapat berkembang dan sukses. Tidak seperti teknik psikologi lainnya, NLP menawarkan berbagai keunikan, mulai dari landasan berpikir hingga teknik-teknik yang ada.\n\n\nDengan harapan bisa memberikan kesegaran akan kehausan ilmu NLP yang dialami pembaca, buku ini ditulis. Bagi pembaca yang masih awam dengan NLP, pun tak perlu khawatir akan menemukan kesukaran atau kebingungan ketika mempelajarinya. Buku ini diulas mulai dari bahasan paling dasar tentang NLP hingga teknik-teknik yang bisa dipraktikkan langsung.	\N	\N	\N	\N				\N		\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/9786027624801_9786027624801.jpg	{}	{}	2025-01-17 05:40:42.724	2025-01-17 05:40:47.029
61	\N	Ingin tahu tentang perusahaan startup? Apa inspirasi yang menginspirasi dan pelajaran yang bisa diambil di balik kesuksesan perusahaan-perusahaan startup?	\N	\N	\N	\N				\N		\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/207958482.jpg	{}	{}	2025-01-17 05:45:33.896	2025-01-17 05:45:38.254
62	6185416	Pujangga Jawa sejak dulu kala telah mewariskan nilai-nilai luhur untuk pembinaan budi pekerti. Empu Sedah, Empu Panuluh, Empu Kanwa< Empu Darmaja, Empu manoguna, Empu Triguna, Empu Prapanca dan Empu Tantular adalah nama besar pujangga Jawa yang turut serta dalam menganyam peradaban bangsa yang penuh dengan moralitas. Para raja, bangsawan dan rakyat jelata menjadikan ajaran itu sebagai pedoman hidup sehari-hari.\n\nKita pantas bersyukur dengan kreatifitas dan produktifitas para pujangga Jawa itu. Harkat dan martabat bangsa kita semakin mantab, karena mempunyai jati diri yang berupa ke arifan lokal. Berbagai permasalahan yang terjadi sekarang sebenarnya bisa diatasi dengan butir-butir budaya luhur warisan masa silam.\n\nSudah saatnya mutiara luhur itu kita gali terus-menerus guna menjaga sikap mental yang selalu berpijak pada sejarah. Equilibrium peradaban bangsa bisa ditumbuhkan dengan cara nuting jaman kelakone, nguri-uri prestasi leluhur yang benar-benar pantas lestari. Mumpung padhang rembulane mumpung jembar kalangane selagi kesempatan terbuka lebar.\n\nSelamat Membaca!	\N	3	1	2008-06-10	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1233553730i/6185416.jpg	{}	{}	2025-01-16 17:35:28.52	2025-01-16 17:35:28.52
63	204345983	Obat merupakan salah satu unsur penting dan sering menjadi alternatif termurah dalam upaya pemeliharaan kesehatan, terutama untuk pencegahan dan penyembuhan. Seiring meningkatnya pendidikan dan kesadaran masyarakat akan kesehatan, penggunaan obat dalam rangka pengobatan sendiri (self-medication atau self-care) juga meningkat. Tekanan ekonomi juga membuat orang lebih memilih obat bebas yang relatif murah dibanding mengeluarkan biaya dan waktu untuk berkonsultasi medis, khusus untuk gangguan sehari-hari yang hanya bersifat ringan.\n\nUntuk tujuan tersebut, tentunya tidak bisa sembarangan. Buku ini disusun dengan tujuan memberikan pengetahuan mengenai obat-obat yang dapat digunakan sendiri dalam mengatasi gangguan sehari-hari yang tidak serius, bagaimana menggunakan obat-obat bebas sederhana secara tepat dan aman.\n\nAkan tetapi, terkait masalah medis serius, tetap usahakan mencari perawatan medis yang kompeten. Informasi di sini dirancang untuk membantu Anda membuat pilihan berdasarkan informasi tentang kesehatan Anda, dan sama sekali bukan dimaksudkan sebagai pengganti untuk perawatan apa pun yang diberikan oleh dokter Anda.	\N	0	0	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1703553400i/204345983.jpg	{}	{}	2025-01-16 17:27:18.842	2025-01-16 17:27:18.842
71	27070469	Jalaluddin Rumi (1207-1273) adalah penyair sufi Persia, salah satu yang mewakili puncak tertinggi khazanah sastra Islam. “Orang suci” dari Timur ini—yang sejak bocah diramalkan oleh Fariduddin Attar akan menjadi orang masyhur yang akan menyalakan api gairah ketuhanan ke seluruh dunia—oleh Unesco digambarkan sebagai “seorang humanis, filosof, dan penyair besar milik semua umat manusia”. Namanya memang melekat abadi di hati banyak warga dunia, tak peduali apa pun agamanya, karena kemilau syair dan kandungannya yang menghunjam relung kesadaran.	\N	136	30	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1444471682i/27070469.jpg	{}	{}	2025-01-16 17:55:41.305	2025-01-16 17:55:41.305
72	5990048	Sang Nabi adalah sebuah novel-puisi yang bercerita tentang seseorang yang bernama Al-Mustafa - yang dalam bahasa Arab berarti "Yang Terpilih". Setelah mengasingkan diri di sebuah pulau terpencil selama dua belas tahun, Al-Mustafa pergi menuju sebuah kota kecil Orphalese dan mengajari manusia tentang berbagai hakikat kehidupan.	\N	312751	15633	1922-12-31	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1237167587i/5990048.jpg	{}	{}	2025-01-16 16:52:34.527	2025-01-16 16:52:34.527
73	41963828		\N	10	2	\N	\N	\N	\N	\N	\N	\N	https://dryofg8nmyqjw.cloudfront.net/images/no-cover.png	{}	{}	2025-01-16 15:58:17.76	2025-01-16 15:58:17.76
64	203850754	Buku aturan emas tentang praktik-praktik terbaik dari parenting, Seni Menjadi Orang Tua Hebat ini dengan tepat menghadirkan cara-cara kunci untuk membantu para orang tua membentuk kembali tingkah laku anak-anaknya yang menantang, menciptakan ikatan keluarga yang kuat, serta membimbing anak-anak untuk menjadi orang dewasa yang bahagia, baik hati, dan bertanggung jawab. Seni Menjadi Orang Tua Hebat merupakan peta jalan dari segala-sesuatu-yang-Anda-perlukan untuk melakukan parenting sehingga Anda akan berulang kali menggunakannya. Ahli psikologi Erica Reischer mengambil dari riset dan pengalaman klinis untuk menyarikan informasi paling bermanfaat tentang seni dan sains parenting menjadi 75 cara sederhana untuk membesarkan anak-anak yang bertumbuh dengan contoh nyata, kiat berguna, dan sarana-sarana yang dapat segera diaplikasikan oleh para orang tua. Buku ini menuntun Anda melakukan hal-hal yang dilakukan dengan baik oleh orang tua hebat, termasuk: Orang Tua Hebat mulai dengan empati Orang Tua Hebat menerima anak-anak apa adanya Orang Tua Hebat menghindari perebutan kekuasaan Orang Tua Hebat melihat tujuan pendisiplinan sebagai pembelajaran, bukan penghukuman Orang Tua Hebat memahami bahwa mereka tidak sempurna Sebagai kotak peralatan dari cara parenting paling efektif, Seni Menjadi Orang Tua Hebat dapat diakses dengan mudah, dapat diaplikasikan dalam tindakan, dan dapat diikuti dengan mudah.	\N	502	85	2016-06-06	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1702655616i/203850754.jpg	{}	{}	2025-01-16 16:49:53.947	2025-01-16 16:49:53.947
65	\N	Mendengar nama Sunan Kalijaga, gambaran yang membekas di benak kita tentu bermacam-macam banyak rumor dan cerita-cerita yang berkembang mengenai kesaktian sunan kalijaga ini bahkan cerita itu berkembang dari zaman ke zaman. Salah satu dari sembilan wali yang tergabung dalam kelompok Walisongo ini memang dikenal bukan hanya karena banyak mitos dan legenda yang menyelimuti kehidupannya. Dengan menyebut nama Sunan Kalijaga, masyarakat juga akan dihadapkan pada banyak warisan budaya yang lahir dari kepiawaian sang putra Adipati Tuban tersebut. Sunan Kalijaga merupakan seorang waliyullah, pendakwah dan penyebar agama Islam. Karakteristik dakwah yang dia bawa berbeda dari wali-wali lainnya. Pendekatan dakwah terkesan unik karena mengadaptasikan kebudayaan lokal dengan ajaran Islam membuatnya mudah diterima di semua kalangan.\nSunan Kalijaga (Raden Sahid) sebagai salah satu wali, ulama, dan penyebar agama Islam di Tanah Jawa. Buku ini secara umum membicarakan riwayat Raden Sahid atau Sunan Kalijaga sebagai salah satu wali, ulama dan penyebar agama Islam di Tanah Jawa. Secara khusus, kita akan melihat perjalanan hidup, kesaktian dan tarekat Sunan Kalijaga. Juga akan disajikan model-model dakwah serta warisan kebudayaan Sunan Kalijaga yang masih lestari hingga saat ini.\nDapatkan buku “Kesaktian dan Tarekat Sunan Kalijaga” karya Rusydie Anwar dengan harga termurah berkualitas. Produk dijamin berkualitas, pengiriman cepat, dan yang pastinya 100% Original.	\N	\N	\N	\N				\N		\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/9786025805691_Kesaktian-Dan-Tarekat-Sunan-Kalijaga.jpg	{}	{}	2025-01-17 05:53:37.505	2025-01-17 05:53:41.911
66	61980232	Belajar tentang uang dan ekonomi sama dengan mempelajari dasar kehidupan. Jangan menjalani kehidupan yang mengharuskanmu bergantung pada orang lain karena tidak memiliki uang. Tapi, kendalikanlah hidupmu secara mandiri. Semoga kehidupanmu bisa berdiri tegak di atas dasar permukaan yang kokoh.—Kutipan dari Bab "Nak, Pernikahan adalah Perjanjian Menyangkut Ekonomi"\nBuku adalah sajian terhangat yang bisa Ayah berikan. Buku ini berisi ketulusan hati Ayah, dengan cara mengeluarkan segala yang ada di hati Ayah sejak lama. Ayah dan ibumu hingga sekarang selalu berusaha memberikan hidangan terhangat untukmu. Demi menyajikan hidangan hangat tersebut, dengan rela kami hidup sederhana. Tetapi, hidangan tersebut hanya ada ketika kamu, masih bersama orangtuamu. Ini alasan kenapa Ayah menyuruhmu untuk belajar tentang ekonomi sendiri.—Kutipan dan Bab "Tetaplah Buka Matamu di Malam Hari"	\N	62	15	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1660535861i/61980232.jpg	{}	{}	2025-01-16 17:09:04.529	2025-01-16 17:09:04.529
67	52221793	Dalam dua belas karya terbaik Kahlil Gibran yaitu, Senyum dan Air Mata, Yesus Anak Manusia, Lazarus dan Kekasihnya, Pasir dan Buih, Jiwa-jiwa Membcrontak, Sayap-Sayap Patah, Dewa-Dewa Bumi, Pertanda, Kebun Sang Nabi, Si Gila, Sang Nabi, Musafir, ia menyisipkan untaian cantik kata-kata tentang cinta yang seolah dirahasiakan. Dan buku ini adalah kumpulan dari untaian kata-kata cantik tersebut. Pemaknaan yang mendalam tentang cinta membuat karya-karyanya tersebut sangat menarik dipakai sebagai bahan perenungan, bahkan bisa digunakan sebagai penguat dan pengingat bagi yang sedang dilanda cinta.	\N	2	1	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1583709083i/52221793.jpg	{}	{}	2025-01-16 17:19:02.236	2025-01-16 17:19:02.236
68	222125126	Rangkaian inovasi yang diusung oleh ilmuwan muslim pada abad pertengahan telah mengundang decak kagum dan mendapat pengakuan dari para sejarawan dan ilmuwan pada masa berikutnya.\n\nMenurut Bertrand Russell, pencapaian teknik pada era Islam seolah melampaui zamannya. Energi intelektual yang membuncah membuat tradisi inovasi berkembang pesat. Pada masa itu, sains Islam juga turut memelihara ilmu pengetahuan masa lampau dan mentransfernya ke seluruh dunia.\n\nLebih lengkapnya, dapatkan informasi akurat, data valid, dan referensi tepercaya tentang kontribusi Islam bagi dunia di dalam buku terbaik ini!	\N	1	0	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1733060617i/222125126.jpg	{}	{}	2025-01-16 17:54:22.886	2025-01-16 17:54:22.886
69	59851015	Buku di tangan pembaca ini adalah terjemahan utuh dan lengkap dari Tahâfut at-Tahâfut karya Ibn Rusyd. Inilah sanggahan, respons, dan kritik-balik Ibn Rusyd atas Tahâfut al-Falâsifah Al-Ghazâlî. Boleh dikata, Ibn Rusyd terlibat dalam “polemik filosofis” dengan Al-Ghazâlî (sebagai lawan debat anumerta) dalam khazanah dan sejarah filsafat Islam. Pengaruh pemikiran Ibn Rusyd atas kebangkitan-kembali intelektualisme filosofis di dunia Islam sesudahnya dan juga di Eropa-Barat selama Abad Pertengahan dan Zaman Renaisans—boleh dikata—sangat besar dan signifikan.\n\nDi atas semuanya itu, bagi Ibn Rusyd, agama dan filsafat sebenarnya tidak perlu saling dibenturkan dan dipertentangkan. Keduanya bisa berjalan seiringan, selaras, dan bersifat komplementer satu sama lain.	\N	1	1	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1639909932i/59851015.jpg	{}	{}	2025-01-16 17:13:12.63	2025-01-16 17:13:12.63
70	28916433	Selama ini belum ada satu pun buku yang mengulas pemikiran Syaikh al-Akbar Ibn ‘Arabi secara relatif sistematis dan lengkap, dalam bahasa Indonesia. Buku ini adalah pengantar kepada pemikiran-pemikiran yang mendalam dan luas bak samudra dari ’Ârif yang satu ini. \n\nSelain mendapatkan gambaran umum dan relatif lebih mudah dipahami, lengkap, mendalam, dan akurat, pembaca tetap dapat menikmati menu “Ibn ‘Arabi sehari-hari” yang dihidangkan di dalamnya. Di sana-sini bertebaran ceceran hikmah yang mencerahkan jiwa dan pemikiran, serta menuntun kepada pemahaman tentang berbagai misteri kehidupan kita. \n\nJudul Semesta Cinta merujuk pada titik pusat pemikiran Ibn ‘Arabi mengenai cinta sebagai sumber pemahaman tentang Islam, dalam segenap aspeknya, sekaligus menjadi konteks seluruh pembahasan dalam buku ini.	\N	24	4	2015-10-31	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1454475994i/28916433.jpg	{}	{}	2025-01-17 04:31:51.211	2025-01-17 04:31:51.211
74	\N	Wayang merupakan bahasa simbol bagi kehidupan orang Jawa dan lebih bersifat rohaniah. Orang yang melihat tokoh wayang akan melihat bayangannya sendiri.\n\nBuku Tasawuf Jawa karya Dr. Purwadi, M.Hum akan menguraikan samudera makna di balik dunia wayang dan dikaitkan dengan dunia Tasawuf Jawa, sebagai sarana bagi manusia untuk mencapai kesejatian hidup dalam konsep manunggaling kawula gusti. Tasawuf bagi orang Jawa berarti memberi kesadaran bahwa manusia dan alam semesta merupakan kesatuan dengan hakikat Ilahi (One With Devine Essence), dan dalam kesadaran mistik (Mistic Consciousness) tidak ada sesuatu pun kecuali Tuhan. Mistik yang sempurna tidak akan ada tanpa refleksi, perenungan, analisis, dan adu argumentasi. Bagaimana kita kembali ke asal mula (Mulih Mula-Mulanira) sebagai wujud penemuan jati diri untuk kembali kepada sangkan paraning dumadi. Kesempurnaan hidup, mati sajrone ngaurip, dapat dicapai dengan menghindari nafsu amarah, lawamah, sufiah, dan memupuk nafsu mutmainah. Tingkat-tingkat peribadatan yang meliputi sembah raga (Syari'Ah), Sembah Cipta (Tarikat), Sembah Jiwa (Hakikat) dan sembah rasa (Ma'Rifat), hendaknya dilakukan secara selaras. Buku ini juga menjelaskan mengenai tipologi manusia ideal (Iman, Ilmu, Amal) yang merupakan jalan utama untuk mendapatkan derajat insan kamil yaitu iman, Islam, dan ihsannya. Namun, semua itu bukan tanpa tantangan. Semakin berat orang menuju hakikat agama, hal-hal yang menjadi penghambatnya akan semakin berat.	\N	\N	\N	\N				\N		\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/img20220302_14293440.jpg	{}	{}	2025-01-17 05:24:35.248	2025-01-17 05:24:39.342
75	\N	Cupu Manik Asthagina sering menjadi simbol dari "buah kerohanian" atau ngelmu kerohanian", dan didapatkan seseorang yang memasuki dunia religius spiritual dengan menjalani lelaku prihatin, lara lapa, dan tirakat. Buku ketiga dari seri Sangkan Paraning Dumadi ini membahas makna, simbolisasi dan konteks Asthagina dalam kehidupan modern.	\N	\N	\N	2019-11-04	Elex Media Komputindo			\N	Falsafah Asthagina	\N	https://ebooks.gramedia.com/ebook-covers/49911/image_highres/ID_FA2019MTH10FA.jpg	{}	{}	2025-01-17 04:55:16.891	2025-01-17 04:55:20.816
76	\N		\N	\N	\N	\N				\N		\N	https://bpcbjatim.kemdikbud.go.id/slims/lib/minigalnano/createthumb.php?filename=images/docs/WhatsApp_Image_2022-11-13_at_19.08.40.jpeg.jpeg&width=200	{}	{}	2025-01-18 19:12:57.129	2025-01-18 19:12:58.813
77	1604439	Javanese prose by Ronggowarsito reflecting the mythology of the origin of Javanese people.	\N	52	4	1992-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1311503608i/1604439.jpg	{}	{}	2025-01-16 18:02:28.533	2025-01-16 18:02:28.533
78	51094092	Buku Mitologi Jawa: Pendidikan Moral dan Etika Tradisional ini mengangkat kandungan nilai-nilai moral, etika estetika, dan budi pekerti dalam mitos-mitos Jawa. Buku ini mampu menggali dengan teliti mitos dan menghubungkannya dengan kehidupan dan kemanusiaan yang lebih universal. Buku ini membahas tentang beragam mitos, wewaler (peringatan), nasihat tersamar, dan prinsip-prinsip hidup orang Jawa.	\N	13	2	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1581239676i/51094092.jpg	{}	{}	2025-01-16 17:06:52.954	2025-01-16 17:06:52.954
79	40110482		\N	20	3	2018-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1526165622i/40110482.jpg	{}	{}	2025-01-16 17:36:44.121	2025-01-16 17:36:44.121
80	8436049	Dia dipuji sekaligus dibenci. \nDia dipuja sekaligus dicerca. \nDia: Yesus Sang Anak Manusia. \n\nKali ini, Kahlil Gibran mencoba merekam kesaksian mereka yang hidupnya -- dengan satu dan lain cara -- pernah bersentuhan dengan hidup Yesus. Oleh Gibran, kita dipikat untuk menyusuri kisah tentang sosok yang luar biasa ini. Kisah yang belum berakhir hingga detik ini...	\N	2824	277	1928-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1276251827i/8436049.jpg	{}	{}	2025-01-16 17:38:07.688	2025-01-16 17:38:07.688
81	36277836	Suwung. Satu kata yang menjadi intisari seluruh ajaran spiritual leluhur Jawa. Suwung, yang bermakna kosong, adalah realitas terdalam kehidupan, sumber penciptaan, yang tenteram-damai sepenuhnya, melampaui suka-duka, sunyi dari gejolak emosi. Leluhur Jawa memahami Tuhan sebagai Suwung, Kemahasadaran dan Kemahakuasaan dalam bentuk kekosongan yang memangku dan meliputi seluruh keberadaan (Suwung hamengku ana). Seseorang yang telah mengalami Suwung akan hidup mengalir mengikuti dorongan Rasa Sejati yang terlahir darinya. Menyelami dan menghayati Suwung akan membantu Anda:\n\n• Membebaskan diri dari ilusi kehidupan yang membuat hidup penuh tekanan.\n• Menyadari keagungan manusia dengan segenap potensinya untuk merasakan kebahagiaan.\n• Mentransformasi diri pada tataran energi murni untuk hidup berkelimpahan.\n\nBuku ini mengulas hakikat Suwung secara saintifik dan filosofis, dilengkapi panduan menjalankan Meditasi Kasih Murni, Meditasi Air Suci, Meditasi Api Suci, Meditasi Penyembuhan Diri, Meditasi Kadewatan, dan berbagai teknik meditasi lainnya, untuk menghubungkan diri Anda dengan Suwung di dalam diri.	\N	203	28	2017-09-06	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1505979964i/36277836.jpg	{}	{}	2025-01-16 15:59:11.646	2025-01-16 15:59:11.646
82	44311062	Kitab Ikhtishar `Ihya` Ulumiddin merupakan ringkasan dari kitab legendaris berjudul `Ihya` Ulumiddin karya Sang Hujjatul Islam Imam al-Ghazali (1058-1111 M). Dikenal luas sebagai kitab referensi spiritualitas umat Islam, kitab ini diringkas sendiri oleh al-Ghazali agar tetap terjaga intisarinya, terutama untuk Anda yang sibuk.\n\nMelalui kitab monumental ini kita seperti diajak untuk membaca lebih dekat sosok Imam al-Ghazali di akhir-akhir hidupnya. Periode ketika al-Ghazali telah sempurna sebagai manusia, yakni ketika ia sampai pada pilihan untuk meninggalkan segala apa yang ia capai selama hidupnya dan memilih untuk kembali ke jalan sederhana, hidup apa adanya di tanah kelahirannya.\n\nKarya yang ditulis hampir seribu tahun yang lalu ini membahas secara lengkap inti-inti ajaran Islam sekaligus memiliki banyak keistimewaan, khususnya dalam hal tuntunan penyucian diri (tazkiyat an-nafs) seorang hamba dan karakter kepenulisan yang menarik dan unik. Tak heran, jika kitab ini begitu populer di Indonesia, khususnya di kalangan santri yang menjadikan kitab al-Ghazali ini sebagai salah satu bacaan wajib setelah al-Quran.	\N	4	2	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1552113042i/44311062.jpg	{}	{}	2025-01-16 18:15:23.466	2025-01-16 18:15:23.466
83	55233270	"Dibandingkan apa pun, filsafat mutlak perlu untuk membantu kita berdiskresi dan kritis. Dengan penuh sukacita, karya ini hendak membantu Anda." —Frédéric Lenoir	\N	290	40	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1599258970i/55233270.jpg	{}	{}	2025-01-16 17:31:27.599	2025-01-16 17:31:27.599
97	12838503	Setelah Majapahit runtuh pada 1527. Jawa kacau balau dan bermandi darah. Kekuasaan tak berpusat, tersebar praktis di seluruh kadipaten, kabupaten, bahkan desa. Perang terus-menerus menjadi untuk memperebutkan penguasa tunggal. Permata-permata kesenian, baik dibidang sastra, musik, dan arsitektur tidak lagi ditemukan. Selama hampir satu abad jawa di kungkung oleh pemerintah teror, yang berpolakan tujuan menghalalkan cara.	\N	810	106	2000-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1465274542i/12838503.jpg	{}	{}	2025-01-16 18:27:08.545	2025-01-16 18:27:08.545
84	17561448	Mahabharata bukan sekadar sebuah epik!\nIni adalah roman yang menceritakan kisah laki-laki dan perempuan heroik dan beberapa tokoh luar biasa. Karya ini adalah seni sastra dalam dirinya sendiri yang mengandung rahasia hidup, filsafat relasi sosial dan etik, dan pemikiran penting tentang masalah-masalah manusia yang sulit dicari padanannya. Namun demikian, melebihi segalanya, kisah ini menyimpan inti cerita dalam Bhagawadgita, yang merupakan karya yang sangat tinggi budinya. Hingga, wajarlah jika banyak pakar yang mengkaji Mahabharata mengatakan bahwa “apa yang tidak ada dalam karya besar ini, tidak akan ada di mana pun.”\nDengan membaca karya besar ini kita akan tahu keagungan dan kedalaman jiwa manusia. Dan, kisah ini adalah rekaman pikiran dan semangat orang-orang yang lebih mementingkan kebaikan di atas kenikmatan dan kesenangan dunia serta yang melihat misteri kehidupan secara lebih mendalam. \n Dalam epos kuno yang luar biasa dari tanah India ini, kita dapat menemukan kisah-kisah yang ilustratif dan ajaran-ajaran luhur, di samping kisah perjalanan hidup kelima Pandawa. Kita dapat mengatakan bahwa Mahabharata merupakan samudra luas dan dalam yang berisi permata dan mutiara berharga yang tak terhitung jumlahnya. Bersama dengan Ramayana buku ini merupakan sumber etika dan kebudayaan Timur yang tidak ada habis-habisnya.\n Selamat membaca!\n\n“Kebahagiaan macam apakah yang akan kita dapatkan, Oh Krishna, setelah membunuh anak-anak Destarata? Membunuh para durjana itu hanya akan menambah panjang dosa kita. Apa gunanya pembantaian berdarah ini? Apa yang kita harapkan dengan membunuh orang-orang yang kita kasihi?” ucap Arjuna menjelang perang akbar Bharatayuda.	\N	167	18	1956-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1362620740i/17561448.jpg	{}	{}	2025-01-16 17:26:29.403	2025-01-16 17:26:29.403
85	18716413	Buku bertajuk Ar-Rahiq al-Makhtum tulisan Shaikh Safiyyu al-Rahman al-Mubarakfuri ini sebenarnya telah terhasil dari pertandingan yang dianjurkan oleh Rabithah Al-Alam Al-Islami pada 1396H di Pakistan. Syarat yang ketat dalam menghasilkan karya berkualiti tentang sirah Rasulullah sallAllahu ‘alaihi wasallam telah disenaraikan. Antara syarat-syarat yang dikenakan bagi pertandingan tersebut ialah:\n\nKajian mesti perspektif, berdasarkan urutan kejadian.\nMesti bagus kualitinya dan belum pernah diterbitkan.\nPenulis mesti menyebut manuskrip dan sumber ilmiah yang menjadi landasan tulisan tersebut.\nPenulis mesti menyebut biografi lengkap tentang diri penulis dan melampirkan karya-karya ilmiah yang pernah ditulis.\nKajian mesti ditulis dengan tulisan tangan yang rapi atau ditaip.\nTulisan bebas dalam bahasa apa pun.\nHasil tulisan akan diteliti oleh panel khusus yang terdiri dari para ulama yang pakar.\nSebanyak 171 kajian telah dihantar dari seluruh dunia. 84 darinya dalam bahasa Arab, 64 dalam bahasa Urdu, 22 dalam bahasa Inggeris dan 1 dalam bahasa Perancis. Pemenang bagi pertandingan tersebut adalah seperti berikut:\n\nTempat Pertama: Shaikh Safiyyurrahman al-Mubarakfuri dari Al-Jami’ah As-Salafiyah di India.\nTempat Kedua: Dr Majid Ali Khan dari Al-Jami’ah Al-Mahalliyah Al-Islamiyyah di India.\nTempat Ketiga: Dr Nushair Ahmad Nashir, Rektor Al-Jami’ah Al-Islamiyyah Pakistan.\nTempat Keempat: Al-Ustadz Hamid Mahmud Muhammad Manshur Laimud dari Mesir.\nTempat Kelima: Al-Ustadz Abdussalam Hasyim Hafizh dari Madiah Al-Munawwarah, Arab Saudi.\nPengumuman pemenang telah diumumkan di Karachi, Pakistan pada 1398H dan telah mendapat liputan akhbar secara besar-besaran. Untuk penyerahan hadiah, satu acara khas yang penuh meriah telah diadakan pada 1399H di Makkah dengan dihadiri oleh ramai tokoh-tokoh.\n\nTersebarnya buku Ar-Rahiq Al-Makhtum adalah hasil usaha dari Rabithah Al-Alam Al-Islami yang telah menyebarkan kajian yang menjadi juara dalam pertandingan tersebut dalam bentuk buku, dan diterbitkan dalam banyak bahasa. Menurut kata-kata Shaikh Muhammad bin Ali Al-Harakan yang merupakan ahli Rabithah Al-Alam Al-Islami yang saya petik dari buku terbitan Pustaka Al-Kautsar, insyaALLAH kajian-kajian yang turut menang dalam pertandingan tersebut akan menyusul disebarkan.\n\nSemoga kita sama-sama dapat mengulangkaji dan mengenali sirah Rasulullah sallAllahu ‘alaihi wasallam, dan semakin subur rasa cinta dan rindu untuk bertemu dengannya pada hari akhirat nanti…\n\nWaAllahu Ta’ala A’lam…\n\nCatatan dari :\nShahmuzir Nordzahir\nwww.muzir.wordpress.com	\N	22738	2093	1976-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1382714402i/18716413.jpg	{}	{}	2025-01-16 17:49:08.522	2025-01-16 17:49:08.522
86	1645649	Dengan iba Sita mengulurkan kendi berisi air minum untuk pertapa tua yang lemah dan renta itu. Aku tidak melanggar pesan Laksmana dan tidak keluar dari lingkaran sakti ini. Aku hanya mengulurkan tanganku, katanya dalam hati. Pertapa tua itu menyambut kendi yang diulurkan Sita dan… tiba-tiba ia berubah menjadi raksasa bertubuh besar dan berwajah sepuluh: Dasamuka. Dengan tangkas Dasamuka menarik Sita keluar dari lingkaran sakti yang melindunginya lalu menerbangkannya ke Alengka. Sita hanya bisa menangis dan menyesali kecerobohannya. Mengapa aku meragukan kesaktian Rama dan mengira ia menjerit meminta tolong? Mengapa aku tidak memercayai ketulusan Laksmana dan menuduhnya ingin mendapatkan diriku dengan membiarkan Rama mati?\n\nEpos Ramayana adalah salah satu warisan budaya Indonesia yang diadaptasi dari khazanah sastra klasik India. Epos yang sudah berabad-abad dikenal di Indonesia dalam bentuk kakawin, relief Candi Prambanan, atau tari-tarian ini, ditulis kembali oleh Nyoman S. Pendit, penulis Mahabharata dengan gaya bertutur yang memikat dan enak dibaca.	\N	12759	983	1957-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1186309472i/1645649.jpg	{}	{}	2025-01-16 17:28:13.184	2025-01-16 17:28:13.184
87	51599713	Ditulis berdasar rontal Sanghyang Nawaruci oleh Mpu Siwamürti menjelang akhir Kerajaan Majapahit. Sebuah naskah berbahasa Jawa Kawi Akhir, yang menuturkan pencarian Raden Wrkodhara akan kesejatian hidup sehingga mendapat anugerah bertemu Sanghyang Nawaruci di tengah samudera. Satu perwujudan Sanghyang Acintya pranesa, Tuhan Tak Tergambarkan yang Memiliki Kehendak Tertinggi. Juga berdasar kisah tutur perjalanan hidup Syekh Malayakusuma (Kangjêng Susuhunaning Kalijaga) ketika bertemu Kangjêng Nabi Khidlir di tengah samudra sehingga dari pertemuan tersebut Syekh Malayakusuma mendapat mukasyafah atau penyingkapan hijab yang luar biasa, maka Raden Ngabehi Yasadipura I, dibantu sepenuhnya oleh putranya Raden Ngabehi Yasadipura II,—mereka berdua adalah para pujangga agung Kasunanan Surakarta—menggubah kisah kuno rontal Sanghyang Nawaruci dan kisah tutur Syekh Malayakusuma dalam satu naskah berbahasa Jawa Anyar (Baru) yang diberi judul: Sêrat Bhimasuci atau Sêrat Dewaruci.\n\nNaskah yang ditulis dalam bentuk têmbang gêdhe—yaitu tembang yang aturan pembuatannya menyerupai pembuatan kakawin masa Jawa Kuno—dengan apik menuturkan perjalanan spiritual Raden Wrêkudara ketika mencari Tirta Pawitrasari (air yang dapat menyucikan jiwa raga) atas petunjuk Dhangnyang Druna yang bermaksud menyesatkannya. Di tengah samudera raya Raden Wrêkudara menjumpai sosok manusia bajang (kecil) yang memiliki perwujudan tak ubahnya seperti dirinya sendiri. Sosok itulah Sang Dewaruci. Dia sebenarnya adalah perwujudan dari Suksma Sêjati (Ruh) Raden Wrêkudara.\n\nDari pertemuan agung tersebut, Raden Wrêkudara segera beroleh Johar Awal (Jauhar Awwal), yaitu kecemerlangan awal, yang merupakan kecemerlangan Ruhnya yang sempat redup ketika dirinya terlahirkan ke dunia. Lantas, bagaimanakah Sang Bhima dapat mencapai kesempurnaan dan Sang Bajang atau Dewaruci dapat melebur atas sukma dalam dirinya. Perhatikan kisah ini, Anda pun akan meraih kebijaksanaan.	\N	2	0	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1565711025l/51599713.jpg	{}	{}	2025-01-16 18:52:23.366	2025-01-16 18:52:23.366
89	8435779		\N	3	0	2002-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1551319825i/8435779.jpg	{}	{}	2025-01-16 17:59:02.502	2025-01-16 17:59:02.502
98	23012658	A wry, affecting tale set in a small town on the Indonesian coast, Man Tiger tells the story of two interlinked and tormented families and of Margio, a young man ordinary in all particulars except that he conceals within himself a supernatural female white tiger. The inequities and betrayals of family life coalesce around and torment this magical being. An explosive act of violence follows, and its mysterious cause is unraveled as events progress toward a heartbreaking revelation.\n\nLyrical and bawdy, experimental and political, this extraordinary novel announces the arrival of a powerful new voice on the global literary stage.	\N	6733	1246	2004-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1428766842i/23012658.jpg	{}	{}	2025-01-16 17:45:11.304	2025-01-16 17:45:11.304
679	\N	Angel kembali menyerang! Kali ini… reaksinya berasal dari dalam NERV!?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1740375906i/228328434.jpg	\N	\N	2026-05-31 16:33:24.818134	2026-05-31 16:33:24.818134
90	\N	Jawa menyimpan banyak misteri sejarah yang sangat dramatis dan mencekam. Namun, tidak banyak jejak yang terekam di dalam catatan tertulis. Buku “Babad Tanah Jawi: Mulai dari Nabi Adam Sampai Runtuhnya Mataram” merupakan satu dari sangat sedikit penurutan sejarah Jawa yang bisa terdokumentasikan.\nTeks asli dari buku ini sebenarnya memuat silsilah dari raja-raja Jawa sejak Nabi Adam, dewa-dewa dalam agama Hindu, kisah Mahabharata, cerita Panji di masa Kediri, era Kerajaan Pajajaran, Majapahit, Demak, Paang, hingga Mataram, dan berakhir pada masa Kartasura. Sebuah era ketika Jawan dirongrong oleh Perang Takhta, dan Mataram mulai terpecah menjadi Yogyakarta dan Surakarta.\nSebenarnya, hanya ada dua versi dari Babad Tanah Jawi yang dianggap orisinal dan berbobot oleh para sejarawan, yaitu versi Meinsma yang terbit pada 1874 dan W.L. Olthof yang terbit di tahun 1941. Menurut sejarawan M.C. Ricklefs, Babad Tanah Jawi versi Meinsma bukanlah sumber primer yang bisa diterima untuk riset historis. Acuan-acuan selalu pada edisi dan terjemahan milik W.L. Olthof. Jadi, dibandingkan dengan berbagai macam versi yang banyak beredar, buku “Babad Tanah Jawi” versi W.L. Olthof ini telah mendapat pengakuan sejarawan terkemuka sebagai versi yang paling otoritatif dan berbobot.	\N	\N	\N	\N	Narasi			\N	Babad Tanah Jawi: Mulai Dari Nabi Adam Sampai Runtuhnya Mata	\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/babad.jpg	{}	{}	2025-01-18 19:03:20.243	2025-01-18 19:03:21.878
91	2409779	Qu'il suive le fil d'Ariane sur les traces du Minotaure pour évoquer Oran et ses alentours, qu'il revisite le mythe de Prométhée à la lumière de la violence du monde moderne, ou qu'il rêve à la beauté d'Hélène et de la Grèce, Albert Camus nous entraîne tout autour de la Méditerranée et de ses légendes.Un court recueil de textes lyriques et passionnés pour voyager de l'Algérie à la Grèce en passant par la Provence.	\N	2641	266	1954-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1394421257i/2409779.jpg	{}	{}	2025-01-16 17:38:59.164	2025-01-16 17:38:59.164
92	38461244	Dalam Tasawuf, spiritualitas Islam, hubungan antara hamba dan Tuhan hanya bisa terjalin melalui cinta, mahabbah. Hamba adalah sang pecinta, Tuhan adalah sang kekasih. Hamba terpisah dari Tuhan karena nafsu, yang berlapis-lapis banyaknya, dan cinta bagaikan tungku api yang membakar nafsu sang pecinta. Perjalanan menuju sang kekasih begitu panjang dan menyakitkan, tetapi itulah yang harus dilalui setiap pecinta yang meniti Jalan Mahabbah.\n\nKisah tentang perjalanan pecinta meniti Jalan Mahabbah kerap diabadikan dalam karya sastra oleh para pujangga Sufi di setiap masa. Yang termasyhur di antara semuanya adalah Layla Majnun karya Nizami (abad ke-12) dan Yusuf Zulaikha karya Jami (abad ke-15). Keduanya berkisah tentang seorang pecinta yang terpesona pada keindahan Tuhan yang mewujud dalam diri kekasihnya, mengalami siksa kerinduan tak terkira hingga kehilangan dirinya dan mengantarkannya pada penyatuan mistis tak terkatakan sebagai puncak pengalaman spiritual. Kisah mereka yang penuh liku dilukiskan dalam metafora-metafora yang luar biasa kaya dan indah, menginspirasi banyak pujangga, seniman, dan pejalan spiritual dari berbagai agama berabad-abad lamanya.	\N	26	1	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1518099417i/38461244.jpg	{}	{}	2025-01-16 17:41:07.359	2025-01-16 17:41:07.359
93	49552	Published in 1942 by French author Albert Camus, The Stranger has long been considered a classic of twentieth-century literature. Le Monde ranks it as number one on its "100 Books of the Century" list. Through this story of an ordinary man unwittingly drawn into a senseless murder on a sundrenched Algerian beach, Camus explores what he termed "the nakedness of man faced with the absurd."	\N	1225483	60253	1942-05-18	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1590930002i/49552.jpg	{}	{}	2025-01-17 04:31:39.322	2025-01-17 04:31:39.322
94	36985707	Petualangan Don Quixote merupakan cerita 'kesatria kesiangan' yang mampu menyihir pembacanya untuk percaya terhadap seluruh imajinasinya. Ia berimaji sebagai seorang Don (kesatria) penumpas kejahatan yang terjadi di negerinya. Namun, 'kesatria kesiangan' tersebut adalah hasil imajinasinya. Pikirannya dijejali kelimunan mimpi-mimpi dan bayang-bayang, yang tak sanggup dihadapinya di dunia nyata. \n\nBagaimanakah 'kesatria kesiangan' tersebut menggambarkan imajinasinya? Dapatkah ia sadar bahwa ia hidup dalam dunia imajinasi?\n \nPetualangan Don QUixote de la Mancha ini merupakan karya pengarang besar Spanyol, Miguel de Cervantes Saavedra, diterbitkan pertama kali tahun 1605 M. Karya ini merupakan salah satu novel besar yang menjadi perbincangan sepanjang masa, dan telah diterjemahkan ke dalam pelbagai bahasa di belahan dunia Barat.	\N	286865	13135	1604-12-31	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1512610785i/36985707.jpg	{}	{}	2025-01-16 17:23:30.804	2025-01-16 17:23:30.804
95	22175715	Tiga belas cerita pendek merentang dari masa prakedatangan Cornelis de Houtman hingga awal Indonesia merdeka. Masing-masing menggoda kita untuk berimajinasi tentang sejarah Indonesia dari sudut pandang yang khas: mantan tentara yang dibujuk membunuh suami kekasih gelapnya; perwira yang dipaksa menembak Von Imhoff; wartawan yang menyaksikan Perang Puputan; inspektur Indo yang berusaha menangkap hantu pencuri beras; administratur perkebunan tembakau Deli yang harus mengusir gundik menjelang kedatangan istri Eropanya; nyai yang begitu disayang sang suami tetapi berselingkuh.\n\nIksaka Banu "peniup ruh" yang jitu dalam menghidupkan masa lalu. Di tangannya, kisah berlatar sejarah tersingkap apik, rinci, dan dramatik.——Kurnia Effendi, cerpenis dan sastrawan senior\n\nCerita-cerita dalam kumpulan ini membawa kita kepada era kolonialisme yang jarang digali oleh penulis Indonesia modern. Dengan riset yang serius dan teliti, Iksaka Banu mengisahkan tentang cinta, keintiman, kemesraan sekaligus pengkhianatan dan kekejian di antara tokoh-tokoh pribumi dan Belanda.——Leila S. Chudori, Peraih Khatulistiwa Literary Award 2013	\N	912	230	2014-05-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1400467077i/22175715.jpg	{}	{}	2025-01-16 17:42:43.07	2025-01-16 17:42:43.07
96	58462921	Dongeng atau cerita rakyat merupakan kisah-kisah atau fabel-fabel yang diceritakan turun-temurun, dari generasi ke generasi lainnya. Isi ceritanya tidak hanya menawan, tetapi biasanya juga diselingi dengan petuah-petuah moral dan etika untuk dipetik pelajarannya.\n \nDi dunia ini tersebar banyak cerita rakyat, tiap-tiap negeri mempunyai beragam dongeng khas masing-masing, yang juga menggambarkan kebudayaan negeri setempat. Cerita-cerita tersebut patut dijaga dan terus-menerus didongengkan untuk melestarikan kebudayaan dunia dan nilai-nilai positifnya.\n \nBuku ini menyuguhkan kepada Anda dongeng-dongeng dari Persia dan India, dua negeri yang sangat kaya akan kisah dan fabel. Cerita rakyat yang dihadirkan di sini merupakan cerita-cerita populer di negeri tersebut yang membangkitkan ketakjuban, tawa dan tangis, serta menyenangkan dunia pembaca, baik orang tua maupun muda.	\N	4	1	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1625086876i/58462921.jpg	{}	{}	2025-01-16 18:02:11.291	2025-01-16 18:02:11.291
507	\N	致命傷を負ったはずのXが豹変し、赤尾の人格が出現!!　本物そのままの言動に坂本と南雲は戸惑いつつも、3人で殺連の追跡から逃れようとする。だが、最恐の“あの男”が現れ!?　世紀の殺し屋展編クライマックス!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1729927091i/214982855.jpg	\N	\N	2026-01-26 15:44:00.286898	2026-01-26 15:44:00.286898
99	44156290	Pencurian malam hari: 2\nPencurian siang hari: 3\nPencurian sendiri: 1\nPencurian bersama-sama: 1\nPencurian dengan pemberatan: 0\nPencurian kendaraan bermotor: 1\n\nSebatang kapur dan penghapus tergeletak di bawah papan tulis itu. Tampak benar telah sangat lama tak dipakai. Demikian minim angka-angka itu sehingga tak bisa dijadikan diagram batang, diagram kue cucur atau diagram naik-naik ke puncak bukit. Rupanya di kota ini, penduduknya telah lupa cara berbuat jahat.\n\nMata Inspektur semakin sendu menatap papan tulis itu. Keadaan yang tenteram ini perlahan-lahan membuat polisi di dalam dirinya terlena, lalu terbaring, lalu pingsan, lalu mati. Inspektur sungguh khawatir. Wahai kaum maling, ke manakah gerangan kalian?\n\nUntuk pertama kalinya, Andrea Hirata menulis novel dalam genre kejahatan. Pembaca akan berjumpa tokoh-tokoh unik dengan pikiran menakjubkan, yang mudah bahagia dengan hal-hal sederhana.	\N	2345	517	2019-03-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1551315476i/44156290.jpg	{}	{}	2025-01-16 18:03:01.661	2025-01-16 18:03:01.661
100	26115985	"Orang bilang, kita akan ke surga setelah mati. Benarkah?"\nMalaikat Ariel mendesah,\n"kalian semua sekarang sudah berada di surga.\nsekarang, di sini. Jadi, sebaiknya \nkalian berhenti bertengkar dan berkelahi. \nSangat tidak sopan berkelahi di hadapan Tuhan."\n\nMalam Natal tahun ini sungguh menyedihkan bagi Cecilia. Ia sakit keras dan mungkin tak akan pernah sembuh. Cecilia marah dan menganggap Tuhan tidak adil. \n\nNamun, terjadi keajaiban. Seorang Malaikat-Ariel namanya-mengunjungi Cecilia. Mereka berdua kemudian membiat perjanjian. Cecilia harus memberitahukan seperti apa rasanya menjadi manusia dan Malaikat Ariel akan memberitahunya seperti apa surga itu.	\N	8371	565	1993-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1439811705i/26115985.jpg	{}	{}	2025-01-16 17:41:17.529	2025-01-16 17:41:17.529
101	44434134	Sejak kecil, Petter lebih suka menyendiri di dalam dunia yang dia ciptakan. Dia terobsesi dengan cerita-cerita, terutama dengan Panina Manina, sang Putri Sirkus yang dikarangnya sendiri. Hingga dewasa pun, imajinasinya terus merajalela. Tak heran dia dijuluki Petter “si Laba-Laba”.\n\nTetapi, Petter membenci ketenaran dan tak mau memublikasikan tulisannya. Dia memilih menciptakan Writers' Aid, sebuah program yang didesain untuk menyediakan cerita-cerita bagi pengarang-pengarang internasional yang mengalami kebuntuan ide.\n\nMeskipun programnya ini pada awalnya sangat sukses, Petter akhirnya terjebak dalam jaring yang ditenunnya sendiri. Skandal memalukan dalam dunia sastra internasional perlahan-lahan terkuak dan nyawa Petter terancam oleh pengarang-pengarang besar yang ingin menyelamatkan nama baik mereka. Tak disangka, kehancuran Petter ternyata bersumber dari perbuatannya masa lalu. \n\nNovel ini akan mempertemukan Anda dengan Petter “si Laba-Laba,” tokoh ciptaan Gaarder yang paling membuat penasaran setelah Sophie dari Dunia Sophie.	\N	5789	461	2000-07-11	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1552631154i/44434134.jpg	{}	{}	2025-01-16 16:49:13.184	2025-01-16 16:49:13.184
102	23433546	"Nova sayang, aku tak tahu bagaimana rupa dunia saat kau membaca surat ini ...."\n\n\nBumi 2082, Nova sangat terkejut saat tiba-tiba di terminal online-nya muncul surat dari nenek buyutnya, Anna. Surat yang ditulis 70 tahun lalu, tepat tanggal 12.12.12. Tepat saat nenek buyutnya berusia 16 tahun seperti Nova saat ini.\n\nSungguh misterius, bagaimana mungkin 70 tahun lalu nenek buyutnya sudah tahu bahwa kelak cicitnya bernama Nova? Dan dari mana nenek buyutnya tahu tentang keresahan-keresahan Nova? Tentang bumi yang sudah tak seindah dulu lagi, tentang spesies yang punah, tanah-tanah yang tenggelam, kutub yang meleleh. Dan, benarkah cincin rubi merah dari legenda Aladin, menjadi kunci untuk mengembalikan keseimbangan bumi? Cincin yang selama ini melingkar di jari Anna, nenek buyutnya?\n\n\nJostein Gaarder, penulis Dunia Sophie, kembali dengan Dunia Anna, sekali lagi mengajak kita berkaca. Dengan kisah yang ringan namun penuh makna, Jostein Gaarder kembali mengajak pembaca merenungkan eksistensi manusia dan semesta.	\N	3624	566	2013-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1413943448i/23433546.jpg	{}	{}	2025-01-16 17:42:55.605	2025-01-16 17:42:55.605
103	1658408	Sophie, seorang pelajar sekolah menengah berusia empat belas tahun. Suatu hari pulang sekolah, dia mendapat sebuah surat misterius yang hanya berisikan satu pertanyaan: "Siapakah Kamu?" Belum habis keheranannya, pada hari yang sama dia mendapat surat lain yang bertanya: "Dari manakah datangnya dunia?" Seakan tersentak dari rutinitas kehidupan sehari-hari, surat-surat itu membuat Sophie mulai mempertanyakan soal-soal mendasar selama ini. Dia mulai belajar Filsafat.\n\nTapi siapakah pengirim surat-surat-surat misterius itu? Bagaiamana Sophie bisa mengenalnya? Dan lagi pula, mengapa dia mengirimkan pelajaran Filsafat kepada Sophie lewat surat-surat itu? Ternyata dia dan Sophie sama-sama berada dalam pengawasan orang lain yang mengatur gerak-gerik mereka. Bagaimana bisa?\n\nInilah novel sejarah filsafat yang akan mempesona Anda dengan cara berkisahnya yang unik. Sebuah best seller yang akan di kenang sepanjang masa. Sejak terbit pertama kali di Norwegia --negeri asal pengarangnya-- pada 1991, buku ini telah diterjemahkan ke dalam 30 bahasa dan terjual lebih dari 9 juta eksempelar di seluruh dunia. Anda akan berterima kasih kepada pengarangnya karena telah membuat sesuatu yang begitu sulit menjadi mudah dan sederhana.\n\n"Mengagumkan ... sebuah novel misteri yang cerdas dan menggemaskan, yang kebetulan juga merupakan sebuah sejarah filsafat". The Washington Post Book World "Luar biasa ... Anda harus membacanya sendiri" Newsweek.	\N	269558	15898	1990-12-31	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1357537764i/1658408.jpg	{}	{}	2025-01-16 17:08:27.985	2025-01-16 17:08:27.985
104	1353409	Di akhir masa kolonial, seorang perempuan dipaksa menjadi pelacur. Kehidupan itu terus dijalaninya hingga ia memiliki tiga anak gadis yang kesemuanya cantik. Ketika mengandung anaknya yang keempat, ia berharap anak itu akan lahir buruk rupa. Itulah yang terjadi, meskipun secara ironik ia memberinya nama si Cantik.\n\nLewat novel ini, Eka mengisahkan nasib anak-anak manusia dalam gelombang sejarah bangsa. Manusia-manusia yang telah menjadi korban kekuasaan dan ‘kutukan karma’. Lebih dari itu, lewat tokoh-tokohnya, Eka juga mendedahkan absurditas kecantikan yang bertengger di wajah perempuan. Kisah seorang perempuan cantik keturunan Belanda bernama Dewi Ayu yang menjadi korban kekejaman perang dan perebutan kekuasaan.	\N	16085	2897	2002-12-12	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1502464714i/1353409.jpg	{}	{}	2025-01-16 18:04:48.555	2025-01-16 18:04:48.555
142	51325062	Python adalah bahasa pemrograman multi-platform yang bersifat free dan open-source, dan dapat digunakan untuk mengembangkan aplikasi-aplikasi desktop maupun web. Python memiliki pustaka standar (Python Standard Library) yang sangat lengkap sehingga dapat memenuhi berbagai macam permasalahan-permasalahan riil di dalam dunia pemrograman, sebagai alternatif dari bahasa-bahasa pemrograman lain seperti C, C++, Java, PHP, dll. Untuk kepentingan yang spesifik, kode Python juga dapat diintegrasikan dengan pustaka lain yang ditulis dalam bahasa C, C++, Java (melalui Jpython), dan bahasa-bahasa .NET seperti Visual Basic dan C# (melalui IronPython).	\N	8	2	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1581857608i/51325062.jpg	{}	{}	2025-01-16 17:11:20.573	2025-01-16 17:11:20.573
105	61439040	A masterpiece of rebellion and imprisonment where war is peace freedom is slavery and Big Brother is watching. Thought Police, Big Brother, Orwellian - these words have entered our vocabulary because of George Orwell's classic dystopian novel 1984. The story of one man's Nightmare Odyssey as he pursues a forbidden love affair through a world ruled by warring states and a power structure that controls not only information but also individual thought and memory 1984 is a prophetic haunting tale More relevant than ever before 1984 exposes the worst crimes imaginable the destruction of truth freedom and individuality. With a foreword by Thomas Pynchon. This beautiful paperback edition features deckled edges and french flaps a perfect gift for any occasion\n\nAlternate cover edition can be found here.	\N	4972695	130644	1949-06-08	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1657781256i/61439040.jpg	{}	{}	2025-01-16 17:34:39.842	2025-01-16 17:34:39.842
106	25111093	New York Times Bestseller \n\nTravel the world with Eric Weiner, the New York Times bestselling author of The Geography of Bliss, as he journeys from Athens to Silicon Valley—and throughout history, too—to show how creative genius flourishes in specific places at specific times.\n\nIn The Geography of Genius, acclaimed travel writer Weiner sets out to examine the connection between our surroundings and our most innovative ideas. He explores the history of places, like Vienna of 1900, Renaissance Florence, ancient Athens, Song Dynasty Hangzhou, and Silicon Valley, to show how certain urban settings are conducive to ingenuity. And, with his trademark insightful humor, he walks the same paths as the geniuses who flourished in these settings to see if the spirit of what inspired figures like Socrates, Michelangelo, and Leonardo remains. In these places, Weiner asks, “What was in the air, and can we bottle it?”	\N	4163	603	2016-01-05	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1451843149i/25111093.jpg	{}	{}	2025-01-16 17:39:48.556	2025-01-16 17:39:48.556
107	1398044	Roman Anak Semua Bangsa adalah periode observasi atau turun ke bawah mencari serangkaian spirit lapangan dan kehidupan arus bawah Pribumi yang tak berdaya melawan kekuatan raksasa Eropa. Di titik ini Minke diperhadapkan antara kekaguman yang melimpah-limpah pada peradaban Eropa dan kenyataan di selingkungan bangsanya yang kerdil. Sepotong perjalanannya ke Tulangan Sidoarjo dan pertemuannya dengan Khouw Ah Soe, seorang aktivis pergerakan Tionghoa, korespondensinya dengan keluarga De la Croix (Sarah, Miriam, Herbert), teman Eropanya yang liberal, dan petuah-petuah Nyai Ontosoroh, mertua sekaligus guru agungnya, kesadaran Minke tergugat, tergurah, dan tergugah, bahwa ia adalah bayi semua bangsa dari segala jaman yang harus menulis dalam bahasa bangsanya (Melayu) dan berbuat untuk manusia-manusia bangsanya.	\N	7402	622	1974-12-31	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1464929002i/1398044.jpg	{}	{}	2025-01-17 05:42:35.717	2025-01-17 05:42:39.779
108	\N		\N	\N	\N	\N				\N		\N	https://onesearch.id/Cover/Show?author=SUPRAPTO%2C+Tommy&callnumber=&size=medium&title=Komunikasi+propaganda%3A+Teori+dan+praktik%23+Tommy+Suprapto&isbn=6029791257	{}	{}	2025-01-18 19:15:24.633	2025-01-18 19:15:26.346
109	\N	Jika Anda sekarang memegang buku ini maka dengan satu atau lain cara Anda pasti sudah pernah bersinggungan dengan gagasan-gagasan dari Immanuel Kant. Mereka yang tertarik untuk membaca buku ini paling sedikit sudah lebih dulu mempunyai perhatian khusus untuk filsafat dari Zaman Pencerahan (Inggris: “The Age of Enlightenment”; Jerman: “Zeitalter der Aufklärung”).\n\nAlasan utama penerjemah untuk mulai mengindonesiakan karya-karya Kant terletak pada relevansi yang semakin besar untuk mengaktualisasikan karya-karya Kant, yang pada pokoknya merupakan analisis kritis terhadap akal manusia (Vernunftkritik) ke dalam zaman, di mana masyarakat kita nampaknya semakin terseret ke dalam hiruk pikuknya sains dan teknologi. Bahayanya justru terletak dalam “peringatan” yang gencar, seolah-olah kita tidak boleh tertinggal dalam perkembangan sains dan teknologi, karena dengan “peringatan” itu sekaligus dilupakan juga bahwa yang seharusnya menentukan perkembangan sains dan teknologi itu adalah kita sendiri. Dan bukannya “kita tidak boleh tertinggal”.\n\nBuku kecil yang ditulis oleh Theodor Valentiner enam dasa warsa yang silam ini dapat membantu untuk menghindarkan kita dari salah kaprah historis yang berlarut-larut, karena Valentiner telah menghasilkan suatu karya pengantar yang sangat berguna bagi mereka yang hendak memahami karya-karya Kant lebih jauh.	\N	\N	\N	\N				\N		\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/immanuel-kant_1.jpg	{}	{}	2025-01-17 05:35:33.359	2025-01-17 05:35:37.66
110	3172015	Bagi kita tentu sudah tidak asing lagi nama-nama seperti Adolf Hitler, Vladimir Ilyich Lenin, Francois Duvalier, Fidel Castro, Joseph Stalin, Mao Tse Tung, Nikita Kruschev, Francicso Franco, Gamal Abdul Nasser dan juga... Soekarno. Buku ini memaparkan kisah-kisah para diktator di abad ke 20 tersebut; bagaimana mereka meraih kekuasaan, cara yang dipakai mempertahankan kekuasaan, serta cara-cara yang dipilih di senjakala kekuasaan mereka.	\N	167	16	1967-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1260854698i/3172015.jpg	{}	{}	2025-01-16 17:44:08.343	2025-01-16 17:44:08.343
111	15725782	MENGAPA HUMANISME, suatu paham yang menitikberatkan pada manusia, kemampuan kodratinya, dan nilai-nilai kehidupan duniawi perlu dibicarakan kembali? Sejak abad ke-14 gerakan humanis modern tumbuh memberikan penafsiran rasional yang mempersoalkan monopoli agama dan negara terhadap tafsir kebenaran. Humanisme sekular memberi kita keyakinan bahwa kehidupan "dunia-atas-sana" tak lebih penting daripada kehidupan "dunia-bawah-sini". Namun, humanisme tak luput dari kritik. Ketika humanisme menuntun pada suatu kemanusiaan tanpa Tuhan, yaitu keadaan ketika manusia bermain sebagai Tuhan, Hiroshima, Gulag, Killing Fields, Sebrenica, dan puluhan tempat pembunuhan massal lain pada abad ke-20 menjadi tak terhindarkan. Di negeri kita, tragedi kemanusiaan juga tak sepi. Lalu, apakah itu berarti humanisme sudah usang? Ketika kini kebangkitan agama-agama sedang berlangsung mulus tak banyak hambatan dan nilai-nilai universal makin relatif, hikmat apakah yang masih dapat kita pelajari dari humanisme? Bagaimanakah sosok dan peran humanisme dalam masyarakat yang menjadi majemuk juga karena agama-agama seperti masyarakat indonesia? Buku kecil ini mengurai dengan jernih pengertian humanisme, perkembangannya, dan berbagai kritik terhadap humanisme. Tidak berhenti di situ, penulis juga menawarkan tafsir baru atas paham tersebut, yang disebutnya sebagai "Humanisme Lentur". (	\N	75	16	2012-06-25	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1340859624i/15725782.jpg	{}	{}	2025-01-16 17:38:38.43	2025-01-16 17:38:38.43
112	6615124	This is a pre-1923 historical reproduction that was curated for quality. Quality assurance was conducted on each of these books in an attempt to remove books with imperfections introduced by the digitization process. Though we have made best efforts - the books may have occasional errors that do not impede the reading experience. We believe this work is culturally important and have elected to bring the book back into print as part of our continuing commitment to the preservation of printed works worldwide.	\N	357898	14183	1512-12-31	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1348180244i/6615124.jpg	{}	{}	2025-01-16 14:23:46.392	2025-01-16 14:23:46.392
113	26813958	Jika kita bertanya siapa filsuf zaman modern yang paling menentukan pemikiran filsafat kemudian hari, kiranya hanya sedikit orang yang tidak akan menyebutkan Immanuel Kant. Profesor yang tidak pernah keluar dari batas kota Konigsberg, ibu kota Prusia, dan mengikuti irama hidup harian yang amat teratur, bahkan rutin itu, dengan pemikirannya yang radikal mengubah gaya manusia berpikir. Bukan seakan-akan semua pikiran Kant sekarang masih diterima umum, tetapi Kant merumuskan kerangka permasalahan yang samapai sekarang, untuk sebagian, tetap tidak dapat dihindari. Sering dikatakan, bahwa revolusi filsafat yang dibawa Kant dapat diperbandingkan dengan revolusi pandangan dunia Kopernikus yang menggantikan gambaran dunia geosentris dengan yang heliosentris. Immanuel Kant adalah seorang filsuf besar yang pernah tampil dalam pentas pemikiran filosofis zaman Aufklarung Jerman menjelang akhir abad ke-18. Ia lahir di Konigsberg, sebuah kota kecil di Prusia Timur, pada 22 April 1724. Kant lahir sebagai anak keempat dari keluarga miskin.	\N	11428	195	1788-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1443191609i/26813958.jpg	{}	{}	2025-01-16 17:33:09.709	2025-01-16 17:33:09.709
114	1353452	Tetralogi ini dibagi dalam format empat buku. Dan roman keempat, Rumah Kaca, memperlihatkan usaha kolonial memukul semua kegiatan kaum pergerakan dalam sebuah operasi pengarsipan yang rapi. Arsip adalah mata radar Hindia yang ditaruh di mana-mana untuk merekam apa pun yang digiatkan aktivis pergerakan itu. Pram dengan cerdas mengistilahkan politik arsip itu sebagai kegiatan pe-rumahkaca-an.\n\nNovel besar berbahasa Indonesia yang menguras energi pengarangnya untuk menampilkan embrio Indonesia dalam ragangan negeri kolonial. Sebuah karya pascakolonial paling bergengsi.	\N	4184	358	1988-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1360646538i/1353452.jpg	{}	{}	2025-01-16 17:52:09.659	2025-01-16 17:52:09.659
115	1398066	Kehadiran roman sejarah ini, bukan saja dimaksudkan untuk mengisi sebuah episode berbangsa yang berada di titik persalinan yang pelik dan menentukan, namun juga mengisi isu kesusastraan yang sangat minim menggarap periode pelik ini. Karena itu hadirnya roman ini memberi bacaan alternatif kepada kita untuk melihat jalan dan gelombang sejarah secara lain dan dari sisinya yang berbeda.\n\nTetralogi ini dibagi dalam format empat buku. Pembagian ini bisa juga kita artikan sebagai pembelahan pergerakan yang hadir dalam beberapa periode. Dan roman ketiga ini, Jejak Langkah, adalah fase pengorganisasian perlawanan.\n\nMinke memobilisasi segala daya untuk melawan bercokolnya kekuasaan Hindia yang sudah berabad-abad umurnya. Namun Minke tak pilih perlawanan bersenjata. Ia memilih jalan jurnalistik dengan membuat sebanyak-banyaknya bacaan Pribumi. Yang paling terkenal tentu saja Medan Prijaji.\n\nDengan koran ini, Minke berseru-seru kepada rakyat Pribumi tiga hal: meningkatkan boikot, berorganisasi, dan menghapuskan kebudayaan feodalistik. Sekaligus lewat langkah jurnalistik, Minke berseru-seru: "Didiklah rakyat dengan organisasi dan didiklah penguasa dengan perlawanan".	\N	6065	455	1984-12-31	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1360760182i/1398066.jpg	{}	{}	2025-01-16 17:08:48.158	2025-01-16 17:08:48.158
116	\N	Saya telah belajar banyak dari guru terhormat saya, Sigmund Freud. Saya dapat melihat betapa jauhnya jarak yang ditempuh Freud di luar batas-batas pengetahuan kontemporer tentang fenomena psiko-patologis, terutama psikologi proses mental yang kompleks. Telah diasumsikan secara salah bahwa sikap saya menunjukkan "perpecahan" dalam gerakan psikoanalisis.\n\nSaya sudah menyajikan fakta-fakta yang diamati dengan lebih memadai. Argumen saya bukan dari argumen akademis, melainkan dari pengalaman saya selama sepuluh tahun bekerja dengan sungguh-sungguh di bidang ini. Kritik yang sedehana dan moderat ini bukanlah untuk memulai perpisahan. Harapan saya adalah membantu gerakan psikoanalitis agar terus berkembang.	\N	\N	\N	\N				\N		\N	https://books.google.co.id/books/publisher/content?id=Ke3GEAAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&imgtk=AFLRE73TN1uZ5sWeeC-kGqqP4QpWdB1pCN1vR-SYhT6rEQIrLj16GvkCI6HuxTbzmhWPCNX2PCXTMJrIM5Qb01CQodI5WXclE_muGkFdD5gqGs0HNrKiiuHMnWR4cDg3YDijpeDu52X9	{}	{}	2025-01-18 19:07:59.736	2025-01-18 19:08:01.184
117	26065679	How to Write a Philosophy Paper is a handbook which provides students with a ready arsenal of analytical and compositional techniques. It is intended for undergraduate students in any type of philosophy course and is written and organized in a user-friendly manner. The first half includes discussions of the nature of philosophy and a variety of basic and essential techniques of philosophical enquiry and argumentation. The second half takes the student step-by-step through the writing process, from choosing a suitable topic, to developing his or her thought, to preparation of the final draft. Includes an index and bibliographical material.	\N	5	1	1994-12-19	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1439091446i/26065679.jpg	{}	{}	2025-01-16 17:18:53.602	2025-01-16 17:18:53.602
118	7015724	Varoluşçuluk nedir?\n\nBugüne değin çeşitli yanıtlar verilmiş bir sorudur bu. Sözgelişi, Weil’e göre varoluşçuluk bir bunalım, Mounier’ye göre umutsuzluk, Hamelin’e göre bunaltı, Banfi’ye göre kötümserlik, Wahl’e göre başkaldırış, Marcel’e göre özgürlük, Lukács’a göre idealizm, Benda’ya göre usdışılık, Foulqué’ye göre saçmalık felsefesidir.\n\nBir dönem, slogancı gençliğin peygamberi ve ‘varoluşçu papası’ sayılan J.-P. Sartre’a göreyse, varoluş, insanda, ama yalnız insanda, özden önce gelir. Bu demektir ki insan önce vardır; sonra şöyle ya da böyle olur. Çünkü o, özünü kendisi yaratır. Nasıl mı? Şöyle: “Dünyaya atılarak, orada acı çekerek, savaşarak yavaş yavaş kendini belirler. Bu belirleme yolu hiç kapanmaz…”\n\nAsım Bezirci’nin çevirip yayıma hazırladığı bu eser her kuramda, her inanda farklı karşılıklar bulan bir felsefenin temel metnini (Varoluşçuluk Bir İnsancılıktır / Sartre) ve bunun yanı sıra Gaéton Picon ve Laffont Bompiani’ nin Varoluşçuluk’a ilişkin incelemeleriyle P. Naville’in Sartre’la yaptığı konuşmayı içeriyor.	\N	41394	2299	1946-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1256056475i/7015724.jpg	{}	{}	2025-01-16 18:02:39.416	2025-01-16 18:02:39.416
143	44172819	Buku ini merupakan kelanjutan dari Step By Step Teknik Hacking (Buku Pintar Teknik Hacking). Jika pada buku sebelumnya Anda telah dibuat pintar, maka pada buku ini Anda akan dibuat menjadi sakti. Buku ini menunjukkan berbagai teknik hacking yang sangat sederhana dan mudah dipraktikkan. Teknik-teknik hacking yang dibahas antara \n- Mencuri data penting dari hard disk & SD card\n- 1 menit membobol password Administrator Windows XP, 7, & 8\n- Menjadikan koneksi Internet secepat kilat\n- Memasang Keylogger pada browser, flash disk & Windows\n- Teknik hacking smartphone Android\n- Memantau smartphone Android dari jauh\n- Hacking dengan RAT (Remote Administration Tool)\n- Santet komputer lawan dengan Turkojan\n- Dan masih banyak teknik hacking lainnya -Semua software yang dibahas juga telah tersedia dalam DVD Bonus. Jadi, tunggu apa lagi? Praktikkan sekarang juga!	\N	2	0	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1551529415i/44172819.jpg	{}	{}	2025-01-16 18:08:20.242	2025-01-16 18:08:20.242
119	\N	Buku ini mencukupkan diri pada teks pidato habermas "Modernity: an Incomplete Project" yang disampaikannya di Frankfrunt, di hadapan para warga kota, pada penerimaan Adorno Prize. Anehkah bila akhirnya saya tak akan menyatakan buku ini termasuk buku kunci abad ke-21 tentang Habernas dan modernitas bagi publik pembaca di Indonesia , tapi cukup hanya menyebut sebuah bacaan renyah dan jitu (karena ditulis dengan sedikit tergesa-gesa) mengenai persoalan yang akbar, berat, dan gila? Sayangnya, saya juga tidak bisa menampik, sulit menolak bahwa buku ini, ikhtiar satu ini (meski tentu dengan kekurangannya) layak dihargai dan mendapat atensi serta empati yang dalam, perlu dibaca oleh mereka (kaum arif, para teolog, budayawan, kritikus sastra dan seni, teoritisi sosial, atau siapa pun) yang ingin memberi makna lebih pada modernitas kita, pada tindakan komunikatif yang tak lekas patah arang.\n\nLalu, ada juga nama Nietzsche dan Heidegger yang menggugat warisan Eropa pencerahan dan menolak hiruk-pikuk modernitas, tapi pada saat yang bersamaan enggan mengajukan cara untuk menanggulangi secara kritis soal itu. Tak diragukan lagi, ambiguitas itulah yang menjadi sorotan utama yang ingin dilampaui karya ini. Modernitas dan postmodernitas, hanyalah nama dari problem\n\nyang lebih mendasar, isu permukaan bagi suatu urgensi yang lebih filosofis, yakni pertanyaan tentang kebenaran, subjek, dan universalitas.	\N	\N	\N	\N				\N		\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/picture_meta/2022/12/13/4bnqksjk5gvyhdoh7jogac.jpg	{}	{}	2025-01-17 05:42:04.818	2025-01-17 05:42:09.159
120	7070614	A compelling argument for the necessity for art in life, Nietzsche's first book is fuelled by his enthusiasms for Greek tragedy, for the philosophy of Schopenhauer and for the music of Wagner, to whom this work was dedicated. Nietzsche outlined a distinction between its two central forces: the Apolline, representing beauty and order, and the Dionysiac, a primal or ecstatic reaction to the sublime. He believed the combination of these states produced the highest forms of music and tragic drama, which not only reveal the truth about suffering in life, but also provide a consolation for it. Impassioned and exhilarating in its conviction, The Birth of Tragedy has become a key text in European culture and in literary criticism.	\N	19485	1059	1870-12-31	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1256894863i/7070614.jpg	{}	{}	2025-01-16 17:25:32.691	2025-01-16 17:25:32.691
121	1807169	Kaum Tertindas selama ini tenggelam dalam mitos yang ditiupkan Kaum Penindas. Karena itu, bagi Friere, pendidikan untuk mereka harus berintikan pembebasan kesadaran atau dialogika memancing mereka berdialog, membiarkan mereka mengucapkan sendiri perkataannya,mendorong mereka untuk menamai dan dengan demikian mengubah dunia.\nDengan porsi besar filsafat manusia, tak pelak lagi buku ini merupakan sebuah refleksi mendalam mengenai jalan pembebasan manusia.Sebuah buku bagi siapa saja yang ingin tersadar bahwa penjajahan masa kini adalah penjajahan kesadaran.\n****	\N	36555	2615	1968-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1453086541i/1807169.jpg	{}	{}	2025-01-16 18:01:49.531	2025-01-16 18:01:49.531
122	7070596		\N	34	5	1987-12-31	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1256894469i/7070596.jpg	{}	{}	2025-01-16 17:10:06.92	2025-01-16 17:10:06.92
123	3313669	Bagi Camus, kesadaran akan kekacauan diri menyebabkan manusia menjadi tragis, tetapi tidak murung. Itulah asal-usul ungkapan mashur: "Haruslah dibayangkan Sisifus bahagia! Biarpun langit menghukum manusia untuk menggelindingkan batu, hukuman ilahi itu justru membuktikan bahwa dengan mencuri sesuatu dari para dewa, manusia telah menyelamatkan diri mereka. Haruslah dibayangkan Sisifus bangga! Manusia Absurd ternyata adalah manusia dengan kebebasan mutlak."	\N	73900	5594	1942-10-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1210919860i/3313669.jpg	{}	{}	2025-01-16 18:21:23.393	2025-01-16 18:21:23.393
124	60315775	Kita diperintah, pikiran-pikiran kita dicetak, selera-selera kita dibentuk, gagasan-gagasan kita disarankan, terutama oleh orang-orang yang tak pernah kita dengar tentangnya. Ini merupakan satu hasil logis dari cara bagaimana masyarakat demokratis kita diorganisasi.” \n\nTujuan buku ini adalah untuk menjelaskan struktur mekanisme yang mengendalikan pikiran masyarakat, dan memberitahu bagaimana mekanisme tersebut dimanipulasi oleh golongan tertentu yang berusaha untuk menciptakan persetujuan masyarakat terhadap satu gagasan atau komoditas.	\N	8139	916	1927-12-31	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1644133560i/60315775.jpg	{}	{}	2025-01-16 17:10:55.183	2025-01-16 17:10:55.183
125	56808821	"Saya tidak busa berpura-pura mengetahui bagaimana menulis itu seharusnya dilakukan, atau apa yang oleh seorang kritikus yang bijak akan disarankan kepada saya agar dilakukan untuk meningkatkan tulisan saya."\n\nPetikan di atas merupakan pernyataan Russell terkait bagaimana ia menulis. Sebagaimana diketahui, minat Russell itu sangat luas dan beragam, yang berkembang dari tahun ke tahun. Di Cambridge, ia mengembangkan bakatnya di bidang matematika, fllsafat, dan ekonomi.\n\nTetapi, bagaimana gaya tulisan Russell? Bagaimana pula struktur kalimatnya, dan caranya mengembangkan sebuah pokok bahasan?\n\nBuku ini menceritakan semuanya, semua tentang bagaimana Russell menemukan gaya tulisannya. Bahkan, ia akan menghabiskan berjam-jam dalam mencoba menemukan jalan paling ringkas untuk mengucapkan sesuatu tanpa ambiguitas. Ia rela mengorbankan semua usaha mencapai kegemilangan estetis.\n\nBukan hanya itu, buku ini juga memuat beberapa esai Russell, di antaranya: Kenang-Kenangan Religius Saya, Perkembangan Mental Saya, Adaptasi: Sebuah Ringkasan Autobiografis, Kenapa Saya Memilih Filsafat, Pemujaan Seorang Manusia Bebas, Mimpi Buruk Sang Metafisikawan: Retro Me Satanas, dan Menyanjung Kemalasan, dan lain sebagainya.	\N	5	2	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1611542570i/56808821.jpg	{}	{}	2025-01-16 17:12:44.124	2025-01-16 17:12:44.124
126	31799	A lively and still one of the best introductions to philosophy, this book pays off both a closer reading for students and specialists, and a casual reading for the general public.	\N	17366	987	1912-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1405495766i/31799.jpg	{}	{}	2025-01-16 18:30:54.334	2025-01-16 18:30:54.334
127	\N	SUBJEKTIVITAS DALAM FILSAFAT POLITIK ALAIN BADIOU DAN SLAVOJ	\N	\N	\N	\N	Ircisod			\N		\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/9786236699225.jpg	{}	{}	2025-01-17 05:23:52.858	2025-01-17 05:23:57.114
171	204788114	Kecanggihan dunia masa kini dibangun oleh kemajuan sains dan teknologi. Sains juga telah menunjukkan kepada kita mengenai luasnya alam semesta, panjangnya waktu, dan rahasia zat. Namun kadang kita belum sepenuhnya memahami bagaimana cara sains memberi kita semua pengetahuan itu. Sukacita Sains menyajikan bahasan singkat tentang prinsip-prinsip sains, pedoman berpikir kritis dan rasional, hakikat kebenaran dan keraguan dalam sains, serta tak lupa keajaiban dan keasyikan yang dihadirkan sains dalam hidup kita.	\N	468	77	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1704294942i/204788114.jpg	{}	{}	2025-01-16 18:06:24.005	2025-01-16 18:06:24.005
172	11256979	Magic takes many forms. Supernatural magic is what our ancestors used in order to explain the world before they developed the scientific method. The ancient Egyptians explained the night by suggesting the goddess Nut swallowed the sun. The Vikings believed a rainbow was the gods’ bridge to earth. The Japanese used to explain earthquakes by conjuring a gigantic catfish that carried the world on its back—earthquakes occurred each time it flipped its tail. These are magical, extraordinary tales. But there is another kind of magic, and it lies in the exhilaration of discovering the real answers to these questions. It is the magic of reality—science.\n\nPacked with clever thought experiments, dazzling illustrations and jaw-dropping facts, The Magic of Reality explains a stunningly wide range of natural phenomena. What is stuff made of? How old is the universe? Why do the continents look like disconnected pieces of a puzzle? What causes tsunamis? Why are there so many kinds of plants and animals? Who was the first man, or woman? This is a page-turning, graphic detective story that not only mines all the sciences for its clues but primes the reader to think like a scientist as well.\n\nRichard Dawkins, the world’s most famous evolutionary biologist and one of science education’s most passionate advocates, has spent his career elucidating the wonders of science for adult readers. But now, in a dramatic departure, he has teamed up with acclaimed artist Dave McKean and used his unrivaled explanatory powers to share the magic of science with readers of all ages. This is a treasure trove for anyone who has ever wondered how the world works. Dawkins and McKean have created an illustrated guide to the secrets of our world—and the universe beyond—that will entertain and inform for years to come.	\N	26675	2016	2011-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1327883246i/11256979.jpg	{}	{}	2025-01-16 18:15:41.977	2025-01-16 18:15:41.977
128	52593484	MASIH PERLUKAH MEMBACA Marx pada hari ini? Masih relevankah membaca Marx pada zaman ketika setiap detik kita temukan wajah penuh senyuman dipamerkan di media sosial, perusahaan-perusahaan menggaji karyawannya sesuai dengan standar hidup umum, dan berita-berita kelaparan menghilang dari koran pagl?\n\nBuku ini merupakan jawaban afirmatif terhadap pertanyaan tersebut. Jika kemudian kita bertanya-tanya, bukankah Marx begini, bukankah Marx begitu, bukankah Marx mengatakan demikian, dan sederet proposisi lainnya yang mengandaikan sebuah konklusi bahwa tulisan-tulisan Marx sudah ketinggalan zaman bagi generasi masa kini, maka kita bukan hanya perlu membaca Marx melainkan juga perlu mengawalinya dengan membaca buku ini.\n\nKarena dalam buku ini Eagleton mengumpulkan sepuluh prasangka umum tentang Marx dan mencoba mementahkannya. Formatnya sederhana: prasangka-prasangka itu ditulis sebagai pembuka setiap bab, lalu di tiap-tiap bab itu Eagleton menunjukkan bahwa prasangka tersebut tak memiliki pondasi untuk menihilkan perlunya membaca Marx pada hari ini.\n\n"Saya berupaya untuk menyajikan gagasan-gagasan Marx bukan sebagai sesuatu yang sempurna melainkan sebagai sesuatu yang masuk akal. Buku ini juga bermaksud memberikan satu pengantar pemikiran Marx yang jelas dan mudah diterima bagi orang-orang yang tidak akrab dengan karya-karya Marx."\n—Eagleton	\N	5102	531	2011-07-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1584878368i/52593484.jpg	{}	{}	2025-01-16 17:42:22.687	2025-01-16 17:42:22.687
129	662912	8" * 5.3".	\N	924	114	1948-12-31	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1241220079i/662912.jpg	{}	{}	2025-01-17 05:43:54.107	2025-01-17 05:43:58.438
130	\N		\N	\N	\N	\N				\N		\N	https://onesearch.id/Cover/Show?author=SUPRAPTO%2C+Tommy&callnumber=&size=medium&title=Komunikasi+propaganda%3A+Teori+dan+praktik%23+Tommy+Suprapto&isbn=6029791257	{}	{}	2025-01-18 19:16:03.717	2025-01-18 19:16:05.156
131	3183649	"Marxisme", karena dilebih-lebihkan, telah menjadi momok yang menakutkan sebagai sarana pembebasan umat manusia dari ketidakadilan maupun sebagai sumber segala subversi. Dalam buku ini, Prof. Dr. Franz Magnis-Suseno, SJ menjelaskan pokok-pokok pemikiran Marx secara objektif dan kritis. Setelah mengemukakan bentuk-bentuk sosialisme "utopis" yang mendahului Marx, ia kemudian menelusuri perkembangan dalam pemikiran dari paham Marx muda tentang peran filsafat kritis dan keterasingan manusia sampai terbentuknya teori tentang hukum-hukum yang mendasari perubahan masyarakat dan kritik terhadap kapitalisme. Selanjutnya, ia menggariskan kembali bagaimana ajaran Marx menjadi "Marxisme", ideologi perjuangan kaum buruh, serta memperkenalkan aliran-aliran terpenting dalam Marxisme. Siapa pun yang ingin mengetahui apa yang sebenarnya diajarkan oleh Marx serta membentuk penilaian kritis sendiri tentangnya akan sangat terbantu oleh buku ini, tanpa terjebak oleh jargon-jargon yang serta-merta mengutuk maupun memuji Marxisme, yang sebenarnya hanya untuk menyelamatkan kepentingan-kepentingan sempit tertentu.	\N	428	46	1999-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1207812375i/3183649.jpg	{}	{}	2025-01-16 17:32:23.558	2025-01-16 17:32:23.558
132	59039542	Buku Dari Sinai sampai Al-Ghazali ini menghimpun esai-esai panjang Goenawan Mohamad yang berisi telaah, renungan, tafsir, sanggahan, dan percakapan sang penulis tentang para pemikir yang merentang mulai Marx hingga Al-Ghazali, Plato hingga Driyarkara, Nietzsche hingga Baldwin. Pokok pergumulan dalam percakapan Goenawan di antaranya adalah ihwal identitas, filsafat dan laku, agama dan politik: tema-tema utama zaman kita.\n\nDitulis dengan tenang tapi penuh gairah, saling silang antara keanggunan bahasa puisi dengan keketatan argumentasi, antara risalah dan kisah, bentangan khazanah sini dan sana. Alhasil, membacanya Anda harus terus awas dan konsentrasi: kalau tidak, Anda bisa tersesat di keluasan cakrawalanya.	\N	4	2	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1632141360i/59039542.jpg	{}	{}	2025-01-16 18:15:07.049	2025-01-16 18:15:07.049
133	6147324	Rene Descartes, selain sering disebut sebagai Bapak Filsafat Modern. Juga dikenal sebagai pencetus fisika matematis, penemu geometri analitis, dan tokoh penting dalam sejarah optik atau pun fisiologi. Ia pun dikenal luas sebagai matematikawan.\nBuku Discours de la methode (1637) ini merupakan karya monumentalnya, diterbitkan sebagai pengantar untuk ketiga esainya: Dioptrique, Meteores dan Geometrie (bagian dari Traite du Monde).\nKarya-karya Descartes lainnya, antara lain, Meditation Metaphysiques (dalam bahasa Latin, 1641), Principes de la Philosophie (dalam bahasa Latin, 1644) dan Traite des Passions de l'Ame (1649).	\N	23681	1030	1637-06-07	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1454776831i/6147324.jpg	{}	{}	2025-01-17 05:44:57.859	2025-01-17 05:45:02.22
134	7558313	SOEKARNO, selain dikenal sebagai Sang Proklamator, Presiden Pertama RI dan berbagai gelar yang disandangnya kemudian, juga merupakan seorang pemikir dan intelektual Islam. Pikiran-pikirannya tentang pembaruan pemikitan Islam sangat berharga bagi khazanah pemikiran Islam di Indonesia.\n\nISLAM SONTOLOYO, dan beberapa tulisan lain yang ada dalam buku ini, merupakan pikiran-pikirannya yang paling "ekstrim" dalam menggugat cara berpikir umat Islam Indonesia. Tulisan itu tidak saja menggemparkan dunia Islam Indonesia ketika itu, tapi bahkan telah menimbulkan polemik dengan tokoh-tokoh Islam, terutama dengan M. Natsir yang berlangsung sepanjang tahun 1930 - 1935. Polemik dengan M. Natsir tersebut diakui sebagai polemik yang nyaris belum ada tandingan bobotnya dala sejarah polemik di Indonesia.	\N	270	19	2006-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1312628394i/7558313.jpg	{}	{}	2025-01-16 18:08:46.158	2025-01-16 18:08:46.158
135	4309628	Filsafat Barat mempunyai riwayat panjang yang sudah meliputi 26 abad. Tempat lahirnya Yunani kuno dan tanggal lahirnya abad ke-6 SM. Pada mulanya nama "filsafat" tidak menunjukkan ilmu tertentu saja, tapi dipakai untuk pemikiran ilmiah pada umumnya. Waktu itu "filsafat" dimaksudkan sebagai pemikiran rasional yang bertolak belakang dengan segala pendekatan mitis. Lama-kelamaan ilmu-ilmu lain satu demi satu melepaskan diri dari pendekatan lebih umum yang disebut "filsafat" itu. Buku ini merupakan revisi dari buku Fisafat Barat Abad XX yang terbit pada tahun 1981. Uraian tentang Jeurgen Habermas diperbaharui seluruhnya, karena dalam pemikiran filsuf Jerman ini berlangsung perkembangan penting sejak tahun 1980-an. Perkembangan tentang filsuf-filsuf lain disesuaikan dengan penelitian terbaru mengenai pemikiran mereka.	\N	98	11	1983-12-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1551165807i/4309628.jpg	{}	{}	2025-01-16 17:51:19.713	2025-01-16 17:51:19.713
252	364957	Sure, lots of people say they want to be the King of the Pirates, but how many have the guts to do what it takes? When Monkey D. Luffy first set out to sea in a leaky rowboat, he had no idea what might lie over the horizon. Now he's got a crew--sort of--in the form of swordsman Roronoa Zolo and treasure-hunting thief Nami. If he wants to prove himself on the high seas, Luffy will have to defeat the weird pirate lord Buggy the Clown. He'll have to find a map to the Grand Line, the sea route where the toughest pirates sail. And he'll have to face the Dread Captain Usopp, who claims to be a notorious pirate captain...but frankly, Usopp says a lot of things...	\N	22792	951	1998-06-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1388531492i/364957.jpg	{}	{}	2025-01-16 17:53:17.454	2025-01-16 17:53:17.454
136	31785	Nietzsche’s notebooks, kept by him during his most productive years, offer a fascinating glimpse into the workshop and mind of a great thinker, and compare favorably with the notebooks of Gide and Kafka, Camus and Wittgenstein. The Will to Power, compiled from the notebooks, is one of the most famous books of the past hundred years, but few have studied it. Here is the first critical edition in any language.\n\nDown through the Nazi period The Will to Power, was often mistakenly considered to be Nietzche’s crowning systematic labor; since World War II it has frequently been denigrated. In fact, it represents a stunning selection from Nietzsche’s notebooks, in a topical arrangement that enables the reader to find what Nietzsche wrote on nihilism, art, morality, religion, the theory of knowledge, and whatever else interested him. But no previous edition—even in the original German—shows which notes Nietzsche utilized subsequently in his works, and which sections are not paralleled in the finished books. Nor has any previous edition furnished a commentary or index.\n\nWalter Kaufmann, in collaboration with R. J. Holilngdale, brings to this volume his unsurpassed skills as a Nietzsche translator and scholar. Professor Kaufmann has included an approximate date of each note. His running footnote commentary offers information needed to follow Nietzsche’s train of thought, and indicates, among other things, which notes were eventually superseded by later formulations. The comprehensive index serves to guide the reader to the extraordinary riches of this book.	\N	10741	308	1901-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1403177768i/31785.jpg	{}	{}	2025-01-16 17:58:08.332	2025-01-16 17:58:08.332
137	181335459		\N	0	0	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1694923310i/181335459.jpg	{}	{}	2025-01-16 18:07:22.252	2025-01-16 18:07:22.252
138	74649	This Introduction explores the origins of capitalism and questions whether it did indeed originate in Europe. It examines a distinctive stage in the development of capitalism that began in the 1980s, in order to understand where we are now and how capitalism has evolved since. The book discusses the crisis tendencies of capitalism--including the S.E. Asian banking crisis, the collapse of the Russian economy, and the 1997-1998 global financial crisis--asking whether capitalism is doomed to fail. In the end, the author ruminates on a possible alternative to capitalism, discussing socialism, communal and cooperative experiments, and alternatives proposed by environmentalists.\n\nAbout the Series: Combining authority with wit, accessibility, and style, Very Short Introductions offer an introduction to some of life's most interesting topics. Written by experts for the newcomer, they demonstrate the finest contemporary thinking about the central problems and issues in hundreds of key topics, from philosophy to Freud, quantum theory to Islam.	\N	1290	146	2001-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1637897055i/74649.jpg	{}	{}	2025-01-16 18:29:57.617	2025-01-16 18:29:57.617
139	31845767	Bagi para ekonom neoklasik dan pendukungnya, mem­bludaknya pekerja informal di Indonesia sejak 1980an tidak peru dikhawatirkan. Mereka meyakini, jika pasar diperbolehkan berfungsi dengan baik, pekerja informal akan mampu menjadi pengusaha mikro, dan peng­usaha mikro nantinya akan mam­pu mengubah bisnis mereka ke peng­aturan formal dan de­ngan demikian secara otomatis menghilangkan perekonomian informal. \n\nBuku ini mempersoalkan klaim di atas dengan menganalisis dampak penyesuaian neoliberal terhadap melimpahnya surplus populasi relatif, yakni suatu kombinasi antara pengangguran dan proletariat informal di negeri-negeri pinggiran. Berfokus pada lintasan pemba­ngunan Indo­nesia, bu­ku ini berusaha menunjukkan bahwa alih-alih menjadi peng­usaha mikro, mayoritas pekerja informal cenderung menjadi proletariat informal yang tidak terpenuhi hak-hak dasarnya sebagai pekerja. Mereka bekerja di luar sektor inti dari produktivitas kapitalis dalam kondisi rentan, terengah-engah untuk sekadar bertahan hidup. Orientasi pembangunan yang dipimpin pasar global, bertentangan dengan klaim untuk menghapus pekerjaan informal, justru cenderung mengabadikannya.\n\n“Karya Muhtar Habibi berhasil men­do­rong pembahasan mengenai masalah pengangguran dan rendahnya kua­litas pekerjaan sebagian yang cukup besar dari penduduk In­do­nesia me­nurut suatu perspektif yang berbeda dengan yang ditemui dalam ilmu ekonomi neoklasik.” —Vedi R. Hadiz	\N	29	1	2016-09-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1473168393i/31845767.jpg	{}	{}	2025-01-16 17:50:16.258	2025-01-16 17:50:16.259
140	\N	Hukum dan Politik adalah topik yang sangat penting untuk pemikiran filosofis (di) Indonesia. Salah satu simpul yang muncul, pemikiran Indonesia mengenai politik dan hukum sanggup mengadaptasi konsep-konsep dan model-model pemikiran Barat modern, seperti nasionalisme, demokrasi, ketatanegaraan, sekularisme, dan hak asasi manusia, tetapi adaptasi itu tidak disertai dialektika dan sintesis, melainkan lebih memberikan ruang hidup untuk konsep-konsep tersebut bersama mentalitas Nusantara. Rasionalisasi itu memungkinkan moderasi dan toleransi, dan Pancasila merupakan kristalisasi konseptual sikap moderat itu.\n\nTulisan-tulisan yang dikumpulkan dalam buku ini merupakan bahan diskusi di dalam Simposium Internasional Filsafat Indonesia (SIFI) yang diadakan pada 19-20 September 2014. Simposium itu diselenggarakan dengan kerja sama antara Sekolah Tinggi Filsafat Driyarkara Jakarta dengan Kementerian Pendidikan dan Kebudayaan Republik Indonesia dan Museum Rekor-Dunia Indonesia. Buku ini merupakan volume kedua dari empat volume buku dalam seri ini. Adapun keempat gugus tema dalam buku itu adalah Manusia dan Budaya (tema volume pertama), Politik dan Hukum (tema volume kedua ini), Kebijaksanaan Lokal (tema volume ketiga), dan Pelangi Nusantara (tema volume keempat).\n	\N	\N	\N	2019-11-18	Penerbit Buku Kompas			\N	Filsafat [di] Indonesia Politik dan Hukum	\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/9786232410657.jpg	{}	{}	2025-01-17 05:14:17.445	2025-01-17 05:14:21.34
141	17184321	If you wonder what your life tomorrow will bring, this is the book for you. It discusses how your everyday life will change over the next few decades. First it covers the various stages of life, from pre-birth genetic design of your offspring all the way through to death and potential immortality. Along the way it considers the possible future of humanity. In part 2, it goes on to consider almost every aspect of your future everyday lifestyle - including sleeping, eating, socialising, recreation, shopping, education and work. Part 3 outlines many of your likely career options, the areas that will improve in prospects and those that will decline too. The final two parts describe the stuff you are likely to own such as your car and your gadgets, and the nature of the world around you from the rooms in your home to public transport and the future city as well as the potential virtual world overlaying it all.	\N	14	1	2011-08-13	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1677806939i/17184321.jpg	{}	{}	2025-01-16 15:57:04.646	2025-01-16 15:57:04.646
508	\N	Aoi Todo dan Mai Zenin dari Akademi Jujutsu Kyoto muncul di hadapan Fushiguro dan Kugisaki. Tiba-tiba saja Todo langsung melontarkan pertanyaan tak terduga...!! Kira-kira apa, ya, jawaban Fushiguro untuk pertanyaan Todo? Sementara itu, Itadori pergi ke sebuah tempat untuk berlatih kemampuan bertarungnya.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1624631780i/58422935.jpg	\N	\N	2026-02-01 01:57:34.820859	2026-02-01 01:57:34.820859
144	\N	Materi buku teks ini ditulis oleh penulis dengan gaya umum, walaupun di beberapa bab terasa berat, tetapi sangat menarik untuk Anda baca. Setiap bab mempunyai pendekatan sendiri cara mengungkapkannya, tetapi sebagian besar berbasis pada kecerdasan hidup hewan dalam berkoloni.\n\nAda 16 bab di sini, yang dimulai di Bab 1 adalah Kecerdasan koloni binatang dan diakhiri di Bab 16 dengan Algoritma Pelacakan dari Ikan Hiu (Shark Search Algorithm, SSA). Di bab 15, Anda disuguhi Algoritma Optimisasi Serigala Abu-abu (Grey Wolf optimization, GWO) dan semua bab di buku ini sangat menarik untuk Anda baca.\n\nBuku Artificial Intelligence karya Imam Robandi menyampaikan seluk-beluk kecerdasan buatan dengan cara yang unik, yaitu dengan memberikan perumpamaan kecerdasan hidup hewan dalam berkoloni sehingga pembaca dapat memahami isi buku ini lebih baik.\n\nBuku Artificial Intelligence cocok dibaca oleh setiap kalangan, baik pelajar, mahasiswa, maupun masyarakat umum yang tertarik untuk mengetahui cara kerja kecerdasan buatan atau ingin berkecimpung di bidang ini. Semoga buku ini dapat memberikan gambaran yang utuh tentang kecerdasan buatan.\n\n	\N	\N	\N	\N				\N		\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/artificial.jpg	{}	{}	2025-01-17 05:26:28.056	2025-01-17 05:26:32.324
145	\N	Bosan dengan game yang ada di pasaran? Atau tertantang untuk menciptakan game Anda sendiri? Jika demikian, pelajari buku ini dan temukan solusi mudah membuat game 3 dimensi menggunakan Unity 3D. Unity 3D merupakan game engine multiplatform untuk membuat game secara mudah, bahkan oleh pemula sekalipun. Aplikasi ini merupakan oleh developer game diseluruh dunia karena menyediakan fungsionalitas inti yang dibutuhkan untuk menciptakan game-game hebat. Unity 3D memiliki kinerja grafis dengan optimis tinggi dan dapat digunakan di PC , Nintendo Wii, PS3, Xbox 360, pad, Iphone, serta android. Unity 3D menggunakan sistem navigasi bebas dalam pembuatan game, sehingga Anda dapat dengan mudah melihat setiap sisi 3D ketika proses pembuatan objek. Dengan Unity 3D, Anda bebas berkarya.\n\nTidak hanya 1 genre saja yang dapat anda buat, melainkan berbagai genre sesuai keinginan. Buku mudah membuat game 3 dimensi menggunakan Unity 3D ini menjelaskan langkah pembuatan game 3D menggunakan Unity 3D. Tiap langkah pembahasan pada buku ini akan dijelaskan secara runtut sehingga mudah anda pahami. Siap-siaplah kecanduan membuat game setelah mempelajari buku ini! Buku ini membahas Pengenalan Unity 3D, Dasar penggunaan Unity 3D, membuat peta, skrip, dan karakter, membuat sistem game, finishing game.\n	\N	\N	\N	\N				\N		\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/mudah_membuat_game_3_dimensi_dengan_unity_3D_1.jpg	{}	{}	2025-01-17 05:50:10.87	2025-01-17 05:50:15.25
146	\N	Materi Aljabar Linier terdiri dari Vektor, Matriks, Persamaan linier, Transformasi linier, dan Irisan kerucut. Kelima materi ini sebagai fondasi penyelesaian persoalan pada materi kuliah di Fakultas Teknik, Fakultas Ilmu Komputer, dan Fakultas Ekonomi. Berbagai persoalan dalam materi kuliah di bidang Teknik Elektro, misalnya penyelesaiannya, menentukan arah medan magnet, arah arus, dan banyak materi lain menggunakan Vektor. Di bidang Ilmu Komputer membuat algoritma dengan menggunakan matriks dan transformasi linier. Dengan karakteristik yang diharapkan setelah mempelajari buku ini persoalan materi kuliah yang penyelesaiannya menyangkut bahan materi buku ini dapat dikerjakan dan diselesaikan dengan baik serta memahami materi tersebut.\n\nBeberapa keunggulan buku Aljabar Linier ini adalah sebagai berikut.\n\n1. Materi disajikan secara sederhana, sistematis, inspiratif, dan realistis. Mahasiswa diajak berpikir logis dan melihat aplikasi Aljabar Linier dalam kehidupan sehari-hari.\n\n2. Untuk memudahkan pemahaman konsep materi, buku ini dilengkapi dengan contoh soal dan penyelesaian yang dijabarkan dengan teratur dan terstruktur. Soal-soal pelatihan disajikan dalam berbagai bentuk untuk kemampuan daya pikir, analisis, dan kreativitas.\n\n3. Buku ini dilengkapi dengan gambar dari perhitungan sehingga dapat memahami bentuk visual dari persoalan.\n\n4. Bentuk soal disusun terdiri dari pilihan ganda dan essay sesuai dengan bentuk soal yang digunakan dalam ujian tengah semester dan ujian akhir semester di berbagai perguruan tinggi	\N	\N	\N	\N				\N		\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/9786024251581-edit.jpg	{}	{}	2025-01-17 05:34:15.86	2025-01-17 05:34:19.975
147	\N	Buku Machine Learning dan Computational sangat tepat dibaca oleh pelajar dan peneliti di bidang Kecerdasan Buatan dan Matematika Terapan. Buku ini memberikan gambaran lengkap konsep Machine Learning dan Computational Intelligence. Layak dimiliki karena langsung diimplementasikan untuk menghasilkan sebuah system cerdas di masa depan, berisi materi antara lain:• Konsep Machine Learning dan Penerapan pada Python• Dasar Computational Intellegence• Neural Network dan Algoritma Genetik• PSO, Artificial Immune System dan Fuzzy Logic• Ant Colony Optimization dan computer vision	\N	\N	\N	2021-09-15	Andi Publisher			\N	Machine Learning and Computational Intelligence	\N	https://ebooks.gramedia.com/ebook-covers/66792/image_highres/BLK_MLACI2021480374.jpg	{}	{}	2025-01-17 05:04:14.294	2025-01-17 05:04:18.254
148	\N	AngularJS adalah Framework Javascript yang dikembangkan oleh GOOGLE dan banyak digunakan pada produk-produk yang dibuat oleh Google. Dan saat ini diperkirakan ada 12.000 website dan beberapa contoh website populer yang telah menggunakan AngularJS seperti Intel, ABC News, Sprint, NBC, Walgreens, dsb.\n\nAngularJS telah menjadi salah satu standarisasi untuk keperluan pembuatan Aplikasi Web Dinamis dari Sisi Client, karena kemudahan dan kecepatannya dalam melakukan komunikasi Server ke Client. Dan di dalam buku ini telah disusun secara sistematis dan step by step untuk menguasai AngularJS. Materi yang dibahas dalam buku ini mencakup:\n\n- Berkenalan dengan AngularJS.\n- Jelajah Output dengan Data View (Expression, Directive, Multi Variable).\n- Two Way Data-Binding pada Tag HTML (Text, TextArea, Select, Radio).\n- Bekerja dengan Controller (Array Bertingkat, if-else, Multi Module).\n- Built-in Filter (Filter Berantai, Format Huruf, Mata Uang, Nomor).\n- Berinovasi dengan Directive (ngBind, ngInit, ngRepeat, Directive Sendiri).\n- Routing.\n- Kolaborasi AngularJS, PHP dan MySQL.\n- Penerapan Materi: Membuat Website Dinamis.\n- Bonus: Membuat Aplikasi dan Game Interaktif.\n\nBuku ini dapat dijadikan referensi oleh siapapun yang ingin mempelajari AngularJS. Miliki segera dan mulailah berlatih!\n\nTentang Penulis\nLutfi Gani, alumnus STMIK AMIK Bandung, jurusan Teknik Informatika. Selain itu, ia pernah bekerja sebagai IT Consultant di Jakarta. Saat ini, ia menjadi pengajar aktif Mata Pelajaran Produksi TKJ di SMK Negeri.	\N	\N	\N	\N				\N		\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/Menguasai-Angular-JS-Untuk-Membuat-Website-Dinamis.jpg	{}	{}	2025-01-17 05:43:38.117	2025-01-17 05:43:42.461
253	22716175	Something is rotten in Okinawa...\n\nThe floating smell of death hangs over the island. What is it? A strange, legged fish appears on the scene... So begins Tadashi and Kaori's spiral into the horror and stench of the sea. Here is the creepiest masterpiece of horror manga ever from the creator of Uzumaki, Junji Ito. Hold your breath until all is revealed.	\N	28680	3504	2014-12-31	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1550552222i/22716175.jpg	{}	{}	2025-01-16 17:09:35.028	2025-01-16 17:09:35.028
149	\N	Skrip Python adalah file yang berisi kode yang ditulis dengan Python, biasanya dengan ekstensi .py. File ini dibaca dan dieksekusi baris demi baris oleh interpreter Python. Skrip Python dapat ditulis dalam editor teks apa pun. Contoh paling sederhana dari editor teks ini adalah Notepad (Windows) dan Nano (Linux). Namun, untuk mempermudah, kami sangat menyarankan menggunakan editor kode seperti VS Code, Sublime Text, atau Atom untuk membuat skrip Python Anda. Untuk membuat skrip Python, cukup masukkan skrip yang diinginkan ke dalam file dengan ekstensi .py. Menulis skrip ini sama dengan menulis kode dalam interpreter Python interaktif.\n\nSinopsis\nMengurus dan mengatur sebuah peralatan jaringan tidaklah sulit, demikian juga ketika peralatan Anda bertambah menjadi 2 atau 3 namun seiring dengan bertambahnya peralatan, Anda akan mulai menghadapi banyak masalah dan menghabiskan sangat banyak waktu Anda ditambah dengan berbagai kesalahan dan ‘lupa’ yang bisa berakibat fatal. Buku ini akan membahas tentang otomatisasi yang bisa Anda buat sendiri dengan script Python dan menghemat ribuan jam kerja Anda.\n\nJangan bekerja keras namun bekerjalah dengan pintar dan cerdik. Dengan memanfaatkan script python, Anda bisa mengerjakan banyak pekerjaan administrasi jaringan dengan mudah dan tanpa salah.	\N	\N	\N	\N				\N		\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/9786020823294_Otomatisasi-A.jpghttps://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/9786020823294_Otomatisasi-A.jpg	{}	{}	2025-01-17 05:33:30.55	2025-01-17 05:33:34.84
150	107552740	Hacking adalah aktivitas untuk masuk ke sebuah sistem komputer dengan mencari kelemahan dari sistem keamanannya. Karena sistem adalah buatan manusia, maka tentu saja tidak ada yang sempurna. Terlepas dari pro dan kontra mengenai aktivitas hacking, buku ini akan memaparkan berbagai tool yang bisa digunakan untuk mempermudah proses hacking. Buku ini menjelaskan tahapan melakukan hacking dengan memanfaatkan tooltool yang tersedia di Internet. Diharapkan setelah mempelajari buku ini, Anda bisa menjadi hacker atau praktisi keamanan komputer, serta bisa memanfaatkan keahlian hacking untuk pengamanan diri sendiri ataupun pengamanan objek lain.	\N	0	0	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1679354413i/107552740.jpg	{}	{}	2025-01-16 17:30:48.235	2025-01-16 17:30:48.235
151	\N	Saat ini, Website Profil Sekolah menjadi tren di dunia pendidikan, tanggapan yang bagus datang dari tenaga kependidikan, siswa, dan juga masyarakat. Dengan adanya website tersebut, pihak sekolah dapat memberikan informasi sekolah yang terbaru, akurat, dan cepat.\n\nMenariknya lagi, Website Profil Sekolah di integrasikan dengan PPDB (Penerimaan Peserta Didik Baru) Online yang digunakan untuk mengolah data calon siswa baru, sehingga mempermudah pengelolaan administrasi dan transparansi dari proses penerimaan peserta didik baru tersebut. Tidak hanya itu, dibahas juga pembuatan Blog Siswa untuk mengasah kreativitas mereka, dimana Blog tersebut juga di integrasikan ke Website Profil Sekolah.\n\nWebsite dibangun menggunakan PHP, MySQL, AJAX/jQuery & Bootstrap. Dan website juga menerapkan RESPONSIVE, sehingga Website Profil Sekolah juga dapat tampil dengan bagus saat diakses melalui handphone, baik Halaman Pengunjung maupun Halaman Administrator.\n\n	\N	\N	\N	\N	loko media			\N		\N	https://www.penerbitlokomedia.com/img_produk/42membuat-web-profil-sekolah-ppdb-online.jpg	{}	{}	2025-01-17 05:13:09.18	2025-01-17 05:13:13.096
152	\N	Sistem Pakar adalah mata kuliah yang mendukung untuk membuat aplikasi yang dapat memecahkan masalah dengan pengetahuan seorang pakar yang di dimasuk..	\N	\N	\N	\N	Mitra Wacana Media			\N		\N	https://www.mitrawacanamedia.com/image/cache/catalog/data/buku_teknik_komputer/pengantar_sistem_pakar_dan_metode-600x600.jpg	{}	{}	2025-01-18 19:09:19.138	2025-01-18 19:09:20.779
153	\N	Keberadaan aplikasi dan layanan berbasis teknologi informasi yang semakin pesat dari waktu ke waktu, memicu tumbuh dan berkembangnya data-data digital.	\N	\N	\N	\N				\N		\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/9786026232564_Handbook-Data-Warehouse--DVD.jpg	{}	{}	2025-01-17 05:49:38.79	2025-01-17 05:49:43.163
154	\N	Di tengah pesatnya perkembangan teknologi kecerdasan buatan atau artificial intelligence (AI) saat ini. Belum banyak orang yang mengetahui bahwa kecerdasan buatan itu terdiri dari beberapa cabang, salah satunya adalah machine learning atau pembelajaran mesin. Machine Learning adalah mesin yang dikembangkan untuk bisa belajar dengan sendirinya tanpa arahan dari penggunanya. Pembelajaran mesin dikembangkan berdasarkan disiplin ilmu lainnya seperti statistika, matematika dan data mining sehingga mesin dapat belajar dengan menganalisa data tanpa perlu di program ulang atau diperintah.\n\nBuku ini membahas konsep dasar Machine Learning dan algoritma Machine Learning yang populer. Pada setiap bab yang terkait dengan algoritma Machine Learning, telah disertakan contoh-contoh latihan menggunakan R. Aplikasi R merupakan aplikasi Statistika yang akhir-akhir ini semakin populer.\n\nBuku ini sengaja dibuat untuk berbagai kalangan, mulai dari kalangan umum, mahasiswa, dosen, atau kalangan lain yang tertarik untuk belajar Machine Learning dari awal. Di dalam buku ini dijelaskan konsep dasar R dengan beberapa contoh soal matematika, neural network, supervised learning, unsupervised learning, dan bagaimana memahami data serta mengolah data untuk keperluan latihan.\n\nSebagai pelangkap telah disertakan DVD yang berisi berbagai aplikasi yang sangat membantu untuk memudahkan mengerjakan latihan di dalam buku ini.	\N	\N	\N	\N				\N		\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/9786026232670_Belajar-Machine-Learning_Teori-dan-Praktik--CD.jpg	{}	{}	2025-01-18 19:11:01.957	2025-01-18 19:11:03.631
155	40123077	The “firefly algorithm” (FA) is a nature-inspired technique originally designed for solving continuous optimization problems. There are several existing approaches that apply FA also as a basis for solving discrete optimization problems, in particular the “traveling salesman problem” (TSP). In this chapter, we present a new movement scheme called edge-based movement, an operation which guarantees that a candidate solution more closely resembles another one. This leads to a more FA-like behavior of the algorithm. We investigate the performance of the ‘evolutionary discrete firefly algorithm” when using this new edge-based movement and compare it against previous methods. Computer simulations show that the new movement scheme produces slightly better accuracy with much faster average time. The average speedup factor is 14.06 times.	\N	0	0	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1526352559i/40123077.jpg	{}	{}	2025-01-16 18:25:33.809	2025-01-16 18:25:33.809
263	55980428	町の商店を営むふくよかな男・坂本太郎。その正体は全ての悪党が恐れ、憧れた元・伝説の殺し屋!!　襲い来る危険から家族と日常を守る、坂本の日々とは…!?　バトルとコメディが交錯するネオアクション活劇、開幕!!	\N	6095	642	2021-04-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1617384366i/55980428.jpg	{}	{}	2025-01-18 19:18:03.938	2025-01-18 19:18:05.309
264	208509126		\N	8	0	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1707954641i/208509126.jpg	{}	{}	2025-01-19 11:35:49.619	2025-01-19 11:35:49.456
156	49618262	Di dalam Artificial Intelligence (AI) dikenal empat teknik pemecahan masalah, yaitu: Searching, Reasoning, Planning dan Learning. Dalam setiap teknik tersebut, terdapat banyak metode yang diusulkan dan sudah dibuktikan secara matematis maupun empiris. Penggunaan teknik dan metode tersebut sangat bergantung pada permasalahan yang akan diselesaikan. Mereka yang baru mempelajari AI seringkali merasa kesulitan dalam memilih teknik dan metode yang tepat untuk menyelesaikan suatu masalah. Buku ini membahas keempat teknik tersebut dan metode-metode yang ada didalamnya. Pembahasan dilakukan melalui ilustrasi dan studi kasus untuk mempermudah pemahaman dan memperjelas perbedaan diantara keempat teknik tersebut. Pembahasan setiap teknik dan metode akan dilakukan secara global, dari ide dan teori dasarnya, sampai detail ke implementasinya. Diharapkan buku ini tidak hanya untuk kalangan mahasiswa Teknik Informatika maupun Ilmu Komputer saja, tetapi juga untuk kalangan pelajar maupun profesional.	\N	3	0	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1576939053i/49618262.jpg	{}	{}	2025-01-16 17:04:45.112	2025-01-16 17:04:45.112
157	\N	Saat ini Python sudah mulai marak digunakan untuk membangun aplikasi berbasis web. YouTube adalah salah satunya. Meskipun pada awal peluncurannya YouTube masih ditulis menggunakan PHP, tapi beberapa bulan kemudian YouTube ditulis ulang menggunakan Python. Terdapat beberapa web framework yang dapat digunakan untuk mempermudah dan mempercepat proses pengembangan web menggunakan Python, di antaranya Django, Flask, Bottle, CherryPy, Web2py, Pyramid, dll. Meskipun demikian, yang populer saat ini dan banyak digunakan oleh pengguna Python adalah Django dan Flask.\n\nBuku ini akan membahas tentang materi-materi esensial yang diperlukan dalam mengembangkan aplikasi berbasis web menggunakan Python dan Flask. Flask sering disebut sebagai micro framework karena hanya menyertakan pustaka inti di dalam paket distribusinya. Pustaka-pustaka pendukung lain disimpan dalam bentuk ekstensi, yang dapat dipasang secara terpisah pada saat dibutuhkan saja. Dengan demikian, Flask berukuran sangat kecil.\n\nDengan mempelajari buku ini, diharapkan Anda dapat berkreasi untuk menciptakan aplikasi-aplikasi berbasis web dengan memanfaatkan keunggulan yang dimiliki oleh Python dan Flask. Syarat utama yang harus dimiliki sebelum mempelajari Flask adalah pengetahuan tentang bahasa pemrograman Python dan database. Khusus bagi Anda yang belum pernah menggunakan Python dan/atau belum pernah bekerja dengan database, buku ini menceritakan tutorial Python dan tutorial SQL (menggunakan MySQL) sebagai lampiran. Buku ini cocok bagi Anda yang tertarik dengan dunia pemrograman.	\N	\N	\N	\N				\N		\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/9786026232267.jpg	{}	{}	2025-01-17 05:37:28.446	2025-01-17 05:37:32.764
158	23658963	THE ULTIMATE GUIDE TO BUILDING AN APP-BASED BUSINESS\n\n'A must read for anyone who wants to start a mobile app business' Riccardo Zacconi, founder and CEO King Digital (maker of Candy Crush Saga)\n\n'A fascinating deep dive into the world of billion-dollar apps. Essential reading for anyone trying to build the next must-have app' Michael Acton Smith, Founder and CEO, Mind Candy\n\nApps have changed the way we communicate, shop, play, interact and travel and their phenomenal popularity has presented possibly the biggest business opportunity in history.\n\nIn How to Build a Billion Dollar App , serial tech entrepreneur George Berkowski gives you exclusive access to the secrets behind the success of the select group of apps that have achieved billion-dollar success.\n\nBerkowski draws exclusively on the inside stories of the billion-dollar app club members, including Instagram, Whatsapp, Snapchat, Candy Crush and Uber to provide all the information you need to create your own spectacularly successful mobile business. He guides you through each step, from an idea scribbled on the back of an envelope, through to finding a cofounder, building a team, attracting (and keeping) millions of users, all the way through to juggling the pressures of being CEO of a billion-dollar company (and still staying ahead of the competition).\n\nIf you've ever dreamed of quitting your nine to five job to launch your own company, you're a gifted developer, seasoned entrepreneur or just intrigued by mobile technology, How to Build a Billion Dollar App will show you what it really takes to create your own billion-dollar, mobile business.	\N	1377	88	2013-12-31	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1420791474i/23658963.jpg	{}	{}	2025-01-16 16:49:34.061	2025-01-16 16:49:34.061
159	\N	Ruby adalah salah satu bahasa pemrograman skrip yang saat ini mulai banyak digunakan untuk mengembangkan program-program console atau command-line interface (CLI), GUI, maupun web. Twitter, Github, dan SlideShare adalah contoh program berbasis web yang dibangun menggunakan Ruby.\n\nRuby merupakan interpreter (bukan compiler); sama seperti Python dan PHP. Dengan kesederhanaan sintaks yang ditawarkan, Ruby mencoba untuk membantu para programmer agar lebih produktif dalam menyelesaikan pekerjaannya. Kode program yang ditulis dengan Ruby pada umumnya jauh lebih pendek dan lebih mudah dipahami jika dibandingkan dengan bahasa-bahasa pemrograman lain yang merupakan keluarga C.\n\nBuku ini membahas tentang dialek dan aturan-aturan yang ditetapkan di dalam Ruby, mulai dari materi-materi dasar (variabel, tipe data, operator, struktur kontrol, fungsi, dan lain-lain) sampai ke materi-materi yang lebih lanjut (hash, kelas, modul, akses file, dan akses database). Dalam bab terakhir dibahas juga tentang cara pembuatan program visual (GUI) menggunakan Ruby dan Qt (Pustaka GUI milik C++). Setiap materi yang disampaikan disertai dengan contoh kode agar konsepnya lebih mudah dipahami dan diaplikasikan ke dalam kasus-kasus riil. Seluruh kode yang ada diuji dan didemonstrasikan menggunakan Ruby 2.3 pada sistem operasi Linux Ubuntu 16.04.\n\nRuby bersifat cross-platform. Dengan demikian, untuk mempelajari buku ini, Anda dapat menggunakan sistem operasi apa saja, Linux, Windows, maupun Mac OS X. Buku ini ditujukan untuk siapa saja yang ingin memiliki keterampilan dalam pengembangan program menggunakan bahasa pemrograman Ruby; baik pelajar, mahasiswa, penggemar, maupun praktisi.	\N	\N	\N	2017-05-05	Informatika			\N		\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/9786026232335_Mudah-Belajar-Ruby-Cd.jpg	{}	{}	2025-01-17 05:10:29.546	2025-01-17 05:10:33.418
173	54566338	Akankah alam semesta berakhir? Berapa lama manusia atau keturunannya bertahan? Ujung takdir alam semesta telah lama menarik perhatian dan pemikiran umat manusia. Sains menawarkan beberapa prakiraan, berdasarkan ilmu fisika, kosmologi, dan matematika.\n\n\n  Tiga Menit Terakhir\n adalah kisah masa depan alam semesta, terkaan terbaik yang bisa kita prediksi, berdasarkan pemikiran terkini beberapa ahli fisika dan ahli kosmologi ternama. Tidak semuanya tentang kehancuran. Masa depan justru mengandung potensi baru untuk pengembangan dan kekayaan pengalaman. Namun, kita tidak bisa mengabaikan fakta bahwa apa-apa yang bisa muncul juga bisa lenyap.\n\nPaul Davies meraih gelar Ph.D. fisika teori di University College London. Kini dia bekerja sebagai profesor fisika di Arizona State University dan direktur BEYOND: Center for Fundamental Concepts in Science. Dia telah menulis banyak artikel dan buku populer maupun teknis mengenai fisika, alam semesta, kehidupan luar Bumi, dan banyak topik lain.	\N	1180	121	1995-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1594992986i/54566338.jpg	{}	{}	2025-01-16 18:04:40.487	2025-01-16 18:04:40.487
160	\N	Artificial Intelligence (AI) adalah bidang ilmu komputer yang dikhususkan untuk memecahkan masalah kognitif yang umumnya terkait dengan kecerdasan manusia, seperti pembelajaran, pemecahan masalah, dan pengenalan pola. Artificial Intelligence, sering disingkat sebagai "AI", mungkin berkonotasi dengan robotika atau adegan futuristik, Artificial Intelligence (AI) mengungguli robot fiksi ilmiah, ke dalam non-fiksi ilmu komputer canggih modern.\n\nMachine learning (ML) adalah bidang penyelidikan yang ditujukan untuk memahami dan membangun metode yang 'belajar', yaitu metode yang memanfaatkan data untuk meningkatkan kinerja pada beberapa rangkaian tugas. Hal ini dilihat sebagai bagian dari kecerdasan buatan. Algoritma pembelajaran mesin membangun model berdasarkan data sampel, yang dikenal sebagai data pelatihan, untuk membuat prediksi atau keputusan tanpa diprogram secara eksplisit untuk melakukannya. Algoritma pembelajaran mesin digunakan dalam berbagai aplikasi, seperti dalam kedokteran, penyaringan email, pengenalan suara, dan visi komputer, di mana sulit atau tidak mungkin untuk mengembangkan algoritma konvensional untuk melakukan tugas yang diperlukan.\n\nDeep learning (juga dikenal sebagai deep structured learning) adalah bagian dari keluarga metode pembelajaran mesin yang lebih luas berdasarkan jaringan saraf tiruan dengan pembelajaran representasi. Belajar dapat diawasi, semi-diawasi atau tanpa pengawasan.\n\nSinopsis\nBagi sebagian orang. Artificial Intelligence (AI), Machine Learning (ML), dan Deep Learning (DL) telah menjadi teknologi disruptif yang mengancam pekerjaan mereka. Namun, bagi sebagian yang lain, semua teknologi itu justru memudahkan dan memurahkan berbagai pekerjaan sehingga mereka bisa lebih banyak menikmati hiburan dan liburan.\n\nBuku ini memberikan gambaran holistik, namun simpel, mengenai ide dasar, capaian, peluang, tantangan, dan masa depan EML. Penjelasan logis dan diskusi dikemas secara ringkas mulai dari konsep dasar yang paling simpel, lalu secara perlahan bergerak hingga gagasan yang relatif kompleks. Setiap model EML dibahas dari ide dasar, motivasi, visualisasi, formulasi matematis, hingga aplikasi yang telah dicapai.	\N	\N	\N	\N				\N		\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/img20201211_16243507.jpg	{}	{}	2025-01-17 05:39:33.011	2025-01-17 05:39:36.806
161	3501200		\N	160	16	1999-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1214031559i/3501200.jpg	{}	{}	2025-01-16 17:59:13.377	2025-01-16 17:59:13.377
162	\N	i era digital saat ini hampir semua kegiatan manusia telah didukung dan dibantu oleh teknologi pintar hingga Artificial Intelligence. Android merupakan salah satu sistem operasi mobile yang paling banyak digunakan di dunia saat ini. Berbagai perangkat digital, mulai dari smartphone, televisi, hingga kacamata digital dapat menggunakan android sebagai pusat operasinya untuk menghasilkan berbagai fitur pintar.\n\nOleh karena itu, kebutuhan akan pengetahuan dan pemahaman teknologi yang digunakan dalam sistem operasi android sangatlah berguna bagi setiap orang, terutama bagi para pengembang aplikasi, ilmuwan, dan mahasiswa yang menekuni bidang ilmu teknologi.\n\nBuku Pemrograman Android Dengan Android Studio Ide ini disusun sebagai upaya penyebrangan ilmu mengenai konsep dasar yang perlu diketahui oleh setiap orang sebelum mengembangkan suatu aplikasi android. Adapun materi yang disajikan dalam buku ini dibagi menjadi 14 bab, antara lain:\nPengenalan pemrograman Android\nAndroid studio IDE\nActivities dan intens\nFragments\nAntarmuka (user interface)\nPengolahan data ( data persistence )\nSQlite Database\nData Sharing\nKomunikasi dan jaringan\nSensors dan location service\nMedia dan kamera\nEksternal Database\nService dan threading\nDeployment	\N	\N	\N	\N				\N		\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/9789792960945_Pemrograman-A.jpg	{}	{}	2025-01-17 05:30:17.506	2025-01-17 05:30:21.622
163	61174480	Master the math needed to excel in data science, machine learning, and statistics. In this book author Thomas Nield guides you through areas like calculus, probability, linear algebra, and statistics and how they apply to techniques like linear regression, logistic regression, and neural networks. Along the way you'll also gain practical insights into the state of data science and how to use those insights to maximize your career.\n\nLearn how \n\nUse Python code and libraries like SymPy, NumPy, and scikit-learn to explore essential mathematical concepts like calculus, linear algebra, statistics, and machine learningUnderstand techniques like linear regression, logistic regression, and neural networks in plain English, with minimal mathematical notation and jargonPerform descriptive statistics and hypothesis testing on a dataset to interpret p-values and statistical significanceManipulate vectors and matrices and perform matrix decompositionIntegrate and build upon incremental knowledge of calculus, probability, statistics, and linear algebra, and apply it to regression models including neural networksNavigate practically through a data science career and avoid common pitfalls, assumptions, and biases while tuning your skill set to stand out in the job market	\N	66	8	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1653636488i/61174480.jpg	{}	{}	2025-01-16 17:34:01.586	2025-01-16 17:34:01.586
164	50214042	Build machine and deep learning systems with the newly released TensorFlow 2 and Keras for the lab, production, and mobile devices\n\nKey FeaturesIntroduces and then uses TensorFlow 2 and Keras right from the startTeaches key machine and deep learning techniquesUnderstand the fundamentals of deep learning and machine learning through clear explanations and extensive code samplesBook DescriptionDeep Learning with TensorFlow 2 and Keras, Second Edition teaches neural networks and deep learning techniques alongside TensorFlow (TF) and Keras. You’ll learn how to write deep learning applications in the most powerful, popular, and scalable machine learning stack available.\n\nTensorFlow is the machine learning library of choice for professional applications, while Keras offers a simple and powerful Python API for accessing TensorFlow. TensorFlow 2 provides full Keras integration, making advanced machine learning easier and more convenient than ever before.\n\nThis book also introduces neural networks with TensorFlow, runs through the main applications (regression, ConvNets (CNNs), GANs, RNNs, NLP), covers two working example apps, and then dives into TF in production, TF mobile, and using TensorFlow with AutoML.\n\nWhat you will learnBuild machine learning and deep learning systems with TensorFlow 2 and the Keras APIUse Regression analysis, the most popular approach to machine learningUnderstand ConvNets (convolutional neural networks) and how they are essential for deep learning systems such as image classifiersUse GANs (generative adversarial networks) to create new data that fits with existing patternsDiscover RNNs (recurrent neural networks) that can process sequences of input intelligently, using one part of a sequence to correctly interpret anotherApply deep learning to natural human language and interpret natural language texts to produce an appropriate responseTrain your models on the cloud and put TF to work in real environmentsExplore how Google tools can automate simple ML workflows without the need for complex modelingWho this book is forThis book is for Python developers and data scientists who want to build machine learning and deep learning systems with TensorFlow. This book gives you the theory and practice required to use Keras, TensorFlow 2, and AutoML to build machine learning systems. Some knowledge of machine learning is expected.\n\nTable of ContentsNeural Network Foundations with TensorFlow 2.0TensorFlow 1.x and 2.xRegressionConvolutional Neural NetworksAdvanced Convolutional Neural NetworksGenerative Adversarial NetworksWord EmbeddingsRecurrent Neural NetworksAutoencodersUnsupervised LearningReinforcement LearningTensorFlow and CloudTensorFlow for Mobile and IoT and TensorFlow.jsAn introduction to AutoMLThe Math Behind Deep LearningTensor Processing Unit	\N	15	3	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1577802984i/50214042.jpg	{}	{}	2025-01-17 05:00:48.026	2025-01-17 05:00:52.096
174	42290277	Seperti apakah sifat dasar ruang dan waktu? Bagaimana kita menempatkan diri dalam alam semesta? Bagaimana alam semesta hadir dalam diri kita? Tidak ada yang lebih bisa menjawab pertanyaan ini daripada astrofisikawan terkemuka Neil deGrasse Tyson.\n\nNamun, sedikit dari kita yang punya waktu untuk memikirkan kosmos. Jadi, Tyson membawa alam semesta ke Bumi dengan ringkas dan jelas, dalam bab-bab yang bisa dilahap kapan pun dan di mana pun di sela-sela hari sibuk Anda. Buku ini akan mengungkapkan apa yang Anda perlu ketahui agar siap dan fasih menghadapi berita berikutnya tentang kosmos: dari ledakan besar sampai lubang hitam, dari kuark sampai mekanika kuantum, dan dari pencarian planet sampai pencarian hidup di alam semesta.\n\nNEIL DEGRASSE TYSON adalah astrofisikawan di American Museum of Natural History, direktur Hayden Planetarium yang terkenal, pembawa acara radio dan televisi StarTalk, dan penulis pemenang penghargaan.	\N	192161	16957	2017-05-02	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1539396004i/42290277.jpg	{}	{}	2025-01-16 18:24:48.471	2025-01-16 18:24:48.471
165	\N	Di era big data saat ini, dengan volume data mencapai zettabyte (satu trilyun gigabyte) permasalahan dan data tumbuh secara eksponensial sedangkan jumlah data analyst dan data scientist tumbuh secara linier. Oleh karena itu, diperlukan teknik komputasi handal yang bisa menganalisis data secara cepat dan akurat. Sayangnya sebagian besar desainer dan pengembang sistem berbasis data mining mengalami kesulitan dalam menentukan teknik dan metode yang sesuai untuk masalah yang mereka hadapi.\n\nBuku ini memberikan gambaran secara jelas dan mudah cara memahami masalah dan data secara benar. kedua hal ini sangat penting karena jika gagal melakukannya Anda akan salah dalam memilih teknik dan metode yang sesuai. Pada akhirnya Anda akan mengalami banyak kesulitan pada tahap desain dan implementasi.\n\nBuku ini akan memandu Anda dalam memahami data mining untuk klasifikasi dan klasterisasi data. Penjelasan diberikan secara menyeluruh dari konsep dasar, visualisasi, hingga formulasi matematis.\n\nDalam buku ini Anda akan berlatih memahami masalah, memvisualisasinya, memilih teknik dan metode yang sesuai, mendesain, dan mengimplementasikan model klasifikasi atau model klasterisasi yang tepat untuk masalah tersebut.	\N	\N	\N	2019-02-18	 Informatika	id		\N	Data Mining Untuk Klasifikasi Dan Klasterisasi Data Edisi Revisi	\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/9786026232977_Data-Mining-Untuk-Klasifikai-dan-Klasterisasi-Data-Edisi-Revisi.jpg	{}	{}	2025-01-17 04:50:13.417	2025-01-17 04:50:17.482
166	54025919	Bertrand Arthur William Russell, 3rd Earl Russell, OM FRS (18 May 1872 - 2 February 1970) was a British polymath - a philosopher, logician, mathematician, historian, writer, social critic, political activist, and Nobel laureate.Throughout his life, Russell considered himself a liberal, a socialist and a pacifist, although he also sometimes suggested that his sceptical nature had led him to feel that he had "never been any of these things, in any profound sense." Russell was born in Monmouthshire into one of the most prominent aristocratic families in the United Kingdom.\n\nIn the early 20th century, Russell led the British "revolt against idealism". He is considered one of the founders of analytic philosophy along with his predecessor Gottlob Frege, colleague G. E. Moore and prot�g� Ludwig Wittgenstein. He is widely held to be one of the 20th century's premier logicians.With A. N. Whitehead he wrote Principia Mathematica, an attempt to create a logical basis for mathematics, the quintessential work of classical logic. His philosophical essay "On Denoting" has been considered a "paradigm of philosophy". His work has had a considerable influence on mathematics, logic, set theory, linguistics, artificial intelligence, cognitive science, computer science (see type theory and type system) and philosophy, especially the philosophy of language, epistemology and metaphysics.	\N	746	49	1921-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1677849806i/54025919.jpg	{}	{}	2025-01-16 18:04:09.131	2025-01-16 18:04:09.131
167	8493685	Evolusi adalah salah satu gagasan ilmiah yang paling sering disalahgunakan dan disalahmengerti. Baik profesional maupun awam, sering keliru memahai teori ini kendati sudah silam hampir dua abad. Kesulitan itu dipahami dan ditangkap oleh Ernst Mayr sehingga ia menulis buku ini.\n\nErnst Mayr adalah salah seorang begawan biologi yang ikut mengawinkan teori evolusi Darwin dan genetika Mendel. Ia dianggap sebagai "Charles Darwin" abad ke-21.\n\nDalam buku ini ia memaparkan duduk-perkara teori evolusi bagi orang awam. Ikut dibahas sejarah penemuan, penyalahgunaan teori evolusi, sampai pukulan terhadap argumen-argumen pemeluk kreasionisme.\n\nBuku ini tidak saja membantu orang awam dan profesional paham teori evolusi, namun juga membantu murid, mahasiswa, dan guru-kelas agar bisa memahami teori evolusi dengan tepat dan dengan cara senikmat membaca novel.	\N	3867	103	2001-10-17	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1277247963i/8493685.jpg	{}	{}	2025-01-16 17:55:31.485	2025-01-16 17:55:31.485
168	5551765	Siapa duga kita yang hidup sekarang sudah berusia 3550 tahun?\nSipa duga kita semua sesungguhnya adalah sepupu?\nSiapa duga kita semua adalah bukti bahwa kaidah hidup yang utama adalah kerjasama bahu-membahu, bukan persaingan apalagi gontok-gontokan?\n\nKita, serta serangkaian panjang leluhur kita, mulai dari bakteri hingga Homo sapiens, benar-benar makhluk yang sukses. Di antara tiga milyar spesies yang pernah ada, kita termasuk di antara 1 persen yang bertahan hidup. Selebihnya, 99 persen, gagal dan punah. Sepupu pun bukan hanya satu leluhur, tapi juga tahu hidup saling membantu, bukan saling membunuh.\n\nDalam buku ini, Richard Dawkins, dengan kemahirannya bertutur yang sudah tidak asing lagi, yang tidak jarang memicu senyum geli, menjelaskan semua itu dengan jernih dan indah. Bukan tanpa alasan jika buku ini dapat meneguhkan dan memperdalam iman umat beragama.	\N	8708	433	1995-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1226114183i/5551765.jpg	{}	{}	2025-01-16 17:45:23.661	2025-01-16 17:45:23.661
169	58964807	“Bagi yang panik atau bingung karena pandemi sekarang, buku ini menunjukkan dengan jelas riwayat perkembangan penyakit menular dan cara mengatasinya.” —Kirkus\n\nKini manusia sedunia mesti hidup berdampingan dengan pandemi COVID-19. Namun sebenarnya selama berabad-abad manusia telah menghadapi berbagai penyakit menular yang telah menyebabkan banyak korban jiwa, bahkan memusnahkan sejumlah masyarakat: Cacar, campak, kusta, malaria, polio, HIV, sampai COVID-19. Dengan vaksin, obat, dan berbagai cara lain, kita berusaha mengendalikan dan berharap memberantas penyakit menular.\n\nNamun penyakit menular tidak mudah dihadapi, dan sering terjadi perbedaan pendapat di antara orang awam, di antara pakar, maupun antara orang awam dan pakar. Padahal ketidaktahuan atau bahkan kebebalan dalam menghadapi penyakit menular bisa tak kalah mematikan dengan penyakit itu sendiri.\n\nBuku ini menyajikan tinjauan atas perjuangan manusia melawan penyakit menular hingga saat ini, berikut penjelasan berbagai istilahnya seperti wabah, epidemi, pandemi, isolasi, kekebalan kelompok, dan lain-lain. Ditunjukkan juga bahwa penanganan penyakit menular bukan hanya soal medis, melainkan juga punya aspek sejarah, politik, sosial, dan lain-lain.\n\nDi tengah dunia yang sedang diancam penyakit menular mematikan, buku ini menjadi pegangan jernih yang memberi wawasan dan harapan, membantu kita mengerti apa yang kita hadapi dan bagaimana kita menghadapinya selama ini.	\N	322	48	2020-03-18	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1631289656i/58964807.jpg	{}	{}	2025-01-16 17:35:40.267	2025-01-16 17:35:40.267
170	59779147	Fisika adalah cabang sains yang menjelaskan cara kerja seluruh bagian dunia, dari yang terbesar sampai terkecil, dari awal waktu sampai masa depan yang jauh. \n  Dunia Menurut Fisika\n merupakan pengantar singkat yang menjabarkan fisika klasik dan modern dengan sederhana bagi pembaca awam maupun ahli, mulai dari konsep-konsep dasar seperti skala, ruang, waktu, energi, dan zat, hingga tiga pilar fisika modern: mekanika kuantum, relativitas, dan termodinamika.	\N	2106	230	2020-03-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1639026929i/59779147.jpg	{}	{}	2025-01-16 17:49:23.913	2025-01-16 17:49:23.913
684	\N	Bakugo diculik oleh villain! Akibat serangan kali ini, banyak teman-temanku yang terluka. Bahkan Akademi U.A juga mendapat banyak kecaman dari masyarakat. Padahal baik aku maupun teman-temanku sudah berjuang semampu kami... Apa yang harus kami lakukan setelah ini? "PLUS ULTRA!!"	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1556752794i/45431824.jpg	\N	\N	2026-05-31 16:37:02.077208	2026-05-31 16:37:02.077208
175	\N	Buku ini menyajikan sebuah penjelasan yang hidup dan gamblang mengenai alam fisis yang telah berhasil disingkap oleh ilmuwan-ilmuwan dunia —sepanjang sejarah.\nㅤㅤ \nDengan kecerdasan dan kecemerlangannya, Bertrand Russell menembus kerumitan matematika dan fisika untuk menyajikan teori relativitas dalam bahasa yang jelas dan ringkas yang dapat dengan mudah dipahami oleh pembaca awam.\nDengan menggunakan analogi yang diambil dari pengalaman sehari-hari, dia menjelaskan teori-teori Copernicus, eksperimen-eksperimen Michelson dan Morley terhadap ether, hipotesis kontraksi Fitzgerald sebagaimana dikembangkan oleh Lorentz, teori Maxwell tentang cahaya, teori Gauss pada permukaan dan hukum gravitasi Newton serta menunjukkan bagaimana teori-teori tersebut memberikan landasan bagi teori relativitas Einstein yang revolusioner.\nㅤㅤ \nDi samping menjelaskan makna teori relativitas umum dan relativitas khusus, dia juga mengulas pengaruh jangka panjang teori Einstein terhadap sains dan masa depan dunia modern kita.\nㅤㅤ \nPenulis sains terkemuka, Leonard Engel, menyebut karya Bertrand Russell Teori Relativitas Einstein, "salah satu penjelasan mengenai teori relativitas yang paling gamblang dan paling baik yang pernah ditulis."	\N	\N	\N	\N				\N		\N	https://dfw7ggv03f58r.cloudfront.net/accounts/651fecc487de5df2891d00e7/products/65265c3205f62449b4e4ba94/65265c3205f62449b4e4baa3.jpeg	{}	{}	2025-01-18 19:13:52.712	2025-01-18 19:13:54.075
176	44101657	An accesible version of Einstein's masterpiece of theory, written by the genius himself\n\nAccording to Einstein himself, this book is intended "to give an exact insight into the theory of Relativity to those readers who, from a general scientific and philosophical point of view, are interested in the theory, but who are not conversant with the mathematical apparatus of theoretical physics." When he wrote the book in 1916, Einstein's name was scarcely known outside the physics institutes. Having just completed his masterpiece, The General Theory of Relativity—which provided a brand-new theory of gravity and promised a new perspective on the cosmos as a whole—he set out at once to share his excitement with as wide a public as possible in this popular and accessible book.\n\nHere published for the first time as a Penguin Classic, this edition of Relativity features a new introduction by bestselling science author Nigel Calder.\n\nFor more than seventy years, Penguin has been the leading publisher of classic literature in the English-speaking world. With more than 1,700 titles, Penguin Classics represents a global bookshelf of the best works throughout history and across genres and disciplines. Readers trust the series to provide authoritative texts enhanced by introductions and notes by distinguished scholars and contemporary authors, as well as up-to-date translations by award-winning translators.	\N	22272	974	1916-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1551335037i/44101657.jpg	{}	{}	2025-01-16 17:56:59.817	2025-01-16 17:56:59.817
177	258823	Tired of making web sites that work absolutely perfectly but just don't look nice? If so, then The Principles of Beautiful Web Design is for you. A simple, easy-to-follow guide, illustrated with plenty of full-color examples, this book will lead you through the process of creating great designs from start to finish. Good design principles are not rocket science, and using the information contained in this book will help you create stunning web sites.	\N	1305	87	2007-01-31	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1436377686i/258823.jpg	{}	{}	2025-01-16 18:32:12.368	2025-01-16 18:32:12.368
178	90560	Between 1993 and 2000, a series of groundbreaking experiments revealed dramatic evidence of a web of energy that connects everything in our lives and our world— the Divine Matrix . From the healing of our bodies, to the success of our careers, relationships, and the peace between nations, this new evidence demonstrates that we each hold the power to speak directly to the force that links all of creation. What would it mean to discover that the power to create joy, to heal suffering, and bring peace to nations lives inside of you? How differently would you live if you knew how to use this power each day of your life? Join Gregg Braden on this extraordinary journey bridging science, spirituality and miracles through the language of The Divine Matrix.	\N	6673	298	2006-12-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1328770207i/90560.jpg	{}	{}	2025-01-16 18:00:59.242	2025-01-16 18:00:59.242
179	61535	"The Selfish Gene" caused a wave of excitement among biologists and the general public when it was first published in 1976. Its vivid rendering of a gene's eye view of life, in lucid prose, gathered together the strands of thought about the nature of natural selection into a conceptual framework with far-reaching implications for our understanding of evolution. Time has confirmed its significance. Intellectually rigorous, yet written in non-technical language, "The Selfish Gene" is widely regarded as a masterpiece of science writing, and its insights remain as relevant today as on the day it was published.	\N	184974	5130	1975-12-31	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1366758096i/61535.jpg	{}	{}	2025-01-16 15:57:26.784	2025-01-16 15:57:26.784
180	17349	How can we make intelligent decisions about our increasingly technology-driven lives if we don’t understand the difference between the myths of pseudoscience and the testable hypotheses of science? Pulitzer Prize-winning author and distinguished astronomer Carl Sagan argues that scientific thinking is critical not only to the pursuit of truth but to the very well-being of our democratic institutions.\n\nCasting a wide net through history and culture, Sagan examines and authoritatively debunks such celebrated fallacies of the past as witchcraft, faith healing, demons, and UFOs. And yet, disturbingly, in today's so-called information age, pseudoscience is burgeoning with stories of alien abduction, channeling past lives, and communal hallucinations commanding growing attention and respect. As Sagan demonstrates with lucid eloquence, the siren song of unreason is not just a cultural wrong turn but a dangerous plunge into darkness that threatens our most basic freedoms.	\N	76310	4098	1994-12-31	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1553691804i/17349.jpg	{}	{}	2025-01-16 15:56:48.907	2025-01-16 15:56:48.907
181	32331601	Read anytime, anywhere with the free Kindle smartphone apps\n\nDarwin's theory of evolution is still considered to be the best account ever given pertaining to the living being as an evolved species. Despite several modifications and rebukes, the hold of his book has not diminished. The Origin of Species by Charles Darwin was published by Fingerprint Publishing in 2013. It is available in paperback.Key The Origin of Species includes several examples and accounts that led to this Darwinian school of thought besides the theory itself.	\N	118073	3302	1859-11-23	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1475431066i/32331601.jpg	{}	{}	2025-01-17 05:36:54.416	2025-01-17 05:36:58.738
188	6782803	Buku Kosmos pada dasarnya merupakan buku ilmu pengetahuan, tetapi dengan gaya yang khas, kita dapat melihat bahwa ilmu pengetahuan dapat menjadi santapan masyarakat luas. Buku ini tidak hanya berguna untuk memperluas cakrawala kita, tetapi juga mengajak kita untuk menghayati dan mencintai penemuan ilmiah.	\N	152029	4776	1980-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1251701652i/6782803.jpg	{}	{}	2025-01-16 17:36:06.023	2025-01-16 17:36:06.023
182	59065670	Tahukah Anda, bahwa ada banyak sekali dunia lain di luar sana?\n\nFisika memberikan pemahaman atas dunia. Berbagai temuan dan teori baru terus memperbarui pengetahuan sains dan mengubah gambaran dunia yang disajikan fisika. Fisika kuantum menghadirkan teka-teki di gambaran itu, dengan dualitas zarah-gelombang dan prinsip ketidakpastian—dari dunia klasik yang serba pasti ke dunia kuantum dianggap tanpa kepastian, segala sesuatu hanya diketahui peluangnya.\n\nNamun fisika kuantum belum selesai. Tafsir Kopenhagen yang sekarang berlaku, dengan dualitas dan ketidakpastian, bukan kata pamungkas. Sejumlah ahli fisika lain mengusulkan: Bagaimana jika yang nyata itu bukan hanya satu kemungkinan, melainkan semuanya? Bagaimana jika segala kemungkinan bisa terjadi, di dunia-dunia yang tak terhitung banyaknya, dan terbentuk tiap kali terjadi peristiwa kuantum? Itulah yang dinyatakan Teori Banyak-Dunia, suatu tafsir alternatif yang berupaya mengembalikan kepastian dan kesederhanaan di fisika kuantum.\n\nAhli fisika teori Sean Carroll menjelaskan fisika kuantum tanpa membuatnya misterius dan sulit diterima akal dalam buku ini. Dia juga menunjukkan bagaimana paradigma yang beda dalam fisika kuantum berpengaruh ke cara kita berpikir mengenai alam semesta dan kepastian.	\N	5609	609	2019-09-09	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1632464505i/59065670.jpg	{}	{}	2025-01-16 16:50:23.744	2025-01-16 16:50:23.744
183	\N	Secara garis besar, buku ini bercerita mengenai sosok Wage Rudolf Supratman. Sejak kecil hingga berpulang, dari sekolah hingga menjadi wartawan, penggesek biola dan penulis buku. Ada pula bagian yang menceritakan tentang proses kreatif penulisan beberapa lagu. Saat-saat harus bersembunyi karena menghindari kejaran PID. Termasuk, sebagai bumbu penyedap, kisah cintanya dengan beberapa wanita.\nSINOPSIS\nSetelah kemunculannya membawakan lagu Indonesia Raya yang disebutnya sebagai lagu kebangsaan pada Kongres Pemuda Kedua tahun 1928, hidup Wage Rudolf Supratman berubah. Agen-agen PID (Dinas Intelijen Kepolisian Hindia Belanda) terus mengawasinya. Upaya Supratman menyebarkan lagu itu pun selalu membentur dinding, mulai dari menyebarkan partitur lagu itu lewat surat kabar Sin Po, hingga merekamnya dalam piringan hitam. Surat kabarnya disita dan piringan hitamnya dimusnahkan.\nDi tengah gejolak politik, kisah cinta Supratman dengan Mujenah juga tak mulus. Ia akhirnya menemukan sosok pengganti bernama Salamah. Sayangnya, keluarga Supratman tak merestui. Kisah cinta keduanya begitu menghanyutkan dan mengharu biru di tengah kehidupan mereka yang serba pas-pasan.\nSementara itu, Pemerintah Hindia Belanda tak henti menyebar kabar bohong. Lagu Indonesia Raya disebut sebagai lagu jiplakan. Tak pelak lagi, Supratman diburu. Ia meninggalkan Batavia, tapi agen-agen PID itu selalu mengikuti kemanapun ia bersembunyi!	\N	\N	\N	\N				\N		\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/9789792907612_Matematika-Diskrit-Dan-Aplikasinya-Pada-Ilmu-Komputer-200153.jpg	{}	{}	2025-01-17 05:31:36.409	2025-01-17 05:31:40.694
184	1723657		\N	19	2	2005-12-31	\N	\N	\N	\N	\N	\N	https://dryofg8nmyqjw.cloudfront.net/images/no-cover.png	{}	{}	2025-01-17 05:36:02.462	2025-01-17 05:36:06.764
185	104576094	Why? WAY 3D printingb Everything you imagine becomes a reality bOn February 13, 2013, President Barack Obama, now the former president, "3D printers have the potential to revolutionize the way we produce almost every product," he said as a representative of the manufacturing revolution.3D printing and 3D printing, one of the industries of the 4th industrial revolution, is a technology that extracts objects from 3D printers. If an existing printer is a way to print two-dimensional data on paper through ink, 3D printing is a technique of printing a three-dimensional model through a desired three-dimensional model. 3D printing is a new and surprising technology that is totally different from the way traditional products are made. "This book is about 3D printing, It is a book released at eye level. In this book, 3D printing is introduced to the full extent of the structure and principle of 3D printer, how to use it, how to use it in various fields such as architecture, food, arts, medical, biotechnology, and future development area. This book will serve to open the eyes and ears of our children, who will be the protagonists of the Fourth Industrial Revolution, and help them grow into future children. Through this book, I hope to have more children who are actively challenging to develop their dreams as a field that can continuously develop.	\N	0	0	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1697595355i/104576094.jpg	{}	{}	2025-01-16 17:27:41.999	2025-01-16 17:27:41.999
186	\N	Buku karangan Wono Setya Budhi dan Bana Goerbana Kartasasmita ini bertujuan untuk memperkenalkan konsep baru yang lebih universal untuk mengajarkan matematika kepada siswa di sekolah, mulai dari sekolah dasar hingga sekolah menengah. Sebagai pengganti dari metode memperkenalkan rumus-rumus dan penerapannya kepada siswa, buku Berpikir Matematis ini menawarkan metode yang memperkenalkan teknik-teknik sederhana untuk dapat menyelesaikan soal-soal. Dengan metode ini, diharapkan siswa dapat memahami proses penyelesaian tersebut dan mampu menyelesaikan soal yang diberikan secara mandiri.\n\nSetiap bab dalam buku Berpikir Matematis Matematika untuk Semua ini dilengkapi dengan banyak ilustrasi dan contoh soal beserta penyelesaiannya. Disamping itu pada bab-bab yang dianggap sulit diberikan soal-soal latihan. Kemudian pada bagian akhir buku ini penulis memberikan penuntun jawaban dari soal-soal latihan yang diberikan sehingga para pengajar tidak akan memiliki interpretasi yang berbeda-beda terhadap soal-soal tersebut yang dapat membingungkan para siswa.\n\nBuku Berpikir Matematis Matematika untuk Semua ini diperuntukkan bagi semua orang yang menggunakan matematika, khususnya guru di sekolah dasar, sekolah lanjutan tingkat pertama, atau sekolah lanjutan tingkat atas maupun mahasiswa calon guru. Versi awal dari buku telah dicobakan pada kuliah pascasarjana Pendidikan Matematika dan Pendidikan Ekonomi dari Universitas Pendidikan Indonesia di Bandung. Walaupun kuliah ini dikembangkan untuk mahasiswa pascasarjana, tetapi materi matematikanya berada pada taraf yang dapat diikuti oleh setiap orang yang sudah lulus SMP. Diharapkan, buku ini dapat digunakan para guru untuk mengembangkan kompetensinya dalam pengajaran matematika, karena itu buku ini memberikan pengalaman bermatematika secara utuh.	\N	\N	\N	\N				\N	Berpikir Matematis Matematika untuk Semua	\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/9786022982791_Berpikir-Matematis-Matematika-Untuk-Semua.jpg	{}	{}	2025-01-17 05:46:16.279	2025-01-17 05:46:20.263
187	\N	“Metode Penelitian Terpadu Sistem Informasi” merupakan salah satu buku yang cocok digunakan sebagai alat penunjang belajar untuk para akademisi yang sedang mengenyam pendidikan di bidang komputer maupun teknologi. Buku ini ditulis oleh Dr. Willy Abdillah, M.Sc. Pemodelan sistem informasi atau pendokumentasian sistem informasi sudah mulai dilakukan oleh banyak perusahaan atau organisasi. Pemodelan sistem informasi memiliki pengertian dimana suatu sistem informasi perusahaan yang berbentuk software diubah menjadi dokumentasi yang dilakukan oleh seorang sistem analisis.\n\nSoftware yang biasa alur prosesnya melalui komputer, dapat dilihat dan dipahami melalui pemodelan sistem informasi karena sudah dilakukan pendokumentasian. Tujuan dari pemodelan sistem informasi ini adalah untuk mengetahui alur proses bisnis sistem informasi yang ada dan mengetahui tujuan terakhir dari sistem informasi tersebut. Dengan adanya pemodelan atau pendokumentasian sistem informasi pada perusahaan, maka segala macam proses bisnis yang ada dalam perusahaan dapat mengalami perbaikan yang lebih baik untuk mencapai tujuan perusahaan dan memberikan layanan yang terbaik kepada konsumen.\n\nAgar pembaca lebih memahami teori, isu, metode, dan teknik dalam Sistem Informasi (SI), buku ini dibagi ke dalam tiga level bahasan. Level I membahas Konsep Dasar Penelitian dan Spesifikasi Model Penelitian terdiri atas lima bab yang menjelaskan paradigma penelitian, masalah penelitian, konsep teori, dan teori-teori dalam riset keperilakuan SI. Level II membahas Pengukuran terdiri dari empat bab yang menjelaskan desain penelitian, data, populasi dan pengambilan sampel, serta isu-isu pengukuran dalam penelitian SI. Terakhir, Level III membahas Teknis Pengujian terdiri atas dua belas bab yang secara detail akan menjelaskan teknik analisis beserta ragam alat dan metode pengujian statistika (teknik dependensi dan interdependensi) yang dilengkapi dengan contoh kasus dan cara interpretasi hasil analisis statistika multivariate.	\N	\N	\N	\N				\N		\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/9789792961133_METODE_PENELITIAN_TERPADU_SISTEM_INFORMASI_PEMODELAN_TEORET.jpg	{}	{}	2025-01-17 05:38:56.355	2025-01-17 05:39:00.671
189	23692271	From a renowned historian comes a groundbreaking narrative of humanity’s creation and evolution—a #1 international bestseller—that explores the ways in which biology and history have defined us and enhanced our understanding of what it means to be “human.” One hundred thousand years ago, at least six different species of humans inhabited Earth. Yet today there is only one—homo sapiens. What happened to the others? And what may happen to us? Most books about the history of humanity pursue either a historical or a biological approach, but Dr. Yuval Noah Harari breaks the mold with this highly original book that begins about 70,000 years ago with the appearance of modern cognition. From examining the role evolving humans have played in the global ecosystem to charting the rise of empires, Sapiens integrates history and science to reconsider accepted narratives, connect past developments with contemporary concerns, and examine specific events within the context of larger ideas. Dr. Harari also compels us to look ahead, because over the last few decades humans have begun to bend laws of natural selection that have governed life for the past four billion years. We are acquiring the ability to design not only the world around us, but also ourselves. Where is this leading us, and what do we want to become? Featuring 27 photographs, 6 maps, and 25 illustrations/diagrams, this provocative and insightful work is sure to spark debate and is essential reading for aficionados of Jared Diamond, James Gleick, Matt Ridley, Robert Wright, and Sharon Moalem.	\N	1135488	57267	2010-12-31	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1703329310i/23692271.jpg	{}	{}	2025-01-17 05:32:53.794	2025-01-17 05:32:57.715
190	61662	NATIONAL BESTSELLER • “Exciting and provocative . . . A tour de force of a book that begs to be seen as well as to be read.”— The Washington Post Book World\n\nWorld renowned scientist Carl Sagan and acclaimed author Ann Druyan have written a Roots  for the human species, a lucid and riveting account of how humans got to be the way we are. Shadows of Forgotten Ancestors is a thrilling saga that starts with the origin of the Earth. It shows with humor and drama that many of our key traits—self-awareness, technology, family ties, submission to authority, hatred for those a little different from ourselves, reason, and ethics—are rooted in the deep past, and illuminated by our kinship with other animals.\n\nSagan and Druyan conduct a breathtaking journey through space and time, zeroing in on critical turning points in evolutionary history, and tracing the origins of sex, altruism, violence, rape, and dominance. Their book culminates in a stunningly original examination of the connection between primate and human traits. Astonishing in its scope, brilliant in its insights, and an absolutely compelling read, Shadows of Forgotten Ancestors is a triumph of popular science.	\N	6113	275	1992-09-14	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1436206919i/61662.jpg	{}	{}	2025-01-16 15:56:12.749	2025-01-16 15:56:12.749
191	53096829	Transformasi digital seperti tecermin dalam derasnya penetrasi layanan media sosial, mesin pencari, dan situs e-commerce, pada gilirannya telah menampakkan diri sebagai sebentuk aporia. Ia menawarkan pembebasan, sekaligus memendam intensi penguasaan. Ia menyajikan kemungkinan deliberasi, sekaligus memperlihatkan tendensi instrumentalisasi. Ia melahirkan peluang-peluang menjanjikan pada aras ekonomi kreatif, sekaligus menciptakan struktur kapitalisme baru yang memusatkan surplus ekonomi digital global hanya pada sedikit perusahaan di satu-dua negara saja. Buku ini menawarkan perspektif kritis tentang fenomena digitalisasi ketika pada umumnya publik bersikap positivistik dalam memandang fenomena tersebut. Penulis mencoba meneropong dimensi-dimensi “antidemokrasi” fenomena digitalisasi yang telanjur lekat dengan term demokratisasi. Buku ini juga menekankan perlunya keseimbangan perspektif dalam menelaah revolusi digital, positivistik, maupun kritis. Dalam konteks ini, integrasi suatu negara ke dalam lanskap informasi global membawa pengaruh positif sekaligus dampak destruktif.\n\nSetelah memetakan masalah-masalah yang muncul bersamaan dengan transformasi digital, penulis mengusulkan langkah-langkah yang perlu diambil pemerintah, DPR, komunitas media, maupun kalangan masyarakat dalam mengantisipasi integrasi Indonesia ke dalam ekosistem informasi global.\n\nHal-hal ini perlu dilakukan agar Indonesia mampu mengambil manfaat sebanyak-banyaknya dan mampu mengantisipasi dampak atau residu yang muncul secara memadai.	\N	14	5	2019-09-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1637381745i/53096829.jpg	{}	{}	2025-01-16 17:30:36.901	2025-01-16 17:30:36.901
192	\N	Ketika Nietzsche berbicara mengenai dunia sebagai fenomena estetika, dia tidak sedang berbicara tentang dunia yang ada untuk dipersepsi manusia. Sebaliknya, dunia adalah estetika dalam perkembangannya, dengan cara yang tidak dapat dibatasi atau sepenuhnya terkandung oleh pengalaman manusia. Keberlebihan estetika inilah yang dipahami oleh visi Dionysian atas dunia.\n\nPembahasan pandangan dunia Apollonian dan Dionysian menunjukkan cara Nietzsche memahami dunia, sifat manusia, moralitas, dan agama. Setelah itu, kita akan menyadari bahwa ungkapan Nietzsche yang paling populer, "Tuhan sudah mati", tidak muncul begitu saja di kemudian hari. Ide anti-agama ini selalu berkembang dan tumbuh di benak Nietzsche ... sejak ia menulis esai ini, atau bahkan jauh lebih awal.\n\nTahun Terbit : Cetakan Pertama, Agustus 2024\n\nPernahkah Anda terpikir betapa menariknya dunia yang terbuka lebar lewat lembaran buku? Membaca bukan hanya kegiatan rutin, tetapi juga petualangan tak terbatas ke dalam imajinasi dan pengetahuan.\n\nMembaca mengasah pikiran, membuka wawasan, dan memperkaya kosakata. Ini adalah pintu menuju dunia di luar kita yang tak terbatas.\n\nTetapkan waktu khusus untuk membaca setiap hari. Dari membaca sebelum tidur hingga menyempatkan waktu di pagi hari, kebiasaan membaca dapat dibentuk dengan konsistensi.\n\nPilih buku sesuai minat dan level literasi. Mulailah dengan buku yang sesuai dengan keinginan dan kemampuan membaca.\n\nTemukan tempat yang tenang dan nyaman untuk membaca. Lampu yang cukup, kursi yang nyaman, dan sedikit musik pelataran bisa menciptakan pengalaman membaca yang lebih baik.\n\nBuat catatan atau jurnal tentang buku yang telah Anda baca. Tuliskan pemikiran, kesan, dan pelajaran yang Anda dapatkan.	\N	\N	\N	2024-08-21	Diva Press			\N		\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/products/-gdux9c9s8.jpg	{}	{}	2025-01-17 05:11:32.983	2025-01-17 05:11:36.802
222	208964223	Dalam buku ini, Al-Ghazali membuat banyak pengamatan menarik tentang hakikat kebahagiaan. Dia menguraikan bahwa terdapat berbagai kemampuan yang berbeda di dalam jiwa, dan bahwa kebahagiaan mereka terhubung dengan masing-masing kemampuan. Setiap bagian jiwa bergembira atas apa yang telah diciptakannya. Namun fungsi tertinggi jiwa adalah persepsi akan kebenaran; oleh karena itu, inilah kebahagiaan terbesar yang dapat diperoleh seseorang.	\N	2733	419	1105-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1708546205i/208964223.jpg	{}	{}	2025-01-16 18:28:15.226	2025-01-16 18:28:15.226
295	63294555	×一味の急襲で、大混乱のJCC!!　生徒を守るため、京の前には佐藤田先生が立ちはだかる!!　一方、データバンクである周の祖父の確保を急ぐ坂本やシン。だがクラブ・ジャムの催眠術で事態はさらなる混沌へ…!!	\N	1044	73	2023-04-04	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1680406017i/63294555.jpg	{}	{}	2025-03-12 15:10:45.673	2025-03-12 15:10:45.021
193	\N	Memahami anatomi dan fisiologi manusia adalah kunci untuk mengenali dan menghargai kompleksitas tubuh kita. Anatomi memberikan gambaran tentang struktur fisik tubuh, sedangkan fisiologi menjelaskan bagaimana organ dan sistem berfungsi secara harmonis untuk menjaga keseimbangan dan kehidupan. Pengetahuan ini esensial dalam pencegahan penyakit, deteksi dini gejala tidak normal, dan diagnosis tepat oleh profesional medis.\n\nSelain itu, memahami prinsip dasar anatomi dan fisiologi juga memainkan peran penting dalam pendidikan kesehatan masyarakat, penelitian medis, pengembangan teknologi medis, dan keamanan pasien.\n• Pengenalan Anatomi dan Fisiologi Manusia\n• Sel dan Jaringan\n• Sistem Rangka\n• Sistem Saraf\n• Sistem Peredaran Darah\n• Sistem Otot\n• Sistem Pernapasan\n• Sistem Pencernaan\n• Sistem Indra\n• Sistem Kekebalan Tubuh\n• Sistem Reproduksi\n• Sistem Ekskresi\n• Sistem Sirkulasi\n• Urinaria\n• Sistem Kardiovaskular\n• Sistem Limfatik\n• Sistem Endokrin\n\nTahun Terbit : Cetakan Pertama, Juni 2024\n\nPernahkah Anda terpikir betapa menariknya dunia yang terbuka lebar lewat lembaran buku? Membaca bukan hanya kegiatan rutin, tetapi juga petualangan tak terbatas ke dalam imajinasi dan pengetahuan.\n\nMembaca mengasah pikiran, membuka wawasan, dan memperkaya kosakata. Ini adalah pintu menuju dunia di luar kita yang tak terbatas.\n\nTetapkan waktu khusus untuk membaca setiap hari. Dari membaca sebelum tidur hingga menyempatkan waktu di pagi hari, kebiasaan membaca dapat dibentuk dengan konsistensi.\n\nPilih buku sesuai minat dan level literasi. Mulailah dengan buku yang sesuai dengan keinginan dan kemampuan membaca.\n\nTemukan tempat yang tenang dan nyaman untuk membaca. Lampu yang cukup, kursi yang nyaman, dan sedikit musik pelataran bisa menciptakan pengalaman membaca yang lebih baik.\n	\N	\N	\N	\N				\N		\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/products/sagx7i-59m.jpg	{}	{}	2025-01-18 19:11:46.267	2025-01-18 19:11:47.96
194	75464640	Tokyo, tahun 16 Meiji. Kenshin Himura, Sang Jago Pedang, telah menggantungkan pedangnya dan hidup damai bersama istrinya, Kaoru, dan putranya, Kenji. Tapi suatu ketika, mereka menemukan selembar foto ayah Kaoru yang seharusnya sudah tewas. Foto itu pun menuntun mereka untuk berangkat ke Hokkaido. Apa yang akan menanti mereka di sana!?\nKisah sang jago pedang bersama Sakabato, pedang yang tak bisa membunuh itu pun memasuki awal baru!	\N	16	3	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1672567849i/75464640.jpg	{}	{}	2025-01-16 17:23:54.924	2025-01-16 17:23:54.924
195	58290173	Mahadata (Big Data) sering disebut-sebut orang akhir-akhir ini. Mahadata dianggap sesuatu yang akan—atau sudah—berpengaruh besar dalam zaman informasi. Namun apa sebenarnya mahadata? Bagaimana mahadata bekerja, apa saja manfaatnya, dan adakah dampak buruk mahadata? Buku ini menjadi pengantar untuk mengenal mahadata, berikut berbagai contoh penerapannya, di antaranya oleh Netflix, CERN, dan Amazon.	\N	387	61	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1623100865i/58290173.jpg	{}	{}	2025-01-16 17:55:20.979	2025-01-16 17:55:20.979
196	1725177	Pelajaran kimia tidak lagi menjadi momok setelah kamu membaca buku ini. Bersama kimiawan Craig Criddle, Gonnick mengajak kamu memahami topik-topik pelajaran kimia di sekolah lewat canda dan tawa. Kamu diajak mempelajari sifat-sifat zat serta berbagai perubahan yang dialaminya. Kartun Kimia menerangkan dasar-dasar kimia antara lain sejarah ilmu kimia, sifat-sifat unsur, ikatan kimia, reaksi, wujud zat, larutan, asam-basa, elektrokimia, stoikiometri, dan kimia organik. Tentu saja, semuanya disampaikan melalui ilustrasi yang sederhana, jernih, dan kocak abis.\n\n"Buku ini memberi ilustrasi dasar-dasar kimia dengan amat baik. Pas bagi para siswa yang mencari cara alternatif untuk memahami konsep-konsep dasar ilmu kimia." -- sciencedaily.com\n\n"Topik-topiknya disajikan dengan humor, kandungan sainsnya bermutu dan dibawakan dengan ringan." --resensi Journal of Chemistry Education	\N	846	57	2005-04-30	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1218170363i/1725177.jpg	{}	{}	2025-01-16 17:16:01.734	2025-01-16 17:16:01.734
197	195879153	Buku kumpulan esai terbaik Orwell ini memuat:\nWhy I Write, Books v. Cigarettes, Good Bad Books, Confessions of a Book Reviewer, Bookshop Memories, Literature and Totalitarianism, Politics and the English Language, Notes on Nationalism, My Country Right or Left, Shooting an Elephant, How the Poor Die, A Hanging, A Nice Cup of Tea.	\N	13462	1386	1945-12-31	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1691440966i/195879153.jpg	{}	{}	2025-01-16 17:14:18.8	2025-01-16 17:14:18.8
198	221829100	Konspirasi adalah esai terpenting dalam Discourses on Livy karya Machiavelli. Esai ini membahas segala hal mengenai konspirasi terhadap penguasa, penyebabnya, metodenya, bahayanya, sampai cara menumpasnya.	\N	219	20	1513-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1732295737i/221829100.jpg	{}	{}	2025-01-16 18:29:28.398	2025-01-16 18:29:28.398
199	52586270	Cerita berawal dari depresi yang dialamP Romeo, karena cinta Romeo pada salah satu keponakan Capulet, Rosaline, tak berbalas. Atas bujukan fc Henvolio dan Mercutio, Romeo akhirnya bersedia menghadiri pesta dansa keluarga Capulet demi bisa bertemu dengan Rosaline. Namun di pesta itu Romeo melihat Juliet untuk pertama kalinya, dan jatuh cinta pada pandangan pertama.\n\nCinta Romeo pada Juliet ternyata tak bertepuk sebelah tangan. Romeo me-nvelinap ke taman keluarga Capulet dan mendengar Juliet yang mengumandangkan cintanya pada Romeo dari balkon kamarnya, tanpa memedulikan permusuhan ke-luarga mereka. Dengan bantuan Pendeta Lauurence, Romeo dan Juliet menikah secara diam-diam keesokan harinya. Pendeta Laurence berharap dapat meng-hentikan permusuhan keluarga Montague dan Capulet dengan menikahkan Romeo dan Juliet.\n\nTvbalt, sepupu Juliet, menantang Romeo berduel, dan berakhir dengan kematian Tybalt. Pangeran Verona yang mengetahui peristiwa ini segera menghukum Romeo dengan mengusirnya dari Verona. Di saat bersamaan, kedu& orang tua Juliet malah menerima pinangan Count Paris untuk Juliet.\n\nJuliet yang putus asa menenggak ramuan yang membuatnya seolah-olah tewas selama dua hari. Namun sang utusan yang seharusnya menyampaikan pesan itu pada Romeo tak kunjung datang hingga Romeo beranggapan bahwa Juliet telah benar-benar tewas. Ia yang tak bisa hidup tanpa Juliet menenggak racun dan tewas. Tak lama kemudian Juliet terbangun, dan ketika melihat belahan jiwanya telah tergeletak tak berdaya, ia mengambil pisau dan menghujamkannya ke tubuhnya.	\N	2704423	34575	1597-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1584856626i/52586270.jpg	{}	{}	2025-01-16 18:13:48.64	2025-01-16 18:13:48.64
200	35335209	Shigeo Kageyama – genannt Mob – ist ein ziemlich seltsamer und schüchterner Teenager, der noch dazu übersinnliche Fähigkeiten besitzt.\n\nAls Praktikant eines stadtbekannten Exorzisten darf er seinem Chef regelmäßig aus der Patsche helfen und trifft so auf die seltsamsten Geister, die den Menschen das Leben zur Hölle machen. Er würde gerne ein normales Leben führen – doch Hausarrest, Taschengeldabzug für Uri-Geller-Löffel-Verbiegen™ und allein der Anblick seines Schwarms bringen seine Emotionen zum Brodeln. Und wenn sein inneres Emo-Meter überkocht und die "100" übersteigt, geschieht Schreckliches...	\N	4785	451	2012-11-16	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1496677252i/35335209.jpg	{}	{}	2025-01-16 18:14:49.898	2025-01-16 18:14:49.898
201	\N	Pernahkah Anda menonton film Musashi besutan sutradara Yasuo Mikami yang rilis tahun 2019? Atau, membaca novel tebal berjudul Musashi karya Eiji Yoshikawa? Keduanya menceritakan kisah hidup Miyamoto Musashi, penulis buku Kitab Lima Unsur ini.\n\nKitab Lima Unsur adalah mahakarya paling mencerahkan tentang seni bela diri pedang dalam sejarah Jepang, bahkan dalam sejarah dunia. Buku ini ditulis bukan hanya untuk para ahli ilmu pedang, tetapi juga buat siapa saja yang ingin mengaplikasikan prinsip-prinsip abadi lima unsur ke dalam kehidupan mereka. Cara penulisannya sangat sederhana, mudah dicerna, dan detail.\n\nDengan membaca dan memahami betul-betul isi buku ini, serta berlatih sesuai dengan petunjuk mengenai prinsip-prinsip yang diciptakan Musashi—yang ia namai “Jalan Strategi”—kita akan menjelma sebagai ahli ilmu pedang yang pilih tanding. Lebih dari itu, kita juga akan menjalani hidup sebagaimana pendekar pedang menjalani hidupnya yang bersahaja, bertumpu pada spiritualitas, dan memperlakukan orang lain secara adil, benar, dan tepat.\n\nTahun Terbit : Cetakan Pertama, Juli 2024\n\nPernahkah Anda terpikir betapa menariknya dunia yang terbuka lebar lewat lembaran buku? Membaca bukan hanya kegiatan rutin, tetapi juga petualangan tak terbatas ke dalam imajinasi dan pengetahuan. Membaca mengasah pikiran, membuka wawasan, dan memperkaya kosakata. Ini adalah pintu menuju dunia di luar kita yang tak terbatas. Tetapkan waktu khusus untuk membaca setiap hari.\n\nDari membaca sebelum tidur hingga menyempatkan waktu di pagi hari, kebiasaan membaca dapat dibentuk dengan konsistensi. Pilih buku sesuai minat dan level literasi. Mulailah dengan buku yang sesuai dengan keinginan dan kemampuan membaca. Temukan tempat yang tenang dan nyaman untuk membaca. Lampu yang cukup, kursi yang nyaman, dan sedikit musik pelataran bisa menciptakan pengalaman membaca yang lebih baik. Bergabunglah dalam kelompok membaca atau forum literasi. Diskusikan buku yang Anda baca dan dapatkan rekomendasi dari sesama pembaca. Buat catatan atau jurnal tentang buku yang telah Anda baca.\n\nTuliskan pemikiran, kesan, dan pelajaran yang Anda dapatkan. Libatkan keluarga dalam kegiatan membaca. Bacakan cerita untuk anak-anak atau ajak mereka membaca bersama. Ini menciptakan ikatan keluarga yang erat melalui kegiatan positif. Jangan ragu untuk menjelajahi genre baru. Terkadang, kejutan terbaik datang dari buku yang tidak pernah Anda bayangkan akan Anda nikmati. Manfaatkan teknologi dengan membaca buku digital atau bergabung dalam komunitas literasi online. Ini membuka peluang untuk terhubung dengan pembaca dari seluruh dunia.	\N	\N	\N	2024-07-23	Ircisod			\N		\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/products/xtmb85unb-.jpeg	{}	{}	2025-01-17 05:15:48.819	2025-01-17 05:15:52.85
202	10241625	"Tuhan tidak menciptakan alam semesta."\n\nItulah teori yang dikemukakan oleh Stephen Hawking dalam buku ini. Bahwa alam semesta terancang dengan begitu agungnya dan amat sangat teratur samasekali bukan karena campur tangan Tuhan, namun berkat hukum-hukum fisika yang sempurna.\n\nBuku ini juga akan menjawab keingintahuan kita tentang hal-hal sebagai berikut:\n* Kapan dan bagaimana alam semesta bermula?\n* Mengapa kita ada di dunia?\n* Apa hakikat realitas?\n\nDalam buku ini, Stephen Hawking dan Leonard Mlodinow menyajikan pemikiran sains terkini mengenai misteri alam semesta, dalam bahasa nonteknis yang cemerlang sekaligus sederhana. Buku ini merupakan buku pedoman singkat, jelas, dan menyentak, yang menyajikan penemuan-penemuan yang akan mengubah pemahaman sekaligus mengusik iman; buku ini akan mencerahkan dan menohok. Buku yang tiada duanya.	\N	75422	3105	2010-09-07	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1295234265i/10241625.jpg	{}	{}	2025-01-16 17:44:49.795	2025-01-16 17:44:49.795
203	\N	Buku Sejarah Nusantara (The Malay Archipelago) adalah sebuah karya penjelajah dan ilmuwan terkenal, Alfred Russel Wallace, yang diterbitkan pada tahun 1869. Buku ini adalah hasil dari pengamatan dan penelitian Wallace selama delapan tahun menjelajahi Kepulauan Melayu, yang meliputi sebagian besar wilayah Indonesia, Malaysia, dan Filipina.\n\nDalam buku ini, Wallace menggambarkan keindahan alam, flora, fauna, dan budaya di wilayah tersebut. Ia juga memaparkan teori tentang distribusi geografis spesies-spesies hewan dan tumbuhan, yang kemudian dikenal sebagai ”Line Wallace” atau ”Wallace Line”. Teori ini mengidentifikasi perbatasan biogeografis antara Asia dan Australia, dan memainkan peran penting dalam pemahaman ilmiah mengenai evolusi dan distribusi spesies di kepulauan tersebut.\n\nSelain itu, buku ini juga mencakup pengalaman Wallace dalam berinteraksi dengan berbagai suku bangsa dan budaya di wilayah tersebut, memberikan gambaran yang mendalam tentang kehidupan sosial dan keberagaman manusia di Kepulauan Melayu.\n\nSejarah Nusantara (The Malay Archipelago) tidak hanya merupakan sumber informasi ilmiah yang berharga, tetapi juga dianggap sebagai salah satu karya sastra penjelajahan yang paling penting dalam sejarah, dengan gaya penulisan yang memikat dan deskripsi alam yang indah.\n\n\n\nPernahkah Anda terpikir betapa menariknya dunia yang terbuka lebar lewat lembaran buku? Membaca bukan hanya kegiatan rutin, tetapi juga petualangan tak terbatas ke dalam imajinasi dan pengetahuan.\n\nMembaca mengasah pikiran, membuka wawasan, dan memperkaya kosakata. Ini adalah pintu menuju dunia di luar kita yang tak terbatas.\n\nTetapkan waktu khusus untuk membaca setiap hari. Dari membaca sebelum tidur hingga menyempatkan waktu di pagi hari, kebiasaan membaca dapat dibentuk dengan konsistensi.\nPilih buku sesuai minat dan level literasi. Mulailah dengan buku yang sesuai dengan keinginan dan kemampuan membaca.\n\nTemukan tempat yang tenang dan nyaman untuk membaca. Lampu yang cukup, kursi yang nyaman, dan sedikit musik pelataran bisa menciptakan pengalaman membaca yang lebih baik.\n\nBergabunglah dalam kelompok membaca atau forum literasi. Diskusikan buku yang Anda baca dan dapatkan rekomendasi dari sesama pembaca.\n\nBuat catatan atau jurnal tentang buku yang telah Anda baca. Tuliskan pemikiran, kesan, dan pelajaran yang Anda dapatkan.\n\nLibatkan keluarga dalam kegiatan membaca. Bacakan cerita untuk anak-anak atau ajak mereka membaca bersama. Ini menciptakan ikatan keluarga yang erat melalui kegiatan positif.\n\nJangan ragu untuk menjelajahi genre baru. Terkadang, kejutan terbaik datang dari buku yang tidak pernah Anda bayangkan akan Anda nikmati.\n\nManfaatkan teknologi dengan membaca buku digital atau bergabung dalam komunitas literasi online. Ini membuka peluang untuk terhubung dengan pembaca dari seluruh dunia.	\N	\N	\N	\N	Anak Hebat Indonesia			\N	Sejarah Nusantara (The Malay Archipelago)	\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/picture_meta/2024/2/12/fkdsbbwr3ra757k9xlff4b.jpg	{}	{}	2025-01-17 05:09:28.612	2025-01-17 05:09:32.785
204	4347293	Three men descend three thousand miles into the earth to enter strange and frightening worlds	\N	211467	9358	1864-11-25	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1413659790i/4347293.jpg	{}	{}	2025-01-16 18:13:39.391	2025-01-16 18:13:39.391
205	1607269	Ditulis di Rajawati dekat pabrik sepatu Kalibata, Cililitan, Jakarta. Di sini saya berdiam dari 15 Juli 1942 sampai pertengahan tahun 1943. Mempelajari keadaan kota dan kampung Indonesia yang lebih dari 20 tahun ditinggalkan.\n\nPengantar Penulis pada halaman awal Madilog.	\N	2566	206	1946-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1417412608i/1607269.jpg	{}	{}	2025-01-16 17:52:26.918	2025-01-16 17:52:26.918
206	74176	The Protestant ethic — a moral code stressing hard work, rigorous self-discipline, and the organization of one's life in the service of God — was made famous by sociologist and political economist Max Weber. In this brilliant study (his best-known and most controversial), he opposes the Marxist concept of dialectical materialism and its view that change takes place through "the struggle of opposites." Instead, he relates the rise of a capitalist economy to the Puritan determination to work out anxiety over salvation or damnation by performing good deeds — an effort that ultimately discouraged belief in predestination and encouraged capitalism. Weber's classic study has long been required reading in college and advanced high school social studies classrooms.	\N	14286	772	1904-11-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1386921121i/74176.jpg	{}	{}	2025-01-16 17:29:03.346	2025-01-16 17:29:03.346
207	51893827	Mahabharata, epos terbesar sepanjang masa, sering kali dipahami sebagai cerita tentang kebaikan (Pandawa) melawan kejahatan (Kurawa). Tetapi sejarah ditulis oleh pemenang. Bagaimana jika Kurawa menyimpan kisah yang luput dari kita? Di India, terdapat 1.260 versi Mahabharata. Di jagat pewayangan, ceritanya pun sangat beragam. Ada bagian Mahabharata karya Abiyasa yang lama hilang, yang ditulis dari sudut pandang Kurawa. Jaimini, murid Abiyasa, menulis kepahlawanan Duryudana. Hanya satu bagian dari versi tersebut, Aswatama Parwa, yang tersisa. Pada abad 2, pujangga Bhasa menulis Urubangga, yang memuja Duryudana. Pun ada beberapa cerita rakyat di India selatan yang menempatkan Duryudana sebagai pemimpin mulia, yang berani melawan tatanan kasta yang semena-mena.\n\nInilah Mahakurawa, kisah Mahabharata dari sudut pandang tokoh-tokoh yang dianggap jahat seperti Duryudana, Aswatama, dan Sengkuni, pun yang tertindas dan terlunta seperti Ekalaya, Karna, dan Jara. Mahakurawa mempertanyakan apa yang baik dan apa yang jahat dan siapa sejatinya pemenang Bharatayuda. Mahakurawa adalah kisah dari sisi lain: yang kalah, yang terhina, yang terinjak-injak, yang bertempur tanpa berharap campur tangan dewata, yang meyakini bahwa tindakan mereka sesuai dharma! Dan jika Mahabharata pada akhirnya adalah kisah tentang kemenangan dharma atas adharma, kenapa dunia justru memasuki Kaliyuga?	\N	3174	275	2015-06-21	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1565843599l/51893827.jpg	{}	{}	2025-01-16 17:54:58.109	2025-01-16 17:54:58.109
208	58284876		\N	4	1	2016-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1623074159i/58284876.jpg	{}	{}	2025-01-16 18:03:43.767	2025-01-16 18:03:43.767
231	25835224	Banyak sekali ulama yang telah menulis kitab tasawuf, namun tak banyak yang mempu menjelaskan sedalam dan segamblang Syekh Abdul Qadir al-Jailani (1078-1166). Buku berjudul asli Sirrul Asrar ini merupakan salah satu karya yang paling berhasil menjelaskan secara detail pengalaman dan tahapan-tahapan spritiual seseorang untuk mencapai Tarekat dan Makrifat hingga mencapai Hakikat Allah. Sebuah rujukan utama ilmu tasawuf yang ditulis sejak 1000 tahun lalu, sebagai bekal untuk menjadi kekasih Allah.	\N	51	4	2015-07-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1435811984i/25835224.jpg	{}	{}	2025-01-16 17:26:48.884	2025-01-16 17:26:48.884
685	\N	Muncul PRIA BERTOPENG misterius yang mampu mengalahkan para hero hanya dalam sekejap mata. sanggupkah all might mengalahkan pria yang memiliki berbagai macam quirk itu?! ini bukan saatnya merasa takut! karena ada seorang TEMAN yang harus kuselamatkan! “PLUS ULTRA”!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1561451327l/49576171.jpg	\N	\N	2026-05-31 16:37:16.106281	2026-05-31 16:37:16.106281
209	31138556	Yuval Noah Harari, author of the critically-acclaimed New York Times bestseller and international phenomenon Sapiens, returns with an equally original, compelling, and provocative book, turning his focus toward humanity’s future, and our quest to upgrade humans into gods.Over the past century humankind has managed to do the impossible and rein in famine, plague, and war. This may seem hard to accept, but, as Harari explains in his trademark style—thorough, yet riveting—famine, plague and war have been transformed from incomprehensible and uncontrollable forces of nature into manageable challenges. For the first time ever, more people die from eating too much than from eating too little; more people die from old age than from infectious diseases; and more people commit suicide than are killed by soldiers, terrorists and criminals put together. The average American is a thousand times more likely to die from binging at McDonalds than from being blown up by Al Qaeda.What then will replace famine, plague, and war at the top of the human agenda? As the self-made gods of planet earth, what destinies will we set ourselves, and which quests will we undertake? Homo Deus explores the projects, dreams and nightmares that will shape the twenty-first century—from overcoming death to creating artificial life. It asks the fundamental questions: Where do we go from here? And how will we protect this fragile world from our own destructive powers? This is the next stage of evolution. This is Homo Deus.With the same insight and clarity that made Sapiens an international hit and a New York Times bestseller, Harari maps out our future.	\N	268261	16918	2015-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1468760805i/31138556.jpg	{}	{}	2025-01-16 18:22:19.536	2025-01-16 18:22:19.536
210	36110733	Suatu malam pada sebuath pertemuan yang dihadiri Bung Karno, Bung Hatta, Bung Sjahrir, dan K.H. Agus Salim - Tan Malaka yang datang tanpa diundang tiba-tiba berkata lantang:\n"Kepada kalian para sahabat, tahukah kalian kenapa aku tidak tertarik pada kemerdekaan yang kalian ciptakan? Aku merasa bahwa kemerdekaan itu tidak kalian rancang untuk kemaslahatan bersama. Kemerdekaan kalian diatur oleh segelintir manusia, tidak menciptakan revolusi besar. Hari ini aku datang kepadamu, wahai Soekarno sahabatku... Harus aku katakan bahwa kita belum merdeka, karena merdeka haruslah 100 persen...!"\n\n\t\t\t\t\t***\t\t\t\t\t\t\n\nNama Tan Malaka seolah terlupakan dari sejarah perjuangan Indonesia. Padahal, Prof. Muhammad Yamin menyebutnya sebagai " Bapak Republik Indonesia". Sedang Jenderal A.H. Nasution mengatakan "... nama Tan Malaka juga harus tercatat sebagai tokoh militer Indonesia untuk selama-lamanya." Tan Malaka memang merupakan salah seorang pemikir brilian yang bercita-cita mewujudkan kemerdekaan Indonesia.\n\nBuku ini merupakan kumpulan karya penting Tan Malaka sekaligus menjadi pernyataan sikapnya tentang politik dan ekonomi yang bebas dan merdeka - sekaligus dapat menggugah kesadaran kita akan arti dari kemerdekaan yang sesungguhnya, yaitu Merdeka 100%!	\N	205	12	1945-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1503501508i/36110733.jpg	{}	{}	2025-01-16 17:57:56.857	2025-01-16 17:57:56.857
211	\N	“Saya mengenal penulis sudah cukup lama. Penulis telah lama mengajar dan memperkenalkan sejumlah pemikiran kontemporer terutama di bidang filsafat dan metodologi untuk kajian sosial-budaya baik di lingkungan Universitas Indonesia maupun di sejumlah perguruan tinggi lainnya. Di samping menarik, materi yang disampaikan di buku ini sangat membantu siapa pun yang hendak membaca persoalan-persoalan sosial-budaya kekinian dengan cara kritis. Juga, buku ini menunjukkan kepada kita betapa pentingnya saat ini menerapkan pendekatan lintas disipliner dalam membaca dan menjelaskan berbagai problem sosial-budaya dewasa ini yang sudah berbeda dengan era sebelumnya”.\n—Prof. Dr. Toeti Heraty (Pendiri Program Pascasarjana Filsafat Universitas Indonesia dan Mantan Ketua Bidang Kebudayaan Akademi Ilmu Pengetahuan Indonesia).\n\nBuku ini diperlukan untuk memahami pikiran-pikiran yang mendasari kajian sosial-budaya kontemporer. Ia menumbuhkan pada kita urgensi sikap kritis dalam mengelola aliran pengetahuan dan menandaskan pentingnya pendekatan lintas disipliner dalam membaca dan mencermati fenomena sosial-budaya. Buku ini penting dan mutlak dibaca serta dimiliki oleh para mahasiswa, pengajar, pelaksana negara dari pusat hingga daerah, pimpinan maupun anggota partai, pelaksana lembaga dari yang terendah hingga yang tertinggi, ataupun mereka yang peduli dan terpanggil untuk memaknai kehidupan masa kini yang penuh dengan perubahan dan perkembangan masyarakat yang tak mudah ditebak arahnya.\n—Prof. Riris K. Toha Sarumpaet, Ph.D. (Guru Besar Ilmu Pengetahuan Budaya Universitas Indonesia; ilmuwan sastra; Ketua Departemen Filsafat FIB UI; serta pemerhati dan pembela sastra, budaya dan pendidikan anak)\n\n“Jika disimak dan dicermati, di balik selubung objektivitas ilmu pengetahuan, media (massa), kebijakan dan lain sebagainya ternyata di sana terselip berbagai kepentingan. Karena itulah, dalam melihat ilmu pengetahuan, media (massa), kebijakan dan sebagainya dibutuhkan sikap kritis. Menumbuhkan sikap kritis, inilah pesan yang paling kuat yang dapat dirasakan setelah membaca buku ini. Di samping itu, pesan lainnya, yang juga tak kalah pentingnya, yang bisa dirasakan sesudah membaca buku ini, adalah bahwa ilmu pengetahuan sebaiknya memiliki karakter emansipatoris. Artinya, ilmu pengetahuan tidak selayaknya berorientasi pada ilmu semata melainkan mesti juga dapat dipergunakan untuk memperbaiki kondisi (realitas) sosial budaya yang tak adil dan tak manusiawi. ”\n—Windo Wibowo (Editor dan Penggiat Kajian Filsafat)	\N	\N	\N	\N				\N		\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/Pemikiran_Kritis_Kontemporer.jpg	{}	{}	2025-01-17 05:52:58.373	2025-01-17 05:53:02.479
212	\N	Buku ini membahas sebagian besar dari aliran-aliran epistemologi filsafat modern Barat yang mencakup rasionalisme, empirisme, fenomenalisme (kritisisme), positivisme dan positivisme logis, idealisme, materialisme historis, intuisionisme, eksistensialisme, dan nihilisme. Pemikiran sejumlah filsuf avant-garde yang mewakili aliran masing-masing juga diurai	\N	\N	\N	\N				\N		\N	https://image.gramedia.net/rs:fit:0:0/plain/https://cdn.gramedia.com/uploads/items/9786027696747_Filsafat-Modern-Barat.jpg	{}	{}	2025-01-17 05:47:20.698	2025-01-17 05:47:25.069
213	3273735	Nusantara merupakan salah satu deskripsi sejarah Indonesia yang ditulis secara mendalam namun populer. Kendati buku ini terbit pertama pada 1943, banyak hal-hal yang disampaikan oleh Vlekke aktual sampai abad ke-21. Berbeda dengan buku sejarah selebihnya, Vlekke menampilkan proses sejarah Indonesia tanpa terlalu memusatkan proses pada perluasan kolonialisasi. Dalam buku ini Vlekke misalnya memaparkan bahwa perang agama sangat langka di Jawa dan boleh jadi penyebabnya adalah sinkretisme terpelihara sejak zaman dulu. Ada kisah kegagalan Sultan Agung menyatukan Nusantara karena tak punya angkatan laut yang memadai. Kisah lain yang langka adalah perubahan tabiat orang Belanda yang rajin di tanahairnya (Homo batavus), namun jadi pemalas ketika tinggal di Batavia (Homo bataviensis). Edisi Indonesia buku ini merupakan terjemahan edisi revisi 1963. Penulis menyajikan sejarah Nusantara secara populer. Oleh karena itu, buku ini seolah-olah berisi dongeng Indonesia pada masa silam. Pembaca muda Indonesia dapat dengan mudah memahami kisah yang ditampilkan dalam buku ini. (	\N	712	63	1959-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1209963724i/3273735.jpg	{}	{}	2025-01-16 17:43:58.649	2025-01-16 17:43:58.649
214	6390570	Buku ini mengantarkan mahasiswa serta masyarakat umum yang berminat ke dalam dunia ilmu politik. Dalam buku ini dibahas konsep-konsep seperti politik (politics), kekuasaan, pembuatan keputusan, (decicion making). Di samping itu, dibahas pula fungsi undang-undang dasar, kelompok-kelompok politik, dewan perwkilan rakyat, baik di dalam maupun di luar Indonesia, serta hak-hak asasi dan perkembangannya di PBB. Bahan-bahan yang disajikan dalam edisi kedua ini telah mengalami perbaikan dan lebih lengkap.	\N	1345	107	1977-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1239335289i/6390570.jpg	{}	{}	2025-01-16 17:26:16.543	2025-01-16 17:26:16.543
215	51893	Friedrich Nietzsche's most accessible and influential philosophical work, misquoted, misrepresented, brilliantly original and enormously influential, Thus Spoke Zarathustra is translated from the German by R.J. Hollingdale in Penguin Classics.\n\nNietzsche was one of the most revolutionary and subversive thinkers in Western philosophy, and Thus Spoke Zarathustra remains his most famous and influential work. It describes how the ancient Persian prophet Zarathustra descends from his solitude in the mountains to tell the world that God is dead and that the Superman, the human embodiment of divinity, is his successor. Nietzsche's utterance 'God is dead', his insistence that the meaning of life is to be found in purely human terms, and his doctrine of the Superman and the will to power were all later seized upon and unrecognisably twisted by, among others, Nazi intellectuals. With blazing intensity and poetic brilliance, Nietzsche argues that the meaning of existence is not to be found in religious pieties or meek submission to authority, but in an all-powerful life passionate, chaotic and free.	\N	162247	6093	1883-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1650680683i/51893.jpg	{}	{}	2025-01-16 18:37:15.626	2025-01-16 18:37:15.626
216	11228295	Saat aku duduk di kelas III, Pak Gaekku akan pergi ke Mekkah dan aku akan dibawanya menurut rencana yang sudah ditetapkan. Tetapi, beberapa minggu sebelum berangkat, ada desakan dari ibuku dan pamanku, supaya jangan aku yang ikut serta, melainkan pamanku yang bungsu, Idris. Aku dianggap terlalu muda untuk pergi ke Mekkah, sedangkan pengajian Al Quran belum tamat. Menurut pamanku, lebih baik aku tamat sekolah dulu. Sesudah khatam Quran dan mulai mengaji Nahu dengan mengerti sedikit-sedikit bahasa Arab, barulah pergi ke Mekkah dan kemudian ke Kairo. Alasan itu diterima oleh Pak Gaekku dan ia berangkat ke Mekkah dengan Idris, pamanku. Ayah Gaekku di Batuhampar tidak setuju dengan perubahan rencana itu, tetapi sebagai seorang ahli tarekat, akhirnya ia mengalah juga. "Ini barangkali sudah takdir Allah," katanya. Tetapi ia selalu berharap supaya didikanku betapa juga berbelok-belok jalannya, akan berakhir di Al Azhar. "Ikhtiar dijalani, takdir menyudahi," katanya lagi. Ia dapat menghargai "pengetahuan dunia," tetapi pengetahuan agama lebih besar nilainya. Masyarakat hanya dapat menjadi baik dengan bimbingan agama.	\N	317	38	2009-12-31	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1309649905i/11228295.jpg	{}	{}	2025-01-16 17:13:51.946	2025-01-16 17:13:51.946
217	11236486	Terhadap mereka yang mengkritik hadirnya kami pada Kongres di Bierville itu, kami ingin menyatakan bahwa kehadiran kami itu menunjukkan kepada kaum demokrasi Barat bahwa ada hubungan yang tidak dapat diputus antara dasar kemanusiaan dengan perjuangan revolusioner untuk kemerdekaan bangsa. Langkah pertama untuk memperkenalkan Tanah Air kita Indonesia di luar negeri dibuat dengan berhasil. Nama "Indonesia" tidak perlu dimajukan dengan resolusi. Selama aku di sana dan setelah mendengar pidatoku pada pembukaan Kongres itu, semuanya menyebut Indonesia. Orang-orang Belanda, yang pada pidato permulaan masih menyebut "Hindia Belanda", kata itu tidak diulang mereka lagi, dalam perdebatan maupun dalam pembicaraan lainnya. Dalam tulisan-tulisan mereka ke luar, kepada kawan dan keterangan umum, mereka sebut "Indonesia". Apalagi setelah bertukar pikiran dengan aku. Dalam agenda pimpinan Kongres, nama Indonesia telah terekam, tidak dapat ditukar kembali dengan "Indes-neerlandaises".	\N	236	31	2011-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1309649978i/11236486.jpg	{}	{}	2025-01-16 18:03:55.752	2025-01-16 18:03:55.752
218	11303407	Sukarno berkata, "Aku persilakan Bung Hatta menyusun teks ringkas itu sebab bahasanya kuanggap yang terbaik. Sesudah itu kita persoalkan bersama-sama. Setelah kita memperoleh persetujuan, kita bawa ke muka sidang lengkap yang sudah hadir di ruang tengah." Aku menjawab, "Apabila aku mesti memikirkannya, lebih baik Bung menuliskan, aku mendiktekannya." Semanya setuju, kalimat pertama diambil dari akhir alinea ketiga rencana Pembukaan UUD yang mengenai Proklamasi. Lalu, kalimat pertama itu menjadi, "Kami bangsa Indonesia dengan ini menyatakan kemerdekaan Indonesia." Namun, aku mengatakan, kalimat itu hanya menyatakan kemauan bangsa untuk menentukan nasibnya sendiri. Sebab itu, mesti ada komplemennya yang menyatakan bagaimana caranya menyelenggarakan revolusi nasional. Lalu, aku mendiktekan kalimat yang berikut, "Hal-hal yang mengenai pemindahan kekuasaan dan lain-lain diselenggarakan dengan cara seksama dan dalam tempo yang sesingkat-singkatnya." Setelah bertukar pikiran sebentar, teks itu disetujui oleh kami berlima yang menjadi panitia kecil.	\N	205	24	2011-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1309650036i/11303407.jpg	{}	{}	2025-01-16 17:38:22.684	2025-01-16 17:38:22.684
219	92402	Contains a series of lectures delivered by Heidegger in 1935 at the University of Freiburg. In this work Heidegger presents the broadest and most intelligible account of the problem of being, as he sees this problem. First, he discusses the relevance of it by pointing out how this problem lies at the root not only of the most basic metaphysical questions but also of our human existence in its present historical setting. Then, after a short digression into the grammatical forms and etymological roots of the word "being," Heidegger enters into a lengthy discussion of the meaning of being in Greek thinking, letting pass at the same time no opportunity to stress the impact of this thinking about being on subsequent western speculation. His contention is that the meaning of being in Greek thinking underwent a serious restriction through the opposition that was introduced between being on one hand, and becoming, appearance, thinking and values on the other.	\N	4228	123	1929-07-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1347942226i/92402.jpg	{}	{}	2025-01-16 17:50:26.743	2025-01-16 17:50:26.743
220	203902146	Orang boleh berbeda dalam banyak hal, tapi bakal bersepakat dalam satu hal: ingin bahagia. Sayangnya, makna bahagia itu tidak tunggal dan sama bagi semua orang. Bahagia bagi yang satu, boleh jadi bukan bahagia bagi yang lain. Bahagia itu ternyata macam-macam dan bisa saling bertentangan. Maka, layak sekali kalau orang bertanya: apa, sih, bahagia itu sebenarnya?\n\nEmpat orang bijak—Plato, al-Farabi, al-Ghazali, dan Ki Ageng Suryomentaram—menawarkan konsep kebahagiaan, berikut cara-cara mencapainya. Meski masing-masing mengambil pendekatan berbeda, ada beberapa kesamaan yang mencolok: bahwa orang mesti mengenal diri sendiri sebagai titik berangkat, dan orang menemukan diri sendiri sebagai titik tujuan. Mustahil orang mencapai kebahagiaan kalau tidak tahu siapa dirinya dan apa makna bahagia bagi dirinya.	\N	56	18	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1702760037i/203902146.jpg	{}	{}	2025-01-16 16:48:46.072	2025-01-16 16:48:46.072
221	51809335		\N	141	32	\N	\N	\N	\N	\N	\N	\N	https://dryofg8nmyqjw.cloudfront.net/images/no-cover.png	{}	{}	2025-01-16 18:00:42.972	2025-01-16 18:00:42.972
296	124938191	神々廻vs四ツ村、大佛vs芸妓の殺仕合いで、血飛沫に染まる京都の街!!　師弟関係にあった四ツ村と神々廻をめぐる壮絶な過去とは…!?　同じ頃、騒乱のJCCでは坂本と京のバトルが最終局面を迎えようとしていた!!	\N	910	71	2023-06-02	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1709346058i/124938191.jpg	{}	{}	2025-03-12 15:11:37.543	2025-03-12 15:11:36.914
223	1604607	Pola kenegaraan modern berkembang bersamaan dengan revolusi ekonomi, sosial, dan budaya, yang berlangsung di Eropa Barat tiga ratus tahun yang lalu dan mendapat ungkapan yang paling mengesankan dalam perwujudan masyarakat industrial dan pasca-industrial masa kini.\n\nSalah satu pertanyaan inti etika politik dewasa ini menyangkut legitimasi kekuasaan. Klaim-klaim kenegaraan modern yang bercorak multidimensional dan kontroversial menuntut regleksi filosofis atas prinsip-prinsip dasar kehidupan politik, baik dalam dimensi hukum maupun kekuasaan. Refleksi ini menjadi tema buku Etika Politik.\n\nDalam delapan belas bab, Franz Magnis-Suseno, dosen Filsafat Sosial pada Sekolah TInggi Filsafat Driyarkara dan Jurusan Filsafat Fakultas Sastra Universitas Indonesia, membahas masalah-masalah metode, legitimasi hukum dan negara, positivisme hukum, hak-hak asasi manusia dan kebebasan suara hati, wewenang negara dan batas-batasnya, demokrasi, tanggungjawab sosial negara, hal ideologi, bersamaan dengan fikiran tokoh-tokoh filsafat politik seperti Aquinas, Hobbes, Locke, Rousseau, Hegel, dan Marx.\n\nSebuah buku ini unik, yang mampu membantu para pembaca memahami masalah-masalah ideologis secara kritis berdasarkan argumen-argumen yang dapat dipertanggungjawabkan.	\N	168	7	1988-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1487691445i/1604607.jpg	{}	{}	2025-01-16 17:46:41.428	2025-01-16 17:46:41.428
224	1739755	Indonesian Edition of:\nBuddha 4: The Forrest of Uruvela\n(c) 2003 by Tezuka Productions \n\nJilid keempat berkisah masa tapa Siddharta di Hutan Uruwela sampai mendapat pencerahan di bawah pohon Bodhi. Pada bagian awal digambarkan pertemuan Siddharta dengan Dewadatta yang berujung pada bentuk-bentuk penyiksaan diri. Siddharta melakoni penyiksaan diri sampai dalam bentuk yang paling berat tapi tetap merasa tak puas. Pada puncaknya ia menolak semua bentuk penyiksaan diri dan sampai pada kesimpulan bahwa hidup adalah derita itu sendiri.\n\n***\n\n"Sarat dengan keindahan, kekejaman, drama, komedi percintaan, dan kekerasan, Buddha karya Osamu Tezuka merangkum keseluruhan kehidupan dalam suatu karya puncak sastra grafis. Mengandung nilai-nilai moral yang mendalam namun tidak pernah menjadi moralistik, Buddha memadukan kegirangan berkartun dengan keseriusan epik salah satu agama besar."\n- Time	\N	3546	156	1983-06-09	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1479886205i/1739755.jpg	{}	{}	2025-01-16 16:50:53.272	2025-01-16 16:50:53.272
225	1739696	Indonesian Edition of:\nBuddha 3: Devadatta\n(c) 2003 by Tezuka Productions \n\nJilid ketiga menceritakan masa awal tapa penyiksaan diri yang sarat upaya berbagai pihak mengembalikan Siddharta ke status awal sebagai priyayi agung. Pada akhir cerita dikisahkan perkenalan Siddharta dengan Raja Bimbisara di Gunung Pandawa. Dalam pertemuan pertama itu Raja Bimbisara memberi nama Buddha, yang berarti yang tercerahkan, kepada Siddharta.\n\n***\n\n"Sarat dengan keindahan, kekejaman, drama, komedi percintaan, dan kekerasan, Buddha karya Osamu Tezuka merangkum keseluruhan kehidupan dalam suatu karya puncak sastra grafis. Mengandung nilai-nilai moral yang mendalam namun tidak pernah menjadi moralistik, Buddha memadukan kegirangan berkartun dengan keseriusan epik salah satu agama besar."\n- Time	\N	3940	167	1983-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1478054845i/1739696.jpg	{}	{}	2025-01-16 17:54:31.557	2025-01-16 17:54:31.557
226	1739624	Indonesian Edition of:\nBuddha 2: The Four Encounters\n(c) 2003 by Tezuka Productions\n\nJilid kedua seri ini melukiskan masa kanak-kanak Pangeran Siddharta Gautama sampai memutuskan untuk keluar dari lingkungan istana. Pangeran Siddharta merasa tak betah terus-menerus dalam kemegahan istana. Suatu hari ia berhasil menyelinap keluar dari istana bersama Tatta.\n\nPerjalanan singkat keluar istana telah memperkenalkan Siddharta pada derita manusia. Sejak itulah ia terus-menerus memikirkan musabab derita dan tujuan hidup. Kegelisahannya akhirnya memuncak sampai akhirnya ia memutuskan keluar dari istana, meninggalkan anak dan istrinya, untuk menemukan jawaban atas persoalan yang ia hadapi.\n\n***\n\n"Sarat dengan keindahan, kekejaman, drama, komedi percintaan, dan kekerasan, Buddha karya Osamu Tezuka merangkum keseluruhan kehidupan dalam suatu karya puncak sastra grafis. Mengandung nilai-nilai moral yang mendalam namun tidak pernah menjadi moralistik, Buddha memadukan kegirangan berkartun dengan keseriusan epik salah satu agama besar."\n- Time	\N	4771	248	1983-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1479886197i/1739624.jpg	{}	{}	2025-01-16 18:10:21.132	2025-01-16 18:10:21.132
227	1739593	Jilid pertama seri ini melukiskan situasi sosial di India menjelang kelahiran Siddharta Gautama. Di sana keturunan paling totok sedang kuat-kuatnya mencengkeram masyarakat. Mereka menamai dirinya kaum Brahmana dan membagi-bagi masyarakat selebihnya ke dalam kelompok yang dibuat lebih rendah statusnya : Ksatria, Waisya, dan Sudra. Dalam situasi masyarakat semacam itulah lahir Siddharta Gautama.\n\nMelalui perkenalan dengan beberapa tokoh imajiner--Chapra si budak, Tatta si paria, dab banyak lagi--Tezuka melukiskan dengan kocak-getir kebrutalan sistem kasta yang menindas bangsa itu bertahun-tahun lamanya.\n\n***\n\n"Sarat dengan keindahan, kekejaman, drama, komedi percintaan, dan kekerasan, Buddha karya Osamu Tezuka merangkum keseluruhan kehidupan dalam suatu karya puncak sastra grafis. Mengandung nilai-nilai moral yang mendalam namun tidak pernah menjadi moralistik, Buddha memadukan kegirangan berkartun dengan keseriusan epik salah satu agama besar." - Time	\N	8352	665	1972-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1479886043i/1739593.jpg	{}	{}	2025-01-16 17:54:15.468	2025-01-16 17:54:15.468
229	60308635		\N	1	0	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1644032866i/60308635.jpg	{}	{}	2025-01-16 15:55:00.895	2025-01-16 15:55:00.895
230	25241	Hegel wrote this classic as an introduction to a series of lectures on the "philosophy of history" — a novel concept in the early nineteenth century. With this work, he created the history of philosophy as a scientific study. He reveals philosophical theory as neither an accident nor an artificial construct, but as an exemplar of its age, fashioned by its antecedents and contemporary circumstances, and serving as a model for the future. The author himself appears to have regarded this book as a popular introduction to his philosophy as a whole, and it remains the most readable and accessible of all his philosophical writings.\nEschewing the methods of original history (written during the period in question) and reflective history (written after the period has passed), Hegel embraces philosophic history, which employs a priori philosophical thought to interpret history as a rational process. Reason rules history, he asserts, through its infinite freedom (being self-sufficient, it depends on nothing beyond its own laws and conclusions) and power (through which it forms its own laws). Hegel argues that all of history is caused and guided by a rational process, and God's seemingly unknowable plan is rendered intelligible through philosophy. The notion that reason rules the world, he concludes, is both necessary to the practice of philosophic history and a conclusion drawn from that practice.	\N	3644	169	1830-12-31	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1328864554i/25241.jpg	{}	{}	2025-01-16 17:18:43.224	2025-01-16 17:18:43.224
232	9788457	This work has been selected by scholars as being culturally important, and is part of the knowledge base of civilization as we know it. This work was reproduced from the original artifact, and remains as true to the original work as possible. Therefore, you will see the original copyright references, library stamps (as most of these works have been housed in our most important libraries around the world), and other notations in the work.\n\nThis work is in the public domain in the United States of America, and possibly other nations. Within the United States, you may freely copy and distribute this work, as no entity (individual or corporate) has a copyright on the body of the work.\n\nAs a reproduction of a historical artifact, this work may contain missing or blurred pages, poor pictures, errant marks, etc. Scholars believe, and we concur, that this work is important enough to be preserved, reproduced, and made generally available to the public. We appreciate your support of the preservation process, and thank you for being an important part of keeping this knowledge alive and relevant.	\N	40738	868	0351-01-01	\N	\N	\N	\N	\N	\N	https://dryofg8nmyqjw.cloudfront.net/images/no-cover.png	{}	{}	2025-01-16 17:32:46.225	2025-01-16 17:32:46.225
233	133673801	The secret passage to the house next door leads to a fascinating adventureNARNIA...where the woods are thick and cold, where Talking Beasts are called to life...a new world where the adventure begins.Digory and Polly meet and become friends one cold, wet summer in London. Their lives burst into adventure when Digory's Uncle Andrew, who thinks he is a magician, sends them hurtling to...somewhere else. They find their way to Narnia, newborn from the Lion's song, and encounter the evil sorceress Jadis before they finally return home.	\N	570401	23050	1955-05-01	\N	\N	\N	\N	\N	\N	https://dryofg8nmyqjw.cloudfront.net/images/no-cover.png	{}	{}	2025-01-16 17:03:38.717	2025-01-16 17:03:38.717
234	132080146	They open a door and enter a world NARNIA...the land beyond the wardrobe, the secret country known only to Peter, Susan, Edmund, and Lucy...the place where the adventure begins. Lucy is the first to find the secret of the wardrobe in the professor's mysterious old house. At first, no one believes her when she tells of her adventures in the land of Narnia. But soon Edmund and then Peter and Susan discover the Magic and meet Aslan, the Great Lion, for themselves. In the blink of an eye, their lives are changed forever.	\N	2951874	36675	1950-10-16	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1697079942i/132080146.jpg	{}	{}	2025-01-16 17:31:47.423	2025-01-16 17:31:47.423
235	84119	The Horse and his Boy is a stirring and dramatic fantasy story that finds a young boy named Shasta on the run from his homeland with the talking horse, Bree. When the pair discover a deadly plot by the Calormen people to conquer the land of Narnia, the race is on to warn the inhabitants of the impending danger and to rescue them all from certain death.	\N	370551	13487	1954-09-05	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1703358949i/84119.jpg	{}	{}	2025-01-16 15:58:37.98	2025-01-16 15:58:37.98
236	121749	Illustrations in this ebook appear in vibrant full color on a full color ebook device, and in rich black and white on all other devices. \n \nNarnia . . . where animals talk . . . where trees walk . . . where a battle is about to begin. \n \nA prince denied his rightful throne gathers an army in a desperate attempt to rid his land of a false king. But in the end, it is a battle of honor between two men alone that will decide the fate of an entire world. \n \nPrince Caspian is the fourth book in C.S. Lewis’s The Chronicles of Narnia, a series that has become part of the canon of classic literature, drawing readers of all ages into a magical land with unforgettable characters for over fifty years. This is a stand-alone novel, but if you would like to see more of Lucy and Edmund’s adventures, read The Voyage of the Dawn Treader, the fifth book in The Chronicles of Narnia.	\N	459615	13179	1951-10-14	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1308814880i/121749.jpg	{}	{}	2025-01-16 17:16:36.322	2025-01-16 17:16:36.322
237	140225	NARNIA... the world of wicked dragons and magic spells, where the very best is brought out of even the worst people, where anything can happen (and most often does)... and where the adventure begins.\n\nThe Dawn Treader is the first ship Narnia has seen in centuries. King Caspian has built it for his voyage to find the seven lords, good men whom his evil uncle Miraz banished when he usurped the throne. The journey takes Edmund, Lucy, and their cousin Eustace to the Eastern Islands, beyond the Silver Sea, toward Aslan's country at the End of the World.	\N	487006	12055	1952-09-15	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1661032500i/140225.jpg	{}	{}	2025-01-16 18:07:50.967	2025-01-16 18:07:50.967
238	65641	Jill and Eustace must rescue the Prince from the evil Witch.\n\nNARNIA...where owls are wise, where some of the giants like to snack on humans, where a prince is put under an evil spell...and where the adventure begins.\n\nEustace and Jill escape from the bullies at school through a strange door in the wall, which, for once, is unlocked. It leads to the open moor...or does it? Once again Aslan has a task for the children, and Narnia needs them. Through dangers untold and caverns deep and dark, they pursue the quest that brings them face to face with the evil Witch. She must be defeated if Prince Rillian is to be saved.	\N	313273	9666	1953-09-06	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1661032839i/65641.jpg	{}	{}	2025-01-16 15:53:30.143	2025-01-16 15:53:30.143
239	84369	For the first time, an edition of Lewis's classic fantasy fiction packaged specifically for adults. Complementing the look of the author's non-fiction books, and anticipating the forthcoming Narnia feature films, this edition contains an exclusive "P.S." section about the history of the book, plus a round-up of the first six titles. The last days of Narnia, and all hope seems lost as lies and treachery interweave to threaten the destruction of everything. As the battle lines are drawn, old friends are summoned back to Narnia, though none can predict the outcome in this magnificent ending to the famous series. On 9 December 2005, Andrew (Shrek) Adamson's live-action film adaptation of The Lion, the Witch and the Wardrobe will be released by Disney, and it is already being hailed as the biggest film franchise of all time, guaranteed to appeal to adults and children across the globe. The second film is already in development. Sporting breathtaking new photographic covers, these new adult editions of the seven Chronicles of Narnia now give everyone an opportunity to experience the adventures in their original form. Re-live your childhood fantasies or discover for the first time what everyone will be talking about by Christmas and savour some of the best-loved stories ever written.	\N	289760	11460	1956-09-03	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1308814830i/84369.jpg	{}	{}	2025-01-16 17:06:39.947	2025-01-16 17:06:39.947
297	198704052	若き日の坂本、南雲、赤尾はJCCの超問題児だった!!　退学を回避すべく、3人は謎の男・有月と共に特別任務へと向かうことに。標的を求め“殺し屋デパート”に乗り込むが…!?　衝撃と戦慄の過去編、スタート!!	\N	754	60	2023-09-04	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1709346233i/198704052.jpg	{}	{}	2025-03-12 15:11:05.019	2025-03-12 15:11:04.38
242	6609784	La obra maestra de Naoki Urasawa (20th Century Boys) regresa al mercado español con la edición definitiva en 9 volúmenes de lujo que recopilan toda la saga de Monster. En ella, el Dr. Tenma se enfrasca en la aventura de su vida después de salvarle la vida a Johan, un niño que llegó a su hospital con una herida de bala en la cabeza en el peor momento posible.Este hecho desencadena toda una serie de acontecimientos que llevarán al Dr. Tenma a viajar por el mundo mientras averigua el secreto detrás de Johan. Uno de los mejores manga de la historia se presenta con páginas a color por primera vez, portadas nuevas que forman un mosaico cuando la colección está completa y una cuidada edición para que Monster perdure para siempre en un lugar privilegiado en la librería de todo el mundo.	\N	10765	1071	1995-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1247397310i/6609784.jpg	{}	{}	2025-01-16 17:46:51.555	2025-01-16 17:46:51.555
243	60805602	Akibat terbangnya selembar kain brokat, perjalanan Dabu sang Penenun dan Lere si Pendongeng ke Desa Impian pun dimulai. \n\nPenenun, Pendongeng, dan Kain Brokat Ajaib merupakan bagian dari Seri Sastra Anak Asia yang mengangkat cerita-cerita dari berbagai negara di Asia. Ditulis secara imajinatif, seri ini bertujuan untuk mengenalkan & memperkaya wawasan anak tentang berbagai kisah dari negara lain serta menghadirkan pendidikan karakter lewat pengalaman yang menyenangkan.	\N	28	10	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1649849819i/60805602.jpg	{}	{}	2025-01-16 18:21:35.945	2025-01-16 18:21:35.945
244	60805589	Si Hitam dan si Merah: Berbeda Itu Indah adalah kisah sarat moral yang tersusun oleh ilustrasi penuh yang unik dan menarik. \n\nBuku ini merupakan bagian dari Seri Sastra Anak Asia yang mengangkat cerita-cerita dari berbagai negara di Asia. Ditulis secara imajinatif, seri ini bertujuan untuk mengenalkan & memperkaya wawasan anak tentang berbagai kisah dari negara lain serta menghadirkan pendidikan karakter lewat pengalaman yang menyenangkan.	\N	30	6	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1649849626i/60805589.jpg	{}	{}	2025-01-16 16:48:59.243	2025-01-16 16:48:59.243
246	17837762	Spirals... this town is contaminated with spirals...\n\nKurouzu-cho, a small fogbound town on the coast of Japan, is cursed. According to Shuichi Saito, the withdrawn boyfriend of teenager Kirie Goshima, their town is haunted not by a person or being but by a pattern: uzumaki, the spiral — the hypnotic secret shape of the world. This bizarre masterpiece of horror manga is now available in a single volume. Fall into a whirlpool of terror!	\N	76355	9743	2000-03-06	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1476677569i/17837762.jpg	{}	{}	2025-01-17 04:50:51.745	2025-01-17 04:50:55.636
247	34746513	Conspirator and assassin, philosopher and statesman, promoter of peace and commander in war, Marcus Brutus (ca. 85–42 BC) was a controversial and enigmatic man even to those who knew him. His leading role in the murder of Julius Caesar on the Ides of March, 44 BC, immortalized his name forever, but the verdict on his act remains out to this day. Was Brutus wrong to kill his friend and benefactor, or was he right to place his duty to country ahead of personal obligations?\n  \n In this comprehensive and stimulating biography Kathryn Tempest delves into contemporary sources to bring to light the personal and political struggles Brutus faced. As the details are revealed—from his own correspondence with Cicero, from the perceptions of his peers, and from the Roman aristocratic values and concepts that held sway in his time—Brutus emerges from legend, revealed to us more surely than ever before.	\N	138	22	2017-11-21	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1495772382i/34746513.jpg	{}	{}	2025-01-16 18:12:49.577	2025-01-16 18:12:49.577
248	28109889	Pada suatu hari, Darmagandhul, seorang murid yang tajam hatinya, bertanya kepada gurunya, Kiai Kalamwadi, tentang awal mula kenapa penduduk Jawa meninggalkan agama Shiwa Buddha dan beralih memeluk agama Islam. Pada saat itulah Kiai Kalamwadi mulai menyadari bahwa rahasia kehancuran Majapahit dan Jawa yang tersembunyi selama berabad-abad patut dibabarkan kepada Darmagandhul, agar menjadi pelajaran bagi generasi mendatang. Kiai Kalamwadi memperoleh pengetahuan itu dari gurunya, Raden Budi, yang mewarisi cerita sejarah dan ilmu-ilmu rahasia leluhur Jawa. Melalui percakapan yang disenandungkan, Kiai Kalamwadi lantas berkisah tentang proses kehancuran Majapahit. Dikisahkan, Majapahit hancur oleh serangan Dêmak yang dipimpin oleh Senapati Jimbun alias Raden Patah—putra kandung Prabu Brawijaya yang berkuasa. Hanya Syekh Siti Jênar yang menolak rencana itu, sehingga ia dijatuhi hukuman mati. \n \nSemenjak terbit pertama kali pada paruh pertama abad ke-20, Darmagandhul memantik polemik panjang di kalangan sejarawan terkait validitas data-data sejarah yang ditampilkan di dalamnya. Banyak yang menyetujui, tetapi tak sedikit yang menyangkal dan menganggap kitab tersebut sekadar karya sastra belaka. Buku yang berada di tangan Anda saat ini memberikan analisis kritis atas kitab tersebut, didasarkan pada peninggalan-peninggalan sejarah berupa prasasti, kakawin, babad, sêrat, kronik, dan cerita tutur yang berkembang di tanah Jawa dan Bali tentang masa akhir Majapahit. Buku ini juga mengulas ajaran-ajaran rahasia Jawa dalam kitab ini dengan sudut pandang Tasawuf, Shiwa Buddha, dan Kêjawen.	\N	31	4	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1449407112i/28109889.jpg	{}	{}	2025-01-16 17:33:31.827	2025-01-16 17:33:31.827
249	18144590	Combining magic, mysticism, wisdom, and wonder into an inspiring tale of self-discovery, The Alchemist has become a modern classic, selling millions of copies around the world and transforming the lives of countless readers across generations.\n\nPaulo Coelho's masterpiece tells the mystical story of Santiago, an Andalusian shepherd boy who yearns to travel in search of a worldly treasure. His quest will lead him to riches far different—and far more satisfying—than he ever imagined. Santiago's journey teaches us about the essential wisdom of listening to our hearts, recognizing opportunity and learning to read the omens strewn along life's path, and, most importantly, following our dreams.	\N	3285715	131292	1987-12-31	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1654371463i/18144590.jpg	{}	{}	2025-01-17 05:42:58.77	2025-01-17 05:43:02.858
250	1237398	A new shonen sensation in Japan, this series features Monkey D. Luffy, whose main ambition is to become a pirate. Eating the Gum-Gum Fruit gives him strange powers but also invokes the fruit's curse: anybody who consumes it can never learn to swim. Nevertheless, Monkey and his crewmate Roronoa Zoro, master of the three-sword fighting style, sail the Seven Seas of swashbuckling adventure in search of the elusive treasure "One Piece."	\N	159813	3840	1997-12-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1318523719i/1237398.jpg	{}	{}	2025-01-16 17:47:07.941	2025-01-16 17:47:07.941
415	53308615	Sfida al re di Kanagawa l'attesissima fase finale del torneo di prefettura ha infine inizio. Quattro squadre e due soli biglietti per accedere al campionato nazionale: il "re" Kainan è pronto a difendere la sua supremazia e a conquistare la qualificazione all'inter-high per il diciassettesimo anno di fila!	\N	428	33	2018-07-02	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1677773735i/53308615.jpg	{}	{}	2025-09-01 05:39:51.124	2025-09-01 05:39:50.448
254	75309771	Gregorio Samsa è un semplice commesso viaggiatore , preciso e metodico, che un mattino, svegliatosi in ritardo rispetto al solito, si rende conto di aver assunto le sembianze di un gigantesco scarafaggio . Il pensiero di Gregorio, però, non è inizialmente rivolto al suo aspetto mostruoso, quanto al consistente ritardo che sta la sua professione lo costringe infatti ad un ferreo rispetto delle coincidenze ferroviarie e, nelle condizioni in cui si trova, Gregorio perderà sicuramente il treno della mattina.\nScritto nel 1912 ma pubblicato nel 1915. Si tratta di uno dei testi più noti e famosi dello scrittore boemo.\nStraordinaria e riuscitissima allegoria della alienazione dell’uomo moderno all’interno della famiglia e della società, che si traduce nell’isolamento del “diverso” e nell’incomunicabilità con i propri simili. Il racconto è anche un ottimo esempio della poetica e della visione del mondo di Kafka , in cui il destino dell’esistenza individuale è in mano a forze oscure e inconoscibili, che operano in maniera assurda e imperscrutabile sulla vita degli uomini.\nIl libro è qui riproposto in una nuova traduzione , fedele al testo originale ma adattata al linguaggio moderno, e arricchito da alcune illustrazioni .\nBuona lettura a tutti!	\N	1244509	54048	1915-10-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1672063892i/75309771.jpg	{}	{}	2025-01-16 17:24:54.557	2025-01-16 17:24:54.557
255	205127614	Sebuah cerita dari Desa Konohagakure. Adalah seorang murid di Akademi Ninja yang suka berbuat onar dan bermimpi menjadi seorang Hokage, bernama Naruto. Ia memiliki rahasia, sejak lahir di dalam tubuhnya terdapat siluman rubah yang disegel! Naruto berhasil meraih mimpinya. Ia berhasil lulus ujian Ninja yang diberikan oleh Guru Kakashi, bersama Sakura dan Sasuke. Sebagai Genin, tingkatan Ninja terbawah, mereka harus melaksanakan berbagai macam misi. Kali ini, misi yang diberikan adalah mengawal Tazuna, si pembuat jembatan. Namun, tanpa disadari, ada pembunuh yang sedang mengincar mereka semua	\N	16	3	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1704860243i/205127614.jpg	{}	{}	2025-01-17 04:47:29.939	2025-01-17 04:47:33.62
256	1815215	Student Hijo karya Marco Kartodikromo, terbit pertama kali tahun 1918 melalui Harian Sinar Hindia, dan muncul sebagai buku tahun 1919. Merupakan salah satu perintis lahirnya sastra perlawanan, sebuah fenomena dalam sastra Indonesia sebelum perang. \n\nNovel ini mencoba berkisah tentang awal mula kelahiran para intelektual pribumi, yang lahir dari kalangan borjuis kecil, dan secara berani mengkontraskan kehidupan di Belanda dan Hindia Belanda. Hingga menjadi masuk akal jika novel ini kemudian dipinggirkan oleh dominasi dan hegemoni Balai Pustaka, bahkan sampai saat ini.\n\nMas Marco secara lugas juga menunjukkan keberpihakannya kepada kaum bumiputra. Ia menggunakan tokoh Controleur Walter sebagai tokoh penganut politik etis yang mengkritik ketidakadilan kolonial terhadap rakyat Jawa atau Hindia.	\N	406	82	1918-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1190265313i/1815215.jpg	{}	{}	2025-01-16 18:01:17.7	2025-01-16 18:01:17.7
257	1739765	Indonesian Edition of:\nBuddha 5: Deer Park\n(c) 2003 by Tezuka Productions \n\nJilid ke-5 memaparkan pertemuan Dewadatta sebagai pejabat istana dengan Buddha dan khotbah di Taman Rusa. Siddharta sekarang sudah menjadi Sang Buddha (yang tercerahkan).	\N	3247	124	1983-07-11	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1479886211i/1739765.jpg	{}	{}	2025-01-16 18:06:57.786	2025-01-16 18:06:57.786
258	36684919	Surat untuk Ayah ditulis Kafka saat ia berusia 36 tahun, pada puncak kreatifnya yang membara. Surat ini berisikan protes Kafka kepada ayahnya; ia bertindak sebagai penggugat sementara ayahnya selamanya menjadi terdakwa. Ia anggap ayahnya sebagai diktator kecil dalam keluarga, betapa ia merasa lebih kerdil dan rapuh di hadapan ayahnya yang perkasa.	\N	46714	5371	1919-11-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1511968174i/36684919.jpg	{}	{}	2025-01-16 18:06:40.604	2025-01-16 18:06:40.604
259	19380	Candide is the story of a gentle man who, though pummeled and slapped in every direction by fate, clings desperately to the belief that he lives in "the best of all possible worlds." On the surface a witty, bantering tale, this eighteenth-century classic is actually a savage, satiric thrust at the philosophical optimism that proclaims that all disaster and human suffering is part of a benevolent cosmic plan. Fast, funny, often outrageous, the French philosopher's immortal narrative takes Candide around the world to discover that — contrary to the teachings of his distinguished tutor Dr. Pangloss — all is not always for the best. Alive with wit, brilliance, and graceful storytelling, Candide has become Voltaire's most celebrated work.	\N	287307	12595	1758-12-31	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1345060082i/19380.jpg	{}	{}	2025-01-16 17:05:23.166	2025-01-16 17:05:23.166
260	221828942	Buku kumpulan cerpen terbaik Kafka ini memuat: \n\nDi Depan Hukum (Vor dem Gesetz)\nPesan dari Sang Kaisar (Eine kaiserliche Botschaft)\nPutusan (Das Urteil)\nSeorang Puasawan (Ein Hungerkünstler)\nSeorang Dokter Desa (Ein Landarzt)\nSebuah Naskah Tua (Ein altes Blatt)\nJakal dan Orang Arab (Schakale und Araber)\nKunjungan di Tambang (Ein Besuch im Bergwerk)\nKekhawatiran Seorang Kepala Keluarga (Die Sorge des Hausvaters)\nSebelas Anak (Elf Söhne)\nPembunuhan terhadap Saudara (Ein Brudermord)\nSebuah Mimpi (Ein Traum)\nPidato di Hadapan Sebuah Akademi (Ein Bericht für eine Akademie)\nDi Koloni Penjara (In der Strafkolonie)	\N	5670	442	1912-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1732295285i/221828942.jpg	{}	{}	2025-01-16 18:04:29.788	2025-01-16 18:04:29.788
261	1723108	Kartun Lingkungan membahas berbagai topik utama lingkungan: daur kimia, komunitas makhluk hidup, jaring-jaring makanan, pertanian, pertumbuhan penduduk, sumber-sumber energi dan bahan mentah, pembuangan daur-ulang limbah, perkotaan, polusi, pembabatan hutan, penipisan lapisan ozon, dan pemanasan global. Semua topik ini ditempatkan dalam konteks ekologi, disertai pembahasan mengenai dinamika populasi, termodinamika, perilaku sistem yang kompleks.	\N	287	29	1996-03-15	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1472286090i/1723108.jpg	{}	{}	2025-01-16 17:54:41.431	2025-01-16 17:54:41.431
262	123675190	The first book in the New York Times best-selling saga with a cover image and an 8-page photo insert from the Disney+ series!\n\nRead the book that launched Percy Jackson into the stratosphere before the Disney+ series comes out!\n\nLately, mythological monsters and the Olympian gods seem to be walking straight out of the pages of Percy Jackson’s Greek mythology textbook and into his life. Zeus's master lightning bolt has been stolen, and Percy is the prime suspect. Percy and his friends have just ten days to find and return Zeus's stolen property and bring peace to a warring Mount Olympus. \n\nWhether you are new to Percy or a longtime fan, this tie-in paperback edition with full-color photos from the Disney+ series is a must-have for your library.	\N	3224599	110588	2005-07-27	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1684776677i/123675190.jpg	{}	{}	2025-01-16 15:54:46.118	2025-01-16 15:54:46.118
265	208430346	Si manusia iblis, Zabuza, yang seharusnya telah dikalahkan oleh Sharingan Kakashi, ternyata masih hidup! Kelompok Naruto, yang telah tiba di negara Nami untuk mengawal Pak Tazuna, dilanda keraguan. Tapi, ini bukan saatnya untuk takut! Di bawah bimbingan Guru Kakashi, Naruto dan yang lain memulai aksi mereka! Namun, Sasuke gugur saat melindungi Naruto! Saat itu, terjadi keanehan pada diri Naruto! Haku yang terkena pukulan kemarahan pun menyadari hal tersebut. Sementara itu, pertarungan antara Zabuza vs Kakashi semakin sengit, siapakah yang menang!? Inilah babak akhir dari pergolakan di Negara Nami!!	\N	13	3	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1707796476i/208430346.jpg	{}	{}	2025-01-21 11:26:16.442	2025-01-21 11:26:15.794
266	44767458	Set on the desert planet Arrakis, Dune is the story of the boy Paul Atreides, heir to a noble family tasked with ruling an inhospitable world where the only thing of value is the “spice” melange, a drug capable of extending life and enhancing consciousness. Coveted across the known universe, melange is a prize worth killing for...\n\nWhen House Atreides is betrayed, the destruction of Paul’s family will set the boy on a journey toward a destiny greater than he could ever have imagined. And as he evolves into the mysterious man known as Muad’Dib, he will bring to fruition humankind’s most ancient and unattainable dream.	\N	1504803	75191	1965-06-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1555447414i/44767458.jpg	{}	{}	2025-01-22 17:04:48.382	2025-01-22 17:04:47.712
267	54315378	Hafızaibeşer, malum, nisyan ile malul. Nisyanı isyana çevirme fikrini üreten Sol bakış en başta antikapitalisttir. Ancak unutmamak artık daha önemli, çünkü bugün kapitalizmin bambaşka bir aşamasını yaşıyoruz: Hiper-kapitalizm. Küreselleşmiş, özelleştirmeye ve piyasa-tapınmacılığına dayalı günümüz hiper-kapitalizminin insanların esenliğini, toplumsal adaleti ve tüm yeryüzünü tehdit ettiğini söyleyen çizer Larry Gonick ve yazar Tim Kasser bu ortak çalışmalarında mevcut sistemin nasıl çığrından çıktığını çözümlemekle kalmıyor, aynı zamanda yaşanmış direniş pratiklerinden hareketle daha sağlıklı bir geleceğin nasıl kurulacağının da ipuçlarını veriyorlar.\n\nWall-Street’i İşgal Et kuşağından olan yazar ve çizer, değerler, insanın esenliği ve tüketim toplumu üzerine yapılan araştırmaları temel alarak, yaşadığımız dünyayı anlamak bakımından kritik önem taşıyan kavramları (şirket iktidarı, serbest ticaret, özelleştirme, kuralsızlaştırma) tanımlıyor ve mevcut sistemi değiştirme yönünde geliştirilmiş tepkilerin (yalın bir yaşam sürmek, paylaşma, protesto vb.) dökümünü çıkarıyorlar.\n\nGonick ve Kasser’in bu sivri dilli ve derinlikli çizgi romanı küresel ekonomiyi ve onu değiştirmeyi hedefleyen hareketleri berrak bir dille anlatırken okurlarını eğlenceli bir anti-hiperkapitalist yolculuğa çağırıyor.	\N	368	77	2017-08-15	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1593414706i/54315378.jpg	{}	{}	2025-01-24 17:54:04.532	2025-01-24 17:54:03.85
268	57557794	坂本を狙う奇妙な殺し屋と対峙するシン。思考の読めない敵に対抗する術は…!?　なんとか遊園地での平和な休日を守り抜こうとする坂本たちに、凄腕殺し屋コンビの魔の手が迫る!!　家族に内緒の超難関任務の行方は!?	\N	3223	225	2021-06-04	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1622651347i/57557794.jpg	{}	{}	2025-01-26 10:10:59.924	2025-01-26 10:10:59.773
269	28320660	Die beeindruckende Geschichte des "Kleinen Prinzen" begleitet Kinder und Erwachsene bereits seit vielen Jahrzehnten. Der Originaltext eignet sich als französische Lektüre ab dem 4. Schuljahr.	\N	2271582	75419	1943-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1451006197i/28320660.jpg	{}	{}	2025-01-27 11:44:36.479	2025-01-27 11:44:35.823
270	78942103	Atrás da recompensa de um milhão de ienes, Sakamoto e sua turma participam de um torneio de Airsoft, organizado pelo bairro comercial. Eles acabam tendo que formar um time com o franco-atirador e exímio idiota Heisuke, que está atrás de... Sakamoto?! Além disso, perigos relacionados à organização subterrânea, onde Shin foi criado, se aproximam do Mercadinho...	\N	2495	185	2021-09-03	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1678362196i/78942103.jpg	{}	{}	2025-01-27 11:45:07.881	2025-01-27 11:45:07.254
271	4000324	Pada masa robot dan manusia hidup berdampingan, terjadi pembunuhan sadis terhadap manusia dan sejumlah robot berkemampuan tinggi.\n\nSiapakah pembunuhnya, manusia atau robot?\n\nDetektif Gesicht - robot Europol - berusaha menyelidiki kasus ini.	\N	10217	648	2004-09-29	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1236354201i/4000324.jpg	{}	{}	2025-01-29 07:28:08.34	2025-01-29 07:28:11.183
272	62328717	ラボの地下深くで坂本商店、殺し屋軍団、ORDERの3者が一挙集結!!　背後に蠢く「あの男」の存在をめぐり緊迫した空気が走る中、ルー奪還を目指す坂本商店に対し鹿島と勢羽が襲いかかる!!　救出作戦の行方は…!?	\N	2154	130	2021-11-03	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1662576857i/62328717.jpg	{}	{}	2025-01-29 07:28:45.379	2025-01-29 07:28:48.605
273	170176600	“Aqueles que contam com a sorte acabam morrendo...”Um intenso confronto do Mercadinho Sakamoto contra o mafioso chinês Wutang no cassino!!Será possível proteger a Lu e conseguir informações sobre a recompensa?! Além disso, os mais sinistros e terríveis assassinos atravessam o mar atrás de Sakamoto!!	\N	1867	136	2022-01-03	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1690203543i/170176600.jpg	{}	{}	2025-01-29 07:28:21.015	2025-01-29 07:28:24.048
274	3237493	Light Yagami es un empollón. Pero su vida da un vuelco cuando encuentra una libreta con el misterioso título Death Note en la portada y recibe la vista de un shinigami, quien le explica que la libreta sirve para matar a todo aquel cuyo nombre sea escrito en ella. A partir de entonces, Light utilizará la libreta para dar cuenta de cuanto criminal o espíritu maligno le pase por delante. Pero pronto sus actividades comenzarán a llamar la atención de la policía y otros investigadores.	\N	330365	5503	2004-04-02	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1262733374i/3237493.jpg	{}	{}	2025-02-05 16:00:39.095	2025-02-05 16:00:38.898
308	213980305	Naruto mulai berlatih setelah bertemu Sennin Katak misterius sebelum babak utama ‘tes ketiga’. Di waktu yang berbeda, Dosu yang menantang Gaara dikalahkan dalam sekejap… Sementara, terjadi sesuatu antara Kabuto dan Baki si jounin dari Suna! Kini, perjanjian yang mengerikan mulai terlihat. Apakah ninja elit bernama Neji? Atau si gagal Naruto? Naruto dan Neji saling berhadapan di pertarungan pertama dalam babak utama tes terakhir ujian seleksi Chuunin! Naruto terkena pukulan langsung dari Neji, si jenius yang memikul beban juuin! Sekarang tiba saatnya untuk menyelesaikan semuanya!!	\N	6	0	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1716986633i/213980305.jpg	{}	{}	2025-03-17 19:09:18.172	2025-03-17 19:09:17.493
275	6493574	Novel memukau yang membangkitkan optimisme ini adalah karya terbaik Ernest Hemingway, pengarang legendaris Amerika dan pemenang Hadiah Nobel Sastra 1954, sekaligus novel terakhirnya yang terbit semasa hidupnya.\n\nLelaki Tua dan Laut (The Old Man and the Sea) berkisah tentang perjuangan luar biasa seorang nelayan tua Kuba yang seorang diri berusaha menangkap ikan marlin raksasa jauh di laut lepas setelah sebelumnya gagal menangkap seekor ikan pun selama 84 hari dan persahabatannya dengan seorang anak lelaki. Perjuangan pantang menyerah sang lelaki tua dalam mencapai tujuannya mengajarkan kepada kita betapa kesabaran, ketabahan, dan kegigihan dalam mengarungi cobaan hidup tak akan berakhir sia-sia.\n\nNovel yang asyik dibaca ini ditulis Hemingway saat tinggal di Kuba dan berhasil menyabet Hadiah Pulitzer 1953 untuk kategori fiksi serta Award of Merit Medal for Novel dari American Academy of Letters, sekaligus mengantarkannya meraih Hadiah Nobel Sastra. Sedemikian populernya novel menyentuh ini sehingga berkali-kali difilmkan dan terus dibaca orang di berbagai penjuru dunia hingga saat ini.	\N	1227463	44276	1952-09-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1243229870i/6493574.jpg	{}	{}	2025-02-05 16:01:11.965	2025-02-05 16:01:11.742
276	19277381	The Tao te Ching of Lao Tzu is among the wisest books ever written and one of the greatest gifts ever given to humankind. In the handful of pages that make up the Tao te Ching, there is an answer to each of life’s questions, a solution to every predicament, a balm for any wound. It is less a book than a living, breathing angel. \n \nBrian Browne Walker’s contemporary translations of Taoist classics have received high marks for their simplicity, clarity, and accessibility. This elegant ebook has been designed to mirror the beautiful look of the original paper edition, and will be a beloved companion for years to come.	\N	170123	8517	0351-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1386469951i/19277381.jpg	{}	{}	2025-02-05 15:59:44.743	2025-02-05 15:59:44.063
277	7478330	¿Johan tiene doble personalidad? ¿Es una especie de Jeckyll y Hyde? Tenma recurre al Dr. Gillen, toda una autoridad en psicología criminal, para que psicoanalice a Johan. Sin embargo, el Dr. Gillen concluye en secreto que es Tenma, y no Johan, quien ha cometido los crímenes, e intenta tenderle una trampa para realizar unos experimentos con él.\n\n¡Ahora Tenma está verdaderamente acorralado!\n\nKarl, un estudiante de la Universidad de Múnich, visita cada semana a un multimillonario ciego para leerle libros y así poder pagar sus estudios, Un día, conoce a un joven que hacía su mismo trabajo en casa del multimillonario. Su nombre es.. ¡Johan! Desde ese momento, a Karl empiezan a sucederle cosas extrañas y... ¿quién es ese joven llamado Johan? ¿Es el Johan que conocemos?	\N	4806	268	2008-02-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1262473115i/7478330.jpg	{}	{}	2025-02-05 16:00:55.87	2025-02-05 16:00:55.195
278	36342984	Nasruddin Hodja adalah figur legendaris, seorang sufi bijak yang banyak melontarkan pernyataan aneh pemancing tawa namun sekaligus mengandung teka-teki. Manuskrip berisi kisah-kisah humor Nasruddin pertama kali terbit tahun 1571. Adapun 200 kisah dalam buku ini akan membuat kita tersenyum sambil merenung-renung, betapa Nasruddin menggunakan logika berpikir yang tidak lazim.	\N	23	2	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1506972790i/36342984.jpg	{}	{}	2025-02-08 15:19:56.006	2025-02-08 15:19:55.388
279	59962187	最凶死刑囚、ORDER、坂本商店、出会った瞬間に始まる殺仕合!!　緊迫のバトルが各所で展開する中、坂本の身にある異変が…!?　裏で全てを糸引く「×」の真の狙いが明らかになる時、殺し屋たちに激震が走る!!	\N	1660	136	2022-03-04	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1646514611i/59962187.jpg	{}	{}	2025-02-08 15:20:15.899	2025-02-08 15:20:15.262
280	40727118	After a year spent trying to prevent a catastropic war among the Greek gods, Percy Jackson finds his seventh-grade school year unnervingly quiet. His biggest problem is dealing with his new friend, Tyson--a six-foot-three, mentally challenged homeless kid who follows Percy everywhere, making it hard for Percy to have any "normal" friends.\n\nBut things don't stay quiet for long. Percy soon discovers there is trouble at Camp Half-Blood: The magical borders which protect Half-Blood Hill have been poisoned by a mysterious enemy, and the only safe haven for demigods is on the verge of being overrun by mythological monsters. To save the camp, Percy needs the help of his best friend, Grover, who has been taken prisoner by the Cyclops Polyphemus on an island somewhere in the Sea of Monsters--the dangerous waters Greek heroes have sailed for millenia--only today, the Sea of Monsters goes by a new name...the Bermuda Triangle.\n\nNow Percy and his friends--Grover, Annabeth, and Tyson--must retrieve the Golden Fleece from the Island of the Cyclopes by the end of the summer or Camp Half-Blood will be destroyed. But first, Percy will learn a stunning new secret about his family--one that makes him question whether being claimed as Poseidon's son is an honor or simply a cruel joke.	\N	1274954	53793	2006-04-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1530819367i/40727118.jpg	{}	{}	2025-02-10 10:17:24.065	2025-02-10 10:17:23.404
281	120561373	Kill some time with former hit man Taro Sakamoto!\n\nTaro Sakamoto was once a legendary hit man considered the greatest of all time. Bad guys feared him! Assassins revered him! But then one day he quit, got married, and had a baby. He’s now living the quiet life as the owner of a neighborhood store, but how long can Sakamoto enjoy his days of retirement before his past catches up to him?!	\N	1513	102	2022-06-03	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1681539021i/120561373.jpg	{}	{}	2025-02-12 10:18:18.413	2025-02-12 10:18:17.747
282	125536698	Le concours d’entrée de la JCC bat son plein ! Pour la troisième épreuve, les candidats participeront à un “tail tag” par équipes. À cette occasion, ils sont rejoints par trois nouveaux arrivants, qui semblent étrangement plus forts que la moyenne. Lors de la constitution des groupes, le hasard veut que Sakamoto et Shin se retrouvent dans des équipes différentes. Shin, bien décidé à progresser par lui-même, prend alors une décision difficile…	\N	1404	113	2022-08-04	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1680764088i/125536698.jpg	{}	{}	2025-02-15 18:17:05.122	2025-02-15 18:17:04.487
283	5502895	Catatan dari Bawah Tanah membisikan suara manusia yang telah menarik diri dari lingkungan masyarakat setelah mengorbankan cinta dan bakatnya. Karya sastra yang menyoroti relung-relung kejiwaan secara falsafi ini menampilkan tokoh seorang pemuda yang peka, yang merasakan penolakan dari lingkungan kehidupannya, padahal ia merasa lebih unggul dalam intelegensia. Karena kehilangan daya untuk mencintai dan dicintai, ia pun mengobarkan cita-citanya dengan tujuan despotisme.	\N	193013	16863	1864-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1491885007i/5502895.jpg	{}	{}	2025-02-16 04:46:51.872	2025-02-16 04:46:51.743
284	23522	The world-renowned classic that has enthralled and delighted millions of readers with its timeless tales of gods and heroes.\n\nEdith Hamilton's Mythology succeeds like no other book in bringing to life for the modern reader the Greek, Roman, and Norse myths that are the keystone of Western culture--the stories of gods and heroes that have inspired human creativity from antiquity to the present. We meet the Greek gods on Olympus and Norse gods in Valhalla. We follow the drama of the Trojan War and the wanderings of Odysseus. We hear the tales of Jason and the Golden Fleece, Cupid and Psyche, and mighty King Midas. We discover the origins of the names of the constellations. And we recognize reference points for countless works of art, literature, and cultural inquiry--from Freud's Oedipus complex to Wagner's Ring Cycle of operas to Eugene O'Neill's Mourning Becomes Electra. Praised throughout the world for its authority and lucidity, Mythology is Edith Hamilton's masterpiece--the standard by which all other books on mythology are measured.	\N	57930	3454	1942-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1305000423i/23522.jpg	{}	{}	2025-02-18 04:43:28.327	2025-02-18 04:43:27.677
285	209759573	Kelompok Naruto berpartisipasi dalam ujian seleksi Chuunin atas rekomendasi Guru Kakashi! Sebelum sampai ke tempat ujian, ada seseorang yang menantang Sasuke. Inikah pertanda akan terwujudnya suatu hal yang mengerikan? Kemudian tes kedua ujian seleksi Chuunin pun dimulai!! Naruto dan teman-teman terlibat dalam pertarungan merebut gulungan di hutan yang mengerikan. Namun, ada sesuatu yang tak jelas asalnya mulai bergerak di balik ujian ini. Bagaimana kelanjutan ujian yang mempertaruhkan nyawa para pesertanya ini!?	\N	9	1	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1710230007i/209759573.jpg	{}	{}	2025-02-20 15:39:57.926	2025-02-20 15:39:57.225
286	123014503	Novel ini bercerita tentang seorang guru bernama Alexei Ivanovich yang bekerja untuk seorang jenderal Rusia yang dulunya kaya raya. Sebuah gambaran kecanduan seorang pemuda terhadap judi, demi memenangkan hati wanita yang dicintainya. Sebagai karya semi-otobiografi, Dostoevsky sendiri menyelesaikan novel ini dalam waktu yang sangat singkat untuk melunasi hutang judinya.	\N	105591	7064	1866-03-10	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1677417890i/123014503.jpg	{}	{}	2025-02-22 18:24:59.763	2025-02-22 18:24:59.079
287	216950278	SEBUAH BUKU BESTSELLER UNTUK ANDA YANG MENGINGINKAN KEKUASAAN, MENGAMATI KEKUASAAN, ATAU INGIN MEMPERSENJATAI DIRI MELAWAN KEKUASAAN.\n\nKarya cemerlang ini menyaring tiga ribu tahun sejarah kekuasaan menjadi 48 Hukum yang relevan sepanjang zaman. Sebuah karya referensial yang layak dibaca dan dimiliki.\n\n“Buku ini membantu Anda menyusun rencana menuju puncak kekuasaan.”\n—Daily Express\n\nPenulis telah menyusun garis besar hukum kekuasaan secara tajam, menggabungkan filsafat Machiavelli, Sun-tzu, Carl von Clausewitz, dan banyak\npemikir besar lainnya. Berhati-hatilah karena KEKUASAAN tanpa KEBIJAKSANAAN akan berujung pada KEHANCURAN.\n\n“Namun jangan ditelan mentah-mentah. Nanti kalau muncul seorang pemimpin seperti gambaran Robert Greene, kita tidak akan bisa membaca buku seperti ini lagi.”\n\n— A. Setyo Wibowo, Pengajar Filsafat di STF Driyarkara	\N	200463	10547	1998-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1722247923i/216950278.jpg	{}	{}	2025-02-23 04:42:27.798	2025-02-23 04:42:27.095
288	3366169	Veronika Memutuskan Mati adalah novel tentang pencarian makna hidup dalam masyarakat yang terbelenggu rutinitas tanpa jiwa dan takluk terhadap tekanan sosial. Dengan tokoh utama Veronika, seorang gadis yang berusaha bunuh diri, Paulo Coelho mengisahkan individu-individu rapuh yang terlempar ke rumah sakit jiwa karena hasrat, impian, dan sikap hidup mereka berbeda dengan yang dianggap normal oleh masyarakat.	\N	232714	11882	1998-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1212119689i/3366169.jpg	{}	{}	2025-03-01 10:34:56.872	2025-03-01 10:34:56.238
289	13619	Light thinks he's put an end to his troubles with the FBI—by using the Death Note to kill off the FBI agents working the case in Japan! But one of the agents has a fiancée who used to work in the Bureau, and now she's uncovered information that could lead to Light's capture. To make matters worse, L has emerged from the shadows to work directly with the task force headed by Light's father. With people pursuing him from every direction, will Light get caught in the conflux?	\N	54065	1968	2004-07-02	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1419952210i/13619.jpg	{}	{}	2025-03-02 10:04:15.68	2025-03-02 10:04:14.936
290	130827852	The desert planet Arrakis, called Dune, has been destroyed. Now the Bene Gesserit, heirs to Dune's powers, have colonized a green world and are turning it into a desert, mile by scorched mile. In this, the final book in the Dune Chronicles, Herbert again creates a world of breathtakingly evolved characters and the contexts in which to appreciate them. The richness of detail and perspective fascinates, while the multi-layered plot evolves as pages turn. Riveting from end to end, the legend lives on in the greatest science fiction epic of all time.	\N	76714	2954	1985-04-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1695830789i/130827852.jpg	{}	{}	2025-03-03 10:20:45.765	2025-03-03 10:20:45.052
291	156022798	Durant l'examen d'entrée de la JCC, Shin pense se battre contre Shinaya quand, en réalité, c'est Gaku qu'il affronte ! Voyant son comagnon blessé par les manigances du subordonné de Slur, Sakamoto ne peut s'empêcher d'iintervenir, plus remonté que jamais ! Pour Sakamoto et Shin, il est temps den finir avec cet examen d'entrée riche en coups fourrés, afin de récupérer les informations de Slur !	\N	1284	88	2022-11-04	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1690831624i/156022798.jpg	{}	{}	2025-03-03 14:39:42.045	2025-03-03 14:39:41.895
292	10256033		\N	14	3	1972-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1295367341i/10256033.jpg	{}	{}	2025-03-03 14:39:28.017	2025-03-03 14:39:27.383
293	63002195	JCCでデータバンクに関する情報を探る坂本たち。シンは秘密を知ると思われる教師との“真剣勝負”に突入する!!　一方の坂本は、×と繋がる少年・周と対峙するが…!?　×の謀略がJCCを未曾有の危機に陥れる!!	\N	1212	80	2023-02-03	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1674681410i/63002195.jpg	{}	{}	2025-03-08 19:32:48.18	2025-03-08 19:32:47.55
294	210636617	"Sasuke pasti mencariku." Orochimaru meninggalkan kalimat penuh misteri itu dan menghilang dari hadapan kelompok Naruto... Lalu, Sasuke yang berada di bawah pengaruh segel pemberian Orochimaru mengalahkan ninja dari Oto. Apa tujuan Orochimaru!? Sementara ujian seleksi Chuunin terus berjalan. Naruto dan teman-temannya akhirnya berhasil lulus `tes kedua` dan melanjutkan ke `tes ketiga`. Tapi, ternyata ada babak penyisihan sebelum `tes ketiga` dan Kabuto mengundurkan diri bahkan sebelum memulai...! Dengan peserta berjumlah 20 orang, layar pertunjukan pertarungan individual satu lawan satu telah dinaikkan...!!	\N	7	0	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1712030937i/210636617.jpg	{}	{}	2025-03-08 19:33:18.005	2025-03-08 19:33:17.368
298	1910412	Jakarta selama bulan-bulan setelah Proklamasi Kemerdekaan Indonesia tanggal 17 Agustus 1945, adalah kota yang dicekam ketegangan. Ketegangan antara kelompok pemuda-pemuda pejuang kemerdekaan dengan berbagai kesatuan tentara Jepang yang menunggu-nunggu kedatangan tentara sekutu, karena pemuda-pemuda pejuang kemerdekaan sedang asik mengumpulkan persenjataan dari pasukan-pasukan Jepang, dan juga ketegangan dalam hati seluruh rakyat Indonesia mengenai siapakah yang akan datang pertama dari tentara Sekutu, tentara Inggris, atau Belanda? Itulah "setting" Jalan Tak Ada Ujung ini, yang mengisahkan pejuang-pejuang seperti Hazil, pemusik yang bersemangat berapi-api, Guru Isa yang lembut hati dan tidak suka pada kekerasan, istrinya yang merindukan kasih lelaki. Perlawanan terhadap tentara Belanda yang hendak menjajah Indonesia, kehangatan cinta, semangat berkorbar perjuangan, ketakutan, kejahatan manusia terhadap manusia, penemuan diri di bawah siksaan, dan kemenangan manusia dalam pergaulan dengan dirinya sendiri, kekejaman peperangan…. Senua ini dapat ditemukan dalam novel ini.	\N	1354	190	1952-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1377676837i/1910412.jpg	{}	{}	2025-03-12 15:11:18.083	2025-03-12 15:11:17.462
299	123356850		\N	0	0	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1697681390i/123356850.jpg	{}	{}	2025-03-12 18:31:44.067	2025-03-12 18:31:43.431
300	212344651	Babak penyisihan ‘tes ketiga’, turnamen pertarungan individual 20 orang peserta diawali dengan ketegangan! Pertama, kemenangan Sasuke dan Shino serta Kankurou, pertarungan Ino vs Sakura pun mencapai klimaksnya. Bagaimana dengan Naruto!? Dan turnamen pun semakin memanas! Lawan tanding Gaara dalam pertarungan adalah Lee. Lee melawan Gaara, si pengendali pasir dalam guci, hanya dengan memakai taijutsu yang telah dilatihnya dengan keras! Dengan memakai taijutsu berlevel tinggi, Lee dapat mendesak Gaara, tapi…	\N	6	0	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1714444192i/212344651.jpg	{}	{}	2025-03-13 09:59:06.357	2025-03-13 09:59:05.713
301	199310942	El cerco de L se ha cerrado tanto que Light ha tenido que buscar una salida a su papel de Kira. Al renunciar a Ryuk y al Cuaderno de Muerte olvida todo lo que ha pasado, pero L sigue sospechando de él… ¡y de repente el Cuaderno de Muerte vuelve a la acción! ¿Quién lo controla ahora?	\N	0	0	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1696688527i/199310942.jpg	{}	{}	2025-03-15 08:08:19.054	2025-03-15 08:08:18.364
302	2671839	El cuartel general de investigaciones discute qué hacer ante la aparición de un segundo Kira; en ese momento, L sugiere que Light se incorpore al mismo en calidad de ayudante. ¡Es allí donde Light descubre la verdadera intención oculta en el mensaje mandado por el falso Kira y sopesa posibles maneras de entrar en contacto con él...!\n\nLight Yagami es un empollón. Pero su vida da un vuelco cuando encuentra una libreta con el misterioso título Death Note en la portada y recibe la vista de un shinigami, quien le explica que la libreta sirve para matar a todo aquel cuyo nombre sea escrito en ella. A partir de entonces, Light utilizará la libreta para dar cuenta de cuanto criminal o espíritu maligno le pase por delante. Pero pronto sus actividades comenzarán a llamar la atención de la policía y otros investigadores.	\N	40348	1404	2004-11-04	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1299363144i/2671839.jpg	{}	{}	2025-03-15 08:06:18.829	2025-03-15 08:06:18.148
303	5998606	Tras la detenció de Misa, el acorralado Light propone ser encerrado voluntariamente. ¡Y le comunica a Ryuk que abandona en Cuaderno de muerte! ¿Qué es lo que tiene Light en mente...? Más tarde, justo cuando parecía que los asesinos habían cesado de una vez por todas, ¡Kira vuelve a sus siniestras andadas!\n\nLight Yagami es un empollón. Pero su vida da un vuelco cuando encuentra una libreta con el misterioso título Death Note en la portada y recibe la vista de un shinigami, quien le explica que la libreta sirve para matar a todo aquel cuyo nombre sea escrito en ella. A partir de entonces, Light utilizará la libreta para dar cuenta de cuanto criminal o espíritu maligno le pase por delante. Pero pronto sus actividades comenzarán a llamar la atención de la policía y otros investigadores.	\N	31172	1205	2005-02-04	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1299363280i/5998606.jpg	{}	{}	2025-03-15 08:07:30.06	2025-03-15 08:07:29.363
304	201296872	ORDER・キンダカと共に要人の警護に挑む、若き日の坂本、南雲、赤尾、そして有月!! 毒使いの攻撃で仲間たちに危機が迫る中、坂本は!? 一方、キンダカ殺害の密命に苦悩する有月…悲劇の歯車が回り始める!!\n\n「この一局、私が勝ったら田中さんに告白します」いつでも真っ直ぐ全力少女・凛が最後の大勝負に出る…!?	\N	668	43	2023-11-02	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1709346361i/201296872.jpg	{}	{}	2025-03-15 17:15:42.691	2025-03-15 17:15:42.054
305	50204647		\N	21	1	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1563939297l/50204647.jpg	{}	{}	2025-03-15 17:18:26.636	2025-03-15 17:18:25.977
306	38275355	Death Note é um mangá sobre um estudante do ensino médio que descobre um caderno sobrenatural que o permite matar qualquer pessoa ao escrever o nome dela no caderno enquanto tem em mente seu rosto. A história da série conta as tentativas do personagem Light Yagami em criar e liderar um mundo livre de maldades usando o caderno e diversos conflitos acontecem devido às ações do jovem, incluindo a investigação pelo maior detetive do mundo, L\n\nCriado pela dupla Tsugumi Ohba (roteiro) e Takeshi Obata (arte), os seis volumes que compõem a série foram lançados em português pela JBC. Este sétimo volume é uma verdadeira enciclopédia do mangá e inclui biografia de personagens, resumo da linha temporal da história, entrevista com os criadores, notas e comentários de produção, extras e a história piloto da série. Basicamente, tudo o que um fã da história gostaria de saber. As biografias dos personagens são tão detalhadas (e muito bem ilustradas) que poderiam ser chamados de dossiês. E, ao contrário do que se imagina, inclui mais que somente os personagens centrais da trama: estão presentes todos os shinigamis, os policiais, os oficiais e, além de revelar o nome do misterioso detetive, ainda faz uma descrição de seus terríveis hábitos alimentares e o conteúdo de seu estômago. Takeshi Obata aparece numa das seções de entrevistas com o processo de criação de personagens e storyboard, com diversos rascunhos feitos pelo artista. Ohba conta detalhes de como criava a trama e uma entrevista conjunta detalha como foi o processo de criação da dupla. E, mesmo se alguém nunca ouviu falar do mangá, Death Note Black Edition How to Read 7 oferece algo essencial: dentro desta enciclopédia há o “Mangá Piloto” feito em 2003. Uma história que introduziu o conceito da trama de uma forma meio assustadora, mas interessante e agradável.	\N	9472	294	2006-10-13	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1518180048i/38275355.jpg	{}	{}	2025-03-15 19:25:13.687	2025-03-15 19:25:13.064
307	160068	Osamu Tezuka's vaunted storytelling genius, consummate skill at visual expression, and warm humanity blossom fully in his eight-volume epic of Siddhartha's life and times. Tezuka evidences his profound grasp of the subject by contextualizing the Buddha's ideas; the emphasis is on movement, action, emotion, and conflict as the prince Siddhartha runs away from home, travels across India, and questions Hindu practices such as ascetic self-mutilation and caste oppression. Rather than recommend resignation and impassivity, Tezuka's Buddha predicates enlightenment upon recognizing the interconnectedness of life, having compassion for the suffering, and ordering one's life sensibly. Philosophical segments are threaded into interpersonal situations with ground-breaking visual dynamism by an artist who makes sure never to lose his readers' attention.\n\nTezuka himself was a humanist rather than a Buddhist, and his magnum opus is not an attempt at propaganda. Hermann Hesse's novel or Bertolucci's film is comparable in this regard; in fact, Tezuka's approach is slightly irreverent in that it incorporates something that Western commentators often eschew, namely, humor.	\N	2928	93	1983-08-11	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1320556637i/160068.jpg	{}	{}	2025-03-16 20:01:25.117	2025-03-16 20:01:24.434
309	216356522	Bersama Kakashi, Sasuke muncul di arena ujian Chuunin. Pertarungan Sasuke melawan Gaara tak bisa dihindari. Sasuke yang sudah memusatkan latihannya di Taijutsu mampu meningkatkan kecepatannya berlipat ganda hingga bisa menembus pertahanan ‘sempurna’ Gaara dan melumpuhkannya... Sementara itu, Orochimaru berhadapan dengan Hokage Ketiga dan bermaksud menghabisinya dengan mengendalikan yang sudah meninggal. Mampukah Orochimaru mengalahkan Hokage Ketiga...!?	\N	6	0	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1720676318i/216356522.jpg	{}	{}	2025-03-18 10:02:23.519	2025-03-18 10:02:22.91
310	217312432	Sasuke menghadapi Gaara yang berubah wujud mengerikan dengan jurus terlarang Chidori hingga roboh akibat kekuatan segel gaib. Namun, Naruto dan yang kawan-kawan berhasil menyusul dan menyelamatkan Sasuke. Sementara itu, pertarungan sampai mati yang sengit antara Orochimaru dan Hokage mendekati akhir. Dan, penghancuran Konoha pun berakhir sudah!	\N	6	0	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1723168786i/217312432.jpg	{}	{}	2025-03-18 10:02:41.334	2025-03-18 10:02:41.216
311	218425086	Naruto yang memulai perjalanan latihan dengan Jiraiya, didatangi pengunjung yang mengerikan. Apa tujuan Itachi, kakak Sasuke, dan Kisame Hoshigaki!? Mereka berdua bermaksud membawa serta Naruto yang berdiri kaku. Namun saat itu, Sasuke datang bersama amukan badai! Sementara itu Tanzakujou bergetar!! Tsunade bertemu Orochimaru dan kini berada dalam keadaan terjepit. Orochimaru mengajukan sebuah syarat jika Tsunade mau menyembuhkan lengannya yang cedera. Namun, muncul Jiraiya dan Naruto di hadapan Tsunade yang mulai goyah. Dan pilihan Tsunade adalah .…	\N	6	0	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1725353745i/218425086.jpg	{}	{}	2025-03-18 10:01:51.956	2025-03-18 10:01:51.8
312	561456	It's not everyday you find yourself in combat with a half-lion, half-human.\n\nBut when you're the son of a Greek god, it happens. And now my friend Annabeth is missing, a goddess is in chains and only five half-blood heroes can join the quest to defeat the doomsday monster.\n\nOh, and guess what? The Oracle has predicted that not all of us will survive...	\N	1150916	44437	2007-05-05	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1361038385i/561456.jpg	{}	{}	2025-03-18 16:30:47.637	2025-03-18 16:30:46.984
313	7347940	Johan se ha ganado la confianza de Schuwald, la persona más influyente de la región de Baviera. Ahora, es su mano derecha- ¿Pretende aparecer en el mundo económico germano como una joven promesa?\n\nMientras, Richard, un detective privado, recibe un encargo de Schuwald, y mientras investiga los extraños acontecimientos alrededor del mismo, percibe algo enorme y malvado tras ellos. Entonces, empieza a luchar contra alguien tan espantoso como un monstruo, pero... ¿alguna vez saldrán a la luz las maquinaciones de Johan?\n\nAl saber que Tenma quiere quitarle la vida, Johan se dedica a llevar una vida tranquila. Sin embargo, de pronto estalla a llorar y pierde el sentido. ¿Qué diablos es ese libro checo?	\N	4017	231	2008-03-28	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1261078917i/7347940.jpg	{}	{}	2025-03-19 09:05:33.229	2025-03-19 09:05:33.114
314	226830599	Umat manusia takkan berhasil masuk ke era baru setelah berhadapan dengan krisis pada akhir abad lalu yang hampir memusnahkan mereka… jika bukan berkat “mereka”. Pada tahun 1969, “mereka” yang masih anak-anak, menciptakan sebuah simbol. Pada tahun 1997, seiring mulai terlihatnya pertanda bencana yang mendekat, simbol itu bangkit kembali. Ini adalah kisah tentang beberapa anak laki-laki yang akan menyelamatkan dunia.	\N	5095	488	2016-01-29	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1738745878i/226830599.jpg	{}	{}	2025-03-19 09:05:09.139	2025-03-19 09:05:08.458
315	220343453	Ternyata yang menguatkan kembali hati Tsunade yang galau adalah Naruto. Naruto, Jiraiya, dan Shizune tiba tepat di saat Tsunade hampir dikalahkan Orochimaru dan Kabuto. Tsunade pun akhirnya pulang ke desa sebagai Hokage Kelima! Sebelum upacara pengangkatan, Tsunade mengobati Kakashi, Sasuke, dan yang lainnya terlebih dahulu. Lalu, Sasuke yang baru saja sadar tiba-tiba menantang Naruto. Apa yang terjadi?	\N	6	0	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1728706022i/220343453.jpg	{}	{}	2025-03-20 16:52:37.83	2025-03-20 16:52:37.176
316	221294411	Sasuke meninggalkan teman-temannya dan keluar dari Konoha. Lalu, atas perintah Hokage Kelima, Shikamaru yang kini sudah berstatus Chuunin, mengumpulkan Naruto, Neji, Kiba, dan Chouji untuk mengejar Sasuke. Mereka pun harus menghadapi para Ninja Oto. Kemudian, Chouji bertarung melawan Jiroubou dan memenangkan pertarungan itu, namun dia sendiri pun roboh. Kini giliran Neji harus berhadapan dengan Kidoumaru, si pengendali jaring laba-laba dengan ’Byakugan’-nya!	\N	5	0	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1730960700i/221294411.jpg	{}	{}	2025-03-20 16:52:20.112	2025-03-20 16:52:19.948
317	222355245	Saat Naruto dan kawan-kawannya mengira sudah berhasil mendapatkan peti mati tempat Sasuke tertidur, muncul musuh baru yang bernama Kimimaro. Naruto VS Kimimaro, Shikamaru VS Tayuya, serta Kiba dan Akamaru VS Sakon. Tiga pertarungan sampai mati pun dimulai! Lalu, di tengah pertarungan mati-matian antara Naruto dan Kimimaro, peti mati tempat Sasuke tertidur meledak! Apa yang terjadi? Wahai orang-orang yang penuh semangat... perhatikan pertarungan ini!	\N	3	0	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1733626037i/222355245.jpg	{}	{}	2025-03-20 16:52:00.75	2025-03-20 16:52:00.078
318	223121338	Sasuke menginginkan ‘kekuatan’ yang lebih besar. Ia pun membuang teman-temannya dan pergi menuju tempat Orochimaru. Naruto bermaksud membawa pulang Sasuke dengan paksa, namun ia berhadapan dengan Sasuke yang penuh tekad membunuh. Ternyata Sasuke ingin membangkitkan kemampuan Bola Mata Mangekyou Sharingan. Dan agar bisa membangkitkan kekuatan itu, syaratnya harus membunuh teman terdekatnya! Apa yang akan terjadi di antara Naruto dan Sasuke yang keduanya sama-sama bisa membangkitkan kemampuan Bola Mata Mangekyou Sharingan!?	\N	3	0	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1735618487i/223121338.jpg	{}	{}	2025-03-20 18:30:59.912	2025-03-20 18:30:59.228
319	34697857	Malam Putih dituturkan melalui sudut pandang orang pertama anonim. Selain menyuguhkan kisah cinta, di dalam buku ini Dostoevsky juga menggali serta melukiskan dengan begitu indah dan jernih kondisi manusia yang teralienasi dari lingkungan sosialnya. Kita dapat melihat bagaimana keterasingan membuat manusia mengalami kesulitan dalam mengaktualisasikan dirinya sendiri.\nLewat narator cerita—dan lewat sudut pandang orang pertama anonim yang digunakan Dostoevsky dalam menuturkan kisah ini—pembaca secara tidak langsung akan menempatkan diri sebagai tokoh utama dan ikut merasakan bagaimana nelangsanya upaya seseorang dalam mencari cinta, persahabatan, kebahagian, atau bahkan pelipur lara ketika penderitaan menjadi sesuatu yang niscaya dan tak terhindarkan, sementara tak ada siapa pun yang dapat diandalkan selain dirinya sendiri.	\N	259126	32632	1848-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1490602758i/34697857.jpg	{}	{}	2025-03-22 12:38:35.968	2025-03-22 12:38:35.305
320	228496880	Di akhir pertarungan yang sengit dalam misi membawa pulang Sasuke ke Desa Konoha, Naruto berhasil mengatasi pertarungan itu namun dia tak mampu membawa Sasuke kembali bersamanya. Dua tahun sudah berlalu sejak peristiwa itu... Latihan dengan Jiraiya pun sudah selesai dan Naruto yang terlihat gagah pulang ke desa Konohagakure!! Di saat Naruto punya waktu luang untuk reuni bersama teman-teman yang dirindukannya, cengkeraman jahat `Akatsuki` membayangi Gaara yang sudah menjadi Kazekage!! Simak juga "KAKASHI`S SIDE STORY - A BOY`S LIFE ON THE BATTLEFIELD" yang menceritakan tentang masa muda Kakashi.	\N	2	0	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1740625859i/228496880.jpg	{}	{}	2025-03-23 17:22:36.129	2025-03-23 17:22:35.387
321	223441713	Ale, seorang pria berusia 37 tahun memiliki tinggi badan 189 cm dan berat 138 kg. Badannya bongsor, berkulit hitam, dan memiliki masalah dengan bau badan. Sejak kecil, Ale hidup di lingkungan keluarga yang tidak mendukungnya. Ia tak memiliki teman dekat dan menjadi korban perundungan di sekolahnya.\nAle didiagnosis psikiaternya mengalami depresi akut. Bukannya Ale tidak peduli untuk memperbaiki dirinya sendiri, ia peduli. Ale telah berusaha mengatasi masalah-masalah yang timbul dari dirinya agar ia diterima di lingkungan pertemanan. Namun usahanya tidak pernah berhasil. Bahkan keluarganya pun tidak mendukungnya saat Ale membutuhkan sandaran dan dukungan.\n\nAtas itu semua, Ale memutuskan untuk mati. Ia mempersiapkan kematiannya dengan baik. Agar ketika mati pun, Ale tidak banyak merepotkan orang. Dua puluh empat jam dari sekarang, ia akan menelan obat antidepresan yang dia punya sekaligus. Sebelum waktu itu tiba, Ale membersihkan apartemennya yang berantakan, makan makanan mahal yang tak pernah ia beli, pergi berkaraoke dan menyanyi sepuasnya hingga mabuk.\n\nSaat 24 jam itu tiba, Ale telah bersiap dengan kemeja hitam dan celana hitam, bak baju melayat ke pemakamannya sendiri. Ia kenakan topi kecurut ulang tahun dan meletuskan konfeti yang ia beli untuk dirinya sendiri.\n“Selamat ulang tahun yang terakhir, Ale.”\n\nAle siap menenggak seluruh obat antidepresan yang ia punya. Saat ia memain-mainkan botolnya, Ale terdiam saat membaca anjuran di kemasan botol itu, dikonsumsi sesudah makan. Seketika perutnya berbunyi. Dan Ale pun memutuskan untuk makan dulu sebelum mengakhiri hidupnya. Setidaknya, itu akan menjadi satu-satunya keputusan yang bisa dia ambil atas kehendaknya sendiri. Setelah selama hidupnya ia tak pernah mampu melakukan hal-hal yang ia inginkan.\n\nAle akan makan seporsi mie ayam sebelum mati.	\N	151	50	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1736474633i/223441713.jpg	{}	{}	2025-03-26 03:42:29.95	2025-03-26 03:42:29.259
322	220343453	Ternyata yang menguatkan kembali hati Tsunade yang galau adalah Naruto. Naruto, Jiraiya, dan Shizune tiba tepat di saat Tsunade hampir dikalahkan Orochimaru dan Kabuto. Tsunade pun akhirnya pulang ke desa sebagai Hokage Kelima! Sebelum upacara pengangkatan, Tsunade mengobati Kakashi, Sasuke, dan yang lainnya terlebih dahulu. Lalu, Sasuke yang baru saja sadar tiba-tiba menantang Naruto. Apa yang terjadi?	\N	6	0	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1728706022i/220343453.jpg	{}	{}	2025-04-12 02:04:27.438	2025-04-12 02:04:27.267
323	29499024	Naruto is a young shinobi with an incorrigible knack for mischief. He’s got a wild sense of humor, but Naruto is completely serious about his mission to be the world’s greatest ninja!\n\nNaruto’s friends are tested as an attempt to overthrow Tsunade begins and they must all fight—or fall. Pain commences with the final destruction of Konoha, and Naruto and the Toads prepare to take him on in battle. Naruto inches ever closer to discovering Pain’s true identity, but is it worth it now that he’s morphing into the dreaded Nine Tails? Then, an unexpected confession reveals incredible secrets about his past as Naruto prepares for the ultimate battle with Pain. Can the chakra-challenged Naruto win when one misstep could spell disaster?	\N	278	20	2016-10-04	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1466946842i/29499024.jpg	{}	{}	2025-04-04 15:59:05.479	2025-04-04 15:59:05.293
324	8072727	Había una vez un monstruo sin nombre, que se moría por conseguir uno. Así que decidió salir de viaje a ver si encontraba un nombre. "¿Por qué esta extraña historia checa para niños ha descentrado tanto a Johan? ¿Es posible que encontremos en ese libro alguna pista sobre el misterio de su nacimiento? Un misterio oculta otro misterio. Tenma intenta colarse en Chequia para buscar a la madre de Johan. Un policía fronterizo le descubre, pero logra escapar con la ayuda de Grimmer, un periodista autónomo. Los dos hombres parten sin preguntarse uno a otro qué les ha llevado hasta Chequia. De hecho, Grimmer también está muy interesado en el kinderheim 511 de la Alemania del Este. Ahora la historia pasa a tener lugar en Praga.	\N	3592	185	2008-04-26	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1271860333i/8072727.jpg	{}	{}	2025-03-27 19:53:39.007	2025-03-27 19:53:38.339
325	58261259	Buku ini memuat antologi cerita dari pengarang perempuan Amerika, antara lain:\n\nCharlotte Perkins Gilman - The Yellow\nWallpaper\nEdith Wharton - Roman Fever\nFlannery O'Connor - A Good Man is Hard to Find\nKate Chopin - Story of an Hour\nLouisa May Alcott - The Piggy Girl\nPearl S. Buck - Christmas Day In The Morning\nShirley Jackson - The Lottery\nSylvia Plath - Johnny Panic and the Bible of Dreams\nWilla Cather - A Wagner Matinée	\N	17	7	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1622840537i/58261259.jpg	{}	{}	2025-03-29 02:32:56.723	2025-03-29 02:32:56.565
326	8130423	Percy Jackson isn't expecting freshman orientation to be any fun. But when a mysterious mortal acquaintance appears at his potential new school, followed by demon cheerleaders, things quickly move from bad to worse.\nIn this fourth installment of the blockbuster series, time is running out as war between the Olympians and the evil Titan lord Kronos draws near. Even the safe haven of Camp Half-Blood grows more vulnerable by the minute as Kronos's army prepares to invade its once impenetrable borders. To stop the invasion, Percy and his demigod friends must set out on a quest through the Labyrinth - a sprawling underground world with stunning surprises at every turn.	\N	1166213	39131	2008-03-06	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1355333381i/8130423.jpg	{}	{}	2025-03-29 13:00:25.894	2025-03-29 13:00:25.231
327	8857716	“TAN MALAKA’S NAAR DE ‘REPUBLIEK INDONESIA’ - A Trans- lation and Commentary” is a reprint of a book of the same title that was published in Japan in 1996. This book is to ‘re- patriate’ a work from China-Japan to Indonesia. The objective is for younger generation of Indonesians who had lived under the dictatorship of Suharto to be able to read history of their own nation objectively. We hope that this book will restore the figure of Tan Malaka to his deserved position at the center of debates on modern Indonesian history.	\N	181	23	1925-04-01	\N	\N	\N	\N	\N	\N	https://dryofg8nmyqjw.cloudfront.net/images/no-cover.png	{}	{}	2025-03-30 17:30:38.406	2025-03-30 17:30:37.741
328	36393774	Jakarta, Maret 1998\n\nDi sebuah senja, di sebuah rumah susun di Jakarta, mahasiswa bernama Biru Laut disergap empat lelaki tak dikenal. Bersama kawan-kawannya, Daniel Tumbuan, Sunu Dyantoro, Alex Perazon, dia dibawa ke sebuah tempat yang tak dikenal. Berbulan-bulan mereka disekap, diinterogasi, dipukul, ditendang, digantung, dan disetrum agar bersedia menjawab satu pertanyaan penting: siapakah yang berdiri di balik gerakan aktivis dan mahasiswa saat itu.\n\nJakarta, Juni 1998\n\nKeluarga Arya Wibisono, seperti biasa, pada hari Minggu sore memasak bersama, menyediakan makanan kesukaan Biru Laut. Sang ayah akan meletakkan satu piring untuk dirinya, satu piring untuk sang ibu, satu piring untuk Biru Laut, dan satu piring untuk si bungsu Asmara Jati. Mereka duduk menanti dan menanti. Tapi Biru Laut tak kunjung muncul.\n\nJakarta, 2000\n\nAsmara Jati, adik Biru Laut, beserta Tim Komisi Orang Hilang yang dipimpin Aswin Pradana mencoba mencari jejak mereka yang hilang serta merekam dan mempelajari testimoni mereka yang kembali. Anjani, kekasih Laut, para orangtua dan istri aktivis yang hilang menuntut kejelasan tentang anggota keluarga mereka. Sementara Biru Laut, dari dasar laut yang sunyi bercerita kepada kita, kepada dunia tentang apa yang terjadi pada dirinya dan kawan-kawannya.\n\nLaut Bercerita, novel terbaru Leila S. Chudori, bertutur tentang kisah keluarga yang kehilangan, sekumpulan sahabat yang merasakan kekosongan di dada, sekelompok orang yang gemar menyiksa dan lancar berkhianat, sejumlah keluarga yang mencari kejelasan akan anaknya, dan tentang cinta yang tak akan luntur.	\N	20289	3979	2017-10-23	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1516602134i/36393774.jpg	{}	{}	2025-04-02 15:13:48.722	2025-04-02 15:13:48.082
329	4556058	All year the half-bloods have been preparing for battle against the Titans, knowing the odds of victory are grim. Kronos's army is stronger than ever, and with every god and half-blood he recruits, the evil Titan's power only grows.\n\nWhile the Olympians struggle to contain the rampaging monster Typhon, Kronos begins his advance on New York City, where Mount Olympus stands virtually unguarded. Now it's up to Percy Jackson and an army of young demigods to stop the Lord of Time. \n\nIn this momentous final book in the New York Times best-selling series, the long-awaited prophecy surrounding Percy's sixteenth birthday unfolds. And as the battle for Western civilization rages on the streets of Manhattan, Percy faces a terrifying suspicion that he may be fighting against his own fate.	\N	1093128	47026	2009-05-05	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1723393514i/4556058.jpg	{}	{}	2025-04-03 05:17:51.002	2025-04-03 05:17:50.211
330	60543010	Carried into modern Japan from a forgotten past, the being known as Ogushi haunts and tortures humans of all kinds. Little is know about Ogushi's curse, except that it resides in an unexpected place: human hair.\n \nLike Junji Ito's Uzumaki, PTSD Radio takes something everyday and weaves it into a series of chilling, cryptic, twisted, repellant, and alluring manga stories that become more than what they first seem.\n \nThe hit digital series finally comes to print in three 400-page compilations!\n\nAn unseen hand tugs at your braid. You find an old box with only a tangled mess of dark hair inside. You open a door in your home only to witness a river of curls slinking away, an ominous lump at its heart.\n\nOgushi preys on the unprepared. Before it's too late, tune into PTSD Radio.\n \nThese episodes and more await in this acclaimed horror series, coming to print after a successful digital run in double-length omnibus editions featuring sickeningly-textured covers. From the gleefully-twisted mind that created Fuan no Tane, PTSD Radio is a necessity for fans of the masters of manga scares such as Junji Ito, Kazuo Umezz, Shintaro Kago, and Suehiro Maruo.	\N	2096	301	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1664248880i/60543010.jpg	{}	{}	2025-04-04 15:59:33.1	2025-04-04 15:59:32.98
331	59345269	Mi dan Ma dan Mo tidak pernah melihat kucing seperti Nona Gigi. Tentu saja, mereka sudah pernah melihat kucing biasa. Tapi Nona Gigi adalah Kucing Luar Biasa. Kucing Luar Biasa berarti kucing yang di luar kebiasaan. Nona Gigi adalah Cara Lain yang dinantikan oleh Bapak dan Ibu Mo untuk menjaga Mi, Ma, dan Mo ketika keduanya keluar rumah mencari uang. Sebab di Kota Suara, semua uang yang tersedia di dasar laut sudah diambil oleh para perompak, uang di bawah tanah diambil oleh para perampok, dan uang di ranting pohon diambil oleh pengusaha kayu yang jahat.\nNona Gigi mengajak Mi dan Ma dan Mo dan Fifi dan Fufu—anak kembar Tetangga Baru bertualang mengunjungi tempat-tempat indah. Mereka naik Kereta Air, bertemu Kolonel Jagung, bermain di Sirkus Sendu, dan menyaksikan kemegahan Kota Terapung Kucing Luar Biasa.\nKita pergi hari ini. Ke tempat-tempat indah dalam mimpi-mimpi anak-anak baik-baik.	\N	2843	867	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1634170562i/59345269.jpg	{}	{}	2025-04-09 03:29:36.871	2025-04-09 03:29:36.187
332	54555561	Buku ini memuat tiga puluh cerita rakyat dari Asia Tenggara (sembilan negara). Di antaranya dari Indonesia: Timun Mas, Cindelaras, Kisah Malin Kundang, Legenda Danau Toba; Malaysia: Putri Gunung Ledang, Mahsuri, Bidasari; Filipina: Benito Utusan yang Setia; Thailand: Ucapan Burung Beo; Singapura: Si Singa.	\N	22	4	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1594918021i/54555561.jpg	{}	{}	2025-04-12 02:04:50.77	2025-04-12 02:04:50.043
333	12068827	"...kalian para perawan remaja, telah aku susun surat ini untuk kalian, bukan saja agar kalian tahu tentang nasib buruk yang biasa menimpa para gadis seumur kalian, juga agar kalian punya perhatian terhadap sejenis kalian yang mengalami kemalangan itu... Surat kepada kalian ini juga semacam pernyataan protes, sekalipun kejadiannya telah puluhan tahun lewat..."	\N	1625	222	2001-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1311032177i/12068827.jpg	{}	{}	2025-04-12 02:04:08.424	2025-04-12 02:04:07.742
334	40381674	Black Jack... Acerca de él, nada se sabe aparte de su nacionalidad japonesa; su verdadero nombre y orígenes permanecen ocultos. ¡Sin embargo, su genial habilidad en el quirófano tiene fama de tener dimensiones divinas!	\N	25	1	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1528130635i/40381674.jpg	{}	{}	2025-04-17 11:51:26.283	2025-04-17 11:51:25.678
335	63048246	After saving the world multiple times, Percy Jackson is hoping to have a normal senior year. Unfortunately, the gods aren't quite done with him. Percy will have to fulfill three quests in order to get the necessary three letters of recommendation from Mount Olympus for college. The first quest is to help Zeus's cup-bearer retrieve his goblet before it falls into the wrong hands. Can Percy, Grover, and Annabeth find it in time? Readers new to Percy Jackson and fans who have been awaiting this reunion for more than a decade will delight equally in this latest hilarious take on Greek mythology.	\N	135693	16953	2023-09-26	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1687720421i/63048246.jpg	{}	{}	2025-04-21 05:49:57.782	2025-04-21 05:49:57.105
336	6236051	In a distant future where sentient humanoid robots pass for human, someone or some thing is out to destroy the seven great robots of the world. Europol’s top detective Gesicht is assigned to investigate these mysterious robot serial murders—the only catch is that he himself is one of the seven targets. \n\nAtom, a boy robot whose sophisticated AI programming seamlessly blurs the distinction between man and machine, starts his own investigation into the serial murders of the great robots of the world. When he discovers that the killer’s motives may be connected with the geopolitical events of the recent past, he realizes that the case is far larger than anyone could have ever imagined.\n\nContains Chapters 8 to 15.	\N	5377	240	2005-04-26	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1554094308i/6236051.jpg	{}	{}	2025-04-21 08:43:45.823	2025-04-21 08:43:45.181
337	6859478		\N	15	0	2001-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1552816330i/6859478.jpg	{}	{}	2025-04-27 00:36:17.153	2025-04-27 00:36:16.977
338	27213435	Namanya Salva. Panggilannya Ava. Namun papanya memanggil dia Saliva atau ludah karena menganggapnya tidak berguna. Ava sekeluarga pindah ke Rusun Nero setelah Kakek Kia meninggal. Kakek Kia, ayahnya Papa, pernah memberi Ava kamus sebagai hadiah ulang tahun yang ketiga. Sejak itu Ava menjadi anak yang pintar berbahasa Indonesia. Sayangnya, kebanyakan orang dewasa lebih menganggap penting anak yang pintar berbahasa Inggris. Setelah pindah ke Rusun Nero, Ava bertemu dengan anak laki-laki bernama P. Iya, namanya hanya terdiri dari satu huruf P. Dari pertemuan itulah, petualangan Ava dan P bermula hingga sampai pada akhir yang mengejutkan.\n\nDitulis dengan alur yang penuh kejutan dan gaya bercerita yang unik, sudah selayaknya para juri sayembara memilih novel Di Tanah Lada sebagai salah satu juaranya.	\N	6973	1818	2015-10-19	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1444954928i/27213435.jpg	{}	{}	2025-04-27 00:36:35.157	2025-04-27 00:36:34.988
340	51820545	«Ich bin nicht ich, sondern jemand ganz anderer, der mir verblüffend ähnlich ist» - zu dieser verwirrenden Einsicht kommt der schüchterne Kanzleibeamte Goljädkin, als er in einer unheilvollen Nacht in Petersburg seinem Doppelgänger gegenübersteht. Nicht nur auf der Straße wird Goljädkin von seinem unheimlichen Double auf Schritt und Tritt verfolgt, auch am Arbeitsplatz, ja sogar in der eigenen Wohnung ist er vor dem ungebetenen Gast nicht mehr sicher, der ihn bald aus allen Lebensbezirken erfolgreich zu verdrängen sucht.\nFjodor M. Dostojewskij (1821-1881) ist zwar nicht der erste, der die Doppelgänger-Thematik aufgreift - schon Shakespeare, Goethe und E.T.A. Hoffmann hatten sich dieses Motivs angenommen -, als brillianter Psychologe und Meister der Groteske geht der russische Dichter jedoch über seine Vorgänger hinaus: Seine Romankunst verflicht in unentwirrbarer Phantastik Wirklichkeit und Wahn und erzeugt so eine Spannung, der sich kein Leser/keine Leserin zu entziehen vermag.	\N	38932	3422	1846-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1568704510l/51820545.jpg	{}	{}	2025-05-02 05:04:55.427	2025-05-02 05:04:54.759
341	164111927	Naruto Volume 34( The Reunion) <> Paperback <> KishimotoMasashi <> VizMedia	\N	2	0	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1699863326i/164111927.jpg	{}	{}	2025-05-02 14:34:21.67	2025-05-02 14:34:21.506
342	69654727	Brida has long been interested in various aspects of magic, but is searching for something more. In a forest, she meets a wise man who helps her overcome her fears and trust in the goodness of the world. She also meets a woman who teaches her how to dance to the music of the world, and how to pray to the moon. She seeks her destiny, even as she struggles to find a balance between her relationships and her desire to become a witch. Renowned for his best-loved work The Alchemist, Paulo Coelho has sold over thirty million books worldwide and has been translated into forty-two languages.	\N	82180	4266	1990-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1695010311i/69654727.jpg	{}	{}	2025-05-02 14:35:18.689	2025-05-02 14:35:16.478
343	12230167	On The Heavens is a philosophical treatise written by Aristotle, a Greek philosopher, in the 4th century BCE. The book explores the nature of the universe and its celestial bodies, including the stars, planets, and the moon. Aristotle argues that the universe is composed of a series of concentric spheres, with the Earth at the center and the stars and planets orbiting around it. He also discusses the concept of motion in the universe, and explains that the celestial bodies move in a circular motion because it is the most perfect and divine form of motion. The book also delves into the idea of causation, with Aristotle asserting that the movements of the celestial bodies are caused by the actions of the gods. On The Heavens is considered a foundational work in the history of astronomy and cosmology, and has influenced scientific thought for centuries.From one point of view it might seem impossible that the heaven should be one and unique, since in all formations and products whether of nature or of art we can distinguish the shape in itself and the shape in combination with matter. For instance the form of the sphere is one thing and the gold or bronze sphere another; the shape of the circle again is one thing, the bronze or wooden circle another.This scarce antiquarian book is a facsimile reprint of the old original and may contain some imperfections such as library marks and notations. Because we believe this work is culturally important, we have made it available as part of our commitment for protecting, preserving, and promoting the world's literature in affordable, high quality, modern editions, that are true to their original work.	\N	370	31	0351-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1348906184i/12230167.jpg	{}	{}	2025-05-03 05:46:46.08	2025-05-03 05:46:45.442
344	177068	For David Deutsch, a young physicist of unusual originality, quantum theory contains our most fundamental knowledge of the physical world. Taken literally, it implies that there are many universes “parallel” to the one we see around us. This multiplicity of universes, according to Deutsch, turns out to be the key to achieving a new worldview, one which synthesizes the theories of evolution, computation, and knowledge with quantum physics. Considered jointly, these four strands of explanation reveal a unified fabric of reality that is both objective and comprehensible, the subject of this daring, challenging book. The Fabric of Reality explains and connects many topics at the leading edge of current research and thinking, such as quantum computers (which work by effectively collaborating with their counterparts in other universes), the physics of time travel, the comprehensibility of nature and the physical limits of virtual reality, the significance of human life, and the ultimate fate of the universe. Here, for scientist and layperson alike, for philosopher, science-fiction reader, biologist, and computer expert, is a startlingly complete and rational synthesis of disciplines, and a new, optimistic message about existence.	\N	5678	311	1996-09-26	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1348344833i/177068.jpg	{}	{}	2025-05-03 06:04:01.007	2025-05-03 06:04:00.913
345	23356815	Terdiri dari tiga cerita pendek, "Dua Orang Hussar", "Tolok Ukur", dan "Kematian Ivan Ilyich".	\N	197015	16212	1886-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1413098129i/23356815.jpg	{}	{}	2025-05-05 03:38:01.829	2025-05-05 03:38:01.17
346	57576859	Buku ini memuat cerita-cerita rakyat Korea klasik yang populer sampai zaman sekarang, antara lain: Shimchong, Anak Gadis Si Buta, Harimau dan Kesemek, serta kisah sepasang kekasih yang bertemu setiap tanggal 7 Juli dalam Jembatan Langit Burung-Burung Murai hingga diperingati sebagai hari kasih sayang di Korea.	\N	17	3	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1617083835i/57576859.jpg	{}	{}	2025-05-08 06:54:18.772	2025-05-08 06:54:18.163
347	164973712	One Piece East Blue Volume 10-12 <> Paperback <> EiichiroOda <> VizMedia	\N	52	6	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1695737099i/164973712.jpg	{}	{}	2025-05-09 22:34:26.206	2025-05-09 22:34:26.045
348	1311355	Basketball. The court, the ball, the hoop. The hopes, the dreams, the sweat. It takes dedication and discipline to be the best, and the Shohoku High hoops team wants to be just that—the best. They have one last year to make their captain's dream of reaching the finals come true—will they do it? Takehiko Inoue's legendary basketball manga is finally here, and the tale of a lifetime is in your hands!\n\nSakuragi Hanamichi's got no game with girls—none at all! It doesn't help that he's known for throwing down at a moment's notice and always coming out on top. A hopeless bruiser, he's been rejected by 50 girls in a row! All that changes when he meets the girl of his dreams, Haruko, and she's actually not afraid of him! When she introduces him to the game of basketball, his life is changed forever...	\N	11628	475	1991-02-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1330196571i/1311355.jpg	{}	{}	2025-05-13 06:40:43.447	2025-05-13 06:40:42.813
349	4945364	Winning isn't everything in the game of basketball, but who wants to come in second? It takes dedication and discipline to be the best, and the Shohoku High hoops team wants to be just that. They have one year left to make their captain's dream of reaching the finals come true—will they do it? Takehiko Inoue's legendary basketball manga is finally here, and the tale of a lifetime is in your hands!\n\nHe may be a pain in the butt, but Hanamichi's athletic prowess and monstrous strength have not gone unnoticed by the captain of Shohoku's judo team. Hoping to take his troupe to a national title, the judo captain is willing to go to great lengths to lure Hanamichi away from the court and get him on the sparring mat. Will out-and-out bribery convince Hanamichi that judo's the way to go, or will he stay a basketball man to the very end?	\N	2986	156	1991-06-10	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1349078538i/4945364.jpg	{}	{}	2025-05-13 06:42:11.061	2025-05-13 06:42:10.365
350	59314040	Buku kumpulan cerpen terbaik Tolstoy ini memuat: Three Deaths * How Much Land Does a Man Need? * What Men Live By * Where Love is There God is Also * The Three Questions * The Three Hermits * A Grain As Big As a Hen’s Egg * Alyosha the Pot * God Sees the Truth, But Waits.	\N	23	4	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1633938015i/59314040.jpg	{}	{}	2025-05-13 06:40:56.104	2025-05-13 06:40:55.907
351	128971332		\N	2	0	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1699403955i/128971332.jpg	{}	{}	2025-05-15 03:56:55.223	2025-05-15 03:56:55.113
352	34311766	“Jam tiga dini hari, sweter, dan jalanan yang gelap dan sepi .... Ada peta, petunjuk; dan Jakarta menjadi tempat yang belum pernah kami datangi sebelumnya.”\n\nMawar, hyacinth biru, dan melati. Dibawa balon perak, tiga bunga ini diantar setiap hari ke balkon apartemen Emina. Tanpa pengirim, tanpa pesan; hanya kemungkinan adanya stalker mencurigakan yang tahu alamat tempat tinggalnya.\n\nKetika—tanpa rasa takut—Emina mencoba menelusuri jejak sang stalker, pencariannya mengantarkan dirinya kepada gadis kecil misterius di toko bunga, kamar apartemen sebelah tanpa suara, dan setumpuk surat cinta berisi kisah yang terlewat di hadapan bangunan-bangunan tua Kota Jakarta.	\N	4859	1276	2016-05-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1487142037i/34311766.jpg	{}	{}	2025-05-15 03:57:14.783	2025-05-15 03:57:14.177
353	36684843	Buku ini memuat cerita-cerita rakyat Jepang klasik yang paling sering dituturkan secara lisan sampai zaman sekarang. Di antaranya legenda Urashima, nelayan yang diundang ke Istana Laut, dan kisah Monogusa Taro, pemuda malas yang ternyata menyimpan bakat luar biasa.	\N	59	12	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1511967366i/36684843.jpg	{}	{}	2025-05-16 03:17:37.945	2025-05-16 03:17:37.343
354	364950	Luffy's pirates thought they were just stopping in for a quick bite...but now Luffy's been made a busboy on Baratie, the oceangoing restaurant, and it turns out some of the worst-mannered pirates on the Grand Line are just dying for a meal.\n\nAlways one to look on the bright side, Luffy sets his sights on Sanji, the smart-talking, skirt-chasing assistant chef on the Baratie, as the Merry Go's new cook. But it'll take more than a vicious pirate battle and a little sweet talking from Nami to convince him to leave the Baratie and join Luffy's team. His oath to feed any and all pirates in need keeps getting in the way. The question is: what do you do when the very same pirates you just fed now want to serve you up for dinner?	\N	19442	746	1998-12-03	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1572271006i/364950.jpg	{}	{}	2025-05-16 03:19:12.079	2025-05-16 03:19:11.943
355	1989838	Premiering the story of the Shohoku Prefectural High School basketball team, and their newest star player, Sakuragi Hanmichi, who's also the newest freshman delinquent! A novice on the court, and in love, Sakuragi learns to master the game and will play to bring the national championship to Shohoku and true love to his heart.	\N	1973	113	1991-07-10	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1266955106i/1989838.jpg	{}	{}	2025-05-19 11:40:29.894	2025-05-19 11:40:29.729
356	131913142	Depuis qu'il a rejoint l'équipe de basket du lycée, Hanamichi Sakuragi en bave ! C'est le moins qu'on puisse dire... L'adolescent supporte mal l'entraînement intensif qu'on lui impose. L'autorité de son impressionnant capitaine lui pèse. Et puis, il y a ses coéquipiers. Des durs, prompts à la bagarre... Dans cette ambiance électrique, l'équipe prépare vaille que vaille le championnat national. Alors, Sakuragi s'accroche. Sakuragi serre les dents. Sakuragi donne le meilleur de lui-même pour épater la jolie Haruko. Slam Dunk est un manga très prisé des adolescents. Et pour cause ! Takehiko Inoue y met le basket à l'honneur ! Ses héros ? Elle va les chercher dans les cours des lycées et jusque dans la rue. Tous sont de fortes têtes, des rebelles qui partagent sans le savoir un même amour pour le basket, une même rage de vaincre. Les réunir tient de la gageure. Et leurs premières rencontres tournent inévitablement aux règlements de comptes. Mais le sport est là pour fédérer leurs énergies. Grâce à lui, les adolescents apprennent à se respecter et à s'unir pour gagner. Il faut signaler que Slam Dunk est publié dans son sens original de lecture (de droite à gauche). --romat	\N	1803	100	1991-08-07	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1684706319i/131913142.jpg	{}	{}	2025-05-17 03:09:35.328	2025-05-17 03:09:34.651
357	40202576	Dalam Takut dan Gemetar, karya terbesarnya yang kontroversial Søren Kierkegaard memberi kesan abadi pada teologi Protestan dan filsuf eksistensialis seperti Sartre dan Camus. Dianggap sebagai bapak Eksistensialisme, Kierkegaard mentransformasikan filsafat dengan keyakinannya bahwa kita semua harus menciptakan sifat kita sendiri; dalam karya besar tentang kegelisahan religius ini, dia berpendapat bahwa pemahaman sejati tentang Tuhan hanya dapat dicapai dengan membuat “lompatan iman”.\n\nMenulis dengan nama samaran ‘Johannes de silentio’, Kierkegaard menguraikan pandangannya mengenai agama melalui diskusi tentang peristiwa di Kitab Kejadian di mana Abraham bersiap untuk mengorbankan putranya Ishak atas perintah Tuhan. Percaya ketaatan tanpa pamrih Abraham menjadi lompatan iman penting yang dibutuhkan untuk membuat komitmen penuh terhadap agamanya, Kierkegaard sendiri membuat pengorbanan besar untuk mengabdikan hidupnya secara penuh kepada filsafat dan Tuhannya. Keyakinan yang ditunjukkan dalam polemik agama ini –bahwa orang bisa memiliki misi luar biasa dalam hidup– menjelaskan semua tulisan Kierkegaard kemudian. ‘Penangguhan teleologis etis’-nya menantang pandangan kontemporer tentang sistem moral universal Hegel, dan juga sangat berpengaruh terhadap teologi Protestan dan gerakan eksistensialis.\n\nSøren Kierkegaard kelahiran Denmark (1813-1855) menulis pada beragam tema, termasuk agama, psikologi, dan sastra. Dia dikenang karena filsafatnya, yang memelopori gagasan Absurd, dan berpengaruh dalam perkembangan eksistensialisme abad ke-20.	\N	29381	2224	1843-10-16	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1527142181i/40202576.jpg	{}	{}	2025-05-19 11:40:54.376	2025-05-19 11:40:54.218
358	179532331	Ini dongeng tiga dara. Bukankah selalu saja tentang mereka, sebab siapa yang tak kenal cerita rumah, keluarga, kita. Tapi ini juga dongeng yang tak kau minta, tentang yang tak terlihat, tak terdengar, terlupa.\n\nDi tahun 1991, Hajjah Victoria binti Haji Tjek Sun meramal ketiga cucunya: satu cucu berkelana, satu menjaga, dan satu lagi menjadi pengantin. Ketika salah seorang berkhianat, dara yang tersisa terperangkap dan menoleh ke belakang, menelusuri dapur berisi kuali-kuali raksasa dan sumur terlarang di Rumah Victoria (kata orang jalan menuju rumah Nenek tak berujung), berhadapan dengan rahasia dan mimpi-mimpi yang macet di tengah jalan. Saat perjalanan dan kitab suci tidak lagi memberi perlindungan, dara yang lain hadir. Ia tak diundang dan menuntut penjelasan.\n\nMalam Seribu Jahanam adalah novel kedua dari Intan Paramaditha. Mengolah kisah-kisah Islami dan mitos nusantara, novel ini merupakan dongeng gelap tentang sesal, malu, dan hantu—sebuah renungan tentang praktik beragama, retakan dan reruntuhan kelas menengah, serta rapuhnya persaudaraan.	\N	532	139	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1687223072i/179532331.jpg	{}	{}	2025-05-20 15:26:23.396	2025-05-20 15:26:23.211
359	176443002	As a child, Monkey D. Luffy dreamed of becoming King of the Pirates. But his life changed when he accidentally gained the power to stretch like rubber...at the cost of never being able to swim again! Years later, Luffy sets off in search of the One Piece, said to be the greatest treasure in the world...\n\nLUFFY'S DREAM\n\nWith Kaido defeated and Wano saved, it's time for Luffy and his Straw Hat crew to depart for their next adventure. But big changes are happening all around the world, including the promotion of some new Emperors of the Sea!	\N	2410	158	2023-03-03	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1703922357i/176443002.jpg	{}	{}	2025-05-24 04:43:18.571	2025-05-24 04:43:17.961
360	1422433	Criticism on contemporary Indonesian literature; collected articles.	\N	45	6	1995-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1212740485i/1422433.jpg	{}	{}	2025-05-24 04:44:12.793	2025-05-24 04:44:12.67
361	46166345	Asuma e Shikamaru saem em busca do paradeiro do corpo de Chiriku, o que o leva ao encontro de Kakuzu e Hidan. Porém, encontrar e encurralar essa dupla da Akatsuki traz complicações trágicas e irreversíveis aos valentes ninjas da Vila da Folha! E mais: novas revelações sobre os planos da Akatsuki!	\N	6367	185	2006-12-27	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1559803754i/46166345.jpg	{}	{}	2025-05-24 04:43:57.598	2025-05-24 04:43:56.991
362	39715700	Inilah salah satu buku sains terpenting yang ditulis oleh satu di antara para ilmuwan besar zaman kita, Stephen Hawking. Dalam buku ini Hawking membahas pertanyaan-pertanyaan besar seperti: Bagaimana alam semesta bermula—dan apa yang memulainya? Apakah waktu itu, dan apakah ia selalu bergerak maju? Adakah ujung alam semesta, dalam ruang maupun waktu? Adakah dimensi lain dalam alam semesta? Apa yang terjadi ketika alam semesta berakhir? \n\nLewat penulisan yang bisa dimengerti semua orang, A Brief History of Time mengajak kita menjelajahi dunia ajaib lubang hitam dan kuark, antizat dan “panah waktu”, ledakan besar dan peran Tuhan di alam semesta beserta segala kemungkinan yang luar biasa dan tak terduga. Dengan penggambaran yang menarik dan menggugah imajinasi, Stephen Hawking membawa kita makin dekat ke rahasia pamungkas penciptaan alam semesta.	\N	462506	13507	1988-09-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1522833625i/39715700.jpg	{}	{}	2025-05-24 16:01:13.329	2025-05-24 16:01:12.686
363	58730640	“Panggilaku: Re:!”\n\n“Pekerjaanku pelacur!”\n\n“Lebih tepatnya, pelacur lesbian!”\n\nPertemuan dengan Re:,sipelacur lesbian, mengubah jalan hidup Herman.\n\nSemula, mahasiswa Kriminologi itu menganggap Re: sekadar objek\n\npenelitian skripsinya. Namun, yang terjadi malah sebaliknya.\n\nKisah hidup Re: yang berliku menyeret Herman hingga jauh kedalam.\n\nHerman terpaksa terlibat dalam sisiter gelap dunia pelacuran\n\nyang bersimbah darah, dendam, dan air mata.\n\n___\n\nDua puluh enam tahun setelah kematian Re:,\n\nMelur kembali ketanah air dengan gelar PhD\n\ntersandang di belakang namanya.\n\nSejumlah tanya ia bawa pulang:\n\nSiapa sebenarnya ibu kandungnya?\n\nBetulkah ibunya diperjualbelikan, dipaksa menjadi pelacur lesbian?\n\nApa penyebab kematian ibunya yang teramat tragi situ?\n\nHerman menyambut kedatangan Melur dengan risau.\n\nHaruskah rahasia yang ia pendam lebih dari seperempat abad itu diungkap?\n\nTidakkah hal itu akan memicu Melur untuk membalas dendam?\n\nMengapa buku kehidupan perempuan harus sarat seloka luka?\n\npeREmpuan adalah sekuel novel RE:\n\nyang diangkat dari kisah nyata.	\N	1280	273	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1628485097i/58730640.jpg	{}	{}	2025-05-25 03:19:14.645	2025-05-25 03:19:14.484
364	211712940	Michel tidak tahu apa-apa tentang cinta saat dia menikahi Marceline semata-mata demi membahagiakan ayahnya. Ketika pasangan tersebut berbulan madu ke Tunisia, Michel jatuh sakit parah, dan selama masa pemulihannya dia mengalami ketertarikan pada seorang anak laki-laki Arab. Semenjak itu, Michel menemukan kebebasan baru dalam berusaha hidup sesuai dengan keinginannya sendiri. Namun dia juga mendapati bahwa kebebasan bisa menjadi sebuah beban. Amoral meneliti konflik-konflik tak terelakkan yang muncul ketika seorang pencari kesenangan menantang masyarakat konvensional dan, tanpa moralitas, novel ini mengangkat isu-isu kompleks yang melibatkan besarnya tanggung jawab manusia.	\N	13097	1113	1902-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1713397379i/211712940.jpg	{}	{}	2025-05-26 03:52:41.317	2025-05-26 03:52:40.732
365	1739929	Indonesian Edition of:\nBuddha 8: Jetavana\n(c) 2005 by Tezuka Productions\n\nJilid ke-8 mengisahkan akhir pengembaraan Sang Buddha. Salah satu pesan dalam buku ini untuk pembaca adalah bahwa welas-asih bersemayam dalam sanubari setiap orang. Itulah sebabnya bila kalian mengasihani seseorang yang menderita, orang lain akan mengasihani kalian ketika tiba giliran kalian menderita.	\N	2898	188	1983-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1479885984i/1739929.jpg	{}	{}	2025-05-26 11:12:58.475	2025-05-26 11:12:57.831
375	212030687	Rufy e i suoi pianificano la fuga da Egghead ma una grande flotta di navi della Marina, capitanata dall’ammiraglio Kizaru, circonda l’isola del futuro! C’è in gioco anche uno dei Cinque Astri di Saggezza e si preannuncia così una battaglia su una scala senza precedenti...	\N	1691	156	2024-03-04	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1719219343i/212030687.jpg	{}	{}	2025-06-07 05:57:26.36	2025-06-07 05:57:25.724
416	364954	Don Krieg's evil pirate armada attempts to hijack the oceangoing restaurant Baratie, but the pirate cooks put up a fierce resistance until Krieg reveals one of the greatest secret weapons in his arsenal--Invincible Pearl! When sous chef Sanji steps into the fray, it turns out that he and Chef Zeff have some unfinished business concerning the loss of the latter's leg! Will their differences come between them or make the Baratie stronger? Either way, unfortunately for Luffy, it turns out that Don Krieg harbors an even deadlier weapon--Gin, the very man whose life Sanji once saved with a square meal!	\N	18744	733	1999-03-04	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1389640440i/364954.jpg	{}	{}	2025-09-02 06:22:26.068	2025-09-02 06:22:25.383
366	1334844	Gabungan 3 buku seri Dukuh Paruk: Ronggeng Dukuh Paruk, Lintang Kemukus Dini Hari & Jantera Bianglala.\n\nSemangat Dukuh Paruk kembali menggeliat sejak Srintil dinobatkan menjadi ronggeng baru, menggantikan ronggeng terakhir yang mati dua belas tahun yang lalu. Bagi pedukuhan yang kecil, miskin, terpencil dan bersahaja itu, ronggeng adalah perlambang. Tanpanya dukuh itu merasakah kehilangan jati diri.\n\nDengan segera Srintil menjadi tokoh yang amat terkenal dan digandrungi. Cantik dan menggoda. Semua ingin pernah bersama ronggeng itu. Dari kaula biasa hingga pekabat-pejabat desa maupun kabupaten. \n\nNamun malapetaka politik tahun 1965 membuat dukuh tersebut hancur, baik secara fisik maupun mental. Karena kebodohannya, mereka terbawa arus dan divonis sebagai manusia-manusia yang telah mengguncangkan negara ini. Pedukuhan itu dibakar. Ronggeng berserta para penabuh calung ditahan.Hanya karena kecantikannya Srintil tidak diperlakukan semena-mena oleh para penguasa penjara itu. \n\nNamun pengalaman pahit sebagai tahanan politikmembuat Srintil sadar akan harkatnya sebagai manusia. Karena itulah setelah bebas, ia berniat memperbaiki citra dirinya. Ia tak ingin lagi melayani lelaki manapun. Ia ingin menjadi wanita somahan. Dan ketika Bajus muncul dalam hidupnya sepercik harapan muncul, harapan yang semakin lama semakin besar.	\N	7100	927	1982-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1464425991i/1334844.jpg	{}	{}	2025-05-28 17:20:44.006	2025-05-28 17:20:43.352
367	209363183	剛腕・豹＆狙撃手・平助vs磁力使いの熊埜御!!　殺しの流儀を異にする3人の近接・遠距離入り乱れる激戦の行方は…!?　同じ頃、×の潜む廃倉庫では、到着を急ぐ坂本たちに先んじて“あの人物”が×と対峙していた!!	\N	675	48	2024-01-04	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1709346520i/209363183.jpg	{}	{}	2025-05-29 08:32:22.841	2025-05-29 08:32:22.728
368	95558	A classic work of science fiction by renowned Polish novelist and satirist Stanislaw Lem.\n\nWhen Kris Kelvin arrives at the planet Solaris to study the ocean that covers its surface, he finds a painful, hitherto unconscious memory embodied in the living physical likeness of a long-dead lover. Others examining the planet, Kelvin learns, are plagued with their own repressed and newly corporeal memories. The Solaris ocean may be a massive brain that creates these incarnate memories, though its purpose in doing so is unknown, forcing the scientists to shift the focus of their quest and wonder if they can truly understand the universe without first understanding what lies within their hearts.	\N	122177	8628	1961-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1498631519i/95558.jpg	{}	{}	2025-05-31 03:03:01.371	2025-05-31 03:03:00.71
369	1341023	Dari balik sel penjara, Firdaus -- yang divonis gantung karena telah membunuh seorang germo -- mengisahkan liku-liku kehidupannya. Dari sejak masa kecilnya di desa, hingga ia menjadi pelacur kelas atas di Kota Kairo. Ia menyambut gembira hukuman gantung itu. Bahkan dengan tegas ia menolak grasi kepada presiden yang diusulkan oleh dokter penjara. Menurut Firdaus, vonis itu justru merupakan satu-satunya jalan menuju kebebasan sejati. Ironis.\n\nLewat pelacur ini, kita justru bisa menguak kebobrokan masyarakat yang didominasi kaum lelaki. Sebuah kritik sosial yang amat pedas!\n\nNovel ini didasari pada kisah nyata. Ditulis oleh Nawal el-Saadawi, seorang penulis feminis dari Mesir dengan reputasi Internasional	\N	26215	3762	1975-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1478753558i/1341023.jpg	{}	{}	2025-06-01 12:51:30.082	2025-06-01 12:51:29.917
370	199798712	Join Monkey D. Luffy and his swashbuckling crew in their search for the ultimate treasure, One Piece!\n\nAs a child, Monkey D. Luffy dreamed of becoming King of the Pirates. But his life changed when he accidentally gained the power to stretch like rubber...at the cost of never being able to swim again! Years later, Luffy sets off in search of the One Piece, said to be the greatest treasure in the world...\n\nLuffy and crew arrive on the mysterious island of Egghead! There, they find Dr. Vegapunk’s laboratory and all sorts of futuristic wonders. But when CP0 arrives to assassinate Vegapunk, a new adventure is kicked off!	\N	2261	148	2023-07-04	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1710177929i/199798712.jpg	{}	{}	2025-06-04 11:47:53.282	2025-06-04 11:47:53.165
371	207297378	Join Monkey D. Luffy and his swashbuckling crew in their search for the ultimate treasure, One Piece!\n\nAs a child, Monkey D. Luffy dreamed of becoming King of the Pirates. But his life changed when he accidentally gained the power to stretch like rubber...at the cost of never being able to swim again! Years later, Luffy sets off in search of the "One Piece", said to be the greatest treasure in the world...\n\nThe Hero of Legend\nHaving learned too much of the world’s history, Dr. Vegapunk is now the target of the CP0 assassins. Vegapunk’s only hope may be to ask for help from Luffy and the Straw Hat crew, but where are they? Chaos erupts on Egghead Island as the world government sends some powerful reinforcements.	\N	2014	154	2023-11-02	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1716864035i/207297378.jpg	{}	{}	2025-06-04 11:48:10.463	2025-06-04 11:48:10.35
372	35012293	Ada dua puluh cerita rakyat dimuat dalam buku ini, baik cerita tentang rakyat jelata, para ksatria dan raja, maupun tokoh-tokoh legenda. Meskipun semua cerita berlatar Cina masa lalu, ajaran moral dan budi perkerti yang terkandung di dalamnya berlaku universal, dan akan tetap mencerahkan serta memberi ilham bagi siapa pun dan sampai kapan pun.	\N	31	6	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1493488206i/35012293.jpg	{}	{}	2025-06-04 11:47:34.498	2025-06-04 11:47:33.884
373	18071363	Karya pamungkas Leo Tolstoy yang baru di-terbitkan setelah kematiannya ini adalah do-ngeng moral paling dahsyat pada zaman kita.\n\nNovel ini terinspirasi oleh sosok historis dan kontroversial yang didengar Tolstoy ketika bertugas sebagai tentara di Kaukasus. Kisah ini menghidupkan sang pejuang terkenal, Haji Murad, seorang pemberontak Chechnya yang berjuang dengan garang dan gagah berani melawan kekaisaran Rusia.\n\nHaji Murad adalah gambaran menggetarkan sosok pejuang tragis yang masih dikenang hingga kini. Inilah sebuah kisah indah tentang cinta, perjuangan, dan pengorbanan yang layak Anda renungkan.	\N	14584	1249	1912-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1371106512i/18071363.jpg	{}	{}	2025-06-07 04:45:26.335	2025-06-07 04:45:25.635
374	2236672	Orang-orang Bloomington adalah karya penting Budi Darma. Kumpulan cerita ini merupakan salah satu karya Sang Maestro yang, berbeda dengan kebanyakan karyanya, tidak bertemakan hal-hal abstrak. Melalui cerita-cerita yang ditulis pada periode akhir 1970an ini, pembaca tidak hanya diajak menelanjangi pergolakan emosional para tokoh di dalamnya, tetapi juga menyelami berbagai permasalahan humanistik mereka dalam berhubungan dengan lingkungan dan sesama.	\N	2154	446	1980-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1417054904i/2236672.jpg	{}	{}	2025-06-07 04:45:09.645	2025-06-07 04:45:09.052
386	\N	membangun Indonesia yang aman, adil dan sejahtera : pidato politik Susilo Bambang Yudhoyono pada pembukaan masa kampanye Pemilihan Presiden dan Wakil Presiden 2004-2009	\N	\N	\N	\N				\N		\N	https://books.google.com/googlebooks/images/no_cover_thumb.gif	{}	{}	2025-06-30 09:10:42.892	2025-06-30 09:10:42.266
376	1563690	Jalan hidup Kadiroen, pejabat lokal di pemerintahan Hindia Belanda, berubah setelah dia mendengar pidato Tjitro, seorang tokoh Partai Komunis. Tjitro bicara tentang kapitalisme, perlunya berserikat, serta komunisme.\n\nIdealisme Kadiroen sejalan dengan konsep Partai Komunis. Dia pun bersimpati dan mendukung partai itu secara diam-diam. Dia melepas kariernya di pemerintahan kolonial dan menjadi penulis pada Sinar Ra’jat, harian Partai Komunis, bahkan pernah terkena pasal delik pers (persdelict).\n\nNovel yang ditulis Semaoen ketika dirinya di penjara pada 1919 ini menunjukkan sosok Kadiroen sebagai borjuis yang menjadi pahlawan karena berupaya memakmurkan kaum tertindas. Selain itu novel ini juga menyelipkan cerita cinta Kadiroen dan Ardinah, istri seorang lurah yang terkena kawin paksa. Romansa mereka menjadi penutup seluruh kisah.	\N	109	26	2000-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1463493184i/1563690.jpg	{}	{}	2025-06-10 02:27:42.5	2025-06-10 02:27:41.9
377	551871	The story of the Shohoku Prefectural High School basketball team, and their newest star player, Sakuragi Hanmichi, who's also the newest freshman delinquent! A novice on the court, and in love, Sakuragi learns to master the game and will play to bring the national championship to Shohoku and true love to his heart.	\N	1737	91	1991-10-09	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1175729344i/551871.jpg	{}	{}	2025-06-11 03:38:43.893	2025-06-11 03:38:43.255
378	61176232	“Ya, begitulah. Baru-baru ini juga saya baca di surat kabar bahwa satu orang Belanda yang gelapkan duit f 1000 cuma dihukum 6 bulan.”\n “Tapi, kalau bangsa Bumiputera mencuri beberapa puluh rupiah bisa dihukum sampai satu tahun.” \n “Dan, Nona, ada lagi yang mencuri ayam saja dapat 3 bulan.”\n “Ya, kasihan!”\n “Itu belum seberapa. Orang Belanda kalau dihukum di bui Semarang masih enak. Dapat makanan baik, roti dan kentang, tidur pakai bulzak, bisa belajar ini dan itu sehingga mereka malah senang sekali. Keluar dari bui ada yang bisa dapat diploma. Tetapi, orang Bumiputera, bagaimana? Kalau jadi orang rantai, belum tentu ia tidak mati.”\n\nWage Rudolf Supratman, bukan hanya seorang wartawan handal dan sosok yang menciptakan lagu kebangsaan Indonesia Raya. Satu tentangnya yang jarang dibicarakan adalah bakatnya menulis. Novel Perawan Desa adalah novel perdananya. Buku itu ditulis selepas kemunculannya di Kongres Pemuda II. Sayangnya gara-gara kemunculan itu gerak-geriknya dipantau pemerintah kolonial. Sebelum tersebar, novel Perawan Desa dibredel dan dianggap sebagai bacaan liar yang terlarang. Sampai berpuluh tahun, keberadaannya seperti tertelan bumi ...	\N	27	10	1928-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1653665491i/61176232.jpg	{}	{}	2025-06-15 03:11:47.823	2025-06-15 03:11:47.165
379	34852851	A best-of story selection by the master of horror manga.\n\nThis volume includes nine of Junji Ito’s best short stories, as selected by the author himself and presented with accompanying notes and commentary. An arm peppered with tiny holes dangles from a sick girl’s window… After an idol hangs herself, balloons bearing faces appear in the sky, some even featuring your own face… An amateur film crew hires an extremely individualistic fashion model and faces a real bloody ending… An offering of nine fresh nightmares for the delight of horror fans.\n\n1. Used Record or Second-Hand Record (from House of the Marionettes, あやつりの屋敷 Ayatsuri no Yashiki), a story about people fighting over the ownership of a record that has a singer's singing as they died recorded on it.\n2. Shiver (from Slug Girl, なめくじの少女 Namekuji no Shoujo), a story about a cursed jade stone that causes holes to open up all over a person's body if they're around it.\n3. Fashion Model (from Souichi's Diary of Curses, 双一の呪い日記, Sōichi no Noroi no Nikki), a story about an oddly ominous fashion model.\n4. Hanging Balloons (from The Face Burglar, 顔泥棒 Kao Dorobou), a story about balloon headed dopplegangers out to hunt their counterparts the moment they go outside.\n5. Marionette Mansion (from House of the Marionettes, あやつりの屋敷 Ayatsuri no Yashiki), a story about a family who rather than deciding what they do or how they live, they instead hire puppeteers to control their actions via strings from the attic of their home.\n6. Painter (from Tomie), a story about a strange but beautiful woman named Tomie who wishes for an artist to accurately capture her beauty, and all the misfortune that happens as a result...\n7. The Long Dream (from The Story of the Mysterious Tunnel,トンネル奇譚 Ton'neru kitan), a story about a man who claims that the length of his dreams are becoming longer and longer and about how he begins to change as his dreams extend farther and farther.\n8. Honored Ancestors (from The Face Burglar, 顔泥棒 Kao Dorobou), a story about an amnesiac girl and the encounter that caused her to lose her memories and about carrying on the family line. At all costs.\n9. Greased (from Voices in the Dark, 闇の声 Yami no Koe, a story about oil and grease. \n10. Fashion Model: Cursed Frame [new]	\N	24991	2845	2015-10-07	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1505139005i/34852851.jpg	{}	{}	2025-06-17 05:44:51.678	2025-06-17 05:44:50.985
380	1430242	Issues on civil rights, democracy, politics & government, rule of law in Indonesia; papers of seminars.	\N	8	0	1995-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1259588409i/1430242.jpg	{}	{}	2025-06-25 14:26:24.968	2025-06-25 14:26:24.341
381	45834865	Buku "Kamu Terlalu Banyak Bercanda"\ntentang gelap untuk terangnya\n"Nanti Kita Cerita Tentang Hari Ini".	\N	1138	129	2019-05-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1736660923i/45834865.jpg	{}	{}	2025-06-25 14:27:05.022	2025-06-25 14:27:04.4
382	1431515	Tulisan Mohammad Hatta, mantan Wakil Presiden pertama RI ini pernah dimuat di Majalah Pandji Masjarakat no. 22 1 Mei 1960 dan sempat dilarang terbit disertai dgn larangan untuk membaca, menyiarkan bahkan menyimpan majalah Pandji Masjarakat edisi tersebut. Buku ini memuat uraian yang jenius dari seorang bapak bangsa yang mengkhawatirkan jalannya pemerintahan semenjak dikeluarkannya Dekrit Preseiden Sukarno 5 juli 1959 dan diberlakukannya Keadaan Daurat dgn dibubarkannya Badan Konstituante yang bertugas menyusun UUD baru.	\N	281	16	1959-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1464193750i/1431515.jpg	{}	{}	2025-06-25 14:26:51.631	2025-06-25 14:26:51.53
383	5071380	The Friend, an enigmatic cult leader who plans to destroy the world, declares, "The cosmos has begun choosing those who are true friends." Meanwhile, horrifying incidents are taking place: the emergence of a mysterious virus, the revelations of a man on the run... Kenji tries to find out who this Friend is, but the answer is still far ahead. The footsteps of doom slowly creep closer and a shadow falls over the city...\n\nYukiji remembers who came up with their group's enigmatic symbol: Otcho. She also discovers that, nine years earlier, Otcho had been working in Thailand but mysteriously vanished. Could Otcho be the mysterious Friend? Also, a legendary detective is hot on the trail of the Shikishima kidnappers, but the clues he uncovers lead him dangerously close to the Friends cult. Is his life now in danger as well?	\N	3700	206	2000-05-29	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1344484501i/5071380.jpg	{}	{}	2025-06-25 14:25:56.845	2025-06-25 14:25:56.224
384	174379	Lying somewhere between medical drama, cartoon humor, and film noir lies Black Jack, the ongoing adventures of an underground doctor who is the last resort for some very unusual patients. In this volume, the risk-taking Black Jack is at the mercy of a doctor after a horrible car wreck.	\N	108	8	1974-07-18	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1172427042i/174379.jpg	{}	{}	2025-06-30 09:11:11.799	2025-06-30 09:11:11.612
385	\N		\N	\N	\N	\N				\N		\N	https://books.google.com/googlebooks/images/no_cover_thumb.gif	{}	{}	2025-06-30 09:12:42.649	2025-06-30 09:12:42.48
387	40813375	Che Guevara dan Fidel Castro memimpin 82 gerilyawan yang bertekad menggulingkan pemerintahan diktator Batista. Mereka berlayar dari Meksiko, menembus badai, dan mendarat di pantai Kuba. Namun pasukan Batista telah siap menyergap. Kelompok gerilyawan itu dibantai dengan artileri berat dan serangan udara. Mereka harus menyingkir ke Sierra Maestra. Jumlah mereka tinggal 20-an orang.\n\nApa yang kemudian dilakukan Che dan Fidel untuk membangun kekuatannya kembali? Lalu bagaimana pula kelompok gerilyawan itu kemudian bisa memenangkan pertempuran melawan angkatan bersenjata Batista? Bagaimana mereka akhirnya berparade dalam kemenangan di Havana, ibu kota Kuba?	\N	37	5	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1531643628i/40813375.jpg	{}	{}	2025-07-09 04:32:32.983	2025-07-09 04:32:32.341
388	5193041	Roman ini ditulis dengan khas dalam bentuk surat antara pemeran utama, yaitu Werther dengan seorang sahabatnya bernama Wilhelm dan jawaban Wilhelm tidak menjadi tema roman ini. Dengan kata lain roman ini ditulis sebagai monolog Werther yang menceritakan mengenai penderitaan batinnya dalam tantangan hdup, terutama penderitaannya dalam mencintai seorang wanita yang telah mengikat diri (bertunangan) dengan orang lain. \n\nPada suatu hari, secara kebetulan, dalam sebuah perjalanan menuju pesta muda-mudi, Werther berkenalan dengan seorang gadis bernama Lotte, seorang saudara sepupu yang mengajaknya pergi ke pesta itu. Dari saat pertama perkenalan mereka, mereka telah menemukan berbagai kecocokan yang menimbulkan simpati kedua belah pihak. Keramahan dan keluwesan Lotte dalam bergaul telah disalah tafsirkan Werther, seakan-akan Lotte memberi peluang umtuk mengembangkan hubungan mereka ke arah cinta. Setelah ia menerima isyarat-isyarat pembatasan hubungan hanya sejauh persahabatan., hal ini tak dapat diterima Werther. Dalam kepiawannya dalam bergaul dan menggunakan intelektualitasnya Werther berusaha untuk tetap menuntut kesempatan mengembangkan hubungan ke arah hubungan cinta. Hal ini terpaksa dijelaskan Lotte juga, karena desakan tunanganya yang lambat laun merasa toleransinya disalahtafsirkan Werther. Semakin menggebu-gebu usaha Werther, semakin tegas jawaban atau penolakan Lotte terhadap tuntutannya. Semua ini begitu membebani jiwa Werther yang dalam kehidupan kesehariannya juga menemukan kegagalan, misalnya dengan ketidakcocokan dengan atasannya, yakni Duta Besar. Oleh karena Werther sudah tidak sanggup lagi menghadapi tantangan hidupnya., ia memutuskan untuk mengakhiri hidupnya dengan bunuh diri. Hal ini dapat ditafsirkan sebagai wujud frustasinya, tetapi juga sebagai ancaman terhadap Lotte. Hal ini dengan terang-terangan dikemukakan kepada Lotte dan Albert tunangannya. \n\nRoman ini enak dibaca, bukan hanya oleh mahasiswa-mahasiswa sastra tetapi juga oleh masyarakat umum yang rindu akan nilai-nilai sastra yang indah.	\N	148306	10524	1774-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1224744220i/5193041.jpg	{}	{}	2025-07-11 03:09:43.379	2025-07-11 03:09:42.771
389	141077	When Marshal of the Nobility Pozdnyshev suspects his wife of having an affair with her music partner, his jealousy consumes him and drives him to murder. Controversial upon publication in 1890, The Kreutzer Sonata illuminates Tolstoy’s then-feverish Christian ideals, his conflicts with lust and the hypocrisies of nineteenth-century marriage, and his thinking on the role of art and music in society.\n\nIn her Introduction, Doris Lessing shows how relevant The Kreutzer Sonata is to our understanding of Tolstoy the artist, as well as to feminism and literature. This Modern Library Paperback Classic also contains Tolstoy’s Sequel to the Kruetzer Sonata .	\N	33884	2814	1889-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1657554522i/141077.jpg	{}	{}	2025-07-11 16:39:12.724	2025-07-11 16:39:12.008
390	8906349	The tales of told by Shahrazad over a thousand and one nights to delay her execution by the vengeful King Shahriyar have become among the most popular in both Eastern and Western literature, as recounted by Sir Francis Burton. From the epic adventures of "Aladdin and the Enchanted Lamp" to the farcical "Young Woman and her Five Lovers" and the social criticism of "The Tale of the Hunchback", the stories depict a fabulous world of all-powerful sorcerers, jinns imprisoned in bottles and enchanting princesses. But despite their imaginative extravagance, the Tales are anchored to everyday life by their realism, providing a full and intimate record of medieval Islam.'	\N	80306	2621	0800-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1282149211i/8906349.jpg	{}	{}	2025-07-12 16:32:37.448	2025-07-12 16:32:36.767
391	13079982	Sixty years after its original publication, Ray Bradbury’s internationally acclaimed novel Fahrenheit 451 stands as a classic of world literature set in a bleak, dystopian future. Today its message has grown more relevant than ever before.\n\nGuy Montag is a fireman. His job is to destroy the most illegal of commodities, the printed book, along with the houses in which they are hidden. Montag never questions the destruction and ruin his actions produce, returning each day to his bland life and wife, Mildred, who spends all day with her television “family.” But when he meets an eccentric young neighbor, Clarisse, who introduces him to a past where people didn’t live in fear and to a present where one sees the world through the ideas in books instead of the mindless chatter of television, Montag begins to question everything he has ever known.	\N	2707755	88438	1953-10-19	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1383718290i/13079982.jpg	{}	{}	2025-07-12 17:28:13.661	2025-07-12 17:28:13.539
392	7044698	Since its first publication in 1945 Lord Russell's A History of Western Philosophy has been universally acclaimed as the outstanding one-volume work on the subject—unparalleled in its comprehensiveness, its clarity, its erudition, its grace and wit. In seventy-six chapters he traces philosophy from the rise of Greek civilization to the emergence of logical analysis in the twentieth century. Among the philosophers considered are: Pythagoras, Heraclitus, Parmenides, Empedocles, Anaxagoras, the Atomists, Protagoras, Socrates, Plato, Aristotle, the Cynics, the Sceptics, the Epicureans, the Stoics, Plotinus, Ambrose, Jerome, Augustine, Benedict, Gregory the Great, John the Scot, Aquinas, Duns Scotus, William of Occam, Machiavelli, Erasmus, More, Bacon, Hobbes, Descartes, Spinoza, Leibniz, Locke, Berkeley, Hume, Rousseau, Kant, Hegel, Schopenhauer, Nietzsche, the Utilitarians, Marx, Bergson, James, Dewey, and lastly the philosophers with whom Lord Russell himself is most closely associated -- Cantor, Frege, and Whitehead, co-author with Russell of the monumental Principia Mathematica.	\N	40872	1541	1945-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1256477944i/7044698.jpg	{}	{}	2025-07-17 13:43:19.467	2025-07-17 13:43:18.845
393	7010659		\N	76	12	2002-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1255971160i/7010659.jpg	{}	{}	2025-07-17 13:38:57.421	2025-07-17 13:38:56.769
401	5660026	Shikamaru's team is out for revenge against their mentor's murderers. Tsunade tries to stop them, but Kakashi wants to help! As the divide among the ninja grows, the mysterious Akatsuki organization continues their brutal attack on the tailed spirits, the bijū, and the young ninja who host them, including Naruto! He's older and stronger, but has Naruto trained enough?!	\N	6626	180	2007-04-04	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1435526929i/5660026.jpg	{}	{}	2025-07-24 15:42:55.15	2025-07-24 15:42:54.442
402	52879286	From the author of Utopia For Realists, a revolutionary argument that the innate goodness and cooperation of human beings has been the greatest factor in our success\n\nIf one basic principle has served as the bedrock of bestselling author Rutger Bregman's thinking, it is that every progressive idea -- whether it was the abolition of slavery, the advent of democracy, women's suffrage, or the ratification of marriage equality -- was once considered radical and dangerous by the mainstream opinion of its time. With Humankind, he brings that mentality to bear against one of our most entrenched ideas: namely, that human beings are by nature selfish and self-interested.\n\nBy providing a new historical perspective of the last 200,000 years of human history, Bregman sets out to prove that we are in fact evolutionarily wired for cooperation rather than competition, and that our instinct to trust each other has a firm evolutionary basis going back to the beginning of Homo sapiens. Bregman systematically debunks our understanding of the Milgram electrical-shock experiment, the Zimbardo prison experiment, and the Kitty Genovese "bystander effect."\n\nIn place of these, he offers little-known true stories: the tale of twin brothers on opposing sides of apartheid in South Africa who came together with Nelson Mandela to create peace; a group of six shipwrecked children who survived for a year and a half on a deserted island by working together; a study done after World War II that found that as few as 15% of American soldiers were actually capable of firing at the enemy.\n\nThe ultimate goal of Humankind is to demonstrate that while neither capitalism nor communism has on its own been proven to be a workable social system, there is a third option: giving "citizens and professionals the means (left) to make their own choices (right)." Reorienting our thinking toward positive and high expectations of our fellow man, Bregman argues, will reap lasting success. Bregman presents this idea with his signature wit and frankness, once again making history, social science and economic theory accessible and enjoyable for lay readers.	\N	75109	8103	2019-09-03	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1577251406i/52879286.jpg	{}	{}	2025-07-26 16:31:35.775	2025-07-26 16:31:35.111
680	\N	Setelah festival olahraga berakhir, kami mendengar bahwa kakak Iida telah diserang oleh Villain. Iida berusaha untuk tetap tegar. Tapi, beberapa hari setelah itu, kami diberikan kesempatan untuk magang bersama Hero Profesional. Demi jalan yang ingin kutempuh... Juga demi mengubah diriku sendiri... Aku tidak akan lari lagi dari Ayah...! "Plus Ultra!!"	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1532947263i/40993604.jpg	\N	\N	2026-05-31 16:35:48.809988	2026-05-31 16:35:48.809988
394	217195528	Apa yang terjadi andai kita jatuh ke lubang hitam? Bagaimana cara bintang bersinar? Mengapa planet-planet bisa beredar mengelilingi Matahari dalam jalur yang stabil? Ahli astrofisika terkenal Neil deGrasse Tyson menawarkan jawaban saintifik untuk berbagai pertanyaan mengenai alam semesta dalam kumpulan esai ini.\n\nDengan bahasa populer yang mempermudah pembaca, Tyson membimbing kita menjelajahi misteri-misteri jagat raya yang menakjubkan, dan menunjukkan hubungan kosmos dengan beraneka topik lain, mulai dari fisika dan biologi sampai agama dan budaya populer.\n\n“[Tyson] membahas beraneka subjek … dengan humor, sikap rendah hati, dan—yang paling penting—manusiawi.” –Entertainment Weekly\n“Menjadi ahli astrofisika terkemuka itu satu hal. Memiliki bakat melucu pada saat yang tepat itu hal lain lagi. Biasanya orang tidak punya dua-duanya sekaligus, tapi Neil bisa.” –Jon Stewart, The Daily Show\n“Tyson bintang rock yang kesukaannya terhadap hukum alam sebanding dengan penjelasannya yang menarik atas berbagai topik, dari zat gelap hingga absurdnya zombie.” –Parade\n“Sukar membayangkan orang yang lebih pas untuk menghidupkan kembali kosmos daripada Neil deGrasse Tyson.” –Dennis Overbye, New York Times\n“[Tyson] penuh gagasan.” –Lisa de Moraes, Washington Post\n“Neil deGrasse Tyson barangkali juru bicara terbaik untuk sains yang ada sekarang.” –Matt Blum, Wired\n“Tyson … adalah orang yang mempopulerkan sains dengan luwes dan penuh percaya diri.” –People\n“Penerus kombinasi langka kebijaksanaan dan kemampuan komunikasi Carl Sagan.” –Seth MacFarlane, pencipta Family Guy	\N	31852	1571	2006-11-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1722863508i/217195528.jpg	{}	{}	2025-07-17 13:41:32.439	2025-07-17 13:41:32.314
395	55351213	Analisis dalam buku ini sangat tepat sasaran. Untuk pertama kalinya terdapat sebuah buku yang mengaitkan peristiwa kematian rōmusha dengan aktivitas Unit Pencegahan Penyakit Epidemik dan Pemurnian Air yang sangat misterius. Sangat mengherankan bahwa ketika perang usai, peristiwa ini tidak begitu diperhatikan oleh tentara Sekutu sebagai kejahatan perang.\nAiko Kurasawa, penulis Masyarakat & Perang Asia Timur Raya dan Kuasa Jepang di Jawa\n\nKisah yang menggentarkan ini diceritakan dengan perhatian forensik yang terperinci dan hasrat yang tak dapat disangkal, menerangi sudut suram sejarah Indonesia. Buku ini merupakan khazanah penting terhadap kurangnya literatur mengenai tahun-tahun pendudukan Jepang.\nElizabeth Pisani, penulis Indonesia Etc. dan The Wisdom of Whores	\N	18	5	2015-05-15	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1600255315i/55351213.jpg	{}	{}	2025-07-17 13:44:58.706	2025-07-17 13:44:58.088
396	54905860	Peristiwa 1 Oktober 1965 diikuti kampanye antikomunis dan pembunuhan massal. Korbannya kurang lebih satu juta jiwa. Dianggap sebagai salah satu genosida yang terbesar setelah Perang Dunia II. Ini masih ditambah penahanan jutaan lainnya selama satu dekade atau lebih tanpa proses hukum. Pembersihan ini dibenarkan dan dimungkinkan oleh kampanye propaganda ketika komunis digambarkan sebagai hantu atau biang kejahatan, seperti ateis, hiperseksual, amoral, dan pengkhianat bangsa. Sampai hari ini dampak kampanye tersebut masih terus dirasakan dan para korbannya distigmatisasi.\n\nBuku ini menyajikan sejarah genosida dan kampanye propaganda serta proses yang mengarah pada pembentukan International People’s Tribunal on Crimes against Humanity Indonesia (IPT 1965), yang diadakan di Den Haag, Belanda pada November 2015. Penulis adalah seorang akademisi Belanda dan pengacara HAM Indonesia. Mereka membahas peristiwa ini, yang untuk pertama kalinya membawa kejahatan ini ke pengadilan internasional dan mereka mempertimbangkan keputusannya. Mereka memilih kampanye propaganda kebencian yang memberikan hasutan untuk membunuh banyak warga Indonesia dan bertanya mengapa kampanye propaganda ini masih terus efektif. Topik ini belum disentuh. Sebab itu, buku ini menjadi yang pertama mengisinya dalam Kajian Asia serta Kajian Genosida.\n\nSaskia E. Wieringa adalah profesor di University of Amsterdam, Belanda, dan Ketua Yayasan IPT 1965 yang mendirikan Pengadilan Rakyat mengenai kejahatan pasca-1965 terhadap kemanusiaan yang terjadi di Indonesia.\n\nNursyahbani Katjasungkana adalah pengacara HAM dan sebelumnya menjadi Direktur Yayasan Lembaga Bantuan Hukum Indonesia (YLBHI) serta Presiden Wahana Lingkungan Indonesia (WALHI). Ia adalah koordinator umum Yayasan IPT 1965.	\N	31	8	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1597300679i/54905860.jpg	{}	{}	2025-07-17 13:45:55.72	2025-07-17 13:45:55.586
397	62916818	Aliansi Demokrasi Rakyat (ALDERA) memang memainkan peranan penting dalam interaksi perlawanan atas rezin. Pilihan bergerak bersama rakyat yang dimulai dengan membangun gerakan-gerakan perlawanan atas perampasan tanah di Jawa Barat, telah membangun solidaritas gerakan ini dan menjadi gerakan politik adiluhung sebagai pengontrol sekaligus penantang langsung kebijakan Soeharto.	\N	28	6	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1665322860i/62916818.jpg	{}	{}	2025-07-17 13:47:14.498	2025-07-17 13:47:14.371
398	18720905	This is a reproduction of a book published before 1923. This book may have occasional imperfections such as missing or blurred pages, poor pictures, errant marks, etc. that were either part of the original artifact, or were introduced by the scanning process. We believe this work is culturally important, and despite the imperfections, have elected to bring it back into print as part of our continuing commitment to the preservation of printed works worldwide. We appreciate your understanding of the imperfections in the preservation process, and hope you enjoy this valuable book.	\N	1	1	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1382900740i/18720905.jpg	{}	{}	2025-07-17 13:48:45.919	2025-07-17 13:48:45.292
399	170206614		\N	1	0	\N	\N	\N	\N	\N	\N	\N	https://dryofg8nmyqjw.cloudfront.net/images/no-cover.png	{}	{}	2025-07-17 13:51:02.632	2025-07-17 13:51:02.5
400	213870316	1828. Robin Swift menjadi yatim piatu akibat kolera di Kanton, lalu dibawa ke London oleh Profesor Lovell yang misterius. Robin mendapat pelatihan selama bertahun-tahun dalam bahasa Latin, Yunani Kuno, dan Tionghoa sebagai bentuk persiapan untuk hari ketika dia akan masuk ke Institut penerjemahan bergengsi di Universitas Oxford—atau yang dikenal sebagai Babel.\n\nBabel adalah pusat penerjemahan dunia dan, yang lebih penting lagi, adanya cipta-perak: seni mewujudkan makna yang hilang dalam penerjemahan melalui batangan perak yang dipahat, dengan efek magis. Pengerjaan perak telah membuat Imperium Inggris memiliki kekuatan yang tak tertandingi. Penelitian Babel tentang penerjemahan membantu upaya Imperium untuk menjajah segala sesuatu yang ditemuinya.\n\nOxford, kota dengan menara-menara impian, adalah sebuah dongeng bagi Robin: sebuah komunitas utopia yang didedikasikan untuk mengejar pengetahuan. Namun, pengetahuan melayani kekuasaan, dan bagi Robin—seorang anak Tiongkok yang dibesarkan di Britania—mengabdi pada Babel berarti mengkhianati tanah leluhurnya.\n\nRobin mendapati dirinya terjebak di antara Babel dan Perkumpulan Hermes, sebuah organisasi yang didedikasikan untuk menyabotase pekerjaan perak yang mendukung ekspansi Imperium. Ketika Britania mengejar perang yang tidak adil dengan Tiongkok untuk mendapatkan perak, dia harus memutuskan: Dapatkah institusi yang berkuasa diubah dari dalam, atau apakah revolusi selalu membutuhkan kekerasan?	\N	393866	74820	2022-08-23	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1716692139i/213870316.jpg	{}	{}	2025-07-17 13:53:53.287	2025-07-17 13:53:52.667
403	7876993	Marni, perempuan Jawa buta huruf yang masih memuja leluhur. Melalui sesajen dia menemukan dewa-dewanya, memanjatkan harapannya. Tak pernah dia mengenal Tuhan yang datang dari negeri nun jauh di sana. Dengan caranya sendiri dia mempertahankan hidup. Menukar keringat dengan sepeser demi sepeser uang. Adakah yang salah selama dia tidak mencuri, menipu, atau membunuh?\n\nRahayu, anak Marni. Generasi baru yang dibentuk oleh sekolah dan berbagai kemudahan hidup. Pemeluk agama Tuhan yang taat. Penjunjung akal sehat. Berdiri tegak melawan leluhur, sekalipun ibu kandungnya sendiri.\n\nAdakah yang salah jika mereka berbeda?\n\nMarni dan Rahayu, dua orang yang terikat darah namun menjadi orang asing bagi satu sama lain selama bertahun-tahun. Bagi Marni, Rahayu adalah manusia tak punya jiwa. Bagi Rahayu, Marni adalah pendosa. Keduanya hidup dalam pemikiran masing-masing tanpa pernah ada titik temu.\n\nLalu bunyi sepatu-sepatu tinggi itu, yang senantiasa mengganggu dan merusak jiwa. Mereka menjadi penguasa masa, yang memainkan kuasa sesuai keinginan. Mengubah warna langit dan sawah menjadi merah, mengubah darah menjadi kuning. Senapan teracung di mana-mana.\n\nMarni dan Rahayu, dua generasi yang tak pernah bisa mengerti, akhirnya menyadari ada satu titik singgung dalam hidup mereka. Keduanya sama-sama menjadi korban orang-orang yang punya kuasa, sama-sama melawan senjata.	\N	3828	799	2010-04-05	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1487049969i/7876993.jpg	{}	{}	2025-08-03 17:30:20.628	2025-08-03 17:30:19.912
404	209363323	殺し屋展のチケットを入手するべく奔走する坂本たち。闇オークションに望みを託すが、執拗に妨害する謎の人物との争奪戦が勃発し!?　坂本商店、X一派、ORDER──殺し屋展で“世紀の殺し合い”の幕が開く!!	\N	687	50	2024-04-04	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1711776090i/209363323.jpg	{}	{}	2025-08-03 17:30:04.702	2025-08-03 17:30:04.525
405	3714426	四人目の仲間に“呪印”の起源・重吾を加えたサスケは、目的達成のための小隊を結成！　その動きを察知する木ノ葉、“暁”もまた警戒を強める。サスケの標的をイタチに絞ったナルトは、新たな小隊と共に動き出す！！	\N	6177	132	2007-08-03	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1370140606i/3714426.jpg	{}	{}	2025-08-03 17:33:43.098	2025-08-03 17:33:42.818
406	16174176	Dimas Suryo is een beginnend journalist in de jonge republiek Indonesië. Hij heeft een vriendin en een levendige, politiek betrokken groep vrienden en collega’s. Zijn toekomst ziet er rooskleurig uit. Maar dan gebeurt het ondenkbare.\n\nWanneer Dimas in het buitenland is, wordt er thuis een coup gepleegd. Opeens mogen hij en zijn vrienden hun eigen land niet meer in. Terwijl hun naasten worden vermoord of gemarteld, moeten deze jonge mannen zich verzoenen met een leven in ballingschap, in Parijs. Er is maar één plek waar Dimas zich dicht bij huis voelt: achter de pannen, waar hij de smaken en geuren oproept van het Indonesië dat hij zo mist.	\N	9196	1556	2012-12-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1465061573i/16174176.jpg	{}	{}	2025-08-04 07:49:10.133	2025-08-04 07:49:09.471
407	28446637	Tentang persahabatan\nTentang cinta\nTentang perpisahan\nTentang melupakan\nTentang hujan	\N	18381	2707	2016-01-28	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1451905281i/28446637.jpg	{}	{}	2025-08-05 06:24:15.492	2025-08-05 06:24:14.864
408	71037196	Takopi, makhluk dari Planet Happy, turun ke bumi untuk menyebarkan kebahagiaan. Takopi berusaha agar Shizuka kembali berbahagia, namun Takopi terseret ke dalam lingkungan Shizuka yang sangat emosional dan tidak terbayangkan sebelumnya oleh Takopi yang naif.\nTakopi hanya ingin Shizuka kembali tersenyum. Lalu dosa seperti apa yang dilakukan Takopi…!?	\N	1388	187	2022-03-04	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1671449355i/71037196.jpg	{}	{}	2025-08-11 08:52:19.575	2025-08-11 08:52:18.929
409	93850474	Tubuh kaku Marina ditemukan. Walaupun polisi telah menjelaskan situasinya, perhatian Shizuka terfokus pada rencana liburan di musim panas, sehingga Azuma yang harus berusaha agar mereka tidak dicurigai. Saat liburan musim panas tiba, Shizuka dan Takopi memulai perjalanan menuju Tokyo.	\N	1032	140	2022-04-04	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1675213466i/93850474.jpg	{}	{}	2025-08-11 08:51:30.058	2025-08-11 08:51:29.442
410	5463398	To truly end the Akatsuki's reign of pain, Naruto's teacher Jiraiya must delve deep into the past to uncover the secret of Pain's origin. At the same time, Sasuke moves toward the final battle of the Uchiha brothers when he closes in on the elusive Itachi!	\N	7561	196	2008-05-02	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1435527231i/5463398.jpg	{}	{}	2025-08-19 18:07:59.624	2025-08-19 18:07:59.012
411	51811500	Ketika Pengelana Waktu mendapati dirinya berada pada tahun 802.701, ia bertemu dengan masyarakat utopis dari manusia yang berevolusi, tapi kemudian menggali rahasia kelam yang mengarahkan umat manusia menuju kehancuran yang tak terhindarkan.	\N	554575	18648	1895-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1582766641i/51811500.jpg	{}	{}	2025-08-21 16:51:12.062	2025-08-21 16:51:11.404
412	201672348		\N	6	1	\N	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1699281418i/201672348.jpg	{}	{}	2025-08-22 19:28:14.492	2025-08-22 19:28:13.873
413	52314860	Hanamichi colleziona espulsioni, ma con l’apporto di Miyagi e Mitsui lo Shohoku avanza nel torneo di qualificazione all’inter-high. L’accesso alla fase finale è vicino, però ora l’avversario è il fortissimo Shoyo, fra le teste di serie della competizione.	\N	462	35	2018-07-02	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1677773605i/52314860.jpg	{}	{}	2025-08-25 04:39:01.442	2025-08-25 04:39:00.854
414	13487232	Tentang mereka yang terusir karena iman di negeri yang penuh keindahan.\n\nLombok, Januari 2011\n\nKami hanya ingin pulang. Ke rumah kami sendiri. Rumah yang kami beli dengan uang kami sendiri. Rumah yang berhasil kami miliki lagi dengan susah payah, setelah dulu pernah diusir dari kampung-kampung kami. Rumah itu masih ada di sana. Sebagian ada yang hancur. Bekas terbakar di mana-mana. Genteng dan tembok yang tak lagi utuh. Tapi tidak apa-apa. Kami mau menerimanya apa adanya. Kami akan memperbaiki sendiri, dengan uang dan tenaga kami sendiri. Kami hanya ingin bisa pulang dan segera tinggal di rumah kami sendiri. Hidup aman. Tak ada lagi yang menyerang. Biarlah yang dulu kami lupakan. Tak ada dendam pada orang-orang yang pernah mengusir dan menyakiti kami. Yang penting bagi kami, hari-hari ke depan kami bisa hidup aman dan tenteram.\n\nKami mohon keadilan. Sampai kapan lagi kami harus menunggu?\n\nMaryam Hayati\n\n\n== Pengarang 5 Besar Khatulistiwa Literary Award 2011 ==	\N	1242	261	2012-02-23	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1329385948i/13487232.jpg	{}	{}	2025-09-01 05:40:06.181	2025-09-01 05:40:05.502
417	36538793	Tanjiro sets out on the path of the Demon Slayer to save his sister and avenge his family!\n\nIn Taisho-era Japan, Tanjiro Kamado is a kindhearted boy who makes a living selling charcoal. But his peaceful life is shattered when a demon slaughters his entire family. His little sister Nezuko is the only survivor, but she has been transformed into a demon herself! Tanjiro sets out on a dangerous journey to find a way to return his sister to normal and destroy the demon who ruined his life.\n\n Learning to slay demons won’t be easy, and Tanjiro barely knows where to start. The surprise appearance of another boy named Giyu, who seems to know what’s going on, might provide some answers…but only if Tanjiro can stop Giyu from killing his sister first!	\N	127430	3237	2016-06-06	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1560396935i/36538793.jpg	{}	{}	2025-09-02 19:25:06.645	2025-09-02 19:25:05.952
418	38926432	Tanjiro sets out on the path of the Demon Slayer to save his sister and avenge his family!\n\nIn Taisho-era Japan, Tanjiro Kamado is a kindhearted boy who makes a living selling charcoal. But his peaceful life is shattered when a demon slaughters his entire family. His little sister Nezuko is the only survivor, but she has been transformed into a demon herself! Tanjiro sets out on a dangerous journey to find a way to return his sister to normal and destroy the demon who ruined his life.\n\nDuring final selection for the Demon Slayer Corps, Tanjiro faces a disfigured demon and uses the techniques taught by his master, Urokodaki! As Tanjiro begins to walk the path of the Demon Slayer, his search for the demon who murdered his family leads him to investigate the disappearances of young girls in a nearby town.	\N	30511	1142	2016-08-04	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1527540863i/38926432.jpg	{}	{}	2025-09-02 19:25:38.05	2025-09-02 19:25:37.345
419	5822950	Naruto must decipher the cryptic last words of his beloved mentor. What did Jiraiya find out about the leader of the Akatsuki that was so important he had to hide it in code? And can Naruto stand a fighting chance against those who managed to take down one of the Three Great Shinobi?	\N	6258	151	2008-11-04	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1435527237i/5822950.jpg	{}	{}	2025-09-03 13:56:05.078	2025-09-03 13:56:04.375
420	364955	If Luffy wants to get out of a year's worth of chore-boy duty on the oceangoing restaurant Baratie, he's got to rid the seas of the evil Don Krieg. Unfortunately, Krieg's armed to the teeth and aided by his "Demon Man," Commander Gin. The battle takes a surprising turn as Krieg reveals his increasingly deadly military might! Meanwhile, Nami has sailed off on the Merry Go with treasure in tow, and she's headed to Arlong Park, home of creepy Captain Arlong and his Fish-Man Pirates. What business does Nami have at Arlong Park, anyway? Something fishy is going on and Luffy's crew just may be in over their heads!	\N	23149	656	1999-04-27	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1630542699i/364955.jpg	{}	{}	2025-09-03 17:55:57.773	2025-09-03 17:55:57.132
421	54390224	La partita contro il Kainan non poteva rivelarsi più difficile per lo Shohoku, che fa i conti con l'infortunio di Akagi e l'inesperienza di Hanamichi. Punto dopo punto, i ragazzi di Anzai stanno tenendo testa al "re" di Kanagawa, ma per fermare il numero uno Maki, affamato di vittoria, dovranno giocarsi il tutto per tutto.	\N	415	31	2018-07-02	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1677773741i/54390224.jpg	{}	{}	2025-09-05 00:36:56.979	2025-09-05 00:36:56.311
422	54625224	Gli incontri del girone finale sono cominciati. Mentre lo Shohoku si allena per agguantare la qualificazione all'inter-high, scendono in campo i loro avversari. È il momento di assistere a un'altra sfida mozzafiato, quella tra il Kainan di Maki e il Ryonan di Sendo.	\N	382	24	2018-07-02	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1595340813i/54625224.jpg	{}	{}	2025-09-06 18:08:14.485	2025-09-06 18:08:13.795
423	1795582	ceramah pada tanggal 6 April 1977 di Taman Ismail Marzuki- Jakarta	\N	942	132	1977-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1493097413i/1795582.jpg	{}	{}	2025-09-07 14:07:06.095	2025-09-07 14:07:05.474
424	1921356	Suasana tak menentu seperti yang terjadi di Jakarta, dimanfaatkan dengan baik oleh orang yang mempunyai sifat bunglon, salah satu di antaranya adalah Halim. Pada saat Partai Indonesia berkuasa. Halim memihak partai tersebut. Ia memperoleh sejumlah besar uang untuk surat kabar yang dipimpinnya. Tentu saja, sebagian besar masuk ke kantongnya dan mendapat “hadiah” dari Partai Indonesia menjadi anggota parlemen. Ketika Partai Indonesia tak kuat menahan serangan oposisi, Halim berpihak pada oposisi dan berbalik menyerang partai yang dahulu memberi fasilitas kepadanya.	\N	931	166	1963-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1470901180i/1921356.jpg	{}	{}	2025-09-11 16:26:39.881	2025-09-11 16:26:39.162
425	52758085	From award-winning author Naoki Urasawa comes a tale of crushing debt, a broken marriage, and the painting that can fix it all—if Kasumi and her dad can manage to steal it.\n\nKamoda will do anything to earn a quick buck, even if it means skipping out on his taxes to take his wife on a luxury cruise. But when a random tax audit bankrupts his family, Kamoda soon discovers his wife has taken that cruise after all—only without Kamoda or their daughter Kasumi.\n\nDesperate to provide, Kamoda invests in a scheme to mass-produce masks of controversial American presidential candidate Beverly Duncan. But a lackluster election kills their sales potential, burying Kamoda under a mountain of masks and debt. On the verge of despair, Kamoda discovers a sign that leads him to the Director, an art fanatic who vows he can make all of Kamoda and Kasumi’s dreams come true.	\N	1118	182	2018-11-22	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1590787742i/52758085.jpg	{}	{}	2025-09-11 19:57:43.918	2025-09-11 19:57:43.788
426	41733839	Alternate covers of this ISBN can be found here and here.\n\nJames L.W. West III to include the author’s final revisions and features a note on the composition and text, a personal foreword by Fitzgerald’s granddaughter, Eleanor Lanahan—and a new introduction by two-time National Book Award winner Jesmyn Ward.\n\nThe Great Gatsby, F. Scott Fitzgerald’s third book, stands as the supreme achievement of his career. First published in 1925, this quintessential novel of the Jazz Age has been acclaimed by generations of readers. The story of the mysteriously wealthy Jay Gatsby and his love for the beautiful Daisy Buchanan, of lavish parties on Long Island at a time when The New York Times noted “gin was the national drink and sex the national obsession,” it is an exquisitely crafted tale of America in the 1920s.	\N	5778209	125010	1925-04-10	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1650033243i/41733839.jpg	{}	{}	2025-09-13 03:29:30.086	2025-09-13 03:29:29.349
427	213790753	Xに利用されていると知りながら任務を遂行しようとする真冬。必死に説得するシンだが、そこに大佛が乱入!!　動き始めたORDERとXの次なる一手により戦場と化した展覧会場で、奔走する坂本たちだが…!?	\N	647	57	2024-06-04	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1717725237i/213790753.jpg	{}	{}	2025-09-13 18:54:57.091	2025-09-13 18:54:56.421
428	1455480	Dalam cerpen "Robohnya Surau Kami", berdialoglah Tuhan dengan Haji Saleh, seorang warga negara Indonesia yang selama hidupnya hanya beribadah dan beribadah…\n"kenapa engkau biarkan dirimu melarat, hingga anak cucumu teraniaya semua. Sedang harta bendamu kau biarkan orang lain yang mengambilnya untuk anak cucu mereka. Dan engkau lebih suka berkelahi antara kamu sendiri, saling menipu, saling memeras. Aku beri kau negeri yang kaya raya, tapi kau malas. Kau lebih suka beribadat saja, karena beribadat tidak mengeluarkan peluh, tidak membanting tulang. Sedang aku menyuruh engkau semuanya beramal di samping beribadat. Bagaimana engkau bisa beramal kalau engkau miskin. Engkau kira aku ini suka pujian, mabuk disembah saja, hingga kerjamu lain tidak memuji-muji dan menyembahku saja.\nTidak..." Semua jadi pucat pasi tak berani berkata apa - apa lagi. Tahulah mereka sekarang apa jalan yang diridai Allah di dunia.	\N	3336	311	1956-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1466437017i/1455480.jpg	{}	{}	2025-09-14 13:36:57.869	2025-09-14 13:36:57.242
429	29621622	Guiada por amor e ódio, Eva insiste em sua perseguição a seu ex-noivo Tenma. Em certo dia de sua vida de depravação, ela conhece um homem misterioso... Quem é ele? E onde está Tenma?	\N	3020	103	1997-05-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1458970403i/29621622.jpg	{}	{}	2025-09-19 08:21:29.908	2025-09-19 08:21:29.215
430	1511836	Aku insinyur. Aku tak bisa menguraikan dengan baik hubungan antara kejujuran dan kesungguhan dalam pembangunan proyek ini dengan keberpihakan kepada masyarakat miskin. Apakah yang pertama merupakan manifestasi yang kedua? Apakah kejujuran dan kesungguhan sejatinya adalah perkara biasa bagi masyarakat berbudaya, dan harus dipilih karena keduanya merupakan hal yang niscaya untuk menghasilkan kemaslahatan bersama?\n\n\nMemahami proyek pembangunan jembatan di sebuah desa bagi Kabul, insinyur yang mantan aktivis kampus, sungguh suatu pekerjaan sekaligus beban psikologis yang berat. "Permainan" yang terjadi dalam proyek itu menuntut konsekuensi yang pelik. Mutu bangunan menjadi taruhannya, dan masyarakat kecillah yang akhirnya menjadi korban. Akankah Kabul bertahan pada idealismenya? Akankah jembatan baru itu mampu memenuhi dambaan lama penduduk setempat?	\N	2208	459	2002-01-01	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1359439571i/1511836.jpg	{}	{}	2025-09-20 05:21:21.226	2025-09-20 05:21:20.552
431	38926402	Tanjiro sets out on the path of the Demon Slayer to save his sister and avenge his family!\n\nIn Taisho-era Japan, Tanjiro Kamado is a kindhearted boy who makes a living selling charcoal. But his peaceful life is shattered when a demon slaughters his entire family. His little sister Nezuko is the only survivor, but she has been transformed into a demon herself! Tanjiro sets out on a dangerous journey to find a way to return his sister to normal and destroy the demon who ruined his life.\n\nTanjiro and Nezuko cross paths with two powerful demons who fight with magical weapons. Even help from Tamayo and Yushiro may not be enough to defeat these demons who claim to belong to the Twelve Kizuki that directly serve Kibutsuji, the demon responsible for all of Tanjiro’s woes! But if these demons can be defeated, what secrets can they reveal about Kibutsuji?	\N	26431	1027	2016-10-04	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1530434213i/38926402.jpg	{}	{}	2025-09-22 05:34:16.485	2025-09-22 05:34:15.866
432	40680067	Tanjiro sets out on the path of the Demon Slayer to save his sister and avenge his family!\n\nIn Taisho-era Japan, Tanjiro Kamado is a kindhearted boy who makes a living selling charcoal. But his peaceful life is shattered when a demon slaughters his entire family. His little sister Nezuko is the only survivor, but she has been transformed into a demon herself! Tanjiro sets out on a dangerous journey to find a way to return his sister to normal and destroy the demon who ruined his life.\n\nAfter a fierce battle with a demon inside a maddening house of ever-changing rooms, Tanjiro has a chance to find out about the fighter in the boar-head mask. Who is this passionate swordsman and what does he want? Later, a new mission has Tanjiro and his compatriots heading for Mt. Natagumo and a confrontation with a mysterious and horrifying threat…	\N	22475	867	2016-12-02	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1537729452i/40680067.jpg	{}	{}	2025-09-22 05:34:35.491	2025-09-22 05:34:34.85
433	55135379	È arrivato il giorno dell'ultima partita del girone finale di qualificazione. Lo Shohoku fa i conti con la pesante assenza del coach Anzai e con la consapevolezza che non sono ammessi errori: perdere contro l'agguerritissimo Ryonan di Uozumi, Sendo e Fukuda significa rinunciare per sempre al sogno del campionato nazionale.	\N	383	21	2018-07-02	\N	\N	\N	\N	\N	\N	https://images-na.ssl-images-amazon.com/images/S/compressed.photo.goodreads.com/books/1598481356i/55135379.jpg	{}	{}	2025-09-24 18:51:53.851	2025-09-24 18:51:53.205
434	55374674	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	{}	{}	2025-10-08 07:08:11.671	2025-10-08 07:08:10.988
435	5527835	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	{}	{}	2025-10-13 18:52:29.679	2025-10-13 18:52:29.008
436	33848032	"Pekerjaan saya memang kedengaran membosankan— mengelilingi tempat yang itu-itu saja, diisi kaki-kaki berkeringat dan orang-orang berisik, diusik cicak-cicak kurang ajar, mendengar lagu aneh tentang tahu berbentuk bulat dan digoreng tanpa persiapan sebelumnya—tapi saya menggemarinya. Saya senang mengetahui cerita manusia dan kecoa dan tikus dan serangga yang mampir. Saya senang melihat-lihat isi tas yang terbuka, membaca buku yang dibalik-balik di kursi belakang, turut mendengarkan musik yang dinyanyikan di kepala seorang penumpang… bahkan kadang-kadang, menyaksikan aksi pencurian. \n\nTrayek saya memang hanya melewati Dipatiukur-Leuwipanjang, sebelum akhirnya bertemu Beliau, dan memulai trayek baru: mengelilingi angkasa, melintasi dimensi ruang dan waktu."	\N	3394	850	2017-02-03	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1484281533i/33848032.jpg	{}	{}	2025-11-08 17:30:41.895	2025-11-08 17:30:41.714
437	55685278	Il match che decide chi tra Shohoku e Ryonan parteciperà al campionato nazionale è agli sgoccioli. Akagi e compagni sono in vantaggio, ma iniziano a cedere alla pressione, mentre la squadra di Uozumi si è ritrovata e ora si lancia all'attacco con Sendo. Ancora una manciata di minuti e per uno dei due club si apriranno le porte dell'inter-high.	\N	369	35	2018-08-01	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1602812080i/55685278.jpg	{}	{}	2025-11-08 17:21:45.736	2025-11-08 17:21:45.623
438	55817473	Magi Diela diculik dan dijinakkan seperti binatang. Sirna sudah impiannya membangun Sumba. Kini dia harus melawan orangtua, seisi kampung, dan adat yang ingin merenggut kemerdekaannya sebagai perempuan. Ketika budaya memenjarakan hati Magi yang meronta, dia harus memilih sendiri nerakanya: meninggalkan orangtua dan tanah kelahirannya, menyerahkan diri kepada si mata keranjang, atau mencurangi kematiannya sendiri.\n\nPerempuan yang Menangis kepada Bulan Hitam ditulis berdasarkan pengalaman banyak perempuan korban kawin tangkap di Sumba. Tradisi kawin tangkap menggedor hati Dian Purnomo untuk menyuarakan jerit perempuan yang seolah tak terdengar bahkan oleh Tuhan sekalipun.	\N	3503	934	2020-11-01	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1604022613i/55817473.jpg	{}	{}	2025-11-07 03:45:35.64	2025-11-07 03:45:35.479
439	55852858	Il match che decide chi tra Shohoku e Ryonan parteciperà al campionato nazionale è agli sgoccioli. Akagi e compagni sono in vantaggio, ma iniziano a cedere alla pressione, mentre la squadra di Uozumi si è ritrovata e ora si lancia all'attacco con Sendo. Ancora una manciata di minuti e per uno dei due club si apriranno le porte dell'inter-high.	\N	347	19	2018-08-01	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1604666487i/55852858.jpg	{}	{}	2025-11-08 17:30:54.694	2025-11-08 17:30:54.543
440	56157418	Con lo Shohoku giunto a Hiroshima e pronto a debuttare sul palcoscenico nazionale, si accendono i riflettori sull'inter-high. Akagi e compagni dovranno farsi valere contro team prestigiosi, affrontando con coraggio alcuni fra i giocatori più forti di tutto il Giappone.	\N	343	22	2018-09-01	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1607074410i/56157418.jpg	{}	{}	2025-11-08 17:21:58.404	2025-11-08 17:21:58.273
441	56556196	Per lo shohoku è già tempo di pensare alla seconda partita dell'inter-high prossimi avversari, i campioni del sannoh kogyo. La squadra più importante del basket liceale giapponese ha dalla sua il favore dei pronostici e il sostegno di tutto il pubblico. I ragazzi del coach anzai sapranno reggere una simile pressione?	\N	332	22	2018-09-01	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1677775231i/56556196.jpg	{}	{}	2025-11-08 17:19:26.801	2025-11-08 17:19:26.147
442	57011927	La squadra di Akagi sta dando prova di carattere e abilità, e si porta in vantaggio sul Sannoh Kogyo, per lo stupore del pubblico accorso ad ammirare il “re” del basket liceale. La partita, però, è appena iniziata e il coach Domoto non intende sottovalutare gli avversari, per quanto sconosciuti.	\N	307	18	2018-09-01	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1612888719i/57011927.jpg	{}	{}	2025-11-08 17:21:30.196	2025-11-08 17:21:30.082
443	55754438	比賽下半場，山王工業展現了全國大賽３連霸的實力。 然而不願放棄的湘北板凳球員，將希望全部寄託在花道身上！ 花道依照安西教練的指示，拚命搶進攻籃板球， 湘北的節奏因而逐漸產生了變化……！	\N	309	20	2018-09-01	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1603283100i/55754438.jpg	{}	{}	2025-11-08 17:22:10.285	2025-11-08 17:22:10.171
444	55755352	湘北驚人的頑強抵抗力，讓山王工業頓失王者的從容！ 偏偏「超級王牌」澤北在緊要關頭阻擋了湘北的攻勢， 使得兩隊比數再度拉開…… 面對澤北壓倒性的自信與運動能力，流川會如何因應──？	\N	310	17	2018-09-01	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1603291702i/55755352.jpg	{}	{}	2025-11-08 17:31:56.793	2025-11-08 17:31:56.631
445	694454	A succinct presentation of the philosophical foundations of Marxism.	\N	2116	217	1938-09-01	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1360395708i/694454.jpg	{}	{}	2025-11-08 17:29:22.929	2025-11-08 17:29:22.77
446	1025847	SENO GUMIRA AJIDARMA dilahirkan tahun 1958, mengenal teater ketika bergabung dengan Teater Alam pimpinan Azwar AN pada 1975. Menulis naskah sandiwara pertama kali pada 1976, berjudul Pertunjukan Segera Dimulai. Politik kekerasan yang berlangsung menjelang Reformasi 1998, mendorong dituliskannya Mengapa Kau Culik Anak Kami? (1999), yang kelak disusul sekuelnya, monolog Ibu yang Anaknya Diculik Itu (2008); dan Jakarta 2039 (2000)—menjadikan ketiganya sebagai drama faktual. Dari tahun ke tahun ketiganya telah terus-menerus dipentaskan.\n\nPenerbitan kembali setelah lebih dari dua dekade, juga menandai wacana sosial politiknya yang tetap relevan dan dibutuhkan.	\N	115	19	2001-01-01	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1369576421i/1025847.jpg	{}	{}	2025-11-08 17:21:05.861	2025-11-08 17:21:05.746
447	1362193	Begitu banyak hal menakjubkan yang terjadi dalam masa kecil para anggota Laskar Pelangi. Sebelas orang anak Melayu Belitong yang luar biasa ini tak menyerah walau keadaan tak bersimpati pada mereka. Tengoklah Lintang, seorang kuli kopra cilik yang genius dan dengan senang hati bersepeda 80 kilometer pulang pergi untuk memuaskan dahaganya akan ilmu—bahkan terkadang hanya untuk menyanyikan Padamu Negeri di akhir jam sekolah. Atau Mahar, seorang pesuruh tukang parut kelapa sekaligus seniman dadakan yang imajinatif, tak logis, kreatif, dan sering diremehkan sahabat-sahabatnya, namun berhasil mengangkat derajat sekolah kampung mereka dalam karnaval 17 Agustus. Dan juga sembilan orang Laskar Pelangi lain yang begitu bersemangat dalam menjalani hidup dan berjuang meraih cita-cita. Selami ironisnya kehidupan mereka, kejujuran pemikiran mereka, indahnya petualangan mereka, dan temukan diri Anda tertawa, menangis, dan tersentuh saat membaca setiap lembarnya. Buku ini dipersembahkan buat mereka yang meyakini the magic of childhood memories, dan khususnya juga buat siapa saja yang masih meyakini adanya pintu keajaiban lain untuk mengubah dunia: pendidikan.	\N	32157	4194	2005-01-01	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1489732961i/1362193.jpg	{}	{}	2025-11-08 17:21:18.965	2025-11-08 17:21:18.854
448	18414	In his most famous and controversial book, Utopia, Thomas More imagines a perfect island nation where thousands live in peace and harmony, men and women are both educated, and all property is communal. Through dialogue and correspondence between the protagonist Raphael Hythloday and his friends and contemporaries, More explores the theories behind war, political disagreements, social quarrels, and wealth distribution and imagines the day-to-day lives of those citizens enjoying freedom from fear, oppression, violence, and suffering. Originally written in Latin, this vision of an ideal world is also a scathing satire of Europe in the sixteenth century and has been hugely influential since publication, shaping utopian fiction even today.	\N	81949	5052	1516-01-01	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1388190168i/18414.jpg	{}	{}	2025-11-08 17:23:59.075	2025-11-08 17:23:58.952
449	40680065	Un cop arribats al mont Natagumo, en Tanjirô i companyia es veuen obligats a lliurar una cruenta batalla contra una família de dimonis aranya. Mentre en Zenitsu lluita contra els efectes d’un verí que l’està convertint en un ésser aràcnid, l’Inosuke i en Tanjirô s’han d’enfrontar al pare de la família, qui no els ho pensa posar gens fàcil... Seran capaços de trobar una sortida a aquesta situació desesperada...?	\N	20126	842	2017-03-03	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1545498525i/40680065.jpg	{}	{}	2025-11-07 03:43:33.508	2025-11-07 03:43:33.369
450	212724981	Buku kumpulan cerpen terbaik Edgar Allan Poe ini memuat: \n- The Tell-Tale Heart (Degup Jantung Jahanam)\n- The Cask of Amontillado (Tong Amontillado) \n- The Fall of the House of Usher (Runtuhnya Rumah Keluarga Usher) \n- The Pit and the Pendulum (Jurang dan Pendulum)\n- The Black Cat (Kucing Hitam) \n- The Masque of the Red Death (Pesta Topeng Maut Merah) \n- The Oval Portrait (Lukisan Berbingkai Oval) \n- The Premature Burial (Penguburan Hidup-Hidup)	\N	74794	792	1960-01-01	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1714798227i/212724981.jpg	{}	{}	2025-11-08 17:26:27.286	2025-11-08 17:26:27.141
451	241910439	TEMAN SAYA MENGHILANG.\n\nJika Anda memiliki informasi, mohon hubungi saya.\nTeman saya adalah editor baru yang sempat memegang proyek untuk edisi khusus sebuah majalah okultisme. Karena tugas tersebut, ia mengumpulkan dokumen dan materi dari berbagai sumber hingga akhirnya menyadari keanehan yang tersembunyi di suatu tempat di wilayah Kinki ….\n\nBuku ini merangkum berbagai tulisan dari sejumlah media yang ia dan saya kumpulkan. Sebagian besar dari tulisan di dalamnya memiliki keterkaitan dengan “suatu tempat” di wilayah Kinki.\n\nOleh karena itu, saya butuh bantuan. Jika Anda memiliki informasi, mohon hubungi saya.	\N	169	39	2023-08-30	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1758510601i/241910439.jpg	{}	{}	2025-11-07 03:45:48.149	2025-11-07 03:45:47.969
452	240342272	Seorang pemuda pemalu meninggalkan kampung halamannya di Turki untuk mempelajari sebuah keahlian dan menjelajahi kehidupan di Berlin pada tahun 1920-an. Jalanan yang ramai, museum-museum yang elegan, dan klub malam di kota itu, menjadi latar belakang pertemuan tak terduga dengan seorang wanita yang akan menghantui hidupnya selamanya.	\N	93332	12071	1943-03-01	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1755584775i/240342272.jpg	{}	{}	2025-11-08 17:20:31.857	2025-11-08 17:20:31.725
453	42633905	Tanjiro sets out on the path of the Demon Slayer to save his sister and avenge his family!\n\nIn Taisho-era Japan, Tanjiro Kamado is a kindhearted boy who makes a living selling charcoal. But his peaceful life is shattered when a demon slaughters his entire family. His little sister Nezuko is the only survivor, but she has been transformed into a demon herself! Tanjiro sets out on a dangerous journey to find a way to return his sister to normal and destroy the demon who ruined his life.\n\nThe members of the Demon Slayer Corps are sworn to destroy demons wherever they find them—but the condition of Tanjiro’s sister, Nezuko, is a problem. What will the Hashira—the leaders of the Demon Slayer Corps—do about Tanjiro protecting his own demonic sister? Meanwhile, Kibutsuji assembles his own minions and intensifies his search for Tanjiro…	\N	18987	735	2017-05-02	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1549012251i/42633905.jpg	{}	{}	2025-11-07 03:43:47.136	2025-11-07 03:43:46.984
454	58022578	Contro ogni pronostico. Lo Shohoku si è dimostrato un avversario tenace per i campioni del Sannoh Kogyo. A un soffio dalla fine del match non c’è più tempo per le incertezze. Nel momento cruciale, però, Hanamichi paga la sua avventatezza e ogni speranza di rimonta sembra svanire.	\N	356	49	2018-09-01	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1677775358i/58022578.jpg	{}	{}	2025-11-08 17:31:43.955	2025-11-08 17:31:43.772
455	214921144	南雲の一撃により深傷を負った楽。死闘は決着までのTAに突入し…!?　地下階でXと殺連会長・麻樹が邂逅する一方、上階ではハルマ＆熊埜御と神々廻＆シンが激突!!　仲間に後を託し、Xの元へ急ぐ坂本だが…!?	\N	610	45	2024-08-02	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1722655781i/214921144.jpg	{}	{}	2025-11-08 17:22:23.824	2025-11-08 17:22:23.715
456	42633909	Tanjiro sets out on the path of the Demon Slayer to save his sister and avenge his family!\n\nIn Taisho-era Japan, Tanjiro Kamado is a kindhearted boy who makes a living selling charcoal. But his peaceful life is shattered when a demon slaughters his entire family. His little sister Nezuko is the only survivor, but she has been transformed into a demon herself! Tanjiro sets out on a dangerous journey to find a way to return his sister to normal and destroy the demon who ruined his life.\n\nShinobu, Tanjiro, Zenitsu, Inosuke and Nezuko have recovered while under the care of the Demon Slayer Corps. They have even learned a new and powerful technique—Total Concentration! They’ll need this new power and all their skill on their next demon-hunting mission aboard the mysterious Infinity Train as it takes them into the dreams of demons!	\N	19173	776	2017-08-04	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1554035573i/42633909.jpg	{}	{}	2025-11-08 17:32:10.293	2025-11-08 17:32:10.137
457	43909410	Tanjiro sets out on the path of the Demon Slayer to save his sister and avenge his family!\n\nIn Taisho-era Japan, Tanjiro Kamado is a kindhearted boy who makes a living selling charcoal. But his peaceful life is shattered when a demon slaughters his entire family. His little sister Nezuko is the only survivor, but she has been transformed into a demon herself! Tanjiro sets out on a dangerous journey to find a way to return his sister to normal and destroy the demon who ruined his life.\n\nAfter dealing with several demonic enemies aboard the Infinity Train, Tanjiro, Zenitsu and Inosuke must face the demon spirt of the train itself! Even if they can stop the demon train, the minions of Muzan Kibutsuji are still out there and Tanjiro must continue to improve his strength and skills. Learning the secret of the Hikonami Kagura and Flame Breathing will give him a powerful new advantage!	\N	19851	1298	2017-10-04	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1555840106i/43909410.jpg	{}	{}	2025-11-08 17:23:00.544	2025-11-08 17:23:00.399
458	27415387	The once popular game Yggdrasil was supposed to shut down that day. Everyone was supposed to be logged out automatically. But the players who stayed online past the moment the servers went quiet found themselves transported to a game world made real. Leading them is Momonga--a man whose love of games in the real world brought him only loneliness, now a skeletal sorcerer. The legends of Momonga and his guild begin here!	\N	6284	366	2012-07-30	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1460312275i/27415387.jpg	{}	{}	2025-11-08 17:22:49.91	2025-11-08 17:22:49.771
459	43909413	Tanjiro sets out on the path of the Demon Slayer to save his sister and avenge his family!\n\nIn Taisho-era Japan, Tanjiro Kamado is a kindhearted boy who makes a living selling charcoal. But his peaceful life is shattered when a demon slaughters his entire family. His little sister Nezuko is the only survivor, but she has been transformed into a demon herself! Tanjiro sets out on a dangerous journey to find a way to return his sister to normal and destroy the demon who ruined his life.\n\nTanjiro and his friends accompany the Hashira Tengen Uzui to an entertainment district where Tengen’s female ninja agents were gathering information on a demon, but suddenly disappeared. In order to investigate, Tanjiro and the others disguise themselves as women to sneak in! As they close in on their target, the demon reaches out for the courtesans of the district!	\N	18178	780	2017-12-04	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1565526386i/43909413.jpg	{}	{}	2025-11-08 17:30:09.61	2025-11-08 17:30:09.408
503	\N	Empat “iblis emosi” yang dapat membelah diri, Hantengu, kini bergabung dan menyisakan si wujud asli lalu menyerang Tanjiro dan kawan-kawan! Di tengah pertempuran sengit itu, kemarahan Tanjiro meluap saat Hantengu menyebutnya telah menindas yang “lemah”. Di sisi lain, Kasumibashira Tokito mendapatkan kembali ingatannya yang hilang saat berhadapan dengan Gyokko dan terjadi suatu perubahan di dirinya…!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1688776053i/185650221.jpg	\N	\N	2026-01-16 07:11:50.243153	2026-01-16 07:11:50.243153
460	52228762	Tanjiro sets out on the path of the Demon Slayer to save his sister and avenge his family!\n\nIn Taisho-era Japan, Tanjiro Kamado is a kindhearted boy who makes a living selling charcoal. But his peaceful life is shattered when a demon slaughters his entire family. His little sister Nezuko is the only survivor, but she has been transformed into a demon herself! Tanjiro sets out on a dangerous journey to find a way to return his sister to normal and destroy the demon who ruined his life.\n\nDespite some comic misunderstandings that almost blow their cover, Tanjiro, Inosuke and Zenitsu smoke out Daki, a demon that has been devouring the residents of the entertainment district for years. The Hashira Tengen Uzui and his ninja companions engage Daki, but if they cannot handle her, will Tanjiro and his friends be able to take on one of Kibutsuji’s Upper-Ranked demons by themselves?	\N	17822	680	2018-03-02	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1566731670l/52228762.jpg	{}	{}	2025-11-07 03:46:04.136	2025-11-07 03:46:03.985
461	51245114	Tanjiro sets out on the path of the Demon Slayer to save his sister and avenge his family!\n\nIn Taisho-era Japan, Tanjiro Kamado is a kindhearted boy who makes a living selling charcoal. But his peaceful life is shattered when a demon slaughters his entire family. His little sister Nezuko is the only survivor, but she has been transformed into a demon herself! Tanjiro sets out on a dangerous journey to find a way to return his sister to normal and destroy the demon who ruined his life.\n\nThe battle against the powerful sibling demons Gyutaro and Daki is not going well. Although finally able to fight alongside Tanjiro against the monsters, Zenitsu, Inosuke and even the Hashira Tengen Uzui get knocked out of the fight, and Tanjiro stands alone. Battling even one of Lord Muzan’s Twelve Kizuki is hard enough for one of the top Demon Slayers—what chance does Tanjiro have?	\N	16403	715	2018-06-04	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1573919151l/51245114.jpg	{}	{}	2025-11-07 03:46:42.412	2025-11-07 03:46:42.254
462	6435922	Naruto inches ever closer to discovering the true identity of his nemesis, Pain. But is it worth it as the frustrated ninja begins to morph at last into the dreaded Nine Tails? Plus an unexpected confession reveals incredible secrets about his past as Naruto prepares for the ultimate battle with Pain. Can the chakra-challenged Naruto win when one misstep could spell disaster?	\N	7009	207	2009-08-04	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1435527327i/6435922.jpg	{}	{}	2025-11-08 17:26:17.382	2025-11-08 17:26:17.258
463	1307394	Cerita ini berkisar tentang semangat juang Zainuddin, bagaimana merana dan melaratnya hidup Zainuddin setelah cintanya ditolak oleh keluarga Hayati. Kemudian beliau bangun semula dari segala kedukaan, membuka lembaran baru dalam hidupnya menjadi seorang penulis yang ternama dan berjaya. Ia menceritakan tentang kesetiaan, cinta dan kasihnya Zainuddin terhadap Hayati. Meski Hayati sudah berkahwin tetapi sebaik mendapat tahu tentang kesusahan yang dihadapi Hayati, lantaran suaminya yang suka berpoya-poya serta tidak bertanggung-jawab, Zainuddin terus membantu tanpa ada dendam dan benci. Sesungguhnya cinta yang suci itu akan terus mekar di dalam hati hingga ke hujung nyawa begitulah jua cinta antara Zainuddin dan Hayati.\nSumber: Laman web KKUM.	\N	6143	777	1937-01-01	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1468645608i/1307394.jpg	{}	{}	2025-11-08 17:20:54.046	2025-11-08 17:20:53.375
464	1302793	Bekisar, unggas elok hasil kawin silang antara ayam hutan dan ayam biasa sering menjadi hiasan rumah orang-orang kaya. Dan, adalah Lasi yang berayah bekas serdadu Jepang; kulitnya yang putih dan matanya yang khas membawa dirinya menjadi bekisar untuk hiasan sebuah gedung dan kehidupan megah seorang lelaki kaya di Jakarta. Lahir dalam keluarga petani gula kelapa sebuah desa di pedalaman, Lasi terbawa arus sejarah hidupnya sendiri dan berlabuh dalam kemewahan kota yang tak pernah terbayangkan sebelumnya. Lasi mencoba menikmati kemewahan itu dan rela membayarnya dengan kesetiaan penuh pada Pak Han, seorang suami tua yang sudah lemah. Namun Lasi gagap ketika menemukan nilai perkawinannya dengan Pak Han hanya sebuah keisengan, main-main. Longgar, dan di mata Lasi sangat ganjil.\n\nDalam kegelapan itu Lasi bertemu dengan Kanjat, teman sepermainan yang sudah jadi lelaki matang. Lasi ingin Kanjat menolongnya seperti dulu ketika keduanya masih sama-sama bocah. Lasi ingin Kanjat membebaskan dirinya dari kurungan bekisar di rumah Pak Han. Tetapi Kanjat sibuk sendiri dengan kegiatan kemasyarakatan dalam upaya memperbaiki kehidupan petani gula kelapa. Maka Lasi harus bisa memutuskan sendiri: tetap menjadi bekisar dalam kurungan kehidupan kota yang makmur tapi ganjil atau terbang untuk membangun kembali dunianya sendiri yang sudah lantak. Pada titik ini Lasi merasa berdiri di simpang jalan yang sangat membingungkan.	\N	1057	121	1993-01-01	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1323919818i/1302793.jpg	{}	{}	2025-11-13 03:58:41.477	2025-11-13 03:58:40.802
465	40680082	A deluxe bind-up edition of Naoki Urasawa’s award-winning epic of doomsday cults, giant robots and a group of friends trying to save the world from destruction!\n\nHumanity, having faced extinction at the end of the 20th century, would not have entered the new millennium if it weren’t for them. In 1969, during their youth, they created a symbol. In 1997, as the coming disaster slowly starts to unfold, that symbol returns. This is the story of a group of boys who try to save the world.\n\nThe giant robot has been built, awaiting its great awakening, but the Friend’s identity has yet to be revealed. Time passes day by day, counting down to December 31, 2000…the day that Earth is destined to see its end. The only ones who can save the world are the nine friends who wrote The Book of Prophecy in their childhood days. Will humanity enter the new world, the new century, safe and sound?	\N	2794	161	2016-03-30	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1545536817i/40680082.jpg	{}	{}	2025-11-13 03:58:18.075	2025-11-13 03:58:17.441
483	\N	"Aku telah membuktikan bahwa siapa pun, tanpa berlatih sebelumnya, jika dia menggunakan pikirannya, dapat memainkan perannya yang absurd menuju kesempurnaan."Tiga drama yang terkumpul dalam buku ini ditulis antara tahun 1938 sampai 1950. Yang pertama, Caligula, ditulis tahun 1938 setelah membaca Twelve Caesar karya Suetonius. Drama ini saya tulis untuk kelompok teater kecil yang saya dirikan di Aljazair, dan saya sendiri yang ingin memerankan tokoh Caligula. Aktor yang belum berpengalaman memang sering suka tampil seperti itu. Di samping itu, saya waktu itu baru berumur dua puluh lima tahun, usia ketika seseorang meragukan segala sesuatu kecuali dirinya sendiri. Perang memaksa saya untuk rendah hati, dan Caligula pertama kali dipentaskan pada 1945 di Theatre Hebertot di Paris.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1565712617l/51618676.jpg	\N	\N	2025-12-28 07:56:38.923211	2025-12-28 07:56:38.923211
468	\N	Terjadi kecelakaan pesawat terbang dengan asap hitam besar membubung saat jatuh, disinyalir itu akibat ulah Choujin. Akan tetapi, ajaibnya, kecelakaan tersebut hanya menimbulkan kerusakan kecil di badan pesawat, dengan penumpang yang selamat mencapai 200 orang. Tokio Kurohara dan Azuma Higashi, dua siswa SMA yang bertugas sebagai sukarelawan kecelakaan tersebut, di perjalanan pulang tiba-tiba ditantang segerombolan preman yang menyimpan dendam kepada mereka.Masalahnya, kondisi preman tersebut tidak tampak normal....	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1763375680i/244071016.jpg	\N	\N	2025-12-28 08:09:10.429111	2025-12-28 08:09:09.676
480	\N	Yogyakarta, 1850. Isah adalah putri pembatik di lingkungan keraton, anak luar nikah seorang bupati yang tidak pernah mengakui ibu Isah sebagai selir resmi. Akibatnya, Isah menempati posisi sosial yang serba salah: dia berbeda dari orang awam di luar lingkungan keraton, tetapi dia juga mendapati diri berada di lapisan bawah dari hierarki ketat dunia keraton.Dengan akal dan tekadnya yang kuat, Isah berusaha merebut takdirnya sendiri dengan kabur dan menjadi nyai seorang perwira Belanda. Namun realitas dunia kolonial ternyata juga tak seperti yang diangankan oleh impian naif masa mudanya.Novel sejarah yang memukau tentang pencarian posisi, hasrat, dan identitas di Hindia Belanda akhir abad ke-19.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1655456886i/61304582.jpg	\N	\N	2025-12-28 08:09:53.664537	2025-12-28 08:09:52.87
479	\N	Luffy dan teman-temannya yang mendengar jeritan Nami, akhirnya berhadapan denagn Arlong. Namun, Luffy jatuh ke laut! Dia menghadapi bahaya besar. Teman-temannya bertekad untuk memenangkan pertarungan agar bisa menyelamatkan Luffy.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1252212732i/6811238.jpg	\N	\N	2025-12-28 08:10:10.369449	2025-12-28 08:10:09.579
478	\N	Arlong Park, kota yang dikuasai oleh manusia ikan. Dalam perjalanannya mencari Nami, Luffy dan teman-temannya tiba di kota itu. Di sana mereka menghadapi satu kenyataan yang mengejutkan. Apakah pikiran Nami yang terus bertempur sendirian sampai pada teman-temannya?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1252212508i/6811227.jpg	\N	\N	2025-12-28 08:10:26.905932	2025-12-28 08:10:26.144
467	\N	The hidden story of the wanton slaughter -- in Indonesia, Latin America, and around the world -- backed by the United States. In 1965, the U.S. government helped the Indonesian military kill approximately one million innocent civilians. This was one of the most important turning points of the twentieth century, eliminating the largest communist party outside China and the Soviet Union and inspiring copycat terror programs in faraway countries like Brazil and Chile. But these events remain widely overlooked, precisely because the CIA's secret interventions were so successful. In this bold and comprehensive new history, Vincent Bevins builds on his incisive reporting for the Washington Post, using recently declassified documents, archival research and eye-witness testimony collected across twelve countries to reveal a shocking legacy that spans the globe. For decades, it's been believed that parts of the developing world passed peacefully into the U.S.-led capitalist system. The Jakarta Method demonstrates that the brutal extermination of unarmed leftists was a fundamental part of Washington's final triumph in the Cold War.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1575565282l/53054943.jpg	\N	\N	2025-12-28 08:15:41.430359	2025-12-28 08:15:40.639
477	\N	A love letter to Syria and its people, As Long as the Lemon Trees Grow is a speculative novel set amid the Syrian Revolution, burning with the fires of hope, love, and possibility. Perfect for fans of The Book Thief  and  Salt to the Sea .Salama Kassab was a pharmacy student when the cries for freedom broke out in Syria. She still had her parents and her big brother; she still had her home. She had a normal teenager’s life.  Now Salama volunteers at a hospital in Homs, helping the wounded who flood through the doors daily. Secretly, though, she is desperate to find a way out of her beloved country before her sister-in-law, Layla, gives birth. So desperate, that she has manifested a physical embodiment of her fear in the form of her imagined companion, Khawf, who haunts her every move in an effort to keep her safe.  But even with Khawf pressing her to leave, Salama is torn between her loyalty to her country and her conviction to survive. Salama must contend with bullets and bombs, military assaults, and her shifting sense of morality before she might finally breathe free. And when she crosses paths with the boy she was supposed to meet one fateful day, she starts to doubt her resolve in leaving home at all.   Soon, Salama must learn to see the events around her for what they truly are—not a war, but a revolution—and decide how she, too, will cry for Syria’s freedom.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1690864627i/182761378.jpg	\N	\N	2025-12-28 08:16:48.162208	2025-12-28 08:16:46.961
484	\N	Kenyataan bahwa karya ini dijiwai oleh satu tema saja merupakan bukti kepadaku bahwa Agama Manusia telah tumbuh di dalam pikiranku sebagai suatu pengalaman religius dan bukan hanya sebagai suatu subjek filsafat. Malahan, sebagian besar dari tulisan-tulisanku, dimulai dari karya-karyaku yang masih mentah semasa muda sampai Saat ini, merupakan jejak berkelanjutan dari sejarah pertumbuhan ini. Dewasa ini aku menyadari kenyataan bahwa karya-karya yang aku mulai dan kata-kata yang telah kuucapkan itu sangat terkait dengan suatu kesatuan inspirasi yang definisinya yang benar sering tidak terungkap olehku.Dalam buku ini aku memberikan bukti tentang kehidupan pribadiku yang diletakkan dalam fokus yang tegas. Kepada sebagian pembacaku hal ini akan merupakan minat psikologis; tetapi bagi sebagian Iainnya aku berharap buku ini. akan memiliki nilai idealnya sendiri yang penting bagi sebuah masalah seperti agama.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1627797026i/58672044.jpg	\N	\N	2025-12-28 10:44:04.01652	2025-12-28 10:44:04.01652
485	\N	Beras adalah sekumpulan cerita pendek bertemakan makanan karya penulis-penulis yang besar pada masanya di Jepang, mulai dari buah-buahan, bahan makanan, sampai permen dan gula-gula.Sepanjang kita hidup, makanan selalu menjadi saksi keseharian kita. la menutrisi, memberikan energi untuk kita menjalani hidup sehari-hari, dan terkadang memberikan arti tertentu dalam hidup masing-masing orang. Makanan yang sama mungkin memberikan persepsi yang berbeda.Delapan penulis dan lima penerjemah akan menemanimu bersantap. Namun, perlu diingat, tak semua makanan bergizi enak di lidah...	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1693746777i/198468968.jpg	\N	\N	2025-12-28 10:55:22.869537	2025-12-28 10:55:22.869537
486	\N	มอคตาร์ ลูบิส นักหนังสือพิมพ์และนักเขียนอาวุโสของอินโดนีเซียและมีชื่อเสียงรู้จักกันในหมู่ประเทศอาเซียน เคยเป็นผู้อำนวยการน.ส.พ. อินโดนีเซีย รายา ตั้งแต่ปี พ.ศ. 2494 จนกระทั่งประธานาธิบดีซูการ์โนได้สั่งปิด ตัวมอคตาร์ ลูบิส ถูกจับคุมขังนานถึง 9 ปี เมื่อเขากลับเข้ามาเป็นบรรณาธิการ น.ส.พ. Horizon ก็ได้ถูกสั่งปิดอีกโดยประธานาธิบดีซูฮาร์โต ในปี พ.ศ. 2517งานเขียนของมอคตาร์ มุ่งเน้นไปในด้านเนื้อหาทางสังคมอินโดนีเซียมากกว่าจะไปในทางปรุงแต่งกลวิธีการเขียนการประพันธ์ ดังนักเขียน นักประพันธ์ทางตะวันตกอื่น ๆ เรื่องที่มอคตาร์เขียนส่วนใหญ่จึงมักพูดถึงสังคมอินโดนีเซีในหลายทัศนะ ในเรื่องความรัก เพศ ความนึกคิดของชาวบ้านไปจนถึงความรู้สึกของคนอินโดนีเซียธรรมดาสามัญที่อยู่ภายใต้พันธนาการของผู้นำจอมปลอมและของความนิยมชาติมอคตาร์ ลูบิส ได้รับรางวัลแมกไซไซทางด้านหนังสือพิมพ์และวรรณกรรม ในปี พ.ศ. 2509 มีผลงานการประพันธ์ที่มีชื่อหลายเล่ม เช่น Jalan Tak Ada Ujing (ถนนที่ไร้จุดหมาย) Tak Ada Esok (ไม่มีวันพรุ่งนี้) Senja Di Jarkarta (จาการ์ตายามสนธยา-แปลเป็นภาษาไทยแล้ว เมื่อปี 2514) "รวมเรื่องสั้นของมอคตาร์ ลูบิส" เป็นผลงานในปัจจุบันของเขาซึ่งสะท้อนภาพอินโดนีเซียได้อย่างน่าติดตาม	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1260972617i/6085244.jpg	\N	\N	2025-12-28 10:57:27.463869	2025-12-28 10:57:27.463869
487	\N	Seribu Bangau, salah satu karya memikat Pemenang Nobel (1968) Yasunari Kawabata ini, adalah kisah tentang hasrat yang menyala, penyesalan, dan juga kenangan yang sangat sendual yang menghubungkan betapa dekat mereka yang hidup dengan yang mati.Seperti karyanya yang lain, langka, halus dan liris.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1474021126i/25173017.jpg	\N	\N	2025-12-28 10:58:24.920758	2025-12-28 10:58:24.920758
476	\N	Perempuan itu perlahan-lahan menjelma menjadi seekor harimau putih dengan bulu yang jauh lebih kemilau dari silau sajadah imam surau. Seekor harimau besar belaka, lebih besar daripada seekor kerbau bajak, tetapi gerakan kepala dan liuk ekornya lincah umpama tupai jinak di tangan. Sesuatu yang tidak mampu dinalar benak Mangkutak pun terjadi: Labai Lebe dan harimau putih jelmaan perempuan itu berjalan menembus dinding.Mangkutak terpilih mewarisi tunggane dari Lebai Lebe, membuatnya menjadi bagian dari Alam Sebalik Mata, dan memiliki usia yang lebih panjang. Dengan kemampuan warisan ini, Mangkutak menjadi saksi atas banyak peristiwa sejarah dan gejolak sosial masyarakat Minangkabau, serta perubahan Indonesia. Novel Inyik Balang merentang kisah dengan kelindan legenda dan peristiwa sejarah, mulai era 1800-an hingga Orde Baru.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1725863640i/218633553.jpg	\N	\N	2025-12-28 10:58:42.632671	2025-12-28 10:58:41.449
475	\N	Aceh semasa perlawanan Gerakan Aceh Merdeka. Empat orang perempuan sedang turun ke rawa bernama Paya Nie untuk mengumpulkan purun danau buat dijadikan tikar. Kilas balik-kilas balik dalam obrolan mereka membawa kita ke masa lalu paya, masa lalu kampung-kampung sekitarnya, masa lalu militerisme, serta masa lalu diri mereka masing-masing. Desas-desus, legenda lokal, laporan saksi mata, dan mungkin juga bualan-bualan bercampur aduk dengan memukau. Tanpa mereka sadari, seregu marinir Indonesia sedang menyiapkan serangan skala besar ke rawa yang diduga menjadi tempat persembunyian gerilyawan Gerakan Aceh Merdeka itu.Juara III Sayembara Novel Dewan Kesenian Jakarta 2023	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1720418980i/216190763.jpg	\N	\N	2025-12-28 11:00:21.824783	2025-12-28 11:00:20.606
474	\N	"Leila bercerita tentang kejujuran, keyakinan, tekad, prinsip dan pengorbanan...Banyak idiom dan metafor baru di samping padangan falsafi yang terasa baru karena pengungkapan yang baru. Sekalipun bermain dalam khayalan lukisan-lukisannya sangat kasat mata." H.B.Jassin, pengantar Malam Terakhir Edisi Pertama."Dalam cerpen 'Air Suci Sita', ditulis di Jakarta 1987, Leila memulai ceritanya dengan kalimat:'Tiba-tiba saja malam menabraknya.' Sebuah kalimat padat yang sugestif dan kental...Dengan thnik bercerita yang menarik, Leila berhasil mengangkat gugatan mengapa hanya kesetiaan wanita yang dipersoalkan, bagaimana dengan kesucian para pria? (...) Sebagaimana awal dari perjalanan panjang Leila sebagai salah seorang penulis di masa depan, kumpulan ini penuh janji."Putu Wijaya, Tempo, Februari 1990.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1517970370i/38402314.jpg	\N	\N	2025-12-28 11:00:41.437855	2025-12-28 11:00:40.336
466	\N	Lembu tak pernah tahu kenapa dia dikutuk tak bisa jauh-jauh dari rel kereta api. Kutukan yang membuat dirinya berkelana menumpang kereta api, melewati seluruh jalur yang ada di Jawa, selama 100 tahun kehidupannya.Tak juga pernah dia ketahui sejarah ibunya, atau tentang Mbok Min—yang mengasihinya, nyaris tanpa syarat. Pun dia tak tahu dari mana datangnya makhluk-makhluk yang hanya terlihat olehnya. Makhluk-makhluk gaib datang bergantian, menemani setiap fase kehidupannya.Lembu memang tak ingin tahu semua itu. Namun, dia tahu, dia lahir saat jalur kereta pertama di Jawa sedang dibangun.Lembu juga mungkin tahu, sesungguhnya ada yang selalu mengawasinya. Setiap langkahnya sudah ditentukan sejak dia lahir untuk sebuah tujuan. Bahkan bagaimana dia mati pun sudah ada yang mengatur. Kerincing yang terkalung di lehernya---simpul dari kehidupan ibunya dan kehidupan Lembu sendiri---membuat dia harus berurusan dengan dewa-dewa yang kian tersingkir saat tanah Jawa semakin tenggelam ke abad modern.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1663834291i/62686455.jpg	\N	\N	2025-12-28 11:03:09.355403	2025-12-28 11:03:08.121
469	\N	Apa itu kebebasan? Apakah kehendak bebas benar-benar ada Apakah manusia bebas benar-benar ada?Okky Madasari mengemukakan pertanyaan-pertanyaan besar dari manusia dan kemanusiaan dalam novel ini. Melalui dua tokoh utama, Sasana dan Jaka Wani, dihadirkan pergulatan manusia dalam mencari kebebasan dan melepaskan diri dari segala kungkungan.Mulai dari kungkungan tubuh dan pikiran, kungkungan tradisi dan keluarga, kungkungan norma dan agama, hingga dominasi ekonomi dan belenggu kekuasaan.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1753245662i/239197650.jpg	\N	\N	2025-12-28 11:03:37.631014	2025-12-28 11:03:36.682
470	\N	"Vad var det då för människor? Vad talade de om? Vilken myndighet tillhörde de? K. levde ju ändå i en rättsstat, överallt härskade fred, inga lagar var upphävda, vem vågade överfalla honom i hans bostad? Han var alltid böjd för att ta allting så lätt som möjligt, att inte tro det värsta redan var ett faktum, att inte träffa några anstalter för framtiden ens om allt tedde sig hotfullt. Men i detta syntes ett sådant beteende inte riktigt."Josef K häktas en dag utan att få veta vad han står anklagad för. Romanen igenom får vi följa hans väg genom rättsväsendets irrgångar och den alltmer absurda hanteringen av hans fall. Josef K:s desperation blir allt starkare och hans obegripliga rättsprocess och maktkampen på hans arbetsplats leder till en absurd och klaustrofobisk situation där han inte kan ta någonting för givet.Med förord av Steve Sem-Sandberg	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1335199860i/11605374.jpg	\N	\N	2025-12-28 11:06:37.979065	2025-12-28 11:06:37.963
504	\N	Tanjiro akhirnya tiba di tempat Iwabashira Himejima dalam proses pelatihan Hashira. Latihan yang keras itu dimulai dari semedi di bawah air terjun, mengangkat gelondongan kayu raksasa, disusul dengan mendorong batu cadas. Apakah Tanjiro berhasil mendapat pengakuan dari Himejima usai menyelesaikan semua tugas tersebut!? Di sisi lain, Muzan menyusup ke kediaman Ubuyashiki demi mencari Nezuko…!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1704647418i/204990701.jpg	\N	\N	2026-01-16 07:12:34.842391	2026-01-16 07:12:34.842391
471	\N	Setelah pilot Saputro meninggal karena kecelakaan pesawat, Sri, tunangannya kawin dengan seorang diplomat Prancis. Kelahiran anak yang oleh kebanyakan orang dianggap sebagai datangnya kebahagiaan, namun di dada Sri hanya ada kehampaan. Dalam perjalanan mengawali liburan dari Saigon menuju Marseille, tanpa disangka-sangka, Sri menemukan kemesraan dan kelembutan pada diri Michel Dubanton. Dia adalah kapten kapal di mana Sri menumpang. Pria ini sudah berkeluarga. Dengan istrinya Nicole, dia mempunyai dua anak. Di pihaknya, Michel juga tidak menemukan kebahagiaan yang dia dambakan dalam rumah tangganya. Maka di atas kapal itulah Sri dan Michel memadu kasih, mendapatkan idaman dalam berpasangan. Nh. Dini memaparkan jalinan cinta antara Sri dan Michel dengan cara halus dan memikat.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1745198504i/231679541.jpg	\N	\N	2025-12-28 11:06:45.290703	2025-12-28 11:06:45.271
472	\N	Lewat buku ini sejarawan Ong Hok Ham menyadarkan kita bahwa Madiun memiliki sejarah yang panjang. Maka betapa salah jika ingatan atas wilayah ini hanya terpatri pada sejarah pembrontakan PKI 1948. Pada era perang Griyanti (1746-1755), Misalnya, Madiun memberikan dukungan yang penting bagi Sultan Mangkubumi (bertakhta 1749-1792). Dukungan ini berasal dari sosok Kiai Tumeneng Wirosentiko (sekitar 1720-1784), gegedug (jawara) Sukowati, yang menjadi panglima setia Mangkubumi selama perang. Paca berdirinya Yogyakarta, sang jawara Sukowati diangkat sebagai Bupati Wedena Madium dengan gelar Raden Ronggo Prawirodirjo I (menjabat 1760-1784) dan diberi janji bahwa Sultan akan menyayangi keturunannya selamanya.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1543453338i/42977277.jpg	\N	\N	2025-12-28 11:06:57.346716	2025-12-28 11:06:57.329
488	\N	Seekor beruang kutub ditangkap oleh para pemburu dan dirumahkan di kebun binatang di Cile. Namun beruang bernama Baltazar ini bukan beruang biasa. Dengan kearifan dan selera humornya yang manusiawi, serta sudut pandangnya yang unik, ia merenungkan situasinya di dalam kerangkeng untuk melucuti problem-problem kemanusiaan seperti kewenangan dan kekuasaan, penghambaan dan kebebasan.Karya tipis yang inspiratif, penuh makna dan permenungan yang menggugah. Ditulis oleh seorang cendekiawan dan politisi Cile pasca kudeta militer 1973 sebagai alegori politik tentang hidup di bawah kediktatoran, dan penyemangat bagi siapa saja yang sedang tertindas agar tidak menyerah dalam perjuangan mencapai kebebasan sejati.——————————Claudio Orrego Vicuña (1939–1982) adalah seorang sosiolog, peneliti sejarah, penulis, dan aktivis mahasiswa yang menjadi politisi dan anggota parlemen dari Partai Kristen Demokrat Cile. Pada 1973, kudeta militer Jenderal Augusto Pinochet bukan hanya menggulingkan presiden terpilih Salvador Allende, tetapi juga membubarkan parlemen yang membuat Orrego Vicuña tersingkir dari jabatannya. Novelet ini, satu-satunya karyanya yang ditulis sebagai karya sastra, diterbitkannya setahun sesudah kudeta dan dimaksudkan sebagai renungan hidup di bawah kediktatoran. Bukunya tentang orang hilang dan korban penculikan, Detenidos desaparecidos: una herida abierta, diberangus oleh rezim militer. Saat meninggal dunia pada usia 42 tahun, ia telah menulis lebih dari 30 buku.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1542794011i/42901124.jpg	\N	\N	2025-12-28 11:08:11.288861	2025-12-28 11:08:11.288861
489	\N	Buku yang melahirkan sistem ekonomi kapitalis.Di masa Smith, pandangan merkantilis menganggap bahwa faktor alam yang menyebabkan kemakmuran suatu bangsa. Mereka menumpuk simpanan emas, perak, dan logam mulia lainnya, baik melalui perdagangan ataupun jalan perang. Namun resep Smith sebaliknya. Faktor manusia pekerja yang produktif, rajin menabung dan berinvestasi, juga melalui jalan perdagangan yang baik adalah sebagai penentu kemakmuran suatu bangsa.Bangsa pedagang akan selalu lebih makmur daripada yang tidak, karena bangsa tersebut mampu membeli bahan mentah yang tidak dimilikinya dan mengubahnya menjadi barang manufaktur yang nilainya jauh lebih tinggi daripada komoditas mentahnya, yang kemudian dijual lagi dengan harga yang lebih tinggi dan keuntungan yang besar. Oleh karenanya harus didukung oleh kualitas pekerja yang terdidik dan produktif.Ide-ide Adam Smith mengenai produksi dan perdagangan ini kemudian menjadi karya terbaik dan paling jujur tentang keuangan industri, geopolitik, dan kapitalisme. Teori "invisible hand" Smith melahirkan sistem pasar bebas yang memicu revolusi ekonomi di berbagai bangsa. Sehingga buku ini disebut juga sebagai Kitab Klasik Ilmu Ekonomi yang mengubah sistem ekonomi dunia.Buku ini adalah satu-satunya buku terjemahan The Wealth of Nations berbahasa Indonesia dengan terjemahan paling akurat.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1754288277i/239684020.jpg	\N	\N	2025-12-28 14:33:31.787681	2025-12-28 14:33:31.787681
490	\N	Sejak kecil, Karla merasa diperlakukan tidak adil oleh ibunya yang ia anggap misterius. Namun tak ada seorang pun dalam keluarga yang membelanya. Inilah yang membuat Karla tak mempunyai pilihan selain menjauh dari keluarganya. Berpuluh tahun sesudahnya, barulah satu demi satu rahasia itu mulai terkuak baginya—bukan hanya rahasia yang menggelayuti keluarganya, tetapi juga banyak manusia lainnya.“Soe Tjen menceritakan kisah keluarga, terutama hubungan anak perempuan dan ibunya yang misterius, sekaligus membuka kisah yang lebih luas. Kita bisa melacak jejak tragedi negeri ini melalui kisah mereka yang tersembunyi, menguak kompleksitas dan kepahitan rasialisme, agama, bahkan kasta dalam masyarakat. Namun tak seperti novel-novel politik yang sibuk berteriak-teriak, ia tetap kisah manusia-manusia yang dipertalikan satu sama lain oleh kemanusiaan mereka—yang baik maupun biadab. Terakhir, saya menemukan sesuatu yang tak mungkin bisa dilakukan para penulis lelaki: kisah tentang rahim. Saya merasa dibawa untuk melihat, atau merasakan, sesuatu yang sangat perempuan.” — Eka Kurniawan, novelis, penulis Cantik Itu Luka“Novel Soe Tjen Marching merupakan salah satu narasi penting tentang bagaimana perempuan, begitu juga gerakannya, dihancurkan dengan keji oleh militerisme di Indonesia. Berlatar sejarah, dengan detail yang belum pernah diungkap selama ini.” — Martin Aleida, sastrawan, penulis Tanah Air yang Hilang“Novel ini adalah catatan tentang penindasan dan ketidakadilan yang tak terelakkan akibat identitas rasial, pilihan akan Tuhan, dan kepentingan politik. Pada akhirnya, kisah dalam novel ini kembali mengingatkan bahwa cara terbaik menghadapi segala luka dan trauma adalah mengingat dan mengisahkannya kembali dengan sepenuh kesadaran.” — Okky Madasari, novelis, penulis Entrok	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1599705189i/55286991.jpg	\N	\N	2025-12-28 14:34:48.860534	2025-12-28 14:34:48.860534
505	\N	Pasukan Kisatsutai menyerbu “Kastil Tanpa Batas” untuk mengalahkan Muzan. Shinobu harus menjalani pertarungan yang alot dan merugikan, melawan Jyogen no Ni Doma karena ternyata racunnya tidak mempan terhadap musuh. Apakah di akhir dia berhasil membalaskan dendam sang kakak? Di sisi lain, Zenitsu juga bertemu dengan seorang iblis yang dikenalnya…!?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1709438071i/209419761.jpg	\N	\N	2026-01-25 04:18:54.887215	2026-01-25 04:18:54.887215
506	\N	Yuji Itadori seorang murid SMA dengan kemampuan atletik yang luar biasa. Kesehariannya adalah menjenguk kakeknya yang terbaring di rumah sakit. Suatu hari, segel "objek terkutuk" yang berada di sekolahnya terlepas, monster-monster pun mulai bermunculan. Yuji menyusup ke dalam gedung sekolah demi menolong senior di klubnya, akan tetapi...!?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1610580094i/56660563.jpg	\N	\N	2026-01-26 04:53:02.784775	2026-01-26 04:53:02.784775
491	\N	Inilah yang kubayangkan detik-detik terakhir Bapak: 18 Mei 1970. Hari gelap. Langit berwarna hitam dengan garis ungu. Bulan bersembunyi di balik ranting pohon randu. Sekumpulan burung nasar bertengger di pagar kawat. Mereka mencium aroma manusia yang nyaris jadi mayat bercampur bau mesiu. Terdengar lolongan anjing berkepanjangan. Empat orang berbaris rapi, masing-masing berdiri dengan senapan yang diarahkan kepada Bapak. Hanya satu senapan berisi peluru mematikan. Selebihnya, peluru karet. Tak satu pun di antara keempat lelaki itu tahu siapa yang kelak menghentikan hidup Bapak. __Pada usianya yang ke-33 tahun, Segara Alam menjenguk kembali masa kecilnya hingga dewasa. Semua peristiwa tertanam dengan kuat. Karena memiliki photographic memory, Alam ingat pertama kali dia ditodong senapan oleh seorang lelaki dewasa ketika masih berusia tiga tahun; pertama kali sepupunya mencercanya sebagai anak ‘pengkhianat negara’; pertama kali Alam berkelahi dengan seorang anak pengusaha besar yang menguasai sekolah; dan pertama kali dia jatuh cinta.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1755693346i/195965151.jpg	\N	\N	2025-12-28 14:36:44.954527	2025-12-28 14:36:44.954527
492	\N	Tahun 2006: Amba pergi ke Pulau Buru. Ia mencari orang yang dikasihinya, yang memberinya seorang anak di luar nikah. Laki-laki itu Bhisma, dokter lulusan Leipzig, Jerman Timur, yang hilang karena ditangkap pemerintah Orde Baru dan dibuang ke Pulau Buru. Ketika kamp tahanan politik itu dibubarkan dan para tapol dipulangkan, Bhisma tetap tak kembali.Novel berlatar sejarah ini mengisahkan cinta dan hidup Amba, anak seorang guru di sebuah kota kecil Jawa Tengah. “Aku dibesarkan di Kadipura. Aku tumbuh dalam keluarga pembaca kitab-kitab tua.” Tapi ia meninggalkan kotanya. Di Kediri ia bertemu Bhisma. Percintaan mereka terputus dengan tiba-tiba di sekitar Peristiwa G30S di Yogyakarta. Dalam sebuah serbuan, Bhisma hilang selama-lamanya. Baru di Pulau Buru, Amba tahu kenapa Bhisma tak kembali.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1595399070i/54633383.jpg	\N	\N	2025-12-28 14:37:54.665789	2025-12-28 14:37:54.665789
493	\N	Pecundang berlatar belakang jaman revolusi Rusia yaitu pada masa revolusi bersenjata melawan rezim Czar di mana seluruh Rusia dalam keadaan kacau. Pecundang ditulis pada tahun 1907 dan sempat dilarang. Baru pada tahun 1917 diterbitkan di saat terjadinya kekosongan kekuasaan. Novel ini menggambarkan dengan sangat baik kehidupan masa kecil seorang anak yang begitu pahit. Namanya Yevsey, di usia yang sangat dini ayahnya tewas dibunuh dan bertahun kemudian ibunya juga meninggal secara misterius. Meninggalkan desanya, ia tumbuh menjadi belia yang tertutup dan lihai menipu, namun seringkali dianggap tolol. Ia miskin akan insting politik, namun lingkungan memaksanya bergabung dengan rezim Czar untuk memata-matai sahabat-sahabatnya.Pecundang buah karya Maxim Gorky sarat akan konflik, internal tokohnya maupun cinta dan kesetiaan. Gorky dengan jeli melukiskan pula kemiskinan, histeria massa, pergolakan kekuasaan, pertentangan kaum pemerintahan dan revolusioner, serta pertumpahan darah di Rusia.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1306599244i/2681495.jpg	\N	\N	2025-12-28 14:40:01.691213	2025-12-28 14:40:01.691213
495	\N	R to L (Japanese Style). Naruto is a young shinobi with an incorrigible knack for mischief. He’s got a wild sense of humor, but Naruto is completely serious about his mission to be the world’s greatest ninja!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1572064321i/48581040.jpg	\N	\N	2026-01-09 03:42:36.059005	2026-01-09 03:42:36.059005
496	\N	Chihiro berlatih untuk menjadi seorang penempa pedang di bawah bimbingan ayahnya, seorang penempa pedang paling terkenal di seluruh negeri. Ayah yang jenaka dan anak yang pendiam, walau berbeda sifat, hari-hari mereka begitu damai. Sampai suatu hari, tragedi datang menghampiri. Ikatan yang berlumuran darah dan keseharian yang takkan pernah kembali lagi. Chihiro pun menyimpan dendam dan menyalakan api tekad dalam hatinya!! Mengikuti petunjuk yang ditinggalkan sebuah organisasi Yakuza, Chihiro berhadapan dengan Hishaku, kelompok penyihir mematikan yang kemungkinan berada di balik pembunuhan ayahnya.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1742444796i/230061948.jpg	\N	\N	2026-01-16 04:29:55.295271	2026-01-16 04:29:55.295271
497	\N	Untuk pertama kalinya setelah 113 tahun, akhirnya iblis Jyogen berkurang! Muzan marah besar dan memberi perintah baru kepada beberapa iblis Jyogen yang tersisa. Di sisi lain, pedang Tanjiro yang rusak akibat pertarungan sebelumnya, membuat Haganezuka marah. Tanjiro terpaksa berangkat ke desa penempa pedang untuk memohon langsung kepadanya agar dibuatkan pedang baru. Tetapi… apakah yang menantinya di sana!?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1672988705i/75608169.jpg	\N	\N	2026-01-16 04:30:45.504847	2026-01-16 04:30:45.504847
498	\N	Dua iblis Jyogen, Hantengu dan Gyokko, datang menyerang ke desa penempa pedang yang tersembunyi! Tanjiro dan Genya bertarung mati-matian melawan Hantengu, iblis yang tiap kali diserang justru akan membelah diri dan semakin kuat. Di sisi lain, Tokito, sang Kasumibashira yang tidak terlalu memedulikan orang lain, berusaha menyelamatkan Kotetsu yang diserang iblis. Bagaimana perkembangan pertarungan mereka!?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1680075513i/124083433.jpg	\N	\N	2026-01-16 04:31:49.436511	2026-01-16 04:31:49.436511
499	\N	Kabar kematian Pak Tazaki, pencetus hukum tentang robot internasional membuat Profesor Abullah dipanggil oleh inspektur polisi, Tawashi. Ia adalah orang terakhir yang bertemu dengan Pak Tazaki sebelum kematiannya. Detectif Gesicht juga mulai curiga bahwa mungkin ada yang berusaha mengacaukan datanya	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1750036303i/236581213.jpg	\N	\N	2026-01-16 04:33:09.665369	2026-01-16 04:33:09.665369
500	\N	Kami menyukai hari-hari di ruang cuci. Kami masuk dalam keadaan kotor dan keluar dengan tangan-tangan yang bersih. Suara-suara pelan memantul di dinding ruang cuci, tapi tidak ada yang perlu bicara karena kata-kata akan ditelan suara mesin yang bergetar menabrak dinding-dinding dan menggilas lantai-lantai. Di dalam ruang cuci, kami ditelan dan ditenggelamkan dan dimuntahkan kembali dengan kotoran badan kami terkubur di dalam wadah penyucian. Kami keluar dari sini, kami putih. Di ruang cuci, kami sunyi.* * *Kapan Nanti berisi delapan cerita penuh keajaiban. Kita akan diajak ke pojok ruang cuci, ke hutan yang dari antara pepohonan tinggi muncul wanita kecil bertopeng kelinci, juga mengikuti kisah Kin yang menggunakan kartu kredit orang tua untuk membeli one way ticket dan melancong salah satu keluarga Kin. Tidak biasa dan memantik imajinasi.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1683590012i/80344350.jpg	\N	\N	2026-01-16 07:09:23.423174	2026-01-16 07:09:23.423174
501	\N	Tanjiro dan kawan-kawan akhirnya berhasil memojokkan wujud asli dari iblis Jyogen Hantengu. Akan tetapi, fajar hampir menyingsing, dan itu berarti bahaya mengancam Nezuko yang sama-sama iblis! Tanjiro ragu untuk terus maju membasmi Hantengu atau melindungi Nezuko Apakah Hantengu berhasil dimusnahkan!? Dan apakah Nezuko selamat!?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1697515989i/199957491.jpg	\N	\N	2026-01-16 07:10:30.644433	2026-01-16 07:10:30.644433
502	\N	Mantan anggota Kelompok Survei Bora juga menjadi target sasaran pembunuh misterius. Sedikit demi sedikit penyelidikan tentang kasus ini mulai terkuak. Mungkinkah Profesor Tenma, orang yang menciptakan robot anak laki-laki Jepang bernama Atom, memegang kunci untuk menemukan pembunuh dan motifnya?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1755054103i/240075446.jpg	\N	\N	2026-01-16 07:11:12.097797	2026-01-16 07:11:12.097797
509	\N	Sebuah kutukan yang menyerupai janin tiba-tiba muncul di lapas anak pria. Itadori dan murid tahun pertama lainnya diutus untuk menyelamatkan orang-orang yang masih berada di lapas tersebut. Akan tetapi, janin yang telah bermetamorfosis menjadi kutukan tingkat tinggi itu melancarkan serangannya sehingga Itadori dkk berada dalam bahaya. Itadori kemudian bertukar dengan Sukuna untuk mengalahkan kutukan tersebut, tapi...!?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1617166550i/57586433.jpg	\N	\N	2026-02-01 01:59:47.107094	2026-02-01 01:59:47.107094
510	\N	Rekam aku sebelum aku mati.Yuta mulai membuat film atas permintaan ibunya yang sakit. Setelah kematian ibunya, Yuta yang ingin bunuh diri, bertemu dengan seorang gadis cantik misterius bernama Eri. Mereka mulai membuat film bersama. Namun, Eri menyimpan sebuah rahasia.Inilah kisah remaja mengenai film, di mana realitas dan kreativitas saling terkait dan meledak!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1730090267i/220925261.jpg	\N	\N	2026-02-01 10:38:57.604671	2026-02-01 10:38:57.604671
511	\N	Dalam proses penyelidikan tentang pembunuhan berantai yang dialami para robot berspesifikasi tinggi dan juga mantan anggota Tim Survei Bora, Gesicht menemukan adanya kebencian antara manusia dan robot. Gesicth juga menemukan ingatan yang terpendan di chip ingatannya. Di lain tempat, Herakles kembali bertarung unguk membalaskan dendam dan rahasia tentang Pluto mulai terungkap.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1759722587i/242443449.jpg	\N	\N	2026-02-04 01:38:12.207798	2026-02-04 01:38:12.207798
512	\N	Itadori bertemu Junpei saat sedang menyelidiki kasus pembunuhan yang disebabkan oleh "kutukan". Awalnya, Itadori tidak erprasangka apa-apa terhadap Junpei. Dan karena merasa cocok, Itadori malah menjadi akrab dengannya. Tapi, ternyata Junpei "terpesona" dengan bujukan Mahito, dan bertikai dengan Itadori...!!Di tengah pertikaian, Itadori yang merasa terdesak dan ingin mengembalikan Junpei ke sosok sesungguhnya, malah dicemooh dan ditertawakan Sukuna yang ada dalam dirinya, juga Mahito. Akankah Itadori sanggup melepaskan Junpei dari "kutukan" kebenciannya!?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1635751684i/59511179.jpg	\N	\N	2026-02-04 02:58:42.930638	2026-02-04 02:58:42.930638
513	\N	Program pertukaran dengan Akademi Jujutsu Kyoto dimulai. Pihak yang duluan menyingkirkan jurei tingkat 2 di area pertandinganlah yang akan jadi pemenangnya. Todo yang gemar berkelahi segera menyerang pihak Tokyo! Saat Todo dan Itadori saling berhadapan, anak-anak Kyoto yang lain ikut mengepung Itadori dengan niat untuk membunuhnya...!?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1642629598i/60163790.jpg	\N	\N	2026-02-05 04:11:36.683309	2026-02-05 04:11:36.683309
514	\N	Tanjiro dan Giyu bertarung dengan sengit melawan iblis Jyogen ketiga, Akaza! Mereka terpaksa hanya bertahan di hadapan tekanan kekuatan Akaza. Tetapi di tengah pertarungan itu, Tanjiro berhasil membuka “Dunia Transparan” seperti yang pernah diajarkan ayahnya!! Apakah kini pedang Tanjiro mampu mencapai Akaza…!?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1714871414i/212801715.jpg	\N	\N	2026-02-07 06:59:24.606615	2026-02-07 06:59:24.606615
515	\N	“Berbuatlah sedikit dosa, Jamal,” kata Sato Reang kepada satu kawan sekelasnya. Jamal anak yang saleh, selalu sembahyang lima kali sehari, juga rajin mengaji. “Pahalamu sudah banyak. Bertumpuk-tumpuk. Tak akan habis dikurangi timbangan dosamu.”Ini kisah Sato Reang. Kadang ia demikian intim dengan dirinya, sehingga ini merupakan cerita tentang aku, tapi kali lain ia tercerabut, dan ini menjadi kisah tentang Sato Reang. Isi kepalanya riuh dan berisik, terutama sejak ia berumur tujuh tahun, ketika sang ayah berkata kepadanya, “Sudah saatnya kau menjadi anak saleh.”	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1718543720i/214866554.jpg	\N	\N	2026-02-08 11:25:45.053638	2026-02-08 11:25:45.053638
516	\N	Tim Kyoto memanfaatkan program pertukaran untuk membunuh Itadori...!! Di sisi lain, Jurei dan Jusoshi yang dipimpin Mahito menyusup masuk ke tempat berlangsungnya acara. Para guru pun bergegas pergi untuk menyelamatkan murid-murid, tapi mereka terhalang oleh Tobari! Sementara itu, Inumaki dan Fushiguro diserang Jurei tingkat tinggi bernama Hanami. Apakah mereka berhasil keluar dari krisis itu!?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1648787026i/60729727.jpg	\N	\N	2026-02-08 11:26:12.739359	2026-02-08 11:26:12.739359
517	\N	Pertarungan antara Kanao dan Inosuke melawan iblis Jyogen no Ni, Doma, mencapai klimaks! Keduanya terbakar amarah dihadapkan iblis yang telah merenggut anggota keluarga mereka, sementara pertarungan berlangsung alot dan keji! Mampukah mereka membalik keadaan di tengah situasi yang tak menguntungkan itu?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1722738712i/217149152.jpg	\N	\N	2026-02-11 04:40:58.969487	2026-02-11 04:40:58.969487
518	\N	Iwabashira Himejima beserta Kazebashira Shinazugawa berusaha mati-matian bergumul melawan Jyogen no Ichi!! Di tengah pertempuran sengit itu, kedua Hashira mendapatkan “tanda” dan mampu melancarkan serangan berturut-turut. Meski demikian, mereka dihadang kekuatan musuh yang luar biasa. Di sisi lain, Genya memakan bagian tubuh sang Jyogen no Ichi… Bagaimanakah akhir dari pertempuran ini!?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1728173219i/220150494.jpg	\N	\N	2026-02-11 04:42:02.946241	2026-02-11 04:42:02.946241
519	\N	Pertempuran sengit melawan iblis Jyogen no Ichi akhirnya mencapai akhir…!! Di penghujung pertempuran itu, Kisatsutai menggenggam kemenangan yang pahit sebab banyak nyawa yang melayang sebagai bayarannya. Sementara itu, di bagian terdalam Kastel Tanpa Batas, sang iblis pertama, Muzan Kibutsuji, telah bangkit kembali! Nasib seperti apakah yang menanti Tanjiro dkk. di depan sana?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1745561366i/231951248.jpg	\N	\N	2026-02-11 04:42:53.910356	2026-02-11 04:42:53.910356
520	\N	Masih satu jam lebih hingga fajar menyingsingâ€¦!! Tetapi, serangan Muzan semakin membabi-buta. Kisatsutai terus menyerbu dengan seluruh hashira yang masih tersisa. Apakah pedang mereka mampu menembusnya!? Apalagi, Tanjiro telah ambruk akibat serangan Muzan. Sungguh pertempuran sengit yang masing-masing orang berjibaku dengan segenap jiwa raga mereka!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1755498731i/240296916.jpg	\N	\N	2026-02-11 04:43:32.548246	2026-02-11 04:43:32.548246
521	\N	Pertempuran antara pencipta iblis, Muzan Kibutsuji, melawan Tanjiro dan kawan-kawan, akhirnya mencapai klimaks!! Empat racun yang disuntikkan Tamayo, kini telah melemahkan Muzan hingga berhasil membuatnya terpojok. Seperti apakah takdir yang menanti Tanjiro, Nezuko, dan seluruh anggota Kisatsutai...!? Pertarungan panjang melawan iblis kini mencapai akhir!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1758690937i/242003723.jpg	\N	\N	2026-02-11 04:45:01.003306	2026-02-11 04:45:01.003306
522	\N	Jari Sukuna dan objek terkutuk tingkat tinggi Jutai Kusozu yang disimpan di akademi jujutsu berhasil dicuri oleh Mahito. Kusozu pun menjelma jadi ancaman baru. Tanpa mengetahui bahaya tersebut, Itadori dan yang lainnya pergi untuk memusnahkan jurei yang muncul di pintu gerbang. Akan tetapi...!?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1665748342i/62989492.jpg	\N	\N	2026-02-13 04:39:00.469756	2026-02-13 04:39:00.469756
583	\N	Danarto dilahirkan pada tanggal 27 Juni 1941 di Sragen, Jawa Tengah. Ayahnya bernama Jakio Harjodinomo, seorang mandor pabrik gula. Ibunya bernama Siti Aminah, pedagang batik kecil-kecilan di pasar.Setelah menamatkan pendidikannya di sekolah dasar (SD), ia melanjutkan pelajarannya ke sekolah menengah pertama (SMP). Kemudian, ia meneruskan sekolahnya di sekolah menengah atas (SMA) bagian Sastra di Solo. Pada tahun 1958–1961 ia belajar di Akademi Seni Rupa Indonesia (ASRI) Yogyakarta jurusan Seni Lukis.Ia memang berbakat dalam bidang seni. Pada tahun 1958—1962 ia membantu majalah anak-anak Si Kuncung yang menampilkan cerita anak sekolah dasar. Ia menghiasi cerita itu dengan berbagai variasi gambar. Selain itu, ia juga membuat karya seni rupa, seperi relief, mozaik, patung, dan mural (lukisan dinding). Rumah pribadi, kantor, gedung, dan sebagainya banyak yang telah ditanganinya dengan karya seninya.Pada tahun 1969—1974 ia bekerja sebagai tukang poster di Pusat kesenian jakarta, Tam Ismail Marzuki. Pada tahun 1973 ia menjadi pengajar di Akademi Seni Rupa LPKJ (sekarang IKJ) Jakarta.Dalam bidang seni sastra, Danarto lebih gemar berkecimpung dalam dunia drama. Hal itu terbukti sejak tahun 1959—1964 ia masuk menjadi anggota Sanggar Bambu Yogyakarta, sebuah perhimpunan pelukis yang biasa mengadakan pameran seni lukis keliling, teater, pergelaran musik, dan tari. Dalam pementasan drama yang dilakukan Rendra dan Arifin C. Noor, Danarto ikut berperan, terutama dalam rias dekorasi.Pad tahun 1970 ia bergabung dengan misi Kesenian Indonesia dan pergi ke Expo ’70 di Osaka, Jepang. Pada tahun 1971 ia membantu penyelenggaraan Festival Fantastikue di Paris. Pada tahun 1976 ia mengikuti lokakarya Internasional Writing Program di Iowa City, Amerika Serikat, bersama pengarang dari 22 negara lainnya. Pada tahun 1979—1985 bekerja pada majalah Zaman.Kegiatan sastra di luar negeri pun ia lakukan. Hal itu dibuktikan dengan kehadirannya tahun 1983 pada Festival Penyair Internasional di Rotterdam, Belanda.Tulisnanya yang berupa cerpen banyak dimuat dalam majalah Horison, seperti “Nostalgia”, “Adam Makrifat”, dan “Mereka Toh Tidak Mungkin Menjaring Malaekat”. Di antara cerpennya, yang berjudul “Rintrik”, mendapat hadiah dari majalah Horison tahun 1968. Pada tahun 1974 kumpulan cerpennya dihimpun dalam satu buku yang berjudul Godlob yang diterbitkan oleh Rombongan Dongeng dari Dirah. Karyanya bersama-sama dengan pengarang lain, yaitu Idrus, Pramudya Ananta Toer, A.A. Navis, Umar Kayam, Sitor Situmorang, dan Noegroho Soetanto, dimuat dalam sebuah antologi cerpen yang berjudul From Surabaya to Armageddon (1975) oleh Herry Aveling. Karya sastra Danarto yang lain pernah dimuat dalam majalah Budaya dan Westerlu (majalah yang terbit di Australia).Dalam bidang film ia pun banyak memberikan sumbangannya yang besar, yaitu sebagai penata dekorasi. Film yang pernah digarapnya ialah Lahirnya Gatotkaca (1962), San Rego (1971), Mutiara dalam Lumpur (1972), dan Bandot (1978).	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1512631587i/36986923.jpg	\N	\N	2026-03-11 16:08:33.047553	2026-03-11 16:08:33.047553
523	\N	Bagaimana mungkin seseorang memiliki keinginan untuk mengurai kembali benang yang tak terkirakan jumlahnya dalam selembar sapu tangan yang telah ditenunnya sendiri.Bagaimana mungkin seseorang bisa mendadak terbebaskan dari jaringan benang yang susun-bersusun, silang-menyilang, timpa-menimpa dengan rapi di selembar saputangan yang sudah bertahun-tahun lamanya ditenun dengan sabar oleh jari-jarinya sendiri oleh kesunyiannya sendiri oleh ketabahannya sendiri oleh tarikan dan hembusan napasnya sendiri oleh rintik waktu dalam benaknya sendiri oleh kerinduannya sendiri oleh penghayatannya sendiri tentang hubungan-hubungan pelik antara perempuan dan laki-laki yang tinggal di sebuah ruangan kedap suara yang bernama kasih sayang.Bagaimana mungkin.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1434455898i/25736858.jpg	\N	\N	2026-02-13 08:15:25.781418	2026-02-13 08:15:25.781418
524	\N	Itadori dkk. berhasil mengalahkan janin kedua dan ketiga penjelmaan “Jutai Kusozu” dan mendapatkan jari Sukuna. Atas hasil upaya tersebut, mereka menerima rekomendasi untuk menjadi shaman tingkat 1! Akan tetapi, Gojo memiliki motif tersembunyi di balik itu semua...!? Dan JUJUTSU KAISEN kali ini juga akan menceritakan kilas balik peristiwa yang terjadi ketika Gojo dan Geto masih menjadi murid tahun kedua di Akademi Jujutsu!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1673594788i/76753348.jpg	\N	\N	2026-02-15 09:22:23.746658	2026-02-15 09:22:23.746658
525	\N	Kumpulan Cerpen Pilihan Kompas 1996Di antara 39 cerpenis yang telah dipilih dalam buku kumpulan cerpen pilihan Kompas sepanjang tahun 1992 hingga 1996, Seno Gumira Ajidarma yang paling menonjol, baik secara kuantitatif maupun secara kualitatif. (Faruk)Ketujuh belas cerpen ini dapat disebut bercorak realis, satu dua masih romantis, sesuai dengan pernyataan awal menjadi segudang pengalaman tambahan… Memang, sewaktu-waktu kita tersenyum atau mengernyitkan dahi karena cerita-cerita ini tetap relevan dengan masyarakat lingkungan kita, katakan saja kurang lebih tentu masih berfungsi sebagai cermin masyarakat. (Toety Heraty)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1488264424i/34410296.jpg	\N	\N	2026-02-15 11:27:03.528714	2026-02-15 11:27:03.528714
526	\N	Misi Gojo dan Geto untuk melindungi wadah plasma bintang berubah menjadi buruk saat seorang pembunuh shaman yang mengaku bernama Fushiguro menyerang mereka secara tiba-tiba . Apa hasil akhir dari kejadian di masa lalu tersebut, yang membuat Gojo menjadi yang terkuat dan membuat Geto memberontak!?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1680572250i/124947455.jpg	\N	\N	2026-02-17 03:53:13.432277	2026-02-17 03:53:13.432277
527	\N	Untuk bisa menggunakan kembali tubuhnya yang lumpuh, Kokichi Muta alias “Mechamaru” telah bertindak sebagai informan untuk Jurei... Akan tetapi, negosiasi gagal dan dia terpaksa bertarung melawan Mahito. Muta kemudian berusaha meloloskan diri dari kematian dengan rencana rahasia!? Lalu, tanggal 31 Oktober, tirai diturunkan di kota dan “Insiden Shibuya” pun dimulai…!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1688384762i/182894168.jpg	\N	\N	2026-02-17 03:53:46.928856	2026-02-17 03:53:46.928856
530	\N	Kumpulan Budak Setan, kompilasi cerita horor Eka Kurniawan, Intan Paramaditha, dan Ugoran Prasad, adalah proyek membaca ulang karya-karya Abdullah Harahap, penulis horor populer yang produktif di era 1970-1980an. Dua belas cerpen di dalamnya mengolah tema-tema khas Abdullah Harahap -- balas dendam, seks, pembunuhan -- serta motif-motif berupa setan, arwah penasaran, obyek gaib (jimat, topeng, susuk), dan manusia jadi-jadian.Kupejamkan kembali mataku dan kubayangkan apa yang dilakukannya di balik punggungku. Mungkin ia berbaring telentang? Mungkin ia sedang memandangiku? Aku merasakan sehembus napas menerpa punggungku.Akhirnya aku berbisik pelan, hingga kupingku pun nyaris tak mendengar:“Ina Mia?”("Riwayat Kesendirian,” Eka Kurniawan)Jilbabnya putih kusam, membingkai wajahnya yang tertutup bedak putih murahan – lebih mirip terigu menggumpal tersapu air – dan gincu merah tak rata serupa darah yang baru dihapus. Orang kampung tak yakin apakah mereka sedang melihat bibir yang tersenyum atau meringis kesakitan.(“Goyang Penasaran,” Intan Paramaditha)“Duluan mana ayam atau telur,” gumam Moko pelan. Intonasinya datar sehingga kalimat itu tak menjadi kalimat tanya. Laki-laki yang ia cekal tak tahu harus bilang apa, tengadah dan menatap ngeri pada pisau berkilat di tangannya. Moko tak menunggu laki-laki itu bersuara, menancapkan pisaunya cepat ke arah leher mangsanya. Sekali. Sekali lagi. Lagi.Darah di mana-mana.(“Hidung Iblis,” Ugoran Prasad)Dalam Kumpulan Budak Setan, sembari mengolah konvensi genre horor, kami juga memandang horor sebagai moda yang dipertukarkan di berbagai ranah, dari panggung politik hingga kehidupan sehari-hari. Horor tak melulu soal hantu, tetapi ruang liyan yang menciptakan kemungkinan runtuhnya “realitas” yang seharusnya, tatanan yang kita percaya. Horor beroperasi tak hanya dalam cerita setan, tapi juga dalam retorika politik (misalnya saja penggunaan moda horor dalam film sejarah Pengkhianatan G30S/PKI, atau, di tataran global, narasi seputar peristiwa 9/11) maupun hubungan personal dan sosial yang sepintas lalu tak berbahaya.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1470726023i/31378883.jpg	\N	\N	2026-02-17 10:05:37.001049	2026-02-17 10:05:37.001049
531	\N	Tentang seekor monyet yang ingin menikah dengan Kaisar Dangdut.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1453791897i/27808997.jpg	\N	\N	2026-02-17 10:06:26.994036	2026-02-17 10:06:26.994036
532	\N	Sesudah seperempat abad, optimisme Reformasi mulai menguap. Kita akan ke mana? Buku ini mengangkat beberapa dari pertanyaan-pertanyaan yang muncul. Sejauh mana demokrasi bisa didukung oleh budaya-budaya tradisional kita? Benarkah ada tanda-tanda PKI mau kembali?Dan, apakah ada itu pendidikan agar orang muda kita mau menolak korupsi? Apa Pancasila masih relevan?Apa benar pernyataan Albert Einstein bahwa ilmu pengetahuan membuat percaya kepada Allah ketinggalan zaman? Benarkah bahwa monoteisme adalah sumber intoleransi dan kekerasan atas nama agama? Kapan patriarkat dan intoleransi terhadap saudara-saudari kita dengan kecenderungan seksual berbeda berakhir? Manakah kecenderungan-kecenderungan baru dalam etika seksualitas? Itulah beberapa hal yang diangkat dalam buku ini.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1770480639i/247711932.jpg	\N	\N	2026-02-17 10:07:14.748531	2026-02-17 10:07:14.748531
533	\N	Bertahun-tahun kemudian, saat menghadapi regu tembak yang akan mengeksekusinya, Kolonel Aureliano Buendia jadi teringat suatu sore, dulu sekali, ketika diajak ayahnya melihat es.Riuh rendah pipa dan drum panci yang berisik mengiringi kedatangan rombongan Gipsi ke Macondo, desa yang baru didirikan, tempat Jose Arcadio Buendia dan istrinya yang keras kepala, Ursula, memulai hidup baru mereka. Ketika Melquiades yang misterius memukau Aureliano Buendia dan ayahnya dengan penemuan-penemuan baru dan kisah-kisah petualangan, mereka tak tahu-menahu arti penting manuskrip yang diberikan lelaki Gipsi tua itu kepada mereka.Kenangan tentang manuskrip itu tersisihkan oleh wabah insomnia, perang saudara, pembalasan dendam, dan hal-hal lain yang menimpa keluarga Buendia turun-menurun. Hanya segelintir yang ingat tentang manuskrip itu, dan hanya satu orang yang akan menemukan pesan tersembunyi di dalamnya...	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1534834917i/41382031.jpg	\N	\N	2026-02-17 10:08:56.149408	2026-02-17 10:08:56.149408
534	\N	Novel Burung-burung Manyar dapat dibaca sebagai bentuk proyek pasca-kolonial. Novel ini berusaha untuk mencari penyimpangan yang terjadi dalam penulisan sejarah Revolusi Indonesia. Sejarah dalam novel Burung-burung Manyar diceritakan secara mengalir dengan beberapa masukan anekdot. Sejarah tidak disampaikan dengan nada otoriter.Sejarah dicerita melalui kisah cinta seorang yang bekerja mendukung kemerdekaan Indonesia, Larasati, dan Satadewa alias Teto, orang Indonesia yang bekerja dalam angkatan perang Belanda.Menjelang akhir novel, terdapat kejutan yang menggelitik. Teto atau terbangkitkan jiwa nasionalismenya, dengan menjadi relawan membongkar kecurangan perusahaan tempatnya bekerja yang merugikan Indonesia.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1491741947i/1379444.jpg	\N	\N	2026-02-17 10:10:31.702545	2026-02-17 10:10:31.702545
535	\N	Dalam proses penyelidikan tentang pembunuhan berantai yang dialami para robor berspesifikasi tinggi dan juga mantan anggota Tim Survei Bora, Gesicht menemukan adanya kebencian antara manusia dan robot. Gesicth juga menemukan ingatan yang terpendan di chip ingatannya. Di lain tempat, Herakles kembali bertarung unguk membalaskan dendam dan rahasia tentang Pluto mulai terungkap.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1767843707i/246281839.jpg	\N	\N	2026-02-18 03:09:49.537427	2026-02-18 03:09:49.537427
536	\N	Peron bawah tanah Stasiun Shibuya dipenuhi warga sipil dan manusia yang telah dimodifikasi. Dalam situasi mengerikan tanpa jalan keluar, Gojo masih memegang kendali atas para Jurei. Akan tetapi, kuasa untuk menyegel Gojo ada di tangan musuh...!! Sementara itu, ketika Itadori bergegas menuju peron bawah tanah, muncul sekutu yang tak terduga!?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1694937528i/198989081.jpg	\N	\N	2026-02-18 03:35:40.001496	2026-02-18 03:35:40.001496
543	\N	The Valley of Fear is the fourth and final Sherlock Holmes novel by Sir Arthur Conan Doyle. It is loosely based on the real-life exploits of the Molly Maguires and Pinkerton agent James McParland. The story was first published in the Strand Magazine between September 1914 and May 1915.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://dryofg8nmyqjw.cloudfront.net/images/no-cover.png	\N	\N	2026-02-21 19:13:15.982099	2026-02-21 19:13:15.982099
544	\N	“…Puthut adalah pencerita yang piawai. Kata-katanya sederhana. Kalimat-kalimatnya ringkas. Tidak neko-neko. Tidak ingin dianggap pintar meliuk-liukkan kata, tapi ceritanya tetap memukau.Dia bukan hanya tahu teknik menulis yang baik, tapi saya kira, cerpen-cerpennya tak hanya ditulis dengan teknik menulis dan bercerita yang baik itu, melainkan ditulis dengan melibatkan perasaannya. Dan itulah yang penting. Karena tulisan yang ditulis dengan sepenuh perasaan tidak bisa dibohongi. Beberapa kali dada saya terasa sesak karena larut membaca cerpen-cerpen Puthut. Seolah saya ada di sana, di dalam cerpen-cerpennya. Menjadi saksi. Menjadi pelaku.” – Rusdi Mathari, wartawan dan penulis.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1585053050i/52669132.jpg	\N	\N	2026-02-22 16:11:13.652605	2026-02-22 16:11:13.652605
545	\N	Sojo menghadang! Di tengah pertarungan, dia mengungkapkan kekagumannya terhadap Kunishige, ayah Chihiro sekaligus pencipta katana sihir, serta keyakinannya bahwa "katana sihir ada untuk mencabut nyawa orang lain". Meski mengagumi orang yang sama, keduanya menempuh jalan yang berlawanan. Di hadapan Sojo yang luar biasa kejam, niat membunuh Chihiro semakin matang!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1748237850i/235035891.jpg	\N	\N	2026-02-22 16:12:20.312915	2026-02-22 16:12:20.312915
546	\N	Ia telah menghimpun kata-kata, menghunusnya, lalu bersiaga di udara terbuka, memandang lanskap, menunggu. Ia telah menghimpun kebusukan, menguhunusnya, lalu bersiaga di udara terbuka, memandang lanskap, menunggu. Oleh karena sebab-sebab sudah tidak lagi bisa disusun, oleh karena akibat-akibat sudah tidak lagi bisa disusun, ia kalah. Tak punya keberanian berlebih seperti Karna, tak punya patuh berlebih seperti Ekalaya. Ia kalah. Pulang dengan lunglai, lalu mengendap mencuri koin-koin ibunya untuk kemudian menyusun, menghunus, dan mengulang kebusukan yang sama. Ia kalah lagi. Kini, dalam lunglai, ia mengendap, mengincar koin-koin Anda!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1295427638i/1528393.jpg	\N	\N	2026-02-22 16:14:33.609006	2026-02-22 16:14:33.609006
547	\N	Masih teringat benar bagaimana kesannya menyadari betapa ibu memandangi kedua tanganku dan buku itu, dan rasanya meskipun aku ingin menaruh buku itu kembali namun sorot matanya melarangku, seolah membatin bahwa entah aku tetap memegangnya ataukah menaruh buku itu ia tetap tahu dan yakin bahwa aku menyayangi Okta, dan kata batin ibuku ini meninggalkan satu siksaan halus yang tidak kunjung dicabut dari atas ringkihnya jaringan sarafku.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1578154722i/49788397.jpg	\N	\N	2026-02-22 16:15:27.348727	2026-02-22 16:15:27.348727
548	\N	In late 1888, only weeks before his final collapse into madness, Nietzsche (1844-1900) set out to compose his autobiography, and Ecce Homo remains one of the most intriguing yet bizarre examples of the genre ever written. In this extraordinary work Nietzsche traces his life, work and development as a philosopher, examines the heroes he has identified with, struggled against and then overcome - Schopenhauer, Wagner, Socrates, Christ - and predicts the cataclysmic impact of his 'forthcoming revelation of all values'. Both self-celebrating and self-mocking, penetrating and strange, Ecce Homo gives the final, definitive expression to Nietzsche's main beliefs and is in every way his last testament.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1411244245i/479356.jpg	\N	\N	2026-02-22 16:17:52.318144	2026-02-22 16:17:52.318144
549	\N	Excerpt from Der Wanderer und Sein SchattenEÂ®er $ch glaube Dich zum berftehen, ob Du Dich gleich etmafÂ» fchattenhaft auÃ©gedriidt haft. 9lber Du hatteft ? gute $reunde geben fich hier und Da ein DunlleÃ© qbvrt alÃ©> 8eidnn De?Â» (sinberftiind uiffeÃ , tvelcheÃ© fiir ieden 93ritten ein 9iÃ¼thfel fein full.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1525242893i/34495436.jpg	\N	\N	2026-02-23 08:43:50.3779	2026-02-23 08:43:50.3779
550	\N	Shinuchi, pedang terkuat di antara 6 katana sihir akan dilelang!? Lelang gelap Rakuza Ichi dipenuhi sampah masyarakat, mulai dari exhibitor, penyelenggara, hingga pesertanya!! Yang menghadang Chihiro hanyalah orang-orang nekat yang tak segan mempertaruhkan nyawa demi lelang . Tapi tak ada alasan bagi Chihiro, si penuntut balas dendam, untuk merasa gentar! Eksekusi semuanya!! Kirim semuanya ke akhirat tanpa sisa!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1766803115i/245816407.jpg	\N	\N	2026-02-23 08:44:35.535279	2026-02-23 08:44:35.535279
551	\N	Sejarah Lengkap Kehidupan para Nabi sejak Adam A.S. hingga Isa A.S.Sebaik-baik kisah sejarah yang dapat diambil pelajaran serta hikmah berharga darinya adalah yang bersumber dari al-Qur`an dan hadis. Keduanya merupakan sumber utama bagi kaum Muslimin dalam menetapkan hukum dan mempelajari sejarah kehidupan umat terdahulu beserta para nabi yang diutus Allah s.w.t. untuk menyampaikan risalah-Nya di muka bumi.Buku Kisah Para Nabi ini merupakan karya fenomenal ulama terkemuka sekaligus ahli tafsir dan sejarah, Ibnu Katsir. Kisah-kisahnya bersandar pada ayat al-Qur`an dan hadis sahih sehingga isinya terbebas dari berbagai kisah israiliyat sejak awal paragraf hingga akhir. Di dalamnya juga tersaji berbagai peristiwa dan hal menarik, seperti: hikmah di balik penciptaan Nabi Adam a.s.; pertemuan Nabi Muhammad s.a.w. dengan Nabi Adam di surga; doa Nabi Nuh a.s. sebagai rasul pertama yang diutus ke bumi; dakwah Nabi Ibrahim a.s. ke tengah kaum penyembah berhala; kisah penyembelihan Nabi Ismail a.s. dan awal pembangunan Baitullah; perjuangan dakwah Nabi Musa a.s. membebaskan Bani Israil dari cengkeraman Firaun; dialog Nabi Musa a.s. dengan Firaun dan para penyihir kerajaan; asal-usul dan bukti kenabian Khidhir; kisah beberapa nabi Bani Israil; serta kisah turunnya Nabi Isa a.s. ke bumi pada akhir zaman.Selain hadir lebih sistematis dan kaya informasi, dengan tetap menjaga orisinalitas dan keautentikan kitab aslinya, buku ini juga begitu istimewa karena telah melalui proses tahqiq dan takhrij yang dilakukan oleh Prof. Dr. Abdul Hayyi al-Farmawi, guru besar Tafsir dan Ulumul Qur`an dari Universitas al-Azhar, Kairo. Melalui buku ini, setiap mukmin akan tenggelam dalam oase keimanan serta ketakwaan yang indah dan paripurna dari para nabi dan rasul. Jadi, tidaklah berlebihan jika buku ini wajib ada dalam perpustakaan pribadi kita. Selamat membaca.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1510124758i/36556711.jpg	\N	\N	2026-02-24 03:18:49.511194	2026-02-24 03:18:49.511194
552	\N	Hammer of the Gods"presents Friedrich Nietzsche s most prophetic, futuristic and apocalyptic philosophies and traces them against the upheavals of the last century and the current millennial panic. This radical re-interpretation reveals Nietzsche as the only guide to the madness in our society which he himself prophesied a century ago; Nietzsche as a philosopher against society, against both the state and the herd; Nietzsche as philosopher with a hammer.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1387749815i/226188.jpg	\N	\N	2026-02-24 07:39:30.609742	2026-02-24 07:39:30.609742
553	\N	Setelah mengetahui keberadaan pintu yang mengarah ke Kura tempat Enten disimpan, Chihiro menuju ke lantai bawah tanah Rakuza Ichi. Dengan Kuregumo yang patah di tangannya, sang pembalas dendam menghabisi musuh-musuhnya bagaikan kilat. Tapi, siapakah yang menghadang di hadapannya?Sementara itu, Hakuri tersungkur oleh kasih sayang dan kekerasan sang kakak. Saat dia sekarat, kenangan bersama seorang gadis terlintas di benaknya. Dalam situasi paling genting, jiwa kedua pemuda itu saling beresonansi!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1769256231i/247049404.jpg	\N	\N	2026-02-25 07:42:14.208101	2026-02-25 07:42:14.208101
554	\N	Di masa Perang Pasifik, nasib mempertemukan seorang bocah asal Batavia dengan para prajurit KNIL di neraka mengambang: sebuah lambung kapal Jepang yang dipenuhi kuli-kuli romusa yang akan diberangkatkan ke belantara Sumatra, dengan bau menyengat dari keringat dan tinja ribuan manusia yang berjejalan. Di bagian lain kapal itu, di kabin-kabin yang lebih manusiawi, disekap para perempuan Jawa yang diangkut paksa oleh tentara Jepang.Novel mendebarkan ini mengungkap satu babak dalam sejarah kolonial di Indonesia yang belum banyak dibicarakan.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1769304449i/247069691.jpg	\N	\N	2026-02-28 11:44:36.62403	2026-02-28 11:44:36.62403
555	\N	Di akhir periode Muromachi yang kacau, pemuda pembunuh roh mati dan bocah yatim piatu yang hidup dengan mencuri bertemu. Tubuh pemuda bernama Hyakkimaru itu dingin dan di lengannya terdapat pedang yang bersinar mencurigakan. Seperti apakah kisah petualangan mereka!?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1741787600i/229060862.jpg	\N	\N	2026-02-28 11:54:26.67691	2026-02-28 11:54:26.67691
556	\N	Sekelompok pahlawan sedang menempuh perjalanan pulang setelah mereka berhasil mengalahkan Kegelapan dan memulihkan kedamaian dunia, tetapi...	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1749700191i/236236887.jpg	\N	\N	2026-02-28 15:12:23.779064	2026-02-28 15:12:23.779064
557	\N	Best friends Tokio and Azuma do everything together, even if most of the time it feels like Tokio is just stumbling along in Azuma’s cooler, more talented footsteps. But when they’re attacked one night by a superhuman mutant called a choujin, Tokio finally has a chance to shine—by turning into a choujin himself!Tokio and his new choujin buddy Ely are now training to become superpowered protectors of the prefecture. But in addition to having to cram their noggins full of choujin rules and regulations, they have to deal with fledgling abilities that won’t always do what they’re supposed to…in ways both embarrassing and dangerous!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1670795872i/62919659.jpg	\N	\N	2026-02-28 15:13:38.899205	2026-02-28 15:13:38.899205
558	\N	Selagi Maria dan Yusuf menjalin percintaan yang mans, Tuti bergelut dengan dirinya sendiri; apakah akan menikah dengan orang yang tidak dicintainya hanya karena alasan usianya yang semakin bertambah, atau tetap memegang lebih baik tidak menikah daripada mendapatkan suami yang tidak sepandangan dan tidak sepaham.Hubungan Maria dan Yusuf makin mendalam, ketika tiba-tiba Maria diketahui mengidap penyakit serius. Bagaimanakah perasaan Yusuf mengetahui keadaan tunangannya? Bagaimana Tuti menghadapi peristiwa-peristiwa tak terduga dalam hidupnya? Dan bagaimana akhirnya hubungan ketiganya? 979-407-065-3	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1416983036i/1494305.jpg	\N	\N	2026-03-02 04:32:27.765524	2026-03-02 04:32:27.765524
559	\N	Dans le monde futuriste imaginé par Osamu Tezuka, où les robots vivent aux côtés des humains et comme des humains, une série de crimes mystérieux s'enchaîne. Des robots et des chercheurs renommés sont assassinés dans des circonstances étranges liées à des phénomènes naturels – feu de forêt, tornade extrêmement locale... Toutes les victimes sont retrouvées avec un ornement formant comme des cornes sur leur tête. Gesicht, un inspecteur robot appartenant à Europol est chargé d'enquêter sur l'affaire. Il découvrira rapidement que toutes les victimes sont des vétérans du dernier conflit d'Asie centrale. Il ne tardera également pas à identifier le fait que les robots visés par le tueur sont en fait les sept robots les plus puissants et performants de la planète, dont Gesicht lui-même fait partie. Il part alors à la rencontre des personnes et robots menacés pour tenter de les prévenir et les protéger du danger.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1331654950i/10717841.jpg	\N	\N	2026-03-02 09:01:10.247963	2026-03-02 09:01:10.247963
560	\N	In Plantation Life Tania Murray Li and Pujo Semedi examine the structure and governance of Indonesia's contemporary oil palm plantations in Indonesia, which supply 50 percent of the world's palm oil. They attend to the exploitative nature of plantation life, wherein villagers' well-being is sacrificed in the name of economic development. While plantations are often plagued by ruined ecologies, injury among workers, and a devastating loss of livelihoods for former landholders, small-scale independent farmers produce palm oil more efficiently and with far less damage to life and land. Li and Semedi theorize “corporate occupation” to underscore how massive forms of capitalist production and control over the palm oil industry replicate colonial-style relations that undermine citizenship. In so doing, they question the assumption that corporations are necessary for rural development, contending that the dominance of plantations stems from a political system that privileges corporations.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1655895183i/61315868.jpg	\N	\N	2026-03-02 13:57:44.880487	2026-03-02 13:57:44.880487
561	\N	Apa artinya sesal, kalau harapan telah tak ada lagi untuk memperbaiki segala kesalahan? Untuk menebus segala dosa? akan tetapi hilangkah pula sesal, karena harapan untuk menebus dosa itu telah hilang? ah, bila demikian halnya, barangkali takkan seberat itu segala dosa menekan jiwa Kartini. Manusia suka menghitung waktu dan seluruh hidupnya dikuasai oleh waktu. Memang, adakah sesuatu yang diam? adakah sesuatu yang tidak berubah? tidakkah semua itu berubah-ubah terus? juga kepercayaan manusia? juga keadaan sesuatu bangsa? juga kekuasaan sesuatu stelsel?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1713836463i/212010681.jpg	\N	\N	2026-03-03 02:50:51.529706	2026-03-03 02:50:51.529706
562	\N	Kompilasi kisah-kisah tentang rasa takut yang “tak terlihat.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1745908170i/232319751.jpg	\N	\N	2026-03-03 03:27:53.101496	2026-03-03 03:27:53.101496
563	\N	Meski pembantaian 1965-1966 terhadap para anggota, simpatisan, dan orang-orang yang dituduh mendukung PKI telah banyak diteliti secara garis besar, baru sedikit saja dari kekejaman ini yang telah dipelajari secara rinci, dan pertanyaan-pertanyaan dasarnya belum terjawab secara memuaskan. Apa kaitan antara tentara dengan milisi sipil? Mengapa korban yang tidak bersenjata dipandang sebagai ancaman bangsa oleh pelaku? Dan mengapa anggota PKI, yang berjumlah jutaan, tidak melawan?Dipijakkan pada riset bertahun-tahun dan wawancara dengan para korban selamat, Riwayat Terkubur adalah sumbangsih impresif bagi kepustakaan mengenai genosida dan kekejaman massal, mengulas isu soal media, pengorganisasian militer, kepentingan ekonomi, dan perlawanan.“Buku ini menghadirkan gebrakan besar dalam menggambarkan peristiwa-peristiwa pembunuhan [1965-1966] dalam konteksnya saat itu dan dalam kekayaan data sejarah lisannya.” — Robert Cribb, Australian National University	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1710651937i/210071600.jpg	\N	\N	2026-03-03 08:51:17.645884	2026-03-03 08:51:17.645884
564	\N	Muncul planet misterius dari “Lubang Cacing”. Penemunya, Profesor Oguro, menamai planet tersebut dengan “Remina”, yang berasal dari nama putri semata wayangnya.Penemuan tersebut mendapat apresiasi yang sangat besar dari masyarakat, dan sang putri, Remina, pun menjadi terkenal. Tapi, planet Remina mulai menghancurkan satu per satu planet, menyebabkan Bumi juga berada dalam bahaya.Inilah kisah horor one shot, karya sang maestro Junji ITO yang hadir dengan dengan sensasi baru.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1680929544i/126532470.jpg	\N	\N	2026-03-03 09:17:47.614506	2026-03-03 09:17:47.614506
565	\N	Bagaimanakah dan sejak kapan serta lantaran apakah sasterawan terkemuka Pramoedya Ananta Toer menjadi Kiri, menggabungkan kerja-kerja sastra dengan politik?Buku yang semula adalah disertasi Savitri Scherer ini menjawabnya. Savitri bukan saja menjelajahi biografi Pram, tetapi juga hubungan antara dunia nyata dan dunia fisiknya. Savitri pun tak merasa cukup hanya membongkar struktur kompleks mediasi antara Pram dan dunia kreatifnya dengan memperhatikan suasana juga kekuatan-kekuatan sosial, kebudayaan, politik yang gegap gempita oleh pertarungan ideologi dan semangat zaman penuh intrik polemik pemenjaraan dan periode 1950-1980 yang dialami serta mempengaruhinya. Lebih jauh Savitri menelusuri pandangan-pandangan sosial dan politik Pram untuk memahami karier sastranya, seraya menilai tanggapan-tanggapannya terhadap norma-norma sosial dan sastra pada masanya.Sebab itu sekali lagi dengan buku ini seperti buku yang sebelumnya telah ditulis Keselarasan dan Kejanggalan: Pemikiran-pemikiran Priyayi Nasionalis Jawa Awal Abad XX--menyumbangkan suatu model sejarah pemikiran yang bukan saja kaya informasi, tetapi juga membuat kedirian Pram dapat dipahami lebih dalam.Usaha yang dilakukan oleh Savitri Scherer untuk memahami langkah-langkah Pramoedya Ananta Toer yang menjadi Kiri patut dihargai karena dengan demikian kita akan dapat memahami lebih baik karya-karya yang ditulisnya.Ajip RosidiSastrawan dan penulis sejarah sastra Indonesia	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1557820902i/45755197.jpg	\N	\N	2026-03-03 16:29:37.561494	2026-03-03 16:29:37.561494
566	\N	Naruto 52 by Masashi Kishimoto (2011-11-01)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1698013739i/144131204.jpg	\N	\N	2026-03-03 20:10:59.107342	2026-03-03 20:10:59.107342
567	\N	This book has an isbn 9786029402452 that was also used for a different book Masa Gelap Pancasila Siapakah Sukarno? Nasionalis? Islamis? Atau marxis? Sukarno sendiri mengakui bahwa Marx, Engels dan Lenin adalah tiga tokoh yang berpengaruh besar dalam pemikirannya. Lebih jauh ia menjadi anak sungai besar yang mengalirkan paham yang kemudian sohor disebut kiri dalam arus sejarah Indonesia. Sukarno memandang pemikiran kiri adalah api pembakar Revolusi Indonesia. Namun, apakah benar paham ini yang menjadi penyebab Revolusi Indonesia? Apakah Revolusi Indonesia adalah revolusi kiri? Sejauh mana paham kiri ini mendapat halangan dan tantangan serta peran seperti apakah yang dimainkan Sukarno dalam menembus itu semua?Buku ini menjawab pertanyaan itu dengan menyusuri kedatangan marxisme-leninisme di Indonesia dan pengaruhnya pada Sukarno, serta lebih jauh mengurai penyebarannya ke tokoh-tokoh kiri Indonesia lainnya yang ada pada awal sampai pertengahan abad ke-20. Termasuk menyingkap bagaimana pemikiran kiri Indonesia yang memainkan peran sejarah itu dihabisi melalui pembunuhan massal yang kejam pada akhir 1965. Bukan hanya partai dengan tokoh-tokohnya, tetapi juga petani dan nelayan, sehingga pemikiran kiri mengalami suatu proyek pemusnahan dan dikenang sebagai hantu yang mengerikan.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1412233473i/23296694.jpg	\N	\N	2026-03-04 10:56:54.444198	2026-03-04 10:56:54.444198
568	\N	Hyakkimaru melawan Bandai yang dirasuki oleh roh mati karena ketamakannya yang ingin menguasai desa. Namun, terjadi perubahan pada tubuh hyakkimaru setelah melawan Bandai! Dia pun akhirnya menceritakan kisahnya kepada Dororo. Apa rahasia tubuh Hyakkimaru?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1745561189i/231951067.jpg	\N	\N	2026-03-08 15:10:36.129649	2026-03-08 15:10:36.129649
569	\N	BATTLE AT THE BANMON The Banmon is a grim barrier between lands, a line that no man can cross alive. Its Tahomaru, a mysterious warrior with the same prosthetics as Hyakkimaru. Both men lost pieces of themselves to demons, and both men stood tall again thanks to the inventions of doctor Jukai. In another world, they might have met in friendship. But with Hyakkimaru’s companion Dororo missing, a fated and bloody conflict looms.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1616497015i/53426674.jpg	\N	\N	2026-03-08 15:12:48.697708	2026-03-08 15:12:48.697708
570	\N	"Orang yang menghancurkan hidupku adalah Tenma!!"Eva menunjukkan kebencian yang tak terbayangkan kepada Tenma.Namun dia satu-satunya yang bisa memberikan kesaksian untuk membuktikan Tenma tidak bersalah.Eva yang dengan keras kepala menolak untuk bersaksi. kemudian memutuskan untuk membantu Tenma setelah memanjakan diri dengan kenangannya. Setelah mendengar tiga kali suara tembakan, orang yang dilihat Eva adalah "Johan"!! Sementara itu, Robert yang berniat membunuh Eva terus beringsut mendekatinya....Kunci untuk memecahkan misteri ini terletak di The Red Rose Mansion" Tenma, Nina dan Johan masing-masing menuju ke "The Red Rose Mansion" Apa yang sebenarnya terjadi di sana? Dan untuk alaxan apa Siapa sebenarnya Franz Bonaparta!?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1770475275i/247708968.jpg	\N	\N	2026-03-08 15:13:33.099046	2026-03-08 15:13:33.099046
571	\N	“Buku penting dan kuat.” — The Sydney Morning Herald“Investigasi yang meyakinkan dan menakutkan. Laboratorium Palestina menyediakan konteks penting tentang […] realitas hidup di wilayah pendudukan Palestina sebelum 7 Oktober.” — WIREDSelama lebih dari setengah abad, pendudukan Tepi Barat dan Gaza telah memberi Israel pengalaman luas dalam mengontrol rakyat Palestina. Dengan ini, wilayah pendudukan Palestina dipakai sebagai medan uji coba persenjataan dan teknologi pemantauan yang lantas mereka ekspor ke seluruh dunia.Untuk pertama kalinya, melalui reportase lapangan, wawancara, dan investigasi membongkar dokumen-dokumen rahasia, dikuak secara mendalam bagaimana Israel menjadi yang terdepan dalam pengembangan teknologi penyadapan dan pertahanan yang memanaskan konflik-konflik paling brutal sedunia. Israel hidup dari menjual senjatanya ke rezim-rezim paling beringas—kediktatoran militer Guatemala yang membantai Indian Maya, tentara Myanmar yang membunuhiribuan orang Rohingya, sampai drone-drone yang digunakan Uni Eropa untuk memantau pengungsi yang dibiarkan tenggelam di Laut Tengah.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1764222822i/244485473.jpg	\N	\N	2026-03-08 16:21:35.765139	2026-03-08 16:21:35.765139
584	\N	Apa yang ditulis Danarto, kian menegaskan keyakinan, betapa sastra ditulis memang untuk membuat manusia kian mengenali seluruh potensi kemanusiaannya. Bahkan, sebagaimana kata Albert Camus, ia adalah sumbangan bagi berlangsungnya peradaban di masa depan. Rasanya, tak berlebih, semua itu disematkan pada kumpulan cerpen Danarto ini.Cerpen-cerpen Danarto, cenderung menghadirkan hal yang non-real, yang tak nyata, ke dalam bingkai kenyataan. Yang real dan non-real mewujud bukan sebagai sesuatu yang saling bertentang, bukan "dua dunia" yang tidak saling bersentuhan, tetapi justru sebagai yang saling berkelindan, jalin-menjalin, pengaruh-mempengaruhi. Yang real dan non-real, dalam cerpen-cerpen Danarto, melebur menerobos ruang dan waktu, sehingga sebagai dunia alternatif cerpen-cerpen Danarto membawa kita, pembaca, ke dunia sonya ruri, ke wilayah fantastis, ke dunia transenden, yang tidak real tapi juga tidak sepenuhnya tak terkenali.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1458287771i/29545369.jpg	\N	\N	2026-03-11 16:09:06.945831	2026-03-11 16:09:06.945831
681	\N	Seorang Hero harus selalu memiliki KEYAKINAN YANG KUAT. Akan tetapi, kalau sampai salah mengartikan keyakinan tersebut, maka kalian akan kehilangan arah tujuan. Hal yang akan kalian PELAJARI atau RASAKAN dari pengalaman magang ini tergantung pada diri kalian sendiri. Sekian. Berjuanglah secara rasional! “PLUS ULTRA”!!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1538726776i/42185290.jpg	\N	\N	2026-05-31 16:36:07.548513	2026-05-31 16:36:07.548513
573	\N	Seorang kenalan ingin membeli rumah seken di Tokyo dan memperlihatkan denah rumahnya padaku karena merasa ada yang ganjil. Sekilas, rumah ini kelihatan seperti rumah-rumah lain pada umumnya dengan interior yang luas dan terang. Namun, ketika mencermatinya baik-baik, aku mendapati bahwa memang ada keanehan di sana-sini. Keanehan demi keanehan itu bertumpuk, kemudian terjalin membentuk satu “kenyataan”. Kenyataan yang teramat sangat mengerikan, dan sama sekali tidak ingin kupercaya.Masalah yang Diceritakan Seorang Kenalan Saat ini, aku berprofesi sebagai penulis lepas spesialis occult— hal-hal gaib. Tuntutan profesi membuatku kerap bersinggungan dengan cerita hantu maupun pengalaman mistis. Dan di antaranya, aku paling sering mendengar cerita supranatural yang terjadi di ”rumah”. ”Aku mendengar bunyi langkah di lantai dua, padahal di sana tidak ada orang.” ”Rasanya seperti ada yang memperhatikanku waktu aku berada di ruang tamu sendirian.” ”Terdengar suara orang bicara dari dalam lemari.” Tak terhitung banyaknya kisah-kisah mengenai bangunan yang dibayangi sejarah kelam. Namun, cerita tentang ”rumah” yang kudengar pada waktu itu agak berbeda dari cerita-cerita serupa lainnya.Pada bulan September tahun 2019, seorang kenalan bernama Yanaoka-san menghubungiku karena ada masalah yang ingin dibahas. Yanaoka-san bekerja sebagai staf sales di sebuah agensi editorial. Kami berdua berteman dekat dan sesekali pergi makan bersama sejak berkenalan beberapa tahun lalu dalam urusan pekerjaan. Tidak lama lagi Yanaoka-san akan menyambut kelahiran anak pertamanya. Sehubungan dengan peristiwa itu, Yanaokasan pun memantapkan diri untuk membeli rumah pertamanya Setelah menghabiskan waktu setiap malam sampai larut melihat lihat informasi properti, Yanaoka­san akhirnya menemukan satu rumah yang ideal di kawasan Tokyo. Rumah dua lantai itu berada di daerah permukiman yang tenang. Banyak hutan di sekitarnya meskipun berlokasi di dekat stasiun, serta usia bangunannya sendiri terbilang baru meskipun berstatus rumah second. Ketika Yanaoka­san beserta istri datang melihat lihat rumah itu, mereka berdua langsung jatuh hati pada interiornya yang lega dan terang. Hanya saja, terdapat satu bagian pada tata letak ruangan di rumah itu yang menimbulkan tanda tanya besar bagi mereka.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1679903430i/123850391.jpg	\N	\N	2026-03-09 07:22:35.397618	2026-03-09 07:22:35.397618
574	\N	Denji, pemuda super miskin yang dikejar banyak utang, bekerja sebagai pemburu iblis bersama iblis bernama Pochita. Hari-harinya sebagai manusia kasta terbawah berubah total setelah sebuah pengkhianatan brutal. Meski Denji menyimpan iblis dalam tubunya setelah insiden tersebut, dia tetap harus memburu iblis agar bisa bertahan hidup!?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1674986999i/89576801.jpg	\N	\N	2026-03-09 13:44:39.025289	2026-03-09 13:44:39.025289
575	\N	Ketika angin puting beliung menerbangkan Dorothy dan anjingnya, Toto, dari rumah mereka di Kansas, keduanya terdampar di Negeri Oz yang penuh keajaiban. Sesuai petunjuk Penyihir Baik dari Utara dan para Munchkin, Dorothy memulai perjalanannya menyusuri jalan bata kuning untuk mencari Kota Zamrud dan sang Penyihir Oz, yang dapat membantunya pulang. Bersama teman-temannya— Orang-orangan Sawah, Manusia Timah, dan Singa Penakut—Dorothy menjalani petualangan yang sarat dengan persahabatan, sihir, dan bahaya.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1765868571i/245327978.jpg	\N	\N	2026-03-10 05:08:08.277865	2026-03-10 05:08:08.277865
576	\N	Menurut Seno Gumira Ajidarma, kita pantas meletakkan harapan atas masa depan sastra Indonesia kepada para penulis muda seperti Eka Kurniawan. Sebuah pernyataan perlu diuji dan penuh tanggung jawab, yang tentu saja tidak sekadar diucapkan untuk kepentingan publikasi semata. Dan Anda bisa jadi setuju dengan pernyataan tersebut setelah Anda membaca Cinta Tak Ada mati dan Cerita-cerita lain, karya Eka Kurniawan.Setiap cerita dalam kumpulan ini ditulis Eka dengan semangat pencanggihan yang tinggi, yang pada masa lalu merupakan ruang kosong dalam sastra Indonesia. Sekali lagi, publikasi ini tidak akan berisi sinopsis atau ringkasan karena akan menghilangkan kejutan dan membuat cerita-cerita Eka menjadi tidak asyik lagi. Membaca Eka Kurniawan dengan sempurna adalah dengan membeli bukunya dan mengalami sendiri perjalanan yang penuh teror estetik dari cerita-cerita dalam kumpulan ini.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1526680395i/40170238.jpg	\N	\N	2026-03-10 06:21:31.375643	2026-03-10 06:21:31.375643
577	\N	Mengapa pemeluk Hindu di India mengagungkan sapi? Mengapa orang Yahudi dan Muslim mengharamkan babi, dan sebaliknya orang Maring di New Guinea seakan tidak bisa hidup tanpa babi? Mengapa beberapa kepala suku Indian Amerika Utara membakar harta bendanya sendiri untuk menyombongkan kekayaannya? Mengapa begitu banyak orang di Abad Pertengahan percaya penyihir? Dan mengapa sihir hadir kembali secara mencolok dalam kebudayaan populer kita sekarang?Antropolog Marvin Harris mencoba memberi jawaban atas perilaku sosial yang sering dibilang tak terjelaskan ini, dan menunjukkan bahwa seaneh apa pun polah manusia, pasti ada penjelasan yang bersumber dari kondisi-kondisi ekonomis dan ekologis konkret.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1663636186i/62654693.jpg	\N	\N	2026-03-10 14:27:11.432222	2026-03-10 14:27:11.432222
578	\N	Kemunculan Toji Zenin yang tak terduga, menambah kekacauan “Insiden Shibuya”! Di sisi lain, Nanami yang sedang menuju ke tempat Geto di peron bawah tanah, sangat marah atas luka yang diderita para asisten pengawas. Shaman tingkat 1 yang memasuki medan pertempuran pun semakin bertambah, sementara Itadori bertarung sengit melawan si sulung kusozu, Choso!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1701324972i/202954368.jpg	\N	\N	2026-03-10 17:59:33.579768	2026-03-10 17:59:33.579768
579	\N	Denji, pemuda super miskin yang dikejar banyak utang, bekerja sebagai devil hunter bersama iblis bernama Pochita. Hari-harinya sebagai manusia kasta terbawah berubah total setelah sebuah pengkhianatan brutal. Meski Denji menyimpan iblis dalam tubuhnya setelah insiden tersebut, dia tetap harus memburu iblis agar bisa bertahan hidup!?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1680311877i/124932285.jpg	\N	\N	2026-03-10 18:00:12.612343	2026-03-10 18:00:12.612343
580	\N	A deluxe bind-up edition of Naoki Urasawa’s award-winning epic of doomsday cults, giant robots and a group of friends trying to save the world from destruction!Humanity, having faced extinction at the end of the 20th century, would not have entered the new millennium if it weren’t for them. In 1969, during their youth, they created a symbol. In 1997, as the coming disaster slowly starts to unfold, that symbol returns. This is the story of a group of boys who try to save the world. In the middle of the Tokyo Bay, a man known as Shogun has escaped from Umihotaru Prison, a place feared by criminals and convicts as an inescapable iron fort, in order to save the world. He heads off to Tokyo, the city where the girl known as “the Last Hope” lives. But the streets of Tokyo are in turmoil after a murder in Chinatown triggers a chain reaction of terror. The time has come for the false peace created by the Friend to be exposed. What is the truth behind the historic disaster on the last day of 20th century?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1551617577i/42867490.jpg	\N	\N	2026-03-11 02:59:05.975778	2026-03-11 02:59:05.975778
581	\N	Korpus preživelih susrešće se sa ženskim titanom. Ali „ona“ ne ubija da bi jela, već da bi se odbranila! Kao da traži nekoga. Kao da je drugačija!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1361254802i/17262714.jpg	\N	\N	2026-03-11 03:00:32.342021	2026-03-11 03:00:32.342021
582	\N	Gambar yang dibuat seorang wanita hamil di internet...Gambar yang dibuat seorang anak kecil sebagai hadiah Hari Ibu...Gambar yang dibuat seorang korban pembunuhan di saat-saat terakhirnya...Jika dilihat sekilas, gambar-gambar ini terkesan biasa saja. Namun, jika dicermati lebih dalam, di sana-sini terdapat keganjilan... keganjilan yang akhirnya mendorong seorang detektif amatir menyusuri labirin penuh teka-teki yang mengarah pada sebuah kenyataan mengerikan.Novel kedua dari YouTuber populer, Uketsu—sosok misterius bertopeng yang merupakan salah satu penulis kontemporer paling populer di Jepang.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1769064410i/246934899.jpg	\N	\N	2026-03-11 16:08:10.336309	2026-03-11 16:08:10.336309
585	\N	Danarto telah diakui sebagai sastrawan yang memulai penulisan Realisme Magis di Indonesia dan juga seorang pelukis. (Goenawan Mohamad)Jika Pramoedya Ananta Toer mata kanan kita, maka Danarto adalah mata kiri kita. Danarto adalah seorang pembaharu. Seorang master.-(Harry Aveling)Cerpen-cerpen Danarto adalah parabel-parabel religius yang luar biasa dinamika dan daya imajinasinya. Tradisional tetapi sekaligus kontemporer. (YB. Mangunwijaya)Cerita-cerita Danarto adalah parodi. Dalam parodinya, yang diejek terutama sastra itu sendiri. Cerita Danarto telah mengejek genrenyasendiri. (Sapardi Djoko Damono)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1501235863i/35842814.jpg	\N	\N	2026-03-11 16:09:28.629547	2026-03-11 16:09:28.629547
586	\N	Buku Pertama dari Trilogi Rara Mendut“Kita kan hanya perempuan rampasan belaka, Den Rara. Kenapa Den Rara tidak mau dipersunting Tumenggung yang kuasa dan kaya raya? Kan enak nanti.”“Tubuh dirampas memang. Tetapi hati tidak.” Genduk Duku, yang menjatuhkan dirinya dalam pangkuan puannya, dibelai rambutnya. “Nduk, Gendukku sayang. Sebentar lagi kau akan menjadi wanita cantik juga. Tidak mudah menjadi wanita cantik, Nduk. Tidak mudah. Apalagi di kalangan istana. Di sini kita menjadi barang hiburan belaka. Di luar kita lebih mudah jadi orang.”*Rara Mendut, wanita rampasan yang menolak diperistri oleh Tumenggung Wiraguna demi cintanya kepada Pranacitra. Dibesarkan di kampung nelayan pantai utara Jawa, ia tumbuh menjadi gadis yang trengginas dan tak pernah ragu menyuarakan isi pikirannya. Sosoknya dianggap membangkang tatanan di lingkungan istana, di mana perempuan diharuskan bersikap halus dan patuh.Tetapi ia tak gentar. Baginya, lebih baik menyambut ajal di ujung keris Sang Tumenggung daripada dipaksa melayani nafsu panglima tua.Rara Mendut merupakan novel pertama dari Trilogi Rara Mendut, mahakarya Y.B. Mangunwijaya. Sebuah narasi yang tidak hanya mengisahkan tumpang tindih hidup manusia, juga dengan apik menyinggung sejarah Tanah Jawa, keberanian perempuan, dan protes atas ketidakadilan.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1568769104l/50811427.jpg	\N	\N	2026-03-15 17:44:54.432992	2026-03-15 17:44:54.432992
587	\N	家族や仲間の安全を思う坂本。自らの居場所を守るため坂本が辿り着いた答えとは!?　一方、篁の人格が暴走しXは殺戮マシンと化していた。混乱の渦中、出現したリオンの人格が有月との最後の日々を語り始め…!?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1735035309i/221715496.jpg	\N	\N	2026-03-15 17:46:30.207828	2026-03-15 17:46:30.207828
588	\N	Dalam Sihir Perempuan, Intan Paramaditha mengolah genre horor, mitos, dan cerita-cerita lama dengan perspektif feminis. Buku ini meraih penghargaan 5 besar Khatulistiwa Literary Award (Kusala Sastra Khatulistiwa) di tahun 2005. Sebagian cerpen dalam Sihir Perempuan diterjemahkan ke dalam bahasa Inggris oleh Stephen J. Epstein dan pada tahun 2018 terbit dalam buku Apple and Knife di Australia (Brow Books) dan Inggris (Harvill Secker/Penguin Random House).***Tentang cerpen-cerpen Intan Paramaditha:“Gelap, subversif… Dongeng dan mitos diolah dengan sudut pandang feminis.” Tatler UK“Terkadang mengganggu, kerap kali humoris, namun selalu feminis tanpa tedeng aling-aling.” Mariella Frostrup, BBC Radio 4 Open Book“[Salah satu dari]… penulis-penulis perempuan baru dengan kisah dan gaya yang mengguncang batas-batas sastra kontemporer.” The Sydney Morning Herald	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1750815743i/237132821.jpg	\N	\N	2026-03-19 19:22:57.954996	2026-03-19 19:22:57.954996
589	\N	이찬혁의 첫 번째 소설이 출간된다. “평소 가진 생각을 음악뿐 아니라 다른 방법으로도 표현하고 싶었다”라고 밝힌 그는, 삶에 대한 가치관과 예술에 대한 관점을 소설 『물 만난 물고기』를 통해 은유적으로 녹여냈다. 2019년 가을, 한날 발매되는 악동뮤지션 정규앨범 「항해」와 세계관을 공유한 작품으로, 세상을 향해 던지는 짙고 푸른 물음과 소중한 것을 지켜나가는 것의 의미, 빛나는 삶의 순간들에 대한 그만의 시선이 담겼다.『물 만난 물고기』는 상상을 뒤집는 강렬한 스토리, 탄탄한 구성력을 동원해 인간의 욕망과 두려움, 자유와 통제의 대비, 사랑의 환희와 상실의 상흔, 삶의 의미를 때로는 담담하게, 때로는 환상적으로 보여준다. 성급하고 단편적인 해석보다는 독자 스스로가 자유롭게 소설의 의미를 발견해주었으면 한다는 저자의 바람처럼, 마음껏 소설 속을 유영하며 깊이 호흡하고, 한편 각자의 삶을 묻고 답하기를 권한다.문장 하나 하나에 섬세하게 박힌 감성, 마음을 위로하고 정화하는 맑은 감각, 생각에 빠져들게 하는 철학적인 화두가 소설에 고스란히 배어 있다. 그동안 짧은 가사만으로 그의 세계를 온전히 만끽하기에 아쉬웠던 독자라면, 소설에서 펼쳐지는 충분히 너른 그의 세계를 마음껏 향유하길 바란다.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1611714137i/56853651.jpg	\N	\N	2026-03-19 19:24:03.043754	2026-03-19 19:24:03.043754
590	\N	Mendesak Sukarno-Hatta untuk memproklamasikan kemerdekaan, Sutan Sjahrir justru absen dari peristiwa besar itu. Dia memilih jalan elegan untuk menghalau penjajah: jalur diplomasi—cara yang ditentang tokoh lain yang lebih radikal. Ideologinya, antifasis dan antimiliter, dikritik hanya untuk kaum terdidik. Ia dituduh elitis.Sejatinya, Sjahrir juga turun ke gubuk-gubuk, berkeliling Tanah Air menghimpun kader Partai Sosialis Indonesia. Sejarah telah menyingkirkan peran besar Bung Kecil—begitu Sjahrir biasa disebut. Meninggal dalam pengasingan, Sjahrir adalah revolusioner yang gugur dalam kesepian.Kisah Sutan Sjahrir adalah satu dari empat cerita tentang pendiri republik: Sukarno, Hatta, Tan Malaka, dan Sutan Sjahrir. Diangkat dari edisi khusus Majalah Berita Mingguan Tempo sepanjang 2001–2009, serial buku ini mereportase ulang kehidupan keempatnya, mulai dari pergolakan pemikiran, petualangan, ketakutan, hingga kisah cinta dan cerita kamar tidur mereka.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1655860509i/61335523.jpg	\N	\N	2026-03-19 19:24:41.103134	2026-03-19 19:24:41.103134
591	\N	5 Besar Khatulistiwa Literary Award 2011 Prosa Apa yang bisa dibanggakan dari pegawai rendahan di pengadilan? Gaji bulanan, baju seragam, atau uang pensiunan? Arimbi, juru ketik di pengadilan negeri, menjadi sumber kebanggaan bagi orangtua dan orang-orang di desanya. Generasi dari keluarga petani yang bisa menjadi pegawai negeri. Bekerja memakai seragam tiap hari, setiap bulan mendapat gaji, dan mendapat uang pensiun saat tua nanti. Arimbi juga menjadi tumpuan harapan, tempat banyak orang menitipkan pesan dan keinginan. Bagi mereka, tak ada yang tak bisa dilakukan oleh pegawai pengadilan. Dari pegawai lugu yang tak banyak tahu, Arimbi ikut menjadi bagian orang-orang yang tak lagi punya malu. Tak ada yang tak benar kalau sudah dilakukan banyak orang. Tak ada lagi yang harus ditakutkan kalau semua orang sudah menganggap sebagai kewajaran. Pokoknya, 86!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1752811565i/239019233.jpg	\N	\N	2026-03-19 19:25:02.157512	2026-03-19 19:25:02.157512
682	\N	Ujian praktik akhir semester di Akademi U.A. telah dimulai. Tak disangka, ujiannya beupa PERTARUNGAN melawan para guru Akademi U.A. SECARA BERPASANGAN! Dibandingkan dengan Todoroki yang menjadi pasanganku, aku sama sekali tidak bisa berbuat apa-apa... Tapi, aku pasti akan lulus! “PLUS ULTRA”!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1547547283i/43569816.jpg	\N	\N	2026-05-31 16:36:27.146422	2026-05-31 16:36:27.146422
592	\N	Perubahan yang mendasar mulai merambah Desa Tanggir pada tahun 1970-an. Suara orang menumbuk padi hilang, digantikan suara mesin kilang padi. Kerbau dan sapi pun dijual karena tenaganya sudah digantikan traktor. Sementara, di desa yang sedang berubah itu muncul kemelut akibat pemilihan kepala desa yang tidak jujur. Pambudi, pemuda Tanggir yang bermaksud menyelamatkan desanya dari kecurangan kepala desa yang baru malah tersingkir ke Yogya. Di kota pelajar itu Pambudi bertemu teman lama yang memintanya meneruskan belajar sambil bekerja di sebuah toko. Melalui persuratkabaran, Pambudi melanjutkan perlawanannya terhadap Kepala Desa Tanggir yang curang, dan berhasil. Tetapi pemuda Tanggir itu kehilangan gadis sedesa yang dicintainya. Dan Pambudi mendapat ganti, anak pemilik toko tempatnya bekerja, meski harus mengalami pergulatan batin yang meletihkan.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1402462375i/22454922.jpg	\N	\N	2026-03-19 19:25:34.429435	2026-03-19 19:25:34.429435
593	\N	Buku Kedua dari Trilogi Rara Mendut“Memang kau benar. Itu tidak adil. Tetapi itulah kekuasaan. Tidak menimbang mana adil dan tidak adil. Kekuasaan seperti angin topan saja. Menghancurkan apa saja yang menghadang di jalan....”“Kalau begitu, perkenankanlah hambamu Duku untuk sementara minta diri dan bersembunyi di tempat yang cukup jauh saja. Sebab hambamu Duku khawatir, bila beliau datang lagi dan minta hal-hal yang bukanbukan, tangan abdimu tidak dapat dikendalikan, dapat melayang ke wajah beliau.”*Genduk Duku, sahabat Rara Mendut yang membantunya menerobos benteng Keraton Mataram dan melarikan diri dari kejaran Tumenggung Wiraguna. Setelah kematian Rara Mendut dan Pranacitra, Genduk Duku hidup sebagai pelarian bersama Slamet. Genduk Duku juga menjadi saksi perseteruan diam-diam antara Wiraguna dan Pangeran Aria Mataram, putra mahkota yang kelak bergelar Sunan Amangkurat I dan sesungguhnyajuga jatuh hati kepada Rara Mendut.Genduk Duku merupakan novel kedua dari Trilogi Rara Mendut, mahakarya Y.B. Mangunwijaya. Sebuah narasi yang tidak hanya mengisahkan tumpang tindih hidup manusia, juga dengan apik menyinggung sejarah Tanah Jawa, keberanian perempuan, dan protes atas ketidakadilan.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1568769428l/50811980.jpg	\N	\N	2026-03-19 19:26:01.371146	2026-03-19 19:26:01.371146
594	\N	Empat perempuan bersahabat sejak kecil. Shakuntala si pemberontak. Cok si binal. Yasmin si “jaim”. Dan Laila, si lugu yang sedang bimbang untuk menyerahkan keperawanannya pada lelaki beristri.Tapi diam-diam dua di antara sahabat itu menyimpan rasa kagum pada seorang pemuda dari masa silam: Saman, seorang aktivis yang menjadi buron dalam masa rezim militer Orde Baru. Kepada Yasmin, atau Lailakah, Saman akhirnya jatuh cinta?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1525243230i/40022099.jpg	\N	\N	2026-03-19 19:26:56.245469	2026-03-19 19:26:56.245469
595	\N	June Hayward dan Athena Liu sama-sama penulis. Athena, keturunan Asia, ternyata lebih ngetop. Sementara June berpendapat tak ada yang akan tertarik pada karyanya, gadis kulit putih biasa.Ketika Athena mendadak meninggal, June mencuri manuskrip Athena lalu menyerahkannya ke penerbit sebagai karyanya.Penerbit membuat citra baru bagi June, lengkap dengan foto yang ambigu memgenai etnik dirinya.Di luar dugaan, buku itu sukses besar.Namun, June tidak bisa lolos dari bayangan Athena, dan bukti-bukti bermunculan, mengancam kesuksesan June.Saat berpacu untuk menutupi rahasianya, June jadi tahu seberapa jauh ia berani bertindak untuk mempertahankan apa yang menurutnya layak ia dapatkan.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1694859160i/198981124.jpg	\N	\N	2026-03-19 19:27:26.360601	2026-03-19 19:27:26.360601
596	\N	Jika Anda hidup di Bumi, mungkin Anda takut akan masa depan. Terorisme, hubungan internasional yang kompleks, pemanasan global, virus mematikan, dan hal-hal lain yang membuat kita akan sulit untuk tidak takut. Menonton berita akan membuat Anda berpikir: apakah pergi keluar benar-benar aman?Dalam buku "The Day it Finally Happens", Mike Pearl memaparkan banyak skenario tentang kejadian yang sering kita pertanyakan akan terjadi atau tidak, yang mungkin sudah kita spekulasikan sebelumnya, memberikan nilai kemungkinannya, dan membawa kita untuk menelusuri itu semua. Ia menjelajahi apa saja yang mungkin terjadi dalam begitu banyak skenario - kegagalan antibiotik, ketika kehidupan di laut hilang, ketika sistem monarki di Inggris dihapuskan, dan bahkan kedatangan alien - dan laporan dari masa depan yang menggambarkan bagaimana kehidupan akan terlihat, terasa, dan tercium ketika itu terjadi.Lucu, mencerahkan, sekaligus menakutkan, buku ini membuat sains menjadi lebih mudah diakses, menjadi terapi eksistensial yang unik, menawarkan jawaban praktis dari berbagai pertanyaan saat kita cemas.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1744092285i/231153992.jpg	\N	\N	2026-03-19 19:28:25.160511	2026-03-19 19:28:25.160511
597	\N	What links together two bands of worshippers, one deep in the Arctic snows, one hidden in the bayous of Louisiana, is more than their shared practice of blood sacrifice. It is the inhuman phrase they both chant: Ph'nglui mglw'nafh Cthulhu R'lyeh wgah'nagl fhtagn...("In his house at R'lyeh dead Cthulhu waits dreaming.")Now these nightmares will disturb the sanity of Francis Thurston, a young man pursuing an investigation into the cult of Cthulhu that leads to the most forsaken spot in the vast Pacific... and to Earth's supreme terror, the risen corpse-city of R'lyeh.First published in 1928, The Call of Cthulhu, rendered in chilling detail by modern manga horror master Gou Tanabe, is the most famous of all of H.P. Lovecraft's stories, and was the namesake of the acclaimed role-playing game system set within the Cthulhu Mythos.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1768245810i/204191787.jpg	\N	\N	2026-03-19 19:31:52.163363	2026-03-19 19:31:52.163363
598	\N	هذا بحث كتبه عبد الرحمن الكواكبي في موضوع الاستبداد مستعرضاً طبائعه وما ينطوي عليه من سلبيات تؤدي إلى خوف المستبد وإلى الاستيلاء الجبن على رغبته إلى جانب انعكاسات الاستبداد على جميع مناحي الحياة الإنسانية بما فيه الدين والعلم والمجد والمال والأخلاق والترقي والتربية والعمران ومن خلال التساؤلات يشرح من هم أعوان المستبد وهل يمكن أن يتحمل الإنسان ذلك الاستبداد وبالتالي كيف يكون الخلاص منه وها هو البديل عنه.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1352231987i/2312458.jpg	\N	\N	2026-03-19 19:35:57.833269	2026-03-19 19:35:57.833269
599	\N	Di dunia ini, majik itu makhluk hidup. Lalu, para pemburu yang melewati tes sulit untuk menguasai majik disebut sebagai "penyihir". Suatu hari, di sebuah pedalaman gunung terpencil, Raja Majik yang menakutkan bertarung sengit melawan penyihir terkuat. Hingga kemudian, tiba-tiba muncul seorang pemuda yang mengganggu jalannya pertarungan. Pemuda itu bernama Ichi. Pemuda pemburu yang tinggal di gunung dan tidak tahu apa-apa tentang penyihir maupun majik, akan menjadi sosok yang tidak biasa bagi dunia ini! Inilah awal dari kisah fantasi perburuan majik!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1767204349i/245963376.jpg	\N	\N	2026-03-23 05:08:08.561372	2026-03-23 05:08:08.561372
683	\N	Saat sedang mengikuti TRAINING CAMP untuk MENGEMBANGKAN QUIRK, para siswa mendadak diserang oleh para VILLAIN. Apa sebenarnya tujuan mereka? Kenapa mereka bisa tahu lokasi kami? Firasatku buruk... Tapi, semua pasti akan baik-baik saja karena kami kuat. “Plus Ultra”!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1550470105i/44046757.jpg	\N	\N	2026-05-31 16:36:45.577695	2026-05-31 16:36:45.577695
600	\N	Rumah tua di samping rumah Adam yang telah lama terbengkalai itu kini ditempati penghuni baru. Eva, seorang perempuan dengan tangan dingin dalam menumbuhkan dan merawat aneka tanaman, menyulap keangkeran rumah itu dengan Toko Firdauz dan pekarangan yang rimbun. Adam remaja tanggung dengan gairah seksual sedang bergejolak, kerap menyaksikan Eva dan aneka tanamannya dari balik jendela kamar.Tiada yang bisa menyangka, di tengah gairah seksual yang bergejolak, Adam menyaksikan sulur-sulur mawar yang masuk kamar, dan memenuhi fantasi akan sosok perempuan yang ditumbuhi duri dan akar. Sepanjang hidup, Eva diikuti kutukan perihal yang tumbuh di tubuhnya. Adam menyimpan rahasia atas tubuh Eva, sekaligus fantasi-fantasi setiap malamnya.Dalam Duri dan Kutuk terbentang selusur kisah perempuan yang sepanjang hidupnya kerap diusik duri dan terkepung kutuk. Semuanya rebah ke tanah dan ditelan rerimbunan.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1708994434i/209187186.jpg	\N	\N	2026-03-23 12:24:16.96608	2026-03-23 12:24:16.96608
601	\N	Ketika si mantan suami muncul lagi untuk memeras Yasuko Hanaoka dan putrinya, keadaan menjadi tak terkendali, hingga si mantan suami terbujur kaku di lantai apartemen. Yasuko berniat menghubungi polisi, tetapi mengurungkan niatnya ketika Ishigami, tetangganya, menawarkan bantuan untuk menyembunyikan mayat itu.Saat mayat tersebut ditemukan, penyidikan Detektif Kusanagi mengarah kepada Yasuko. Namun sekuat apa pun insting detektifnya, alibi wanita itu sulit sekali dipatahkan. Kusanagi berkonsultasi dengan sahabatnya, Dr. Manabu Yukawa sang Profesor Galileo, yang ternyata teman kuliah Ishigami.Diselingi nostalgia masa-masa kuliah, Yukawa sang pakar fisika beradu kecerdasan dengan Ishigami, sang genius matematika. Ishigami berjuang melindungi Yasuko dengan berusaha mengakali dan memperdaya Yukawa, yang baru kali ini menemukan lawan paling cerdas dan bertekad baja.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1468811163i/31142330.jpg	\N	\N	2026-03-25 15:43:04.564907	2026-03-25 15:43:04.564907
602	\N	In a world where only women can be witches, one unsuspecting boy acquires their power.Magic is alive and well in the world, inside beings known as Majiks. By completing a Majik’s trial, a Witch can gain its power. However, only women can become Witches or use magical items. All that changes one day when a young man named Ichi turns the world on its head by defeating an infamous Majik and gaining its magical powers!After bringing Ichi to the Witches’ Association to prove his legitimacy as the first male Witch, the association creates Team Desscaras. Consisting of the famous Witch herself, Ichi, and a timid girl from the research department named Kumugi, the team’s first mission is to defeat the Majik ice shark Hisame. Upon the trio’s discovery of villagers frozen in ice, Hisame announces her specific trial—to make her beautiful. While Desscaras and Kumugi struggle, Ichi comes up with a surprising yet effective way to overcome this odd trial…	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1764164068i/235991947.jpg	\N	\N	2026-03-25 15:44:40.263192	2026-03-25 15:44:40.263192
603	\N	Satoshi Shiki (士貴智志) is a Japanese manga artist.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1763769498i/244261838.jpg	\N	\N	2026-03-25 19:17:18.584807	2026-03-25 19:17:18.584807
604	\N	BLAR! Pesawat yang ditumpangi Yana dalam suatu ekspedisi meledak. Yana selamat, tetapi malah terlempar ke tahun 1292 karena iseng menjajal helm waktu.Kembali ke masa lalu memang terdengar seru, tetapi Yana harus membebaskan diri dari sergapan bajak laut Kala Wredati dan penjara Bupati Madura. Belum lagi, Yana perlu mengatur strategi demi menyelamatkan Raden Wijaya, raja pertama Majapahit. Tidak kalah penting, bisakah Yana mempertahankan helm waktu, satu-satunya benda yang bisa membawanya pulang ke tahun 1971?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1741675377i/229011148.jpg	\N	\N	2026-04-01 07:14:31.867624	2026-04-01 07:14:31.867624
605	\N	15 tahun berlalu sejak “Second Impact”. Umat manusia akhirnya mulai menunjukkan tanda-tanda pemulihan akibat bencana yang tak pernah terjadi sebelumnya dalam sejarah. Akan tetapi, sebuah bahaya baru kembali datang mengancam umat manusia.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1693438928i/198276806.jpg	\N	\N	2026-04-01 08:50:32.276679	2026-04-01 08:50:32.276679
606	\N	Mendesak Sukarno-Hatta untuk memproklamasikan kemerdekaan, Sutan Sjahrir justru absen dari peristiwa besar itu. Dia memilih jalan elegan untuk menghalau penjajah: jalur diplomasi—cara yang ditentang tokoh lain yang lebih radikal. Ideologinya, antifasis dan antimiliter, dikritik hanya untuk kaum terdidik. Ia dituduh elitis.Sejatinya, Sjahrir juga turun ke gubuk-gubuk, berkeliling Tanah Air menghimpun kader Partai Sosialis Indonesia. Sejarah telah menyingkirkan peran besar Bung Kecil—begitu Sjahrir biasa disebut. Meninggal dalam pengasingan, Sjahrir adalah revolusioner yang gugur dalam kesepian.Kisah Sutan Sjahrir adalah satu dari empat cerita tentang pendiri republik: Sukarno, Hatta, Tan Malaka, dan Sutan Sjahrir. Diangkat dari edisi khusus Majalah Berita Mingguan Tempo sepanjang 2001–2009, serial buku ini mereportase ulang kehidupan keempatnya, mulai dari pergolakan pemikiran, petualangan, ketakutan, hingga kisah cinta dan cerita kamar tidur mereka.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1655860509i/61335523.jpg	\N	\N	2026-04-02 07:47:15.382903	2026-04-02 07:47:15.382903
607	\N	Kisah Paul Atreides, yang kini dikenal dengan nama Muad'Dib, terus berlanjut. Setelah menjadi kaisar, kekuasaannya kian tak terbendung. Muad’Dib disembah oleh kaum Fremen fanatik, hal yang dulu dia takutkan tapi justru kini dia lestarikan demi mempertahankan takhta. Namun, para lawan politiknya tidak tinggal diam. Bahkan dengan kemampuannya melihat masa depan, Muad’Dib masih harus menghadapi persekongkolan yang tak hanya mengancam dirinya, melainkan juga keberlangsungan Klan Atreides serta keselamatan nyawa kekasihnya, Chani.Dune: Mesias merupakan lanjutan dari Dune 01 dan Dune 02.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1708937621i/209161139.jpg	\N	\N	2026-04-03 03:07:57.805816	2026-04-03 03:07:57.805816
608	\N	Panduan esensial untuk memahami perubahan iklim dan mengapa hal ini penting bagi kamu, generasi muda Indonesia yang cerdas dan penuh rasa ingin tahu. Buku ini akan membongkar misteri perubahan iklim dengan cara yang mudah dipahami, seru untuk dijelajahi, dan penuh langkah praktis!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1765527684i/245120957.jpg	\N	\N	2026-04-03 06:11:57.826187	2026-04-03 06:11:57.826187
609	\N	Dagon berubah menjadi jurei yang menakutkan! Serangan energi kutukan yang tak ada habisnya pun membanjiri Naobito, Maki, dan Nanami. Di sisi lain, sekelompok jusoshi yang mengabdikan diri pada Geto berusaha untuk mendapatkan kembali tubuh Geto dengan membangkitkan sosok yang paling keji.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1705112373i/205304409.jpg	\N	\N	2026-04-03 06:12:32.562973	2026-04-03 06:12:32.562973
632	\N	Selusoh dalam bahasa Melayu berarti mantra. Sialang Rayo adalah pohon paling besar yang tumbuh di belantara hutan kanopi dan menjadi barang pusaka yang diatur dalam adat istiadat Orang Melayu. Cerita Selusoh Sialang Rayo mengambil latar di berbagai periodesasi kerajaan. Novel ini mengisahkan kehidupan perempuan tradisional yang hidup dalam lingkungan kerajaan dengan sistem yang sangat feodal dan tentu saja sangat normatif serta konvensional.- diambil dari Sekapur Sirih	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1743989831i/231107172.jpg	\N	\N	2026-05-05 05:54:12.729327	2026-05-05 05:54:12.729327
610	\N	Sepanjang hidup saya melihat manusia berkaki empat. Berekor anjing, babi atau kerbau. Berbulu serigala, landak, atau harimau. Dan berkepala ular, banteng, atau keledai. Namun tetap saja mereka bukan binatang. Cara mereka menyantap hidangan di depan meja makan sangat benar. Cara mereka berbicara selalu menggunakan bahasa dan sikap yang sopan. Dan mereka membaca buku-buku bermutu. Mereka menulis catatan-catatan penting. Mereka bergaun indah dan berdasi.Bahkan konon mereka mempunyai hati. Saya memperhatikan bayangan diri saya di dalam cermin dengan cermat. Saya berkaki dua, berkepala manusia, tapi menurut mereka, saya adalah seekor binatang. Kata mereka, saya adalah seekor monyet. Waktu mereka mengatakan itu kepada saya, saya sangat gembira. Saya katakan, jika saya seekor monyet maka saya satu-satunya binatang yang paling mendekati manusia. Berarti derajat saya berada di atas mereka.Tapi mereka manusia bukan binatang, karena mereka mempunyai akal dan perasaan. Dan saya hanyalah seekor binatang. Hanya seekor monyet....	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1458172588i/29537763.jpg	\N	\N	2026-04-04 11:05:10.289032	2026-04-04 11:05:10.289032
611	\N	Buku ini merupakan kumpulan lima belas cerita pendek Ahmad Tohari yang tersebar di sejumlah media cetak antara tahun 1983 dan 1997.Seperti novel-novelnya, cerita-cerita pendeknya pun memiliki ciri khas. Ia selalu mengangkat kehidupan orang-orang kecil atau kalangan bawah dengan segala lika-likunya.Ahmad Tohari sangat mengenal kehidupan mereka dengan baik. Oleh karena itu, ia dapat melukiskannya dengan simpati dan empati sehingga kisah-kisah itu memperkaya batin pembaca.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1384913224i/18867903.jpg	\N	\N	2026-04-04 16:15:37.63739	2026-04-04 16:15:37.63739
612	\N	Tarian Bumi menjadi fenomena sekaligus kontroversi. Novel ini dengan sangat terbuka menghantam keadaan yang melingkupi kehidupan perempuan di kalangan bangsawan Bali yang masih sangat feodal. Dalam konteks adat-istiadat Bali, Tarian Bumi dipandang sebagai sebuah pemberontakan kepada adat.—Tempo, 9 Mei 2004	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1758673308i/241996263.jpg	\N	\N	2026-04-04 20:29:22.678931	2026-04-04 20:29:22.678931
613	\N	Wilayah Kisoji ketakutan dengan serangan pasukan Daigo. Di sana, tuan Sanseu selaku pemilik rumah bangsawan memiliki kekuasaan yang lebih besar dibandingkan penguasa wilayahnya dan menjadikan orang-orang sebagai makanannya. Dororo dan Hyakkimaru pun masuk ke dalam wilayahnya. Di sana, mereka pun bertemu sosok yang dikenal. Siapakah dia?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1767205412i/245963964.jpg	\N	\N	2026-04-04 21:08:36.238358	2026-04-04 21:08:36.238358
614	\N	Yozo seorang pemuda yang eksentrik dan lain dari kebanyakan manusia di sekitarnya dalam memandang diri dan masyarakat. Dia selalu berusaha menyesuaikan diri dengan siapa pun, menurunkan dirinya sampai pada level mereka, tapi dia malah disalahpahami, diperalat, dan bahkan dikhianati. Dia berperan sebagai seorang badut, karena manusia membuatnya takut bersikap jujur. Seiring berjalannya waktu, dalam memainkan peran badut itu dia terjebak di tengah berbagai pengalaman yang tidak menguntungkan dirinya sendiri, jatuh pada kebiasaan destruktif yang pada akhirnya semakin membuatnya tidak berdaya dan mati secara perlahan.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1654827847i/61259200.jpg	\N	\N	2026-04-05 19:36:10.46303	2026-04-05 19:36:10.46303
615	\N	Majapahit adalah kerajaan besar di Nusantara yang kekayaan dan kekuasaannya dibangun dari perpaduan muslihat politik, panen raya padi, dan angkatan laut yang sedemikian perkasa sampai-sampai bahkan orang Portugis, pelaut hebat Eropa, pun terkesan. Namun, tidak banyak bukti fisik yang tersisa dari Majapahit. Sumber sejarah juga terbatas dan akurasinya meragukan. Ditulis berdasarkan sumber-sumber primer dan naskah-naskah kuno, cerita dalam buku ini mengangkat kisah raja-raja sangat eksentrik, perseteruan berdarah keluarga kerajaan, dan kisah tentang juru tulis istana pemabuk, tetapi memiliki kesadaran jernih untuk menuliskan segala yang dilihatnya.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1762939902i/243859154.jpg	\N	\N	2026-04-07 10:36:57.098938	2026-04-07 10:36:57.098938
616	\N	Penemuan Morel tidak hanya sebuah novel penting tetapi juga pelopor genre fiksi ilmiah dalam kesusastraan Spanyol. Bertempat di sebuah pulau misterius, novel ini penuh ketegangan dan eksplorasi, serta romansa yang sangat tidak terduga, di mana setiap detailnya sangat jelas dan sangat misterius.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1732297195i/221829787.jpg	\N	\N	2026-04-08 03:58:29.065159	2026-04-08 03:58:29.065159
617	\N	Sukuna yang telah mendapatkan kebebasan sementara, membuat kerusakan besar di Shibuya. Sementara itu, Fushiguro yang terluka parah akibat serangan mendadak Jusoshi, memutuskan untuk menggunakan cara terakhir. Menyadari bahwa Fushiguro memulai ritual untuk menaklukkan Shikigami, Sukuna lalu...!?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1712376259i/210946891.jpg	\N	\N	2026-04-08 18:18:08.608318	2026-04-08 18:18:08.608318
618	\N	Seorang anak lelaki empat belas tahun dirundung karena bermata juling. Alih-alih melawan, ia memilih menanggung derita dalam diam. Satu-satunya orang yang mengerti apa yang dialaminya adalah teman sekelasnya, Kojima, siswi yang juga mengalami perlakuan serupa dari para pengganggunya. Saling memberikan penghiburan saat mereka sangat membutuhkan, kedua remaja ini semakin dekat dari hari ke hari. Namun, bagaimana persahabatan yang terus-menerus dibayangi sekaligus direkatkan oleh teror ini akhirnya berkembang?“Mieko Kawakami adalah seorang pengarang yang tak pernah malu-malu menyingkap kebenaran sulit maupun pengalaman pahit.”—The Japan Times	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1702808381i/203925758.jpg	\N	\N	2026-04-11 09:00:40.802484	2026-04-11 09:00:40.802484
619	\N	"Misteri adalah dasar segala jenis hiburan.Rasa ingin tahu membuat pembaca terus membalik halaman."Semua orang yang ingin menjadi penulis punya cerita.Namun, menulisnya sampai tuntas, apalagi menyusunnya menjadi rangkaian yang utuh dan memikat pembaca, tidaklah mudah.Hook Your Readers adalah sebuah buku pengantar menulis yang akan membantumu memahami esensi bercerita: bagaimana membangun konflik dan karakter yang kuat, menata plot, hingga menghasilkan akhir mengesankan. Meski ditulis dari perspektif fiksi misteri, buku ini akan memberikanmu fondasi yang kuat untuk menulis cerita di berbagai genre.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1775305304i/250632279.jpg	\N	\N	2026-04-11 10:26:34.075649	2026-04-11 10:26:34.075649
620	\N	Pembunuhan massal oleh Sukuna, kematian Nanami, hingga tumbangnya Kugisaki di tangan Mahito. Ketika hati Itadori dikalahkan oleh beban rasa bersalahnya sendiri, seorang pria bergegas menuju ke sahabatnya yang tengah mengalami krisis itu. Bagaimanakah akhir dari perjalanan Itadori dan Mahito yang saling mengutuk!?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1719469369i/215519337.jpg	\N	\N	2026-04-11 11:06:27.240406	2026-04-11 11:06:27.240406
644	\N	Hamlet adalah drama tragedi yang ditulis Shakespeare antara tahun 1599 hingga 1602, yang berkisah tentang pembalasan dendam yang dilakukan Pangeran Hamlet kepada Claudius, pamannya. Claudius telah membunuh ayah Pangeran Hamlet, dan merebut takhta sekaligus istri Sang Raja.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1547306639i/43545845.jpg	\N	\N	2026-05-31 15:26:23.31079	2026-05-31 15:26:23.31079
621	\N	"Kebenaran seperti apa pun, tidak mungkin bisa menyembuhkan kepedihan seseorang yang ditinggal mati kekasihnya. Kebenaran seperti apa pun, ketulusan seperti apa pun, kekuatan seperti apa pun, kelembutan seperti apa pun, tidak bisa menyembuhkan kepedihan itu. Kita hanya bisa merasakan kepedihan itu sedalam-dalamnya, dan dari situ kita mempelajari sesuatu dan sesuatu yang kita pelajari itu pun menjadi percuma di saat kita menghadapi kesedihan yang sekonyong-konyong muncul.”KETIKA IA MENDENGAR “Norwegian Wood” karya Beatles, Toru Watanabe terkenang akan Naoko, gadis cinta pertamanya, yang kebetulan juga kekasih mendiang sahabat karibnya, Kizuki. Serta-merta ia merasa terlempar ke masa-masa kuliah di Tokyp, hampir dua puluh tahun silam, terhanyut dalam dunia pertemuan yang serba pelik, seks bebas, nafsu-nafsi, dan rasa hampa hingga ke masa seorang gadis bandung, Midori, memasuki masa depan dan masa silam.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1523262362i/39787524.jpg	\N	\N	2026-04-13 19:10:44.813729	2026-04-13 19:10:44.813729
622	\N	Ca-Bau-Kan (Hanya Sebuah Dosa) adalah kisah cinta antara perempuan Betawi dan pedagang Tionghoa dalam latar awal abad ke-20 hingga pascakemerdekaan Indonesia. Remy Sylado menggunakan narator Ny. Dijkhoff, seorang perempuan Belanda yang datang ke Indonesia untuk mencari tahu asal-usul ibunya yang ternyata adalah seorang ca-bau-kan atau perempuan penghibur bagi masyarakat Tionghoa. Dalam kompleksitas tersebut, novel ini menyatakan peran masyarakat Tionghoa peranakan dalam sejarah kemerdekaan Indonesia	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1677835826i/123169651.jpg	\N	\N	2026-04-15 04:28:12.207284	2026-04-15 04:28:12.207284
623	\N	Shinji penasaran dengan pilot Unit-00 yang misterius, Rei, termasuk hubungan dengan ayahnya. Di tengah percobaan aktivasi ulang Unit-00, datang Angel ke-5 yang memiliki sistem penyerangan dan pertahanan sempurna!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1700466648i/202427756.jpg	\N	\N	2026-04-15 05:27:24.069647	2026-04-15 05:27:24.069647
624	\N	Buku Ketiga dari Trilogi Rara Mendut“Panglima-panglima medan perang, raja, serta adipati adalah jago-jago perang, pendekar dalam seni menyebar maut. Mungkin itu nasib lelaki. Tetapi kita kaum perempuan, Lusiku sayang, kita punya keunggulan lain: mengandung, menyusui, mengemban, dan memekarkan kehidupan. Rahim kita serba menerima. Tetapi juga serba memberi. Payudara perempuanadalah buah yang membanggakan kaum kita, Lusi. Sumber pancuran kehidupan dan kesayangan. Bukan senjata. Bukan racun kepongahan.”*Lusi Lindri, anak Genduk Duku dipilih menjadi anggota Trinisat Kenya—pasukan pengawal Sunan Amangkurat I. Lusi Lindri menjalani kehidupan penuh warna di balik dinding-dinding istana yang menyimpan ribuan rahasia dan intrik-intrik jahat. Sebagai istri perwira mata-mata Mataram, ia tahu banyak... Bahkan terlalu banyak... Semakin lama nuraninya semakin terusik melihat kezaliman junjungannya. Tiada pilihan lain! Bulat sudah tekadnya, baginya lebih baik mati sebagai pemberontak penentang kezaliman daripada hidup nyaman bergelimang kemewahan.Lusi Lindri merupakan novel ketiga dari Trilogi Rara Mendut, mahakarya Y.B. Mangunwijaya. Sebuah narasi yang tidak hanya mengisahkan tumpang tindih hidup manusia, juga dengan apik menyinggung sejarah Tanah Jawa, keberanian perempuan, dan protes atas ketidakadilan.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1568769677l/50812292.jpg	\N	\N	2026-04-16 19:17:07.223001	2026-04-16 19:17:07.223001
626	\N	“Jangan menangis, Bocah. Kau akan jadi pekerja magang dan diurus oleh seorang pria baik hati. Berterima kasihlah kepadanya karena kau tidak akan lagi membebani kota ini,” kata Tuan Bumble, seseorang yang biasanya memukulinya.***Kisah tentang seorang anak yatim piatu yang disia-siakan memang mudah menarik simpati siapa pun untuk membacanya. Tapi, Oliver Twist bukanlah sekadar cerita sedih untuk mencari simpati dan menguras air mata pembaca. Lebih dari itu, novel ini dengan indahnya memotret karakter terdalam dari manusia.Dalam buku ini, tema-tema tentang ketekunan, kesabaran, dan kasih sayang saling berjalin dalam satu cerita bersama tema-tema kelam, seperti ketamakan, rasa pengecut, dan kekejian.Dengan membaca novel ini, pembaca dapat belajar banyak mengenai watak dasar manusia yang mungkin tertutupi oleh topeng bernama martabat atau kekuasaan.Bukan hal yang mudah untuk menyadur naskah asli Oliver Twist yang dalam draf asli berada dalam kisaran lebih dari 500 halaman menjadi sebuah naskah saduran utuh setebal ini. Upaya penyaduran dilakukan untuk lebih memperkenalkan karya ini kepada para pembaca umum, yang rata-rata lebih memilih buku bacaan yang tidak tebal dan bisa selesai dalam sekali-dua kali duduk.Selamat menikmati novel terbaik karya Charles Dickens yang mengandung nilai-nilai universal nan abadi ini!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1377241032i/18367697.jpg	\N	\N	2026-04-20 08:31:34.924893	2026-04-20 08:31:34.924893
629	\N	“Setiap bahasa berkembang secara berbeda dan untuk alasan-alasan emosional dan gramatikal yang berbeda. Membahas penerjemahan yang tepat adalah suatu cap birokratis, bukan suatu kebutuhan estetik, dan para penerjemah bukan birokrat, kecuali kalau mereka berniat untuk gagal.”Sebagai salah satu ahli perbukuan dan pembacaan terkemuka di dunia—yang sendirinya juga seorang penerjemah poliglot—Alberto Manguel berbagi renungan-renungannya tentang teks dan seni penerjemahan. Dengan meluaskan definisi penerjemahan, Manguel seolah bertanya: adakah sesuatu di dunia ini yang bukan penerjemahan, yang bukan penafsiran—sesuatu yang asli murni?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1777037814i/251425139.jpg	\N	\N	2026-05-03 12:16:24.522397	2026-05-03 12:16:24.522397
630	\N	Ada lima anak perempuan dalam keluarga Bennet yang dibesarkan oleh ibu mereka untuk memiliki satu tujuan hidup: mencari suami. Meskipun saudara-saudaranya sangat ingin mencari sendiri pria untuk dinikahi, Elizabeth Bennet lebih suka menunggu seseorang yang dicintainya—tentu saja bukan seseorang seperti Fitzwilliam Darcy, yang menurutnya angkuh dan suka menghakimi, berbeda dengan George Wickham yang menawan. Namun Elizabeth segera mengetahui bahwa kesan pertamanya mungkin salah, dan Fitzwilliam Darcy yang pendiam dan sopan mungkin adalah cinta sejatinya.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1732296884i/221829660.jpg	\N	\N	2026-05-03 12:17:31.853153	2026-05-03 12:17:31.853153
631	\N	Pada suatu malam bersalju tahun 1936, seorang seniman dipukuli hingga tewas di balik pintu studionya yang terkunci di Tokyo. Polisi menemukan surat wasiat aneh yang memaparkan rencananya untuk menciptakan Azoth—sang wanita sempurna—dari potongan-potongan tubuh para wanita muda kerabatnya. Tak lama sesudah itu, putri tertuanya dibunuh. Lalu putri-putrinya yang lain serta keponakan-keponakan perempuannya tiba-tiba menghilang. Satu per satu mayat mereka yang termutilasi ditemukan, semua dikubur sesuai dengan prinsip astrologis yang diuraikan sang seniman.Pembantaian misterius itu mengguncang Jepang, menyibukkan pihak berwenang dan para detektif amatir, namun tirai misteri tetap tak terpecahkan selama lebih dari 40 tahun. Lalu pada suatu hari di tahun 1979, sebuah dokumen diserahkan kepada Kiyoshi Mitarai—astrolog, peramal nasib, dan detektif eksentrik. Dengan didampingi Dr. Watson versinya sendiri—ilustrator dan penggemar kisah detektif, Kazumi Ishioka—dia mulai melacak jejak pelaku Pembunuhan Zodiak Tokyo serta pencipta Azoth yang bagaikan lenyap ditelan bumi.Kisah menarik tentang sulap dan ilusi karya salah satu pencerita misteri terkemuka di Jepang ini disusun seperti tragedi panggung yang megah. Penulis melemparkan tantangan kepada pembaca untuk membongkar misteri sebelum tirai ditutup.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1340777688i/15724390.jpg	\N	\N	2026-05-04 04:54:25.775225	2026-05-04 04:54:25.775225
633	\N	Bagi Soedarsono, putra seorang petani, predikat itu adalah sebuah dinasti yang harus dibangun dari nol. Dimulai sebagai guru desa hingga merambah birokrasi, ia adalah "Sang Pemula" pilar yang mengangkat harkat keluarga di asat tatanan kelas asosial.Namun, sejarah adalah arus yang tak bisa dibendung. Melintasi zaman Belanda, penduduk Jepang, hingga badai politik 1965, trah Soedarsono diuji. Cucu-cucunya tersesat dalam kemanjaan kelas menengah, terjebak idealisme kiri, dan tercerai berai oleh zaman.Di tengah keruntuhan nilai-nilai lama, muncullah Lantip. Ia bukan "darah biru" yang sah, melainkan anak luar nikah dari kerabat jauh. Justru darinya, kita akan belajar bahwa kepriyayian sejati bukanlah tentang silsilah atau pangkat, melainkan tentang keteguhan budi. Sebuah mahakarya Umar Kayam yang memotret wajah manusia Jawa dalam pusaran sejarah.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1770097504i/247516689.jpg	\N	\N	2026-05-10 15:33:51.475715	2026-05-10 15:33:51.475715
634	\N	Di suatu masa saat sebagian besar orang memiliki kekuatan super yang disebut dengan “Quirk”. Aku, Izuku Midoriya, seorang penggemar “Hero” yang bercita-cita mengikuti jejak Sang Hero Nomor 1 di Dunia, “All Might”, malah divonis tidak memiliki “Quirk”. Inilah awal ceritaku menuju Hero nomor 1 di dunia! "PLUS ULTRA"!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1505214980i/36226984.jpg	\N	\N	2026-05-10 15:38:52.68201	2026-05-10 15:38:52.68201
635	\N	What would the world be like if 80 percent of the population manifested superpowers called “Quirks” at age four? Heroes and villains would be battling it out everywhere! Being a hero would mean learning to use your power, but where would you go to study? The Hero Academy of course! But what would you do if you were one of the 20 percent who were born Quirkless?Getting into U.A. High School was difficult enough, but it was only the beginning of Izuku’s long road toward becoming a superhero. The new students all have some amazing powers, and although Izuku has inherited All Might’s abilities, he can barely control them. Then the first-year students are told they will have to compete just to avoid being expelled!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1437370282i/25111261.jpg	\N	\N	2026-05-14 06:52:31.05718	2026-05-14 06:52:31.05718
636	\N	Three short stories from the great Russian writer, including the title story, in which a thieving vagrant takes on a young, unwilling apprentice; "Twenty-six Men and A Girl," widely regarded as Gorky’s best short story, which describes how a wretched crew of bakery workers destroy their only source of joy; and the ill-fated romance, "Makar Chudra."	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1390885863i/370665.jpg	\N	\N	2026-05-14 13:37:12.140302	2026-05-14 13:37:12.140302
637	\N	Dinamika gambaran kehidupan manusia yang terus-menerus berubah menyebabkan sebagian manusia tidak mengindahkan lagi, mana yang harus dilakukan mana yang dilarang. Kebenaran, kebebasan, keadilan menjadi barang langka yang hanya menjadi impian belaka. Kekejaman telah memunculkan ketakutan, kegelisahan, kesengsaraan. Agar terbebas dari tekanan yang menyiksa, Kalatidha menyajikan sebuah potret bagaimana seseorang telah hidup di alam khayalnya dengan bahagia. Impian dan cita-cita yang selama ini didambakan, hanya dapat untuk menggambarkan bagaimana seseorang telah memenjarakan dirinya dari kehidupan nyata. Kehidupan nyata yang ia pahami hanyalah dunia yang dapat memberinya kesenangan, kegembiraan dan keceriaan. Hal-hal aneh yang dianggap menyimpang oleh masyarakat pada umumnya bukan merupakan celaan baginya. Satu hal yang ia yakini bahwa hidup ini adalah sebuah perjalanan, dan bagaimana ia menjalankannya. Kekosongan dan kehampaan bukan lagi siksaan, tapi sebuah proses yang harus dilewati dalam menempuh perjalanan.Kalatidha telah menjadi sebuah potret bagaimana pergolakan batin menjadi fokus sebuah lukisan kenyataan semu. Kepalsuan dan kepurapuraan adalah hal bodoh, dan kegilaan adalah tindakan dari suatu keputusasaan.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1223526947i/2040560.jpg	\N	\N	2026-05-16 04:46:06.153834	2026-05-16 04:46:06.153834
638	\N	What would the world be like if 80 percent of the population manifested superpowers called “Quirks”? Heroes and villains would be battling it out everywhere! Being a hero would mean learning to use your power, but where would you go to study? The Hero Academy of course! But what would you do if you were one of the 20 percent who were born Quirkless?A sinister group of villains has attacked the first-year U.A. students, but their real target is All Might. It’s all that Midoriya and his classmates can do to hold them off until reinforcements arrive. All Might joins the battle to protect the kids, but as his power runs out he may be forced into an extremely dangerous bluff!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1446684728i/25814001.jpg	\N	\N	2026-05-17 09:01:51.957617	2026-05-17 09:01:51.957617
639	\N	Upaya pembunuhan terhadap Menteri terbongkar sebelum waktunya dan digagalkan oleh kepolisian Tsar. Kelima “teroris” —tiga laki-laki dua perempuan—ditangkap dan dijatuhi hukuman gantung.Inilah novel pendek yang menyoroti renungan-renungan batin dan kondisi mental para terpidana pada malam sebelum eksekusi, ditulis oleh sastrawan yang digelari sebagai Bapak Ekspresionisme Kesusastraan Rusia.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1777141779i/251468380.jpg	\N	\N	2026-05-18 16:21:03.796377	2026-05-18 16:21:03.796377
640	\N	No te pierdas las espectaculares aventuras del guerrero más famoso del universo manga, Naruto Uzumaki, que para llegar a Hokage, el máximo grado ninja, ha de aprender a mantener el control de sus increíbles poderes.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1695169219i/137331216.jpg	\N	\N	2026-05-27 23:50:11.152855	2026-05-27 23:50:11.152855
641	\N	What would the world be like if 80 percent of the population manifested superpowers called “Quirks”? Heroes and villains would be battling it out everywhere! Being a hero would mean learning to use your power, but where would you go to study? The Hero Academy of course! But what would you do if you were one of the 20 percent who were born Quirkless?The U.A. High sports festival is a chance for the budding heroes to show their stuff and find a superhero mentor. The students have already struggled through a grueling preliminary round, but now they have to team up to prove they’re capable of moving on to the next stage. The whole country is watching, and so are the shadowy forces that attacked the academy…	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1443734662i/25814066.jpg	\N	\N	2026-05-28 00:08:12.503297	2026-05-28 00:08:12.503297
642	\N	A Room of One’s Own ditujukan bagi semua orang yang pernah bertanya-tanya mengapa sebagian besar perempuan tidak ada dalam buku-buku sejarah, kecuali jika mereka adalah ratu, ibu, atau gundik. Mengapa ruang bagi perempuan untuk berkarya sangat dibatasi di masa lalu? Ini adalah buku tentang feminisme yang diresapi humor, serta optimisme untuk apa yang dapat dicapai oleh seorang perempuan dengan pikiran yang terbebaskan.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1667840855i/63248630.jpg	\N	\N	2026-05-29 04:34:52.125687	2026-05-29 04:34:52.125687
643	\N	What he hears will change everything. Egged on by his wife, he decides to kill in order to gain the Scottish crown. How many people will have to die in Macbeth's pursuit of power? With armies, ghosts and magic against him, will Macbeth survive in this tale of greed and betrayal? Getting the crown is one thing - keeping it is quite another.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1671466418i/43913694.jpg	\N	\N	2026-05-31 09:16:53.520272	2026-05-31 09:16:53.520272
645	\N	Nyonya Dalloway adalah novel karya Virginia Dalloway yang mengisahkan kehidupan Nyonya Dalloway, seorang wanita kelas atas di Inggris pasca Perang Dunia Pertama. Nyonya Dalloway bahkan masuk dalam daftar 100 novel terbaik berbahasa Inggris versi majalah Time. Pagi itu Clarissa Dalloway berkeliling kota London demi membeli beberapa hal untuk persiapan pesta yang akan berlangsung di kediamannya malam itu. Di sepanjang perjalanannya, ia menemui beragam hal yang mengingatkannya pada masa mudanya yang dihabiskannya di kawasan pedesaan Bourton. la teringat persahabatannya yang 'tak biasa' dengan Sally Seton dan teman lamanya Peter Walsh yang mendamba cinta Clarissa. Setibanya di rumah, tiba-tiba saja Peter Walsh datang mengun-junginya setelah bertahun-tahun merantau ke India. Kemunculan Peter membangkitkan perasaan lama. la mulai mempertanyakan keputusan-keputusan yang telah diambilnya di masa muda, apakah ia telah memilih suami yang tepat? Mengapa dulu ia lebih memilih untuk menikah dengan Richard Dalloway daripada Peter Walsh? Apakah karena Richard lebih bisa diandalkan daripada Peter yang selalu gagal di segala aspek kehidupannya? ' Adeline Virginia Woolf (25 Januari 1882-28 Maret 1941) adalah penulis asal Inggris, yang dianggap sebagai penulis modern abad keduapuluh yang paling terkemuka. Karya-karyanya dikenal beraliran feminis, antara lain: To the Lighthouse (1927), Orlando: A Biography (1928), The Waves (1931), The Years (1941) dan Between the Acts (1941).	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1647041944i/60594141.jpg	\N	\N	2026-05-31 15:30:04.91131	2026-05-31 15:30:04.91131
646	\N	Dari dalam penjara yang dingin, kebosanan akan kediamanmungkin telah menggerogoti seluruh kesadarannya. Dalam masa-masa yang mungkin saja menjadi batas kehidupannya, lembar demi lembar ia coreti dengan tinta dan pengharapan. Lembar ke lembar bagaikan senjata yang siap memusnahkan belenggu, jeruji besi, dan tembok-tembok yang lembap.Gramsci menghancurkan pembatas antara kurungan dan dunia luar. Ia merindukan sebuah tatanan masyarakat yang berpikir untuk masyarakat. Ia melihat dunia dari lorong gelap kehidupan sejak dilahirkan, yang juga ia lihat dari pandangan-pandangan masyarakat atas "kekuasaan ketinggian" rasa tidak sanggup mendaki.Buku ini menawarkan sebuah kebebasan interpretasi terhadap pandangan-pandangan Gramsci, utamanya dalam melihat politik dan filsafat. Dua hal yang sering dipisah, justru dicetak oleh Gramsci dalam satu koin bernilai.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1765183154i/244934641.jpg	\N	\N	2026-05-31 15:54:39.033088	2026-05-31 15:54:39.033088
647	\N	Sejak hadir kali pertama pada 1844, The Count of Monte Cristo telah dialih rupa ke ratusan film, drama, dan opera. Bagi Alexandre Dumas sendiri, novel ini bukan sekadar kisah biasa. Melalui sosok Dante, Dumas ingin menceritakan ayahnya, seorang jenderal besar Prancis yang nasibnya berakhir pahit. Namun, kisah Dante adalah juga kisah kita, yang terus mencari keadilan di sepanjang hidup yang penuh kekecewaan.Terpuruk dalam dinginnya dinding penjara bawah tanah yang gelap, Dante bagai menghitung hari. Ulah satu komplotan jahat telah menghancurkan hidup kapten kapal pemberani itu. Tak ada lagi kapal megah beserta awak yang siap melayaninya. Ayahnya menanti ajal dalam kemiskinan tanpa kehadirannya. Wanita yang dicintainya pun turut dirampas. Masih layakkah dia berharap pada hidup?Namun, hidup yang dia benci masih menyimpan kejutan. Secuil harapan muncul justru dari sosok tak terduga: seorang pria renta yang sekarat. Dari tubuh rapuhnya, terlontar sebuah rahasia yang bisa membuat Dante keluar dari tempat terkutuk itu; lebih dari itu, balas dendam! Mata bayar mata, gigi bayar gigi.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1747182542i/233995500.jpg	\N	\N	2026-05-31 15:54:59.386319	2026-05-31 15:54:59.386319
648	\N	Inilah Kisah Seribu Satu Siang dan Malam gaya Naguib Mahfouz yang sulit dilupakan. Secara cerdas, ia menangguk ilham dari kekayaan khasanah kisah klasik Arab.Berbagai simbol, tokoh, alur, dan perangkat lain dari dunia dongeng Timur Tengah yang fantastik disiasatinya secara kreatif. Maka terciptalah dongeng politik religius yang memukau dengan ironi yang canggih yang mengemas pandangan ataupun kritik tajamnya terhadap penguasa yang korup dan suka menumpahkan darah, birokrasi yang kotor, pengusaha licik dan tamak, juga kaum intelektual munafik yang berlagak sebagai moralis. Novel ini adalah contoh keberhasilan meramu gagasan, wawasan spiritual, khasanah budaya tradisi, dan imajinasi kreatif menjadi karya sastra bermutu dari seorang penulis yang layak mendapat hadiah Nobel.Dengan novelnya ini, pantas jika The Financial Times menilai Mahfouz sebagai novelis kontemporer yang paling cerdas.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1616606518i/57516801.jpg	\N	\N	2026-05-31 15:57:39.516068	2026-05-31 15:57:39.516068
649	\N	This epic tale about the effects of the Russian Revolution and its aftermath on a bourgeois family was not published in the Soviet Union until 1987. One of the results of its publication in the West was Pasternak's complete rejection by Soviet authorities; when he was awarded the Nobel Prize for Literature in 1958 he was compelled to decline it. The book quickly became an international best-seller.Dr. Yury Zhivago, Pasternak's alter ego, is a poet, philosopher, and physician whose life is disrupted by the war and by his love for Lara, the wife of a revolutionary. His artistic nature makes him vulnerable to the brutality and harshness of the Bolsheviks. The poems he writes constitute some of the most beautiful writing featured in the novel.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1385508725i/130440.jpg	\N	\N	2026-05-31 15:59:18.076527	2026-05-31 15:59:18.076527
650	\N	A Christmas Carol menceritakan kisah Ebenezer Scrooge yang sangat pelit dan sangat membenci Natal. Ia menolak undangan keponakannya, Fred, untuk makan malam bersama keluarganya di malam Natal, bahkan mengejek Fred yang telah menikah. Scrooge juga mengusir pria-pria yang mendatanginya untuk meminta donasi bagi kaum miskin dan papa. Dan Scrooge bahkan harus berdebat dengan karyawannya, Bob Cratchitt, sebelum akhirnya memberikan hari libur di hari Natal.Di malam Natal, tujuh tahun setelah kematian rekan bisnisnya, Jacob Marley, Scrooge tiba-tiba mengalami peristiwa yang sangat aneh. Ia didatangi oleh hantu Marley! Marley dikutuk selamanya untuk menghantui dunia dengan menyeret rantai yang sangat berat di kakinya, karena di sepanjang hidupnya ia sangat tamak dan egois.Agar Scrooge tak mengalami nasib yang sama sepertinya, Marley memberitahunya bahwa ia akan didatangi tiga roh. Scrooge harus mendengarkan perintah roh tersebut, agar tak menerima kutukan yang sama dengannya. Scrooge yang sangat ketakutan terpaksa menurutinya. Namun akhirnya ia menyadari hal yang selama ini luput dari pandangan, pikiran serta perasaannya. Dan Natal kali itu menjadi Natal yang sangat istimewa untuk Scrooge.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1567086438l/52762824.jpg	\N	\N	2026-05-31 15:59:39.456838	2026-05-31 15:59:39.456838
674	\N	A new vision based on Astroboy - "The greatest robot on earth". Final Volume!Contains Chapters 56 to 65.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1554094371i/6889271.jpg	\N	\N	2026-05-31 16:29:02.927223	2026-05-31 16:29:02.927223
675	\N	Akhirnya Festival Olahraga Akademi U.A. memasuki babak akhir! Walau saling bertarung, tapi kami semua adalah teman sekaligus rival! Aku juga harus menunjukkan pertarungan yang tidak membuat Hero seperti kakak merasa malu! "Plus Ultra!!"	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1527296698i/40212337.jpg	\N	\N	2026-05-31 16:29:28.677302	2026-05-31 16:29:28.677302
651	\N	Buku ini mengisahkan persekutuan “aneh” di Australia antara pejabat Belanda yang melarikan diri ke Australia setelah Hindia Belanda diduduki oleh Jepang, dan para tahanan komunis serta nasionalis yang dibuang di Boven Digoel. Persekutuan dimulai pada 1943 karena orang Belanda dan orang buangan memiliki musuh bersama yang ditakuti, yaitu kekuatan fasis Jepang.Van der Plas adalah tokoh utama Belanda yang berharap dapat memanfaatkan orang-orang Digoel. Ia membujuk para tahanan untuk pindah ke Australia dengan iming-iming akan membebaskan mereka. Ia juga berharap bahwa organisasi baru Serikat Indonesia Baroe atau SIBAR, yang dibentuk sebagai hasil kerja sama pemerintah Belanda dan orang buangan, akan menjadi alat untuk memudahkan kembalinya kekuasaan Belanda. Bagi orang komunis, SIBAR menjadi cara untuk mempropagandakan kemerdekaan Indonesia dan mengkritik Belanda. Sementara itu, kaum komunis menganggap Belanda sebagai kawan sehaluan, bahkan ketuanya, Sardjono, disumpah sebagai opsir KNIL. Sejarawan terkemuka Harry A. Poeze mengungkapkan dengan terperinci dalam buku ringkas tetapi sarat informasi ini perihal bagaimana persekutuan “aneh” tersebut berjalan.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1421739709i/24589063.jpg	\N	\N	2026-05-31 16:00:20.326602	2026-05-31 16:00:20.326602
652	\N	A selection of writings by one of the most important practitioners of social revolution. "The best available in English. Bakunin's insights into power and authority, and the conditions of freedom, are refreshing, original and still unsurpassed in clarity and vision. I read this selection with great pleasure."--Noam Chomsky	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1348965205i/203890.jpg	\N	\N	2026-05-31 16:01:55.67103	2026-05-31 16:01:55.67103
653	\N	Umberto Eco was an Italian medievalist, philosopher, semiotician, novelist, cultural critic, and political and social commentator. In English, he is best known for his popular 1980 novel The Name of the Rose, a historical mystery combining semiotics in fiction with biblical analysis, medieval studies and literary theory, as well as Foucault's Pendulum, his 1988 novel which touches on similar themes.Eco wrote prolifically throughout his life, with his output including children's books, translations from French and English, in addition to a twice-monthly newspaper column "La Bustina di Minerva" (Minerva's Matchbook) in the magazine L'Espresso beginning in 1985, with his last column (a critical appraisal of the Romantic paintings of  Francesco Hayez) appearing 27 January 2016. At the time of his death, he was an Emeritus professor at the University of Bologna, where he taught for much of his life. In the 21st century, he has continued to gain recognition for his 1995 essay "Ur-Fascism", where Eco lists fourteen general properties he believes comprise fascist ideologies.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://dryofg8nmyqjw.cloudfront.net/images/no-cover.png	\N	\N	2026-05-31 16:02:29.683224	2026-05-31 16:02:29.683224
654	\N	Sesudah GODOT dikenal luas di Indonesia sejak 1989,tatkala pentas di Teater Besar, TIM, oleh Bengkel Teater, baru sekarang naskahnya mewujud dalam bentuk buku. Lakon ini diharapkan bisa merangsang lebih banyak pecinta teater tidak hanya mementaskannya, tetapi juga mempelajari lebih suntuk. Sebab lakon yang tampaknya bernada—dasar pesimistik ini, sebenarnya terkandung keberanian luar biasa untuk memertahankan kesetiaan menunggu sesuatu yang diharapkan. Hadirnya buku ini diharapkan bisa membantu kita untuk tetap setia kepada sesuatu atau seseorang atau keadaan yang kita nanti-nantikan. Kita memerlukan dorongan semangat untuk bisa menjaga daya hidup.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1456719322i/29364108.jpg	\N	\N	2026-05-31 16:02:56.538972	2026-05-31 16:02:56.538972
655	\N	Manusia itu bebas,atau ditentukan kodrat?Dari dasar lautan,Wisanggeni Sang Buronan,menyerbu kahyanganmencari jawab.Seru seperti cerita silat.Bijak seperti buku filsafat.Ringan seperti hiburan.Pernah dimuat bersambung di majalah mingguan Zaman dari edisi 21 Juli sampai 1 September 1984.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1470155507i/1025833.jpg	\N	\N	2026-05-31 16:04:31.873067	2026-05-31 16:04:31.873067
656	\N	Awarded the Nobel Prize in Literature in 1913 "because of his profoundly sensitive, fresh and beautiful verse, by which, with consummate skill, he has made his poetic thought, expressed in his own English words, a part of the literature of the West."Tagore modernised Bengali art by spurning rigid classical forms and resisting linguistic strictures. His novels, stories, songs, dance-dramas, and essays spoke to topics political and personal. Gitanjali (Song Offerings), Gora (Fair-Faced), and Ghare-Baire (The Home and the World) are his best-known works, and his verse, short stories, and novels were acclaimed—or panned—for their lyricism, colloquialism, naturalism, and unnatural contemplation. His compositions were chosen by two nations as national anthems: India's Jana Gana Mana and Bangladesh's Amar Shonar Bangla.The complete works of Rabindranath Tagore (রবীন্দ্র রচনাবলী) in the original Bengali are now available at these third-party websites:http://www.tagoreweb.in/http://www.rabindra-rachanabali.nltr....	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1352708158i/6087605.jpg	\N	\N	2026-05-31 16:07:00.78046	2026-05-31 16:07:00.78046
657	\N	Seribu Burung Bangau merupakan salah satu novel Yasunari Kawabata yang mengungkapkan masalah cinta berikut nuansa aspek-aspeknya yang lembut, subtil, penuh rahasia dan indah. Melalui deskripsi tentang hal-hal yang bersahaja, seperti cangkir teh atau motif hiasan sapu tangan, Kawabata menyiratkan dalamnya makna memiliki, kehilangan dan juga pengkhianatan yang acapkali menyertai cinta.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1474275943i/3682390.jpg	\N	\N	2026-05-31 16:09:07.146154	2026-05-31 16:09:07.146154
658	\N	This work has been selected by scholars as being culturally important and is part of the knowledge base of civilization as we know it.This work is in the public domain in the United States of America, and possibly other nations. Within the United States, you may freely copy and distribute this work, as no entity (individual or corporate) has a copyright on the body of the work.Scholars believe, and we concur, that this work is important enough to be preserved, reproduced, and made generally available to the public. To ensure a quality reading experience, this work has been proofread and republished using a format that seamlessly blends the original graphical elements with text in an easy-to-read typeface.We appreciate your support of the preservation process, and thank you for being an important part of keeping this knowledge alive and relevant.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1253549466i/2692676.jpg	\N	\N	2026-05-31 16:10:39.089428	2026-05-31 16:10:39.089428
659	\N	Anak-anak dan para nabi, keduanya sama-sama mempunyai visi dan imajinasi yang kreatif mengenai dunia dan cara mengelolanya. Yang membedakannya yaitu bahwa nabi-nabi dengan cara yang tepat dan terpuji mampu membagikan visinya kepada orang lain, sedangkan anak-anak sekedar menikmatinya. Melalui cerpen-cerpennya dalam buku ini, Tagore menunjukkan bahwa dirinya adalah anak-anak sekaligus nabi.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1310534199i/12027778.jpg	\N	\N	2026-05-31 16:12:56.919952	2026-05-31 16:12:56.919952
676	\N	Saat Shinji dan ayahnya mengunjungi makam ibunya, Angel kembali menyerang! Saat ini tiga unit Eva bekerja sama untuk menghadang Angel!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1711708802i/210513717.jpg	\N	\N	2026-05-31 16:31:04.85723	2026-05-31 16:31:04.85723
660	\N	"Brilian dan asyik dibaca." --Literary Review"Aku menguntitmu ke mana-mana seperti mata-mata. Kau cantik, cantik sekali."Sebuah surat dari sosok tak dikenal mengagetkan Chantal. Tanpa alamat, tanpa perangko. Sebersit persaan tidak senag menyergapnya. Seseorang tengah berusaha menarik perhatiannya, memasuki kehidupannya. Dan ia tidak begitu suka. Lagipula ia tidak punya cukup enerji untuk memberi semacam perhatian.Namun di tengah kehidupannya yang digelayuti pikiran akan kematian dan perasaan 'tidak ada lagi lelaki yang menoleh padanya', surat itu memercikkan sedikit suasanan yang berbeda. Ia sembunyikan surat itu dari Jean-March, ia taruh di dalam lemarinya, di bawah lipatan pakaian dalamnya. Sampai saat itu tiba, saat di mana mereka merasa asing satu sama lain, tercemburu, terkhianati.Inilah novel dari seorang penulis ternama kelahiran Cekoslovakia, Milan Kundera, yang bukan saja enak dinikmati tetapi juga mengajak kita untuk sedikit berefleksi: tentang persahabatan, cinta, hidup, dan kematian. Karena kecerdasannya, tidak heran jika novel ini terpilih sebagai New York Times Notable Book pada tahun 1998.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1210920724i/2785943.jpg	\N	\N	2026-05-31 16:13:47.93357	2026-05-31 16:13:47.93357
661	\N	Dalam cerpen-cerpen Umar Kayam kita bisa melihat bahkan percakapan-percakapan itu demikian nyata. Ia tak hanya mengajak kita, pembacanya, untuk bercakap-cakap, tapi juga mengajak dan membiarkan tokoh-tokohnya juga bercakap cakap. Kita bisa melihat atau merasakan betapa gentingnya kebutuhan mereka untuk melakukan perbincangan, penuh hasrat untuk menemukan teman ngobrol, dan kita ada untuk memberikan diri sendiri sebagai pendengar sekaligus menciptakan narasi sendiri melalui cerita mereka.Seorang penulis seperti Umar Kayam tak hanya seorang pendongeng yang melaporkan satu keping peristiwa kepada pembacanya, tapi jauh lebih penting adalah seorang teman bicara. Teman ngobrol. (Eka Kurniawan)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1543248089i/42958942.jpg	\N	\N	2026-05-31 16:14:31.047339	2026-05-31 16:14:31.047339
662	\N	“Sebelum revolusi, dia calon rahib. Selama revolusi, dia komandan kompi. Diakhir revolusi, dia algojo berdarah dingin. Sesudah revolusi, dia masuk rumah sakit jiwa!”Pembukaan novel yang mencekam seperti itu, sampai dengan tahun 1960 silam, merupakan pembukaan novel yang khas milik Iwan Simatupang. Pembukaan novel yang padat, penuh dengan pandangan-pandangan hidupnya. Ini juga yang menjadi dasar konsep penulisan kesustraannya yang sarat dengan personifikasi teori eksistensialisme.Novel yang mulai ditulis 18 Maret 1961 hingga 9 September 1961, menampilkan Tokoh kita. Yang dengan kesadarannya bergelimang pada nilai-nilai irasionalisme, kesadaran pada nilai-nilai ‘gelandangannya’, tak jelas mana makna dan realitas. Hingga akhirnya terbias menjadi manusia-manusia kalah dalam usaha memahami apa sebenarnya hakikat hidup ini.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1592051353i/53998647.jpg	\N	\N	2026-05-31 16:15:02.009631	2026-05-31 16:15:02.009631
663	\N	Botchan, seorang pemuda yang baru lulus kuliah, memulai pekerjaan pertamanya sebagai guru di sekolah negeri, namun tidak pernah membayangkan apa yang menantinya. Ada para siswa yang berusaha memata-matainya, ada sesama guru yang saling bersaing satu sama lain, serta ada pemilik rumah yang menjual barang antik tak berharga kepadanya. Terlepas dari semua itu, Botchan memiliki kepedulian yang besar terhadap Kiyo, pelayan keluarga yang ditinggalkannya dan merupakan satu-satunya orang yang menyayanginya dengan tulus.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1677585905i/123027647.jpg	\N	\N	2026-05-31 16:15:32.534094	2026-05-31 16:15:32.534094
664	\N	“Gadis celaka, kau harus tetap di sini bersamaku! Hidup di antara makam-makam sunyi ini, wajah-wajah kematian, mayat-mayat membusuk yang rusak dan menjijikkan!”Salah satu novel horor gotik klasik yang mengisahkan Ambrosio sang rahib. Tiga puluh tahun ia hidup dalam kaul spiritual, berlindung di balik dinding-dinding biara yang tebal dan kokoh. Khotbahnya memukau masyarakat Madrid, membuatnya dianggap sebagai orang suci, tapi ia sendiri terpukau balik oleh kesalehan dan wibawanya. Ia jatuh dalam kesombongan iman, dan itu hanyalah awal dari keruntuhannya, membawanya terjerat nikmat berahi. Sementara hantu-hantu bergentayangan di kastil-kastil, hantu yang paling menakutkan tetaplah berwujud manusia: sang rahib yang bersembunyi dalam jubah kesalehannya.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1613804458i/57134191.jpg	\N	\N	2026-05-31 16:16:00.00313	2026-05-31 16:16:00.00313
665	\N	A gripping portrayal of London's dark criminal underbelly, published in Penguin Classics with an introduction by Philip Horne.The story of Oliver Twist - orphaned, and set upon by evil and adversity from his first breath - shocked readers when it was published. After running away from the workhouse and pompous beadle Mr Bumble, Oliver finds himself lured into a den of thieves peopled by vivid and memorable characters - the Artful Dodger, vicious burglar Bill Sikes, his dog Bull's Eye, and prostitute Nancy, all watched over by cunning master-thief Fagin. Combining elements of Gothic Romance, the Newgate Novel and popular melodrama, Dickens created an entirely new kind of fiction, scathing in its indictment of a cruel society, and pervaded by an unforgettable sense of threat and mystery.This Penguin Classics edition of Oliver Twist is the first critical edition to faithfully reproduce the text as its earliest readers would have encountered it from its serialisation in Bentley's Miscellany, and includes an introduction by Philip Horne, a glossary of Victorian thieves' slang, a chronology of Dickens's life, a map of contemporary London and all of George Cruikshank's original illustrations.For more than seventy years, Penguin has been the leading publisher of classic literature in the English-speaking world. With more than 1,700 titles, Penguin Classics represents a global bookshelf of the best works throughout history and across genres and disciplines. Readers trust the series to provide authoritative texts enhanced by introductions and notes by distinguished scholars and contemporary authors, as well as up-to-date translations by award-winning translators.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1327868529i/18254.jpg	\N	\N	2026-05-31 16:19:09.18955	2026-05-31 16:19:09.18955
666	\N	Kumpulan esai dalam buku ini dimaksudkan untuk mendokumentasikan perjalanan kepenulisan penulis selama 20 tahun, yaitu mulai dari terbitnya tulisan pertamanya pada tahun 2001 sampai pada tahun publikasi esei terakhir di buku ini, yaitu 2021. Banyak di antara esei di kumpulan ini merespon situasi atau perkembangan tertentu di dunia sastra Indonesia, yang seringkali menjadi bagian dari perdebatan yang lebih luas.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1764744602i/244721663.jpg	\N	\N	2026-05-31 16:20:28.812186	2026-05-31 16:20:28.812186
667	\N	Buku ini memuat seluruh cerpen Seno Gumira Ajidarma yang pernah dimuat Harian Kompas antara 1978-2013. Inilah 84 cerpen yang dalam 35 tahun secara kronologis menjelajahi berbagai tema dalam beragam cara, yang selain bisa dibaca sebagai hiburan, berpeluang diperiksa dalam konteks sosial historis zamannya. Dalam penerbitan kali ini, sejumlah cerpen ditulis ulang, sehingga bisa juga dibaca sebagai karya baru.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1409371914i/23125037.jpg	\N	\N	2026-05-31 16:21:08.713716	2026-05-31 16:21:08.713716
677	\N	Setelah kejadian yang menimpa teman sekelasnya, Shinji memutuskan untuk tidak akan menaiki Evangelion lagi dan keluar dari NERV. Tidak lama setelahnya, Angel baru menyerang dan membuat NERV kewalahan!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1722577582i/217086278.jpg	\N	\N	2026-05-31 16:31:46.967049	2026-05-31 16:31:46.967049
668	\N	Genom manusia, seperangkat lengkap gen yang terdapat dalam dua puluh tiga pasang kromosom, tidak lain adalah autobiografi spesies kita. Dengan telah diumumkannya “draf kasar” genom manusia, berarti kita, generasi yang beruntung ini, menjadi makhluk hidup pertama yang mampu membaca buku pintarnya sendiri, sekaligus memperoleh wawasan paling mendalam tentang makna hidup, arti menjadi manusia, kesadaran, atau fenomena jatuh sakit.Dengan mengambil satu gen yang baru ditemukan dari tiap pasang kromosom kemudian menyuruhnya bercerita, Matt Ridley mengajak kita menapak tilas sejarah spesies kita sendiri berikut nenek-nenek moyangnya, sejak fajar kehidupan hingga peluang datangnya zaman kedokteran masa depan.Ia menemukan gen-gen yang mungkin memengaruhi kecerdasan kita, gen-gen yang memungkinkan kita bertata bahasa, gen-gen yang memandu perkembangan tubuh dan otak kita, gen-gen yang memungkinkan kita mengingat, gen-gen yang menunjukkan keistimewaan unsur bawaan dan pengaruh pengasuhan, gen-gen yang membebani kita dengan kecenderungan egois, gen-gen yang saling berperang, juga gen-gen yang merekam sejarah perpindahan penduduk.Ia menggali berbagai upaya penerapan genetika: untuk memahami penyakit Huntington hingga mengobati kanker. Ia mengupas munculnya kecemasan dan kengerian terhadap eugenika, serta implikasi filosofi dari memahami paradoks kehendak bebas.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1501129930i/35835615.jpg	\N	\N	2026-05-31 16:21:47.968473	2026-05-31 16:21:47.968473
669	\N	[Sampul alternatif dari ISBN yang sama dapat diakses di laman ini]Sesudah Uni Soviet runtuh, kapitalisme sempat disanjung sebagai keniscayaan sejarah. Namun krisis demi krisis di abad ke-21 menyadarkan banyak orang bahwa cita-cita sosialisme tidak berakhir dengan Uni Soviet. Semangat Revolusi Oktober nyatanya terus menginspirasi perjuangan demi dunia yang lebih adil. Inilah revolusi yang membuktikan bahwa kelas buruh dan tani bisa menggulingkan pemerintah autokratik dan membentuk pemerintahan sendiri dalam rupa gambarannya.Buku ini bukan kajian komprehensif, melainkan buku kecil dengan harapan besar: menjelaskan kekuatan Revolusi Oktober bagi emansipasi negara-negara jajahan."Prashad menulis buku sejarah dalam gaya sastrawi. Momen-momen dikerangkai dalam cara yang memudahkan untuk membayangkan latarnya (...) efektif untuk menyampaikan poin utama buku ini: perjuangan demi perjuangan terhubung lintas ruang dan waktu manakala ada organisasinya."- Citizens' Press"Brilian dan mengusik pikiran, titik awal penting untuk memahami komplaksitas komunisme internasional selama abad lalu." - Communist Review	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1600661207i/55400518.jpg	\N	\N	2026-05-31 16:22:20.012729	2026-05-31 16:22:20.012729
670	\N	“…yang dulu ada, sekarang tidak ada. Yang sekarang ada, kelak tidak ada. Yang sekarang belum ada, kelak akan ada.”Inilah kisah tentang Ny. Talis, perias pengantin yang dapat melompat dari satu gedung ke gedung lain, sehingga dia mampu merias banyak pengantin dalam sekali tempo. Ini juga tentang Santi Wedanti penyanyi, pemilik restoran, sekaligus calon sarjana hukum. Juga perihal Wiwin, sang pelukis yang meninggal dalam kecelakaan mobil usai melakukan pameran di Jakarta. Dan tentu, soal Madras yang setiap hari menyaksikan debu beterbangan sekaligus pengikat banyak tokoh dan keajaiban.Novel ini merekam perjalanan hidup manusia dalam menapaki titah sang nasib, hingga menemukan hakikat di hadapan Sang Maha Pencipta, sekaligus kefanaan dirinya.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1695022657i/199009980.jpg	\N	\N	2026-05-31 16:22:51.183728	2026-05-31 16:22:51.183728
671	\N	Setelah beberapa tahun mencoba, saya menemukan sejenis medium berkelamin ganda, pada bentuk yang kemudian berkembang: blog, sebuah ungkapan ringkas dari weblog. Di satu sisi, seperti tulisan di media cetak, ia bersifat publik. Terbuka untuk dibaca siapa saja. Di sisi lain, seperti catatan harian atau surat, bisa juga bersifat pribadi dan personal. Apalagi mengingat bentuk ini nyaris tak memiliki sekat antara ketika ditulis dan diterbitkan: tak ada otoritas media, tak ada saringan editorial. Saya bisa memilih sendiri buku yang saya baca dan menulis sesuatu dengan cara yang saya inginkan. Di sini saya bisa menebarkan remah-remah roti Hansel dan Gretel untuk melacak jejak-jejak bacaan saya, juga pikiran, agar mudah kembali ke sana, sekaligus memungkinkan untuk dibaca siapa pun. Siapa tahu dalam perjalanan ini saya tersesat dalam labirin bacaan tak berujung, dan kita dipertemukan di suatu tempat, untuk memulai perbincangan yang lain.Dunia sastra kita akan dipenuhi penulis-penulis yang bertabiat ugal-ugalan seperti sopir angkutan umum di Jakarta. Dan mereka akan bangga dengan ini. Bangga telah menjadi penulis berpihak, tak peduli caranya menulis menyedihkan. Mungkin seperti kata Lenin (saya kutip semena-mena): "Penyakit kiri kekanak-kanakan." Bangga telah menjejali novel dengan pesan-pesan moral, tapi lupa bagaimana menulis yang benar (belum lagi sampai tahap mengasyikan). Tapi ah, kenapa saya harus jengkel? Saya bukan guru yang harus mendidik orang bagaimana bersikap, sebagaimana tak perlu mendidik para penulis dan kaum intelektual. Mereka sudah cukup pintar untuk melihat kebodohan-kebodohan di dalam diri sendiri. Barangkali problem utamanya bukan ini, tapi kebutuhan saya untuk mengunjungi psikiater. Untuk meredakan ketegangan-ketagangan estetik, kejengkelankejengkelan yang tak perlu. Beberapa miligram obat pengendali mood mungkin baik buat saya, sehingga tak terlalu terganggu oleh apa pun yang terjadi di dunia kesusastraan. Seperti kata Roberto Bolano, kita para penulis (yang baik, dan saya harap saya bisa menjadi bagiannya, bahkan meskipun saya penulis yang buruk, saya akan mengikuti sarannya), tak memerlukan siapa pun untuk bernyanyi bertepuk tangan atas karya-karya kita. Kenapa? Karena kita sudah dan akan melakukannya sendiri. Kita akan bernyanyi dan bertepuk tangan untuk karyakarya kita sendiri. Dan saya mesti mengingatkan diri sendiri, satu-satunya ukuran yang perlu diperhatikan adalah ukuranukuran yang telah ditancapkan oleh diri sendiri. Jika ingin menulis karya bermoral, tulislah. Jika ingin menulis karya tak bemoral, tulislah. Yang akan membuat saya membaca novel itil, pertama-tama bagaimana ia dituliskan. Menarik atau tidak? Mengasyikan atau tidak? Kalau sekadar ingin bilang "para bayi butuh minum ASI hingga 6 bulan” cukup tuliskan dalam satu baris kalimat, tak perlu satu novel.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1764893001i/244807341.jpg	\N	\N	2026-05-31 16:24:32.980328	2026-05-31 16:24:32.980328
672	\N	Seseorang bisa sadar membaca karya-karya tertentu dan mengabaikan karya-karya lain. Kadangkala bersifat acak dan tanpa sadar. Tergantung bagaimana ia memperoleh akses terhadap bacaan, maupun bias-bias pra-keputusan membaca. Orang bisa dengan sadar membaca lebih banyak karya penulis-penulis minoritas (baik secara genre, orientasi seks, etnik, bahasa, dan lainnya). Tapi tetap tanpa sadar dibentuk oleh apa yang disediakan toko buku atau industri buku terjemahan, jika sang pembaca kebetulan hanya menguasai bahasa ibunya.Tulisan-tulisan di buku ini, juga buku sebelumnya (Senyap yang Lebih Nyaring, 2018), merupakan hamparan terbuka sejarah kesusastraan personal saya, yang dibentuk oleh pilihan bacaan secara sadar dan tanpa sadar. Tulisan-tulisan tersebut secara langsung menggambarkan cara pandang saya terhadap sejarah kesuastraan (dan pada akhirnya terhadap Sejarah dengan “S” besar, sejarah yang lebih luas). Bisa juga dilihat sebagai usaha kecil untuk mencatat… Semacam usaha menulis silsilah bacaan. Di titik tertentu mungkin kita berkerabat; di titik lain, siapa tahu, leluhur bacaan kita saling menikam.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1764893123i/244807384.jpg	\N	\N	2026-05-31 16:26:12.134319	2026-05-31 16:26:12.134319
673	\N	Dalam novel ini Kundera mencoba menganalisa manusia melalui kehidupan pelik dua orang wanita kakak beradik bernama Agnes dan Laura, serta melalui percakapan imajinernya dengan sosok terkenal yang namanya kekal seperti Goethe dan Hemingway: tentang perjalanan hidup mereka sebelum menuai sukses hingga arti kesuksesan setelah mereka tiada. “Kematian dan kekekalan adalah sepasang kekasih tak terpisahkan. Lebih erat daripada Marx dan Engels, Romeo dan Juliet, Laurel dan Hardy… Dalam urusan kekekalan, manusia tidaklah sederajat. Kita mesti membedakan kekekalan kecil: kenangan terhadap seseorang dalam benak orang-orang yang mengenalnya, dengan kekekalan agung: kenangan terhadap seseorang dalam benak orang-orang yang sama sekali tidak dikenalnya dan juga tidak mengenalnya.”	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1490161739i/34660173.jpg	\N	\N	2026-05-31 16:27:22.08836	2026-05-31 16:27:22.08836
686	\N	Menciptakan JURUS PAMUNGKAS?! aku jadi semangat! baiklah! akan kuperbarui juga kostumku untuk menunjukkan diriku yang baru! kita pasti akan lulus UJIAN LISENSI SEMENTARA! “PLUS ULTRA”!Teater Tawa Hero!Mari awali tahun baru dengan penuh tawa!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1565851279l/51896227.jpg	\N	\N	2026-05-31 16:38:01.584914	2026-05-31 16:38:01.584914
687	\N	Tahap terakhir dari ujian lisensi hero sementara adalah “MISI PENYELAMATAN”! kemampuan membaca kondisi! kecepatan reaksi! dan yang terpenting... koordinasi bersama rekan! BOOOOM! uwa, apa itu?! villain muncul di dekat lokasi pengungsian?! aku harus secepatnya ikut menolong! “PLUS ULTRA”!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1581946403i/51377539.jpg	\N	\N	2026-05-31 16:38:37.114537	2026-05-31 16:38:37.114537
688	\N	Liburan musim panas berakhir dan semester kedua pun dimulai! eh? “KEGIATAN INTERNSHIP HERO”? apa bedanya dengan kegiatan magang yang sudah kami lakukan? selain itu, juga ada kakak kelas yang kelihatannya kuat! apa?! mereka itu “BIG THREE”?! “PLUS ULTRA”!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1585410255i/52763050.jpg	\N	\N	2026-05-31 16:39:11.083204	2026-05-31 16:39:11.083204
689	\N	Kenapa gelagat Midoriya jadi aneh sejak kembali dari kegiatan internship? APA ADA GADIS YANG LAGI DALAM BAHAYA?! RETAKNYA HUBUNGAN GURU MURID?! ATAU ADA ORGANISASI GELAP YANG LAGI BERAKSI SECARA DIAM-DIAM?! Yah, cerita kayak gitu cuma muncul di komik, sih. aah, rasanya aku jadi ingin pergi ke tampat yang banyak hero ceweknya... “PLUS ULTRA”!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1593922742i/54393670.jpg	\N	\N	2026-05-31 16:40:42.198027	2026-05-31 16:40:42.198027
690	\N	Grup intern Midoriya, Kirishima, serta Uraraka dan Asui bergabung dengan para hero profesional untuk melaksanakan sebuah MISI PENYERBUAN! Kirishima, kau adalah PRIA YANG DAPAT DIANDALKAN. Sebab kau berani pasang badan demi melindungi rekanmu! Terjanglah semua tantangan dengan penuh percaya diri! “PLUS ULTRA”!!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1613080162i/57033170.jpg	\N	\N	2026-05-31 16:41:02.384418	2026-05-31 16:41:02.384418
691	\N	Saat melihat sosokmu menghilang di balik gelapnya lorong itu, aku merasa sangat menyesal karena tidak bisa berbuat apa pun. Aku menyadari bahwa diriku ini memang masih lemah, tapi aku takkan membiarkanmu bersedih lagi, Eri!Aku akan menjadi pahlawan bagimu!"Plus Ultra"!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1618578820i/57754853.jpg	\N	\N	2026-05-31 16:41:20.581525	2026-05-31 16:41:20.581525
692	\N	Midoriya berhasil mengerahkan 100% kekuatannya dengan meminjam kekuatan Quirk "Memutar Kembali" milik Eri Hero itu pasti adalah sosok yang hadir untuk bertarung demi melindungi suatu hal dan juga orang-orang! Di hati ini senantiasa terpatri.."Plus Ultra"!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1624630494i/58422820.jpg	\N	\N	2026-05-31 16:42:03.1965	2026-05-31 16:42:03.1965
693	\N	Kehidupan di sekolah takkan berkesan kalau tidak ada festival budaya! Belakangan ini kasus-kasus Villain datang silih berganti dan bikin stres, jadi ayo kita hibur teman-teman kita di jurusan lain dengan pertunjukan band! Sejujurnya kami khawatir apa kami bisa meramaikan festival budaya, tapi percaya diri dan hajar saja semuanya dengan ROCK!!PLUS ULTRA!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1647032832i/60593496.jpg	\N	\N	2026-05-31 16:42:26.850323	2026-05-31 16:42:26.850323
694	\N	Meskipun banyak yang senang dengan festival budaya, sebuah pesta impian setahun sekali yang digelar siswa untuk siswa. Ternyata ada yang menyimpan kegelapan di dalam hatinya berencana mengacaukan acara besar ini! Menjadi hero bukan hanya menolong di saat kesulitan, tapi juga membuat semua orang tersenyum! “Plus Ultra”!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1653088959i/61137037.jpg	\N	\N	2026-05-31 16:43:06.627456	2026-05-31 16:43:06.627456
695	\N	GAWAT!!Nomu lagi-lagi mengacau di kota!! Ayah Todoroki, Endeavor, kini sedang berjuang mati-matian melawan nomu yang sulit dikalahkan. Keadaannya sempat membuat Todoroki khawatir. Tapi Endeavor pasti akan baik-baik saja!!Sebab Endeavor adalah Hero Nomor 1!! Ayo kita percaya padanya dan terus dukung dia hingga akhir!!“Plus Ultra”!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1659140197i/61778567.jpg	\N	\N	2026-05-31 16:43:25.479346	2026-05-31 16:43:25.479346
696	\N	Latihan tarung gabungan kelas A versus kelas B sudah dimulai!! Waah, kelas B memang hebat!! Kemampuan Quirk mereka berkembang pesat, ditambah lagi mereka punya jurus-jurus andalan baru!! Kami juga tidak boleh lengah dan harus memikirkan strategi dengan hati-hati… Eeh?! Bakugo!! Tunggu!! Jangan gegabah!! “Plus Ultra”!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1664540909i/62829783.jpg	\N	\N	2026-05-31 16:43:43.789064	2026-05-31 16:43:43.789064
697	\N	DETNERAT.Apa yang disebut kebahagiaan? Apa yang disebut ketidakbahagiaan? Apa yang disebut kebebasan? Apa yang disebut ketidakbebasan? Kami ingin memikirkan semua jawaban itu bersama "Mu". Semoga hari esok lebih bahagia dari hari ini. Semoga hari esok lebih bebas dari hari ini. KEREN!! Keren sekali!! Jurus baru Midoriya sangat keren!! Tapi, setelah asap hitam itu keluar, kenapa kondisinya jadi aneh!? Waaahh!! Sekaramg semuanya sudah berkumpul!! Latihan pertempuran semakin menjadi sengit dengan berbagai Quirk yang digunakan di sana!! Inilah bagian terakhir latihan pertempuran gabungan dengan kelas B!! Siapakah yang akan keluar sebagai pemenangnya!? "PLUS ULTRA"!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1672989281i/75608227.jpg	\N	\N	2026-05-31 16:44:02.334776	2026-05-31 16:44:02.334776
698	\N	Tunggulah Giran!! Aku akan menyelamatkanmu! (Dia sudah mati) Diam kau!! Hanya di sinilah... Hanya bersama aliansi villain nilah aku menemukan tempatku bernaung! (Akulah aku yang as;i). Bukan!! Kau Salah!! Bersiaplah. Meta Liberation Army!! "PLUS ULTRA"!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1684191766i/156426250.jpg	\N	\N	2026-05-31 16:44:20.33116	2026-05-31 16:44:20.33116
699	\N	Rasa sakit yang membuat kepalaku seolah akan pecah, hilang begitu saja… Aah… aku ingat sekarang… Kepuasan yang kurasakan pertama kalinya waktu kecil dulu. Ingatan tentang keluargaku bukanlah tragedi bagiku. Aku tidak memerlukan masyarakat yang penuh dengan manusia super ini. Aku juga tidak memerlukan masa depan…	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1691882313i/196498331.jpg	\N	\N	2026-05-31 16:44:41.5752	2026-05-31 16:44:41.5752
700	\N	Rencana penyerbuan besar-besaran para Hero pun dimulai! Waktu yang begitu panjang, yang kuhabiskan untuk menyusup sampai sekarang, semuanya hanya demi saat ini! Kami harus berhasil membekuk Paranormal Liberation Front!! Aku akan terbang lebih cepat demi bisa menjadi seperti Hero yang kukagumi sejak kecil… Demi semuanya!! Plus Ultra!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1711719864i/210518317.jpg	\N	\N	2026-05-31 16:45:07.807505	2026-05-31 16:45:07.807505
701	\N	Suaraku jelas dan jernih!! YEAAAAAAHHHHH!!! Villain dan Nomu bermunculan!! Ketegangan memuncak!! Demi mengakhiri mimpi buruk ini dan mencegahnya berulang kembali, kami harus meringkus mereka semua di tempat ini!! Jadi, dia tidak boleh dibangunkan!! Shigaraki tidak boleh dibangunkan!! Plus Ultra!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1716371340i/213752147.jpg	\N	\N	2026-05-31 16:45:26.055421	2026-05-31 16:45:26.055421
702	\N	Takehiko Inoue (井上雄彦) is a Japanese manga artist, best known for Slam Dunk and Vagabond.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1776702257i/251261253.jpg	\N	\N	2026-05-31 16:45:53.341128	2026-05-31 16:45:53.341128
703	\N	Indonesian translation of selected Camus' writings. Translated by Edhi Martono, edited by A. Sonny Keraf, and preface by Goenawan Mohamad. This book has been published with the assistance of European Cultural Foundation, Amsterdam, and UNESCO, Paris.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1210893898i/3268162.jpg	\N	\N	2026-05-31 16:50:24.163444	2026-05-31 16:50:24.163444
704	\N	Di Jawa, kematian seolah menggantung di awang-awang: melayang di atas kepalamu; maut itu hadir dalam senyum seorang perempuan, dalam kerling matanya, dalam gemulai gerak rayuannya…”Kisah kembara ke Jawa yang ditulis oleh Honoré de Balzac ini bisa jadi merupakan contoh unik tentang orientalisme Eropa sebelum abad kesembilan belas. Gambarannya tentang perempuan oriental yang jauh dan asing, penuh dengan sensasi seksual serta obyek petualangan. Demikian pula gambarannya tentang adat istiadat serta kepercayaan setempat, yang berlepotan antara imajinasi dan prasangka. Jika kenyataannya sang penulis tak pernah sekali pun dalam hidupnya menginjakkan kaki ke tanah Jawa, itu justru memberi cerita yang terbit pertama kali tahun 1832 ini daya pikat untuk terus ditelaah, khususnya mengenai bagaimana hubungan Barat dan Timur dengan beragam masalahnya.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1613916154i/57146583.jpg	\N	\N	2026-06-04 18:17:44.115373	2026-06-04 18:17:44.115373
705	\N	Buku ini dicap sebagai “bacaan berbahaya” sejak per­tama kali terbit dalam bahasa Swedia 30 tahun lalu. Tetapi sebagai karya, daya tariknya bukan hanya pada bagaimana kekuasaan Orba begitu takut pada buku ini, melainkan cara Törnquist menempatkan pokok pembahasan atas Peristiwa G30S 1965. Törnquist mengupas persoalan yang hampir tidak pernah dicermati sungguh-sungguh di dalam karya-karya para peneliti maupun pelaku peristiwa G30S 1965. Apakah penyebab kegagalan PKI? Apakah keterlibatan pemimpin PKI dalam G30S cuma sial dan keliru langkah seorang Aidit atau itulah pilihan jalan PKI untuk menyingkirkan “strategi borjuis” seraya menggenjot partai memobilisasi petani? Sejauh mana Aidit mengkhianati partai dan terlibat petualangan rahasia serta elitis? Apakah PKI terlalu doktriner sehingga salah membaca kondisi sehingga mudah dihancurkan dan sejauh ini gagal bangkit kembali?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1319645392i/12962696.jpg	\N	\N	2026-06-04 18:18:05.193904	2026-06-04 18:18:05.193904
707	\N	Taiju, seorang siswa sekolah menengah, terlibat dalam fenomena misterius di mana semua manusia di dunia berubah menjadi batu dalam sekejap.Ribuan tahun kemudian, Taiju yang terbangun dan temannya Senku, memutuskan untuk menciptakan peradaban mulai dari awal!! Kisah petualangan survival sci-fi yang belum pernah ada sebelumnya, dimulai!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1658441538i/61646423.jpg	\N	\N	2026-06-27 19:53:58.021938	2026-06-27 19:53:58.021938
708	\N	Kunci kelahiran monster ini pasti ada di ingatanku!Nina tetap tinggal di Praha, berharap pengalaman dapat membantunya mengingat apa yang terjadi di masa kecilnya. Akhirnya, Nina mengingat kembali semuanya. Apa yang terjadi pada Nina dan Johan saat mereka masih kecil? Apa yang terjadi di Red Rose Mansion?Johan tidak pernah mendengarkan siapa pun, tidak pernah memberi apa pun kepada siapa pun. Keinginan siapa pun tidak pernah menarik baginya. Apa tujuan akhir yang mungkin dia miliki, dan apa yang membuatnya menjadi monster seperti itu? Seiring terungkapnya misteri ini dengan perlahan-lahan, apa yang akan terjadi selanjutnya?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1775197028i/250574011.jpg	\N	\N	2026-06-28 15:25:01.188733	2026-06-28 15:25:01.188733
709	\N	Senku, Taiju, dan Yuzuriha melanjutkan pembuatan mesiu. Di saat itu, tiba-tiba saja ada asap membubung dari kejauhan. Senku merasa yakin ada manusia lain, dan menyalakan sinyal asap dengan mengetahui risikonya. Sementara itu, Tsukasa yang mengejar Senku untuk menghentikan pembuatan mesiu semakin dekat, dan mereka pun berada dalam situasi genting tanpa jalan keluar!?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1666304742i/63050026.jpg	\N	\N	2026-06-28 15:27:37.894894	2026-06-28 15:27:37.894894
710	\N	Senku yang datang ke desa Kohaku, berencana untuk menjadikan penduduk desa sebagai kawannya. Sebagai langkah pertama, Senku mengalahkan seorang pemuda dalam duel sains dan menjadikannya sebagai asisten. Kemudian, dia mulai mengembangkan obat mujarab untuk menyembuhkan penyakit kakak perempuan Kohaku. Tantangan untuk membangun kerajaan sains pun dimulai!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1671867878i/75262654.jpg	\N	\N	2026-06-28 15:28:44.675235	2026-06-28 15:28:44.675235
711	\N	Demi membuat sulfa, obat mujarab, Senku dkk. terus maju menapaki peta jalan sains. Bahkan di antaranya dia harus pergi ke area super berbahaya dengan tekad siap mati untuk mengambil material tersulit, asam sulfat! Sementara itu, di desa, turnamen bela diri yang mempertaruhkan kursi kepala desa, “Duel Agung”, semakin dekat!?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1679637790i/123726049.jpg	\N	\N	2026-06-28 15:28:59.961801	2026-06-28 15:28:59.961801
712	\N	“Duel Agung” dimulai! Ronde pertama tim kerajaan sains yang dipimpin oleh Senku adalah Kinro melawan Magma. Kinro yang rabun jauh kesulitan dalam mengambil jarak, tapi begitu mengenakan “mata sains” dia langsung menekan Magma!? Senku dkk. pun mengincar juara dengan kekuatan sains!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1694069370i/198687396.jpg	\N	\N	2026-06-28 15:29:15.082814	2026-06-28 15:29:15.082814
713	\N	Byakuya, ayah Senku, pulang kembali ke bumi setelah umat manusia membatu. Apakah yang yang ditinggalkannya untuk sang putra dengan melampaui waktu ribuan tahun? Sementara itu, Senku dkk. menerima serangan pembunuh dari kekaisaran Tsukasa. Di tengah keadaan darurat, mereka mulai mengembangkan “pedang sains”, senjata terkuat untuk melindungi desa!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1700466792i/202427792.jpg	\N	\N	2026-06-28 15:29:29.811513	2026-06-28 15:29:29.811513
714	\N	Senku, Chrome, dan Magma yang berusaha untuk mendapatkan material mineral langka, berangkat untuk menjelajah gua. Dapatkah mereka mengatasi dungeon alami yang telah menanti mereka dan sampai ke tempat harta karun!? Lalu, pembuatan senjata terkuat zaman modern, ponsel, akhirnya memasuki bagian klimaks!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1702908521i/203988660.jpg	\N	\N	2026-06-28 15:29:45.834198	2026-06-28 15:29:45.834198
715	\N	Berkat Chrome dkk. yang menyusup ke Kekaisaran Tsukasa, ponsel mulai beroperasi di belakang layar dalam kekaisaran! Siapakah lawan bicara telepon pertamanya!? Sementara itu, kerajaan sains, Senku dkk. yang mencoba mengembangkan mobil, membuat mesin uap dalam prosesnya, dan menimbulkan revolusi industri di Stone World!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1719468522i/215519203.jpg	\N	\N	2026-06-28 15:29:58.526696	2026-06-28 15:29:58.526696
716	\N	Pertempuran antara Kerajaan Sains dan Kekaisaran Tsukasa memasuki duel penentuan terakhir! Senku dkk. bersatu menghadapi perang merebut gua ajaib. Alur pertempuran dipertaruhkan dalam serangan mendadak yang cuma 20 detik!? Sains dan kekuatan, manakah yang akan menuntun umat manusia? Hitung mundur takdir dimulai!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1724386375i/217999730.jpg	\N	\N	2026-06-28 15:30:11.160392	2026-06-28 15:30:11.160392
731	\N	Pasukan pemberontak dan tentara kerajaan diadu domba oleh Baroque Works. Pertempuran sudah di depan mata. Untuk menghentikan aksi pemberontakan, Luffy dan kawan-kawan pergi ke Rainbase, tempat Crocodile berada. Namun, mereka jatuh ke dalam perangkap dan ditangkap!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1252215914i/6811427.jpg	\N	\N	2026-06-28 15:40:04.253066	2026-06-28 15:40:04.253066
717	\N	Karena pengkhianatan Hyoga, Senku dan Tsukasa memutuskan untuk bertarung bersama! Mereka pun menghadapi Hyoga dengan tandem ajaib!! Sementara itu, Senku dkk. berencana bertolak menuju dunia untuk mencari tahu misteri fenomena pembatuan. Untuk mengarungi samudera yang luas butuh kapal dan kapten!? Waktunya memasuki zaman penjelajahan!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1728172937i/220150454.jpg	\N	\N	2026-06-28 15:30:25.194207	2026-06-28 15:30:25.194207
718	\N	Senku dkk. mendapatkan peta harta karun bahan mentah berkat pencarian dengan balon udara, tapi mereka menghadapi masalah bahan makanan karena peningkatan penduduk desa. Mereka pun merencanakan revolusi bahan pangan dengan “membuat roti yang enak dan tahan lama”! Sementara itu, Senku yang pergi ke laut dengan kapal kecil untuk percobaan, mendapatkan perjumpaan yang mengejutkan!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1734675379i/222806038.jpg	\N	\N	2026-06-28 15:30:38.498637	2026-06-28 15:30:38.498637
719	\N	Kapal sains yang dibuat dengan menyatukan seluruh kekuatan Kerajaan Sains, di bawah kepemimpinan Senku dan Ryusui, akhirnya selesai!! Demi mendekati rahasia pembatuan dan menyelamatkan umat manusia, Senku pergi berlayar dengan tujuan dunia bersama anggota terpilih. Tujuan pertama mereka adalah, “Pulau Harta” tempat tertidurnya benda dewa!?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1745117193i/231645501.jpg	\N	\N	2026-06-28 15:32:05.033131	2026-06-28 15:32:05.033131
720	\N	Senku dkk. mengincar untuk mendapatkan senjata pembatuan yang dimiliki ketua, dengan membuat Kohaku menyusup ke harem di pulau. Mereka pun mulai bergerak untuk merebut kembali lab di kapal dengan maksud untuk merombak besar-besaran Kohaku menjadi anak perempuan yang populer dengan sains. Sementara para orang kuat di pulau sedang mengawasi kapal, kartu truf kesuksesan untuk merebut kembali ada di dalam kapal!?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1745560569i/231950360.jpg	\N	\N	2026-06-28 15:32:22.191157	2026-06-28 15:32:22.191157
721	\N	Tak selamanya kita membandingkan satu hal dengan hal lain untuk berkompetisi. Tak selamanya melihat merekamereka yang menjadi juara untuk mematok standar baru tentang apa yang berhasil. Sesekali kita perlu benar menoleh ke sisi lain, ke mereka yang tertatih-tatih, yang terjatuh, bahkan yang tak bisa berlari. Dunia semestinya tak melulu soal menjadi lebih baik setiap hari, tapi juga memastikan tak ada yang ditinggalkan.– Ada Rumput Tetangga Yang Lebih Kering MeranggasSebagai seorang pembaca, dengan mudah saya juga akan membela banyak jenis novel sebagai karya sastra. Tak hanya novel romansa, tapi juga cerita silat, novel horor, atau cerita detektif. Seperti film-film Marvel, novel-novel itu juga tak hanya bisa dinikmati sebagai sensasi hiburan semata, tapi juga bisa menjadi pintu diskusi intelektual– Bukan Sinema, Bukan Sastra, Juga Bukan Kopi***Satu hal yang bisa menerangkan apa isi buku ini, ia merupakan kumpulan sebagian besar esai-esai yang pernah ditulis Eka Kurniawan untuk Jawa Pos. Diawali beberapa tahun lalu ketika ia sesekali mengirimkan esai untuk ikut berkomentar mengenai perkara hangat. Tak banyak, mungkin satu atau dua esai dalam setahun.Bicara tentang sastra dan kebudayaan barangkali hal paling awal dan sering dilakukan. Tapi, diam-diam ia sering juga berpikir untuk menulis hal-ihwal lainnya. Politik, dinamika sosial, dan sedikit perbincangan mengenai etika atau sesat pikir dalam ranah filosofis, misalnya.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1721807450i/199223222.jpg	\N	\N	2026-06-28 15:33:22.91582	2026-06-28 15:33:22.91582
722	\N	Lapar adalah salah satu karya terbesar dari pengarang peraih Hadiah Nobel Kesusastraan tahun 1920, Knut Hamsun, seorang novelis Norwegia yang terkenal. Karyanya telah terjual dari dua juta eksemplar.Tokoh “Aku” adalah seorang penulis dalam Lapar, yang menggambarkan bagaimana seseorang bertekad mempertahankan nilai hidup yang diyakininya, meskipun ditempa oleh pahit getirnya kehidupan yang dialaminya. Semangatnya yang tinggi untuk tetap menulis, mengingatkan kita pada “Aku” Chairil Anwar, yang menyepak, menerjang membawa luka, dan bisa berlari, serta mau hidup seribu tahun lagi.Membaca karya Knut Hamsun, Lapar, akan terkesan dengan gairah semangat hidupnya yang luar biasa, dan pembaca akan menyadari mengapa Hamsun memenangkan Hadiah Nobel Kesusastraan.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1402662939i/18493141.jpg	\N	\N	2026-06-28 15:33:45.306264	2026-06-28 15:33:45.306264
723	\N	New York City, kota yang selalu dipenuhi dengan kasus. Di kota ini ada seorang pembunuh yang disebut “Sister Militia”. Identitas aslinya yang menghabisi target tanpa pernah memperlihatkan sosoknya itu adalah, seorang gadis yang memikul takdir yang tragis. Seraya memanjatkan doa penebusan dosa, dia melepaskan pelurunya.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1741422702i/228904644.jpg	\N	\N	2026-06-28 15:35:09.553024	2026-06-28 15:35:09.553024
724	\N	Agen FBI, Snow, melakukan kontak dengan Arty! Dia mulai menyelidiki kehidupan pribadinya, dan mencari hubungan antara Tista dan “Sister Militia”. Sementara itu, Tista menutup hatinya dan menjalankan misinya sebagai ksatria biara. Namun, organisasi memberikan sebuah perintah yang kejam kepada dirinya.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1741422928i/228904777.jpg	\N	\N	2026-06-28 15:35:49.026504	2026-06-28 15:35:49.026504
725	\N	Luffy marah mendengar pernyataan Arlong bahwa Nami hanyalah sekedar alat untuk memperoleh apa yang diinginkan. Untuk mengembalikan senyuman di wajah Nami, ia menghancurkan Arlong Park dengan satu pukulan	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1255740292i/6811282.jpg	\N	\N	2026-06-28 15:36:43.276665	2026-06-28 15:36:43.276665
726	\N	Legenda baru saja dimulai! Setiap orang memperbaharui sumpahnya. Mereka semua bertekat menuju Grand Line untuk mewujudkan impian masing-masing, Luffy dan teman-temannya harus mendaki gunung!? Dan apa sebenarnya monster hitam besar yang menghadang mereka?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1252213563i/6811320.jpg	\N	\N	2026-06-28 15:37:27.41785	2026-06-28 15:37:27.41785
727	\N	Baroque Works. Tidak lama setelah masuk ke Grand Line, Luffy dan kawan-kawan diincar oleh kelompok jahat rahasia. Lalu, bagaimana nasib Luffy dan teman-teman yang mengetahui nama bos kelompok itu?	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1411727360i/6811332.jpg	\N	\N	2026-06-28 15:38:04.686569	2026-06-28 15:38:04.686569
728	\N	男達の“誇り”を賭けた闘いが、100年も続く巨人島。そこへ、ルフィ達を追って来たB．Wが邪魔をする！　猛るルフィ…。一方、ゾロ達は敵の罠にかかってしまう！？　“ひとつなぎの大秘宝（ワンピース）”を巡る海洋冒険ロマン！！	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1411727629i/6811343.jpg	\N	\N	2026-06-28 15:39:14.058013	2026-06-28 15:39:14.058013
729	\N	Percayalah pada kami! Terus maju! Dengan mempercayai kata-kata Dorey dan Burogy, Luffy dan teman-temannya berlayar menuju pulau selanjutnya. Namun, Nami jatuh sakit. Akhirnya kapal berubah arah, mencari dokter...!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1411728119i/6811352.jpg	\N	\N	2026-06-28 15:39:30.808535	2026-06-28 15:39:30.808535
730	\N	Luffy dan kawan-kawannya berniat mencoba berteman dengan Tony Tony Chopper si Hidung Biru. Akan tetapi, peristiwa masa lalu yang sangat menyedihkan meninggalkan luka besar di hati Chopper...	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1252214747i/6811354.jpg	\N	\N	2026-06-28 15:39:47.629274	2026-06-28 15:39:47.629274
732	\N	Ibukota Alubarna bergolak! Situasi semakin memburuk, karena msing-masing pihak mengabaikan apa yang ada di dalam hati mereka. Untuk menghentikan pemberontakan ini, Luffy pun harus melawan Mr. 0, dalang di balik semua ini, seorang diri!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1252216138i/6811431.jpg	\N	\N	2026-06-28 15:40:27.693733	2026-06-28 15:40:27.693733
733	\N	Crocodile muncul sebelum Vivi tiba di istana. Dari mulutnya terungkap alasan sebenarnya di balik pemberontakan ini!! Di lain pihak, pertarungan Luffy dan kawan-kawan melawan anggota Baroque works yang memiliki kekuatan dahsyat masih terus berlanjut!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1252217888i/6811461.jpg	\N	\N	2026-06-28 15:40:46.02033	2026-06-28 15:40:46.02033
734	\N	クロコダイルとの死闘により、傷付き、ボロボロになったルフィ。だが、仲間との強き絆が、ルフィの身体を突き動かし、激動続くアラバスタに、終止符を打つ!!　“ひとつなぎの大秘宝（ワンピース）”を巡る海洋冒険ロマン!!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1252218318i/6811478.jpg	\N	\N	2026-06-28 15:41:23.827189	2026-06-28 15:41:23.827189
735	\N	"DO YOU THINK THIS WORLD HAS A FUTURE?" Thanks to Eren's timely arrival, the 104th has managed to turn the tide at Wall Rose. But this momentary victory forces two more traitors into a corner – and the identity of the Titans who have been destroying the walls is revealed! What can Eren do against the two most dangerous monsters humanity has ever faced? And who else might be an enemy in disguise?  Chapters list :43. The Armored Titan44. Strike, Throw, Submit45. The Hunters46. Opening	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1382069286i/18077957.jpg	\N	\N	2026-06-28 15:44:08.294186	2026-06-28 15:44:08.294186
736	\N	TURNING ON THEIR OWN!The Survey Corps sets a cunning trap to capture the mysterious Abnormal Titan that broke through their ranks. As Arwin tries to determine the grotesque creature's identity and purpose, scouts report Titans closing in on all sides! But they don't seem to be after the humans - instead they're targeting the Titan!	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1363837004i/17568815.jpg	\N	\N	2026-06-28 15:45:28.120904	2026-06-28 15:45:28.120904
737	\N	HUMANITY'S WORST NIGHTMARE Eren is still resting from his brutal fight with the female Titan, when word reaches the interior that the impossible has happened: Wall Rose itself has been breached, and Titans are pouring through the gap! The emergency casts new urgency over Armin and Hange's questions about how the walls were built, and what humanity can do to restore them...	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1448406398i/18077955.jpg	\N	\N	2026-06-28 15:46:27.708312	2026-06-28 15:46:27.708312
738	\N	Budi Darma selalu berurusan dengan jungkir balik kehidupan. Rafilus adalah radikalisasi urusan tersebut. Seluruh tokoh dalam Rafilus adalah manusia yang terkondisi oleh kesadaran akan keterbatasannya.Dalam Rafilus, Budi Darma terus mengikuti perjalanan imajinasinya dengan cermat. Tema, penokohan, dan cara penyajian yang merupakan ciri khas Budi Darma terangkat dengan sendirinya. Tidak pelak lagi Rafilus menyajikan keunikan tersendiri.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1306683356i/1422434.jpg	\N	\N	2026-06-28 15:47:27.47754	2026-06-28 15:47:27.47754
739	\N	«Fue el 15 de abril». El sonido de las sirenas antiaéreas irrumpe en la extraña cotidianidad de Izawa; en cuestión de minutos, los aviones americanos convierten su barrio de Tokio en un mar incendiado.El sentido de la vida y del arte; el sueldo de doscientos yenes para comprar tabaco, arroz y sopa de miso; la delgada línea que separa al entendimiento de la locura y a la angustia de los hombres del silencio estático de los niños; el afecto por una mujer reducida a los instintos de la carne, todo queda suspendido como las bombas en el aire antes de caer. Es posible escribir después de la guerra, pocos lo hacen como Ango Sakaguchi. Un lúcido relato sobre la deshumanización y el absurdo en tiempos de guerra. La voluntad de vivir abriéndose paso entre el fuego y la destrucción. La introducción perfecta a una de las voces más agudas de la narrativa japonesa del siglo XX.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1734795180i/222856651.jpg	\N	\N	2026-06-28 15:56:36.043181	2026-06-28 15:56:36.043181
740	\N	"In the Cherry Wood of Full Bloom" is a haunting and surreal short story by Ango Sakaguchi, one of Japan's most provocative post-war writers. Set in medieval Japan, this tale blends elements of folklore, horror, and psychological drama to create a uniquely unsettling narrative.The story follows a mountain bandit who becomes enthralled by a beautiful woman from the capital. As their relationship unfolds beneath the blooming cherry blossoms, readers are drawn into a world where beauty and violence, love and madness intertwine in unexpected ways.Sakaguchi's vivid prose and masterful storytelling challenge conventional morality and explore the darker aspects of human nature. Through its exploration of desire, power, and the thin line between civilization and savagery, "Under the Blossoming Cherry Trees" offers a thought-provoking glimpse into the complexities of the human psyche.This gripping tale, which has become a classic of modern Japanese literature, invites readers to question their perceptions of beauty, love, and the human condition. Its haunting imagery and philosophical underpinnings make it a must-read for those interested in Japanese literature or anyone seeking a story that will linger in their thoughts long after the last page is turned.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1724634729i/218072939.jpg	\N	\N	2026-06-28 15:59:23.740248	2026-06-28 15:59:23.740248
741	\N	昭和初期に活躍した「無頼派」の代表的作家である坂口安吾の小説。初出は「青い馬」［1931（昭和6）年］。「山岳」と「都会の雑踏」、対照的的な2つの場所に魅了される矢車凡太。ある日雑踏の中で、黒谷村の若い住職で学生時代の友人・蜂谷龍然を思い出し、村を訪ねることを決めた。仏教と肉体、求道精神と現実という対立を描いた作品。	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1386395559i/19253586.jpg	\N	\N	2026-06-28 16:01:12.79507	2026-06-28 16:01:12.79507
742	\N	戦後文学の代表作家としらしめた『白痴』ほか、 太宰と人気を二分した無頼派・坂口安吾の主要7編を収録。 白痴の女と火炎の中をのがれ、「生きるための、明日の希望がないから」女を捨てていくはりあいもなく、ただ今朝も太陽の光がそそぐだろうかと考える。戦後の混乱と頽廃の世相にさまよう人々の心に強く訴えかけた表題作など、自嘲的なアウトローの生活をくりひろげながら、「堕落論」の主張を作品化し、観念的私小説を創造してデカダン派と称される著者の代表作7編を収める。 目次 いずこへ白痴母の上京外套と青空私は海をだきしめていたい戦争と一人の女青鬼の褌を洗う女解説 福田恆存※電子書籍版には解説は収録しておりません。 本書収録「白痴」より その家には人間と豚と犬と鶏と家鴨(あひる)が住んでいたが、まったく、住む建物も各々(おのおの)の食物も殆ど変っていやしない。物置のようなひん曲った建物があって、階下には主人夫婦、天井裏には母と娘が間借りしていて、この娘は相手の分らぬ子供を孕んでいる。 伊沢の借りている一室は母屋(おもや)から分離した小屋で、ここは昔この家の肺病の息子がね	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1677811855i/26064658.jpg	\N	\N	2026-06-28 16:06:37.386224	2026-06-28 16:06:37.386224
743	\N	このコンテンツは日本国内ではパブリックドメインの作品です。印刷版からデジタル版への変換はボランティアによって行われたものです。	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1385551642i/18999538.jpg	\N	\N	2026-06-28 16:08:05.102761	2026-06-28 16:08:05.102761
744	\N	Sakaguchi Ango's "Discourse on Decadence" (Daraku-ron) is a provocative and influential essay that challenges conventional morality and offers a radical perspective on post-war Japanese society. Written in 1946, this seminal work explores the liberating potential of "decadence" and argues for embracing human desires and imperfections as a path to authentic living. With its bold ideas and captivating prose, Ango's essay continues to intrigue readers and spark debates about individuality, social norms, and the nature of human existence in times of upheaval.Sakaguchi Ango's "Discourse on Decadence" (Daraku-ron) was published in April 1946, immediately after World War II, against the backdrop of chaos and the collapse of values in Japanese society.At this time, Japan was The breakdown of social order following defeat in the war.A significant shaking of previously held moral and ethical values.A forced, rapid shift from wartime ideologies.Faced with this turbulent era, Ango deeply contemplated the essence of human nature. He observed the dramatically changed social conditions before and after the war, exploring the concept of inherent "decadence" in human nature.The core of Ango's argument lies in the following The insight that humans inherently possess a nature of "decadence."The idea that people don't become decadent because they lost the war, but that decadence is an essential part of human nature.The recognition that humans are contradictory beings who can never fully succumb to decadence."Discourse on Decadence" provided a new perspective for post-war Japanese people, prompting a fundamental reconsideration of conventional morals and values. Through this work, Ango encouraged readers to confront the essential nature of humanity and explore new ways of living in a new era.	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	https://dryofg8nmyqjw.cloudfront.net/images/no-cover.png	\N	\N	2026-06-28 16:10:51.637883	2026-06-28 16:10:51.637883
\.


--
-- Data for Name: monthly_stats; Type: TABLE DATA; Schema: public; Owner: default
--

COPY public.monthly_stats (month_id, year, month, books_read, pages_read, average_rating, created_at, updated_at) FROM stdin;
174	2025	4	11	2867	4.09	2025-12-27 07:08:41.24519	2025-12-27 07:08:44.390168
1	2024	11	65	0	\N	2025-12-27 07:07:56.594704	2025-12-27 07:09:53.332738
322	2025	9	42	5069	3.90	2025-12-27 07:09:20.827773	2025-12-27 07:09:31.528436
435	2025	12	11	1805	4.00	2025-12-27 07:09:50.626118	2025-12-28 11:18:30.463906
639	2026	6	26	5457	3.92	2026-06-01 03:03:59.450643	2026-06-28 16:14:30.571098
90	2025	1	28	5520	3.93	2025-12-27 07:08:19.324701	2025-12-27 07:08:26.371188
589	2026	4	33	8721	4.03	2026-04-01 07:14:42.819055	2026-04-25 13:12:57.867835
185	2025	5	29	7154	4.31	2025-12-27 07:08:44.643769	2025-12-27 07:08:52.298327
118	2025	2	15	3673	3.87	2025-12-27 07:08:26.622454	2025-12-27 07:08:30.210727
447	2026	1	28	5501	3.86	2026-01-02 19:03:30.747076	2026-01-31 19:44:30.184829
622	2026	5	17	4967	4.06	2026-05-03 12:16:49.737328	2026-05-31 16:30:28.151348
364	2025	10	38	4904	4.11	2025-12-27 07:09:31.784927	2025-12-27 07:09:41.370327
214	2025	6	19	3823	3.89	2025-12-27 07:08:52.562603	2025-12-27 07:08:57.207205
541	2026	3	48	13165	4.08	2026-03-01 11:57:16.304586	2026-03-28 18:20:35.773918
260	2025	8	62	3080	3.26	2025-12-27 07:09:04.667961	2025-12-27 07:09:20.525958
475	2026	2	61	10275	3.79	2026-02-01 01:56:40.478646	2026-02-28 15:13:58.633395
133	2025	3	41	12658	4.27	2025-12-27 07:08:30.461464	2025-12-27 07:08:40.990874
233	2025	7	27	1983	3.74	2025-12-27 07:08:57.460489	2025-12-27 07:09:04.369333
66	2024	12	24	0	5.00	2025-12-27 07:08:13.140333	2025-12-27 07:08:19.071554
402	2025	11	33	7489	4.06	2025-12-27 07:09:41.627483	2025-12-27 07:09:50.298319
\.


--
-- Data for Name: reading_goals; Type: TABLE DATA; Schema: public; Owner: default
--

COPY public.reading_goals (goal_id, year, target_books, target_pages, current_books, current_pages, created_at, updated_at) FROM stdin;
1	2025	52	\N	0	0	2025-12-27 06:37:09.335262	2025-12-27 06:37:09.335262
2	2026	100	0	0	0	2026-01-01 08:09:13.992637	2026-01-01 08:09:13.992637
\.


--
-- Data for Name: reading_log; Type: TABLE DATA; Schema: public; Owner: default
--

COPY public.reading_log (log_id, book_id, status, date_added, date_started, date_finished, current_page, rating, review, notes, reading_days, reread, reread_count, tags, created_at, updated_at) FROM stdin;
2	10	finished	2024-11-22	2024-11-22	2024-11-22	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:07:56.888395	2025-12-27 07:07:56.888395
3	11	finished	2024-11-22	2024-11-22	2024-11-22	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:07:57.139961	2025-12-27 07:07:57.139961
4	12	finished	2024-11-22	2024-11-22	2024-11-22	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:07:57.392338	2025-12-27 07:07:57.392338
5	13	finished	2024-11-22	2024-11-22	2024-11-22	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:07:57.677693	2025-12-27 07:07:57.677693
6	14	finished	2024-11-22	2024-11-22	2024-11-22	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:07:57.930106	2025-12-27 07:07:57.930106
7	16	finished	2024-11-22	2024-11-22	2024-11-22	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:07:58.180623	2025-12-27 07:07:58.180623
8	17	finished	2024-11-22	2024-11-22	2024-11-22	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:07:58.429973	2025-12-27 07:07:58.429973
9	21	finished	2024-11-22	2024-11-22	2024-11-22	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:07:58.679069	2025-12-27 07:07:58.679069
10	22	finished	2024-11-22	2024-11-22	2024-11-22	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:07:58.928017	2025-12-27 07:07:58.928017
11	24	finished	2024-11-22	2024-11-22	2024-11-22	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:07:59.177199	2025-12-27 07:07:59.177199
12	25	finished	2024-11-22	2024-11-22	2024-11-22	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:07:59.426829	2025-12-27 07:07:59.426829
13	34	finished	2024-11-22	2024-11-22	2024-11-22	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:07:59.67608	2025-12-27 07:07:59.67608
14	35	finished	2024-11-22	2024-11-22	2024-11-22	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:07:59.930962	2025-12-27 07:07:59.930962
15	37	finished	2024-11-22	2024-11-22	2024-11-22	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:00.180513	2025-12-27 07:08:00.180513
16	50	finished	2024-11-22	2024-11-22	2024-11-22	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:00.430458	2025-12-27 07:08:00.430458
17	51	finished	2024-11-22	2024-11-22	2024-11-22	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:00.679625	2025-12-27 07:08:00.679625
18	72	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:00.931083	2025-12-27 07:08:00.931083
19	77	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:01.180446	2025-12-27 07:08:01.180446
20	83	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:01.439282	2025-12-27 07:08:01.439282
21	84	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:01.693171	2025-12-27 07:08:01.693171
22	85	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:01.942765	2025-12-27 07:08:01.942765
23	92	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:02.19167	2025-12-27 07:08:02.19167
24	93	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:02.441497	2025-12-27 07:08:02.441497
25	94	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:02.704907	2025-12-27 07:08:02.704907
26	97	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:02.957449	2025-12-27 07:08:02.957449
27	98	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:03.208219	2025-12-27 07:08:03.208219
28	99	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:03.457515	2025-12-27 07:08:03.457515
29	100	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:03.707324	2025-12-27 07:08:03.707324
30	107	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:03.958512	2025-12-27 07:08:03.958512
31	108	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:04.211683	2025-12-27 07:08:04.211683
32	111	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:04.462097	2025-12-27 07:08:04.462097
33	114	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:04.712227	2025-12-27 07:08:04.712227
34	115	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:04.965286	2025-12-27 07:08:04.965286
35	118	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:05.217224	2025-12-27 07:08:05.217224
36	130	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:05.484904	2025-12-27 07:08:05.484904
37	159	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:05.737407	2025-12-27 07:08:05.737407
38	169	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:05.990087	2025-12-27 07:08:05.990087
39	171	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:06.241145	2025-12-27 07:08:06.241145
40	185	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:06.49235	2025-12-27 07:08:06.49235
41	192	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:06.744245	2025-12-27 07:08:06.744245
42	193	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:06.996025	2025-12-27 07:08:06.996025
43	194	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:07.251565	2025-12-27 07:08:07.251565
44	199	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:07.502177	2025-12-27 07:08:07.502177
45	200	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:07.755014	2025-12-27 07:08:07.755014
46	201	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:08.010615	2025-12-27 07:08:08.010615
47	224	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:08.260872	2025-12-27 07:08:08.260872
48	225	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:08.512037	2025-12-27 07:08:08.512037
49	226	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:08.763187	2025-12-27 07:08:08.763187
50	227	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:09.044274	2025-12-27 07:08:09.044274
51	233	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:09.307988	2025-12-27 07:08:09.307988
52	234	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:09.561245	2025-12-27 07:08:09.561245
53	235	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:09.811447	2025-12-27 07:08:09.811447
54	236	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:10.061701	2025-12-27 07:08:10.061701
55	237	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:10.312372	2025-12-27 07:08:10.312372
56	238	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:10.563238	2025-12-27 07:08:10.563238
57	239	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:10.81387	2025-12-27 07:08:10.81387
58	241	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:11.092474	2025-12-27 07:08:11.092474
59	242	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:11.343533	2025-12-27 07:08:11.343533
60	243	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:11.603784	2025-12-27 07:08:11.603784
61	244	finished	2024-11-23	2024-11-23	2024-11-23	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:11.854827	2025-12-27 07:08:11.854827
62	4	finished	2024-11-27	2024-11-27	2024-11-27	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:12.10538	2025-12-27 07:08:12.10538
63	102	finished	2024-11-27	2024-11-27	2024-11-27	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:12.356417	2025-12-27 07:08:12.356417
64	105	finished	2024-11-27	2024-11-27	2024-11-27	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:12.628251	2025-12-27 07:08:12.628251
65	246	finished	2024-11-27	2024-11-27	2024-11-27	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:12.879008	2025-12-27 07:08:12.879008
66	5	finished	2024-12-02	2024-12-02	2024-12-02	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:13.140333	2025-12-27 07:08:13.140333
67	29	finished	2024-12-03	2024-12-03	2024-12-03	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:13.393769	2025-12-27 07:08:13.393769
68	96	finished	2024-12-04	2024-12-04	2024-12-04	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:13.653159	2025-12-27 07:08:13.653159
69	91	finished	2024-12-05	2024-12-05	2024-12-05	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:13.905915	2025-12-27 07:08:13.905915
70	198	finished	2024-12-06	2024-12-06	2024-12-06	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:14.16452	2025-12-27 07:08:14.16452
71	168	finished	2024-12-09	2024-12-09	2024-12-09	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:14.47649	2025-12-27 07:08:14.47649
72	55	finished	2024-12-10	2024-12-10	2024-12-10	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:14.741955	2025-12-27 07:08:14.741955
73	202	finished	2024-12-12	2024-12-12	2024-12-12	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:14.994396	2025-12-27 07:08:14.994396
74	79	finished	2024-12-15	2024-12-15	2024-12-15	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:15.245619	2025-12-27 07:08:15.245619
75	174	finished	2024-12-15	2024-12-15	2024-12-15	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:15.497918	2025-12-27 07:08:15.497918
76	172	finished	2024-12-16	2024-12-16	2024-12-16	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:15.75258	2025-12-27 07:08:15.75258
77	247	finished	2024-12-18	2024-12-18	2024-12-18	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:16.011416	2025-12-27 07:08:16.011416
78	173	finished	2024-12-22	2024-12-22	2024-12-22	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:16.266963	2025-12-27 07:08:16.266963
79	197	finished	2024-12-22	2024-12-22	2024-12-22	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:16.520306	2025-12-27 07:08:16.520306
80	195	finished	2024-12-25	2024-12-25	2024-12-25	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:16.775441	2025-12-27 07:08:16.775441
81	41	finished	2024-12-26	2024-12-26	2024-12-26	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:17.027856	2025-12-27 07:08:17.027856
82	149	finished	2024-12-26	2024-12-26	2024-12-26	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:17.283352	2025-12-27 07:08:17.283352
83	249	finished	2024-12-26	2024-12-26	2024-12-26	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:17.540202	2025-12-27 07:08:17.540202
84	26	finished	2024-12-28	2024-12-28	2024-12-28	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:17.793366	2025-12-27 07:08:17.793366
85	59	finished	2024-12-28	2024-12-28	2024-12-28	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:18.045259	2025-12-27 07:08:18.045259
86	66	finished	2024-12-28	2024-12-28	2024-12-28	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:18.307133	2025-12-27 07:08:18.307133
87	143	finished	2024-12-28	2024-12-28	2024-12-28	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:18.567438	2025-12-27 07:08:18.567438
88	148	finished	2024-12-28	2024-12-28	2024-12-28	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:18.819354	2025-12-27 07:08:18.819354
89	150	finished	2024-12-28	2024-12-28	2024-12-28	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:08:19.071554	2025-12-27 07:08:19.071554
90	248	finished	2025-01-04	2025-01-04	2025-01-04	0	3	\N	\N	1	f	0	\N	2025-12-27 07:08:19.324701	2025-12-27 07:08:19.324701
91	2	finished	2025-01-04	2025-01-04	2025-01-04	0	3	\N	\N	1	f	0	\N	2025-12-27 07:08:19.625562	2025-12-27 07:08:19.625562
92	250	finished	2025-01-08	2025-01-08	2025-01-08	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:19.898709	2025-12-27 07:08:19.898709
93	251	finished	2025-01-08	2025-01-08	2025-01-08	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:20.152715	2025-12-27 07:08:20.152715
94	252	finished	2025-01-08	2025-01-08	2025-01-08	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:20.416165	2025-12-27 07:08:20.416165
95	176	finished	2025-01-08	2025-01-08	2025-01-08	0	3	\N	\N	1	f	0	\N	2025-12-27 07:08:20.71768	2025-12-27 07:08:20.71768
96	253	finished	2025-01-08	2025-01-08	2025-01-08	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:21.029056	2025-12-27 07:08:21.029056
97	254	finished	2025-01-08	2025-01-08	2025-01-08	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:21.279358	2025-12-27 07:08:21.279358
98	255	finished	2025-01-08	2025-01-08	2025-01-08	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:21.53722	2025-12-27 07:08:21.53722
99	256	finished	2025-01-09	2025-01-09	2025-01-09	0	3	\N	\N	1	f	0	\N	2025-12-27 07:08:21.790098	2025-12-27 07:08:21.790098
100	257	finished	2025-01-09	2025-01-09	2025-01-09	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:22.051847	2025-12-27 07:08:22.051847
101	258	finished	2025-01-10	2025-01-10	2025-01-10	0	3	\N	\N	1	f	0	\N	2025-12-27 07:08:22.302509	2025-12-27 07:08:22.302509
102	259	finished	2025-01-12	2025-01-12	2025-01-12	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:22.556252	2025-12-27 07:08:22.556252
103	260	finished	2025-01-13	2025-01-13	2025-01-13	0	2	\N	\N	1	f	0	\N	2025-12-27 07:08:22.806964	2025-12-27 07:08:22.806964
104	262	finished	2025-01-15	2025-01-15	2025-01-15	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:23.076244	2025-12-27 07:08:23.076244
105	261	finished	2025-01-15	2025-01-15	2025-01-15	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:23.32987	2025-12-27 07:08:23.32987
106	264	finished	2025-01-19	2025-01-19	2025-01-19	0	3	\N	\N	1	f	0	\N	2025-12-27 07:08:23.582544	2025-12-27 07:08:23.582544
107	263	finished	2025-01-19	2025-01-19	2025-01-19	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:23.835062	2025-12-27 07:08:23.835062
108	265	finished	2025-01-21	2025-01-21	2025-01-21	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:24.086501	2025-12-27 07:08:24.086501
109	266	finished	2025-01-22	2025-01-22	2025-01-22	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:24.343199	2025-12-27 07:08:24.343199
110	267	finished	2025-01-24	2025-01-24	2025-01-24	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:24.594263	2025-12-27 07:08:24.594263
111	36	finished	2025-01-26	2025-01-26	2025-01-26	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:24.851936	2025-12-27 07:08:24.851936
112	268	finished	2025-01-26	2025-01-26	2025-01-26	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:25.103171	2025-12-27 07:08:25.103171
113	269	finished	2025-01-27	2025-01-27	2025-01-27	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:25.356846	2025-12-27 07:08:25.356846
114	270	finished	2025-01-27	2025-01-27	2025-01-27	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:25.608372	2025-12-27 07:08:25.608372
115	271	finished	2025-01-28	2025-01-28	2025-01-28	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:25.865109	2025-12-27 07:08:25.865109
116	272	finished	2025-01-28	2025-01-28	2025-01-28	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:26.117625	2025-12-27 07:08:26.117625
117	273	finished	2025-01-28	2025-01-28	2025-01-28	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:26.371188	2025-12-27 07:08:26.371188
118	275	finished	2025-02-07	2025-02-07	2025-02-07	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:26.622454	2025-12-27 07:08:26.622454
119	277	finished	2025-02-07	2025-02-07	2025-02-07	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:26.877402	2025-12-27 07:08:26.877402
120	274	finished	2025-02-07	2025-02-07	2025-02-07	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:27.128453	2025-12-27 07:08:27.128453
121	278	finished	2025-02-08	2025-02-08	2025-02-08	0	3	\N	\N	1	f	0	\N	2025-12-27 07:08:27.383745	2025-12-27 07:08:27.383745
122	276	finished	2025-02-08	2025-02-08	2025-02-08	0	2	\N	\N	1	f	0	\N	2025-12-27 07:08:27.680881	2025-12-27 07:08:27.680881
123	279	finished	2025-02-08	2025-02-08	2025-02-08	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:27.933027	2025-12-27 07:08:27.933027
124	280	finished	2025-02-10	2025-02-10	2025-02-10	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:28.185797	2025-12-27 07:08:28.185797
125	281	finished	2025-02-12	2025-02-12	2025-02-12	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:28.435781	2025-12-27 07:08:28.435781
126	8	finished	2025-02-12	2025-02-12	2025-02-12	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:28.686801	2025-12-27 07:08:28.686801
127	283	finished	2025-02-16	2025-02-16	2025-02-16	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:28.938247	2025-12-27 07:08:28.938247
128	282	finished	2025-02-16	2025-02-16	2025-02-16	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:29.206817	2025-12-27 07:08:29.206817
129	284	finished	2025-02-18	2025-02-18	2025-02-18	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:29.457654	2025-12-27 07:08:29.457654
130	285	finished	2025-02-20	2025-02-20	2025-02-20	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:29.708509	2025-12-27 07:08:29.708509
131	286	finished	2025-02-22	2025-02-22	2025-02-22	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:29.95983	2025-12-27 07:08:29.95983
132	287	finished	2025-02-23	2025-02-23	2025-02-23	0	3	\N	\N	1	f	0	\N	2025-12-27 07:08:30.210727	2025-12-27 07:08:30.210727
133	288	finished	2025-03-01	2025-03-01	2025-03-01	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:30.461464	2025-12-27 07:08:30.461464
134	289	finished	2025-03-02	2025-03-02	2025-03-02	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:30.713165	2025-12-27 07:08:30.713165
135	292	finished	2025-03-03	2025-03-03	2025-03-03	0	3	\N	\N	1	f	0	\N	2025-12-27 07:08:30.964485	2025-12-27 07:08:30.964485
136	290	finished	2025-03-03	2025-03-03	2025-03-03	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:31.216465	2025-12-27 07:08:31.216465
137	291	finished	2025-03-03	2025-03-03	2025-03-03	0	3	\N	\N	1	f	0	\N	2025-12-27 07:08:31.471485	2025-12-27 07:08:31.471485
138	294	finished	2025-03-08	2025-03-08	2025-03-08	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:31.726351	2025-12-27 07:08:31.726351
139	293	finished	2025-03-08	2025-03-08	2025-03-08	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:31.9783	2025-12-27 07:08:31.9783
140	297	finished	2025-03-12	2025-03-12	2025-03-12	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:32.229505	2025-12-27 07:08:32.229505
141	295	finished	2025-03-12	2025-03-12	2025-03-12	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:32.493537	2025-12-27 07:08:32.493537
142	298	finished	2025-03-12	2025-03-12	2025-03-12	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:32.802378	2025-12-27 07:08:32.802378
143	296	finished	2025-03-12	2025-03-12	2025-03-12	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:33.055379	2025-12-27 07:08:33.055379
144	299	finished	2025-03-12	2025-03-12	2025-03-12	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:33.314365	2025-12-27 07:08:33.314365
145	300	finished	2025-03-13	2025-03-13	2025-03-13	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:33.566073	2025-12-27 07:08:33.566073
146	302	finished	2025-03-15	2025-03-15	2025-03-15	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:33.818929	2025-12-27 07:08:33.818929
147	304	finished	2025-03-15	2025-03-15	2025-03-15	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:34.070596	2025-12-27 07:08:34.070596
148	301	finished	2025-03-15	2025-03-15	2025-03-15	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:34.321945	2025-12-27 07:08:34.321945
149	303	finished	2025-03-15	2025-03-15	2025-03-15	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:34.644331	2025-12-27 07:08:34.644331
150	305	finished	2025-03-15	2025-03-15	2025-03-15	0	3	\N	\N	1	f	0	\N	2025-12-27 07:08:34.897384	2025-12-27 07:08:34.897384
151	306	finished	2025-03-15	2025-03-15	2025-03-15	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:35.148824	2025-12-27 07:08:35.148824
152	307	finished	2025-03-16	2025-03-16	2025-03-16	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:35.399801	2025-12-27 07:08:35.399801
153	308	finished	2025-03-17	2025-03-17	2025-03-17	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:35.651995	2025-12-27 07:08:35.651995
154	309	finished	2025-03-18	2025-03-18	2025-03-18	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:35.903879	2025-12-27 07:08:35.903879
155	311	finished	2025-03-18	2025-03-18	2025-03-18	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:36.155369	2025-12-27 07:08:36.155369
156	310	finished	2025-03-18	2025-03-18	2025-03-18	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:36.407721	2025-12-27 07:08:36.407721
157	312	finished	2025-03-18	2025-03-18	2025-03-18	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:36.660087	2025-12-27 07:08:36.660087
158	314	finished	2025-03-19	2025-03-19	2025-03-19	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:36.911987	2025-12-27 07:08:36.911987
159	313	finished	2025-03-19	2025-03-19	2025-03-19	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:37.164599	2025-12-27 07:08:37.164599
160	317	finished	2025-03-20	2025-03-20	2025-03-20	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:37.511248	2025-12-27 07:08:37.511248
161	318	finished	2025-03-20	2025-03-20	2025-03-20	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:37.762569	2025-12-27 07:08:37.762569
162	316	finished	2025-03-20	2025-03-20	2025-03-20	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:38.017932	2025-12-27 07:08:38.017932
163	315	finished	2025-03-20	2025-03-20	2025-03-20	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:38.271437	2025-12-27 07:08:38.271437
164	319	finished	2025-03-22	2025-03-22	2025-03-22	0	3	\N	\N	1	f	0	\N	2025-12-27 07:08:38.535582	2025-12-27 07:08:38.535582
165	7	finished	2025-03-23	2025-03-23	2025-03-23	0	3	\N	\N	1	f	0	\N	2025-12-27 07:08:38.844438	2025-12-27 07:08:38.844438
166	320	finished	2025-03-23	2025-03-23	2025-03-23	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:39.150054	2025-12-27 07:08:39.150054
167	321	finished	2025-03-26	2025-03-26	2025-03-26	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:39.402795	2025-12-27 07:08:39.402795
168	322	finished	2025-03-26	2025-03-26	2025-03-26	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:39.655832	2025-12-27 07:08:39.655832
169	323	finished	2025-03-27	2025-03-27	2025-03-27	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:39.970832	2025-12-27 07:08:39.970832
170	324	finished	2025-03-27	2025-03-27	2025-03-27	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:40.222854	2025-12-27 07:08:40.222854
171	325	finished	2025-03-29	2025-03-29	2025-03-29	0	3	\N	\N	1	f	0	\N	2025-12-27 07:08:40.482915	2025-12-27 07:08:40.482915
172	326	finished	2025-03-29	2025-03-29	2025-03-29	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:40.734781	2025-12-27 07:08:40.734781
173	327	finished	2025-03-30	2025-03-30	2025-03-30	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:40.990874	2025-12-27 07:08:40.990874
174	328	finished	2025-04-02	2025-04-02	2025-04-02	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:41.24519	2025-12-27 07:08:41.24519
175	329	finished	2025-04-03	2025-04-03	2025-04-03	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:41.50513	2025-12-27 07:08:41.50513
176	330	finished	2025-04-04	2025-04-04	2025-04-04	0	3	\N	\N	1	f	0	\N	2025-12-27 07:08:41.757232	2025-12-27 07:08:41.757232
177	331	finished	2025-04-09	2025-04-09	2025-04-09	0	3	\N	\N	1	f	0	\N	2025-12-27 07:08:42.009274	2025-12-27 07:08:42.009274
178	332	finished	2025-04-12	2025-04-12	2025-04-12	0	3	\N	\N	1	f	0	\N	2025-12-27 07:08:42.262959	2025-12-27 07:08:42.262959
179	333	finished	2025-04-12	2025-04-12	2025-04-12	0	3	\N	\N	1	f	0	\N	2025-12-27 07:08:42.514394	2025-12-27 07:08:42.514394
180	334	finished	2025-04-17	2025-04-17	2025-04-17	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:42.768163	2025-12-27 07:08:42.768163
181	335	finished	2025-04-21	2025-04-21	2025-04-21	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:43.03329	2025-12-27 07:08:43.03329
182	336	finished	2025-04-21	2025-04-21	2025-04-21	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:43.287639	2025-12-27 07:08:43.287639
183	337	finished	2025-04-27	2025-04-27	2025-04-27	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:43.589194	2025-12-27 07:08:43.589194
184	338	finished	2025-04-27	2025-04-27	2025-04-27	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:44.390168	2025-12-27 07:08:44.390168
185	340	finished	2025-05-02	2025-05-02	2025-05-02	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:44.643769	2025-12-27 07:08:44.643769
186	341	finished	2025-05-02	2025-05-02	2025-05-02	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:44.895426	2025-12-27 07:08:44.895426
187	342	finished	2025-05-02	2025-05-02	2025-05-02	0	3	\N	\N	1	f	0	\N	2025-12-27 07:08:45.203231	2025-12-27 07:08:45.203231
188	344	finished	2025-05-03	2025-05-03	2025-05-03	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:45.500835	2025-12-27 07:08:45.500835
189	343	finished	2025-05-03	2025-05-03	2025-05-03	0	3	\N	\N	1	f	0	\N	2025-12-27 07:08:45.766408	2025-12-27 07:08:45.766408
190	345	finished	2025-05-05	2025-05-05	2025-05-05	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:46.121654	2025-12-27 07:08:46.121654
191	346	finished	2025-05-08	2025-05-08	2025-05-08	0	3	\N	\N	1	f	0	\N	2025-12-27 07:08:46.386265	2025-12-27 07:08:46.386265
192	347	finished	2025-05-09	2025-05-09	2025-05-09	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:46.652108	2025-12-27 07:08:46.652108
193	348	finished	2025-05-13	2025-05-13	2025-05-13	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:46.904564	2025-12-27 07:08:46.904564
194	350	finished	2025-05-13	2025-05-13	2025-05-13	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:47.15694	2025-12-27 07:08:47.15694
195	349	finished	2025-05-13	2025-05-13	2025-05-13	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:47.40927	2025-12-27 07:08:47.40927
196	352	finished	2025-05-15	2025-05-15	2025-05-15	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:47.661602	2025-12-27 07:08:47.661602
197	351	finished	2025-05-15	2025-05-15	2025-05-15	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:47.914476	2025-12-27 07:08:47.914476
198	353	finished	2025-05-16	2025-05-16	2025-05-16	0	3	\N	\N	1	f	0	\N	2025-12-27 07:08:48.167122	2025-12-27 07:08:48.167122
199	354	finished	2025-05-16	2025-05-16	2025-05-16	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:48.476623	2025-12-27 07:08:48.476623
200	356	finished	2025-05-17	2025-05-17	2025-05-17	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:48.891672	2025-12-27 07:08:48.891672
201	355	finished	2025-05-17	2025-05-17	2025-05-17	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:49.143934	2025-12-27 07:08:49.143934
202	357	finished	2025-05-19	2025-05-19	2025-05-19	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:49.405282	2025-12-27 07:08:49.405282
203	358	finished	2025-05-20	2025-05-20	2025-05-20	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:49.659045	2025-12-27 07:08:49.659045
204	360	finished	2025-05-24	2025-05-24	2025-05-24	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:49.913872	2025-12-27 07:08:49.913872
205	361	finished	2025-05-24	2025-05-24	2025-05-24	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:50.166642	2025-12-27 07:08:50.166642
206	359	finished	2025-05-24	2025-05-24	2025-05-24	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:50.419464	2025-12-27 07:08:50.419464
207	362	finished	2025-05-24	2025-05-24	2025-05-24	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:50.672058	2025-12-27 07:08:50.672058
208	363	finished	2025-05-25	2025-05-25	2025-05-25	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:51.030039	2025-12-27 07:08:51.030039
209	365	finished	2025-05-26	2025-05-26	2025-05-26	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:51.286474	2025-12-27 07:08:51.286474
210	364	finished	2025-05-26	2025-05-26	2025-05-26	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:51.539799	2025-12-27 07:08:51.539799
211	366	finished	2025-05-28	2025-05-28	2025-05-28	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:51.792781	2025-12-27 07:08:51.792781
212	367	finished	2025-05-29	2025-05-29	2025-05-29	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:52.045474	2025-12-27 07:08:52.045474
213	368	finished	2025-05-31	2025-05-31	2025-05-31	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:52.298327	2025-12-27 07:08:52.298327
214	369	finished	2025-06-01	2025-06-01	2025-06-01	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:52.562603	2025-12-27 07:08:52.562603
215	371	finished	2025-06-04	2025-06-04	2025-06-04	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:52.826966	2025-12-27 07:08:52.826966
216	370	finished	2025-06-04	2025-06-04	2025-06-04	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:53.079186	2025-12-27 07:08:53.079186
217	372	finished	2025-06-04	2025-06-04	2025-06-04	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:53.334092	2025-12-27 07:08:53.334092
218	375	finished	2025-06-07	2025-06-07	2025-06-07	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:53.594826	2025-12-27 07:08:53.594826
219	374	finished	2025-06-07	2025-06-07	2025-06-07	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:53.848138	2025-12-27 07:08:53.848138
220	373	finished	2025-06-07	2025-06-07	2025-06-07	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:54.101138	2025-12-27 07:08:54.101138
221	64	finished	2025-06-10	2025-06-10	2025-06-10	0	3	\N	\N	1	f	0	\N	2025-12-27 07:08:54.354244	2025-12-27 07:08:54.354244
222	376	finished	2025-06-10	2025-06-10	2025-06-10	0	3	\N	\N	1	f	0	\N	2025-12-27 07:08:54.607227	2025-12-27 07:08:54.607227
223	377	finished	2025-06-11	2025-06-11	2025-06-11	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:54.920609	2025-12-27 07:08:54.920609
224	378	finished	2025-06-15	2025-06-15	2025-06-15	0	3	\N	\N	1	f	0	\N	2025-12-27 07:08:55.174556	2025-12-27 07:08:55.174556
225	379	finished	2025-06-17	2025-06-17	2025-06-17	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:55.431882	2025-12-27 07:08:55.431882
226	380	finished	2025-06-25	2025-06-25	2025-06-25	0	3	\N	\N	1	f	0	\N	2025-12-27 07:08:55.684788	2025-12-27 07:08:55.684788
227	381	finished	2025-06-25	2025-06-25	2025-06-25	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:55.93839	2025-12-27 07:08:55.93839
228	382	finished	2025-06-25	2025-06-25	2025-06-25	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:56.191487	2025-12-27 07:08:56.191487
229	383	finished	2025-06-25	2025-06-25	2025-06-25	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:56.444977	2025-12-27 07:08:56.444977
230	384	finished	2025-06-30	2025-06-30	2025-06-30	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:56.700672	2025-12-27 07:08:56.700672
231	386	finished	2025-06-30	2025-06-30	2025-06-30	0	2	\N	\N	1	f	0	\N	2025-12-27 07:08:56.954335	2025-12-27 07:08:56.954335
232	385	finished	2025-06-30	2025-06-30	2025-06-30	0	2	\N	\N	1	f	0	\N	2025-12-27 07:08:57.207205	2025-12-27 07:08:57.207205
233	387	finished	2025-07-09	2025-07-09	2025-07-09	0	3	\N	\N	1	f	0	\N	2025-12-27 07:08:57.460489	2025-12-27 07:08:57.460489
234	388	finished	2025-07-11	2025-07-11	2025-07-11	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:57.714214	2025-12-27 07:08:57.714214
235	389	finished	2025-07-11	2025-07-11	2025-07-11	0	5	\N	\N	1	f	0	\N	2025-12-27 07:08:57.967005	2025-12-27 07:08:57.967005
236	390	finished	2025-07-12	2025-07-12	2025-07-12	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:58.221863	2025-12-27 07:08:58.221863
237	391	finished	2025-07-12	2025-07-12	2025-07-12	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:58.50415	2025-12-27 07:08:58.50415
238	30	finished	2025-07-14	2025-07-14	2025-07-14	0	2	\N	\N	1	f	0	\N	2025-12-27 07:08:58.757792	2025-12-27 07:08:58.757792
239	134	finished	2025-07-14	2025-07-14	2025-07-14	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:59.01779	2025-12-27 07:08:59.01779
240	46	finished	2025-07-14	2025-07-14	2025-07-14	0	3	\N	\N	1	f	0	\N	2025-12-27 07:08:59.272957	2025-12-27 07:08:59.272957
241	177	finished	2025-07-15	2025-07-15	2025-07-15	0	4	\N	\N	1	f	0	\N	2025-12-27 07:08:59.531573	2025-12-27 07:08:59.531573
242	49	finished	2025-07-15	2025-07-15	2025-07-15	0	3	\N	\N	1	f	0	\N	2025-12-27 07:08:59.792602	2025-12-27 07:08:59.792602
243	215	finished	2025-07-16	2025-07-16	2025-07-16	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:00.046503	2025-12-27 07:09:00.046503
244	95	finished	2025-07-16	2025-07-16	2025-07-16	0	5	\N	\N	1	f	0	\N	2025-12-27 07:09:00.299942	2025-12-27 07:09:00.299942
245	162	finished	2025-07-17	2025-07-17	2025-07-17	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:00.55381	2025-12-27 07:09:00.55381
246	18	finished	2025-07-18	2025-07-18	2025-07-18	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:00.837178	2025-12-27 07:09:00.837178
247	48	finished	2025-07-18	2025-07-18	2025-07-18	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:01.099256	2025-12-27 07:09:01.099256
248	222	finished	2025-07-20	2025-07-20	2025-07-20	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:01.361965	2025-12-27 07:09:01.361965
249	158	finished	2025-07-24	2025-07-24	2025-07-24	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:01.682352	2025-12-27 07:09:01.682352
250	401	finished	2025-07-24	2025-07-24	2025-07-24	0	5	\N	\N	1	f	0	\N	2025-12-27 07:09:01.946772	2025-12-27 07:09:01.946772
251	122	finished	2025-07-24	2025-07-24	2025-07-24	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:02.205395	2025-12-27 07:09:02.205395
252	402	finished	2025-07-26	2025-07-26	2025-07-26	0	5	\N	\N	1	f	0	\N	2025-12-27 07:09:02.466783	2025-12-27 07:09:02.466783
253	19	finished	2025-07-27	2025-07-27	2025-07-27	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:02.735242	2025-12-27 07:09:02.735242
254	61	finished	2025-07-27	2025-07-27	2025-07-27	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:02.991766	2025-12-27 07:09:02.991766
255	38	finished	2025-07-27	2025-07-27	2025-07-27	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:03.252372	2025-12-27 07:09:03.252372
256	157	finished	2025-07-27	2025-07-27	2025-07-27	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:03.528052	2025-12-27 07:09:03.528052
257	145	finished	2025-07-28	2025-07-28	2025-07-28	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:03.845957	2025-12-27 07:09:03.845957
258	208	finished	2025-07-28	2025-07-28	2025-07-28	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:04.10602	2025-12-27 07:09:04.10602
259	231	finished	2025-07-28	2025-07-28	2025-07-28	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:04.369333	2025-12-27 07:09:04.369333
260	403	finished	2025-08-03	2025-08-03	2025-08-03	0	5	\N	\N	1	f	0	\N	2025-12-27 07:09:04.667961	2025-12-27 07:09:04.667961
261	404	finished	2025-08-03	2025-08-03	2025-08-03	0	5	\N	\N	1	f	0	\N	2025-12-27 07:09:04.926165	2025-12-27 07:09:04.926165
262	405	finished	2025-08-03	2025-08-03	2025-08-03	0	5	\N	\N	1	f	0	\N	2025-12-27 07:09:05.187718	2025-12-27 07:09:05.187718
263	406	finished	2025-08-04	2025-08-04	2025-08-04	0	5	\N	\N	1	f	0	\N	2025-12-27 07:09:05.44114	2025-12-27 07:09:05.44114
264	407	finished	2025-08-05	2025-08-05	2025-08-05	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:05.694657	2025-12-27 07:09:05.694657
265	132	finished	2025-08-09	2025-08-09	2025-08-09	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:05.948622	2025-12-27 07:09:05.948622
266	63	finished	2025-08-10	2025-08-10	2025-08-10	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:06.201875	2025-12-27 07:09:06.201875
267	67	finished	2025-08-10	2025-08-10	2025-08-10	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:06.495024	2025-12-27 07:09:06.495024
268	408	finished	2025-08-11	2025-08-11	2025-08-11	0	5	\N	\N	1	f	0	\N	2025-12-27 07:09:06.750392	2025-12-27 07:09:06.750392
269	409	finished	2025-08-11	2025-08-11	2025-08-11	0	5	\N	\N	1	f	0	\N	2025-12-27 07:09:07.004517	2025-12-27 07:09:07.004517
270	128	finished	2025-08-13	2025-08-13	2025-08-13	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:07.261366	2025-12-27 07:09:07.261366
271	65	finished	2025-08-13	2025-08-13	2025-08-13	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:07.516913	2025-12-27 07:09:07.516913
272	126	finished	2025-08-14	2025-08-14	2025-08-14	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:07.771015	2025-12-27 07:09:07.771015
273	52	finished	2025-08-14	2025-08-14	2025-08-14	0	2	\N	\N	1	f	0	\N	2025-12-27 07:09:08.028636	2025-12-27 07:09:08.028636
274	56	finished	2025-08-14	2025-08-14	2025-08-14	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:08.283073	2025-12-27 07:09:08.283073
275	112	finished	2025-08-15	2025-08-15	2025-08-15	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:08.537356	2025-12-27 07:09:08.537356
276	71	finished	2025-08-16	2025-08-16	2025-08-16	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:08.791751	2025-12-27 07:09:08.791751
277	6	finished	2025-08-17	2025-08-17	2025-08-17	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:09.051729	2025-12-27 07:09:09.051729
278	110	finished	2025-08-18	2025-08-18	2025-08-18	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:09.306446	2025-12-27 07:09:09.306446
279	60	finished	2025-08-18	2025-08-18	2025-08-18	0	2	\N	\N	1	f	0	\N	2025-12-27 07:09:09.565552	2025-12-27 07:09:09.565552
280	125	finished	2025-08-18	2025-08-18	2025-08-18	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:09.823302	2025-12-27 07:09:09.823302
281	45	finished	2025-08-18	2025-08-18	2025-08-18	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:10.077665	2025-12-27 07:09:10.077665
282	196	finished	2025-08-18	2025-08-18	2025-08-18	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:10.331622	2025-12-27 07:09:10.331622
283	42	finished	2025-08-18	2025-08-18	2025-08-18	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:10.586247	2025-12-27 07:09:10.586247
284	221	finished	2025-08-18	2025-08-18	2025-08-18	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:10.84073	2025-12-27 07:09:10.84073
285	161	finished	2025-08-18	2025-08-18	2025-08-18	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:11.095258	2025-12-27 07:09:11.095258
286	165	finished	2025-08-18	2025-08-18	2025-08-18	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:11.349966	2025-12-27 07:09:11.349966
287	154	finished	2025-08-18	2025-08-18	2025-08-18	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:11.605304	2025-12-27 07:09:11.605304
288	220	finished	2025-08-18	2025-08-18	2025-08-18	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:11.859392	2025-12-27 07:09:11.859392
289	32	finished	2025-08-19	2025-08-19	2025-08-19	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:12.115628	2025-12-27 07:09:12.115628
290	78	finished	2025-08-19	2025-08-19	2025-08-19	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:12.370756	2025-12-27 07:09:12.370756
291	117	finished	2025-08-19	2025-08-19	2025-08-19	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:12.737201	2025-12-27 07:09:12.737201
292	410	finished	2025-08-19	2025-08-19	2025-08-19	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:12.992417	2025-12-27 07:09:12.992417
293	411	finished	2025-08-21	2025-08-21	2025-08-21	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:13.254543	2025-12-27 07:09:13.254543
294	62	finished	2025-08-21	2025-08-21	2025-08-21	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:13.509105	2025-12-27 07:09:13.509105
295	74	finished	2025-08-21	2025-08-21	2025-08-21	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:13.766254	2025-12-27 07:09:13.766254
296	81	finished	2025-08-22	2025-08-22	2025-08-22	0	1	\N	\N	1	f	0	\N	2025-12-27 07:09:14.021232	2025-12-27 07:09:14.021232
297	412	finished	2025-08-22	2025-08-22	2025-08-22	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:14.276896	2025-12-27 07:09:14.276896
298	75	finished	2025-08-23	2025-08-23	2025-08-23	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:14.531508	2025-12-27 07:09:14.531508
299	73	finished	2025-08-23	2025-08-23	2025-08-23	0	2	\N	\N	1	f	0	\N	2025-12-27 07:09:14.786957	2025-12-27 07:09:14.786957
300	23	finished	2025-08-24	2025-08-24	2025-08-24	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:15.041692	2025-12-27 07:09:15.041692
301	57	finished	2025-08-24	2025-08-24	2025-08-24	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:15.300107	2025-12-27 07:09:15.300107
302	54	finished	2025-08-24	2025-08-24	2025-08-24	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:15.555454	2025-12-27 07:09:15.555454
303	152	finished	2025-08-24	2025-08-24	2025-08-24	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:15.81022	2025-12-27 07:09:15.81022
304	20	finished	2025-08-24	2025-08-24	2025-08-24	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:16.102466	2025-12-27 07:09:16.102466
305	184	finished	2025-08-24	2025-08-24	2025-08-24	0	2	\N	\N	1	f	0	\N	2025-12-27 07:09:16.426133	2025-12-27 07:09:16.426133
306	155	finished	2025-08-24	2025-08-24	2025-08-24	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:16.68408	2025-12-27 07:09:16.68408
307	156	finished	2025-08-24	2025-08-24	2025-08-24	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:16.9415	2025-12-27 07:09:16.9415
308	144	finished	2025-08-24	2025-08-24	2025-08-24	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:17.196981	2025-12-27 07:09:17.196981
309	151	finished	2025-08-24	2025-08-24	2025-08-24	0	2	\N	\N	1	f	0	\N	2025-12-27 07:09:17.452391	2025-12-27 07:09:17.452391
310	153	finished	2025-08-24	2025-08-24	2025-08-24	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:17.707461	2025-12-27 07:09:17.707461
311	160	finished	2025-08-24	2025-08-24	2025-08-24	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:17.963129	2025-12-27 07:09:17.963129
312	147	finished	2025-08-24	2025-08-24	2025-08-24	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:18.219024	2025-12-27 07:09:18.219024
313	164	finished	2025-08-25	2025-08-25	2025-08-25	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:18.474302	2025-12-27 07:09:18.474302
314	163	finished	2025-08-25	2025-08-25	2025-08-25	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:18.731025	2025-12-27 07:09:18.731025
315	183	finished	2025-08-25	2025-08-25	2025-08-25	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:18.988726	2025-12-27 07:09:18.988726
316	187	finished	2025-08-25	2025-08-25	2025-08-25	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:19.244542	2025-12-27 07:09:19.244542
317	142	finished	2025-08-25	2025-08-25	2025-08-25	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:19.501231	2025-12-27 07:09:19.501231
318	413	finished	2025-08-25	2025-08-25	2025-08-25	0	5	\N	\N	1	f	0	\N	2025-12-27 07:09:19.756877	2025-12-27 07:09:19.756877
319	186	finished	2025-08-25	2025-08-25	2025-08-25	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:20.012549	2025-12-27 07:09:20.012549
320	146	finished	2025-08-25	2025-08-25	2025-08-25	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:20.271893	2025-12-27 07:09:20.271893
321	129	finished	2025-08-28	2025-08-28	2025-08-28	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:20.525958	2025-12-27 07:09:20.525958
322	414	finished	2025-09-01	2025-09-01	2025-09-01	0	5	\N	\N	1	f	0	\N	2025-12-27 07:09:20.827773	2025-12-27 07:09:20.827773
323	415	finished	2025-09-01	2025-09-01	2025-09-01	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:21.081982	2025-12-27 07:09:21.081982
324	39	finished	2025-09-02	2025-09-02	2025-09-02	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:21.337059	2025-12-27 07:09:21.337059
325	416	finished	2025-09-02	2025-09-02	2025-09-02	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:21.593427	2025-12-27 07:09:21.593427
326	31	finished	2025-09-02	2025-09-02	2025-09-02	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:21.847573	2025-12-27 07:09:21.847573
327	124	finished	2025-09-02	2025-09-02	2025-09-02	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:22.162943	2025-12-27 07:09:22.162943
328	133	finished	2025-09-02	2025-09-02	2025-09-02	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:22.429927	2025-12-27 07:09:22.429927
329	417	finished	2025-09-02	2025-09-02	2025-09-02	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:22.684995	2025-12-27 07:09:22.684995
330	418	finished	2025-09-02	2025-09-02	2025-09-02	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:22.940329	2025-12-27 07:09:22.940329
331	80	finished	2025-09-02	2025-09-02	2025-09-02	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:23.223054	2025-12-27 07:09:23.223054
332	419	finished	2025-09-03	2025-09-03	2025-09-03	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:23.477729	2025-12-27 07:09:23.477729
333	420	finished	2025-09-03	2025-09-03	2025-09-03	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:23.732088	2025-12-27 07:09:23.732088
334	70	finished	2025-09-03	2025-09-03	2025-09-03	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:23.987381	2025-12-27 07:09:23.987381
335	68	finished	2025-09-04	2025-09-04	2025-09-04	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:24.242667	2025-12-27 07:09:24.242667
336	421	finished	2025-09-05	2025-09-05	2025-09-05	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:24.497337	2025-12-27 07:09:24.497337
337	121	finished	2025-09-05	2025-09-05	2025-09-05	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:24.753132	2025-12-27 07:09:24.753132
338	422	finished	2025-09-06	2025-09-06	2025-09-06	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:25.008875	2025-12-27 07:09:25.008875
339	423	finished	2025-09-07	2025-09-07	2025-09-07	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:25.263393	2025-12-27 07:09:25.263393
340	424	finished	2025-09-11	2025-09-11	2025-09-11	0	5	\N	\N	1	f	0	\N	2025-12-27 07:09:25.539417	2025-12-27 07:09:25.539417
341	425	finished	2025-09-11	2025-09-11	2025-09-11	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:25.795161	2025-12-27 07:09:25.795161
342	426	finished	2025-09-13	2025-09-13	2025-09-13	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:26.050521	2025-12-27 07:09:26.050521
343	216	finished	2025-09-13	2025-09-13	2025-09-13	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:26.306097	2025-12-27 07:09:26.306097
344	217	finished	2025-09-13	2025-09-13	2025-09-13	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:26.563722	2025-12-27 07:09:26.563722
345	427	finished	2025-09-13	2025-09-13	2025-09-13	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:26.869456	2025-12-27 07:09:26.869456
346	218	finished	2025-09-14	2025-09-14	2025-09-14	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:27.124063	2025-12-27 07:09:27.124063
347	127	finished	2025-09-14	2025-09-14	2025-09-14	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:27.38299	2025-12-27 07:09:27.38299
348	428	finished	2025-09-14	2025-09-14	2025-09-14	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:27.639966	2025-12-27 07:09:27.639966
349	119	finished	2025-09-16	2025-09-16	2025-09-16	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:27.898833	2025-12-27 07:09:27.898833
350	429	finished	2025-09-19	2025-09-19	2025-09-19	0	5	\N	\N	1	f	0	\N	2025-12-27 07:09:28.154181	2025-12-27 07:09:28.154181
351	430	finished	2025-09-20	2025-09-20	2025-09-20	0	5	\N	\N	1	f	0	\N	2025-12-27 07:09:28.408635	2025-12-27 07:09:28.408635
352	109	finished	2025-09-20	2025-09-20	2025-09-20	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:28.663416	2025-12-27 07:09:28.663416
353	27	finished	2025-09-22	2025-09-22	2025-09-22	0	5	\N	\N	1	f	0	\N	2025-12-27 07:09:28.918465	2025-12-27 07:09:28.918465
354	432	finished	2025-09-22	2025-09-22	2025-09-22	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:29.173116	2025-12-27 07:09:29.173116
355	431	finished	2025-09-22	2025-09-22	2025-09-22	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:29.431313	2025-12-27 07:09:29.431313
356	140	finished	2025-09-22	2025-09-22	2025-09-22	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:29.686477	2025-12-27 07:09:29.686477
357	76	finished	2025-09-22	2025-09-22	2025-09-22	0	2	\N	\N	1	f	0	\N	2025-12-27 07:09:29.942233	2025-12-27 07:09:29.942233
358	58	finished	2025-09-22	2025-09-22	2025-09-22	0	2	\N	\N	1	f	0	\N	2025-12-27 07:09:30.197474	2025-12-27 07:09:30.197474
359	101	finished	2025-09-22	2025-09-22	2025-09-22	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:30.453271	2025-12-27 07:09:30.453271
360	433	finished	2025-09-24	2025-09-24	2025-09-24	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:30.75981	2025-12-27 07:09:30.75981
361	138	finished	2025-09-25	2025-09-25	2025-09-25	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:31.015246	2025-12-27 07:09:31.015246
362	135	finished	2025-09-26	2025-09-26	2025-09-26	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:31.273077	2025-12-27 07:09:31.273077
363	116	finished	2025-09-29	2025-09-29	2025-09-29	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:31.528436	2025-12-27 07:09:31.528436
364	120	finished	2025-10-01	2025-10-01	2025-10-01	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:31.784927	2025-12-27 07:09:31.784927
365	398	finished	2025-10-04	2025-10-04	2025-10-04	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:32.039686	2025-12-27 07:09:32.039686
366	53	finished	2025-10-04	2025-10-04	2025-10-04	0	2	\N	\N	1	f	0	\N	2025-12-27 07:09:32.295321	2025-12-27 07:09:32.295321
367	167	finished	2025-10-06	2025-10-06	2025-10-06	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:32.55153	2025-12-27 07:09:32.55153
368	434	finished	2025-10-08	2025-10-08	2025-10-08	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:32.807288	2025-12-27 07:09:32.807288
369	435	finished	2025-10-13	2025-10-13	2025-10-13	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:33.062677	2025-12-27 07:09:33.062677
370	436	finished	2025-10-15	2025-10-15	2025-10-15	0	5	\N	\N	1	f	0	\N	2025-12-27 07:09:33.31769	2025-12-27 07:09:33.31769
371	393	finished	2025-10-15	2025-10-15	2025-10-15	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:33.578225	2025-12-27 07:09:33.578225
372	437	finished	2025-10-15	2025-10-15	2025-10-15	0	5	\N	\N	1	f	0	\N	2025-12-27 07:09:33.834376	2025-12-27 07:09:33.834376
373	89	finished	2025-10-15	2025-10-15	2025-10-15	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:34.089275	2025-12-27 07:09:34.089275
374	131	finished	2025-10-17	2025-10-17	2025-10-17	0	5	\N	\N	1	f	0	\N	2025-12-27 07:09:34.344441	2025-12-27 07:09:34.344441
375	438	finished	2025-10-17	2025-10-17	2025-10-17	0	5	\N	\N	1	f	0	\N	2025-12-27 07:09:34.652768	2025-12-27 07:09:34.652768
376	170	finished	2025-10-17	2025-10-17	2025-10-17	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:34.907929	2025-12-27 07:09:34.907929
377	210	finished	2025-10-18	2025-10-18	2025-10-18	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:35.163766	2025-12-27 07:09:35.163766
378	137	finished	2025-10-18	2025-10-18	2025-10-18	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:35.419461	2025-12-27 07:09:35.419461
379	204	finished	2025-10-19	2025-10-19	2025-10-19	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:35.676173	2025-12-27 07:09:35.676173
380	188	finished	2025-10-19	2025-10-19	2025-10-19	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:35.935073	2025-12-27 07:09:35.935073
381	439	finished	2025-10-19	2025-10-19	2025-10-19	0	5	\N	\N	1	f	0	\N	2025-12-27 07:09:36.191276	2025-12-27 07:09:36.191276
382	191	finished	2025-10-19	2025-10-19	2025-10-19	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:36.447581	2025-12-27 07:09:36.447581
383	15	finished	2025-10-19	2025-10-19	2025-10-19	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:36.709805	2025-12-27 07:09:36.709805
384	43	finished	2025-10-19	2025-10-19	2025-10-19	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:36.967589	2025-12-27 07:09:36.967589
385	40	finished	2025-10-19	2025-10-19	2025-10-19	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:37.223157	2025-12-27 07:09:37.223157
386	440	finished	2025-10-20	2025-10-20	2025-10-20	0	5	\N	\N	1	f	0	\N	2025-12-27 07:09:37.483592	2025-12-27 07:09:37.483592
387	82	finished	2025-10-20	2025-10-20	2025-10-20	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:37.739445	2025-12-27 07:09:37.739445
388	205	finished	2025-10-20	2025-10-20	2025-10-20	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:37.994973	2025-12-27 07:09:37.994973
389	441	finished	2025-10-21	2025-10-21	2025-10-21	0	5	\N	\N	1	f	0	\N	2025-12-27 07:09:38.253521	2025-12-27 07:09:38.253521
390	442	finished	2025-10-21	2025-10-21	2025-10-21	0	5	\N	\N	1	f	0	\N	2025-12-27 07:09:38.542287	2025-12-27 07:09:38.542287
391	444	finished	2025-10-21	2025-10-21	2025-10-21	0	5	\N	\N	1	f	0	\N	2025-12-27 07:09:38.797464	2025-12-27 07:09:38.797464
392	443	finished	2025-10-21	2025-10-21	2025-10-21	0	5	\N	\N	1	f	0	\N	2025-12-27 07:09:39.053642	2025-12-27 07:09:39.053642
393	445	finished	2025-10-22	2025-10-22	2025-10-22	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:39.309567	2025-12-27 07:09:39.309567
394	104	finished	2025-10-22	2025-10-22	2025-10-22	0	5	\N	\N	1	f	0	\N	2025-12-27 07:09:39.565792	2025-12-27 07:09:39.565792
395	28	finished	2025-10-22	2025-10-22	2025-10-22	0	2	\N	\N	1	f	0	\N	2025-12-27 07:09:39.82294	2025-12-27 07:09:39.82294
396	446	finished	2025-10-23	2025-10-23	2025-10-23	0	5	\N	\N	1	f	0	\N	2025-12-27 07:09:40.078386	2025-12-27 07:09:40.078386
397	447	finished	2025-10-24	2025-10-24	2025-10-24	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:40.340983	2025-12-27 07:09:40.340983
398	448	finished	2025-10-25	2025-10-25	2025-10-25	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:40.597308	2025-12-27 07:09:40.597308
399	449	finished	2025-10-28	2025-10-28	2025-10-28	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:40.853269	2025-12-27 07:09:40.853269
400	450	finished	2025-10-28	2025-10-28	2025-10-28	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:41.109233	2025-12-27 07:09:41.109233
401	451	finished	2025-10-31	2025-10-31	2025-10-31	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:41.370327	2025-12-27 07:09:41.370327
402	166	finished	2025-11-01	2025-11-01	2025-11-01	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:41.627483	2025-12-27 07:09:41.627483
403	452	finished	2025-11-03	2025-11-03	2025-11-03	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:41.883228	2025-12-27 07:09:41.883228
404	455	finished	2025-11-03	2025-11-03	2025-11-03	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:42.138941	2025-12-27 07:09:42.138941
405	454	finished	2025-11-03	2025-11-03	2025-11-03	0	5	\N	\N	1	f	0	\N	2025-12-27 07:09:42.3956	2025-12-27 07:09:42.3956
406	453	finished	2025-11-03	2025-11-03	2025-11-03	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:42.652775	2025-12-27 07:09:42.652775
407	123	finished	2025-11-03	2025-11-03	2025-11-03	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:42.908751	2025-12-27 07:09:42.908751
408	456	finished	2025-11-06	2025-11-06	2025-11-06	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:43.164868	2025-12-27 07:09:43.164868
409	457	finished	2025-11-06	2025-11-06	2025-11-06	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:43.425468	2025-12-27 07:09:43.425468
410	458	finished	2025-11-06	2025-11-06	2025-11-06	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:43.765477	2025-12-27 07:09:43.765477
411	219	finished	2025-11-07	2025-11-07	2025-11-07	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:44.021463	2025-12-27 07:09:44.021463
412	136	finished	2025-11-07	2025-11-07	2025-11-07	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:44.27882	2025-12-27 07:09:44.27882
413	459	finished	2025-11-07	2025-11-07	2025-11-07	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:44.534482	2025-12-27 07:09:44.534482
414	460	finished	2025-11-07	2025-11-07	2025-11-07	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:44.790589	2025-12-27 07:09:44.790589
415	461	finished	2025-11-07	2025-11-07	2025-11-07	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:45.047262	2025-12-27 07:09:45.047262
416	462	finished	2025-11-08	2025-11-08	2025-11-08	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:45.305128	2025-12-27 07:09:45.305128
417	463	finished	2025-11-08	2025-11-08	2025-11-08	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:45.611513	2025-12-27 07:09:45.611513
418	400	finished	2025-11-09	2025-11-09	2025-11-09	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:45.915087	2025-12-27 07:09:45.915087
419	464	finished	2025-11-13	2025-11-13	2025-11-13	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:46.170939	2025-12-27 07:09:46.170939
420	465	finished	2025-11-13	2025-11-13	2025-11-13	0	5	\N	\N	1	f	0	\N	2025-12-27 07:09:46.427945	2025-12-27 07:09:46.427945
421	213	finished	2025-11-13	2025-11-13	2025-11-13	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:46.838543	2025-12-27 07:09:46.838543
422	466	finished	2025-11-13	2025-11-13	2025-11-13	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:47.094893	2025-12-27 07:09:47.094893
423	103	finished	2025-11-13	2025-11-13	2025-11-13	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:47.352988	2025-12-27 07:09:47.352988
424	467	finished	2025-11-16	2025-11-16	2025-11-16	0	5	\N	\N	1	f	0	\N	2025-12-27 07:09:47.61012	2025-12-27 07:09:47.61012
425	468	finished	2025-11-17	2025-11-17	2025-11-17	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:47.866876	2025-12-27 07:09:47.866876
426	469	finished	2025-11-18	2025-11-18	2025-11-18	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:48.124216	2025-12-27 07:09:48.124216
427	470	finished	2025-11-22	2025-11-22	2025-11-22	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:48.381259	2025-12-27 07:09:48.381259
428	471	finished	2025-11-24	2025-11-24	2025-11-24	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:48.687144	2025-12-27 07:09:48.687144
429	472	finished	2025-11-25	2025-11-25	2025-11-25	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:48.9439	2025-12-27 07:09:48.9439
430	473	finished	2025-11-27	2025-11-27	2025-11-27	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:49.200053	2025-12-27 07:09:49.200053
431	474	finished	2025-11-29	2025-11-29	2025-11-29	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:49.513035	2025-12-27 07:09:49.513035
432	113	finished	2025-11-30	2025-11-30	2025-11-30	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:49.771148	2025-12-27 07:09:49.771148
433	475	finished	2025-11-30	2025-11-30	2025-11-30	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:50.04101	2025-12-27 07:09:50.04101
434	476	finished	2025-11-30	2025-11-30	2025-11-30	0	3	\N	\N	1	f	0	\N	2025-12-27 07:09:50.298319	2025-12-27 07:09:50.298319
435	223	finished	2025-12-01	2025-12-01	2025-12-01	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:50.626118	2025-12-27 07:09:50.626118
436	479	finished	2025-12-07	2025-12-07	2025-12-07	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:50.887873	2025-12-27 07:09:50.887873
437	478	finished	2025-12-07	2025-12-07	2025-12-07	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:51.145524	2025-12-27 07:09:51.145524
438	477	finished	2025-12-07	2025-12-07	2025-12-07	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:51.40263	2025-12-27 07:09:51.40263
439	86	finished	2025-12-09	2025-12-09	2025-12-09	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:51.669104	2025-12-27 07:09:51.669104
440	87	finished	2025-12-13	2025-12-13	2025-12-13	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:51.926224	2025-12-27 07:09:51.926224
441	480	finished	2025-12-14	2025-12-14	2025-12-14	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:52.250162	2025-12-27 07:09:52.250162
442	106	finished	2025-12-17	2025-12-17	2025-12-17	0	4	\N	\N	1	f	0	\N	2025-12-27 07:09:52.572347	2025-12-27 07:09:52.572347
1	9	finished	2024-11-22	2024-11-22	2024-11-22	0	\N	\N	\N	1	f	0	\N	2025-12-27 07:07:56.594704	2025-12-27 07:09:53.332738
598	608	finished	2026-04-03	\N	2026-04-03	0	4	\N	\N	\N	f	0	\N	2026-04-03 06:12:39.161139	2026-04-03 06:12:41.124055
445	488	finished	2025-12-28	\N	2025-12-28	0	4	\N	\N	\N	f	0	\N	2025-12-28 11:11:53.315487	2025-12-28 11:18:05.996505
444	484	finished	2025-12-28	\N	2025-12-28	0	4	\N	\N	\N	f	0	\N	2025-12-28 11:08:24.741631	2025-12-28 11:18:17.247624
446	485	finished	2025-12-28	\N	2025-12-28	0	4	\N	\N	\N	f	0	\N	2025-12-28 11:18:25.302753	2025-12-28 11:18:30.463906
447	486	finished	2026-01-02	\N	2026-01-02	0	4	\N	\N	\N	f	0	\N	2026-01-02 19:03:27.691294	2026-01-02 19:03:30.747076
448	483	finished	2026-01-04	\N	2026-01-04	0	4	\N	\N	\N	f	0	\N	2026-01-04 15:06:13.969428	2026-01-04 15:06:17.24776
449	495	finished	2026-01-09	\N	2026-01-09	0	4	\N	\N	\N	f	0	\N	2026-01-09 03:42:46.339615	2026-01-09 03:42:49.237354
450	491	finished	2026-01-09	\N	2026-01-09	0	4	\N	\N	\N	f	0	\N	2026-01-09 12:02:30.984048	2026-01-09 12:02:33.177688
451	189	finished	2026-01-10	\N	2026-01-10	0	4	\N	\N	\N	f	0	\N	2026-01-10 02:26:45.684502	2026-01-10 02:26:47.093292
443	47	finished	2025-12-27	\N	2026-01-10	0	3	\N	\N	\N	f	0	\N	2025-12-27 07:56:07.355458	2026-01-10 02:28:03.259633
452	487	finished	2026-01-12	\N	2026-01-12	0	3	\N	\N	\N	f	0	\N	2026-01-12 07:30:38.402945	2026-01-12 07:30:40.64715
453	493	finished	2026-01-13	\N	2026-01-13	0	4	\N	\N	\N	f	0	\N	2026-01-13 01:46:00.891758	2026-01-13 01:46:03.384282
455	496	finished	2026-01-16	\N	2026-01-16	0	4	\N	\N	\N	f	0	\N	2026-01-16 04:30:57.325755	2026-01-16 04:31:04.272504
456	497	finished	2026-01-16	\N	2026-01-16	0	4	\N	\N	\N	f	0	\N	2026-01-16 04:31:10.092993	2026-01-16 04:31:13.303063
458	397	finished	2026-01-16	\N	2026-01-16	0	4	\N	\N	\N	f	0	\N	2026-01-16 12:24:47.175706	2026-01-16 12:25:53.783933
459	498	finished	2026-01-17	\N	2026-01-17	0	4	\N	\N	\N	f	0	\N	2026-01-17 14:37:40.596681	2026-01-17 14:37:42.471744
460	499	finished	2026-01-18	\N	2026-01-18	0	4	\N	\N	\N	f	0	\N	2026-01-18 11:12:46.158821	2026-01-18 11:12:48.001445
461	494	finished	2026-01-18	\N	2026-01-18	0	4	\N	\N	\N	f	0	\N	2026-01-18 11:13:31.991834	2026-01-18 11:13:33.672086
462	503	finished	2026-01-22	\N	2026-01-22	0	4	\N	\N	\N	f	0	\N	2026-01-22 06:27:58.06584	2026-01-22 06:27:59.449439
463	501	finished	2026-01-24	\N	2026-01-24	0	4	\N	\N	\N	f	0	\N	2026-01-24 03:20:51.731042	2026-01-24 03:20:54.826224
464	212	finished	2026-01-24	\N	2026-01-24	0	3	\N	\N	\N	f	0	\N	2026-01-24 03:54:26.791181	2026-01-24 03:54:29.087059
466	504	finished	2026-01-24	\N	2026-01-24	0	5	\N	\N	\N	f	0	\N	2026-01-24 18:05:00.570234	2026-01-24 18:05:02.842359
467	505	finished	2026-01-25	\N	2026-01-25	0	4	\N	\N	\N	f	0	\N	2026-01-25 04:19:51.211711	2026-01-25 04:19:53.708255
468	492	finished	2026-01-25	\N	2026-01-25	0	4	\N	\N	\N	f	0	\N	2026-01-25 05:23:52.9797	2026-01-25 05:23:54.716532
469	175	finished	2026-01-26	\N	2026-01-26	0	3	\N	\N	\N	f	0	\N	2026-01-26 11:33:44.168867	2026-01-26 11:33:47.423347
470	507	finished	2026-01-26	\N	2026-01-26	0	5	\N	\N	\N	f	0	\N	2026-01-26 15:44:20.976587	2026-01-26 15:44:25.292597
471	178	finished	2026-01-27	\N	2026-01-27	0	3	\N	\N	\N	f	0	\N	2026-01-27 16:15:03.045592	2026-01-27 16:15:04.797604
472	229	finished	2026-01-27	\N	2026-01-27	0	3	\N	\N	\N	f	0	\N	2026-01-27 16:15:57.52299	2026-01-27 16:15:59.214237
473	139	finished	2026-01-27	\N	2026-01-27	0	3	\N	\N	\N	f	0	\N	2026-01-27 19:01:54.94076	2026-01-27 19:01:57.062802
474	502	finished	2026-01-31	\N	2026-01-31	0	5	\N	\N	\N	f	0	\N	2026-01-31 18:44:32.092254	2026-01-31 18:44:33.813901
475	506	finished	2026-01-31	\N	2026-01-31	0	4	\N	\N	\N	f	0	\N	2026-01-31 18:44:47.497972	2026-01-31 18:44:50.023414
476	490	finished	2026-01-31	\N	2026-01-31	0	4	\N	\N	\N	f	0	\N	2026-01-31 19:44:28.838398	2026-01-31 19:44:30.184829
477	500	finished	2026-02-01	\N	2026-02-01	0	3	\N	\N	\N	f	0	\N	2026-02-01 01:56:38.497875	2026-02-01 01:56:40.478646
478	508	finished	2026-02-01	\N	2026-02-01	0	4	\N	\N	\N	f	0	\N	2026-02-01 01:57:45.627128	2026-02-01 01:57:49.759136
479	509	finished	2026-02-01	\N	2026-02-01	0	3	\N	\N	\N	f	0	\N	2026-02-01 02:00:01.691227	2026-02-01 02:00:03.743736
480	90	finished	2026-02-01	\N	2026-02-01	0	4	\N	\N	\N	f	0	\N	2026-02-01 02:36:15.726445	2026-02-01 02:36:17.803567
481	141	finished	2026-02-01	\N	2026-02-01	0	3	\N	\N	\N	f	0	\N	2026-02-01 03:21:31.754593	2026-02-01 03:21:34.065242
482	206	finished	2026-02-01	\N	2026-02-01	0	3	\N	\N	\N	f	0	\N	2026-02-01 10:38:18.177712	2026-02-01 10:38:20.370384
484	510	finished	2026-02-01	\N	2026-02-01	0	5	\N	\N	\N	f	0	\N	2026-02-01 10:39:21.718304	2026-02-01 10:39:25.15871
485	33	finished	2026-02-02	\N	2026-02-02	0	3	\N	\N	\N	f	0	\N	2026-02-02 04:29:13.595894	2026-02-02 04:29:15.512222
486	511	finished	2026-02-05	\N	2026-02-05	0	4	\N	\N	\N	f	0	\N	2026-02-05 04:11:50.861841	2026-02-05 04:11:54.782855
487	512	finished	2026-02-05	\N	2026-02-05	0	4	\N	\N	\N	f	0	\N	2026-02-05 04:12:04.439594	2026-02-05 04:12:06.064831
488	513	finished	2026-02-05	\N	2026-02-05	0	4	\N	\N	\N	f	0	\N	2026-02-05 04:12:14.269395	2026-02-05 04:12:17.06757
490	395	finished	2026-02-07	\N	2026-02-07	0	4	\N	\N	\N	f	0	\N	2026-02-07 06:47:57.823738	2026-02-07 06:47:59.612021
491	514	finished	2026-02-07	\N	2026-02-07	0	4	\N	\N	\N	f	0	\N	2026-02-07 06:59:32.083839	2026-02-07 06:59:34.567659
492	69	finished	2026-02-07	\N	2026-02-07	0	3	\N	\N	\N	f	0	\N	2026-02-07 09:44:02.956222	2026-02-07 09:44:19.576864
493	182	finished	2026-02-08	\N	2026-02-08	0	4	\N	\N	\N	f	0	\N	2026-02-08 11:25:02.62841	2026-02-08 11:25:05.589458
494	515	finished	2026-02-08	\N	2026-02-08	0	4	\N	\N	\N	f	0	\N	2026-02-08 11:26:21.566495	2026-02-08 11:26:23.573254
495	516	finished	2026-02-08	\N	2026-02-08	0	4	\N	\N	\N	f	0	\N	2026-02-08 11:26:30.116693	2026-02-08 11:26:34.626634
496	214	finished	2026-02-09	\N	2026-02-09	0	4	\N	\N	\N	f	0	\N	2026-02-09 02:46:33.926085	2026-02-09 02:46:37.589372
497	517	finished	2026-02-11	\N	2026-02-11	0	4	\N	\N	\N	f	0	\N	2026-02-11 04:45:09.358666	2026-02-11 04:45:11.186169
498	521	finished	2026-02-11	\N	2026-02-11	0	5	\N	\N	\N	f	0	\N	2026-02-11 04:45:16.88356	2026-02-11 04:45:18.383792
499	520	finished	2026-02-11	\N	2026-02-11	0	5	\N	\N	\N	f	0	\N	2026-02-11 04:45:23.878319	2026-02-11 04:45:25.90224
500	519	finished	2026-02-11	\N	2026-02-11	0	4	\N	\N	\N	f	0	\N	2026-02-11 04:45:33.204019	2026-02-11 04:45:34.847555
501	518	finished	2026-02-11	\N	2026-02-11	0	4	\N	\N	\N	f	0	\N	2026-02-11 04:45:40.213278	2026-02-11 04:45:42.898595
502	522	finished	2026-02-13	\N	2026-02-13	0	4	\N	\N	\N	f	0	\N	2026-02-13 04:45:16.758916	2026-02-13 04:45:19.158962
503	523	finished	2026-02-13	\N	2026-02-13	0	2	\N	\N	\N	f	0	\N	2026-02-13 08:17:03.395146	2026-02-13 08:17:05.3204
504	396	finished	2026-02-15	\N	2026-02-15	0	4	\N	\N	\N	f	0	\N	2026-02-15 09:05:22.988561	2026-02-15 09:05:25.395647
505	524	finished	2026-02-15	\N	2026-02-15	0	4	\N	\N	\N	f	0	\N	2026-02-15 09:22:31.964253	2026-02-15 09:22:35.782726
506	525	finished	2026-02-15	\N	2026-02-15	0	4	\N	\N	\N	f	0	\N	2026-02-15 11:27:32.950306	2026-02-15 11:27:34.94499
508	527	finished	2026-02-17	\N	2026-02-17	0	4	\N	\N	\N	f	0	\N	2026-02-17 10:01:40.302955	2026-02-17 10:01:42.265213
507	526	finished	2026-02-17	\N	2026-02-17	0	4	\N	\N	\N	f	0	\N	2026-02-17 10:01:31.528661	2026-02-17 10:01:46.854079
509	211	finished	2026-02-17	\N	2026-02-17	0	4	\N	\N	\N	f	0	\N	2026-02-17 10:20:07.547805	2026-02-17 10:20:09.436331
510	394	finished	2026-02-18	\N	2026-02-18	0	5	\N	\N	\N	f	0	\N	2026-02-18 02:11:54.99665	2026-02-18 02:11:56.889573
511	535	finished	2026-02-18	\N	2026-02-18	0	4	\N	\N	\N	f	0	\N	2026-02-18 03:10:51.505856	2026-02-18 03:10:53.619843
512	536	finished	2026-02-18	\N	2026-02-18	0	4	\N	\N	\N	f	0	\N	2026-02-18 03:35:47.048717	2026-02-18 03:35:49.48553
513	179	finished	2026-02-18	\N	2026-02-18	0	4	\N	\N	\N	f	0	\N	2026-02-18 04:48:19.03519	2026-02-18 04:48:21.360175
515	203	finished	2026-02-19	\N	2026-02-19	0	4	\N	\N	\N	f	0	\N	2026-02-19 12:19:19.751362	2026-02-19 12:19:22.531133
516	209	finished	2026-02-19	\N	2026-02-19	0	3	\N	\N	\N	f	0	\N	2026-02-19 12:19:40.009134	2026-02-19 12:19:41.987224
514	537	finished	2026-02-19	\N	2026-02-20	0	4	\N	\N	\N	f	0	\N	2026-02-19 09:00:26.13806	2026-02-20 16:31:07.136744
517	538	finished	2026-02-20	\N	2026-02-20	0	4	\N	\N	\N	f	0	\N	2026-02-20 16:31:31.010209	2026-02-20 16:31:32.905678
518	539	finished	2026-02-20	\N	2026-02-20	0	4	\N	\N	\N	f	0	\N	2026-02-20 16:31:38.183527	2026-02-20 16:31:39.83882
519	540	finished	2026-02-20	\N	2026-02-20	0	4	\N	\N	\N	f	0	\N	2026-02-20 16:32:44.108554	2026-02-20 16:32:46.008077
520	207	finished	2026-02-21	\N	2026-02-21	0	3	\N	\N	\N	f	0	\N	2026-02-21 19:10:27.188078	2026-02-21 19:10:29.43223
521	541	finished	2026-02-21	\N	2026-02-21	0	3	\N	\N	\N	f	0	\N	2026-02-21 19:12:32.632553	2026-02-21 19:12:34.388565
522	542	finished	2026-02-21	\N	2026-02-21	0	3	\N	\N	\N	f	0	\N	2026-02-21 19:12:42.269904	2026-02-21 19:12:43.714333
523	543	finished	2026-02-21	\N	2026-02-21	0	3	\N	\N	\N	f	0	\N	2026-02-21 19:13:30.624922	2026-02-21 19:13:33.470076
524	181	finished	2026-02-22	\N	2026-02-22	0	4	\N	\N	\N	f	0	\N	2026-02-22 16:10:01.283438	2026-02-22 16:10:03.219045
525	544	finished	2026-02-22	\N	2026-02-22	0	4	\N	\N	\N	f	0	\N	2026-02-22 16:15:37.922384	2026-02-22 16:15:39.150852
526	546	finished	2026-02-22	\N	2026-02-22	0	3	\N	\N	\N	f	0	\N	2026-02-22 16:15:45.174303	2026-02-22 16:15:47.273867
527	547	finished	2026-02-22	\N	2026-02-22	0	2	\N	\N	\N	f	0	\N	2026-02-22 16:15:52.434096	2026-02-22 16:15:53.71461
528	545	finished	2026-02-22	\N	2026-02-22	0	4	\N	\N	\N	f	0	\N	2026-02-22 16:15:59.934823	2026-02-22 16:16:03.963052
530	549	finished	2026-02-23	\N	2026-02-23	0	4	\N	\N	\N	f	0	\N	2026-02-23 08:43:56.042432	2026-02-23 08:43:58.796463
532	550	finished	2026-02-23	\N	2026-02-23	0	4	\N	\N	\N	f	0	\N	2026-02-23 08:44:42.198184	2026-02-23 08:44:44.038949
533	551	finished	2026-02-24	\N	2026-02-24	0	4	\N	\N	\N	f	0	\N	2026-02-24 03:19:03.056365	2026-02-24 03:19:04.896769
534	548	finished	2026-02-24	\N	2026-02-24	0	4	\N	\N	\N	f	0	\N	2026-02-24 03:19:36.790783	2026-02-24 03:19:40.071777
535	552	finished	2026-02-24	\N	2026-02-24	0	3	\N	\N	\N	f	0	\N	2026-02-24 07:39:36.622183	2026-02-24 07:39:38.403712
536	534	finished	2026-02-25	\N	2026-02-25	0	4	\N	\N	\N	f	0	\N	2026-02-25 07:41:21.621834	2026-02-25 07:41:23.618539
537	553	finished	2026-02-25	\N	2026-02-25	0	4	\N	\N	\N	f	0	\N	2026-02-25 07:42:26.530708	2026-02-25 07:42:28.648209
538	554	finished	2026-02-28	\N	2026-02-28	0	4	\N	\N	\N	f	0	\N	2026-02-28 11:44:44.353584	2026-02-28 11:44:46.259775
539	555	finished	2026-02-28	\N	2026-02-28	0	4	\N	\N	\N	f	0	\N	2026-02-28 11:55:10.259794	2026-02-28 11:55:11.964154
540	556	finished	2026-02-28	\N	2026-02-28	0	5	\N	\N	\N	f	0	\N	2026-02-28 15:13:48.002875	2026-02-28 15:13:50.199704
541	557	finished	2026-02-28	\N	2026-02-28	0	3	\N	\N	\N	f	0	\N	2026-02-28 15:13:56.826706	2026-02-28 15:13:58.633395
599	609	finished	2026-04-03	\N	2026-04-03	0	4	\N	\N	\N	f	0	\N	2026-04-03 06:12:46.173698	2026-04-03 06:12:47.909819
542	532	finished	2026-03-01	\N	2026-03-01	0	4	\N	\N	\N	f	0	\N	2026-03-01 11:57:13.965558	2026-03-01 11:57:16.304586
543	530	finished	2026-03-01	\N	2026-03-01	0	4	\N	\N	\N	f	0	\N	2026-03-01 15:58:54.856807	2026-03-01 15:58:56.791534
600	591	finished	2026-04-04	\N	2026-04-04	0	4	\N	\N	\N	f	0	\N	2026-04-04 07:08:34.332164	2026-04-04 07:08:36.066775
544	558	finished	2026-03-02	\N	2026-03-02	0	3	\N	\N	\N	f	0	\N	2026-03-02 04:32:43.068716	2026-03-02 04:32:45.040602
545	190	finished	2026-03-02	\N	2026-03-02	0	4	\N	\N	\N	f	0	\N	2026-03-02 07:47:47.073169	2026-03-02 07:47:49.193116
601	585	finished	2026-04-04	\N	2026-04-04	0	4	\N	\N	\N	f	0	\N	2026-04-04 07:08:52.989522	2026-04-04 07:08:54.903984
546	559	finished	2026-03-02	\N	2026-03-02	0	4	\N	\N	\N	f	0	\N	2026-03-02 09:01:19.697344	2026-03-02 09:01:21.617212
547	230	finished	2026-03-02	\N	2026-03-02	0	4	\N	\N	\N	f	0	\N	2026-03-02 13:28:21.488395	2026-03-02 13:28:23.446756
548	180	finished	2026-03-02	\N	2026-03-02	0	4	\N	\N	\N	f	0	\N	2026-03-02 13:28:36.57396	2026-03-02 13:28:38.322616
602	610	finished	2026-04-04	\N	2026-04-04	0	4	\N	\N	\N	f	0	\N	2026-04-04 11:05:17.70314	2026-04-04 11:05:20.758658
549	560	finished	2026-03-02	\N	2026-03-02	0	4	\N	\N	\N	f	0	\N	2026-03-02 13:57:58.373642	2026-03-02 13:58:00.635842
550	399	finished	2026-03-02	\N	2026-03-02	0	4	\N	\N	\N	f	0	\N	2026-03-02 16:42:47.472585	2026-03-02 16:42:49.092044
604	611	finished	2026-04-04	\N	2026-04-04	0	4	\N	\N	\N	f	0	\N	2026-04-04 16:15:44.814697	2026-04-04 16:15:47.327572
551	232	finished	2026-03-02	\N	2026-03-02	0	4	\N	\N	\N	f	0	\N	2026-03-02 16:42:53.878336	2026-03-02 16:42:55.469553
552	561	finished	2026-03-03	\N	2026-03-03	0	4	\N	\N	\N	f	0	\N	2026-03-03 03:27:59.386769	2026-03-03 03:28:01.087164
605	612	finished	2026-04-04	\N	2026-04-04	0	4	\N	\N	\N	f	0	\N	2026-04-04 20:29:29.079146	2026-04-04 20:29:31.161817
553	562	finished	2026-03-03	\N	2026-03-03	0	3	\N	\N	\N	f	0	\N	2026-03-03 03:28:06.160432	2026-03-03 03:28:10.149181
606	613	finished	2026-04-04	\N	2026-04-04	0	5	\N	\N	\N	f	0	\N	2026-04-04 21:08:43.555377	2026-04-04 21:08:45.437214
555	563	finished	2026-03-03	\N	2026-03-03	0	4	\N	\N	\N	f	0	\N	2026-03-03 08:51:27.765847	2026-03-03 08:51:29.570024
556	564	finished	2026-03-03	\N	2026-03-03	0	4	\N	\N	\N	f	0	\N	2026-03-03 09:17:57.533964	2026-03-03 09:17:59.432024
607	614	finished	2026-04-05	\N	2026-04-05	0	4	\N	\N	\N	f	0	\N	2026-04-05 19:36:16.62316	2026-04-05 19:36:18.52428
557	531	finished	2026-03-03	\N	2026-03-03	0	4	\N	\N	\N	f	0	\N	2026-03-03 12:55:31.02968	2026-03-03 12:55:33.620192
558	489	finished	2026-03-03	\N	2026-03-03	0	4	\N	\N	\N	f	0	\N	2026-03-03 12:55:39.59631	2026-03-03 12:55:42.15942
608	593	finished	2026-04-06	\N	2026-04-06	0	4	\N	\N	\N	f	0	\N	2026-04-06 05:16:19.936766	2026-04-06 05:16:21.438421
559	392	finished	2026-03-03	\N	2026-03-03	0	4	\N	\N	\N	f	0	\N	2026-03-03 12:55:47.454469	2026-03-03 12:55:49.810522
560	533	finished	2026-03-03	\N	2026-03-03	0	4	\N	\N	\N	f	0	\N	2026-03-03 14:04:06.404432	2026-03-03 14:04:08.983495
609	615	finished	2026-04-07	\N	2026-04-07	0	5	\N	\N	\N	f	0	\N	2026-04-07 10:37:04.205368	2026-04-07 10:37:06.324434
561	565	finished	2026-03-03	\N	2026-03-03	0	4	\N	\N	\N	f	0	\N	2026-03-03 16:29:44.753564	2026-03-03 16:29:46.477854
562	566	finished	2026-03-03	\N	2026-03-03	0	4	\N	\N	\N	f	0	\N	2026-03-03 20:11:13.479657	2026-03-03 20:11:15.234635
610	616	finished	2026-04-08	\N	2026-04-08	0	4	\N	\N	\N	f	0	\N	2026-04-08 03:58:35.836044	2026-04-08 03:58:37.57335
563	567	finished	2026-03-04	\N	2026-03-04	0	4	\N	\N	\N	f	0	\N	2026-03-04 10:57:02.484193	2026-03-04 10:57:04.166873
564	568	finished	2026-03-08	\N	2026-03-08	0	4	\N	\N	\N	f	0	\N	2026-03-08 15:13:40.172485	2026-03-08 15:13:41.640564
611	617	finished	2026-04-08	\N	2026-04-08	0	4	\N	\N	\N	f	0	\N	2026-04-08 18:18:56.640035	2026-04-08 18:18:58.794693
565	569	finished	2026-03-08	\N	2026-03-08	0	4	\N	\N	\N	f	0	\N	2026-03-08 15:13:46.267404	2026-03-08 15:13:48.041339
566	570	finished	2026-03-08	\N	2026-03-08	0	5	\N	\N	\N	f	0	\N	2026-03-08 15:13:54.013372	2026-03-08 15:13:55.677648
612	596	finished	2026-04-08	\N	2026-04-08	0	3	\N	\N	\N	f	0	\N	2026-04-08 18:19:14.20346	2026-04-08 18:19:16.609755
567	571	finished	2026-03-08	\N	2026-03-08	0	5	\N	\N	\N	f	0	\N	2026-03-08 16:21:48.012063	2026-03-08 16:21:49.812323
568	572	finished	2026-03-08	\N	2026-03-08	0	4	\N	\N	\N	f	0	\N	2026-03-08 20:40:20.976567	2026-03-08 20:40:22.625411
613	618	finished	2026-04-11	\N	2026-04-11	0	4	\N	\N	\N	f	0	\N	2026-04-11 09:00:50.155241	2026-04-11 09:00:51.851425
569	573	finished	2026-03-09	\N	2026-03-09	0	4	\N	\N	\N	f	0	\N	2026-03-09 07:22:46.398461	2026-03-09 07:22:48.214502
570	574	finished	2026-03-09	\N	2026-03-09	0	4	\N	\N	\N	f	0	\N	2026-03-09 13:44:50.351697	2026-03-09 13:44:51.99855
614	619	finished	2026-04-11	\N	2026-04-11	0	4	\N	\N	\N	f	0	\N	2026-04-11 10:26:41.231184	2026-04-11 10:26:43.740612
571	575	finished	2026-03-10	\N	2026-03-10	0	4	\N	\N	\N	f	0	\N	2026-03-10 05:08:16.757079	2026-03-10 05:08:18.955062
572	576	finished	2026-03-10	\N	2026-03-10	0	4	\N	\N	\N	f	0	\N	2026-03-10 06:21:38.108388	2026-03-10 06:21:40.205437
615	620	finished	2026-04-11	\N	2026-04-11	0	4	\N	\N	\N	f	0	\N	2026-04-11 11:06:33.21353	2026-04-11 11:06:34.933213
573	577	finished	2026-03-10	\N	2026-03-10	0	4	\N	\N	\N	f	0	\N	2026-03-10 14:27:18.17695	2026-03-10 14:27:19.963021
574	578	finished	2026-03-10	\N	2026-03-10	0	4	\N	\N	\N	f	0	\N	2026-03-10 17:59:43.184129	2026-03-10 17:59:44.958549
616	595	finished	2026-04-11	\N	2026-04-11	0	4	\N	\N	\N	f	0	\N	2026-04-11 15:36:30.62186	2026-04-11 15:36:32.456509
575	580	finished	2026-03-11	\N	2026-03-11	0	5	\N	\N	\N	f	0	\N	2026-03-11 03:00:40.609326	2026-03-11 03:00:42.448026
576	581	finished	2026-03-11	\N	2026-03-11	0	4	\N	\N	\N	f	0	\N	2026-03-11 03:00:48.907358	2026-03-11 03:00:52.570545
617	621	finished	2026-04-13	\N	2026-04-13	0	5	\N	\N	\N	f	0	\N	2026-04-13 19:10:52.10362	2026-04-13 19:10:55.213918
577	579	finished	2026-03-11	\N	2026-03-11	0	4	\N	\N	\N	f	0	\N	2026-03-11 05:36:22.256762	2026-03-11 05:36:24.378215
578	582	finished	2026-03-13	\N	2026-03-13	0	5	\N	\N	\N	f	0	\N	2026-03-13 18:28:04.420758	2026-03-13 18:28:06.30012
618	622	finished	2026-04-15	\N	2026-04-15	0	4	\N	\N	\N	f	0	\N	2026-04-15 04:28:36.054363	2026-04-15 04:28:40.68887
579	586	finished	2026-03-15	\N	2026-03-15	0	4	\N	\N	\N	f	0	\N	2026-03-15 17:46:37.171466	2026-03-15 17:46:39.564075
580	587	finished	2026-03-15	\N	2026-03-15	0	4	\N	\N	\N	f	0	\N	2026-03-15 17:46:46.070833	2026-03-15 17:46:48.377489
619	623	finished	2026-04-15	\N	2026-04-15	0	4	\N	\N	\N	f	0	\N	2026-04-15 05:27:32.717548	2026-04-15 05:27:34.435483
581	583	finished	2026-03-15	\N	2026-03-15	0	4	\N	\N	\N	f	0	\N	2026-03-15 17:47:06.007631	2026-03-15 17:47:09.581228
582	597	finished	2026-03-23	\N	2026-03-23	0	5	\N	\N	\N	f	0	\N	2026-03-23 05:07:16.383752	2026-03-23 05:07:18.165528
620	624	finished	2026-04-16	\N	2026-04-16	0	4	\N	\N	\N	f	0	\N	2026-04-16 19:17:16.069666	2026-04-16 19:17:17.971172
583	599	finished	2026-03-23	\N	2026-03-23	0	5	\N	\N	\N	f	0	\N	2026-03-23 05:08:15.950071	2026-03-23 05:08:17.838276
584	588	finished	2026-03-23	\N	2026-03-23	0	4	\N	\N	\N	f	0	\N	2026-03-23 12:23:04.596686	2026-03-23 12:23:06.202736
585	600	finished	2026-03-23	\N	2026-03-23	0	4	\N	\N	\N	f	0	\N	2026-03-23 12:24:28.055068	2026-03-23 12:24:29.939517
586	601	finished	2026-03-25	\N	2026-03-25	0	4	\N	\N	\N	f	0	\N	2026-03-25 15:43:20.795132	2026-03-25 15:43:22.561417
622	584	finished	2026-04-20	\N	2026-04-20	0	4	\N	\N	\N	f	0	\N	2026-04-20 04:48:46.954796	2026-04-20 04:48:48.549463
587	603	finished	2026-03-25	\N	2026-03-25	0	4	\N	\N	\N	f	0	\N	2026-03-25 19:17:41.119496	2026-03-25 19:17:42.888189
588	598	finished	2026-03-26	\N	2026-03-26	0	4	\N	\N	\N	f	0	\N	2026-03-26 19:16:30.562226	2026-03-26 19:16:32.465642
589	594	finished	2026-03-28	\N	2026-03-28	0	4	\N	\N	\N	f	0	\N	2026-03-28 18:20:14.543341	2026-03-28 18:20:16.15321
590	592	finished	2026-03-28	\N	2026-03-28	0	4	\N	\N	\N	f	0	\N	2026-03-28 18:20:33.491309	2026-03-28 18:20:35.773918
591	604	finished	2026-04-01	\N	2026-04-01	0	4	\N	\N	\N	f	0	\N	2026-04-01 07:14:40.283808	2026-04-01 07:14:42.819055
592	602	finished	2026-04-01	\N	2026-04-01	0	4	\N	\N	\N	f	0	\N	2026-04-01 07:15:24.240196	2026-04-01 07:15:26.085577
593	605	finished	2026-04-01	\N	2026-04-01	0	5	\N	\N	\N	f	0	\N	2026-04-01 08:50:39.504574	2026-04-01 08:50:41.614774
594	606	finished	2026-04-02	\N	2026-04-02	0	4	\N	\N	\N	f	0	\N	2026-04-02 07:47:22.192727	2026-04-02 07:47:24.055982
595	607	finished	2026-04-03	\N	2026-04-03	0	4	\N	\N	\N	f	0	\N	2026-04-03 03:08:03.888276	2026-04-03 03:08:06.409896
596	589	finished	2026-04-03	\N	2026-04-03	0	2	\N	\N	\N	f	0	\N	2026-04-03 04:40:15.154333	2026-04-03 04:40:17.106528
597	590	finished	2026-04-03	\N	2026-04-03	0	4	\N	\N	\N	f	0	\N	2026-04-03 04:40:38.583241	2026-04-03 04:40:40.415163
623	626	finished	2026-04-20	\N	2026-04-20	0	4	\N	\N	\N	f	0	\N	2026-04-20 08:31:42.800118	2026-04-20 08:31:50.220734
624	627	finished	2026-04-25	\N	2026-04-25	0	4	\N	\N	\N	f	0	\N	2026-04-25 13:12:56.021002	2026-04-25 13:12:57.867835
625	629	finished	2026-05-03	\N	2026-05-03	0	4	\N	\N	\N	f	0	\N	2026-05-03 12:16:47.985443	2026-05-03 12:16:49.737328
626	630	finished	2026-05-03	\N	2026-05-03	0	4	\N	\N	\N	f	0	\N	2026-05-03 12:17:41.842491	2026-05-03 12:17:43.385802
627	631	finished	2026-05-04	\N	2026-05-04	0	4	\N	\N	\N	f	0	\N	2026-05-04 05:03:09.767125	2026-05-04 05:03:11.823699
628	632	finished	2026-05-05	\N	2026-05-05	0	2	\N	\N	\N	f	0	\N	2026-05-05 05:54:19.672063	2026-05-05 05:54:21.694168
629	633	finished	2026-05-10	\N	2026-05-10	0	5	\N	\N	\N	f	0	\N	2026-05-10 15:34:07.416744	2026-05-10 15:34:09.252164
630	634	finished	2026-05-10	\N	2026-05-10	0	4	\N	\N	\N	f	0	\N	2026-05-10 15:39:01.149605	2026-05-10 15:39:03.866853
631	635	finished	2026-05-14	\N	2026-05-14	0	4	\N	\N	\N	f	0	\N	2026-05-14 06:52:40.385131	2026-05-14 06:52:42.13527
632	636	finished	2026-05-14	\N	2026-05-14	0	4	\N	\N	\N	f	0	\N	2026-05-14 13:37:33.053706	2026-05-14 13:37:38.090272
634	637	finished	2026-05-16	\N	2026-05-16	0	4	\N	\N	\N	f	0	\N	2026-05-16 04:46:38.355784	2026-05-16 04:46:40.896047
635	638	finished	2026-05-17	\N	2026-05-17	0	4	\N	\N	\N	f	0	\N	2026-05-17 09:01:58.908436	2026-05-17 09:02:01.209593
636	639	finished	2026-05-18	\N	2026-05-18	0	4	\N	\N	\N	f	0	\N	2026-05-18 16:21:11.239838	2026-05-18 16:21:13.080339
637	640	finished	2026-05-27	\N	2026-05-27	0	5	\N	\N	\N	f	0	\N	2026-05-27 23:50:21.224106	2026-05-27 23:50:25.99733
638	641	finished	2026-05-28	\N	2026-05-28	0	4	\N	\N	\N	f	0	\N	2026-05-28 00:08:18.865119	2026-05-28 00:08:20.93612
639	642	finished	2026-05-29	\N	2026-05-29	0	4	\N	\N	\N	f	0	\N	2026-05-29 04:34:59.52324	2026-05-29 04:35:01.321196
640	643	finished	2026-05-31	\N	2026-05-31	0	4	\N	\N	\N	f	0	\N	2026-05-31 09:17:05.713332	2026-05-31 09:17:07.91475
641	674	finished	2026-05-31	\N	2026-05-31	0	5	\N	\N	\N	f	0	\N	2026-05-31 16:30:18.301716	2026-05-31 16:30:19.874797
642	675	finished	2026-05-31	\N	2026-05-31	0	4	\N	\N	\N	f	0	\N	2026-05-31 16:30:26.3761	2026-05-31 16:30:28.151348
643	654	finished	2026-06-01	\N	2026-06-01	0	3	\N	\N	\N	f	0	\N	2026-06-01 03:03:41.329345	2026-06-01 03:03:59.450643
645	673	finished	2026-06-02	\N	2026-06-02	0	4	\N	\N	\N	f	0	\N	2026-06-02 12:00:07.731259	2026-06-02 12:00:10.045186
646	650	finished	2026-06-02	\N	2026-06-02	0	3	\N	\N	\N	f	0	\N	2026-06-02 12:09:25.484005	2026-06-02 12:09:27.791023
647	680	finished	2026-06-02	\N	2026-06-02	0	4	\N	\N	\N	f	0	\N	2026-06-02 17:04:31.508275	2026-06-02 17:04:33.432415
648	644	finished	2026-06-05	\N	2026-06-05	0	4	\N	\N	\N	f	0	\N	2026-06-05 04:24:02.793082	2026-06-05 04:24:04.784868
650	663	finished	2026-06-06	\N	2026-06-06	0	4	\N	\N	\N	f	0	\N	2026-06-06 17:20:45.862138	2026-06-06 17:20:47.472776
651	662	finished	2026-06-08	\N	2026-06-08	0	4	\N	\N	\N	f	0	\N	2026-06-08 04:26:32.573712	2026-06-08 04:26:34.967372
649	658	finished	2026-06-06	\N	2026-06-08	0	3	\N	\N	\N	f	0	\N	2026-06-06 17:19:12.519233	2026-06-08 04:26:53.818137
652	653	finished	2026-06-08	\N	2026-06-08	0	3	\N	\N	\N	f	0	\N	2026-06-08 10:58:34.343088	2026-06-08 10:58:36.54211
653	682	finished	2026-06-08	\N	2026-06-08	0	4	\N	\N	\N	f	0	\N	2026-06-08 10:59:07.100128	2026-06-08 10:59:33.570148
654	704	finished	2026-06-10	\N	2026-06-10	0	4	\N	\N	\N	f	0	\N	2026-06-10 08:02:47.718207	2026-06-10 08:02:49.727634
655	655	finished	2026-06-10	\N	2026-06-10	0	4	\N	\N	\N	f	0	\N	2026-06-10 10:20:00.712397	2026-06-10 10:20:02.984959
656	683	finished	2026-06-11	\N	2026-06-11	0	4	\N	\N	\N	f	0	\N	2026-06-11 22:40:06.023393	2026-06-11 22:40:08.115066
657	706	finished	2026-06-12	\N	2026-06-12	0	5	\N	\N	\N	f	0	\N	2026-06-12 01:10:32.878738	2026-06-12 01:10:35.289766
658	661	finished	2026-06-13	\N	2026-06-13	0	4	\N	\N	\N	f	0	\N	2026-06-13 11:35:02.809186	2026-06-13 11:35:04.861893
661	652	finished	2026-06-14	\N	2026-06-14	0	3	\N	\N	\N	f	0	\N	2026-06-14 08:53:42.512256	2026-06-14 08:53:44.619625
662	648	finished	2026-06-21	\N	2026-06-21	0	4	\N	\N	\N	f	0	\N	2026-06-21 21:05:28.779116	2026-06-21 21:05:30.841075
659	649	finished	2026-06-14	\N	2026-06-21	0	4	\N	\N	\N	f	0	\N	2026-06-14 08:53:31.648948	2026-06-21 21:05:41.508305
663	646	finished	2026-06-21	\N	2026-06-21	0	4	\N	\N	\N	f	0	\N	2026-06-21 21:05:58.531055	2026-06-21 21:06:00.411958
664	684	finished	2026-06-23	\N	2026-06-23	0	4	\N	\N	\N	f	0	\N	2026-06-23 15:45:26.144536	2026-06-23 15:45:27.86742
665	685	finished	2026-06-23	\N	2026-06-23	0	5	\N	\N	\N	f	0	\N	2026-06-23 15:45:37.334621	2026-06-23 15:45:38.90122
666	669	finished	2026-06-23	\N	2026-06-23	0	4	\N	\N	\N	f	0	\N	2026-06-23 17:13:51.094651	2026-06-23 17:13:53.026928
667	703	finished	2026-06-23	\N	2026-06-23	0	4	\N	\N	\N	f	0	\N	2026-06-23 17:56:49.416597	2026-06-23 17:56:51.222791
668	660	finished	2026-06-27	\N	2026-06-27	0	5	\N	\N	\N	f	0	\N	2026-06-27 19:10:45.399991	2026-06-27 19:10:47.177209
669	707	finished	2026-06-27	\N	2026-06-27	0	4	\N	\N	\N	f	0	\N	2026-06-27 19:54:04.993308	2026-06-27 19:54:06.895829
670	739	finished	2026-06-28	\N	\N	0	\N	\N	\N	\N	f	0	\N	2026-06-28 16:13:33.455712	2026-06-28 16:13:33.455712
672	645	finished	2026-06-28	\N	2026-06-28	0	4	\N	\N	\N	f	0	\N	2026-06-28 16:14:26.709895	2026-06-28 16:14:30.571098
\.


--
-- Data for Name: reading_sessions; Type: TABLE DATA; Schema: public; Owner: default
--

COPY public.reading_sessions (session_id, book_id, session_date, pages_read, minutes_read, start_page, end_page, notes, created_at) FROM stdin;
1	189	2025-12-28	30	30	\N	\N	\N	2025-12-28 09:08:23.120487
\.


--
-- Data for Name: reading_stats; Type: TABLE DATA; Schema: public; Owner: default
--

COPY public.reading_stats (stats_id, total_books_read, total_books_dnf, total_pages_read, total_books_reading, total_books_want_to_read, average_rating, average_book_length, average_reading_days, current_reading_streak, longest_reading_streak, last_read_date, favorite_genre_id, favorite_author_id, books_read_this_year, books_read_this_month, pages_read_this_year, pages_read_this_month, created_at, updated_at) FROM stdin;
1	658	0	107695	0	0	3.92	258	1.0	0	0	2026-06-28	9	195	212	26	47615	5457	2025-12-27 06:37:09.019739	2026-06-28 16:14:30.571098
\.


--
-- Data for Name: series; Type: TABLE DATA; Schema: public; Owner: default
--

COPY public.series (series_id, title, description, total_books, status, created_at, updated_at) FROM stdin;
8	One Piece	One Piece (stylized in all caps) is a Japanese manga series written and illustrated by Eiichiro Oda. It has been serialized in Shueisha's shōnen manga magazine Weekly Shōnen Jump since July 1997, with its chapters compiled in 110 tankōbon volumes as of November 2024. 	3	ongoing	2025-01-22 17:21:58.732	2025-12-27 07:07:53.782457
3	Dune	Set on the desert planet Arrakis, Dune is the story of the boy Paul Atreides, heir to a noble family tasked with ruling an inhospitable world where the only thing of value is the “spice” melange, a drug capable of extending life and enhancing consciousness. Coveted across the known universe, melange is a prize worth killing for...	2	ongoing	2025-01-22 17:13:44.556	2025-12-27 07:07:44.022676
5	Sakamoto Days	Sakamoto Days is a Japanese manga series written and illustrated by Yuto Suzuki. It has been serialized in Shueisha's shōnen manga magazine Weekly Shōnen Jump since November 2020, with its chapters collected in 20 tankōbon volumes as of January 2025.	14	ongoing	2025-01-22 17:15:19.047	2025-12-27 07:07:51.022232
6	Percy Jackson	Percy Jackson & the Olympians is a fantasy novel series by American author Rick Riordan. The first book series in his Camp Half-Blood Chronicles, the novels are set in a world with the Greek gods in the 21st century. The series follows the protagonist, Percy Jackson, a young demigod who must prevent the Titans, led by Kronos, from destroying the world.	1	ongoing	2025-01-22 17:17:06.4	2025-12-27 07:07:51.273448
2	The Chronicles of Narnia	The Chronicles of Narnia is a series of seven portal fantasy novels by British author C. S. Lewis. Illustrated by Pauline Baynes and originally published between 1950 and 1956, the series is set in the fictional realm of Narnia, a fantasy world of magic, mythical beasts, and talking animals.	7	completed	2025-01-21 13:05:40.18	2025-12-27 07:07:43.527154
4	Naruto	Naruto is a Japanese manga series written and illustrated by Masashi Kishimoto. It tells the story of Naruto Uzumaki, a young ninja who seeks recognition from his peers and dreams of becoming the Hokage, the leader of his village.	13	ongoing	2025-01-22 17:14:51.145	2025-12-27 07:07:47.260327
7	Buddha Manga	Osamu Tezuka's vaunted storytelling genius, consummate skill at visual expression, and warm humanity blossom fully in his eight-volume epic of Siddhartha's life and times. Tezuka evidences his profound grasp of the subject by contextualizing the Buddha's ideas; the emphasis is on movement, action, emotion, and conflict as the prince Siddhartha runs away from home, travels across India, and questions Hindu practices such as ascetic self-mutilation and caste oppression. 	7	ongoing	2025-01-22 17:19:51.287	2025-12-27 07:07:53.025518
10	Untuk Negeriku	Biografi Moh Hatta	3	completed	2025-01-22 17:28:03.91	2025-12-27 07:07:55.519512
9	Monster Manga	Monster (stylized in all caps) is a Japanese manga series written and illustrated by Naoki Urasawa. It was published by Shogakukan in its seinen manga magazine Big Comic Original between December 1994 and December 2001, with its chapters collected in 18 tankōbon volumes. The story revolves around Kenzo Tenma, a Japanese surgeon living in Düsseldorf, Germany whose life enters turmoil after he gets himself involved with Johan Liebert, one of his former patients, who is revealed to be a psychopathic serial killer.	4	ongoing	2025-01-22 17:24:40.203	2025-12-27 07:07:54.7773
11	Mob Psyhco 100	What's his secret to busting ghosts while keeping prices low? Well, first, he's a fraud, and second, he pays the guy who's got the real psychic power--his student assistant Shigeo--less than minimum wage. Shigeo is an awkward but kind boy whose urge to help others and get along with them is bound up with the mental safety locks he's placed on his own emotions. Reigen knows he needs to exploit Shigeo to stay in business, yet for better or worse he's also his mentor and counselor. And he also knows whenever the normally repressed kid's emotions reach level 100, it may unleash more psychic energy than either of them can handle!	1	ongoing	2025-01-22 17:30:12.665	2025-12-27 07:07:55.834388
12	Samurai X Hokkaido Arc	Tokyo, tahun 16 Meiji. Kenshin Himura, Sang Jago Pedang, telah menggantungkan pedangnya dan hidup damai bersama istrinya, Kaoru, dan putranya, Kenji. Tapi suatu ketika, mereka menemukan selembar foto ayah Kaoru yang seharusnya sudah tewas. Foto itu pun menuntun mereka untuk berangkat ke Hokkaido. Apa yang akan menanti mereka di sana!?	1	ongoing	2025-01-22 17:31:18.009	2025-12-27 07:07:56.082185
\.


--
-- Data for Name: series_books; Type: TABLE DATA; Schema: public; Owner: default
--

COPY public.series_books (series_id, book_id, "position", is_side_story, created_at) FROM stdin;
2	233	1	f	2025-01-21 13:29:22.287
2	234	2	f	2025-01-21 13:10:27.716
2	235	3	f	2025-01-21 13:10:44.221
2	236	4	f	2025-01-21 13:11:05.726
2	237	5	f	2025-01-21 13:11:23.25
2	238	6	f	2025-01-21 13:11:42.36
2	239	7	f	2025-01-21 13:11:57.894
3	266	1	f	2025-01-22 17:14:10.799
3	290	2	f	2025-03-15 17:34:03.069
4	255	1	f	2025-01-22 17:17:26.825
4	265	2	f	2025-01-22 17:17:44.659
4	285	3	f	2025-03-21 17:20:04.1
4	294	4	f	2025-03-21 17:20:28.513
4	300	5	f	2025-03-21 17:20:48.378
4	308	6	f	2025-03-21 17:21:23.878
4	309	7	f	2025-03-21 17:22:41.516
4	310	8	f	2025-03-21 17:22:54.745
4	311	9	f	2025-03-21 17:23:07.655
4	315	10	f	2025-03-21 17:23:31.151
4	316	11	f	2025-03-21 17:23:43.175
4	317	12	f	2025-03-21 17:23:55.24
4	318	13	f	2025-03-21 17:24:05.075
5	263	1	f	2025-01-22 17:18:36.595
5	268	2	f	2025-03-21 17:27:34.85
5	270	3	f	2025-03-21 17:28:38.771
5	272	4	f	2025-03-21 17:29:14.212
5	273	5	f	2025-03-21 17:29:24.279
5	279	6	f	2025-03-21 17:29:41.004
5	281	7	f	2025-03-21 17:30:10.246
5	282	8	f	2025-03-21 17:30:23.305
5	291	9	f	2025-03-21 17:30:39.478
5	293	10	f	2025-03-21 17:33:37.464
5	295	11	f	2025-03-21 17:30:52.968
5	296	12	f	2025-03-21 17:31:39.266
5	297	13	f	2025-03-21 17:32:37.367
5	304	14	f	2025-03-21 17:32:47.075
6	262	1	f	2025-01-22 17:18:14.225
7	227	1	f	2025-01-22 17:20:23.077
7	226	2	f	2025-01-22 17:20:38.543
7	225	3	f	2025-01-22 17:20:54.328
7	224	4	f	2025-01-22 17:21:02.333
7	257	5	f	2025-01-22 17:21:14.111
7	299	6	f	2025-03-15 17:33:02.52
7	307	7	f	2025-03-21 17:19:26.431
8	250	1	f	2025-01-22 17:22:39.857
8	251	2	f	2025-01-22 17:22:47.498
8	252	3	f	2025-01-22 17:23:03.025
9	242	1	f	2025-01-22 17:24:57.355
9	241	2	f	2025-01-22 17:25:10.194
9	277	3	f	2025-03-21 17:26:49.809
9	313	4	f	2025-03-21 17:27:00.447
10	216	1	f	2025-01-22 17:28:23.704
10	217	2	f	2025-01-22 17:28:32.972
10	218	3	f	2025-01-22 17:28:41.999
11	200	1	f	2025-01-22 17:30:34.91
12	194	1	f	2025-01-22 17:31:41.197
\.


--
-- Data for Name: session; Type: TABLE DATA; Schema: public; Owner: default
--

COPY public.session (id, expires_at, token, created_at, updated_at, ip_address, user_agent, user_id) FROM stdin;
gbXise3vTFDVJpisyjEs7ZwPsBolDnj2	2026-01-03 07:26:55.537	uWAnpo7w4M6dmvdsLAgoypmlbuXeKQtZ	2025-12-27 07:26:55.538	2025-12-27 07:26:55.538	::1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	x7AQqtCDmNVKBeH3KgWXOluUdZyQKYUI
J67GyPhwY4sC3G7CdbUe1FR5fbqcJOhe	2026-01-03 07:27:06.833	N8ZwnEIvDrQf9ZGqwg4hFFAo1s9q29Bk	2025-12-27 07:27:06.833	2025-12-27 07:27:06.833	::1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	x7AQqtCDmNVKBeH3KgWXOluUdZyQKYUI
mn70OBz3UC821Go9CEsEFgwVE40nwfap	2026-01-04 05:52:55.345	bKVI0RZhe0oEtyrJgByopoBvbGP8pSq8	2025-12-28 05:52:55.345	2025-12-28 05:52:55.345	::1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
c0BmeudBerU246l2ItcFP9FqscnuXgC7	2026-01-04 05:52:59.9	8M45Au0mqFDRhH3XIBhiHfJUcdjbBcGF	2025-12-28 05:52:59.901	2025-12-28 05:52:59.901	::1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
cXz7Gatts3bcrjFGrLwNH3dh3Ym0xrJ1	2026-01-04 08:27:20.408	vrwy6tOfet23oHe6zbssj8kFH5yhM7VL	2025-12-28 08:27:20.411	2025-12-28 08:27:20.411	104.28.241.32	Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.2 Mobile/15E148 Safari/604.1	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
3UemY7piSzbyU2kMbf59ptN2gc3hS8qW	2026-01-04 11:34:41.782	62wQwjEHtlJRBV3uW8mbufLWgExTEU4l	2025-12-28 11:34:41.783	2025-12-28 11:34:41.783	::1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
cKbv5fMHTps04zHJQ956Bvre7Bqb1qLh	2026-01-08 08:08:59.853	CmRv5hgi4ymhNKepofTkU6e6UNpLF58c	2025-12-28 07:24:46.422	2026-01-01 08:08:59.853	180.245.126.155	Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Mobile Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
q13nCUaFtuuBsCW2SqOohsvftEmVsZ8c	2026-01-09 19:03:01.884	P3ZESOzMyjXARn64KRyQ96ly3MsA8JKE	2025-12-28 07:32:48.411	2026-01-02 19:03:01.884	104.28.250.136	Mozilla/5.0 (iPhone; CPU iPhone OS 26_2_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/143.0.7499.151 Mobile/15E148 Safari/604.1	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
IulzTSoffg7mxUqOOZwb5bXK7u3Aa23l	2026-02-14 06:47:05.44	gNyjwLmkDc0sROit4q9gaExMfMx13u5t	2026-02-01 10:37:54.301	2026-02-07 06:47:05.44	180.245.218.102	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
3KFlXYrVcovwam2mXhDjDRw41FT9ULdQ	2026-01-16 12:02:13.306	i2axGB0m6QhqnTOt5yrZ2J9hSKZ47pb2	2026-01-04 15:05:38.079	2026-01-09 12:02:13.306	104.28.218.136	Mozilla/5.0 (iPhone; CPU iPhone OS 26_2_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/143.0.7499.151 Mobile/15E148 Safari/604.1	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
3DgrrDq2PHkWrqUSmaW9hVAUcQYMGfro	2026-02-14 15:54:05.562	a1nqwthVli4VGCGZmVSojhEDp0IeE7bI	2026-02-01 01:26:43.412	2026-02-07 15:54:05.562	104.28.209.32	Mozilla/5.0 (iPhone; CPU iPhone OS 26_2_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/144.0.7559.95 Mobile/15E148 Safari/604.1	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
50CkzlwjgxuIxdKiVyttzE4Wb4PqQvkc	2026-03-02 08:41:06.759	qwr5YIAbDGvEEe0qmq7b1PP9miN1eUWG	2026-02-19 08:58:27.982	2026-02-23 08:41:06.759	182.10.161.229	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
G1Qa9JmSeqr0yZoI3RPyyKDiOaW0xuOr	2026-01-21 16:15:18.189	ClFxrzVmGox4YDn9oRBDNp6B2BWnL3o3	2026-01-09 03:39:55.98	2026-01-14 16:15:18.189	182.10.161.236	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
dlEPM0NxFoYRakIzYinRAKvoQ8dBDx6N	2026-01-23 04:28:23.908	13jddyB7kGKUavETMXXHPTIcVIb2YIyy	2026-01-16 04:28:23.911	2026-01-16 04:28:23.911	182.10.161.218	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.2 Safari/605.1.15	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
p7gAJUtPdZ4StgTnbxFHcqli21Hv0UB9	2026-02-03 11:54:43.842	4eV7fLxJlx4opQkOKB2hKUpjHeaGusg1	2026-01-25 04:18:08.043	2026-01-27 11:54:43.842	182.10.161.184	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
KpdKdBhn1g8vJR6YzPRodik84fBGBn8J	2026-01-24 14:37:24.556	9eHOi9mwASFgIUvAofnYYuLXxz1NkTix	2026-01-17 14:37:24.558	2026-01-17 14:37:24.558	182.10.161.99	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
EL9m6ilwUnBMBLX58TBsM9yxRIuR8JuJ	2026-01-25 11:12:30.594	lbHj4m6Ci49IYPEQnHHeeentbngfNjNS	2026-01-12 07:30:10.805	2026-01-18 11:12:30.594	104.28.209.32	Mozilla/5.0 (iPhone; CPU iPhone OS 26_2_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/143.0.7499.151 Mobile/15E148 Safari/604.1	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
6iL7nvy80bW7VwcDB3KgIlEGQDRB2qO3	2026-02-03 16:14:40.298	SR1bXJeFsjg3cXPfwHGPnz3GMDHUItyN	2026-01-22 06:07:58.423	2026-01-27 16:14:40.298	114.122.72.15	Mozilla/5.0 (iPhone; CPU iPhone OS 26_2_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/144.0.7559.85 Mobile/15E148 Safari/604.1	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
Z2qlKRGrUyYUDdcVuYagNIiALWF7oCrx	2026-02-09 04:28:49.881	aVpjwKFSVGFcf9XDY8fZL8jA6G35eNxH	2026-02-02 04:28:49.883	2026-02-02 04:28:49.883	182.10.161.108	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.2 Safari/605.1.15	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
tLt4zhxWe4BEvSOXZgVXo2IBPsZwcg8G	2026-02-13 02:41:01.41	6Ah5j9yyee9pAAz8r3zNcIPh4OZFM6LR	2026-01-31 18:43:25.821	2026-02-06 02:41:01.41	104.28.218.135	Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.2 Mobile/15E148 Safari/604.1	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
vMeHnM7pwHCa1QWcWkhcfUqV0ZLJrIDC	2026-02-15 11:24:41.854	j1aguaWOZ2a4dz61pV2iz7nzEoGZof2z	2026-02-08 11:24:41.857	2026-02-08 11:24:41.857	172.225.78.196	Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.2 Mobile/15E148 Safari/604.1	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
2Jhxco4cBWXXbt4fywqMEnyXuwj0RU7a	2026-02-21 14:46:58.736	ve5RevIl8GwmvPgU8zWeHAK3tK5Fz0RK	2026-02-08 04:35:01.994	2026-02-14 14:46:58.736	182.10.161.129	Mozilla/5.0 (iPhone; CPU iPhone OS 26_2_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/144.0.7559.95 Mobile/15E148 Safari/604.1	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
DeHNebQy7zq2SKLVW6diF0w8OePYu5lJ	2026-02-24 09:31:31.511	7E9W58aTdJOP7qTGFYty7s4bkyKw6yXA	2026-02-17 09:31:31.513	2026-02-17 09:31:31.513	104.28.118.53	Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.2 Mobile/15E148 Safari/604.1	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
txeaE39Ew3u4jVmPZw9aZgTrzpsopy98	2026-02-24 09:59:28.544	6Ouy5zsorrM2oN3Ig2SXw3dFJZlGGYC2	2026-02-11 04:36:42.223	2026-02-17 09:59:28.544	182.10.161.124	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
Qd7mZLyeLOcAXxfeIz7exS47nrmZ6iK9	2026-05-24 08:59:36.067	9iZqyiKWZKwuGPNXvHbuKMPSSWNXrv9v	2026-05-14 06:50:41.689	2026-05-17 08:59:36.067	182.10.161.117	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
faE5LMAg2ICCMUrP6a3F069IuinkEYTq	2026-02-27 01:40:31.195	9d3l5NjB6uxwfjXz1aR9j9LaZKulFAas	2026-02-15 09:04:59.773	2026-02-20 01:40:31.195	182.10.161.186	Mozilla/5.0 (iPhone; CPU iPhone OS 26_2_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/144.0.7559.95 Mobile/15E148 Safari/604.1	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
l10uOgSBDmvNXIXNuZRtBnNvkQ7tFhEL	2026-04-22 04:27:49.783	Bd53F3HDevtRdypUfSjQgJ1dnVnkjY5o	2026-04-08 18:17:40.955	2026-04-15 04:27:49.783	182.10.161.59	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Mobile Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
menUiMdcIvE8z8OapNUz05x4jZ0odfYl	2026-04-12 08:03:17.123	xeM5z18ZhaYMLAKSF8yK3P3iEHgkQJ9A	2026-04-04 07:08:15.574	2026-04-05 08:03:17.123	140.213.106.238	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
SAPb6vWKeBTTz0xgfwzEFC0phsnZNTkS	2026-04-01 19:16:10.957	de9tM7RRj6lt8GEkyrzx2DYv4FJ7cpqA	2026-03-19 17:26:44.4	2026-03-25 19:16:10.957	182.10.161.122	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Mobile Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
rVfZj611dZtdAyYW5WaRnnFg6WcCO612	2026-04-02 19:16:14.08	lxHrq6tEIN1TX06LhtFhj8AfWheOHoFG	2026-03-19 19:29:48.808	2026-03-26 19:16:14.08	104.28.163.40	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
xTdGByIo7tiiFSTcdd9Q3Ay8osPYxUlO	2026-03-10 16:27:11.884	VhqZVW9HIij0WTjp5C4GGw95sPGqLPwC	2026-03-03 16:27:11.886	2026-03-03 16:27:11.886	182.10.161.132	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
EF4YNyc6zQJYDNWt1pdlrzWuHvTBRSto	2026-03-10 17:38:23.16	boDBZrWHbWkO4IQbbhVahPKMPEbuib8E	2026-02-25 07:40:50.222	2026-03-03 17:38:23.16	182.10.161.198	Mozilla/5.0 (iPhone; CPU iPhone OS 26_3_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/145.0.7632.108 Mobile/15E148 Safari/604.1	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
OxKiEi0OfTdxxLhy6fEcXfvKOau0wpfw	2026-03-13 03:04:13.569	XmOwSLUEqg6AZanhypv50XFKMst9Ggb6	2026-02-28 11:43:00.269	2026-03-06 03:04:13.569	180.245.222.78	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
QtcD7cJRhdFrLeGvKyBfjKimXuNh6F2l	2026-04-04 18:19:58.755	XdA4007cbHQaB0f0x6HNlZ9oNmQNTba7	2026-03-28 18:19:58.758	2026-03-28 18:19:58.758	104.28.156.114	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
NnZG9R3FfrMhGWNJUTXiftpmRWaJP8HH	2026-03-17 10:01:23.031	3ZbvefRaBUXsNPWZ2ObdCCIVrCsWnzoT	2026-03-06 19:06:35.147	2026-03-10 10:01:23.031	104.28.163.14	Mozilla/5.0 (iPhone; CPU iPhone OS 26_3_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/145.0.7632.108 Mobile/15E148 Safari/604.1	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
AGLEG7jbagBe370eCHg9feU1CKix3GeH	2026-03-20 18:27:45.605	QHoaYnKzISA45esb9EjOGaIpW8PYzxlf	2026-03-08 15:08:09.169	2026-03-13 18:27:45.605	182.10.161.132	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
iwia6oYK8mKm8YWiHBJEIYhfzPZlvsF8	2026-03-22 17:44:29.401	QzC3qJ7NGpuaoCf6vVhDsEjRM07YyU0x	2026-03-11 16:06:24.453	2026-03-15 17:44:29.401	182.10.161.95	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
fzL4Uanw1ri8T8UTETs5D3CXEpmnsGj3	2026-04-05 20:50:05.77	ojMU2M04lguzhQ7bPNYpqawzY1mVvdUU	2026-03-23 12:22:44.463	2026-03-29 20:50:05.77	104.28.166.112	Mozilla/5.0 (iPhone; CPU iPhone OS 26_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/146.0.7680.151 Mobile/15E148 Safari/604.1	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
RdxSiduYl0ScZ1aOaT6S23lROhdThole	2026-03-27 21:58:12.301	P2tquynEF4bbt0IriDnrrQQjjoHj76Oi	2026-03-15 17:43:48.905	2026-03-20 21:58:12.301	104.28.159.63	Mozilla/5.0 (iPhone; CPU iPhone OS 26_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/145.0.7632.108 Mobile/15E148 Safari/604.1	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
rIcr23VpthslCxVU6dxLXhmPGHIWXvhf	2026-04-08 07:13:50.369	PwaKOXmBGdJlytb9b1TwxxYwhvBqK01T	2026-04-01 07:13:50.372	2026-04-01 07:13:50.372	182.10.161.180	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Mobile Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
7mToTkJiUDmOxr4Ki8CkL6a7X9fbyq29	2026-04-27 04:47:47.205	DTz7DONc76WnV6rY2FhrQ1m7ewmD8vV7	2026-04-16 04:25:51.221	2026-04-20 04:47:47.205	182.10.161.248	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Mobile Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
qOUwzi8YcWoWUMZePiq9pcKbHFqhgfi5	2026-04-19 17:50:49.477	eyZw4S7JpXOu4FRsh2iicFULwgR5TlHh	2026-04-09 07:10:12.531	2026-04-12 17:50:49.477	140.213.38.60	Mozilla/5.0 (iPhone; CPU iPhone OS 26_4_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/146.0.7680.151 Mobile/15E148 Safari/604.1	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
F2VdEu1Yz0CMXv37TOhiwY9QW8K2xsbb	2026-05-02 13:10:04.389	1BY5BXWRLKAXQ9J3XE8YHGjKsuvNxXZh	2026-04-25 13:10:04.391	2026-04-25 13:10:04.391	182.10.161.196	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
7V2TGmuHgzqQwV6HuXtZcxHhoZErER9b	2026-04-14 10:00:01.871	cUQBjd2aRVl8O1NdAo2YyRo8PRxCkCrq	2026-03-31 20:32:54.796	2026-04-07 10:00:01.871	104.28.156.137	Mozilla/5.0 (iPhone; CPU iPhone OS 26_4_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/146.0.7680.151 Mobile/15E148 Safari/604.1	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
S81VQ3rEcYJabcScxJFV1LaFrNFgsBZA	2026-04-14 10:36:27.526	lUHDsRFlInDiSJcIl6jhyOlBkQVwWKbM	2026-04-01 07:13:52.501	2026-04-07 10:36:27.526	182.10.161.180	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Mobile Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
JDoxNCw8rfIAOK3tvSuh6yppHFalF3a1	2026-04-27 12:03:13.991	mhel7RZ1D1i9fVDMV6R9v2jy3gQ8SoMt	2026-04-13 19:21:55.48	2026-04-20 12:03:13.991	182.10.161.172	Mozilla/5.0 (iPhone; CPU iPhone OS 26_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/147.0.7727.47 Mobile/15E148 Safari/604.1	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
nvnCeKZVxeWrsxzS8yIs7eoc7ZIY0hrt	2026-05-01 19:16:59.997	nkoL6f4IX1uZLZWdqwtQuVtSEOILoOV9	2026-04-24 19:16:59.999	2026-04-24 19:16:59.999	182.10.161.196	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Mobile Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
EemAve5d1jIJlm0ttBZykc6GDQIeLYC6	2026-05-12 05:53:34.485	byABl0fBhHl0HzWlWLjwg9qCdRvCXCgV	2026-05-03 12:15:25.779	2026-05-05 05:53:34.485	180.245.126.119	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
x92mpwZsxiOuZzpNlSYCCfPtfINrbagW	2026-05-16 10:12:04.864	gxkyNGRlovocjO86nyGXVR9kxQh5tSE8	2026-05-09 10:12:04.866	2026-05-09 10:12:04.866	125.166.63.101	Mozilla/5.0 (iPhone; CPU iPhone OS 26_4_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/148.0.7778.100 Mobile/15E148 Safari/604.1	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
RSVvq7ra4iDei6gBvVXZ44Jin8z7l5It	2026-05-17 15:33:15.264	BNywRRUrcDRKQudbjJ5zaDRhODcDvdc4	2026-05-04 04:53:52.122	2026-05-10 15:33:15.264	182.10.161.183	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Mobile Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
ID6icclQvKEpKZj6ZLST8wZbEhAbsmvP	2026-05-31 11:46:53.705	SOC17HtUEs2joRUtvqkU4qjzXk4nfvLl	2026-05-18 16:19:05.168	2026-05-24 11:46:53.705	104.28.159.127	Mozilla/5.0 (iPhone; CPU iPhone OS 26_4_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/148.0.7778.166 Mobile/15E148 Safari/604.1	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
3KcqPoOneemXdgCmEpGXcNZgI66D9HNu	2026-06-03 23:48:22.579	FcwJyanJvqlyjRFOnFJegljYmqckatnR	2026-05-27 23:48:22.581	2026-05-27 23:48:22.581	182.10.161.180	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
As1IWZ5Crkf7uTM0yAqCwqhWrXhgYTFZ	2026-06-21 05:30:11.242	x3MKaKj7U5tslKwtOmb1jPH6prK8mrku	2026-06-14 05:30:11.244	2026-06-14 05:30:11.244	182.10.161.111	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Mobile Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
67ae2EN8MhkshCMcwNdksR4zuZfUrU4z	2026-06-22 12:08:10.913	X4ZfOa6xEvuY6eWsp5PouQVc6kzwMM3Z	2026-06-15 12:08:10.916	2026-06-15 12:08:10.916	182.10.161.111	Mozilla/5.0 (iPhone; CPU iPhone OS 26_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/149.0.7827.137 Mobile/15E148 Safari/604.1	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
RbHjuTfrMV4rBVjsb1Cj64ks9WXr15fW	2026-06-07 15:10:08.838	xUobTxcJ9Ena6SdVaGlkMQl2bCWNNLY4	2026-05-31 15:10:08.84	2026-05-31 15:10:08.84	182.10.183.10	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
dc9TKkFw9r9OKrQlIq6HK0IsP73ueKMu	2026-06-07 15:19:26.07	xCeXpgvUCfrO87OW0TeUB9ZzIwafHr3Q	2026-05-31 15:19:26.071	2026-05-31 15:19:26.071	::1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
YwrMPef8qKjjNHNXPRCtYdEw3fzznsJ2	2026-06-07 15:29:40.139	n78wdfh90izscDddnppfrO6BaUPIRcRs	2026-05-27 23:48:29.416	2026-05-31 15:29:40.139	182.10.161.180	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
eTDmaXjiPSDDed9MbP1LWEFYnn60NB6G	2026-06-11 18:15:15.04	6GHaPlhXiP4DCkqsJsCk4h0L8CWsJiSC	2026-06-04 18:15:15.042	2026-06-04 18:15:15.042	182.10.161.88	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Mobile Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
qCf4cf0dTOgUy4uFU5PJ4vkfdDAzYIhd	2026-06-11 18:27:24.538	BH2WoPtMGsuRMqQ1mB0vSdKINRjSdtt9	2026-05-29 10:01:21.276	2026-06-04 18:27:24.538	114.122.109.74	Mozilla/5.0 (iPhone; CPU iPhone OS 26_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/148.0.7778.166 Mobile/15E148 Safari/604.1	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
1McMiRrYlxrerWB1f0alELnSrWOenNaq	2026-06-13 17:18:45.452	zQEUfrv5qFvB36A0xToVMZdUUl5PUkyJ	2026-06-01 03:30:47.707	2026-06-06 17:18:45.452	182.10.183.10	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
FzQ60P23h7fWzZbaM8OC8yxvcIi9yaz9	2026-07-04 19:09:41.099	hU4crLeVoyw6u9RLguafbQtgWt1KUcRL	2026-06-21 21:04:34.934	2026-06-27 19:09:41.099	104.28.159.45	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
LsT2Irl7JIvFZpOCFMb1ZffuA6Z8vNDa	2026-07-04 19:52:52.399	s4DlRgk0czei5RDN7B2KhAO2HaVHLIHh	2026-06-27 19:52:52.401	2026-06-27 19:52:52.401	::1	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
KrubeSC3Kd64gQimLvTjnY8Ay9XrBhZS	2026-07-05 15:18:46.624	tRgUn8URtDhUm9SsKPK1uaaSP0lruX9C	2026-06-28 15:18:46.627	2026-06-28 15:18:46.627	182.10.161.101	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Mobile Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
NJO25XBENUf9SloCqLgNpGOTGn4OhDy2	2026-06-20 11:34:40.634	x1wmWJos5mTh9PwjjAj9aRySCszcrbjY	2026-06-08 04:25:40.533	2026-06-13 11:34:40.634	182.10.161.88	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
nWSgQsBgD0yE3ASeYCNpQGEjjYwTTGPW	2026-06-21 04:17:04.195	102dLItCsyMK4RgQfAYZmoRtAjyxmFMP	2026-06-08 10:58:13.976	2026-06-14 04:17:04.195	182.10.161.88	Mozilla/5.0 (iPhone; CPU iPhone OS 26_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/149.0.7827.45 Mobile/15E148 Safari/604.1	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
L3RQdcClroXZz3xdDN8nJ8HuxcBOH3Ao	2026-07-05 15:25:37.882	fiRdpNwP6D7QoF9eCUDRVnpeNe7ZbYat	2026-06-23 15:44:56.022	2026-06-28 15:25:37.882	182.10.183.39	Mozilla/5.0 (iPhone; CPU iPhone OS 26_5_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/149.0.7827.137 Mobile/15E148 Safari/604.1	QPxsNolOyPUfFobN4evEzjZGD45lYM8p
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: default
--

COPY public.users (id, name, email, email_verified, image, created_at, updated_at) FROM stdin;
x7AQqtCDmNVKBeH3KgWXOluUdZyQKYUI	hermansh.repo	hermansh.repo@gmail.com	f	\N	2025-12-27 07:26:54.003	2025-12-27 07:26:54.003
QPxsNolOyPUfFobN4evEzjZGD45lYM8p	hermansh.id	hermansh.id@gmail.com	f	\N	2025-12-28 05:52:54.284	2025-12-28 05:52:54.284
\.


--
-- Data for Name: verification; Type: TABLE DATA; Schema: public; Owner: default
--

COPY public.verification (id, identifier, value, expires_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: yearly_stats; Type: TABLE DATA; Schema: public; Owner: default
--

COPY public.yearly_stats (year_id, year, books_read, pages_read, average_rating, top_genre_id, top_author_id, longest_book_id, shortest_book_id, highest_rated_book_id, created_at, updated_at) FROM stdin;
444	2025	356	60025	3.90	9	195	248	386	467	2025-12-28 11:18:05.996505	2025-12-28 11:18:30.463906
447	2026	212	47615	3.94	9	294	189	565	660	2026-01-02 19:03:30.747076	2026-06-28 16:14:30.571098
\.


--
-- Name: authors_author_id_seq; Type: SEQUENCE SET; Schema: public; Owner: default
--

SELECT pg_catalog.setval('public.authors_author_id_seq', 453, true);


--
-- Name: book_quotes_quote_id_seq; Type: SEQUENCE SET; Schema: public; Owner: default
--

SELECT pg_catalog.setval('public.book_quotes_quote_id_seq', 1, true);


--
-- Name: books_book_id_seq; Type: SEQUENCE SET; Schema: public; Owner: default
--

SELECT pg_catalog.setval('public.books_book_id_seq', 744, true);


--
-- Name: genres_genre_id_seq; Type: SEQUENCE SET; Schema: public; Owner: default
--

SELECT pg_catalog.setval('public.genres_genre_id_seq', 30, true);


--
-- Name: monthly_stats_month_id_seq; Type: SEQUENCE SET; Schema: public; Owner: default
--

SELECT pg_catalog.setval('public.monthly_stats_month_id_seq', 665, true);


--
-- Name: reading_goals_goal_id_seq; Type: SEQUENCE SET; Schema: public; Owner: default
--

SELECT pg_catalog.setval('public.reading_goals_goal_id_seq', 2, true);


--
-- Name: reading_log_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: default
--

SELECT pg_catalog.setval('public.reading_log_log_id_seq', 672, true);


--
-- Name: reading_sessions_session_id_seq; Type: SEQUENCE SET; Schema: public; Owner: default
--

SELECT pg_catalog.setval('public.reading_sessions_session_id_seq', 1, true);


--
-- Name: reading_stats_stats_id_seq; Type: SEQUENCE SET; Schema: public; Owner: default
--

SELECT pg_catalog.setval('public.reading_stats_stats_id_seq', 1, false);


--
-- Name: series_series_id_seq; Type: SEQUENCE SET; Schema: public; Owner: default
--

SELECT pg_catalog.setval('public.series_series_id_seq', 12, true);


--
-- Name: yearly_stats_year_id_seq; Type: SEQUENCE SET; Schema: public; Owner: default
--

SELECT pg_catalog.setval('public.yearly_stats_year_id_seq', 665, true);


--
-- Name: account account_pkey; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.account
    ADD CONSTRAINT account_pkey PRIMARY KEY (id);


--
-- Name: authors authors_name_unique; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.authors
    ADD CONSTRAINT authors_name_unique UNIQUE (name);


--
-- Name: authors authors_pkey; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.authors
    ADD CONSTRAINT authors_pkey PRIMARY KEY (author_id);


--
-- Name: book_authors book_authors_book_id_author_id_pk; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.book_authors
    ADD CONSTRAINT book_authors_book_id_author_id_pk PRIMARY KEY (book_id, author_id);


--
-- Name: book_genres book_genres_book_id_genre_id_pk; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.book_genres
    ADD CONSTRAINT book_genres_book_id_genre_id_pk PRIMARY KEY (book_id, genre_id);


--
-- Name: book_quotes book_quotes_pkey; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.book_quotes
    ADD CONSTRAINT book_quotes_pkey PRIMARY KEY (quote_id);


--
-- Name: books books_pkey; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_pkey PRIMARY KEY (book_id);


--
-- Name: genres genres_genre_name_unique; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.genres
    ADD CONSTRAINT genres_genre_name_unique UNIQUE (genre_name);


--
-- Name: genres genres_pkey; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.genres
    ADD CONSTRAINT genres_pkey PRIMARY KEY (genre_id);


--
-- Name: goodreads_data goodreads_data_pkey; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.goodreads_data
    ADD CONSTRAINT goodreads_data_pkey PRIMARY KEY (book_id);


--
-- Name: monthly_stats monthly_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.monthly_stats
    ADD CONSTRAINT monthly_stats_pkey PRIMARY KEY (month_id);


--
-- Name: monthly_stats monthly_stats_year_month_key; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.monthly_stats
    ADD CONSTRAINT monthly_stats_year_month_key UNIQUE (year, month);


--
-- Name: reading_goals reading_goals_pkey; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.reading_goals
    ADD CONSTRAINT reading_goals_pkey PRIMARY KEY (goal_id);


--
-- Name: reading_log reading_log_pkey; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.reading_log
    ADD CONSTRAINT reading_log_pkey PRIMARY KEY (log_id);


--
-- Name: reading_sessions reading_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.reading_sessions
    ADD CONSTRAINT reading_sessions_pkey PRIMARY KEY (session_id);


--
-- Name: reading_stats reading_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.reading_stats
    ADD CONSTRAINT reading_stats_pkey PRIMARY KEY (stats_id);


--
-- Name: series_books series_books_series_id_book_id_pk; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.series_books
    ADD CONSTRAINT series_books_series_id_book_id_pk PRIMARY KEY (series_id, book_id);


--
-- Name: series series_pkey; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.series
    ADD CONSTRAINT series_pkey PRIMARY KEY (series_id);


--
-- Name: session session_pkey; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT session_pkey PRIMARY KEY (id);


--
-- Name: session session_token_unique; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT session_token_unique UNIQUE (token);


--
-- Name: reading_log unique_book_log; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.reading_log
    ADD CONSTRAINT unique_book_log UNIQUE (book_id);


--
-- Name: reading_goals unique_year_goal; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.reading_goals
    ADD CONSTRAINT unique_year_goal UNIQUE (year);


--
-- Name: users users_email_unique; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_unique UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: verification verification_pkey; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.verification
    ADD CONSTRAINT verification_pkey PRIMARY KEY (id);


--
-- Name: yearly_stats yearly_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.yearly_stats
    ADD CONSTRAINT yearly_stats_pkey PRIMARY KEY (year_id);


--
-- Name: yearly_stats yearly_stats_year_key; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.yearly_stats
    ADD CONSTRAINT yearly_stats_year_key UNIQUE (year);


--
-- Name: yearly_stats yearly_stats_year_unique; Type: CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.yearly_stats
    ADD CONSTRAINT yearly_stats_year_unique UNIQUE (year);


--
-- Name: idx_authors_name; Type: INDEX; Schema: public; Owner: default
--

CREATE INDEX idx_authors_name ON public.authors USING btree (name);


--
-- Name: idx_book_authors_author; Type: INDEX; Schema: public; Owner: default
--

CREATE INDEX idx_book_authors_author ON public.book_authors USING btree (author_id);


--
-- Name: idx_book_authors_book; Type: INDEX; Schema: public; Owner: default
--

CREATE INDEX idx_book_authors_book ON public.book_authors USING btree (book_id);


--
-- Name: idx_book_genres_book; Type: INDEX; Schema: public; Owner: default
--

CREATE INDEX idx_book_genres_book ON public.book_genres USING btree (book_id);


--
-- Name: idx_book_genres_genre; Type: INDEX; Schema: public; Owner: default
--

CREATE INDEX idx_book_genres_genre ON public.book_genres USING btree (genre_id);


--
-- Name: idx_book_quotes_book; Type: INDEX; Schema: public; Owner: default
--

CREATE INDEX idx_book_quotes_book ON public.book_quotes USING btree (book_id);


--
-- Name: idx_book_quotes_created; Type: INDEX; Schema: public; Owner: default
--

CREATE INDEX idx_book_quotes_created ON public.book_quotes USING btree (created_at);


--
-- Name: idx_book_quotes_favorite; Type: INDEX; Schema: public; Owner: default
--

CREATE INDEX idx_book_quotes_favorite ON public.book_quotes USING btree (is_favorite);


--
-- Name: idx_books_isbn; Type: INDEX; Schema: public; Owner: default
--

CREATE INDEX idx_books_isbn ON public.books USING btree (isbn);


--
-- Name: idx_books_title; Type: INDEX; Schema: public; Owner: default
--

CREATE INDEX idx_books_title ON public.books USING btree (title);


--
-- Name: idx_books_year; Type: INDEX; Schema: public; Owner: default
--

CREATE INDEX idx_books_year ON public.books USING btree (year);


--
-- Name: idx_reading_log_date_finished; Type: INDEX; Schema: public; Owner: default
--

CREATE INDEX idx_reading_log_date_finished ON public.reading_log USING btree (date_finished);


--
-- Name: idx_reading_log_date_started; Type: INDEX; Schema: public; Owner: default
--

CREATE INDEX idx_reading_log_date_started ON public.reading_log USING btree (date_started);


--
-- Name: idx_reading_log_rating; Type: INDEX; Schema: public; Owner: default
--

CREATE INDEX idx_reading_log_rating ON public.reading_log USING btree (rating);


--
-- Name: idx_reading_log_status; Type: INDEX; Schema: public; Owner: default
--

CREATE INDEX idx_reading_log_status ON public.reading_log USING btree (status);


--
-- Name: idx_reading_sessions_book; Type: INDEX; Schema: public; Owner: default
--

CREATE INDEX idx_reading_sessions_book ON public.reading_sessions USING btree (book_id);


--
-- Name: idx_reading_sessions_date; Type: INDEX; Schema: public; Owner: default
--

CREATE INDEX idx_reading_sessions_date ON public.reading_sessions USING btree (session_date);


--
-- Name: idx_series_books_book; Type: INDEX; Schema: public; Owner: default
--

CREATE INDEX idx_series_books_book ON public.series_books USING btree (book_id);


--
-- Name: idx_series_books_position; Type: INDEX; Schema: public; Owner: default
--

CREATE INDEX idx_series_books_position ON public.series_books USING btree ("position");


--
-- Name: idx_series_books_series; Type: INDEX; Schema: public; Owner: default
--

CREATE INDEX idx_series_books_series ON public.series_books USING btree (series_id);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: default
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: reading_log trigger_update_monthly_stats; Type: TRIGGER; Schema: public; Owner: default
--

CREATE TRIGGER trigger_update_monthly_stats AFTER INSERT OR UPDATE ON public.reading_log FOR EACH ROW EXECUTE FUNCTION public.update_monthly_stats();


--
-- Name: reading_log trigger_update_reading_days; Type: TRIGGER; Schema: public; Owner: default
--

CREATE TRIGGER trigger_update_reading_days BEFORE INSERT OR UPDATE ON public.reading_log FOR EACH ROW EXECUTE FUNCTION public.update_reading_days();


--
-- Name: reading_log trigger_update_reading_stats; Type: TRIGGER; Schema: public; Owner: default
--

CREATE TRIGGER trigger_update_reading_stats AFTER INSERT OR DELETE OR UPDATE ON public.reading_log FOR EACH STATEMENT EXECUTE FUNCTION public.update_reading_stats();


--
-- Name: series_books trigger_update_series_books_delete; Type: TRIGGER; Schema: public; Owner: default
--

CREATE TRIGGER trigger_update_series_books_delete AFTER DELETE ON public.series_books FOR EACH ROW EXECUTE FUNCTION public.update_series_total_books();


--
-- Name: series_books trigger_update_series_books_insert; Type: TRIGGER; Schema: public; Owner: default
--

CREATE TRIGGER trigger_update_series_books_insert AFTER INSERT ON public.series_books FOR EACH ROW EXECUTE FUNCTION public.update_series_total_books();


--
-- Name: reading_log trigger_update_yearly_stats; Type: TRIGGER; Schema: public; Owner: default
--

CREATE TRIGGER trigger_update_yearly_stats AFTER INSERT OR UPDATE ON public.reading_log FOR EACH ROW EXECUTE FUNCTION public.update_yearly_stats();


--
-- Name: account account_user_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.account
    ADD CONSTRAINT account_user_id_users_id_fk FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: book_authors book_authors_author_id_authors_author_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.book_authors
    ADD CONSTRAINT book_authors_author_id_authors_author_id_fk FOREIGN KEY (author_id) REFERENCES public.authors(author_id) ON DELETE CASCADE;


--
-- Name: book_authors book_authors_book_id_books_book_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.book_authors
    ADD CONSTRAINT book_authors_book_id_books_book_id_fk FOREIGN KEY (book_id) REFERENCES public.books(book_id) ON DELETE CASCADE;


--
-- Name: book_genres book_genres_book_id_books_book_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.book_genres
    ADD CONSTRAINT book_genres_book_id_books_book_id_fk FOREIGN KEY (book_id) REFERENCES public.books(book_id) ON DELETE CASCADE;


--
-- Name: book_genres book_genres_genre_id_genres_genre_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.book_genres
    ADD CONSTRAINT book_genres_genre_id_genres_genre_id_fk FOREIGN KEY (genre_id) REFERENCES public.genres(genre_id) ON DELETE CASCADE;


--
-- Name: book_quotes book_quotes_book_id_books_book_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.book_quotes
    ADD CONSTRAINT book_quotes_book_id_books_book_id_fk FOREIGN KEY (book_id) REFERENCES public.books(book_id) ON DELETE CASCADE;


--
-- Name: goodreads_data goodreads_data_book_id_books_book_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.goodreads_data
    ADD CONSTRAINT goodreads_data_book_id_books_book_id_fk FOREIGN KEY (book_id) REFERENCES public.books(book_id) ON DELETE CASCADE;


--
-- Name: reading_log reading_log_book_id_books_book_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.reading_log
    ADD CONSTRAINT reading_log_book_id_books_book_id_fk FOREIGN KEY (book_id) REFERENCES public.books(book_id) ON DELETE CASCADE;


--
-- Name: reading_sessions reading_sessions_book_id_books_book_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.reading_sessions
    ADD CONSTRAINT reading_sessions_book_id_books_book_id_fk FOREIGN KEY (book_id) REFERENCES public.books(book_id) ON DELETE CASCADE;


--
-- Name: reading_stats reading_stats_favorite_author_id_authors_author_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.reading_stats
    ADD CONSTRAINT reading_stats_favorite_author_id_authors_author_id_fk FOREIGN KEY (favorite_author_id) REFERENCES public.authors(author_id);


--
-- Name: reading_stats reading_stats_favorite_genre_id_genres_genre_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.reading_stats
    ADD CONSTRAINT reading_stats_favorite_genre_id_genres_genre_id_fk FOREIGN KEY (favorite_genre_id) REFERENCES public.genres(genre_id);


--
-- Name: series_books series_books_book_id_books_book_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.series_books
    ADD CONSTRAINT series_books_book_id_books_book_id_fk FOREIGN KEY (book_id) REFERENCES public.books(book_id) ON DELETE CASCADE;


--
-- Name: series_books series_books_series_id_series_series_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.series_books
    ADD CONSTRAINT series_books_series_id_series_series_id_fk FOREIGN KEY (series_id) REFERENCES public.series(series_id) ON DELETE CASCADE;


--
-- Name: session session_user_id_users_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT session_user_id_users_id_fk FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: yearly_stats yearly_stats_top_author_id_authors_author_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.yearly_stats
    ADD CONSTRAINT yearly_stats_top_author_id_authors_author_id_fk FOREIGN KEY (top_author_id) REFERENCES public.authors(author_id);


--
-- Name: yearly_stats yearly_stats_top_genre_id_genres_genre_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: default
--

ALTER TABLE ONLY public.yearly_stats
    ADD CONSTRAINT yearly_stats_top_genre_id_genres_genre_id_fk FOREIGN KEY (top_genre_id) REFERENCES public.genres(genre_id);


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: cloud_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE cloud_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO neon_superuser WITH GRANT OPTION;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: cloud_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE cloud_admin IN SCHEMA public GRANT ALL ON TABLES TO neon_superuser WITH GRANT OPTION;


--
-- PostgreSQL database dump complete
--

\unrestrict QVc8a6BkCiFZBqQccLhGeZVsHOD3GeNPFSSEgdTpJYCygAaQ78Lv4EYMcqot0BG

