"use server";

import { db } from "@/lib/db";
import { authors } from "@/lib/db/schema";
import { revalidatePath } from "next/cache";

export interface AddAuthorInput {
  name: string;
  bio?: string;
}

export async function addAuthor(input: AddAuthorInput) {
  try {
    const [author] = await db
      .insert(authors)
      .values({
        name: input.name,
        bio: input.bio || null,
      })
      .returning();

    revalidatePath("/books/add");
    return { success: true, author };
  } catch (error) {
    console.error("Error adding author:", error);
    return { success: false, error: "Failed to add author" };
  }
}
