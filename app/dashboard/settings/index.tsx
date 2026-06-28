import { createFileRoute } from "@tanstack/react-router";
import { useSettings } from "@/lib/queries/settings";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { SettingsForm } from "@/components/settings-form";
import { ExportCsvButton } from "@/components/export-csv-button";
import { Settings } from "lucide-react";

export const Route = createFileRoute('/dashboard/settings/')({
  component: SettingsPage,
});

function SettingsPage() {
  const { data, isLoading } = useSettings();

  const currentYear = new Date().getFullYear();

  if (isLoading) {
    return (
      <div className="flex flex-col gap-4 p-4 md:gap-6 md:p-6">
        <div className="space-y-2">
          <Skeleton className="h-9 w-48" />
          <Skeleton className="h-4 w-64" />
        </div>
        <div className="grid gap-6 md:grid-cols-2">
          <Card>
            <CardContent className="pt-6">
              <Skeleton className="h-48 w-full" />
            </CardContent>
          </Card>
          <Card>
            <CardContent className="pt-6">
              <Skeleton className="h-48 w-full" />
            </CardContent>
          </Card>
        </div>
      </div>
    );
  }

  const goal = (data as any)?.goal;
  const year = (data as any)?.currentYear ?? currentYear;

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
              Set your target for {year}
            </CardDescription>
          </CardHeader>
          <CardContent>
            <SettingsForm
              currentGoal={{
                targetBooks: goal?.targetBooks || 52,
                targetPages: goal?.targetPages || 0,
                year,
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
