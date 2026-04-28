# Backend — Socratic AI Tutor (Express + TypeScript)

Self-hosted Node.js backend that replaces the previous Lovable Cloud edge
functions. Verifies Supabase JWTs, calls the Lovable AI Gateway (Gemini
2.5 Pro for planning, 2.5 Flash for streaming), and persists messages /
scratchpad / knowledge state in Supabase.

## Endpoints

| Method | Path             | Auth                | Returns                               |
|--------|------------------|---------------------|---------------------------------------|
| GET    | `/health`        | —                   | `{ ok: true }`                         |
| POST   | `/api/tutor`     | Optional Bearer JWT | `text/event-stream` (SSE)              |
| POST   | `/api/simulator` | Bearer JWT required | JSON `{ result: { ... } }`             |

`POST /api/tutor` works in two modes:

- **Authenticated**: include `Authorization: Bearer <supabase-jwt>` and
  `{ sessionId }`. Server loads the session, persists the user + assistant
  message, and updates the scratchpad / knowledge state.
- **Guest**: send `{ guest: true }` with no Authorization header. Pass
  `subjectSlug`, `scratchpad`, and `fluency` in the body — server is
  stateless and writes nothing.

The SSE stream is:

```
data: { "meta": { "sub_skill_id": "...", "subgoal": "...", ... } }

data: { "choices": [ { "delta": { "content": "..." } } ] }
data: { "choices": [ { "delta": { "content": "..." } } ] }
...
data: [DONE]
```

## Local development

```bash
# 1. Install
npm install

# 2. Configure secrets
cp .env.example .env
# then fill in:
#   SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY
#   LOVABLE_API_KEY
#   ALLOWED_ORIGINS=http://localhost:5173

# 3. Run
npm run dev          # tsx watch on :8787
```

Health check:

```bash
curl http://localhost:8787/health
# {"ok":true,"service":"socratic-tutor-backend"}
```

Tutor smoke test (guest mode):

```bash
curl -N -X POST http://localhost:8787/api/tutor \
  -H "Content-Type: application/json" \
  -d '{"guest":true,"message":"Solve x+5=12","language":"en","subjectSlug":"math"}'
```

## Production build

```bash
npm run build        # → dist/
npm start            # → node dist/index.js
```

## Deploy: Render

The included `render.yaml` is a Render Blueprint. Easiest path:

1. Push this repo to GitHub.
2. <https://dashboard.render.com> → **New → Blueprint** → connect repo.
3. Render reads `backend/render.yaml` and creates a Web Service. Set the
   five secrets in the dashboard (`SUPABASE_URL`, `SUPABASE_ANON_KEY`,
   `SUPABASE_SERVICE_ROLE_KEY`, `LOVABLE_API_KEY`, `ALLOWED_ORIGINS`).
4. Set **Root Directory** to `backend` if Render didn't auto-detect.
5. Deploy. Once green, copy the `https://<your-service>.onrender.com`
   URL into the **frontend's** `VITE_API_URL`.

Manual setup (without Blueprint):

| Setting          | Value                              |
|------------------|------------------------------------|
| Environment      | Node                               |
| Root Directory   | `backend`                          |
| Build Command    | `npm install && npm run build`     |
| Start Command    | `npm start`                        |
| Health Check     | `/health`                          |
| Node version     | 20+                                |

## Deploy: Docker

```bash
docker build -t socratic-tutor-backend .
docker run -p 8787:8787 --env-file .env socratic-tutor-backend
```

## Architecture notes

- **`lib/supabase.ts`** exposes `serviceClient()` (service-role,
  bypasses RLS — used for all DB writes after manual `user_id` scoping)
  and `anonClient()` (used to verify JWTs via
  `supabase.auth.getUser(jwt)`).
- **`middleware/auth.ts`** provides `requireUser` and `optionalUser`.
- **`routes/tutor.ts`** is a 1:1 port of the previous `tutor-agent`
  Deno function. Streams Gemini chunks unchanged; prefixes a single
  `meta` event so the client can render the planner's output.
- **`routes/simulator.ts`** is a 1:1 port of `student-simulator`.
- **CORS** is driven by `ALLOWED_ORIGINS` (comma-separated). Empty value
  means "any origin allowed" — only use that for local debugging.
- **Image inputs**: the tutor route accepts `imageUrl` either as a
  Supabase signed URL (auth mode) or a base64 `data:` URL (guest mode).
  The default `express.json` body limit is bumped to 10 MB to fit guest
  base64 uploads.
