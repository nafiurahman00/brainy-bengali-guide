# How the Socratic AI Tutor Works — Feature & Architecture Guide

This document explains, in detail, what the application does and how each piece
fits together. For setup/deploy, see [README.md](README.md) (root) and
[backend/README.md](backend/README.md).

---

## 1. What the app is

A bilingual (English / বাংলা) AI tutor for math and science. A student types a
problem (or uploads a photo of one), and the tutor helps them **solve it
themselves** — Socratic by default, but it adapts how much it helps to how the
student is actually doing. While the student works, the system continuously
estimates how much they've learned per skill and uses that to calibrate
difficulty, tone, pacing, and a live interactive visualization.

Two ways to use it:

| Mode | Auth | Persistence |
|------|------|-------------|
| **Signed-in** | Supabase email/password (optional Google) | Sessions, messages, mastery, learner profile, and event log all saved |
| **Guest** | none | Stateless — progress lives only in the browser tab; the server writes nothing |

Everything below works identically in both languages and (where noted) in both
modes.

---

## 2. The student experience (feature tour)

### 2.1 A tutor that adapts how much it helps — the Adaptive Help Ladder
The tutor is **not** a rigid "I'll never tell you the answer" gatekeeper. Each
turn it picks one of five **support levels** based on how stuck the student is:

