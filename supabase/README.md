# Supabase setup

1. Create a Supabase project.
2. Run `supabase/schema.sql` in the SQL editor.
3. Add `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` from `.env.example`.
4. Enable Supabase Auth anonymous sign-ins for Raspberry Pi display claiming.
5. Enable Google in Supabase Auth providers:
   - In Google Cloud, add your app origin to Authorized JavaScript origins.
   - In Google Cloud, add the Supabase callback URL to Authorized redirect URIs:
     `https://<project-ref>.supabase.co/auth/v1/callback`.
   - In Supabase, add the Google OAuth Client ID and Client Secret under Authentication > Sign In / Providers > Google.
   - In Supabase, add your local and production app URLs under Authentication > URL Configuration.
6. Keep email magic links enabled for passwordless sign-ins.
7. Disable password sign-ins and Apple OAuth in Supabase Auth.
8. Insert your own Google- or magic-link-authenticated user into `app_admin` using the SQL editor or service role.
9. Seed `couple`, `partner`, `dashboard_widget`, and `couple_alert`.
10. Store tokens only as hashes:
   - `display_token_hash = extensions.crypt('plain-display-token', extensions.gen_salt('bf'))`
   - `invite_token_hash = extensions.crypt('plain-invite-token', extensions.gen_salt('bf'))`

The frontend routes are private by design:
- `/display/:slug` signs in anonymously, then calls `claim_display_device`.
- `/invite/:slug/:partnerSlug?token=...` signs in with Google or magic link, then links that Supabase Auth user to a `partner`.
- `/edit/:slug` requires a linked partner session.
- `/admin` calls `is_app_admin()`.

Without Supabase env vars the app keeps local demo mode for UI development only. Do not use local mode for a real private dashboard.
