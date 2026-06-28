import { n as createServerFn } from "./ssr.mjs";
import { t as createSsrRpc } from "./createSsrRpc-C1p7zOu_.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/authors-CvrsKKX8.js
var addAuthor = createServerFn({ method: "POST" }).validator((d) => d).handler(createSsrRpc("9a03d43cf1f7201da32f130d08605e61c2f3187415ec98af61e9e8a161620e1b"));
var getAuthorsWithStatsAction = createServerFn({ method: "GET" }).handler(createSsrRpc("135805530c9e9062a7fa69e30dc674290514d842344e6d4d291143519a35822e"));
//#endregion
export { getAuthorsWithStatsAction as n, addAuthor as t };
