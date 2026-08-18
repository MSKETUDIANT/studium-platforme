-- Module Ambassadeur (EPIC 10) : colonnes additives, RLS, RPC d'inscription
-- via parrainage, et trigger de conversion filleul -> commission.

-- 1) Colonnes additives sur referrals (non destructives)
ALTER TABLE public.referrals
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now(),
  ADD COLUMN IF NOT EXISTS converted_application_id uuid REFERENCES public.applications(id),
  ADD COLUMN IF NOT EXISTS converted_at timestamptz;

-- 2) RLS : referrals
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ambassador_select_own_referrals" ON public.referrals
  FOR SELECT
  USING (ambassador_user_id = auth.uid());

CREATE POLICY "staff_select_all_referrals" ON public.referrals
  FOR SELECT
  USING (public.is_team_member());

-- 3) RLS : commissions
ALTER TABLE public.commissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ambassador_select_own_commissions" ON public.commissions
  FOR SELECT
  USING (ambassador_user_id = auth.uid());

CREATE POLICY "staff_select_all_commissions" ON public.commissions
  FOR SELECT
  USING (public.is_team_member());

CREATE POLICY "staff_update_commissions" ON public.commissions
  FOR UPDATE
  USING (public.is_team_member());

-- 4) RPC : enregistre le parrainage a l'inscription du filleul
CREATE OR REPLACE FUNCTION public.register_referral(p_ambassador_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF p_ambassador_id IS NULL OR p_ambassador_id = auth.uid() THEN
    RETURN;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.user_roles ur
    JOIN public.roles r ON r.id = ur.role_id
    WHERE ur.user_id = p_ambassador_id AND r.name = 'ambassador'
  ) THEN
    RETURN;
  END IF;

  INSERT INTO public.referrals (ambassador_user_id, student_user_id, status)
  VALUES (p_ambassador_id, auth.uid(), 'registered');
END;
$$;

ALTER FUNCTION public.register_referral(uuid) OWNER TO postgres;

-- 5) Trigger : conversion du filleul + commission a l'acceptation d'une candidature
CREATE OR REPLACE FUNCTION public.handle_application_accepted()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_referral      public.referrals%ROWTYPE;
  v_period_start  date;
  v_period_end    date;
  v_flat_amount   numeric := 50;
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status AND NEW.status = 'accepted' THEN

    SELECT * INTO v_referral
    FROM public.referrals
    WHERE student_user_id = NEW.student_profile_id
      AND status = 'registered'
    LIMIT 1
    FOR UPDATE;

    IF FOUND THEN
      UPDATE public.referrals
      SET status = 'converted',
          converted_application_id = NEW.id,
          converted_at = now(),
          updated_at = now()
      WHERE id = v_referral.id;

      v_period_start := date_trunc('month', now())::date;
      v_period_end   := (date_trunc('month', now()) + interval '1 month - 1 day')::date;

      UPDATE public.commissions
      SET amount = amount + v_flat_amount
      WHERE ambassador_user_id = v_referral.ambassador_user_id
        AND period_start = v_period_start
        AND status = 'pending';

      IF NOT FOUND THEN
        INSERT INTO public.commissions (ambassador_user_id, amount, status, period_start, period_end)
        VALUES (v_referral.ambassador_user_id, v_flat_amount, 'pending', v_period_start, v_period_end);
      END IF;

      INSERT INTO audit_logs (action, entity_type, entity_id, old_value, new_value, actor_id, actor_email)
      VALUES ('referral_converted', 'referrals', v_referral.id, 'registered', 'converted',
              auth.uid(), (auth.jwt() ->> 'email'));
    END IF;

  END IF;
  RETURN NEW;
END;
$$;

ALTER FUNCTION public.handle_application_accepted() OWNER TO postgres;

CREATE TRIGGER trg_application_accepted
  AFTER UPDATE ON public.applications
  FOR EACH ROW EXECUTE FUNCTION public.handle_application_accepted();
