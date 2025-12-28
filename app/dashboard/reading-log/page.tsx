import { ReadingLogClient } from "./reading-log-client";
import { getReadingSessions } from "@/lib/db/queries";
import { getBooksAction } from "@/app/actions/books";

export default async function ReadingLogPage() {
  const [sessionsResult, booksResult] = await Promise.all([
    getReadingSessions(100),
    getBooksAction(),
  ]);

  return (
    <ReadingLogClient initialSessions={sessionsResult} availableBooks={booksResult} />
  );
}
