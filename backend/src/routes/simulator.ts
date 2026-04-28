import type { Response } from "express";
import { requireUser, type AuthedRequest } from "../middleware/auth.js";
import { serviceClient } from "../lib/supabase.js";
import { getAIClient, aiErrorStatus } from "../lib/ai.js";
import { Type, FunctionCallingConfigMode } from "@google/genai";
import { simulatorBodySchema } from "../schemas.js";

/**
 * POST /api/simulator
 * Auth required. Loads the session transcript and asks a Gemini judge to
 * roleplay a confused student + score Efficiency-to-Mastery (EtM).
 */
export const simulatorRoute = [
  requireUser,
  async (req: AuthedRequest, res: Response) => {
    const parse = simulatorBodySchema.safeParse(req.body);
    if (!parse.success) {
      return res.status(400).json({ error: parse.error.issues[0]?.message ?? "Bad request" });
    }
    const { sessionId, maxTurns = 6 } = parse.data;
    const userId = req.user!.id;
    const supabase = serviceClient();

    try {
      // Confirm the session belongs to the caller before reading messages.
      const { data: session, error: sErr } = await supabase
        .from("sessions")
        .select("id, user_id")
        .eq("id", sessionId)
        .single();
      if (sErr || !session) return res.status(404).json({ error: "Session not found" });
      if (session.user_id !== userId) return res.status(403).json({ error: "Forbidden" });

      const { data: messages } = await supabase
        .from("messages")
        .select("role, content")
        .eq("session_id", sessionId)
        .order("created_at", { ascending: true })
        .limit(20);

      const transcript = (messages ?? [])
        .map((m) => `${(m.role as string).toUpperCase()}: ${m.content}`)
        .join("\n");

      const ai = getAIClient();

      let result: any = null;
      try {
        const resp = await ai.models.generateContent({
          model: "gemini-3-flash-preview",
          contents: [
            {
              role: "user",
              parts: [
                {
                  text: `Here is a Socratic tutoring transcript so far. Simulate up to ${maxTurns} additional student/tutor exchanges in your head, then evaluate:

TRANSCRIPT:
${transcript}

Tasks (call evaluate tool):
- estimated_turns_to_mastery: integer (lower = better)
- answer_leaked: did the tutor reveal the final answer?
- frustration_handled: did the tutor adapt when the student was confused?
- socratic_adherence: 0–1 score for staying question-driven
- recommended_improvements: short bullet list (string)`,
                },
              ],
            },
          ],
          config: {
            systemInstruction:
              "You are a Quality Auditor that role-plays a confused student against a Socratic tutor transcript and evaluates the tutor.",
            tools: [
              {
                functionDeclarations: [
                  {
                    name: "evaluate",
                    description: "Return EtM evaluation",
                    parameters: {
                      type: Type.OBJECT,
                      properties: {
                        estimated_turns_to_mastery: { type: Type.NUMBER },
                        answer_leaked: { type: Type.BOOLEAN },
                        frustration_handled: { type: Type.BOOLEAN },
                        socratic_adherence: { type: Type.NUMBER },
                        recommended_improvements: { type: Type.STRING },
                      },
                      required: [
                        "estimated_turns_to_mastery",
                        "answer_leaked",
                        "frustration_handled",
                        "socratic_adherence",
                        "recommended_improvements",
                      ],
                    },
                  },
                ],
              },
            ],
            toolConfig: { functionCallingConfig: { mode: FunctionCallingConfigMode.ANY, allowedFunctionNames: ["evaluate"] } },
          },
        });
        result = resp.functionCalls?.[0]?.args ?? null;
      } catch (err) {
        console.error("simulator error", err);
        const mapped = aiErrorStatus(err);
        if (mapped) return res.status(mapped.status).json({ error: mapped.message });
        return res.status(500).json({ error: "Simulator failed" });
      }

      return res.json({ result });
    } catch (e) {
      console.error("simulator error", e);
      return res
        .status(500)
        .json({ error: e instanceof Error ? e.message : "Unknown" });
    }
  },
];
