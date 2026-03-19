# 🗄️ PRD Schema Reference (Current Snapshot)

**Source:** Supabase SQL Editor output (context-only, not executable)  
**Generated:** 2026-03-19
**Status:** Informational snapshot

---

## Rules (STRICT)

- **Every form must map to the corresponding table(s) below** for create/edit/save flows.
- **Schema will be updated periodically**; this file is a snapshot and must be refreshed when DB changes.
- **Do not invent tables or fields** not present here without a schema update.
- **New Table Naming (Mandatory):** All **current and future** tables created from this point forward must use the prefix format  
  `<module_name>_<table_name>` (snake_case). **Do not rename existing tables.**
- **Destructive DB Safety (Mandatory):**
  - **Always run `npm run db:pull` first** before creating or altering tables, and generate changes based on the pulled schema.
  - **If a table exists in the DB but not in this snapshot, assume it was created by another developer. Do NOT delete or alter it.**
  - Be extra cautious with destructive commands (drop/alter). Default to non-destructive changes.

---

## Tables (Extracted)

- `account_transactions`
- `accounts`
- `accounts_fiscal_years`
- `accounts_journal_number_settings`
- `accounts_journal_template_items`
- `accounts_journal_templates`
- `accounts_manual_journal_attachments`
- `accounts_manual_journal_items`
- `accounts_manual_journal_tag_mappings`
- `accounts_manual_journals`
- `accounts_recurring_journal_items`
- `accounts_recurring_journals`
- `accounts_reporting_tags`
- `associate_taxes`
- `audit_logs`
- `audit_logs_archive`
- `batches`
- `brands`
- `buying_rules`
- `categories`
- `composite_item_outlet_inventory_settings`
- `composite_item_parts`
- `composite_items`
- `contents`
- `countries`
- `currencies`
- `customer_contact_persons`
- `customers`
- `hsn_sac_codes`
- `item_vendor_mappings`
- `manufacturers`
- `organization`
- `outlet_inventory`
- `payment_terms`
- `price_list_items`
- `price_list_volume_ranges`
- `price_lists`
- `product_contents`
- `product_outlet_inventory_settings`
- `products`
- `racks`
- `reorder_terms`
- `sales_eway_bills`
- `sales_orders`
- `sales_payment_links`
- `sales_payments`
- `schedules`
- `shipment_preferences`
- `states`
- `storage_locations`
- `strengths`
- `tax_group_taxes`
- `tax_groups`
- `tds_group_items`
- `tds_groups`
- `tds_rates`
- `tds_sections`
- `transaction_locks`
- `transactional_sequences`
- `units`
- `uqc`
- `vendor_bank_accounts`
- `vendor_contact_persons`
- `vendors`
- `warehouses`

---

## Form-to-Table Enforcement (Mandatory)

All creation/edit forms must:

1. **Persist to the correct table(s)** above.
2. **Respect foreign keys** (e.g., `products.unit_id → units.id`).
3. **Use lookup tables** for dropdowns (e.g., `associate_taxes`, `units`, `categories`, `vendors`, `accounts`, `manufacturers`, `brands`).
4. **Use transactional tables** for document flows (e.g., `sales_orders`, `sales_payments`, `sales_eway_bills`).
5. **Use junction tables** for mappings (e.g., `item_vendor_mappings`, `product_contents`, `composite_item_parts`).

---

## Audit Rollout Delta (2026-03-17)

This snapshot now includes the central audit rollout that was added after the earlier 2026-03-06 extract.

### New audit tables

- `audit_logs`
  - hot/current audit rows
- `audit_logs_archive`
  - archived historical audit rows

### Audit-read surface

The live database also uses:
- `audit_logs_all`
  - a combined read view over current and archived audit records

This view is not listed as a `CREATE TABLE` because it is a view, not a base table, but it is part of the reporting contract used by the backend audit endpoint.

### Important schema changes reflected below

- `account_transactions` includes tenancy/contact columns:
  - `org_id`
  - `outlet_id`
  - `contact_id`
  - `contact_type`
- `accounts` includes tenancy columns:
  - `org_id`
  - `outlet_id`
- `accounts_manual_journals` includes:
  - `updated_at`
  - `is_deleted`
- central audit tables include:
  - `schema_name`
  - `record_pk`
  - `changed_columns`
  - `txid`
  - `source`
  - `module_name`
  - `request_id`
  - `archived_at` on archive rows

### Development rule

Any new backend or frontend work that reads audit data must target the combined audit reporting surface, not just the hot table, so archived logs remain visible in the product.