| Level | Name | What the tutor does |
|------:|------|---------------------|
| 1 | `socratic` | One guiding question. Leads the student to the next step. |
| 2 | `hint` | A concrete pointer toward the next idea, then a question. |
| 3 | `scaffold` | Works one sub-step or a small analogous example, then asks the student to continue. |
| 4 | `direct` | Walks the method explicitly, leaving the final answer for the student to finish. |
| 5 | `full_solution` | Gives the complete worked solution (it's OK!), then a quick check-for-understanding question. |

It **escalates** (gives more help) when the student is stuck on the same problem
repeatedly, seems frustrated/anxious/disengaged, or explicitly asks ("just tell
me", "show me how", "I give up"). It **de-escalates** back toward questions once
the student is making progress, and stays at level 1–2 when they're doing well
so the work stays challenging. This is the core comfort feature: a struggling
student is never stonewalled.

### 2.2 A tutor that reads the room (affective tailoring)
Every turn the planner infers the student's mood (`frustrated`, `anxious`,
`confident`, `neutral`, `confused`, `disengaged`). When the student seems
frustrated, the tutor opens with a brief, genuine sentence that validates their
effort and lowers the pressure before diving in. When they're confident, it
stays crisp and stretches them a little. Tone is always warm and never shames a
wrong answer.

### 2.3 Remembers you across sessions (continuity)
A persistent **learner profile** (mood trend, pace, how much encouragement helps)
follows the student between sessions. When a returning student starts a fresh
session, the tutor opens with a short "welcome back — last time we worked on …"
recap that references their weakest recent skills and invites them to continue.

### 2.4 Live, relevant visualizations
Alongside the chat, an interactive **p5.js sketch** builds intuition for the
exact concept the student is on. It uses the **actual numbers** from their
problem, targets the specific misconception the tutor diagnosed, and is
genuinely interactive (sliders/drag, animation, a "predict then reveal" beat).
As the conversation moves to a new skill, a fresh, relevant sketch is generated;
revisiting a skill reuses the cached one instantly. Students can ask for
"another angle" or a "simpler" version.

### 2.5 A knowledge map that updates itself
The **Knowledge** page shows per-skill mastery, concept-level rollups
(average % and how many skills are mastered), a "needs review" badge on skills
gone stale, a confidence indicator, and a recent-activity strip. Crucially, it
updates **automatically as the student works** — not only when they tap a
button. The **Dashboard** greets returning students and recommends the weakest
concept to practice next.

### 2.6 Feedback buttons (secondary)
"Got it / Still confused / More help" buttons remain, but they're now a
**secondary** signal that gently nudges mastery and the mood model — the primary
signal is the AI's own per-turn assessment (below).

### 2.7 Safety
- **Prompt-injection defense:** the planner flags jailbreak attempts ("ignore
  previous rules", "you are now…"); flagged user messages get a warning badge and
  the tutor ignores the injected instructions.
- **Sandboxed visualizations:** generated p5.js runs in a locked-down `sandbox`
  iframe with no network/escape APIs, a static-analysis sanitizer, a hidden
  pre-flight that catches runtime crashes, and one automatic AI repair pass.

---

## 3. The AI pipeline (what happens on every turn)

`POST /api/tutor` ([backend/src/routes/tutor.ts](backend/src/routes/tutor.ts))
runs a **two-stage** pipeline with a learning-model update in between:

```
 Student message (+ optional image)
        │
        ▼
 ┌─────────────────────────────────────────────────────────────┐
 │ STAGE 1 — Pedagogical Architect (planner)                    │
 │ Gemini structured tool-call. Reads full history, fluency     │
 │ vector, learner profile, scratchpad. Produces:               │
 │  • cleaned_problem, injection_detected                       │
 │  • sub_skill_slug (which skill this is)                      │
 │  • student_step_correct  (ground-truth verdict)             │
 │  • diagnosed_error, correct_next_step_hint                   │
 │  • response_type, evidence_strength, assessment_confidence  │
 │  • affective_state, student_requests_answer                 │
 │  • difficulty, recommend_support_level, pedagogical_subgoal │
 └─────────────────────────────────────────────────────────────┘
        │
        ▼
 ┌─────────────────────────────────────────────────────────────┐
 │ PER-TURN ASSESSMENT  (lib/mastery.ts — pure, unit-tested)    │
 │  • decay prior mastery for idle time                        │
 │  • decide support_level (the Help Ladder)                   │
 │  • if a real attempt & we didn't hand over the answer:      │
 │       evidence-weighted BKT update → knowledge_state        │
 │       + append a knowledge_events row                       │
 │  • roll the learner profile forward (affect/pace)           │
 └─────────────────────────────────────────────────────────────┘
        │
        ▼
 ┌─────────────────────────────────────────────────────────────┐
 │ STAGE 2 — Socratic generator (streamed)                      │
 │ Gemini streaming. System prompt is built from the plan +    │
 │ support_level + tone + recap. Streams the reply as SSE.     │
 └─────────────────────────────────────────────────────────────┘
        │
        ▼
 SSE: one `meta` event (skill, difficulty, affect, support_level,
      mastery_after, knowledge_update, …) then token chunks, then [DONE]
```

**Models:** the planner uses `gemini-3-flash-preview` for text or
`gemini-2.5-pro` when an image is attached (vision); the generator streams with
`gemini-3-flash-preview`; visualizations use `gemini-2.5-pro`. Configured in
[backend/src/lib/ai.ts](backend/src/lib/ai.ts).

**Key property:** the planner already computes a ground-truth correctness verdict
every turn, so the per-turn assessment costs **no extra LLM call**.

---

## 4. The learning model in detail

All math lives in one pure, unit-tested module:
[backend/src/lib/mastery.ts](backend/src/lib/mastery.ts). Both `/api/tutor` and
`/api/feedback` go through it, so the logic is never duplicated.

### 4.1 Bayesian Knowledge Tracing (BKT), evidence-weighted
Mastery is a probability in `[0,1]` (starts at `0.3`). After a real attempt it's
updated with a BKT posterior (`pLearn=0.1`, `pGuess=0.2`, `pSlip=0.1`), but the
**influence is scaled by how strong the evidence is**:

`weight = evidenceStrength × assessmentConfidence`

- `evidence_strength` ∈ `none | weak | moderate | strong` — a fully-worked
  solution moves mastery far more than a one-word "yes".
- `assessment_confidence` (0–1) — the planner's confidence in its own verdict,
  lowered for ambiguous or OCR'd work, so hallucinated certainty matters less.
- A weight of 0 (a clarifying question, chit-chat, or a turn where the tutor gave
  the answer) leaves mastery untouched — it can't be gamed.

### 4.2 Forgetting / decay
Idle skills decay gently toward a floor (`applyDecay`, ~14-day half-life, floor
0.2). The AI uses the **decayed** value internally for difficulty and
recommendations; the UI keeps the displayed % steady and shows a "needs review"
badge instead, so students aren't demoralized by dropping numbers.

### 4.3 Confidence & streak
Each row also tracks a `confidence` score (how much evidence we've accumulated)
and a correct-answer `streak`, both surfaced in the UI.

### 4.4 What counts as evidence vs. not
`response_type` gates assessment: only `attempt` and `answer` are graded. A
`question`, `clarification`, `chitchat`, `off_topic`, or `new_problem` turn never
moves mastery — so asking for help is never penalized. And when `support_level ≥ 4`
(the tutor largely handed over the answer), evidence is forced to `none`.

### 4.5 The event log
Every assessment writes a row to `knowledge_events` (append-only): before/after
mastery, correctness, evidence strength, support level, affect, difficulty, and a
canonical error tag. This powers the recent-activity view, longitudinal progress,
and future parameter tuning.

### 4.6 Guest mode parity
Guests have no database, so the server **computes** the same update and returns it
in the SSE `meta.knowledge_update`; the browser stores it locally and sends it
back next turn. The algorithm still lives server-side — guests just don't persist.

---

## 5. Visualizations in detail

`POST /api/visualize` ([backend/src/routes/visualize.ts](backend/src/routes/visualize.ts)):

- **Context-aware:** receives the planner's `concept`, `subSkill`,
  `diagnosedError`, `difficulty`, `subgoal`, and the cleaned problem, and is told
  to parameterize the sketch with the student's **actual numbers** and target the
  specific misconception (without printing the final numeric answer as text).
- **Engaging:** must include an animation or a manipulable control that visibly
  changes the concept, a "what to notice" label, and where natural a
  predict-then-reveal interaction. Richness scales with difficulty.
- **Evolves across the conversation:** sketches are cached **per focus** inside
  the existing `sessions.visualization` JSONB as `{ active, items }`. A new
  skill/concept generates a fresh sketch; revisiting one is instant. The legacy
  single-sketch shape is still read (back-compatible).
- **Lenses:** "another angle" (different representation) and "simpler" re-prompt
  for a fresh take.
- **Localized:** title, explanation, hint, and on-canvas labels render in the
  student's language.
- **Self-healing:** `POST /api/visualize/repair` fixes a crashed sketch with the
  smallest possible change; the fix is written back to the active item.

Front-end safety/render plumbing:
[use-p5-preflight.ts](frontend/src/hooks/use-p5-preflight.ts),
[p5-sanitize.ts](frontend/src/lib/p5-sanitize.ts),
[VisualizationPanel.tsx](frontend/src/components/VisualizationPanel.tsx).

---

## 6. Data model

Base tables in [supabase-export/dump.sql](supabase-export/dump.sql); the
learning-model additions in
[supabase-export/02_learning_model.sql](supabase-export/02_learning_model.sql).

| Table / view | Purpose |
|--------------|---------|
| `subjects` → `concepts` → `sub_skills` | The curriculum tree (bilingual names) |
| `profiles` | Student profile + `learner_state` JSONB (mood, pace, encouragement) |
| `sessions` | One study session: `scratchpad` (goal, struggle count, support level, affect) + `visualization` (keyed sketch store) |
| `messages` | Full chat history + `feedback` + injection flag, per-message skill tag |
| `knowledge_state` | **One row per (user, skill):** `mastery`, `attempts`, `correct`, `streak`, `confidence`, `error_tags`, `last_practiced_at` |
| `knowledge_events` | **Append-only** evidence log (every assessment) |
| `sub_skill_prerequisites` | Optional skill-dependency graph (schema ready; data authored later) |
| `concept_mastery` (view) | Per-user, per-concept rollup (avg mastery, # mastered) — `security_invoker` so RLS applies |

Row-Level Security: curriculum tables are world-readable; all user data is
restricted to `auth.uid() = user_id`. The backend uses the service-role key and
scopes every write to the authenticated user manually.

---

## 7. API surface

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | `/health` | — | Liveness |
| POST | `/api/tutor` | optional | Plan + per-turn assessment + Help Ladder → SSE stream |
| POST | `/api/feedback` | required | Record "Got it / Confused" tap (secondary signal) |
| POST | `/api/visualize` | required | Context-aware p5.js sketch (cached per focus) |
| POST | `/api/visualize/repair` | required | Fix a crashed sketch |
| POST | `/api/simulator` | required | Teaching-quality audit (role-play; UI button currently off) |

### The SSE `meta` event
```jsonc
{ "meta": {
  "sub_skill_id": "…", "sub_skill_slug": "…", "difficulty": "guided",
  "diagnosed_error": "…", "subgoal": "…", "student_step_correct": true,
  "affective_state": "neutral", "support_level": "hint",
  "response_type": "attempt", "mastery_after": 0.46,
  "knowledge_update": { "sub_skill_slug": "…", "mastery": 0.46, "attempts": 3, … }
}}
```

---

## 8. File map (where each feature lives)

**Backend**
- [routes/tutor.ts](backend/src/routes/tutor.ts) — the two-stage pipeline, per-turn assessment, Help Ladder, continuity recap
- [lib/mastery.ts](backend/src/lib/mastery.ts) — BKT, decay, support-level, learner profile (single source of truth)
- [lib/mastery.test.ts](backend/src/lib/mastery.test.ts) — unit tests (`npm test`)
- [routes/feedback.ts](backend/src/routes/feedback.ts) — secondary feedback signal
- [routes/visualize.ts](backend/src/routes/visualize.ts) — context-aware sketches + repair
- [schemas.ts](backend/src/schemas.ts) — Zod request schemas
- [middleware/auth.ts](backend/src/middleware/auth.ts) — JWT verification

**Frontend**
- [hooks/use-chat.ts](frontend/src/hooks/use-chat.ts) — SSE client, consumes the rich `meta`, posts feedback
- [hooks/use-visualization.ts](frontend/src/hooks/use-visualization.ts) — focus-driven sketch generation + lenses
- [pages/SessionPage.tsx](frontend/src/pages/SessionPage.tsx) — signed-in chat + visualization + pipeline panel
- [pages/GuestSession.tsx](frontend/src/pages/GuestSession.tsx) — stateless guest chat (server-computed mastery)
- [pages/Knowledge.tsx](frontend/src/pages/Knowledge.tsx) — knowledge map, concept rollups, review badges, recent activity
- [pages/Dashboard.tsx](frontend/src/pages/Dashboard.tsx) — sessions + welcome-back / recommended-next
- [components/VisualizationPanel.tsx](frontend/src/components/VisualizationPanel.tsx) — sandboxed iframe render + lens controls
- [lib/i18n.ts](frontend/src/lib/i18n.ts) — English / বাংলা UI strings

---

## 9. Tuning knobs

Most behavior is adjustable in one place — the constants at the top of
[lib/mastery.ts](backend/src/lib/mastery.ts):

| Knob | Effect |
|------|--------|
| `INITIAL_MASTERY` (0.3) | Starting belief for an untouched skill |
| `P_LEARN / P_GUESS / P_SLIP` | BKT dynamics |
| `EVIDENCE_WEIGHT` map | How much weak vs. strong evidence moves mastery |
| `DECAY_HALF_LIFE_DAYS` (14), `DECAY_FLOOR` (0.2) | How fast skills go stale |
| `decideSupportLevel(...)` thresholds | When the Help Ladder escalates/relaxes |
| Difficulty bands (`<0.4`, `0.4–0.7`, `>0.7`) in the planner prompt | scaffolding / guided / challenge |

The per-turn approach means these can later be fit from the `knowledge_events`
log rather than hand-tuned.
