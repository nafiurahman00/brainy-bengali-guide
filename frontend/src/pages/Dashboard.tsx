import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/contexts/AuthContext";
import { useLang } from "@/contexts/LangContext";
import { t } from "@/lib/i18n";
import { AppHeader } from "@/components/AppHeader";
import { InkButton } from "@/components/InkButton";
import { toast } from "sonner";
import { format } from "date-fns";
import { Plus, ArrowRight, BookOpen, Sparkles, Clock } from "lucide-react";

interface Subject { id: string; slug: string; name: string; name_bn: string | null; }
interface Session { id: string; title: string; created_at: string; subject_id: string | null; subject?: Subject; }

export default function Dashboard() {
  const { user } = useAuth();
  const { lang } = useLang();
  const T = t(lang);
  const nav = useNavigate();
  const [subjects, setSubjects] = useState<Subject[]>([]);
  const [sessions, setSessions] = useState<Session[]>([]);
  const [picking, setPicking] = useState(false);
  const [creating, setCreating] = useState(false);
  const [rec, setRec] = useState<{ name: string; name_bn: string | null; avg: number } | null>(null);

  useEffect(() => {
    supabase.from("subjects").select("*").order("sort_order").then(({ data }) => setSubjects(data || []));
    if (user) {
      supabase
        .from("sessions")
        .select("id, title, created_at, subject_id, subject:subjects(id, slug, name, name_bn)")
        .eq("user_id", user.id)
        .order("created_at", { ascending: false })
        .then(({ data }) => setSessions((data as any) || []));
      // Weakest tracked concept → "recommended next" (view not in generated types).
      (supabase as any)
        .from("concept_mastery")
        .select("concept_name, concept_name_bn, avg_mastery, skills_tracked")
        .eq("user_id", user.id)
        .order("avg_mastery", { ascending: true })
        .limit(1)
        .then(({ data }: { data: any[] | null }) => {
          const r = data?.[0];
          if (r) setRec({ name: r.concept_name, name_bn: r.concept_name_bn, avg: Number(r.avg_mastery) });
        });
    }
  }, [user]);

  const startSession = async (subj: Subject) => {
    if (!user) return;
    setCreating(true);
    try {
      const { data, error } = await supabase
        .from("sessions")
        .insert({ user_id: user.id, subject_id: subj.id, title: `${subj.name} session` })
        .select()
        .single();
      if (error) { toast.error(error.message); return; }
      nav(`/session/${data.id}`);
    } finally { setCreating(false); }
  };

  const subjectName = (s?: Subject) => s ? (lang === "bn" && s.name_bn ? s.name_bn : s.name) : "";

  // Color palette for subject cards — refined gradient pairs
  const subjectStyles = [
    { gradient: "from-violet-500 to-purple-600", emoji: "📐" },
    { gradient: "from-blue-500 to-cyan-500", emoji: "🔬" },
    { gradient: "from-emerald-500 to-teal-600", emoji: "🧪" },
    { gradient: "from-orange-500 to-rose-500", emoji: "📊" },
    { gradient: "from-pink-500 to-fuchsia-600", emoji: "🎨" },
    { gradient: "from-amber-500 to-orange-600", emoji: "⚡" },
    { gradient: "from-indigo-500 to-blue-600", emoji: "🌍" },
    { gradient: "from-teal-500 to-emerald-600", emoji: "🧬" },
  ];

  return (
    <div className="min-h-screen flex flex-col">
      <AppHeader />
      <main className="flex-1 max-w-3xl w-full mx-auto px-4 sm:px-6 py-8 sm:py-12">
        <div className="animate-slide-up">
          {/* Page header */}
          <div className="flex flex-col sm:flex-row sm:items-end sm:justify-between gap-4 mb-8">
            <div>
              <p className="text-[11px] font-semibold gradient-text tracking-widest mb-1.5 uppercase">Your sessions</p>
              <h1 className="text-3xl sm:text-4xl font-bold tracking-tight">{T.dashboard}</h1>
            </div>
            <InkButton variant="solid" onClick={() => setPicking((p) => !p)} className="group">
              <Plus className="h-4 w-4 mr-2 transition-transform group-hover:rotate-90" /> {T.newSession}
            </InkButton>
          </div>

          {/* Recommendation banner */}
          {rec && sessions.length > 0 && (
            <div className="glass-card px-5 py-3.5 mb-6 flex items-center gap-3 flex-wrap text-[13px] animate-scale-in">
              <div className="w-8 h-8 rounded-lg flex items-center justify-center shrink-0" style={{ background: 'var(--gradient-subtle)' }}>
                <Sparkles className="h-4 w-4 text-[hsl(var(--primary))]" />
              </div>
              <div className="flex-1 min-w-0">
                <span className="font-medium">{T.welcomeBack} 👋</span>
                <span className="text-[hsl(var(--ink-muted))] ml-2">
                  {T.recommendedNext}:
                </span>
                <span className="font-semibold gradient-text ml-1.5">
                  {lang === "bn" && rec.name_bn ? rec.name_bn : rec.name} · {Math.round(rec.avg * 100)}%
                </span>
              </div>
            </div>
          )}

          {/* Subject picker */}
          {picking && (
            <div className="glass-card p-6 mb-8 animate-pop-in">
              <p className="text-[12px] font-semibold text-[hsl(var(--ink-muted))] mb-4 uppercase tracking-wide">{T.pickSubject}</p>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 stagger-children">
                {subjects.map((s, i) => {
                  const style = subjectStyles[i % subjectStyles.length];
                  return (
                    <button
                      key={s.id}
                      disabled={creating}
                      onClick={() => startSession(s)}
                      className={`group relative h-24 flex flex-col items-center justify-center gap-1.5 rounded-xl bg-gradient-to-br ${style.gradient} text-white shadow-md hover:shadow-xl hover:scale-[1.04] active:scale-[0.97] transition-all duration-300 overflow-hidden`}
                    >
                      <span className="absolute inset-0 bg-gradient-to-b from-white/12 to-transparent" />
                      <span className="text-lg mb-0.5">{style.emoji}</span>
                      <span className="text-[13px] font-semibold drop-shadow-sm relative z-10">{subjectName(s)}</span>
                      <span className="text-[9px] uppercase tracking-widest opacity-60 relative z-10">
                        {s.slug}
                      </span>
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {/* Sessions list */}
          {sessions.length === 0 ? (
            <div className="glass-card p-16 text-center">
              <div className="w-14 h-14 rounded-2xl flex items-center justify-center mx-auto mb-5" style={{ background: 'var(--gradient-subtle)' }}>
                <BookOpen className="h-6 w-6 text-[hsl(var(--primary))]" />
              </div>
              <p className="text-[16px] font-medium text-[hsl(var(--ink-muted))] mb-1">{T.noSessions}</p>
              <p className="text-[13px] text-[hsl(var(--ink-faint))]">Start a new session to begin learning</p>
            </div>
          ) : (
            <div className="glass-card overflow-hidden">
              <div className="divide-y divide-[hsl(var(--hairline))]">
                {sessions.map((s, i) => (
                  <Link
                    key={s.id}
                    to={`/session/${s.id}`}
                    className="flex items-center justify-between gap-4 px-5 py-4 hover:bg-[hsl(var(--primary)/0.03)] transition-all duration-200 group"
                    style={{ animationDelay: `${i * 0.03}s` }}
                  >
                    <div className="flex items-center gap-4 min-w-0">
                      <span className="text-[12px] font-mono font-bold shrink-0 w-7 text-center gradient-text">
                        {String(i + 1).padStart(2, "0")}
                      </span>
                      <div className="min-w-0">
                        <div className="text-[15px] font-medium truncate group-hover:text-[hsl(var(--primary))] transition-colors">{s.title}</div>
                        <div className="flex items-center gap-1.5 text-[11px] text-[hsl(var(--ink-faint))] mt-0.5">
                          <Clock className="h-3 w-3" />
                          {subjectName(s.subject)} · {format(new Date(s.created_at), "MMM d, yyyy · HH:mm")}
                        </div>
                      </div>
                    </div>
                    <ArrowRight className="h-4 w-4 text-[hsl(var(--ink-faint))] group-hover:text-[hsl(var(--primary))] group-hover:translate-x-1 transition-all shrink-0" />
                  </Link>
                ))}
              </div>
            </div>
          )}
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-[hsl(var(--hairline))] py-6">
        <div className="max-w-3xl mx-auto px-4 sm:px-6 flex items-center justify-between text-[11px] text-[hsl(var(--ink-faint))]">
          <span>© {new Date().getFullYear()} Socratic Tutor</span>
          <span className="gradient-text font-medium">Learn by questioning</span>
        </div>
      </footer>
    </div>
  );
}
