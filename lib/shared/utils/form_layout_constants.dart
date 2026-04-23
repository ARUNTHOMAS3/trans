// FILE: lib/shared/utils/form_layout_constants.dart
//
// Form layout constants — use these instead of hardcoding values in create/edit
// screens.  Based on the repeated pattern found in sales_customer_create.dart,
// purchases_vendors_vendor_create.dart, and 10+ other screens.

/// Standard width for the label column in a horizontal form row.
const double kFormLabelWidth = 200.0;

/// Standard width for a single-column form input field.
const double kFormFieldWidth = 480.0;

/// Standard height for single-line text and dropdown inputs (matches
/// [CustomTextField] and [FormDropdown] default heights).
const double kFormInputHeight = 36.0;

/// Vertical gap between consecutive form rows.
const double kFormFieldSpacing = 16.0;

/// Vertical gap between form sections / card groups.
const double kFormSectionSpacing = 24.0;

/// Width used for licence / registration number inputs that are intentionally
/// narrower than a full [kFormFieldWidth] field.
const double kLicenseInputWidth = 280.0;

/// Internal padding applied to form cards / sections.
const double kFormCardPadding = 24.0;
