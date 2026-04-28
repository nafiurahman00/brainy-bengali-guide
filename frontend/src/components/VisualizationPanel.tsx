import { Component, ReactNode, useMemo, useState } from "react";
import { Loader2, RefreshCw, Code2, ChevronDown, ChevronRight, Sparkles, Wand2 } from "lucide-react";
import type { VizState } from "@/hooks/use-visualization";

class VizErrorBoundary extends Component<{ children: ReactNode }, { error: Error | null }> {
  state = { error: null as Error | null };
  static getDerivedStateFromError(error: Error) {
    return { error };
  }
  componentDidCatch(error: Error) {
    console.error("VisualizationPanel render error:", error);
  }
  render() {
    if (this.state.error) {
      return (
        <div className="px-1 py-4">
          <p className="text-[13px] font-medium text-[hsl(var(--destructive))]">Visualization failed to render.</p>
          <p className="text-[12px] text-[hsl(var(--ink-muted))] mt-1 break-words">{this.state.error.message}</p>
        </div>
      );
    }
    return this.props.children;
  }
}

const P5_CDN = "https://cdn.jsdelivr.net/npm/p5@1.11.2/lib/p5.min.js";

// Wraps the LLM-generated p5 sketch in a self-contained HTML document. The
// canvas is constrained by CSS so it never overflows the iframe — the sketch
// can call createCanvas(560, 420) freely; we scale it to fit visually.
function buildSrcDoc(p5Code: string): string {
  return `<!doctype html>
<html>
<head>
<meta charset="utf-8" />
<script src="${P5_CDN}"></script>
<style>
  html, body {
    margin: 0;
    padding: 0;
    background: #ffffff;
    color: #0f172a;
    font-family: ui-sans-serif, system-ui, -apple-system, "Segoe UI", sans-serif;
    width: 100%;
    height: 100%;
    overflow: hidden;
  }
  body {
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 8px;
    box-sizing: border-box;
  }
  canvas {
    display: block;
    max-width: 100% !important;
    max-height: 100% !important;
    height: auto !important;
    width: auto !important;
    border-radius: 6px;
  }
  /* p5 inserts its own DOM elements (sliders, buttons) below the canvas — keep them on one row */
  .p5Canvas + * { margin-top: 6px; }
  input[type="range"] { accent-color: #16A085; }
  .p5-error {
    color: #b91c1c;
    font: 12px ui-monospace, Menlo, monospace;
    padding: 12px;
    white-space: pre-wrap;
  }
</style>
</head>
<body>
<script>
  window.addEventListener("error", (e) => {
    document.body.innerHTML =
      '<pre class="p5-error">Sketch error: ' +
      (e.message || "unknown") +
      '</pre>';
  });
</script>
<script>
${p5Code}
</script>
</body>
</html>`;
}

export function VisualizationPanel(props: { state: VizState; onRetry?: () => void }) {
  return (
    <VizErrorBoundary>
      <VisualizationPanelInner {...props} />
    </VizErrorBoundary>
  );
}

function PanelHeader({ subtitle }: { subtitle?: string }) {
  return (
    <div className="flex items-center gap-2 mb-3">
      <div className="w-6 h-6 rounded-md bg-[hsl(var(--ink))] flex items-center justify-center shrink-0">
        <Wand2 className="h-3.5 w-3.5 text-[hsl(var(--background))]" />
      </div>
      <div className="min-w-0">
        <p className="text-[11px] font-medium text-[hsl(var(--ink-muted))] tracking-wide uppercase leading-none">
          Visual Explainer
        </p>
        {subtitle && (
          <p className="text-[10px] text-[hsl(var(--ink-faint))] mt-0.5 truncate">{subtitle}</p>
        )}
      </div>
    </div>
  );
}

