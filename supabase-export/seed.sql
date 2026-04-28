-- ============================================================
-- Socratic AI Tutor — Taxonomy seed
-- Run AFTER schema.sql.
-- Re-runnable: uses ON CONFLICT DO NOTHING on the natural unique keys.
-- ============================================================

-- ============ SUBJECTS ============
INSERT INTO public.subjects (slug, name, name_bn, sort_order) VALUES
  ('math','Mathematics','গণিত',1),
  ('physics','Physics','পদার্থবিজ্ঞান',2),
  ('chemistry','Chemistry','রসায়ন',3),
  ('biology','Biology','জীববিজ্ঞান',4)
ON CONFLICT (slug) DO NOTHING;

-- ============ MATH ============
WITH s AS (SELECT id FROM public.subjects WHERE slug='math')
INSERT INTO public.concepts (subject_id, slug, name, name_bn, sort_order)
SELECT s.id, c.slug, c.name, c.name_bn, c.so FROM s, (VALUES
  ('algebra','Algebra','বীজগণিত',1),
  ('geometry','Geometry','জ্যামিতি',2),
  ('calculus','Calculus','ক্যালকুলাস',3),
  ('trigonometry','Trigonometry','ত্রিকোণমিতি',4),
  ('probability','Probability','সম্ভাব্যতা',5)
) AS c(slug,name,name_bn,so)
ON CONFLICT (subject_id, slug) DO NOTHING;

WITH c AS (SELECT id, slug FROM public.concepts WHERE subject_id=(SELECT id FROM public.subjects WHERE slug='math'))
INSERT INTO public.sub_skills (concept_id, slug, name, name_bn, sort_order)
SELECT c.id, ss.slug, ss.name, ss.name_bn, ss.so
FROM c JOIN (VALUES
  ('algebra','linear-eq','Linear equations','রৈখিক সমীকরণ',1),
  ('algebra','quadratic-factoring','Quadratic factoring','দ্বিঘাত উৎপাদকীকরণ',2),
  ('algebra','discriminant','Discriminant','ডিসক্রিমিন্যান্ট',3),
  ('algebra','polynomials','Polynomials','বহুপদী',4),
  ('geometry','triangles','Triangles','ত্রিভুজ',1),
  ('geometry','circles','Circles','বৃত্ত',2),
  ('geometry','area-volume','Area & Volume','ক্ষেত্রফল ও আয়তন',3),
  ('calculus','derivatives','Derivatives','অন্তরজ',1),
  ('calculus','integrals','Integrals','যোগজ',2),
  ('calculus','limits','Limits','সীমা',3),
  ('trigonometry','identities','Identities','অভেদ',1),
  ('trigonometry','ratios','Trig ratios','ত্রিকোণমিতিক অনুপাত',2),
  ('probability','basic-prob','Basic probability','মৌলিক সম্ভাব্যতা',1),
  ('probability','combinations','Combinations','সমাবেশ',2)
) AS ss(c_slug,slug,name,name_bn,so) ON ss.c_slug = c.slug
ON CONFLICT (concept_id, slug) DO NOTHING;

-- ============ PHYSICS ============
WITH s AS (SELECT id FROM public.subjects WHERE slug='physics')
INSERT INTO public.concepts (subject_id, slug, name, name_bn, sort_order)
SELECT s.id, c.slug, c.name, c.name_bn, c.so FROM s, (VALUES
  ('mechanics','Mechanics','বলবিদ্যা',1),
  ('thermodynamics','Thermodynamics','তাপগতিবিদ্যা',2),
  ('electromagnetism','Electromagnetism','তড়িৎ-চুম্বকত্ব',3),
  ('waves-optics','Waves & Optics','তরঙ্গ ও আলোকবিজ্ঞান',4)
) AS c(slug,name,name_bn,so)
ON CONFLICT (subject_id, slug) DO NOTHING;

WITH c AS (SELECT id, slug FROM public.concepts WHERE subject_id=(SELECT id FROM public.subjects WHERE slug='physics'))
INSERT INTO public.sub_skills (concept_id, slug, name, name_bn, sort_order)
SELECT c.id, ss.slug, ss.name, ss.name_bn, ss.so
FROM c JOIN (VALUES
  ('mechanics','kinematics','Kinematics','গতিবিজ্ঞান',1),
  ('mechanics','newtons-laws','Newton''s laws','নিউটনের সূত্র',2),
  ('mechanics','momentum','Momentum','ভরবেগ',3),
  ('mechanics','energy-work','Energy & Work','শক্তি ও কাজ',4),
  ('thermodynamics','heat-temp','Heat & Temperature','তাপ ও তাপমাত্রা',1),
  ('thermodynamics','laws-thermo','Laws of thermodynamics','তাপগতিবিদ্যার সূত্র',2),
  ('electromagnetism','circuits','Circuits','বর্তনী',1),
  ('electromagnetism','fields','Electric & magnetic fields','তড়িৎ ও চৌম্বক ক্ষেত্র',2),
  ('waves-optics','wave-properties','Wave properties','তরঙ্গের ধর্ম',1),
  ('waves-optics','reflection-refraction','Reflection & refraction','প্রতিফলন ও প্রতিসরণ',2)
) AS ss(c_slug,slug,name,name_bn,so) ON ss.c_slug = c.slug
ON CONFLICT (concept_id, slug) DO NOTHING;

