# Brainy Bengali Guide - Socratic AI Tutor

A bilingual (English & Bangla) Socratic AI tutor for math and science, designed to facilitate learning without revealing answers directly. The tutor asks focused, mastery-calibrated questions, defends against prompt injection, and dynamically tracks per-skill mastery using Bayesian Knowledge Tracing. 

Additionally, the project features live, interactive **p5.js visual explanations** generated securely on the fly.

> **Architecture Overview**: The project is decoupled into a static **frontend** (Vercel) and a self-hosted **Node.js backend** (Render). It is backed by **your own Supabase project** for database, storage, and authentication. The backend calls the Gemini API directly via the Google Gen AI SDK.

---

## 🏗 Architecture

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
│  p5.js + shadcn/ui          │    │  POST /api/tutor    (SSE)    │
│                             │───▶│  POST /api/simulator         │
│  Authorization: Bearer JWT  │    │  GET  /health                │
└─────────────────────────────┘    │  Verifies Supabase JWT       │
                                   │  Calls Gemini API directly   │
                                   └──────────────────────────────┘
```

- **Authentication Flow**: The browser authenticates via Supabase (`signInWithPassword` or OAuth) and receives a JWT. The JWT is sent via `Authorization: Bearer <JWT>` to the backend. The backend strictly verifies the JWT on each request.
- **Guest Mode**: Supports guest sessions via `POST /api/tutor` with `{ guest: true }`. Guest state is fully stateless on the server side.
- **Security**: The `GEMINI_API_KEY` stays exclusively on the backend, ensuring it never reaches the browser. Visualizations powered by `p5.js` are tightly sandboxed within isolated iframe components to prevent XSS.

---

## 📂 Repository Structure

```
.
├── frontend/              ← React 18, Vite 5 SPA (Vercel Deploy Root)
├── backend/               ← Express + TS server (Render Deploy Root)
└── supabase-export/       ← SQL schema, seed data, and storage setup for Supabase
```

---

## 🛠 Tech Stack

| Layer        | Choice |
|--------------|--------|
| **Frontend** | React 18, Vite 5, TypeScript, Tailwind v3, shadcn/ui, react-router 6, `@supabase/supabase-js`, p5.js, KaTeX + react-markdown |
| **Backend**  | Node 20, Express 4, TypeScript, Zod, `@supabase/supabase-js`, Google Gen AI SDK |
| **Database** | Supabase Postgres + Row-Level Security (RLS) + Storage |
| **AI**       | Google Gemini Models (Direct API via `@google/genai`) |
| **Deploy**   | Vercel (frontend) + Render (backend) |

---

## 🚀 Local Development setup

### 1. Database (Supabase)
Create a Supabase project at [supabase.com](https://supabase.com/dashboard). In the SQL editor, run the following scripts in order:
1. `supabase-export/schema.sql`
2. `supabase-export/seed.sql`
3. `supabase-export/storage.sql`

*(See `supabase-export/README.md` for more details)*

### 2. Backend
```bash
cd backend
# Create a .env file and fill in:
# SUPABASE_URL=...
# SUPABASE_ANON_KEY=...
# SUPABASE_SERVICE_ROLE_KEY=...
# GEMINI_API_KEY=...
# ALLOWED_ORIGINS=http://localhost:5173
# PORT=8787

npm install
npm run dev                # Starts server on http://localhost:8787
```

### 3. Frontend (In a new terminal)
```bash
cd frontend
# Create a .env file and fill in:
# VITE_SUPABASE_URL=...
# VITE_SUPABASE_PUBLISHABLE_KEY=...
# VITE_API_URL=http://localhost:8787

npm install
npm run dev                # Starts UI on http://localhost:5173
```

---

## 🌩 Deployment

### Frontend (Vercel)
1. Add a new project on Vercel and import the repository.
2. Set **Root Directory** to `frontend`.
3. Vercel auto-detects **Vite**. Output directory is `dist`.
4. Configure environment variables (`VITE_SUPABASE_URL`, `VITE_SUPABASE_PUBLISHABLE_KEY`, `VITE_API_URL`).
5. Ensure the resulting Vercel domain is added to your Supabase Auth **Redirect URLs**, as well as the Backend's `ALLOWED_ORIGINS`.

### Backend (Render)
A `render.yaml` blueprint is provided in `backend/`.
1. Go to Render Dashboard -> **New** -> **Blueprint**.
2. Connect your repository. Render will automatically detect the Web Service.
3. Fill in the required environment variables (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `GEMINI_API_KEY`, `ALLOWED_ORIGINS`).

*(A `Dockerfile` is also provided for containerized deployments.)*

---

## 💡 Core Features

### Socratic Planning & Evaluation
The application utilizes an intelligent "Planner" process. The backend safely passes contextual scratchpad memory to the LLM to form a plan of action before responding, maintaining a high-fidelity learning experience.

### Secure Visualizations (p5.js)
The tutor can generate graphical explanations dynamically. The `frontend` securely processes generated p5.js code through strict initialization and run-loop sandboxing shims ensuring malicious or broken LLM-generated code will not crash the browser application.

### Efficiency-to-Mastery Simulator
`POST /api/simulator` serves as an integration to run quality audits. A Gemini judge evaluates a Socratic transcript segment and issues performance scores such as `socratic_adherence` and `frustration_handled`.

---

## ⚠️ Caveats & Notes
- After configuring a new Supabase project, you may need to regenerate the TypeScript types using the Supabase CLI to reflect your precise schema:
  ```bash
  npx supabase gen types typescript --project-id <your-project-ref> > frontend/src/integrations/supabase/types.ts
  ```
- Make sure to restart the `frontend` server if changing environment variables.
