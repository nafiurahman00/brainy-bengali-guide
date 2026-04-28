import "dotenv/config";
import express from "express";
import cors from "cors";
import { tutorRoute } from "./routes/tutor.js";
import { simulatorRoute } from "./routes/simulator.js";

const PORT = Number(process.env.PORT ?? 8787);
const ALLOWED_ORIGINS = (process.env.ALLOWED_ORIGINS ?? "")
  .split(",")
  .map((s) => s.trim())
  .filter(Boolean);

const app = express();

app.use(
  cors({
    origin: (origin, cb) => {
      // Allow no-origin (curl, server-to-server, health checks)
      if (!origin) return cb(null, true);
      if (ALLOWED_ORIGINS.length === 0 || ALLOWED_ORIGINS.includes(origin)) {
        return cb(null, true);
      }
      return cb(new Error(`Origin ${origin} not allowed by CORS`));
    },
    credentials: false,
    methods: ["GET", "POST", "OPTIONS"],
    allowedHeaders: ["Authorization", "Content-Type", "apikey"],
  })
);

// Larger limit so guest mode can submit base64 image data URLs (~5MB cap)
app.use(express.json({ limit: "10mb" }));

app.get("/health", (_req, res) => {
  res.json({ ok: true, service: "socratic-tutor-backend" });
});

app.post("/api/tutor", tutorRoute);
app.post("/api/simulator", simulatorRoute);

app.use((err: any, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error("[unhandled]", err);
  res.status(500).json({ error: err?.message ?? "Internal error" });
});

app.listen(PORT, () => {
  console.log(`▣ socratic-tutor-backend listening on :${PORT}`);
  console.log(`  Allowed origins: ${ALLOWED_ORIGINS.join(", ") || "(any)"}`);
});
