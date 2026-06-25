import { useEffect, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/contexts/AuthContext";
import { useLang } from "@/contexts/LangContext";
import { t } from "@/lib/i18n";
import { AppHeader } from "@/components/AppHeader";
import { format } from "date-fns";
import { Brain, TrendingUp, AlertTriangle } from "lucide-react";

interface Subject { id: string; name: string; name_bn: string | null; slug: string; sort_order: number; }
interface Concept { id: string; name: string; name_bn: string | null; slug: string; subject_id: string; }
interface SubSkill { id: string; name: string; name_bn: string | null; slug: string; concept_id: string; }
interface KS {
  sub_skill_id: string;
  mastery: number;
  attempts: number;
  correct: number;
  confidence?: number;
  error_tags: string[];
  last_practiced_at: string | null;
}

interface KEvent {
  id: string;
  sub_skill_id: string | null;
  event_type: string;
  correct: boolean | null;
  mastery_after: number | null;
  created_at: string;
}

const STALE_DAYS = 10;
const daysSince = (iso: string | null) =>
  iso ? Math.floor((Date.now() - new Date(iso).getTime()) / 86_400_000) : Infinity;

export default function Knowledge() {
  const { user } = useAuth();
  const { lang } = useLang();
  const T = t(lang);
  const [subjects, setSubjects] = useState<Subject[]>([]);
  const [concepts, setConcepts] = useState<Concept[]>([]);
  const [skills, setSkills] = useState<SubSkill[]>([]);
  const [ks, setKs] = useState<Record<string, KS>>({});
  const [events, setEvents] = useState<KEvent[]>([]);

  useEffect(() => {
    Promise.all([
      supabase.from("subjects").select("*").order("sort_order"),
      supabase.from("concepts").select("*").order("sort_order"),
      supabase.from("sub_skills").select("*").order("sort_order"),
    ]).then(([s, c, sk]) => {
      setSubjects(s.data || []);
      setConcepts(c.data || []);
      setSkills(sk.data || []);
    });
    if (user) {
      supabase
        .from("knowledge_state")
        .select("*")
        .eq("user_id", user.id)
        .then(({ data }) => {
          const map: Record<string, KS> = {};
          for (const row of data || []) map[row.sub_skill_id] = row as any;
          setKs(map);
        });
      // Recent activity (table not in generated types yet — cast around it).
      (supabase as any)
        .from("knowledge_events")
        .select("id, sub_skill_id, event_type, correct, mastery_after, created_at")
        .eq("user_id", user.id)
        .order("created_at", { ascending: false })
        .limit(8)
        .then(({ data }: { data: KEvent[] | null }) => setEvents(data || []));
    }
  }, [user]);

  const lname = (o: { name: string; name_bn: string | null }) =>
    lang === "bn" && o.name_bn ? o.name_bn : o.name;

  const skillName = (id: string | null) => {
    const sk = skills.find((s) => s.id === id);
    return sk ? lname(sk) : "—";
  };

  // Concept-level rollup computed from the loaded knowledge_state.
  const conceptStats = (conceptId: string) => {
    const ids = skills.filter((sk) => sk.concept_id === conceptId).map((sk) => sk.id);
    const rows = ids.map((i) => ks[i]).filter(Boolean) as KS[];
    if (rows.length === 0) return null;
    const avg = rows.reduce((a, r) => a + r.mastery, 0) / rows.length;
    const mastered = rows.filter((r) => r.mastery >= 0.8).length;
    return { avg, mastered, tracked: rows.length };
  };

  // Color for mastery percentage
  const masteryColor = (m: number) => {
    if (m >= 0.8) return "text-[hsl(var(--success))]";
    if (m >= 0.5) return "text-[hsl(var(--warning))]";
    return "text-[hsl(var(--destructive))]";
  };

  return (
    <div className="min-h-screen flex flex-col">
      <AppHeader />
      <main className="flex-1 max-w-[1280px] w-full mx-auto px-4 sm:px-6 py-6 sm:py-10 animate-slide-up">
        {/* Page header */}
        <div className="flex items-center gap-3 mb-2">
          <div className="w-8 h-8 rounded-xl flex items-center justify-center relative overflow-hidden" style={{ background: 'var(--gradient-primary)' }}>
            <span className="absolute inset-0 bg-gradient-to-b from-white/15 to-transparent" />
            <Brain className="h-4 w-4 text-white relative z-10" />
          </div>
          <p className="text-[11px] font-semibold gradient-text tracking-widest uppercase">Knowledge Map</p>
        </div>
        <h1 className="text-2xl sm:text-3xl font-bold mb-1">{T.knowledge}</h1>
        <p className="text-[14px] text-[hsl(var(--ink-muted))] mb-8">
          {T.autoUpdated}
        </p>

        {/* Recent activity */}
        {events.length > 0 && (
          <div className="glass-card p-5 mb-8 sm:mb-10">
            <div className="flex items-center gap-2 mb-4">
              <TrendingUp className="h-4 w-4 text-[hsl(var(--primary))]" />
              <p className="text-[11px] font-semibold text-[hsl(var(--ink-muted))] tracking-widest uppercase">{T.recentActivity}</p>
            </div>
            <ul className="flex flex-wrap gap-2 stagger-children">
              {events.map((e) => (
                <li
                  key={e.id}
                  className="inline-flex items-center gap-1.5 text-[11px] rounded-xl border border-[hsl(var(--hairline))] px-2.5 py-1.5 bg-[hsl(var(--muted)/0.5)] hover:border-[hsl(var(--primary)/0.2)] transition-colors"
                  title={format(new Date(e.created_at), "MMM d, HH:mm")}
                >
                  <span className={e.correct === false ? "text-[hsl(var(--destructive))]" : e.correct ? "text-[hsl(var(--success))]" : "text-[hsl(var(--ink-faint))]"}>
                    {e.correct === false ? "✗" : e.correct ? "✓" : "·"}
                  </span>
                  <span className="truncate max-w-[140px] font-medium">{skillName(e.sub_skill_id)}</span>
                  {e.mastery_after != null && (
                    <span className="font-mono text-[hsl(var(--ink-faint))]">{Math.round(e.mastery_after * 100)}%</span>
                  )}
                </li>
              ))}
            </ul>
          </div>
        )}

        {/* Subject sections */}
        <div className="space-y-10 sm:space-y-12">
          {subjects.map((s, sIdx) => {
            const sConcepts = concepts.filter((c) => c.subject_id === s.id);
            return (
              <section key={s.id}>
                <div className="pb-3 mb-6 flex items-baseline gap-3 section-divider">
                  <span className="text-[12px] font-mono font-bold gradient-text">{String(sIdx + 1).padStart(2, "0")}</span>
                  <h2 className="text-xl sm:text-2xl font-bold">{lname(s)}</h2>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-x-6 lg:gap-x-10 gap-y-8">
                  {sConcepts.map((c) => {
                    const cSkills = skills.filter((sk) => sk.concept_id === c.id);
                    const cStats = conceptStats(c.id);
                    return (
                      <div key={c.id} className="glass-card p-5 card-hover-lift">
                        <div className="flex items-baseline justify-between gap-2 mb-4 pb-3 section-divider">
                          <p className="text-[13px] font-semibold text-[hsl(var(--primary))]">{lname(c)}</p>
                          {cStats && (
                            <p className="text-[10px] font-mono text-[hsl(var(--ink-faint))]">
                              <span className={`font-bold ${masteryColor(cStats.avg)}`}>{Math.round(cStats.avg * 100)}%</span> · {cStats.mastered}/{cStats.tracked} {T.mastered}
                            </p>
                          )}
                        </div>
                        <ul className="space-y-4">
                          {cSkills.map((sk) => {
                            const k = ks[sk.id];
                            return (
                              <li key={sk.id}>
                                <div className="flex items-baseline justify-between gap-3 mb-1.5">
                                  <div className="text-[14px] font-medium">{lname(sk)}</div>
                                  <div className={`font-mono text-[12px] font-bold ${k ? masteryColor(k.mastery) : "text-[hsl(var(--ink-faint))]"}`}>
                                    {k ? `${Math.round(k.mastery * 100)}%` : "—"}
                                  </div>
                                </div>
                                <div className="bar-track">
                                  <div
                                    className="bar-fill"
                                    style={{ width: `${k ? Math.round(k.mastery * 100) : 0}%` }}
                                  />
                                </div>
                                <div className="mt-1.5 flex flex-wrap items-center gap-2 text-[10px] font-medium text-[hsl(var(--ink-faint))]">
                                  {k ? (
                                    <>
                                      <span>{k.attempts} {T.attempts}</span>
                                      {typeof k.confidence === "number" && k.confidence > 0 && (
                                        <span>· {Math.round(k.confidence * 100)}% {T.confidence}</span>
                                      )}
                                      {k.last_practiced_at && (
                                        <span>· {format(new Date(k.last_practiced_at), "MMM d")}</span>
                                      )}
                                      {k.mastery >= 0.5 && daysSince(k.last_practiced_at) >= STALE_DAYS && (
                                        <span className="inline-flex items-center gap-1 bg-[hsl(var(--warning)/0.1)] text-[hsl(var(--warning))] rounded-md px-2 py-0.5 border border-[hsl(var(--warning)/0.15)]">
                                          <AlertTriangle className="h-2.5 w-2.5" />
                                          {T.needsReview}
                                        </span>
                                      )}
                                      {k.error_tags?.length > 0 && (
                                        <span className="flex gap-1 flex-wrap">
                                          {k.error_tags.slice(0, 3).map((tag) => (
                                            <span key={tag} className="bg-[hsl(var(--primary)/0.08)] text-[hsl(var(--primary))] rounded-md px-2 py-0.5 border border-[hsl(var(--primary)/0.06)]">
                                              {tag}
                                            </span>
                                          ))}
                                        </span>
                                      )}
                                    </>
                                  ) : (
                                    <span>{T.noPractice}</span>
                                  )}
                                </div>
                              </li>
                            );
                          })}
                        </ul>
                      </div>
                    );
                  })}
                </div>
              </section>
            );
          })}
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-[hsl(var(--hairline))] py-6 mt-8">
        <div className="max-w-[1280px] mx-auto px-4 sm:px-6 flex items-center justify-between text-[11px] text-[hsl(var(--ink-faint))]">
          <span>© {new Date().getFullYear()} Socratic Tutor</span>
          <span className="gradient-text font-medium">Learn by questioning</span>
        </div>
      </footer>
    </div>
  );
}
