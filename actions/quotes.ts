import { createServerFn } from "@tanstack/react-start";
import {
  createQuote,
  updateQuote,
  deleteQuote,
  toggleQuoteFavorite,
} from "@/lib/db/queries";

export const createQuoteAction = createServerFn({ method: "POST" })
  .validator(
    (d: {
      bookId: number;
      quoteText: string;
      pageNumber?: number;
      chapter?: string;
      tags?: string[];
      isFavorite?: boolean;
      notes?: string;
    }) => d
  )
  .handler(async ({ data }) => {
    try {
      const result = await createQuote(data);
      return { success: true, data: result };
    } catch (error) {
      console.error("Error creating quote:", error);
      return { success: false, error: "Failed to create quote" };
    }
  });

export const updateQuoteAction = createServerFn({ method: "POST" })
  .validator(
    (d: {
      quoteId: number;
      quoteText?: string;
      pageNumber?: number;
      chapter?: string;
      tags?: string[];
      isFavorite?: boolean;
      notes?: string;
    }) => d
  )
  .handler(async ({ data }) => {
    try {
      const { quoteId, ...updateData } = data;
      const result = await updateQuote(quoteId, updateData);
      return { success: true, data: result };
    } catch (error) {
      console.error("Error updating quote:", error);
      return { success: false, error: "Failed to update quote" };
    }
  });

export const deleteQuoteAction = createServerFn({ method: "POST" })
  .validator((d: { quoteId: number }) => d)
  .handler(async ({ data }) => {
    try {
      await deleteQuote(data.quoteId);
      return { success: true };
    } catch (error) {
      console.error("Error deleting quote:", error);
      return { success: false, error: "Failed to delete quote" };
    }
  });

export const toggleQuoteFavoriteAction = createServerFn({ method: "POST" })
  .validator((d: { quoteId: number }) => d)
  .handler(async ({ data }) => {
    try {
      await toggleQuoteFavorite(data.quoteId);
      return { success: true };
    } catch (error) {
      console.error("Error toggling favorite:", error);
      return { success: false, error: "Failed to toggle favorite" };
    }
  });

export const getQuotesDataAction = createServerFn({ method: "GET" }).handler(async () => {
  const { getAllQuotes, getQuoteStats } = await import("@/lib/db/queries");
  const [quotes, stats] = await Promise.all([getAllQuotes(), getQuoteStats()]);
  return { quotes, stats };
});
