import { ReadingLogClient } from "./reading-log-client";
import { getReadingSessions } from "@/lib/db/queries";
import { getUnfinishedBooksAction } from "@/app/actions/reading-sessions";

export default async function ReadingLogPage() {
  const [sessionsResult, unfinishedBooks] = await Promise.all([
    getReadingSessions(100),
    getUnfinishedBooksAction(),
  ]);

  return (
    <ReadingLogClient
      initialSessions={sessionsResult}
      unfinishedBooks={unfinishedBooks}
    />
  );
}
