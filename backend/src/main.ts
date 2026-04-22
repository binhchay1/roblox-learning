import express from "express";
import { config } from "./config.js";
import { gameRouter } from "./routes/game.js";

const app = express();

app.use(express.json());

app.get("/health", (_req, res) => {
  res.status(200).json({
    success: true,
    service: "edu-rpg-api",
  });
});

app.use("/api/v1/game", gameRouter);

app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: `Route not found: ${req.method} ${req.path}`,
  });
});

app.listen(config.port, () => {
  console.log(`[edu-rpg-api] listening on :${config.port}`);
});
