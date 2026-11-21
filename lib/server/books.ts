import { db } from "@/lib/db";
import { books } from "@/lib/db/schema";
import { eq, or, sql } from "drizzle-orm";
import * as cheerio from "cheerio";
import { BookInputError, createBookWithAuthors } from "@/lib/db/book-writes";

// Server-only helpers for book actions. Keep DB / scraping code OUT of
// actions/books.ts: plain (non-createServerFn) code there is bundled into the
// browser and would pull `lib/db` (and its DATABASE_URL check) into the client.

export interface AddBookInput {
  title: string;
  isbn?: string;
  goodreadsUrl?: string;
  year?: number;
  pages?: number;
  /** Existing author IDs (backward compatible). */
  authorIds?: number[];
  /** Author names: reused if they exist (case-insensitive), created otherwise. */
  authors?: string[];
  genreIds?: number[];
  coverUrl?: string;
  description?: string;
  publisher?: string;
}

export async function addBook(data: AddBookInput) {
  try {
    // Never create duplicates: same ISBN/QRCBN, or same title (case-insensitive)
    const title = data.title?.trim() ?? "";
    const isbn = data.isbn?.replace(/[-\s]/g, "") || null;
    const [existing] = await db
      .select({ bookId: books.bookId, title: books.title })
      .from(books)
      .where(
        isbn
          ? or(eq(books.isbn, isbn), sql`lower(${books.title}) = lower(${title})`)
          : sql`lower(${books.title}) = lower(${title})`
      )
      .limit(1);

    if (existing) {
      return {
        success: false,
        duplicate: true,
        bookId: existing.bookId,
        error: `Book already exists: "${existing.title}"`,
      };
    }

    // Authors + book + links are written atomically (see lib/db/book-writes.ts)
    const book = await createBookWithAuthors(db, data);
    return { success: true, bookId: book.bookId, book };
  } catch (error) {
    if (error instanceof BookInputError) {
      return { success: false, error: error.message };
    }
    console.error("Error adding book:", error);
    return { success: false, error: "Failed to add book" };
  }
}

export interface BookLookupResult {
  success: boolean;
  data?: {
    title: string;
    authors: string[];
    year?: number;
    pages?: number;
    goodreadsUrl: string;
    coverUrl?: string;
    description?: string;
  };
  error?: string;
}

