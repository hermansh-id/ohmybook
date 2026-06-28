import { A as redirect, f as lazyRouteComponent, p as createFileRoute } from "../_libs/@tanstack/react-router+[...].mjs";
import { n as createServerFn } from "./ssr.mjs";
import { t as createSsrRpc } from "./createSsrRpc-C1p7zOu_.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/dashboard-C6y-StmE.js
var $$splitComponentImporter = () => import("./dashboard-DSjA5bZA.mjs");
var getSessionFn = createServerFn({ method: "GET" }).handler(createSsrRpc("9c28b1473383bc5c07ea09398e5b2fbf510bb68495b227ba0d986554f6290561"));
var getUnfinishedBooksFn = createServerFn({ method: "GET" }).handler(createSsrRpc("2a617e3fd3720041aa42a69c48dba74533d1c05d0c50acdf8b9e5c953521e6b0"));
var Route = createFileRoute("/dashboard")({
	beforeLoad: async () => {
		const session = await getSessionFn();
		if (!session) throw redirect({ to: "/login" });
		return { user: session.user };
	},
	loader: async () => {
		return { unfinishedBooks: await getUnfinishedBooksFn() };
	},
	component: lazyRouteComponent($$splitComponentImporter, "component")
});
//#endregion
export { Route as t };
