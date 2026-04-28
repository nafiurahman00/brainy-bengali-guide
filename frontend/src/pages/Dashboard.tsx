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

  return (
    <div className="min-h-screen flex flex-col">
      <AppHeader />
      <main className="flex-1 max-w-3xl w-full mx-auto px-4 sm:px-6 py-8 sm:py-12">
        <div className="animate-slide-up">
          <div className="flex flex-col sm:flex-row sm:items-end sm:justify-between gap-4 mb-8">
            <div>
              <p className="text-[12px] font-medium text-[hsl(var(--ink-muted))] tracking-wide mb-1">Your sessions</p>
              <h1 className="text-3xl sm:text-4xl font-bold tracking-tight">{T.dashboard}</h1>
            </div>
            <InkButton variant="solid" onClick={() => setPicking((p) => !p)}>
              <Plus className="h-4 w-4 mr-2" /> {T.newSession}
            </InkButton>
          </div>

          {picking && (
            <div className="glass-card p-6 mb-8">
              <p className="text-[12px] font-medium text-[hsl(var(--ink-muted))] mb-4">{T.pickSubject}</p>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                {subjects.map((s) => (
                  <button
                    key={s.id}
                    disabled={creating}
                    onClick={() => startSession(s)}
                    className="group relative h-24 flex flex-col items-center justify-center gap-1.5 rounded-xl border border-[hsl(var(--hairline))] bg-[hsl(var(--paper))] hover:border-[hsl(var(--ink))] hover:bg-[hsl(var(--ink))] hover:text-[hsl(var(--background))] transition-all duration-200"
                  >
                    <span className="text-base font-semibold">{subjectName(s)}</span>
                    <span className="text-[10px] uppercase tracking-wider text-[hsl(var(--ink-faint))] group-hover:text-[hsl(var(--background))]/70 transition-colors">
                      {s.slug}
                    </span>
                  </button>
                ))}
              </div>
            </div>
          )}

          {sessions.length === 0 ? (
            <div className="glass-card p-14 text-center">
              <BookOpen className="h-10 w-10 text-[hsl(var(--ink-faint))] mx-auto mb-4 opacity-40" />
              <p className="text-[15px] text-[hsl(var(--ink-muted))]">{T.noSessions}</p>
            </div>
          ) : (
            <div className="glass-card overflow-hidden divide-y divide-[hsl(var(--hairline))]">
              {sessions.map((s, i) => (
                <Link
                  key={s.id}
                  to={`/session/${s.id}`}
                  className="flex items-center justify-between gap-4 px-5 py-4 hover:bg-[hsl(var(--muted))] transition-colors group"
                >
                  <div className="flex items-center gap-4 min-w-0">
                    <span className="text-[12px] font-mono font-semibold text-[hsl(var(--ink-muted))] shrink-0 w-7 text-center">
                      {String(i + 1).padStart(2, "0")}
                    </span>
                    <div className="min-w-0">
                      <div className="text-[15px] font-medium truncate">{s.title}</div>
                      <div className="text-[11px] text-[hsl(var(--ink-faint))] mt-0.5">
                        {subjectName(s.subject)} · {format(new Date(s.created_at), "MMM d, yyyy · HH:mm")}
                      </div>
                    </div>
                  </div>
                  <ArrowRight className="h-4 w-4 text-[hsl(var(--ink-faint))] group-hover:text-[hsl(var(--ink))] group-hover:translate-x-0.5 transition-all shrink-0" />
                </Link>
              ))}
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
