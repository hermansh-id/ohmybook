import { n as createServerFn } from "./ssr.mjs";
import { t as createServerRpc } from "./createServerRpc-A6pJPYTF.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/calendar-xWtGFdX2.js
var getCalendarDataAction_createServerFn_handler = createServerRpc({
	id: "6c42d6417d44c4d66474a8d327f5ffa4b56a883088d443640616c585d6a3861b",
	name: "getCalendarDataAction",
	filename: "actions/calendar.ts"
}, (opts) => getCalendarDataAction.__executeServer(opts));
var getCalendarDataAction = createServerFn({ method: "GET" }).validator((d) => d).handler(getCalendarDataAction_createServerFn_handler, async ({ data }) => {
	const { getFinishedBooksByDate } = await import("./queries-CGoFn0cR.mjs").then((n) => n.b);
	return {
		books: await getFinishedBooksByDate(data.year, data.month),
		year: data.year,
		month: data.month
	};
});
//#endregion
export { getCalendarDataAction_createServerFn_handler };
