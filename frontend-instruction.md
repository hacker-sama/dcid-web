You are an expert Next.js architect. Your task is to scaffold a 
production-grade Next.js 14 frontend for a Vietnamese e-Government platform 
called "DCID" (DCID Platform). The backend is a separate Spring Boot 
service exposing REST + WebSocket APIs, secured by Keycloak OAuth2.

## STRICT RULES
- Use Next.js 14 App Router exclusively. No Pages Router.
- Use TypeScript throughout. No .js files except config files.
- Every page component must have proper TypeScript interfaces for props and data.
- Every placeholder page must render a visible UI with a "Work in progress" 
  notice — never a blank page or null return.
- No business logic in page components — extract to hooks or server actions.
- After scaffolding, run: npm run build
  Fix ALL TypeScript and build errors before finishing.

---

## TECH STACK

- Next.js 14.x (App Router)
- TypeScript 5.x
- TailwindCSS 3.x
- next-auth v5 (Auth.js) — Keycloak provider
- TanStack Query v5 (React Query) — client-side data fetching
- Axios — HTTP client
- Zod — schema validation for forms and API responses
- React Hook Form + Zod resolver
- Lucide React — icons
- Recharts — charts (officer dashboard)
- shadcn/ui — component primitives (install: button, input, select,
  dialog, badge, table, tabs, card, skeleton, toast, dropdown-menu)
- next-intl — i18n (Vietnamese vi + English en)
- date-fns — date formatting with Vietnamese locale

---

## PROJECT STRUCTURE TO CREATE

