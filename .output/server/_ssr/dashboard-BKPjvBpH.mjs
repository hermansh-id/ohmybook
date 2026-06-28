import { n as createServerFn, r as getRequest } from "./ssr.mjs";
import { t as createServerRpc } from "./createServerRpc-A6pJPYTF.mjs";
import { i as getUnfinishedBooksAction } from "./reading-sessions-DGduYzP1.mjs";
import { t as auth } from "./auth-CxVFL592.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/dashboard-BKPjvBpH.js
var getSessionFn_createServerFn_handler = createServerRpc({
	id: "9c28b1473383bc5c07ea09398e5b2fbf510bb68495b227ba0d986554f6290561",
	name: "getSessionFn",
	filename: "app/dashboard.tsx"
}, (opts) => getSessionFn.__executeServer(opts));
var getSessionFn = createServerFn({ method: "GET" }).handler(getSessionFn_createServerFn_handler, async () => {
	const request = getRequest();
	return auth.api.getSession({ headers: request.headers });
});
var getUnfinishedBooksFn_createServerFn_handler = createServerRpc({
	id: "2a617e3fd3720041aa42a69c48dba74533d1c05d0c50acdf8b9e5c953521e6b0",
	name: "getUnfinishedBooksFn",
	filename: "app/dashboard.tsx"
}, (opts) => getUnfinishedBooksFn.__executeServer(opts));
var getUnfinishedBooksFn = createServerFn({ method: "GET" }).handler(getUnfinishedBooksFn_createServerFn_handler, async () => {
	return getUnfinishedBooksAction();
});
//#endregion
export { getSessionFn_createServerFn_handler, getUnfinishedBooksFn_createServerFn_handler };
