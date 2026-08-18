-- Code de parrainage lisible (prenom + indicatif pays), en remplacement
-- du lien base sur l'uuid brut de l'ambassadeur.
-- Table de reference indicatifs pays alimentee depuis les memes donnees
-- que le country_picker utilise deja cote mobile (lib/src/res/country_codes.dart),
-- pour garantir une correspondance exacte avec les valeurs stockees dans
-- student_profiles.nationality / country_residence.

CREATE EXTENSION IF NOT EXISTS unaccent;

CREATE TABLE IF NOT EXISTS public.country_calling_codes (
  country_name text PRIMARY KEY,
  calling_code text NOT NULL
);

INSERT INTO public.country_calling_codes (calling_code, country_name) VALUES
  ('93', 'Afghanistan'),
  ('358', 'Åland Islands'),
  ('355', 'Albania'),
  ('213', 'Algeria'),
  ('1', 'American Samoa'),
  ('376', 'Andorra'),
  ('244', 'Angola'),
  ('1', 'Anguilla'),
  ('1', 'Antigua and Barbuda'),
  ('54', 'Argentina'),
  ('374', 'Armenia'),
  ('297', 'Aruba'),
  ('247', 'Ascension Island'),
  ('61', 'Australia'),
  ('43', 'Austria'),
  ('994', 'Azerbaijan'),
  ('1', 'Bahamas'),
  ('973', 'Bahrain'),
  ('880', 'Bangladesh'),
  ('1', 'Barbados'),
  ('375', 'Belarus'),
  ('32', 'Belgium'),
  ('501', 'Belize'),
  ('229', 'Benin'),
  ('1', 'Bermuda'),
  ('975', 'Bhutan'),
  ('591', 'Bolivia'),
  ('387', 'Bosnia and Herzegovina'),
  ('267', 'Botswana'),
  ('55', 'Brazil'),
  ('246', 'British Indian Ocean Territory'),
  ('1', 'British Virgin Islands'),
  ('673', 'Brunei'),
  ('359', 'Bulgaria'),
  ('226', 'Burkina Faso'),
  ('257', 'Burundi'),
  ('855', 'Cambodia'),
  ('237', 'Cameroon'),
  ('1', 'Canada'),
  ('238', 'Cape Verde'),
  ('599', 'Caribbean Netherlands'),
  ('1', 'Cayman Islands'),
  ('236', 'Central African Republic'),
  ('235', 'Chad'),
  ('56', 'Chile'),
  ('86', 'China'),
  ('61', 'Christmas Island'),
  ('61', 'Cocos [Keeling] Islands'),
  ('57', 'Colombia'),
  ('269', 'Comoros'),
  ('243', 'Democratic Republic Congo'),
  ('242', 'Republic of Congo'),
  ('682', 'Cook Islands'),
  ('506', 'Costa Rica'),
  ('225', 'Côte d''Ivoire'),
  ('385', 'Croatia'),
  ('53', 'Cuba'),
  ('599', 'Curaçao'),
  ('357', 'Cyprus'),
  ('420', 'Czech Republic'),
  ('45', 'Denmark'),
  ('253', 'Djibouti'),
  ('1', 'Dominica'),
  ('1', 'Dominican Republic'),
  ('670', 'East Timor'),
  ('593', 'Ecuador'),
  ('20', 'Egypt'),
  ('503', 'El Salvador'),
  ('240', 'Equatorial Guinea'),
  ('291', 'Eritrea'),
  ('372', 'Estonia'),
  ('268', 'Eswatini'),
  ('251', 'Ethiopia'),
  ('500', 'Falkland Islands [Islas Malvinas]'),
  ('298', 'Faroe Islands'),
  ('679', 'Fiji'),
  ('358', 'Finland'),
  ('33', 'France'),
  ('594', 'French Guiana'),
  ('689', 'French Polynesia'),
  ('241', 'Gabon'),
  ('220', 'Gambia'),
  ('995', 'Georgia'),
  ('49', 'Germany'),
  ('233', 'Ghana'),
  ('350', 'Gibraltar'),
  ('30', 'Greece'),
  ('299', 'Greenland'),
  ('1', 'Grenada'),
  ('590', 'Guadeloupe'),
  ('1', 'Guam'),
  ('502', 'Guatemala'),
  ('44', 'Guernsey'),
  ('224', 'Guinea Conakry'),
  ('245', 'Guinea-Bissau'),
  ('592', 'Guyana'),
  ('509', 'Haiti'),
  ('672', 'Heard Island and McDonald Islands'),
  ('504', 'Honduras'),
  ('852', 'Hong Kong'),
  ('36', 'Hungary'),
  ('354', 'Iceland'),
  ('91', 'India'),
  ('62', 'Indonesia'),
  ('98', 'Iran'),
  ('964', 'Iraq'),
  ('353', 'Ireland'),
  ('44', 'Isle of Man'),
  ('972', 'Israel'),
  ('39', 'Italy'),
  ('1', 'Jamaica'),
  ('81', 'Japan'),
  ('44', 'Jersey'),
  ('962', 'Jordan'),
  ('7', 'Kazakhstan'),
  ('254', 'Kenya'),
  ('686', 'Kiribati'),
  ('383', 'Kosovo'),
  ('965', 'Kuwait'),
  ('996', 'Kyrgyzstan'),
  ('856', 'Laos'),
  ('371', 'Latvia'),
  ('961', 'Lebanon'),
  ('266', 'Lesotho'),
  ('231', 'Liberia'),
  ('218', 'Libya'),
  ('423', 'Liechtenstein'),
  ('370', 'Lithuania'),
  ('352', 'Luxembourg'),
  ('853', 'Macau'),
  ('389', 'North Macedonia'),
  ('261', 'Madagascar'),
  ('265', 'Malawi'),
  ('60', 'Malaysia'),
  ('960', 'Maldives'),
  ('223', 'Mali'),
  ('356', 'Malta'),
  ('692', 'Marshall Islands'),
  ('596', 'Martinique'),
  ('222', 'Mauritania'),
  ('230', 'Mauritius'),
  ('262', 'Mayotte'),
  ('52', 'Mexico'),
  ('691', 'Micronesia'),
  ('373', 'Moldova'),
  ('377', 'Monaco'),
  ('976', 'Mongolia'),
  ('382', 'Montenegro'),
  ('1', 'Montserrat'),
  ('212', 'Morocco'),
  ('258', 'Mozambique'),
  ('95', 'Myanmar [Burma]'),
  ('264', 'Namibia'),
  ('674', 'Nauru'),
  ('977', 'Nepal'),
  ('31', 'Netherlands'),
  ('687', 'New Caledonia'),
  ('64', 'New Zealand'),
  ('505', 'Nicaragua'),
  ('227', 'Niger'),
  ('234', 'Nigeria'),
  ('683', 'Niue'),
  ('672', 'Norfolk Island'),
  ('850', 'North Korea'),
  ('1', 'Northern Mariana Islands'),
  ('47', 'Norway'),
  ('968', 'Oman'),
  ('92', 'Pakistan'),
  ('680', 'Palau'),
  ('970', 'Palestinian Territories'),
  ('507', 'Panama'),
  ('675', 'Papua New Guinea'),
  ('595', 'Paraguay'),
  ('51', 'Peru'),
  ('63', 'Philippines'),
  ('48', 'Poland'),
  ('351', 'Portugal'),
  ('1', 'Puerto Rico'),
  ('974', 'Qatar'),
  ('262', 'Réunion'),
  ('40', 'Romania'),
  ('7', 'Russia'),
  ('250', 'Rwanda'),
  ('590', 'Saint Barthélemy'),
  ('290', 'Saint Helena'),
  ('1', 'St. Kitts'),
  ('1', 'St. Lucia'),
  ('590', 'Saint Martin'),
  ('508', 'Saint Pierre and Miquelon'),
  ('1', 'St. Vincent'),
  ('685', 'Samoa'),
  ('378', 'San Marino'),
  ('239', 'São Tomé and Príncipe'),
  ('966', 'Saudi Arabia'),
  ('221', 'Senegal'),
  ('381', 'Serbia'),
  ('248', 'Seychelles'),
  ('232', 'Sierra Leone'),
  ('65', 'Singapore'),
  ('1', 'Sint Maarten'),
  ('421', 'Slovakia'),
  ('386', 'Slovenia'),
  ('677', 'Solomon Islands'),
  ('252', 'Somalia'),
  ('27', 'South Africa'),
  ('500', 'South Georgia and the South Sandwich Islands'),
  ('82', 'South Korea'),
  ('211', 'South Sudan'),
  ('34', 'Spain'),
  ('94', 'Sri Lanka'),
  ('249', 'Sudan'),
  ('597', 'Suriname'),
  ('47', 'Svalbard and Jan Mayen'),
  ('46', 'Sweden'),
  ('41', 'Switzerland'),
  ('963', 'Syria'),
  ('886', 'Taiwan'),
  ('992', 'Tajikistan'),
  ('255', 'Tanzania'),
  ('66', 'Thailand'),
  ('228', 'Togo'),
  ('690', 'Tokelau'),
  ('676', 'Tonga'),
  ('1', 'Trinidad/Tobago'),
  ('216', 'Tunisia'),
  ('90', 'Turkey'),
  ('993', 'Turkmenistan'),
  ('1', 'Turks and Caicos Islands'),
  ('688', 'Tuvalu'),
  ('1', 'U.S. Virgin Islands'),
  ('256', 'Uganda'),
  ('380', 'Ukraine'),
  ('971', 'United Arab Emirates'),
  ('44', 'United Kingdom'),
  ('1', 'United States'),
  ('598', 'Uruguay'),
  ('998', 'Uzbekistan'),
  ('678', 'Vanuatu'),
  ('379', 'Vatican City'),
  ('58', 'Venezuela'),
  ('84', 'Vietnam'),
  ('681', 'Wallis and Futuna'),
  ('212', 'Western Sahara'),
  ('967', 'Yemen'),
  ('260', 'Zambia'),
  ('263', 'Zimbabwe')
