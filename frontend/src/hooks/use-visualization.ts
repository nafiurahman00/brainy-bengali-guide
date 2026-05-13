import { useCallback, useEffect, useRef, useState } from "react";
import { supabase } from "@/integrations/supabase/client";

const VIZ_URL = `${import.meta.env.VITE_API_URL || ""}/api/visualize`;

export interface Visualization {
  title: string;
  explanation: string;
  concept: string;
  p5_code: string;
  interaction_hint: string;
}

export type VizState =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "ready"; viz: Visualization }
  | { status: "error"; error: string };

function normalizeViz(raw: any): Visualization | null {
  if (!raw || typeof raw !== "object") return null;
  if (typeof raw.p5_code !== "string" || raw.p5_code.trim().length === 0) return null;
  return {
    title: typeof raw.title === "string" ? raw.title : "Visualization",
    explanation: typeof raw.explanation === "string" ? raw.explanation : "",
    concept: typeof raw.concept === "string" ? raw.concept : "",
    p5_code: raw.p5_code,
    interaction_hint: typeof raw.interaction_hint === "string" ? raw.interaction_hint : "",
  };
}

export function useVisualization(sessionId: string | undefined) {
  const [state, setState] = useState<VizState>({ status: "idle" });
  const abortRef = useRef<AbortController | null>(null);
  const lastMsgRef = useRef<{ message: string; language: "en" | "bn" } | null>(null);

  useEffect(() => {
    let cancelled = false;
    if (!sessionId) {
      setState({ status: "idle" });
      return;
    }
    setState({ status: "idle" });
    (async () => {
      try {
        const { data } = await supabase
          .from("sessions")
          .select("visualization")
          .eq("id", sessionId)
          .maybeSingle();
        if (cancelled) return;
        const v = normalizeViz((data as any)?.visualization);
        if (v) setState({ status: "ready", viz: v });
      } catch {
        // Column may not exist yet, or network blip — leave as idle so the
        // first turn can still trigger generation.
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [sessionId]);

  const generate = useCallback(
    async (message: string, language: "en" | "bn" = "en", regenerate = false) => {
      if (!sessionId) return;
      lastMsgRef.current = { message, language };

      abortRef.current?.abort();
      const ctl = new AbortController();
      abortRef.current = ctl;

      setState({ status: "loading" });
      try {
        const { data: sess } = await supabase.auth.getSession();
        const token = sess.session?.access_token;
        const resp = await fetch(VIZ_URL, {
          method: "POST",
          headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
          body: JSON.stringify({ sessionId, message, language, regenerate }),
          signal: ctl.signal,
        });
        const json = await resp.json().catch(() => null);
        if (!resp.ok || !json?.ok) {
          setState({ status: "error", error: json?.error || `Visualizer failed (${resp.status})` });
          return;
        }
        const viz = normalizeViz(json.viz);
        if (!viz) {
          setState({ status: "error", error: "Visualizer returned malformed sketch" });
          return;
        }
        setState({ status: "ready", viz });
      } catch (e: any) {
        if (e?.name === "AbortError") return;
        setState({ status: "error", error: e?.message || "Network error" });
      } finally {
        if (abortRef.current === ctl) abortRef.current = null;
      }
    },
    [sessionId]
  );

  const retry = useCallback(() => {
    const last = lastMsgRef.current;
    if (last) generate(last.message, last.language, true);
  }, [generate]);

  return { state, generate, retry };
}
