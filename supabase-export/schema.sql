-- ============================================================
-- Socratic AI Tutor — Database schema
-- Run this in the SQL editor of YOUR new Supabase project.
-- After running, also run seed.sql and storage.sql.
-- ============================================================

-- ============ PROFILES ============
CREATE TABLE public.profiles (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  preferred_language TEXT NOT NULL DEFAULT 'en' CHECK (preferred_language IN ('en','bn')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own profile select" ON public.profiles FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "own profile insert" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "own profile update" ON public.profiles FOR UPDATE USING (auth.uid() = user_id);

-- ============ TAXONOMY ============
CREATE TABLE public.subjects (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  slug TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  name_bn TEXT,
  sort_order INT NOT NULL DEFAULT 0
);
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
CREATE POLICY "subjects readable" ON public.subjects FOR SELECT TO anon, authenticated USING (true);

CREATE TABLE public.concepts (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  subject_id UUID NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
  slug TEXT NOT NULL,
  name TEXT NOT NULL,
  name_bn TEXT,
  sort_order INT NOT NULL DEFAULT 0,
  UNIQUE(subject_id, slug)
);
ALTER TABLE public.concepts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "concepts readable" ON public.concepts FOR SELECT TO anon, authenticated USING (true);

CREATE TABLE public.sub_skills (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  concept_id UUID NOT NULL REFERENCES public.concepts(id) ON DELETE CASCADE,
  slug TEXT NOT NULL,
  name TEXT NOT NULL,
  name_bn TEXT,
  description TEXT,
  sort_order INT NOT NULL DEFAULT 0,
  UNIQUE(concept_id, slug)
);
ALTER TABLE public.sub_skills ENABLE ROW LEVEL SECURITY;
CREATE POLICY "sub_skills readable" ON public.sub_skills FOR SELECT TO anon, authenticated USING (true);

-- ============ KNOWLEDGE STATE ============
CREATE TABLE public.knowledge_state (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sub_skill_id UUID NOT NULL REFERENCES public.sub_skills(id) ON DELETE CASCADE,
  mastery NUMERIC NOT NULL DEFAULT 0.3,
  attempts INT NOT NULL DEFAULT 0,
  correct INT NOT NULL DEFAULT 0,
  error_tags TEXT[] NOT NULL DEFAULT '{}',
  last_practiced_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, sub_skill_id)
);
ALTER TABLE public.knowledge_state ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ks select own" ON public.knowledge_state FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "ks insert own" ON public.knowledge_state FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "ks update own" ON public.knowledge_state FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "ks delete own" ON public.knowledge_state FOR DELETE USING (auth.uid() = user_id);
CREATE INDEX idx_ks_user ON public.knowledge_state(user_id);

-- ============ SESSIONS ============
CREATE TABLE public.sessions (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  subject_id UUID REFERENCES public.subjects(id) ON DELETE SET NULL,
  title TEXT NOT NULL DEFAULT 'New session',
  scratchpad JSONB NOT NULL DEFAULT '{"goal":null,"summary":"","turn":0}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "sessions select own" ON public.sessions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "sessions insert own" ON public.sessions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "sessions update own" ON public.sessions FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "sessions delete own" ON public.sessions FOR DELETE USING (auth.uid() = user_id);
CREATE INDEX idx_sessions_user ON public.sessions(user_id, created_at DESC);

-- ============ MESSAGES ============
CREATE TABLE public.messages (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  session_id UUID NOT NULL REFERENCES public.sessions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user','assistant','system')),
  content TEXT NOT NULL DEFAULT '',
  image_url TEXT,
  sub_skill_id UUID REFERENCES public.sub_skills(id) ON DELETE SET NULL,
  was_sanitized BOOLEAN NOT NULL DEFAULT false,
  feedback TEXT CHECK (feedback IN ('got_it','confused','more_help')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "messages select own" ON public.messages FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "messages insert own" ON public.messages FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "messages update own" ON public.messages FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "messages delete own" ON public.messages FOR DELETE USING (auth.uid() = user_id);
CREATE INDEX idx_messages_session ON public.messages(session_id, created_at);

-- ============ TIMESTAMP TRIGGER ============
CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql SET search_path = public AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;

CREATE TRIGGER trg_profiles_touch BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
CREATE TRIGGER trg_ks_touch BEFORE UPDATE ON public.knowledge_state
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
CREATE TRIGGER trg_sessions_touch BEFORE UPDATE ON public.sessions
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- ============ AUTO-CREATE PROFILE ON SIGNUP ============
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.profiles (user_id, display_name, preferred_language)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email,'@',1)),
    COALESCE(NEW.raw_user_meta_data->>'preferred_language', 'en')
  );
  RETURN NEW;
END; $$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
