# CoupleDash

CoupleDash is a private two-partner dashboard built with Vue and Supabase. It is meant to run indefinitely on a shared display, show live relationship widgets, and expose a QR code that opens the authenticated edit screen for the same couple.

The current product direction is a simple v1: Supabase-only authentication, RLS/RPC-first authorization, no custom session system, no local demo mode for production behavior, and no legacy compatibility structures.

## Stack

- Vue 3, Vite, TypeScript, Vue Router, Vue I18n
- Nuxt UI, Tailwind CSS v4, lucide/simple-icons through Nuxt UI icon names
- Supabase Auth, Postgres, RLS, RPC functions, Realtime, and Storage
- Unovis for chart widgets and `qrcode` for dashboard edit QR codes
- Bun for package scripts

## Routes

- `/` lists dashboards linked to the signed-in account.
- `/display/:coupleSlug` shows the private always-on dashboard display.
- `/edit/:coupleSlug` edits shared widgets, timeline/chart data, status, alerts, and avatar data.
- `/invite/:coupleSlug/:partnerSlug?token=...` claims one partner invite after Supabase sign-in.
- `/admin`, `/admin/new`, and `/admin/tenants/:tenantId` provision and manage couple tenants.

## Setup

```sh
bun install
```

Create a Supabase project, apply `supabase/schema.sql`, and configure:

```sh
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

See `supabase/README.md` for auth provider and admin setup.

## Development

```sh
bun dev
bun run typecheck
bun run build
```

## AI Context

Use `docs/AI_HANDOFF.md` when starting a new AI chat about this project. It summarizes the current architecture, auth model, data model, and implementation rules.
