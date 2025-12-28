"use client";

import { useMemo } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import { Flame } from "lucide-react";

interface DailyActivity {
  date: string;
  pagesRead: number;
  minutesRead: number;
  sessionCount: number;
}

interface ReadingHeatmapProps {
  data: DailyActivity[];
  currentStreak?: number;
  bestStreak?: number;
}

export function ReadingHeatmap({ data, currentStreak = 0, bestStreak = 0 }: ReadingHeatmapProps) {
  // Generate last 365 days
  const heatmapData = useMemo(() => {
    const today = new Date();
    const days = [];

    // Create a map of activity by date
    const activityMap = new Map<string, DailyActivity>();
    data.forEach(activity => {
      activityMap.set(activity.date, activity);
    });

    // Generate 365 days
    for (let i = 364; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      date.setHours(0, 0, 0, 0);

      const dateStr = date.toISOString().split('T')[0];
      const activity = activityMap.get(dateStr);

      days.push({
        date: dateStr,
        dayOfWeek: date.getDay(),
        pagesRead: activity?.pagesRead || 0,
        minutesRead: activity?.minutesRead || 0,
        sessionCount: activity?.sessionCount || 0,
      });
    }

    return days;
  }, [data]);

  // Group by weeks
  const weeks = useMemo(() => {
    const weeksList: typeof heatmapData[] = [];
    let currentWeek: typeof heatmapData = [];

    heatmapData.forEach((day, index) => {
      if (index === 0 && day.dayOfWeek !== 0) {
        // Pad start of first week with empty days
        for (let i = 0; i < day.dayOfWeek; i++) {
          currentWeek.push({ date: '', dayOfWeek: i, pagesRead: 0, minutesRead: 0, sessionCount: 0 });
        }
      }

      currentWeek.push(day);

      if (day.dayOfWeek === 6 || index === heatmapData.length - 1) {
        weeksList.push([...currentWeek]);
        currentWeek = [];
      }
    });

    return weeksList;
  }, [heatmapData]);

  // Get color intensity based on pages read
  const getColorClass = (pagesRead: number) => {
    if (pagesRead === 0) return "bg-secondary hover:bg-secondary/80";
    if (pagesRead < 20) return "bg-emerald-200 dark:bg-emerald-900 hover:bg-emerald-300 dark:hover:bg-emerald-800";
    if (pagesRead < 50) return "bg-emerald-400 dark:bg-emerald-700 hover:bg-emerald-500 dark:hover:bg-emerald-600";
    if (pagesRead < 100) return "bg-emerald-600 dark:bg-emerald-500 hover:bg-emerald-700 dark:hover:bg-emerald-400";
    return "bg-emerald-800 dark:bg-emerald-300 hover:bg-emerald-900 dark:hover:bg-emerald-200";
  };

  const formatDate = (dateStr: string) => {
    if (!dateStr) return '';
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
  };

  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  return (
    <Card className="w-full">
      <CardHeader>
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2">
          <CardTitle className="flex items-center gap-2">
            <Flame className="h-5 w-5 text-orange-500" />
            Reading Activity
          </CardTitle>
          <div className="flex gap-4 text-sm">
            {currentStreak > 0 && (
              <div className="flex items-center gap-1">
                <Flame className="h-4 w-4 text-orange-500" />
                <span className="font-semibold">{currentStreak}</span>
                <span className="text-muted-foreground">day streak</span>
              </div>
            )}
            {bestStreak > 0 && (
              <div className="flex items-center gap-1">
                <span className="text-muted-foreground">Best:</span>
                <span className="font-semibold">{bestStreak}</span>
                <span className="text-muted-foreground">days</span>
              </div>
            )}
          </div>
        </div>
      </CardHeader>
      <CardContent className="pb-6 overflow-x-auto">
        <div className="min-w-max">
          <TooltipProvider>
            <div className="flex flex-col gap-1">
              {/* Day labels */}
              <div className="flex gap-1">
                <div className="w-10" />
                {weeks.map((week, weekIndex) => {
                  const firstDay = week.find(d => d.date);
                  if (!firstDay) return <div key={weekIndex} className="w-3.5" />;

                  const date = new Date(firstDay.date);
                  const isFirstOfMonth = date.getDate() <= 7;

                  return (
                    <div key={weekIndex} className="w-3.5">
                      {isFirstOfMonth && (
                        <span className="text-[10px] text-muted-foreground font-medium">
                          {months[date.getMonth()]}
                        </span>
                      )}
                    </div>
                  );
                })}
              </div>

              {/* Heatmap grid */}
              <div className="flex gap-1">
                {/* Day of week labels */}
                <div className="flex flex-col gap-1">
                  {days.map((day, i) => (
                    <div key={i} className="h-3.5 w-10 flex items-center">
                      {i % 2 === 1 && (
                        <span className="text-[10px] text-muted-foreground font-medium">{day}</span>
                      )}
                    </div>
                  ))}
                </div>

                {/* Weeks */}
                {weeks.map((week, weekIndex) => (
                  <div key={weekIndex} className="flex flex-col gap-1">
                    {Array.from({ length: 7 }).map((_, dayIndex) => {
                      const dayData = week.find(d => d.dayOfWeek === dayIndex);

                      if (!dayData || !dayData.date) {
                        return <div key={dayIndex} className="h-3.5 w-3.5" />;
                      }

                      return (
                        <Tooltip key={dayIndex}>
                          <TooltipTrigger asChild>
                            <div
                              className={`h-3.5 w-3.5 rounded-sm transition-colors cursor-pointer ${getColorClass(dayData.pagesRead)}`}
                            />
                          </TooltipTrigger>
                          <TooltipContent>
                            <div className="text-sm">
                              <p className="font-semibold">{formatDate(dayData.date)}</p>
                              {dayData.sessionCount > 0 ? (
                                <>
                                  <p>{dayData.pagesRead} pages</p>
                                  <p>{dayData.minutesRead} minutes</p>
                                  <p>{dayData.sessionCount} session{dayData.sessionCount > 1 ? 's' : ''}</p>
                                </>
                              ) : (
                                <p className="text-muted-foreground">No reading activity</p>
                              )}
                            </div>
                          </TooltipContent>
                        </Tooltip>
                      );
                    })}
                  </div>
                ))}
              </div>

              {/* Legend */}
              <div className="flex items-center gap-2 mt-4 text-xs text-muted-foreground">
                <span className="font-medium">Less</span>
                <div className="flex gap-1">
                  <div className="h-3.5 w-3.5 rounded-sm bg-secondary border border-muted" />
                  <div className="h-3.5 w-3.5 rounded-sm bg-emerald-200 dark:bg-emerald-900" />
                  <div className="h-3.5 w-3.5 rounded-sm bg-emerald-400 dark:bg-emerald-700" />
                  <div className="h-3.5 w-3.5 rounded-sm bg-emerald-600 dark:bg-emerald-500" />
                  <div className="h-3.5 w-3.5 rounded-sm bg-emerald-800 dark:bg-emerald-300" />
                </div>
                <span className="font-medium">More</span>
              </div>
            </div>
          </TooltipProvider>
        </div>
      </CardContent>
    </Card>
  );
}
