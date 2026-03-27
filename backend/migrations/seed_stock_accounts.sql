-- Migration: Seed missing Stock-type accounts (Finished Goods, Work In Progress)
-- These are global system accounts (org_id = default zero UUID).
-- Run once in Supabase SQL editor.

INSERT INTO public.accounts (
  system_account_name,
  account_type,
  account_group,
  is_system,
  is_active,
  is_deletable,
  org_id
)
VALUES
  (
    'Finished Goods',
    'Stock',
    'Assets',
    true,
    true,
    false,
    '00000000-0000-0000-0000-000000000000'
  ),
  (
    'Work In Progress',
    'Stock',
    'Assets',
    true,
    true,
    false,
    '00000000-0000-0000-0000-000000000000'
  )
ON CONFLICT (system_account_name) DO NOTHING;
