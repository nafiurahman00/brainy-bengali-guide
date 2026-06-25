import { useCallback, useEffect, useRef, useState } from "react";
import { supabase } from "@/integrations/supabase/client";

const VIZ_URL = `${import.meta.env.VITE_API_URL}/api/visualize`;

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

/** Planner context passed from the latest tutor turn so the sketch is relevant. */
export interface VizContext {
  concept?: string;
  subSkillSlug?: string;
  subSkillName?: string;
  diagnosedError?: string;
  difficulty?: string;
  subgoal?: string;
  cleanedProblem?: string;
}

export type VizLens = "another" | "simpler";

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

/** Read the active sketch out of the keyed store (or legacy single-object shape). */
function pickActiveViz(raw: any): { viz: Visualization | null; activeKey: string } {
  if (raw && typeof raw === "object" && raw.items && typeof raw.items === "object") {
    const active = typeof raw.active === "string" && raw.items[raw.active] ? raw.active : Object.keys(raw.items)[0] ?? "";
    return { viz: normalizeViz(raw.items[active]), activeKey: active };
  }
  return { viz: normalizeViz(raw), activeKey: "default" };
}

export function useVisualization(sessionId: string | undefined) {
  const [state, setState] = useState<VizState>({ status: "idle" });
  const abortRef = useRef<AbortController | null>(null);
  const lastReqRef = useRef<{ message: string; language: "en" | "bn"; imageUrl?: string; ctx?: VizContext } | null>(null);
  // Which conversational focus the currently-shown sketch belongs to.
  const focusRef = useRef<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    if (!sessionId) {
      setState({ status: "idle" });
      return;
    }
    setState({ status: "idle" });
    focusRef.current = null;
    (async () => {
      try {
        const { data } = await supabase
          .from("sessions")
          .select("visualization")
          .eq("id", sessionId)
          .maybeSingle();
        if (cancelled) return;
        const { viz, activeKey } = pickActiveViz((data as any)?.visualization);
        if (viz) {
          focusRef.current = activeKey;
          setState({ status: "ready", viz });
        }
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
    async (
      message: string,
      language: "en" | "bn" = "en",
      imageUrl?: string,
      regenerate = false,
      ctx?: VizContext,
      lens?: VizLens
    ) => {
      if (!sessionId) return;
      lastReqRef.current = { message, language, imageUrl, ctx };

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
          body: JSON.stringify({ sessionId, message, language, imageUrl, regenerate, lens, ...(ctx ?? {}) }),
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

  /**
   * Generate (or reuse) a sketch for the current conversational focus. Called as
   * the conversation evolves; only fires when the focus actually changes, so a
   * new skill/concept produces a fresh, relevant sketch while staying put reuses
   * the cached one.
   */
  const ensureFor = useCallback(
    (focusKey: string | undefined, message: string, language: "en" | "bn", ctx?: VizContext) => {
      if (!focusKey) return;
      if (focusRef.current === focusKey && state.status !== "idle" && state.status !== "error") return;
      focusRef.current = focusKey;
      void generate(message, language, undefined, false, ctx);
    },
    [generate, state.status]
  );

  const retry = useCallback(() => {
    const last = lastReqRef.current;
    if (last) generate(last.message, last.language, last.imageUrl, true, last.ctx);
  }, [generate]);

  /** Re-render the same idea from a different angle or in a simpler form. */
  const vary = useCallback(
    (lens: VizLens) => {
      const last = lastReqRef.current;
      if (last) generate(last.message, last.language, last.imageUrl, true, last.ctx, lens);
    },
    [generate]
  );

  return { state, generate, ensureFor, retry, vary };
}
