const port = Number(process.env.PORT ?? 3000);
const databaseUrl = process.env.DATABASE_URL ?? "";
const gameApiSecret = process.env.GAME_API_SECRET ?? "";

if (!databaseUrl) {
  throw new Error("Missing DATABASE_URL");
}

if (!gameApiSecret) {
  throw new Error("Missing GAME_API_SECRET");
}

export const config = {
  port,
  databaseUrl,
  gameApiSecret,
} as const;
