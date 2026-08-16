-- Phase 5: prevent duplicate activity notifications at the source.
-- Run in Supabase SQL Editor on project lmohyfcmiftvuluhyaqh.
--
-- Root cause (from production audit):
--   Identical rows at the same timestamp (like ×2, follow ×2) while only one
--   trigger name is attached. Likely historical double-call inside notify_*
--   or a race. Fix: make create_notification idempotent for a short window.
--
-- Does NOT delete historical duplicates (optional cleanup query at bottom).

CREATE OR REPLACE FUNCTION public.create_notification(
  p_user_id uuid,
  p_actor_id uuid,
  p_type text,
  p_post_id uuid DEFAULT NULL,
  p_comment_id uuid DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  -- No self-notify
  IF p_user_id IS NULL OR p_actor_id IS NULL OR p_user_id = p_actor_id THEN
    RETURN;
  END IF;

  -- Idempotency window: ignore identical events within 5 seconds
  IF EXISTS (
    SELECT 1
    FROM public.notifications n
    WHERE n.user_id = p_user_id
      AND n.actor_id = p_actor_id
      AND n.type = p_type
      AND n.post_id IS NOT DISTINCT FROM p_post_id
      AND n.comment_id IS NOT DISTINCT FROM p_comment_id
      AND n.created_at > (timezone('utc', now()) - interval '5 seconds')
  ) THEN
    RETURN;
  END IF;

  INSERT INTO public.notifications (user_id, actor_id, type, post_id, comment_id)
  VALUES (p_user_id, p_actor_id, p_type, p_post_id, p_comment_id);
END;
$function$;

-- Drop orphan legacy trigger functions if they are still attached elsewhere.
-- Safe if they do not exist.
DO $$
BEGIN
  -- If any leftover triggers still call old names, detach them.
  IF EXISTS (
    SELECT 1 FROM pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND NOT t.tgisinternal
      AND t.tgname LIKE 'trg_notify_%'
  ) THEN
    DROP TRIGGER IF EXISTS trg_notify_on_like ON public.likes;
    DROP TRIGGER IF EXISTS trg_notify_on_dislike ON public.dislikes;
    DROP TRIGGER IF EXISTS trg_notify_on_comment ON public.comments;
    DROP TRIGGER IF EXISTS trg_notify_on_follow ON public.follows;
    DROP TRIGGER IF EXISTS trg_notify_on_new_post ON public.posts;
    DROP TRIGGER IF EXISTS trg_dispatch_push_on_notification ON public.notifications;
  END IF;
END $$;

-- ── Investigation (read-only) ──────────────────────────────────────────
-- Find recent duplicate pairs:
/*
SELECT user_id, actor_id, type, post_id, count(*), min(created_at), max(created_at)
FROM public.notifications
WHERE created_at > now() - interval '7 days'
GROUP BY user_id, actor_id, type, post_id, comment_id
HAVING count(*) > 1
ORDER BY count(*) DESC
LIMIT 50;
*/

-- Optional one-time cleanup of exact dupes keeping oldest id:
/*
DELETE FROM public.notifications n
USING public.notifications d
WHERE n.user_id = d.user_id
  AND n.actor_id = d.actor_id
  AND n.type = d.type
  AND n.post_id IS NOT DISTINCT FROM d.post_id
  AND n.comment_id IS NOT DISTINCT FROM d.comment_id
  AND n.created_at = d.created_at
  AND n.id > d.id;
*/
