# Price List Module

**Last Updated:** 2026-05-15 12:45:00 IST

---

## Overview

The Price List module is a core component of the Zerpai ERP inventory system, allowing for flexible and dynamic pricing strategies. It enables the creation of custom price lists that can be applied globally, to specific branches, or to individual customers.

## Key Features

### 1. Multi-Level Pricing
The system supports a hierarchical pricing resolution:
- **Branch-Specific Pricing:** Overrides global rates for a specific location.
- **Customer-Specific Pricing:** Tailored rates for specific clients (e.g., wholesale vs. retail).
- **Volume Pricing:** Discounts based on quantity breaks.

### 2. Markup and Markdown
Price lists can be defined as a percentage adjustment relative to the base product rate:
- **Markup:** Increase the price (e.g., +10%).
- **Markdown:** Decrease the price (e.g., -5% for seasonal sales).

### 3. Individual Item Overrides
Beyond percentage-based rules, specific items can be assigned fixed rates within a price list, providing granular control over profit margins.

## User Interface

### Price List Management
Accessed via **Items > Price Lists > Price List**.
- **Table View:** Displays all created price lists with their type (Markup/Markdown/Item-Based) and status.
- **Creation Form:** 
  - **Name:** Mandatory unique name.
  - **Type:** Percentage or Individual Items.
  - **Item Selector:** Add items and set their specific rates if using the "Individual Items" type.

### Branch Price List Assignment
Accessed via **Items > Price Lists > Branch Price List**.
- **Mapping Interface:** Select a branch and assign one or more price lists to it.
- **Scheduling:** Set effective start and end dates for the pricing to remain active.

## Technical Details

### Backend Persistence
The module uses three primary tables in the database:
- `inventory_price_lists`: Header information and type.
- `inventory_price_list_items`: Item-specific rates.
- `inventory_branch_price_list_mapping`: Branch-to-PriceList associations.

### Pricing Engine Logic
When a document (e.g., Sales Order) is created:
1. The system identifies the active branch and customer.
2. It queries the `inventory_branch_price_list_mapping` for an active branch-level list.
3. If none, it checks the customer's profile for an assigned list.
4. It then looks for the item's rate within the selected list's items or applies the percentage rule.
5. If no list is found, it uses the product's base rate.

---
