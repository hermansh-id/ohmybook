-- Case-insensitive unique author names.
-- `bun db:push` applies this index from lib/db/schema/core.ts; this file is the
-- manual equivalent plus a pre-check, for running by hand.

-- 1) PRE-CHECK: must return 0 rows, otherwise the index creation fails.
--    Merge/rename the listed authors first.
SELECT lower(name) AS name_key, count(*) AS n, array_agg(author_id ORDER BY author_id) AS author_ids
FROM authors
GROUP BY lower(name)
HAVING count(*) > 1;

-- 2) UP
CREATE UNIQUE INDEX IF NOT EXISTS uq_authors_name_lower ON authors (lower(name));

-- 3) DOWN (rollback)
-- DROP INDEX IF EXISTS uq_authors_name_lower;
