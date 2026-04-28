-- Adds the visualization column used by /api/visualize to persist a one-shot
-- p5.js sketch generated from the student's first question of a session.
ALTER TABLE public.sessions
  ADD COLUMN IF NOT EXISTS visualization JSONB;
