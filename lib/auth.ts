import { betterAuth } from "better-auth";
import { drizzleAdapter } from "better-auth/adapters/drizzle";
import { mcp } from "better-auth/plugins";
import { db } from "./db";
import {
  users,
  sessions,
  accounts,
  verifications,
  oauthApplication,
  oauthAccessToken,
  oauthConsent,
} from "./db/schema";

export const auth = betterAuth({
  database: drizzleAdapter(db, {
    provider: "pg",
    schema: {
      user: users,
      session: sessions,
      account: accounts,
      verification: verifications,
      oauthApplication,
      oauthAccessToken,
      oauthConsent,
    },
  }),
  emailAndPassword: {
    enabled: true,
    requireEmailVerification: false,
  },
  advanced: {
    cookiePrefix: "bookjet",
  },
  plugins: [
    // OAuth 2.1 provider for remote MCP clients (PKCE + dynamic client registration)
    mcp({
      loginPage: "/login",
      oidcConfig: {
        loginPage: "/login",
        allowDynamicClientRegistration: true,
      },
    }),
  ],
  secret: process.env.BETTER_AUTH_SECRET || "secret-key-development-only",
  baseURL: process.env.BETTER_AUTH_URL || "http://localhost:3000",
});

export type Session = typeof auth.$Infer.Session;
