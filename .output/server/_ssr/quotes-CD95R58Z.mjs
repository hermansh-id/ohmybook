import { n as createServerFn } from "./ssr.mjs";
import { t as createServerRpc } from "./createServerRpc-A6pJPYTF.mjs";
import { S as updateQuote, r as deleteQuote, t as createQuote, x as toggleQuoteFavorite } from "./queries-CGoFn0cR.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/quotes-CD95R58Z.js
var createQuoteAction_createServerFn_handler = createServerRpc({
	id: "5be86db5a7c3be44b7ead75eb13a7cc18430e0d98e526f7b6396435b673621af",
	name: "createQuoteAction",
	filename: "actions/quotes.ts"
}, (opts) => createQuoteAction.__executeServer(opts));
var createQuoteAction = createServerFn({ method: "POST" }).validator((d) => d).handler(createQuoteAction_createServerFn_handler, async ({ data }) => {
	try {
		return {
			success: true,
			data: await createQuote(data)
		};
	} catch (error) {
		console.error("Error creating quote:", error);
		return {
			success: false,
			error: "Failed to create quote"
		};
	}
});
var updateQuoteAction_createServerFn_handler = createServerRpc({
	id: "f2c7b8eb645901ff1b264169558edd0b9a5a3d802348b1645e280ad69b7c49f8",
	name: "updateQuoteAction",
	filename: "actions/quotes.ts"
}, (opts) => updateQuoteAction.__executeServer(opts));
var updateQuoteAction = createServerFn({ method: "POST" }).validator((d) => d).handler(updateQuoteAction_createServerFn_handler, async ({ data }) => {
	try {
		const { quoteId, ...updateData } = data;
		return {
			success: true,
			data: await updateQuote(quoteId, updateData)
		};
	} catch (error) {
		console.error("Error updating quote:", error);
		return {
			success: false,
			error: "Failed to update quote"
		};
	}
});
var deleteQuoteAction_createServerFn_handler = createServerRpc({
	id: "bd81548eab56db8f8b670e277c60efa81de4937a717e3e393c42902faeaee2d8",
	name: "deleteQuoteAction",
	filename: "actions/quotes.ts"
}, (opts) => deleteQuoteAction.__executeServer(opts));
var deleteQuoteAction = createServerFn({ method: "POST" }).validator((d) => d).handler(deleteQuoteAction_createServerFn_handler, async ({ data }) => {
	try {
		await deleteQuote(data.quoteId);
		return { success: true };
	} catch (error) {
		console.error("Error deleting quote:", error);
		return {
			success: false,
			error: "Failed to delete quote"
		};
	}
});
var toggleQuoteFavoriteAction_createServerFn_handler = createServerRpc({
	id: "115930e6ab838671b9e8597b1eb07fc45c277b9a70363eeef4c2af3f59707cfe",
	name: "toggleQuoteFavoriteAction",
	filename: "actions/quotes.ts"
}, (opts) => toggleQuoteFavoriteAction.__executeServer(opts));
var toggleQuoteFavoriteAction = createServerFn({ method: "POST" }).validator((d) => d).handler(toggleQuoteFavoriteAction_createServerFn_handler, async ({ data }) => {
	try {
		await toggleQuoteFavorite(data.quoteId);
		return { success: true };
	} catch (error) {
		console.error("Error toggling favorite:", error);
		return {
			success: false,
			error: "Failed to toggle favorite"
		};
	}
});
var getQuotesDataAction_createServerFn_handler = createServerRpc({
	id: "0f4470ee978b0ac56785452903cbd9c680bc6e3a5e9814d0549ab2d266344f2f",
	name: "getQuotesDataAction",
	filename: "actions/quotes.ts"
}, (opts) => getQuotesDataAction.__executeServer(opts));
var getQuotesDataAction = createServerFn({ method: "GET" }).handler(getQuotesDataAction_createServerFn_handler, async () => {
	const { getAllQuotes, getQuoteStats } = await import("./queries-CGoFn0cR.mjs").then((n) => n.b);
	const [quotes, stats] = await Promise.all([getAllQuotes(), getQuoteStats()]);
	return {
		quotes,
		stats
	};
});
//#endregion
export { createQuoteAction_createServerFn_handler, deleteQuoteAction_createServerFn_handler, getQuotesDataAction_createServerFn_handler, toggleQuoteFavoriteAction_createServerFn_handler, updateQuoteAction_createServerFn_handler };
