## Table `account_transactions`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `account_id` | `uuid` |  |
| `transaction_date` | `timestamp` |  |
| `transaction_type` | `varchar` |  Nullable |
| `reference_number` | `varchar` |  Nullable |
| `description` | `text` |  Nullable |
| `debit` | `numeric` |  Nullable |
| `credit` | `numeric` |  Nullable |
| `created_at` | `timestamp` |  Nullable |
| `source_id` | `uuid` |  Nullable |
| `source_type` | `varchar` |  Nullable |
| `contact_id` | `uuid` |  Nullable |
| `contact_type` | `varchar` |  Nullable |
| `entity_id` | `uuid` |  |
| `org_id` | `uuid` |  |

## Table `accounts`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `system_account_name` | `varchar` |  Nullable Unique |
| `account_code` | `varchar` |  Nullable Unique |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamp` |  Nullable |
| `parent_id` | `uuid` |  Nullable |
| `account_group` | `account_group_enum` |  |
| `is_system` | `bool` |  Nullable |
| `account_type` | `account_type_enum` |  |
| `description` | `text` |  Nullable |
| `account_number` | `varchar` |  Nullable |
| `ifsc` | `varchar` |  Nullable |
| `currency` | `varchar` |  Nullable |
| `show_in_zerpai_expense` | `bool` |  Nullable |
| `add_to_watchlist` | `bool` |  Nullable |
| `is_deletable` | `bool` |  Nullable |
| `user_account_name` | `varchar` |  Nullable |
| `created_by` | `uuid` |  Nullable |
| `is_deleted` | `bool` |  Nullable |
| `modified_at` | `timestamptz` |  Nullable |
| `modified_by` | `uuid` |  Nullable |
| `entity_id` | `uuid` |  |
| `org_id` | `uuid` |  |

## Table `assemblies_constituencies`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `district_id` | `uuid` |  |
| `code` | `varchar` |  Nullable |
| `name` | `varchar` |  |
| `is_active` | `bool` |  |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |

## Table `audit_logs`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `table_name` | `varchar` |  |
| `record_id` | `uuid` |  |
| `action` | `varchar` |  |
| `old_values` | `jsonb` |  Nullable |
| `new_values` | `jsonb` |  Nullable |
| `user_id` | `uuid` |  |
| `created_at` | `timestamptz` |  Nullable |
| `org_id` | `uuid` |  |
| `actor_name` | `text` |  |
| `schema_name` | `text` |  |
| `record_pk` | `text` |  Nullable |
| `changed_columns` | `_text` |  Nullable |
| `txid` | `int8` |  |
| `source` | `text` |  |
| `module_name` | `text` |  Nullable |
| `request_id` | `text` |  Nullable |
| `entity_id` | `uuid` |  |

## Table `audit_logs_archive`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `table_name` | `varchar` |  |
| `record_id` | `uuid` |  |
| `action` | `varchar` |  |
| `old_values` | `jsonb` |  Nullable |
| `new_values` | `jsonb` |  Nullable |
| `user_id` | `uuid` |  |
| `created_at` | `timestamptz` |  Nullable |
| `org_id` | `uuid` |  |
| `actor_name` | `text` |  |
| `schema_name` | `text` |  |
| `record_pk` | `text` |  Nullable |
| `changed_columns` | `_text` |  Nullable |
| `txid` | `int8` |  |
| `source` | `text` |  |
| `module_name` | `text` |  Nullable |
| `request_id` | `text` |  Nullable |
| `archived_at` | `timestamptz` |  |
| `entity_id` | `uuid` |  |

## Table `backup_inventory_adjustment_reasons_20260518`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` |  Nullable |
| `entity_id` | `uuid` |  Nullable |
| `name` | `varchar` |  Nullable |
| `code` | `varchar` |  Nullable |
| `reason_type` | `varchar` |  Nullable |
| `is_active` | `bool` |  Nullable |
| `sort_order` | `int4` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |

## Table `batch_master`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `product_id` | `uuid` |  Nullable |
| `batch_no` | `varchar` |  Unique |
| `expiry_date` | `date` |  |
| `unit_pack` | `varchar` |  Nullable |
| `is_manufacture_details` | `bool` |  Nullable |
| `manufacture_batch_number` | `varchar` |  Nullable |
| `manufacture_exp` | `date` |  Nullable |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |
| `created_by_entity_id` | `uuid` |  Nullable |
| `source_type` | `varchar` |  Nullable |

## Table `batch_stock_layers`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `batch_id` | `uuid` |  |
| `product_id` | `uuid` |  |
| `entity_id` | `uuid` |  |
| `warehouse_id` | `uuid` |  |
| `bin_id` | `uuid` |  |
| `vendor_id` | `uuid` |  Nullable |
| `purchase_rate` | `numeric` |  |
| `mrp` | `numeric` |  |
| `qty` | `numeric` |  |
| `foc_qty` | `numeric` |  Nullable |
| `ref_id` | `uuid` |  Nullable |
| `ref_type` | `varchar` |  |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |
| `reserved_qty` | `numeric` |  |

## Table `batch_transactions`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `batch_id` | `uuid` |  |
| `layer_id` | `uuid` |  Nullable |
| `product_id` | `uuid` |  |
| `entity_id` | `uuid` |  |
| `warehouse_id` | `uuid` |  |
| `bin_id` | `uuid` |  Nullable |
| `trans_type` | `varchar` |  |
| `ref_id` | `uuid` |  Nullable |
| `ref_no` | `varchar` |  Nullable |
| `qty_in` | `numeric` |  Nullable |
| `qty_out` | `numeric` |  Nullable |
| `rate` | `numeric` |  Nullable |
| `trans_date` | `timestamptz` |  |
| `created_at` | `timestamptz` |  Nullable |

## Table `bin_master`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `entity_id` | `uuid` |  |
| `warehouse_id` | `uuid` |  |
| `zone_id` | `uuid` |  |
| `bin_code` | `varchar` |  |
| `level_path` | `text` |  Nullable |
| `bin_type` | `varchar` |  Nullable |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `branch_price_list_assignments`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `price_list_id` | `uuid` |  |
| `branch_entity_id` | `uuid` |  |
| `created_at` | `timestamptz` |  Nullable |

## Table `branch_transaction_series`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `transaction_series_id` | `uuid` |  |
| `created_at` | `timestamptz` |  |
| `entity_id` | `uuid` |  |

## Table `branch_user_access`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `user_id` | `uuid` |  |
| `role_id` | `uuid` |  Nullable |
| `is_default_branch` | `bool` |  Nullable |
| `permissions` | `jsonb` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  |
| `entity_id` | `uuid` |  |

## Table `branch_users`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `user_id` | `uuid` |  |
| `role` | `varchar` |  Nullable |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |
| `entity_id` | `uuid` |  |

## Table `branches`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `org_id` | `uuid` |  |
| `name` | `varchar` |  |
| `branch_code` | `varchar` |  |
| `branch_type` | `varchar` |  Nullable |
| `email` | `varchar` |  Nullable |
| `phone` | `varchar` |  Nullable |
| `website` | `varchar` |  Nullable |
| `attention` | `text` |  Nullable |
| `street` | `text` |  Nullable |
| `place` | `text` |  Nullable |
| `city` | `varchar` |  Nullable |
| `state` | `varchar` |  Nullable |
| `pincode` | `varchar` |  Nullable |
| `country` | `varchar` |  |
| `gstin` | `varchar` |  Nullable |
| `gstin_registration_type` | `varchar` |  Nullable |
| `logo_url` | `text` |  Nullable |
| `subscription_from` | `date` |  Nullable |
| `subscription_to` | `date` |  Nullable |
| `is_active` | `bool` |  |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |
| `is_child_location` | `bool` |  |
| `parent_branch_id` | `uuid` |  Nullable |
| `primary_contact_id` | `uuid` |  Nullable |
| `gstin_legal_name` | `varchar` |  Nullable |
| `gstin_trade_name` | `varchar` |  Nullable |
| `gstin_registered_on` | `date` |  Nullable |
| `gstin_reverse_charge` | `bool` |  |
| `gstin_import_export` | `bool` |  |
| `gstin_import_export_account_id` | `uuid` |  Nullable |
| `gstin_digital_services` | `bool` |  |
| `default_transaction_series_id` | `uuid` |  Nullable |
| `district_id` | `uuid` |  Nullable |
| `local_body_id` | `uuid` |  Nullable |
| `ward_id` | `uuid` |  Nullable |
| `system_id` | `varchar` |  |
| `pan` | `varchar` |  Nullable |
| `industry` | `varchar` |  Nullable |
| `gst_treatment` | `varchar` |  Nullable |
| `is_drug_registered` | `bool` |  |
| `drug_licence_type` | `varchar` |  Nullable |
| `drug_licence_20` | `varchar` |  Nullable |
| `drug_licence_21` | `varchar` |  Nullable |
| `drug_licence_20b` | `varchar` |  Nullable |
| `drug_licence_21b` | `varchar` |  Nullable |
| `is_fssai_registered` | `bool` |  |
| `fssai_number` | `varchar` |  Nullable |
| `is_msme_registered` | `bool` |  |
| `msme_registration_type` | `varchar` |  Nullable |
| `msme_number` | `varchar` |  Nullable |
| `msme_type` | `varchar` |  Nullable |
| `fiscal_year` | `varchar` |  Nullable |
| `report_basis` | `varchar` |  Nullable |
| `has_separate_payment_stub_address` | `bool` |  |
| `payment_stub_address` | `text` |  Nullable |
| `payment_stub_assembly_id` | `uuid` |  Nullable |
| `assembly_id` | `uuid` |  Nullable |

