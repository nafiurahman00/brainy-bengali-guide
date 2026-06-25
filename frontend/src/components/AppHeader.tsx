import { Link, useLocation, useNavigate } from "react-router-dom";
import { useAuth } from "@/contexts/AuthContext";
import { useLang } from "@/contexts/LangContext";
import { t } from "@/lib/i18n";
import { InkButton } from "./InkButton";
import { ThemeToggle } from "./ThemeToggle";
import { GraduationCap, Menu, X } from "lucide-react";
import { useState } from "react";

export function AppHeader() {
  const { user, signOut } = useAuth();
  const { lang, toggle } = useLang();
  const T = t(lang);
  const loc = useLocation();
  const nav = useNavigate();
  const [mobileOpen, setMobileOpen] = useState(false);

  const NavLink = ({ to, label }: { to: string; label: string }) => {
    const active =
      loc.pathname === to || (to !== "/" && loc.pathname.startsWith(to));
    return (
      <Link
        to={to}
        onClick={() => setMobileOpen(false)}
        className={`relative text-[13px] font-medium tracking-wide transition-colors py-1 ${
          active
            ? "text-[hsl(var(--primary))]"
            : "text-[hsl(var(--ink-muted))] hover:text-[hsl(var(--foreground))]"
        }`}
      >
        {label}
        {active && (
          <span className="nav-active-bar" />
        )}
      </Link>
    );
  };

  return (
    <header className="shrink-0 sticky top-0 z-50 border-b border-[hsl(var(--hairline))]" style={{ background: 'hsl(var(--background) / 0.65)', backdropFilter: 'blur(24px) saturate(1.5)', WebkitBackdropFilter: 'blur(24px) saturate(1.5)' }}>
      <div className="w-full px-4 sm:px-6 lg:px-8 h-14 flex items-center justify-between gap-4">
        {/* Logo */}
        <Link to="/" className="flex items-center gap-2.5 group shrink-0">
          <span className="relative inline-flex items-center justify-center w-8 h-8 rounded-xl text-white text-sm font-bold overflow-hidden" style={{ background: 'var(--gradient-primary)' }}>
            <span className="absolute inset-0 bg-gradient-to-b from-white/15 to-transparent" />
            <GraduationCap className="h-4 w-4 relative z-10" />
          </span>
          <span className="text-[17px] font-bold tracking-tight">
            Socratic
          </span>
          <span className="text-[11px] font-semibold gradient-text hidden sm:inline">
            Tutor
          </span>
        </Link>

        {/* Desktop Nav */}
        <div className="hidden sm:flex items-center gap-6 flex-1 justify-end">
          {user ? (
            <nav className="flex items-center gap-5">
              <NavLink to="/" label={T.dashboard} />
              <NavLink to="/knowledge" label={T.knowledge} />
            </nav>
          ) : (
            <nav className="flex items-center gap-5">
              <NavLink to="/guest" label={T.guestMode} />
            </nav>
          )}

          <div className="flex items-center gap-1.5">
            <ThemeToggle />
            <button
              onClick={toggle}
              className="text-[11px] font-medium text-[hsl(var(--ink-muted))] hover:text-[hsl(var(--foreground))] rounded-xl px-2.5 h-8 hover:bg-[hsl(var(--muted))] transition-all duration-200"
              aria-label="Toggle language"
            >
              {T.lang}
              <span className="mx-1 text-[hsl(var(--ink-faint))]">·</span>
              <span className="text-[hsl(var(--ink-faint))]">
                {T.altLang}
              </span>
            </button>
            {user ? (
              <div className="flex items-center gap-2 pl-2 ml-1 border-l border-[hsl(var(--hairline))]">
                <div className="w-7 h-7 rounded-full flex items-center justify-center text-[11px] font-bold text-white shrink-0" style={{ background: 'var(--gradient-primary)' }}>
                  {(user.user_metadata?.display_name ?? user.email ?? '?')[0].toUpperCase()}
                </div>
                <span className="text-[13px] font-medium text-[hsl(var(--ink-muted))] truncate max-w-[120px]">
                  {user.user_metadata?.display_name ?? user.email}
                </span>
                <InkButton
                  variant="ghost"
                  size="sm"
                  onClick={async () => {
                    await signOut();
                    nav("/auth");
                  }}
                >
                  {T.signOut}
                </InkButton>
              </div>
            ) : (
              <InkButton variant="solid" size="sm" onClick={() => nav("/auth")}>
                {T.signIn}
              </InkButton>
            )}
          </div>
        </div>

        {/* Mobile hamburger */}
        <div className="flex sm:hidden items-center gap-2">
          <ThemeToggle />
          <button
            onClick={() => setMobileOpen(!mobileOpen)}
            className="p-2 rounded-xl hover:bg-[hsl(var(--muted))] transition-colors"
            aria-label="Toggle menu"
          >
            {mobileOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
          </button>
        </div>
      </div>

      {/* Mobile dropdown */}
      {mobileOpen && (
        <div className="sm:hidden border-t border-[hsl(var(--hairline))] animate-slide-down" style={{ background: 'hsl(var(--card) / 0.95)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)' }}>
          <div className="px-4 py-4 space-y-4">
            {user ? (
              <nav className="flex flex-col gap-3">
                <NavLink to="/" label={T.dashboard} />
                <NavLink to="/knowledge" label={T.knowledge} />
              </nav>
            ) : (
              <nav className="flex flex-col gap-3">
                <NavLink to="/guest" label={T.guestMode} />
              </nav>
            )}
            <div className="flex items-center gap-2 pt-2 border-t border-[hsl(var(--hairline))]">
              <button
                onClick={toggle}
                className="text-[11px] font-medium text-[hsl(var(--ink-muted))] rounded-lg px-2.5 h-8 bg-[hsl(var(--muted))] transition-colors"
                aria-label="Toggle language"
              >
                {T.lang}
                <span className="mx-0.5 text-[hsl(var(--ink-faint))]">·</span>
                <span className="text-[hsl(var(--ink-faint))]">{T.altLang}</span>
              </button>
              {user ? (
                <InkButton
                  variant="ghost"
                  size="sm"
                  onClick={async () => {
                    await signOut();
                    nav("/auth");
                    setMobileOpen(false);
                  }}
                >
                  {T.signOut}
                </InkButton>
              ) : (
                <InkButton variant="solid" size="sm" onClick={() => { nav("/auth"); setMobileOpen(false); }}>
                  {T.signIn}
                </InkButton>
              )}
            </div>
          </div>
        </div>
      )}
    </header>
  );
}
