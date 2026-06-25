-- 02_learning_model.sql
-- Smarter learning model + analytics. Run this in the Supabase SQL editor on
-- top of the base schema (dump.sql). Idempotent — safe to re-run.
--
-- Adds: per-turn mastery confidence/streak, a persistent learner profile,
-- an append-only knowledge-event log, an (optional) prerequisite graph, and a
-- concept-level rollup view. The application updates mastery on EVERY tutor turn
-- (see backend/src/lib/mastery.ts), not just on manual feedback.

-- 1. knowledge_state: evidence-weighted confidence + streak
alter table public.knowledge_state
  add column if not exists confidence numeric not null default 0,
  add column if not exists streak integer not null default 0;

-- 2. profiles: persistent learner model (affect, pace, prefs)
alter table public.profiles
  add column if not exists learner_state jsonb not null default '{}'::jsonb;

-- 3. knowledge_events: append-only evidence / progress log
create table if not exists public.knowledge_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  session_id uuid references public.sessions(id) on delete set null,
  sub_skill_id uuid references public.sub_skills(id) on delete cascade,
  event_type text not null check (event_type in ('auto_assessment','feedback','manual_adjust','decay')),
  correct boolean,
  evidence_strength text check (evidence_strength in ('none','weak','moderate','strong')),
  planner_confidence numeric,
  support_level text,
  affective_state text,
  difficulty text,
  error_tag text,
  mastery_before numeric,
  mastery_after numeric,
  created_at timestamptz not null default now()
);
create index if not exists idx_kevents_user_time  on public.knowledge_events (user_id, created_at desc);
create index if not exists idx_kevents_user_skill on public.knowledge_events (user_id, sub_skill_id, created_at desc);

alter table public.knowledge_events enable row level security;
drop policy if exists "kevents select own" on public.knowledge_events;
create policy "kevents select own" on public.knowledge_events for select using (auth.uid() = user_id);
drop policy if exists "kevents insert own" on public.knowledge_events;
create policy "kevents insert own" on public.knowledge_events for insert with check (auth.uid() = user_id);
-- backend uses the service role (bypasses RLS); policies cover direct client access.

-- 4. prerequisite graph (optional Phase-2 data; schema ready now)
create table if not exists public.sub_skill_prerequisites (
  sub_skill_id   uuid not null references public.sub_skills(id) on delete cascade,
  prerequisite_id uuid not null references public.sub_skills(id) on delete cascade,
  strength numeric not null default 1.0,
  primary key (sub_skill_id, prerequisite_id)
);
alter table public.sub_skill_prerequisites enable row level security;
drop policy if exists "prereqs readable" on public.sub_skill_prerequisites;
create policy "prereqs readable" on public.sub_skill_prerequisites
  for select to authenticated, anon using (true);

-- 5. concept-level rollup (respects each user's RLS via security_invoker)
create or replace view public.concept_mastery
with (security_invoker = true) as
select
  ks.user_id,
  c.id as concept_id,
  c.subject_id,
  c.name as concept_name,
  c.name_bn as concept_name_bn,
  avg(ks.mastery) as avg_mastery,
  count(*) as skills_tracked,
  count(*) filter (where ks.mastery >= 0.8) as skills_mastered,
  max(ks.last_practiced_at) as last_practiced_at
from public.knowledge_state ks
join public.sub_skills ss on ss.id = ks.sub_skill_id
join public.concepts c  on c.id = ss.concept_id
group by ks.user_id, c.id, c.subject_id, c.name, c.name_bn;
