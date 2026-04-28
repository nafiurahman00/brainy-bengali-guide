-- ============================================================
-- Socratic AI Tutor — Storage bucket + per-user RLS
-- Run AFTER schema.sql in your new Supabase SQL editor.
-- ============================================================

-- Private bucket for student-uploaded problem screenshots.
INSERT INTO storage.buckets (id, name, public)
VALUES ('problem-images','problem-images', false)
ON CONFLICT (id) DO NOTHING;

-- Path convention enforced by the app: {auth.uid()}/{sessionId}/{filename}
-- so the first folder segment is always the owner's user id.

DROP POLICY IF EXISTS "own folder read" ON storage.objects;
CREATE POLICY "own folder read" ON storage.objects FOR SELECT
  USING (bucket_id = 'problem-images' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "own folder insert" ON storage.objects;
CREATE POLICY "own folder insert" ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'problem-images' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "own folder delete" ON storage.objects;
CREATE POLICY "own folder delete" ON storage.objects FOR DELETE
  USING (bucket_id = 'problem-images' AND auth.uid()::text = (storage.foldername(name))[1]);
