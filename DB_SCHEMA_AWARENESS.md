# DB Schema Awareness — Zerpai ERP

> **Source**: `current schema.txt` (PostgreSQL DDL dump, 74 base tables, extracted 2026-03-24)
> **Purpose**: Developer knowledge file — what each table is, why it exists, and what data it stores.
> **Rule**: Never invent columns or tables not listed here. Run `npm run db:pull` before schema changes.
> **Multi-tenancy**: Most business tables carry `org_id` + `outlet_id`. See reference table at bottom.
> **Exception**: `products`, `composite_items`, and all lookup/reference tables are GLOBAL (no org_id).

---

## Quick Reference — Module → Tables

| Module | Tables |
|--------|--------|
| Accounting | account_transactions, accounts, accounts_fiscal_years, accounts_journal_number_settings, accounts_journal_templates, accounts_journal_template_items, accounts_manual_journals, accounts_manual_journal_items, accounts_manual_journal_attachments, accounts_manual_journal_tag_mappings, accounts_recurring_journals, accounts_recurring_journal_items, accounts_reporting_tags, transaction_locks |
| TDS | tds_sections, tds_rates, tds_groups, tds_group_items |
| Audit | audit_logs, audit_logs_archive |
| Products (Global) | products, batches, product_contents, product_outlet_inventory_settings, product_warehouse_stocks, product_warehouse_stock_adjustments, outlet_inventory |
| Composite Items | composite_items, composite_item_parts, composite_item_outlet_inventory_settings |
| Inventory / Warehouse | warehouses, storage_locations, racks |
| Drug / Pharma Masters | buying_rules, schedules, strengths, contents |
| Sales | sales_orders, sales_payments, sales_payment_links, sales_eway_bills |
| Customers | customers, customer_contact_persons |
| Purchases / Vendors | vendors, vendor_contact_persons, vendor_bank_accounts, item_vendor_mappings |
| Items Masters | categories, brands, manufacturers, units, uqc, reorder_terms |
| Pricing & Tax | price_lists, price_list_items, price_list_volume_ranges, associate_taxes, tax_groups, tax_group_taxes, hsn_sac_codes, payment_terms |
| Settings & Org | organization, settings_branding, settings_locations, settings_outlets, settings_transaction_series, transactional_sequences |
| Lookup / Reference | countries, states, timezones, currencies, industries, company_id_labels, shipment_preferences |

---

## 1. Accounting Module

### `accounts`
**What it is**: Chart of accounts — the master ledger account list.
**Why it exists**: Double-entry bookkeeping requires every transaction to map to debit/credit accounts. This is the master list from which all journal entries are assembled.
**Key data collected**:
- `account_code` / `system_account_name` — unique identifier and name (system accounts are seeded at org setup)
- `account_type` / `account_group` — enum classification (Assets, Liabilities, Income, Expenses, Equity, etc.)
- `parent_id` — self-referencing FK enabling hierarchical account trees (e.g., Bank Accounts under Assets)
- `is_system` — system-seeded accounts (Sales, COGS, etc.) cannot be deleted or renamed
- `is_deletable`, `is_active`, `is_deleted` — soft delete with deletability guard
- `account_number` / `ifsc` — populated for bank accounts linked to actual bank branches
- `show_in_zerpai_expense` / `add_to_watchlist` — dashboard visibility flags
- `user_account_name` — user's custom display name (overrides system name)
- `org_id` / `outlet_id` — multi-tenancy (system accounts use zero-UUID sentinel)

---

### `account_transactions`
**What it is**: Individual debit/credit transaction lines posted to a ledger account.
**Why it exists**: This is the actual journal ledger — every financial event writes rows here. Drives balance sheets, P&L, and ledger reports.
**Key data collected**:
- `account_id` → FK to `accounts`
- `transaction_type` — e.g., "sale", "purchase", "manual_journal", "payment"
- `debit` / `credit` — double-entry: always one is 0.00 per row
- `reference_number` — voucher/invoice number for traceability
- `source_id` / `source_type` — polymorphic FK back to the originating record (sales_order, manual_journal, payment, etc.)
- `contact_id` / `contact_type` — who the transaction was with (customer/vendor)
- `org_id` / `outlet_id` — mandatory multi-tenancy

---

### `accounts_fiscal_years`
**What it is**: Fiscal year period definitions per org/outlet.
**Why it exists**: Indian fiscal year is April–March. Journals and all financial reports are scoped to fiscal year.
**Key data collected**:
- `name` — e.g., "FY 2025–26"
- `start_date` / `end_date` — typically April 1 to March 31
- `is_active` — the currently open fiscal year

---

### `accounts_journal_number_settings`
**What it is**: Configuration for auto-generating manual journal entry numbers.
**Why it exists**: Every manual journal needs a unique sequential reference number. This stores the prefix and counter.
**Key data collected**:
- `auto_generate` — if true, system assigns numbers automatically
- `prefix` — e.g., "JV-" produces "JV-000001"
- `next_number` — the auto-increment counter
- `is_manual_override_allowed` — whether users can type their own number

---

### `accounts_journal_templates`
**What it is**: Reusable journal entry templates for recurring patterns.
**Why it exists**: Accountants post the same entries repeatedly (monthly rent, depreciation). Templates save setup time and reduce errors.
**Key data collected**:
- `template_name`, `reference_number`, `notes`
- `reporting_method` — accrual / cash / both
- `currency_code` — default INR
- `enter_amount` — flag: use template amounts or prompt user to enter amounts at posting time

---

### `accounts_journal_template_items`
**What it is**: Debit/credit line items belonging to a journal template.
**Why it exists**: One template = many line items (same double-entry structure as manual journal items).
**Key data collected**:
- `template_id` → FK to `accounts_journal_templates`
- `account_id` → which ledger account
- `type` — Debit or Credit (enum)
- `debit` / `credit`, `sort_order`, `contact_id`, `contact_type`

---

### `accounts_manual_journals`
**What it is**: Posted manual journal entries (the header record).
**Why it exists**: Manual journals handle non-automated accounting: adjustments, corrections, opening balances, year-end entries.
**Key data collected**:
- `journal_number` — unique sequential number (from `accounts_journal_number_settings`)
- `fiscal_year_id` → FK to `accounts_fiscal_years`
- `journal_date` — effective posting date
- `status` — draft / published / void
- `total_amount` — sum of debit side (must equal credit side to balance)
- `reporting_method` — accrual_and_cash / accrual_only / cash_only
- `is_13th_month_adjustment` — special flag for year-end closing entries
- `recurring_journal_id` → FK to `accounts_recurring_journals` (set if auto-generated)
- `is_deleted`, `created_by`

---

### `accounts_manual_journal_items`
**What it is**: Individual debit/credit line items within a manual journal.
**Why it exists**: One journal header = many line items. Each line hits a specific account with a specific amount.
**Key data collected**:
- `manual_journal_id` → parent journal
- `account_id` → the ledger account
- `contact_id` / `contact_type` / `contact_name` — who the line relates to (customer, vendor, employee)
- `debit` / `credit`, `description`, `sort_order`

---

### `accounts_manual_journal_attachments`
**What it is**: File attachments (supporting documents) for a manual journal.
**Why it exists**: Auditors require supporting documents (invoices, receipts, bank statements) for every journal entry.
**Key data collected**:
- `manual_journal_id` → parent journal
- `file_name`, `file_path` (Cloudflare R2 URL), `file_size`, `uploaded_at`

---

### `accounts_manual_journal_tag_mappings`
**What it is**: Many-to-many join between journal line items and reporting tags.
**Why it exists**: Reporting tags enable filtering P&L and balance sheet by custom dimensions (project, cost center, department) without changing the chart of accounts.
**Key data collected**:
- `manual_journal_item_id` → FK to `accounts_manual_journal_items`
- `reporting_tag_id` → FK to `accounts_reporting_tags`

---

### `accounts_recurring_journals`
**What it is**: Scheduled recurring journal profile (header).
**Why it exists**: Some journals repeat on schedule (monthly rent, loan EMI, depreciation). A recurring profile auto-generates journals on due dates.
**Key data collected**:
- `profile_name`, `repeat_every` — "day" / "week" / "month" / "year"
- `interval` — e.g., interval=1 + repeat_every="month" = monthly
- `start_date` / `end_date`, `never_expires`
- `status` — active / paused / completed
- `last_generated_date` — tracks what periods have already been generated

---

### `accounts_recurring_journal_items`
**What it is**: Template line items for a recurring journal.
**Why it exists**: Stores the debit/credit rows that get copied into each generated journal cycle.
**Key data collected**:
- `recurring_journal_id`, `account_id`, `debit`, `credit`, `contact_id`, `contact_name`, `description`, `sort_order`

---

### `accounts_reporting_tags`
**What it is**: Custom dimension labels attachable to journal lines.
**Why it exists**: Allows reporting by project, department, cost center, or any user-defined category without modifying the chart of accounts.
**Key data collected**:
- `tag_name`, `is_active` — simple org-scoped master

---

### `transaction_locks`
**What it is**: Period-lock records preventing editing of transactions before a certain date.
**Why it exists**: After GST filing or audit, transactions in that period must be locked to prevent backdated changes.
**Key data collected**:
- `module_name` — which module is locked (Sales, Purchases, Accounting, etc.)
- `lock_date` — no changes allowed on or before this date
- `reason` — why the lock was applied

---

## 2. TDS (Tax Deducted at Source)

### `tds_sections`
**What it is**: Income Tax Act sections under which TDS is deducted (e.g., 194A — interest, 194C — contractors, 194J — professionals).
**Why it exists**: Indian TDS rules are section-specific. Each payment type maps to a designated section.
**Key data collected**:
- `section_name` (e.g., "194C"), `description`, `is_active`

---

### `tds_rates`
**What it is**: TDS rate configurations linked to a section.
**Why it exists**: Each section has multiple rates (individual vs company, or 20% higher rate for non-PAN holders).
**Key data collected**:
- `tax_name`, `section_id` → FK to `tds_sections`
- `base_rate`, `surcharge_rate`, `cess_rate` — effective TDS % = base + surcharge + cess
- `payable_account_id` / `receivable_account_id` → which ledger accounts to credit/debit when TDS is applied
- `is_higher_rate` / `reason_higher_rate` — 20% higher rate scenario (no PAN, non-filer)
- `applicable_from` / `applicable_to` — validity period

---

### `tds_groups`
**What it is**: Named groupings of TDS rates for easy assignment to vendors.
**Why it exists**: A vendor may attract multiple TDS rates. Groups let you assign a bundle to a vendor at once.
**Key data collected**:
- `group_name`, `applicable_from`, `applicable_to`, `is_active`

---

### `tds_group_items`
**What it is**: Join table — which TDS rates belong to which group.
**Key data collected**: `tds_group_id` → FK to `tds_groups`, `tds_rate_id` → FK to `tds_rates`

---

## 3. Audit

### `audit_logs`
**What it is**: Real-time immutable change log for all significant table mutations.
**Why it exists**: Compliance, fraud detection, and debugging. Every INSERT/UPDATE/DELETE on business tables is captured automatically via PostgreSQL triggers.
**Key data collected**:
- `table_name`, `record_id`, `action` (INSERT/UPDATE/DELETE)
- `old_values` / `new_values` — jsonb snapshots of the row before/after change
- `changed_columns` — array of only the columns that actually changed
- `user_id`, `actor_name` — who made the change
- `txid` — PostgreSQL transaction ID for precise ordering
- `module_name`, `request_id`, `source` — context about origin of the change
- `org_id`, `outlet_id` — full tenancy context

---

### `audit_logs_archive`
**What it is**: Cold storage for older audit log rows moved out of the hot table.
**Why it exists**: `audit_logs` grows very fast (every row change = 1+ rows). Rows older than N months are moved here to keep the hot table lean and fast.
**Key data**: Identical to `audit_logs` plus `archived_at` timestamp.

---

## 4. Products (Global — No org_id Filtering)

> ⚠️ **CRITICAL**: The `products` table is GLOBAL. Never add `org_id` filtering to products queries. All organizations share the same product catalog. This is intentional for pharmaceutical/FMCG distribution where products are standardized nationally.

