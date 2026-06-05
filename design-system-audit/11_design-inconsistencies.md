# ⚠️ Design Inconsistencies Audit

## CRITICAL ISSUES
1. **Hardcoded Color Usage**: Several legacy modules still use `Colors.white` or `Color(0xFF...)` instead of `AppTheme` tokens. This breaks theme propagation.
2. **Missing Master-Detail Transition**: Some new modules implement full-screen lists that don't transition into the Master-Detail split on selection, violating the Zoho-style UX pattern.

## MAJOR ISSUES
1. **Typography Drift**: Casing rules (Title Case vs. Sentence case) are inconsistent across module headers and form labels.
2. **Input Height Discrepancies**: `isDense: true` is not applied consistently to all text fields, leading to height variations in dense forms.
3. **Z-Order/Overlay Clashes**: Some dropdown overlays appear behind other UI elements due to incorrect `Navigator` or `Stack` usage.

## MINOR ISSUES
1. **Icon Sizing**: Inconsistent icon sizes (some 20px, some 24px) in secondary toolbars.
2. **Spacing Variance**: Use of arbitrary padding (e.g., 20px, 15px) instead of the 8px-based scale (`space16`, `space24`).
3. **Radius Drift**: Some card components still use 8px/12px radius instead of the standardized **4px**.

## Technical Debt (Frontend)
- **Bloated Presentation Files**: Some screens (e.g., `sales_order_list.dart`) have exceeded 5000 lines, making UI maintenance difficult. Recommend extracting widgets to sub-folders.
- **Redundant Dialogs**: Multiple implementations of "Unsaved Changes" dialogs. Recommend standardizing on `ZerpaiConfirmationDialog`.
- **Inline Styles**: Extensive use of inline `TextStyle` instead of `AppTheme.bodyText` or `AppTheme.pageTitle`.

## Priority Fix Roadmap
1. **Phase 1 (Critical)**: Refactor all hardcoded colors to `AppTheme` tokens.
2. **Phase 2 (Major)**: Audit and fix casing standards across all screens.
3. **Phase 3 (Major)**: Extract local widgets from massive presentation files to improve reusability and scanability.
