import { A as redirect, f as lazyRouteComponent, p as createFileRoute } from "./_libs/@tanstack/react-router+[...].mjs";
import { o as getBookDetailsAction } from "./_ssr/books-B1VN5UCC.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/_bookId-C7OasE3q.js
var $$splitComponentImporter = () => import("./_bookId-Dv24Acka.mjs");
var Route = createFileRoute("/dashboard/books/$bookId")({
	loader: async ({ params }) => {
		const id = parseInt(params.bookId);
		if (isNaN(id)) throw redirect({ to: "/dashboard/books" });
		try {
			return { book: await getBookDetailsAction(id) };
		} catch (error) {
			throw redirect({ to: "/dashboard/books" });
		}
	},
	component: lazyRouteComponent($$splitComponentImporter, "component")
});
//#endregion
export { Route as t };
