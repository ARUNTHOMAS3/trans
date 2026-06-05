# 📏 Spacing & Layout Audit

## Spacing System
The system uses an 8px base unit (Section 14.4).

| Token | Value | Usage |
| :--- | :--- | :--- |
| `space4` | 4px | Micro-spacing (radius, icons). |
| `space8` | 8px | Base spacing unit. |
| `space12`| 12px | Small grouping. |
| `space16`| 16px | Standard padding (cards, tables). |
| `space24`| 24px | Section padding, modal padding. |
| `space32`| 32px | Large gaps. |

## Layout Structure
- **Sidebar Width**: 240px (Collapsible).
- **Page Header Height**: 64px.
- **Form Field Max Width**: 400px (standard), 700px (large/description).
- **Density**: High (Row heights ~32px-40px).

## Container & Grid
- **Master-Detail View**: 30-40% Master list, 60-70% Detail pane.
- **Responsiveness**:
  - `Compact`: < 1100px width (hides non-essential columns).
  - `Mobile`: Stacked layout for detail panes.

## Common Patterns
- **Card Padding**: Fixed 16px.
- **Divider**: 1px thickness, `AppTheme.borderColor`.
- **Form Gaps**: 12px-16px between vertical fields.

## Inconsistencies
- **Hardcoded Margins**: Some screens use `EdgeInsets.all(20)` instead of `EdgeInsets.all(AppTheme.space16)`.
- **Inconsistent Card Radius**: Some older cards might use default 8px or 12px instead of the required **4px**.

## Recommended Standard
Always use `AppTheme.spaceX` constants. For screen-level layouts, wrap content in `ZerpaiLayout` (from `lib/shared/widgets/zerpai_layout.dart`) which enforces standardized top/horizontal padding.
