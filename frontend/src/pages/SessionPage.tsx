import { useEffect, useRef, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { AppHeader } from "@/components/AppHeader";
import { InkButton } from "@/components/InkButton";
import { useChat, UIMessage, uploadProblemImage } from "@/hooks/use-chat";
import { useLang } from "@/contexts/LangContext";
import { t } from "@/lib/i18n";
import ReactMarkdown from "react-markdown";
import remarkMath from "remark-math";
import rehypeKatex from "rehype-katex";
import { ImageIcon, X, Loader2, Plus, Minus, ArrowLeft, Send, Sparkles } from "lucide-react";
import { toast } from "sonner";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs";
import { useVisualization } from "@/hooks/use-visualization";
import { VisualizationPanel } from "@/components/VisualizationPanel";

interface Subject { id: string; slug: string; name: string; name_bn: string | null; }

export default function SessionPage() {
  const { id } = useParams<{ id: string }>();
  const nav = useNavigate();
  const { lang } = useLang();
  const T = t(lang);
  const { messages, loading, streaming, send, giveFeedback, adjustMastery } = useChat(id);
  const viz = useVisualization(id);
  const [input, setInput] = useState("");
  const [image, setImage] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [subject, setSubject] = useState<Subject | null>(null);
  const [auditing, setAuditing] = useState(false);
  const [audit, setAudit] = useState<any>(null);
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!id) return;
    supabase
      .from("sessions")
      .select("title, subject:subjects(id, slug, name, name_bn)")
      .eq("id", id)
      .single()
      .then(({ data }) => setSubject((data as any)?.subject ?? null));
  }, [id]);

  useEffect(() => {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight, behavior: "smooth" });
  }, [messages, streaming]);

  const handleImage = (f: File) => {
    if (f.size > 5 * 1024 * 1024) { toast.error("Image too large (max 5MB)"); return; }
    setImage(f);
    setImagePreview(URL.createObjectURL(f));
  };

  const handleSend = async () => {
    if (!input.trim() && !image) return;
    const text = input.trim() || (image ? "[image submitted]" : "");
    const isFirstTurn = !loading && messages.length === 0;
    setInput("");
    const f = image;
    setImage(null);
    setImagePreview(null);

    let imageUrl: string | undefined;
    if (f && id) {
      const { data: u } = await supabase.auth.getUser();
      if (u.user) imageUrl = await uploadProblemImage(u.user.id, id, f);
    }

    if (isFirstTurn && viz.state.status === "idle" && (text || imageUrl)) {
      void viz.generate(text, lang, imageUrl);
    }
    await send(text, imageUrl, lang);
  };

  const runAudit = async () => {
    if (!id) return;
    setAuditing(true);
    setAudit(null);
    try {
      const { data: sess } = await supabase.auth.getSession();
      const r = await fetch(`${import.meta.env.VITE_SUPABASE_URL}/functions/v1/student-simulator`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${sess.session?.access_token}` },
        body: JSON.stringify({ sessionId: id }),
      });
      const j = await r.json();
      if (!r.ok) { toast.error(j.error || "Audit failed"); return; }
      setAudit(j.result);
    } finally { setAuditing(false); }
  };

  const lastAssistantId = [...messages].reverse().find((m) => m.role === "assistant" && !m.pending)?.id;

  return (
    <div className="h-[100dvh] w-full overflow-hidden flex flex-col">
      <AppHeader />
      <div className="shrink-0 border-b border-[hsl(var(--hairline))] bg-[hsl(var(--paper))]">
        <div className="max-w-[1280px] mx-auto px-4 sm:px-6 py-3 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
          <div>
            <button onClick={() => nav("/")} className="inline-flex items-center gap-1.5 text-[12px] font-medium text-[hsl(var(--ink-muted))] hover:text-[hsl(var(--primary))] transition-colors">
              <ArrowLeft className="h-3.5 w-3.5" /> {T.dashboard}
            </button>
            <div className="text-base sm:text-lg font-semibold mt-1">
              {subject ? (lang === "bn" && subject.name_bn ? subject.name_bn : subject.name) : "Session"}
            </div>
          </div>
          {/* <InkButton variant="outline" onClick={runAudit} disabled={auditing || messages.length < 2}>
            {auditing ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <Sparkles className="h-3.5 w-3.5" />} <span className="ml-2">{T.runQualityCheck}</span>
          </InkButton> */}
        </div>
      </div>

      <main className="flex-1 max-w-[1280px] w-full mx-auto px-4 sm:px-6 py-4 sm:py-6 grid grid-cols-1 lg:grid-cols-12 gap-6 min-h-0 overflow-hidden">
        <section className="lg:col-span-8 flex flex-col min-h-0 h-full">
          <div ref={scrollRef} className="flex-1 overflow-y-auto pr-2 space-y-6">
            {loading && <div className="text-[12px] font-medium text-[hsl(var(--ink-muted))]">loading…</div>}
            {!loading && messages.length === 0 && (
              <div className="flex flex-col items-center justify-center h-full min-h-[40vh] text-center px-8">
                <div className="hero-icon w-16 h-16 mb-5">
                  <Sparkles className="h-7 w-7 text-white" />
                </div>
                <p className="text-[12px] font-medium text-[hsl(var(--primary))] mb-2">First turn</p>
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
            <div className="rounded-xl border border-[hsl(var(--hairline))] bg-[hsl(var(--paper))] flex items-end gap-2 p-3 shadow-surface focus-primary transition-all">
              <label className="cursor-pointer p-2 rounded-lg hover:bg-[hsl(var(--primary)/0.08)] shrink-0 transition-colors" title="Attach image">
                <ImageIcon className="h-4 w-4 text-[hsl(var(--ink-muted))]" />
                <input type="file" accept="image/*" hidden onChange={(e) => e.target.files?.[0] && handleImage(e.target.files[0])} />
              </label>
              <textarea
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); handleSend(); }
                }}
                placeholder={T.askAnything}
                rows={2}
                className="flex-1 resize-none bg-transparent outline-none text-[14px] py-2 px-1 max-h-40 leading-relaxed"
                disabled={streaming}
              />
              <button
                onClick={handleSend}
                disabled={streaming || (!input.trim() && !image)}
                className="shrink-0 w-9 h-9 rounded-xl flex items-center justify-center disabled:opacity-30 hover:shadow-md active:scale-95 transition-all text-white btn-gradient"
              >
                <Send className="h-4 w-4" />
              </button>
            </div>
            <p className="mt-2 text-[11px] text-[hsl(var(--ink-faint))] pl-1">Enter to send · Shift+Enter for newline</p>
          </div>
        </section>

        <aside className="lg:col-span-4 border-t border-[hsl(var(--hairline))] lg:border-t-0 lg:border-l lg:border-[hsl(var(--hairline))] pt-6 lg:pt-0 lg:pl-6 overflow-y-auto h-full pr-2 min-h-0 flex flex-col">
          <Tabs defaultValue="visualization" className="flex flex-col flex-1 min-h-0">
            <TabsList className="self-start bg-[hsl(var(--muted))] h-8 mb-4">
              <TabsTrigger value="visualization" className="text-[11px] h-6 px-2.5 data-[state=active]:text-[hsl(var(--primary))]">Visualization</TabsTrigger>
              <TabsTrigger value="pipeline" className="text-[11px] h-6 px-2.5 data-[state=active]:text-[hsl(var(--primary))]">Pipeline</TabsTrigger>
            </TabsList>

            <TabsContent value="visualization" className="flex-1 min-h-0 mt-0 outline-none">
              <VisualizationPanel sessionId={id} state={viz.state} onRetry={viz.retry} />
            </TabsContent>

            <TabsContent value="pipeline" className="flex-1 min-h-0 mt-0 outline-none">
              <p className="text-[11px] font-medium text-[hsl(var(--ink-muted))] tracking-wide mb-4 uppercase">Pipeline · Last Turn</p>
              <PipelinePanel
                last={messages.filter((m) => m.role === "assistant" && !m.pending).slice(-1)[0]}
                T={T}
                onAdjust={async (delta) => {
                  const last = messages.filter((m) => m.role === "assistant" && !m.pending).slice(-1)[0];
                  if (!last?.sub_skill_id) return;
                  await adjustMastery(last.sub_skill_id, delta);
                  toast.success(delta > 0 ? T.increase : T.decrease);
                }}
              />

              {audit && (
                <div className="mt-8">
                  <p className="text-[11px] font-medium text-[hsl(var(--ink-muted))] tracking-wide mb-3 uppercase">Audit Results</p>
                  <h3 className="text-base font-semibold mb-3">{T.qualityResults}</h3>
                  <dl className="space-y-2 text-[13px]">
                    <Row k={T.etmTurns} v={String(audit.estimated_turns_to_mastery)} />
                    <Row k={T.answerLeaked} v={audit.answer_leaked ? T.yes : T.no} bold={audit.answer_leaked} />
                    <Row k={T.socraticAdherence} v={`${Math.round(audit.socratic_adherence * 100)}%`} />
                  </dl>
                  <div className="mt-3">
                    <p className="text-[12px] font-medium text-[hsl(var(--ink-muted))] mb-1">{T.improvements}</p>
                    <p className="text-[13px] text-[hsl(var(--ink-muted))] whitespace-pre-wrap">
                      {audit.recommended_improvements}
                    </p>
                  </div>
                </div>
              )}
            </TabsContent>
          </Tabs>
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
  onFeedback: (fb: "got_it" | "confused" | "more_help") => void;
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
        <span className="text-white text-[11px] font-bold">AI</span>
      </div>
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2 mb-2">
          <span className="text-[11px] font-medium text-[hsl(var(--ink-muted))]">tutor</span>
          {msg.difficulty && (
            <span className="tag-primary">{msg.difficulty}</span>
          )}
        </div>
        {msg.image_url && (
          <img src={msg.image_url} alt="problem" className="rounded-xl max-h-56 mb-2 border border-[hsl(var(--hairline))]" />
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
            {(["got_it", "confused", "more_help"] as const).map((fb) => {
              const labels = { got_it: T.gotIt, confused: T.confused, more_help: T.moreHelp };
              const icons = { got_it: "✓", confused: "?", more_help: "+" };
              const active = msg.feedback === fb;
              return (
                <button
                  key={fb}
                  disabled={!!msg.feedback}
                  onClick={() => onFeedback(fb)}
                  className={`text-[11px] font-medium px-3 h-8 rounded-xl border transition-all ${
                    active
                      ? "btn-gradient border-transparent text-white"
                      : "border-[hsl(var(--primary)/0.2)] text-[hsl(var(--ink-muted))] hover:border-[hsl(var(--primary))] hover:text-[hsl(var(--primary))] disabled:opacity-30"
                  }`}
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
        <span className="text-white text-[11px] font-bold">AI</span>
      </div>
      <div className="flex gap-2 items-center py-3 px-4 tutor-bubble rounded-2xl rounded-tl-md">
        <span className="thinking-dot h-2 w-2 rounded-full" />
        <span className="thinking-dot h-2 w-2 rounded-full" />
        <span className="thinking-dot h-2 w-2 rounded-full" />
      </div>
    </div>
  );
}

function PipelinePanel({
  last, T, onAdjust,
}: {
  last?: UIMessage;
  T: ReturnType<typeof t>;
  onAdjust?: (delta: number) => Promise<void> | void;
}) {
  if (!last) return <p className="text-[13px] text-[hsl(var(--ink-muted))]">No turns yet.</p>;
  return (
    <dl className="space-y-3 text-[13px]">
      <Row k={T.targetSkill} v={last.sub_skill_name || "—"} />
      <Row k="Difficulty" v={last.difficulty || "—"} />
      <Row k={T.diagnosis} v={last.diagnosed_error || "—"} multiline />
      <Row k={T.subgoal} v={last.subgoal || "—"} multiline />
      {onAdjust && last.sub_skill_id && (
        <div className="pt-2">
          <dt className="text-[12px] font-medium text-[hsl(var(--ink-muted))] mb-1.5">{T.adjustMastery}</dt>
          <div className="flex items-center gap-1.5">
            <button
              onClick={() => onAdjust(-0.1)}
              className="rounded-xl border border-[hsl(var(--primary)/0.2)] h-8 px-3 flex items-center gap-1.5 text-[11px] font-medium hover:border-[hsl(var(--primary))] hover:text-[hsl(var(--primary))] transition-colors"
            >
              <Minus className="h-3 w-3" /> 10%
            </button>
            <button
              onClick={() => onAdjust(0.1)}
              className="rounded-xl border border-[hsl(var(--primary)/0.2)] h-8 px-3 flex items-center gap-1.5 text-[11px] font-medium hover:border-[hsl(var(--primary))] hover:text-[hsl(var(--primary))] transition-colors"
            >
              <Plus className="h-3 w-3" /> 10%
            </button>
          </div>
        </div>
      )}
    </dl>
  );
}

function Row({ k, v, multiline, bold }: { k: string; v: string; multiline?: boolean; bold?: boolean }) {
  return (
    <div>
      <dt className="text-[12px] font-medium text-[hsl(var(--ink-muted))]">{k}</dt>
      <dd className={`mt-0.5 ${multiline ? "" : "truncate"} ${bold ? "font-semibold text-[hsl(var(--destructive))]" : ""}`}>{v}</dd>
    </div>
  );
}
