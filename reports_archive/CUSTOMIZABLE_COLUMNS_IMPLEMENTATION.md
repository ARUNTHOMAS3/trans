# 🎯 CUSTOMIZABLE COLUMNS FEATURE - IMPLEMENTATION PLAN

**Status:** IN PROGRESS  
**Date:** 2026-01-15

---

## ✅ COMPLETED SO FAR:

### 1. Updated ItemRow Model ✅
- Added ALL new fields (40+ fields total)
- Organized into logical groups
- File: `item_row.dart`

### 2. Updated _mapToRow Function ✅
- Maps all Item fields to ItemRow
- Includes lookups for all foreign keys:
  - Brand, Category, Manufacturer
  - Vendor, Storage Location
  - Sales Account, Purchase Account
  - Reorder Term, Buying Rule, Schedule of Drug
- Formats display values (Tax Preference, Type, etc.)
- File: `items_report_screen.dart`

### 3. Created Column Visibility Manager ✅
- Manages which columns are visible
- Persists to localStorage
- Provides column definitions with groups
- File: `column_visibility_manager.dart`

---

## 🚧 REMAINING TASKS:

### 4. Update Customize Columns Dialog
- Show ALL columns grouped by category
- Allow users to check/uncheck columns
- Save button persists to localStorage
- File to modify: `items_custom_columns.dart`

### 5. Update Items Table Component
- Dynamically show/hide columns based on visibility manager
- Adjust column widths dynamically
- File to modify: `items_table.dart`

### 6. Update Table Header
- Show only visible column headers
- File to modify: `items_table.dart` (ItemsTableer widget)

### 7. Wire Up State Management
- Integrate ColumnVisibilityManager with the report screen
- Update when columns change
- File to modify: `items_report_screen.dart`

---

## 📋 COLUMN LIST (40 columns total):

### Basic Information (11 columns):
1. ✅ Name (always visible)
2. ⭐ Billing Name
3. ⭐ Item Code
4. ⭐ Type
5. ⭐ Tax Preference
6. ✅ HSN/SAC
7. ✅ SKU
8. ✅ EAN
9. ✅ Brand
10. ✅ Category
11. ✅ Account Name

### Sales Information (5 columns):
12. ⭐ Selling Price
13. ⭐ MRP
14. ⭐ PTR
15. ⭐ Sales Account
16. ✅ Sales Description

### Purchase Information (4 columns):
17. ⭐ Cost Price
18. ⭐ Purchase Account
19. ⭐ Preferred Vendor
20. ⭐ Purchase Description

### Formulation (8 columns):
21. ⭐ Length
22. ⭐ Width
23. ⭐ Height
24. ⭐ Weight
25. ⭐ Manufacturer
26. ⭐ MPN
27. ⭐ UPC
28. ⭐ ISBN

### Inventory (5 columns):
29. ✅ Stock on Hand
30. ✅ Reorder Level
31. ⭐ Inventory Valuation Method
32. ⭐ Storage Location
33. ⭐ Reorder Term

### Composition (2 columns):
34. ⭐ Buying Rule
35. ⭐ Schedule of Drug

**Legend:**
- ✅ = Currently visible by default
- ⭐ = New column to add

---

## 🎨 UI DESIGN:

### Customize Columns Dialog:
```
┌─────────────────────────────────────┐
│  Customize Columns            [X]   │
├─────────────────────────────────────┤
│                                     │
│  Basic Information                  │
│  ☑ Name (required)                  │
│  ☐ Billing Name                     │
│  ☐ Item Code                        │
│  ☐ Type                             │
│  ☐ Tax Preference                   │
│  ☑ HSN/SAC                          │
│  ☑ SKU                              │
│  ☑ EAN                              │
│  ☑ Brand                            │
│  ☑ Category                         │
│                                     │
│  Sales Information                  │
│  ☐ Selling Price                    │
│  ☐ MRP                              │
│  ☐ PTR                              │
│  ☐ Sales Account                    │
│  ☑ Sales Description                │
│                                     │
│  [... more groups ...]              │
│                                     │
├─────────────────────────────────────┤
│         [Cancel]  [Reset]  [Save]   │
└─────────────────────────────────────┘
```

---

## 💾 DATA PERSISTENCE:

### localStorage Structure:
```json
{
  "items_report_visible_columns": [
    "name",
    "sku",
    "hsn",
    "category",
    "ean",
    "brand",
    "stockOnHand",
    "reorderLevel",
    "accountName",
    "description"
  ]
}
```

---

## 🔄 NEXT STEPS:

I'll continue with tasks 4-7 to complete the feature. This will involve:
1. Updating the dialog UI
2. Making the table dynamic
3. Wiring everything together

**Ready to continue?**
