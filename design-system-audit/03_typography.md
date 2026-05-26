# 🔡 Typography Audit

## Font Family
- **Primary Font**: `Inter`
- **Fallback Stack**: `NotoSansFallback`, `Segoe UI`, `Arial`, `sans-serif`.

## Typography Scale (AppTheme)

| Element | Size | Weight | Color Token | Usage |
| :--- | :--- | :--- | :--- | :--- |
| **Page Title** | 18px | 600 | `textBlack` | Screen headers (#000000). |
| **Section Header** | 15px | 600 | `textBlack` | Grouping headings (#000000). |
| **Table Header** | 13px | 600 | `textSecondary`| Data table column titles. |
| **Table Cell** | 13px | 400 | `textBlack` | Data table values (#000000). |
| **Meta / Helper** | 12px | 400 | `textSecondary`| Hints, muted metadata. |
| **Link / Hyperlink**| 13px | 500 | `linkBlue` | Interactive links (#0000FF). |
| **Button Text** | 14px | 600 | `white` | Action buttons (on primary backgrounds). |

## Casing Standards (Mandatory)
| UI Element | Case Style | Example |
| :--- | :--- | :--- |
| **Destinations (Titles)** | Title Case | Create Sales Order |
| **Instructions (Labels)** | Sentence case | Customer name |
| **Actions (Buttons)** | Title Case | Save Invoice |
| **Identifiers (SKU/ID)**| Uppercase | ITEM-1001 |

## Interaction & Mobile Behavior
- **Responsive**: Font sizes remain consistent across web and mobile to maintain ERP density.
- **Line Height**: Typically ranges from `1.2` to `1.5` based on context (standardized in `AppTheme` base styles).

## Inconsistencies Found
- **Case Mismatches**: Some labels use Title Case (e.g., "Customer Name") instead of the required Sentence case ("Customer name").
- **Font Weight Drift**: Occasional use of `FontWeight.bold` instead of `FontWeight.w600` or `FontWeight.w700`.

## Recommended Standards
Use `AppTheme.pageTitle`, `AppTheme.sectionHeader`, etc., as the primary entry points for text styling. Avoid manual `TextStyle` creation in presentation files.
