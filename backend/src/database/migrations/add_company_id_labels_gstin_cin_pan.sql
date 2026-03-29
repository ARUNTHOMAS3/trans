-- Add GSTIN, CIN, and PAN to company_id_labels lookup table.
-- Uses ON CONFLICT DO NOTHING so re-running is safe.
-- sort_order values continue from existing entries (LLPIN=10, UDYAM=20, FSSAI=30 assumed).

INSERT INTO public.company_id_labels (label, is_active, sort_order) VALUES
  ('GSTIN', true, 5),
  ('CIN',   true, 15),
  ('PAN',   true, 25)
ON CONFLICT (label) DO NOTHING;