```sql
-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.
-- Schema last updated: 2026-03-17

CREATE TABLE public.account_transactions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  account_id uuid NOT NULL,
  transaction_date timestamp without time zone NOT NULL DEFAULT now(),
  transaction_type character varying,
  reference_number character varying,
  description text,
  debit numeric DEFAULT 0.00,
  credit numeric DEFAULT 0.00,
  created_at timestamp without time zone DEFAULT now(),
  source_id uuid,
  source_type character varying,
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
  outlet_id uuid,
  contact_id uuid,
  contact_type character varying,
  CONSTRAINT account_transactions_pkey PRIMARY KEY (id),
  CONSTRAINT account_transactions_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id)
);
CREATE TABLE public.accounts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  system_account_name character varying UNIQUE,
  account_code character varying UNIQUE,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT now(),
  parent_id uuid,
  account_group USER-DEFINED NOT NULL DEFAULT 'Expenses'::account_group_enum,
  is_system boolean DEFAULT false,
  account_type USER-DEFINED NOT NULL,
  description text,
  account_number character varying,
  ifsc character varying,
  currency character varying DEFAULT 'INR'::character varying,
  show_in_zerpai_expense boolean DEFAULT false,
  add_to_watchlist boolean DEFAULT false,
  is_deletable boolean DEFAULT true,
  user_account_name character varying,
  created_by uuid,
  is_deleted boolean DEFAULT false,
  modified_at timestamp with time zone DEFAULT now(),
  modified_by uuid,
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
  outlet_id uuid,
  CONSTRAINT accounts_pkey PRIMARY KEY (id),
  CONSTRAINT fk_accounts_parent FOREIGN KEY (parent_id) REFERENCES public.accounts(id)
);
CREATE TABLE public.accounts_fiscal_years (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
  outlet_id uuid,
  name character varying NOT NULL,
  start_date date NOT NULL,
  end_date date NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT accounts_fiscal_years_pkey PRIMARY KEY (id)
);
CREATE TABLE public.accounts_journal_number_settings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
  outlet_id uuid,
  auto_generate boolean DEFAULT true,
  prefix character varying,
  next_number integer DEFAULT 1,
  is_manual_override_allowed boolean DEFAULT false,
  user_id uuid,
  CONSTRAINT accounts_journal_number_settings_pkey PRIMARY KEY (id)
);
CREATE TABLE public.accounts_journal_template_items (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
  outlet_id uuid,
  template_id uuid NOT NULL,
  account_id uuid NOT NULL,
  description text,
  contact_id uuid,
  contact_type USER-DEFINED,
  type USER-DEFINED,
  debit numeric DEFAULT 0.00,
  credit numeric DEFAULT 0.00,
  sort_order integer,
  CONSTRAINT accounts_journal_template_items_pkey PRIMARY KEY (id),
  CONSTRAINT accounts_journal_template_items_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.accounts_journal_templates(id),
  CONSTRAINT accounts_journal_template_items_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id)
);
CREATE TABLE public.accounts_journal_templates (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
  outlet_id uuid,
  template_name character varying NOT NULL,
  reference_number character varying,
  notes text,
  reporting_method USER-DEFINED,
  currency_code character varying DEFAULT 'INR'::character varying,
  is_active boolean DEFAULT true,
  enter_amount boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT accounts_journal_templates_pkey PRIMARY KEY (id)
);
CREATE TABLE public.accounts_manual_journal_attachments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
  outlet_id uuid,
  manual_journal_id uuid NOT NULL,
  file_name character varying NOT NULL,
  file_path text NOT NULL,
  file_size integer,
  uploaded_at timestamp without time zone DEFAULT now(),
  CONSTRAINT accounts_manual_journal_attachments_pkey PRIMARY KEY (id),
  CONSTRAINT accounts_manual_journal_attachments_manual_journal_id_fkey FOREIGN KEY (manual_journal_id) REFERENCES public.accounts_manual_journals(id)
);
CREATE TABLE public.accounts_manual_journal_items (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
  outlet_id uuid,
  manual_journal_id uuid NOT NULL,
  account_id uuid NOT NULL,
  description text,
  contact_id uuid,
  contact_type USER-DEFINED,
  debit numeric DEFAULT 0.00,
  credit numeric DEFAULT 0.00,
  sort_order integer,
  CONSTRAINT accounts_manual_journal_items_pkey PRIMARY KEY (id),
  CONSTRAINT accounts_manual_journal_items_manual_journal_id_fkey FOREIGN KEY (manual_journal_id) REFERENCES public.accounts_manual_journals(id),
  CONSTRAINT accounts_manual_journal_items_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id)
);
CREATE TABLE public.accounts_manual_journal_tag_mappings (
  manual_journal_item_id uuid NOT NULL,
  reporting_tag_id uuid NOT NULL,
  CONSTRAINT accounts_manual_journal_tag_mappings_pkey PRIMARY KEY (manual_journal_item_id, reporting_tag_id),
  CONSTRAINT accounts_manual_journal_tag_mapping_manual_journal_item_id_fkey FOREIGN KEY (manual_journal_item_id) REFERENCES public.accounts_manual_journal_items(id),
  CONSTRAINT accounts_manual_journal_tag_mappings_reporting_tag_id_fkey FOREIGN KEY (reporting_tag_id) REFERENCES public.accounts_reporting_tags(id)
);
CREATE TABLE public.accounts_manual_journals (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
  outlet_id uuid,
  journal_number character varying NOT NULL UNIQUE,
  fiscal_year_id uuid,
  reference_number character varying,
  journal_date date DEFAULT CURRENT_DATE,
  notes text,
  is_13th_month_adjustment boolean DEFAULT false,
  reporting_method USER-DEFINED DEFAULT 'accrual_and_cash'::accounts_reporting_method,
  currency_code character varying DEFAULT 'INR'::character varying,
  status USER-DEFINED DEFAULT 'draft'::accounts_manual_journal_status,
  total_amount numeric DEFAULT 0.00,
  created_by uuid,
  created_at timestamp without time zone DEFAULT now(),
  recurring_journal_id uuid,
  updated_at timestamp with time zone DEFAULT now(),
  is_deleted boolean NOT NULL DEFAULT false,
  CONSTRAINT accounts_manual_journals_pkey PRIMARY KEY (id),
  CONSTRAINT accounts_manual_journals_recurring_journal_id_fkey FOREIGN KEY (recurring_journal_id) REFERENCES public.accounts_recurring_journals(id),
  CONSTRAINT accounts_manual_journals_fiscal_year_id_fkey FOREIGN KEY (fiscal_year_id) REFERENCES public.accounts_fiscal_years(id)
);
CREATE TABLE public.accounts_recurring_journal_items (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  recurring_journal_id uuid NOT NULL,
  account_id uuid NOT NULL,
  description text,
  contact_id uuid,
  contact_type character varying,
  debit numeric DEFAULT 0.00,
  credit numeric DEFAULT 0.00,
  sort_order integer,
  CONSTRAINT accounts_recurring_journal_items_pkey PRIMARY KEY (id),
  CONSTRAINT accounts_recurring_journal_items_recur_journal_id_fkey FOREIGN KEY (recurring_journal_id) REFERENCES public.accounts_recurring_journals(id),
  CONSTRAINT accounts_recurring_journal_items_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id)
);
CREATE TABLE public.accounts_recurring_journals (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
  outlet_id uuid,
  profile_name character varying NOT NULL,
  repeat_every character varying NOT NULL,
  interval integer NOT NULL DEFAULT 1,
  start_date date NOT NULL,
  end_date date,
  never_expires boolean DEFAULT true,
  reference_number character varying,
  notes text,
  currency_code character varying DEFAULT 'INR'::character varying,
  reporting_method character varying DEFAULT 'accrual_and_cash'::character varying,
  status character varying DEFAULT 'active'::character varying,
  last_generated_date timestamp without time zone,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone DEFAULT now(),
  created_by uuid,
  CONSTRAINT accounts_recurring_journals_pkey PRIMARY KEY (id)
);
CREATE TABLE public.accounts_reporting_tags (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
  outlet_id uuid,
  tag_name character varying NOT NULL,
  is_active boolean DEFAULT true,
  CONSTRAINT accounts_reporting_tags_pkey PRIMARY KEY (id)
);
CREATE TABLE public.associate_taxes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  tax_name character varying NOT NULL UNIQUE,
  tax_rate numeric NOT NULL,
  tax_type USER-DEFINED,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT associate_taxes_pkey PRIMARY KEY (id)
);
CREATE TABLE public.audit_logs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  table_name character varying NOT NULL,
  record_id uuid NOT NULL,
  action character varying NOT NULL,
  old_values jsonb,
  new_values jsonb,
  user_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
  created_at timestamp with time zone DEFAULT now(),
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
  outlet_id uuid,
  actor_name text NOT NULL DEFAULT 'system'::text,
  schema_name text NOT NULL DEFAULT 'public'::text,
  record_pk text,
  changed_columns ARRAY,
  txid bigint NOT NULL DEFAULT txid_current(),
  source text NOT NULL DEFAULT 'system'::text,
  module_name text,
  request_id text,
  CONSTRAINT audit_logs_pkey PRIMARY KEY (id)
);
CREATE TABLE public.audit_logs_archive (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  table_name character varying NOT NULL,
  record_id uuid NOT NULL,
  action character varying NOT NULL,
  old_values jsonb,
  new_values jsonb,
  user_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
  created_at timestamp with time zone DEFAULT now(),
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
  outlet_id uuid,
  actor_name text NOT NULL DEFAULT 'system'::text,
  schema_name text NOT NULL DEFAULT 'public'::text,
  record_pk text,
  changed_columns ARRAY,
  txid bigint NOT NULL DEFAULT txid_current(),
  source text NOT NULL DEFAULT 'system'::text,
  module_name text,
  request_id text,
  archived_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT audit_logs_archive_pkey PRIMARY KEY (id)
);
CREATE TABLE public.batches (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  product_id uuid,
  batch character varying NOT NULL,
  exp date NOT NULL,
  mrp numeric NOT NULL,
  ptr numeric NOT NULL,
  unit_pack character varying,
  is_manufacture_details boolean DEFAULT false,
  manufacture_batch_number character varying,
  manufacture_exp date,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT batches_pkey PRIMARY KEY (id),
  CONSTRAINT batches_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.brands (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name character varying NOT NULL UNIQUE,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT brands_pkey PRIMARY KEY (id)
);
CREATE TABLE public.buying_rules (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  buying_rule character varying NOT NULL UNIQUE,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT buying_rules_pkey PRIMARY KEY (id)
);
CREATE TABLE public.categories (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name character varying NOT NULL UNIQUE,
  description text,
  parent_id uuid,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT categories_pkey PRIMARY KEY (id),
  CONSTRAINT categories_parent_id_categories_id_fk FOREIGN KEY (parent_id) REFERENCES public.categories(id)
);
CREATE TABLE public.composite_item_outlet_inventory_settings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
  outlet_id uuid,
  composite_item_id uuid NOT NULL,
  reorder_point integer NOT NULL DEFAULT 0 CHECK (reorder_point >= 0),
  reorder_term_id uuid,
  is_active boolean NOT NULL DEFAULT true,
  created_by_id uuid,
  updated_by_id uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT composite_item_outlet_inventory_settings_pkey PRIMARY KEY (id),
  CONSTRAINT composite_item_outlet_inventory_settings_composite_item_fkey FOREIGN KEY (composite_item_id) REFERENCES public.composite_items(id),
  CONSTRAINT composite_item_outlet_inventory_settings_reorder_term_fkey FOREIGN KEY (reorder_term_id) REFERENCES public.reorder_terms(id)
);
CREATE TABLE public.composite_item_parts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  composite_item_id uuid NOT NULL,
  component_product_id uuid NOT NULL,
  quantity numeric NOT NULL,
  selling_price_override numeric,
  cost_price_override numeric,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT composite_item_parts_pkey PRIMARY KEY (id),
  CONSTRAINT composite_item_parts_composite_item_id_fkey FOREIGN KEY (composite_item_id) REFERENCES public.composite_items(id),
  CONSTRAINT composite_item_parts_component_product_id_fkey FOREIGN KEY (component_product_id) REFERENCES public.products(id)
);
CREATE TABLE public.composite_items (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  type USER-DEFINED NOT NULL,
  product_name character varying NOT NULL,
  sku character varying UNIQUE,
  unit_id uuid NOT NULL,
  category_id uuid,
  is_returnable boolean DEFAULT false,
  push_to_ecommerce boolean DEFAULT false,
  hsn_code character varying,
  tax_preference USER-DEFINED,
  intra_state_tax_id uuid,
  inter_state_tax_id uuid,
  primary_image_url text,
  image_urls text,
  selling_price numeric,
  selling_price_currency character varying DEFAULT 'INR'::character varying,
  ptr numeric,
  sales_account_id uuid,
  sales_description text,
  cost_price numeric,
  purchase_account_id uuid,
  preferred_vendor_id uuid,
  purchase_description text,
  length numeric,
  width numeric,
  height numeric,
  dimension_unit character varying DEFAULT 'cm'::character varying,
  weight numeric,
  weight_unit character varying DEFAULT 'kg'::character varying,
  manufacturer_id uuid,
  brand_id uuid,
  mpn character varying,
  upc character varying,
  isbn character varying,
  ean character varying,
  is_track_inventory boolean DEFAULT true,
  track_batches boolean DEFAULT false,
  track_serial_number boolean DEFAULT false,
  inventory_account_id uuid,
  inventory_valuation_method USER-DEFINED,
  reorder_point integer DEFAULT 0,
  reorder_term_id uuid,
  is_active boolean DEFAULT true,
  is_lock boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  created_by_id uuid,
  updated_at timestamp with time zone DEFAULT now(),
  updated_by_id uuid,
  CONSTRAINT composite_items_pkey PRIMARY KEY (id),
  CONSTRAINT composite_items_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.units(id),
  CONSTRAINT composite_items_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id),
  CONSTRAINT composite_items_intra_state_tax_id_fkey FOREIGN KEY (intra_state_tax_id) REFERENCES public.associate_taxes(id),
  CONSTRAINT composite_items_inter_state_tax_id_fkey FOREIGN KEY (inter_state_tax_id) REFERENCES public.associate_taxes(id),
  CONSTRAINT composite_items_sales_account_id_fkey FOREIGN KEY (sales_account_id) REFERENCES public.accounts(id),
  CONSTRAINT composite_items_purchase_account_id_fkey FOREIGN KEY (purchase_account_id) REFERENCES public.accounts(id),
  CONSTRAINT composite_items_manufacturer_id_fkey FOREIGN KEY (manufacturer_id) REFERENCES public.manufacturers(id),
  CONSTRAINT composite_items_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES public.brands(id),
  CONSTRAINT composite_items_inventory_account_id_fkey FOREIGN KEY (inventory_account_id) REFERENCES public.accounts(id),
  CONSTRAINT composite_items_reorder_term_id_fkey FOREIGN KEY (reorder_term_id) REFERENCES public.reorder_terms(id)
);
CREATE TABLE public.contents (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  content_name character varying NOT NULL UNIQUE,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT contents_pkey PRIMARY KEY (id)
);
CREATE TABLE public.countries (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name character varying NOT NULL UNIQUE,
  full_label character varying,
  phone_code character varying NOT NULL,
  short_code character varying,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT countries_pkey PRIMARY KEY (id)
);
CREATE TABLE public.currencies (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  code character varying NOT NULL UNIQUE,
  name character varying NOT NULL,
  symbol character varying,
  decimals integer DEFAULT 2,
  format character varying,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT currencies_pkey PRIMARY KEY (id)
);
CREATE TABLE public.customer_contact_persons (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  customer_id uuid NOT NULL,
  salutation character varying,
  first_name character varying,
  last_name character varying,
  email character varying,
  work_phone character varying,
  mobile_phone character varying,
  display_order integer DEFAULT 0,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone DEFAULT now(),
  CONSTRAINT customer_contact_persons_pkey PRIMARY KEY (id),
  CONSTRAINT customer_contact_persons_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id)
);
CREATE TABLE public.customers (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  display_name character varying NOT NULL,
  customer_type character varying DEFAULT 'Business'::character varying,
  salutation character varying,
  first_name character varying,
  last_name character varying,
  company_name character varying,
  email character varying,
  phone character varying,
  mobile_phone character varying,
  gstin character varying,
  pan character varying,
  payment_terms character varying,
  billing_address text,
  shipping_address text,
  is_active boolean DEFAULT true,
  receivables numeric DEFAULT 0.00,
  created_at timestamp without time zone DEFAULT now(),
  customer_number character varying UNIQUE,
  designation character varying,
  department character varying,
  business_type character varying,
  customer_language character varying DEFAULT 'English'::character varying,
  date_of_birth date,
  age integer,
  gender character varying,
  place_of_customer character varying,
  privilege_card_number character varying,
  parent_customer_id uuid,
  tax_preference character varying,
  exemption_reason text,
  drug_licence_type character varying,
  drug_license_20 character varying,
  drug_license_21 character varying,
  drug_license_20b character varying,
  drug_license_21b character varying,
  fssai character varying,
  msme_registration_type character varying,
  msme_number character varying,
  drug_license_20_doc_url text,
  drug_license_21_doc_url text,
  drug_license_20b_doc_url text,
  drug_license_21b_doc_url text,
  fssai_doc_url text,
  msme_doc_url text,
  opening_balance numeric DEFAULT 0,
  credit_limit numeric,
  enable_portal boolean DEFAULT false,
  facebook_handle character varying,
  twitter_handle character varying,
  whatsapp_number character varying,
  is_recurring boolean DEFAULT false,
  gst_treatment character varying,
  place_of_supply character varying,
  website character varying,
  price_list_id uuid,
  receivable_balance numeric DEFAULT 0,
  billing_address_street1 character varying,
  billing_address_street2 character varying,
  billing_address_city character varying,
  billing_address_zip character varying,
  billing_address_phone character varying,
  shipping_address_street1 character varying,
  shipping_address_street2 character varying,
  shipping_address_city character varying,
  shipping_address_zip character varying,
  shipping_address_phone character varying,
  remarks text,
  status character varying DEFAULT 'active'::character varying,
  document_urls text,
  is_drug_registered boolean,
  is_fssai_registered boolean,
  is_msme_registered boolean,
  currency_id uuid,
  billing_address_state_id uuid,
  shipping_address_state_id uuid,
  billing_address_country_id uuid,
  shipping_address_country_id uuid,
  CONSTRAINT customers_pkey PRIMARY KEY (id),
  CONSTRAINT customers_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES public.currencies(id),
  CONSTRAINT customers_price_list_id_fkey FOREIGN KEY (price_list_id) REFERENCES public.price_lists(id),
  CONSTRAINT customers_parent_customer_id_fkey FOREIGN KEY (parent_customer_id) REFERENCES public.customers(id),
  CONSTRAINT customers_billing_address_state_id_states_id_fk FOREIGN KEY (billing_address_state_id) REFERENCES public.states(id),
  CONSTRAINT customers_shipping_address_state_id_states_id_fk FOREIGN KEY (shipping_address_state_id) REFERENCES public.states(id),
  CONSTRAINT customers_billing_address_country_id_fkey FOREIGN KEY (billing_address_country_id) REFERENCES public.countries(id),
  CONSTRAINT customers_shipping_address_country_id_fkey FOREIGN KEY (shipping_address_country_id) REFERENCES public.countries(id)
);
CREATE TABLE public.item_vendor_mappings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  vendor_id uuid NOT NULL,
  item_id uuid NOT NULL,
  mapping_name character varying NOT NULL,
  vendor_product_code character varying,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT item_vendor_mappings_pkey PRIMARY KEY (id),
  CONSTRAINT item_vendor_mappings_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.products(id)
);
CREATE TABLE public.manufacturers (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name character varying NOT NULL UNIQUE,
  contact_info jsonb,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT manufacturers_pkey PRIMARY KEY (id)
);
CREATE TABLE public.organization (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name character varying NOT NULL,
  slug character varying NOT NULL UNIQUE,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone DEFAULT now(),
  CONSTRAINT organization_pkey PRIMARY KEY (id)
);
CREATE TABLE public.outlet_inventory (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  outlet_id uuid NOT NULL,
  product_id uuid NOT NULL,
  current_stock integer NOT NULL DEFAULT 0 CHECK (current_stock >= 0),
  reserved_stock integer DEFAULT 0,
  available_stock integer DEFAULT (current_stock - reserved_stock),
  batch_no character varying,
  expiry_date date,
  min_stock_level integer DEFAULT 0,
  max_stock_level integer DEFAULT 0,
  last_stock_update timestamp with time zone DEFAULT now(),
  CONSTRAINT outlet_inventory_pkey PRIMARY KEY (id)
);
CREATE TABLE public.payment_terms (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  term_name character varying NOT NULL UNIQUE,
  number_of_days integer NOT NULL,
  description text,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT payment_terms_pkey PRIMARY KEY (id)
);
CREATE TABLE public.price_list_items (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  price_list_id uuid NOT NULL,
  product_id uuid NOT NULL,
  custom_rate numeric,
  discount_percentage numeric,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone DEFAULT now(),
  CONSTRAINT price_list_items_pkey PRIMARY KEY (id),
  CONSTRAINT price_list_items_price_list_id_fkey FOREIGN KEY (price_list_id) REFERENCES public.price_lists(id),
  CONSTRAINT price_list_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.price_list_volume_ranges (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  price_list_item_id uuid NOT NULL,
  start_quantity numeric NOT NULL,
  end_quantity numeric,
  rate numeric NOT NULL,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone DEFAULT now(),
  CONSTRAINT price_list_volume_ranges_pkey PRIMARY KEY (id),
  CONSTRAINT price_list_volume_ranges_price_list_item_id_fkey FOREIGN KEY (price_list_item_id) REFERENCES public.price_list_items(id)
);
CREATE TABLE public.price_lists (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name character varying NOT NULL,
  description text DEFAULT ''::text,
  currency character varying DEFAULT 'INR'::character varying,
  pricing_scheme character varying NOT NULL,
  details text DEFAULT ''::text,
  round_off_preference character varying DEFAULT 'never_mind'::character varying,
  status character varying DEFAULT 'active'::character varying,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  price_list_type character varying DEFAULT 'all_items'::character varying,
  percentage_type character varying,
  percentage_value numeric,
  discount_enabled boolean DEFAULT false,
  transaction_type character varying DEFAULT 'Sales'::character varying,
  CONSTRAINT price_lists_pkey PRIMARY KEY (id)
);
CREATE TABLE public.product_contents (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  product_id uuid NOT NULL,
  content_id uuid,
  strength_id uuid,
  shedule_id uuid,
  display_order integer DEFAULT 0,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT product_contents_pkey PRIMARY KEY (id),
  CONSTRAINT product_contents_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id),
  CONSTRAINT product_contents_strength_id_fkey FOREIGN KEY (strength_id) REFERENCES public.strengths(id),
  CONSTRAINT product_contents_content_id_fkey FOREIGN KEY (content_id) REFERENCES public.contents(id),
  CONSTRAINT product_contents_schedule_id_fkey FOREIGN KEY (shedule_id) REFERENCES public.schedules(id)
);
CREATE TABLE public.product_outlet_inventory_settings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
  outlet_id uuid,
  product_id uuid NOT NULL,
  reorder_point integer NOT NULL DEFAULT 0 CHECK (reorder_point >= 0),
  reorder_term_id uuid,
  is_active boolean NOT NULL DEFAULT true,
  created_by_id uuid,
  updated_by_id uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT product_outlet_inventory_settings_pkey PRIMARY KEY (id),
  CONSTRAINT product_outlet_inventory_settings_product_fkey FOREIGN KEY (product_id) REFERENCES public.products(id),
  CONSTRAINT product_outlet_inventory_settings_reorder_term_fkey FOREIGN KEY (reorder_term_id) REFERENCES public.reorder_terms(id)
);
CREATE TABLE public.products (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  type USER-DEFINED NOT NULL,
  product_name character varying NOT NULL,
  billing_name character varying,
  item_code character varying NOT NULL UNIQUE,
  sku character varying UNIQUE,
  unit_id uuid NOT NULL,
  category_id uuid,
  is_returnable boolean DEFAULT false,
  push_to_ecommerce boolean DEFAULT false,
  hsn_code character varying,
  tax_preference USER-DEFINED,
  intra_state_tax_id uuid,
  inter_state_tax_id uuid,
  primary_image_url text,
  image_urls jsonb,
  selling_price numeric,
  selling_price_currency character varying DEFAULT 'INR'::character varying,
  mrp numeric,
  ptr numeric,
  sales_account_id uuid,
  sales_description text,
  cost_price numeric,
  cost_price_currency character varying DEFAULT 'INR'::character varying,
  purchase_account_id uuid,
  preferred_vendor_id uuid,
  purchase_description text,
  length numeric,
  width numeric,
  height numeric,
  dimension_unit character varying DEFAULT 'cm'::character varying,
  weight numeric,
  weight_unit character varying DEFAULT 'kg'::character varying,
  manufacturer_id uuid,
  brand_id uuid,
  mpn character varying,
  upc character varying,
  isbn character varying,
  ean character varying,
  track_assoc_ingredients boolean DEFAULT false,
  buying_rule_old character varying,
  schedule_of_drug_old character varying,
  is_track_inventory boolean DEFAULT true,
  track_bin_location boolean DEFAULT false,
  track_batches boolean DEFAULT false,
  inventory_account_id uuid,
  inventory_valuation_method USER-DEFINED CHECK (inventory_valuation_method IS NULL OR (inventory_valuation_method = ANY (ARRAY['FIFO'::inventory_valuation_method, 'LIFO'::inventory_valuation_method, 'FEFO'::inventory_valuation_method, 'Weighted Average'::inventory_valuation_method, 'Specific Identification'::inventory_valuation_method]))),
  storage_id uuid,
  rack_id uuid,
  reorder_point integer DEFAULT 0,
  reorder_term_id uuid,
  is_active boolean DEFAULT true,
  is_lock boolean DEFAULT false,
  created_at timestamp without time zone DEFAULT now(),
  created_by_id uuid,
  updated_at timestamp without time zone DEFAULT now(),
  updated_by_id uuid,
  track_serial_number boolean DEFAULT false,
  buying_rule_id uuid,
  schedule_of_drug_id uuid,
  lock_unit_pack numeric,
  storage_description text,
  about text,
  uses_description text,
  how_to_use text,
  dosage_description text,
  missed_dose_description text,
  safety_advice text,
  side_effects jsonb,
  faq_text jsonb,
  CONSTRAINT products_pkey PRIMARY KEY (id),
  CONSTRAINT products_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES public.brands(id),
  CONSTRAINT products_intra_state_tax_id_fkey FOREIGN KEY (intra_state_tax_id) REFERENCES public.tax_groups(id),
  CONSTRAINT products_storage_id_fkey FOREIGN KEY (storage_id) REFERENCES public.storage_locations(id),
  CONSTRAINT products_inter_state_tax_id_fkey FOREIGN KEY (inter_state_tax_id) REFERENCES public.associate_taxes(id),
  CONSTRAINT products_manufacturer_id_fkey FOREIGN KEY (manufacturer_id) REFERENCES public.manufacturers(id),
  CONSTRAINT products_unit_id_units_id_fk FOREIGN KEY (unit_id) REFERENCES public.units(id),
  CONSTRAINT products_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id),
  CONSTRAINT products_preferred_vendor_id_vendors_id_fk FOREIGN KEY (preferred_vendor_id) REFERENCES public.vendors(id),
  CONSTRAINT products_sales_account_id_accounts_id_fk FOREIGN KEY (sales_account_id) REFERENCES public.accounts(id),
  CONSTRAINT products_purchase_account_id_accounts_id_fk FOREIGN KEY (purchase_account_id) REFERENCES public.accounts(id),
  CONSTRAINT products_inventory_account_id_accounts_id_fk FOREIGN KEY (inventory_account_id) REFERENCES public.accounts(id),
  CONSTRAINT products_rack_id_racks_id_fk FOREIGN KEY (rack_id) REFERENCES public.racks(id),
  CONSTRAINT products_buying_rule_id_buying_rules_id_fk FOREIGN KEY (buying_rule_id) REFERENCES public.buying_rules(id),
  CONSTRAINT products_schedule_of_drug_id_schedules_id_fk FOREIGN KEY (schedule_of_drug_id) REFERENCES public.schedules(id)
);
CREATE TABLE public.racks (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  rack_code character varying NOT NULL UNIQUE,
  rack_name character varying,
  storage_id uuid,
  capacity integer,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT racks_pkey PRIMARY KEY (id),
  CONSTRAINT racks_storage_id_storage_locations_id_fk FOREIGN KEY (storage_id) REFERENCES public.storage_locations(id)
);
CREATE TABLE public.reorder_terms (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  term_name character varying NOT NULL,
  description text,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT now(),
  quantity integer NOT NULL DEFAULT 1 CHECK (quantity > 0),
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
  outlet_id uuid,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT reorder_terms_pkey PRIMARY KEY (id)
);
CREATE TABLE public.sales_eway_bills (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  sale_id uuid,
  bill_number character varying UNIQUE,
  bill_date timestamp without time zone DEFAULT now(),
  supply_type character varying DEFAULT 'Outward'::character varying,
  sub_type character varying DEFAULT 'Supply'::character varying,
  transporter_id character varying,
  vehicle_number character varying,
  status character varying DEFAULT 'active'::character varying,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT sales_eway_bills_pkey PRIMARY KEY (id),
  CONSTRAINT sales_eway_bills_sale_id_sales_orders_id_fk FOREIGN KEY (sale_id) REFERENCES public.sales_orders(id)
);
CREATE TABLE public.sales_orders (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  customer_id uuid NOT NULL,
  sale_number character varying UNIQUE,
  reference character varying,
  sale_date timestamp without time zone DEFAULT now(),
  expected_shipment_date timestamp without time zone,
  delivery_method character varying,
  payment_terms character varying,
  document_type character varying NOT NULL,
  status character varying DEFAULT 'Draft'::character varying,
  total numeric NOT NULL,
  currency character varying DEFAULT 'INR'::character varying,
  customer_notes text,
  terms_and_conditions text,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT sales_orders_pkey PRIMARY KEY (id),
  CONSTRAINT sales_orders_customer_id_customers_id_fk FOREIGN KEY (customer_id) REFERENCES public.customers(id)
);
CREATE TABLE public.sales_payment_links (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  customer_id uuid NOT NULL,
  amount numeric NOT NULL,
  link_url text NOT NULL,
  status character varying DEFAULT 'active'::character varying,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT sales_payment_links_pkey PRIMARY KEY (id),
  CONSTRAINT sales_payment_links_customer_id_customers_id_fk FOREIGN KEY (customer_id) REFERENCES public.customers(id)
);
CREATE TABLE public.sales_payments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  customer_id uuid NOT NULL,
  payment_number character varying UNIQUE,
  payment_date timestamp without time zone DEFAULT now(),
  payment_mode character varying,
  amount numeric NOT NULL,
  bank_charges numeric DEFAULT 0.00,
  reference character varying,
  deposit_to character varying,
  notes text,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT sales_payments_pkey PRIMARY KEY (id),
  CONSTRAINT sales_payments_customer_id_customers_id_fk FOREIGN KEY (customer_id) REFERENCES public.customers(id)
);
CREATE TABLE public.schedules (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  shedule_name character varying NOT NULL UNIQUE,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT schedules_pkey PRIMARY KEY (id)
);
CREATE TABLE public.states (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  country_id uuid NOT NULL,
  name character varying NOT NULL,
  code character varying,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT states_pkey PRIMARY KEY (id),
  CONSTRAINT states_country_id_countries_id_fk FOREIGN KEY (country_id) REFERENCES public.countries(id)
);
CREATE TABLE public.storage_locations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  location_name character varying NOT NULL UNIQUE,
  temperature_range character varying,
  description text,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT storage_locations_pkey PRIMARY KEY (id)
);
CREATE TABLE public.strengths (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  strength_name character varying NOT NULL UNIQUE,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT strengths_pkey PRIMARY KEY (id)
);
CREATE TABLE public.tax_group_taxes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  tax_group_id uuid,
  tax_id uuid,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT tax_group_taxes_pkey PRIMARY KEY (id),
  CONSTRAINT tax_group_taxes_tax_group_id_fkey FOREIGN KEY (tax_group_id) REFERENCES public.tax_groups(id),
  CONSTRAINT tax_group_taxes_tax_id_fkey FOREIGN KEY (tax_id) REFERENCES public.associate_taxes(id)
);
CREATE TABLE public.tax_groups (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  tax_group_name character varying NOT NULL UNIQUE,
  tax_rate numeric NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT tax_groups_pkey PRIMARY KEY (id)
);
CREATE TABLE public.tds_group_items (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  tds_group_id uuid,
  tds_rate_id uuid,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT tds_group_items_pkey PRIMARY KEY (id),
  CONSTRAINT tds_group_items_tds_group_id_fkey FOREIGN KEY (tds_group_id) REFERENCES public.tds_groups(id),
  CONSTRAINT tds_group_items_tds_rate_id_fkey FOREIGN KEY (tds_rate_id) REFERENCES public.tds_rates(id)
);
CREATE TABLE public.tds_groups (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  group_name character varying NOT NULL UNIQUE,
  applicable_from timestamp without time zone,
  applicable_to timestamp without time zone,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT tds_groups_pkey PRIMARY KEY (id)
);
CREATE TABLE public.tds_rates (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  tax_name character varying NOT NULL UNIQUE,
  section_id uuid,
  base_rate numeric NOT NULL,
  surcharge_rate numeric DEFAULT 0.00,
  cess_rate numeric DEFAULT 0.00,
  payable_account_id uuid,
  receivable_account_id uuid,
  is_higher_rate boolean DEFAULT false,
  reason_higher_rate text,
  applicable_from timestamp without time zone,
  applicable_to timestamp without time zone,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT tds_rates_pkey PRIMARY KEY (id),
  CONSTRAINT tds_rates_section_id_fkey FOREIGN KEY (section_id) REFERENCES public.tds_sections(id),
  CONSTRAINT tds_rates_payable_account_id_fkey FOREIGN KEY (payable_account_id) REFERENCES public.accounts(id),
  CONSTRAINT tds_rates_receivable_account_id_fkey FOREIGN KEY (receivable_account_id) REFERENCES public.accounts(id)
);
CREATE TABLE public.tds_sections (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  section_name character varying NOT NULL UNIQUE,
  description text,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT tds_sections_pkey PRIMARY KEY (id)
);
CREATE TABLE public.transactional_sequences (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  module character varying NOT NULL,
  prefix character varying NOT NULL DEFAULT ''::character varying,
  next_number integer NOT NULL DEFAULT 1,
  padding integer NOT NULL DEFAULT 6,
  is_active boolean DEFAULT true,
  updated_at timestamp with time zone DEFAULT now(),
  suffix character varying DEFAULT ''::character varying,
  outlet_id uuid,
  CONSTRAINT transactional_sequences_pkey PRIMARY KEY (id)
);
CREATE TABLE public.units (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  unit_name character varying NOT NULL UNIQUE,
  unit_symbol character varying,
  unit_type USER-DEFINED,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT now(),
  uqc_id uuid,
  CONSTRAINT units_pkey PRIMARY KEY (id),
  CONSTRAINT units_uqc_id_fkey FOREIGN KEY (uqc_id) REFERENCES public.uqc(id)
);
CREATE TABLE public.uqc (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  uqc_code character varying NOT NULL UNIQUE,
  description character varying NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT uqc_pkey PRIMARY KEY (id)
);
CREATE TABLE public.vendor_bank_accounts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  vendor_id uuid,
  holder_name text,
  bank_name text,
  account_number text,
  ifsc text,
  is_primary boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT vendor_bank_accounts_pkey PRIMARY KEY (id),
  CONSTRAINT vendor_bank_accounts_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.vendors(id)
);
CREATE TABLE public.vendor_contact_persons (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  vendor_id uuid,
  salutation text,
  first_name text,
  last_name text,
  email text,
  work_phone text,
  mobile_phone text,
  designation text,
  department text,
  is_primary boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT vendor_contact_persons_pkey PRIMARY KEY (id),
  CONSTRAINT vendor_contact_persons_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.vendors(id)
);
CREATE TABLE public.vendors (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
  outlet_id uuid,
  vendor_number character varying UNIQUE,
  display_name character varying NOT NULL,
  salutation character varying,
  first_name character varying,
  last_name character varying,
  company_name character varying,
  email character varying,
  phone character varying,
  mobile_phone character varying,
  designation character varying,
  department character varying,
  website character varying,
  vendor_language character varying DEFAULT 'English'::character varying,
  gst_treatment character varying,
  gstin character varying,
  source_of_supply character varying,
  pan character varying,
  currency character varying DEFAULT 'INR'::character varying,
  payment_terms character varying,
  is_msme_registered boolean DEFAULT false,
  msme_registration_type character varying,
  msme_registration_number character varying,
  is_drug_registered boolean DEFAULT false,
  drug_licence_type character varying,
  drug_license_20 character varying,
  drug_license_21 character varying,
  drug_license_20b character varying,
  drug_license_21b character varying,
  is_fssai_registered boolean DEFAULT false,
  fssai_number character varying,
  tds_rate_id character varying,
  enable_portal boolean DEFAULT false,
  remarks text,
  x_handle character varying,
  facebook_handle character varying,
  whatsapp_number character varying,
  source character varying DEFAULT 'User'::character varying,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  billing_attention text,
  billing_address_street_1 text,
  billing_address_street_2 text,
  billing_city text,
  billing_state text,
  billing_pincode text,
  billing_country_region text,
  billing_phone text,
  billing_fax text,
  shipping_attention text,
  shipping_address_street_1 text,
  shipping_address_street_2 text,
  shipping_city text,
  shipping_state text,
  shipping_pincode text,
  shipping_country_region text,
  shipping_phone text,
  shipping_fax text,
  price_list_id uuid,
  CONSTRAINT vendors_pkey PRIMARY KEY (id)
);
```
