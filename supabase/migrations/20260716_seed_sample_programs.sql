-- Jeu de donnees de demo : 10 programmes varies (pays, niveau, cout,
-- eligibilite) pour tester le catalogue, les favoris et les
-- recommandations predictives (min_average / required_language_level).

INSERT INTO public.programs
  (program_name, university_name, country, language, level, duration, cost, deadline,
   description, domain, requirements, contact_email, is_active, min_average, required_language_level)
VALUES
  ('Licence Informatique', 'Université Paris-Saclay', 'France', 'Français', 'bachelor', '3 ans', 2770,
   '2027-03-15', 'Formation generaliste en informatique : algorithmique, developpement, reseaux.',
   'Informatique', ARRAY['CV','Relevé de notes','Lettre de motivation','Passeport'],
   'admissions@paris-saclay.fr', true, 12, 'B1'),

  ('Master Intelligence Artificielle', 'Sorbonne Université', 'France', 'Français', 'master', '2 ans', 3770,
   '2027-02-28', 'Machine learning, deep learning et traitement du langage naturel.',
   'Informatique', ARRAY['CV','Relevé de notes','Lettre de motivation','Lettre de recommandation'],
   'admissions@sorbonne-universite.fr', true, 14, 'B2'),

  ('MBA International Business', 'ESCP Business School', 'France', 'Anglais', 'master', '2 ans', 25000,
   '2027-01-31', 'Management international, strategie et finance d''entreprise.',
   'Commerce / Gestion', ARRAY['CV','Relevé de notes','Lettre de motivation','Passeport','Lettre de recommandation'],
   'admissions@escp.eu', true, 13, 'C1'),

  ('Licence Médecine', 'Université de Tunis El Manar', 'Tunisie', 'Français', 'bachelor', '6 ans', 1000,
   '2026-09-30', 'Cursus complet de medecine generale.',
   'Médecine / Santé', ARRAY['CV','Relevé de notes','Passeport'],
   'admissions@utm.tn', true, 15, NULL),

  ('Master Génie Civil', 'École Polytechnique de Montréal', 'Canada', 'Français', 'master', '2 ans', 18000,
   '2027-04-30', 'Conception et gestion de grands projets d''infrastructure.',
   'Ingénierie', ARRAY['CV','Relevé de notes','Lettre de motivation','Passeport'],
   'admissions@polymtl.ca', true, 13, 'B2'),

  ('Doctorat Sciences Sociales', 'Université Laval', 'Canada', 'Anglais', 'phd', '4 ans', 12000,
   '2027-05-15', 'Recherche doctorale en sociologie et politiques publiques.',
   'Sciences Sociales', ARRAY['CV','Relevé de notes','Lettre de motivation','Lettre de recommandation'],
   'admissions@ulaval.ca', true, 15, 'C1'),

  ('Licence Droit', 'Université Cheikh Anta Diop', 'Sénégal', 'Français', 'bachelor', '3 ans', 400,
   '2026-10-31', 'Droit public et prive, introduction au droit international.',
   'Droit', ARRAY['CV','Relevé de notes'],
   'admissions@ucad.sn', true, 10, NULL),

  ('Master Architecture', 'Université Libre de Bruxelles', 'Belgique', 'Français', 'master', '2 ans', 4175,
   '2027-03-01', 'Conception architecturale et urbanisme durable.',
   'Architecture', ARRAY['CV','Relevé de notes','Lettre de motivation','Portfolio'],
   'admissions@ulb.be', true, 12, 'B1'),

  ('Licence Sciences', 'Université Mohammed V', 'Maroc', 'Français', 'bachelor', '3 ans', 600,
   '2026-11-15', 'Tronc commun scientifique : mathematiques, physique, chimie.',
   'Sciences', ARRAY['CV','Relevé de notes','Passeport'],
   'admissions@um5.ac.ma', true, 11, NULL),

  ('Master Éducation', 'Université de Genève', 'Suisse', 'Français', 'master', '2 ans', 5000,
   '2027-02-15', 'Sciences de l''education et ingenierie pedagogique.',
   'Éducation', ARRAY['CV','Relevé de notes','Lettre de motivation'],
   'admissions@unige.ch', true, 12, 'B1');