export async function lookupIsbn(isbn: string): Promise<BookLookupResult> {
    try {
      // Clean ISBN (remove hyphens and spaces)
      const cleanIsbn = isbn.replace(/[-\s]/g, "");

      // Validate ISBN (10 or 13 digits)
      if (!/^\d{10}(\d{3})?$/.test(cleanIsbn)) {
        return { success: false, error: "Invalid ISBN format" };
      }

      const browserHeaders = {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.9",
        "Cache-Control": "no-cache",
        "Sec-Fetch-Dest": "document",
        "Sec-Fetch-Mode": "navigate",
        "Sec-Fetch-Site": "none",
        "Upgrade-Insecure-Requests": "1",
      };

      // Use /book/isbn/ endpoint — avoids the AWS WAF-protected search page
      const isbnUrl = `https://www.goodreads.com/book/isbn/${cleanIsbn}`;
      console.log("[ISBN Lookup] Trying direct ISBN URL:", isbnUrl);

      const response = await fetch(isbnUrl, {
        redirect: "follow",
        headers: browserHeaders,
      });

      console.log("[ISBN Lookup] Response status:", response.status);
      console.log("[ISBN Lookup] Final URL after redirect:", response.url);

      if (response.ok && response.url.includes("/book/show/")) {
        const html = await response.text();
        console.log("[ISBN Lookup] Got book page directly, HTML length:", html.length);
        const direct = parseBookPage(html, response.url);
        if (direct.success) return direct;

        // Goodreads WAF-challenges server-side fetches (202 + empty body), but
        // the redirect already resolved the book URL. Read the page through
        // the reader proxy, same as lookupBookByGoodreadsUrl.
        // Ask for rendered HTML: the markdown output truncates titles and
        // drops authors/description on pages with long review lists.
        const proxied = await fetch(`https://r.jina.ai/${response.url}`, {
          headers: {
            "User-Agent": browserHeaders["User-Agent"],
            "X-Return-Format": "html",
          },
        });
        if (proxied.ok) {
          const rendered = parseBookPage(await proxied.text(), response.url);
          if (rendered.success) return rendered;
        }
        return direct;
      }

      // Fallback to search if direct ISBN URL didn't work
      const searchUrl = `https://www.goodreads.com/search?utf8=%E2%9C%93&q=${cleanIsbn}&search_type=books&search%5Bfield%5D=on`;
      console.log("[ISBN Lookup] Falling back to search URL:", searchUrl);

      const searchResponse = await fetch(searchUrl, {
        redirect: "follow",
        headers: browserHeaders,
      });

      console.log("[ISBN Lookup] Search response status:", searchResponse.status);
      console.log("[ISBN Lookup] Search final URL:", searchResponse.url);

      if (!searchResponse.ok) {
        return { success: false, error: "Failed to fetch from Goodreads" };
      }

      const html = await searchResponse.text();
      const currentUrl = searchResponse.url;

      if (currentUrl.includes("/book/show/")) {
        return parseBookPage(html, currentUrl);
      }

      const $ = cheerio.load(html);
      const firstBookLink =
        $('a.bookTitle').first().attr('href') ||
        $('a[href*="/book/show/"]').first().attr('href');

      console.log("[ISBN Lookup] First book link from search:", firstBookLink);

      if (!firstBookLink) {
        return { success: false, error: "Book not found on Goodreads" };
      }

      const bookUrl = firstBookLink.startsWith("http")
        ? firstBookLink
        : `https://www.goodreads.com${firstBookLink}`;

      const bookResponse = await fetch(bookUrl, { headers: browserHeaders });
      if (!bookResponse.ok) {
        return { success: false, error: "Failed to fetch book page" };
      }

      return parseBookPage(await bookResponse.text(), bookUrl);
    } catch (error) {
      console.error("Error looking up book:", error);
      return { success: false, error: "An error occurred while looking up the book" };
    }
}

export function parseBookPage(html: string, url: string): BookLookupResult {
  try {
    const $ = cheerio.load(html);

    // Extract title
    const title = $('h1[data-testid="bookTitle"]').text().trim() ||
                  $('.BookPageTitleSection__title h1').text().trim() ||
                  $('h1.Text.Text__title1').text().trim();

    if (!title) {
      return { success: false, error: "Could not extract book title" };
    }

    // Extract authors
    const bookAuthorsList: string[] = [];
    $('span[data-testid="name"]').each((_, el) => {
      const authorName = $(el).text().trim();
      if (authorName && !bookAuthorsList.includes(authorName)) bookAuthorsList.push(authorName);
    });

    // Fallback for authors
    if (bookAuthorsList.length === 0) {
      $('.ContributorLink__name').each((_, el) => {
        const authorName = $(el).text().trim();
        if (authorName) bookAuthorsList.push(authorName);
      });
    }

    // Extract publication year
    let year: number | undefined;
    const pubInfo = $('p[data-testid="publicationInfo"]').text();
    const yearMatch = pubInfo.match(/(\d{4})/);
    if (yearMatch) {
      year = parseInt(yearMatch[1]);
    }

    // Extract pages
    let pages: number | undefined;
    const pagesText = $('p[data-testid="pagesFormat"]').text();
    const pagesMatch = pagesText.match(/(\d+)\s*pages/i);
    if (pagesMatch) {
      pages = parseInt(pagesMatch[1]);
    }

    // Extract cover URL
    const coverUrl = $('img.ResponsiveImage').first().attr('src') ||
                     $('.BookCover__image img').first().attr('src');

    // Extract description
    const description = $('div[data-testid="description"]').text().trim() ||
                       $('.DetailsLayoutRightParagraph__widthConstrained').text().trim();

    return {
      success: true,
      data: {
        title,
        authors: bookAuthorsList,
        year,
        pages,
        goodreadsUrl: url,
        coverUrl,
        description,
      },
    };
  } catch (error) {
    console.error("Error parsing book page:", error);
    return { success: false, error: "Failed to parse book data" };
  }
}

