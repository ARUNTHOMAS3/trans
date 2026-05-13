// FILE: lib/shared/widgets/sections/contact_persons_table.dart
//
// Reusable contact-persons table widget that consolidates the identical
// patterns previously duplicated in:
//   lib/modules/sales/presentation/sections/sales_customer_contact_persons_section.dart
//   lib/modules/purchases/vendors/presentation/sections/purchases_vendors_contact_persons_section.dart

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/phone_input_field.dart';

// ─── Data model ───────────────────────────────────────────────────────────────

/// Mutable data row representing a single contact person entry.
///
/// Call [dispose] when the row is permanently removed from the list.
class ContactPersonRow {
  String salutation;
  String phonePrefix;
  String mobilePrefix;

  final TextEditingController firstName;
  final TextEditingController lastName;
  final TextEditingController email;
  final TextEditingController phone;
  final TextEditingController mobile;

  /// Internal hover state — managed by [ContactPersonsTable].
  bool _isHovered = false;

  ContactPersonRow({
    this.salutation = 'Mr.',
    this.phonePrefix = '+91',
    this.mobilePrefix = '+91',
    String? initialFirstName,
    String? initialLastName,
    String? initialEmail,
    String? initialPhone,
    String? initialMobile,
  })  : firstName = TextEditingController(text: initialFirstName),
        lastName = TextEditingController(text: initialLastName),
        email = TextEditingController(text: initialEmail),
        phone = TextEditingController(text: initialPhone),
        mobile = TextEditingController(text: initialMobile);

  /// Clears all text fields and resets dropdowns to their defaults.
  void clear() {
    firstName.clear();
    lastName.clear();
    email.clear();
    phone.clear();
    mobile.clear();
    salutation = 'Mr.';
    phonePrefix = '+91';
    mobilePrefix = '+91';
  }

  /// Disposes all [TextEditingController]s. Call when the row is removed.
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    email.dispose();
    phone.dispose();
    mobile.dispose();
  }
}

// ─── Widget ───────────────────────────────────────────────────────────────────

/// A full-width tabular editor for a list of contact persons.
///
/// The parent screen is responsible for owning [rows] and calling
/// [onAddRow] / [onRemoveRow]. The widget is intentionally stateless so that
/// all mutations flow back through the parent (Riverpod / setState).
///
/// Row deletion behaviour mirrors the source screens:
/// - First row (index 0): fields are cleared, the row itself is kept.
/// - Subsequent rows: the row is removed from the list.
///
/// Usage:
/// ```dart
/// ContactPersonsTable(
///   rows: _contactRows,
///   onAddRow: () => setState(() => _contactRows.add(ContactPersonRow())),
///   onRemoveRow: (i) => setState(() {
///     if (i == 0) _contactRows[0].clear();
///     else _contactRows.removeAt(i).dispose();
///   }),
///   onChanged: _markDirty,
/// )
/// ```
class ContactPersonsTable extends StatefulWidget {
  /// The live list of contact-person rows owned by the parent.
  final List<ContactPersonRow> rows;

  /// Called when the user taps "Add Contact Person".
  final VoidCallback onAddRow;

  /// Called when the delete button for row [index] is tapped.
  final void Function(int index) onRemoveRow;

  /// Optional callback invoked whenever any inline field changes.
  /// Useful for dirty-state tracking.
  final VoidCallback? onChanged;

  /// Height for all inline input widgets.
  final double inputHeight;

  const ContactPersonsTable({
    super.key,
    required this.rows,
    required this.onAddRow,
    required this.onRemoveRow,
    this.onChanged,
    this.inputHeight = AppTheme.inputHeight,
  });

  @override
  State<ContactPersonsTable> createState() => _ContactPersonsTableState();
}

class _ContactPersonsTableState extends State<ContactPersonsTable> {
  // ── Header ──────────────────────────────────────────────────────────────────

  static const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: AppTheme.textSecondary,
  );

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space8,
        vertical: AppTheme.space10,
      ),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'SALUTATION',
              style: _headerStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'FIRST NAME',
              style: _headerStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'LAST NAME',
              style: _headerStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              'EMAIL ADDRESS',
              style: _headerStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              'WORK PHONE',
              style: _headerStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              'MOBILE',
              style: _headerStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Spacer for the delete-icon column
          SizedBox(width: 32),
        ],
      ),
    );
  }

  // ── Data row ─────────────────────────────────────────────────────────────────

  Widget _buildRow(int index, ContactPersonRow row) {
    return StatefulBuilder(
      builder: (context, setRowState) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.space6),
          child: MouseRegion(
            onEnter: (_) => setRowState(() => row._isHovered = true),
            onExit: (_) => setRowState(() => row._isHovered = false),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space8,
                vertical: AppTheme.space8,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderLight),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  // Salutation dropdown
                  Expanded(
                    flex: 2,
                    child: FormDropdown<String>(
                      height: widget.inputHeight,
                      value: row.salutation,
                      items: const ['Mr.', 'Mrs.', 'Ms.', 'Miss', 'Dr.'],
                      onChanged: (v) {
                        setState(() => row.salutation = v ?? 'Mr.');
                        widget.onChanged?.call();
                      },
                    ),
                  ),
                  const SizedBox(width: AppTheme.space8),

                  // First name
                  Expanded(
                    flex: 3,
                    child: CustomTextField(
                      height: widget.inputHeight,
                      controller: row.firstName,
                      forceUppercase: false,
                      onChanged: (_) => widget.onChanged?.call(),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space8),

                  // Last name
                  Expanded(
                    flex: 3,
                    child: CustomTextField(
                      height: widget.inputHeight,
                      controller: row.lastName,
                      forceUppercase: false,
                      onChanged: (_) => widget.onChanged?.call(),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space8),

                  // Email
                  Expanded(
                    flex: 4,
                    child: CustomTextField(
                      height: widget.inputHeight,
                      controller: row.email,
                      forceUppercase: false,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => widget.onChanged?.call(),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space8),

                  // Work phone
                  Expanded(
                    flex: 4,
                    child: PhoneInputField(
                      selectedPrefix: row.phonePrefix,
                      controller: row.phone,
                      hintText: '',
                      onPrefixChanged: (v) {
                        setState(() => row.phonePrefix = v ?? '+91');
                        widget.onChanged?.call();
                      },
                    ),
                  ),
                  const SizedBox(width: AppTheme.space8),

                  // Mobile
                  Expanded(
                    flex: 4,
                    child: PhoneInputField(
                      selectedPrefix: row.mobilePrefix,
                      controller: row.mobile,
                      hintText: '',
                      onPrefixChanged: (v) {
                        setState(() => row.mobilePrefix = v ?? '+91');
                        widget.onChanged?.call();
                      },
                    ),
                  ),
                  const SizedBox(width: AppTheme.space8),

                  // Delete button (visible on hover)
                  SizedBox(
                    width: 32,
                    child: row._isHovered
                        ? IconButton(
                            onPressed: () {
                              widget.onRemoveRow(index);
                              widget.onChanged?.call();
                            },
                            icon: const Icon(
                              LucideIcons.trash2,
                              size: 16,
                              color: AppTheme.errorRed,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 20,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: AppTheme.space8),

          // Data rows
          ...widget.rows
              .asMap()
              .entries
              .map((e) => _buildRow(e.key, e.value)),

          const SizedBox(height: AppTheme.space12),

          // Add-row button
          OutlinedButton.icon(
            onPressed: widget.onAddRow,
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('Add Contact Person'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryBlueDark,
              side: const BorderSide(color: AppTheme.borderColor),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space16,
                vertical: AppTheme.space12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
