/**
 * mastery.ts — single source of truth for the learning model.
 *
 * Replaces the BKT logic that used to be duplicated in the frontend
 * (use-chat.ts, GuestSession.tsx). Pure, dependency-free, and unit-tested so
 * both the per-turn auto-assessment and the manual-feedback path go through
 * one code path. See plan Parts A & B.
 */

export type EvidenceStrength = "none" | "weak" | "moderate" | "strong";
export type Affect =
  | "frustrated"
  | "anxious"
  | "confident"
  | "neutral"
  | "confused"
  | "disengaged";

/** Help-ladder levels, 1 (most Socratic) → 5 (full worked solution). */
export type SupportLevel = 1 | 2 | 3 | 4 | 5;
export const SUPPORT_LEVEL_NAMES = [
  "socratic",
  "hint",
  "scaffold",
  "direct",
  "full_solution",
] as const;
export type SupportLevelName = (typeof SUPPORT_LEVEL_NAMES)[number];

export interface MasteryState {
  mastery: number;
  attempts: number;
  correct: number;
  streak: number;
  confidence: number;
}

// --- Tunable constants (one place for future per-skill calibration) ---
export const INITIAL_MASTERY = 0.3;
const P_LEARN = 0.1;
const P_GUESS = 0.2;
const P_SLIP = 0.1;
/** Gentle forgetting: mastery half-decays toward the floor every N days idle. */
const DECAY_HALF_LIFE_DAYS = 14;
const DECAY_FLOOR = 0.2;

const EVIDENCE_WEIGHT: Record<EvidenceStrength, number> = {
  none: 0,
  weak: 0.35,
  moderate: 0.7,
  strong: 1,
};

const clamp01 = (x: number) => Math.min(1, Math.max(0, x));

/** Combined influence of a turn: how much this evidence should move mastery. */
export function evidenceWeight(strength: EvidenceStrength, plannerConfidence = 0.7): number {
  const conf = clamp01(Number.isFinite(plannerConfidence) ? plannerConfidence : 0.7);
  return clamp01((EVIDENCE_WEIGHT[strength] ?? 0) * conf);
}

export function freshState(): MasteryState {
  return { mastery: INITIAL_MASTERY, attempts: 0, correct: 0, streak: 0, confidence: 0 };
}

/**
 * Bayesian Knowledge Tracing posterior update, scaled by evidence weight so a
 * fully-worked correct solution moves mastery far more than a one-word reply.
 * A weight of 0 (no real evidence — e.g. a clarifying question, or a turn where
 * the tutor handed over the answer) leaves the state untouched.
 */
export function applyEvidence(
  state: MasteryState,
  opts: { correct: boolean; evidenceStrength: EvidenceStrength; plannerConfidence?: number }
): MasteryState {
  const weight = evidenceWeight(opts.evidenceStrength, opts.plannerConfidence ?? 0.7);
  if (weight <= 0) return { ...state };

  const pM = clamp01(state.mastery);
  const post = opts.correct
    ? (pM * (1 - P_SLIP)) / (pM * (1 - P_SLIP) + (1 - pM) * P_GUESS)
    : (pM * P_SLIP) / (pM * P_SLIP + (1 - pM) * (1 - P_GUESS));
  const afterLearn = post + (1 - post) * P_LEARN;
  const newMastery = clamp01(pM + weight * (afterLearn - pM));

  return {
    mastery: newMastery,
    attempts: state.attempts + 1,
    correct: state.correct + (opts.correct ? 1 : 0),
    streak: opts.correct ? state.streak + 1 : 0,
    confidence: clamp01(state.confidence + weight * 0.2),
  };
}

/**
 * Exponential forgetting toward DECAY_FLOOR based on idle time. Used for the
 * AI's *internal* model and recommendations; the UI keeps the displayed % steady
 * and flags staleness instead, so students aren't discouraged by dropping numbers.
 */
export function applyDecay(mastery: number, lastPracticedAt: string | Date | null | undefined, now: Date = new Date()): number {
  if (mastery <= DECAY_FLOOR || !lastPracticedAt) return mastery;
  const last = lastPracticedAt instanceof Date ? lastPracticedAt : new Date(lastPracticedAt);
  const ms = now.getTime() - last.getTime();
  if (!Number.isFinite(ms) || ms <= 0) return mastery;
  const days = ms / 86_400_000;
  const decayed = DECAY_FLOOR + (mastery - DECAY_FLOOR) * Math.pow(0.5, days / DECAY_HALF_LIFE_DAYS);
  return Math.max(DECAY_FLOOR, Math.min(mastery, decayed));
}

const ESCALATING_AFFECT = new Set<Affect>(["frustrated", "anxious", "disengaged"]);

/**
 * Decide how much help to give this turn (the "relaxation" of the strict
 * never-reveal rule). Higher = more direct help. See plan Part A.
 */
export function decideSupportLevel(opts: {
  struggleCount: number;
  affect: Affect;
  requestsAnswer: boolean;
  mastery: number;
  correct: boolean;
}): SupportLevel {
  let level = 1;
  if (opts.struggleCount >= 3) level += 2;
  else if (opts.struggleCount >= 2) level += 1;
  if (ESCALATING_AFFECT.has(opts.affect)) level += 1;
  // Making progress → ease back off the help.
  if (opts.correct) level = Math.max(1, level - 1);
  // A student explicitly asking for the answer should not be stonewalled.
  if (opts.requestsAnswer) level = Math.max(level, 4);
  // Doing well → keep the challenge, don't over-help.
  if (opts.correct && opts.mastery > 0.7) level = Math.min(level, 2);
  return Math.min(5, Math.max(1, level)) as SupportLevel;
}

export function supportLevelName(level: SupportLevel): SupportLevelName {
  return SUPPORT_LEVEL_NAMES[level - 1];
}

// --- Persistent learner profile (affect / pace), stored in profiles.learner_state ---
export interface LearnerState {
  affect: Affect;
  frustration_streak: number;
  pace: "slow" | "normal" | "fast";
  encouragement: "low" | "normal" | "high";
  updated_at?: string;
}

export function defaultLearnerState(): LearnerState {
  return { affect: "neutral", frustration_streak: 0, pace: "normal", encouragement: "normal" };
}

/** Roll the learner profile forward from this turn's affect signal. */
export function updateLearnerState(prev: Partial<LearnerState> | null | undefined, affect: Affect): LearnerState {
  const base = { ...defaultLearnerState(), ...(prev ?? {}) };
  const frustrated = ESCALATING_AFFECT.has(affect) || affect === "confused";
  const frustration_streak = frustrated ? base.frustration_streak + 1 : 0;
  return {
    affect,
    frustration_streak,
    pace: frustration_streak >= 2 ? "slow" : base.pace === "slow" && !frustrated ? "normal" : base.pace,
    encouragement: frustration_streak >= 2 ? "high" : affect === "confident" ? "low" : "normal",
    updated_at: new Date().toISOString(),
  };
}

/** One-line summary folded into the planner + generator prompts for tailoring. */
export function summarizeLearnerState(ls: Partial<LearnerState> | null | undefined): string {
  if (!ls || Object.keys(ls).length === 0) return "(new learner — no profile yet)";
  const s = { ...defaultLearnerState(), ...ls };
  return `mood=${s.affect}, frustration_streak=${s.frustration_streak}, pace=${s.pace}, wants_encouragement=${s.encouragement}`;
}
