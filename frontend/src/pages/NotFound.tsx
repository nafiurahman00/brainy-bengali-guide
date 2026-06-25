import { useLocation } from "react-router-dom";
import { useEffect } from "react";
import { AlertTriangle, ArrowLeft } from "lucide-react";

const NotFound = () => {
  const location = useLocation();

  useEffect(() => {
    console.error("404 Error: User attempted to access non-existent route:", location.pathname);
  }, [location.pathname]);

  return (
    <div className="flex min-h-screen items-center justify-center bg-background">
      <div className="text-center animate-slide-up px-6">
        <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl mb-8 relative overflow-hidden" style={{ background: 'var(--gradient-primary)' }}>
          <span className="absolute inset-0 bg-gradient-to-b from-white/15 to-transparent" />
          <AlertTriangle className="h-7 w-7 text-white relative z-10" />
        </div>
        <h1 className="mb-3 text-6xl font-bold tracking-tighter shimmer-text">404</h1>
        <p className="mb-2 text-[17px] font-medium text-[hsl(var(--foreground))]">Page not found</p>
        <p className="mb-8 text-[14px] text-[hsl(var(--ink-muted))] max-w-xs mx-auto">
          The page you're looking for doesn't exist or has been moved.
        </p>
        <a href="/" className="inline-flex items-center justify-center gap-2 h-11 px-6 rounded-xl text-[14px] font-medium transition-all text-white btn-gradient group">
          <ArrowLeft className="h-4 w-4 transition-transform group-hover:-translate-x-0.5" />
          Return to Home
        </a>
      </div>
    </div>
  );
};

export default NotFound;