### `products`
**What it is**: The master product/item catalog — every SKU, drug, or service that can be sold or purchased.
**Why it exists**: Central source of truth for all items. Sales, purchases, inventory, price lists, and tax calculations all reference this table.
**Key data collected**:
- `product_name` / `billing_name` — display name and the name printed on invoices/bills
- `item_code` / `sku` — unique internal identifiers
- `type` — Goods / Service / Digital (enum)
- `unit_id` → FK to `units` (e.g., Tablet, Strip, Kg, Box)
- `category_id` → FK to `categories`
- `hsn_code` — GST-required HSN/SAC code for the product
- `tax_preference` — Taxable / Tax Exempt (enum)
- `intra_state_tax_id` → FK to `tax_groups` (CGST+SGST for intra-state sales)
- `inter_state_tax_id` → FK to `associate_taxes` (IGST for inter-state sales)
- `selling_price`, `mrp`, `ptr`, `cost_price` — pricing fields
- `selling_price_currency` / `cost_price_currency` — currency for each price
- `sales_account_id` / `purchase_account_id` / `inventory_account_id` → accounting ledger linkage
- `preferred_vendor_id` → FK to `vendors`
- `manufacturer_id` → FK to `manufacturers`
- `brand_id` → FK to `brands`
- `mpn`, `upc`, `isbn`, `ean` — global product identifiers for barcode/ecommerce
- `track_batches`, `track_serial_number`, `is_track_inventory` — inventory tracking modes
- `track_bin_location` — whether to assign to a specific rack/bin in warehouse
- `inventory_valuation_method` — FIFO / LIFO / Weighted Average (enum)
- `storage_id` → FK to `storage_locations` (temperature zone for pharma)
- `rack_id` → FK to `racks` (bin location)
- `reorder_point`, `reorder_term_id` → automated reorder triggers
- `buying_rule_id` → FK to `buying_rules` (pharma sale rules — OTC, Rx, Schedule H, etc.)
- `schedule_of_drug_id` → FK to `schedules` (drug schedule classification)
- `track_assoc_ingredients` — whether to track API ingredient composition
- `lock_unit_pack` — fixed pack size that cannot be changed at sale time
- Rich content fields: `about`, `uses_description`, `how_to_use`, `dosage_description`, `missed_dose_description`, `safety_advice`, `side_effects` (jsonb), `faq_text` (jsonb) — for ecommerce/patient-facing pages
- `is_active`, `is_lock`, `is_returnable`, `push_to_ecommerce`

---

### `batches`
**What it is**: Batch/lot records for products requiring batch tracking (primarily pharma).
**Why it exists**: Pharmaceutical regulations require tracking batch numbers and expiry dates. FIFO inventory valuation needs expiry-aware batch tracking.
**Key data collected**:
- `product_id` → FK to `products`
- `batch` — batch/lot number (e.g., "BN240312")
- `exp` — expiry date
- `mrp` / `ptr` — batch-specific pricing (can differ per batch)
- `unit_pack` — pack size for this specific batch
- `is_manufacture_details`, `manufacture_batch_number`, `manufacture_exp` — manufacturer's own batch reference (sometimes differs from retail batch)

---

### `product_contents`
**What it is**: Active pharmaceutical ingredient (API) composition of a drug product.
**Why it exists**: Drugs are defined by their active ingredients. This powers ingredient-based search, drug interaction checks, and schedule auto-detection.
**Key data collected**:
- `product_id` → FK to `products`
- `content_id` → FK to `contents` (ingredient name, e.g., "Paracetamol")
- `strength_id` → FK to `strengths` (concentration, e.g., "500mg")
- `shedule_id` → FK to `schedules` (drug schedule for this specific ingredient)
- `display_order` — order in which ingredients appear on the label

---

### `product_outlet_inventory_settings`
**What it is**: Per-outlet reorder configuration for a product.
**Why it exists**: Reorder points differ per outlet — a high-traffic outlet reorders earlier than a small one.
**Key data collected**:
- `product_id`, `outlet_id`, `org_id`
- `reorder_point` — quantity threshold below which to trigger a reorder alert
- `reorder_term_id` → FK to `reorder_terms` (what quantity to reorder)

---