## Table `branding`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `accent_color` | `varchar` |  |
| `theme_mode` | `varchar` |  |
| `keep_branding` | `bool` |  |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |
| `entity_id` | `uuid` |  |

## Table `brands`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `name` | `varchar` |  Unique |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamp` |  Nullable |

## Table `business_types`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `code` | `varchar` |  Unique |
| `label` | `varchar` |  |
| `description` | `text` |  |
| `sort_order` | `int4` |  |
| `is_active` | `bool` |  |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |

## Table `buying_rules`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `buying_rule` | `varchar` |  Unique |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamp` |  Nullable |
| `rule_description` | `text` |  Nullable |
| `system_behavior` | `text` |  Nullable |
| `associated_schedule_codes` | `_text` |  |
| `requires_rx` | `bool` |  |
| `requires_patient_info` | `bool` |  |
| `is_saleable` | `bool` |  |
| `log_to_special_register` | `bool` |  |
| `requires_doctor_name` | `bool` |  |
| `requires_prescription_date` | `bool` |  |
| `requires_age_check` | `bool` |  |
| `institutional_only` | `bool` |  |
| `blocks_retail_sale` | `bool` |  |
| `quantity_limit` | `int4` |  Nullable |
| `allows_refill` | `bool` |  |
| `sort_order` | `int4` |  |

## Table `carrier`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `name` | `varchar` |  Unique |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `categories`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `name` | `varchar` |  Unique |
| `description` | `text` |  Nullable |
| `parent_id` | `uuid` |  Nullable |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamp` |  Nullable |

## Table `company_id_labels`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `label` | `varchar` |  Unique |
| `is_active` | `bool` |  |
| `sort_order` | `int2` |  |

## Table `composite_item_branch_inventory_settings`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `entity_id` | `uuid` |  |
| `org_id` | `uuid` |  |
| `composite_item_id` | `uuid` |  |
| `reorder_point` | `int4` |  |
| `reorder_term_id` | `uuid` |  Nullable |
| `is_active` | `bool` |  |
| `created_by_id` | `uuid` |  Nullable |
| `updated_by_id` | `uuid` |  Nullable |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |

## Table `composite_item_parts`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `composite_item_id` | `uuid` |  |
| `component_product_id` | `uuid` |  |
| `quantity` | `numeric` |  |
| `selling_price_override` | `numeric` |  Nullable |
| `cost_price_override` | `numeric` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `composite_items`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `type` | `composite_type` |  |
| `product_name` | `varchar` |  |
| `sku` | `varchar` |  Nullable Unique |
| `unit_id` | `uuid` |  |
| `category_id` | `uuid` |  Nullable |
| `is_returnable` | `bool` |  Nullable |
| `push_to_ecommerce` | `bool` |  Nullable |
| `hsn_code` | `varchar` |  Nullable |
| `tax_preference` | `tax_preference` |  Nullable |
| `intra_state_tax_id` | `uuid` |  Nullable |
| `inter_state_tax_id` | `uuid` |  Nullable |
| `primary_image_url` | `text` |  Nullable |
| `image_urls` | `text` |  Nullable |
| `selling_price` | `numeric` |  Nullable |
| `selling_price_currency` | `varchar` |  Nullable |
| `ptr` | `numeric` |  Nullable |
| `sales_account_id` | `uuid` |  Nullable |
| `sales_description` | `text` |  Nullable |
| `cost_price` | `numeric` |  Nullable |
| `purchase_account_id` | `uuid` |  Nullable |
| `preferred_vendor_id` | `uuid` |  Nullable |
| `purchase_description` | `text` |  Nullable |
| `length` | `numeric` |  Nullable |
| `width` | `numeric` |  Nullable |
| `height` | `numeric` |  Nullable |
| `dimension_unit` | `varchar` |  Nullable |
| `weight` | `numeric` |  Nullable |
| `weight_unit` | `varchar` |  Nullable |
| `manufacturer_id` | `uuid` |  Nullable |
| `brand_id` | `uuid` |  Nullable |
| `mpn` | `varchar` |  Nullable |
| `upc` | `varchar` |  Nullable |
| `isbn` | `varchar` |  Nullable |
| `ean` | `varchar` |  Nullable |
| `is_track_inventory` | `bool` |  Nullable |
| `track_batches` | `bool` |  Nullable |
| `track_serial_number` | `bool` |  Nullable |
| `inventory_account_id` | `uuid` |  Nullable |
| `inventory_valuation_method` | `inventory_valuation_method` |  Nullable |
| `reorder_point` | `int4` |  Nullable |
| `reorder_term_id` | `uuid` |  Nullable |
| `is_active` | `bool` |  Nullable |
| `is_lock` | `bool` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `created_by_id` | `uuid` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |
| `updated_by_id` | `uuid` |  Nullable |

## Table `contents`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `content_name` | `varchar` |  Unique |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamp` |  Nullable |

## Table `countries`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `name` | `varchar` |  Unique |
| `full_label` | `varchar` |  Nullable |
| `phone_code` | `varchar` |  |
| `short_code` | `varchar` |  Nullable |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamp` |  Nullable |
| `primary_timezone_id` | `uuid` |  Nullable |

## Table `credit_note_item_batches`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `credit_note_item_id` | `uuid` |  |
| `batch_id` | `uuid` |  |
| `layer_id` | `uuid` |  Nullable |
| `warehouse_id` | `uuid` |  Nullable |
| `bin_id` | `uuid` |  Nullable |
| `quantity` | `numeric` |  |
| `rate` | `numeric` |  Nullable |
| `mrp` | `numeric` |  Nullable |
| `ref_type` | `varchar` |  Nullable |
| `ref_id` | `uuid` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `credit_note_items`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `credit_note_id` | `uuid` |  |
| `product_id` | `uuid` |  |
| `invoice_item_id` | `uuid` |  Nullable |
| `sales_return_item_id` | `uuid` |  Nullable |
| `account_id` | `uuid` |  Nullable |
| `description` | `text` |  Nullable |
| `quantity` | `numeric` |  |
| `rate` | `numeric` |  |
| `discount_type` | `varchar` |  Nullable |
| `discount_value` | `numeric` |  Nullable |
| `discount_amount` | `numeric` |  Nullable |
| `tax_id` | `uuid` |  Nullable |
| `tax_percentage` | `numeric` |  Nullable |
| `tax_amount` | `numeric` |  Nullable |
| `taxable_amount` | `numeric` |  Nullable |
| `line_total` | `numeric` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |

## Table `credit_notes`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `entity_id` | `uuid` |  |
| `customer_id` | `uuid` |  |
| `credit_note_number` | `varchar` |  Unique |
| `reference_number` | `varchar` |  Nullable |
| `credit_note_date` | `date` |  |
| `reason` | `varchar` |  Nullable |
| `salesperson_id` | `uuid` |  Nullable |
| `warehouse_id` | `uuid` |  Nullable |
| `price_list_id` | `uuid` |  Nullable |
| `subject` | `text` |  Nullable |
| `customer_notes` | `text` |  Nullable |
| `terms_conditions` | `text` |  Nullable |
| `subtotal` | `numeric` |  Nullable |
| `discount_total` | `numeric` |  Nullable |
| `tax_total` | `numeric` |  Nullable |
| `shipping_charges` | `numeric` |  Nullable |
| `tds_total` | `numeric` |  Nullable |
| `tcs_total` | `numeric` |  Nullable |
| `adjustment_amount` | `numeric` |  Nullable |
| `round_off` | `numeric` |  Nullable |
| `grand_total` | `numeric` |  Nullable |
| `source_type` | `varchar` |  Nullable |
| `source_id` | `uuid` |  Nullable |
| `status` | `varchar` |  |
| `created_by` | `uuid` |  Nullable |
| `approved_by` | `uuid` |  Nullable |
| `approved_at` | `timestamptz` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |

## Table `currencies`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `code` | `varchar` |  Unique |
| `name` | `varchar` |  |
| `symbol` | `varchar` |  Nullable |
| `decimals` | `int4` |  Nullable |
| `format` | `varchar` |  Nullable |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamp` |  Nullable |

## Table `customer_contact_persons`

Alternative contact persons for customers

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `customer_id` | `uuid` |  |
| `salutation` | `varchar` |  Nullable |
| `first_name` | `varchar` |  Nullable |
| `last_name` | `varchar` |  Nullable |
| `email` | `varchar` |  Nullable |
| `work_phone` | `varchar` |  Nullable |
| `mobile_phone` | `varchar` |  Nullable |
| `display_order` | `int4` |  Nullable |
| `created_at` | `timestamp` |  Nullable |
| `updated_at` | `timestamp` |  Nullable |
| `entity_id` | `uuid` |  |

