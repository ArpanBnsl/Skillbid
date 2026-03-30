-- =============================================================================
-- Contract notification triggers
-- Fires push notifications when:
--   1. A new contract is created (bid accepted) → notify provider
--   2. A provider submits work (work_submitted_at goes from NULL → value)
--   3. A client approves work  (status goes from non-completed → 'completed')
--   4. A client terminates the contract → notify provider
-- =============================================================================

-- ---------- INSERT trigger: bid accepted ----------
CREATE OR REPLACE FUNCTION public.notify_contract_created()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  payload jsonb;
BEGIN
  payload := jsonb_build_object(
    'type',   'bid_accepted',
    'record', row_to_json(NEW)::jsonb
  );

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

DROP TRIGGER IF EXISTS on_contract_created ON public.contracts;
CREATE TRIGGER on_contract_created
  AFTER INSERT ON public.contracts
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_contract_created();

-- ---------- UPDATE trigger: work submitted / approved / terminated ----------
CREATE OR REPLACE FUNCTION public.notify_contract_push()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  payload  jsonb;
  notif_type text;
BEGIN
  IF NEW.work_submitted_at IS NOT NULL AND OLD.work_submitted_at IS NULL THEN
    notif_type := 'work_submitted';
  ELSIF NEW.status = 'completed' AND OLD.status IS DISTINCT FROM 'completed' THEN
    notif_type := 'work_approved';
  ELSIF NEW.status = 'terminated' AND OLD.status IS DISTINCT FROM 'terminated'
        AND NEW.terminated_by = 'client' THEN
    notif_type := 'contract_terminated';
  ELSE
    RETURN NEW;
  END IF;

  payload := jsonb_build_object(
    'type',   notif_type,
    'record', row_to_json(NEW)::jsonb
  );

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

DROP TRIGGER IF EXISTS on_contract_updated ON public.contracts;
CREATE TRIGGER on_contract_updated
  AFTER UPDATE ON public.contracts
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_contract_push();
