"use client"

import * as React from "react"
import {
  IconChartDots3,
  IconDashboard,
  IconInnerShadowTop,
  IconSettings,
  IconUsers,
  IconBook,
  IconCalendar,
  IconNotebook,
  IconCategory,
  IconBulb,
} from "@tabler/icons-react"

import { NavMain } from "@/components/nav-main"
import { NavSecondary } from "@/components/nav-secondary"
import { NavUser } from "@/components/nav-user"
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarSeparator,
} from "@/components/ui/sidebar"

const data = {
  primaryNav: [
    {
      title: "Dashboard",
      url: "/dashboard",
      icon: IconDashboard,
    },
    {
      title: "Books",
      url: "/dashboard/books",
      icon: IconBook,
    },
    {
      title: "Authors",
      url: "/dashboard/authors",
      icon: IconUsers,
    },
    {
      title: "Genres",
      url: "/dashboard/genres",
      icon: IconCategory,
    },
  ],
  activityNav: [
    {
      title: "Recommendations",
      url: "/dashboard/recommendations",
      icon: IconBulb,
    },
    {
      title: "Calendar",
      url: "/dashboard/calendar",
      icon: IconCalendar,
    },
    {
      title: "Reading Log",
      url: "/dashboard/reading-log",
      icon: IconNotebook,
    },
    {
      title: "Statistics",
      url: "/dashboard/statistics",
      icon: IconChartDots3,
    },
  ],
  secondaryNav: [
    {
      title: "Settings",
      url: "/dashboard/settings",
      icon: IconSettings,
    },
  ],
}

interface AppSidebarProps extends React.ComponentProps<typeof Sidebar> {
  user: {
    name: string
    email: string
    avatar?: string
  }
  unfinishedBooks: Array<{
    id: number
    title: string
    pages: number
    currentPage: number
    status: string
  }>
}

export function AppSidebar({ user, unfinishedBooks, ...props }: AppSidebarProps) {
  return (
    <Sidebar collapsible="offcanvas" {...props}>
      <SidebarHeader>
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton
              asChild
              className="data-[slot=sidebar-menu-button]:!p-1.5"
            >
              <a href="/dashboard">
                <IconInnerShadowTop className="!size-5" />
                <span className="text-base font-semibold">Bookjet</span>
              </a>
            </SidebarMenuButton>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarHeader>
      <SidebarContent>
        <NavMain items={data.primaryNav} unfinishedBooks={unfinishedBooks} />
        <SidebarSeparator />
        <SidebarGroup>
          <SidebarGroupLabel>Activity</SidebarGroupLabel>
          <NavSecondary items={data.activityNav} />
        </SidebarGroup>
        <NavSecondary items={data.secondaryNav} className="mt-auto" />
      </SidebarContent>
      <SidebarFooter>
        <NavUser user={user} />
      </SidebarFooter>
    </Sidebar>
  )
}
