import { n as createServerFn } from "./ssr.mjs";
import { t as createSsrRpc } from "./createSsrRpc-C1p7zOu_.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/books-B1VN5UCC.js
var getBooksAction = createServerFn({ method: "GET" }).handler(createSsrRpc("64c1a81f41d7945c6599cdc9accacb77d3f379b3c55715a5eca6b2793c7d2cdc"));
var getBookDetailsAction = createServerFn({ method: "POST" }).validator((d) => d).handler(createSsrRpc("01b4e14b547ad387aa616cc01c9b1184ef251522917acba268803640ff9c1fcd"));
var updateBookStatusAction = createServerFn({ method: "POST" }).validator((d) => d).handler(createSsrRpc("3aec4fda845b3b79029767b1631f2ed52ead4795abcc913ad48262da0513c2b7"));
var addBookAction = createServerFn({ method: "POST" }).validator((d) => d).handler(createSsrRpc("f9a652bd6c68118253acd1a18c6c6bd28438dbe99bd7d676834d326f0cdac1cf"));
var deleteBookAction = createServerFn({ method: "POST" }).validator((d) => d).handler(createSsrRpc("d6146983f8b22455437a1988e1f3466992ab3e27e6467b8a7f375e9174e93e3d"));
var updateBookAction = createServerFn({ method: "POST" }).validator((d) => d).handler(createSsrRpc("d5ba42d20fd11e37d18480c1898593ec5b7e197e5a1f9780773a43871e68ac92"));
var getAllBooksAction = createServerFn({ method: "GET" }).handler(createSsrRpc("66d04371c9608bca006fd7d63cf64d303131177821e1b7c7783aa3eb17a241df"));
var getAuthorsAction = createServerFn({ method: "GET" }).handler(createSsrRpc("90b4c5be81c06c15b87f34bcf817bfd7c9b860290525bc9ea5ce52360fc51c66"));
var lookupBookByISBN = createServerFn({ method: "POST" }).validator((d) => d).handler(createSsrRpc("b565a49351db7f478bbd7dfdec3ee323909f94ecf1c49513f55ed61e421dd23c"));
var getReadingRecommendationsAction = createServerFn({ method: "GET" }).handler(createSsrRpc("5a9102dcd3bbfcf6cfaff03a9c891747003fca59cd540e0e275a50f9434d0dc7"));
var lookupBookByGoodreadsUrl = createServerFn({ method: "POST" }).validator((d) => d).handler(createSsrRpc("195a49472d00f6fde35f852382d67f4caf379b9684817d6741ece871e4484fce"));
var fetchGoodreadsDataAction = createServerFn({ method: "POST" }).validator((d) => d).handler(createSsrRpc("e8a8221e2251a48f4a05c68b76e7bbe0714b1c940df2717ef309bfac8ac249bd"));
//#endregion
export { getAuthorsAction as a, getReadingRecommendationsAction as c, updateBookAction as d, updateBookStatusAction as f, getAllBooksAction as i, lookupBookByGoodreadsUrl as l, deleteBookAction as n, getBookDetailsAction as o, fetchGoodreadsDataAction as r, getBooksAction as s, addBookAction as t, lookupBookByISBN as u };
