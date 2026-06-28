import { n as createServerFn } from "./ssr.mjs";
import { t as createSsrRpc } from "./createSsrRpc-C1p7zOu_.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/genres-DLeE_Pci.js
var getGenresAction = createServerFn({ method: "GET" }).handler(createSsrRpc("600b96fe6bc263f507bb4e51b8c075cf8f2e48a9187c9a11c7b53763f7f15193"));
var addGenre = createServerFn({ method: "POST" }).validator((d) => d).handler(createSsrRpc("b6aec75738ca1669be65b3d0f67ffe736a5c36811a9dc9faab788289ac9d6b61"));
var getGenresWithStatsAction = createServerFn({ method: "GET" }).handler(createSsrRpc("d122679c877b5eff4dc661a1f67cbb4741a21118c8425755ead1d88e971adab3"));
//#endregion
export { getGenresAction as n, getGenresWithStatsAction as r, addGenre as t };
