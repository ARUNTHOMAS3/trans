# 📝 Form Patterns Audit

## Form Structure
- **Label Position**: Typically above the input field (Section 14.3.1).
- **Mandatory Fields**: Indicated by a red asterisk (`*`) or `errorRed` text.
- **Grouping**: Related fields are grouped into sections using `SectionHeader` or `FormRow`.
- **Spacing**: 12px-16px vertical gap between rows.

## Input Behavior
- **Searchable Dropdowns**: `FormDropdown` supports local and async search.
- **Validation**: Performed via `Form` widget and `TextFormField` validators. Errors are displayed in `errorRed` (#D32F2F) below the input.
- **Autofill**: Supported for common fields like `customer_name`, `billing_address`.
- **Keyboard Navigation**: Optimized for `Tab` key progression. `ShortcutHandler` is used for POS workflows.

## Field Types & Validation
- **GSTIN**: Validated using `LicenceValidationMixin`.
- **Amount/Currency**: Uses `ZCurrencyDisplay` and numeric-only keyboard types.
- **Required fields**: Checked on form submission; focus jumps to the first invalid field.

## Libraries Used
- **Flutter Core**: `Form`, `TextFormField`.
- **Validation**: Custom mixins (`LicenceValidationMixin`) and `class-validator` (backend).
- **State**: `Riverpod` for real-time field synchronization.

## Inconsistencies
- **Error Positioning**: Some forms display errors in dialogs, while others use inline text. Standardize to inline `errorRed` text.
- **Placeholder Case**: Some placeholders use Title Case ("Enter Customer Name") instead of the required Sentence case ("Enter customer name").

## Recommended Standard
Wrap form fields in `FormRow` or `SharedFieldLayout` to ensure consistent horizontal alignment and label spacing. Use `CustomTextField` for all standard inputs.
