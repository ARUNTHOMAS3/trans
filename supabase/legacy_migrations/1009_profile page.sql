-- ─────────────────────────────────────────────
-- Industries lookup table
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.industries (
  id         UUID         NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name       VARCHAR(255) NOT NULL UNIQUE,
  is_active  BOOLEAN      NOT NULL DEFAULT TRUE,
  sort_order SMALLINT     NOT NULL DEFAULT 0
);

INSERT INTO public.industries (name, sort_order) VALUES
  ('Agency or Sales House',            1),
  ('Agriculture',                      2),
  ('Art and Design',                   3),
  ('Automotive',                       4),
  ('Construction',                     5),
  ('Consulting',                       6),
  ('Consumer Packaged Goods',          7),
  ('Education',                        8),
  ('Engineering',                      9),
  ('Entertainment',                   10),
  ('Financial Services',              11),
  ('Food Services (Restaurants/Fast Food)', 12),
  ('Gaming',                          13),
  ('Government',                      14),
  ('Health Care',                     15),
  ('Interior Design',                 16),
  ('Internal',                        17),
  ('Legal',                           18),
  ('Manufacturing',                   19),
  ('Marketing',                       20),
  ('Mining and Logistics',            21),
  ('Non-Profit',                      22),
  ('Publishing and Web Media',        23),
  ('Real Estate',                     24),
  ('Retail (E-Commerce and Offline)', 25),
  ('Services',                        26),
  ('Technology',                      27),
  ('Telecommunications',              28),
  ('Travel/Hospitality',              29),
  ('Web Designing',                   30),
  ('Web Development',                 31),
  ('Writers',                         32)
ON CONFLICT (name) DO NOTHING;


-- ─────────────────────────────────────────────
-- Timezones lookup table (linked to countries)
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.timezones (
  id          UUID         NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name        VARCHAR(150) NOT NULL UNIQUE,   -- e.g. "India Standard Time (Asia/Calcutta)"
  tzdb_name   VARCHAR(100) NOT NULL,           -- IANA tz: "Asia/Calcutta"
  utc_offset  VARCHAR(10)  NOT NULL,           -- e.g. "+05:30"
  display     VARCHAR(255) NOT NULL,           -- e.g. "(GMT +5:30) India Standard Time (Asia/Calcutta)"
  country_id  UUID         REFERENCES public.countries(id) ON DELETE SET NULL,
  is_active   BOOLEAN      NOT NULL DEFAULT TRUE,
  sort_order  SMALLINT     NOT NULL DEFAULT 0
);

