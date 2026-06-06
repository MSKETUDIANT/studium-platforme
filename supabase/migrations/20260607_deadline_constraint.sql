-- Empêche la création d'une candidature pour un programme dont la deadline est dépassée.
-- La contrainte est évaluée à l'INSERT uniquement (pas de modification rétroactive).

CREATE OR REPLACE FUNCTION check_program_deadline()
RETURNS TRIGGER AS $$
DECLARE
  prog_deadline DATE;
BEGIN
  SELECT deadline INTO prog_deadline
  FROM programs
  WHERE id = NEW.program_id;

  -- Si le programme n'a pas de deadline, on autorise
  IF prog_deadline IS NULL THEN
    RETURN NEW;
  END IF;

  -- Bloquer si la deadline est dépassée (jour entier)
  IF prog_deadline < CURRENT_DATE THEN
    RAISE EXCEPTION 'La date limite de candidature pour ce programme est dépassée (deadline : %).',
      prog_deadline
      USING ERRCODE = 'check_violation';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger uniquement sur INSERT (les candidatures existantes ne sont pas affectées)
DROP TRIGGER IF EXISTS trg_check_program_deadline ON applications;
CREATE TRIGGER trg_check_program_deadline
  BEFORE INSERT ON applications
  FOR EACH ROW
  EXECUTE FUNCTION check_program_deadline();
