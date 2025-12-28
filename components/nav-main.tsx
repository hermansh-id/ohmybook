"use client"

import { useState } from "react"
import { IconCirclePlusFilled, IconClock, type Icon } from "@tabler/icons-react"

import { Button } from "@/components/ui/button"
import {
  SidebarGroup,
  SidebarGroupContent,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
} from "@/components/ui/sidebar"
import { AddReadingSessionDialog } from "@/components/add-reading-session-dialog"

export function NavMain({
  items,
  unfinishedBooks,
}: {
  items: {
    title: string
    url: string
    icon?: Icon
  }[]
  unfinishedBooks: Array<{
    id: number
    title: string
    pages: number
    currentPage: number
    status: string
  }>
}) {
  return (
    <SidebarGroup>
      <SidebarGroupContent className="flex flex-col gap-2">
        <SidebarMenu>
          <SidebarMenuItem className="flex items-center gap-2">
            <SidebarMenuButton
              asChild
              tooltip="Add Book"
              className="bg-primary text-primary-foreground hover:bg-primary/90 hover:text-primary-foreground active:bg-primary/90 active:text-primary-foreground min-w-8 duration-200 ease-linear"
            >
              <a href="/dashboard/books/add">
                <IconCirclePlusFilled />
                <span>Add Book</span>
              </a>
            </SidebarMenuButton>
            <AddReadingSessionDialog
              books={unfinishedBooks}
              trigger={
                <Button
                  size="icon"
                  className="size-8 group-data-[collapsible=icon]:opacity-0"
                  variant="outline"
                >
                  <IconClock />
                  <span className="sr-only">Add Reading Session</span>
                </Button>
              }
            />
          </SidebarMenuItem>
        </SidebarMenu>
        <SidebarMenu>
          {items.map((item) => (
            <SidebarMenuItem key={item.title}>
              <SidebarMenuButton asChild tooltip={item.title}>
                <a href={item.url}>
                  {item.icon && <item.icon />}
                  <span>{item.title}</span>
                </a>
              </SidebarMenuButton>
            </SidebarMenuItem>
          ))}
        </SidebarMenu>
      </SidebarGroupContent>
    </SidebarGroup>
  )
}
