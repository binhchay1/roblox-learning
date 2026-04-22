import type { Request, Response, NextFunction } from "express";
import { config } from "../config.js";

const SECRET_HEADER = "x-game-secret";

export function requireGameSecret(
  req: Request,
  res: Response,
  next: NextFunction
) {
  const provided = req.header(SECRET_HEADER);
  if (!provided || provided !== config.gameApiSecret) {
    return res.status(401).json({
      success: false,
      error: "Unauthorized game client",
    });
  }

  return next();
}
