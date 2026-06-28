import { o as __toESM } from "../_runtime.mjs";
import { t as cva } from "../_libs/class-variance-authority+clsx.mjs";
import { t as cn } from "./utils-oIFR_d28.mjs";
import { u as require_react } from "../_libs/@floating-ui/react-dom+[...].mjs";
import { j as require_jsx_runtime } from "../_libs/@radix-ui/react-alert-dialog+[...].mjs";
import { t as Button } from "./button-PkU2hkqt.mjs";
import { a as CardHeader, i as CardDescription, o as CardTitle, r as CardContent, t as Card } from "./card-BxgehY3N.mjs";
import { _ as useRouter, g as useNavigate } from "../_libs/@tanstack/react-router+[...].mjs";
import { t as Input } from "./input-BO5Hu60S.mjs";
import { t as Label } from "./label-Ca2nQBgL.mjs";
import "./separator-_u3Cq2VW.mjs";
import { n as toast } from "../_libs/sonner.mjs";
import { r as signUp, t as signIn } from "./auth-client-jslm_EX-.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/login-BdxWX0zi.js
var import_react = /* @__PURE__ */ __toESM(require_react());
var import_jsx_runtime = require_jsx_runtime();
function FieldGroup({ className, ...props }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
		"data-slot": "field-group",
		className: cn("group/field-group @container/field-group flex w-full flex-col gap-7 data-[slot=checkbox-group]:gap-3 [&>[data-slot=field-group]]:gap-4", className),
		...props
	});
}
var fieldVariants = cva("group/field flex w-full gap-3 data-[invalid=true]:text-destructive", {
	variants: { orientation: {
		vertical: ["flex-col [&>*]:w-full [&>.sr-only]:w-auto"],
		horizontal: [
			"flex-row items-center",
			"[&>[data-slot=field-label]]:flex-auto",
			"has-[>[data-slot=field-content]]:items-start has-[>[data-slot=field-content]]:[&>[role=checkbox],[role=radio]]:mt-px"
		],
		responsive: [
			"flex-col [&>*]:w-full [&>.sr-only]:w-auto @md/field-group:flex-row @md/field-group:items-center @md/field-group:[&>*]:w-auto",
			"@md/field-group:[&>[data-slot=field-label]]:flex-auto",
			"@md/field-group:has-[>[data-slot=field-content]]:items-start @md/field-group:has-[>[data-slot=field-content]]:[&>[role=checkbox],[role=radio]]:mt-px"
		]
	} },
	defaultVariants: { orientation: "vertical" }
});
function Field({ className, orientation = "vertical", ...props }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
		role: "group",
		"data-slot": "field",
		"data-orientation": orientation,
		className: cn(fieldVariants({ orientation }), className),
		...props
	});
}
function FieldLabel({ className, ...props }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Label, {
		"data-slot": "field-label",
		className: cn("group/field-label peer/field-label flex w-fit gap-2 leading-snug group-data-[disabled=true]/field:opacity-50", "has-[>[data-slot=field]]:w-full has-[>[data-slot=field]]:flex-col has-[>[data-slot=field]]:rounded-md has-[>[data-slot=field]]:border [&>*]:data-[slot=field]:p-4", "has-data-[state=checked]:bg-primary/5 has-data-[state=checked]:border-primary dark:has-data-[state=checked]:bg-primary/10", className),
		...props
	});
}
function FieldDescription({ className, ...props }) {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
		"data-slot": "field-description",
		className: cn("text-muted-foreground text-sm leading-normal font-normal group-has-[[data-orientation=horizontal]]/field:text-balance", "last:mt-0 nth-last-2:-mt-1 [[data-variant=legend]+&]:-mt-1.5", "[&>a:hover]:text-primary [&>a]:underline [&>a]:underline-offset-4", className),
		...props
	});
}
function LoginForm({ className, ...props }) {
	const [email, setEmail] = (0, import_react.useState)("");
	const [password, setPassword] = (0, import_react.useState)("");
	const [isLoading, setIsLoading] = (0, import_react.useState)(false);
	const [isSignUp, setIsSignUp] = (0, import_react.useState)(false);
	const navigate = useNavigate();
	const router = useRouter();
	const handleSubmit = async (e) => {
		e.preventDefault();
		setIsLoading(true);
		if (isSignUp) await signUp.email({
			email,
			password,
			name: email.split("@")[0]
		}, {
			onSuccess: () => {
				toast.success("Account created! Please sign in.");
				setIsSignUp(false);
				setPassword("");
				setIsLoading(false);
			},
			onError: (ctx) => {
				toast.error(ctx.error.message || "Failed to create account");
				setIsLoading(false);
			}
		});
		else await signIn.email({
			email,
			password
		}, {
			onSuccess: async () => {
				toast.success("Signed in successfully!");
				await router.invalidate();
				navigate({ to: "/dashboard" });
				setIsLoading(false);
			},
			onError: (ctx) => {
				toast.error(ctx.error.message || "Invalid email or password");
				setIsLoading(false);
			}
		});
	};
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
		className: cn("flex flex-col gap-6", className),
		...props,
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Card, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(CardHeader, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardTitle, { children: isSignUp ? "Create an account" : "Login to your account" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardDescription, { children: isSignUp ? "Enter your email below to create your account" : "Enter your email below to login to your account" })] }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(CardContent, { children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("form", {
			onSubmit: handleSubmit,
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(FieldGroup, { children: [
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Field, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(FieldLabel, {
					htmlFor: "email",
					children: "Email"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
					id: "email",
					type: "email",
					placeholder: "m@example.com",
					required: true,
					value: email,
					onChange: (e) => setEmail(e.target.value),
					disabled: isLoading
				})] }),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Field, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(FieldLabel, {
					htmlFor: "password",
					children: "Password"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Input, {
					id: "password",
					type: "password",
					required: true,
					value: password,
					onChange: (e) => setPassword(e.target.value),
					disabled: isLoading
				})] }),
				/* @__PURE__ */ (0, import_jsx_runtime.jsxs)(Field, { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Button, {
					type: "submit",
					disabled: isLoading,
					children: isLoading ? "Loading..." : isSignUp ? "Sign Up" : "Login"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)(FieldDescription, {
					className: "text-center",
					children: isSignUp ? /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [
						"Already have an account?",
						" ",
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
							type: "button",
							onClick: () => setIsSignUp(false),
							className: "underline",
							children: "Sign in"
						})
					] }) : /* @__PURE__ */ (0, import_jsx_runtime.jsxs)(import_jsx_runtime.Fragment, { children: [
						"Don't have an account?",
						" ",
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
							type: "button",
							onClick: () => setIsSignUp(true),
							className: "underline",
							children: "Sign up"
						})
					] })
				})] })
			] })
		}) })] })
	});
}
function LoginPage() {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
		className: "flex min-h-svh w-full items-center justify-center p-6 md:p-10",
		children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
			className: "w-full max-w-sm",
			children: /* @__PURE__ */ (0, import_jsx_runtime.jsx)(LoginForm, {})
		})
	});
}
//#endregion
export { LoginPage as component };