export function parseBookMarkdown(markdown: string, url: string): BookLookupResult {
  try {
    // The reader proxy sometimes captures the page before the book-detail
    // section finishes rendering (dynamic content, e.g. long review lists),
    // in which case there's no "# Title" heading. Fall back to the "Title:"
    // metadata line the proxy always prepends to its output.
    const titleMatch = markdown.match(/^#\s+(.+)$/m) || markdown.match(/^Title:\s+(.+)$/m);
    const title = titleMatch?.[1].trim();

    if (!title) {
      return { success: false, error: "Could not extract book title" };
    }

    // Authors appear as "### [Name](.../author/show/...)" links right after the title
    const bookAuthorsList: string[] = [];
    const authorRegex = /###\s+\[([^\]]+)\]\(https:\/\/www\.goodreads\.com\/author\/show\/[^)]+\)/g;
    let authorMatch: RegExpExecArray | null;
    while ((authorMatch = authorRegex.exec(markdown)) !== null) {
      const name = authorMatch[1].trim();
      if (!bookAuthorsList.includes(name)) bookAuthorsList.push(name);
    }

    // Extract publication year
    let year: number | undefined;
    const pubMatch = markdown.match(/Published\s+.*?(\d{4})/);
    if (pubMatch) {
      year = parseInt(pubMatch[1]);
    }

    // Extract pages
    let pages: number | undefined;
    const pagesMatch = markdown.match(/(\d+)\s*pages/i);
    if (pagesMatch) {
      pages = parseInt(pagesMatch[1]);
    }

    // Extract cover URL (first amazon/goodreads book image)
    const coverMatch = markdown.match(/!\[Image \d+\]\((https:\/\/[^)]+)\)/);
    const coverUrl = coverMatch?.[1];

    return {
      success: true,
      data: {
        title,
        authors: bookAuthorsList,
        year,
        pages,
        goodreadsUrl: url,
        coverUrl,
        description: undefined,
      },
    };
  } catch (error) {
    console.error("Error parsing book markdown:", error);
    return { success: false, error: "Failed to parse book data" };
  }
}

export const GOODREADS_BROWSER_HEADERS = {
  "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
  "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
  "Accept-Language": "en-US,en;q=0.9",
  "Cache-Control": "no-cache",
  "Sec-Fetch-Dest": "document",
  "Sec-Fetch-Mode": "navigate",
  "Sec-Fetch-Site": "none",
  "Upgrade-Insecure-Requests": "1",
};

// Best-effort Goodreads lookup by free-text query (title + author). Used to
// enrich data from sources that don't carry an ISBN, like QRCBN. Returns
// null (rather than an error) on any failure so callers can fall back to
// their own data.
export async function searchGoodreadsByQuery(query: string): Promise<BookLookupResult | null> {
  try {
    const searchUrl = `https://www.goodreads.com/search?utf8=%E2%9C%93&q=${encodeURIComponent(query)}&search_type=books`;
    const searchResponse = await fetch(searchUrl, {
      redirect: "follow",
      headers: GOODREADS_BROWSER_HEADERS,
    });

    if (!searchResponse.ok) return null;

    const html = await searchResponse.text();
    const currentUrl = searchResponse.url;

    if (currentUrl.includes("/book/show/")) {
      const result = parseBookPage(html, currentUrl);
      return result.success ? result : null;
    }

    const $ = cheerio.load(html);
    const firstBookLink =
      $('a.bookTitle').first().attr('href') ||
      $('a[href*="/book/show/"]').first().attr('href');

    if (!firstBookLink) return null;

    const bookUrl = firstBookLink.startsWith("http")
      ? firstBookLink
      : `https://www.goodreads.com${firstBookLink}`;

    const bookResponse = await fetch(bookUrl, { headers: GOODREADS_BROWSER_HEADERS });
    if (!bookResponse.ok) return null;

    const result = parseBookPage(await bookResponse.text(), bookUrl);
    return result.success ? result : null;
  } catch (error) {
    console.error("Error searching Goodreads by query:", error);
    return null;
  }
}

