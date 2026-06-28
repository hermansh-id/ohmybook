import { n as createServerFn } from "./ssr.mjs";
import { t as createSsrRpc } from "./createSsrRpc-C1p7zOu_.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/reading-sessions-DGduYzP1.js
var getReadingSessionsAction = createServerFn({ method: "POST" }).validator((d) => d).handler(createSsrRpc("7b218efcbe2a3dd853960b5948497bea0c87a427cb21f76557d9829a21a81391"));
createServerFn({ method: "POST" }).validator((d) => d).handler(createSsrRpc("5d19854c6c65d6b8c9f9ba4b03fb305faf59c5bad6f5c2eaf254c1bad48eb876"));
var createReadingSessionAction = createServerFn({ method: "POST" }).validator((d) => d).handler(createSsrRpc("d212cfcf5d471e6286c41abb64a5dfee3e96fcf4d8ddd06ad55cabb2253eef8d"));
createServerFn({ method: "POST" }).validator((d) => d).handler(createSsrRpc("272174318505e75970f1c607abf95ae70aeb6d1a35929615fed51fba20d9d4e8"));
var deleteReadingSessionAction = createServerFn({ method: "POST" }).validator((d) => d).handler(createSsrRpc("ecd934a809c0df1df243deaca01561e04806c94eacc82fa2f7d2ddf8bbd93e86"));
var getUnfinishedBooksAction = createServerFn({ method: "GET" }).handler(createSsrRpc("a1a91c60c4233061b249bc33e3286c07227ffd67e89bed665d67168eec5295ff"));
//#endregion
export { getUnfinishedBooksAction as i, deleteReadingSessionAction as n, getReadingSessionsAction as r, createReadingSessionAction as t };
