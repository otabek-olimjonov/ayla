-- =============================================================================
-- Ayla – Initial Schema
-- =============================================================================
-- Run order: 1 of 3
-- Description: Creates all application tables, indexes, and auto-update triggers.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ---------------------------------------------------------------------------
-- Helper: automatically keep updated_at current
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- ===========================================================================
-- TABLE: profiles
-- One row per authenticated user.
-- ===========================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id               uuid        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  birth_year       int2,
  cycle_length     int2        NOT NULL DEFAULT 28 CHECK (cycle_length BETWEEN 15 AND 60),
  period_length    int2        NOT NULL DEFAULT 5  CHECK (period_length BETWEEN 1 AND 14),
  language         text        NOT NULL DEFAULT 'uz'
                               CHECK (language IN ('uz', 'uz_CY', 'ru', 'en')),
  plan_expires_at  timestamptz,                           -- NULL = free tier
  mode             text        NOT NULL DEFAULT 'cycle'
                               CHECK (mode IN ('cycle', 'pregnancy')),
  pregnancy_start  date,                                  -- LMP date if pregnancy mode
  partner_code     text        UNIQUE                     -- 6-char invite code
);

CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ===========================================================================
-- TABLE: cycle_logs
-- One row per (user, date, log_type, value) combination.
-- ===========================================================================
CREATE TABLE IF NOT EXISTS public.cycle_logs (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  log_date    date        NOT NULL,
  log_type    text        NOT NULL
              CHECK (log_type IN (
                'period_start', 'period_end', 'spotting',
                'cramp', 'headache', 'bloating',
                'mood_happy', 'mood_sad', 'mood_anxious', 'mood_calm', 'mood_irritable',
                'note', 'temperature',
                'discharge_normal', 'discharge_unusual'
              )),
  value       text,
  intensity   int2        CHECK (intensity BETWEEN 1 AND 3),
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- Unique index using COALESCE (functions not allowed in inline UNIQUE constraints)
CREATE UNIQUE INDEX IF NOT EXISTS idx_cycle_logs_unique
  ON public.cycle_logs (user_id, log_date, log_type, COALESCE(value, ''));

CREATE INDEX IF NOT EXISTS idx_cycle_logs_user_date
  ON public.cycle_logs (user_id, log_date DESC);

-- ===========================================================================
-- TABLE: health_logs
-- Daily weight / water / sleep metrics.
-- ===========================================================================
CREATE TABLE IF NOT EXISTS public.health_logs (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  log_date    date        NOT NULL,
  metric      text        NOT NULL
              CHECK (metric IN ('weight', 'water', 'sleep_hours')),
  value       numeric     NOT NULL CHECK (value >= 0),
  unit        text        CHECK (unit IN ('kg', 'ml', 'hours')),
  created_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, log_date, metric)
);

CREATE INDEX IF NOT EXISTS idx_health_logs_user_date
  ON public.health_logs (user_id, log_date DESC);

-- ===========================================================================
-- TABLE: partner_links
-- Maps a woman's account to a partner's account.
-- ===========================================================================
CREATE TABLE IF NOT EXISTS public.partner_links (
  id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  partner_user_id  uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status           text        NOT NULL DEFAULT 'active'
                               CHECK (status IN ('active', 'revoked')),
  created_at       timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, partner_user_id)
);

CREATE INDEX IF NOT EXISTS idx_partner_links_user
  ON public.partner_links (user_id);
CREATE INDEX IF NOT EXISTS idx_partner_links_partner
  ON public.partner_links (partner_user_id);

-- ===========================================================================
-- TABLE: articles
-- Admin-managed health articles with multilingual content.
-- ===========================================================================
CREATE TABLE IF NOT EXISTS public.articles (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  title_uz     text        NOT NULL,
  title_uz_cy  text,
  title_ru     text,
  title_en     text,
  body_uz      text        NOT NULL,
  body_uz_cy   text,
  body_ru      text,
  body_en      text,
  category     text        NOT NULL DEFAULT 'cycle'
               CHECK (category IN ('cycle', 'pregnancy', 'nutrition', 'mental_health')),
  is_paid      boolean     NOT NULL DEFAULT false,
  published_at timestamptz NOT NULL DEFAULT now(),
  cover_url    text
);

CREATE INDEX IF NOT EXISTS idx_articles_category_paid
  ON public.articles (category, is_paid, published_at DESC);

-- ===========================================================================
-- TABLE: community_posts
-- Anonymous-by-default user posts in the community forum.
-- ===========================================================================
CREATE TABLE IF NOT EXISTS public.community_posts (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  body         text        NOT NULL CHECK (char_length(body) BETWEEN 1 AND 2000),
  category     text        NOT NULL DEFAULT 'general'
               CHECK (category IN ('general', 'pregnancy', 'symptoms', 'advice')),
  is_anonymous boolean     NOT NULL DEFAULT true,
  likes_count  int4        NOT NULL DEFAULT 0 CHECK (likes_count >= 0),
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_community_posts_category
  ON public.community_posts (category, created_at DESC);

-- ===========================================================================
-- TABLE: community_comments
-- Replies to community posts.
-- ===========================================================================
CREATE TABLE IF NOT EXISTS public.community_comments (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id      uuid        NOT NULL REFERENCES public.community_posts(id) ON DELETE CASCADE,
  user_id      uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  body         text        NOT NULL CHECK (char_length(body) BETWEEN 1 AND 1000),
  is_anonymous boolean     NOT NULL DEFAULT true,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_community_comments_post
  ON public.community_comments (post_id, created_at ASC);

-- ===========================================================================
-- TABLE: notification_settings
-- Per-user notification preferences.
-- ===========================================================================
CREATE TABLE IF NOT EXISTS public.notification_settings (
  user_id                uuid        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  period_reminder        boolean     NOT NULL DEFAULT true,
  period_reminder_days   int2        NOT NULL DEFAULT 2 CHECK (period_reminder_days BETWEEN 1 AND 7),
  ovulation_reminder     boolean     NOT NULL DEFAULT true,
  pregnancy_reminder     boolean     NOT NULL DEFAULT true,
  reminder_time          time        NOT NULL DEFAULT '09:00'
);

-- ===========================================================================
-- TABLE: ai_chat_messages
-- Persisted AI assistant conversation history per user.
-- ===========================================================================
CREATE TABLE IF NOT EXISTS public.ai_chat_messages (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role        text        NOT NULL CHECK (role IN ('user', 'assistant')),
  content     text        NOT NULL CHECK (char_length(content) BETWEEN 1 AND 8000),
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ai_chat_user_time
  ON public.ai_chat_messages (user_id, created_at DESC);

-- ===========================================================================
-- TABLE: payment_requests
-- Manual payment verification flow (UZS bank transfer model).
-- ===========================================================================
CREATE TABLE IF NOT EXISTS public.payment_requests (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email       text        NOT NULL,
  status      text        NOT NULL DEFAULT 'pending'
              CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_payment_requests_status
  ON public.payment_requests (status, created_at DESC);