## Table `customers`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `display_name` | `varchar` |  |
| `customer_type` | `varchar` |  Nullable |
| `salutation` | `varchar` |  Nullable |
| `first_name` | `varchar` |  Nullable |
| `last_name` | `varchar` |  Nullable |
| `company_name` | `varchar` |  Nullable |
| `email` | `varchar` |  Nullable |
| `phone` | `varchar` |  Nullable |
| `mobile_phone` | `varchar` |  Nullable |
| `gstin` | `varchar` |  Nullable |
| `pan` | `varchar` |  Nullable |
| `payment_terms` | `varchar` |  Nullable |
| `billing_address` | `text` |  Nullable |
| `shipping_address` | `text` |  Nullable |
| `is_active` | `bool` |  Nullable |
| `receivables` | `numeric` |  Nullable |
| `created_at` | `timestamp` |  Nullable |
| `customer_number` | `varchar` |  Nullable Unique |
| `designation` | `varchar` |  Nullable |
| `department` | `varchar` |  Nullable |
| `business_type` | `varchar` |  Nullable |
| `customer_language` | `varchar` |  Nullable |
| `date_of_birth` | `date` |  Nullable |
| `age` | `int4` |  Nullable |
| `gender` | `varchar` |  Nullable |
| `place_of_customer` | `varchar` |  Nullable |
| `privilege_card_number` | `varchar` |  Nullable |
| `parent_customer_id` | `uuid` |  Nullable |
| `tax_preference` | `varchar` |  Nullable |
| `exemption_reason` | `text` |  Nullable |
| `drug_licence_type` | `varchar` |  Nullable |
| `drug_license_20` | `varchar` |  Nullable |
| `drug_license_21` | `varchar` |  Nullable |
| `drug_license_20b` | `varchar` |  Nullable |
| `drug_license_21b` | `varchar` |  Nullable |
| `fssai` | `varchar` |  Nullable |
| `msme_registration_type` | `varchar` |  Nullable |
| `msme_number` | `varchar` |  Nullable |
| `drug_license_20_doc_url` | `text` |  Nullable |
| `drug_license_21_doc_url` | `text` |  Nullable |
| `drug_license_20b_doc_url` | `text` |  Nullable |
| `drug_license_21b_doc_url` | `text` |  Nullable |
| `fssai_doc_url` | `text` |  Nullable |
| `msme_doc_url` | `text` |  Nullable |
| `opening_balance` | `numeric` |  Nullable |
| `credit_limit` | `numeric` |  Nullable |
| `enable_portal` | `bool` |  Nullable |
| `facebook_handle` | `varchar` |  Nullable |
| `twitter_handle` | `varchar` |  Nullable |
| `whatsapp_number` | `varchar` |  Nullable |
| `is_recurring` | `bool` |  Nullable |
| `gst_treatment` | `varchar` |  Nullable |
| `place_of_supply` | `varchar` |  Nullable |
| `website` | `varchar` |  Nullable |
| `price_list_id` | `uuid` |  Nullable |
| `receivable_balance` | `numeric` |  Nullable |
| `billing_address_street` | `varchar` |  Nullable |
| `billing_address_place` | `varchar` |  Nullable |
| `billing_address_city` | `varchar` |  Nullable |
| `billing_address_zip` | `varchar` |  Nullable |
| `billing_address_phone` | `varchar` |  Nullable |
| `shipping_address_street` | `varchar` |  Nullable |
| `shipping_address_place` | `varchar` |  Nullable |
| `shipping_address_city` | `varchar` |  Nullable |
| `shipping_address_zip` | `varchar` |  Nullable |
| `shipping_address_phone` | `varchar` |  Nullable |
| `remarks` | `text` |  Nullable |
| `status` | `varchar` |  Nullable |
| `document_urls` | `text` |  Nullable |
| `is_drug_registered` | `bool` |  Nullable |
| `is_fssai_registered` | `bool` |  Nullable |
| `is_msme_registered` | `bool` |  Nullable |
| `currency_id` | `uuid` |  Nullable |
| `billing_address_state_id` | `uuid` |  Nullable |
| `shipping_address_state_id` | `uuid` |  Nullable |
| `billing_address_country_id` | `uuid` |  Nullable |
| `shipping_address_country_id` | `uuid` |  Nullable |
| `entity_id` | `uuid` |  |
| `associated_branch_id` | `uuid` |  Nullable |

## Table `date_format`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `code` | `varchar` |  Unique |
| `format_pattern` | `varchar` |  |
| `group_name` | `varchar` |  |
| `label` | `varchar` |  |
| `sort_order` | `int4` |  |
| `is_active` | `bool` |  |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |

## Table `date_separator`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `code` | `varchar` |  Unique |
| `separator` | `varchar` |  |
| `label` | `varchar` |  |
| `sort_order` | `int4` |  |
| `is_active` | `bool` |  |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |

## Table `drug_licence_types`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `code` | `varchar` |  Unique |
| `label` | `varchar` |  |
| `sort_order` | `int4` |  |
| `is_active` | `bool` |  |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |

## Table `drug_schedules`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `shedule_name` | `varchar` |  Unique |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamp` |  Nullable |
| `schedule_code` | `varchar` |  Nullable |
| `reference_description` | `text` |  Nullable |
| `requires_prescription` | `bool` |  |
| `requires_h1_register` | `bool` |  |
| `is_narcotic` | `bool` |  |
| `requires_batch_tracking` | `bool` |  |
| `sort_order` | `int4` |  |
| `is_common` | `bool` |  |

## Table `drug_strengths`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `strength_name` | `varchar` |  Unique |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamp` |  Nullable |

## Table `fiscal_year_presets`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `code` | `varchar` |  Unique |
| `label` | `varchar` |  |
| `start_month` | `int2` |  |
| `end_month` | `int2` |  |
| `sort_order` | `int4` |  |
| `is_active` | `bool` |  |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |

