import { Link, useLocation, useNavigate } from "react-router-dom";
import { useAuth } from "@/contexts/AuthContext";
import { useLang } from "@/contexts/LangContext";
import { t } from "@/lib/i18n";
import { InkButton } from "./InkButton";
import { ThemeToggle } from "./ThemeToggle";

export function AppHeader() {
  const { user, signOut } = useAuth();
  const { lang, toggle } = useLang();
  const T = t(lang);
  const loc = useLocation();
  const nav = useNavigate();

  const NavLink = ({ to, label }: { to: string; label: string }) => {
    const active =
      loc.pathname === to || (to !== "/" && loc.pathname.startsWith(to));
    return (
      <Link
        to={to}
        className={`relative text-[13px] font-medium tracking-wide transition-colors py-1 ${
          active
            ? "text-[hsl(var(--primary))]"
            : "text-[hsl(var(--ink-muted))] hover:text-[hsl(var(--primary))]"
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
    <header className="shrink-0 sticky top-0 z-50 border-b border-[hsl(var(--hairline))] bg-[hsl(var(--background))]/70 backdrop-blur-xl">
      <div className="max-w-[1280px] mx-auto px-4 sm:px-6 h-auto sm:h-16 py-3 sm:py-0 flex flex-col sm:flex-row items-center justify-between gap-4 sm:gap-6">
        <div className="flex items-center justify-between w-full sm:w-auto">
          <Link to="/" className="flex items-center gap-2.5 group">
            <span className="inline-flex items-center justify-center w-8 h-8 rounded-xl text-white text-sm font-bold" style={{ background: 'var(--gradient-primary)' }}>
              S
            </span>
            <span className="text-[18px] font-bold tracking-tight">
              Socratic
            </span>
            <span className="text-[12px] text-[hsl(var(--primary))] font-semibold hidden sm:inline opacity-70">
              Tutor
            </span>
          </Link>
          <div className="flex sm:hidden items-center gap-2">
            <ThemeToggle />
            <button
              onClick={toggle}
              className="text-[11px] font-medium text-[hsl(var(--ink-muted))] hover:text-[hsl(var(--primary))] rounded-lg px-2.5 h-8 bg-[hsl(var(--muted))] transition-colors"
              aria-label="Toggle language"
            >
              {T.lang === "EN" ? "EN" : "BN"}{" "}
              <span className="mx-0.5 text-[hsl(var(--ink-faint))]">·</span>{" "}
              <span className="text-[hsl(var(--ink-faint))]">
                {T.altLang === "EN" ? "EN" : "BN"}
              </span>
            </button>
          </div>
        </div>

        <div className="flex items-center gap-4 sm:gap-6 w-full sm:w-auto justify-between sm:justify-start">
          {user ? (
            <nav className="flex items-center gap-5 sm:gap-6">
              <NavLink to="/" label={T.dashboard} />
              <NavLink to="/knowledge" label={T.knowledge} />
            </nav>
          ) : (
            <nav className="flex items-center gap-5 sm:gap-6">
              <NavLink to="/guest" label={T.guestMode} />
            </nav>
          )}

          <div className="flex items-center gap-2">
            <div className="hidden sm:flex items-center gap-2">
              <ThemeToggle />
              <button
                onClick={toggle}
                className="text-[11px] font-medium text-[hsl(var(--ink-muted))] hover:text-[hsl(var(--primary))] rounded-lg px-2.5 h-8 bg-[hsl(var(--muted))] transition-colors"
                aria-label="Toggle language"
              >
                {T.lang}{" "}
                <span className="mx-0.5 text-[hsl(var(--ink-faint))]">·</span>{" "}
                <span className="text-[hsl(var(--ink-faint))]">
                  {T.altLang}
                </span>
              </button>
            </div>
            {user ? (
              <div className="flex items-center gap-2">
                <span className="text-[13px] font-medium text-[hsl(var(--ink-muted))] hidden sm:inline truncate max-w-[150px]">
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
      </div>
    </header>
  );
}
