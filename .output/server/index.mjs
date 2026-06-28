globalThis.__nitro_main__ = import.meta.url;
import { a as toEventHandler, c as serve, i as defineLazyEventHandler, n as HTTPError, r as defineHandler, s as NodeResponse, t as H3Core } from "./_libs/h3+rou3+srvx.mjs";
import { i as withoutTrailingSlash, n as joinURL, r as withLeadingSlash, t as decodePath } from "./_libs/ufo.mjs";
import { promises } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";
//#region node_modules/nitro/dist/runtime/internal/route-rules.mjs
var headers = ((m) => function headersRouteRule(event) {
	for (const [key, value] of Object.entries(m.options || {})) event.res.headers.set(key, value);
});
//#endregion
//#region #nitro/virtual/public-assets-data
var public_assets_data_default = {
	"/fonts/Geist-Variable.woff2": {
		"type": "font/woff2",
		"etag": "\"11014-g6L/lNMioZihwpl0isu7iTswzeQ\"",
		"mtime": "2026-06-28T18:26:06.764Z",
		"size": 69652,
		"path": "../public/fonts/Geist-Variable.woff2"
	},
	"/globe.svg": {
		"type": "image/svg+xml",
		"etag": "\"40b-LrojsBpGczu4Qj5tOOv19+lavsU\"",
		"mtime": "2026-06-28T18:26:06.762Z",
		"size": 1035,
		"path": "../public/globe.svg"
	},
	"/next.svg": {
		"type": "image/svg+xml",
		"etag": "\"55f-Pz6VYiYSuYnFvWoDKZowjG88fms\"",
		"mtime": "2026-06-28T18:26:06.764Z",
		"size": 1375,
		"path": "../public/next.svg"
	},
	"/file.svg": {
		"type": "image/svg+xml",
		"etag": "\"187-+zgO7/6H1QtZc4NmTAKYKWTQ0ow\"",
		"mtime": "2026-06-28T18:26:06.762Z",
		"size": 391,
		"path": "../public/file.svg"
	},
	"/vercel.svg": {
		"type": "image/svg+xml",
		"etag": "\"80-zruIUtWMiIa+PpBRomlX9Cu4Lxo\"",
		"mtime": "2026-06-28T18:26:06.763Z",
		"size": 128,
		"path": "../public/vercel.svg"
	},
	"/window.svg": {
		"type": "image/svg+xml",
		"etag": "\"181-VMSODapsqjF/4bTEGQB/2T6Ujbk\"",
		"mtime": "2026-06-28T18:26:06.764Z",
		"size": 385,
		"path": "../public/window.svg"
	},
	"/assets/add-reading-session-dialog-CHkZjLzm.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"2f7e-hlVAo1r+DU9EneV58LkJstIP9eM\"",
		"mtime": "2026-06-28T18:26:05.023Z",
		"size": 12158,
		"path": "../public/assets/add-reading-session-dialog-CHkZjLzm.js"
	},
	"/assets/add-reading-session-form-PcwqSGij.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"39a8-V247Fe0jEO+k+dmg/pNm/z6wyFk\"",
		"mtime": "2026-06-28T18:26:05.023Z",
		"size": 14760,
		"path": "../public/assets/add-reading-session-form-PcwqSGij.js"
	},
	"/fonts/GeistMono-Variable.woff2": {
		"type": "font/woff2",
		"etag": "\"116c8-bziaItzNkolThMwmbCwxzRLfwyk\"",
		"mtime": "2026-06-28T18:26:06.763Z",
		"size": 71368,
		"path": "../public/fonts/GeistMono-Variable.woff2"
	},
	"/assets/_bookId-Bo3sBjo_.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"19a0-Z917Rmdeccu1LMVUJPFnVJxSb40\"",
		"mtime": "2026-06-28T18:26:05.022Z",
		"size": 6560,
		"path": "../public/assets/_bookId-Bo3sBjo_.js"
	},
	"/assets/authors-BoNREQqq.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"114-pIqRe5oKyszCCO8eKPi5sN+zgDE\"",
		"mtime": "2026-06-28T18:26:05.024Z",
		"size": 276,
		"path": "../public/assets/authors-BoNREQqq.js"
	},
	"/assets/arrow-up-nH-gUgbb.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"1c8-w1aD9BkE6EgPH8vc4ZOOYDCCKBg\"",
		"mtime": "2026-06-28T18:26:05.023Z",
		"size": 456,
		"path": "../public/assets/arrow-up-nH-gUgbb.js"
	},
	"/assets/app-DTSQRk2o.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"1fac-+9iDAcVr2kSXHJeWfHjOyarsEho\"",
		"mtime": "2026-06-28T18:26:05.023Z",
		"size": 8108,
		"path": "../public/assets/app-DTSQRk2o.js"
	},
	"/assets/auth-client-yvIaMzDc.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"6374-reFVzxdZwcQ7ZbqvbfoDXV1gPgo\"",
		"mtime": "2026-06-28T18:26:05.023Z",
		"size": 25460,
		"path": "../public/assets/auth-client-yvIaMzDc.js"
	},
	"/assets/add-CesKhT-7.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"69094-a81/2sAZHVubxIblH/J56hRiW/w\"",
		"mtime": "2026-06-28T18:26:05.022Z",
		"size": 430228,
		"path": "../public/assets/add-CesKhT-7.js"
	},
	"/assets/book-open-DJr82djz.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"117-oJLrpiKBBrb+pzQYJ9xbcjFVDI8\"",
		"mtime": "2026-06-28T18:26:05.024Z",
		"size": 279,
		"path": "../public/assets/book-open-DJr82djz.js"
	},
	"/assets/books-CvomnAzC.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"70cf-hIZ6ypgIzHI3EkelKE42tzi4Yx4\"",
		"mtime": "2026-06-28T18:26:05.024Z",
		"size": 28879,
		"path": "../public/assets/books-CvomnAzC.js"
	},
	"/assets/authors-DsPI0ibZ.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"1ad4-s+2+xx1H/3t2QnZBRDzI4c/lXL8\"",
		"mtime": "2026-06-28T18:26:05.024Z",
		"size": 6868,
		"path": "../public/assets/authors-DsPI0ibZ.js"
	},
	"/assets/badge-CcYgRXi6.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"4a4-IR0yCosiGKQLdex6YvxLU0zyV/Q\"",
		"mtime": "2026-06-28T18:26:05.024Z",
		"size": 1188,
		"path": "../public/assets/badge-CcYgRXi6.js"
	},
	"/assets/button-CXDm8Q4C.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"66f-POzpV+gmccyLOwURiFSH4Lj8SRA\"",
		"mtime": "2026-06-28T18:26:05.024Z",
		"size": 1647,
		"path": "../public/assets/button-CXDm8Q4C.js"
	},
	"/assets/chart-column-Ae4PhwVu.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"fb-TF5ytrmO97WFBqdmR2+wif+Oq0Y\"",
		"mtime": "2026-06-28T18:26:05.027Z",
		"size": 251,
		"path": "../public/assets/chart-column-Ae4PhwVu.js"
	},
	"/assets/chevron-right-7-L0nUQU.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"cf-17QSPDhrTGedFe0ly8VYjRVZdac\"",
		"mtime": "2026-06-28T18:26:05.027Z",
		"size": 207,
		"path": "../public/assets/chevron-right-7-L0nUQU.js"
	},
	"/assets/card-Dq8fDv5q.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"464-+PTndxX1/qGpkvBUfNFrjg4uWJg\"",
		"mtime": "2026-06-28T18:26:05.026Z",
		"size": 1124,
		"path": "../public/assets/card-Dq8fDv5q.js"
	},
	"/assets/calendar-DEQQz1lC.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"2142-pUtdTQAdd9Y9DDmRBM+q7b2LCKI\"",
		"mtime": "2026-06-28T18:26:05.026Z",
		"size": 8514,
		"path": "../public/assets/calendar-DEQQz1lC.js"
	},
	"/assets/calendar-9CLSdVf2.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"101-Zdwz4nJz/VdJE2GRcuqbb+1GTBg\"",
		"mtime": "2026-06-28T18:26:05.025Z",
		"size": 257,
		"path": "../public/assets/calendar-9CLSdVf2.js"
	},
	"/assets/chevrons-up-down-CcwcMRq2.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"ae-Znw6GmUPEf1t7VCLS99IusNDevY\"",
		"mtime": "2026-06-28T18:26:05.027Z",
		"size": 174,
		"path": "../public/assets/chevrons-up-down-CcwcMRq2.js"
	},
	"/assets/clock-DdgNpUPY.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"a9-ZlAT2t15p6HJ/bkf0VJvJsgtOII\"",
		"mtime": "2026-06-28T18:26:05.027Z",
		"size": 169,
		"path": "../public/assets/clock-DdgNpUPY.js"
	},
	"/assets/dialog-CXJ445wZ.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"30e8-SY2OR/Vno88cGvzBTE8444e1LeA\"",
		"mtime": "2026-06-28T18:26:05.030Z",
		"size": 12520,
		"path": "../public/assets/dialog-CXJ445wZ.js"
	},
	"/assets/createServerFn-BwA-uHPj.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"8d7d-FaMQKXlDi//pgCFbLU8SZLshyUs\"",
		"mtime": "2026-06-28T18:26:05.028Z",
		"size": 36221,
		"path": "../public/assets/createServerFn-BwA-uHPj.js"
	},
	"/assets/dashboard-DdkmcbfA.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"dbc3-8j9OhH3p44XY2vFJIuVBClniD5c\"",
		"mtime": "2026-06-28T18:26:05.029Z",
		"size": 56259,
		"path": "../public/assets/dashboard-DdkmcbfA.js"
	},
	"/assets/dashboard-1e7q0WWi.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"79dd-WAThHJTPj1eZjz/OSPJYGknW9sM\"",
		"mtime": "2026-06-28T18:26:05.028Z",
		"size": 31197,
		"path": "../public/assets/dashboard-1e7q0WWi.js"
	},
	"/assets/dist-CU4Hiust.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"2e4e-a05wucatdF6s2KxOuSLMpx3U6No\"",
		"mtime": "2026-06-28T18:26:05.031Z",
		"size": 11854,
		"path": "../public/assets/dist-CU4Hiust.js"
	},
	"/assets/dist-twEiPGkt.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"e0e9-w5uexW/o6xMSfHeYmUqiVDpiYug\"",
		"mtime": "2026-06-28T18:26:05.032Z",
		"size": 57577,
		"path": "../public/assets/dist-twEiPGkt.js"
	},
	"/assets/download-HjOsAYzu.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"e8-I0cX81nPqudr2l4S+DFwnil3qEE\"",
		"mtime": "2026-06-28T18:26:05.032Z",
		"size": 232,
		"path": "../public/assets/download-HjOsAYzu.js"
	},
	"/assets/dist-CeF8MQzX.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"3fc-PwvZss5HeWsoD/XM20/OCLQMgcA\"",
		"mtime": "2026-06-28T18:26:05.031Z",
		"size": 1020,
		"path": "../public/assets/dist-CeF8MQzX.js"
	},
	"/assets/external-link-CcsubwRi.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"fb-7VsSpiEtB4Exf8EN5Sd0G9QeW6w\"",
		"mtime": "2026-06-28T18:26:05.032Z",
		"size": 251,
		"path": "../public/assets/external-link-CcsubwRi.js"
	},
	"/assets/file-text-ClR6OUtZ.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"181-/HzNx6N3YqvYyqS5Ya7RmL1Egsg\"",
		"mtime": "2026-06-28T18:26:05.032Z",
		"size": 385,
		"path": "../public/assets/file-text-ClR6OUtZ.js"
	},
	"/assets/dist-BBLLvJk1.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"1849-/LfhyWMZXECwHzzngNqoNuRmDwQ\"",
		"mtime": "2026-06-28T18:26:05.031Z",
		"size": 6217,
		"path": "../public/assets/dist-BBLLvJk1.js"
	},
	"/assets/dropdown-menu-wAnDkxgG.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"63b8-e7/RvCTBp0EanQU0GgkYdOc0k7A\"",
		"mtime": "2026-06-28T18:26:05.032Z",
		"size": 25528,
		"path": "../public/assets/dropdown-menu-wAnDkxgG.js"
	},
	"/assets/genres-C11iTY0-.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"1a42-x6Zw7MsldtH4sFcuscJmuLsYEyE\"",
		"mtime": "2026-06-28T18:26:05.033Z",
		"size": 6722,
		"path": "../public/assets/genres-C11iTY0-.js"
	},
	"/assets/genres-C92gOHR6.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"179-pE+5ILRYwJsioMRLSnMDO+8mXCU\"",
		"mtime": "2026-06-28T18:26:05.035Z",
		"size": 377,
		"path": "../public/assets/genres-C92gOHR6.js"
	},
	"/assets/globals-BQl_4yUe.css": {
		"type": "text/css; charset=utf-8",
		"etag": "\"206a0-rY9oXk/UavGfc0o4x4hNwel11IU\"",
		"mtime": "2026-06-28T18:26:05.060Z",
		"size": 132768,
		"path": "../public/assets/globals-BQl_4yUe.css"
	},
	"/assets/createLucideIcon-C2aNlAKu.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"4a2-YydcACMNdwhnsKI9bgkscRi6mo0\"",
		"mtime": "2026-06-28T18:26:05.028Z",
		"size": 1186,
		"path": "../public/assets/createLucideIcon-C2aNlAKu.js"
	},
	"/assets/invariant-DEEwAagU.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"3c-eVh/3DMi1s3cxf4N/OJar+ew1jA\"",
		"mtime": "2026-06-28T18:26:05.040Z",
		"size": 60,
		"path": "../public/assets/invariant-DEEwAagU.js"
	},
	"/assets/label-BUSNSMsE.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"43a-bVpIfK5OKT4VUScYnhlB4Hx2ahM\"",
		"mtime": "2026-06-28T18:26:05.042Z",
		"size": 1082,
		"path": "../public/assets/label-BUSNSMsE.js"
	},
	"/assets/jsx-runtime-DWL-0PYl.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"2157-x/rSLMaXw2OkJk00bebdowJc7mE\"",
		"mtime": "2026-06-28T18:26:05.042Z",
		"size": 8535,
		"path": "../public/assets/jsx-runtime-DWL-0PYl.js"
	},
	"/assets/link-Bl40zoBX.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"58d3-hKS/gwI5flS9FfAEY+CYoBZYHqw\"",
		"mtime": "2026-06-28T18:26:05.042Z",
		"size": 22739,
		"path": "../public/assets/link-Bl40zoBX.js"
	},
	"/assets/input-SxJqap6v.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"35b-CtJCUwSkyfFGwy/CIrhTCwgBa50\"",
		"mtime": "2026-06-28T18:26:05.040Z",
		"size": 859,
		"path": "../public/assets/input-SxJqap6v.js"
	},
	"/assets/index-HCIlBLFv.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"5c869-2axIgwAMle/CS6NLBaBHZVe9TuQ\"",
		"mtime": "2026-06-28T18:26:05.021Z",
		"size": 378985,
		"path": "../public/assets/index-HCIlBLFv.js"
	},
	"/assets/flame-BC58PI5A.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"c7-cMXYKF0Nd0hI4PEZVgafoUYBOQ4\"",
		"mtime": "2026-06-28T18:26:05.033Z",
		"size": 199,
		"path": "../public/assets/flame-BC58PI5A.js"
	},
	"/assets/pencil-0VI2to1E.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"114-zgr7i58Ge4iNKPsm9tQ9Dh60UUo\"",
		"mtime": "2026-06-28T18:26:05.045Z",
		"size": 276,
		"path": "../public/assets/pencil-0VI2to1E.js"
	},
	"/assets/login-DeRO8xi6.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"120b-kVqHcOCWvh1aWau34DIa+984pXI\"",
		"mtime": "2026-06-28T18:26:05.044Z",
		"size": 4619,
		"path": "../public/assets/login-DeRO8xi6.js"
	},
	"/assets/quote-DAfJl7lY.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"185-kJki96Gp/x/21ko57NtHdZaAjC4\"",
		"mtime": "2026-06-28T18:26:05.045Z",
		"size": 389,
		"path": "../public/assets/quote-DAfJl7lY.js"
	},
	"/assets/react-dom-BdlzS5am.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"dda-qB4EzSLcnEeUF1PahqJ7fAiknqg\"",
		"mtime": "2026-06-28T18:26:05.045Z",
		"size": 3546,
		"path": "../public/assets/react-dom-BdlzS5am.js"
	},
	"/assets/quotes-DOur1yz8.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"4b04-h0JN8qzr/axMMiyqKuXngYc4+O4\"",
		"mtime": "2026-06-28T18:26:05.045Z",
		"size": 19204,
		"path": "../public/assets/quotes-DOur1yz8.js"
	},
	"/assets/plus-CyCFtlnm.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"99-JH7NedTUMorCs2PuzOH0tthlGmg\"",
		"mtime": "2026-06-28T18:26:05.045Z",
		"size": 153,
		"path": "../public/assets/plus-CyCFtlnm.js"
	},
	"/assets/reading-log-6JPzfhlx.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"20e2-7HDnNqZQ2OboTvHODhm8x3Nbhxo\"",
		"mtime": "2026-06-28T18:26:05.046Z",
		"size": 8418,
		"path": "../public/assets/reading-log-6JPzfhlx.js"
	},
	"/assets/recommendations-CBTfO_a7.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"ba5-SxnwPIJKCrkwuEp3psMC/cgRKQY\"",
		"mtime": "2026-06-28T18:26:05.046Z",
		"size": 2981,
		"path": "../public/assets/recommendations-CBTfO_a7.js"
	},
	"/assets/loader-circle-DJfgvMmh.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"90-cC38rhFEbBV2DOd+9P4iFOvxk2w\"",
		"mtime": "2026-06-28T18:26:05.043Z",
		"size": 144,
		"path": "../public/assets/loader-circle-DJfgvMmh.js"
	},
	"/assets/reading-history-chart-Cvv1VXZu.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"615f6-6Os9/AN6BX47JcPgGOGh51umL7U\"",
		"mtime": "2026-06-28T18:26:05.045Z",
		"size": 398838,
		"path": "../public/assets/reading-history-chart-Cvv1VXZu.js"
	},
	"/assets/select-zks42xBK.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"7454-Tpgb9OGz6ozRWbtv0sPXzPPvNDg\"",
		"mtime": "2026-06-28T18:26:05.046Z",
		"size": 29780,
		"path": "../public/assets/select-zks42xBK.js"
	},
	"/assets/separator-CD1OSxNR.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"4b6-6zzj2gc2/R770FzbTyHwjpmbVOs\"",
		"mtime": "2026-06-28T18:26:05.046Z",
		"size": 1206,
		"path": "../public/assets/separator-CD1OSxNR.js"
	},
	"/assets/settings-C3rmTUoT.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"1e7-V0uA9IvQx0cmiFJLFvPgI03JKiM\"",
		"mtime": "2026-06-28T18:26:05.046Z",
		"size": 487,
		"path": "../public/assets/settings-C3rmTUoT.js"
	},
	"/assets/settings-Dv0UXCin.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"143f-PmE6sYuX9igdOeufQDnupt37l9M\"",
		"mtime": "2026-06-28T18:26:05.047Z",
		"size": 5183,
		"path": "../public/assets/settings-Dv0UXCin.js"
	},
	"/assets/share-2-CcDHPI6m.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"165-di5fP0o9xwS2pq29B9Uveoo9M8s\"",
		"mtime": "2026-06-28T18:26:05.048Z",
		"size": 357,
		"path": "../public/assets/share-2-CcDHPI6m.js"
	},
	"/assets/skeleton-D0xMTbNC.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"f2-NmNdPA6XNcqqrWnjRDvIdJJ6gTs\"",
		"mtime": "2026-06-28T18:26:05.048Z",
		"size": 242,
		"path": "../public/assets/skeleton-D0xMTbNC.js"
	},
	"/assets/star-D_Ytg2-M.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"1d8-OSHUTeO5CYsMNmhJxynWPE792SM\"",
		"mtime": "2026-06-28T18:26:05.049Z",
		"size": 472,
		"path": "../public/assets/star-D_Ytg2-M.js"
	},
	"/assets/statistics-CfqConr9.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"5aa3-HCFFuM2gCmaSNqXx43XfCzQnOt4\"",
		"mtime": "2026-06-28T18:26:05.050Z",
		"size": 23203,
		"path": "../public/assets/statistics-CfqConr9.js"
	},
	"/assets/table-zg4kt_-Y.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"c8ca-41oaSV1F/Izo7F76yTJ79GbzPxk\"",
		"mtime": "2026-06-28T18:26:05.050Z",
		"size": 51402,
		"path": "../public/assets/table-zg4kt_-Y.js"
	},
	"/assets/tag-CX5qY6tI.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"146-XF/3f22lOdiOwE4alB3OHVNBTaM\"",
		"mtime": "2026-06-28T18:26:05.050Z",
		"size": 326,
		"path": "../public/assets/tag-CX5qY6tI.js"
	},
	"/assets/target-LcP2jjxt.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"e2-kZ8x19OV+ab/PK0OfEugfIvYEjA\"",
		"mtime": "2026-06-28T18:26:05.050Z",
		"size": 226,
		"path": "../public/assets/target-LcP2jjxt.js"
	},
	"/assets/trending-up-Cxua4NxM.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"af-Gdq7YqFHjfvv1sFMzl252iTe+VY\"",
		"mtime": "2026-06-28T18:26:05.051Z",
		"size": 175,
		"path": "../public/assets/trending-up-Cxua4NxM.js"
	},
	"/assets/useMutation-cegXhMv_.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"843-x0SZmSYNC1ZlBDKFgTgeNo8H9rk\"",
		"mtime": "2026-06-28T18:26:05.051Z",
		"size": 2115,
		"path": "../public/assets/useMutation-cegXhMv_.js"
	},
	"/assets/useQuery-BS-OLxEC.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"21e8-fhpzGRbUGXdd5HFN7TuNY2qxe3I\"",
		"mtime": "2026-06-28T18:26:05.052Z",
		"size": 8680,
		"path": "../public/assets/useQuery-BS-OLxEC.js"
	},
	"/assets/users-DaeVlr_u.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"132-69IVdF7lEp8+hBMaBosABzKSBjc\"",
		"mtime": "2026-06-28T18:26:05.053Z",
		"size": 306,
		"path": "../public/assets/users-DaeVlr_u.js"
	},
	"/assets/useRouter-7Y4uKbXC.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"2b2-Uu28bcGb5hNr7TeN6SwxjJ8zdhw\"",
		"mtime": "2026-06-28T18:26:05.052Z",
		"size": 690,
		"path": "../public/assets/useRouter-7Y4uKbXC.js"
	},
	"/assets/use-mobile-8hvLZ9Rl.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"154-SCvS+EI1gPuchKmJEIghzgLA2NQ\"",
		"mtime": "2026-06-28T18:26:05.051Z",
		"size": 340,
		"path": "../public/assets/use-mobile-8hvLZ9Rl.js"
	},
	"/assets/trash-2-CBa-aPri.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"148-f5KhNO4UD8Fm4sV7dqk1BV7zxdQ\"",
		"mtime": "2026-06-28T18:26:05.051Z",
		"size": 328,
		"path": "../public/assets/trash-2-CBa-aPri.js"
	},
	"/assets/utils-CLpGte51.js": {
		"type": "text/javascript; charset=utf-8",
		"etag": "\"6d54-zxDWUyqUPGF4WixzJOaK7FFlyn0\"",
		"mtime": "2026-06-28T18:26:05.053Z",
		"size": 27988,
		"path": "../public/assets/utils-CLpGte51.js"
	}
};
//#endregion
//#region #nitro/virtual/public-assets-node
function readAsset(id) {
	const serverDir = dirname(fileURLToPath(globalThis.__nitro_main__));
	return promises.readFile(resolve(serverDir, public_assets_data_default[id].path));
}
//#endregion
//#region #nitro/virtual/public-assets
var publicAssetBases = {};
function isPublicAssetURL(id = "") {
	if (public_assets_data_default[id]) return true;
	for (const base in publicAssetBases) if (id.startsWith(base)) return true;
	return false;
}
function getAsset(id) {
	return public_assets_data_default[id];
}
//#endregion
//#region node_modules/nitro/dist/runtime/internal/static.mjs
var METHODS = new Set(["HEAD", "GET"]);
var EncodingMap = {
	gzip: ".gz",
	br: ".br",
	zstd: ".zst"
};
var static_default = defineHandler((event) => {
	if (event.req.method && !METHODS.has(event.req.method)) return;
	let id = decodePath(withLeadingSlash(withoutTrailingSlash(event.url.pathname)));
	let asset;
	const encodings = [...(event.req.headers.get("accept-encoding") || "").split(",").map((e) => EncodingMap[e.trim()]).filter(Boolean).sort(), ""];
	for (const encoding of encodings) for (const _id of [id + encoding, joinURL(id, "index.html" + encoding)]) {
		const _asset = getAsset(_id);
		if (_asset) {
			asset = _asset;
			id = _id;
			break;
		}
	}
	if (!asset) {
		if (isPublicAssetURL(id)) {
			event.res.headers.delete("Cache-Control");
			throw new HTTPError({ status: 404 });
		}
		return;
	}
	if (encodings.length > 1) event.res.headers.append("Vary", "Accept-Encoding");
	if (event.req.headers.get("if-none-match") === asset.etag) {
		event.res.status = 304;
		event.res.statusText = "Not Modified";
		return "";
	}
	const ifModifiedSinceH = event.req.headers.get("if-modified-since");
	const mtimeDate = new Date(asset.mtime);
	if (ifModifiedSinceH && asset.mtime && new Date(ifModifiedSinceH) >= mtimeDate) {
		event.res.status = 304;
		event.res.statusText = "Not Modified";
		return "";
	}
	if (asset.type) event.res.headers.set("Content-Type", asset.type);
	if (asset.etag && !event.res.headers.has("ETag")) event.res.headers.set("ETag", asset.etag);
	if (asset.mtime && !event.res.headers.has("Last-Modified")) event.res.headers.set("Last-Modified", mtimeDate.toUTCString());
	if (asset.encoding && !event.res.headers.has("Content-Encoding")) event.res.headers.set("Content-Encoding", asset.encoding);
	if (asset.size > 0 && !event.res.headers.has("Content-Length")) event.res.headers.set("Content-Length", asset.size.toString());
	return readAsset(id);
});
//#endregion
//#region #nitro/virtual/routing
var findRouteRules = /* @__PURE__ */ (() => {
	const $0 = [{
		name: "headers",
		route: "/assets/**",
		handler: headers,
		options: { "cache-control": "public, max-age=31536000, immutable" }
	}];
	return (m, p) => {
		let r = [];
		if (p.charCodeAt(p.length - 1) === 47) p = p.slice(0, -1) || "/";
		let s = p.split("/");
		if (s.length > 1) {
			if (s[1] === "assets") r.unshift({
				data: $0,
				params: { "_": s.slice(2).join("/") }
			});
		}
		return r;
	};
})();
var _lazy_U_a72W = defineLazyEventHandler(() => import("./_chunks/ssr-renderer.mjs"));
var findRoute = /* @__PURE__ */ (() => {
	const data = {
		route: "/**",
		handler: _lazy_U_a72W
	};
	return ((_m, p) => {
		return {
			data,
			params: { "_": p.slice(1) }
		};
	});
})();
var globalMiddleware = [toEventHandler(static_default)].filter(Boolean);
//#endregion
//#region node_modules/nitro/dist/runtime/internal/error/prod.mjs
var errorHandler = (error, event) => {
	const res = defaultHandler(error, event);
	return new NodeResponse(typeof res.body === "string" ? res.body : JSON.stringify(res.body, null, 2), res);
};
function defaultHandler(error, event) {
	const unhandled = error.unhandled ?? !HTTPError.isError(error);
	const { status = 500, statusText = "" } = unhandled ? {} : error;
	if (status === 404) {
		const url = event.url || new URL(event.req.url);
		const baseURL = "/";
		if (/^\/[^/]/.test(baseURL) && !url.pathname.startsWith(baseURL)) return {
			status: 302,
			headers: new Headers({ location: `${baseURL}${url.pathname.slice(1)}${url.search}` })
		};
	}
	const headers = new Headers(unhandled ? {} : error.headers);
	headers.set("content-type", "application/json; charset=utf-8");
	return {
		status,
		statusText,
		headers,
		body: {
			error: true,
			...unhandled ? {
				status,
				unhandled: true
			} : typeof error.toJSON === "function" ? error.toJSON() : {
				status,
				statusText,
				message: error.message
			}
		}
	};
}
//#endregion
//#region #nitro/virtual/error-handler
var errorHandlers = [errorHandler];
async function error_handler_default(error, event) {
	for (const handler of errorHandlers) try {
		const response = await handler(error, event, { defaultHandler });
		if (response) return response;
	} catch (error) {
		console.error(error);
	}
}
//#endregion
//#region #nitro/virtual/app
function createNitroApp() {
	const captureError = (error, errorCtx) => {
		if (errorCtx?.event) {
			const errors = errorCtx.event.req.context?.nitro?.errors;
			if (errors) errors.push({
				error,
				context: errorCtx
			});
		}
	};
	const h3App = createH3App({ onError(error, event) {
		return error_handler_default(error, event);
	} });
	let appHandler = (req) => {
		req.context ||= {};
		req.context.nitro = req.context.nitro || { errors: [] };
		return h3App.fetch(req);
	};
	return {
		fetch: appHandler,
		h3: h3App,
		hooks: void 0,
		captureError
	};
}
function createH3App(config) {
	const h3App = new H3Core(config);
	h3App["~findRoute"] = (event) => findRoute(event.req.method, event.url.pathname);
	h3App["~middleware"].push(...globalMiddleware);
	h3App["~getMiddleware"] = (event, route) => {
		const pathname = event.url.pathname;
		const method = event.req.method;
		const middleware = [];
		const routeRules = getRouteRules(method, pathname);
		event.context.routeRules = routeRules?.routeRules;
		if (routeRules?.routeRuleMiddleware.length) middleware.push(...routeRules.routeRuleMiddleware);
		middleware.push(...h3App["~middleware"]);
		if (route?.data?.middleware?.length) middleware.push(...route.data.middleware);
		return middleware;
	};
	return h3App;
}
//#endregion
//#region node_modules/nitro/dist/runtime/internal/app.mjs
var APP_ID = "default";
function useNitroApp() {
	let instance = useNitroApp._instance;
	if (instance) return instance;
	instance = useNitroApp._instance = createNitroApp();
	globalThis.__nitro__ = globalThis.__nitro__ || {};
	globalThis.__nitro__[APP_ID] = instance;
	return instance;
}
function getRouteRules(method, pathname) {
	const m = findRouteRules(method, pathname);
	if (!m?.length) return { routeRuleMiddleware: [] };
	const routeRules = {};
	for (const layer of m) for (const rule of layer.data) {
		const currentRule = routeRules[rule.name];
		if (currentRule) {
			if (rule.options === false) {
				delete routeRules[rule.name];
				continue;
			}
			if (typeof currentRule.options === "object" && typeof rule.options === "object") currentRule.options = {
				...currentRule.options,
				...rule.options
			};
			else currentRule.options = rule.options;
			currentRule.route = rule.route;
			currentRule.params = {
				...currentRule.params,
				...layer.params
			};
		} else if (rule.options !== false) routeRules[rule.name] = {
			...rule,
			params: layer.params
		};
	}
	const middleware = [];
	const orderedRules = Object.values(routeRules).sort((a, b) => (a.handler?.order || 0) - (b.handler?.order || 0));
	for (const rule of orderedRules) {
		if (rule.options === false || !rule.handler) continue;
		middleware.push(rule.handler(rule));
	}
	return {
		routeRules,
		routeRuleMiddleware: middleware
	};
}
//#endregion
//#region node_modules/nitro/dist/runtime/internal/error/hooks.mjs
function _captureError(error, type) {
	console.error(`[${type}]`, error);
	useNitroApp().captureError?.(error, { tags: [type] });
}
function trapUnhandledErrors() {
	process.on("unhandledRejection", (error) => _captureError(error, "unhandledRejection"));
	process.on("uncaughtException", (error) => _captureError(error, "uncaughtException"));
}
//#endregion
//#region #nitro/virtual/tracing
var tracingSrvxPlugins = [];
//#endregion
//#region node_modules/nitro/dist/presets/node/runtime/node-server.mjs
var _parsedPort = Number.parseInt(process.env.NITRO_PORT ?? process.env.PORT ?? "");
var port = Number.isNaN(_parsedPort) ? 3e3 : _parsedPort;
var host = process.env.NITRO_HOST || process.env.HOST;
var cert = process.env.NITRO_SSL_CERT;
var key = process.env.NITRO_SSL_KEY;
var nitroApp = useNitroApp();
serve({
	port,
	hostname: host,
	tls: cert && key ? {
		cert,
		key
	} : void 0,
	fetch: nitroApp.fetch,
	plugins: [...tracingSrvxPlugins]
});
trapUnhandledErrors();
var node_server_default = {};
//#endregion
export { node_server_default as default };