## Table `fiscal_years`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `org_id` | `uuid` |  |
| `name` | `varchar` |  |
| `start_date` | `date` |  |
| `end_date` | `date` |  |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamp` |  Nullable |
| `entity_id` | `uuid` |  |

## Table `gst_treatments`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `code` | `varchar` |  Unique |
| `label` | `varchar` |  |
| `sort_order` | `int4` |  |
| `is_active` | `bool` |  |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |

## Table `gstin_registration_types`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `code` | `varchar` |  Unique |
| `label` | `varchar` |  |
| `sort_order` | `int4` |  |
| `is_active` | `bool` |  |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |

## Table `hsn_sac_codes`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `type` | `hsn_sac_type` |  |
| `code` | `varchar` |  Unique |
| `description` | `text` |  |

## Table `industries`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `name` | `varchar` |  Unique |
| `is_active` | `bool` |  |
| `sort_order` | `int2` |  |

## Table `inventory_adjustment_account_entries`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `adjustment_id` | `uuid` |  |
| `entity_id` | `uuid` |  |
| `account_id` | `uuid` |  |
| `debit` | `numeric` |  |
| `credit` | `numeric` |  |
| `description` | `text` |  Nullable |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |

## Table `inventory_adjustment_attachments`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `entity_id` | `uuid` |  |
| `adjustment_id` | `uuid` |  |
| `file_name` | `text` |  |
| `file_url` | `text` |  Nullable |
| `storage_bucket` | `text` |  Nullable |
| `storage_path` | `text` |  Nullable |
| `mime_type` | `text` |  Nullable |
| `file_size_bytes` | `int8` |  Nullable |
| `file_hash` | `text` |  Nullable |
| `uploaded_by` | `uuid` |  Nullable |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |

## Table `inventory_adjustment_item_batches`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `adjustment_id` | `uuid` |  |
| `adjustment_item_id` | `uuid` |  |
| `entity_id` | `uuid` |  |
| `product_id` | `uuid` |  |
| `warehouse_id` | `uuid` |  Nullable |
| `bin_id` | `uuid` |  Nullable |
| `batch_id` | `uuid` |  Nullable |
| `batch_reference` | `varchar` |  Nullable |
| `quantity_in` | `numeric` |  |
| `quantity_out` | `numeric` |  |
| `rate` | `numeric` |  Nullable |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |
| `batch_stock_layer_id` | `uuid` |  Nullable |

## Table `inventory_adjustment_items`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `adjustment_id` | `uuid` |  |
| `entity_id` | `uuid` |  |
| `product_id` | `uuid` |  |
| `quantity_before` | `numeric` |  |
| `quantity_adjusted` | `numeric` |  |
| `quantity_after` | `numeric` |  |
| `cost_price` | `numeric` |  Nullable |
| `mrp` | `numeric` |  Nullable |
| `adjustment_value` | `numeric` |  |
| `batch_id` | `uuid` |  Nullable |
| `batch_reference` | `varchar` |  Nullable |
| `batch_allocations` | `jsonb` |  |
| `reporting_tags` | `jsonb` |  |
| `mfd_month_year` | `varchar` |  Nullable |
| `expiry_month_year` | `varchar` |  Nullable |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |

## Table `inventory_adjustment_reasons`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `entity_id` | `uuid` |  Nullable |
| `name` | `varchar` |  |
| `code` | `varchar` |  Nullable |
| `reason_type` | `varchar` |  Nullable |
| `is_active` | `bool` |  |
| `sort_order` | `int4` |  |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |

## Table `inventory_adjustment_value_items`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `adjustment_id` | `uuid` |  |
| `entity_id` | `uuid` |  |
| `product_id` | `uuid` |  |
| `batch_id` | `uuid` |  Nullable |
| `batch_stock_layer_id` | `uuid` |  Nullable |
| `current_value` | `numeric` |  |
| `changed_value` | `numeric` |  |
| `adjusted_value` | `numeric` |  |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |

## Table `inventory_adjustments`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `entity_id` | `uuid` |  |
| `product_id` | `uuid` |  Nullable |
| `warehouse_id` | `uuid` |  Nullable |
| `adjustment_number` | `varchar` |  Nullable Unique |
| `adjustment_date` | `timestamptz` |  |
| `adjustment_type` | `inventory_adjustment_type` |  |
| `reason_id` | `uuid` |  Nullable |
| `reason` | `varchar` |  Nullable |
| `reference_number` | `varchar` |  Nullable |
| `notes` | `text` |  Nullable |
| `account_id` | `uuid` |  Nullable |
| `status` | `inventory_adjustment_status` |  |
| `quantity_before` | `numeric` |  Nullable |
| `quantity_adjusted` | `numeric` |  Nullable |
| `quantity_after` | `numeric` |  Nullable |
| `cost_price` | `numeric` |  Nullable |
| `adjustment_value` | `numeric` |  Nullable |
| `adjusted_by` | `uuid` |  Nullable |
| `approved_by` | `uuid` |  Nullable |
| `approved_at` | `timestamptz` |  Nullable |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |

## Table `inventory_move_order_destination_bins`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `source_batch_row_id` | `uuid` |  |
| `destination_bin_id` | `uuid` |  |
| `qty_in` | `numeric` |  |
| `created_at` | `timestamp` |  Nullable |

## Table `inventory_move_order_items`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `move_order_id` | `uuid` |  |
| `product_id` | `uuid` |  |
| `qty` | `numeric` |  |
| `remarks` | `text` |  Nullable |
| `created_at` | `timestamp` |  Nullable |

## Table `inventory_move_order_source_batches`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `move_order_item_id` | `uuid` |  |
| `source_layer_id` | `uuid` |  |
| `batch_id` | `uuid` |  |
| `source_bin_id` | `uuid` |  |
| `qty_out` | `numeric` |  |
| `created_at` | `timestamp` |  Nullable |

## Table `inventory_move_orders`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `entity_id` | `uuid` |  |
| `warehouse_id` | `uuid` |  |
| `move_order_number` | `varchar` |  Unique |
| `move_date` | `timestamp` |  |
| `assignee_id` | `uuid` |  Nullable |
| `notes` | `text` |  Nullable |
| `status` | `varchar` |  |
| `created_by` | `uuid` |  Nullable |
| `completed_by` | `uuid` |  Nullable |
| `completed_at` | `timestamp` |  Nullable |
| `created_at` | `timestamp` |  Nullable |
| `updated_at` | `timestamp` |  Nullable |

## Table `inventory_package_items`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `package_id` | `uuid` |  |
| `entity_id` | `uuid` |  |
| `product_id` | `uuid` |  |
| `quantity` | `numeric` |  |
| `sales_order_id` | `uuid` |  Nullable |
| `picklist_id` | `uuid` |  Nullable |
| `batch_no` | `varchar` |  Nullable |
| `bin_location` | `varchar` |  Nullable |
| `foc` | `int2` |  Nullable |

## Table `inventory_package_sales_orders`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `package_id` | `uuid` | Primary |
| `sales_order_id` | `uuid` | Primary |
| `entity_id` | `uuid` |  |

## Table `inventory_packages`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `entity_id` | `uuid` |  |
| `customer_id` | `uuid` |  |
| `package_number` | `varchar` |  Unique |
| `package_date` | `date` |  |
| `dimension_length` | `numeric` |  Nullable |
| `dimension_width` | `numeric` |  Nullable |
| `dimension_height` | `numeric` |  Nullable |
| `dimension_unit` | `varchar` |  Nullable |
| `weight` | `numeric` |  Nullable |
| `weight_unit` | `varchar` |  Nullable |
| `is_manual_mode` | `bool` |  Nullable |
| `notes` | `text` |  Nullable |
| `status` | `varchar` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |
| `created_by` | `uuid` |  Nullable |
| `is_delete` | `bool` |  |

## Table `inventory_shipment_packages`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `shipment_id` | `uuid` | Primary |
| `package_id` | `uuid` | Primary |

## Table `inventory_shipment_sales_orders`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `shipment_id` | `uuid` | Primary |
| `sales_order_id` | `uuid` | Primary |

## Table `inventory_shipments`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `entity_id` | `uuid` |  |
| `shipment_number` | `varchar` |  Unique |
| `customer_id` | `uuid` |  Nullable |
| `date` | `date` |  |
| `delivered_date` | `timestamp` |  Nullable |
| `carrier` | `varchar` |  Nullable |
| `tracking_number` | `varchar` |  Nullable |
| `tracking_url` | `text` |  Nullable |
| `shipping_charges` | `numeric` |  |
| `notes` | `text` |  Nullable |
| `is_delivered` | `bool` |  |
| `send_notification` | `bool` |  |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |
| `is_delete` | `bool` |  |

## Table `inventory_stock_commitments`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `entity_id` | `uuid` |  |
| `warehouse_id` | `uuid` |  Nullable |
| `product_id` | `uuid` |  |
| `source_type` | `varchar` |  |
| `source_id` | `uuid` |  |
| `committed_qty` | `numeric` |  |
| `status` | `varchar` |  |
| `created_at` | `timestamptz` |  Nullable |

## Table `invoice_attachments`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `invoice_id` | `uuid` |  |
| `file_name` | `varchar` |  Nullable |
| `file_path` | `text` |  Nullable |
| `uploaded_by` | `uuid` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `invoice_item_batches`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `invoice_item_id` | `uuid` |  |
| `batch_id` | `uuid` |  |
| `layer_id` | `uuid` |  Nullable |
| `warehouse_id` | `uuid` |  |
| `bin_id` | `uuid` |  Nullable |
| `quantity` | `numeric` |  |
| `foc_quantity` | `numeric` |  Nullable |
| `purchase_rate` | `numeric` |  Nullable |
| `sales_rate` | `numeric` |  Nullable |
| `mrp` | `numeric` |  Nullable |
| `expiry_date` | `date` |  Nullable |
| `manufacturer_batch` | `varchar` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `invoice_items`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `invoice_id` | `uuid` |  |
| `product_id` | `uuid` |  |
| `description` | `text` |  Nullable |
| `quantity` | `numeric` |  |
| `rate` | `numeric` |  |
| `discount_type` | `varchar` |  Nullable |
| `discount_value` | `numeric` |  Nullable |
| `tax_id` | `uuid` |  Nullable |
| `tax_percentage` | `numeric` |  Nullable |
| `taxable_amount` | `numeric` |  Nullable |
| `tax_amount` | `numeric` |  Nullable |
| `line_total` | `numeric` |  Nullable |
| `foc_quantity` | `numeric` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |

## Table `invoice_master`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `entity_id` | `uuid` |  |
| `customer_id` | `uuid` |  |
| `warehouse_id` | `uuid` |  Nullable |
| `invoice_number` | `varchar` |  |
| `invoice_date` | `date` |  |
| `due_date` | `date` |  Nullable |
| `payment_terms` | `varchar` |  Nullable |
| `salesperson_id` | `uuid` |  Nullable |
| `subject` | `text` |  Nullable |
| `customer_notes` | `text` |  Nullable |
| `terms_conditions` | `text` |  Nullable |
| `price_list_id` | `uuid` |  Nullable |
| `shipping_charges` | `numeric` |  Nullable |
| `adjustment_amount` | `numeric` |  Nullable |
| `round_off` | `numeric` |  Nullable |
| `subtotal` | `numeric` |  Nullable |
| `tax_total` | `numeric` |  Nullable |
| `tds_total` | `numeric` |  Nullable |
| `tcs_total` | `numeric` |  Nullable |
| `grand_total` | `numeric` |  Nullable |
| `inventory_flow_type` | `varchar` |  Nullable |
| `status` | `varchar` |  Nullable |
| `is_batch_allocated` | `bool` |  Nullable |
| `created_by` | `uuid` |  Nullable |
| `approved_by` | `uuid` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |

## Table `invoice_sales_orders`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `invoice_id` | `uuid` |  |
| `sales_order_id` | `uuid` |  |

## Table `invoice_shipments`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `invoice_id` | `uuid` |  |
| `shipment_id` | `uuid` |  |

## Table `journal_number_settings`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `auto_generate` | `bool` |  Nullable |
| `prefix` | `varchar` |  Nullable |
| `next_number` | `int4` |  Nullable |
| `is_manual_override_allowed` | `bool` |  Nullable |
| `user_id` | `uuid` |  Nullable |
| `entity_id` | `uuid` |  |

## Table `journal_template_items`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `template_id` | `uuid` |  |
| `account_id` | `uuid` |  |
| `description` | `text` |  Nullable |
| `contact_id` | `uuid` |  Nullable |
| `contact_type` | `accounts_contact_type` |  Nullable |
| `type` | `accounts_journal_template_type` |  Nullable |
| `debit` | `numeric` |  Nullable |
| `credit` | `numeric` |  Nullable |
| `sort_order` | `int4` |  Nullable |
| `entity_id` | `uuid` |  |

## Table `journal_templates`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `template_name` | `varchar` |  |
| `reference_number` | `varchar` |  Nullable |
| `notes` | `text` |  Nullable |
| `reporting_method` | `accounts_reporting_method` |  Nullable |
| `currency_code` | `varchar` |  Nullable |
| `is_active` | `bool` |  Nullable |
| `enter_amount` | `bool` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |
| `entity_id` | `uuid` |  |

## Table `lsgd_districts`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `state_id` | `uuid` |  |
| `name` | `varchar` |  |
| `code` | `varchar` |  Nullable |
| `is_active` | `bool` |  |
| `created_at` | `timestamp` |  Nullable |
| `updated_at` | `timestamp` |  Nullable |

## Table `lsgd_local_bodies`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `district_id` | `uuid` |  |
| `name` | `varchar` |  |
| `code` | `varchar` |  Nullable |
| `body_type` | `varchar` |  |
| `is_active` | `bool` |  |
| `created_at` | `timestamp` |  Nullable |
| `updated_at` | `timestamp` |  Nullable |

## Table `lsgd_wards`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `local_body_id` | `uuid` |  |
| `ward_no` | `int4` |  Nullable |
| `name` | `varchar` |  |
| `code` | `varchar` |  Nullable |
| `is_active` | `bool` |  |
| `created_at` | `timestamp` |  Nullable |
| `updated_at` | `timestamp` |  Nullable |

## Table `manual_journal_attachments`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `manual_journal_id` | `uuid` |  |
| `file_name` | `varchar` |  |
| `file_path` | `text` |  |
| `file_size` | `int4` |  Nullable |
| `uploaded_at` | `timestamp` |  Nullable |
| `entity_id` | `uuid` |  |

## Table `manual_journal_items`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `manual_journal_id` | `uuid` |  |
| `account_id` | `uuid` |  |
| `description` | `text` |  Nullable |
| `contact_id` | `uuid` |  Nullable |
| `contact_type` | `accounts_contact_type` |  Nullable |
| `debit` | `numeric` |  Nullable |
| `credit` | `numeric` |  Nullable |
| `sort_order` | `int4` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |
| `contact_name` | `varchar` |  Nullable |
| `entity_id` | `uuid` |  |

## Table `manual_journal_tag_mappings`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `manual_journal_item_id` | `uuid` | Primary |
| `reporting_tag_id` | `uuid` | Primary |

## Table `manual_journals`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `journal_number` | `varchar` |  Unique |
| `fiscal_year_id` | `uuid` |  Nullable |
| `reference_number` | `varchar` |  Nullable |
| `journal_date` | `date` |  Nullable |
| `notes` | `text` |  Nullable |
| `is_13th_month_adjustment` | `bool` |  Nullable |
| `reporting_method` | `accounts_reporting_method` |  Nullable |
| `currency_code` | `varchar` |  Nullable |
| `status` | `accounts_manual_journal_status` |  Nullable |
| `total_amount` | `numeric` |  Nullable |
| `created_by` | `uuid` |  Nullable |
| `created_at` | `timestamp` |  Nullable |
| `recurring_journal_id` | `uuid` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |
| `is_deleted` | `bool` |  |
| `entity_id` | `uuid` |  |

## Table `manufacturers`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `name` | `varchar` |  Unique |
| `contact_info` | `jsonb` |  Nullable |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamp` |  Nullable |

