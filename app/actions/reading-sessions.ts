"use server";

import {
  getReadingSessions,
  getBookReadingSessions,
  createReadingSession,
  updateReadingSession,
  deleteReadingSession,
} from "@/lib/db/queries";
import { revalidatePath } from "next/cache";

export async function getReadingSessionsAction(limit: number = 50) {
  try {
    const sessions = await getReadingSessions(limit);
    return { success: true, data: sessions };
  } catch (error) {
    console.error("Error fetching reading sessions:", error);
    return { success: false, error: "Failed to fetch reading sessions" };
  }
}

export async function getBookReadingSessionsAction(bookId: number) {
  try {
    const sessions = await getBookReadingSessions(bookId);
    return { success: true, data: sessions };
  } catch (error) {
    console.error("Error fetching book reading sessions:", error);
    return { success: false, error: "Failed to fetch book reading sessions" };
  }
}

export async function createReadingSessionAction(data: {
  bookId: number;
  sessionDate: string;
  pagesRead?: number;
  minutesRead?: number;
  startPage?: number;
  endPage?: number;
  notes?: string;
}) {
  try {
    const session = await createReadingSession({
      ...data,
      sessionDate: new Date(data.sessionDate),
    });

    revalidatePath("/dashboard/reading-log");
    return { success: true, data: session[0] };
  } catch (error) {
    console.error("Error creating reading session:", error);
    return { success: false, error: "Failed to create reading session" };
  }
}

export async function updateReadingSessionAction(
  sessionId: number,
  data: {
    sessionDate?: string;
    pagesRead?: number;
    minutesRead?: number;
    startPage?: number;
    endPage?: number;
    notes?: string;
  }
) {
  try {
    const updateData = {
      ...data,
      sessionDate: data.sessionDate ? new Date(data.sessionDate) : undefined,
    };

    const session = await updateReadingSession(sessionId, updateData);

    revalidatePath("/dashboard/reading-log");
    return { success: true, data: session[0] };
  } catch (error) {
    console.error("Error updating reading session:", error);
    return { success: false, error: "Failed to update reading session" };
  }
}

export async function deleteReadingSessionAction(sessionId: number) {
  try {
    await deleteReadingSession(sessionId);

    revalidatePath("/dashboard/reading-log");
    return { success: true };
  } catch (error) {
    console.error("Error deleting reading session:", error);
    return { success: false, error: "Failed to delete reading session" };
  }
}