function VisualizationPanelInner({
  state,
  onRetry,
}: {
  state: VizState;
  onRetry?: () => void;
}) {
  const [showCode, setShowCode] = useState(false);

  const srcDoc = useMemo(() => {
    if (state.status !== "ready") return "";
    return buildSrcDoc(state.viz.p5_code);
  }, [state]);

  if (state.status === "idle") {
    return (
      <div className="flex flex-col h-full">
        <PanelHeader />
        <div className="flex-1 flex flex-col items-center justify-center text-center px-4 py-10 rounded-xl border border-dashed border-[hsl(var(--hairline))] bg-[hsl(var(--muted))]/30">
          <div className="w-10 h-10 rounded-xl bg-[hsl(var(--paper))] border border-[hsl(var(--hairline))] flex items-center justify-center mb-3">
            <Sparkles className="h-4 w-4 text-[hsl(var(--ink-muted))]" />
          </div>
          <p className="text-[12px] text-[hsl(var(--ink-muted))] max-w-[240px] leading-relaxed">
            Ask your first question and a live, interactive sketch will appear here.
          </p>
        </div>
      </div>
    );
  }

  if (state.status === "loading") {
    return (
      <div className="flex flex-col h-full">
        <PanelHeader subtitle="generating…" />
        <div className="flex-1 flex flex-col items-center justify-center text-center px-4 py-10 rounded-xl border border-[hsl(var(--hairline))] bg-[hsl(var(--paper))] shadow-surface">
          <Loader2 className="h-5 w-5 animate-spin text-[hsl(var(--ink-muted))] mb-3" />
          <p className="text-[13px] font-medium text-[hsl(var(--ink))]">Building a visual…</p>
          <p className="text-[11px] text-[hsl(var(--ink-faint))] mt-1">Runs once per session · ~5–15s</p>
        </div>
      </div>
    );
  }

  if (state.status === "error") {
    return (
      <div className="flex flex-col h-full">
        <PanelHeader />
        <div className="flex flex-col items-start gap-3 p-4 rounded-xl border border-[hsl(var(--destructive))]/30 bg-[hsl(var(--destructive))]/5">
          <p className="text-[13px] font-medium text-[hsl(var(--destructive))]">Couldn't generate a visualization.</p>
          <p className="text-[12px] text-[hsl(var(--ink-muted))] break-words">{state.error}</p>
          {onRetry && (
            <button
              onClick={onRetry}
              className="inline-flex items-center gap-1.5 text-[12px] font-medium border border-[hsl(var(--hairline))] rounded-lg h-8 px-3 bg-[hsl(var(--paper))] hover:border-[hsl(var(--ink))] hover:text-[hsl(var(--ink))] transition-colors"
            >
              <RefreshCw className="h-3 w-3" /> Retry
            </button>
          )}
        </div>
      </div>
    );
  }

  const { viz } = state;

  return (
    <div className="flex flex-col gap-4 pb-6">
      <PanelHeader subtitle={viz.concept && viz.concept !== "none" ? viz.concept : undefined} />

      <div>
        <h3 className="text-[15px] font-semibold leading-snug">{viz.title}</h3>
        {viz.explanation && (
          <p className="mt-1.5 text-[12.5px] text-[hsl(var(--ink-muted))] leading-relaxed">
            {viz.explanation}
          </p>
        )}
      </div>

      <div className="rounded-xl border border-[hsl(var(--hairline))] overflow-hidden bg-white shadow-surface aspect-[4/3] w-full">
        <iframe
          key={typeof viz.p5_code === "string" ? viz.p5_code.slice(0, 64) : "viz"}
          title={viz.title || "Visualization"}
          srcDoc={srcDoc}
          sandbox="allow-scripts"
          className="block w-full h-full"
          style={{ border: 0 }}
        />
      </div>

      {viz.interaction_hint && (
        <div className="flex items-start gap-2 rounded-lg bg-[hsl(var(--muted))]/60 border border-[hsl(var(--hairline))] px-3 py-2">
          <Sparkles className="h-3 w-3 text-[hsl(var(--ink-muted))] mt-0.5 shrink-0" />
          <p className="text-[11.5px] text-[hsl(var(--ink-muted))] leading-relaxed">
            {viz.interaction_hint}
          </p>
        </div>
      )}

      <div className="border-t border-[hsl(var(--hairline))] pt-3">
        <button
          onClick={() => setShowCode((s) => !s)}
          className="inline-flex items-center gap-1.5 text-[11px] font-medium text-[hsl(var(--ink-muted))] hover:text-[hsl(var(--ink))] transition-colors"
        >
          {showCode ? <ChevronDown className="h-3 w-3" /> : <ChevronRight className="h-3 w-3" />}
          <Code2 className="h-3 w-3" /> {showCode ? "Hide source" : "View source"}
        </button>

        {showCode && (
          <pre className="mt-2 text-[10.5px] leading-snug bg-[hsl(var(--muted))] border border-[hsl(var(--hairline))] rounded-lg p-3 overflow-auto max-h-72 whitespace-pre">
            <code>{viz.p5_code}</code>
          </pre>
        )}
      </div>
    </div>
  );
}
