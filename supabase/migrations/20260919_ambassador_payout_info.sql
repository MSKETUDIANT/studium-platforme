-- A8 CDC : "Demande de paiement / coordonnees" se limitait a une tache
-- interne en texte libre (le montant, rien d'autre) -- aucune saisie ni
-- stockage structure d'IBAN/PayPal. Ajoute les colonnes sur student_profiles
-- (l'ambassadeur est un etudiant promu, meme table de profil) ; deja
-- couvertes par la policy "own_profile" existante (USING auth.uid() = id,
-- sans restriction de colonnes), donc aucune nouvelle policy necessaire.

ALTER TABLE public.student_profiles
  ADD COLUMN IF NOT EXISTS payout_method        text CHECK (payout_method IN ('iban', 'paypal')),
  ADD COLUMN IF NOT EXISTS payout_iban           text,
  ADD COLUMN IF NOT EXISTS payout_paypal_email   text;