### `product_warehouse_stocks`
**What it is**: Current stock levels for a product in a specific warehouse.
**Why it exists**: Multi-warehouse inventory management — tracks units per location, separating accounting stock (what invoices say) from physical stock (what's actually there).
**Key data collected**:
- `product_id`, `warehouse_id`, `org_id`, `outlet_id`
- `opening_stock` / `opening_stock_value` — starting inventory when the product was first added
- `accounting_stock` — quantity per processed invoices/bills
- `physical_stock` — quantity per last physical count
- `committed_stock` — reserved for confirmed but unfulfilled orders

---

### `product_warehouse_stock_adjustments`
**What it is**: Audit trail for every manual stock adjustment.
**Why it exists**: When physical count differs from system count, an adjustment reconciles them. This table records who changed what, why, and the before/after quantities.
**Key data collected**:
- `product_id`, `warehouse_id`, `org_id`, `outlet_id`
- `adjustment_type` — "physical_count", "damaged", "expired", "transfer", "write_off"
- `previous_accounting_stock` / `previous_physical_stock` / `new_physical_stock`
- `committed_stock`, `variance_qty` — difference between accounting and physical
- `reason`, `notes` — mandatory justification

---

### `outlet_inventory`
**What it is**: Simplified stock record per outlet for fast POS-level queries.
**Why it exists**: POS counter stock lookup needs to be fast. This table gives a pre-computed outlet-level view without joining warehouse tables.
**Key data collected**:
- `outlet_id`, `product_id`
- `current_stock`, `reserved_stock`, `available_stock` (computed: current − reserved)
- `batch_no`, `expiry_date` — pharma FIFO tracking at outlet level
- `min_stock_level`, `max_stock_level` — replenishment alert thresholds

---

## 5. Composite Items

### `composite_items`
**What it is**: Bundle/kit products assembled from multiple component products.
**Why it exists**: Retail and pharma sell bundles (e.g., "Diabetes Care Kit" = glucometer + strips + lancets). Bundles have their own SKU, pricing, and inventory tracking.
**Key data collected**:
- Same rich structure as `products` (pricing, tax, dimensions, tracking flags)
- `type` — Bundle / Assembly / Kit (enum)
- Has its own `sku`, `selling_price`, `cost_price`, `hsn_code`, `tax preferences`
- `inventory_valuation_method`, `track_batches`, `track_serial_number`

---

### `composite_item_parts`
**What it is**: Bill of Materials — the component list of a composite item.
**Why it exists**: Defines which products make up the bundle and in what quantities. Used for cost calculation and stock deduction when a bundle is sold.
**Key data collected**:
- `composite_item_id` → FK to `composite_items`
- `component_product_id` → FK to `products`
- `quantity` — units of component per bundle (e.g., 50 strips per kit)
- `selling_price_override` / `cost_price_override` — per-component price override within this bundle

---

### `composite_item_outlet_inventory_settings`
**What it is**: Per-outlet reorder configuration for composite items.
**Why it exists**: Same purpose as `product_outlet_inventory_settings` but for bundle/kit items.
**Key data collected**: `composite_item_id`, `outlet_id`, `org_id`, `reorder_point`, `reorder_term_id`

---

## 6. Inventory / Warehouse

### `warehouses`
**What it is**: Physical warehouse or storage facility definitions.
**Why it exists**: Multi-warehouse businesses need to track stock per location separately. All `product_warehouse_stocks` rows reference a warehouse.
**Key data collected**:
- `org_id`, `outlet_id`
- `name`, `attention` — warehouse name and contact person name
- Full address: `address_street_1`, `address_street_2`, `city`, `state`, `zip_code`, `country_region`
- `phone`, `email`, `is_active`

---

### `storage_locations`
**What it is**: Physical storage condition categories (temperature-controlled zones).
**Why it exists**: Pharma regulations require products to be stored under specific conditions (refrigerated, room temp, frozen). Products reference this to indicate their required storage condition.
**Key data collected**:
- `location_name` — e.g., "Refrigerated (2°C–8°C)", "Controlled Room Temperature (15°C–25°C)"
- `temperature_range`, `min_temp_c`, `max_temp_c`
- `is_cold_chain`, `requires_fridge`
- `display_text`, `common_examples` — UI display helpers
- `storage_type` — "cold", "ambient", "frozen", "controlled"
- `sort_order`

---

### `racks`
**What it is**: Rack/bin locations within a warehouse for bin-location tracking.
**Why it exists**: Products with `track_bin_location = true` are assigned to specific racks. Enables accurate pick lists and receiving.
**Key data collected**:
- `rack_code` (unique) / `rack_name`
- `storage_id` — which temperature zone / storage area this rack is in
- `capacity` — maximum units the rack can hold

---

## 7. Drug / Pharma Masters

### `buying_rules`
**What it is**: Rules governing how a drug may be sold (prescription requirements, sale restrictions).
**Why it exists**: Indian pharmaceutical law mandates specific sale rules per drug schedule. This table codifies rules so POS can enforce them at the point of sale automatically.
**Key data collected**:
- `buying_rule` — rule name (e.g., "OTC", "Prescription Only", "Schedule H", "Schedule X")
- `associated_schedule_codes` — which drug schedule codes trigger this rule
- `requires_rx` — prescription must be recorded before sale
- `requires_patient_info`, `requires_doctor_name`, `requires_prescription_date` — data collected at time of sale
- `requires_age_check` — age-restricted drugs (e.g., tobacco analogs)
- `institutional_only`, `blocks_retail_sale` — distribution channel restrictions
- `quantity_limit` — max quantity per transaction
- `allows_refill` — can be refilled without a new prescription
- `log_to_special_register` — H1 narcotic/psychotropic register requirement
- `is_saleable`, `sort_order`

---

### `schedules`
**What it is**: Indian drug schedule classifications (Schedule H, H1, X, G, J, OTC, etc.).
**Why it exists**: Drugs and Cosmetics Act 1940 classifies drugs into schedules. Each schedule has specific sale, storage, labeling, and record-keeping requirements enforced by the system.
**Key data collected**:
- `shedule_name` (note: legacy typo in column name) — e.g., "Schedule H", "Schedule X", "Schedule G"
- `schedule_code` — short code (e.g., "H", "H1", "X") used in `buying_rules.associated_schedule_codes`
- `reference_description` — the legal/regulatory reference text
- `requires_prescription`, `requires_h1_register`, `is_narcotic`, `requires_batch_tracking`
- `is_common` — commonly used schedules shown first in dropdowns

---

### `strengths`
**What it is**: Drug strength/concentration master (e.g., 500mg, 10mg/5ml, 0.1%).
**Why it exists**: Pharma products need standardized strength descriptors for ingredient labeling, search, and regulatory reporting.
**Key data collected**:
- `strength_name` (unique) — e.g., "500mg", "250mg/5ml", "0.025%"; `is_active`

---

### `contents`
**What it is**: Active pharmaceutical ingredient (API) name master.
**Why it exists**: Ingredient names must be standardized using INN (International Non-proprietary Names) for consistent labeling and search.
**Key data collected**:
- `content_name` (unique) — generic/INN drug name (e.g., "Paracetamol", "Amoxicillin"); `is_active`

---

## 8. Sales Module

### `sales_orders`
**What it is**: Sales invoice / order header records.
**Why it exists**: The primary sales transaction record. Every invoice, proforma, order, or quote is stored here.
**Key data collected**:
- `customer_id` → FK to `customers`
- `sale_number` (unique) — invoice/order number
- `sale_date`, `expected_shipment_date`
- `document_type` — Invoice / Order / Proforma / Quote / Credit Note / Debit Note
- `status` — Draft / Confirmed / Shipped / Invoiced / Paid / Cancelled
- `total`, `currency`
- `payment_terms`, `delivery_method`, `reference`
- `customer_notes`, `terms_and_conditions`

---

### `sales_payments`
**What it is**: Customer payment receipts.
**Why it exists**: Tracks all money received from customers — against invoices or as advance payments.
**Key data collected**:
- `customer_id`, `payment_number` (unique)
- `payment_date`, `payment_mode` — Cash / UPI / Card / NEFT / RTGS / Cheque
- `amount`, `bank_charges`
- `deposit_to` — which bank/cash account received the payment
- `reference` — cheque number / UTR / transaction reference
- `notes`

---

### `sales_payment_links`
**What it is**: Payment link generation records for online/digital collection.
**Why it exists**: Enables sending a payment URL to customers for UPI/card gateway payment without the customer visiting in person.
**Key data collected**:
- `customer_id`, `amount`, `link_url`, `status` — active / expired / paid

---

### `sales_eway_bills`
**What it is**: E-way bill records for GST-compliant goods movement.
**Why it exists**: GST law mandates e-way bills for goods moved above ₹50,000. These must be generated before dispatch and stored for compliance.
**Key data collected**:
- `sale_id` → FK to `sales_orders`
- `bill_number` (unique) — government-issued e-way bill number
- `bill_date`, `supply_type` (Outward), `sub_type` (Supply/Export/etc.)
- `transporter_id`, `vehicle_number` — transport details
- `status` — active / cancelled / expired

---

## 9. Customers

### `customers`
**What it is**: Customer master — individuals and businesses that purchase from the organization.
**Why it exists**: All sales transactions reference a customer. The complete profile including billing, GST compliance, drug licenses, and credit settings is stored here.
**Key data collected**:
- **Identity**: `display_name`, `customer_type` (Business/Individual), `salutation`, `first_name`, `last_name`, `company_name`, `customer_number` (unique)
- **Contact**: `email`, `phone`, `mobile_phone`, `whatsapp_number`, `website`
- **GST compliance**: `gstin`, `gst_treatment`, `place_of_supply`, `tax_preference`, `exemption_reason`
- **Financial**: `pan`, `payment_terms`, `credit_limit`, `opening_balance`, `receivable_balance`, `currency_id`
- **Addresses**: Full separate `billing_address_*` and `shipping_address_*` field sets with FK refs to `states` and `countries`
- **Drug licenses** (for pharma distributors): `is_drug_registered`, `drug_licence_type`, `drug_license_20`, `drug_license_21`, `drug_license_20b`, `drug_license_21b` + corresponding `*_doc_url` fields
- **FSSAI** (food businesses): `is_fssai_registered`, `fssai`, `fssai_doc_url`
- **MSME**: `is_msme_registered`, `msme_registration_type`, `msme_number`, `msme_doc_url`
- **B2B context**: `business_type`, `designation`, `department`
- **B2C personal**: `date_of_birth`, `age`, `gender`, `place_of_customer`
- **Loyalty**: `privilege_card_number`, `parent_customer_id` (sub-account linking)
- **Portal/digital**: `enable_portal`, `price_list_id`
- **Social**: `facebook_handle`, `twitter_handle`
- `remarks`, `is_recurring`, `status` (active/inactive)

---

### `customer_contact_persons`
**What it is**: Additional named contact persons for a business customer.
**Why it exists**: B2B customers have multiple contacts (Accounts Manager, Purchase Head, MD). Each is stored with their role.
**Key data collected**:
- `customer_id` → FK to `customers`
- `salutation`, `first_name`, `last_name`, `email`, `work_phone`, `mobile_phone`
- `display_order` — order shown in the UI

---

## 10. Purchases / Vendors

### `vendors`
**What it is**: Vendor/supplier master — companies and individuals that supply goods or services.
**Why it exists**: All purchase transactions reference a vendor. Complete profile including GST, bank details, drug licenses, and payment settings is stored here.
**Key data collected**:
- **Identity**: `display_name`, `salutation`, `first_name`, `last_name`, `company_name`, `vendor_number` (unique)
- **Contact**: `email`, `phone`, `mobile_phone`, `website`, `whatsapp_number`
- **GST**: `gstin`, `gst_treatment`, `source_of_supply`, `pan`
- **Financial**: `currency`, `payment_terms`, `tds_rate_id`, `price_list_id`
- **Addresses**: Full `billing_*` and `shipping_*` field sets
- **Drug licenses**: `is_drug_registered`, `drug_licence_type`, `drug_license_20`, `drug_license_21`, `drug_license_20b`, `drug_license_21b`
- **FSSAI**: `is_fssai_registered`, `fssai_number`
- **MSME**: `is_msme_registered`, `msme_registration_type`, `msme_registration_number`
- **Social**: `x_handle`, `facebook_handle`
- **Portal**: `enable_portal`
- `source` — "User" (manually created) or "Import" (bulk import)
- `org_id`, `outlet_id` — vendors are org-scoped (unlike products/customers)

---

### `vendor_contact_persons`
**What it is**: Additional named contacts for a vendor.
**Why it exists**: Multiple points of contact per supplier (Sales Rep, Accounts Payable, Logistics coordinator).
**Key data collected**:
- `vendor_id`, `salutation`, `first_name`, `last_name`, `email`, `work_phone`, `mobile_phone`
- `designation`, `department`, `is_primary`

---

### `vendor_bank_accounts`
**What it is**: Bank account details for making payments to vendors.
**Why it exists**: Stores vendor banking details for NEFT/RTGS payment processing and payment reconciliation.
**Key data collected**:
- `vendor_id`, `holder_name`, `bank_name`, `account_number`, `ifsc`, `is_primary`

---

### `item_vendor_mappings`
**What it is**: Maps a product to a vendor with the vendor's own product reference codes.
**Why it exists**: The same product may be sourced from multiple vendors, each using their own catalog codes. This enables accurate purchase order generation and invoice matching.
**Key data collected**:
- `vendor_id`, `item_id` → FK to `products`
- `mapping_name` — label for this vendor-product relationship
- `vendor_product_code` — the vendor's own SKU/catalog number for this product

---

## 11. Items Masters

### `categories`
**What it is**: Product category hierarchy.
**Why it exists**: Products are organized into categories for browsing, filtering, reporting, and GST rate grouping.
**Key data collected**:
- `name`, `description`
- `parent_id` — self-referencing FK for nested categories (e.g., Medicines → Tablets → Antibiotics)
- `is_active`

---

### `brands`
**What it is**: Product brand master.
**Why it exists**: Products are tagged with brands for brand-level sales reporting, filtering, and ecommerce display.
**Key data collected**: `name` (unique), `is_active`

---

### `manufacturers`
**What it is**: Drug/product manufacturer master.
**Why it exists**: Products are linked to manufacturers for regulatory compliance, recall tracking, and manufacturer-level purchase analysis.
**Key data collected**: `name` (unique), `contact_info` (jsonb with address/phone), `is_active`

---

### `units`
**What it is**: Unit of measure master.
**Why it exists**: Every product must have a unit for quantity calculations, invoicing, and GST compliance (UQC codes on GST invoices).
**Key data collected**:
- `unit_name` (e.g., "Tablet", "Strip", "Box", "Kg", "Litre", "Nos")
- `unit_type` — quantity / weight / volume / length (enum)
- `unit_symbol` — abbreviated form (e.g., "TAB", "KG", "LTR")
- `uqc_id` → FK to `uqc` (the government's standardized Unit Quantity Code)

---

### `uqc`
**What it is**: GST Unit Quantity Code (UQC) master — government-defined standard codes.
**Why it exists**: GST e-invoices and GSTR filings require official UQC codes (e.g., NOS, KGS, LTR, PCS). This is the seeded reference list from the GST portal.
**Key data collected**:
- `uqc_code` (unique) — official GST code (e.g., "NOS", "KGS", "LTR", "PCS")
- `description`, `is_active`

---

### `reorder_terms`
**What it is**: Reorder quantity term definitions for automated reorder suggestions.
**Why it exists**: When stock falls below the reorder point, the system recommends ordering specific quantities (e.g., "Minimum Order Quantity", "Economic Order Quantity").
**Key data collected**:
- `term_name`, `description`
- `quantity` — the standard reorder quantity for this term
- `org_id`, `outlet_id` — can be org-specific terms

---

## 12. Pricing & Tax

### `price_lists`
**What it is**: Named pricing schemes assignable to customers or vendors.
**Why it exists**: Different customers get different prices (wholesale, retail, VIP, institutional). Price lists are the mechanism for maintaining multiple pricing tiers.
**Key data collected**:
- `name`, `description`, `currency` (default INR)
- `pricing_scheme` — "flat_rate" / "percentage_markup" / "percentage_discount" / "volume_based"
- `price_list_type` — "all_items" (applies to every product) / "specific_items" (only listed products)
- `percentage_type` / `percentage_value` — for markup/discount-based lists
- `discount_enabled` — shows discount column in price list item table
- `transaction_type` — "Sales" / "Purchases"
- `round_off_preference` — "never_mind" / "round_up" / "round_down"
- `status` — active / inactive

---

### `price_list_items`
**What it is**: Product-specific price overrides within a specific price list.
**Why it exists**: A price list may use global percentages but override rates for specific high-volume products.
**Key data collected**:
- `price_list_id` → FK to `price_lists`, `product_id` → FK to `products`
- `custom_rate` — specific override price for this product
- `discount_percentage` — or apply a % discount on the product's default selling price

---

### `price_list_volume_ranges`
**What it is**: Quantity-based tiered pricing within a price list item.
**Why it exists**: Bulk buyers get lower prices per unit. This table stores the quantity brackets and their corresponding rates.
**Key data collected**:
- `price_list_item_id` → FK to `price_list_items`
- `start_quantity` / `end_quantity` — the quantity range (e.g., 1–10 units, 11–50 units)
- `rate` — price per unit for this quantity tier

---

### `associate_taxes`
**What it is**: Individual tax rate components (CGST 9%, SGST 9%, IGST 18%, Cess 1%, etc.).
**Why it exists**: GST has multiple components per rate slab. Each component is stored separately so they can be assembled into tax groups and applied correctly on intra-state vs inter-state transactions.
**Key data collected**:
- `tax_name` (e.g., "CGST 9%", "SGST 9%", "IGST 18%", "Cess 1%")
- `tax_rate` — the percentage value
- `tax_type` — CGST / SGST / IGST / Cess / VAT (enum)
- `is_active`

---

### `tax_groups`
**What it is**: Composite GST tax group (e.g., GST 18% = CGST 9% + SGST 9%).
**Why it exists**: Products are assigned a tax group rather than individual tax components. The group bundles the applicable rates for clean product setup and automatic split on invoices.
**Key data collected**:
- `tax_group_name` (e.g., "GST 0%", "GST 5%", "GST 12%", "GST 18%", "GST 28%")
- `tax_rate` — combined effective rate (sum of all components)
- `is_active`

---

### `tax_group_taxes`
**What it is**: Join table — which individual tax rates (`associate_taxes`) make up each tax group.
**Key data collected**:
- `tax_group_id` → FK to `tax_groups`
- `tax_id` → FK to `associate_taxes`

---

### `hsn_sac_codes`
**What it is**: GST Harmonized System of Nomenclature (HSN) and Service Accounting Code (SAC) master.
**Why it exists**: Every product and service on a GST invoice must carry an HSN/SAC code. This is the government's reference table used for lookups and validation.
**Key data collected**:
- `type` — "HSN" (goods) or "SAC" (services)
- `code` — the numeric code (e.g., "3004" for pharma formulations, "9983" for software services)
- `description` — plain-English description of what the code covers

---

### `payment_terms`
**What it is**: Standard payment term definitions.
**Why it exists**: Payment terms drive invoice due date calculations, cash flow forecasting, and accounts receivable aging reports.
**Key data collected**:
- `term_name` (e.g., "Net 30", "Due on Receipt", "Net 60", "2/10 Net 30")
- `number_of_days` — days until payment is due from invoice date
- `description`, `is_active`

---

## 13. Settings & Organization

### `organization`
**What it is**: The top-level tenant record — one row per business registered on Zerpai.
**Why it exists**: The root of multi-tenancy. Every org-scoped table links back here via `org_id`. Created when a business signs up.
**Key data collected**:
- `name`, `slug` (unique URL-safe identifier), `system_id` (sequential human-readable ID)
- `state_id` → FK to `states` (home state for GST — determines default place of supply)
- `industry`, `logo_url`
- Financial settings: `base_currency`, `fiscal_year` (e.g., "April-March"), `timezone`
- Display settings: `date_format` (e.g., "DD/MM/YYYY"), `date_separator`
- Company registration: `company_id_label` (e.g., "CIN") + `company_id_value` (e.g., "U12345DL2020PLC123456")
- Payment stub: `payment_stub_address`, `has_separate_payment_stub_address`

---

### `settings_branding`
**What it is**: UI branding customization per organization (one row per org).
**Why it exists**: Allows businesses to customize the app's accent color and theme for a branded feel.
**Key data collected**:
- `org_id` (unique — one row per org)
- `accent_color` — hex color code (default `#22A95E`, Zerpai's primary green)
- `theme_mode` — "dark" / "light"
- `keep_branding` — whether to display Zerpai branding in the interface

---

### `settings_outlets`
**What it is**: Branch/outlet records — each physical or logical location of the business.
**Why it exists**: Multi-location businesses (chains, distributors, hospital groups) need separate branches with their own GSTIN, address, and operational settings.
**Key data collected**:
- `org_id`, `name`, `outlet_code` (short code for the branch)
- `gstin` — outlet-specific GSTIN (required when branches are in different states)
- `email`, `phone`
- Full address: `address`, `city`, `state`, `country`, `pincode`
- `is_active`

---

### `settings_locations`
**What it is**: Extended metadata/classification for an outlet.
**Why it exists**: Separates basic outlet contact data (`settings_outlets`) from location-type classification and hierarchy.
**Key data collected**:
- `outlet_id` → FK to `settings_outlets` (one-to-one relationship)
- `location_type` — "business" / "warehouse" / "store" / "distribution_center" (enum)
- `is_primary` — marks the headquarters or main outlet
- `parent_outlet_id` → FK to `settings_outlets` (hub-spoke hierarchy support)
- `logo_url` — outlet-specific logo that overrides the org logo

---

### `settings_transaction_series`
**What it is**: Named transaction number series configurations.
**Why it exists**: Businesses require specific invoice/order number formats (e.g., "INV/2025-26/001", "PO-MAR-0001"). Different document types or outlets can use different series.
**Key data collected**:
- `org_id`, `name` — series name (e.g., "Main Invoice Series", "Branch B Orders")
- `modules` — jsonb array of which modules/document types use this series

---

### `transactional_sequences`
**What it is**: Auto-increment sequence state per module per outlet.
**Why it exists**: Guarantees unique sequential, gap-free numbers for all transaction documents (invoices, orders, payments, journals).
**Key data collected**:
- `module` — document type (e.g., "sales_invoice", "purchase_order", "payment_receipt", "manual_journal")
- `prefix` / `suffix` — text wrapping around the number
- `next_number` — current counter value (incremented atomically on each use)
- `padding` — zero-padding length (padding=6 → "000001")
- `is_auto` — auto-increment vs manual entry
- `outlet_id` — per-outlet sequences for independent numbering per branch

---

## 14. Lookup / Reference Tables

System-wide seed data — no `org_id`, not tenant-specific, seeded at deployment.

### `countries`
**What it is**: ISO country master list.
**Key data**: `name`, `full_label`, `phone_code` (+91 for India), `short_code` (ISO 2-letter, e.g., "IN"), `primary_timezone_id`

---

### `states`
**What it is**: State/territory master, scoped per country.
**Key data**: `name`, `code` (state code used in GST place of supply, e.g., "DL" for Delhi), `state_id` → FK to `countries`, `is_active`

---

### `timezones`
**What it is**: IANA timezone master list.
**Key data**: `name`, `tzdb_name` (IANA format, e.g., "Asia/Kolkata"), `utc_offset` (e.g., "+05:30"), `display` (friendly label), `country_id`, `sort_order` (India shown first)

---

### `currencies`
**What it is**: ISO 4217 currency master.
**Key data**: `code` (e.g., "INR", "USD"), `name`, `symbol` (e.g., "₹"), `decimals` (2 for INR), `format` (e.g., "#,##,##0.00" for Indian number formatting)

---

### `industries`
**What it is**: Business industry type classifications shown during org setup.
**Key data**: `name` (e.g., "Pharmacy", "Retail", "FMCG", "Trading", "Manufacturing"), `sort_order`

---

### `company_id_labels`
**What it is**: Types of business registration IDs that can be selected on the company profile form.
**Key data**: `label` (e.g., "CIN", "LLPIN", "PAN", "UDYAM", "FSSAI"), `sort_order`

---

### `shipment_preferences`
**What it is**: Preferred courier/shipment method names displayed on sales invoices.
**Key data**: `name` (e.g., "BlueDart", "DTDC", "Self-Pickup", "Courier"), `is_active`

---

## Multi-Tenancy Reference

| Table | Has org_id | Has outlet_id | Notes |
|-------|-----------|---------------|-------|
| `products` | ❌ | ❌ | **GLOBAL** — never filter by org_id |
| `composite_items` | ❌ | ❌ | **GLOBAL** — never filter by org_id |
| `customers` | ❌ | ❌ | Currently global catalog |
| `batches`, `hsn_sac_codes` | ❌ | ❌ | Global reference data |
| All lookup tables (countries, states, currencies, etc.) | ❌ | ❌ | System-wide seed data |
| `vendors` | ✅ | ✅ | Org-scoped |
| `accounts` | ✅ (zero-UUID for system) | ✅ | System accounts use sentinel UUID |
| `account_transactions` | ✅ | ✅ | Mandatory multi-tenancy |
| All `accounts_*` tables | ✅ | ✅ | Mandatory multi-tenancy |
| `product_warehouse_stocks` | ✅ | ✅ | Per-warehouse, per-org |
| `product_outlet_inventory_settings` | ✅ | ✅ | Per-outlet, per-org |
| `reorder_terms` | ✅ | ✅ | Can be org-specific |
| `transactional_sequences` | ❌ | ✅ | Per-outlet sequences only |
| `warehouses` | ✅ | ✅ | Per-org warehouses |
| `settings_outlets` | ✅ (org_id col) | — | Is the outlet definition itself |
| `settings_locations` | ✅ | via outlet_id | Extended outlet metadata |
| `audit_logs` | ✅ | ✅ | Full tenancy context captured |

---

*Last updated: 2026-03-24 | Source: `current schema.txt` (74 base tables)*

## Appendix A - Full Column Inventory (Generated from `current schema.txt`)

This appendix is the exhaustive raw-column reference for every live base table in the schema dump. Use it together with the narrative sections above:
- The main body explains business meaning and usage.
- This appendix lists every column, its SQL type, and important DB-level flags/defaults/constraints.

### `account_transactions` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `account_id`: `uuid` | NOT NULL
- `transaction_date`: `timestamp without time zone` | NOT NULL DEFAULT now()
- `transaction_type`: `character varying`
- `reference_number`: `character varying`
- `description`: `text`
- `debit`: `numeric` | DEFAULT 0.00
- `credit`: `numeric` | DEFAULT 0.00
- `created_at`: `timestamp without time zone` | DEFAULT now()
- `source_id`: `uuid`
- `source_type`: `character varying`
- `org_id`: `uuid` | NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid
- `outlet_id`: `uuid`
- `contact_id`: `uuid`
- `contact_type`: `character varying`

**Table-level constraints / FKs**
- `CONSTRAINT account_transactions_pkey PRIMARY KEY (id)`
- `CONSTRAINT account_transactions_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id)`

---

### `accounts` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `system_account_name`: `character varying` | UNIQUE
- `account_code`: `character varying` | UNIQUE
- `is_active`: `boolean` | DEFAULT true
- `created_at`: `timestamp without time zone` | DEFAULT now()
- `parent_id`: `uuid`
- `account_group`: `USER-DEFINED` | NOT NULL DEFAULT 'Expenses'::account_group_enum
- `is_system`: `boolean` | DEFAULT false
- `account_type`: `USER-DEFINED` | NOT NULL
- `description`: `text`
- `account_number`: `character varying`
- `ifsc`: `character varying`
- `currency`: `character varying` | DEFAULT 'INR'::character varying
- `show_in_zerpai_expense`: `boolean` | DEFAULT false
- `add_to_watchlist`: `boolean` | DEFAULT false
- `is_deletable`: `boolean` | DEFAULT true
- `user_account_name`: `character varying`
- `created_by`: `uuid`
- `is_deleted`: `boolean` | DEFAULT false
- `modified_at`: `timestamp with time zone` | DEFAULT now()
- `modified_by`: `uuid`
- `org_id`: `uuid` | NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid
- `outlet_id`: `uuid`

**Table-level constraints / FKs**
- `CONSTRAINT accounts_pkey PRIMARY KEY (id)`
- `CONSTRAINT fk_accounts_parent FOREIGN KEY (parent_id) REFERENCES public.accounts(id)`

---

### `accounts_fiscal_years` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `org_id`: `uuid` | NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid
- `outlet_id`: `uuid`
- `name`: `character varying` | NOT NULL
- `start_date`: `date` | NOT NULL
- `end_date`: `date` | NOT NULL
- `is_active`: `boolean` | DEFAULT true
- `created_at`: `timestamp without time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT accounts_fiscal_years_pkey PRIMARY KEY (id)`

---

### `accounts_journal_number_settings` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `org_id`: `uuid` | NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid
- `outlet_id`: `uuid`
- `auto_generate`: `boolean` | DEFAULT true
- `prefix`: `character varying`
- `next_number`: `integer` | DEFAULT 1
- `is_manual_override_allowed`: `boolean` | DEFAULT false
- `user_id`: `uuid`

**Table-level constraints / FKs**
- `CONSTRAINT accounts_journal_number_settings_pkey PRIMARY KEY (id)`

---

### `accounts_journal_template_items` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `org_id`: `uuid` | NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid
- `outlet_id`: `uuid`
- `template_id`: `uuid` | NOT NULL
- `account_id`: `uuid` | NOT NULL
- `description`: `text`
- `contact_id`: `uuid`
- `contact_type`: `USER-DEFINED`
- `type`: `USER-DEFINED`
- `debit`: `numeric` | DEFAULT 0.00
- `credit`: `numeric` | DEFAULT 0.00
- `sort_order`: `integer`

**Table-level constraints / FKs**
- `CONSTRAINT accounts_journal_template_items_pkey PRIMARY KEY (id)`
- `CONSTRAINT accounts_journal_template_items_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.accounts_journal_templates(id)`
- `CONSTRAINT accounts_journal_template_items_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id)`

---

### `accounts_journal_templates` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `org_id`: `uuid` | NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid
- `outlet_id`: `uuid`
- `template_name`: `character varying` | NOT NULL
- `reference_number`: `character varying`
- `notes`: `text`
- `reporting_method`: `USER-DEFINED`
- `currency_code`: `character varying` | DEFAULT 'INR'::character varying
- `is_active`: `boolean` | DEFAULT true
- `enter_amount`: `boolean` | DEFAULT false
- `created_at`: `timestamp with time zone` | DEFAULT now()
- `updated_at`: `timestamp with time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT accounts_journal_templates_pkey PRIMARY KEY (id)`

---

### `accounts_manual_journal_attachments` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `org_id`: `uuid` | NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid
- `outlet_id`: `uuid`
- `manual_journal_id`: `uuid` | NOT NULL
- `file_name`: `character varying` | NOT NULL
- `file_path`: `text` | NOT NULL
- `file_size`: `integer`
- `uploaded_at`: `timestamp without time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT accounts_manual_journal_attachments_pkey PRIMARY KEY (id)`
- `CONSTRAINT accounts_manual_journal_attachments_manual_journal_id_fkey FOREIGN KEY (manual_journal_id) REFERENCES public.accounts_manual_journals(id)`

---

### `accounts_manual_journal_items` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `org_id`: `uuid` | NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid
- `outlet_id`: `uuid`
- `manual_journal_id`: `uuid` | NOT NULL
- `account_id`: `uuid` | NOT NULL
- `description`: `text`
- `contact_id`: `uuid`
- `contact_type`: `USER-DEFINED`
- `debit`: `numeric` | DEFAULT 0.00
- `credit`: `numeric` | DEFAULT 0.00
- `sort_order`: `integer`
- `created_at`: `timestamp with time zone` | DEFAULT now()
- `updated_at`: `timestamp with time zone` | DEFAULT now()
- `contact_name`: `character varying`

**Table-level constraints / FKs**
- `CONSTRAINT accounts_manual_journal_items_pkey PRIMARY KEY (id)`
- `CONSTRAINT accounts_manual_journal_items_manual_journal_id_fkey FOREIGN KEY (manual_journal_id) REFERENCES public.accounts_manual_journals(id)`
- `CONSTRAINT accounts_manual_journal_items_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id)`

---

### `accounts_manual_journal_tag_mappings` - Full Column Inventory

- `manual_journal_item_id`: `uuid` | NOT NULL
- `reporting_tag_id`: `uuid` | NOT NULL

**Table-level constraints / FKs**
- `CONSTRAINT accounts_manual_journal_tag_mappings_pkey PRIMARY KEY (manual_journal_item_id, reporting_tag_id)`
- `CONSTRAINT accounts_manual_journal_tag_mapping_manual_journal_item_id_fkey FOREIGN KEY (manual_journal_item_id) REFERENCES public.accounts_manual_journal_items(id)`
- `CONSTRAINT accounts_manual_journal_tag_mappings_reporting_tag_id_fkey FOREIGN KEY (reporting_tag_id) REFERENCES public.accounts_reporting_tags(id)`

---

### `accounts_manual_journals` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `org_id`: `uuid` | NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid
- `outlet_id`: `uuid`
- `journal_number`: `character varying` | NOT NULL UNIQUE
- `fiscal_year_id`: `uuid`
- `reference_number`: `character varying`
- `journal_date`: `date` | DEFAULT CURRENT_DATE
- `notes`: `text`
- `is_13th_month_adjustment`: `boolean` | DEFAULT false
- `reporting_method`: `USER-DEFINED` | DEFAULT 'accrual_and_cash'::accounts_reporting_method
- `currency_code`: `character varying` | DEFAULT 'INR'::character varying
- `status`: `USER-DEFINED` | DEFAULT 'draft'::accounts_manual_journal_status
- `total_amount`: `numeric` | DEFAULT 0.00
- `created_by`: `uuid`
- `created_at`: `timestamp without time zone` | DEFAULT now()
- `recurring_journal_id`: `uuid`
- `updated_at`: `timestamp with time zone` | DEFAULT now()
- `is_deleted`: `boolean` | NOT NULL DEFAULT false

**Table-level constraints / FKs**
- `CONSTRAINT accounts_manual_journals_pkey PRIMARY KEY (id)`
- `CONSTRAINT accounts_manual_journals_recurring_journal_id_fkey FOREIGN KEY (recurring_journal_id) REFERENCES public.accounts_recurring_journals(id)`
- `CONSTRAINT accounts_manual_journals_fiscal_year_id_fkey FOREIGN KEY (fiscal_year_id) REFERENCES public.accounts_fiscal_years(id)`

---

### `accounts_recurring_journal_items` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `recurring_journal_id`: `uuid` | NOT NULL
- `account_id`: `uuid` | NOT NULL
- `description`: `text`
- `contact_id`: `uuid`
- `contact_type`: `character varying`
- `debit`: `numeric` | DEFAULT 0.00
- `credit`: `numeric` | DEFAULT 0.00
- `sort_order`: `integer`
- `contact_name`: `character varying`

**Table-level constraints / FKs**
- `CONSTRAINT accounts_recurring_journal_items_pkey PRIMARY KEY (id)`
- `CONSTRAINT accounts_recurring_journal_items_recur_journal_id_fkey FOREIGN KEY (recurring_journal_id) REFERENCES public.accounts_recurring_journals(id)`
- `CONSTRAINT accounts_recurring_journal_items_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id)`

---

### `accounts_recurring_journals` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `org_id`: `uuid` | NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid
- `outlet_id`: `uuid`
- `profile_name`: `character varying` | NOT NULL
- `repeat_every`: `character varying` | NOT NULL
- `interval`: `integer` | NOT NULL DEFAULT 1
- `start_date`: `date` | NOT NULL
- `end_date`: `date`
- `never_expires`: `boolean` | DEFAULT true
- `reference_number`: `character varying`
- `notes`: `text`
- `currency_code`: `character varying` | DEFAULT 'INR'::character varying
- `reporting_method`: `character varying` | DEFAULT 'accrual_and_cash'::character varying
- `status`: `character varying` | DEFAULT 'active'::character varying
- `last_generated_date`: `timestamp without time zone`
- `created_at`: `timestamp without time zone` | DEFAULT now()
- `updated_at`: `timestamp without time zone` | DEFAULT now()
- `created_by`: `uuid`

**Table-level constraints / FKs**
- `CONSTRAINT accounts_recurring_journals_pkey PRIMARY KEY (id)`

---

### `accounts_reporting_tags` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `org_id`: `uuid` | NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid
- `outlet_id`: `uuid`
- `tag_name`: `character varying` | NOT NULL
- `is_active`: `boolean` | DEFAULT true

**Table-level constraints / FKs**
- `CONSTRAINT accounts_reporting_tags_pkey PRIMARY KEY (id)`

---

### `associate_taxes` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `tax_name`: `character varying` | NOT NULL UNIQUE
- `tax_rate`: `numeric` | NOT NULL
- `tax_type`: `USER-DEFINED`
- `is_active`: `boolean` | DEFAULT true
- `created_at`: `timestamp without time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT associate_taxes_pkey PRIMARY KEY (id)`

---

### `audit_logs` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `table_name`: `character varying` | NOT NULL
- `record_id`: `uuid` | NOT NULL
- `action`: `character varying` | NOT NULL
- `old_values`: `jsonb`
- `new_values`: `jsonb`
- `user_id`: `uuid` | NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid
- `created_at`: `timestamp with time zone` | DEFAULT now()
- `org_id`: `uuid` | NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid
- `outlet_id`: `uuid`
- `actor_name`: `text` | NOT NULL DEFAULT 'system'::text
- `schema_name`: `text` | NOT NULL DEFAULT 'public'::text
- `record_pk`: `text`
- `changed_columns`: `ARRAY`
- `txid`: `bigint` | NOT NULL DEFAULT txid_current()
- `source`: `text` | NOT NULL DEFAULT 'system'::text
- `module_name`: `text`
- `request_id`: `text`

**Table-level constraints / FKs**
- `CONSTRAINT audit_logs_pkey PRIMARY KEY (id)`

---

### `audit_logs_archive` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `table_name`: `character varying` | NOT NULL
- `record_id`: `uuid` | NOT NULL
- `action`: `character varying` | NOT NULL
- `old_values`: `jsonb`
- `new_values`: `jsonb`
- `user_id`: `uuid` | NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid
- `created_at`: `timestamp with time zone` | DEFAULT now()
- `org_id`: `uuid` | NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid
- `outlet_id`: `uuid`
- `actor_name`: `text` | NOT NULL DEFAULT 'system'::text
- `schema_name`: `text` | NOT NULL DEFAULT 'public'::text
- `record_pk`: `text`
- `changed_columns`: `ARRAY`
- `txid`: `bigint` | NOT NULL DEFAULT txid_current()
- `source`: `text` | NOT NULL DEFAULT 'system'::text
- `module_name`: `text`
- `request_id`: `text`
- `archived_at`: `timestamp with time zone` | NOT NULL DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT audit_logs_archive_pkey PRIMARY KEY (id)`

---

### `batches` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `product_id`: `uuid`
- `batch`: `character varying` | NOT NULL
- `exp`: `date` | NOT NULL
- `mrp`: `numeric` | NOT NULL
- `ptr`: `numeric` | NOT NULL
- `unit_pack`: `character varying`
- `is_manufacture_details`: `boolean` | DEFAULT false
- `manufacture_batch_number`: `character varying`
- `manufacture_exp`: `date`
- `is_active`: `boolean` | DEFAULT true
- `created_at`: `timestamp with time zone` | DEFAULT now()
- `updated_at`: `timestamp with time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT batches_pkey PRIMARY KEY (id)`
- `CONSTRAINT batches_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)`

---

### `brands` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `name`: `character varying` | NOT NULL UNIQUE
- `is_active`: `boolean` | DEFAULT true
- `created_at`: `timestamp without time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT brands_pkey PRIMARY KEY (id)`

---

### `buying_rules` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `buying_rule`: `character varying` | NOT NULL UNIQUE
- `is_active`: `boolean` | DEFAULT true
- `created_at`: `timestamp without time zone` | DEFAULT now()
- `rule_description`: `text`
- `system_behavior`: `text`
- `associated_schedule_codes`: `ARRAY` | NOT NULL DEFAULT ARRAY[]::text[]
- `requires_rx`: `boolean` | NOT NULL DEFAULT false
- `requires_patient_info`: `boolean` | NOT NULL DEFAULT false
- `is_saleable`: `boolean` | NOT NULL DEFAULT true
- `log_to_special_register`: `boolean` | NOT NULL DEFAULT false
- `requires_doctor_name`: `boolean` | NOT NULL DEFAULT false
- `requires_prescription_date`: `boolean` | NOT NULL DEFAULT false
- `requires_age_check`: `boolean` | NOT NULL DEFAULT false
- `institutional_only`: `boolean` | NOT NULL DEFAULT false
- `blocks_retail_sale`: `boolean` | NOT NULL DEFAULT false
- `quantity_limit`: `integer`
- `allows_refill`: `boolean` | NOT NULL DEFAULT false
- `sort_order`: `integer` | NOT NULL DEFAULT 0

**Table-level constraints / FKs**
- `CONSTRAINT buying_rules_pkey PRIMARY KEY (id)`

---

### `categories` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `name`: `character varying` | NOT NULL UNIQUE
- `description`: `text`
- `parent_id`: `uuid`
- `is_active`: `boolean` | DEFAULT true
- `created_at`: `timestamp without time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT categories_pkey PRIMARY KEY (id)`
- `CONSTRAINT categories_parent_id_categories_id_fk FOREIGN KEY (parent_id) REFERENCES public.categories(id)`

---

### `company_id_labels` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `label`: `character varying` | NOT NULL UNIQUE
- `is_active`: `boolean` | NOT NULL DEFAULT true
- `sort_order`: `smallint` | NOT NULL DEFAULT 0

**Table-level constraints / FKs**
- `CONSTRAINT company_id_labels_pkey PRIMARY KEY (id)`

---

### `composite_item_outlet_inventory_settings` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `org_id`: `uuid` | NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid
- `outlet_id`: `uuid`
- `composite_item_id`: `uuid` | NOT NULL
- `reorder_point`: `integer` | NOT NULL DEFAULT 0 CHECK (reorder_point >= 0)
- `reorder_term_id`: `uuid`
- `is_active`: `boolean` | NOT NULL DEFAULT true
- `created_by_id`: `uuid`
- `updated_by_id`: `uuid`
- `created_at`: `timestamp with time zone` | NOT NULL DEFAULT now()
- `updated_at`: `timestamp with time zone` | NOT NULL DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT composite_item_outlet_inventory_settings_pkey PRIMARY KEY (id)`
- `CONSTRAINT composite_item_outlet_inventory_settings_composite_item_fkey FOREIGN KEY (composite_item_id) REFERENCES public.composite_items(id)`
- `CONSTRAINT composite_item_outlet_inventory_settings_reorder_term_fkey FOREIGN KEY (reorder_term_id) REFERENCES public.reorder_terms(id)`

---

### `composite_item_parts` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `composite_item_id`: `uuid` | NOT NULL
- `component_product_id`: `uuid` | NOT NULL
- `quantity`: `numeric` | NOT NULL
- `selling_price_override`: `numeric`
- `cost_price_override`: `numeric`
- `created_at`: `timestamp with time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT composite_item_parts_pkey PRIMARY KEY (id)`
- `CONSTRAINT composite_item_parts_composite_item_id_fkey FOREIGN KEY (composite_item_id) REFERENCES public.composite_items(id)`
- `CONSTRAINT composite_item_parts_component_product_id_fkey FOREIGN KEY (component_product_id) REFERENCES public.products(id)`

---

### `composite_items` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `type`: `USER-DEFINED` | NOT NULL
- `product_name`: `character varying` | NOT NULL
- `sku`: `character varying` | UNIQUE
- `unit_id`: `uuid` | NOT NULL
- `category_id`: `uuid`
- `is_returnable`: `boolean` | DEFAULT false
- `push_to_ecommerce`: `boolean` | DEFAULT false
- `hsn_code`: `character varying`
- `tax_preference`: `USER-DEFINED`
- `intra_state_tax_id`: `uuid`
- `inter_state_tax_id`: `uuid`
- `primary_image_url`: `text`
- `image_urls`: `text`
- `selling_price`: `numeric`
- `selling_price_currency`: `character varying` | DEFAULT 'INR'::character varying
- `ptr`: `numeric`
- `sales_account_id`: `uuid`
- `sales_description`: `text`
- `cost_price`: `numeric`
- `purchase_account_id`: `uuid`
- `preferred_vendor_id`: `uuid`
- `purchase_description`: `text`
- `length`: `numeric`
- `width`: `numeric`
- `height`: `numeric`
- `dimension_unit`: `character varying` | DEFAULT 'cm'::character varying
- `weight`: `numeric`
- `weight_unit`: `character varying` | DEFAULT 'kg'::character varying
- `manufacturer_id`: `uuid`
- `brand_id`: `uuid`
- `mpn`: `character varying`
- `upc`: `character varying`
- `isbn`: `character varying`
- `ean`: `character varying`
- `is_track_inventory`: `boolean` | DEFAULT true
- `track_batches`: `boolean` | DEFAULT false
- `track_serial_number`: `boolean` | DEFAULT false
- `inventory_account_id`: `uuid`
- `inventory_valuation_method`: `USER-DEFINED`
- `reorder_point`: `integer` | DEFAULT 0
- `reorder_term_id`: `uuid`
- `is_active`: `boolean` | DEFAULT true
- `is_lock`: `boolean` | DEFAULT false
- `created_at`: `timestamp with time zone` | DEFAULT now()
- `created_by_id`: `uuid`
- `updated_at`: `timestamp with time zone` | DEFAULT now()
- `updated_by_id`: `uuid`

**Table-level constraints / FKs**
- `CONSTRAINT composite_items_pkey PRIMARY KEY (id)`
- `CONSTRAINT composite_items_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.units(id)`
- `CONSTRAINT composite_items_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id)`
- `CONSTRAINT composite_items_intra_state_tax_id_fkey FOREIGN KEY (intra_state_tax_id) REFERENCES public.associate_taxes(id)`
- `CONSTRAINT composite_items_inter_state_tax_id_fkey FOREIGN KEY (inter_state_tax_id) REFERENCES public.associate_taxes(id)`
- `CONSTRAINT composite_items_sales_account_id_fkey FOREIGN KEY (sales_account_id) REFERENCES public.accounts(id)`
- `CONSTRAINT composite_items_purchase_account_id_fkey FOREIGN KEY (purchase_account_id) REFERENCES public.accounts(id)`
- `CONSTRAINT composite_items_manufacturer_id_fkey FOREIGN KEY (manufacturer_id) REFERENCES public.manufacturers(id)`
- `CONSTRAINT composite_items_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES public.brands(id)`
- `CONSTRAINT composite_items_inventory_account_id_fkey FOREIGN KEY (inventory_account_id) REFERENCES public.accounts(id)`
- `CONSTRAINT composite_items_reorder_term_id_fkey FOREIGN KEY (reorder_term_id) REFERENCES public.reorder_terms(id)`

---

### `contents` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `content_name`: `character varying` | NOT NULL UNIQUE
- `is_active`: `boolean` | DEFAULT true
- `created_at`: `timestamp without time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT contents_pkey PRIMARY KEY (id)`

---

### `countries` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `name`: `character varying` | NOT NULL UNIQUE
- `full_label`: `character varying`
- `phone_code`: `character varying` | NOT NULL
- `short_code`: `character varying`
- `is_active`: `boolean` | DEFAULT true
- `created_at`: `timestamp without time zone` | DEFAULT now()
- `primary_timezone_id`: `uuid`

**Table-level constraints / FKs**
- `CONSTRAINT countries_pkey PRIMARY KEY (id)`
- `CONSTRAINT countries_primary_timezone_id_fkey FOREIGN KEY (primary_timezone_id) REFERENCES public.timezones(id)`

---

### `currencies` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `code`: `character varying` | NOT NULL UNIQUE
- `name`: `character varying` | NOT NULL
- `symbol`: `character varying`
- `decimals`: `integer` | DEFAULT 2
- `format`: `character varying`
- `is_active`: `boolean` | DEFAULT true
- `created_at`: `timestamp without time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT currencies_pkey PRIMARY KEY (id)`

---

### `customer_contact_persons` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `customer_id`: `uuid` | NOT NULL
- `salutation`: `character varying`
- `first_name`: `character varying`
- `last_name`: `character varying`
- `email`: `character varying`
- `work_phone`: `character varying`
- `mobile_phone`: `character varying`
- `display_order`: `integer` | DEFAULT 0
- `created_at`: `timestamp without time zone` | DEFAULT now()
- `updated_at`: `timestamp without time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT customer_contact_persons_pkey PRIMARY KEY (id)`
- `CONSTRAINT customer_contact_persons_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(id)`

---

### `customers` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `display_name`: `character varying` | NOT NULL
- `customer_type`: `character varying` | DEFAULT 'Business'::character varying
- `salutation`: `character varying`
- `first_name`: `character varying`
- `last_name`: `character varying`
- `company_name`: `character varying`
- `email`: `character varying`
- `phone`: `character varying`
- `mobile_phone`: `character varying`
- `gstin`: `character varying`
- `pan`: `character varying`
- `payment_terms`: `character varying`
- `billing_address`: `text`
- `shipping_address`: `text`
- `is_active`: `boolean` | DEFAULT true
- `receivables`: `numeric` | DEFAULT 0.00
- `created_at`: `timestamp without time zone` | DEFAULT now()
- `customer_number`: `character varying` | UNIQUE
- `designation`: `character varying`
- `department`: `character varying`
- `business_type`: `character varying`
- `customer_language`: `character varying` | DEFAULT 'English'::character varying
- `date_of_birth`: `date`
- `age`: `integer`
- `gender`: `character varying`
- `place_of_customer`: `character varying`
- `privilege_card_number`: `character varying`
- `parent_customer_id`: `uuid`
- `tax_preference`: `character varying`
- `exemption_reason`: `text`
- `drug_licence_type`: `character varying`
- `drug_license_20`: `character varying`
- `drug_license_21`: `character varying`
- `drug_license_20b`: `character varying`
- `drug_license_21b`: `character varying`
- `fssai`: `character varying`
- `msme_registration_type`: `character varying`
- `msme_number`: `character varying`
- `drug_license_20_doc_url`: `text`
- `drug_license_21_doc_url`: `text`
- `drug_license_20b_doc_url`: `text`
- `drug_license_21b_doc_url`: `text`
- `fssai_doc_url`: `text`
- `msme_doc_url`: `text`
- `opening_balance`: `numeric` | DEFAULT 0
- `credit_limit`: `numeric`
- `enable_portal`: `boolean` | DEFAULT false
- `facebook_handle`: `character varying`
- `twitter_handle`: `character varying`
- `whatsapp_number`: `character varying`
- `is_recurring`: `boolean` | DEFAULT false
- `gst_treatment`: `character varying`
- `place_of_supply`: `character varying`
- `website`: `character varying`
- `price_list_id`: `uuid`
- `receivable_balance`: `numeric` | DEFAULT 0
- `billing_address_street1`: `character varying`
- `billing_address_street2`: `character varying`
- `billing_address_city`: `character varying`
- `billing_address_zip`: `character varying`
- `billing_address_phone`: `character varying`
- `shipping_address_street1`: `character varying`
- `shipping_address_street2`: `character varying`
- `shipping_address_city`: `character varying`
- `shipping_address_zip`: `character varying`
- `shipping_address_phone`: `character varying`
- `remarks`: `text`
- `status`: `character varying` | DEFAULT 'active'::character varying
- `document_urls`: `text`
- `is_drug_registered`: `boolean`
- `is_fssai_registered`: `boolean`
- `is_msme_registered`: `boolean`
- `currency_id`: `uuid`
- `billing_address_state_id`: `uuid`
- `shipping_address_state_id`: `uuid`
- `billing_address_country_id`: `uuid`
- `shipping_address_country_id`: `uuid`

**Table-level constraints / FKs**
- `CONSTRAINT customers_pkey PRIMARY KEY (id)`
- `CONSTRAINT customers_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES public.currencies(id)`
- `CONSTRAINT customers_price_list_id_fkey FOREIGN KEY (price_list_id) REFERENCES public.price_lists(id)`
- `CONSTRAINT customers_parent_customer_id_fkey FOREIGN KEY (parent_customer_id) REFERENCES public.customers(id)`
- `CONSTRAINT customers_billing_address_state_id_states_id_fk FOREIGN KEY (billing_address_state_id) REFERENCES public.states(id)`
- `CONSTRAINT customers_shipping_address_state_id_states_id_fk FOREIGN KEY (shipping_address_state_id) REFERENCES public.states(id)`
- `CONSTRAINT customers_billing_address_country_id_fkey FOREIGN KEY (billing_address_country_id) REFERENCES public.countries(id)`
- `CONSTRAINT customers_shipping_address_country_id_fkey FOREIGN KEY (shipping_address_country_id) REFERENCES public.countries(id)`

---

### `hsn_sac_codes` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `type`: `USER-DEFINED` | NOT NULL
- `code`: `character varying` | NOT NULL UNIQUE
- `description`: `text` | NOT NULL

**Table-level constraints / FKs**
- `CONSTRAINT hsn_sac_codes_pkey PRIMARY KEY (id)`

---

### `industries` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `name`: `character varying` | NOT NULL UNIQUE
- `is_active`: `boolean` | NOT NULL DEFAULT true
- `sort_order`: `smallint` | NOT NULL DEFAULT 0

**Table-level constraints / FKs**
- `CONSTRAINT industries_pkey PRIMARY KEY (id)`

---

### `item_vendor_mappings` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `vendor_id`: `uuid` | NOT NULL
- `item_id`: `uuid` | NOT NULL
- `mapping_name`: `character varying` | NOT NULL
- `vendor_product_code`: `character varying`
- `created_at`: `timestamp with time zone` | DEFAULT now()
- `updated_at`: `timestamp with time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT item_vendor_mappings_pkey PRIMARY KEY (id)`
- `CONSTRAINT item_vendor_mappings_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.products(id)`

---

### `manufacturers` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `name`: `character varying` | NOT NULL UNIQUE
- `contact_info`: `jsonb`
- `is_active`: `boolean` | DEFAULT true
- `created_at`: `timestamp without time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT manufacturers_pkey PRIMARY KEY (id)`

---

### `organization` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `name`: `character varying` | NOT NULL
- `slug`: `character varying` | NOT NULL UNIQUE
- `is_active`: `boolean` | DEFAULT true
- `created_at`: `timestamp without time zone` | DEFAULT now()
- `updated_at`: `timestamp without time zone` | DEFAULT now()
- `state_id`: `uuid`
- `industry`: `character varying`
- `logo_url`: `text`
- `base_currency`: `character varying`
- `fiscal_year`: `character varying`
- `timezone`: `character varying`
- `date_format`: `character varying`
- `date_separator`: `character varying`
- `company_id_label`: `character varying`
- `company_id_value`: `character varying`
- `payment_stub_address`: `text`
- `has_separate_payment_stub_address`: `boolean` | NOT NULL DEFAULT false
- `system_id`: `character varying` | NOT NULL DEFAULT (nextval('organization_system_id_seq'::regclass))::text

**Table-level constraints / FKs**
- `CONSTRAINT organization_pkey PRIMARY KEY (id)`
- `CONSTRAINT organization_state_id_fkey FOREIGN KEY (state_id) REFERENCES public.states(id)`

---

### `outlet_inventory` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `outlet_id`: `uuid` | NOT NULL
- `product_id`: `uuid` | NOT NULL
- `current_stock`: `integer` | NOT NULL DEFAULT 0 CHECK (current_stock >= 0)
- `reserved_stock`: `integer` | DEFAULT 0
- `available_stock`: `integer` | DEFAULT (current_stock - reserved_stock)
- `batch_no`: `character varying`
- `expiry_date`: `date`
- `min_stock_level`: `integer` | DEFAULT 0
- `max_stock_level`: `integer` | DEFAULT 0
- `last_stock_update`: `timestamp with time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT outlet_inventory_pkey PRIMARY KEY (id)`

---

### `payment_terms` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `term_name`: `character varying` | NOT NULL UNIQUE
- `number_of_days`: `integer` | NOT NULL
- `description`: `text`
- `is_active`: `boolean` | DEFAULT true
- `created_at`: `timestamp without time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT payment_terms_pkey PRIMARY KEY (id)`

---

### `price_list_items` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `price_list_id`: `uuid` | NOT NULL
- `product_id`: `uuid` | NOT NULL
- `custom_rate`: `numeric`
- `discount_percentage`: `numeric`
- `is_active`: `boolean` | DEFAULT true
- `created_at`: `timestamp without time zone` | DEFAULT now()
- `updated_at`: `timestamp without time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT price_list_items_pkey PRIMARY KEY (id)`
- `CONSTRAINT price_list_items_price_list_id_fkey FOREIGN KEY (price_list_id) REFERENCES public.price_lists(id)`
- `CONSTRAINT price_list_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)`

---

### `price_list_volume_ranges` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `price_list_item_id`: `uuid` | NOT NULL
- `start_quantity`: `numeric` | NOT NULL
- `end_quantity`: `numeric`
- `rate`: `numeric` | NOT NULL
- `created_at`: `timestamp without time zone` | DEFAULT now()
- `updated_at`: `timestamp without time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT price_list_volume_ranges_pkey PRIMARY KEY (id)`
- `CONSTRAINT price_list_volume_ranges_price_list_item_id_fkey FOREIGN KEY (price_list_item_id) REFERENCES public.price_list_items(id)`

---

### `price_lists` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `name`: `character varying` | NOT NULL
- `description`: `text` | DEFAULT ''::text
- `currency`: `character varying` | DEFAULT 'INR'::character varying
- `pricing_scheme`: `character varying` | NOT NULL
- `details`: `text` | DEFAULT ''::text
- `round_off_preference`: `character varying` | DEFAULT 'never_mind'::character varying
- `status`: `character varying` | DEFAULT 'active'::character varying
- `created_at`: `timestamp with time zone` | DEFAULT now()
- `updated_at`: `timestamp with time zone` | DEFAULT now()
- `price_list_type`: `character varying` | DEFAULT 'all_items'::character varying
- `percentage_type`: `character varying`
- `percentage_value`: `numeric`
- `discount_enabled`: `boolean` | DEFAULT false
- `transaction_type`: `character varying` | DEFAULT 'Sales'::character varying

**Table-level constraints / FKs**
- `CONSTRAINT price_lists_pkey PRIMARY KEY (id)`

---

### `product_contents` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `product_id`: `uuid` | NOT NULL
- `content_id`: `uuid`
- `strength_id`: `uuid`
- `shedule_id`: `uuid`
- `display_order`: `integer` | DEFAULT 0
- `created_at`: `timestamp without time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT product_contents_pkey PRIMARY KEY (id)`
- `CONSTRAINT product_contents_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)`
- `CONSTRAINT product_contents_strength_id_fkey FOREIGN KEY (strength_id) REFERENCES public.strengths(id)`
- `CONSTRAINT product_contents_content_id_fkey FOREIGN KEY (content_id) REFERENCES public.contents(id)`
- `CONSTRAINT product_contents_schedule_id_fkey FOREIGN KEY (shedule_id) REFERENCES public.schedules(id)`

---

### `product_outlet_inventory_settings` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `org_id`: `uuid` | NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid
- `outlet_id`: `uuid`
- `product_id`: `uuid` | NOT NULL
- `reorder_point`: `integer` | NOT NULL DEFAULT 0 CHECK (reorder_point >= 0)
- `reorder_term_id`: `uuid`
- `is_active`: `boolean` | NOT NULL DEFAULT true
- `created_by_id`: `uuid`
- `updated_by_id`: `uuid`
- `created_at`: `timestamp with time zone` | NOT NULL DEFAULT now()
- `updated_at`: `timestamp with time zone` | NOT NULL DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT product_outlet_inventory_settings_pkey PRIMARY KEY (id)`
- `CONSTRAINT product_outlet_inventory_settings_product_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)`
- `CONSTRAINT product_outlet_inventory_settings_reorder_term_fkey FOREIGN KEY (reorder_term_id) REFERENCES public.reorder_terms(id)`

---

### `product_warehouse_stock_adjustments` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `product_id`: `uuid` | NOT NULL
- `warehouse_id`: `uuid` | NOT NULL
- `org_id`: `uuid` | NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid
- `outlet_id`: `uuid`
- `adjustment_type`: `text` | NOT NULL DEFAULT 'physical_count'::text CHECK (adjustment_type = 'physical_count'::text)
- `previous_accounting_stock`: `numeric` | NOT NULL DEFAULT 0
- `previous_physical_stock`: `numeric` | NOT NULL DEFAULT 0
- `new_physical_stock`: `numeric` | NOT NULL DEFAULT 0
- `committed_stock`: `numeric` | NOT NULL DEFAULT 0
- `variance_qty`: `numeric` | NOT NULL DEFAULT 0
- `reason`: `text` | NOT NULL
- `notes`: `text`
- `adjusted_at`: `timestamp with time zone` | NOT NULL DEFAULT now()
- `created_at`: `timestamp with time zone` | NOT NULL DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT product_warehouse_stock_adjustments_pkey PRIMARY KEY (id)`
- `CONSTRAINT product_warehouse_stock_adjustments_product_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)`
- `CONSTRAINT product_warehouse_stock_adjustments_warehouse_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id)`

---

### `product_warehouse_stocks` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `product_id`: `uuid` | NOT NULL
- `warehouse_id`: `uuid` | NOT NULL
- `org_id`: `uuid` | NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid
- `outlet_id`: `uuid`
- `opening_stock`: `numeric` | NOT NULL DEFAULT 0
- `opening_stock_value`: `numeric` | NOT NULL DEFAULT 0
- `accounting_stock`: `numeric` | NOT NULL DEFAULT 0
- `physical_stock`: `numeric` | NOT NULL DEFAULT 0
- `committed_stock`: `numeric` | NOT NULL DEFAULT 0
- `created_at`: `timestamp with time zone` | NOT NULL DEFAULT now()
- `updated_at`: `timestamp with time zone` | NOT NULL DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT product_warehouse_stocks_pkey PRIMARY KEY (id)`
- `CONSTRAINT product_warehouse_stocks_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)`
- `CONSTRAINT product_warehouse_stocks_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id)`

---

### `products` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `type`: `USER-DEFINED` | NOT NULL
- `product_name`: `character varying` | NOT NULL
- `billing_name`: `character varying`
- `item_code`: `character varying` | NOT NULL UNIQUE
- `sku`: `character varying` | UNIQUE
- `unit_id`: `uuid` | NOT NULL
- `category_id`: `uuid`
- `is_returnable`: `boolean` | DEFAULT false
- `push_to_ecommerce`: `boolean` | DEFAULT false
- `hsn_code`: `character varying`
- `tax_preference`: `USER-DEFINED`
- `intra_state_tax_id`: `uuid`
- `inter_state_tax_id`: `uuid`
- `primary_image_url`: `text`
- `image_urls`: `jsonb`
- `selling_price`: `numeric`
- `selling_price_currency`: `character varying` | DEFAULT 'INR'::character varying
- `mrp`: `numeric`
- `ptr`: `numeric`
- `sales_account_id`: `uuid`
- `sales_description`: `text`
- `cost_price`: `numeric`
- `cost_price_currency`: `character varying` | DEFAULT 'INR'::character varying
- `purchase_account_id`: `uuid`
- `preferred_vendor_id`: `uuid`
- `purchase_description`: `text`
- `length`: `numeric`
- `width`: `numeric`
- `height`: `numeric`
- `dimension_unit`: `character varying` | DEFAULT 'cm'::character varying
- `weight`: `numeric`
- `weight_unit`: `character varying` | DEFAULT 'kg'::character varying
- `manufacturer_id`: `uuid`
- `brand_id`: `uuid`
- `mpn`: `character varying`
- `upc`: `character varying`
- `isbn`: `character varying`
- `ean`: `character varying`
- `track_assoc_ingredients`: `boolean` | DEFAULT false
- `buying_rule_old`: `character varying`
- `schedule_of_drug_old`: `character varying`
- `is_track_inventory`: `boolean` | DEFAULT true
- `track_bin_location`: `boolean` | DEFAULT false
- `track_batches`: `boolean` | DEFAULT false
- `inventory_account_id`: `uuid`
- `inventory_valuation_method`: `USER-DEFINED` | CHECK (inventory_valuation_method IS NULL OR (inventory_valuation_method = ANY (ARRAY['FIFO'::inventory_valuation_method, 'LIFO'::inventory_valuation_method, 'FEFO'::inventory_valuation_method, 'Weighted Average'::inventory_valuation_method, 'Specific Identification'::inventory_valuation_method])))
- `storage_id`: `uuid`
- `rack_id`: `uuid`
- `reorder_point`: `integer` | DEFAULT 0
- `reorder_term_id`: `uuid`
- `is_active`: `boolean` | DEFAULT true
- `is_lock`: `boolean` | DEFAULT false
- `created_at`: `timestamp without time zone` | DEFAULT now()
- `created_by_id`: `uuid`
- `updated_at`: `timestamp without time zone` | DEFAULT now()
- `updated_by_id`: `uuid`
- `track_serial_number`: `boolean` | DEFAULT false
- `buying_rule_id`: `uuid`
- `schedule_of_drug_id`: `uuid`
- `lock_unit_pack`: `numeric`
- `storage_description`: `text`
- `about`: `text`
- `uses_description`: `text`
- `how_to_use`: `text`
- `dosage_description`: `text`
- `missed_dose_description`: `text`
- `safety_advice`: `text`
- `side_effects`: `jsonb`
- `faq_text`: `jsonb`

**Table-level constraints / FKs**
- `CONSTRAINT products_pkey PRIMARY KEY (id)`
- `CONSTRAINT products_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES public.brands(id)`
- `CONSTRAINT products_intra_state_tax_id_fkey FOREIGN KEY (intra_state_tax_id) REFERENCES public.tax_groups(id)`
- `CONSTRAINT products_storage_id_fkey FOREIGN KEY (storage_id) REFERENCES public.storage_locations(id)`
- `CONSTRAINT products_inter_state_tax_id_fkey FOREIGN KEY (inter_state_tax_id) REFERENCES public.associate_taxes(id)`
- `CONSTRAINT products_manufacturer_id_fkey FOREIGN KEY (manufacturer_id) REFERENCES public.manufacturers(id)`
- `CONSTRAINT products_unit_id_units_id_fk FOREIGN KEY (unit_id) REFERENCES public.units(id)`
- `CONSTRAINT products_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id)`
- `CONSTRAINT products_preferred_vendor_id_vendors_id_fk FOREIGN KEY (preferred_vendor_id) REFERENCES public.vendors(id)`
- `CONSTRAINT products_sales_account_id_accounts_id_fk FOREIGN KEY (sales_account_id) REFERENCES public.accounts(id)`
- `CONSTRAINT products_purchase_account_id_accounts_id_fk FOREIGN KEY (purchase_account_id) REFERENCES public.accounts(id)`
- `CONSTRAINT products_inventory_account_id_accounts_id_fk FOREIGN KEY (inventory_account_id) REFERENCES public.accounts(id)`
- `CONSTRAINT products_rack_id_racks_id_fk FOREIGN KEY (rack_id) REFERENCES public.racks(id)`
- `CONSTRAINT products_buying_rule_id_buying_rules_id_fk FOREIGN KEY (buying_rule_id) REFERENCES public.buying_rules(id)`
- `CONSTRAINT products_schedule_of_drug_id_schedules_id_fk FOREIGN KEY (schedule_of_drug_id) REFERENCES public.schedules(id)`

---

### `racks` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `rack_code`: `character varying` | NOT NULL UNIQUE
- `rack_name`: `character varying`
- `storage_id`: `uuid`
- `capacity`: `integer`
- `is_active`: `boolean` | DEFAULT true
- `created_at`: `timestamp without time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT racks_pkey PRIMARY KEY (id)`

---

### `reorder_terms` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `term_name`: `character varying` | NOT NULL
- `description`: `text`
- `is_active`: `boolean` | DEFAULT true
- `created_at`: `timestamp without time zone` | DEFAULT now()
- `quantity`: `integer` | NOT NULL DEFAULT 1 CHECK (quantity > 0)
- `org_id`: `uuid` | NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid
- `outlet_id`: `uuid`
- `updated_at`: `timestamp with time zone` | NOT NULL DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT reorder_terms_pkey PRIMARY KEY (id)`

