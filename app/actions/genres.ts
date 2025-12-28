"use server";

import { db } from "@/lib/db";
import { genres } from "@/lib/db/schema";
import { revalidatePath } from "next/cache";

export async function getGenresAction() {
  try {
    const allGenres = await db
      .select({
        genreId: genres.genreId,
        genreName: genres.genreName,
      })
      .from(genres)
      .orderBy(genres.genreName);

    return allGenres;
  } catch (error) {
    console.error("Error fetching genres:", error);
    return [];
  }
}

export async function addGenre(input: { genreName: string; description?: string }) {
  try {
    const [genre] = await db
      .insert(genres)
      .values({
        genreName: input.genreName,
        description: input.description || null,
      })
      .returning();

    revalidatePath("/dashboard/genres");
    return { success: true, genre };
  } catch (error) {
    console.error("Error adding genre:", error);
    return { success: false, error: "Failed to add genre" };
  }
}
