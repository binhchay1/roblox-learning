import { Router } from "express";
import type { PoolClient } from "pg";
import { pool } from "../db.js";
import { requireGameSecret } from "../middleware/gameAuth.js";

type UserRow = {
  id: string;
  school_id: string | null;
  metadata: Record<string, unknown> | null;
};

type QuestRow = {
  id: string;
  code: string;
  is_premium: boolean;
  dungeon_slug: string | null;
};

function toPositiveInt(raw: unknown): number | null {
  const value = Number(raw);
  if (!Number.isInteger(value) || value <= 0) {
    return null;
  }
  return value;
}

async function findUserAndQuest(
  client: PoolClient,
  robloxUserId: number,
  questCode: string
) {
  const userResult = await client.query<UserRow>(
    `
      SELECT id, school_id, metadata
      FROM users
      WHERE roblox_user_id = $1
      LIMIT 1
    `,
    [robloxUserId]
  );

  if (userResult.rowCount === 0) {
    return { user: null, quest: null };
  }

  const user = userResult.rows[0];
  const questResult = await client.query<QuestRow>(
    `
      SELECT id, code, is_premium, dungeon_slug
      FROM quests
      WHERE code = $1
        AND (school_id IS NULL OR school_id = $2)
      ORDER BY
        CASE
          WHEN school_id = $2 THEN 0
          ELSE 1
        END
      LIMIT 1
    `,
    [questCode, user.school_id]
  );

  if (questResult.rowCount === 0) {
    return { user, quest: null };
  }

  return {
    user,
    quest: questResult.rows[0],
  };
}

function hasPremiumAccess(
  userMetadata: Record<string, unknown> | null,
  questCode: string,
  dungeonSlug: string | null
) {
  if (!userMetadata) {
    return false;
  }

  if (userMetadata.premium_access === true) {
    return true;
  }

  const premiumQuests = userMetadata.premium_quests;
  if (Array.isArray(premiumQuests) && premiumQuests.includes(questCode)) {
    return true;
  }

  if (dungeonSlug) {
    const premiumDungeons = userMetadata.premium_dungeons;
    if (Array.isArray(premiumDungeons) && premiumDungeons.includes(dungeonSlug)) {
      return true;
    }
  }

  return false;
}

export const gameRouter = Router();

gameRouter.use(requireGameSecret);

gameRouter.post("/submit-score", async (req, res) => {
  const robloxUserId = toPositiveInt(req.body?.robloxUserId);
  const points = Number(req.body?.points);
  const questCode =
    typeof req.body?.questCode === "string" ? req.body.questCode.trim() : "";
  const correctCount =
    req.body?.correctCount === undefined ? null : Number(req.body.correctCount);
  const totalCount =
    req.body?.totalCount === undefined ? null : Number(req.body.totalCount);
  const clientAttemptId =
    typeof req.body?.clientAttemptId === "string"
      ? req.body.clientAttemptId.slice(0, 200)
      : null;

  if (!robloxUserId || !questCode || !Number.isFinite(points) || points < 0) {
    return res.status(400).json({
      success: false,
      error: "Invalid payload: robloxUserId, questCode, points are required.",
    });
  }

  if (
    (correctCount !== null && (!Number.isFinite(correctCount) || correctCount < 0)) ||
    (totalCount !== null && (!Number.isFinite(totalCount) || totalCount < 0))
  ) {
    return res.status(400).json({
      success: false,
      error: "Invalid payload: correctCount/totalCount must be >= 0.",
    });
  }

  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const { user, quest } = await findUserAndQuest(client, robloxUserId, questCode);

    if (!user) {
      await client.query("ROLLBACK");
      return res.status(404).json({
        success: false,
        error: "User not found for robloxUserId.",
      });
    }

    if (!quest) {
      await client.query("ROLLBACK");
      return res.status(404).json({
        success: false,
        error: "Quest not found for this school/global scope.",
      });
    }

    const insertResult = await client.query<{ id: string }>(
      `
        INSERT INTO scores
          (user_id, quest_id, points, correct_count, total_count, client_attempt_id, metadata)
        VALUES
          ($1, $2, $3, $4, $5, $6, $7::jsonb)
        RETURNING id
      `,
      [
        user.id,
        quest.id,
        Math.floor(points),
        correctCount === null ? null : Math.floor(correctCount),
        totalCount === null ? null : Math.floor(totalCount),
        clientAttemptId,
        JSON.stringify({ source: "roblox" }),
      ]
    );

    await client.query("COMMIT");
    return res.status(201).json({
      success: true,
      data: {
        scoreId: insertResult.rows[0].id,
        robloxUserId,
        questCode: quest.code,
      },
    });
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("[submit-score] error", error);
    return res.status(500).json({
      success: false,
      error: "Internal server error.",
    });
  } finally {
    client.release();
  }
});

gameRouter.get("/check-access", async (req, res) => {
  const robloxUserId = toPositiveInt(req.query.robloxUserId);
  const questCode =
    typeof req.query.questCode === "string" ? req.query.questCode.trim() : "";

  if (!robloxUserId || !questCode) {
    return res.status(400).json({
      success: false,
      error: "Missing query params: robloxUserId, questCode.",
    });
  }

  const client = await pool.connect();
  try {
    const { user, quest } = await findUserAndQuest(client, robloxUserId, questCode);

    if (!user) {
      return res.status(404).json({
        success: false,
        error: "User not found for robloxUserId.",
      });
    }

    if (!quest) {
      return res.status(404).json({
        success: false,
        error: "Quest not found for this school/global scope.",
      });
    }

    if (!quest.is_premium) {
      return res.status(200).json({
        success: true,
        data: {
          allowed: true,
          reason: "free_quest",
          questCode: quest.code,
        },
      });
    }

    const premiumAllowed = hasPremiumAccess(user.metadata, quest.code, quest.dungeon_slug);
    return res.status(200).json({
      success: true,
      data: {
        allowed: premiumAllowed,
        reason: premiumAllowed ? "premium_unlocked" : "payment_required",
        questCode: quest.code,
      },
    });
  } catch (error) {
    console.error("[check-access] error", error);
    return res.status(500).json({
      success: false,
      error: "Internal server error.",
    });
  } finally {
    client.release();
  }
});