---

### `sales_eway_bills` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `sale_id`: `uuid`
- `bill_number`: `character varying` | UNIQUE
- `bill_date`: `timestamp without time zone` | DEFAULT now()
- `supply_type`: `character varying` | DEFAULT 'Outward'::character varying
- `sub_type`: `character varying` | DEFAULT 'Supply'::character varying
- `transporter_id`: `character varying`
- `vehicle_number`: `character varying`
- `status`: `character varying` | DEFAULT 'active'::character varying
- `created_at`: `timestamp without time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT sales_eway_bills_pkey PRIMARY KEY (id)`
- `CONSTRAINT sales_eway_bills_sale_id_sales_orders_id_fk FOREIGN KEY (sale_id) REFERENCES public.sales_orders(id)`

---

### `sales_orders` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `customer_id`: `uuid` | NOT NULL
- `sale_number`: `character varying` | UNIQUE
- `reference`: `character varying`
- `sale_date`: `timestamp without time zone` | DEFAULT now()
- `expected_shipment_date`: `timestamp without time zone`
- `delivery_method`: `character varying`
- `payment_terms`: `character varying`
- `document_type`: `character varying` | NOT NULL
- `status`: `character varying` | DEFAULT 'Draft'::character varying
- `total`: `numeric` | NOT NULL
- `currency`: `character varying` | DEFAULT 'INR'::character varying
- `customer_notes`: `text`
- `terms_and_conditions`: `text`
- `created_at`: `timestamp without time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT sales_orders_pkey PRIMARY KEY (id)`
- `CONSTRAINT sales_orders_customer_id_customers_id_fk FOREIGN KEY (customer_id) REFERENCES public.customers(id)`