## Table `move_order_attachments`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `move_order_id` | `uuid` |  |
| `file_name` | `varchar` |  |
| `original_file_name` | `varchar` |  Nullable |
| `file_url` | `text` |  |
| `file_size` | `int8` |  Nullable |
| `file_type` | `varchar` |  Nullable |
| `uploaded_by` | `uuid` |  Nullable |
| `uploaded_at` | `timestamptz` |  Nullable |

## Table `organisation_branch_master`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `name` | `varchar` |  |
| `type` | `varchar` |  |
| `ref_id` | `uuid` |  Unique |
| `parent_id` | `uuid` |  Nullable |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `organization`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `name` | `varchar` |  |
| `slug` | `varchar` |  Unique |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamp` |  Nullable |
| `updated_at` | `timestamp` |  Nullable |
| `state_id` | `uuid` |  Nullable |
| `industry` | `varchar` |  Nullable |
| `logo_url` | `text` |  Nullable |
| `base_currency` | `varchar` |  Nullable |
| `fiscal_year` | `varchar` |  Nullable |
| `timezone` | `varchar` |  Nullable |
| `date_format` | `varchar` |  Nullable |
| `date_separator` | `varchar` |  Nullable |
| `company_id_label` | `varchar` |  Nullable |
| `company_id_value` | `varchar` |  Nullable |
| `payment_stub_address` | `text` |  Nullable |
| `has_separate_payment_stub_address` | `bool` |  |
| `system_id` | `varchar` |  |
| `base_currency_decimals` | `int2` |  Nullable |
| `base_currency_format` | `varchar` |  Nullable |
| `organization_language` | `varchar` |  Nullable |
| `communication_languages` | `_text` |  |
| `payment_stub_district_id` | `uuid` |  Nullable |
| `payment_stub_local_body_id` | `uuid` |  Nullable |
| `payment_stub_ward_id` | `uuid` |  Nullable |
| `is_drug_registered` | `bool` |  |
| `drug_licence_type` | `varchar` |  Nullable |
| `drug_license_20` | `varchar` |  Nullable |
| `drug_license_21` | `varchar` |  Nullable |
| `drug_license_20b` | `varchar` |  Nullable |
| `drug_license_21b` | `varchar` |  Nullable |
| `is_fssai_registered` | `bool` |  |
| `fssai_number` | `varchar` |  Nullable |
| `is_msme_registered` | `bool` |  |
| `msme_registration_type` | `varchar` |  Nullable |
| `msme_number` | `varchar` |  Nullable |
| `payment_stub_assembly_id` | `uuid` |  Nullable |
| `attention` | `text` |  Nullable |
| `street` | `text` |  Nullable |
| `place` | `text` |  Nullable |
| `city` | `varchar` |  Nullable |
| `pincode` | `varchar` |  Nullable |
| `phone` | `varchar` |  Nullable |
| `district_id` | `uuid` |  Nullable |
| `local_body_id` | `uuid` |  Nullable |
| `assembly_id` | `uuid` |  Nullable |
| `ward_id` | `uuid` |  Nullable |
| `report_basis` | `varchar` |  Nullable |
| `drug_license_20_url` | `text` |  Nullable |
| `drug_license_21_url` | `text` |  Nullable |
| `drug_license_20b_url` | `text` |  Nullable |
| `drug_license_21b_url` | `text` |  Nullable |
| `fssai_url` | `text` |  Nullable |
| `msme_url` | `text` |  Nullable |
| `additional_fields` | `jsonb` |  Nullable |

## Table `payment_terms`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `term_name` | `varchar` |  Unique |
| `number_of_days` | `int4` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamp` |  Nullable |

## Table `picklist_batch_allocation`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `picklist_item_id` | `uuid` |  |
| `batch_id` | `uuid` |  |
| `layer_id` | `varchar` |  |
| `warehouse_id` | `uuid` |  |
| `bin_id` | `uuid` |  |
| `qty` | `numeric` |  |
| `foc_qty` | `numeric` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `picklist_items`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `picklist_id` | `uuid` |  |
| `product_id` | `uuid` |  |
| `sales_order_id` | `uuid` |  Nullable |
| `sales_order_line_id` | `uuid` |  Nullable |
| `qty_ordered` | `numeric` |  Nullable |
| `qty_to_pick` | `numeric` |  Nullable |
| `qty_picked` | `numeric` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `status` | `text` |  Nullable |

## Table `picklist_master`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `picklist_no` | `varchar` |  Unique |
| `entity_id` | `uuid` |  |
| `warehouse_id` | `uuid` |  |
| `assignee_id` | `uuid` |  Nullable |
| `picklist_date` | `date` |  |
| `status` | `text` |  Nullable |
| `notes` | `text` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `is_delete` | `bool` |  |
| `is_entrypass` | `bool` |  |

## Table `price_list_items`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `price_list_id` | `uuid` |  |
| `product_id` | `uuid` |  |
| `custom_rate` | `numeric` |  Nullable |
| `discount_percentage` | `numeric` |  Nullable |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |

## Table `price_list_volume_ranges`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `price_list_item_id` | `uuid` |  |
| `start_quantity` | `numeric` |  |
| `end_quantity` | `numeric` |  Nullable |
| `rate` | `numeric` |  |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |

## Table `price_lists`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `name` | `varchar` |  |
| `description` | `text` |  Nullable |
| `currency` | `varchar` |  Nullable |
| `pricing_scheme` | `varchar` |  |
| `details` | `text` |  Nullable |
| `round_off_preference` | `varchar` |  Nullable |
| `status` | `varchar` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |
| `price_list_type` | `varchar` |  Nullable |
| `percentage_type` | `varchar` |  Nullable |
| `percentage_value` | `numeric` |  Nullable |
| `discount_enabled` | `bool` |  Nullable |
| `transaction_type` | `varchar` |  Nullable |
| `entity_id` | `uuid` |  Nullable |
| `created_by_entity_id` | `uuid` |  Nullable |
| `price_scope` | `varchar` |  |
| `is_seasonal` | `bool` |  |
| `valid_from` | `date` |  Nullable |
| `valid_to` | `date` |  Nullable |

## Table `product_bin_mappings`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `product_id` | `uuid` |  |
| `entity_id` | `uuid` |  |
| `warehouse_id` | `uuid` |  |
| `bin_id` | `uuid` |  |
| `is_default` | `bool` |  Nullable |
| `is_active` | `bool` |  Nullable |
| `min_qty` | `int4` |  Nullable |
| `max_qty` | `int4` |  Nullable |
| `created_at` | `timestamp` |  Nullable |
| `created_by_id` | `uuid` |  Nullable |
| `updated_at` | `timestamp` |  Nullable |
| `updated_by_id` | `uuid` |  Nullable |

## Table `product_branch_inventory_settings`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `entity_id` | `uuid` |  |
| `org_id` | `uuid` |  |
| `product_id` | `uuid` |  |
| `reorder_point` | `int4` |  |
| `reorder_term_id` | `uuid` |  Nullable |
| `is_active` | `bool` |  |
| `created_by_id` | `uuid` |  Nullable |
| `updated_by_id` | `uuid` |  Nullable |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |

## Table `product_contents`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `product_id` | `uuid` |  |
| `content_id` | `uuid` |  Nullable |
| `strength_id` | `uuid` |  Nullable |
| `shedule_id` | `uuid` |  Nullable |
| `display_order` | `int4` |  Nullable |
| `created_at` | `timestamp` |  Nullable |

