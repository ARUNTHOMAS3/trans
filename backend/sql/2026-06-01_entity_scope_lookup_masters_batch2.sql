-- Batch-2: convert key global lookup masters to entity-scoped
-- Guardrail: products stay global; only lookup masters scoped.
-- Prereq: run in maintenance window, take DB backup.

begin;

-- 0) Resolve default org entity for backfill (single-tenant fallback)
-- Adjust WHERE if you want a different org.
with default_org as (
  select id
  from organisation_branch_master
  where type = 'ORG'
  order by created_at asc nulls last
  limit 1
)
select id as default_org_entity_id from default_org;

-- 1) Add entity_id columns (nullable first, additive-safe)
alter table categories add column if not exists entity_id uuid;
alter table manufacturers add column if not exists entity_id uuid;
alter table brands add column if not exists entity_id uuid;
alter table tax_rates add column if not exists entity_id uuid;
alter table tax_groups add column if not exists entity_id uuid;
alter table units add column if not exists entity_id uuid;
alter table racks add column if not exists entity_id uuid;
alter table storage_conditions add column if not exists entity_id uuid;
alter table contents add column if not exists entity_id uuid;
alter table drug_strengths add column if not exists entity_id uuid;
alter table buying_rules add column if not exists entity_id uuid;
alter table drug_schedules add column if not exists entity_id uuid;
alter table payment_terms add column if not exists entity_id uuid;

-- 2) Backfill null entity_id rows to default org entity
with default_org as (
  select id
  from organisation_branch_master
  where type = 'ORG'
  order by created_at asc nulls last
  limit 1
)
update categories t set entity_id = d.id
from default_org d where t.entity_id is null;

with default_org as (
  select id
  from organisation_branch_master
  where type = 'ORG'
  order by created_at asc nulls last
  limit 1
)
update manufacturers t set entity_id = d.id
from default_org d where t.entity_id is null;

with default_org as (
  select id
  from organisation_branch_master
  where type = 'ORG'
  order by created_at asc nulls last
  limit 1
)
update brands t set entity_id = d.id
from default_org d where t.entity_id is null;

with default_org as (
  select id
  from organisation_branch_master
  where type = 'ORG'
  order by created_at asc nulls last
  limit 1
)
update tax_rates t set entity_id = d.id
from default_org d where t.entity_id is null;

with default_org as (
  select id
  from organisation_branch_master
  where type = 'ORG'
  order by created_at asc nulls last
  limit 1
)
update tax_groups t set entity_id = d.id
from default_org d where t.entity_id is null;

with default_org as (
  select id
  from organisation_branch_master
  where type = 'ORG'
  order by created_at asc nulls last
  limit 1
)
update units t set entity_id = d.id
from default_org d where t.entity_id is null;

with default_org as (
  select id
  from organisation_branch_master
  where type = 'ORG'
  order by created_at asc nulls last
  limit 1
)
update racks t set entity_id = d.id
from default_org d where t.entity_id is null;

with default_org as (
  select id
  from organisation_branch_master
  where type = 'ORG'
  order by created_at asc nulls last
  limit 1
)
update storage_conditions t set entity_id = d.id
from default_org d where t.entity_id is null;

with default_org as (
  select id
  from organisation_branch_master
  where type = 'ORG'
  order by created_at asc nulls last
  limit 1
)
update contents t set entity_id = d.id
from default_org d where t.entity_id is null;

with default_org as (
  select id
  from organisation_branch_master
  where type = 'ORG'
  order by created_at asc nulls last
  limit 1
)
update drug_strengths t set entity_id = d.id
from default_org d where t.entity_id is null;

with default_org as (
  select id
  from organisation_branch_master
  where type = 'ORG'
  order by created_at asc nulls last
  limit 1
)
update buying_rules t set entity_id = d.id
from default_org d where t.entity_id is null;

with default_org as (
  select id
  from organisation_branch_master
  where type = 'ORG'
  order by created_at asc nulls last
  limit 1
)
update drug_schedules t set entity_id = d.id
from default_org d where t.entity_id is null;

with default_org as (
  select id
  from organisation_branch_master
  where type = 'ORG'
  order by created_at asc nulls last
  limit 1
)
update payment_terms t set entity_id = d.id
from default_org d where t.entity_id is null;

