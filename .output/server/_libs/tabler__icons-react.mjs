import { o as __toESM } from "../_runtime.mjs";
import { u as require_react } from "./@floating-ui/react-dom+[...].mjs";
//#region node_modules/@tabler/icons-react/dist/esm/defaultAttributes.mjs
var import_react = /* @__PURE__ */ __toESM(require_react(), 1);
/**
* @license @tabler/icons-react v3.36.0 - MIT
*
* This source code is licensed under the MIT license.
* See the LICENSE file in the root directory of this source tree.
*/
var defaultAttributes = {
	outline: {
		xmlns: "http://www.w3.org/2000/svg",
		width: 24,
		height: 24,
		viewBox: "0 0 24 24",
		fill: "none",
		stroke: "currentColor",
		strokeWidth: 2,
		strokeLinecap: "round",
		strokeLinejoin: "round"
	},
	filled: {
		xmlns: "http://www.w3.org/2000/svg",
		width: 24,
		height: 24,
		viewBox: "0 0 24 24",
		fill: "currentColor",
		stroke: "none"
	}
};
//#endregion
//#region node_modules/@tabler/icons-react/dist/esm/createReactComponent.mjs
/**
* @license @tabler/icons-react v3.36.0 - MIT
*
* This source code is licensed under the MIT license.
* See the LICENSE file in the root directory of this source tree.
*/
var createReactComponent = (type, iconName, iconNamePascal, iconNode) => {
	const Component = (0, import_react.forwardRef)(({ color = "currentColor", size = 24, stroke = 2, title, className, children, ...rest }, ref) => (0, import_react.createElement)("svg", {
		ref,
		...defaultAttributes[type],
		width: size,
		height: size,
		className: [
			`tabler-icon`,
			`tabler-icon-${iconName}`,
			className
		].join(" "),
		...type === "filled" ? { fill: color } : {
			strokeWidth: stroke,
			stroke: color
		},
		...rest
	}, [
		title && (0, import_react.createElement)("title", { key: "svg-title" }, title),
		...iconNode.map(([tag, attrs]) => (0, import_react.createElement)(tag, attrs)),
		...Array.isArray(children) ? children : [children]
	]));
	Component.displayName = `${iconNamePascal}`;
	return Component;
};
/**
* @license @tabler/icons-react v3.36.0 - MIT
*
* This source code is licensed under the MIT license.
* See the LICENSE file in the root directory of this source tree.
*/
var IconBook = createReactComponent("outline", "book", "Book", [
	["path", {
		"d": "M3 19a9 9 0 0 1 9 0a9 9 0 0 1 9 0",
		"key": "svg-0"
	}],
	["path", {
		"d": "M3 6a9 9 0 0 1 9 0a9 9 0 0 1 9 0",
		"key": "svg-1"
	}],
	["path", {
		"d": "M3 6l0 13",
		"key": "svg-2"
	}],
	["path", {
		"d": "M12 6l0 13",
		"key": "svg-3"
	}],
	["path", {
		"d": "M21 6l0 13",
		"key": "svg-4"
	}]
]);
/**
* @license @tabler/icons-react v3.36.0 - MIT
*
* This source code is licensed under the MIT license.
* See the LICENSE file in the root directory of this source tree.
*/
var IconBulb = createReactComponent("outline", "bulb", "Bulb", [
	["path", {
		"d": "M3 12h1m8 -9v1m8 8h1m-15.4 -6.4l.7 .7m12.1 -.7l-.7 .7",
		"key": "svg-0"
	}],
	["path", {
		"d": "M9 16a5 5 0 1 1 6 0a3.5 3.5 0 0 0 -1 3a2 2 0 0 1 -4 0a3.5 3.5 0 0 0 -1 -3",
		"key": "svg-1"
	}],
	["path", {
		"d": "M9.7 17l4.6 0",
		"key": "svg-2"
	}]
]);
/**
* @license @tabler/icons-react v3.36.0 - MIT
*
* This source code is licensed under the MIT license.
* See the LICENSE file in the root directory of this source tree.
*/
var IconCalendar = createReactComponent("outline", "calendar", "Calendar", [
	["path", {
		"d": "M4 7a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v12a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2v-12z",
		"key": "svg-0"
	}],
	["path", {
		"d": "M16 3v4",
		"key": "svg-1"
	}],
	["path", {
		"d": "M8 3v4",
		"key": "svg-2"
	}],
	["path", {
		"d": "M4 11h16",
		"key": "svg-3"
	}],
	["path", {
		"d": "M11 15h1",
		"key": "svg-4"
	}],
	["path", {
		"d": "M12 15v3",
		"key": "svg-5"
	}]
]);
/**
* @license @tabler/icons-react v3.36.0 - MIT
*
* This source code is licensed under the MIT license.
* See the LICENSE file in the root directory of this source tree.
*/
var IconCategory = createReactComponent("outline", "category", "Category", [
	["path", {
		"d": "M4 4h6v6h-6z",
		"key": "svg-0"
	}],
	["path", {
		"d": "M14 4h6v6h-6z",
		"key": "svg-1"
	}],
	["path", {
		"d": "M4 14h6v6h-6z",
		"key": "svg-2"
	}],
	["path", {
		"d": "M17 17m-3 0a3 3 0 1 0 6 0a3 3 0 1 0 -6 0",
		"key": "svg-3"
	}]
]);
/**
* @license @tabler/icons-react v3.36.0 - MIT
*
* This source code is licensed under the MIT license.
* See the LICENSE file in the root directory of this source tree.
*/
var IconChartDots3 = createReactComponent("outline", "chart-dots-3", "ChartDots3", [
	["path", {
		"d": "M5 7m-2 0a2 2 0 1 0 4 0a2 2 0 1 0 -4 0",
		"key": "svg-0"
	}],
	["path", {
		"d": "M16 15m-2 0a2 2 0 1 0 4 0a2 2 0 1 0 -4 0",
		"key": "svg-1"
	}],
	["path", {
		"d": "M18 6m-3 0a3 3 0 1 0 6 0a3 3 0 1 0 -6 0",
		"key": "svg-2"
	}],
	["path", {
		"d": "M6 18m-3 0a3 3 0 1 0 6 0a3 3 0 1 0 -6 0",
		"key": "svg-3"
	}],
	["path", {
		"d": "M9 17l5 -1.5",
		"key": "svg-4"
	}],
	["path", {
		"d": "M6.5 8.5l7.81 5.37",
		"key": "svg-5"
	}],
	["path", {
		"d": "M7 7l8 -1",
		"key": "svg-6"
	}]
]);
/**
* @license @tabler/icons-react v3.36.0 - MIT
*
* This source code is licensed under the MIT license.
* See the LICENSE file in the root directory of this source tree.
*/
var IconClock = createReactComponent("outline", "clock", "Clock", [["path", {
	"d": "M3 12a9 9 0 1 0 18 0a9 9 0 0 0 -18 0",
	"key": "svg-0"
}], ["path", {
	"d": "M12 7v5l3 3",
	"key": "svg-1"
}]]);
/**
* @license @tabler/icons-react v3.36.0 - MIT
*
* This source code is licensed under the MIT license.
* See the LICENSE file in the root directory of this source tree.
*/
var IconDashboard = createReactComponent("outline", "dashboard", "Dashboard", [
	["path", {
		"d": "M12 13m-2 0a2 2 0 1 0 4 0a2 2 0 1 0 -4 0",
		"key": "svg-0"
	}],
	["path", {
		"d": "M13.45 11.55l2.05 -2.05",
		"key": "svg-1"
	}],
	["path", {
		"d": "M6.4 20a9 9 0 1 1 11.2 0z",
		"key": "svg-2"
	}]
]);
/**
* @license @tabler/icons-react v3.36.0 - MIT
*
* This source code is licensed under the MIT license.
* See the LICENSE file in the root directory of this source tree.
*/
var IconDotsVertical = createReactComponent("outline", "dots-vertical", "DotsVertical", [
	["path", {
		"d": "M12 12m-1 0a1 1 0 1 0 2 0a1 1 0 1 0 -2 0",
		"key": "svg-0"
	}],
	["path", {
		"d": "M12 19m-1 0a1 1 0 1 0 2 0a1 1 0 1 0 -2 0",
		"key": "svg-1"
	}],
	["path", {
		"d": "M12 5m-1 0a1 1 0 1 0 2 0a1 1 0 1 0 -2 0",
		"key": "svg-2"
	}]
]);
/**
* @license @tabler/icons-react v3.36.0 - MIT
*
* This source code is licensed under the MIT license.
* See the LICENSE file in the root directory of this source tree.
*/
var IconInnerShadowTop = createReactComponent("outline", "inner-shadow-top", "InnerShadowTop", [["path", {
	"d": "M5.636 5.636a9 9 0 1 0 12.728 12.728a9 9 0 0 0 -12.728 -12.728z",
	"key": "svg-0"
}], ["path", {
	"d": "M16.243 7.757a6 6 0 0 0 -8.486 0",
	"key": "svg-1"
}]]);
/**
* @license @tabler/icons-react v3.36.0 - MIT
*
* This source code is licensed under the MIT license.
* See the LICENSE file in the root directory of this source tree.
*/
var IconLogout = createReactComponent("outline", "logout", "Logout", [
	["path", {
		"d": "M14 8v-2a2 2 0 0 0 -2 -2h-7a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h7a2 2 0 0 0 2 -2v-2",
		"key": "svg-0"
	}],
	["path", {
		"d": "M9 12h12l-3 -3",
		"key": "svg-1"
	}],
	["path", {
		"d": "M18 15l3 -3",
		"key": "svg-2"
	}]
]);
/**
* @license @tabler/icons-react v3.36.0 - MIT
*
* This source code is licensed under the MIT license.
* See the LICENSE file in the root directory of this source tree.
*/
var IconNotebook = createReactComponent("outline", "notebook", "Notebook", [
	["path", {
		"d": "M6 4h11a2 2 0 0 1 2 2v12a2 2 0 0 1 -2 2h-11a1 1 0 0 1 -1 -1v-14a1 1 0 0 1 1 -1m3 0v18",
		"key": "svg-0"
	}],
	["path", {
		"d": "M13 8l2 0",
		"key": "svg-1"
	}],
	["path", {
		"d": "M13 12l2 0",
		"key": "svg-2"
	}]
]);
/**
* @license @tabler/icons-react v3.36.0 - MIT
*
* This source code is licensed under the MIT license.
* See the LICENSE file in the root directory of this source tree.
*/
var IconQuote = createReactComponent("outline", "quote", "Quote", [["path", {
	"d": "M10 11h-4a1 1 0 0 1 -1 -1v-3a1 1 0 0 1 1 -1h3a1 1 0 0 1 1 1v6c0 2.667 -1.333 4.333 -4 5",
	"key": "svg-0"
}], ["path", {
	"d": "M19 11h-4a1 1 0 0 1 -1 -1v-3a1 1 0 0 1 1 -1h3a1 1 0 0 1 1 1v6c0 2.667 -1.333 4.333 -4 5",
	"key": "svg-1"
}]]);
/**
* @license @tabler/icons-react v3.36.0 - MIT
*
* This source code is licensed under the MIT license.
* See the LICENSE file in the root directory of this source tree.
*/
var IconSettings = createReactComponent("outline", "settings", "Settings", [["path", {
	"d": "M10.325 4.317c.426 -1.756 2.924 -1.756 3.35 0a1.724 1.724 0 0 0 2.573 1.066c1.543 -.94 3.31 .826 2.37 2.37a1.724 1.724 0 0 0 1.065 2.572c1.756 .426 1.756 2.924 0 3.35a1.724 1.724 0 0 0 -1.066 2.573c.94 1.543 -.826 3.31 -2.37 2.37a1.724 1.724 0 0 0 -2.572 1.065c-.426 1.756 -2.924 1.756 -3.35 0a1.724 1.724 0 0 0 -2.573 -1.066c-1.543 .94 -3.31 -.826 -2.37 -2.37a1.724 1.724 0 0 0 -1.065 -2.572c-1.756 -.426 -1.756 -2.924 0 -3.35a1.724 1.724 0 0 0 1.066 -2.573c-.94 -1.543 .826 -3.31 2.37 -2.37c1 .608 2.296 .07 2.572 -1.065z",
	"key": "svg-0"
}], ["path", {
	"d": "M9 12a3 3 0 1 0 6 0a3 3 0 0 0 -6 0",
	"key": "svg-1"
}]]);
/**
* @license @tabler/icons-react v3.36.0 - MIT
*
* This source code is licensed under the MIT license.
* See the LICENSE file in the root directory of this source tree.
*/
var IconUsers = createReactComponent("outline", "users", "Users", [
	["path", {
		"d": "M9 7m-4 0a4 4 0 1 0 8 0a4 4 0 1 0 -8 0",
		"key": "svg-0"
	}],
	["path", {
		"d": "M3 21v-2a4 4 0 0 1 4 -4h4a4 4 0 0 1 4 4v2",
		"key": "svg-1"
	}],
	["path", {
		"d": "M16 3.13a4 4 0 0 1 0 7.75",
		"key": "svg-2"
	}],
	["path", {
		"d": "M21 21v-2a4 4 0 0 0 -3 -3.85",
		"key": "svg-3"
	}]
]);
/**
* @license @tabler/icons-react v3.36.0 - MIT
*
* This source code is licensed under the MIT license.
* See the LICENSE file in the root directory of this source tree.
*/
var IconCirclePlusFilled = createReactComponent("filled", "circle-plus-filled", "CirclePlusFilled", [["path", {
	"d": "M4.929 4.929a10 10 0 1 1 14.141 14.141a10 10 0 0 1 -14.14 -14.14zm8.071 4.071a1 1 0 1 0 -2 0v2h-2a1 1 0 1 0 0 2h2v2a1 1 0 1 0 2 0v-2h2a1 1 0 1 0 0 -2h-2v-2z",
	"key": "svg-0"
}]]);
//#endregion
export { IconNotebook as a, IconDotsVertical as c, IconChartDots3 as d, IconCategory as f, IconBook as h, IconQuote as i, IconDashboard as l, IconBulb as m, IconUsers as n, IconLogout as o, IconCalendar as p, IconSettings as r, IconInnerShadowTop as s, IconCirclePlusFilled as t, IconClock as u };
