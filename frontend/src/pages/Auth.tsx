import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { signInSchema, signUpSchema, emailSchema } from "@/lib/validation";
import { toast } from "sonner";
import { InkButton } from "@/components/InkButton";
import { useAuth } from "@/contexts/AuthContext";
import { useEffect } from "react";
import { useLang } from "@/contexts/LangContext";
import { t } from "@/lib/i18n";
import { AppHeader } from "@/components/AppHeader";
import { GraduationCap, Sparkles, ArrowRight, BookOpen, Brain } from "lucide-react";

type Mode = "signin" | "signup" | "forgot";

export default function Auth() {
  const nav = useNavigate();
  const { user, loading } = useAuth();
  const { lang } = useLang();
  const T = t(lang);

  const [mode, setMode] = useState<Mode>("signin");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [displayName, setDisplayName] = useState("");
  const [busy, setBusy] = useState(false);

  useEffect(() => { if (!loading && user) nav("/"); }, [user, loading, nav]);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    try {
      if (mode === "signin") {
        const v = signInSchema.safeParse({ email, password });
        if (!v.success) { toast.error(v.error.issues[0].message); return; }
        const { error } = await supabase.auth.signInWithPassword({ email, password });
        if (error) { toast.error(error.message); return; }
        nav("/");
      } else if (mode === "signup") {
        const v = signUpSchema.safeParse({ email, password, displayName });
        if (!v.success) { toast.error(v.error.issues[0].message); return; }
        const { error } = await supabase.auth.signUp({
          email, password,
          options: {
            emailRedirectTo: `${window.location.origin}/`,
            data: { display_name: displayName, preferred_language: lang },
          },
        });
        if (error) { toast.error(error.message); return; }
        toast.success("Account created. You're signed in.");
        nav("/");
      } else {
        const v = emailSchema.safeParse(email);
        if (!v.success) { toast.error(v.error.issues[0].message); return; }
        const { error } = await supabase.auth.resetPasswordForEmail(email, {
          redirectTo: `${window.location.origin}/reset-password`,
        });
        if (error) { toast.error(error.message); return; }
        toast.success("Check your email for the reset link.");
        setMode("signin");
      }
    } finally { setBusy(false); }
  };

  const features = [
    { icon: <Sparkles className="h-4 w-4" />, text: "AI-powered Socratic method" },
    { icon: <BookOpen className="h-4 w-4" />, text: "Bilingual Bengali + English" },
    { icon: <Brain className="h-4 w-4" />, text: "Adaptive knowledge tracking" },
  ];

  return (
    <div className="min-h-screen flex flex-col">
      <AppHeader />
      <main className="flex-1 flex items-center justify-center px-4 sm:px-6 py-8 sm:py-12">
        <div className="w-full max-w-[440px] animate-slide-up">
          {/* Hero section */}
          <div className="mb-8 sm:mb-10 text-center">
            <div className="hero-icon w-14 h-14 text-white text-2xl font-bold mb-6 mx-auto">
              <GraduationCap className="h-6 w-6 relative z-10" />
            </div>
            <h1 className="text-3xl sm:text-4xl font-bold tracking-tight mb-2">{T.appName}</h1>
            <p className="text-[15px] text-[hsl(var(--ink-muted))] leading-relaxed">{T.tagline}</p>
          </div>

          {/* Feature pills */}
          <div className="flex flex-wrap justify-center gap-2 mb-8">
            {features.map((f, i) => (
              <div key={i} className="inline-flex items-center gap-1.5 text-[11px] font-medium text-[hsl(var(--ink-muted))] bg-[hsl(var(--muted))] rounded-full px-3 py-1.5 border border-[hsl(var(--hairline))]">
                <span className="text-[hsl(var(--primary))]">{f.icon}</span>
                {f.text}
              </div>
            ))}
          </div>

          {/* Auth card */}
          <div className="glass-card-elevated overflow-hidden">
            {/* Tab selector */}
            <div className="grid grid-cols-2 relative">
              <button
                onClick={() => setMode("signin")}
                className={`h-12 text-[13px] font-medium tracking-wide transition-all relative z-10 ${
                  mode === "signin"
                    ? "text-[hsl(var(--foreground))]"
                    : "text-[hsl(var(--ink-muted))] hover:text-[hsl(var(--foreground))]"
                }`}
              >{T.signIn}</button>
              <button
                onClick={() => setMode("signup")}
                className={`h-12 text-[13px] font-medium tracking-wide transition-all relative z-10 ${
                  mode === "signup"
                    ? "text-[hsl(var(--foreground))]"
                    : "text-[hsl(var(--ink-muted))] hover:text-[hsl(var(--foreground))]"
                }`}
              >{T.signUp}</button>
              {/* Sliding indicator */}
              <div
                className="absolute bottom-0 h-[2px] rounded-full transition-all duration-300 ease-out"
                style={{
                  width: '50%',
                  left: mode === "signup" ? '50%' : '0%',
                  background: 'var(--gradient-primary)',
                  boxShadow: '0 0 8px hsl(var(--primary) / 0.3)',
                }}
              />
            </div>
            <div className="h-px bg-[hsl(var(--hairline))]" />

            <form onSubmit={submit} className="p-6 space-y-4">
              {mode === "signup" && (
                <Field label={T.displayName}>
                  <input
                    value={displayName}
                    onChange={(e) => setDisplayName(e.target.value)}
                    className="input-premium"
                    autoComplete="name"
                    placeholder="Your name"
                  />
                </Field>
              )}
              <Field label={T.email}>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="input-premium"
                  autoComplete="email"
                  required
                  placeholder="you@example.com"
                />
              </Field>
              {mode !== "forgot" && (
                <Field label={T.password}>
                  <input
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="input-premium"
                    autoComplete={mode === "signup" ? "new-password" : "current-password"}
                    required
                    placeholder="••••••••"
                  />
                </Field>
              )}

              <div className="pt-2">
                <InkButton variant="solid" disabled={busy} className="w-full h-11 text-[14px]">
                  {mode === "signin" && T.signIn}
                  {mode === "signup" && T.signUp}
                  {mode === "forgot" && T.sendReset}
                  <ArrowRight className="h-4 w-4 ml-2" />
                </InkButton>
              </div>

              <div className="text-center">
                {mode === "signin" && (
                  <button type="button" onClick={() => setMode("forgot")}
                    className="text-[12px] font-medium text-[hsl(var(--ink-muted))] hover:text-[hsl(var(--primary))] transition-colors">
                    {T.forgot}
                  </button>
                )}
                {mode === "forgot" && (
                  <button type="button" onClick={() => setMode("signin")}
                    className="text-[12px] font-medium text-[hsl(var(--ink-muted))] hover:text-[hsl(var(--primary))] transition-colors">
                    ← {T.backToSignIn}
                  </button>
                )}
              </div>
            </form>
          </div>

          {/* Guest link */}
          <div className="mt-6 text-center">
            <div className="relative py-4">
              <div className="absolute inset-0 flex items-center"><div className="w-full" style={{ height: '1px', background: 'linear-gradient(90deg, transparent, hsl(var(--hairline)), transparent)' }} /></div>
              <div className="relative flex justify-center"><span className="bg-[hsl(var(--background))] px-3 text-[12px] text-[hsl(var(--ink-faint))] font-medium">or</span></div>
            </div>
            <button
              type="button"
              onClick={() => nav("/guest")}
              className="inline-flex items-center gap-1.5 text-[13px] font-medium text-[hsl(var(--primary))] hover:underline transition-colors group"
            >
              {T.continueGuest}
              <ArrowRight className="h-3.5 w-3.5 transition-transform group-hover:translate-x-0.5" />
            </button>
          </div>
        </div>
      </main>
    </div>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <span className="block mb-1.5 text-[12px] font-medium text-[hsl(var(--ink-muted))]">{label}</span>
      {children}
    </label>
  );
}
