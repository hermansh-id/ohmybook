import { createFileRoute, Outlet, redirect } from "@tanstack/react-router";
import { createServerFn } from "@tanstack/react-start";
import { getRequest } from "@tanstack/react-start/server";
import { auth } from "@/lib/auth";
import { getUnfinishedBooksAction } from "@/actions/reading-sessions";
import { AppSidebar } from "@/components/app-sidebar";
import { SiteHeader } from "@/components/site-header";
import {
  SidebarInset,
  SidebarProvider,
} from "@/components/ui/sidebar";
import { CommandPalette } from "@/components/command-palette";

const getSessionFn = createServerFn({ method: "GET" }).handler(async () => {
  const request = getRequest();
  return auth.api.getSession({ headers: request.headers });
});

const getUnfinishedBooksFn = createServerFn({ method: "GET" }).handler(async () => {
  return getUnfinishedBooksAction();
});

export const Route = createFileRoute('/dashboard')({
  beforeLoad: async () => {
    const session = await getSessionFn();
    if (!session) throw redirect({ to: '/login' });
    return { user: session.user };
  },
  loader: async () => {
    const unfinishedBooks = await getUnfinishedBooksFn();
    return { unfinishedBooks };
  },
  component: DashboardLayout,
});

function DashboardLayout() {
  const { user } = Route.useRouteContext();
  const { unfinishedBooks } = Route.useLoaderData();

  const sidebarUser = {
    name: user.name,
    email: user.email,
    avatar: user.image ?? undefined,
  };

  return (
    <SidebarProvider
      style={
        {
          "--sidebar-width": "calc(var(--spacing) * 72)",
          "--header-height": "calc(var(--spacing) * 12)",
        } as React.CSSProperties
      }
    >
      <AppSidebar variant="inset" user={sidebarUser} unfinishedBooks={unfinishedBooks} />
      <SidebarInset>
        <SiteHeader />
        <div className="flex flex-1 flex-col">
          <div className="@container/main flex flex-1 flex-col gap-2">
            <Outlet />
          </div>
        </div>
      </SidebarInset>
      <CommandPalette />
    </SidebarProvider>
  );
}
