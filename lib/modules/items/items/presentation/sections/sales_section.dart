import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_builders.dart';
import 'package:zerpai_erp/shared/widgets/inputs/shared_field_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class SalesSection extends StatelessWidget {
  final TextEditingController sellingPriceCtrl;
  final TextEditingController mrpCtrl;
  final TextEditingController ptrCtrl;
  final TextEditingController descriptionCtrl;

  final String currency;
  final ValueChanged<String?> onCurrencyChange;

  final String? accountValue;
  final ValueChanged<String?> onAccountChanged;

  final bool sellable;
  final ValueChanged<bool?> onSellableChanged;

  // Kept only for constructor compatibility
  final ZerpaiFieldBuilder zerpaiField;
  final ZerpaiTextFieldBuilder zerpaiTextField;
  final ZerpaiDropdownBuilder zerpaiDropdown;
  final List<dynamic> accountOptions;
  final String? sellingPriceError;
  final String? accountError;
  final Future<List<String>> Function(String query)? onAccountSearch;

  const SalesSection({
    super.key,
    required this.sellingPriceCtrl,
    required this.mrpCtrl,
    required this.ptrCtrl,
    required this.descriptionCtrl,
    required this.currency,
    required this.onCurrencyChange,
    required this.accountValue,
    required this.onAccountChanged,
    required this.sellable,
    required this.onSellableChanged,
    required this.zerpaiField,
    required this.zerpaiTextField,
    required this.zerpaiDropdown,
    required this.accountOptions,
    this.sellingPriceError,
    this.accountError,
    this.onAccountSearch,
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
    final Color labelDim = sellable
        ? AppTheme.textBody
        : AppTheme.textMuted;

    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- SELLING PRICE ----------------
            SharedFieldLayout(
              label: "Selling Price",
              required: false,
              tooltip:
                  "The price at which you sell this item to your customers.",
              labelColor: sellable ? null : labelDim,
              child: Row(
                children: [
                  _wrapDisabled(
                    enabled: sellable,
                    cursor: SystemMouseCursors.click,
                    child: SizedBox(
                      width: 90,
                      child: FormDropdown<String>(
                        value: currency,
                        items: const ['INR', 'USD', 'AED'],
                        onChanged: onCurrencyChange,
                        enabled: sellable,
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
                      enabled: sellable,
                      cursor: SystemMouseCursors.text,
                      child: CustomTextField(
                        controller: sellingPriceCtrl,
                        hintText: 'Enter price',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        height: 44,
                        enabled: sellable,
                        errorText: sellingPriceError,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ---------------- MRP ----------------
            SharedFieldLayout(
              label: "MRP",
              tooltip:
                  "Maximum Retail Price (inclusive of taxes where applicable).",
              labelColor: labelDim,
              child: _wrapDisabled(
                enabled: sellable,
                cursor: SystemMouseCursors.text,
                child: CustomTextField(
                  controller: mrpCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  height: 44,
                  enabled: sellable,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ---------------- PTR ----------------
            SharedFieldLayout(
              label: "PTR",
              tooltip:
                  "Price To Retailer (the price at which stock is sold to a retail branch).",
              labelColor: labelDim,
              child: _wrapDisabled(
                enabled: sellable,
                cursor: SystemMouseCursors.text,
                child: CustomTextField(
                  controller: ptrCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  height: 44,
                  enabled: sellable,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ---------------- ACCOUNT (TREE) ----------------
            SharedFieldLayout(
              label: "Account",
              required: true,
              tooltip:
                  "All sales transactions for this item will be tracked under this account",
              labelColor: sellable ? null : labelDim,
              child: _wrapDisabled(
                enabled: sellable,
                cursor: SystemMouseCursors.click,
                child: zerpaiDropdown<String>(
                  value: accountValue,
                  items: accountOptions.map((a) => a['id'] as String).toList(),
                  hint: 'Select account',
                  onChanged: onAccountChanged,
                  errorText: accountError,
                  enabled: sellable,
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
                            ? AppTheme.primaryBlueDark
                            : isSelected
                            ? AppTheme.infoBg
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
              labelColor: labelDim,
              child: _wrapDisabled(
                enabled: sellable,
                cursor: SystemMouseCursors.text,
                child: CustomTextField(
                  controller: descriptionCtrl,
                  hintText: 'Description',
                  keyboardType: TextInputType.multiline,
                  maxLines: 3,
                  height: 96,
                  enabled: sellable,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
