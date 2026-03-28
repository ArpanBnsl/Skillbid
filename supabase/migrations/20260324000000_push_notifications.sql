-- =============================================================================
-- Push Notification Infrastructure
-- =============================================================================

-- 1. Device tokens table for storing FCM tokens per user/device
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.device_tokens (
  id         uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id    uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fcm_token  text        NOT NULL,
  device_id  text        NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, device_id)
);

-- RLS: users manage their own rows; the Edge Function uses service_role which
-- bypasses RLS automatically.
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert their own tokens"
  ON public.device_tokens FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own tokens"
  ON public.device_tokens FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own tokens"
  ON public.device_tokens FOR DELETE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can read their own tokens"
  ON public.device_tokens FOR SELECT
  USING (auth.uid() = user_id);

CREATE INDEX idx_device_tokens_user_id ON public.device_tokens(user_id);

-- 2. Enable pg_net extension (required for HTTP calls from triggers)
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- 3. Trigger function that POSTs to the send-notification Edge Function
-- =============================================================================

CREATE OR REPLACE FUNCTION public.notify_push()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  payload jsonb;
  notification_type text;
BEGIN
  -- Determine notification type from the source table.
  IF TG_TABLE_NAME = 'jobs' THEN
    notification_type := 'new_job';
  ELSIF TG_TABLE_NAME = 'bids' THEN
    notification_type := 'new_bid';
  ELSIF TG_TABLE_NAME = 'messages' THEN
    notification_type := 'new_message';
  ELSE
    RETURN NEW;
  END IF;

  payload := jsonb_build_object(
    'type',   notification_type,
    'record', row_to_json(NEW)::jsonb
  );

  -- Fire an async HTTP POST via pg_net.
  -- The Edge Function URL uses the project's own Supabase domain.
  -- Authorization uses the service_role key stored in Vault.
  PERFORM net.http_post(
    url     := 'https://fwsugwyorwnbvzvalykx.supabase.co/functions/v1/send-notification',
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer YOUR_SERVICE_ROLE_KEY_HERE'
    ),
    body    := payload
  );

  RETURN NEW;
END;
$$;

-- 4. Attach triggers to the relevant tables
-- =============================================================================

-- New job posted → providers get notified
CREATE TRIGGER on_job_created
  AFTER INSERT ON public.jobs
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_push();

-- New bid placed → client gets notified
CREATE TRIGGER on_bid_created
  AFTER INSERT ON public.bids
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_push();

-- New message sent → other participant gets notified
CREATE TRIGGER on_message_created
  AFTER INSERT ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_push();
