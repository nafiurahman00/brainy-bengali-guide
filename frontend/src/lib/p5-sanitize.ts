export type SanitizeResult =
  | { ok: true; code: string; warnings: string[] }
  | { ok: false; error: string };

const FORBIDDEN = [
  "loadImage(",
  "loadJSON(",
  "loadStrings(",
  "loadTable(",
  "loadXML(",
  "loadBytes(",
  "loadModel(",
  "loadShader(",
  "loadSound(",
  "fetch(",
  "XMLHttpRequest",
  "import(",
  "require(",
  "new p5(",
  "alert(",
  "prompt(",
  "confirm(",
  "document.cookie",
  "window.location",
  "eval(",
];

const COLOR_FN_ARGS_RE =
  /\b(fill|stroke|background|color|tint|colorMode)\s*\(\s*arguments\s*\)/g;

const SCRIPT_TAG_RE = /<\/?script\b[^>]*>/gi;

export function sanitizeP5Code(input: string): SanitizeResult {
  if (typeof input !== "string" || input.trim().length === 0) {
    return { ok: false, error: "Sketch is empty." };
  }

  const warnings: string[] = [];
  let code = input;

  if (SCRIPT_TAG_RE.test(code)) {
    code = code.replace(SCRIPT_TAG_RE, "");
    warnings.push("Stripped <script> tags from sketch.");
  }

  if (COLOR_FN_ARGS_RE.test(code)) {
    code = code.replace(COLOR_FN_ARGS_RE, "$1(...arguments)");
    warnings.push(
      "Auto-fixed color helper that passed `arguments` instead of spreading.",
    );
  }

  for (const token of FORBIDDEN) {
    if (code.includes(token)) {
      return {
        ok: false,
        error: `Sketch used forbidden API: ${token.replace(/\($/, "")}`,
      };
    }
  }

  const hasSetup =
    /\bfunction\s+setup\s*\(/.test(code) ||
    /\bsetup\s*=\s*(?:function\s*\(|\([^)]*\)\s*=>)/.test(code) ||
    /\bwindow\.setup\s*=/.test(code);
  if (!hasSetup) {
    return { ok: false, error: "Sketch is missing a top-level setup() function." };
  }

  const hasDraw =
    /\bfunction\s+draw\s*\(/.test(code) ||
    /\bdraw\s*=\s*(?:function\s*\(|\([^)]*\)\s*=>)/.test(code) ||
    /\bwindow\.draw\s*=/.test(code);
  if (!hasDraw) {
    return { ok: false, error: "Sketch is missing a top-level draw() function." };
  }

  if (!/\bcreateCanvas\s*\(/.test(code)) {
    return { ok: false, error: "Sketch never calls createCanvas()." };
  }

  try {
    new Function(code);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    return { ok: false, error: `Sketch has a syntax error: ${msg}` };
  }

  return { ok: true, code, warnings };
}