-- Seed: common timezones (extend as needed)
INSERT INTO public.timezones (name, tzdb_name, utc_offset, display, sort_order) VALUES
  ('Coordinated Universal Time (UTC)',             'UTC',              '+00:00', '(GMT +0:00) Coordinated Universal Time (UTC)',              1),
  ('India Standard Time (Asia/Calcutta)',          'Asia/Calcutta',    '+05:30', '(GMT +5:30) India Standard Time (Asia/Calcutta)',           2),
  ('Gulf Standard Time (Asia/Dubai)',              'Asia/Dubai',       '+04:00', '(GMT +4:00) Gulf Standard Time (Asia/Dubai)',               3),
  ('Singapore Standard Time (Asia/Singapore)',     'Asia/Singapore',   '+08:00', '(GMT +8:00) Singapore Standard Time (Asia/Singapore)',      4),
  ('China Standard Time (Asia/Shanghai)',          'Asia/Shanghai',    '+08:00', '(GMT +8:00) China Standard Time (Asia/Shanghai)',           5),
  ('Japan Standard Time (Asia/Tokyo)',             'Asia/Tokyo',       '+09:00', '(GMT +9:00) Japan Standard Time (Asia/Tokyo)',              6),
  ('Eastern Standard Time (America/New_York)',     'America/New_York', '-05:00', '(GMT -5:00) Eastern Standard Time (America/New_York)',      7),
  ('Central Standard Time (America/Chicago)',      'America/Chicago',  '-06:00', '(GMT -6:00) Central Standard Time (America/Chicago)',       8),
  ('Mountain Standard Time (America/Denver)',      'America/Denver',   '-07:00', '(GMT -7:00) Mountain Standard Time (America/Denver)',       9),
  ('Pacific Standard Time (America/Los_Angeles)',  'America/Los_Angeles','-08:00','(GMT -8:00) Pacific Standard Time (America/Los_Angeles)', 10),
  ('Greenwich Mean Time (Europe/London)',          'Europe/London',    '+00:00', '(GMT +0:00) Greenwich Mean Time (Europe/London)',           11),
  ('Central European Time (Europe/Paris)',         'Europe/Paris',     '+01:00', '(GMT +1:00) Central European Time (Europe/Paris)',          12),
  ('Eastern European Time (Europe/Helsinki)',      'Europe/Helsinki',  '+02:00', '(GMT +2:00) Eastern European Time (Europe/Helsinki)',       13),
  ('Arabia Standard Time (Asia/Riyadh)',           'Asia/Riyadh',      '+03:00', '(GMT +3:00) Arabia Standard Time (Asia/Riyadh)',            14),
  ('Pakistan Standard Time (Asia/Karachi)',        'Asia/Karachi',     '+05:00', '(GMT +5:00) Pakistan Standard Time (Asia/Karachi)',         15),
  ('Bangladesh Standard Time (Asia/Dhaka)',        'Asia/Dhaka',       '+06:00', '(GMT +6:00) Bangladesh Standard Time (Asia/Dhaka)',         16),
  ('SE Asia Standard Time (Asia/Bangkok)',         'Asia/Bangkok',     '+07:00', '(GMT +7:00) SE Asia Standard Time (Asia/Bangkok)',          17),
  ('Australian Eastern Time (Australia/Sydney)',   'Australia/Sydney', '+10:00', '(GMT +10:00) Australian Eastern Time (Australia/Sydney)',   18)
ON CONFLICT (name) DO NOTHING;

-- Link India timezone to India country row (run after countries are seeded)
UPDATE public.timezones t
SET country_id = c.id
FROM public.countries c
WHERE c.short_code = 'IN'
  AND t.tzdb_name = 'Asia/Calcutta';

-- Optional: add primary_timezone_id convenience column to countries
ALTER TABLE public.countries
  ADD COLUMN IF NOT EXISTS primary_timezone_id UUID
  REFERENCES public.timezones(id) ON DELETE SET NULL;

UPDATE public.countries c
SET primary_timezone_id = t.id
FROM public.timezones t
WHERE c.short_code = 'IN' AND t.tzdb_name = 'Asia/Calcutta';


-- ─────────────────────────────────────────────
-- Company ID label lookup table
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.company_id_labels (
  id         UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  label      VARCHAR(50) NOT NULL UNIQUE,
  is_active  BOOLEAN     NOT NULL DEFAULT TRUE,
  sort_order SMALLINT    NOT NULL DEFAULT 0
);

INSERT INTO public.company_id_labels (label, sort_order) VALUES
  ('Company ID', 1), ('ACN', 2), ('BN', 3),  ('CN', 4),
  ('CPR', 5), ('CVR', 6), ('DIW', 7), ('KT', 8),
  ('ORG', 9), ('SEC', 10), ('CRN', 11)
ON CONFLICT (label) DO NOTHING;


-- ─────────────────────────────────────────────
-- Grants for lookup access
-- ─────────────────────────────────────────────
GRANT SELECT ON TABLE public.industries TO anon, authenticated, service_role;
GRANT SELECT ON TABLE public.timezones TO anon, authenticated, service_role;
GRANT SELECT ON TABLE public.company_id_labels TO anon, authenticated, service_role;
