import { useLocation } from "react-router-dom";
import { useEffect } from "react";
import { AlertTriangle } from "lucide-react";

const NotFound = () => {
  const location = useLocation();

  useEffect(() => {
    console.error("404 Error: User attempted to access non-existent route:", location.pathname);
  }, [location.pathname]);

  return (
    <div className="flex min-h-screen items-center justify-center bg-background">
      <div className="text-center animate-slide-up">
        <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-[hsl(var(--muted))] mb-6">
          <AlertTriangle className="h-7 w-7 text-[hsl(var(--ink-faint))]" />
        </div>
        <h1 className="mb-2 text-5xl font-bold tracking-tight">404</h1>
        <p className="mb-6 text-[15px] text-[hsl(var(--ink-muted))]">Oops! Page not found</p>
        <a href="/" className="inline-flex items-center justify-center h-10 px-5 rounded-lg bg-[hsl(var(--ink))] text-[hsl(var(--background))] text-[13px] font-medium hover:opacity-80 transition-all">
          Return to Home
        </a>
      </div>
    </div>
  );
};

export default NotFound;