## Table `product_entity_settings`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `product_id` | `uuid` |  |
| `entity_id` | `uuid` |  |
| `sku` | `varchar` |  Nullable |
| `reorder_point` | `int4` |  Nullable |
| `reorder_term_id` | `uuid` |  Nullable |
| `inventory_valuation_method` | `inventory_valuation_method` |  Nullable |
| `preferred_vendor_id` | `uuid` |  Nullable |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamp` |  Nullable |
| `created_by_id` | `uuid` |  Nullable |
| `updated_at` | `timestamp` |  Nullable |
| `updated_by_id` | `uuid` |  Nullable |

## Table `product_vendor_mappings`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `vendor_id` | `uuid` |  |
| `item_id` | `uuid` |  |
| `mapping_name` | `varchar` |  |
| `vendor_product_code` | `varchar` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |

## Table `products`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `type` | `product_type` |  |
| `product_name` | `varchar` |  |
| `billing_name` | `varchar` |  Nullable |
| `item_code` | `varchar` |  Unique |
| `unit_id` | `uuid` |  |
| `category_id` | `uuid` |  Nullable |
| `is_returnable` | `bool` |  Nullable |
| `push_to_ecommerce` | `bool` |  Nullable |
| `hsn_code` | `varchar` |  Nullable |
| `tax_preference` | `tax_preference` |  Nullable |
| `intra_state_tax_id` | `uuid` |  Nullable |
| `inter_state_tax_id` | `uuid` |  Nullable |
| `primary_image_url` | `text` |  Nullable |
| `image_urls` | `jsonb` |  Nullable |
| `selling_price` | `numeric` |  Nullable |
| `selling_price_currency` | `varchar` |  Nullable |
| `mrp` | `numeric` |  Nullable |
| `ptr` | `numeric` |  Nullable |
| `sales_account_id` | `uuid` |  Nullable |
| `sales_description` | `text` |  Nullable |
| `cost_price` | `numeric` |  Nullable |
| `cost_price_currency` | `varchar` |  Nullable |
| `purchase_account_id` | `uuid` |  Nullable |
| `purchase_description` | `text` |  Nullable |
| `length` | `numeric` |  Nullable |
| `width` | `numeric` |  Nullable |
| `height` | `numeric` |  Nullable |
| `dimension_unit` | `varchar` |  Nullable |
| `weight` | `numeric` |  Nullable |
| `weight_unit` | `varchar` |  Nullable |
| `manufacturer_id` | `uuid` |  Nullable |
| `brand_id` | `uuid` |  Nullable |
| `mpn` | `varchar` |  Nullable |
| `upc` | `varchar` |  Nullable |
| `isbn` | `varchar` |  Nullable |
| `ean` | `varchar` |  Nullable |
| `track_assoc_ingredients` | `bool` |  Nullable |
| `buying_rule_old` | `varchar` |  Nullable |
| `schedule_of_drug_old` | `varchar` |  Nullable |
| `is_track_inventory` | `bool` |  Nullable |
| `track_bin_location` | `bool` |  Nullable |
| `track_batches` | `bool` |  Nullable |
| `inventory_account_id` | `uuid` |  Nullable |
| `storage_id` | `uuid` |  Nullable |
| `is_active` | `bool` |  Nullable |
| `is_lock` | `bool` |  Nullable |
| `created_at` | `timestamp` |  Nullable |
| `created_by_id` | `uuid` |  Nullable |
| `updated_at` | `timestamp` |  Nullable |
| `updated_by_id` | `uuid` |  Nullable |
| `track_serial_number` | `bool` |  Nullable |
| `buying_rule_id` | `uuid` |  Nullable |
| `schedule_of_drug_id` | `uuid` |  Nullable |
| `lock_unit_pack` | `numeric` |  Nullable |
| `storage_description` | `text` |  Nullable |
| `about` | `text` |  Nullable |
| `uses_description` | `text` |  Nullable |
| `how_to_use` | `text` |  Nullable |
| `dosage_description` | `text` |  Nullable |
| `missed_dose_description` | `text` |  Nullable |
| `safety_advice` | `text` |  Nullable |
| `side_effects` | `jsonb` |  Nullable |
| `faq_text` | `jsonb` |  Nullable |
| `preferred_vendor_id` | `uuid` |  Nullable |
| `sku` | `varchar` |  Nullable Unique |
| `exemption_reason` | `varchar` |  Nullable |
| `inventory_valuation_method` | `varchar` |  Nullable |
| `rack_id` | `uuid` |  Nullable |
| `reorder_point` | `int4` |  Nullable |
| `reorder_term_id` | `uuid` |  Nullable |

## Table `purchase_order_attachments`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `purchase_order_id` | `uuid` |  |
| `file_name` | `varchar` |  |
| `file_path` | `text` |  |
| `file_size` | `varchar` |  Nullable |
| `file_type` | `varchar` |  Nullable |
| `uploaded_at` | `timestamptz` |  Nullable |

## Table `purchase_order_items`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `purchase_order_id` | `uuid` |  |
| `sort_order` | `int4` |  Nullable |
| `is_header` | `bool` |  Nullable |
| `header_text` | `text` |  Nullable |
| `product_id` | `uuid` |  Nullable |
| `description` | `text` |  Nullable |
| `account_id` | `uuid` |  Nullable |
| `quantity` | `numeric` |  Nullable |
| `rate` | `numeric` |  Nullable |
| `tax_id` | `uuid` |  Nullable |
| `item_tax_rate` | `numeric` |  Nullable |
| `tax_amount` | `numeric` |  Nullable |
| `discount` | `numeric` |  Nullable |
| `discount_type` | `varchar` |  Nullable |
| `amount` | `numeric` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |
| `entity_id` | `uuid` |  Nullable |
| `accounts` | `uuid` |  Nullable |
| `pricelist` | `varchar` |  Nullable |
| `hsn_code` | `numeric` |  Nullable |

## Table `purchase_orders`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `order_number` | `varchar` |  Unique |
| `order_date` | `date` |  |
| `expected_delivery_date` | `date` |  Nullable |
| `reference_number` | `varchar` |  Nullable |
| `vendor_id` | `uuid` |  |
| `payment_terms_id` | `uuid` |  Nullable |
| `shipment_preference_id` | `uuid` |  Nullable |
| `delivery_type` | `varchar` |  |
| `delivery_warehouse_id` | `uuid` |  Nullable |
| `delivery_customer_id` | `uuid` |  Nullable |
| `warehouse_id` | `uuid` |  Nullable |
| `discount_level` | `varchar` |  Nullable |
| `discount` | `numeric` |  Nullable |
| `discount_type` | `varchar` |  Nullable |
| `total_quantity` | `numeric` |  Nullable |
| `currency` | `varchar` |  Nullable |
| `subtotal` | `numeric` |  Nullable |
| `tax_amount` | `numeric` |  Nullable |
| `tax_type` | `varchar` |  Nullable |
| `tds_tcs_type` | `varchar` |  Nullable |
| `tds_id` | `uuid` |  Nullable |
| `tds_tcs_amount` | `numeric` |  Nullable |
| `adjustment` | `numeric` |  Nullable |
| `total` | `numeric` |  Nullable |
| `status` | `varchar` |  Nullable |
| `notes` | `text` |  Nullable |
| `terms_and_conditions` | `text` |  Nullable |
| `is_reverse_charge` | `bool` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |
| `entity_id` | `uuid` |  |
| `is_delete` | `bool` |  |
| `discount_account_id` | `uuid` |  |

## Table `purchase_receive_item_batches`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `purchase_receive_item_id` | `uuid` |  |
| `product_id` | `uuid` |  |
| `warehouse_id` | `uuid` |  Nullable |
| `bin_id` | `uuid` |  Nullable |
| `bin_label` | `varchar` |  Nullable |
| `batch_no` | `varchar` |  |
| `unit_pack` | `varchar` |  Nullable |
| `mrp` | `numeric` |  Nullable |
| `ptr` | `numeric` |  Nullable |
| `quantity` | `numeric` |  |
| `foc_qty` | `numeric` |  |
| `manufacture_batch_number` | `varchar` |  Nullable |
| `manufacture_date` | `date` |  Nullable |
| `expiry_date` | `date` |  |
| `is_damaged` | `bool` |  |
| `damaged_qty` | `numeric` |  |
| `entity_id` | `uuid` |  |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |

## Table `purchase_receive_items`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `purchase_receive_id` | `uuid` |  |
| `item_id` | `uuid` |  Nullable |
| `item_name` | `varchar` |  |
| `description` | `text` |  Nullable |
| `ordered` | `numeric` |  |
| `received` | `numeric` |  |
| `in_transit` | `numeric` |  |
| `quantity_to_receive` | `numeric` |  |
| `warehouse_id` | `uuid` |  Nullable |
| `bin_id` | `uuid` |  Nullable |
| `bin_label` | `varchar` |  Nullable |
| `entity_id` | `uuid` |  |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |

## Table `purchase_receives`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `purchase_receive_number` | `varchar` |  Unique |
| `received_date` | `date` |  |
| `vendor_name` | `varchar` |  Nullable |
| `purchase_order_id` | `uuid` |  Nullable |
| `purchase_order_number` | `varchar` |  Nullable |
| `warehouse_id` | `uuid` |  Nullable |
| `transaction_bin_id` | `uuid` |  Nullable |
| `transaction_bin_label` | `varchar` |  Nullable |
| `status` | `varchar` |  |
| `notes` | `text` |  Nullable |
| `entity_id` | `uuid` |  |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |
| `is_delete` | `bool` |  |
| `bill_no` | `varchar` |  Nullable |
| `bill_date` | `date` |  Nullable |
| `bill_invoice_total` | `numeric` |  Nullable |

## Table `racks`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `rack_code` | `varchar` |  Unique |
| `rack_name` | `varchar` |  Nullable |
| `storage_id` | `uuid` |  Nullable |
| `capacity` | `int4` |  Nullable |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamp` |  Nullable |

## Table `recurring_journal_items`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `recurring_journal_id` | `uuid` |  |
| `account_id` | `uuid` |  |
| `description` | `text` |  Nullable |
| `contact_id` | `uuid` |  Nullable |
| `contact_type` | `varchar` |  Nullable |
| `debit` | `numeric` |  Nullable |
| `credit` | `numeric` |  Nullable |
| `sort_order` | `int4` |  Nullable |
| `contact_name` | `varchar` |  Nullable |

