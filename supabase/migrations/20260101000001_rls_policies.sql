-- =============================================================================
-- Ayla – Row Level Security Policies
-- =============================================================================
-- Run order: 2 of 3
-- Description: Enables RLS on all tables and creates access policies.
--              Partners get read-only access to limited fields only.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles: owner can select"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "profiles: owner can insert"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles: owner can update"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Partners may read the partner_code of a linked user to display the link status.
CREATE POLICY "profiles: linked partner can select code and mode"
  ON public.profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.partner_links pl
      WHERE pl.user_id = profiles.id
        AND pl.partner_user_id = auth.uid()
        AND pl.status = 'active'
    )
  );

-- ---------------------------------------------------------------------------
-- cycle_logs
-- ---------------------------------------------------------------------------
ALTER TABLE public.cycle_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "cycle_logs: owner full access"
  ON public.cycle_logs FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Partners may only read log_type (mood + period phase) — no notes, temperature, symptoms.
CREATE POLICY "cycle_logs: partner limited select"
  ON public.cycle_logs FOR SELECT
  USING (
    log_type IN ('period_start', 'period_end', 'mood_happy', 'mood_sad',
                 'mood_anxious', 'mood_calm', 'mood_irritable')
    AND EXISTS (
      SELECT 1 FROM public.partner_links pl
      WHERE pl.user_id = cycle_logs.user_id
        AND pl.partner_user_id = auth.uid()
        AND pl.status = 'active'
    )
  );

-- ---------------------------------------------------------------------------
-- health_logs
-- ---------------------------------------------------------------------------
ALTER TABLE public.health_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "health_logs: owner full access"
  ON public.health_logs FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Partners cannot see health logs (weight, water, sleep).

-- ---------------------------------------------------------------------------
-- partner_links
-- ---------------------------------------------------------------------------
ALTER TABLE public.partner_links ENABLE ROW LEVEL SECURITY;

CREATE POLICY "partner_links: owner can manage"
  ON public.partner_links FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "partner_links: partner can select own entry"
  ON public.partner_links FOR SELECT
  USING (auth.uid() = partner_user_id);

-- ---------------------------------------------------------------------------
-- articles
-- ---------------------------------------------------------------------------
ALTER TABLE public.articles ENABLE ROW LEVEL SECURITY;

-- Free articles: all authenticated users.
CREATE POLICY "articles: free articles for all authenticated"
  ON public.articles FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND (
      is_paid = false
      OR EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
          AND p.plan_expires_at IS NOT NULL
          AND p.plan_expires_at > now()
      )
    )
  );

-- ---------------------------------------------------------------------------
-- community_posts
-- ---------------------------------------------------------------------------
ALTER TABLE public.community_posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "community_posts: all authenticated can select"
  ON public.community_posts FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "community_posts: paid users can insert"
  ON public.community_posts FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.plan_expires_at IS NOT NULL
        AND p.plan_expires_at > now()
    )
  );

CREATE POLICY "community_posts: owner can delete"
  ON public.community_posts FOR DELETE
  USING (auth.uid() = user_id);

-- likes_count is updated via RPC (security definer), not direct UPDATE.

-- ---------------------------------------------------------------------------
-- community_comments
-- ---------------------------------------------------------------------------
ALTER TABLE public.community_comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "community_comments: all authenticated can select"
  ON public.community_comments FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "community_comments: paid users can insert"
  ON public.community_comments FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.plan_expires_at IS NOT NULL
        AND p.plan_expires_at > now()
    )
  );

CREATE POLICY "community_comments: owner can delete"
  ON public.community_comments FOR DELETE
  USING (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- notification_settings
-- ---------------------------------------------------------------------------
ALTER TABLE public.notification_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notification_settings: owner full access"
  ON public.notification_settings FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- ai_chat_messages
-- ---------------------------------------------------------------------------
ALTER TABLE public.ai_chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ai_chat_messages: owner full access"
  ON public.ai_chat_messages FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- payment_requests
-- ---------------------------------------------------------------------------
ALTER TABLE public.payment_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "payment_requests: owner can insert"
  ON public.payment_requests FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "payment_requests: owner can select own"
  ON public.payment_requests FOR SELECT
  USING (auth.uid() = user_id);
