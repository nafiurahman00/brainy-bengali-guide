import type { Response } from "express";
import { requireUser, type AuthedRequest } from "../middleware/auth.js";
import { serviceClient } from "../lib/supabase.js";
import { getAIClient, aiErrorStatus } from "../lib/ai.js";
import { Type, FunctionCallingConfigMode } from "@google/genai";
import { visualizeBodySchema } from "../schemas.js";

export interface Visualization {
  title: string;
  explanation: string;
  concept: string;
  p5_code: string;
  interaction_hint: string;
}

/**
 * POST /api/visualize
 * Generates a deterministic, sandboxed p5.js sketch that visually explains the
 * student's first question for a session. Idempotent — once a session has a
 * visualization persisted on `sessions.visualization`, the cached value is
 * returned without calling Gemini again.
 */
export const visualizeRoute = [
  requireUser,
  async (req: AuthedRequest, res: Response) => {
    const parse = visualizeBodySchema.safeParse(req.body);
    if (!parse.success) {
      return res.status(400).json({ ok: false, error: parse.error.issues[0]?.message ?? "Bad request" });
    }
    const { sessionId, message, language } = parse.data;
    const userId = req.user!.id;
    const supabase = serviceClient();

    try {
      const { data: session, error: sErr } = await supabase
        .from("sessions")
        .select("id, user_id, visualization, subject:subjects(name)")
        .eq("id", sessionId)
        .single();
      if (sErr || !session) return res.status(404).json({ ok: false, error: "Session not found" });
      if (session.user_id !== userId) return res.status(403).json({ ok: false, error: "Forbidden" });

      const cached = session.visualization as Partial<Visualization> | null | undefined;
      if (cached && typeof cached.p5_code === "string" && cached.p5_code.trim().length > 0) {
        return res.json({
          ok: true,
          cached: true,
          viz: {
            title: cached.title ?? "Visualization",
            explanation: cached.explanation ?? "",
            concept: cached.concept ?? "",
            p5_code: cached.p5_code,
            interaction_hint: cached.interaction_hint ?? "",
          } satisfies Visualization,
        });
      }

      const subjectName = (session.subject as any)?.name ?? "the subject";
      const lang = language === "bn" ? "Bangla" : "English";

      const ai = getAIClient();

      const systemInstruction = `You are a "Visual Explainer" for a Socratic tutoring app. Given a student's question about ${subjectName}, you produce a SELF-CONTAINED p5.js sketch that helps the student build intuition for the concept behind the question.

ABSOLUTE RULES — your output MUST satisfy all of these or the renderer will crash:
1. p5.js GLOBAL MODE only. Define top-level functions \`setup()\` and \`draw()\`. Do NOT use \`new p5(...)\` instance mode. Do NOT wrap your code in modules or IIFEs unless you also expose setup/draw on window.
2. Inside setup() the FIRST line must be: \`createCanvas(560, 420);\`.
3. NO external resources. No \`loadImage\`, no \`loadJSON\`, no \`fetch\`, no \`import\`, no \`require\`. Everything must be drawn from primitives.
4. NO \`alert\`, \`prompt\`, \`confirm\`, \`window.location\`, \`document.cookie\`, or any attempts to escape the iframe. The sandbox blocks these but emitting them is wasted effort.
5. The sketch must run forever without throwing. Guard against divide-by-zero, NaN, and infinite loops. Use deterministic math; avoid \`new Date()\` based logic except for \`millis()\`.
6. Prefer INTERACTIVITY: use \`mouseX\`, \`mouseY\`, \`mouseIsPressed\`, \`keyIsDown\`, or \`createSlider(...)\`. The student should be able to manipulate the visualization, not just watch it.
7. Make it READABLE: white/light background, dark axes/text, one accent color (e.g. crimson #C0392B or teal #16A085) for the interactive element. Label axes and key quantities with \`text()\`.
8. The visualization must illustrate the MECHANISM of the concept (e.g. show how a tangent slope changes as x moves; show vectors composing into a resultant). Do NOT give away a final numerical answer to the student's specific problem — keep it general.
9. Keep the code under ~200 lines. No minification.

OUTPUT: call the propose_visualization tool with:
- title: ≤ 60 chars, in ${lang}
- explanation: 1–2 sentences in ${lang} describing what the student sees and why it matters.
- concept: short canonical English tag (e.g. "derivative", "projectile_motion", "unit_circle"). Use "none" only if the question is genuinely impossible to visualize (e.g. "hi").
- p5_code: the full sketch source as a single string. Must be ready to paste into <script>...</script>.
- interaction_hint: one sentence in ${lang} telling the student how to interact (e.g. "Drag the red dot to slide x along the curve.").`;

      let toolArgs: any = null;
      try {
        const resp = await ai.models.generateContent({
          model: "gemini-2.5-pro",
          contents: [
            {
              role: "user",
              parts: [
                {
                  text: `STUDENT'S FIRST QUESTION (subject: ${subjectName}):\n"""${message}"""\n\nProduce a p5.js visualization that helps the student build intuition for the underlying concept. Call the propose_visualization tool.`,
                },
              ],
            },
          ],
          config: {
            systemInstruction,
            tools: [
              {
                functionDeclarations: [
                  {
                    name: "propose_visualization",
                    description: "Return a self-contained p5.js sketch that explains the concept behind the student's question.",
                    parameters: {
                      type: Type.OBJECT,
                      properties: {
                        title: { type: Type.STRING },
                        explanation: { type: Type.STRING },
                        concept: { type: Type.STRING },
                        p5_code: { type: Type.STRING },
                        interaction_hint: { type: Type.STRING },
                      },
                      required: ["title", "explanation", "concept", "p5_code", "interaction_hint"],
                    },
                  },
                ],
              },
            ],
            toolConfig: {
              functionCallingConfig: {
                mode: FunctionCallingConfigMode.ANY,
                allowedFunctionNames: ["propose_visualization"],
              },
            },
          },
        });
        toolArgs = resp.functionCalls?.[0]?.args ?? null;
      } catch (err) {
        console.error("visualize error", err);
        const mapped = aiErrorStatus(err);
        if (mapped) return res.status(mapped.status).json({ ok: false, error: mapped.message });
        return res.status(500).json({ ok: false, error: "Visualizer failed" });
      }

      if (!toolArgs?.p5_code) {
        return res.status(502).json({ ok: false, error: "Visualizer returned no sketch" });
      }

      const viz: Visualization = {
        title: String(toolArgs.title ?? "Visualization"),
        explanation: String(toolArgs.explanation ?? ""),
        concept: String(toolArgs.concept ?? "none"),
        p5_code: String(toolArgs.p5_code),
        interaction_hint: String(toolArgs.interaction_hint ?? ""),
      };

      await supabase.from("sessions").update({ visualization: viz }).eq("id", sessionId);

      return res.json({ ok: true, viz, cached: false });
    } catch (e) {
      console.error("visualize fatal", e);
      return res.status(500).json({ ok: false, error: e instanceof Error ? e.message : "Unknown error" });
    }
  },
];