## Table `recurring_journals`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `profile_name` | `varchar` |  |
| `repeat_every` | `varchar` |  |
| `interval` | `int4` |  |
| `start_date` | `date` |  |
| `end_date` | `date` |  Nullable |
| `never_expires` | `bool` |  Nullable |
| `reference_number` | `varchar` |  Nullable |
| `notes` | `text` |  Nullable |
| `currency_code` | `varchar` |  Nullable |
| `reporting_method` | `varchar` |  Nullable |
| `status` | `varchar` |  Nullable |
| `last_generated_date` | `timestamp` |  Nullable |
| `created_at` | `timestamp` |  Nullable |
| `updated_at` | `timestamp` |  Nullable |
| `created_by` | `uuid` |  Nullable |
| `entity_id` | `uuid` |  |

## Table `reorder_terms`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `term_name` | `varchar` |  |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamp` |  Nullable |
| `quantity` | `int4` |  |
| `updated_at` | `timestamptz` |  |
| `entity_id` | `uuid` |  |

## Table `reporting_tags`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `tag_name` | `varchar` |  |
| `is_active` | `bool` |  Nullable |
| `entity_id` | `uuid` |  |

## Table `roles`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `label` | `varchar` |  |
| `description` | `text` |  |
| `permissions` | `jsonb` |  |
| `is_active` | `bool` |  |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |
| `entity_id` | `uuid` |  |

## Table `sales_order_attachments`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `sales_order_id` | `uuid` |  |
| `file_name` | `varchar` |  |
| `file_path` | `text` |  |
| `file_size` | `varchar` |  Nullable |
| `file_type` | `varchar` |  Nullable |
| `source` | `varchar` |  Nullable |
| `uploaded_at` | `timestamp` |  Nullable |
| `entity_id` | `uuid` |  |

## Table `sales_order_items`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `sales_order_id` | `uuid` |  |
| `line_no` | `int4` |  |
| `product_id` | `uuid` |  |
| `description` | `text` |  Nullable |
| `quantity` | `numeric` |  |
| `free_quantity` | `numeric` |  |
| `rate` | `numeric` |  |
| `discount_type` | `varchar` |  Nullable |
| `discount_value` | `numeric` |  |
| `discount_amount` | `numeric` |  |
| `tax_id` | `uuid` |  Nullable |
| `tax_rate` | `numeric` |  |
| `tax_amount` | `numeric` |  |
| `amount` | `numeric` |  |
| `mrp` | `numeric` |  |
| `batch_id` | `uuid` |  Nullable |
| `warehouse_id` | `uuid` |  Nullable |
| `line_meta` | `jsonb` |  Nullable |
| `created_at` | `timestamp` |  Nullable |
| `updated_at` | `timestamp` |  Nullable |
| `entity_id` | `uuid` |  |
| `hsn_code` | `numeric` |  |
| `accounts` | `uuid` |  |
| `pricelist` | `varchar` |  Nullable |

## Table `sales_orders`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `customer_id` | `uuid` |  |
| `transaction_series` | `varchar` |  Nullable |
| `sale_number` | `varchar` |  Nullable Unique |
| `reference` | `varchar` |  Nullable |
| `sale_date` | `timestamp` |  Nullable |
| `expected_shipment_date` | `timestamp` |  Nullable |
| `delivery_method` | `varchar` |  Nullable |
| `payment_terms` | `varchar` |  Nullable |
| `payment_term_id` | `uuid` |  Nullable |
| `salesperson_id` | `varchar` |  Nullable |
| `salesperson_name` | `varchar` |  Nullable |
| `warehouse_id` | `uuid` |  Nullable |
| `warehouse_name` | `varchar` |  Nullable |
| `price_list_id` | `uuid` |  Nullable |
| `place_of_supply` | `varchar` |  Nullable |
| `document_type` | `varchar` |  |
| `status` | `varchar` |  Nullable |
| `sub_total` | `numeric` |  |
| `tax_total` | `numeric` |  |
| `discount_total` | `numeric` |  |
| `shipping_charges` | `numeric` |  |
| `tds_tcs_type` | `varchar` |  Nullable |
| `tds_tcs_tax_id` | `uuid` |  Nullable |
| `tds_tcs_amount` | `numeric` |  |
| `adjustment` | `numeric` |  |
| `round_off` | `numeric` |  |
| `total_quantity` | `numeric` |  |
| `total` | `numeric` |  |
| `currency` | `varchar` |  Nullable |
| `customer_notes` | `text` |  Nullable |
| `terms_and_conditions` | `text` |  Nullable |
| `created_at` | `timestamp` |  Nullable |
| `updated_at` | `timestamp` |  Nullable |
| `entity_id` | `uuid` |  |
| `is_delete` | `bool` |  |

## Table `sales_payment_links`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `customer_id` | `uuid` |  |
| `amount` | `numeric` |  |
| `link_url` | `text` |  |
| `status` | `varchar` |  Nullable |
| `created_at` | `timestamp` |  Nullable |
| `entity_id` | `uuid` |  |

## Table `sales_payments`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `customer_id` | `uuid` |  |
| `payment_number` | `varchar` |  Nullable Unique |
| `payment_date` | `timestamp` |  Nullable |
| `payment_mode` | `varchar` |  Nullable |
| `amount` | `numeric` |  |
| `bank_charges` | `numeric` |  Nullable |
| `reference` | `varchar` |  Nullable |
| `deposit_to` | `varchar` |  Nullable |
| `notes` | `text` |  Nullable |
| `created_at` | `timestamp` |  Nullable |
| `entity_id` | `uuid` |  |

## Table `sales_return_items`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `sales_return_id` | `uuid` |  |
| `product_id` | `uuid` |  |
| `sales_invoice_item_id` | `uuid` |  Nullable |
| `invoiced_qty` | `numeric` |  Nullable |
| `already_returned_qty` | `numeric` |  Nullable |
| `return_qty` | `numeric` |  Nullable |
| `receivable_qty` | `numeric` |  Nullable |
| `credit_only_qty` | `numeric` |  Nullable |
| `remarks` | `text` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |

## Table `sales_returns`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `entity_id` | `uuid` |  |
| `customer_id` | `uuid` |  |
| `rma_number` | `varchar` |  |
| `return_date` | `date` |  |
| `warehouse_id` | `uuid` |  Nullable |
| `reason` | `text` |  Nullable |
| `reference_number` | `varchar` |  Nullable |
| `contains_credit_only_goods` | `bool` |  |
| `status` | `varchar` |  |
| `notes` | `text` |  Nullable |
| `created_by` | `uuid` |  Nullable |
| `approved_by` | `uuid` |  Nullable |
| `approved_at` | `timestamptz` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |

## Table `states`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `state_id` | `uuid` |  |
| `name` | `varchar` |  |
| `code` | `varchar` |  Nullable |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamp` |  Nullable |

## Table `storage_conditions`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `location_name` | `varchar` |  Unique |
| `temperature_range` | `varchar` |  Nullable |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamp` |  Nullable |
| `display_text` | `varchar` |  Nullable |
| `common_examples` | `text` |  Nullable |
| `min_temp_c` | `numeric` |  Nullable |
| `max_temp_c` | `numeric` |  Nullable |
| `is_cold_chain` | `bool` |  |
| `requires_fridge` | `bool` |  |
| `sort_order` | `int4` |  |
| `storage_type` | `varchar` |  Nullable |

## Table `tax_group_rates`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `tax_group_id` | `uuid` |  Nullable |
| `tax_id` | `uuid` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `tax_groups`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `tax_group_name` | `varchar` |  Unique |
| `tax_rate` | `numeric` |  |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

## Table `tax_rates`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `tax_name` | `varchar` |  Unique |
| `tax_rate` | `numeric` |  |
| `tax_type` | `tax_type` |  Nullable |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamp` |  Nullable |

## Table `tds_group_items`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `tds_group_id` | `uuid` |  Nullable |
| `tds_rate_id` | `uuid` |  Nullable |
| `created_at` | `timestamp` |  Nullable |

## Table `tds_groups`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `group_name` | `varchar` |  Unique |
| `applicable_from` | `timestamp` |  Nullable |
| `applicable_to` | `timestamp` |  Nullable |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamp` |  Nullable |

## Table `tds_rates`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `tax_name` | `varchar` |  Unique |
| `section_id` | `uuid` |  Nullable |
| `base_rate` | `numeric` |  |
| `surcharge_rate` | `numeric` |  Nullable |
| `cess_rate` | `numeric` |  Nullable |
| `payable_account_id` | `uuid` |  Nullable |
| `receivable_account_id` | `uuid` |  Nullable |
| `is_higher_rate` | `bool` |  Nullable |
| `reason_higher_rate` | `text` |  Nullable |
| `applicable_from` | `timestamp` |  Nullable |
| `applicable_to` | `timestamp` |  Nullable |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamp` |  Nullable |

## Table `tds_sections`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `section_name` | `varchar` |  Unique |
| `description` | `text` |  Nullable |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamp` |  Nullable |

## Table `timezones`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `name` | `varchar` |  Unique |
| `tzdb_name` | `varchar` |  |
| `utc_offset` | `varchar` |  |
| `display` | `varchar` |  |
| `country_id` | `uuid` |  Nullable |
| `is_active` | `bool` |  |
| `sort_order` | `int2` |  |

## Table `transaction_locks`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `org_id` | `uuid` |  |
| `module_name` | `varchar` |  |
| `lock_date` | `timestamp` |  |
| `reason` | `text` |  Nullable |
| `updated_at` | `timestamp` |  Nullable |
| `entity_id` | `uuid` |  |

