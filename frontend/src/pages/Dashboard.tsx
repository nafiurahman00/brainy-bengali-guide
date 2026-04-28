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
import { Plus, ArrowRight, BookOpen } from "lucide-react";

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

  useEffect(() => {
    supabase.from("subjects").select("*").order("sort_order").then(({ data }) => setSubjects(data || []));
    if (user) {
      supabase
        .from("sessions")
        .select("id, title, created_at, subject_id, subject:subjects(id, slug, name, name_bn)")
        .eq("user_id", user.id)
        .order("created_at", { ascending: false })
        .then(({ data }) => setSessions((data as any) || []));
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

  // Color palette for subject cards
  const subjectColors = [
    "from-violet-500 to-purple-600",
    "from-blue-500 to-cyan-500",
    "from-emerald-500 to-teal-600",
    "from-orange-500 to-rose-500",
    "from-pink-500 to-fuchsia-600",
    "from-amber-500 to-orange-600",
    "from-indigo-500 to-blue-600",
    "from-teal-500 to-emerald-600",
  ];

  return (
    <div className="min-h-screen flex flex-col">
      <AppHeader />
      <main className="flex-1 max-w-3xl w-full mx-auto px-4 sm:px-6 py-8 sm:py-12">
        <div className="animate-slide-up">
          <div className="flex flex-col sm:flex-row sm:items-end sm:justify-between gap-4 mb-8">
            <div>
              <p className="text-[12px] font-medium text-[hsl(var(--primary))] tracking-wide mb-1 uppercase">Your sessions</p>
              <h1 className="text-3xl sm:text-4xl font-bold tracking-tight">{T.dashboard}</h1>
            </div>
            <InkButton variant="solid" onClick={() => setPicking((p) => !p)}>
              <Plus className="h-4 w-4 mr-2" /> {T.newSession}
            </InkButton>
          </div>

          {picking && (
            <div className="glass-card p-6 mb-8 animate-pop-in">
              <p className="text-[12px] font-medium text-[hsl(var(--ink-muted))] mb-4">{T.pickSubject}</p>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                {subjects.map((s, i) => (
                  <button
                    key={s.id}
                    disabled={creating}
                    onClick={() => startSession(s)}
                    className={`group relative h-24 flex flex-col items-center justify-center gap-1.5 rounded-xl bg-gradient-to-br ${subjectColors[i % subjectColors.length]} text-white shadow-md hover:shadow-lg hover:scale-[1.03] active:scale-[0.98] transition-all duration-200`}
                  >
                    <span className="text-base font-semibold drop-shadow-sm">{subjectName(s)}</span>
                    <span className="text-[10px] uppercase tracking-wider opacity-70">
                      {s.slug}
                    </span>
                  </button>
                ))}
              </div>
            </div>
          )}

          {sessions.length === 0 ? (
            <div className="glass-card p-14 text-center">
              <BookOpen className="h-10 w-10 text-[hsl(var(--primary))] mx-auto mb-4 opacity-50" />
              <p className="text-[15px] text-[hsl(var(--ink-muted))]">{T.noSessions}</p>
            </div>
          ) : (
            <div className="glass-card overflow-hidden divide-y divide-[hsl(var(--hairline))]">
              {sessions.map((s, i) => (
                <Link
                  key={s.id}
                  to={`/session/${s.id}`}
                  className="flex items-center justify-between gap-4 px-5 py-4 hover:bg-[hsl(var(--primary)/0.04)] transition-colors group"
                >
                  <div className="flex items-center gap-4 min-w-0">
                    <span className="text-[12px] font-mono font-semibold shrink-0 w-7 text-center" style={{ background: 'var(--gradient-primary)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text' }}>
                      {String(i + 1).padStart(2, "0")}
                    </span>
                    <div className="min-w-0">
                      <div className="text-[15px] font-medium truncate">{s.title}</div>
                      <div className="text-[11px] text-[hsl(var(--ink-faint))] mt-0.5">
                        {subjectName(s.subject)} · {format(new Date(s.created_at), "MMM d, yyyy · HH:mm")}
                      </div>
                    </div>
                  </div>
                  <ArrowRight className="h-4 w-4 text-[hsl(var(--ink-faint))] group-hover:text-[hsl(var(--primary))] group-hover:translate-x-0.5 transition-all shrink-0" />
                </Link>
              ))}
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
