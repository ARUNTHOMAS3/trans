// FILE: lib/shared/constants/gst_constants.dart
// Centralised GST treatment and registration type constants used across
// sales, purchases, and settings modules.

/// GST treatment options for customers, vendors, and branches.
/// Each entry is a display label used directly in FormDropdown<String>.
const List<String> kGstTreatmentOptions = [
  'Registered Business - Regular',
  'Registered Business - Composition',
  'Unregistered Business',
  'Consumer',
  'Overseas',
  'Special Economic Zone',
  'Deemed Export',
];

/// GST registration types for settings (branches, locations).
const List<String> kGstRegistrationTypes = [
  'Regular',
  'Composition',
  'Unregistered',
  'Consumer',
  'Overseas',
  'Special Economic Zone',
  'Deemed Export',
];

/// Salutation options for contact persons and customer/vendor profiles.
const List<String> kSalutationOptions = [
  'Mr.',
  'Mrs.',
  'Ms.',
  'Dr.',
  'Prof.',
];

/// Drug licence type display options for the dropdown.
const List<String> kDrugLicenceTypeOptions = [
  'Wholesale (Form 20)',
  'Retail (Form 21)',
  'Wholesale & Retail (Form 20 & 21)',
  'Wholesale (Form 20B)',
  'Retail (Form 21B)',
  'Wholesale & Retail (Form 20B & 21B)',
];
