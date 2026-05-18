import { z } from "zod";

export const tutorBodySchema = z.object({
  sessionId: z.string().uuid().optional(),
  message: z.string().min(1, "message is required"),
  imageUrl: z.string().optional(),
  language: z.enum(["en", "bn"]).optional(),
  guest: z.boolean().optional(),
  // Guest-only fields
  subjectSlug: z.string().optional(),
  fluency: z.record(z.any()).optional(),
  scratchpad: z.any().optional(),
  history: z
    .array(
      z.object({
        role: z.enum(["user", "assistant"]),
        content: z.string(),
      })
    )
    .optional(),
});
export type TutorBody = z.infer<typeof tutorBodySchema>;

export const simulatorBodySchema = z.object({
  sessionId: z.string().uuid(),
  maxTurns: z.number().int().min(1).max(20).optional(),
});
export type SimulatorBody = z.infer<typeof simulatorBodySchema>;

export const visualizeBodySchema = z.object({
  sessionId: z.string().uuid(),
  message: z.string().min(1, "message is required"),
  imageUrl: z.string().optional(),
  language: z.enum(["en", "bn"]).optional(),
  regenerate: z.boolean().optional(),
});
export type VisualizeBody = z.infer<typeof visualizeBodySchema>;

export const visualizeRepairBodySchema = z.object({
  sessionId: z.string().uuid(),
  code: z.string().min(1, "code is required").max(40000),
  errorMessage: z.string().min(1, "errorMessage is required").max(2000),
});
export type VisualizeRepairBody = z.infer<typeof visualizeRepairBodySchema>;