ON CONFLICT (country_name) DO NOTHING;

-- Colonne code de parrainage sur le profil (les ambassadeurs ont un
-- student_profiles, cf. discussion : ambassadeur = ancien etudiant)
ALTER TABLE public.student_profiles
  ADD COLUMN IF NOT EXISTS referral_code text;

CREATE UNIQUE INDEX IF NOT EXISTS uq_student_profiles_referral_code
  ON public.student_profiles (lower(referral_code))
  WHERE referral_code IS NOT NULL;

-- Genere (si besoin) et retourne le code de parrainage de l'utilisateur
-- courant : prenom (sans accents/espaces) + indicatif telephonique de son
-- pays (nationalite, ou a defaut pays de residence). Reserve aux ambassadeurs.
CREATE OR REPLACE FUNCTION public.ensure_referral_code()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_existing   text;
  v_first_name text;
  v_nationality text;
  v_residence   text;
  v_calling_code text;
  v_base       text;
  v_candidate  text;
  v_suffix     int := 0;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.user_roles ur
    JOIN public.roles r ON r.id = ur.role_id
    WHERE ur.user_id = auth.uid() AND r.name = 'ambassador'
  ) THEN
    RETURN NULL;
  END IF;

  SELECT referral_code, first_name, nationality, country_residence
  INTO v_existing, v_first_name, v_nationality, v_residence
  FROM public.student_profiles
  WHERE id = auth.uid();

  IF v_existing IS NOT NULL THEN
    RETURN v_existing;
  END IF;

  SELECT calling_code INTO v_calling_code
  FROM public.country_calling_codes
  WHERE country_name = v_nationality;

  IF v_calling_code IS NULL THEN
    SELECT calling_code INTO v_calling_code
    FROM public.country_calling_codes
    WHERE country_name = v_residence;
  END IF;

  v_base := regexp_replace(
    unaccent(coalesce(nullif(btrim(v_first_name), ''), 'ambassadeur')),
    '[^a-zA-Z]', '', 'g'
  );
  IF v_base = '' THEN
    v_base := 'ambassadeur';
  END IF;
  v_base := initcap(lower(v_base)) || coalesce(v_calling_code, '000');

  v_candidate := v_base;
  WHILE EXISTS (
    SELECT 1 FROM public.student_profiles WHERE lower(referral_code) = lower(v_candidate)
  ) LOOP
    v_suffix := v_suffix + 1;
    v_candidate := v_base || v_suffix::text;
  END LOOP;

  UPDATE public.student_profiles SET referral_code = v_candidate WHERE id = auth.uid();

  RETURN v_candidate;
END;
$$;

ALTER FUNCTION public.ensure_referral_code() OWNER TO postgres;

-- register_referral prenait un uuid brut ; on le fait desormais reposer
-- sur le code lisible, resolu cote serveur.
DROP FUNCTION IF EXISTS public.register_referral(uuid);

CREATE OR REPLACE FUNCTION public.register_referral(p_code text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_ambassador_id uuid;
BEGIN
  IF p_code IS NULL OR btrim(p_code) = '' THEN
    RETURN;
  END IF;

  SELECT sp.id INTO v_ambassador_id
  FROM public.student_profiles sp
  JOIN public.user_roles ur ON ur.user_id = sp.id
  JOIN public.roles r ON r.id = ur.role_id
  WHERE r.name = 'ambassador'
    AND lower(sp.referral_code) = lower(btrim(p_code))
  LIMIT 1;

  IF v_ambassador_id IS NULL OR v_ambassador_id = auth.uid() THEN
    RETURN;
  END IF;

  INSERT INTO public.referrals (ambassador_user_id, student_user_id, status)
  VALUES (v_ambassador_id, auth.uid(), 'registered');
END;
$$;

ALTER FUNCTION public.register_referral(text) OWNER TO postgres;
