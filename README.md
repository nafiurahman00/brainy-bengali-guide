# Socratic AI Tutor

A bilingual (English / Bangla) Socratic tutor for math and science. The
tutor never reveals answers — it asks one focused, mastery-calibrated
question per turn, defends against prompt injection, and tracks per-skill
mastery using Bayesian Knowledge Tracing.

> **v2 architecture** — decoupled into a static **frontend** (Vercel) and
> a self-hosted **Node.js backend** (Render), backed by **your own**
> Supabase project. The backend calls Gemini 2.5 Pro / Flash through the
> Lovable AI Gateway.

---

## Architecture

```text
                ┌──────────────────────────────────┐
                │  YOUR Supabase project           │
                │  Auth · Postgres · Storage       │
                └──────────────────────────────────┘
                    ▲                          ▲
        anon JWT    │                          │  service_role
   (auth, table     │                          │  (writes from
    reads, signed   │                          │   server)
    URLs, storage)  │                          │
                    │                          │
┌───────────────────┴─────────┐    ┌───────────┴──────────────────┐
│  frontend/  (Vercel)        │    │  backend/  (Render)          │
│  React + Vite + Tailwind    │    │  Express + TypeScript        │
│  supabase-js                │    │  POST /api/tutor    (SSE)    │
│                             │───▶│  POST /api/simulator         │
│  Authorization: Bearer JWT  │    │  GET  /health                │
└─────────────────────────────┘    │  Verifies Supabase JWT       │
                                   │  Calls Lovable AI Gateway    │
                                   │   (Gemini 2.5 Pro / Flash)   │
                                   └──────────────────────────────┘
```

- **Auth flow** — The browser logs in with `supabase.auth` and gets a
  JWT. The JWT is sent as `Authorization: Bearer …` on every backend
  call. The backend verifies it with `supabase.auth.getUser(jwt)` and
  attaches `req.user.id`.
- **Guest mode** — `POST /api/tutor` accepts `{ guest: true }` with no
  JWT. The client passes `scratchpad` + `fluency` in the body; the
  server is stateless and writes nothing to the database.
- **AI calls** stay on the backend so the `LOVABLE_API_KEY` never
  reaches the browser.

---

## Repo layout

```
.
├── README.md              ← this file
├── frontend/              ← Vercel deploy root (React + Vite SPA)
├── backend/               ← Render deploy root (Express + TS server)
└── supabase-export/       ← SQL to recreate the database in your own Supabase
```

`supabase/` (the original Lovable Cloud edge functions and migrations) is
kept as historical reference. The new source of truth is
`supabase-export/`.

---

## Tech stack

| Layer        | Choice |
|--------------|--------|
| Frontend     | React 18, Vite 5, TypeScript 5, Tailwind v3, shadcn/ui, react-router 6, `@supabase/supabase-js`, KaTeX + react-markdown |
| Backend      | Node 20, Express 4, TypeScript 5, Zod, `@supabase/supabase-js` (service role + anon JWT verify) |
| Database     | Supabase Postgres + Row-Level Security + Storage |
| AI           | Gemini 2.5 Pro (planner, tool-call) + Gemini 2.5 Flash (streaming response), via Lovable AI Gateway |
| Deploy       | Vercel (frontend) + Render (backend) |

---

## Local dev — quickstart

```bash
# 1. Database — create a Supabase project (https://supabase.com/dashboard),
#    then in its SQL editor run:
#      supabase-export/schema.sql
#      supabase-export/seed.sql
#      supabase-export/storage.sql
#    (See supabase-export/README.md for screenshots-style instructions.)

# 2. Backend
cd backend
cp .env.example .env       # fill SUPABASE_*, LOVABLE_API_KEY, ALLOWED_ORIGINS
npm install
npm run dev                # → http://localhost:8787

# 3. Frontend (in a second terminal)
cd frontend
cp .env.example .env       # fill VITE_SUPABASE_*, VITE_API_URL=http://localhost:8787
npm install
npm run dev                # → http://localhost:5173
```

Smoke test the backend:

```bash
curl http://localhost:8787/health
# → {"ok":true,"service":"socratic-tutor-backend"}
```

---

## Deploy — Frontend → Vercel

