# DCID Frontend Project Notes

## Project Overview
This is the Next.js 14 frontend for the DCID e-Government Platform. It uses the App Router, TailwindCSS, shadcn/ui, TanStack Query, and NextAuth.js (Keycloak).

## How to run
1. Ensure you have Node.js 20+ installed.
2. Install dependencies: `npm install`
3. Copy `.env.example` to `.env` and configure it.
4. Run dev server: `npm run dev`
5. Access at `http://localhost:3000`

## Architecture Guide
- **Server Components (Default):** Use for data fetching (if direct to DB) or layout. But since we use a Spring Boot backend, we mostly use Client Components with React Query for data fetching.
- **Client Components (`"use client"`):** Used almost everywhere since we heavily rely on React Hooks, React Query, and interactive UI (shadcn/ui).

## How to add a new page
1. Determine if it belongs to `/citizen` or `/officer`.
2. Create `app/[role]/[feature]/page.tsx`.
3. Add the route to `constants/routes.ts`.
4. Add a navigation link in the layout if necessary.

## How to add a new API hook
1. Define types in `types/`.
2. Add query keys in `constants/query-keys.ts`.
3. Create a new hook in `hooks/` using `useQuery` or `useMutation` with `apiClient`.

## TypeScript Notes
- We enforce Strict Mode.
- No `any` type allowed for new code unless strictly necessary for generic utilities.
- Always define proper interfaces for API responses and component props.
