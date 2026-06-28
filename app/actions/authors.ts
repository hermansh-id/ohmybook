"use server";

import { db } from "@/lib/db";
import { authors } from "@/lib/db/schema";
import { eq } from "drizzle-orm";
import { revalidatePath } from "next/cache";

export interface AddAuthorInput {
  name: string;
  bio?: string;
}

export async function addAuthor(input: AddAuthorInput) {
  try {
    // Upsert: return existing author if name already taken
    const [author] = await db
      .insert(authors)
      .values({
        name: input.name,
        bio: input.bio || null,
      })
      .onConflictDoUpdate({
        target: authors.name,
        set: { name: authors.name }, // no-op update so we can use .returning()
      })
      .returning();

    revalidatePath("/books/add");
    return { success: true, author };
  } catch (error) {
    console.error("Error adding author:", error);
    return { success: false, error: "Failed to add author" };
  }
}
