import { useEffect, useRef, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { supabase } from "@/integrations/supabase/client";
import { AppHeader } from "@/components/AppHeader";
import { useChat, UIMessage, uploadProblemImage } from "@/hooks/use-chat";
import { useLang } from "@/contexts/LangContext";
import { t } from "@/lib/i18n";
import ReactMarkdown from "react-markdown";
import remarkMath from "remark-math";
import rehypeKatex from "rehype-katex";
import { ImageIcon, X, ArrowLeft, Send, GraduationCap } from "lucide-react";
import { toast } from "sonner";
import { useVisualization } from "@/hooks/use-visualization";
import { VisualizationPanel } from "@/components/VisualizationPanel";

interface Subject { id: string; slug: string; name: string; name_bn: string | null; }

export default function SessionPage() {
  const { id } = useParams<{ id: string }>();
  const nav = useNavigate();
  const { lang } = useLang();
  const T = t(lang);
  const { messages, loading, streaming, send, giveFeedback } = useChat(id);
  const viz = useVisualization(id);
  const [input, setInput] = useState("");
  const [image, setImage] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [subject, setSubject] = useState<Subject | null>(null);
  const [mobileTab, setMobileTab] = useState<"chat" | "viz">("chat");
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

    void isFirstTurn; // viz is now driven by the focus effect below (context-aware)
    await send(text, imageUrl, lang);
  };

  // Drive the visualization from the conversation's current focus: when the
  // tutor's target sub-skill changes, generate a fresh, context-aware sketch
  // (the backend caches per focus, so revisiting a focus is instant).
  const lastAssistantMeta = [...messages].reverse().find((m) => m.role === "assistant");
  const lastUserContent = [...messages].reverse().find((m) => m.role === "user")?.content;
  const vizFocus = lastAssistantMeta?.sub_skill_slug;
  useEffect(() => {
    if (!id || !vizFocus) return;
    viz.ensureFor(vizFocus, lastUserContent ?? "", lang, {
      subSkillSlug: lastAssistantMeta?.sub_skill_slug,
      subSkillName: lastAssistantMeta?.sub_skill_name,
      diagnosedError: lastAssistantMeta?.diagnosed_error,
      difficulty: lastAssistantMeta?.difficulty,
      subgoal: lastAssistantMeta?.subgoal,
      cleanedProblem: lastUserContent,
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [vizFocus, id, lang]);

  const lastAssistantId = [...messages].reverse().find((m) => m.role === "assistant" && !m.pending)?.id;

  return (
    <div className="h-[100dvh] w-full overflow-hidden flex flex-col">
      <AppHeader />
      <div className="shrink-0 section-divider" style={{ background: 'hsl(var(--paper))' }}>
        <div className="w-full px-4 sm:px-6 lg:px-8 py-3 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
          <div>
            <button onClick={() => nav("/")} className="inline-flex items-center gap-1.5 text-[12px] font-medium text-[hsl(var(--ink-muted))] hover:text-[hsl(var(--primary))] transition-colors group">
              <ArrowLeft className="h-3.5 w-3.5 transition-transform group-hover:-translate-x-0.5" /> {T.dashboard}
            </button>
            <div className="text-base sm:text-lg font-semibold mt-1.5 flex items-center gap-2">
              <span className="inline-flex items-center justify-center w-6 h-6 rounded-lg text-white" style={{ background: 'var(--gradient-primary)' }}>
                <GraduationCap className="h-3.5 w-3.5" />
              </span>
              {subject ? (lang === "bn" && subject.name_bn ? subject.name_bn : subject.name) : "Session"}
            </div>
          </div>
        </div>
      </div>

      <main className="flex-1 w-full px-4 sm:px-6 lg:px-8 py-4 sm:py-6 flex flex-col lg:grid lg:grid-cols-12 gap-6 min-h-0 overflow-hidden">
        {/* Mobile Tabs */}
        <div className="lg:hidden flex rounded-xl bg-[hsl(var(--muted))] p-1 shrink-0">
          <button onClick={() => setMobileTab("chat")} className={`flex-1 py-1.5 text-[13px] font-medium rounded-lg transition-all ${mobileTab === 'chat' ? 'bg-[hsl(var(--card))] shadow-sm text-[hsl(var(--foreground))]' : 'text-[hsl(var(--ink-muted))] hover:text-[hsl(var(--foreground))]'}`}>Chat</button>
          <button onClick={() => setMobileTab("viz")} className={`flex-1 py-1.5 text-[13px] font-medium rounded-lg transition-all ${mobileTab === 'viz' ? 'bg-[hsl(var(--card))] shadow-sm text-[hsl(var(--foreground))]' : 'text-[hsl(var(--ink-muted))] hover:text-[hsl(var(--foreground))]'}`}>Visualization</button>
        </div>

        <section className={`lg:col-span-6 min-h-0 h-full flex-col ${mobileTab === 'chat' ? 'flex' : 'hidden lg:flex'}`}>
          <div ref={scrollRef} className="flex-1 overflow-y-auto pr-2 space-y-6">
            {loading && <div className="text-[12px] font-medium text-[hsl(var(--ink-muted))]">loading…</div>}
            {!loading && messages.length === 0 && (
              <div className="flex flex-col items-center justify-center h-full min-h-[40vh] text-center px-8">
                <div className="hero-icon w-16 h-16 mb-6">
                  <GraduationCap className="h-7 w-7 text-white relative z-10" />
                </div>
                <p className="text-[11px] font-semibold gradient-text tracking-widest mb-3 uppercase">First turn</p>
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

        <aside className={`lg:col-span-6 border-t border-[hsl(var(--hairline))] lg:border-t-0 lg:border-l lg:border-[hsl(var(--hairline))] pt-6 lg:pt-0 lg:pl-6 overflow-y-auto h-full pr-2 min-h-0 flex-col ${mobileTab === 'viz' ? 'flex' : 'hidden lg:flex'}`}>
          <VisualizationPanel sessionId={id} state={viz.state} onRetry={viz.retry} onVary={viz.vary} T={T} />
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
  onFeedback: (fb: "got_it" | "confused" | "more_help") => void;
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
                      : "border-[hsl(var(--hairline))] text-[hsl(var(--ink-muted))] hover:border-[hsl(var(--primary)/0.3)] hover:text-[hsl(var(--primary))] hover:bg-[hsl(var(--primary)/0.04)] disabled:opacity-30"
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