---

### `sales_payment_links` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `customer_id`: `uuid` | NOT NULL
- `amount`: `numeric` | NOT NULL
- `link_url`: `text` | NOT NULL
- `status`: `character varying` | DEFAULT 'active'::character varying
- `created_at`: `timestamp without time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT sales_payment_links_pkey PRIMARY KEY (id)`
- `CONSTRAINT sales_payment_links_customer_id_customers_id_fk FOREIGN KEY (customer_id) REFERENCES public.customers(id)`

---

### `sales_payments` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `customer_id`: `uuid` | NOT NULL
- `payment_number`: `character varying` | UNIQUE
- `payment_date`: `timestamp without time zone` | DEFAULT now()
- `payment_mode`: `character varying`
- `amount`: `numeric` | NOT NULL
- `bank_charges`: `numeric` | DEFAULT 0.00
- `reference`: `character varying`
- `deposit_to`: `character varying`
- `notes`: `text`
- `created_at`: `timestamp without time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT sales_payments_pkey PRIMARY KEY (id)`
- `CONSTRAINT sales_payments_customer_id_customers_id_fk FOREIGN KEY (customer_id) REFERENCES public.customers(id)`

---

### `schedules` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `shedule_name`: `character varying` | NOT NULL UNIQUE
- `is_active`: `boolean` | DEFAULT true
- `created_at`: `timestamp without time zone` | DEFAULT now()
- `schedule_code`: `character varying`
- `reference_description`: `text`
- `requires_prescription`: `boolean` | NOT NULL DEFAULT false
- `requires_h1_register`: `boolean` | NOT NULL DEFAULT false
- `is_narcotic`: `boolean` | NOT NULL DEFAULT false
- `requires_batch_tracking`: `boolean` | NOT NULL DEFAULT false
- `sort_order`: `integer` | NOT NULL DEFAULT 0
- `is_common`: `boolean` | NOT NULL DEFAULT false

