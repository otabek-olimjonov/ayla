-- Add email column to profiles for searchability in admin dashboard
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS email text;

-- Backfill existing profiles with email from auth.users
UPDATE public.profiles p
SET email = u.email
FROM auth.users u
WHERE p.id = u.id
  AND p.email IS NULL;

-- Trigger function: keep profiles.email in sync with auth.users.email
CREATE OR REPLACE FUNCTION public.sync_user_email()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.profiles
  SET email = NEW.email
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$;

-- Trigger on auth.users: fires on INSERT and UPDATE of email
DROP TRIGGER IF EXISTS on_auth_user_email_change ON auth.users;
CREATE TRIGGER on_auth_user_email_change
  AFTER INSERT OR UPDATE OF email ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_user_email();

-- RLS: email is still only visible to the owner (same policy as other columns)
-- No extra policy needed since the row-level policies on profiles already
-- restrict SELECT to auth.uid() = id; admin dashboard uses service_role which bypasses RLS.
