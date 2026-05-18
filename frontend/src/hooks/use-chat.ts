import { useCallback, useEffect, useRef, useState } from "react";
import { supabase } from "@/integrations/supabase/client";

const FN_URL = `${import.meta.env.VITE_API_URL}/api/tutor`;

export interface UIMessage {
  id: string;
  role: "user" | "assistant";
  content: string;
  image_url?: string | null;
  sub_skill_id?: string | null;
  sub_skill_name?: string;
  difficulty?: string;
  sanitized?: boolean;
  diagnosed_error?: string;
  subgoal?: string;
  feedback?: "got_it" | "confused" | "more_help" | null;
  pending?: boolean;
}

export async function uploadProblemImage(
  userId: string,
  sessionId: string,
  file: File
): Promise<string | undefined> {
  const path = `${userId}/${sessionId}/${Date.now()}-${file.name}`;
  const { error: upErr } = await supabase.storage.from("problem-images").upload(path, file);
  if (upErr) return undefined;
  const { data: signed } = await supabase.storage.from("problem-images").createSignedUrl(path, 3600);
  return signed?.signedUrl;
}

export function useChat(sessionId: string | undefined) {
  const [messages, setMessages] = useState<UIMessage[]>([]);
  const [loading, setLoading] = useState(false);
  const [streaming, setStreaming] = useState(false);
  const abortRef = useRef<AbortController | null>(null);

  const refresh = useCallback(async () => {
    if (!sessionId) return;
    setLoading(true);
    const { data } = await supabase
      .from("messages")
      .select("id, role, content, image_url, sub_skill_id, was_sanitized, feedback, sub_skill:sub_skills(name)")
      .eq("session_id", sessionId)
      .order("created_at", { ascending: true });
    setMessages(
      ((data as any) || []).map((m: any) => ({
        id: m.id,
        role: m.role,
        content: m.content,
        image_url: m.image_url,
        sub_skill_id: m.sub_skill_id,
        sub_skill_name: m.sub_skill?.name,
        sanitized: m.was_sanitized,
        feedback: m.feedback,
      }))
    );
    setLoading(false);
  }, [sessionId]);

  useEffect(() => { refresh(); }, [refresh]);

  const send = useCallback(
    async (text: string, imageUrl?: string, language: "en" | "bn" = "en") => {
      if (!sessionId) return;
      const { data: u } = await supabase.auth.getUser();
      if (!u.user) return;

      // optimistic user message
      const tempUser: UIMessage = {
        id: `temp-${Date.now()}`,
        role: "user",
        content: text,
        image_url: imageUrl,
        pending: true,
      };
      const tempAsst: UIMessage = {
        id: `temp-asst-${Date.now()}`,
        role: "assistant",
        content: "",
        pending: true,
      };
      setMessages((prev) => [...prev, tempUser, tempAsst]);
      setStreaming(true);

      const ctl = new AbortController();
      abortRef.current = ctl;

      try {
        const { data: sess } = await supabase.auth.getSession();
        const token = sess.session?.access_token;
        const resp = await fetch(FN_URL, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({ sessionId, message: text, imageUrl, language }),
          signal: ctl.signal,
        });

        if (!resp.ok || !resp.body) {
          const t = await resp.text();
          throw new Error(t || "Failed");
        }

        const reader = resp.body.getReader();
        const dec = new TextDecoder();
        let buf = "";
        let asstText = "";
        let meta: any = null;

        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          buf += dec.decode(value, { stream: true });
          let nl: number;
          while ((nl = buf.indexOf("\n")) !== -1) {
            let line = buf.slice(0, nl);
            buf = buf.slice(nl + 1);
            if (line.endsWith("\r")) line = line.slice(0, -1);
            if (!line.startsWith("data: ")) continue;
            const json = line.slice(6).trim();
            if (json === "[DONE]") continue;
            try {
              const p = JSON.parse(json);
              if (p.meta) {
                meta = p.meta;
                setMessages((prev) =>
                  prev.map((m) =>
                    m.id === tempAsst.id
                      ? {
                          ...m,
                          sub_skill_id: meta.sub_skill_id,
                          sub_skill_name: meta.sub_skill_name,
                          difficulty: meta.difficulty,
                          sanitized: meta.sanitized,
                          diagnosed_error: meta.diagnosed_error,
                          subgoal: meta.subgoal,
                        }
                      : m
                  )
                );
              }
              const d = p.choices?.[0]?.delta?.content;
              if (d) {
                asstText += d;
                setMessages((prev) =>
                  prev.map((m) => (m.id === tempAsst.id ? { ...m, content: asstText } : m))
                );
              }
            } catch { /* partial */ }
          }
        }
      } catch (e: any) {
        if (e.name !== "AbortError") {
          setMessages((prev) =>
            prev.map((m) =>
              m.id === tempAsst.id ? { ...m, content: "Sorry — that request failed. Please try again." } : m
            )
          );
        }
      } finally {
        setStreaming(false);
        abortRef.current = null;
        // re-sync from DB to get real ids
        setTimeout(refresh, 600);
      }
    },
    [sessionId, refresh]
  );

  const giveFeedback = useCallback(
    async (msg: UIMessage, fb: "got_it" | "confused" | "more_help") => {
      // optimistic UI
      setMessages((prev) => prev.map((m) => (m.id === msg.id ? { ...m, feedback: fb } : m)));
      if (msg.id.startsWith("temp-")) return;
      await supabase.from("messages").update({ feedback: fb }).eq("id", msg.id);

      // update knowledge_state via BKT
      if (!msg.sub_skill_id) return;
      const { data: u } = await supabase.auth.getUser();
      if (!u.user) return;

      const { data: existing } = await supabase
        .from("knowledge_state")
        .select("*")
        .eq("user_id", u.user.id)
        .eq("sub_skill_id", msg.sub_skill_id)
        .maybeSingle();

      const cur = existing
        ? {
            mastery: Number(existing.mastery),
            attempts: existing.attempts,
            correct: existing.correct,
            error_tags: existing.error_tags ?? [],
          }
        : { mastery: 0.3, attempts: 0, correct: 0, error_tags: [] as string[] };

      const isCorrect = fb === "got_it";
      const pLearn = 0.1, pGuess = 0.2, pSlip = 0.1;
      let pM = cur.mastery;
      if (isCorrect) {
        const post = (pM * (1 - pSlip)) / (pM * (1 - pSlip) + (1 - pM) * pGuess);
        pM = post + (1 - post) * pLearn;
      } else {
        const post = (pM * pSlip) / (pM * pSlip + (1 - pM) * (1 - pGuess));
        pM = post + (1 - post) * pLearn;
      }

      const newTags = new Set(cur.error_tags);
      if (fb === "confused" && msg.diagnosed_error) {
        newTags.add(msg.diagnosed_error.slice(0, 40));
      }

      const payload = {
        user_id: u.user.id,
        sub_skill_id: msg.sub_skill_id,
        mastery: Math.min(Math.max(pM, 0), 1),
        attempts: cur.attempts + 1,
        correct: cur.correct + (isCorrect ? 1 : 0),
        error_tags: Array.from(newTags),
        last_practiced_at: new Date().toISOString(),
      };
      await supabase.from("knowledge_state").upsert(payload, { onConflict: "user_id,sub_skill_id" });
    },
    []
  );

  const adjustMastery = useCallback(
    async (subSkillId: string, delta: number) => {
      const { data: u } = await supabase.auth.getUser();
      if (!u.user) return;
      const { data: existing } = await supabase
        .from("knowledge_state")
        .select("*")
        .eq("user_id", u.user.id)
        .eq("sub_skill_id", subSkillId)
        .maybeSingle();
      const cur = existing
        ? { mastery: Number(existing.mastery), attempts: existing.attempts, correct: existing.correct, error_tags: existing.error_tags ?? [] }
        : { mastery: 0.3, attempts: 0, correct: 0, error_tags: [] as string[] };
      const newM = Math.min(Math.max(cur.mastery + delta, 0), 1);
      await supabase.from("knowledge_state").upsert(
        {
          user_id: u.user.id,
          sub_skill_id: subSkillId,
          mastery: newM,
          attempts: cur.attempts,
          correct: cur.correct,
          error_tags: cur.error_tags,
          last_practiced_at: new Date().toISOString(),
        },
        { onConflict: "user_id,sub_skill_id" }
      );
      return newM;
    },
    []
  );

  return { messages, loading, streaming, send, giveFeedback, adjustMastery, refresh };
}
