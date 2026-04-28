import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { passwordSchema } from "@/lib/validation";
import { toast } from "sonner";
import { InkButton } from "@/components/InkButton";
import { AppHeader } from "@/components/AppHeader";
import { KeyRound } from "lucide-react";

export default function ResetPassword() {
  const nav = useNavigate();
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    // Supabase parses the recovery hash automatically; once a session exists, allow update.
    supabase.auth.getSession().then(({ data }) => setReady(!!data.session));
    const { data: sub } = supabase.auth.onAuthStateChange((event, session) => {
      if (event === "PASSWORD_RECOVERY" || session) setReady(true);
    });
    return () => sub.subscription.unsubscribe();
  }, []);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    const v = passwordSchema.safeParse(password);
    if (!v.success) { toast.error(v.error.issues[0].message); return; }
    setBusy(true);
    try {
      const { error } = await supabase.auth.updateUser({ password });
      if (error) { toast.error(error.message); return; }
      toast.success("Password updated. Signing you in…");
      nav("/");
    } finally { setBusy(false); }
  };

  return (
    <div className="min-h-screen flex flex-col">
      <AppHeader />
      <main className="flex-1 flex items-center justify-center px-4 sm:px-6 py-8 sm:py-12">
        <div className="w-full max-w-md animate-slide-up">
          <div className="text-center mb-8">
            <div className="hero-icon w-14 h-14 text-white mb-5">
              <KeyRound className="h-6 w-6" />
            </div>
            <p className="text-[12px] font-medium text-[hsl(var(--primary))] mb-2 uppercase">Recovery</p>
            <h1 className="text-2xl sm:text-3xl font-bold">Set a new password</h1>
          </div>
          <form onSubmit={submit} className="glass-card p-6 space-y-4">
            <label className="block">
              <span className="block mb-1.5 text-[12px] font-medium text-[hsl(var(--ink-muted))]">New password</span>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="block w-full h-11 px-4 rounded-xl border border-[hsl(var(--hairline))] bg-[hsl(var(--muted))] text-[14px] outline-none focus:border-[hsl(var(--primary))] focus:shadow-glow transition-all"
                autoComplete="new-password"
                disabled={!ready}
              />
            </label>
            <InkButton variant="solid" disabled={busy || !ready} className="w-full h-11">
              Update password
            </InkButton>
            {!ready && (
              <p className="text-[13px] text-[hsl(var(--ink-muted))] text-center">
                Open the link from your email on this device.
              </p>
            )}
          </form>
        </div>
      </main>
    </div>
  );
}
