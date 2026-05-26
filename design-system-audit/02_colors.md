# 🎨 Color Palette Audit

## Core Tokens (AppTheme)
All colors originate from `lib/core/theme/app_theme.dart`.

| Purpose | Token Name | HEX | Usage |
| :--- | :--- | :--- | :--- |
| **Branding / Action** | `accentBase` | *Dynamic* | **ONLY** for Primary Buttons and Sidebar "New" buttons. User-configurable via Branding settings. |
| **App Background** | `backgroundColor` | `#FFFFFF` | Global background, cards, surfaces. |
| **Sidebar Background**| `sidebarColor` | `#1F2633` | Primary navigation sidebar background. |
| **Primary Text** | `textBlack` | `#000000` | **Mandatory** for all normal texts, headers, and table values. |
| **Secondary & Links** | `linkBlue` | `#0000FF` | Used for all hyperlinks, blue text, and secondary interactive text. |
| **Required Field** | `requiredRed` | `#FF0000` | **Mandatory** for the asterisk (*) next to required questions. |
| **Borders / Dividers** | `borderColor` | `#D3D9E3` | Separators, table borders, card outlines. |

## Visibility & Contrast Rules
- **Light Backgrounds**: If a component uses a light color (e.g., Green, light `accentBase`), the text on top **MUST** be white to ensure maximum visibility.
- **Normal Surfaces**: Text on white backgrounds must always be `#000000` (Black).

## Extended Palette
| Purpose | Token Name | HEX | Usage |
| :--- | :--- | :--- | :--- |
| **Success** | `successGreen` | `#28A745` | Success notifications (Text on top: White). |
| **Warning** | `warningOrange` | `#F59E0B` | Warning alerts (Text on top: Black/White depending on shade). |
| **Error** | `errorRed` | `#D32F2F` | Error messages (distinct from required asterisk red). |
| **Hover State** | `bgHover` | `#F3F4F6` | Interactive element hover background. |
| **Disabled** | `bgDisabled` | `#F3F4F6` | Disabled input/button background. |

## Interaction States
- **Hover**: Typically uses `bgHover` (#F3F4F6) or a 10% darker shade of the base color.
- **Active/Selection**: Uses `selectionActiveBg` (#F0F7FF) for row highlights.
- **Required Asterisk**: The `*` symbol color is strictly `#FF0000`.

## Design Anomalies & Inconsistencies
- **Off-Black Text**: Currently, `textPrimary` uses `#1F2933`. This must be refactored to pure black `#000000`.
- **Link Colors**: Ensure all clickable text uses the `linkBlue` token instead of primary action blue.

## Recommended Unified Palette
Stick strictly to the tokens defined in `AppTheme`. Any new color requirement must be added to the global theme instead of being hardcoded.
