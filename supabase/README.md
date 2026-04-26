# Supabase setup

1. Create a Supabase project.
2. Run `supabase/schema.sql` in the SQL editor.
3. Add `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` from `.env.example`.
4. Enable Supabase Auth anonymous sign-ins for Raspberry Pi display claiming.
5. Insert your own user into `app_admin` using the SQL editor or service role.
6. Seed `couple`, `partner`, `dashboard_widget`, and `couple_alert`.
7. Store tokens only as hashes:
   - `display_token_hash = extensions.crypt('plain-display-token', extensions.gen_salt('bf'))`
   - `invite_token_hash = extensions.crypt('plain-invite-token', extensions.gen_salt('bf'))`

The frontend routes are private by design:
- `/display/:slug` signs in anonymously, then calls `claim_display_device`.
- `/invite/:slug/:partnerSlug?token=...` links a real Supabase Auth user to a `partner`.
- `/edit/:slug` requires a linked partner session.
- `/admin` calls `is_app_admin()`.

Without Supabase env vars the app keeps local demo mode for UI development only. Do not use local mode for a real private dashboard.

