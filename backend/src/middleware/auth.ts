import type { Request, Response, NextFunction } from "express";
import { anonClient } from "../lib/supabase.js";

export interface AuthedRequest extends Request {
  user?: { id: string; email?: string };
}

/**
 * Verifies the Supabase JWT in the Authorization header.
 * On success: attaches req.user and calls next().
 * On failure: responds 401.
 */
export async function requireUser(req: AuthedRequest, res: Response, next: NextFunction) {
  const auth = req.headers.authorization;
  if (!auth?.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Missing Bearer token" });
  }
  const jwt = auth.slice(7);
  const { data, error } = await anonClient().auth.getUser(jwt);
  if (error || !data.user) {
    return res.status(401).json({ error: "Invalid or expired token" });
  }
  req.user = { id: data.user.id, email: data.user.email ?? undefined };
  next();
}

/**
 * Optional auth: attaches req.user when a valid token is present, otherwise
 * leaves it undefined (used by /api/tutor which supports guest mode).
 */
export async function optionalUser(req: AuthedRequest, _res: Response, next: NextFunction) {
  const auth = req.headers.authorization;
  if (!auth?.startsWith("Bearer ")) return next();
  const jwt = auth.slice(7);
  try {
    const { data } = await anonClient().auth.getUser(jwt);
    if (data.user) req.user = { id: data.user.id, email: data.user.email ?? undefined };
  } catch {
    // Ignore — treat as anonymous
  }
  next();
}