## Table `transaction_series`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `org_id` | `uuid` |  Nullable |
| `name` | `varchar` |  |
| `modules` | `jsonb` |  |
| `created_at` | `timestamp` |  Nullable |
| `updated_at` | `timestamp` |  Nullable |
| `code` | `varchar` |  Nullable |
| `branch_code` | `varchar` |  Nullable |
| `warehouse_code` | `varchar` |  Nullable |
| `entity_id` | `uuid` |  |

## Table `transaction_series_modules`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `code` | `varchar` |  Unique |
| `label` | `varchar` |  |
| `sort_order` | `int4` |  |
| `is_active` | `bool` |  |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |

## Table `transaction_series_placeholders`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `token` | `varchar` |  Unique |
| `label` | `varchar` |  |
| `sort_order` | `int4` |  |
| `is_active` | `bool` |  |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |

## Table `transaction_series_restart_options`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `code` | `varchar` |  Unique |
| `label` | `varchar` |  |
| `sort_order` | `int4` |  |
| `is_active` | `bool` |  |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |

## Table `transactional_sequences`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `module` | `varchar` |  |
| `prefix` | `varchar` |  |
| `suffix` | `varchar` |  Nullable |
| `next_number` | `int4` |  |
| `padding` | `int4` |  |
| `is_active` | `bool` |  |
| `entity_id` | `uuid` |  |
| `created_at` | `timestamp` |  Nullable |
| `updated_at` | `timestamp` |  Nullable |

## Table `transfer_order_destination_batches`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `transfer_item_id` | `uuid` |  |
| `source_batch_id` | `uuid` |  |
| `destination_batch_id` | `uuid` |  |
| `destination_warehouse_id` | `uuid` |  |
| `destination_bin_id` | `uuid` |  |
| `qty` | `numeric` |  |

## Table `transfer_order_items`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `transfer_order_id` | `uuid` |  |
| `product_id` | `uuid` |  |
| `qty_requested` | `numeric` |  |
| `qty_transferred` | `numeric` |  |
| `unit` | `varchar` |  Nullable |
| `created_at` | `timestamptz` |  |

## Table `transfer_order_logs`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `transfer_order_id` | `uuid` |  |
| `action` | `varchar` |  |
| `action_by` | `uuid` |  Nullable |
| `action_at` | `timestamptz` |  |

## Table `transfer_order_master`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `transfer_no` | `varchar` |  |
| `transfer_date` | `date` |  |
| `entity_id` | `uuid` |  |
| `source_warehouse_id` | `uuid` |  |
| `destination_warehouse_id` | `uuid` |  |
| `status` | `varchar` |  |
| `reason` | `text` |  Nullable |
| `created_by` | `uuid` |  Nullable |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |

## Table `transfer_order_source_batches`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `transfer_item_id` | `uuid` |  |
| `batch_id` | `uuid` |  |
| `layer_id` | `uuid` |  |
| `warehouse_id` | `uuid` |  |
| `bin_id` | `uuid` |  |
| `qty` | `numeric` |  |

## Table `units`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `unit_name` | `varchar` |  Unique |
| `unit_type` | `unit_type` |  Nullable |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamp` |  Nullable |
| `unit_symbol` | `varchar` |  Nullable |
| `uqc_id` | `uuid` |  Nullable |

## Table `uqc`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `uqc_code` | `varchar` |  Unique |
| `description` | `varchar` |  |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamp` |  Nullable |

## Table `user_branch_access`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `org_id` | `uuid` |  |
| `user_id` | `uuid` |  |
| `is_default_business` | `bool` |  |
| `is_default_warehouse` | `bool` |  |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |
| `entity_id` | `uuid` |  |

## Table `users`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `email` | `varchar` |  Unique |
| `full_name` | `varchar` |  |
| `role` | `varchar` |  |
| `is_active` | `bool` |  |
| `created_at` | `timestamptz` |  |
| `updated_at` | `timestamptz` |  |
| `entity_id` | `uuid` |  |
| `default_warehouse_id` | `uuid` |  Nullable |

## Table `vendor_bank_accounts`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `vendor_id` | `uuid` |  Nullable |
| `holder_name` | `text` |  Nullable |
| `bank_name` | `text` |  Nullable |
| `account_number` | `text` |  Nullable |
| `ifsc` | `text` |  Nullable |
| `is_primary` | `bool` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |

## Table `vendor_contact_persons`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `vendor_id` | `uuid` |  Nullable |
| `salutation` | `text` |  Nullable |
| `first_name` | `text` |  Nullable |
| `last_name` | `text` |  Nullable |
| `email` | `text` |  Nullable |
| `work_phone` | `text` |  Nullable |
| `mobile_phone` | `text` |  Nullable |
| `designation` | `text` |  Nullable |
| `department` | `text` |  Nullable |
| `is_primary` | `bool` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |

## Table `vendors`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `vendor_number` | `varchar` |  Nullable Unique |
| `display_name` | `varchar` |  |
| `salutation` | `varchar` |  Nullable |
| `first_name` | `varchar` |  Nullable |
| `last_name` | `varchar` |  Nullable |
| `company_name` | `varchar` |  Nullable |
| `email` | `varchar` |  Nullable |
| `phone` | `varchar` |  Nullable |
| `mobile_phone` | `varchar` |  Nullable |
| `designation` | `varchar` |  Nullable |
| `department` | `varchar` |  Nullable |
| `website` | `varchar` |  Nullable |
| `vendor_language` | `varchar` |  Nullable |
| `gst_treatment` | `varchar` |  Nullable |
| `gstin` | `varchar` |  Nullable |
| `source_of_supply` | `varchar` |  Nullable |
| `pan` | `varchar` |  Nullable |
| `currency` | `varchar` |  Nullable |
| `payment_terms` | `varchar` |  Nullable |
| `is_msme_registered` | `bool` |  Nullable |
| `msme_registration_type` | `varchar` |  Nullable |
| `msme_registration_number` | `varchar` |  Nullable |
| `is_drug_registered` | `bool` |  Nullable |
| `drug_licence_type` | `varchar` |  Nullable |
| `drug_license_20` | `varchar` |  Nullable |
| `drug_license_21` | `varchar` |  Nullable |
| `drug_license_20b` | `varchar` |  Nullable |
| `drug_license_21b` | `varchar` |  Nullable |
| `is_fssai_registered` | `bool` |  Nullable |
| `fssai_number` | `varchar` |  Nullable |
| `tds_rate_id` | `varchar` |  Nullable |
| `enable_portal` | `bool` |  Nullable |
| `remarks` | `text` |  Nullable |
| `x_handle` | `varchar` |  Nullable |
| `facebook_handle` | `varchar` |  Nullable |
| `whatsapp_number` | `varchar` |  Nullable |
| `source` | `varchar` |  Nullable |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |
| `updated_at` | `timestamptz` |  Nullable |
| `billing_attention` | `text` |  Nullable |
| `billing_address_street` | `text` |  Nullable |
| `billing_address_place` | `text` |  Nullable |
| `billing_city` | `text` |  Nullable |
| `billing_state` | `text` |  Nullable |
| `billing_pincode` | `text` |  Nullable |
| `billing_country_region` | `text` |  Nullable |
| `billing_phone` | `text` |  Nullable |
| `billing_fax` | `text` |  Nullable |
| `shipping_attention` | `text` |  Nullable |
| `shipping_address_street` | `text` |  Nullable |
| `shipping_address_place` | `text` |  Nullable |
| `shipping_city` | `text` |  Nullable |
| `shipping_state` | `text` |  Nullable |
| `shipping_pincode` | `text` |  Nullable |
| `shipping_country_region` | `text` |  Nullable |
| `shipping_phone` | `text` |  Nullable |
| `shipping_fax` | `text` |  Nullable |
| `price_list_id` | `uuid` |  Nullable |
| `entity_id` | `uuid` |  |

## Table `warehouses`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `name` | `varchar` |  |
| `attention` | `text` |  Nullable |
| `street` | `text` |  Nullable |
| `place` | `text` |  Nullable |
| `city` | `text` |  Nullable |
| `state` | `text` |  Nullable |
| `phone` | `varchar` |  Nullable |
| `email` | `varchar` |  Nullable |
| `is_active` | `bool` |  |
| `created_at` | `timestamp` |  |
| `updated_at` | `timestamp` |  |
| `warehouse_code` | `varchar` |  Nullable |
| `pincode` | `varchar` |  Nullable |
| `country` | `varchar` |  |
| `customer_id` | `uuid` |  Nullable |
| `vendor_id` | `uuid` |  Nullable |
| `district_id` | `uuid` |  Nullable |
| `local_body_id` | `uuid` |  Nullable |
| `ward_id` | `uuid` |  Nullable |
| `assembly_id` | `uuid` |  Nullable |
| `entity_id` | `uuid` |  |
| `org_id` | `uuid` |  |
| `source_branch_id` | `uuid` |  Nullable |
| `is_default_for_branch` | `bool` |  |

## Table `zone_levels`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `zone_id` | `uuid` |  |
| `level_no` | `int4` |  |
| `level_name` | `varchar` |  Nullable |
| `alias` | `varchar` |  Nullable |
| `delimiter` | `varchar` |  Nullable |
| `total` | `int4` |  |
| `created_at` | `timestamptz` |  Nullable |

## Table `zone_master`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `uuid` | Primary |
| `entity_id` | `uuid` |  |
| `warehouse_id` | `uuid` |  |
| `zone_name` | `varchar` |  |
| `is_active` | `bool` |  Nullable |
| `created_at` | `timestamptz` |  Nullable |

