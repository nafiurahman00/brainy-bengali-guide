import { GoogleGenAI } from "@google/genai";

export function getAIClient(): GoogleGenAI {
  const key = process.env.GEMINI_API_KEY;
  if (!key) throw new Error("GEMINI_API_KEY is required");
  return new GoogleGenAI({ apiKey: key });
}

/** Map Gemini errors to client-friendly status codes. */
export function aiErrorStatus(err: unknown): { status: number; message: string } | null {
  const msg = err instanceof Error ? err.message : String(err);
  if (msg.includes("429") || msg.toLowerCase().includes("quota")) return { status: 429, message: "Rate limit exceeded. Try again shortly." };
  if (msg.includes("402")) return { status: 402, message: "AI credits exhausted." };
  return null;
}
