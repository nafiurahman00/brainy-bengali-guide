import type { Response } from "express";
import { requireUser, type AuthedRequest } from "../middleware/auth.js";
import { serviceClient } from "../lib/supabase.js";
import { getAIClient, aiErrorStatus } from "../lib/ai.js";
import { Type, FunctionCallingConfigMode } from "@google/genai";
import { visualizeBodySchema, visualizeRepairBodySchema } from "../schemas.js";

export interface Visualization {
  title: string;
  explanation: string;
  concept: string;
  p5_code: string;
  interaction_hint: string;
}

/** Keyed store kept inside the existing `sessions.visualization` JSONB. */
interface VizStore {
  active: string;
  items: Record<string, Visualization>;
}

const MAX_VIZ_ITEMS = 12;

/** Read the JSONB column into a keyed store, migrating the legacy single-object shape. */
function readVizStore(raw: any): VizStore {
  if (raw && typeof raw === "object" && raw.items && typeof raw.items === "object") {
    const active = typeof raw.active === "string" ? raw.active : Object.keys(raw.items)[0] ?? "";
    return { active, items: raw.items };
  }
  if (raw && typeof raw === "object" && typeof raw.p5_code === "string" && raw.p5_code.trim().length > 0) {
    const key = typeof raw.concept === "string" && raw.concept && raw.concept !== "none" ? raw.concept : "default";
    return { active: key, items: { [key]: raw as Visualization } };
  }
  return { active: "", items: {} };
}

/** Which conversational focus this sketch belongs to (concept > sub-skill > default). */
function vizFocusKey(ctx: { concept?: string; subSkillSlug?: string }): string {
  if (ctx.concept && ctx.concept !== "none") return ctx.concept;
  if (ctx.subSkillSlug) return ctx.subSkillSlug;
  return "default";
}

function pruneStore(store: VizStore): VizStore {
  const keys = Object.keys(store.items);
  if (keys.length <= MAX_VIZ_ITEMS) return store;
  const items: Record<string, Visualization> = {};
  for (const k of keys.slice(-MAX_VIZ_ITEMS)) items[k] = store.items[k];
  if (!items[store.active]) store.active = Object.keys(items).slice(-1)[0] ?? "";
  return { active: store.active, items };
}

/**
 * POST /api/visualize
 * Generates a deterministic, sandboxed p5.js sketch tied to what the student is
 * working on RIGHT NOW (the planner's concept / diagnosed error / actual numbers).
 * Sketches are cached per focus inside `sessions.visualization` so revisiting a
 * focus is instant, while a genuinely new focus (or an explicit lens/regenerate)
 * produces a fresh, relevant sketch.
 */
