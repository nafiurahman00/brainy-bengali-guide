import { useEffect, useRef, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { AppHeader } from "@/components/AppHeader";
import { InkButton } from "@/components/InkButton";
import { useLang } from "@/contexts/LangContext";
import { t } from "@/lib/i18n";
import ReactMarkdown from "react-markdown";
import remarkMath from "remark-math";
import rehypeKatex from "rehype-katex";
import { ImageIcon, X, Plus, Minus, RotateCcw, Send, Sparkles, LogIn } from "lucide-react";
import { toast } from "sonner";

const FN_URL = `${import.meta.env.VITE_API_URL}/api/tutor`;

interface Subject { id: string; slug: string; name: string; name_bn: string | null; }

interface UIMessage {
  id: string;
  role: "user" | "assistant";
  content: string;
  image_url?: string;
  sub_skill_slug?: string;
  sub_skill_name?: string;
  difficulty?: string;
  sanitized?: boolean;
  diagnosed_error?: string;
  subgoal?: string;
}

interface Fluency {
  mastery: number;
  attempts: number;
  correct: number;
  error_tags: string[];
  name?: string;
}

export default function GuestSession() {
  const { lang } = useLang();
  const T = t(lang);
  const nav = useNavigate();

  const [subjects, setSubjects] = useState<Subject[]>([]);
  const [subject, setSubject] = useState<Subject | null>(null);
  const [messages, setMessages] = useState<UIMessage[]>([]);
  const [scratchpad, setScratchpad] = useState<any>({ goal: null, summary: "", turn: 0 });
  const [fluency, setFluency] = useState<Record<string, Fluency>>({});
  const [input, setInput] = useState("");
  const [image, setImage] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [streaming, setStreaming] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    supabase.from("subjects").select("*").order("sort_order").then(({ data }) => {
      const list = data || [];
      setSubjects(list);
      if (list.length && !subject) setSubject(list[0]);
    });
  }, []);

  useEffect(() => {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight, behavior: "smooth" });
  }, [messages, streaming]);

  const subjectName = (s?: Subject | null) => s ? (lang === "bn" && s.name_bn ? s.name_bn : s.name) : "";

  const handleImage = (f: File) => {
    if (f.size > 5 * 1024 * 1024) { toast.error("Image too large (max 5MB)"); return; }
    setImage(f);
    setImagePreview(URL.createObjectURL(f));
  };

  // Convert image file to base64 data URL (no storage in guest mode)
  const fileToDataUrl = (f: File): Promise<string> =>
    new Promise((res, rej) => {
      const r = new FileReader();
      r.onload = () => res(r.result as string);
      r.onerror = rej;
      r.readAsDataURL(f);
    });

  const send = async () => {
    if (!subject) { toast.error(T.pickSubject); return; }
    if (!input.trim() && !image) return;
    const text = input.trim() || "[image submitted]";
    const f = image;
    setInput("");
    setImage(null);
    setImagePreview(null);

    let imageUrl: string | undefined;
    if (f) imageUrl = await fileToDataUrl(f);

    const userMsg: UIMessage = {
      id: `u-${Date.now()}`,
      role: "user",
      content: text,
      image_url: imageUrl,
    };
    const asstId = `a-${Date.now()}`;
    const asstMsg: UIMessage = { id: asstId, role: "assistant", content: "" };
    setMessages((p) => [...p, userMsg, asstMsg]);
    setStreaming(true);

    try {
      const resp = await fetch(FN_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          guest: true,
          message: text,
          imageUrl,
          language: lang,
          subjectSlug: subject.slug,
          fluency,
          scratchpad,
        }),
      });
      if (!resp.ok || !resp.body) {
        const errText = await resp.text();
        throw new Error(errText || "Failed");
      }
      const reader = resp.body.getReader();
      const dec = new TextDecoder();
      let buf = "";
      let asstText = "";
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
              if (p.meta.scratchpad) setScratchpad(p.meta.scratchpad);
              userMsg.sanitized = p.meta.sanitized;
              setMessages((prev) =>
                prev.map((m) =>
                  m.id === asstId
                    ? {
                        ...m,
                        sub_skill_slug: p.meta.sub_skill_slug,
                        sub_skill_name: p.meta.sub_skill_name,
                        difficulty: p.meta.difficulty,
                        diagnosed_error: p.meta.diagnosed_error,
                        subgoal: p.meta.subgoal,
                      }
                    : m.id === userMsg.id
                      ? { ...m, sanitized: p.meta.sanitized }
                      : m
                )
              );
              // ensure fluency entry exists for this skill
              const slug = p.meta.sub_skill_slug;
              if (slug) {
                setFluency((prev) =>
                  prev[slug]
                    ? prev
                    : {
                        ...prev,
                        [slug]: {
                          mastery: 0.3,
                          attempts: 0,
                          correct: 0,
                          error_tags: [],
                          name: p.meta.sub_skill_name,
                        },
                      }
                );
              }
            }
            const d = p.choices?.[0]?.delta?.content;
            if (d) {
              asstText += d;
              setMessages((prev) =>
                prev.map((m) => (m.id === asstId ? { ...m, content: asstText } : m))
              );
            }
          } catch { /* partial */ }
        }
      }
    } catch (e: any) {
      setMessages((prev) =>
        prev.map((m) => (m.id === asstId ? { ...m, content: "Sorry — that request failed. Please try again." } : m))
      );
    } finally {
      setStreaming(false);
    }
  };

  const giveFeedback = (msg: UIMessage, fb: "got_it" | "confused") => {
    if (!msg.sub_skill_slug) return;
    const slug = msg.sub_skill_slug;
    setFluency((prev) => {
      const cur = prev[slug] ?? { mastery: 0.3, attempts: 0, correct: 0, error_tags: [], name: msg.sub_skill_name };
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
      if (!isCorrect && msg.diagnosed_error) newTags.add(msg.diagnosed_error.slice(0, 40));
      return {
        ...prev,
        [slug]: {
          ...cur,
          mastery: Math.min(Math.max(pM, 0), 1),
          attempts: cur.attempts + 1,
          correct: cur.correct + (isCorrect ? 1 : 0),
          error_tags: Array.from(newTags),
          name: msg.sub_skill_name ?? cur.name,
        },
      };
    });
  };

  const adjustMastery = (slug: string, delta: number) => {
    setFluency((prev) => {
      const cur = prev[slug] ?? { mastery: 0.3, attempts: 0, correct: 0, error_tags: [] };
      return {
        ...prev,
        [slug]: { ...cur, mastery: Math.min(Math.max(cur.mastery + delta, 0), 1) },
      };
    });
  };

  const resetMastery = (slug: string) => {
    setFluency((prev) => {
      const cur = prev[slug];
      if (!cur) return prev;
      return { ...prev, [slug]: { ...cur, mastery: 0.3 } };
    });
  };

  const lastAssistantId = [...messages].reverse().find((m) => m.role === "assistant" && m.content)?.id;
  const lastAssistant = messages.filter((m) => m.role === "assistant" && m.content).slice(-1)[0];

  return (
    <div className="h-[100dvh] w-full overflow-hidden flex flex-col">
      <AppHeader />

      <div className="shrink-0 border-b border-[hsl(var(--hairline))] bg-[hsl(var(--muted))]">
        <div className="max-w-[1280px] mx-auto px-4 sm:px-6 py-2.5 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 sm:gap-4 text-[12px]">
          <span className="font-medium text-[hsl(var(--ink-muted))]">
            ✦ {T.guestNotice}
          </span>
          <Link to="/auth" className="inline-flex items-center gap-1.5 text-[12px] font-medium text-[hsl(var(--ink))] hover:underline">
            <LogIn className="h-3.5 w-3.5" /> {T.saveProgress} →
          </Link>
        </div>
      </div>

      <div className="shrink-0 border-b border-[hsl(var(--hairline))] bg-[hsl(var(--paper))]">
        <div className="max-w-[1280px] mx-auto px-4 sm:px-6 py-3 flex items-center gap-3 flex-wrap">
          <p className="text-[12px] font-medium text-[hsl(var(--ink-muted))]">{T.pickSubject}:</p>
          {subjects.map((s) => (
            <button
              key={s.id}
              onClick={() => setSubject(s)}
              className={`text-[12px] font-medium px-3 h-8 rounded-lg border transition-all ${
                subject?.id === s.id
                  ? "bg-[hsl(var(--ink))] text-[hsl(var(--background))] border-[hsl(var(--ink))] shadow-sm"
                  : "border-[hsl(var(--hairline))] text-[hsl(var(--ink-muted))] hover:border-[hsl(var(--ink))] hover:text-[hsl(var(--ink))]"
              }`}
            >
              {subjectName(s)}
            </button>
          ))}
        </div>
      </div>

      <main className="flex-1 max-w-[1280px] w-full mx-auto px-4 sm:px-6 py-4 sm:py-6 grid grid-cols-1 lg:grid-cols-12 gap-6 min-h-0 overflow-hidden">
        <section className="lg:col-span-8 flex flex-col min-h-0 h-full">
          <div ref={scrollRef} className="flex-1 overflow-y-auto pr-2 space-y-6">
            {messages.length === 0 && (
              <div className="flex flex-col items-center justify-center h-full min-h-[40vh] text-center px-8">
                <div className="w-16 h-16 rounded-2xl bg-[hsl(var(--ink))] flex items-center justify-center mb-5 shadow-surface-md">
                  <Sparkles className="h-7 w-7 text-[hsl(var(--background))]" />
                </div>
                <p className="text-[12px] font-medium text-[hsl(var(--ink-muted))] mb-2">Guest mode</p>
                <p className="text-[15px] text-[hsl(var(--ink-muted))] max-w-sm leading-relaxed">
                  Type a problem below — or attach a screenshot.<br />
                  <span className="text-[hsl(var(--ink-faint))] text-[13px]">Your tutor will respond with a question, never the answer.</span>
                </p>
              </div>
            )}
            {messages.map((m, i) => (
              <Bubble
                key={m.id}
                msg={m}
                lang={lang}
                index={i}
                isLastAssistant={m.id === lastAssistantId}
                onFeedback={(fb) => giveFeedback(m, fb)}
              />
            ))}
            {streaming && messages[messages.length - 1]?.role === "assistant" && !messages[messages.length - 1]?.content && (
              <Thinking />
            )}
          </div>

          <div className="border-t border-[hsl(var(--hairline))] pt-4 mt-4">
            {imagePreview && (
              <div className="mb-3 inline-flex items-center gap-2 rounded-xl border border-[hsl(var(--hairline))] p-2 bg-[hsl(var(--muted))]">
                <img src={imagePreview} alt="preview" className="h-14 w-14 object-cover rounded-lg" />
                <button onClick={() => { setImage(null); setImagePreview(null); }} className="p-1 rounded-md hover:bg-[hsl(var(--paper))] transition-colors">
                  <X className="h-4 w-4" />
                </button>
              </div>
            )}
            <div className="rounded-xl border border-[hsl(var(--hairline))] bg-[hsl(var(--paper))] flex items-end gap-2 p-3 shadow-surface focus-within:border-[hsl(var(--ink))] focus-within:shadow-glow transition-all">
              <label className="cursor-pointer p-2 rounded-lg hover:bg-[hsl(var(--muted))] shrink-0 transition-colors" title="Attach image">
                <ImageIcon className="h-4 w-4 text-[hsl(var(--ink-muted))]" />
                <input type="file" accept="image/*" hidden onChange={(e) => e.target.files?.[0] && handleImage(e.target.files[0])} />
              </label>
              <textarea
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); send(); }
                }}
                placeholder={T.askAnything}
                rows={2}
                className="flex-1 resize-none bg-transparent outline-none text-[14px] py-2 px-1 max-h-40 leading-relaxed"
                disabled={streaming}
              />
              <button
                onClick={send}
                disabled={streaming || (!input.trim() && !image)}
                className="shrink-0 w-9 h-9 rounded-lg bg-[hsl(var(--ink))] text-[hsl(var(--background))] flex items-center justify-center disabled:opacity-30 hover:opacity-80 active:scale-95 transition-all"
              >
                <Send className="h-4 w-4" />
              </button>
            </div>
            <p className="mt-2 text-[11px] text-[hsl(var(--ink-faint))] pl-1">Enter to send · Shift+Enter for newline</p>
          </div>
        </section>

        <aside className="lg:col-span-4 border-t border-[hsl(var(--hairline))] lg:border-t-0 lg:border-l lg:border-[hsl(var(--hairline))] pt-6 lg:pt-0 lg:pl-6 space-y-8 overflow-y-auto h-full pr-2">
          <div>
            <p className="text-[11px] font-medium text-[hsl(var(--ink-muted))] tracking-wide mb-3 uppercase">Pipeline · Last Turn</p>
            {lastAssistant ? (
              <dl className="space-y-3 text-[13px]">
                <Row k={T.targetSkill} v={lastAssistant.sub_skill_name || "—"} />
                <Row k="Difficulty" v={lastAssistant.difficulty || "—"} />
                <Row k={T.diagnosis} v={lastAssistant.diagnosed_error || "—"} multiline />
                <Row k={T.subgoal} v={lastAssistant.subgoal || "—"} multiline />
              </dl>
            ) : (
              <p className="text-[13px] text-[hsl(var(--ink-muted))]">No turns yet.</p>
            )}
          </div>

          <div>
            <p className="text-[11px] font-medium text-[hsl(var(--ink-muted))] tracking-wide mb-3 uppercase">Session Mastery</p>
            {Object.keys(fluency).length === 0 ? (
              <p className="text-[13px] text-[hsl(var(--ink-muted))]">{T.noPractice}</p>
            ) : (
              <ul className="space-y-5">
                {Object.entries(fluency).map(([slug, f]) => (
                  <li key={slug}>
                    <div className="flex items-baseline justify-between gap-3 mb-1.5">
                      <div className="text-[14px] font-medium truncate">{f.name || slug}</div>
                      <div className="font-mono text-[12px] font-semibold text-[hsl(var(--ink))]">
                        {Math.round(f.mastery * 100)}%
                      </div>
                    </div>
                    <div className="bar-track">
                      <div className="bar-fill" style={{ width: `${Math.round(f.mastery * 100)}%` }} />
                    </div>
                    <div className="mt-2 flex items-center gap-1.5">
                      <button
                        onClick={() => adjustMastery(slug, -0.1)}
                        className="rounded-md border border-[hsl(var(--hairline))] h-7 w-7 flex items-center justify-center hover:border-[hsl(var(--ink))] hover:text-[hsl(var(--ink))] transition-colors"
                        title={T.decrease}
                      >
                        <Minus className="h-3 w-3" />
                      </button>
                      <button
                        onClick={() => adjustMastery(slug, 0.1)}
                        className="rounded-md border border-[hsl(var(--hairline))] h-7 w-7 flex items-center justify-center hover:border-[hsl(var(--ink))] hover:text-[hsl(var(--ink))] transition-colors"
                        title={T.increase}
                      >
                        <Plus className="h-3 w-3" />
                      </button>
                      <button
                        onClick={() => resetMastery(slug)}
                        className="rounded-md border border-[hsl(var(--hairline))] h-7 px-2 flex items-center gap-1 text-[10px] font-medium hover:border-[hsl(var(--ink))] hover:text-[hsl(var(--ink))] transition-colors"
                        title={T.reset}
                      >
                        <RotateCcw className="h-2.5 w-2.5" /> {T.reset}
                      </button>
                      <span className="font-mono text-[10px] text-[hsl(var(--ink-faint))] ml-auto">
                        {f.attempts} {T.attempts}
                      </span>
                    </div>
                  </li>
                ))}
              </ul>
            )}
          </div>
        </aside>
      </main>
    </div>
  );
}

