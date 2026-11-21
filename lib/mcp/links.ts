/** Public base URL of the app (no trailing slash). */
export function appBaseUrl() {
  const raw = process.env.BETTER_AUTH_URL || process.env.VITE_APP_URL || "http://localhost:3000";
  return raw.replace(/\/+$/, "");
}

export function bookUrl(bookId: number) {
  return `${appBaseUrl()}/dashboard/books/${bookId}`;
}

/**
 * Deep-copy `data`, adding a `url` field to every object that looks like a
 * book (numeric `bookId` + string `title`). Leaves Dates and primitives alone.
 */
export function withBookUrls<T>(data: T): T {
  if (Array.isArray(data)) return data.map(withBookUrls) as T;
  if (data && typeof data === "object" && !(data instanceof Date)) {
    const obj = data as Record<string, unknown>;
    const out: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(obj)) out[k] = withBookUrls(v);
    if (typeof obj.bookId === "number" && typeof obj.title === "string" && out.url === undefined) {
      out.url = bookUrl(obj.bookId);
    }
    return out as T;
  }
  return data;
}
