-- Étend les valeurs acceptées pour la colonne type de la table documents.
-- Les anciens types restent valides ; les nouveaux couvrent les cas courants
-- de candidature universitaire (lettre de motivation, diplôme, langue, financement).

ALTER TABLE documents DROP CONSTRAINT IF EXISTS documents_type_check;

ALTER TABLE documents ADD CONSTRAINT documents_type_check
  CHECK (type IN (
    'cv',
    'transcript',
    'recommendation',
    'passport',
    'motivation_letter',
    'diploma',
    'language_cert',
    'financial_proof',
    'other'
  ));