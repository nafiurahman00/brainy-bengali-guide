import { useEffect, useState } from "react";
import { Moon, Sun } from "lucide-react";

export function ThemeToggle() {
  const [theme, setTheme] = useState<"light" | "dark">(
    () => (localStorage.getItem("theme") as "light" | "dark") || (window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light")
  );

  useEffect(() => {
    const root = window.document.documentElement;
    root.classList.remove("light", "dark");
    root.classList.add(theme);
    localStorage.setItem("theme", theme);
  }, [theme]);

  const toggleTheme = () => {
    setTheme(theme === "light" ? "dark" : "light");
  };

  const isDark = theme === "dark";

  return (
    <button
      onClick={toggleTheme}
      className="relative w-8 h-8 rounded-lg inline-flex items-center justify-center text-[hsl(var(--ink-muted))] hover:text-[hsl(var(--ink))] hover:bg-[hsl(var(--muted))] transition-all duration-200"
      aria-label={isDark ? "Switch to light theme" : "Switch to dark theme"}
      title={isDark ? "Light mode" : "Dark mode"}
    >
      <span className="transition-transform duration-300" style={{ transform: isDark ? 'rotate(0deg)' : 'rotate(-90deg)' }}>
        {isDark ? <Sun size={16} strokeWidth={2} /> : <Moon size={16} strokeWidth={2} />}
      </span>
    </button>
  );
}
