import { useEffect, useRef, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { buildSrcDoc } from "@/components/VisualizationPanel";
import { sanitizeP5Code } from "@/lib/p5-sanitize";

const REPAIR_URL = `${import.meta.env.VITE_API_URL}/api/visualize/repair`;

const PREFLIGHT_TIMEOUT_MS = 3000;
const REPAIR_TIMEOUT_MS = 20000;

export type PreflightStatus =
  | { kind: "checking" }
  | { kind: "repairing"; error: string }
  | { kind: "ready"; code: string; repaired: boolean }
  | { kind: "failed"; error: string };

interface PreflightAttempt {
  code: string;
  resolve: (ok: true | { error: string }) => void;
  nonce: string;
  iframe: HTMLIFrameElement;
  onMessage: (e: MessageEvent) => void;
  timer: number;
}

function runPreflight(code: string): Promise<true | { error: string }> {
  return new Promise((resolve) => {
    const nonce = `pf_${Math.random().toString(36).slice(2)}_${Date.now().toString(36)}`;
    const iframe = document.createElement("iframe");
    iframe.setAttribute("sandbox", "allow-scripts");
    iframe.setAttribute("aria-hidden", "true");
    iframe.style.cssText =
      "position:absolute;width:600px;height:460px;left:-10000px;top:-10000px;border:0;visibility:hidden;pointer-events:none;";
    iframe.srcdoc = buildSrcDoc(code, nonce);

    let settled = false;
    const cleanup = () => {
      window.removeEventListener("message", onMessage);
      window.clearTimeout(attempt.timer);
      try { iframe.remove(); } catch (_) { /* noop */ }
    };
    const finish = (result: true | { error: string }) => {
      if (settled) return;
      settled = true;
      cleanup();
      resolve(result);
    };

    const onMessage = (e: MessageEvent) => {
      const data = e.data as { type?: string; nonce?: string; message?: string } | null;
      if (!data || data.nonce !== nonce) return;
      if (data.type === "viz-error") finish({ error: data.message || "Unknown sketch error" });
      else if (data.type === "viz-ready") finish(true);
    };
    const timer = window.setTimeout(() => finish(true), PREFLIGHT_TIMEOUT_MS);

    const attempt: PreflightAttempt = { code, resolve, nonce, iframe, onMessage, timer };
    window.addEventListener("message", onMessage);
    document.body.appendChild(iframe);
  });
}

async function repairCode(
  sessionId: string,
  code: string,
  errorMessage: string,
  signal: AbortSignal,
): Promise<{ ok: true; code: string } | { ok: false; error: string }> {
  const ctl = new AbortController();
  const onAbort = () => ctl.abort();
  signal.addEventListener("abort", onAbort);
  const timeout = window.setTimeout(() => ctl.abort(), REPAIR_TIMEOUT_MS);
  try {
    const { data: sess } = await supabase.auth.getSession();
    const token = sess.session?.access_token;
    const resp = await fetch(REPAIR_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
      body: JSON.stringify({ sessionId, code, errorMessage }),
      signal: ctl.signal,
    });
    const json = (await resp.json().catch(() => null)) as { ok?: boolean; p5_code?: string; error?: string } | null;
    if (!resp.ok || !json?.ok || typeof json.p5_code !== "string" || json.p5_code.trim().length === 0) {
      return { ok: false, error: json?.error || `Repair failed (${resp.status})` };
    }
    return { ok: true, code: json.p5_code };
  } catch (e: any) {
    if (e?.name === "AbortError") return { ok: false, error: "Repair aborted" };
    return { ok: false, error: e?.message || "Repair network error" };
  } finally {
    window.clearTimeout(timeout);
    signal.removeEventListener("abort", onAbort);
  }
}

/**
 * Runs the LLM-generated p5 sketch in a hidden preflight iframe before
 * exposing it to the user. If the preflight catches a runtime error within
 * ~1.5s, sends the broken code + error to /api/visualize/repair for one
 * automatic LLM-driven fix attempt, then preflights the repaired code once.
 *
 * Returns the validated code (original or repaired). Bumping `attemptKey`
 * (e.g. on the user's manual Retry) re-runs the whole flow.
 */
export function useP5Preflight(
  sessionId: string | undefined,
  rawCode: string | null,
  attemptKey: number,
): PreflightStatus {
  const [status, setStatus] = useState<PreflightStatus>({ kind: "checking" });
  const abortRef = useRef<AbortController | null>(null);

  useEffect(() => {
    abortRef.current?.abort();
    if (!rawCode || !sessionId) {
      setStatus({ kind: "checking" });
      return;
    }

    const ctl = new AbortController();
    abortRef.current = ctl;

    const sanitized = sanitizeP5Code(rawCode);
    if (sanitized.ok === false) {
      setStatus({ kind: "failed", error: sanitized.error });
      return;
    }
    const cleanCode = sanitized.code;

    setStatus({ kind: "checking" });
    let cancelled = false;

    (async () => {
      const first = await runPreflight(cleanCode);
      if (cancelled || ctl.signal.aborted) return;
      if (first === true) {
        setStatus({ kind: "ready", code: cleanCode, repaired: false });
        return;
      }

      setStatus({ kind: "repairing", error: first.error });
      const repair = await repairCode(sessionId, cleanCode, first.error, ctl.signal);
      if (cancelled || ctl.signal.aborted) return;
      if (!repair.ok) {
        setStatus({ kind: "failed", error: `${first.error} (repair: ${repair.error})` });
        return;
      }

      const repairedSanitized = sanitizeP5Code(repair.code);
      if (repairedSanitized.ok === false) {
        setStatus({ kind: "failed", error: `Repair returned invalid code: ${repairedSanitized.error}` });
        return;
      }

      const second = await runPreflight(repairedSanitized.code);
      if (cancelled || ctl.signal.aborted) return;
      if (second === true) {
        setStatus({ kind: "ready", code: repairedSanitized.code, repaired: true });
      } else {
        setStatus({ kind: "failed", error: `Sketch still broken after one repair: ${second.error}` });
      }
    })();

    return () => {
      cancelled = true;
      ctl.abort();
    };
  }, [sessionId, rawCode, attemptKey]);

  return status;
}
