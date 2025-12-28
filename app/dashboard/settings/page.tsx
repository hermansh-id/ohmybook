import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { SettingsForm } from "@/components/settings-form";
import { ExportCsvButton } from "@/components/export-csv-button";
import { db } from "@/lib/db";
import { readingGoals } from "@/lib/db/schema";
import { eq } from "drizzle-orm";
import { Settings } from "lucide-react";

export default async function SettingsPage() {
  const currentYear = new Date().getFullYear();

  // Get current year's goal
  const [goal] = await db
    .select()
    .from(readingGoals)
    .where(eq(readingGoals.year, currentYear))
    .limit(1);

  return (
    <div className="flex flex-col gap-4 p-4 md:gap-6 md:p-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight flex items-center gap-2">
          <Settings className="h-8 w-8" />
          Settings
        </h1>
        <p className="text-muted-foreground">
          Manage your reading goals and export your data
        </p>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        {/* Reading Goal Settings */}
        <Card>
          <CardHeader>
            <CardTitle>Annual Reading Goal</CardTitle>
            <CardDescription>
              Set your target for {currentYear}
            </CardDescription>
          </CardHeader>
          <CardContent>
            <SettingsForm
              currentGoal={{
                targetBooks: goal?.targetBooks || 52,
                targetPages: goal?.targetPages || 0,
                year: currentYear,
              }}
            />
          </CardContent>
        </Card>

        {/* Export Data */}
        <Card>
          <CardHeader>
            <CardTitle>Export Data</CardTitle>
            <CardDescription>
              Export your reading log to import into Goodreads
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <p className="text-sm text-muted-foreground">
                Download your reading log as a CSV file that can be imported directly into Goodreads.
              </p>
              <ExportCsvButton />
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