export const visualizeRoute = [
  requireUser,
  async (req: AuthedRequest, res: Response) => {
    const parse = visualizeBodySchema.safeParse(req.body);
    if (!parse.success) {
      return res.status(400).json({ ok: false, error: parse.error.issues[0]?.message ?? "Bad request" });
    }
    const {
      sessionId, message, imageUrl, language, regenerate, lens,
      concept, subSkillSlug, subSkillName, diagnosedError, difficulty, subgoal, cleanedProblem,
    } = parse.data;
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

      const store = readVizStore(session.visualization);
      const key = vizFocusKey({ concept, subSkillSlug });

      // Reuse a cached sketch for this exact focus unless asked to vary it.
      const cachedItem = store.items[key];
      if (!regenerate && !lens && cachedItem && typeof cachedItem.p5_code === "string" && cachedItem.p5_code.trim().length > 0) {
        store.active = key;
        await supabase.from("sessions").update({ visualization: store }).eq("id", sessionId);
        return res.json({ ok: true, cached: true, viz: cachedItem });
      }

      const subjectName = (session.subject as any)?.name ?? "the subject";
      const lang = language === "bn" ? "Bangla" : "English";

      const ai = getAIClient();

      const richnessRule =
        difficulty === "challenge"
          ? "The student is advanced — make it rich and exploratory with multiple things to manipulate."
          : difficulty === "scaffolding"
          ? "Keep it simple and uncluttered — one clear idea, one control."
          : "Keep it focused — one core idea with one or two controls.";
      const lensRule =
        lens === "simpler"
          ? "\nLENS: Produce a SIMPLER, more stripped-down take on the same idea than before — fewer elements, bigger labels."
          : lens === "another"
          ? "\nLENS: Produce a DIFFERENT representation of the same idea (e.g. switch from a graph to an area/number-line/geometric view) so the student sees it from a fresh angle."
          : "";

      const systemInstruction = `You are a "Visual Explainer" for a Socratic tutoring app. Given what a student is working on in ${subjectName}, you produce a SELF-CONTAINED p5.js sketch that builds intuition for the SPECIFIC concept and step they are on right now.

RELEVANCE & ENGAGEMENT (this is what makes the sketch worth showing):
A. Target the EXACT mechanism the student is working on (see TARGET CONCEPT / DIAGNOSED GAP below), not a generic overview.
B. PARAMETERIZE the sketch with the ACTUAL numbers from the student's problem (see PROBLEM) so it mirrors their case — e.g. if the problem is 2x+6=0, draw the line y=2x+6 and its crossing, not a generic line. You may show the final answer GEOMETRICALLY (a point, a crossing) but do NOT print the final numeric answer as on-screen text — let them read it off.
C. Make it INTERESTING: include either a time-based animation OR a manipulable control (slider/drag) that visibly CHANGES the concept as the student moves it. ${richnessRule}
D. Add a short "what to notice" label on the canvas, and where natural a PREDICT-THEN-REVEAL beat (let the student set/guess something, then reveal whether it matches).${lensRule}

ABSOLUTE RULES — your output MUST satisfy all of these or the renderer will crash:
1. p5.js GLOBAL MODE only. Define top-level functions \`setup()\` and \`draw()\`. Do NOT use \`new p5(...)\` instance mode. Do NOT wrap your code in modules or IIFEs unless you also expose setup/draw on window.
2. Inside setup() the FIRST line must be: \`createCanvas(560, 420);\`.
3. NO external resources. No \`loadImage\`, no \`loadJSON\`, no \`fetch\`, no \`import\`, no \`require\`. Everything must be drawn from primitives.
4. NO \`alert\`, \`prompt\`, \`confirm\`, \`window.location\`, \`document.cookie\`, or any attempts to escape the iframe. The sandbox blocks these but emitting them is wasted effort.
5. The sketch must run forever without throwing. Guard against divide-by-zero, NaN, and infinite loops. Use deterministic math; avoid \`new Date()\` based logic except for \`millis()\`. Any value passed to \`fill\`, \`stroke\`, \`background\`, or \`tint\` must be finite numbers in [0, 255] or a valid CSS string — never an array of mixed types or an object.
6. Prefer INTERACTIVITY: use \`mouseX\`, \`mouseY\`, \`mouseIsPressed\`, \`keyIsDown\`, or \`createSlider(...)\`. The student should be able to manipulate the visualization, not just watch it.
7. Make it READABLE: white/light background, dark axes/text, one accent color (e.g. crimson #C0392B or teal #16A085) for the interactive element. Label axes and key quantities with \`text()\`.
8. Illustrate the MECHANISM of the concept and the student's specific case (see RELEVANCE above). Showing the answer geometrically is fine; printing the final numeric answer as text is not.
9. Keep the code under ~200 lines. No minification.
10. NEVER pass the \`arguments\` object directly to \`color\`, \`fill\`, \`stroke\`, \`background\`, or \`tint\`. If you write a wrapper helper, spread it: \`fill(...arguments)\` (or use rest parameters). Passing \`arguments\` triggers \`[object Arguments] is not a valid color representation\` and crashes the sketch.
11. INITIALIZATION ORDER: every \`let\` global you reference inside a helper function MUST be assigned a value BEFORE that helper is called. Either assign at the very top of \`setup()\` (immediately after \`createCanvas\`) before any other call, or initialize at module scope with a literal. In particular, do NOT call \`resetSketch()\` or any helper that reads vector globals before all \`let X = createVector(...)\` assignments have run. A helper using an unassigned global produces \`Cannot read properties of undefined\` from inside p5.Vector helpers and the canvas never renders.
12. p5 CONSTANTS AND FUNCTIONS DO NOT EXIST AT MODULE TOP LEVEL. \`PI\`, \`TWO_PI\`, \`HALF_PI\`, \`QUARTER_PI\`, \`width\`, \`height\`, and functions like \`cos\`, \`sin\`, \`color\`, \`createVector\`, \`random\` are only defined AFTER setup() begins running. NEVER use them in a top-level \`let\` initializer. If you need an angle constant at top level, use \`Math.PI\`. If you need a vector at top level, declare \`let myVec;\` and assign \`myVec = createVector(...)\` inside setup(). Top-level use produces \`ReferenceError: PI is not defined\`.
13. NO TEMPORAL DEAD ZONE BUGS. Do not reference any \`let\`/\`const\` inside its own initializer (e.g. \`let centerX = width / 2; let centerY = centerX + 10;\` is fine, but \`let centerX = centerY;\` before \`centerY\` is declared is not). If a global depends on \`width\`/\`height\`, assign it inside setup() AFTER \`createCanvas\`.
14. CLASS DEFINITIONS go at MODULE TOP LEVEL (outside any function), not inside setup() or draw(). Instances created inside setup/draw can use them freely.
15. EVENT HANDLERS (\`mousePressed\`, \`mouseReleased\`, \`keyPressed\`, etc.) must be top-level functions, not assigned to globals dynamically.
16. ALL on-canvas \`text()\` labels must be written in ${lang} (axis labels, the "what to notice" note, the interaction prompt). Keep mathematical symbols/numerals as usual.

OUTPUT: call the propose_visualization tool with:
- title: ≤ 60 chars, in ${lang}
- explanation: 1–2 sentences in ${lang} describing what the student sees and why it matters for THEIR problem.
- concept: short canonical English tag (e.g. "derivative", "projectile_motion", "unit_circle"). Use "none" only if the question is genuinely impossible to visualize (e.g. "hi").
- p5_code: the full sketch source as a single string. Must be ready to paste into <script>...</script>.
- interaction_hint: one sentence in ${lang} telling the student how to interact (e.g. "Drag the red dot to slide x along the curve.").`;

      const contextLines = [
        cleanedProblem ? `PROBLEM (use these actual numbers): """${cleanedProblem}"""` : "",
        concept && concept !== "none" ? `TARGET CONCEPT: ${concept}` : "",
        subSkillName ? `TARGET SUB-SKILL: ${subSkillName}` : "",
        diagnosedError && diagnosedError !== "first attempt" ? `DIAGNOSED GAP (address this misconception visually): ${diagnosedError}` : "",
        subgoal ? `CURRENT TEACHING GOAL: ${subgoal}` : "",
      ].filter(Boolean).join("\n");

      const userParts: any[] = [
        {
          text:
            `STUDENT'S QUESTION (subject: ${subjectName}):\n"""${message}"""\n\n` +
            (contextLines ? contextLines + "\n\n" : "") +
            (imageUrl
              ? `The student also attached the image below — it contains the actual problem. ` +
                `OCR/read the image to determine the real subject of the visualization; ` +
                `if it disagrees with the text, trust the image.\n\n`
              : "") +
            `Produce a p5.js visualization that helps the student build intuition for the underlying concept and their specific case. ` +
            `Call the propose_visualization tool.`,
        },
      ];

      if (imageUrl) {
        try {
          const imgResp = await fetch(imageUrl);
          if (imgResp.ok) {
            const imgBuf = await imgResp.arrayBuffer();
            const mimeType = imgResp.headers.get("content-type") ?? "image/jpeg";
            userParts.push({
              inlineData: { mimeType, data: Buffer.from(imgBuf).toString("base64") },
            });
          }
        } catch {
          // text-only generation is still a useful fallback
        }
      }

      let toolArgs: any = null;
      try {
        const resp = await ai.models.generateContent({
          model: "gemini-2.5-pro",
          contents: [
            {
              role: "user",
              parts: userParts,
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

      // Store under the focus key; reuse the returned concept tag if we had none.
      const storeKey = key !== "default" ? key : viz.concept && viz.concept !== "none" ? viz.concept : "default";
      store.items[storeKey] = viz;
      store.active = storeKey;
      await supabase.from("sessions").update({ visualization: pruneStore(store) }).eq("id", sessionId);

      return res.json({ ok: true, viz, cached: false });
    } catch (e) {
      console.error("visualize fatal", e);
      return res.status(500).json({ ok: false, error: e instanceof Error ? e.message : "Unknown error" });
    }
  },
];

/**
 * POST /api/visualize/repair
 * Takes a known-broken p5 sketch and the runtime error it produced, asks
 * Gemini for the smallest possible fix, and returns the corrected code. The
 * fixed code is persisted back to `sessions.visualization` so subsequent loads
 * skip the buggy version. Frontend calls this after a hidden-iframe preflight
 * detects an error; capped at one repair per generation by the caller.
 */
export const repairVisualizationRoute = [
  requireUser,
  async (req: AuthedRequest, res: Response) => {
    const parse = visualizeRepairBodySchema.safeParse(req.body);
    if (!parse.success) {
      return res.status(400).json({ ok: false, error: parse.error.issues[0]?.message ?? "Bad request" });
    }
    const { sessionId, code, errorMessage } = parse.data;
    const userId = req.user!.id;
    const supabase = serviceClient();

    try {
      const { data: session, error: sErr } = await supabase
        .from("sessions")
        .select("id, user_id, visualization")
        .eq("id", sessionId)
        .single();
      if (sErr || !session) return res.status(404).json({ ok: false, error: "Session not found" });
      if (session.user_id !== userId) return res.status(403).json({ ok: false, error: "Forbidden" });

      const ai = getAIClient();

      const systemInstruction = `You are a "p5.js Sketch Repair" assistant. You receive a p5.js sketch that crashed at runtime, plus the exact runtime error message. Your job is to return a CORRECTED version of the sketch with the SMALLEST POSSIBLE change that addresses the error while preserving the original visualization's intent and structure.

ABSOLUTE RULES — your output MUST satisfy all of these or the renderer will crash again:
1. p5.js GLOBAL MODE only. Top-level \`setup()\` and \`draw()\` functions. No \`new p5(...)\`, no modules, no IIFEs.
2. Inside setup() the FIRST line must be: \`createCanvas(560, 420);\`.
3. NO external resources: no \`loadImage\`, \`loadJSON\`, \`fetch\`, \`import\`, \`require\`.
4. NO \`alert\`, \`prompt\`, \`confirm\`, \`window.location\`, \`document.cookie\`, \`eval\`.
5. p5 constants like \`PI\`, \`TWO_PI\`, \`HALF_PI\`, and p5 functions like \`cos\`, \`sin\`, \`color\`, \`createVector\` ONLY exist after setup() starts running. NEVER reference them at module top level. If you need a constant at top level, use \`Math.PI\` etc. or initialize the variable inside setup().
6. INITIALIZATION ORDER: any variable read by a helper function must be assigned before that helper is called. In setup(), assign all globals BEFORE calling any helper that reads them.
7. NEVER pass the \`arguments\` object directly to color setters. Spread it: \`fill(...arguments)\`.
8. Apply the smallest fix that resolves the reported error. Do NOT rewrite the sketch. Do NOT change the conceptual intent, the variable names, or the visual layout unless it is strictly necessary to fix the bug.

OUTPUT: call the repair_sketch tool with a single field \`p5_code\` containing the full corrected sketch.`;

      let toolArgs: any = null;
      try {
        const resp = await ai.models.generateContent({
          model: "gemini-2.5-pro",
          contents: [
            {
              role: "user",
              parts: [
                {
                  text: `RUNTIME ERROR FROM THE BROWSER:\n"""\n${errorMessage}\n"""\n\nBROKEN SKETCH:\n\`\`\`js\n${code}\n\`\`\`\n\nReturn the corrected sketch via the repair_sketch tool. Apply the smallest fix that resolves the error.`,
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
                    name: "repair_sketch",
                    description: "Return a corrected p5.js sketch that fixes the reported runtime error.",
                    parameters: {
                      type: Type.OBJECT,
                      properties: {
                        p5_code: { type: Type.STRING },
                      },
                      required: ["p5_code"],
                    },
                  },
                ],
              },
            ],
            toolConfig: {
              functionCallingConfig: {
                mode: FunctionCallingConfigMode.ANY,
                allowedFunctionNames: ["repair_sketch"],
              },
            },
          },
        });
        toolArgs = resp.functionCalls?.[0]?.args ?? null;
      } catch (err) {
        console.error("visualize repair error", err);
        const mapped = aiErrorStatus(err);
        if (mapped) return res.status(mapped.status).json({ ok: false, error: mapped.message });
        return res.status(500).json({ ok: false, error: "Repair failed" });
      }

      if (!toolArgs?.p5_code || typeof toolArgs.p5_code !== "string") {
        return res.status(502).json({ ok: false, error: "Repair returned no sketch" });
      }

      const fixedCode = String(toolArgs.p5_code);
      const store = readVizStore(session.visualization);
      const activeKey = store.active || Object.keys(store.items)[0] || "default";
      const prev = store.items[activeKey];
      store.items[activeKey] = {
        title: String(prev?.title ?? "Visualization"),
        explanation: String(prev?.explanation ?? ""),
        concept: String(prev?.concept ?? "none"),
        interaction_hint: String(prev?.interaction_hint ?? ""),
        p5_code: fixedCode,
      };
      store.active = activeKey;
      await supabase.from("sessions").update({ visualization: store }).eq("id", sessionId);

      return res.json({ ok: true, p5_code: fixedCode });
    } catch (e) {
      console.error("visualize repair fatal", e);
      return res.status(500).json({ ok: false, error: e instanceof Error ? e.message : "Unknown error" });
    }
  },
];
