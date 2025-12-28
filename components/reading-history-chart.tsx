"use client"

import * as React from "react"
import { Area, AreaChart, CartesianGrid, XAxis, YAxis } from "recharts"
import { useIsMobile } from "@/hooks/use-mobile"
import {
  Card,
  CardAction,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import {
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
  type ChartConfig,
} from "@/components/ui/chart"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import {
  ToggleGroup,
  ToggleGroupItem,
} from "@/components/ui/toggle-group"

interface ReadingHistoryData {
  period: string // Date string or week/month identifier
  booksRead: number
  pagesRead: number
}

interface ReadingHistoryChartProps {
  data: ReadingHistoryData[]
  title?: string
  description?: string
}

const chartConfig = {
  booksRead: {
    label: "Books Read",
    color: "hsl(var(--primary))",
  },
  pagesRead: {
    label: "Pages Read",
    color: "hsl(var(--chart-2))",
  },
} satisfies ChartConfig

export function ReadingHistoryChart({
  data,
  title = "Reading History",
  description = "Your reading activity over time",
}: ReadingHistoryChartProps) {
  const isMobile = useIsMobile()
  const [timeRange, setTimeRange] = React.useState<"week" | "month">("month")
  const [metric, setMetric] = React.useState<"books" | "pages">("books")

  // Group data by week or month
  const processedData = React.useMemo(() => {
    if (data.length === 0) return []

    if (timeRange === "week") {
      // Group by week (last 12 weeks)
      const weeks = new Map<string, { booksRead: number; pagesRead: number }>()
      const now = new Date()

      // Initialize last 12 weeks
      for (let i = 11; i >= 0; i--) {
        const weekStart = new Date(now)
        weekStart.setDate(now.getDate() - (i * 7))
        weekStart.setHours(0, 0, 0, 0)
        const weekEnd = new Date(weekStart)
        weekEnd.setDate(weekStart.getDate() + 6)

        const weekKey = `${weekStart.getMonth() + 1}/${weekStart.getDate()}`
        weeks.set(weekKey, { booksRead: 0, pagesRead: 0 })
      }

      // Aggregate data
      data.forEach((item) => {
        const date = new Date(item.period)
        const weekStart = new Date(date)
        const dayOfWeek = date.getDay()
        weekStart.setDate(date.getDate() - dayOfWeek)
        weekStart.setHours(0, 0, 0, 0)

        const weekKey = `${weekStart.getMonth() + 1}/${weekStart.getDate()}`
        const existing = weeks.get(weekKey)
        if (existing) {
          existing.booksRead += item.booksRead
          existing.pagesRead += item.pagesRead
        }
      })

      return Array.from(weeks.entries()).map(([period, values]) => ({
        period,
        booksRead: values.booksRead,
        pagesRead: values.pagesRead,
      }))
    } else {
      // Group by month (last 12 months)
      const months = new Map<string, { booksRead: number; pagesRead: number }>()
      const now = new Date()

      // Initialize last 12 months
      for (let i = 11; i >= 0; i--) {
        const monthDate = new Date(now.getFullYear(), now.getMonth() - i, 1)
        const monthKey = monthDate.toLocaleDateString("en-US", {
          month: "short",
          year: "numeric",
        })
        months.set(monthKey, { booksRead: 0, pagesRead: 0 })
      }

      // Aggregate data
      data.forEach((item) => {
        const date = new Date(item.period)
        const monthKey = date.toLocaleDateString("en-US", {
          month: "short",
          year: "numeric",
        })
        const existing = months.get(monthKey)
        if (existing) {
          existing.booksRead += item.booksRead
          existing.pagesRead += item.pagesRead
        }
      })

      return Array.from(months.entries()).map(([period, values]) => ({
        period,
        booksRead: values.booksRead,
        pagesRead: values.pagesRead,
      }))
    }
  }, [data, timeRange])

  const maxValue = React.useMemo(() => {
    if (processedData.length === 0) return 10
    const values = metric === "books"
      ? processedData.map(d => d.booksRead)
      : processedData.map(d => d.pagesRead)
    return Math.max(...values, 1)
  }, [processedData, metric])

  return (
    <Card className="@container/card">
      <CardHeader>
        <CardTitle>{title}</CardTitle>
        <CardDescription>
          <span className="hidden @[540px]/card:block">{description}</span>
          <span className="@[540px]/card:hidden">Reading activity</span>
        </CardDescription>
        <CardAction className="flex flex-col gap-2 @[540px]/card:flex-row">
          <ToggleGroup
            type="single"
            value={timeRange}
            onValueChange={(value) => value && setTimeRange(value as "week" | "month")}
            variant="outline"
            className="hidden *:data-[slot=toggle-group-item]:!px-4 @[540px]/card:flex"
          >
            <ToggleGroupItem value="month">By Month</ToggleGroupItem>
            <ToggleGroupItem value="week">By Week</ToggleGroupItem>
          </ToggleGroup>
          <Select value={timeRange} onValueChange={(value) => setTimeRange(value as "week" | "month")}>
            <SelectTrigger
              className="flex w-32 **:data-[slot=select-value]:block **:data-[slot=select-value]:truncate @[540px]/card:hidden"
              size="sm"
              aria-label="Select time range"
            >
              <SelectValue placeholder="By Month" />
            </SelectTrigger>
            <SelectContent className="rounded-xl">
              <SelectItem value="month" className="rounded-lg">
                By Month
              </SelectItem>
              <SelectItem value="week" className="rounded-lg">
                By Week
              </SelectItem>
            </SelectContent>
          </Select>

          <ToggleGroup
            type="single"
            value={metric}
            onValueChange={(value) => value && setMetric(value as "books" | "pages")}
            variant="outline"
            className="hidden *:data-[slot=toggle-group-item]:!px-4 @[540px]/card:flex"
          >
            <ToggleGroupItem value="books">Books</ToggleGroupItem>
            <ToggleGroupItem value="pages">Pages</ToggleGroupItem>
          </ToggleGroup>
          <Select value={metric} onValueChange={(value) => setMetric(value as "books" | "pages")}>
            <SelectTrigger
              className="flex w-32 **:data-[slot=select-value]:block **:data-[slot=select-value]:truncate @[540px]/card:hidden"
              size="sm"
              aria-label="Select metric"
            >
              <SelectValue placeholder="Books" />
            </SelectTrigger>
            <SelectContent className="rounded-xl">
              <SelectItem value="books" className="rounded-lg">
                Books
              </SelectItem>
              <SelectItem value="pages" className="rounded-lg">
                Pages
              </SelectItem>
            </SelectContent>
          </Select>
        </CardAction>
      </CardHeader>
      <CardContent className="px-2 pt-4 sm:px-6 sm:pt-6">
        {processedData.length === 0 ? (
          <div className="flex h-[250px] items-center justify-center text-muted-foreground">
            No reading data available
          </div>
        ) : (
          <ChartContainer
            config={chartConfig}
            className="aspect-auto h-[250px] w-full"
          >
            <AreaChart data={processedData}>
              <defs>
                <linearGradient id="fillBooks" x1="0" y1="0" x2="0" y2="1">
                  <stop
                    offset="5%"
                    stopColor="hsl(var(--primary))"
                    stopOpacity={0.8}
                  />
                  <stop
                    offset="95%"
                    stopColor="hsl(var(--primary))"
                    stopOpacity={0.1}
                  />
                </linearGradient>
                <linearGradient id="fillPages" x1="0" y1="0" x2="0" y2="1">
                  <stop
                    offset="5%"
                    stopColor="hsl(var(--chart-2))"
                    stopOpacity={0.8}
                  />
                  <stop
                    offset="95%"
                    stopColor="hsl(var(--chart-2))"
                    stopOpacity={0.1}
                  />
                </linearGradient>
              </defs>
              <CartesianGrid vertical={false} strokeDasharray="3 3" opacity={0.3} />
              <XAxis
                dataKey="period"
                tickLine={false}
                axisLine={false}
                tickMargin={8}
                minTickGap={32}
                tick={{ fontSize: 12 }}
              />
              <YAxis
                tickLine={false}
                axisLine={false}
                tickMargin={8}
                tick={{ fontSize: 12 }}
                domain={[0, maxValue]}
              />
              <ChartTooltip
                cursor={false}
                content={
                  <ChartTooltipContent
                    labelFormatter={(value) => {
                      return timeRange === "month"
                        ? `${value}`
                        : `Week of ${value}`
                    }}
                    indicator="dot"
                  />
                }
              />
              {metric === "books" ? (
                <Area
                  dataKey="booksRead"
                  type="monotone"
                  fill="url(#fillBooks)"
                  stroke="hsl(var(--primary))"
                  strokeWidth={2}
                />
              ) : (
                <Area
                  dataKey="pagesRead"
                  type="monotone"
                  fill="url(#fillPages)"
                  stroke="hsl(var(--chart-2))"
                  strokeWidth={2}
                />
              )}
            </AreaChart>
          </ChartContainer>
        )}
      </CardContent>
    </Card>
  )
}