**Table-level constraints / FKs**
- `CONSTRAINT schedules_pkey PRIMARY KEY (id)`

---

### `settings_branding` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `org_id`: `uuid` | NOT NULL UNIQUE
- `accent_color`: `character varying` | NOT NULL DEFAULT '#22A95E'::character varying
- `theme_mode`: `character varying` | NOT NULL DEFAULT 'dark'::character varying CHECK (theme_mode::text = ANY (ARRAY['dark'::character varying, 'light'::character varying]::text[]))
- `keep_branding`: `boolean` | NOT NULL DEFAULT false
- `created_at`: `timestamp with time zone` | NOT NULL DEFAULT now()
- `updated_at`: `timestamp with time zone` | NOT NULL DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT settings_branding_pkey PRIMARY KEY (id)`
- `CONSTRAINT settings_branding_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id)`

---

### `settings_locations` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `outlet_id`: `uuid` | NOT NULL UNIQUE
- `org_id`: `uuid` | NOT NULL
- `location_type`: `USER-DEFINED` | NOT NULL DEFAULT 'business'::location_type
- `is_primary`: `boolean` | NOT NULL DEFAULT false
- `parent_outlet_id`: `uuid`
- `logo_url`: `text`
- `created_at`: `timestamp with time zone` | NOT NULL DEFAULT now()
- `updated_at`: `timestamp with time zone` | NOT NULL DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT settings_locations_pkey PRIMARY KEY (id)`
- `CONSTRAINT settings_locations_outlet_id_fkey FOREIGN KEY (outlet_id) REFERENCES public.settings_outlets(id)`
- `CONSTRAINT settings_locations_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id)`
- `CONSTRAINT settings_locations_parent_outlet_id_fkey FOREIGN KEY (parent_outlet_id) REFERENCES public.settings_outlets(id)`

