import { useEffect, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/contexts/AuthContext";
import { useLang } from "@/contexts/LangContext";
import { t } from "@/lib/i18n";
import { AppHeader } from "@/components/AppHeader";
import { format } from "date-fns";
import { Brain } from "lucide-react";

interface Subject { id: string; name: string; name_bn: string | null; slug: string; sort_order: number; }
interface Concept { id: string; name: string; name_bn: string | null; slug: string; subject_id: string; }
interface SubSkill { id: string; name: string; name_bn: string | null; slug: string; concept_id: string; }
interface KS {
  sub_skill_id: string;
  mastery: number;
  attempts: number;
  correct: number;
  error_tags: string[];
  last_practiced_at: string | null;
}

export default function Knowledge() {
  const { user } = useAuth();
  const { lang } = useLang();
  const T = t(lang);
  const [subjects, setSubjects] = useState<Subject[]>([]);
  const [concepts, setConcepts] = useState<Concept[]>([]);
  const [skills, setSkills] = useState<SubSkill[]>([]);
  const [ks, setKs] = useState<Record<string, KS>>({});

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
    }
  }, [user]);

  const lname = (o: { name: string; name_bn: string | null }) =>
    lang === "bn" && o.name_bn ? o.name_bn : o.name;

  return (
    <div className="min-h-screen flex flex-col">
      <AppHeader />
      <main className="flex-1 max-w-[1280px] w-full mx-auto px-4 sm:px-6 py-6 sm:py-10 animate-slide-up">
        <div className="flex items-center gap-3 mb-2">
          <Brain className="h-5 w-5 text-[hsl(var(--ink-muted))]" />
          <p className="text-[12px] font-medium text-[hsl(var(--ink-muted))] tracking-wide uppercase">Knowledge Map</p>
        </div>
        <h1 className="text-2xl sm:text-3xl font-bold mb-1">{T.knowledge}</h1>
        <p className="text-[14px] text-[hsl(var(--ink-muted))] mb-8 sm:mb-10">
          Your fluency vector. Updated whenever you tap a feedback button.
        </p>

        <div className="space-y-10 sm:space-y-12">
          {subjects.map((s, sIdx) => {
            const sConcepts = concepts.filter((c) => c.subject_id === s.id);
            return (
              <section key={s.id}>
                <div className="border-b border-[hsl(var(--hairline))] pb-3 mb-6 flex items-baseline gap-3">
                  <span className="text-[12px] font-mono font-semibold text-[hsl(var(--ink-muted))]">{String(sIdx + 1).padStart(2, "0")}</span>
                  <h2 className="text-xl sm:text-2xl font-bold">{lname(s)}</h2>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-x-6 lg:gap-x-10 gap-y-8">
                  {sConcepts.map((c) => {
                    const cSkills = skills.filter((sk) => sk.concept_id === c.id);
                    return (
                      <div key={c.id} className="glass-card p-5">
                        <p className="text-[12px] font-medium text-[hsl(var(--ink-muted))] mb-4 pb-2 border-b border-[hsl(var(--hairline))]">{lname(c)}</p>
                        <ul className="space-y-4">
                          {cSkills.map((sk) => {
                            const k = ks[sk.id];
                            return (
                              <li key={sk.id}>
                                <div className="flex items-baseline justify-between gap-3 mb-1.5">
                                  <div className="text-[15px] font-medium">{lname(sk)}</div>
                                  <div className={`font-mono text-[12px] font-semibold ${k ? "text-[hsl(var(--ink))]" : "text-[hsl(var(--ink-faint))]"}`}>
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
                                      {k.last_practiced_at && (
                                        <span>· {format(new Date(k.last_practiced_at), "MMM d")}</span>
                                      )}
                                      {k.error_tags?.length > 0 && (
                                        <span className="flex gap-1 flex-wrap">
                                          {k.error_tags.slice(0, 3).map((tag) => (
                                            <span key={tag} className="bg-[hsl(var(--muted))] rounded-md px-2 py-0.5 text-[hsl(var(--ink-muted))]">
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
    </div>
  );
}
