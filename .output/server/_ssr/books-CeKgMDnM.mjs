import { n as createServerFn } from "./ssr.mjs";
import { s as eq } from "../_libs/drizzle-orm.mjs";
import { a as bookGenres, c as db, d as goodreadsData, i as bookAuthors, r as authors, s as books } from "./db-Byp6WemB.mjs";
import { t as createServerRpc } from "./createServerRpc-A6pJPYTF.mjs";
import { a as getAllBooksWithDetails, s as getBookById } from "./queries-CGoFn0cR.mjs";
import { t as load } from "../_libs/cheerio+[...].mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/books-CeKgMDnM.js
var getBooksAction_createServerFn_handler = createServerRpc({
	id: "64c1a81f41d7945c6599cdc9accacb77d3f379b3c55715a5eca6b2793c7d2cdc",
	name: "getBooksAction",
	filename: "actions/books.ts"
}, (opts) => getBooksAction.__executeServer(opts));
var getBooksAction = createServerFn({ method: "GET" }).handler(getBooksAction_createServerFn_handler, async () => {
	try {
		const allBooks = await getAllBooksWithDetails();
		const bookMap = /* @__PURE__ */ new Map();
		allBooks.forEach((row) => {
			const bookId = row.book.bookId;
			if (!bookMap.has(bookId)) bookMap.set(bookId, {
				id: bookId,
				title: row.book.title,
				isbn: row.book.isbn,
				year: row.book.year,
				pages: row.book.pages,
				addedAt: row.book.addedAt,
				authors: [],
				genres: [],
				status: row.readingStatus?.status || "not_started",
				rating: row.readingStatus?.rating || null,
				dateFinished: row.readingStatus?.dateFinished || null,
				currentPage: row.readingStatus?.currentPage || 0,
				coverUrl: row.goodreads?.coverUrl || null,
				averageRating: row.goodreads?.averageRating || null
			});
			const book = bookMap.get(bookId);
			if (row.author && !book.authors.some((a) => a.name === row.author?.name)) book.authors.push({
				id: row.author.authorId,
				name: row.author.name
			});
			if (row.genre && !book.genres.some((g) => g.name === row.genre?.genreName)) book.genres.push({
				id: row.genre.genreId,
				name: row.genre.genreName
			});
		});
		return Array.from(bookMap.values());
	} catch (error) {
		console.error("Error fetching books:", error);
		throw new Error("Failed to fetch books");
	}
});
var getBookDetailsAction_createServerFn_handler = createServerRpc({
	id: "01b4e14b547ad387aa616cc01c9b1184ef251522917acba268803640ff9c1fcd",
	name: "getBookDetailsAction",
	filename: "actions/books.ts"
}, (opts) => getBookDetailsAction.__executeServer(opts));
var getBookDetailsAction = createServerFn({ method: "POST" }).validator((d) => d).handler(getBookDetailsAction_createServerFn_handler, async ({ data }) => {
	try {
		const result = await getBookById(data.bookId);
		if (!result || result.length === 0) throw new Error("Book not found");
		const bookData = result[0];
		return {
			id: bookData.books.bookId,
			title: bookData.books.title,
			isbn: bookData.books.isbn,
			year: bookData.books.year,
			pages: bookData.books.pages,
			addedAt: bookData.books.addedAt,
			goodreadsUrl: bookData.books.goodreadsUrl,
			status: bookData.reading_log?.status || "not_started",
			rating: bookData.reading_log?.rating || null,
			review: bookData.reading_log?.review || null,
			notes: bookData.reading_log?.notes || null,
			dateAdded: bookData.reading_log?.dateAdded || null,
			dateStarted: bookData.reading_log?.dateStarted || null,
			dateFinished: bookData.reading_log?.dateFinished || null,
			currentPage: bookData.reading_log?.currentPage || 0,
			readingDays: bookData.reading_log?.readingDays || null,
			tags: bookData.reading_log?.tags || [],
			coverUrl: bookData.goodreads_data?.coverUrl || null,
			description: bookData.goodreads_data?.description || null,
			averageRating: bookData.goodreads_data?.averageRating || null,
			ratingsCount: bookData.goodreads_data?.ratingsCount || null,
			publisher: bookData.goodreads_data?.publisher || null,
			publicationDate: bookData.goodreads_data?.publicationDate || null,
			logId: bookData.reading_log?.logId || null
		};
	} catch (error) {
		console.error("Error fetching book details:", error);
		throw new Error("Failed to fetch book details");
	}
});
var updateBookStatusAction_createServerFn_handler = createServerRpc({
	id: "3aec4fda845b3b79029767b1631f2ed52ead4795abcc913ad48262da0513c2b7",
	name: "updateBookStatusAction",
	filename: "actions/books.ts"
}, (opts) => updateBookStatusAction.__executeServer(opts));
var updateBookStatusAction = createServerFn({ method: "POST" }).validator((d) => d).handler(updateBookStatusAction_createServerFn_handler, async ({ data }) => {
	try {
		const { addToReadingLog, updateReadingStatus, markBookAsFinished } = await import("./queries-CGoFn0cR.mjs").then((n) => n.b);
		if (!data.logId) return (await addToReadingLog(data.bookId, data.status))[0];
		if (data.status === "finished") return await markBookAsFinished(data.logId, data.rating ?? void 0);
		return await updateReadingStatus(data.logId, {
			status: data.status,
			rating: data.rating ?? void 0,
			dateFinished: data.dateFinished ?? void 0
		});
	} catch (error) {
		console.error("Error updating book status:", error);
		throw new Error("Failed to update book status");
	}
});
var addBookAction_createServerFn_handler = createServerRpc({
	id: "f9a652bd6c68118253acd1a18c6c6bd28438dbe99bd7d676834d326f0cdac1cf",
	name: "addBookAction",
	filename: "actions/books.ts"
}, (opts) => addBookAction.__executeServer(opts));
var addBookAction = createServerFn({ method: "POST" }).validator((d) => d).handler(addBookAction_createServerFn_handler, async ({ data }) => {
	try {
		const [book] = await db.insert(books).values({
			title: data.title,
			isbn: data.isbn || null,
			goodreadsUrl: data.goodreadsUrl || null,
			year: data.year || null,
			pages: data.pages || null
		}).returning();
		if (data.authorIds.length > 0) await db.insert(bookAuthors).values(data.authorIds.map((authorId, index) => ({
			bookId: book.bookId,
			authorId,
			authorOrder: index + 1
		})));
		if (data.genreIds && data.genreIds.length > 0) await db.insert(bookGenres).values(data.genreIds.map((genreId, index) => ({
			bookId: book.bookId,
			genreId,
			isPrimary: index === 0
		})));
		if (data.coverUrl || data.description) try {
			await db.insert(goodreadsData).values({
				bookId: book.bookId,
				coverUrl: data.coverUrl || null,
				description: data.description || null
			});
		} catch (error) {
			console.error("Error saving Goodreads data:", error);
		}
		return {
			success: true,
			bookId: book.bookId
		};
	} catch (error) {
		console.error("Error adding book:", error);
		return {
			success: false,
			error: "Failed to add book"
		};
	}
});
var deleteBookAction_createServerFn_handler = createServerRpc({
	id: "d6146983f8b22455437a1988e1f3466992ab3e27e6467b8a7f375e9174e93e3d",
	name: "deleteBookAction",
	filename: "actions/books.ts"
}, (opts) => deleteBookAction.__executeServer(opts));
var deleteBookAction = createServerFn({ method: "POST" }).validator((d) => d).handler(deleteBookAction_createServerFn_handler, async ({ data }) => {
	try {
		await db.delete(books).where(eq(books.bookId, data.bookId));
		return { success: true };
	} catch (error) {
		console.error("Error deleting book:", error);
		return {
			success: false,
			error: "Failed to delete book"
		};
	}
});
var updateBookAction_createServerFn_handler = createServerRpc({
	id: "d5ba42d20fd11e37d18480c1898593ec5b7e197e5a1f9780773a43871e68ac92",
	name: "updateBookAction",
	filename: "actions/books.ts"
}, (opts) => updateBookAction.__executeServer(opts));
var updateBookAction = createServerFn({ method: "POST" }).validator((d) => d).handler(updateBookAction_createServerFn_handler, async ({ data }) => {
	try {
		const { bookId, ...updateData } = data;
		const dataToUpdate = {};
		if (updateData.title !== void 0) dataToUpdate.title = updateData.title;
		if (updateData.isbn !== void 0) dataToUpdate.isbn = updateData.isbn || null;
		if (updateData.year !== void 0) dataToUpdate.year = updateData.year || null;
		if (updateData.pages !== void 0) dataToUpdate.pages = updateData.pages || null;
		if (updateData.goodreadsUrl !== void 0) dataToUpdate.goodreadsUrl = updateData.goodreadsUrl || null;
		await db.update(books).set(dataToUpdate).where(eq(books.bookId, bookId));
		return { success: true };
	} catch (error) {
		console.error("Error updating book:", error);
		return {
			success: false,
			error: "Failed to update book"
		};
	}
});
var getAllBooksAction_createServerFn_handler = createServerRpc({
	id: "66d04371c9608bca006fd7d63cf64d303131177821e1b7c7783aa3eb17a241df",
	name: "getAllBooksAction",
	filename: "actions/books.ts"
}, (opts) => getAllBooksAction.__executeServer(opts));
var getAllBooksAction = createServerFn({ method: "GET" }).handler(getAllBooksAction_createServerFn_handler, async () => {
	try {
		return await db.select({
			bookId: books.bookId,
			title: books.title
		}).from(books).orderBy(books.title);
	} catch (error) {
		console.error("Error fetching books:", error);
		return [];
	}
});
var getAuthorsAction_createServerFn_handler = createServerRpc({
	id: "90b4c5be81c06c15b87f34bcf817bfd7c9b860290525bc9ea5ce52360fc51c66",
	name: "getAuthorsAction",
	filename: "actions/books.ts"
}, (opts) => getAuthorsAction.__executeServer(opts));
var getAuthorsAction = createServerFn({ method: "GET" }).handler(getAuthorsAction_createServerFn_handler, async () => {
	try {
		return await db.select({
			authorId: authors.authorId,
			name: authors.name
		}).from(authors).orderBy(authors.name);
	} catch (error) {
		console.error("Error fetching authors:", error);
		return [];
	}
});
var lookupBookByISBN_createServerFn_handler = createServerRpc({
	id: "b565a49351db7f478bbd7dfdec3ee323909f94ecf1c49513f55ed61e421dd23c",
	name: "lookupBookByISBN",
	filename: "actions/books.ts"
}, (opts) => lookupBookByISBN.__executeServer(opts));
var lookupBookByISBN = createServerFn({ method: "POST" }).validator((d) => d).handler(lookupBookByISBN_createServerFn_handler, async ({ data }) => {
	try {
		const cleanIsbn = data.isbn.replace(/[-\s]/g, "");
		if (!/^\d{10}(\d{3})?$/.test(cleanIsbn)) return {
			success: false,
			error: "Invalid ISBN format"
		};
		const browserHeaders = {
			"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
			"Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
			"Accept-Language": "en-US,en;q=0.9",
			"Cache-Control": "no-cache",
			"Sec-Fetch-Dest": "document",
			"Sec-Fetch-Mode": "navigate",
			"Sec-Fetch-Site": "none",
			"Upgrade-Insecure-Requests": "1"
		};
		const isbnUrl = `https://www.goodreads.com/book/isbn/${cleanIsbn}`;
		console.log("[ISBN Lookup] Trying direct ISBN URL:", isbnUrl);
		const response = await fetch(isbnUrl, {
			redirect: "follow",
			headers: browserHeaders
		});
		console.log("[ISBN Lookup] Response status:", response.status);
		console.log("[ISBN Lookup] Final URL after redirect:", response.url);
		if (response.ok && response.url.includes("/book/show/")) {
			const html = await response.text();
			console.log("[ISBN Lookup] Got book page directly, HTML length:", html.length);
			return parseBookPage(html, response.url);
		}
		const searchUrl = `https://www.goodreads.com/search?utf8=%E2%9C%93&q=${cleanIsbn}&search_type=books&search%5Bfield%5D=on`;
		console.log("[ISBN Lookup] Falling back to search URL:", searchUrl);
		const searchResponse = await fetch(searchUrl, {
			redirect: "follow",
			headers: browserHeaders
		});
		console.log("[ISBN Lookup] Search response status:", searchResponse.status);
		console.log("[ISBN Lookup] Search final URL:", searchResponse.url);
		if (!searchResponse.ok) return {
			success: false,
			error: "Failed to fetch from Goodreads"
		};
		const html = await searchResponse.text();
		const currentUrl = searchResponse.url;
		if (currentUrl.includes("/book/show/")) return parseBookPage(html, currentUrl);
		const $ = load(html);
		const firstBookLink = $("a.bookTitle").first().attr("href") || $("a[href*=\"/book/show/\"]").first().attr("href");
		console.log("[ISBN Lookup] First book link from search:", firstBookLink);
		if (!firstBookLink) return {
			success: false,
			error: "Book not found on Goodreads"
		};
		const bookUrl = firstBookLink.startsWith("http") ? firstBookLink : `https://www.goodreads.com${firstBookLink}`;
		const bookResponse = await fetch(bookUrl, { headers: browserHeaders });
		if (!bookResponse.ok) return {
			success: false,
			error: "Failed to fetch book page"
		};
		return parseBookPage(await bookResponse.text(), bookUrl);
	} catch (error) {
		console.error("Error looking up book:", error);
		return {
			success: false,
			error: "An error occurred while looking up the book"
		};
	}
});
function parseBookPage(html, url) {
	try {
		const $ = load(html);
		const title = $("h1[data-testid=\"bookTitle\"]").text().trim() || $(".BookPageTitleSection__title h1").text().trim() || $("h1.Text.Text__title1").text().trim();
		if (!title) return {
			success: false,
			error: "Could not extract book title"
		};
		const bookAuthorsList = [];
		$("span[data-testid=\"name\"]").each((_, el) => {
			const authorName = $(el).text().trim();
			if (authorName) bookAuthorsList.push(authorName);
		});
		if (bookAuthorsList.length === 0) $(".ContributorLink__name").each((_, el) => {
			const authorName = $(el).text().trim();
			if (authorName) bookAuthorsList.push(authorName);
		});
		let year;
		const yearMatch = $("p[data-testid=\"publicationInfo\"]").text().match(/(\d{4})/);
		if (yearMatch) year = parseInt(yearMatch[1]);
		let pages;
		const pagesMatch = $("p[data-testid=\"pagesFormat\"]").text().match(/(\d+)\s*pages/i);
		if (pagesMatch) pages = parseInt(pagesMatch[1]);
		const coverUrl = $("img.ResponsiveImage").first().attr("src") || $(".BookCover__image img").first().attr("src");
		const description = $("div[data-testid=\"description\"]").text().trim() || $(".DetailsLayoutRightParagraph__widthConstrained").text().trim();
		return {
			success: true,
			data: {
				title,
				authors: bookAuthorsList,
				year,
				pages,
				goodreadsUrl: url,
				coverUrl,
				description
			}
		};
	} catch (error) {
		console.error("Error parsing book page:", error);
		return {
			success: false,
			error: "Failed to parse book data"
		};
	}
}
var getReadingRecommendationsAction_createServerFn_handler = createServerRpc({
	id: "5a9102dcd3bbfcf6cfaff03a9c891747003fca59cd540e0e275a50f9434d0dc7",
	name: "getReadingRecommendationsAction",
	filename: "actions/books.ts"
}, (opts) => getReadingRecommendationsAction.__executeServer(opts));
var getReadingRecommendationsAction = createServerFn({ method: "GET" }).handler(getReadingRecommendationsAction_createServerFn_handler, async () => {
	try {
		const allBooks = await getAllBooksWithDetails();
		const bookMap = /* @__PURE__ */ new Map();
		allBooks.forEach((row) => {
			const bookId = row.book.bookId;
			if (!bookMap.has(bookId)) bookMap.set(bookId, {
				id: bookId,
				title: row.book.title,
				isbn: row.book.isbn,
				year: row.book.year,
				pages: row.book.pages,
				addedAt: row.book.addedAt,
				authors: [],
				genres: [],
				status: row.readingStatus?.status || "not_started",
				rating: row.readingStatus?.rating || null,
				coverUrl: row.goodreads?.coverUrl || null,
				averageRating: row.goodreads?.averageRating || null,
				ratingsCount: row.goodreads?.ratingsCount || null,
				description: row.goodreads?.description || null
			});
			const book = bookMap.get(bookId);
			if (row.author && !book.authors.some((a) => a.name === row.author?.name)) book.authors.push({
				id: row.author.authorId,
				name: row.author.name
			});
			if (row.genre && !book.genres.some((g) => g.name === row.genre?.genreName)) book.genres.push({
				id: row.genre.genreId,
				name: row.genre.genreName
			});
		});
		const recommendations = Array.from(bookMap.values()).filter((book) => book.status === "not_started" || book.status === "reading").map((book) => {
			let score = 0;
			if (book.status === "reading") score += 100;
			if (book.averageRating) score += parseFloat(book.averageRating.toString()) * 10;
			if (book.ratingsCount) score += Math.min(book.ratingsCount / 100, 20);
			if (book.pages) score += Math.max(0, (500 - book.pages) / 100);
			if (book.addedAt) {
				const daysInLibrary = (Date.now() - new Date(book.addedAt).getTime()) / (1e3 * 60 * 60 * 24);
				score += Math.min(daysInLibrary / 10, 15);
			}
			return {
				...book,
				recommendationScore: score
			};
		});
		recommendations.sort((a, b) => b.recommendationScore - a.recommendationScore);
		return recommendations.slice(0, 10);
	} catch (error) {
		console.error("Error getting recommendations:", error);
		return [];
	}
});
var lookupBookByGoodreadsUrl_createServerFn_handler = createServerRpc({
	id: "195a49472d00f6fde35f852382d67f4caf379b9684817d6741ece871e4484fce",
	name: "lookupBookByGoodreadsUrl",
	filename: "actions/books.ts"
}, (opts) => lookupBookByGoodreadsUrl.__executeServer(opts));
var lookupBookByGoodreadsUrl = createServerFn({ method: "POST" }).validator((d) => d).handler(lookupBookByGoodreadsUrl_createServerFn_handler, async ({ data }) => {
	try {
		if (!data.url.includes("goodreads.com/book/show/")) return {
			success: false,
			error: "Invalid Goodreads URL. Must be a book page URL."
		};
		const response = await fetch(data.url, { headers: { "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" } });
		if (!response.ok) return {
			success: false,
			error: "Failed to fetch from Goodreads"
		};
		return parseBookPage(await response.text(), data.url);
	} catch (error) {
		console.error("Error looking up book by URL:", error);
		return {
			success: false,
			error: "An error occurred while looking up the book"
		};
	}
});
var fetchGoodreadsDataAction_createServerFn_handler = createServerRpc({
	id: "e8a8221e2251a48f4a05c68b76e7bbe0714b1c940df2717ef309bfac8ac249bd",
	name: "fetchGoodreadsDataAction",
	filename: "actions/books.ts"
}, (opts) => fetchGoodreadsDataAction.__executeServer(opts));
var fetchGoodreadsDataAction = createServerFn({ method: "POST" }).validator((d) => d).handler(fetchGoodreadsDataAction_createServerFn_handler, async ({ data }) => {
	try {
		console.log("Fetching Goodreads data for book:", data.bookId, "ISBN:", data.isbn);
		const result = await lookupBookByISBN({ data: { isbn: data.isbn } });
		console.log("Lookup result:", result);
		if (!result.success || !result.data) {
			console.error("Lookup failed:", result.error);
			return {
				success: false,
				error: result.error || "Failed to fetch Goodreads data"
			};
		}
		const existingData = await db.select().from(goodreadsData).where(eq(goodreadsData.bookId, data.bookId)).limit(1);
		console.log("Existing data:", existingData.length > 0 ? "Found" : "Not found");
		const goodreadsDataToSave = {
			coverUrl: result.data.coverUrl || null,
			description: result.data.description || null,
			lastUpdated: /* @__PURE__ */ new Date()
		};
		console.log("Data to save:", goodreadsDataToSave);
		if (existingData.length > 0) {
			const updated = await db.update(goodreadsData).set(goodreadsDataToSave).where(eq(goodreadsData.bookId, data.bookId)).returning();
			console.log("Updated data:", updated);
		} else {
			const inserted = await db.insert(goodreadsData).values({
				bookId: data.bookId,
				...goodreadsDataToSave
			}).returning();
			console.log("Inserted data:", inserted);
		}
		if (result.data.goodreadsUrl) {
			await db.update(books).set({ goodreadsUrl: result.data.goodreadsUrl }).where(eq(books.bookId, data.bookId));
			console.log("Updated book with Goodreads URL");
		}
		console.log("Successfully saved Goodreads data");
		return { success: true };
	} catch (error) {
		console.error("Error fetching Goodreads data:", error);
		return {
			success: false,
			error: error instanceof Error ? error.message : "Failed to fetch Goodreads data"
		};
	}
});
//#endregion
export { addBookAction_createServerFn_handler, deleteBookAction_createServerFn_handler, fetchGoodreadsDataAction_createServerFn_handler, getAllBooksAction_createServerFn_handler, getAuthorsAction_createServerFn_handler, getBookDetailsAction_createServerFn_handler, getBooksAction_createServerFn_handler, getReadingRecommendationsAction_createServerFn_handler, lookupBookByGoodreadsUrl_createServerFn_handler, lookupBookByISBN_createServerFn_handler, updateBookAction_createServerFn_handler, updateBookStatusAction_createServerFn_handler };