---

### `settings_outlets` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `org_id`: `uuid` | NOT NULL
- `name`: `character varying` | NOT NULL
- `outlet_code`: `character varying` | NOT NULL
- `gstin`: `character varying`
- `email`: `character varying`
- `phone`: `character varying`
- `address`: `text`
- `city`: `character varying`
- `state`: `character varying`
- `country`: `character varying`
- `pincode`: `character varying`
- `is_active`: `boolean` | NOT NULL DEFAULT true
- `created_at`: `timestamp with time zone` | NOT NULL DEFAULT now()
- `updated_at`: `timestamp with time zone` | NOT NULL DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT settings_outlets_pkey PRIMARY KEY (id)`
- `CONSTRAINT settings_outlets_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id)`

---

### `settings_transaction_series` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `org_id`: `uuid` | NOT NULL
- `name`: `character varying` | NOT NULL
- `modules`: `jsonb` | NOT NULL DEFAULT '[]'::jsonb
- `created_at`: `timestamp without time zone` | DEFAULT now()
- `updated_at`: `timestamp without time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT settings_transaction_series_pkey PRIMARY KEY (id)`

---

### `shipment_preferences` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `name`: `character varying` | NOT NULL UNIQUE
- `is_active`: `boolean` | DEFAULT true
- `created_at`: `timestamp with time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT shipment_preferences_pkey PRIMARY KEY (id)`

---

### `states` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `state_id`: `uuid` | NOT NULL
- `name`: `character varying` | NOT NULL
- `code`: `character varying`
- `is_active`: `boolean` | DEFAULT true
- `created_at`: `timestamp without time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT states_pkey PRIMARY KEY (id)`
- `CONSTRAINT states_state_id_fkey FOREIGN KEY (state_id) REFERENCES public.countries(id)`

---

### `storage_locations` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `location_name`: `character varying` | NOT NULL UNIQUE
- `temperature_range`: `character varying`
- `description`: `text`
- `is_active`: `boolean` | DEFAULT true
- `created_at`: `timestamp without time zone` | DEFAULT now()
- `display_text`: `character varying`
- `common_examples`: `text`
- `min_temp_c`: `numeric`
- `max_temp_c`: `numeric`
- `is_cold_chain`: `boolean` | NOT NULL DEFAULT false
- `requires_fridge`: `boolean` | NOT NULL DEFAULT false
- `sort_order`: `integer` | NOT NULL DEFAULT 0
- `storage_type`: `character varying`

**Table-level constraints / FKs**
- `CONSTRAINT storage_locations_pkey PRIMARY KEY (id)`

---

### `strengths` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `strength_name`: `character varying` | NOT NULL UNIQUE
- `is_active`: `boolean` | DEFAULT true
- `created_at`: `timestamp without time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT strengths_pkey PRIMARY KEY (id)`

---

### `tax_group_taxes` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `tax_group_id`: `uuid`
- `tax_id`: `uuid`
- `created_at`: `timestamp with time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT tax_group_taxes_pkey PRIMARY KEY (id)`
- `CONSTRAINT tax_group_taxes_tax_group_id_fkey FOREIGN KEY (tax_group_id) REFERENCES public.tax_groups(id)`
- `CONSTRAINT tax_group_taxes_tax_id_fkey FOREIGN KEY (tax_id) REFERENCES public.associate_taxes(id)`

---

### `tax_groups` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `tax_group_name`: `character varying` | NOT NULL UNIQUE
- `tax_rate`: `numeric` | NOT NULL
- `is_active`: `boolean` | DEFAULT true
- `created_at`: `timestamp with time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT tax_groups_pkey PRIMARY KEY (id)`

---

### `tds_group_items` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `tds_group_id`: `uuid`
- `tds_rate_id`: `uuid`
- `created_at`: `timestamp without time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT tds_group_items_pkey PRIMARY KEY (id)`
- `CONSTRAINT tds_group_items_tds_group_id_fkey FOREIGN KEY (tds_group_id) REFERENCES public.tds_groups(id)`
- `CONSTRAINT tds_group_items_tds_rate_id_fkey FOREIGN KEY (tds_rate_id) REFERENCES public.tds_rates(id)`

---

### `tds_groups` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `group_name`: `character varying` | NOT NULL UNIQUE
- `applicable_from`: `timestamp without time zone`
- `applicable_to`: `timestamp without time zone`
- `is_active`: `boolean` | DEFAULT true
- `created_at`: `timestamp without time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT tds_groups_pkey PRIMARY KEY (id)`

---

### `tds_rates` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `tax_name`: `character varying` | NOT NULL UNIQUE
- `section_id`: `uuid`
- `base_rate`: `numeric` | NOT NULL
- `surcharge_rate`: `numeric` | DEFAULT 0.00
- `cess_rate`: `numeric` | DEFAULT 0.00
- `payable_account_id`: `uuid`
- `receivable_account_id`: `uuid`
- `is_higher_rate`: `boolean` | DEFAULT false
- `reason_higher_rate`: `text`
- `applicable_from`: `timestamp without time zone`
- `applicable_to`: `timestamp without time zone`
- `is_active`: `boolean` | DEFAULT true
- `created_at`: `timestamp without time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT tds_rates_pkey PRIMARY KEY (id)`
- `CONSTRAINT tds_rates_section_id_fkey FOREIGN KEY (section_id) REFERENCES public.tds_sections(id)`
- `CONSTRAINT tds_rates_payable_account_id_fkey FOREIGN KEY (payable_account_id) REFERENCES public.accounts(id)`
- `CONSTRAINT tds_rates_receivable_account_id_fkey FOREIGN KEY (receivable_account_id) REFERENCES public.accounts(id)`

---

### `tds_sections` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `section_name`: `character varying` | NOT NULL UNIQUE
- `description`: `text`
- `is_active`: `boolean` | DEFAULT true
- `created_at`: `timestamp without time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT tds_sections_pkey PRIMARY KEY (id)`

---

### `timezones` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `name`: `character varying` | NOT NULL UNIQUE
- `tzdb_name`: `character varying` | NOT NULL
- `utc_offset`: `character varying` | NOT NULL
- `display`: `character varying` | NOT NULL
- `country_id`: `uuid`
- `is_active`: `boolean` | NOT NULL DEFAULT true
- `sort_order`: `smallint` | NOT NULL DEFAULT 0

**Table-level constraints / FKs**
- `CONSTRAINT timezones_pkey PRIMARY KEY (id)`
- `CONSTRAINT timezones_country_id_fkey FOREIGN KEY (country_id) REFERENCES public.countries(id)`

---

### `transaction_locks` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `org_id`: `uuid` | NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid
- `module_name`: `character varying` | NOT NULL
- `lock_date`: `timestamp without time zone` | NOT NULL
- `reason`: `text`
- `updated_at`: `timestamp without time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT transaction_locks_pkey PRIMARY KEY (id)`

---

### `transactional_sequences` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `module`: `character varying` | NOT NULL
- `prefix`: `character varying` | NOT NULL DEFAULT ''::character varying
- `next_number`: `integer` | NOT NULL DEFAULT 1
- `padding`: `integer` | NOT NULL DEFAULT 6
- `is_active`: `boolean` | DEFAULT true
- `updated_at`: `timestamp with time zone` | DEFAULT now()
- `suffix`: `character varying` | DEFAULT ''::character varying
- `outlet_id`: `uuid`
- `is_auto`: `boolean` | DEFAULT true

**Table-level constraints / FKs**
- `CONSTRAINT transactional_sequences_pkey PRIMARY KEY (id)`

---

### `units` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `unit_name`: `character varying` | NOT NULL UNIQUE
- `unit_type`: `USER-DEFINED`
- `is_active`: `boolean` | DEFAULT true
- `created_at`: `timestamp without time zone` | DEFAULT now()
- `unit_symbol`: `character varying`
- `uqc_id`: `uuid`

**Table-level constraints / FKs**
- `CONSTRAINT units_pkey PRIMARY KEY (id)`
- `CONSTRAINT units_uqc_id_fkey FOREIGN KEY (uqc_id) REFERENCES public.uqc(id)`

---

### `uqc` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `uqc_code`: `character varying` | NOT NULL UNIQUE
- `description`: `character varying` | NOT NULL
- `is_active`: `boolean` | DEFAULT true
- `created_at`: `timestamp without time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT uqc_pkey PRIMARY KEY (id)`

---

### `vendor_bank_accounts` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `vendor_id`: `uuid`
- `holder_name`: `text`
- `bank_name`: `text`
- `account_number`: `text`
- `ifsc`: `text`
- `is_primary`: `boolean` | DEFAULT false
- `created_at`: `timestamp with time zone` | DEFAULT now()
- `updated_at`: `timestamp with time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT vendor_bank_accounts_pkey PRIMARY KEY (id)`
- `CONSTRAINT vendor_bank_accounts_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.vendors(id)`

---

### `vendor_contact_persons` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `vendor_id`: `uuid`
- `salutation`: `text`
- `first_name`: `text`
- `last_name`: `text`
- `email`: `text`
- `work_phone`: `text`
- `mobile_phone`: `text`
- `designation`: `text`
- `department`: `text`
- `is_primary`: `boolean` | DEFAULT false
- `created_at`: `timestamp with time zone` | DEFAULT now()
- `updated_at`: `timestamp with time zone` | DEFAULT now()

**Table-level constraints / FKs**
- `CONSTRAINT vendor_contact_persons_pkey PRIMARY KEY (id)`
- `CONSTRAINT vendor_contact_persons_vendor_id_fkey FOREIGN KEY (vendor_id) REFERENCES public.vendors(id)`

---

### `vendors` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `org_id`: `uuid` | NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid
- `outlet_id`: `uuid`
- `vendor_number`: `character varying` | UNIQUE
- `display_name`: `character varying` | NOT NULL
- `salutation`: `character varying`
- `first_name`: `character varying`
- `last_name`: `character varying`
- `company_name`: `character varying`
- `email`: `character varying`
- `phone`: `character varying`
- `mobile_phone`: `character varying`
- `designation`: `character varying`
- `department`: `character varying`
- `website`: `character varying`
- `vendor_language`: `character varying` | DEFAULT 'English'::character varying
- `gst_treatment`: `character varying`
- `gstin`: `character varying`
- `source_of_supply`: `character varying`
- `pan`: `character varying`
- `currency`: `character varying` | DEFAULT 'INR'::character varying
- `payment_terms`: `character varying`
- `is_msme_registered`: `boolean` | DEFAULT false
- `msme_registration_type`: `character varying`
- `msme_registration_number`: `character varying`
- `is_drug_registered`: `boolean` | DEFAULT false
- `drug_licence_type`: `character varying`
- `drug_license_20`: `character varying`
- `drug_license_21`: `character varying`
- `drug_license_20b`: `character varying`
- `drug_license_21b`: `character varying`
- `is_fssai_registered`: `boolean` | DEFAULT false
- `fssai_number`: `character varying`
- `tds_rate_id`: `character varying`
- `enable_portal`: `boolean` | DEFAULT false
- `remarks`: `text`
- `x_handle`: `character varying`
- `facebook_handle`: `character varying`
- `whatsapp_number`: `character varying`
- `source`: `character varying` | DEFAULT 'User'::character varying
- `is_active`: `boolean` | DEFAULT true
- `created_at`: `timestamp with time zone` | DEFAULT now()
- `updated_at`: `timestamp with time zone` | DEFAULT now()
- `billing_attention`: `text`
- `billing_address_street_1`: `text`
- `billing_address_street_2`: `text`
- `billing_city`: `text`
- `billing_state`: `text`
- `billing_pincode`: `text`
- `billing_country_region`: `text`
- `billing_phone`: `text`
- `billing_fax`: `text`
- `shipping_attention`: `text`
- `shipping_address_street_1`: `text`
- `shipping_address_street_2`: `text`
- `shipping_city`: `text`
- `shipping_state`: `text`
- `shipping_pincode`: `text`
- `shipping_country_region`: `text`
- `shipping_phone`: `text`
- `shipping_fax`: `text`
- `price_list_id`: `uuid`

**Table-level constraints / FKs**
- `CONSTRAINT vendors_pkey PRIMARY KEY (id)`

---

### `warehouses` - Full Column Inventory

- `id`: `uuid` | NOT NULL DEFAULT gen_random_uuid()
- `org_id`: `uuid`
- `name`: `character varying` | NOT NULL
- `attention`: `text`
- `address_street_1`: `text`
- `address_street_2`: `text`
- `city`: `text`
- `state`: `text`
- `zip_code`: `character varying`
- `country_region`: `text` | NOT NULL
- `phone`: `character varying`
- `email`: `character varying`
- `is_active`: `boolean` | DEFAULT true
- `created_at`: `timestamp without time zone` | DEFAULT now()
- `updated_at`: `timestamp without time zone` | DEFAULT now()
- `outlet_id`: `uuid`

**Table-level constraints / FKs**
- `CONSTRAINT warehouses_pkey PRIMARY KEY (id)`
- `CONSTRAINT warehouses_org_id_fkey FOREIGN KEY (org_id) REFERENCES public.organization(id)`

---

*Generated from the live DDL in `current schema.txt` on 2026-03-24.*


