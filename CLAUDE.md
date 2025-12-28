# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Bookjet is a Next.js 16.1 application built with React 19, TypeScript, and Tailwind CSS v4. The project uses the App Router architecture with server components and follows the "new-york" shadcn/ui component style.

## Package Manager

This project uses **Bun** as the package manager (indicated by `bun.lock`). Always use `bun` commands instead of npm/yarn/pnpm:
- `bun install` - Install dependencies
- `bun run dev` - Run development server
- `bun run build` - Build for production
- `bun run start` - Start production server
- `bun run lint` - Run ESLint

## Development Commands

### Running the App
```bash
bun dev          # Start development server at http://localhost:3000
bun build        # Build for production
bun start        # Start production server
```

### Linting
```bash
bun lint         # Run ESLint with Next.js config
```

Note: There are no test scripts currently configured in this project.

## Architecture & Structure

### Next.js App Router
- Uses Next.js 16.1 with React 19.2 and App Router (`app/` directory)
- TypeScript strict mode enabled
- Server components by default (RSC enabled in components.json)

### Styling System
- **Tailwind CSS v4** with PostCSS (@tailwindcss/postcss)
- Custom theme using CSS variables with `oklch()` color space
- Dark mode support via `.dark` class with custom variant `@custom-variant dark (&:is(.dark *))`
- Global styles in `app/globals.css`
- Uses `tw-animate-css` for animations
- Custom radius tokens: `--radius-sm` through `--radius-4xl`

### Path Aliases
All imports use `@/*` alias mapped to the project root:
```typescript
@/components    // components directory
@/lib/utils     // lib/utils.ts
@/components/ui // UI components (shadcn/ui)
@/lib           // lib directory
@/hooks         // hooks directory
```

### Component System
- **shadcn/ui** configured with "new-york" style
- **ALWAYS use shadcn/ui components** - never create custom UI components from scratch
- Add new shadcn components with: `bunx shadcn@latest add <component-name>`
- Components use `class-variance-authority` for variant management
- `cn()` utility function in `lib/utils.ts` combines `clsx` and `tailwind-merge`
- Icon library: `lucide-react`
- CSS variables enabled for theming
- Base color: zinc
- No prefix for Tailwind utilities

### Design Philosophy
**MOBILE-FIRST APPROACH - ALWAYS**
- Design for mobile screens first (320px minimum)
- Use responsive Tailwind classes: `sm:`, `md:`, `lg:`, `xl:`
- Stack elements vertically on mobile, horizontal on desktop
- Touch-friendly buttons and tap targets (minimum 44px)
- Hide/show elements based on screen size when needed
- Test layouts at 375px, 768px, 1024px, 1440px

### TypeScript Configuration
- Strict mode enabled
- Module resolution: `bundler`
- JSX runtime: `react-jsx`
- Target: ES2017
- All paths use `@/*` alias

### Fonts
- Uses Next.js `next/font` with Geist Sans and Geist Mono
- Font variables: `--font-geist-sans` and `--font-geist-mono`
- Applied via className in root layout

## File Organization

```
app/              # Next.js App Router pages and layouts
  layout.tsx      # Root layout with fonts and metadata
  page.tsx        # Homepage
  globals.css     # Global styles and Tailwind configuration
lib/              # Utility functions
  utils.ts        # cn() helper for className merging
public/           # Static assets (SVGs, images)
components/       # React components (will contain shadcn/ui components)
  ui/             # shadcn/ui components
```

## Adding shadcn/ui Components

This project is configured for shadcn/ui. To add components:
```bash
bunx shadcn@latest add <component-name>
```

Components will be added to `components/ui/` following the "new-york" style with RSC support.

## Data Fetching

**IMPORTANT: Always use TanStack Query for client-side data fetching.**

### TanStack Query (React Query)
- Use `@tanstack/react-query` for all client-side data fetching
- Server actions should be wrapped in query functions
- Place query hooks in `lib/queries/` directory
- Configure QueryClient in root layout provider

Example pattern:
```typescript
// lib/queries/books.ts
import { useQuery } from '@tanstack/react-query';
import { getBooksAction } from '@/app/actions/books';

export function useBooks() {
  return useQuery({
    queryKey: ['books'],
    queryFn: () => getBooksAction(),
  });
}
```

### Server Actions
- Place server actions in `app/actions/` directory
- Mark with `'use server'` directive
- Used for data mutations and server-side operations
- Can be called from Client Components via TanStack Query

## Database

### Drizzle ORM + Neon PostgreSQL
- Uses Drizzle ORM with Neon serverless PostgreSQL
- Schema defined in `lib/db/schema/`
- Database queries in `lib/db/queries.ts`
- Connection configured in `lib/db/index.ts`

### Database Commands
```bash
bun db:push      # Push schema to database
bun db:generate  # Generate migrations
bun db:migrate   # Run migrations
bun db:studio    # Open Drizzle Studio
```

## Authentication

### Better Auth
- Email/password authentication
- Configuration in `lib/auth.ts`
- Client-side helpers in `lib/auth-client.ts`
- API routes at `/api/auth/[...all]`
- Protected routes use `auth.api.getSession()` check

## Key Dependencies

- **Next.js 16.1** - React framework
- **React 19.2** - UI library
- **TypeScript 5** - Type safety
- **Tailwind CSS v4** - Utility-first CSS framework
- **Drizzle ORM** - TypeScript ORM
- **Better Auth** - Authentication
- **TanStack Query** - Data fetching and caching
- **class-variance-authority** - CVA for component variants
- **lucide-react** - Icon library
- **clsx + tailwind-merge** - Conditional className utilities