-- 3) FK constraints (guarded for idempotency)
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'categories_entity_id_fkey') then
    alter table categories add constraint categories_entity_id_fkey
      foreign key (entity_id) references organisation_branch_master(id);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'manufacturers_entity_id_fkey') then
    alter table manufacturers add constraint manufacturers_entity_id_fkey
      foreign key (entity_id) references organisation_branch_master(id);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'brands_entity_id_fkey') then
    alter table brands add constraint brands_entity_id_fkey
      foreign key (entity_id) references organisation_branch_master(id);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'tax_rates_entity_id_fkey') then
    alter table tax_rates add constraint tax_rates_entity_id_fkey
      foreign key (entity_id) references organisation_branch_master(id);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'tax_groups_entity_id_fkey') then
    alter table tax_groups add constraint tax_groups_entity_id_fkey
      foreign key (entity_id) references organisation_branch_master(id);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'units_entity_id_fkey') then
    alter table units add constraint units_entity_id_fkey
      foreign key (entity_id) references organisation_branch_master(id);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'racks_entity_id_fkey') then
    alter table racks add constraint racks_entity_id_fkey
      foreign key (entity_id) references organisation_branch_master(id);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'storage_conditions_entity_id_fkey') then
    alter table storage_conditions add constraint storage_conditions_entity_id_fkey
      foreign key (entity_id) references organisation_branch_master(id);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'contents_entity_id_fkey') then
    alter table contents add constraint contents_entity_id_fkey
      foreign key (entity_id) references organisation_branch_master(id);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'drug_strengths_entity_id_fkey') then
    alter table drug_strengths add constraint drug_strengths_entity_id_fkey
      foreign key (entity_id) references organisation_branch_master(id);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'buying_rules_entity_id_fkey') then
    alter table buying_rules add constraint buying_rules_entity_id_fkey
      foreign key (entity_id) references organisation_branch_master(id);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'drug_schedules_entity_id_fkey') then
    alter table drug_schedules add constraint drug_schedules_entity_id_fkey
      foreign key (entity_id) references organisation_branch_master(id);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'payment_terms_entity_id_fkey') then
    alter table payment_terms add constraint payment_terms_entity_id_fkey
      foreign key (entity_id) references organisation_branch_master(id);
  end if;
end $$;

-- 4) Tenant query indexes
create index if not exists idx_categories_entity_id on categories(entity_id);
create index if not exists idx_manufacturers_entity_id on manufacturers(entity_id);
create index if not exists idx_brands_entity_id on brands(entity_id);
create index if not exists idx_tax_rates_entity_id on tax_rates(entity_id);
create index if not exists idx_tax_groups_entity_id on tax_groups(entity_id);
create index if not exists idx_units_entity_id on units(entity_id);
create index if not exists idx_racks_entity_id on racks(entity_id);
create index if not exists idx_storage_conditions_entity_id on storage_conditions(entity_id);
create index if not exists idx_contents_entity_id on contents(entity_id);
create index if not exists idx_drug_strengths_entity_id on drug_strengths(entity_id);
create index if not exists idx_buying_rules_entity_id on buying_rules(entity_id);
create index if not exists idx_drug_schedules_entity_id on drug_schedules(entity_id);
create index if not exists idx_payment_terms_entity_id on payment_terms(entity_id);

-- 5) Enforce tenant-local uniqueness (keep old unique constraints for now)
create unique index if not exists uq_categories_entity_name_ci
  on categories(entity_id, lower(name));
create unique index if not exists uq_manufacturers_entity_name_ci
  on manufacturers(entity_id, lower(name));
create unique index if not exists uq_brands_entity_name_ci
  on brands(entity_id, lower(name));
create unique index if not exists uq_tax_rates_entity_name_ci
  on tax_rates(entity_id, lower(tax_name));
create unique index if not exists uq_tax_groups_entity_name_ci
  on tax_groups(entity_id, lower(tax_group_name));
create unique index if not exists uq_units_entity_name_ci
  on units(entity_id, lower(unit_name));
create unique index if not exists uq_racks_entity_code_ci
  on racks(entity_id, lower(rack_code));
create unique index if not exists uq_storage_conditions_entity_name_ci
  on storage_conditions(entity_id, lower(location_name));
create unique index if not exists uq_contents_entity_name_ci
  on contents(entity_id, lower(content_name));
create unique index if not exists uq_drug_strengths_entity_name_ci
  on drug_strengths(entity_id, lower(strength_name));
create unique index if not exists uq_buying_rules_entity_name_ci
  on buying_rules(entity_id, lower(buying_rule));
create unique index if not exists uq_drug_schedules_entity_name_ci
  on drug_schedules(entity_id, lower(shedule_name));
create unique index if not exists uq_payment_terms_entity_name_ci
  on payment_terms(entity_id, lower(term_name));

-- 6) Make entity_id required after backfill
alter table categories alter column entity_id set not null;
alter table manufacturers alter column entity_id set not null;
alter table brands alter column entity_id set not null;
alter table tax_rates alter column entity_id set not null;
alter table tax_groups alter column entity_id set not null;
alter table units alter column entity_id set not null;
alter table racks alter column entity_id set not null;
alter table storage_conditions alter column entity_id set not null;
alter table contents alter column entity_id set not null;
alter table drug_strengths alter column entity_id set not null;
alter table buying_rules alter column entity_id set not null;
alter table drug_schedules alter column entity_id set not null;
alter table payment_terms alter column entity_id set not null;

commit;
