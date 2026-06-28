import { createServerFn } from "@tanstack/react-start";
import { db } from "@/lib/db";
import { genres } from "@/lib/db/schema";

export const getGenresAction = createServerFn({ method: "GET" })
  .handler(async () => {
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
  });

export const addGenre = createServerFn({ method: "POST" })
  .validator((d: { genreName: string; description?: string }) => d)
  .handler(async ({ data }) => {
    try {
      const [genre] = await db
        .insert(genres)
        .values({
          genreName: data.genreName,
          description: data.description || null,
        })
        .returning();

      return { success: true, genre };
    } catch (error) {
      console.error("Error adding genre:", error);
      return { success: false, error: "Failed to add genre" };
    }
  });

export const getGenresWithStatsAction = createServerFn({ method: "GET" }).handler(async () => {
  const { getGenresWithStats } = await import("@/lib/db/queries");
  return getGenresWithStats();
});
