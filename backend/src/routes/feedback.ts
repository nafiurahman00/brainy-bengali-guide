import type { Response } from "express";
import { requireUser, type AuthedRequest } from "../middleware/auth.js";
import { serviceClient } from "../lib/supabase.js";
import { feedbackBodySchema } from "../schemas.js";
import {
  applyDecay,
  applyEvidence,
  defaultLearnerState,
  freshState,
  updateLearnerState,
  type Affect,
  type MasteryState,
} from "../lib/mastery.js";

/**
 * POST /api/feedback
 * Records the student's "Got it / Confused / More help" tap as a SECONDARY,
 * downweighted evidence event. The primary mastery signal is the per-turn
 * auto-assessment in /api/tutor; this just nudges mastery and the affective
 * profile. Single source of truth for the math is lib/mastery.ts.
 */
export const feedbackRoute = [
  requireUser,
  async (req: AuthedRequest, res: Response) => {
    const parse = feedbackBodySchema.safeParse(req.body);
    if (!parse.success) {
      return res.status(400).json({ ok: false, error: parse.error.issues[0]?.message ?? "Bad request" });
    }
    const { sessionId, messageId, feedback } = parse.data;
    const userId = req.user!.id;
    const supabase = serviceClient();

    try {
      // Load the message (must belong to the user) to find its skill.
      const { data: msg, error: mErr } = await supabase
        .from("messages")
        .select("id, user_id, session_id, sub_skill_id")
        .eq("id", messageId)
        .single();
      if (mErr || !msg) return res.status(404).json({ ok: false, error: "Message not found" });
      if (msg.user_id !== userId) return res.status(403).json({ ok: false, error: "Forbidden" });

      await supabase.from("messages").update({ feedback }).eq("id", messageId);

      const correct = feedback === "got_it";
      let knowledgeUpdate: any = null;

      if (msg.sub_skill_id) {
        const { data: ksRow } = await supabase
          .from("knowledge_state")
          .select("mastery, attempts, correct, streak, confidence, error_tags, last_practiced_at")
          .eq("user_id", userId)
          .eq("sub_skill_id", msg.sub_skill_id)
          .maybeSingle();

        const cur: MasteryState = ksRow
          ? {
              mastery: Number(ksRow.mastery),
              attempts: ksRow.attempts ?? 0,
              correct: ksRow.correct ?? 0,
              streak: ksRow.streak ?? 0,
              confidence: Number(ksRow.confidence ?? 0),
            }
          : freshState();
        const errorTags: string[] = ksRow?.error_tags ?? [];

        const now = new Date();
        const decayed: MasteryState = { ...cur, mastery: applyDecay(cur.mastery, ksRow?.last_practiced_at, now) };
        // Manual feedback is a weak, low-confidence signal vs. the auto-assessment.
        const next = applyEvidence(decayed, { correct, evidenceStrength: "weak", plannerConfidence: 0.5 });

        await supabase.from("knowledge_state").upsert(
          {
            user_id: userId,
            sub_skill_id: msg.sub_skill_id,
            mastery: next.mastery,
            attempts: next.attempts,
            correct: next.correct,
            streak: next.streak,
            confidence: next.confidence,
            error_tags: errorTags,
            last_practiced_at: now.toISOString(),
          },
          { onConflict: "user_id,sub_skill_id" }
        );

        await supabase.from("knowledge_events").insert({
          user_id: userId,
          session_id: sessionId,
          sub_skill_id: msg.sub_skill_id,
          event_type: "feedback",
          correct,
          evidence_strength: "weak",
          planner_confidence: 0.5,
          mastery_before: decayed.mastery,
          mastery_after: next.mastery,
        });

        knowledgeUpdate = { sub_skill_id: msg.sub_skill_id, mastery: next.mastery, attempts: next.attempts };
      }

      // Nudge the affective profile from the tap.
      const affect: Affect = feedback === "got_it" ? "confident" : "confused";
      const { data: prof } = await supabase
        .from("profiles")
        .select("learner_state")
        .eq("user_id", userId)
        .maybeSingle();
      const prev = (prof?.learner_state as any) ?? defaultLearnerState();
      await supabase
        .from("profiles")
        .update({ learner_state: updateLearnerState(prev, affect) })
        .eq("user_id", userId);

      return res.json({ ok: true, knowledge_update: knowledgeUpdate });
    } catch (e) {
      console.error("feedback fatal", e);
      return res.status(500).json({ ok: false, error: e instanceof Error ? e.message : "Unknown error" });
    }
  },
];
