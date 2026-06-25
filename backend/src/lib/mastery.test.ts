import { test } from "node:test";
import assert from "node:assert/strict";
import {
  applyEvidence,
  applyDecay,
  decideSupportLevel,
  evidenceWeight,
  freshState,
  supportLevelName,
  updateLearnerState,
} from "./mastery.js";

test("applyEvidence: a correct strong attempt raises mastery", () => {
  const s = freshState();
  const next = applyEvidence(s, { correct: true, evidenceStrength: "strong", plannerConfidence: 1 });
  assert.ok(next.mastery > s.mastery);
  assert.equal(next.attempts, 1);
  assert.equal(next.correct, 1);
  assert.equal(next.streak, 1);
  assert.ok(next.confidence > 0);
});

test("applyEvidence: a wrong attempt lowers mastery and resets streak", () => {
  const s = { ...freshState(), mastery: 0.7, streak: 3 };
  const next = applyEvidence(s, { correct: false, evidenceStrength: "strong", plannerConfidence: 1 });
  assert.ok(next.mastery < s.mastery);
  assert.equal(next.streak, 0);
});

test("applyEvidence: stronger evidence moves mastery more than weak", () => {
  const s = freshState();
  const weak = applyEvidence(s, { correct: true, evidenceStrength: "weak", plannerConfidence: 1 });
  const strong = applyEvidence(s, { correct: true, evidenceStrength: "strong", plannerConfidence: 1 });
  assert.ok(strong.mastery - s.mastery > weak.mastery - s.mastery);
});

test("applyEvidence: no evidence (weight 0) leaves state untouched", () => {
  const s = { ...freshState(), mastery: 0.55, attempts: 4 };
  const next = applyEvidence(s, { correct: true, evidenceStrength: "none", plannerConfidence: 1 });
  assert.deepEqual(next, s);
});

test("evidenceWeight scales with planner confidence", () => {
  assert.ok(evidenceWeight("strong", 1) > evidenceWeight("strong", 0.5));
  assert.equal(evidenceWeight("none", 1), 0);
});

test("applyDecay: ~half-decays toward floor after one half-life", () => {
  const now = new Date("2026-01-15T00:00:00Z");
  const last = new Date("2026-01-01T00:00:00Z"); // 14 days earlier = one half-life
  const decayed = applyDecay(0.8, last, now);
  // floor 0.2 + (0.8-0.2)*0.5 = 0.5
  assert.ok(Math.abs(decayed - 0.5) < 0.01, `expected ~0.5, got ${decayed}`);
});

test("applyDecay: no decay below floor or with no practice timestamp", () => {
  assert.equal(applyDecay(0.15, new Date("2020-01-01"), new Date()), 0.15);
  assert.equal(applyDecay(0.9, null), 0.9);
});

test("decideSupportLevel: stays Socratic by default", () => {
  assert.equal(decideSupportLevel({ struggleCount: 0, affect: "neutral", requestsAnswer: false, mastery: 0.3, correct: false }), 1);
});

test("decideSupportLevel: escalates with repeated struggle", () => {
  assert.equal(decideSupportLevel({ struggleCount: 2, affect: "neutral", requestsAnswer: false, mastery: 0.3, correct: false }), 2);
  assert.equal(decideSupportLevel({ struggleCount: 3, affect: "neutral", requestsAnswer: false, mastery: 0.3, correct: false }), 3);
});

test("decideSupportLevel: frustration relaxes help faster", () => {
  assert.equal(decideSupportLevel({ struggleCount: 3, affect: "frustrated", requestsAnswer: false, mastery: 0.3, correct: false }), 4);
});

test("decideSupportLevel: explicit request jumps to direct help", () => {
  assert.ok(decideSupportLevel({ struggleCount: 0, affect: "neutral", requestsAnswer: true, mastery: 0.3, correct: false }) >= 4);
});

test("decideSupportLevel: doing well keeps the challenge", () => {
  assert.ok(decideSupportLevel({ struggleCount: 0, affect: "confident", requestsAnswer: false, mastery: 0.85, correct: true }) <= 2);
});

test("supportLevelName maps to ladder names", () => {
  assert.equal(supportLevelName(1), "socratic");
  assert.equal(supportLevelName(5), "full_solution");
});

test("updateLearnerState: tracks a frustration streak and bumps encouragement", () => {
  let ls = updateLearnerState(null, "frustrated");
  ls = updateLearnerState(ls, "frustrated");
  assert.equal(ls.frustration_streak, 2);
  assert.equal(ls.encouragement, "high");
  assert.equal(ls.pace, "slow");
  const recovered = updateLearnerState(ls, "confident");
  assert.equal(recovered.frustration_streak, 0);
});
