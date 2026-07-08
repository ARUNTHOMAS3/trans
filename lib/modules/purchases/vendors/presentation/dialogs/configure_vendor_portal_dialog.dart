import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';
import 'package:zerpai_erp/modules/purchases/vendors/repositories/vendor_repository_impl.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

class _PortalContact {
  final String name;
  final String? email;
  const _PortalContact({required this.name, this.email});
}

/// "Configure Portal Access" dialog — lists the vendor's contacts (primary +
/// contact persons) so the user can pick which ones get vendor-portal access.
///
/// Self-contained: fetches the full vendor (incl. contact persons) from the
/// detail endpoint. Show with
/// `showDialog(builder: (_) => ConfigureVendorPortalDialog(...))`.
class ConfigureVendorPortalDialog extends ConsumerStatefulWidget {
  final String vendorId;

  /// The vendor already known from the list — used for the primary contact and
  /// as a fallback if the detail fetch fails.
  final Vendor fallbackVendor;

  const ConfigureVendorPortalDialog({
    super.key,
    required this.vendorId,
    required this.fallbackVendor,
  });

  @override
  ConsumerState<ConfigureVendorPortalDialog> createState() =>
      _ConfigureVendorPortalDialogState();
}

class _ConfigureVendorPortalDialogState
    extends ConsumerState<ConfigureVendorPortalDialog> {
  bool _loading = true;
  List<_PortalContact> _contacts = const [];
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    Vendor? full;
    try {
      full = await ref
          .read(vendorRepositoryProvider)
          .getVendorById(widget.vendorId);
    } catch (_) {
      // Fall back to the list vendor (primary contact only).
    }
    final vendor = full ?? widget.fallbackVendor;

    final contacts = <_PortalContact>[];

    // Primary contact (the vendor's own contact details).
    final primaryName = _joinName(
      vendor.salutation,
      vendor.firstName,
      vendor.lastName,
    );
    contacts.add(
      _PortalContact(
        name: primaryName.isNotEmpty ? primaryName : vendor.displayName,
        email: _clean(vendor.email),
      ),
    );

    // Additional contact persons.
    for (final cp in vendor.contactPersons ?? const <Map<String, dynamic>>[]) {
      final name = _joinName(
        cp['salutation']?.toString(),
        cp['firstName']?.toString(),
        cp['lastName']?.toString(),
      );
      contacts.add(
        _PortalContact(
          name: name.isNotEmpty ? name : '-',
          email: _clean(cp['email']?.toString()),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _contacts = contacts;
        _loading = false;
      });
    }
  }

  static String _joinName(String? salutation, String? first, String? last) {
    return [salutation, first, last]
        .where((p) => p != null && p.trim().isNotEmpty)
        .map((p) => p!.trim())
        .join(' ');
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  Widget _checkbox(bool value, ValueChanged<bool?> onChanged) {
    return SizedBox(
      width: 16,
      height: 16,
      child: Theme(
        data: Theme.of(context).copyWith(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          checkboxTheme: CheckboxThemeData(
            side: const BorderSide(color: Color(0xFFD1D5DB), width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3),
            ),
            fillColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? const Color(0xFF2563EB)
                  : Colors.white,
            ),
            checkColor: const WidgetStatePropertyAll(Colors.white),
          ),
        ),
        child: Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF2563EB),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Material(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 24,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 680,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──────────────────────────────────────────────
                Container(
                  color: const Color(0xFFF9F9FB),
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Configure Portal Access',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            LucideIcons.x,
                            size: 18,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                // ── Table header ────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  height: 44,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Row(
                    children: const [
                      SizedBox(width: 30),
                      Expanded(
                        flex: 5,
                        child: Text(
                          'NAME',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 7,
                        child: Text(
                          'EMAIL ADDRESS',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Rows ────────────────────────────────────────────────
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 360),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(_contacts.length, (index) {
                          final contact = _contacts[index];
                          final selected = _selected.contains(index);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            height: 52,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Color(0xFFF0F0F2)),
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 30,
                                  child: _checkbox(selected, (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selected.add(index);
                                      } else {
                                        _selected.remove(index);
                                      }
                                    });
                                  }),
                                ),
                                Expanded(
                                  flex: 5,
                                  child: Text(
                                    contact.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 7,
                                  child: contact.email != null
                                      ? Text(
                                          contact.email!,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF4B5563),
                                          ),
                                        )
                                      : Align(
                                          alignment: Alignment.centerLeft,
                                          child: InkWell(
                                            onTap: () {},
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 2,
                                              ),
                                              child: Text(
                                                'Add Email',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF2563EB),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                // ── Footer ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                  child: Row(
                    children: [
                      ZButton.primary(
                        label: 'Save',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 10),
                      ZButton.secondary(
                        label: 'Cancel',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