1. <https://vercel.com> → **Add New → Project** → import the repo.
2. **Root Directory:** `frontend`
3. **Framework preset:** Vite (auto-detected). Build `npm run build`,
   output `dist`.
4. **Environment variables:**

   | Name                            | Value                                          |
   |---------------------------------|------------------------------------------------|
   | `VITE_SUPABASE_URL`             | `https://<your-ref>.supabase.co`               |
   | `VITE_SUPABASE_PUBLISHABLE_KEY` | your Supabase **anon** key                     |
   | `VITE_API_URL`                  | `https://<your-backend>.onrender.com`          |

5. Deploy. The included `frontend/vercel.json` rewrites all paths to
   `index.html` so React Router deep links survive a refresh.
6. After deploy, add the Vercel domain to:
   - The backend's `ALLOWED_ORIGINS`
   - Supabase **Auth → URL Configuration → Redirect URLs**

## Deploy — Backend → Render

Easiest path uses the included `backend/render.yaml` blueprint:

1. <https://dashboard.render.com> → **New → Blueprint** → connect repo.
2. Render reads `backend/render.yaml` and creates a Web Service. Fill in
   the five secrets when prompted.

Or set up manually:

| Setting                | Value                            |
|------------------------|----------------------------------|
| Type                   | Web Service                      |
| Environment            | Node                             |
| Root Directory         | `backend`                        |
| Build Command          | `npm install && npm run build`   |
| Start Command          | `npm start`                      |
| Health Check Path      | `/health`                        |
| Environment variables  | `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `LOVABLE_API_KEY`, `ALLOWED_ORIGINS=https://<your-vercel-domain>` |

A Dockerfile is also provided for container-based deploys.

---

## Auth flow in detail

```text
browser                 supabase.co                 backend
  │                         │                         │
  │  signInWithPassword ───▶│                         │
  │◀───────  JWT  ──────────│                         │
  │                         │                         │
  │  POST /api/tutor                                  │
  │   Authorization: Bearer <JWT> ───────────────────▶│
  │                         │                         │
  │                         │◀──── auth.getUser(jwt) ─│
  │                         │────────  user  ────────▶│
  │                         │                         │
  │◀────  text/event-stream  ────────────────────────│
```

- The JWT is issued by Supabase Auth (email/password, optionally Google).
- The backend never stores the JWT — it only verifies it on each request.
- For DB writes, the backend uses the **service-role** key (which
  bypasses RLS) and always scopes writes to `req.user.id` manually.

---

## Caveats

- **Lovable preview will not run the Node server.** Use the deployed
  Render backend, or run `backend/` locally and point `VITE_API_URL` at
  `http://localhost:8787`.
- `frontend/src/integrations/supabase/client.ts` and `types.ts` were
  originally Lovable Cloud auto-generated. After switching to your own
  Supabase, regenerate the types:

  ```bash
  npx supabase gen types typescript \
    --project-id <your-project-ref> \
    > frontend/src/integrations/supabase/types.ts
  ```
- The `LOVABLE_API_KEY` works from any Node host — no Lovable Cloud
  dependency at runtime.
- Existing Lovable Cloud Supabase data is **not** auto-migrated. If you
  want to preserve rows, use `pg_dump --data-only` (see
  `supabase-export/README.md`).

---

## Folder reference

| Path                       | Purpose                                                  |
|----------------------------|----------------------------------------------------------|
| `frontend/src/pages/`      | Auth, Dashboard, SessionPage, GuestSession, Knowledge    |
| `frontend/src/hooks/use-chat.ts` | Calls `${VITE_API_URL}/api/tutor` (SSE)            |
| `frontend/src/integrations/supabase/` | Auto-generated client + types               |
| `backend/src/routes/tutor.ts`     | Sanitize+Plan (Pro) → SSE stream (Flash)          |
| `backend/src/routes/simulator.ts` | EtM scoring (port of student-simulator)            |
| `backend/src/middleware/auth.ts`  | `requireUser` / `optionalUser` JWT verify          |
| `supabase-export/schema.sql`      | Tables, RLS, triggers, `handle_new_user`           |
| `supabase-export/seed.sql`        | Subjects → concepts → sub_skills (EN + BN)          |
| `supabase-export/storage.sql`     | `problem-images` bucket + per-user RLS              |
