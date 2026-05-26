# 🖼️ Icons & Assets Audit

## Icon Libraries
- **Primary**: `LucideIcons` (from `lucide_icons` package).
- **Secondary (Brands)**: `FontAwesomeIcons` (from `font_awesome_flutter` package).

## Usage Rules
- **Sizing**: Default size is `20px`. Small action icons use `14px-16px`.
- **Color**:
  - `textPrimary` for navigation/action icons.
  - `primaryBlue` for active/highlighted icons.
  - `errorRed` for delete/warning icons.
  - `textDisabled` for inactive states.

## Key Icons Mapping
| Action | Icon |
| :--- | :--- |
| **Add/New** | `plus` |
| **Edit** | `edit` |
| **Delete** | `trash2` |
| **Search** | `search` |
| **Filter** | `filter` |
| **More/Options**| `moreVertical` |
| **Success** | `checkCircle` |
| **Warning** | `alertTriangle` |
| **Error** | `alertCircle` |
| **Help/Tooltip**| `helpCircle` |

## Assets & Illustrations
- **Logos**: Stored in `assets/images/logo.png`.
- **Empty States**: Minimalist line-art illustrations used for "No Data" states.
- **Loading**: Custom circular progress indicators and skeletons.

## Inconsistencies
- **Mixed Libraries**: Occasional usage of `Icons` (Material) instead of `LucideIcons`.
- **Scaling**: Some icons are hardcoded at `24px` instead of the standard `20px`.

## Recommended Standard
Always use `LucideIcons`. Material Icons should be avoided unless a specific Lucide equivalent is missing.
