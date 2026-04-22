-- Edu-RPG PostgreSQL schema (Step 1)
-- Multi-tenant: schools -> users -> scores; quests can be global or school-scoped.

BEGIN;

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ---------------------------------------------------------------------------
-- Schools (tenant root)
-- ---------------------------------------------------------------------------
CREATE TABLE schools (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT NOT NULL,
  slug            TEXT NOT NULL UNIQUE,
  metadata        JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_schools_slug ON schools (slug);

-- ---------------------------------------------------------------------------
-- Users (web accounts linked to Roblox; tenant-scoped)
-- ---------------------------------------------------------------------------
CREATE TABLE users (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID REFERENCES schools (id) ON DELETE CASCADE,
  roblox_user_id  BIGINT UNIQUE,
  email           TEXT UNIQUE,
  display_name    TEXT,
  role            TEXT NOT NULL DEFAULT 'student'
    CHECK (role IN ('student', 'teacher', 'school_admin', 'platform_admin')),
  metadata        JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT users_school_scope CHECK (
    (role = 'platform_admin' AND school_id IS NULL)
    OR (role <> 'platform_admin' AND school_id IS NOT NULL)
  )
);

CREATE INDEX idx_users_school ON users (school_id);
CREATE INDEX idx_users_roblox ON users (roblox_user_id) WHERE roblox_user_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Quests (educational content / exercises; optional school override)
-- ---------------------------------------------------------------------------
CREATE TABLE quests (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID REFERENCES schools (id) ON DELETE CASCADE,
  code            TEXT NOT NULL,
  title           TEXT NOT NULL,
  subject_code    TEXT NOT NULL,
  education_tier  TEXT NOT NULL DEFAULT 'cap1'
    CHECK (education_tier IN ('cap1', 'cap2')),
  grade_band      TEXT,
  dungeon_slug    TEXT,
  is_premium      BOOLEAN NOT NULL DEFAULT false,
  metadata        JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Global quest: unique code when school_id IS NULL.
CREATE UNIQUE INDEX idx_quests_global_code ON quests (code) WHERE school_id IS NULL;
-- School-specific quest: unique (school_id, code).
CREATE UNIQUE INDEX idx_quests_school_code ON quests (school_id, code) WHERE school_id IS NOT NULL;

CREATE INDEX idx_quests_subject ON quests (subject_code);
CREATE INDEX idx_quests_tier ON quests (education_tier);
CREATE INDEX idx_quests_dungeon ON quests (dungeon_slug) WHERE dungeon_slug IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Scores (attempts / submissions from game or web)
-- ---------------------------------------------------------------------------
CREATE TABLE scores (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  quest_id          UUID NOT NULL REFERENCES quests (id) ON DELETE CASCADE,
  points            INTEGER NOT NULL CHECK (points >= 0),
  correct_count     INTEGER,
  total_count       INTEGER,
  client_attempt_id TEXT,
  metadata          JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_scores_user_time ON scores (user_id, created_at DESC);
CREATE INDEX idx_scores_quest ON scores (quest_id);

COMMENT ON TABLE schools IS 'Tenant (school). Most users belong to exactly one school.';
COMMENT ON TABLE users IS 'Internal account; roblox_user_id links to Roblox.';
COMMENT ON TABLE quests IS 'Quest/exercise; school_id NULL means system (global) quest.';
COMMENT ON TABLE scores IS 'Score submission from Roblox HttpService or LMS.';

COMMIT;