dcid-frontend/
├── app/
│   ├── layout.tsx                    ← root layout: providers, fonts
│   ├── page.tsx                      ← redirect → /citizen or /officer
│   │                                    based on role
│   ├── globals.css                   ← Tailwind directives + CSS tokens
│   │
│   ├── (auth)/
│   │   └── login/
│   │       └── page.tsx              ← Keycloak redirect button
│   │
│   ├── citizen/
│   │   ├── layout.tsx                ← sidebar nav + header for citizen
│   │   ├── page.tsx                  ← redirect → /citizen/dashboard
│   │   ├── dashboard/
│   │   │   └── page.tsx             ← stat cards + recent applications
│   │   ├── procedures/
│   │   │   ├── page.tsx             ← search + procedure card grid
│   │   │   └── [code]/
│   │   │       └── page.tsx         ← procedure detail + CTA button
│   │   ├── applications/
│   │   │   ├── page.tsx             ← application list with filters
│   │   │   ├── new/
│   │   │   │   └── [code]/
│   │   │   │       └── page.tsx     ← multi-step wizard
│   │   │   └── [id]/
│   │   │       └── page.tsx         ← detail + timeline + WebSocket
│   │   ├── appointments/
│   │   │   └── page.tsx
│   │   └── notifications/
│   │       └── page.tsx
│   │
│   ├── officer/
│   │   ├── layout.tsx                ← sidebar nav for officer/supervisor/admin
│   │   ├── dashboard/
│   │   │   └── page.tsx             ← KPI cards + charts
│   │   ├── applications/
│   │   │   ├── page.tsx             ← application queue table
│   │   │   └── [id]/
│   │   │       └── page.tsx         ← split view: docs + review panel
│   │   ├── procedures/
│   │   │   └── page.tsx             ← CRUD table
│   │   ├── users/
│   │   │   └── page.tsx             ← user management
│   │   ├── reports/
│   │   │   └── page.tsx             ← date picker + table + export
│   │   └── audit-log/
│   │       └── page.tsx             ← immutable log table
│   │
│   └── api/
│       └── auth/
│           └── [...nextauth]/
│               └── route.ts         ← Auth.js Keycloak handler
│
├── components/
│   ├── ui/                           ← shadcn/ui components (auto-generated)
│   │
│   ├── shared/
│   │   ├── StatusBadge.tsx           ← maps ApplicationStatus → color + label
│   │   ├── ApplicationTimeline.tsx   ← vertical timeline component
│   │   ├── FileUploadZone.tsx        ← drag-drop, preview, 10MB limit
│   │   ├── PageHeader.tsx            ← title + breadcrumb + actions slot
│   │   ├── DataTable.tsx             ← generic sortable/filterable table
│   │   ├── ConfirmDialog.tsx         ← wraps shadcn AlertDialog
│   │   ├── EmptyState.tsx            ← icon + message + optional CTA
│   │   ├── LoadingSkeleton.tsx       ← animate-pulse placeholder blocks
│   │   ├── NotificationBell.tsx      ← bell icon + unread badge + dropdown
│   │   └── WebSocketIndicator.tsx    ← pulsing dot: connected/disconnected
│   │
│   ├── citizen/
│   │   ├── StatCard.tsx
│   │   ├── ProcedureCard.tsx
│   │   ├── ApplicationListItem.tsx
│   │   └── wizard/
│   │       ├── WizardLayout.tsx      ← step indicator + content area
│   │       ├── StepPersonalInfo.tsx
│   │       ├── StepDynamicForm.tsx   ← renders fields from JSON Schema
│   │       ├── StepDocuments.tsx
│   │       ├── StepSignature.tsx     ← HTML5 canvas e-signature
│   │       └── StepConfirm.tsx
│   │
│   └── officer/
│       ├── KpiCard.tsx
│       ├── ApplicationQueueRow.tsx
│       ├── ReviewPanel.tsx
│       └── charts/
│           ├── StatusBarChart.tsx    ← Recharts BarChart
│           └── SubmissionLineChart.tsx
│
├── hooks/
│   ├── useApplicationStatus.ts  ← WebSocket hook with auto-reconnect
│   ├── useApplications.ts       ← TanStack Query: list, detail, mutations
│   ├── useProcedures.ts
│   ├── useNotifications.ts      ← polling every 30s for unread count
│   ├── useOfficerDashboard.ts
│   └── useFileUpload.ts         ← handles multipart upload to backend
│
├── lib/
│   ├── auth.ts                  ← Auth.js config: Keycloak provider,
│   │                               callbacks to attach access_token + role
│   ├── api-client.ts            ← Axios instance: baseURL from env,
│   │                               request interceptor → attach Bearer token,
│   │                               response interceptor → handle 401/403
│   ├── query-client.ts          ← TanStack Query client config
│   ├── websocket.ts             ← WebSocket connection manager (singleton)
│   └── utils.ts                 ← cn() for className merging, formatDate,
│                                    formatStatus, truncate
│
├── types/
│   ├── application.ts           ← ApplicationStatus enum, ApplicationDTO,
│   │                               ApplicationDetailDTO, StatusHistoryItem
│   ├── procedure.ts             ← ProcedureTypeDTO, JsonSchemaField
│   ├── user.ts                  ← UserRole enum, UserProfileDTO
│   ├── notification.ts
│   ├── appointment.ts
│   └── api.ts                   ← ApiResponse<T>, PagedResponse<T>,
│                                    ErrorResponse, FieldError
│
├── constants/
│   ├── routes.ts                ← ROUTES object with all app paths
│   ├── query-keys.ts            ← QUERY_KEYS for TanStack Query
│   └── application-status.ts   ← STATUS_CONFIG: label, color, icon per status
│
├── middleware.ts                ← Next.js middleware: protect /citizen/* 
│                                   and /officer/*, redirect based on role
│
├── public/
│   └── logo.svg                 ← simple SVG placeholder logo
│
├── messages/
│   ├── vi.json                  ← Vietnamese translations (key strings)
│   └── en.json                  ← English translations
│
├── next.config.ts
├── tailwind.config.ts           ← extend with design tokens
├── tsconfig.json
├── .env.example
├── Dockerfile
└── CLAUDE.md

---

## KEY IMPLEMENTATION DETAILS

### globals.css — design tokens
:root {
  --color-primary: #1B3F8B;
  --color-primary-hover: #2D57B0;
  --color-primary-tint: #E8EFF9;
  --color-accent: #D97706;
  --color-accent-tint: #FEF3C7;
  --color-success: #16A34A;
  --color-danger: #DC2626;
  --color-warning: #EA580C;
  --radius-sm: 6px;
  --radius-md: 8px;
  --radius-lg: 12px;
}

### tailwind.config.ts — extend with tokens
colors: primary, accent, success, danger, warning mapped to CSS vars
fontFamily: { sans: ['Be Vietnam Pro', 'Inter', 'sans-serif'] }

### lib/auth.ts — Auth.js Keycloak config
- Provider: Keycloak
- Callbacks:
  jwt callback: attach access_token and extract role from 
    token.realm_access.roles[0]
  session callback: expose session.accessToken and session.user.role
- Session strategy: jwt

### middleware.ts
- Protect /citizen/* → require authenticated + role CITIZEN
- Protect /officer/* → require authenticated + role in 
  [OFFICER, SUPERVISOR, ADMIN]
- Unauthenticated → redirect /login
- Wrong role → redirect to correct portal or /403

### StatusBadge.tsx
Map each ApplicationStatus to:
- DRAFT:               gray bg, gray text
- SUBMITTED:           blue bg (#E8EFF9), blue text (#1B3F8B)
- IN_REVIEW:           amber bg (#FEF3C7), amber text (#92400E)
- PENDING_SUPPLEMENT:  orange bg (#FFF7ED), orange text (#9A3412)
- APPROVED:            green bg (#F0FDF4), green text (#166534)
- REJECTED:            red bg (#FEF2F2), red text (#991B1B)
- WITHDRAWN:           gray bg, gray text

### ApplicationTimeline.tsx
Vertical timeline: each StatusHistoryItem shows:
- Colored dot (color from STATUS_CONFIG)
- Status label (bold)
- Changed by + timestamp (secondary text)
- Note if present (rounded bg box)
Connected by vertical line between dots

### StepDynamicForm.tsx — JSON Schema renderer
Support these field types from JSON Schema:
- string → <Input>
- string + enum → <Select>
- string + format: date → date input
- number → number <Input>
- boolean → checkbox
Each field must show label, required indicator (*), validation error

### useApplicationStatus.ts — WebSocket hook
- Connect to ws://backend/ws/applications/{id}
- On message: parse JSON, invalidate TanStack Query cache for that application
- Auto-reconnect with exponential backoff (max 5 retries)
- Expose: { isConnected, lastEvent }
- Clean up on unmount

### .env.example
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=change-me-in-production
KEYCLOAK_ISSUER=http://localhost:8180/realms/dcid
KEYCLOAK_CLIENT_ID=dcid-frontend
KEYCLOAK_CLIENT_SECRET=change-me
NEXT_PUBLIC_API_URL=http://localhost:8080
NEXT_PUBLIC_WS_URL=ws://localhost:8080

### CLAUDE.md — write with:
- Project overview
- How to run: npm install, npm run dev
- App Router conventions used (Server vs Client components decision guide)
- How to add a new page (checklist)
- How to add a new API hook
- TypeScript strict mode notes

### Dockerfile
Multi-stage:
Stage 1 (deps): node:20-alpine, install production deps
Stage 2 (builder): copy source, run npm run build
Stage 3 (runner): node:20-alpine, copy .next standalone output
ENV NODE_ENV=production
EXPOSE 3000
Non-root user (nextjs:nodejs)

---

## WHAT NOT TO DO
- Do not use Pages Router
- Do not use any .js file for application code (config files are ok)
- Do not fetch data directly in Client Components — use hooks
- Do not store access tokens in localStorage
- Do not import server-only modules in client components
- Do not hardcode API URLs — always use environment variables
- Do not create the backend or docker-compose

---

## VERIFICATION STEPS
After creating all files:
1. Run: npm install
2. Run: npm run build
3. Fix ALL TypeScript errors and build errors
4. Run: npx tsc --noEmit
5. Report: list every file created with its line count