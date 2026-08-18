-- Le montant de commission ambassadeur (50) etait code en dur dans le
-- trigger, sans aucune interface pour l'ajuster. Il est desormais lu
-- depuis platform_settings (cle 'ambassador_commission_amount', geree
-- depuis Parametres > Regles & Limites cote dashboard), avec repli sur 50
-- si la cle n'existe pas encore.

CREATE OR REPLACE FUNCTION public.handle_application_accepted()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_referral      public.referrals%ROWTYPE;
  v_period_start  date;
  v_period_end    date;
  v_flat_amount   numeric;
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

      SELECT COALESCE(
        (SELECT value::numeric FROM public.platform_settings WHERE key = 'ambassador_commission_amount'),
        50
      ) INTO v_flat_amount;

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
