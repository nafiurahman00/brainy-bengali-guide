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

  return (
    <div className="min-h-screen flex flex-col">
      <AppHeader />
      <main className="flex-1 flex items-center justify-center px-4 sm:px-6 py-8 sm:py-12">
        <div className="w-full max-w-md animate-slide-up">
          <div className="mb-8 sm:mb-10 text-center">
            <div className="hero-icon w-14 h-14 text-white text-2xl font-bold mb-5">
              S
            </div>
            <h1 className="text-3xl sm:text-4xl font-bold tracking-tight">{T.appName}</h1>
            <p className="mt-2.5 text-[15px] text-[hsl(var(--ink-muted))]">{T.tagline}</p>
          </div>

          <div className="glass-card overflow-hidden">
            <div className="grid grid-cols-2 border-b border-[hsl(var(--hairline))]">
              <button
                onClick={() => setMode("signin")}
                className={`h-12 text-[13px] font-medium tracking-wide transition-all ${
                  mode === "signin"
                    ? "btn-gradient text-white"
                    : "text-[hsl(var(--ink-muted))] hover:text-[hsl(var(--primary))] hover:bg-[hsl(var(--primary)/0.06)]"
                }`}
              >{T.signIn}</button>
              <button
                onClick={() => setMode("signup")}
                className={`h-12 text-[13px] font-medium tracking-wide transition-all ${
                  mode === "signup"
                    ? "btn-gradient text-white"
                    : "text-[hsl(var(--ink-muted))] hover:text-[hsl(var(--primary))] hover:bg-[hsl(var(--primary)/0.06)]"
                }`}
              >{T.signUp}</button>
            </div>

            <form onSubmit={submit} className="p-6 space-y-4">
              {mode === "signup" && (
                <Field label={T.displayName}>
                  <input
                    value={displayName}
                    onChange={(e) => setDisplayName(e.target.value)}
                    className="auth-input"
                    autoComplete="name"
                  />
                </Field>
              )}
              <Field label={T.email}>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="auth-input"
                  autoComplete="email"
                  required
                />
              </Field>
              {mode !== "forgot" && (
                <Field label={T.password}>
                  <input
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="auth-input"
                    autoComplete={mode === "signup" ? "new-password" : "current-password"}
                    required
                  />
                </Field>
              )}

              <div className="pt-2">
                <InkButton variant="solid" disabled={busy} className="w-full h-11">
                  {mode === "signin" && T.signIn}
                  {mode === "signup" && T.signUp}
                  {mode === "forgot" && T.sendReset}
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

          <div className="mt-6 text-center">
            <div className="relative py-4">
              <div className="absolute inset-0 flex items-center"><div className="w-full border-t border-[hsl(var(--hairline))]" /></div>
              <div className="relative flex justify-center"><span className="bg-[hsl(var(--background))] px-3 text-[12px] text-[hsl(var(--ink-faint))] font-medium">or</span></div>
            </div>
            <button
              type="button"
              onClick={() => nav("/guest")}
              className="text-[13px] font-medium text-[hsl(var(--primary))] hover:underline transition-colors"
            >
              {T.continueGuest} →
            </button>
          </div>
        </div>
      </main>
      <style>{`.auth-input{display:block;width:100%;height:44px;padding:0 14px;border:1px solid hsl(var(--hairline));border-radius:12px;background:hsl(var(--muted));font-family:'Inter',system-ui,sans-serif;font-size:14px;color:hsl(var(--ink));outline:none;transition:border-color 0.2s,box-shadow 0.2s}.auth-input:focus{border-color:hsl(var(--primary));box-shadow:var(--shadow-glow)}`}</style>
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