export async function lookupQrcbn(rawCode: string): Promise<BookLookupResult> {
    try {
      // Accept a bare code, a dashed code or a full qrcbn.com/check/ URL
      const digits = rawCode.split("/check/").pop()!.replace(/\D/g, "");

      if (!/^\d{6,20}$/.test(digits)) {
        return { success: false, error: "Invalid QRCBN code" };
      }

      // The API only matches the dashed form (62-XXXX-XXXX-XXX); the bare
      // digits return `naskah: null`.
      const code = /^62\d{11}$/.test(digits)
        ? `${digits.slice(0, 2)}-${digits.slice(2, 6)}-${digits.slice(6, 10)}-${digits.slice(10)}`
        : digits;

      const response = await fetch(`https://my.qrcbn.com/api/naskah/${code}`, {
        headers: { Accept: "application/json" },
      });

      if (!response.ok) {
        return { success: false, error: "Failed to fetch from QRCBN" };
      }

      const json = await response.json();
      const naskah = json?.data?.naskah;

      if (!naskah || !naskah.title) {
        return { success: false, error: "QRCBN code not found" };
      }

      const yearMatch =
        typeof naskah.publish_date === "string" ? naskah.publish_date.match(/(\d{4})/) : null;

      const bookData: NonNullable<BookLookupResult["data"]> = {
        title: naskah.title,
        authors: naskah.author ? [naskah.author] : [],
        year: yearMatch ? parseInt(yearMatch[1]) : undefined,
        pages: parseInt(naskah.page) || undefined,
        goodreadsUrl: "",
        coverUrl: /^https?:\/\//.test(naskah.cover_url) ? naskah.cover_url : undefined,
        description: naskah.description ?? undefined,
      };

      // QRCBN books rarely carry an ISBN, so match Goodreads by title+author
      // instead. Best-effort only — QRCBN data always wins on conflicts.
      const enriched = await searchGoodreadsByQuery(
        [bookData.title, bookData.authors[0]].filter(Boolean).join(" ")
      );

      if (enriched?.data) {
        bookData.goodreadsUrl = enriched.data.goodreadsUrl;
        bookData.coverUrl = bookData.coverUrl ?? enriched.data.coverUrl;
        bookData.description = bookData.description ?? enriched.data.description;
        bookData.year = bookData.year ?? enriched.data.year;
        bookData.pages = bookData.pages ?? enriched.data.pages;
      }

      return { success: true, data: bookData };
    } catch (error) {
      console.error("Error looking up book by QRCBN:", error);
      return { success: false, error: "An error occurred while looking up the book" };
    }
}

export async function lookupGoodreadsUrl(url: string): Promise<BookLookupResult> {
    const data = { url };
    try {
      // Validate URL
      if (!/goodreads\.com\/(?:[a-z]{2}\/)?book\/show\//.test(data.url)) {
        return { success: false, error: "Invalid Goodreads URL. Must be a book page URL." };
      }

      // Fetch the book page. Goodreads WAF-challenges direct server-side
      // fetches of /book/show/ pages (returns 202 with an empty body), so
      // route through the r.jina.ai reader proxy which renders the page
      // and returns clean markdown instead.
      const userAgent =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36";

      // Rendered HTML first: the markdown output truncates titles and drops
      // authors/description on pages with long review lists.
      const htmlResponse = await fetch(`https://r.jina.ai/${data.url}`, {
        headers: { "User-Agent": userAgent, "X-Return-Format": "html" },
      });
      if (htmlResponse.ok) {
        const rendered = parseBookPage(await htmlResponse.text(), data.url);
        if (rendered.success) return rendered;
      }

      const response = await fetch(`https://r.jina.ai/${data.url}`, {
        headers: { "User-Agent": userAgent },
      });

      if (!response.ok) {
        return { success: false, error: "Failed to fetch from Goodreads" };
      }

      const markdown = await response.text();
      return parseBookMarkdown(markdown, data.url);
    } catch (error) {
      console.error("Error looking up book by URL:", error);
      return { success: false, error: "An error occurred while looking up the book" };
    }
}

