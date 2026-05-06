# CoupleDash AI Handoff

CoupleDash is a new Vue/Supabase app for a private dashboard shared by two partners. The dashboard runs on a shared display, updates live through Supabase Realtime, and includes a QR code to open the authenticated edit screen.

## Product Direction

Build the simplest useful v1. Prefer deleting or rewriting unclear old structures over preserving compatibility. Do not add custom auth/session logic. Use standard Supabase features and keep the code small.

Keep:

- Private Supabase account-based access.
- Admin tenant creation and partner invite links.
- `/display/:coupleSlug` with a QR code to `/edit/:coupleSlug`.
- `/edit/:coupleSlug` for shared widgets, timeline/chart data, partner status, alerts, and avatar upload.
- Supabase Realtime refresh for display data.
- RLS and RPC-first authorization.

Avoid:

- Local demo mode as a production behavior.
- Legacy cleanup branches or old schema support.
- Custom QR token auth beyond Supabase account and invite ownership.
- Parallel frontend-only ownership models.

## Stack

- Frontend: Vue 3, Vite, TypeScript, Vue Router, Vue I18n.
- UI: Nuxt UI Vue plugin and Tailwind CSS v4.
- Visuals: Unovis chart widgets and `qrcode`.
- Backend: Supabase Auth, Postgres, RLS, RPC functions, Realtime, Storage.
- Runtime/scripts: Bun.

## Auth And Data Model

Supabase Auth is the only auth system. The frontend uses `supabase.auth.getSession()` and `onAuthStateChange()`. Pages may show auth panels, but real access control must stay in Supabase RLS and security-definer RPCs.

Core tables:

- `app_admin`: users allowed to manage tenants.
- `couple`: one private dashboard tenant.
- `partner`: the two partner records, linked to `auth.users` after invite acceptance.
- `couple_member`: membership bridge for partner/admin access.
- `dashboard_widget`: shared display widgets.
- `couple_alert`: live partner/system alerts.
- Storage bucket `partner-avatars`: private avatar uploads, read through signed URLs.

Invite flow:

- Admin creates a tenant and receives two partner invite links.
- Invite tokens are stored only as hashes using `extensions.crypt`.
- The partner opens `/invite/:coupleSlug/:partnerSlug?token=...`, signs in, and `accept_partner_invite()` links their Supabase user to the partner row.
- Invite tokens cannot be recovered; regenerate them when needed.

Realtime:

- `partner`, `dashboard_widget`, and `couple_alert` are added to `supabase_realtime`.
- The dashboard subscribes to `postgres_changes` filtered by `couple_id`.
- On any relevant change, the couple data reloads.

## Implementation Rules

- Read existing files before editing.
- Prefer Supabase standard features over custom backend logic.
- Keep schema and frontend state small and explicit.
- Enable RLS on exposed tables.
- Never expose service role keys in frontend code.
- Do not use `user_metadata` for authorization.
- Use RPCs for privileged mutations that need ownership checks.
- If a feature is unclear, choose the simplest v1 behavior instead of preserving old behavior.

## Verification

Run:

```sh
bun run typecheck
bun run build
```

Manual checks:

- A signed-in partner sees only linked dashboards.
- Admin can create/manage tenants and partner invite links.
- Invite links claim exactly one partner account.
- Editing widgets/status/alerts/avatar updates the display through Realtime.
- Unauthenticated users and non-members cannot load or mutate private couple data.
