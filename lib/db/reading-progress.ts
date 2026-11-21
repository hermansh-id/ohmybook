/**
 * Single source of truth for how a reading session moves a book's reading_log.
 * Used by the "log session" action and by the planner when a plan item is completed.
 */

export interface LogSnapshot {
  currentPage: number | null;
  status: string | null;
  dateStarted: string | null;
}

export interface LogUpdate {
  currentPage: number;
  status: string;
  dateStarted: string;
  /** Set only when this session completes the book; otherwise left unchanged. */
  dateFinished: string | null;
  isCompleted: boolean;
}

/**
 * @param prev       existing reading_log row, or null/undefined when the book has none
 * @param totalPages books.pages (null/0 when unknown: the book is then never auto-finished)
 * @param pagesRead  pages read in this session
 * @param sessionDate YYYY-MM-DD
 */
export function computeLogUpdate(
  prev: LogSnapshot | null | undefined,
  totalPages: number | null | undefined,
  pagesRead: number | null | undefined,
  sessionDate: string,
): LogUpdate {
  const total = totalPages || 0;
  const currentPage = (prev?.currentPage || 0) + (pagesRead || 0);
  const isCompleted = total > 0 && currentPage >= total;

  return {
    currentPage: isCompleted ? total : currentPage,
    status: isCompleted
      ? "finished"
      : !prev
        ? "reading"
        : prev.status === "want_to_read"
          ? "reading"
          : (prev.status ?? "reading"),
    dateStarted: prev?.dateStarted || sessionDate,
    dateFinished: isCompleted ? sessionDate : null,
    isCompleted,
  };
}
