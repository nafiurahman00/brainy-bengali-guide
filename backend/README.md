# Backend — Socratic AI Tutor (Express + TypeScript)

Self-hosted Node.js backend that replaces the previous Lovable Cloud edge
functions. Verifies Supabase JWTs, calls the Lovable AI Gateway (Gemini
for planning + streaming), and persists messages / scratchpad / knowledge
state in Supabase. Mastery is assessed **every turn** from the planner's own
correctness verdict (single source of truth: `lib/mastery.ts`), and the tutor
relaxes from Socratic questions up to a full solution via an Adaptive Help
Ladder. Works identically in Bangla and English.

## Endpoints

| Method | Path                   | Auth                | Returns                               |
|--------|------------------------|---------------------|---------------------------------------|
| GET    | `/health`              | —                   | `{ ok: true }`                         |
| POST   | `/api/tutor`           | Optional Bearer JWT | `text/event-stream` (SSE)              |
| POST   | `/api/feedback`        | Bearer JWT required | JSON `{ ok, knowledge_update }` — records the "Got it / Confused" tap as a secondary, downweighted signal |
| POST   | `/api/visualize`       | Bearer JWT required | JSON `{ ok, viz }` — context-aware p5.js sketch, cached per focus in `sessions.visualization` |
| POST   | `/api/visualize/repair`| Bearer JWT required | JSON `{ ok, p5_code }`                  |
| POST   | `/api/simulator`       | Bearer JWT required | JSON `{ result: { ... } }`             |

`POST /api/tutor` works in two modes:

- **Authenticated**: include `Authorization: Bearer <supabase-jwt>` and
  `{ sessionId }`. Server loads the session, persists the user + assistant
  message, and updates the scratchpad / knowledge state.
- **Guest**: send `{ guest: true }` with no Authorization header. Pass
  `subjectSlug`, `scratchpad`, and `fluency` in the body — server is
  stateless and writes nothing.

The SSE stream is:

```
data: { "meta": {
  "sub_skill_id": "...", "sub_skill_slug": "...", "difficulty": "...",
  "diagnosed_error": "...", "subgoal": "...", "student_step_correct": true,
  "affective_state": "neutral", "support_level": "socratic",
  "response_type": "attempt", "mastery_after": 0.42,
  "knowledge_update": { "sub_skill_slug": "...", "mastery": 0.42, "attempts": 3, ... }
} }

data: { "choices": [ { "delta": { "content": "..." } } ] }
data: { "choices": [ { "delta": { "content": "..." } } ] }
...
data: [DONE]
```

`support_level` is the Help Ladder rung the tutor used this turn (`socratic` →
`hint` → `scaffold` → `direct` → `full_solution`). `knowledge_update` is the new
per-skill state after the server's per-turn assessment — guests apply it
client-side (they persist nothing).

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
- **`routes/tutor.ts`** runs the two-stage pipeline: a planner (structured
  tool call) that verifies correctness, reads affect, and rates evidence; then
  a streamed Socratic generator. Between the two it runs the **per-turn
  assessment** (updates `knowledge_state` + logs a `knowledge_events` row) and
  decides the **Help Ladder** support level. Streams Gemini chunks unchanged;
  prefixes a single `meta` event.
- **`lib/mastery.ts`** is the single source of truth for the learning model:
  evidence-weighted BKT (`applyEvidence`), forgetting (`applyDecay`), the
  support-level ladder (`decideSupportLevel`), and the learner profile. It is
  pure and unit-tested (`npm test`); both `/api/tutor` and `/api/feedback` go
  through it so the math is never duplicated.
- **`routes/feedback.ts`** records the manual "Got it / Confused" tap as a
  secondary, downweighted evidence event and nudges the affective profile.
- **`routes/visualize.ts`** builds p5.js sketches tied to the planner's current
  concept / diagnosed gap / actual numbers, cached per focus inside the
  `sessions.visualization` JSONB so they evolve as the conversation moves. All
  on-canvas labels are localized.
- **`routes/simulator.ts`** is a 1:1 port of `student-simulator`.
- **CORS** is driven by `ALLOWED_ORIGINS` (comma-separated). Empty value
  means "any origin allowed" — only use that for local debugging.
- **Image inputs**: the tutor route accepts `imageUrl` either as a
  Supabase signed URL (auth mode) or a base64 `data:` URL (guest mode).
  The default `express.json` body limit is bumped to 10 MB to fit guest
  base64 uploads.
