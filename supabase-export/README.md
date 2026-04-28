# Supabase Export — Database setup for your own project

This folder recreates the full database that the Socratic AI Tutor needs in
**your own** Supabase project (independent of Lovable Cloud).

## What gets created

- **7 tables**: `profiles`, `subjects`, `concepts`, `sub_skills`,
  `sessions`, `messages`, `knowledge_state`
- **Row-Level Security** policies on every table (per-user ownership for
  user data; public read for taxonomy)
- **Functions / triggers**: `touch_updated_at`, `handle_new_user`
  (auto-creates a profile row on signup), and `on_auth_user_created`
  trigger on `auth.users`
- **Storage**: private `problem-images` bucket with per-user folder RLS
- **Seed data**: subjects → concepts → sub_skills taxonomy (Math, Physics,
  Chemistry, Biology in English + Bangla)

## Step-by-step

1. **Create a new Supabase project** at <https://supabase.com/dashboard>.
   Pick a region close to your Render backend deploy region for lowest
   latency.

2. **Open the SQL editor** (left sidebar) and run the files **in this
   order** — paste the contents of each, click **Run**:

   1. `schema.sql` — tables, RLS, triggers
   2. `seed.sql`   — taxonomy rows (re-runnable; uses `ON CONFLICT`)
   3. `storage.sql` — bucket + storage RLS

3. **Grab your keys** from **Project Settings → API**:

   | Key | Used by | Where it goes |
   |-----|---------|---------------|
   | Project URL | frontend + backend | `VITE_SUPABASE_URL` and `SUPABASE_URL` |
   | `anon` public key | frontend + backend (JWT verification) | `VITE_SUPABASE_PUBLISHABLE_KEY` and `SUPABASE_ANON_KEY` |
   | `service_role` secret key | **backend only** | `SUPABASE_SERVICE_ROLE_KEY` |

   ⚠ **Never** commit the service-role key or expose it to the browser.
   It bypasses RLS.

4. **Configure Auth** (Authentication → Providers):
   - Enable **Email** provider
   - For development, you may want to disable "Confirm email" so signups
     work without inbox verification
   - Add your frontend URL (Vercel domain + `http://localhost:5173`) to
     **URL Configuration → Redirect URLs**

5. **Paste the keys** into:
   - `frontend/.env` (`VITE_SUPABASE_URL`, `VITE_SUPABASE_PUBLISHABLE_KEY`)
   - `backend/.env`  (`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`,
     `SUPABASE_ANON_KEY`)

6. **(Optional) Regenerate frontend types** against your new project:

   ```bash
   npx supabase gen types typescript \
     --project-id <your-project-ref> \
     > frontend/src/integrations/supabase/types.ts
   ```

## Migrating existing data (optional)

If you have rows in your previous Lovable Cloud Supabase that you want to
keep:

```bash
# Dump from old project
pg_dump --data-only --no-owner --no-acl \
  --schema=public \
  -t profiles -t sessions -t messages -t knowledge_state \
  "postgres://postgres:<old-pwd>@<old-host>:5432/postgres" \
  > data.sql

# Restore into new project (run after schema.sql + seed.sql)
psql "postgres://postgres:<new-pwd>@<new-host>:5432/postgres" < data.sql
```

User accounts in `auth.users` cannot be moved by a simple SQL dump —
Supabase support has a migration tool, or users can re-sign-up.
