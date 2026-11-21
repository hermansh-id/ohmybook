import { expect, test } from "bun:test";

process.env.DATABASE_URL ??= "postgres://u:p@localhost:5432/none"; // never connected in these tests

test("MCP server exposes Goodreads tools and validates lookup_book input", async () => {
  const { Client } = await import("@modelcontextprotocol/sdk/client/index.js");
  const { InMemoryTransport } = await import("@modelcontextprotocol/sdk/inMemory.js");
  const { createMcpServer } = await import("@/lib/mcp/server");

  const server = createMcpServer();
  const client = new Client({ name: "test", version: "1" });
  const [a, b] = InMemoryTransport.createLinkedPair();
  await Promise.all([server.connect(a), client.connect(b)]);

  const { tools } = await client.listTools();
  const names = tools.map((t) => t.name);
  for (const n of ["lookup_book", "refresh_goodreads_data", "get_reading_recommendations", "add_book", "update_book", "update_book_details", "add_book_authors", "add_book_genres", "add_author", "add_genre", "get_book_link", "delete_book", "delete_quote", "delete_reading_session", "update_quote", "update_reading_session", "set_reading_goal", "get_reading_goal", "get_yearly_stats", "get_monthly_stats", "get_top_rated_books", "get_reading_history", "list_reading_priorities", "set_book_priority", "close_book_priority", "list_reading_plan", "plan_reading", "complete_plan_item", "reschedule_plan_item", "skip_plan_item", "remove_plan_item"]) {
    expect(names).toContain(n);
  }
  const lookup = tools.find((t) => t.name === "lookup_book")!;
  expect(lookup.annotations?.readOnlyHint).toBe(true);
  expect(lookup.annotations?.openWorldHint).toBe(true);

  // destructive tools are flagged; delete_book needs explicit confirm
  for (const n of ["delete_book", "delete_quote", "delete_reading_session"]) {
    expect(tools.find((t) => t.name === n)!.annotations?.destructiveHint).toBe(true);
  }
  const del = await client.callTool({ name: "delete_book", arguments: { bookId: 1 } });
  expect(del.isError).toBe(true); // confirm missing -> schema validation error, no DB access
  const noArg = await client.callTool({ name: "get_book_link", arguments: {} });
  expect(noArg.isError).toBe(true);

  // none / more than one identifier -> error, no network call
  for (const args of [{}, { isbn: "1", qrcbn: "2" }]) {
    const res = await client.callTool({ name: "lookup_book", arguments: args });
    expect(res.isError).toBe(true);
  }
});
