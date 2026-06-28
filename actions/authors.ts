import { createServerFn } from "@tanstack/react-start";
import { db } from "@/lib/db";
import { authors } from "@/lib/db/schema";

export interface AddAuthorInput {
  name: string;
  bio?: string;
}

export const addAuthor = createServerFn({ method: "POST" })
  .validator((d: AddAuthorInput) => d)
  .handler(async ({ data }) => {
    try {
      // Upsert: return existing author if name already taken
      const [author] = await db
        .insert(authors)
        .values({
          name: data.name,
          bio: data.bio || null,
        })
        .onConflictDoUpdate({
          target: authors.name,
          set: { name: authors.name }, // no-op update so we can use .returning()
        })
        .returning();

      return { success: true, author };
    } catch (error) {
      console.error("Error adding author:", error);
      return { success: false, error: "Failed to add author" };
    }
  });

export const getAuthorsWithStatsAction = createServerFn({ method: "GET" }).handler(async () => {
  const { getAuthorsWithStats } = await import("@/lib/db/queries");
  return getAuthorsWithStats();
});
