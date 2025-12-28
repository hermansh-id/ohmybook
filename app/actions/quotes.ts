"use server";

import {
  createQuote,
  updateQuote,
  deleteQuote,
  toggleQuoteFavorite,
} from "@/lib/db/queries";
import { revalidatePath } from "next/cache";

export async function createQuoteAction(data: {
  bookId: number;
  quoteText: string;
  pageNumber?: number;
  chapter?: string;
  tags?: string[];
  isFavorite?: boolean;
  notes?: string;
}) {
  try {
    const result = await createQuote(data);
    revalidatePath("/dashboard/quotes");
    return { success: true, data: result };
  } catch (error) {
    console.error("Error creating quote:", error);
    return { success: false, error: "Failed to create quote" };
  }
}

export async function updateQuoteAction(
  quoteId: number,
  data: {
    quoteText?: string;
    pageNumber?: number;
    chapter?: string;
    tags?: string[];
    isFavorite?: boolean;
    notes?: string;
  }
) {
  try {
    const result = await updateQuote(quoteId, data);
    revalidatePath("/dashboard/quotes");
    return { success: true, data: result };
  } catch (error) {
    console.error("Error updating quote:", error);
    return { success: false, error: "Failed to update quote" };
  }
}

export async function deleteQuoteAction(quoteId: number) {
  try {
    await deleteQuote(quoteId);
    revalidatePath("/dashboard/quotes");
    return { success: true };
  } catch (error) {
    console.error("Error deleting quote:", error);
    return { success: false, error: "Failed to delete quote" };
  }
}

export async function toggleQuoteFavoriteAction(quoteId: number) {
  try {
    await toggleQuoteFavorite(quoteId);
    revalidatePath("/dashboard/quotes");
    return { success: true };
  } catch (error) {
    console.error("Error toggling favorite:", error);
    return { success: false, error: "Failed to toggle favorite" };
  }
}
