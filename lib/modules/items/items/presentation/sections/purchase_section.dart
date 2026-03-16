import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_builders.dart';

import 'package:zerpai_erp/shared/widgets/inputs/shared_field_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';

class PurchaseSection extends StatelessWidget {
  final TextEditingController costPriceCtrl;
  final TextEditingController descriptionCtrl;

  final String currency;
  final ValueChanged<String?> onCurrencyChange;

  final String? accountValue;
  final ValueChanged<String?> onAccountChanged;

  final String? preferredVendor;
  final ValueChanged<String?> onVendorChanged;

  final bool purchasable;
  final ValueChanged<bool?> onPurchasableChanged;

  // Kept only for constructor compatibility
  final ZerpaiFieldBuilder zerpaiField;
  final ZerpaiTextFieldBuilder zerpaiTextField;
  final ZerpaiDropdownBuilder zerpaiDropdown;
  final List<dynamic> accountOptions;
  final List<dynamic> vendorOptions;

  final String? costPriceError;
  final String? accountError;
  final Future<List<String>> Function(String query)? onAccountSearch;
  final Future<List<String>> Function(String query)? onVendorSearch;

  const PurchaseSection({
    super.key,
    required this.costPriceCtrl,
    required this.currency,
    required this.onCurrencyChange,
    required this.accountValue,
    required this.onAccountChanged,
    required this.preferredVendor,
    required this.onVendorChanged,
    required this.purchasable,
    required this.onPurchasableChanged,
    required this.descriptionCtrl,
    required this.zerpaiField,
    required this.zerpaiTextField,
    required this.zerpaiDropdown,
    required this.accountOptions,
    required this.vendorOptions,
    this.costPriceError,
    this.accountError,
    this.onAccountSearch,
    this.onVendorSearch,
  });

  Widget _wrapDisabled({
    required bool enabled,
    required Widget child,
    SystemMouseCursor cursor = SystemMouseCursors.basic,
  }) {
    return MouseRegion(
      cursor: enabled ? cursor : SystemMouseCursors.forbidden,
      child: AbsorbPointer(
        absorbing: !enabled,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled ? 1 : 0.55,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color? dimLabel = purchasable ? null : const Color(0xFF9CA3AF);

    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- COST PRICE ----------------
            SharedFieldLayout(
              label: 'Cost Price',
              required: false,
              tooltip: "The price you pay for purchasing this item.",
              labelColor: dimLabel,
              child: Row(
                children: [
                  _wrapDisabled(
                    enabled: purchasable,
                    cursor: SystemMouseCursors.click,
                    child: SizedBox(
                      width: 80,
                      child: FormDropdown<String>(
                        value: currency,
                        items: const ['INR', 'USD', 'EUR'],
                        onChanged: onCurrencyChange,
                        enabled: purchasable,
                        showSearch: false,
                        itemBuilder: (id, isSelected, isHovered) {
                          return Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: isHovered
                                  ? const Color(0xFF2563EB)
                                  : isSelected
                                  ? const Color(0xFFEFF6FF)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    id,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isHovered
                                          ? Colors.white
                                          : isSelected
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFF111827),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check,
                                    size: 16,
                                    color: isHovered
                                        ? Colors.white
                                        : const Color(0xFF2563EB),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _wrapDisabled(
                      enabled: purchasable,
                      cursor: SystemMouseCursors.text,
                      child: CustomTextField(
                        controller: costPriceCtrl,
                        hintText: 'Enter cost price',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        height: 44,
                        maxLines: 1,
                        enabled: purchasable,
                        errorText: costPriceError,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ---------------- ACCOUNT (TREE DROPDOWN) ----------------
            SharedFieldLayout(
              label: "Account",
              required: true,
              tooltip:
                  "All purchase transactions for this item will be tracked under this account",
              labelColor: dimLabel,
              child: _wrapDisabled(
                enabled: purchasable,
                cursor: SystemMouseCursors.click,
                child: zerpaiDropdown<String>(
                  value: accountValue,
                  items: accountOptions.map((a) => a['id'] as String).toList(),
                  hint: "Select account",
                  enabled: purchasable,
                  onChanged: onAccountChanged,
                  errorText: accountError,
                  onSearch: onAccountSearch,
                  displayStringForValue: (id) {
                    if (accountOptions.isEmpty) return id;
                    final acc = accountOptions.firstWhere(
                      (a) => a['id'] == id,
                      orElse: () => {
                        'id': id,
                        'name': 'Unknown',
                        'system_account_name': 'Unknown',
                      },
                    );
                    return acc['name'] ?? acc['system_account_name'] ?? id;
                  },
                  itemBuilder: (id, isSelected, isHovered) {
                    final acc = accountOptions.firstWhere(
                      (a) => a['id'] == id,
                      orElse: () => {
                        'id': id,
                        'name': 'Unknown',
                        'system_account_name': 'Unknown',
                      },
                    );
                    return Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: isHovered
                            ? const Color(0xFF2563EB)
                            : isSelected
                            ? const Color(0xFFEFF6FF)
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              acc['name'] ?? acc['system_account_name'] ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: isHovered
                                    ? Colors.white
                                    : isSelected
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF111827),
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check,
                              size: 16,
                              color: isHovered
                                  ? Colors.white
                                  : const Color(0xFF2563EB),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ---------------- PREFERRED VENDOR ----------------
            SharedFieldLayout(
              label: "Preferred Vendor",
              tooltip: "The main supplier you procure this item from.",
              labelColor: dimLabel,
              child: _wrapDisabled(
                enabled: purchasable,
                cursor: SystemMouseCursors.click,
                child: zerpaiDropdown<String>(
                  value: preferredVendor,
                  items: vendorOptions.map((v) => v['id'] as String).toList(),
                  hint: "Select vendor",
                  onChanged: onVendorChanged,
                  enabled: purchasable,
                  onSearch: onVendorSearch,
                  displayStringForValue: (id) {
                    if (vendorOptions.isEmpty) return id;
                    final v = vendorOptions.firstWhere(
                      (ven) => ven['id'] == id,
                      orElse: () => {
                        'id': id,
                        'vendor_name': 'Unknown',
                        'name': 'Unknown',
                      },
                    );
                    return v['vendor_name'] ?? v['name'] ?? id;
                  },
                  itemBuilder: (id, isSelected, isHovered) {
                    final v = vendorOptions.firstWhere(
                      (ven) => ven['id'] == id,
                      orElse: () => {
                        'id': id,
                        'vendor_name': 'Unknown',
                        'name': 'Unknown',
                      },
                    );
                    return Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: isHovered
                            ? const Color(0xFF2563EB)
                            : isSelected
                            ? const Color(0xFFEFF6FF)
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              v['vendor_name'] ?? v['name'] ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: isHovered
                                    ? Colors.white
                                    : isSelected
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF111827),
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check,
                              size: 16,
                              color: isHovered
                                  ? Colors.white
                                  : const Color(0xFF2563EB),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ---------------- DESCRIPTION ----------------
            SharedFieldLayout(
              label: "Description",
              labelColor: dimLabel,
              child: _wrapDisabled(
                enabled: purchasable,
                cursor: SystemMouseCursors.text,
                child: CustomTextField(
                  controller: descriptionCtrl,
                  hintText: "Enter description",
                  keyboardType: TextInputType.multiline,
                  maxLines: 3,
                  height: 96,
                  enabled: purchasable,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
