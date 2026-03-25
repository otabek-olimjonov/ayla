-- =============================================================================
-- Ayla – Database Functions & Triggers
-- =============================================================================
-- Run order: 3 of 3
-- Description: RPCs called by the Flutter app via supabase.rpc(), auto-profile
--              creation on signup, and partner code helpers.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- RPC: increment_post_likes
-- Called by: community_repository.dart → _client.rpc('increment_post_likes', ...)
-- Security DEFINER so it bypasses the UPDATE restriction on community_posts.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.increment_post_likes(post_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.community_posts
  SET likes_count = likes_count + 1
  WHERE id = post_id;
END;
$$;

-- Only authenticated users may call this.
REVOKE ALL ON FUNCTION public.increment_post_likes(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.increment_post_likes(uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- RPC: link_partner_by_code
-- Called by: partner_repository.dart → _client.rpc('link_partner_by_code', ...)
-- Resolves the partner_code to a user_id and creates a partner_link row.
-- Returns the new link id, or NULL if code not found.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.link_partner_by_code(p_code text)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_owner_id  uuid;
  v_link_id   uuid;
BEGIN
  -- Find the profile that owns this partner_code
  SELECT id INTO v_owner_id
  FROM public.profiles
  WHERE partner_code = upper(trim(p_code))
  LIMIT 1;

  IF v_owner_id IS NULL THEN
    RETURN NULL;                          -- code not found
  END IF;

  IF v_owner_id = auth.uid() THEN
    RAISE EXCEPTION 'You cannot link to your own account';
  END IF;

  INSERT INTO public.partner_links (user_id, partner_user_id, status)
  VALUES (v_owner_id, auth.uid(), 'active')
  ON CONFLICT (user_id, partner_user_id) DO UPDATE
    SET status = 'active'
  RETURNING id INTO v_link_id;

  RETURN v_link_id;
END;
$$;

REVOKE ALL ON FUNCTION public.link_partner_by_code(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.link_partner_by_code(text) TO authenticated;

-- ---------------------------------------------------------------------------
-- RPC: activate_user_plan
-- Called by: admin via Supabase Studio / admin API after payment confirmed.
-- Accepts 'month' or 'year' as duration.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.activate_user_plan(
  p_user_id  uuid,
  p_duration text DEFAULT 'month'    -- 'month' | 'year'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_duration NOT IN ('month', 'year') THEN
    RAISE EXCEPTION 'Invalid duration: %', p_duration;
  END IF;

  UPDATE public.profiles
  SET plan_expires_at = CASE
    WHEN p_duration = 'month' THEN now() + INTERVAL '1 month'
    WHEN p_duration = 'year'  THEN now() + INTERVAL '1 year'
  END
  WHERE id = p_user_id;

  -- Mark payment request as approved
  UPDATE public.payment_requests
  SET status = 'approved'
  WHERE user_id = p_user_id
    AND status = 'pending';
END;
$$;

-- Admin only — not exposed to anon/authenticated roles.
REVOKE ALL ON FUNCTION public.activate_user_plan(uuid, text) FROM PUBLIC;

-- ---------------------------------------------------------------------------
-- TRIGGER: auto-create profile row when a new user signs up
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, created_at, updated_at)
  VALUES (NEW.id, now(), now())
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.notification_settings (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ---------------------------------------------------------------------------
-- FUNCTION: generate_partner_code (utility — called from app or trigger)
-- Generates a unique 6-character alphanumeric code (no O/0/I/1).
-- Does not auto-assign; the Flutter app calls saveProfile() with the code it
-- already generated. This function is provided for admin/seed use.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.generate_partner_code()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_code    text;
  v_chars   text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_exists  boolean;
BEGIN
  LOOP
    v_code := '';
    FOR i IN 1..6 LOOP
      v_code := v_code || substr(v_chars, floor(random() * length(v_chars) + 1)::int, 1);
    END LOOP;

    SELECT EXISTS (
      SELECT 1 FROM public.profiles WHERE partner_code = v_code
    ) INTO v_exists;

    EXIT WHEN NOT v_exists;
  END LOOP;

  RETURN v_code;
END;
$$;

REVOKE ALL ON FUNCTION public.generate_partner_code() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.generate_partner_code() TO authenticated;
