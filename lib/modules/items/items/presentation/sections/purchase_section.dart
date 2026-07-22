import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zerpai_erp/shared/models/account_node.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_builders.dart';

import 'package:zerpai_erp/shared/widgets/inputs/shared_field_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/account_tree_dropdown.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class PurchaseSection extends StatelessWidget {
  final TextEditingController costPriceCtrl;
  final TextEditingController descriptionCtrl;

  final String currency;
  final ValueChanged<String?> onCurrencyChange;

  final String? accountValue;
  final ValueChanged<String?> onAccountChanged;

  final String? preferredVendor;
  final ValueChanged<String?> onVendorChanged;
  final String? repValue;
  final ValueChanged<String?> onRepChanged;

  final bool purchasable;
  final ValueChanged<bool?> onPurchasableChanged;

  // Kept only for constructor compatibility
  final ZerpaiFieldBuilder zerpaiField;
  final ZerpaiTextFieldBuilder zerpaiTextField;
  final ZerpaiDropdownBuilder zerpaiDropdown;
  final List<dynamic> accountOptions;
  final List<dynamic> repOptions;
  final List<dynamic> vendorOptions;

  final String? costPriceError;
  final String? accountError;
  final Future<List<String>> Function(String query)? onAccountSearch;
  final Future<List<String>> Function(String query)? onRepSearch;
  final Future<List<String>> Function(String query)? onVendorSearch;
  final VoidCallback? onManageRepsTap;

  const PurchaseSection({
    super.key,
    required this.costPriceCtrl,
    required this.currency,
    required this.onCurrencyChange,
    required this.accountValue,
    required this.onAccountChanged,
    required this.preferredVendor,
    required this.onVendorChanged,
    required this.repValue,
    required this.onRepChanged,
    required this.purchasable,
    required this.onPurchasableChanged,
    required this.descriptionCtrl,
    required this.zerpaiField,
    required this.zerpaiTextField,
    required this.zerpaiDropdown,
    required this.accountOptions,
    required this.repOptions,
    required this.vendorOptions,
    this.costPriceError,
    this.accountError,
    this.onAccountSearch,
    this.onRepSearch,
    this.onVendorSearch,
    this.onManageRepsTap,
  });

  static const Set<String> _purchaseAccountWhitelist = {
    'other current asset',
    'advance tax',
    'employee advance',
    'prepaid expenses',
    'tds receivable',
    'fixed asset',
    'furniture and equipment',
    'other current liability',
    'employee reimbursements',
    'opening balance adjustments',
    'tax payable',
    'tds payable',
    'unearned revenue',
    'expense',
    'advertising and marketing',
    'automobile expense',
    'bad debt',
    'bank fees and charges',
    'consultant expense',
    'contract assets',
    'credit card charges',
    'depreciation and amortisation',
    'depreciation expense',
    'it and internet expenses',
    'janitorial expense',
    'lodging',
    'meals and entertainment',
    'merchandise',
    'office supplies',
    'other expenses',
    'postage',
    'printing and stationery',
    'purchase discounts',
    'raw materials and consumables',
    'rent expense',
    'repairs and maintenance',
    'salaries and employee wages',
    'telephone expense',
    'transportation expense',
    'travel expense',
    'uncategorized',
    'cost of goods sold',
    'job costing',
    'labor',
    'materials',
    'subcontractor',
  };

  String _accountName(Map<String, dynamic> a) {
    return (a['name'] ??
            a['user_account_name'] ??
            a['system_account_name'] ??
            a['account_name'] ??
            '')
        .toString();
  }

  String _accountType(Map<String, dynamic> a) {
    return (a['account_type'] ?? a['accountType'] ?? a['type'] ?? '')
        .toString()
        .trim();
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .toLowerCase()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  List<AccountNode> _buildWhitelistedAccountTree() {
    if (accountOptions.isEmpty) return const <AccountNode>[];

    final groupedByType = <String, List<AccountNode>>{};
    for (final raw in accountOptions) {
      if (raw is! Map<String, dynamic>) continue;
      final id = raw['id']?.toString();
      if (id == null || id.isEmpty) continue;
      final name = _accountName(raw).trim();
      if (!_purchaseAccountWhitelist.contains(name.toLowerCase())) continue;

      final typeRaw = _accountType(raw);
      final type = _toTitleCase(typeRaw.isEmpty ? 'Other' : typeRaw);
      groupedByType
          .putIfAbsent(type, () => <AccountNode>[])
          .add(AccountNode(id: id, name: name, selectable: true));
    }

    final sortedTypes = groupedByType.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return sortedTypes.map((type) {
      final children = groupedByType[type]!
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return AccountNode(
        id: '__account_type__$type',
        name: type,
        selectable: false,
        children: children,
      );
    }).toList();
  }

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
    final Color? dimLabel = purchasable ? null : AppTheme.textMuted;

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
                                  ? AppTheme.primaryBlueDark
                                  : isSelected
                                  ? AppTheme.infoBg
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
                                          ? AppTheme.primaryBlueDark
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check,
                                    size: 16,
                                    color: isHovered
                                        ? Colors.white
                                        : AppTheme.primaryBlueDark,
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
                child: AccountTreeDropdown(
                  value: accountValue,
                  nodes: _buildWhitelistedAccountTree(),
                  hint: 'Select account',
                  enabled: purchasable,
                  onChanged: onAccountChanged,
                  errorText: accountError,
                  height: 44,
                ),
              ),
            ),

            const SizedBox(height: 10),

            SharedFieldLayout(
              label: "Rep",
              tooltip: "Assign default rep for purchase follow-up.",
              labelColor: dimLabel,
              child: _wrapDisabled(
                enabled: purchasable,
                cursor: SystemMouseCursors.click,
                child: zerpaiDropdown<String>(
                  value: repValue,
                  items: repOptions
                      .map((r) => r['id']?.toString() ?? '')
                      .where((id) => id.isNotEmpty)
                      .toList(),
                  hint: "Select rep",
                  onChanged: onRepChanged,
                  enabled: purchasable,
                  onSearch: onRepSearch,
                  showSettings: true,
                  settingsLabel: 'Manage Rep',
                  onSettingsTap: onManageRepsTap,
                  displayStringForValue: (id) {
                    final rep = repOptions.firstWhere(
                      (r) => r['id']?.toString() == id,
                      orElse: () => {'name': id},
                    );
                    final name = (rep['name'] ?? rep['rep_name'] ?? id)
                        .toString();
                    final brandOrDivision =
                        ((rep['brand_name'] ??
                                    rep['brand'] ??
                                    rep['division'] ??
                                    '')
                                .toString())
                            .trim();
                    return brandOrDivision.isEmpty
                        ? name
                        : '$name ($brandOrDivision)';
                  },
                  itemBuilder: (id, isSelected, isHovered) {
                    final rep = repOptions.firstWhere(
                      (r) => r['id']?.toString() == id,
                      orElse: () => {'name': id},
                    );
                    final name = (rep['name'] ?? rep['rep_name'] ?? id)
                        .toString();
                    final brandOrDivision =
                        ((rep['brand_name'] ??
                                    rep['brand'] ??
                                    rep['division'] ??
                                    '')
                                .toString())
                            .trim();
                    return Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: isHovered
                            ? AppTheme.primaryBlueDark
                            : isSelected
                            ? AppTheme.infoBg
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              brandOrDivision.isEmpty
                                  ? name
                                  : '$name ($brandOrDivision)',
                              style: TextStyle(
                                fontSize: 13,
                                color: isHovered
                                    ? Colors.white
                                    : isSelected
                                    ? AppTheme.primaryBlueDark
                                    : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check,
                              size: 16,
                              color: isHovered
                                  ? Colors.white
                                  : AppTheme.primaryBlueDark,
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
                            ? AppTheme.primaryBlueDark
                            : isSelected
                            ? AppTheme.infoBg
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
                                    ? AppTheme.primaryBlueDark
                                    : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check,
                              size: 16,
                              color: isHovered
                                  ? Colors.white
                                  : AppTheme.primaryBlueDark,
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
