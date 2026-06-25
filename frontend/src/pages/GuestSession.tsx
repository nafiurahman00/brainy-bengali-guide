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
import { ImageIcon, X, Plus, Minus, RotateCcw, Send, Sparkles, LogIn, GraduationCap, ArrowUp } from "lucide-react";
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
  const [mobileTab, setMobileTab] = useState<"chat" | "sidebar">("chat");
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
              // Sync fluency from the server's per-turn assessment (the algorithm
              // lives server-side even for guests). Falls back to ensuring an entry.
              const slug = p.meta.sub_skill_slug;
              const ku = p.meta.knowledge_update;
              if (slug && ku) {
                setFluency((prev) => ({
                  ...prev,
                  [slug]: {
                    mastery: Number(ku.mastery ?? prev[slug]?.mastery ?? 0.3),
                    attempts: Number(ku.attempts ?? prev[slug]?.attempts ?? 0),
                    correct: Number(ku.correct ?? prev[slug]?.correct ?? 0),
                    error_tags: ku.error_tags ?? prev[slug]?.error_tags ?? [],
                    name: ku.sub_skill_name ?? p.meta.sub_skill_name ?? prev[slug]?.name,
                  },
                }));
              } else if (slug) {
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
      // Secondary signal: the server already auto-assessed this turn, so the
      // manual tap only nudges mastery a fraction of the way.
      const blended = cur.mastery + 0.4 * (Math.min(Math.max(pM, 0), 1) - cur.mastery);
      const newTags = new Set(cur.error_tags);
      if (!isCorrect && msg.diagnosed_error) newTags.add(msg.diagnosed_error.slice(0, 80));
      return {
        ...prev,
        [slug]: {
          ...cur,
          mastery: Math.min(Math.max(blended, 0), 1),
          name: msg.sub_skill_name ?? cur.name,
          error_tags: Array.from(newTags),
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

      {/* Guest notice */}
      <div className="shrink-0 section-divider" style={{ background: 'var(--gradient-subtle)' }}>
        <div className="w-full px-4 sm:px-6 lg:px-8 py-2.5 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 sm:gap-4 text-[12px]">
          <span className="font-medium text-[hsl(var(--ink-muted))] flex items-center gap-1.5">
            <Sparkles className="h-3.5 w-3.5 text-[hsl(var(--primary))]" />
            {T.guestNotice}
          </span>
          <Link to="/auth" className="inline-flex items-center gap-1.5 text-[12px] font-medium text-[hsl(var(--primary))] hover:underline group">
            <LogIn className="h-3.5 w-3.5" /> {T.saveProgress}
            <ArrowUp className="h-3 w-3 rotate-45 transition-transform group-hover:translate-x-0.5 group-hover:-translate-y-0.5" />
          </Link>
        </div>
      </div>

      {/* Subject picker */}
      <div className="shrink-0 border-b border-[hsl(var(--hairline))]" style={{ background: 'hsl(var(--paper))' }}>
        <div className="w-full px-4 sm:px-6 lg:px-8 py-3 flex items-center gap-3 flex-wrap">
          <p className="text-[12px] font-semibold text-[hsl(var(--ink-muted))] uppercase tracking-wide">{T.pickSubject}:</p>
          <div className="flex gap-2 flex-wrap">
            {subjects.map((s) => (
              <button
                key={s.id}
                onClick={() => setSubject(s)}
                className={`text-[12px] font-medium px-3.5 h-8 rounded-xl border transition-all duration-200 ${
                  subject?.id === s.id
                    ? "btn-gradient text-white border-transparent shadow-sm"
                    : "border-[hsl(var(--hairline))] text-[hsl(var(--ink-muted))] hover:border-[hsl(var(--primary)/0.3)] hover:text-[hsl(var(--primary))] hover:bg-[hsl(var(--primary)/0.04)]"
                }`}
              >
                {subjectName(s)}
              </button>
            ))}
          </div>
        </div>
      </div>

      <main className="flex-1 w-full px-4 sm:px-6 lg:px-8 py-4 sm:py-6 flex flex-col lg:grid lg:grid-cols-12 gap-6 min-h-0 overflow-hidden">
        {/* Mobile Tabs */}
        <div className="lg:hidden flex rounded-xl bg-[hsl(var(--muted))] p-1 shrink-0">
          <button onClick={() => setMobileTab("chat")} className={`flex-1 py-1.5 text-[13px] font-medium rounded-lg transition-all ${mobileTab === 'chat' ? 'bg-[hsl(var(--card))] shadow-sm text-[hsl(var(--foreground))]' : 'text-[hsl(var(--ink-muted))] hover:text-[hsl(var(--foreground))]'}`}>Chat</button>
          <button onClick={() => setMobileTab("sidebar")} className={`flex-1 py-1.5 text-[13px] font-medium rounded-lg transition-all ${mobileTab === 'sidebar' ? 'bg-[hsl(var(--card))] shadow-sm text-[hsl(var(--foreground))]' : 'text-[hsl(var(--ink-muted))] hover:text-[hsl(var(--foreground))]'}`}>Session Info</button>
        </div>

        {/* Chat panel */}
        <section className={`lg:col-span-8 min-h-0 h-full flex-col ${mobileTab === 'chat' ? 'flex' : 'hidden lg:flex'}`}>
          <div ref={scrollRef} className="flex-1 overflow-y-auto pr-2 space-y-6">
            {messages.length === 0 && (
              <div className="flex flex-col items-center justify-center h-full min-h-[40vh] text-center px-8">
                <div className="hero-icon w-16 h-16 mb-6">
                  <GraduationCap className="h-7 w-7 text-white relative z-10" />
                </div>
                <p className="text-[11px] font-semibold gradient-text tracking-widest mb-3 uppercase">Guest mode</p>
                <p className="text-[16px] font-medium text-[hsl(var(--foreground))] mb-2">
                  What would you like to learn?
                </p>
                <p className="text-[14px] text-[hsl(var(--ink-muted))] max-w-sm leading-relaxed">
                  Type a problem below — or attach a screenshot.
                  <br />
                  <span className="text-[hsl(var(--ink-faint))] text-[13px]">Your tutor guides you with questions — and steps in with more help whenever you're stuck.</span>
                </p>
              </div>
            )}
            {messages.map((m) => (
              <Bubble
                key={m.id}
                msg={m}
                lang={lang}
                isLastAssistant={m.id === lastAssistantId}
                onFeedback={(fb) => giveFeedback(m, fb)}
              />
            ))}
            {streaming && messages[messages.length - 1]?.role === "assistant" && !messages[messages.length - 1]?.content && (
              <Thinking />
            )}
          </div>

          {/* Input area */}
          <div className="border-t border-[hsl(var(--hairline))] pt-4 mt-4">
            {imagePreview && (
              <div className="mb-3 inline-flex items-center gap-2 rounded-xl border border-[hsl(var(--hairline))] p-2 bg-[hsl(var(--muted))]">
                <img src={imagePreview} alt="preview" className="h-14 w-14 object-cover rounded-lg" />
                <button onClick={() => { setImage(null); setImagePreview(null); }} className="p-1.5 rounded-lg hover:bg-[hsl(var(--paper))] transition-colors">
                  <X className="h-4 w-4" />
                </button>
              </div>
            )}
            <div className="rounded-2xl border border-[hsl(var(--hairline))] bg-[hsl(var(--card))] flex items-end gap-2 p-3 shadow-surface focus-primary transition-all">
              <label className="cursor-pointer p-2 rounded-xl hover:bg-[hsl(var(--primary)/0.06)] shrink-0 transition-all" title="Attach image">
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
                className="shrink-0 w-9 h-9 rounded-xl flex items-center justify-center disabled:opacity-30 hover:shadow-md active:scale-95 transition-all text-white btn-gradient"
              >
                <Send className="h-4 w-4" />
              </button>
            </div>
            <p className="mt-2 text-[11px] text-[hsl(var(--ink-faint))] pl-1">Enter to send · Shift+Enter for newline</p>
          </div>
        </section>

        {/* Sidebar */}
        <aside className={`lg:col-span-4 border-t border-[hsl(var(--hairline))] lg:border-t-0 lg:border-l lg:border-[hsl(var(--hairline))] pt-6 lg:pt-0 lg:pl-6 space-y-8 overflow-y-auto h-full pr-2 flex-col ${mobileTab === 'sidebar' ? 'flex' : 'hidden lg:flex'}`}>
          {/* Pipeline info */}
          <div>
            <p className="text-[11px] font-semibold text-[hsl(var(--ink-muted))] tracking-widest mb-4 uppercase">Pipeline · Last Turn</p>
            {lastAssistant ? (
              <dl className="space-y-3 text-[13px]">
                <Row k={T.targetSkill} v={lastAssistant.sub_skill_name || "—"} />
                <Row k="Difficulty" v={lastAssistant.difficulty || "—"} />
                <Row k={T.diagnosis} v={lastAssistant.diagnosed_error || "—"} multiline />
                <Row k={T.subgoal} v={lastAssistant.subgoal || "—"} multiline />
              </dl>
            ) : (
              <p className="text-[13px] text-[hsl(var(--ink-faint))]">No turns yet.</p>
            )}
          </div>

          {/* Mastery tracking */}
          <div>
            <p className="text-[11px] font-semibold text-[hsl(var(--ink-muted))] tracking-widest mb-4 uppercase">Session Mastery</p>
            {Object.keys(fluency).length === 0 ? (
              <p className="text-[13px] text-[hsl(var(--ink-faint))]">{T.noPractice}</p>
            ) : (
              <ul className="space-y-5">
                {Object.entries(fluency).map(([slug, f]) => (
                  <li key={slug} className="glass-card p-4">
                    <div className="flex items-baseline justify-between gap-3 mb-2">
                      <div className="text-[14px] font-medium truncate">{f.name || slug}</div>
                      <div className="font-mono text-[12px] font-bold gradient-text">
                        {Math.round(f.mastery * 100)}%
                      </div>
                    </div>
                    <div className="bar-track">
                      <div className="bar-fill" style={{ width: `${Math.round(f.mastery * 100)}%` }} />
                    </div>
                    <div className="mt-3 flex items-center gap-1.5">
                      <button
                        onClick={() => adjustMastery(slug, -0.1)}
                        className="rounded-xl border border-[hsl(var(--hairline))] h-7 w-7 flex items-center justify-center hover:border-[hsl(var(--primary)/0.3)] hover:text-[hsl(var(--primary))] transition-all"
                        title={T.decrease}
                      >
                        <Minus className="h-3 w-3" />
                      </button>
                      <button
                        onClick={() => adjustMastery(slug, 0.1)}
                        className="rounded-xl border border-[hsl(var(--hairline))] h-7 w-7 flex items-center justify-center hover:border-[hsl(var(--primary)/0.3)] hover:text-[hsl(var(--primary))] transition-all"
                        title={T.increase}
                      >
                        <Plus className="h-3 w-3" />
                      </button>
                      <button
                        onClick={() => resetMastery(slug)}
                        className="rounded-xl border border-[hsl(var(--hairline))] h-7 px-2 flex items-center gap-1 text-[10px] font-medium hover:border-[hsl(var(--primary)/0.3)] hover:text-[hsl(var(--primary))] transition-all"
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
  msg, lang, isLastAssistant, onFeedback,
}: {
  msg: UIMessage; lang: "en" | "bn";
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
            <span className="text-[10px] font-medium text-[hsl(var(--warning))] bg-[hsl(var(--warning)/0.1)] rounded-md px-2 py-0.5 border border-[hsl(var(--warning)/0.15)]">
              ⚠ {T.sanitized}
            </span>
          )}
          <span className="text-[11px] font-medium text-[hsl(var(--ink-muted))]">you</span>
        </div>
        {msg.image_url && (
          <img src={msg.image_url} alt="problem" className="rounded-xl max-h-56 border border-[hsl(var(--hairline))] shadow-sm" />
        )}
        <div className={`prose-chat user-bubble px-4 py-3 rounded-2xl rounded-tr-md max-w-[78%] ${lang === "bn" ? "bn" : ""}`}>
          <ReactMarkdown remarkPlugins={[remarkMath]} rehypePlugins={[rehypeKatex]}>
            {msg.content}
          </ReactMarkdown>
        </div>
      </div>
    );
  }

  return (
    <div className="flex gap-3 animate-[inkFade_0.25s_ease-out]">
      <div className="ai-avatar mt-1">
        <GraduationCap className="h-3.5 w-3.5 text-white relative z-10" />
      </div>
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2 mb-2">
          <span className="text-[11px] font-semibold text-[hsl(var(--ink-muted))]">tutor</span>
          {msg.difficulty && (
            <span className="tag-primary">{msg.difficulty}</span>
          )}
        </div>
        {msg.image_url && (
          <img src={msg.image_url} alt="problem" className="rounded-xl max-h-56 mb-2 border border-[hsl(var(--hairline))] shadow-sm" />
        )}
        <div className={`prose-chat tutor-bubble px-4 py-3 rounded-2xl rounded-tl-md ${lang === "bn" ? "bn" : ""}`}>
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
                  className="text-[11px] font-medium px-3 h-8 rounded-xl border border-[hsl(var(--hairline))] text-[hsl(var(--ink-muted))] hover:border-[hsl(var(--primary)/0.3)] hover:text-[hsl(var(--primary))] hover:bg-[hsl(var(--primary)/0.04)] transition-all"
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
      <div className="ai-avatar">
        <GraduationCap className="h-3.5 w-3.5 text-white relative z-10" />
      </div>
      <div className="flex gap-2 items-center py-3 px-4 tutor-bubble rounded-2xl rounded-tl-md">
        <span className="thinking-dot h-2 w-2 rounded-full" />
        <span className="thinking-dot h-2 w-2 rounded-full" />
        <span className="thinking-dot h-2 w-2 rounded-full" />
      </div>
    </div>
  );
}

function Row({ k, v, multiline }: { k: string; v: string; multiline?: boolean }) {
  return (
    <div className="glass-card p-3">
      <dt className="text-[11px] font-semibold text-[hsl(var(--ink-muted))] uppercase tracking-wide mb-1">{k}</dt>
      <dd className={`text-[13px] ${multiline ? "" : "truncate"}`}>{v}</dd>
    </div>
  );
}