function Bubble({
  msg, lang, index, isLastAssistant, onFeedback,
}: {
  msg: UIMessage; lang: "en" | "bn"; index: number;
  isLastAssistant: boolean;
  onFeedback: (fb: "got_it" | "confused") => void;
}) {
  const T = t(lang);
  const isUser = msg.role === "user";

  if (isUser) {
    return (
      <div className="flex flex-col items-end gap-1.5 animate-[inkFade_0.25s_ease-out]">
        <div className="flex items-center gap-2">
          {msg.sanitized && (
            <span className="text-[10px] font-medium text-[hsl(var(--warning))] bg-[hsl(var(--warning))]/10 rounded-md px-2 py-0.5">
              ⚠ {T.sanitized}
            </span>
          )}
          <span className="text-[11px] font-medium text-[hsl(var(--ink-muted))]">you</span>
        </div>
        {msg.image_url && (
          <img src={msg.image_url} alt="problem" className="rounded-xl max-h-56 border border-[hsl(var(--hairline))]" />
        )}
        <div className={`prose-chat bg-[hsl(var(--ink))] text-[hsl(var(--background))] px-4 py-3 rounded-2xl rounded-tr-md max-w-[78%] ${lang === "bn" ? "bn" : ""}`}>
          <ReactMarkdown remarkPlugins={[remarkMath]} rehypePlugins={[rehypeKatex]}>
            {msg.content}
          </ReactMarkdown>
        </div>
      </div>
    );
  }

  return (
    <div className="flex gap-3 animate-[inkFade_0.25s_ease-out]">
      <div className="shrink-0 w-8 h-8 rounded-lg bg-[hsl(var(--ink))] flex items-center justify-center mt-1">
        <span className="text-[hsl(var(--background))] text-[11px] font-bold">AI</span>
      </div>
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2 mb-2">
          <span className="text-[11px] font-medium text-[hsl(var(--ink-muted))]">tutor</span>
          {msg.difficulty && (
            <span className="text-[10px] font-medium text-[hsl(var(--ink-muted))] bg-[hsl(var(--muted))] rounded-md px-1.5 py-0.5">{msg.difficulty}</span>
          )}
        </div>
        {msg.image_url && (
          <img src={msg.image_url} alt="problem" className="rounded-xl max-h-56 mb-2 border border-[hsl(var(--hairline))]" />
        )}
        <div className={`prose-chat bg-[hsl(var(--paper))] border border-[hsl(var(--hairline))] px-4 py-3 rounded-2xl rounded-tl-md ${lang === "bn" ? "bn" : ""}`}>
          {msg.content ? (
            <ReactMarkdown remarkPlugins={[remarkMath]} rehypePlugins={[rehypeKatex]}>
              {msg.content}
            </ReactMarkdown>
          ) : (
            <span className="text-[hsl(var(--ink-faint))]">…</span>
          )}
        </div>
        {isLastAssistant && msg.content && (
          <div className="mt-3 flex flex-wrap gap-2">
            {(["got_it", "confused"] as const).map((fb) => {
              const labels = { got_it: T.gotIt, confused: T.confused };
              const icons = { got_it: "✓", confused: "?" };
              return (
                <button
                  key={fb}
                  onClick={() => onFeedback(fb)}
                  className="text-[11px] font-medium px-3 h-8 rounded-lg border border-[hsl(var(--hairline))] text-[hsl(var(--ink-muted))] hover:border-[hsl(var(--ink))] hover:text-[hsl(var(--ink))] transition-all"
                >
                  {icons[fb]} {labels[fb]}
                </button>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}

function Thinking() {
  return (
    <div className="flex gap-3">
      <div className="shrink-0 w-8 h-8 rounded-lg bg-[hsl(var(--ink))] flex items-center justify-center">
        <span className="text-[hsl(var(--background))] text-[11px] font-bold">AI</span>
      </div>
      <div className="flex gap-2 items-center py-3 px-4 bg-[hsl(var(--paper))] border border-[hsl(var(--hairline))] rounded-2xl rounded-tl-md">
        <span className="thinking-dot h-2 w-2 bg-[hsl(var(--ink-faint))] rounded-full" />
        <span className="thinking-dot h-2 w-2 bg-[hsl(var(--ink-faint))] rounded-full" />
        <span className="thinking-dot h-2 w-2 bg-[hsl(var(--ink-faint))] rounded-full" />
      </div>
    </div>
  );
}

function Row({ k, v, multiline }: { k: string; v: string; multiline?: boolean }) {
  return (
    <div>
      <dt className="text-[12px] font-medium text-[hsl(var(--ink-muted))]">{k}</dt>
      <dd className={`mt-0.5 ${multiline ? "" : "truncate"}`}>{v}</dd>
    </div>
  );
}
