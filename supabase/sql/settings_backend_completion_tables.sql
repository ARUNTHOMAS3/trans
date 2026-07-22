-- Zerpai Settings backend completion tables
-- Additive only. Review and run after existing-table backend/page wiring is done.

create table if not exists public.general_preferences (
  id uuid primary key default gen_random_uuid(),
  entity_id uuid not null references public.organisation_branch_master(id),
  enabled_modules jsonb not null default '{}'::jsonb,
  pdf_preferences jsonb not null default '{}'::jsonb,
  discount_preferences jsonb not null default '{}'::jsonb,
  charges_preferences jsonb not null default '{}'::jsonb,
  stock_preferences jsonb not null default '{}'::jsonb,
  rounding_preferences jsonb not null default '{}'::jsonb,
  document_copy_labels jsonb not null default '{}'::jsonb,
  retention_preferences jsonb not null default '{}'::jsonb,
  address_formats jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (entity_id)
);

create table if not exists public.currency_exchange_rates (
  id uuid primary key default gen_random_uuid(),
  entity_id uuid not null references public.organisation_branch_master(id),
  currency_id uuid not null references public.currencies(id),
  exchange_rate numeric(18, 8) not null,
  as_of_date date not null,
  source character varying not null default 'manual',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (entity_id, currency_id, as_of_date)
);

create table if not exists public.unit_groups (
  id uuid primary key default gen_random_uuid(),
  entity_id uuid not null references public.organisation_branch_master(id),
  name character varying not null,
  base_unit_id uuid not null references public.units(id),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (entity_id, name)
);

create table if not exists public.unit_group_conversions (
  id uuid primary key default gen_random_uuid(),
  unit_group_id uuid not null references public.unit_groups(id) on delete cascade,
  target_unit_id uuid not null references public.units(id),
  conversion_rate numeric(18, 8) not null,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (unit_group_id, target_unit_id)
);

create table if not exists public.reporting_tag_options (
  id uuid primary key default gen_random_uuid(),
  reporting_tag_id uuid not null references public.reporting_tags(id) on delete cascade,
  parent_option_id uuid references public.reporting_tag_options(id) on delete cascade,
  label character varying not null,
  level integer not null default 0,
  sort_order integer not null default 0,
  is_default boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.reporting_tag_module_mappings (
  id uuid primary key default gen_random_uuid(),
  reporting_tag_id uuid not null references public.reporting_tags(id) on delete cascade,
  module character varying not null,
  scope character varying not null check (scope in ('transaction', 'line_item', 'master')),
  is_mandatory boolean not null default false,
  created_at timestamptz not null default now(),
  unique (reporting_tag_id, module, scope)
);

create table if not exists public.reminder_rules (
  id uuid primary key default gen_random_uuid(),
  entity_id uuid not null references public.organisation_branch_master(id),
  name character varying not null,
  module character varying not null,
  event_code character varying not null,
  channel character varying not null default 'email',
  offset_days integer not null default 0,
  subject_template text,
  body_template text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (entity_id, module, event_code, channel, name)
);

create table if not exists public.print_templates (
  id uuid primary key default gen_random_uuid(),
  entity_id uuid not null references public.organisation_branch_master(id),
  module character varying not null,
  template_name character varying not null,
  template_type character varying not null default 'pdf',
  content jsonb not null default '{}'::jsonb,
  is_default boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (entity_id, module, template_name)
);

create table if not exists public.email_notification_templates (
  id uuid primary key default gen_random_uuid(),
  entity_id uuid not null references public.organisation_branch_master(id),
  module character varying not null,
  event_code character varying not null,
  subject_template text not null default '',
  body_template text not null default '',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (entity_id, module, event_code)
);

create table if not exists public.custom_fields (
  id uuid primary key default gen_random_uuid(),
  entity_id uuid not null references public.organisation_branch_master(id),
  module character varying not null,
  field_key character varying not null,
  label character varying not null,
  field_type character varying not null,
  options jsonb not null default '[]'::jsonb,
  validation jsonb not null default '{}'::jsonb,
  sort_order integer not null default 0,
  is_required boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (entity_id, module, field_key)
);

create table if not exists public.approval_rules (
  id uuid primary key default gen_random_uuid(),
  entity_id uuid not null references public.organisation_branch_master(id),
  module character varying not null,
  approval_type character varying not null,
  rule_name character varying not null,
  conditions jsonb not null default '{}'::jsonb,
  approvers jsonb not null default '[]'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (entity_id, module, approval_type, rule_name)
);

create index if not exists idx_currency_exchange_rates_entity_currency
  on public.currency_exchange_rates(entity_id, currency_id);
create index if not exists idx_unit_groups_entity
  on public.unit_groups(entity_id);
create index if not exists idx_reporting_tag_options_tag
  on public.reporting_tag_options(reporting_tag_id);
create index if not exists idx_reporting_tag_module_mappings_tag
  on public.reporting_tag_module_mappings(reporting_tag_id);
create index if not exists idx_reminder_rules_entity_module
  on public.reminder_rules(entity_id, module);
create index if not exists idx_print_templates_entity_module
  on public.print_templates(entity_id, module);
create index if not exists idx_custom_fields_entity_module
  on public.custom_fields(entity_id, module);
create index if not exists idx_approval_rules_entity_module
  on public.approval_rules(entity_id, module);
