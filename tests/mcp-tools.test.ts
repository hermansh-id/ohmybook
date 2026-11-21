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
  for (const n of ["lookup_book", "refresh_goodreads_data", "get_reading_recommendations", "add_book", "update_book"]) {
    expect(names).toContain(n);
  }
  const lookup = tools.find((t) => t.name === "lookup_book")!;
  expect(lookup.annotations?.readOnlyHint).toBe(true);
  expect(lookup.annotations?.openWorldHint).toBe(true);

  // none / more than one identifier -> error, no network call
  for (const args of [{}, { isbn: "1", qrcbn: "2" }]) {
    const res = await client.callTool({ name: "lookup_book", arguments: args });
    expect(res.isError).toBe(true);
  }
});
