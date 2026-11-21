import { createFileRoute } from "@tanstack/react-router";
import { eq } from "drizzle-orm";
import { WebStandardStreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/webStandardStreamableHttp.js";
import { withMcpAuth } from "better-auth/plugins";
import { auth } from "@/lib/auth";
import { db } from "@/lib/db";
import { users } from "@/lib/db/schema";
import { createMcpServer } from "@/lib/mcp/server";

/**
 * Signup is open on this app, so a valid OAuth token alone is not enough:
 * the token's user must be on the MCP_ALLOWED_EMAILS allowlist (comma-separated).
 * Unset/empty allowlist = deny everyone.
 */
async function isAllowedUser(userId: string | null | undefined) {
  const allowed = (process.env.MCP_ALLOWED_EMAILS ?? "")
    .split(",")
    .map((e) => e.trim().toLowerCase())
    .filter(Boolean);
  if (!userId || allowed.length === 0) return false;
  const [user] = await db.select({ email: users.email }).from(users).where(eq(users.id, userId)).limit(1);
  return !!user && allowed.includes(user.email.toLowerCase());
}

const handle = withMcpAuth(auth, async (req, session) => {
  if (!(await isAllowedUser(session.userId))) {
    return Response.json(
      { jsonrpc: "2.0", error: { code: -32001, message: "Forbidden" }, id: null },
      { status: 403 },
    );
  }

  // Stateless: fresh server + transport per request (works on serverless).
  const transport = new WebStandardStreamableHTTPServerTransport({
    sessionIdGenerator: undefined,
    enableJsonResponse: true,
  });
  const server = createMcpServer();
  await server.connect(transport);
  return transport.handleRequest(req);
});

export const Route = createFileRoute("/api/mcp")({
  server: {
    handlers: {
      GET: ({ request }) => handle(request),
      POST: ({ request }) => handle(request),
      DELETE: ({ request }) => handle(request),
    },
  },
});
