# DCID Frontend Project Notes

## Project Overview
DCID Frontend is a Next.js 14 application that serves the DCID e‑Government platform UI. It uses the App Router, React Server Components, TailwindCSS, shadcn/ui components, TanStack Query for server data fetching, and NextAuth.js for authentication against Keycloak.

## How to Run Locally
```bash
# 1. Install Node 20+ (LTS)
# 2. Install dependencies
npm install
# 3. Copy environment variables
cp .env.example .env # Edit secrets
# 4. Start dev server
npm run dev
# 5. Access at http://localhost:3000
```

## Dependencies & Key Libraries
- **Next.js 14** – App Router & React Server Components
- **TailwindCSS** & **shadcn/ui** – UI styling and components
- **TanStack Query v5** – GraphQL‑ish query/mutation abstraction
- **NextAuth.js** (Keycloak provider) – JWT auth, session handling
- **React Hook Form + Zod** – form state and validation
- **Axios** – API client (via wrapper in `lib/apiClient.ts`)
- **Recharts** – charts for Officer dashboards

## Architecture Guide
- **Server Components** – Used for layout & data‑loading where possible; most page logic is Client Components due to interaction.
- **Client Components (`"use client"`)** – almost every page/action; hooks utilising TanStack Query.
- **App Router** – `app/` directory contains layouts, pages, and API routes.
- **Hooks** – `hooks/` contains data‑loading and mutations (e.g., `useProcedures`, `useApplications`).
- **Components** – `components/` subfolders per role (citizen/officer) and shared.
- **Routes** – Centralized in `constants/routes.ts` for type‑safe navigation.
- **Environment** – `.env.example` provides required variables (`NEXTAUTH_*`, `KEYCLOAK_*`, `NEXT_PUBLIC_API_URL`).

## Adding a New Page
1. Decide the role: citizen or officer.
2. Create the file in `app/[role]/[feature]/page.tsx`.
3. Import layout and necessary hooks.
4. Register route in `constants/routes.ts` if needed.
5. Add navigation link in the appropriate layout.

## Adding a New API Hook
1. Define TypeScript types in `types/` for request/response.
2. Create a query key in `constants/query-keys.ts`.
3. Implement the hook in `hooks/` using `useQuery` or `useMutation`.
4. Export the hook for use in pages.

## TypeScript Rules
- **Strict mode** is enforced.
- **No `any`** unless absolutely required.
- Prefer interfaces or type aliases for API shapes.
- Keep component props strongly typed.

## Security & Authentication
- Auth is handled by NextAuth.js with Keycloak provider.
- Use the `useSession` hook to guard client routes.
- Server components use `await getServerSession()` for protected data.
- All secrets reside in environment variables; never commit `.env`.

## Testing & Linting
- Uses ESLint (`next lint`).
- No explicit unit test framework present yet; consider adding Jest/React Testing Library in future.

## Known Missing or Incomplete Logic
- API client (`lib/apiClient.ts`) is a thin wrapper around Axios; verify request/response types with the backend.
- OAuth2 token refresh handling is managed by NextAuth, but custom hooks for token introspection are not yet implemented.
- Some cache invalidation strategies for TanStack Query are pending.

## Conflict Notes
- None currently. If a legacy page becomes outdated, replace with a server/client component pattern to align with the rest of the codebase.