-- ============ CHEMISTRY ============
WITH s AS (SELECT id FROM public.subjects WHERE slug='chemistry')
INSERT INTO public.concepts (subject_id, slug, name, name_bn, sort_order)
SELECT s.id, c.slug, c.name, c.name_bn, c.so FROM s, (VALUES
  ('atomic','Atomic structure','পারমাণবিক গঠন',1),
  ('reactions','Chemical reactions','রাসায়নিক বিক্রিয়া',2),
  ('organic','Organic chemistry','জৈব রসায়ন',3),
  ('solutions','Solutions & acids','দ্রবণ ও অ্যাসিড',4)
) AS c(slug,name,name_bn,so)
ON CONFLICT (subject_id, slug) DO NOTHING;

WITH c AS (SELECT id, slug FROM public.concepts WHERE subject_id=(SELECT id FROM public.subjects WHERE slug='chemistry'))
INSERT INTO public.sub_skills (concept_id, slug, name, name_bn, sort_order)
SELECT c.id, ss.slug, ss.name, ss.name_bn, ss.so
FROM c JOIN (VALUES
  ('atomic','periodic-table','Periodic table','পর্যায় সারণি',1),
  ('atomic','electron-config','Electron configuration','ইলেকট্রন বিন্যাস',2),
  ('atomic','bonding','Chemical bonding','রাসায়নিক বন্ধন',3),
  ('reactions','balancing','Balancing equations','সমীকরণ সমতা',1),
  ('reactions','stoichiometry','Stoichiometry','স্টয়কিওমেট্রি',2),
  ('reactions','redox','Redox reactions','জারণ-বিজারণ',3),
  ('organic','hydrocarbons','Hydrocarbons','হাইড্রোকার্বন',1),
  ('organic','functional-groups','Functional groups','ক্রিয়াশীল মূলক',2),
  ('solutions','ph-acids','pH & acids','pH ও অ্যাসিড',1),
  ('solutions','concentration','Concentration','গাঢ়ত্ব',2)
) AS ss(c_slug,slug,name,name_bn,so) ON ss.c_slug = c.slug
ON CONFLICT (concept_id, slug) DO NOTHING;

-- ============ BIOLOGY ============
WITH s AS (SELECT id FROM public.subjects WHERE slug='biology')
INSERT INTO public.concepts (subject_id, slug, name, name_bn, sort_order)
SELECT s.id, c.slug, c.name, c.name_bn, c.so FROM s, (VALUES
  ('cell','Cell biology','কোষ জীববিজ্ঞান',1),
  ('genetics','Genetics','জিনতত্ত্ব',2),
  ('physiology','Physiology','শারীরবিদ্যা',3),
  ('ecology','Ecology','বাস্তুবিদ্যা',4)
) AS c(slug,name,name_bn,so)
ON CONFLICT (subject_id, slug) DO NOTHING;

WITH c AS (SELECT id, slug FROM public.concepts WHERE subject_id=(SELECT id FROM public.subjects WHERE slug='biology'))
INSERT INTO public.sub_skills (concept_id, slug, name, name_bn, sort_order)
SELECT c.id, ss.slug, ss.name, ss.name_bn, ss.so
FROM c JOIN (VALUES
  ('cell','cell-structure','Cell structure','কোষের গঠন',1),
  ('cell','mitosis-meiosis','Mitosis & meiosis','মাইটোসিস ও মিয়োসিস',2),
  ('cell','photosynthesis','Photosynthesis','সালোকসংশ্লেষণ',3),
  ('cell','respiration','Cellular respiration','কোষীয় শ্বসন',4),
  ('genetics','dna-rna','DNA & RNA','ডিএনএ ও আরএনএ',1),
  ('genetics','mendelian','Mendelian genetics','মেন্ডেলীয় জিনতত্ত্ব',2),
  ('physiology','circulation','Circulatory system','সংবহনতন্ত্র',1),
  ('physiology','digestion','Digestive system','পরিপাকতন্ত্র',2),
  ('ecology','ecosystems','Ecosystems','বাস্তুতন্ত্র',1),
  ('ecology','food-chains','Food chains','খাদ্য শৃঙ্খল',2)
) AS ss(c_slug,slug,name,name_bn,so) ON ss.c_slug = c.slug
ON CONFLICT (concept_id, slug) DO NOTHING;
